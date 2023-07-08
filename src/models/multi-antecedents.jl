
using SoleLogics: AbstractFormula, AbstractSyntaxStructure, AbstractOperator
import SoleLogics: syntaxstring, joinformulas

import SoleLogics: tree
import SoleLogics: normalize

"""
    struct MultiAntecedent{F<:AbstractFormula} <: AbstractSyntaxStructure
        modants::Dict{Int,F}
    end

A symbolic antecedent that can be checked on a `MultiLogiset`, associating
antecedents to modalities.
"""
struct MultiAntecedent{F<:AbstractFormula} <: AbstractSyntaxStructure
    modants::Dict{Int,F}
end

modants(f::MultiAntecedent) = f.modants

function MultiAntecedent(i_modality::Integer, modant::AbstractFormula)
    MultiAntecedent(Dict{Int,F}(i_modality => modant))
end

function syntaxstring(
    f::MultiAntecedent;
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
        φ = syntaxstring(modants(f)[i_modality]; variable_names_map = _variable_names_map, kwargs...)
        hidemodality ? "$φ" : "{$(i_modality)}($φ)"
    end for i_modality in sort(collect(keys(modants(f))))], " $(CONJUNCTION) ")
end

function joinformulas(op::typeof(∧), children::NTuple{N,MultiAntecedent{F}}) where {N,F}
    new_formulas = Dict{Int,F}()
    i_modalities = unique(vcat(collect.(keys.([modants(ch) for ch in children]))...))
    for i_modality in i_modalities
        chs = filter(ch->haskey(modants(ch), i_modality), children)
        fs = map(ch->modants(ch)[i_modality], chs)
        new_formulas[i_modality] = (length(fs) == 1 ? first(fs) : joinformulas(op, fs))
    end
    return MultiAntecedent(new_formulas)
end

# function joinformulas(op::typeof(¬), children::NTuple{N,MultiAntecedent{F}}) where {N,F}
#     if length(children) > 1
#         error("Cannot negate $(length(children)) MultiAntecedent's.")
#     end
#     f = first(children)
#     ks = keys(modants(f))
#     if length(ks) != 1
#         error("Cannot negate a $(length(ks))-MultiAntecedent.")
#     end
#     i_modality = first(ks)
#     MultiAntecedent(i_modality, ¬(modants(f)[i_modality]))
# end
function joinformulas(op::AbstractOperator, children::NTuple{N,MultiAntecedent{F}}) where {N,F}
    if !all(c->length(modants(c)) == 1, children)
        error("Cannot join $(length(children)) MultiAntecedent's by means of $(op). " *
            "$(children)\n" *
            "$(map(c->length(modants(c)), children)).")
    end
    ks = map(c->first(keys(modants(c))), children)
    if !allequal(ks)
        error("Cannot join $(length(children)) MultiAntecedent's by means of $(op)." *
            "Found different modalities: $(unique(ks)).")
    end
    i_modality = first(ks)
    MultiAntecedent(i_modality, joinformulas(op, map(c->modants(c)[i_modality], children)))
end

function normalize(φ::MultiAntecedent{F}; kwargs...) where {F<:AbstractFormula}
    MultiAntecedent(Dict{Int,F}([i_modality => SoleLogics.normalize(f; kwargs...) for (i_modality,f) in pairs(modants(φ))]))
end

function check(
    φ::MultiAntecedent,
    X::MultiLogiset,
    i_instance::Integer,
    args...;
    kwargs...,
)
    # TODO in the fuzzy case: use collatetruth(fuzzy algebra, ∧, ...)
    all([check(f, X, i_modality, i_instance, args...; kwargs...)
        for (i_modality, f) in modants(φ)])
end

# # TODO join MultiAntecedent leads to a SyntaxTree with MultiAntecedent children
# function joinformulas(op::AbstractOperator, children::NTuple{N,MultiAntecedent{F}}) where {N,F}
# end
