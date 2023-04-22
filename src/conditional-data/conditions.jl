using SoleLogics: AbstractAlphabet
using Random
import SoleLogics: negation

import Base: isequal, hash, in, iterate, isfinite, length
import StatsBase: sample

abstract type AbstractCondition end # TODO parametric?

function syntaxstring(c::AbstractCondition; kwargs...)
    error("Please, provide method syntaxstring(::$(typeof(c)); kwargs...). Note that this value must be unique.")
end

Base.isequal(a::AbstractCondition, b::AbstractCondition) = syntaxstring(a) == syntaxstring(b) # nameof(x) == nameof(feature)
Base.hash(a::AbstractCondition) = Base.hash(syntaxstring(a))

############################################################################################

# TODO add TruthType: T as in:
#  struct FeatMetaCondition{F<:AbstractFeature,T,O<:TestOperatorFun} <: AbstractCondition
struct FeatMetaCondition{F<:AbstractFeature,O<:TestOperatorFun} <: AbstractCondition

  # Feature: a scalar function that can be computed on a world
  feature::F

  # Test operator (e.g. ≥)
  test_operator::O

end

feature(m::FeatMetaCondition) = m.feature
test_operator(m::FeatMetaCondition) = m.test_operator

syntaxstring(m::FeatMetaCondition; kwargs...) =
    "$(_syntaxstring_feature_test_operator_pair(feature(m),test_operator(m); kwargs...)) ⍰"

############################################################################################

struct FeatCondition{U,M<:FeatMetaCondition} <: AbstractCondition

  # Metacondition
  metacond::M

  # Threshold value
  a::U

  function FeatCondition(
      metacond       :: M,
      a              :: U
  ) where {M<:FeatMetaCondition,U}
      new{U,M}(metacond, a)
  end

  function FeatCondition(
      condition      :: FeatCondition{U,M},
      a              :: U
  ) where {M<:FeatMetaCondition,U}
      new{U,M}(condition.metacond, a)
  end

  function FeatCondition(
      feature       :: AbstractFeature,
      test_operator :: TestOperatorFun,
      threshold     :: U
  ) where {U}
      metacond = FeatMetaCondition(feature, test_operator)
      FeatCondition(metacond, threshold)
  end
end

metacond(c::FeatCondition) = c.metacond
threshold(c::FeatCondition) = c.a

feature(c::FeatCondition) = feature(metacond(c))
test_operator(c::FeatCondition) = test_operator(metacond(c))

function negation(c::FeatCondition)
    FeatCondition(feature(c), test_operator_inverse(test_operator(c)), threshold(c))
end

syntaxstring(m::FeatCondition; threshold_decimals = nothing, kwargs...) =
    "$(_syntaxstring_feature_test_operator_pair(feature(m), test_operator(m))) $((isnothing(threshold_decimals) ? threshold(m) : round(threshold(m); digits=threshold_decimals)))"

############################################################################################

"""
    abstract type AbstractConditionalAlphabet{M<:FeatMetaCondition} <: AbstractAlphabet{M} end

Abstract type for alphabets of conditions.

See also
[`FeatCondition`](@ref),
[`FeatMetaCondition`](@ref),
[`AbstractAlphabet`](@ref).
"""
abstract type AbstractConditionalAlphabet{M<:FeatMetaCondition} <: AbstractAlphabet{M} end

"""
    struct UnboundedExplicitConditionalAlphabet{M<:FeatMetaCondition} <: AbstractConditionalAlphabet{M}
        metaconditions::Vector{M}
    end

An infinite alphabet of conditions induced from a finite set of metaconditions.
For example, if `metaconditions = [FeatMetaCondition(SingleAttributeMin(1), ≥)]`,
the alphabet represents the (infinite) set: \${min(V1) ≥ a, a ∈ ℝ}\$. # TODO display math

See also
[`BoundedExplicitConditionalAlphabet`](@ref),
[`FeatCondition`](@ref),
[`FeatMetaCondition`](@ref),
[`AbstractAlphabet`](@ref).
"""
struct UnboundedExplicitConditionalAlphabet{M<:FeatMetaCondition} <: AbstractConditionalAlphabet{M}
    metaconditions::Vector{M}

    function UnboundedExplicitConditionalAlphabet{M}(
        metaconditions::Vector{M}
    ) where {M<:FeatMetaCondition}
        new{M}(metaconditions)
    end

    function UnboundedExplicitConditionalAlphabet(
        metaconditions::Vector{M}
    ) where {M<:FeatMetaCondition}
        UnboundedExplicitConditionalAlphabet{M}(metaconditions)
    end

    function UnboundedExplicitConditionalAlphabet(
        features       :: Vector,
        test_operators :: Vector,
    )
        metaconditions =
            [FeatMetaCondition(f,t) for f in features for t in test_operators]
        UnboundedExplicitConditionalAlphabet(metaconditions)
    end
end

Base.isfinite(::Type{<:UnboundedExplicitConditionalAlphabet}) = false
Base.isiterable(::Type{<:UnboundedExplicitConditionalAlphabet}) = false

# Finite alphabet of conditions induced from a set of metaconditions
struct BoundedExplicitConditionalAlphabet{M<:FeatMetaCondition} <: AbstractConditionalAlphabet{M}
    featconditions::Vector{Tuple{M,Vector}}

    function BoundedExplicitConditionalAlphabet{M}(
        featconditions::Vector{Tuple{M,Vector}}
    ) where {M<:FeatMetaCondition}
        new{M}(featconditions)
    end

    function BoundedExplicitConditionalAlphabet(
        metaconditions::Vector{<:FeatMetaCondition},
        thresholds::Vector{<:Vector},
    )
        length(metaconditions) != length(thresholds) &&
            error("Can't instantiate BoundedExplicitConditionalAlphabet with mismatching" *
                " number of `metaconditions` and `thresholds`" *
                " ($(metaconditions) != $(thresholds)).")
        featconditions = collect(zip(metaconditions, thresholds))
        M = SoleBase._typejoin(typeof.(metaconditions)...)
        BoundedExplicitConditionalAlphabet{M}(featconditions)
    end

    function BoundedExplicitConditionalAlphabet(
        features       :: Vector,
        test_operators :: Vector,
        thresholds     :: Vector
    )
        metaconditions =
            [FeatMetaCondition(f,t) for f in features for t in test_operators]
        BoundedExplicitConditionalAlphabet(metaconditions,thresholds)
    end
end

featconditions(a::BoundedExplicitConditionalAlphabet) = a.featconditions

propositions(a::BoundedExplicitConditionalAlphabet) =
    reduce(vcat, map(
        mc_thresholds->
            map(threshold->FeatCondition(first(mc_thresholds), threshold),
            last(mc_thresholds)),
        featconditions(a)))

function Base.in(fc::FeatCondition, a::BoundedExplicitConditionalAlphabet)
    featconds = featconditions(a)
    idx = findfirst(mc_thresholds->first(mc_thresholds)==metacond(fc), featconds)
    return !isnothing(idx) && Base.in(threshold(fc), last(featconds[idx]))
end

Base.iterate(a::BoundedExplicitConditionalAlphabet) = Base.iterate(propositions(a))
function Base.iterate(a::BoundedExplicitConditionalAlphabet, state)
    return Base.iterate(propositions(a), state)
end

Base.isfinite(::Type{BoundedExplicitConditionalAlphabet}) = true
Base.isfinite(a::BoundedExplicitConditionalAlphabet) = Base.isfinite(typeof(a))

Base.length(a::BoundedExplicitConditionalAlphabet) = length(propositions(a))

############################################################################################

function _syntaxstring_feature_test_operator_pair(
    feature::AbstractFeature,
    test_operator::TestOperatorFun;
    use_feature_abbreviations::Bool = false,
    kwargs...,
)
    if use_feature_abbreviations
        _syntaxstring_feature_test_operator_pair_abbr(feature, test_operator; kwargs...)
    else
        "$(syntaxstring(feature; kwargs...)) $(test_operator)"
    end
end

_syntaxstring_feature_test_operator_pair_abbr(feature::SingleAttributeMin,     test_operator::typeof(≥); kwargs...)        = "$(attribute_name(feature; kwargs...)) ⪴"
_syntaxstring_feature_test_operator_pair_abbr(feature::SingleAttributeMax,     test_operator::typeof(≤); kwargs...)        = "$(attribute_name(feature; kwargs...)) ⪳"
_syntaxstring_feature_test_operator_pair_abbr(feature::SingleAttributeSoftMin, test_operator::typeof(≥); kwargs...)        = "$(attribute_name(feature; kwargs...)) $("⪴" * utils.subscriptnumber(rstrip(rstrip(string(alpha(feature)*100), '0'), '.')))"
_syntaxstring_feature_test_operator_pair_abbr(feature::SingleAttributeSoftMax, test_operator::typeof(≤); kwargs...)        = "$(attribute_name(feature; kwargs...)) $("⪳" * utils.subscriptnumber(rstrip(rstrip(string(alpha(feature)*100), '0'), '.')))"

_syntaxstring_feature_test_operator_pair_abbr(feature::SingleAttributeMin,     test_operator::typeof(<); kwargs...)        = "$(attribute_name(feature; kwargs...)) ⪶"
_syntaxstring_feature_test_operator_pair_abbr(feature::SingleAttributeMax,     test_operator::typeof(>); kwargs...)        = "$(attribute_name(feature; kwargs...)) ⪵"
_syntaxstring_feature_test_operator_pair_abbr(feature::SingleAttributeSoftMin, test_operator::typeof(<); kwargs...)        = "$(attribute_name(feature; kwargs...)) $("⪶" * utils.subscriptnumber(rstrip(rstrip(string(alpha(feature)*100), '0'), '.')))"
_syntaxstring_feature_test_operator_pair_abbr(feature::SingleAttributeSoftMax, test_operator::typeof(>); kwargs...)        = "$(attribute_name(feature; kwargs...)) $("⪵" * utils.subscriptnumber(rstrip(rstrip(string(alpha(feature)*100), '0'), '.')))"

_syntaxstring_feature_test_operator_pair_abbr(feature::SingleAttributeMin,     test_operator::typeof(≤); kwargs...)        = "$(attribute_name(feature; kwargs...)) ↘"
_syntaxstring_feature_test_operator_pair_abbr(feature::SingleAttributeMax,     test_operator::typeof(≥); kwargs...)        = "$(attribute_name(feature; kwargs...)) ↗"
_syntaxstring_feature_test_operator_pair_abbr(feature::SingleAttributeSoftMin, test_operator::typeof(≤); kwargs...)        = "$(attribute_name(feature; kwargs...)) $("↘" * utils.subscriptnumber(rstrip(rstrip(string(alpha(feature)*100), '0'), '.')))"
_syntaxstring_feature_test_operator_pair_abbr(feature::SingleAttributeSoftMax, test_operator::typeof(≥); kwargs...)        = "$(attribute_name(feature; kwargs...)) $("↗" * utils.subscriptnumber(rstrip(rstrip(string(alpha(feature)*100), '0'), '.')))"
