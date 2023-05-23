using SoleLogics: AbstractKripkeStructure, AbstractInterpretationSet, AbstractFrame
import SoleLogics: frame, check
import SoleLogics: accessibles, allworlds, nworlds, initialworld
import SoleLogics: worldtype, frametype
export check, accessibles, allworlds, representatives

"""
    abstract type AbstractConditionalDataset{
        W<:AbstractWorld,
        A<:AbstractCondition,
        T<:TruthValue,
        FR<:AbstractFrame{W,T},
    } <: AbstractInterpretationSet{AbstractKripkeStructure{W,A,T,FR}} end

Abstract type for conditional datasets, that is,
symbolic learning datasets where each instance is a Kripke model
where conditions (see [`AbstractCondition`](@ref)), and logical formulas
with conditional letters can be checked on worlds.

See also
[`AbstractInterpretationSet`](@ref),
[`AbstractCondition`](@ref).
"""
abstract type AbstractConditionalDataset{
    W<:AbstractWorld,
    A<:AbstractCondition,
    T<:TruthValue,
    FR<:AbstractFrame{W,T},
} <: AbstractInterpretationSet{AbstractKripkeStructure{W,A,T,FR}} end

representatives(X::AbstractConditionalDataset, i_sample, args...) = representatives(frame(X, i_sample), args...)

# TODO initialworld is at model-level, not at frame-level?
function initialworld(
    X::AbstractConditionalDataset{W,A,T},
    i_sample
) where {W<:AbstractWorld,A<:AbstractCondition,T<:TruthValue}
    error("Please, provide method initialworld(::$(typeof(X)), i_sample::$(typeof(i_sample))).")
end

function check(
    p::Proposition{A},
    X::AbstractConditionalDataset{W,AA,T},
    i_sample,
    w::W,
)::T where {W<:AbstractWorld,AA<:AbstractCondition,T<:TruthValue,A<:AA}
    error("Please, provide method check(p::$(typeof(p)), X::$(typeof(X)), i_sample::$(typeof(i_sample)), w::$(typeof(w))).")
end

function check(
    f::AbstractFormula,
    X::AbstractConditionalDataset{W,A,T},
    i_sample,
    w::W,
)::T where {W<:AbstractWorld,A<:AbstractCondition,T<:TruthValue}
    error("Please, provide method check(f::$(typeof(f)), X::$(typeof(X)), i_sample::$(typeof(i_sample)), w::$(typeof(w))).")
end

"""
    abstract type AbstractActiveConditionalDataset{
        W<:AbstractWorld,
        A<:AbstractCondition,
        T<:TruthValue,
        FR<:AbstractFrame{W,T},
    } <: AbstractConditionalDataset{W,A,T,FR} end

Abstract type for active conditional datasets, that is,
conditional datasets that can be used in machine learning algorithms
(e.g., they have an alphabet, can enumerate propositions and learn formulas from).

See also
[`AbstractConditionalDataset`](@ref),
[`AbstractCondition`](@ref).
"""
abstract type AbstractActiveConditionalDataset{
    W<:AbstractWorld,
    A<:AbstractCondition,
    T<:TruthValue,
    FR<:AbstractFrame{W,T},
} <: AbstractConditionalDataset{W,A,T,FR} end

function alphabet(X::AbstractActiveConditionalDataset)
    error("Please, provide method alphabet(::$(typeof(X))).")
end
