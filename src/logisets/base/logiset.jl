using SoleLogics: AbstractKripkeStructure, AbstractInterpretationSet, AbstractFrame
using SoleLogics: TruthValue
import SoleLogics: alphabet, frame, check
import SoleLogics: accessibles, allworlds, nworlds, initialworld
import SoleLogics: worldtype, frametype

"""
    abstract type AbstractLogiset{
        W<:AbstractWorld,
        U,
        F<:AbstractFeature,
        FR<:AbstractFrame{W},
    } <: AbstractInterpretationSet{AbstractKripkeStructure{W,C where C<:AbstractCondition{_F where _F<:F},T where T<:TruthValue,FR}} end

Abstract type for logisets, that is, logical datasets for
symbolic learning where each instance is a
[Kripke structure](https://en.wikipedia.org/wiki/Kripke_structure_(model_checking))
associating feature values to each world.
Conditions (see [`AbstractCondition`](@ref)), and logical formulas
with conditional letters can be checked on worlds of instances of the dataset.

See also
[`AbstractCondition`](@ref),
[`AbstractFeature`](@ref),
[`AbstractKripkeStructure`](@ref),
[`AbstractInterpretationSet`](@ref).
"""
abstract type AbstractLogiset{
    W<:AbstractWorld,
    U,
    F<:AbstractFeature,
    FR<:AbstractFrame{W},
} <: AbstractInterpretationSet{AbstractKripkeStructure{W,C where C<:AbstractCondition{_F where _F<:F},T where T<:TruthValue,FR}} end

function featvalue(
    X::AbstractLogiset{W},
    i_instance::Integer,
    w::W,
    f::AbstractFeature,
) where {W<:AbstractWorld}
    error("Please, provide method featvalue(::$(typeof(X)), i_instance::$(typeof(i_instance)), w::$(typeof(w)), f::$(typeof(f))).")
end

function frame(X::AbstractLogiset, i_instance::Integer)
    error("Please, provide method frame(::$(typeof(X)), i_instance::$(typeof(i_instance))).")
end

function ninstances(X::AbstractLogiset)
    error("Please, provide method ninstances(::$(typeof(X))).")
end

function allfeatvalues(
    X::AbstractLogiset,
    i_instance,
)
    error("Please, provide method allfeatvalues(::$(typeof(X)), i_instance::$(typeof(i_instance))).")
end

function allfeatvalues(
    X::AbstractLogiset,
    i_instance,
    f,
)
    error("Please, provide method allfeatvalues(::$(typeof(X)), i_instance::$(typeof(i_instance)), f::$(typeof(f))).")
end

function instances(
    X::AbstractLogiset,
    inds::AbstractVector{<:Integer},
    return_view::Union{Val{true},Val{false}} = Val(false);
    kwargs...
)
    error("Please, provide method instances(::$(typeof(X))).")
end

function concatdatasets(Xs::AbstractLogiset...)
    error("Please, provide method concatdatasets(X...::$(typeof(Xs))).")
end

function displaystructure(X::AbstractLogiset; kwargs...)::String
    error("Please, provide method displaystructure(X::$(typeof(X)); kwargs...)::String.")
end

isminifiable(::AbstractLogiset) = false

usesfullmemo(::AbstractLogiset) = false

function allfeatvalues(X::AbstractLogiset)
    unique([allfeatvalues(X, i_instance) for i_instance in 1:ninstances(X)])
end

hasnans(::AbstractLogiset) = any.(isnan, allfeatvalues(X))

############################################################################################

function featvalue(
    f::AbstractFeature,
    X::AbstractLogiset{W},
    i_instance::Integer,
    w::W,
) where {W<:AbstractWorld}
    featvalue(X, i_instance, w, f)
end

function check(
    p::Proposition{<:AbstractCondition},
    X::AbstractLogiset{W},
    i_instance::Integer,
    w::W;
    kwargs...
) where {W<:AbstractWorld}
    checkcondition(atom(p), X, i_instance, w; kwargs...)
end

function Base.show(io::IO, X::AbstractLogiset; kwargs...)
    println(io, displaystructure(X; kwargs...))
end

worldtype(::Type{<:AbstractLogiset{W}}) where {W<:AbstractWorld} = W
worldtype(X::AbstractLogiset) = worldtype(typeof(X))

featvaltype(::Type{<:AbstractLogiset{W,U}}) where {W<:AbstractWorld,U} = U
featvaltype(X::AbstractLogiset) = featvaltype(typeof(X))

featuretype(::Type{<:AbstractLogiset{W,U,F}}) where {W<:AbstractWorld,U,F<:AbstractFeature} = F
featuretype(X::AbstractLogiset) = featuretype(typeof(X))

frametype(::Type{<:AbstractLogiset{W,U,F,FR}}) where {W<:AbstractWorld,U,F<:AbstractFeature,FR<:AbstractFrame} = FR
frametype(X::AbstractLogiset) = frametype(typeof(X))

representatives(X::AbstractLogiset, i_instance::Integer, args...) = representatives(frame(X, i_instance), args...)

############################################################################################


# """
#     abstract type AbstractBaseLogiset{
#         W<:AbstractWorld,
#         U,
#         F<:AbstractFeature,
#         FR<:AbstractFrame{W},
#     } <: AbstractLogiset{W,U,F,FR} end

# (Base) logisets can be associated to support logisets that perform memoization in order
# to speed up model checking times.

# See also
# [`SuportedLogiset`](@ref),
# [`AbstractLogiset`](@ref).
# """
# abstract type AbstractBaseLogiset{
#     W<:AbstractWorld,
#     U,
#     F<:AbstractFeature,
#     FR<:AbstractFrame{W},
# } <: AbstractLogiset{W,U,F,FR} end


"""
    struct ExplicitBooleanLogiset{
        W<:AbstractWorld,
        F<:AbstractFeature,
        FR<:AbstractFrame{W},
    } <: AbstractLogiset{W,Bool,F,FR}

        d :: Vector{Tuple{Dict{W,Vector{F}},FR}}

    end

A logiset where the features are boolean, and where each instance associates to each world
the set of features with `true`.

See also
[`AbstractLogiset`](@ref).
"""
struct ExplicitBooleanLogiset{
    W<:AbstractWorld,
    F<:AbstractFeature,
    FR<:AbstractFrame{W},
    D<:AbstractVector{<:Tuple{<:Dict{<:W,<:Vector{<:F}},<:FR}}
} <: AbstractLogiset{W,Bool,F,FR}

    d :: D

end

ninstances(X::ExplicitBooleanLogiset) = length(X.d)

function featvalue(
    X::ExplicitBooleanLogiset{W},
    i_instance::Integer,
    w::W,
    f::AbstractFeature,
) where {W<:AbstractWorld}
    Base.in(f, X.d[i_instance][1][w])
end


function frame(
    X::ExplicitBooleanLogiset{W},
    i_instance::Integer,
) where {W<:AbstractWorld}
    X.d[i_instance][2]
end

function instances(
    X::ExplicitBooleanLogiset,
    inds::AbstractVector{<:Integer},
    return_view::Union{Val{true},Val{false}} = Val(false);
    kwargs...
)
    ExplicitBooleanLogiset(if return_view == Val(true) @views X.d[inds] else X.d[inds] end)
end

function concatdatasets(Xs::ExplicitBooleanLogiset...)
    ExplicitBooleanLogiset(vcat([X.d for X in Xs]...))
end

function displaystructure(X::ExplicitBooleanLogiset; indent_str = "", include_ninstances = true)
    padattribute(l,r) = string(l) * lpad(r,32+length(string(r))-(length(indent_str)+2+length(l)))
    out = "ExplicitBooleanLogiset ($(humansize(X)))\n"
    out *= indent_str * "├ " * padattribute("worldtype:", worldtype(X)) * "\n"
    out *= indent_str * "├ " * padattribute("featvaltype:", featvaltype(X)) * "\n"
    out *= indent_str * "├ " * padattribute("featuretype:", featuretype(X)) * "\n"
    out *= indent_str * "├ " * padattribute("frametype:", frametype(X)) * "\n"
    if include_ninstances
        out *= indent_str * "├ " * padattribute("# instances:", ninstances(X)) * "\n"
    end
    out *= indent_str * "└ " * padattribute("# world density (countmap):", "$(countmap([nworlds(X, i_instance) for i_instance in 1:ninstances(X)]))") * "\n"
    out
end

function allfeatvalues(X::ExplicitBooleanLogiset)
    [true, false]
end

function allfeatvalues(
    X::ExplicitBooleanLogiset,
    i_instance
)
    [true, false]
end

function allfeatvalues(
    X::ExplicitBooleanLogiset,
    i_instance,
    feature,
)
    [true, false]
end

hasnans(X::ExplicitBooleanLogiset) = false

# TODO "show plot" method


"""
    struct ExplicitLogiset{
        W<:AbstractWorld,
        U,
        F<:AbstractFeature,
        FR<:AbstractFrame{W},
    } <: AbstractLogiset{W,U,F,FR}

        d :: Vector{Tuple{Dict{W,Dict{F,U}},FR}}

    end

A logiset where the features are boolean, and where each instance associates to each world
the set of features with `true`.

See also
[`AbstractLogiset`](@ref).
"""
struct ExplicitLogiset{
    W<:AbstractWorld,
    U,
    F<:AbstractFeature,
    FR<:AbstractFrame{W},
    D<:AbstractVector{<:Tuple{<:Dict{<:W,<:Dict{<:F,<:U}},<:FR}}
} <: AbstractLogiset{W,U,F,FR}

    d :: D

end

ninstances(X::ExplicitLogiset) = length(X.d)

function featvalue(
    X::ExplicitLogiset{W},
    i_instance::Integer,
    w::W,
    f::AbstractFeature,
) where {W<:AbstractWorld}
    X.d[i_instance][1][w][f]
end


function frame(
    X::ExplicitLogiset{W},
    i_instance::Integer,
) where {W<:AbstractWorld}
    X.d[i_instance][2]
end

function instances(
    X::ExplicitLogiset,
    inds::AbstractVector{<:Integer},
    return_view::Union{Val{true},Val{false}} = Val(false);
    kwargs...
)
    ExplicitLogiset(if return_view == Val(true) @views X.d[inds] else X.d[inds] end)
end

function concatdatasets(Xs::ExplicitLogiset...)
    ExplicitBooleanLogiset(vcat([X.d for X in Xs]...))
end

function displaystructure(X::ExplicitLogiset; indent_str = "", include_ninstances = true)
    padattribute(l,r) = string(l) * lpad(r,32+length(string(r))-(length(indent_str)+2+length(l)))
    out = "ExplicitBooleanLogiset ($(humansize(X)))\n"
    out *= indent_str * "├ " * padattribute("worldtype:", "$(worldtype(X))") * "\n"
    out *= indent_str * "├ " * padattribute("featvaltype:", "$(featvaltype(X))") * "\n"
    out *= indent_str * "├ " * padattribute("featuretype:", "$(featuretype(X))") * "\n"
    out *= indent_str * "├ " * padattribute("frametype:", "$(frametype(X))") * "\n"
    if include_ninstances
        out *= indent_str * "├ " * padattribute("# instances:", "$(ninstances(X))") * "\n"
    end
    out *= indent_str * "└ " * padattribute("# world density (countmap):", "$(countmap([nworlds(X, i_instance) for i_instance in 1:ninstances(X)]))") * "\n"
    out
end


# TODO "show plot" method


function allfeatvalues(
    X::ExplicitLogiset{W},
    i_instance,
) where {W<:AbstractWorld}
    unique(collect(Iterators.flatten(values.(values(d[i_instance][1])))))
end

function allfeatvalues(
    X::ExplicitLogiset{W},
    i_instance,
    feature,
) where {W<:AbstractWorld}
    unique([ch[feature] for ch in values(d[i_instance][1])])
end