using SoleLogics: AbstractKripkeStructure, AbstractInterpretationSet, AbstractFrame
using SoleLogics: Truth
import SoleData: modality, nmodalities, eachmodality

"""
    struct MultiLogiset{L<:AbstractLogiset}
        modalities  :: Vector{L}
    end

A logical dataset composed of different
[modalities](https://en.wikipedia.org/wiki/Multimodal_learning));
this structure is useful for representing multimodal datasets in logical terms.

See also
[`AbstractLogiset`](@ref),
[`minify`](@ref).
"""
struct MultiLogiset{L<:AbstractLogiset} <: AbstractInterpretationSet{AbstractKripkeStructure}

    modalities  :: Vector{L}

    function MultiLogiset{L}(X::MultiLogiset{L}) where {L<:AbstractLogiset}
        MultiLogiset{L}(X.modalities)
    end
    function MultiLogiset{L}(X::AbstractVector) where {L<:AbstractLogiset}
        X = collect(X)
        @assert length(X) > 0 && length(unique(ninstances.(X))) == 1 "Cannot create an empty MultiLogiset or with mismatching number of instances (nmodalities: $(length(X)), modality_sizes: $(ninstances.(X)))."
        new{L}(X)
    end
    function MultiLogiset{L}() where {L<:AbstractLogiset}
        new{L}(L[])
    end
    function MultiLogiset{L}(X::L) where {L<:AbstractLogiset}
        MultiLogiset{L}(L[X])
    end
    function MultiLogiset(X::AbstractVector{L}) where {L<:AbstractLogiset}
        MultiLogiset{L}(X)
    end
    function MultiLogiset(X::L) where {L<:AbstractLogiset}
        MultiLogiset{L}(X)
    end
end

eachmodality(X::MultiLogiset) = X.modalities

modalitytype(::Type{<:MultiLogiset{L}}) where {L<:AbstractLogiset} = L
modalitytype(X::MultiLogiset) = modalitytype(typeof(X))

modality(X::MultiLogiset, i_modality::Integer) = eachmodality(X)[i_modality]
nmodalities(X::MultiLogiset)                   = length(eachmodality(X))
ninstances(X::MultiLogiset)                    = ninstances(modality(X, 1))

worldtype(X::MultiLogiset,  i_modality::Integer) = worldtype(modality(X, i_modality))

featvaltype(X::MultiLogiset,  i_modality::Integer) = featvaltype(modality(X, i_modality))
featvaltypes(X::MultiLogiset) = Vector{Type{<:AbstractWorld}}(featvaltype.(eachmodality(X)))

featuretype(X::MultiLogiset,  i_modality::Integer) = featuretype(modality(X, i_modality))
featuretypes(X::MultiLogiset) = Vector{Type{<:AbstractWorld}}(featuretype.(eachmodality(X)))

frametype(X::MultiLogiset,  i_modality::Integer) = frametype(modality(X, i_modality))
frametypes(X::MultiLogiset) = Vector{Type{<:AbstractWorld}}(frametype.(eachmodality(X)))

function instances(
    X::MultiLogiset,
    inds::AbstractVector{<:Integer},
    return_view::Union{Val{true},Val{false}} = Val(false);
    kwargs...
)
    MultiLogiset(map(modality->instances(modality, inds, return_view; kwargs...), eachmodality(X)))
end

function concatdatasets(Xs::MultiLogiset...)
    @assert allequal(nmodalities.(Xs)) "Cannot concatenate MultiLogiset's with mismatching " *
        "number of modalities: $(nmodalities.(Xs))"
    MultiLogiset([
        concatdatasets([modality(X, i_mod) for X in Xs]...) for i_mod in 1:nmodalities(first(Xs))
    ])
end

function Base.show(io::IO, X::MultiLogiset; kwargs...)
    println(io, displaystructure(X; kwargs...))
end

function displaystructure(X::MultiLogiset; indent_str = "", include_ninstances = true)
    pieces = []
    push!(pieces, "MultiLogiset with $(nmodalities(X)) modalities ($(humansize(X)))")
    # push!(pieces, indent_str * "├ # modalities:\t$(nmodalities(X))")
    if include_ninstances
        push!(pieces, indent_str * "├ # instances:\t$(ninstances(X))")
    end
    # push!(pieces, indent_str * "├ modalitytype:\t$(modalitytype(X))")
    for (i_modality, mod) in enumerate(eachmodality(X))
        out = ""
        if i_modality == nmodalities(X)
            out *= "$(indent_str)└"
        else
            out *= "$(indent_str)├"
        end
        out *= "{$i_modality} "
        # \t\t\t$(humansize(mod))\t(worldtype: $(worldtype(mod)))"
        out *= displaystructure(mod; indent_str = indent_str * (i_modality == nmodalities(X) ? "  " : "│ "), include_ninstances = false)
        push!(pieces, out)
    end
    return join(pieces, "\n")
end


function featvalue(
    X::MultiLogiset,
    i_modality::Integer,
    i_instance::Integer,
    w::W,
    f::AbstractFeature;
    kwargs...
) where {W<:AbstractWorld}
    featvalue(modality(X, i_modality), i_instance, w, f)
end


hasnans(X::MultiLogiset) = any(hasnans.(eachmodality(X)))

isminifiable(X::MultiLogiset) = any(isminifiable.(eachmodality(X)))

function minify(X::MultiLogiset)
    if !any(map(isminifiable, eachmodality(X)))
        if !all(map(isminifiable, eachmodality(X)))
            error("Cannot perform minification with modalities " *
                "of types $(typeof.(eachmodality(X))). Please use a " *
                "minifiable format (e.g., SupportedLogiset).")
        else
            @warn "Cannot perform minification on some of the modalities " *
                "provided. Please use a minifiable format (e.g., " *
                "SupportedLogiset) ($(typeof.(eachmodality(X))) were used instead)."
        end
    end
    X, backmap = zip([!isminifiable(X) ? minify(X) : (X, identity) for X in eachmodality(X)]...)
    X, backmap
end

############################################################################################

function featvalue(
    f::AbstractFeature,
    X::MultiLogiset,
    i_modality::Integer,
    i_instance::Integer,
    w::W;
    kwargs...
) where {W<:AbstractWorld}
    featvalue(X, i_modality, i_instance, w, f)
end

# TODO remove:

# Base.size(X::MultiLogiset)                      = map(size, eachmodality(X))

# # maxchannelsize(X::MultiLogiset) = map(maxchannelsize, eachmodality(X)) # TODO: figure if this is useless or not. Note: channelsize doesn't make sense at this point.
# nfeatures(X::MultiLogiset) = map(nfeatures, eachmodality(X)) # Note: used for safety checks in fit_tree.jl
# # nrelations(X::MultiLogiset) = map(nrelations, eachmodality(X)) # TODO: figure if this is useless or not
# nfeatures(X::MultiLogiset,  i_modality::Integer) = nfeatures(modality(X, i_modality))
# nrelations(X::MultiLogiset, i_modality::Integer) = nrelations(modality(X, i_modality))
# Base.length(X::MultiLogiset) = length(nmodalities(X))
# Base.push!(X::MultiLogiset, f::AbstractLogiset) = push!(eachmodality(X), f)
# Base.getindex(X::MultiLogiset, i_modality::Integer) = modality(X, i_modality)
# Base.iterate(X::MultiLogiset, state=1)   = state > nmodalities(X) ? nothing : (modality(X, state), state+1)

############################################################################################

function check(
    φ::SoleLogics.Formula,
    X::MultiLogiset,
    i_modality::Integer,
    i_instance::Integer,
    args...;
    kwargs...,
)
    check(φ, modality(X, i_modality), i_instance, args...; kwargs...)
end

############################################################################################

using SoleLogics: Formula, AbstractSyntaxStructure, Operator
import SoleLogics: syntaxstring, joinformulas

import SoleLogics: tree
import SoleLogics: normalize

"""
    struct MultiFormula{F<:Formula} <: AbstractSyntaxStructure
        modforms::Dict{Int,F}
    end

A symbolic antecedent that can be checked on a `MultiLogiset`, associating
antecedents to modalities.
"""
struct MultiFormula{F<:Formula} <: AbstractSyntaxStructure
    modforms::Dict{Int,F}
end

subformulatype(::Type{<:M}) where {F,M<:MultiFormula{F}} = F
subformulatype(::MultiFormula{F}) where {F} = F

function SoleLogics.tree(f::MultiFormula)
    return error("Cannot convert object of type $(typeof(f)) to a SyntaxTree.")
end

modforms(f::MultiFormula) = f.modforms

function MultiFormula(i_modality::Integer, modant::Formula)
    F = eval(nameof(typeof(modant)))
    MultiFormula(Dict{Int,F}(i_modality => modant))
end

function syntaxstring(
    f::MultiFormula;
    hidemodality = false,
    variable_names_map::Union{Nothing,AbstractDict,AbstractVector,AbstractVector{<:Union{AbstractDict,AbstractVector}}} = nothing,
    kwargs...
)
    map_is_multimodal = begin
        if !isnothing(variable_names_map) && all(e->!(e isa Union{AbstractDict,AbstractVector}), variable_names_map)
            @warn "With multimodal formulas, variable_names_map should be a vector of vectors/maps of " *
                "variable names. Got $(typeof(variable_names_map)) instead. This may fail, " *
                "or lead to unexpected results."
            false
        else
            !isnothing(variable_names_map)
        end
    end
    join([begin
        _variable_names_map = map_is_multimodal ? variable_names_map[i_modality] : variable_names_map
        φ = syntaxstring(modforms(f)[i_modality]; variable_names_map = _variable_names_map, kwargs...)
        hidemodality ? "$φ" : "{$(i_modality)}($φ)"
    end for i_modality in sort(collect(keys(modforms(f))))], " $(CONJUNCTION) ")
end

function joinformulas(op::typeof(∧), children::NTuple{N,MultiFormula}) where {N}
    F = eval(nameof(SoleBase._typejoin(subformulatype.(children)...)))
    new_formulas = Dict{Int,F}()
    i_modalities = unique(vcat(collect.(keys.([modforms(ch) for ch in children]))...))
    for i_modality in i_modalities
        chs = filter(ch->haskey(modforms(ch), i_modality), children)
        fs = map(ch->modforms(ch)[i_modality], chs)
        new_formulas[i_modality] = (length(fs) == 1 ? first(fs) : joinformulas(op, fs))
    end
    return MultiFormula(new_formulas)
end

# function joinformulas(op::typeof(¬), children::NTuple{N,MultiFormula{F}}) where {N,F}
#     if length(children) > 1
#         error("Cannot negate $(length(children)) MultiFormula's.")
#     end
#     f = first(children)
#     ks = keys(modforms(f))
#     if length(ks) != 1
#         error("Cannot negate a $(length(ks))-MultiFormula.")
#     end
#     i_modality = first(ks)
#     MultiFormula(i_modality, ¬(modforms(f)[i_modality]))
# end
function joinformulas(op::Operator, children::NTuple{N,MultiFormula}) where {N}
    if !all(c->length(modforms(c)) == 1, children)
        error("Cannot join $(length(children)) MultiFormula's by means of $(op). " *
            "$(children)\n" *
            "$(map(c->length(modforms(c)), children)).")
    end
    ks = map(c->first(keys(modforms(c))), children)
    if !allequal(ks)
        error("Cannot join $(length(children)) MultiFormula's by means of $(op)." *
            "Found different modalities: $(unique(ks)).")
    end
    i_modality = first(ks)
    MultiFormula(i_modality, joinformulas(op, map(c->modforms(c)[i_modality], children)))
end

function SoleLogics.normalize(φ::MultiFormula{F}; kwargs...) where {F<:Formula}
    MultiFormula(Dict{Int,F}([i_modality => SoleLogics.normalize(f; kwargs...) for (i_modality,f) in pairs(modforms(φ))]))
end

function check(
    φ::MultiFormula,
    X::MultiLogiset,
    i_instance::Integer,
    args...;
    kwargs...,
)
    # TODO in the fuzzy case: use collatetruth(∧, fuzzy truth values...)
    all([check(f, X, i_modality, i_instance, args...; kwargs...)
        for (i_modality, f) in modforms(φ)])
end

# # TODO join MultiFormula leads to a SyntaxTree with MultiFormula children
# function joinformulas(op::Operator, children::NTuple{N,MultiFormula{F}}) where {N,F}
# end
