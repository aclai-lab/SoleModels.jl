using SoleLogics: AbstractKripkeStructure, AbstractInterpretationSet, AbstractFrame
using SoleLogics: TruthValue
import SoleLogics: alphabet, frame, check
import SoleLogics: accessibles, allworlds, nworlds, initialworld
import SoleLogics: worldtype, frametype

"""
    abstract type AbstractLogiset{
        W<:AbstractWorld,
        F<:AbstractFeature,
        T<:TruthValue,
        FR<:AbstractFrame{W,T},
    } <: AbstractInterpretationSet{AbstractKripkeStructure{W,C where C<:AbstractCondition{F},T,FR}} end

Abstract type for logisets, that is, logical datasets for
symbolic learning where each instance is a
[Kripke structure](https://en.wikipedia.org/wiki/Kripke_structure_(model_checking))
on features. Conditions (see [`AbstractCondition`](@ref)), and logical formulas
with conditional letters can be checked on (worlds of) instances of the dataset.

Logisets have an associated alphabet, set of features and set of relations.

See also
[`AbstractCondition`](@ref),
[`AbstractFeature`](@ref),
[`AbstractKripkeStructure`](@ref),
[`AbstractInterpretationSet`](@ref).
"""
abstract type AbstractLogiset{
    W<:AbstractWorld,
    V,
    F<:AbstractFeature{V},
    T<:TruthValue,
    FR<:AbstractFrame{W,T},
} <: AbstractInterpretationSet{AbstractKripkeStructure{W,C where C<:AbstractCondition{_F where _F<:F},T,FR}} end

function evaluatecondition(
    X::AbstractLogiset{W,V,F,T},
    i_sample,
    w::W,
    c::AbstractCondition,
)::T where {W<:AbstractWorld,V,F<:AbstractFeature{V},T<:TruthValue}
    error("Please, provide method evaluatecondition(X::$(typeof(X)), i_sample::$(typeof(i_sample)), w::$(typeof(w)), c::$(typeof(c))).")
end

function check(
    f::AbstractFormula,
    X::AbstractLogiset{W,V,F,T},
    i_sample,
    w::W,
)::T where {W<:AbstractWorld,V,F<:AbstractFeature{V},T<:TruthValue}
    # TODO implement once for all.
    error("Please, provide method check(f::$(typeof(f)), X::$(typeof(X)), i_sample::$(typeof(i_sample)), w::$(typeof(w))).")
end

function displaystructure(X::AbstractLogiset; kwargs...)::String
    error("Please, provide method displaystructure(X::$(typeof(X)); kwargs...)::String.")
end

function check(
    p::Proposition{A},
    X::AbstractLogiset{W,V,F,T},
    i_sample,
    w::W,
)::T where {W<:AbstractWorld,V,F<:AbstractFeature{V},T<:TruthValue,A<:AbstractCondition}
    cond = atom(p)
    evaluatecondition(X, i_sample, w, cond)
end

function Base.show(io::IO, X::AbstractLogiset; kwargs...)
    println(io, displaystructure(X; kwargs...))
end

############################################################################################

featvaltype(::Type{<:AbstractLogiset{W,V}}) where {W<:AbstractWorld,V} = V
featvaltype(d::AbstractLogiset) = featvaltype(typeof(d))

featuretype(::Type{<:AbstractLogiset{W,V,F}}) where {W<:AbstractWorld,V,F<:AbstractFeature} = F
featuretype(d::AbstractLogiset) = featuretype(typeof(d))

function features(X::AbstractLogiset)
    return error("Please, provide method features(::$(typeof(X))).")
end

function featvalue(
    X::AbstractLogiset{W},
    i_sample,
    w::W,
    f::AbstractFeature,
) where {W<:AbstractWorld}
    error("Please, provide method featvalue(::$(typeof(X)), i_sample::$(typeof(i_sample)), w::$(typeof(w)), f::$(typeof(f))).")
end

isminifiable(::AbstractLogiset) = false

function initialworld(
    X::AbstractLogiset{W,V,F,T},
    i_sample
) where {W<:AbstractWorld,V,F<:AbstractFeature{V},T<:TruthValue}
    error("Please, provide method initialworld(::$(typeof(X)), i_sample::$(typeof(i_sample))).")
end

representatives(X::AbstractLogiset, i_sample, args...) = representatives(frame(X, i_sample), args...)

############################################################################################
# Helpers
############################################################################################

function findfeature(X::AbstractLogiset, feature::AbstractFeature)
    id = findfirst(x->(Base.isequal(x, feature)), features(X))
    if isnothing(id)
        error("Could not find feature $(feature) in AbstractLogiset of type $(typeof(X)).")
    end
    id
end
function findrelation(X::AbstractLogiset, relation::AbstractRelation)
    id = findfirst(x->x==relation, relations(X))
    if isnothing(id)
        error("Could not find relation $(relation) in AbstractLogiset of type $(typeof(X)).")
    end
    id
end
