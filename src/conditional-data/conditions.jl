
export MixedFeature, CanonicalFeature, canonical_geq, canonical_leq

abstract type CanonicalFeature end

# ⪴ and ⪳, that is, "*all* of the values on this world are at least, or at most ..."
struct CanonicalFeatureGeq <: CanonicalFeature end; const canonical_geq  = CanonicalFeatureGeq();
struct CanonicalFeatureLeq <: CanonicalFeature end; const canonical_leq  = CanonicalFeatureLeq();

export canonical_geq_95, canonical_geq_90, canonical_geq_85, canonical_geq_80, canonical_geq_75, canonical_geq_70, canonical_geq_60,
       canonical_leq_95, canonical_leq_90, canonical_leq_85, canonical_leq_80, canonical_leq_75, canonical_leq_70, canonical_leq_60

# ⪴_α and ⪳_α, that is, "*at least α⋅100 percent* of the values on this world are at least, or at most ..."

struct CanonicalFeatureGeqSoft  <: CanonicalFeature
  alpha :: AbstractFloat
  CanonicalFeatureGeqSoft(a::T) where {T<:Real} = (a > 0 && a < 1) ? new(a) : throw_n_log("Invalid instantiation for test operator: CanonicalFeatureGeqSoft($(a))")
end;
struct CanonicalFeatureLeqSoft  <: CanonicalFeature
  alpha :: AbstractFloat
  CanonicalFeatureLeqSoft(a::T) where {T<:Real} = (a > 0 && a < 1) ? new(a) : throw_n_log("Invalid instantiation for test operator: CanonicalFeatureLeqSoft($(a))")
end;

const canonical_geq_95  = CanonicalFeatureGeqSoft((Rational(95,100)));
const canonical_geq_90  = CanonicalFeatureGeqSoft((Rational(90,100)));
const canonical_geq_85  = CanonicalFeatureGeqSoft((Rational(85,100)));
const canonical_geq_80  = CanonicalFeatureGeqSoft((Rational(80,100)));
const canonical_geq_75  = CanonicalFeatureGeqSoft((Rational(75,100)));
const canonical_geq_70  = CanonicalFeatureGeqSoft((Rational(70,100)));
const canonical_geq_60  = CanonicalFeatureGeqSoft((Rational(60,100)));

const canonical_leq_95  = CanonicalFeatureLeqSoft((Rational(95,100)));
const canonical_leq_90  = CanonicalFeatureLeqSoft((Rational(90,100)));
const canonical_leq_85  = CanonicalFeatureLeqSoft((Rational(85,100)));
const canonical_leq_80  = CanonicalFeatureLeqSoft((Rational(80,100)));
const canonical_leq_75  = CanonicalFeatureLeqSoft((Rational(75,100)));
const canonical_leq_70  = CanonicalFeatureLeqSoft((Rational(70,100)));
const canonical_leq_60  = CanonicalFeatureLeqSoft((Rational(60,100)));


const MixedFeature = Union{AbstractFeature,CanonicalFeature,Function,Tuple{TestOperator,Function},Tuple{TestOperator,AbstractFeature}}

############################################################################################


using SoleLogics: AbstractAlphabet
using Random
import SoleLogics: negation, propositions

import Base: isequal, hash, in, isfinite, length

abstract type AbstractCondition end # TODO parametric?

function syntaxstring(c::AbstractCondition; kwargs...)
    error("Please, provide method syntaxstring(::$(typeof(c)); kwargs...). Note that this value must be unique.")
end

Base.isequal(a::AbstractCondition, b::AbstractCondition) = syntaxstring(a) == syntaxstring(b) # nameof(x) == nameof(feature)
Base.hash(a::AbstractCondition) = Base.hash(syntaxstring(a))

############################################################################################

# TODO add TruthType: T as in:
#  struct FeatMetaCondition{F<:AbstractFeature,T,O<:TestOperator} <: AbstractCondition
struct FeatMetaCondition{F<:AbstractFeature,O<:TestOperator} <: AbstractCondition

  # Feature: a scalar function that can be computed on a world
  feature::F

  # Test operator (e.g. ≥)
  test_operator::O

end

feature(m::FeatMetaCondition) = m.feature
test_operator(m::FeatMetaCondition) = m.test_operator

negation(m::FeatMetaCondition) = FeatMetaCondition(feature(m), inverse_test_operator(test_operator(m)))

syntaxstring(m::FeatMetaCondition; kwargs...) =
    "$(_syntaxstring_feature_test_operator_pair(feature(m), test_operator(m); kwargs...)) ⍰"

############################################################################################

struct FeatCondition{U,M<:FeatMetaCondition} <: AbstractCondition

  # Metacondition
  metacond::M

  # Threshold value
  threshold::U

  function FeatCondition(
      metacond       :: M,
      threshold      :: U
  ) where {M<:FeatMetaCondition,U}
      new{U,M}(metacond, threshold)
  end

  function FeatCondition(
      condition      :: FeatCondition{U,M},
      threshold      :: U
  ) where {M<:FeatMetaCondition,U}
      new{U,M}(condition.metacond, threshold)
  end

  function FeatCondition(
      feature       :: AbstractFeature,
      test_operator :: TestOperator,
      threshold     :: U
  ) where {U}
      metacond = FeatMetaCondition(feature, test_operator)
      FeatCondition(metacond, threshold)
  end
end

metacond(c::FeatCondition) = c.metacond
threshold(c::FeatCondition) = c.threshold

feature(c::FeatCondition) = feature(metacond(c))
test_operator(c::FeatCondition) = test_operator(metacond(c))

negation(c::FeatCondition) = FeatCondition(negation(metacond(c)), threshold(c))

syntaxstring(m::FeatCondition; threshold_decimals = nothing, kwargs...) =
    "$(_syntaxstring_feature_test_operator_pair(feature(m), test_operator(m))) $((isnothing(threshold_decimals) ? threshold(m) : round(threshold(m); digits=threshold_decimals)))"

############################################################################################

"""
    abstract type AbstractConditionalAlphabet{C<:FeatCondition} <: AbstractAlphabet{C} end

Abstract type for alphabets of conditions.

See also
[`FeatCondition`](@ref),
[`FeatMetaCondition`](@ref),
[`AbstractAlphabet`](@ref).
"""
abstract type AbstractConditionalAlphabet{C<:FeatCondition} <: AbstractAlphabet{C} end

"""
    struct UnboundedExplicitConditionalAlphabet{C<:FeatCondition} <: AbstractConditionalAlphabet{C}
        metaconditions::Vector{<:FeatMetaCondition}
    end

An infinite alphabet of conditions induced from a finite set of metaconditions.
For example, if `metaconditions = [FeatMetaCondition(UnivariateMin(1), ≥)]`,
the alphabet represents the (infinite) set: \${min(V1) ≥ a, a ∈ ℝ}\$. # TODO display math

See also
[`BoundedExplicitConditionalAlphabet`](@ref),
[`FeatCondition`](@ref),
[`FeatMetaCondition`](@ref),
[`AbstractAlphabet`](@ref).
"""
struct UnboundedExplicitConditionalAlphabet{C<:FeatCondition} <: AbstractConditionalAlphabet{C}
    metaconditions::Vector{<:FeatMetaCondition}

    function UnboundedExplicitConditionalAlphabet{C}(
        metaconditions::Vector{<:FeatMetaCondition}
    ) where {C<:FeatCondition}
        new{C}(metaconditions)
    end

    function UnboundedExplicitConditionalAlphabet(
        features       :: AbstractVector{C},
        test_operators :: AbstractVector,
    ) where {C<:FeatCondition}
        metaconditions =
            [FeatMetaCondition(f, t) for f in features for t in test_operators]
        UnboundedExplicitConditionalAlphabet{C}(metaconditions)
    end
end

Base.isfinite(::Type{<:UnboundedExplicitConditionalAlphabet}) = false

function Base.in(p::Proposition{<:FeatCondition}, a::UnboundedExplicitConditionalAlphabet)
    fc = atom(p)
    idx = findfirst(mc->mc == metacond(fc), a.metaconditions)
    return !isnothing(idx)
end

"""
    struct BoundedExplicitConditionalAlphabet{C<:FeatCondition} <: AbstractConditionalAlphabet{C}
        grouped_featconditions::Vector{Tuple{<:FeatMetaCondition,Vector}}
    end

A finite alphabet of conditions, grouped by (a finite set of) metaconditions.

See also
[`UnboundedExplicitConditionalAlphabet`](@ref),
[`FeatCondition`](@ref),
[`FeatMetaCondition`](@ref),
[`AbstractAlphabet`](@ref).
"""
# Finite alphabet of conditions induced from a set of metaconditions
struct BoundedExplicitConditionalAlphabet{C<:FeatCondition} <: AbstractConditionalAlphabet{C}
    grouped_featconditions::Vector{<:Tuple{FeatMetaCondition,Vector}}

    function BoundedExplicitConditionalAlphabet{C}(
        grouped_featconditions::Vector{<:Tuple{FeatMetaCondition,Vector}}
    ) where {C<:FeatCondition}
        new{C}(grouped_featconditions)
    end

    function BoundedExplicitConditionalAlphabet{C}(
        metaconditions::Vector{<:FeatMetaCondition},
        thresholds::Vector{<:Vector},
    ) where {C<:FeatCondition}
        length(metaconditions) != length(thresholds) &&
            error("Can't instantiate BoundedExplicitConditionalAlphabet with mismatching" *
                " number of `metaconditions` and `thresholds`" *
                " ($(metaconditions) != $(thresholds)).")
        grouped_featconditions = collect(zip(metaconditions, thresholds))
        # M = SoleBase._typejoin(typeof.(metaconditions)...)
        BoundedExplicitConditionalAlphabet{C}(grouped_featconditions)
    end

    function BoundedExplicitConditionalAlphabet(
        features       :: AbstractVector{C},
        test_operators :: AbstractVector,
        thresholds     :: Vector
    ) where {C<:FeatCondition}
        metaconditions =
            [FeatMetaCondition(f, t) for f in features for t in test_operators]
        BoundedExplicitConditionalAlphabet{C}(metaconditions, thresholds)
    end
end

function propositions(a::BoundedExplicitConditionalAlphabet)
    Iterators.flatten(
        map(
            ((mc,thresholds),)->map(
                threshold->Proposition(FeatCondition(mc, threshold)),
                thresholds),
            a.grouped_featconditions
        )
    ) |> collect
end

function Base.in(p::Proposition{<:FeatCondition}, a::BoundedExplicitConditionalAlphabet)
    fc = atom(p)
    grouped_featconditions = a.grouped_featconditions
    idx = findfirst(((mc,thresholds),)->mc == metacond(fc), grouped_featconditions)
    return !isnothing(idx) && Base.in(threshold(fc), last(grouped_featconditions[idx]))
end

############################################################################################

function _syntaxstring_feature_test_operator_pair(
    feature::AbstractFeature,
    test_operator::TestOperator;
    use_feature_abbreviations::Bool = false,
    kwargs...,
)
    if use_feature_abbreviations
        _syntaxstring_feature_test_operator_pair_abbr(feature, test_operator; kwargs...)
    else
        "$(syntaxstring(feature; kwargs...)) $(test_operator)"
    end
end

_syntaxstring_feature_test_operator_pair_abbr(feature::UnivariateMin,     test_operator::typeof(≥); kwargs...)        = "$(attribute_name(feature; kwargs...)) ⪴"
_syntaxstring_feature_test_operator_pair_abbr(feature::UnivariateMax,     test_operator::typeof(≤); kwargs...)        = "$(attribute_name(feature; kwargs...)) ⪳"
_syntaxstring_feature_test_operator_pair_abbr(feature::UnivariateSoftMin, test_operator::typeof(≥); kwargs...)        = "$(attribute_name(feature; kwargs...)) $("⪴" * utils.subscriptnumber(rstrip(rstrip(string(alpha(feature)*100), '0'), '.')))"
_syntaxstring_feature_test_operator_pair_abbr(feature::UnivariateSoftMax, test_operator::typeof(≤); kwargs...)        = "$(attribute_name(feature; kwargs...)) $("⪳" * utils.subscriptnumber(rstrip(rstrip(string(alpha(feature)*100), '0'), '.')))"

_syntaxstring_feature_test_operator_pair_abbr(feature::UnivariateMin,     test_operator::typeof(<); kwargs...)        = "$(attribute_name(feature; kwargs...)) ⪶"
_syntaxstring_feature_test_operator_pair_abbr(feature::UnivariateMax,     test_operator::typeof(>); kwargs...)        = "$(attribute_name(feature; kwargs...)) ⪵"
_syntaxstring_feature_test_operator_pair_abbr(feature::UnivariateSoftMin, test_operator::typeof(<); kwargs...)        = "$(attribute_name(feature; kwargs...)) $("⪶" * utils.subscriptnumber(rstrip(rstrip(string(alpha(feature)*100), '0'), '.')))"
_syntaxstring_feature_test_operator_pair_abbr(feature::UnivariateSoftMax, test_operator::typeof(>); kwargs...)        = "$(attribute_name(feature; kwargs...)) $("⪵" * utils.subscriptnumber(rstrip(rstrip(string(alpha(feature)*100), '0'), '.')))"

_syntaxstring_feature_test_operator_pair_abbr(feature::UnivariateMin,     test_operator::typeof(≤); kwargs...)        = "$(attribute_name(feature; kwargs...)) ↘"
_syntaxstring_feature_test_operator_pair_abbr(feature::UnivariateMax,     test_operator::typeof(≥); kwargs...)        = "$(attribute_name(feature; kwargs...)) ↗"
_syntaxstring_feature_test_operator_pair_abbr(feature::UnivariateSoftMin, test_operator::typeof(≤); kwargs...)        = "$(attribute_name(feature; kwargs...)) $("↘" * utils.subscriptnumber(rstrip(rstrip(string(alpha(feature)*100), '0'), '.')))"
_syntaxstring_feature_test_operator_pair_abbr(feature::UnivariateSoftMax, test_operator::typeof(≥); kwargs...)        = "$(attribute_name(feature; kwargs...)) $("↗" * utils.subscriptnumber(rstrip(rstrip(string(alpha(feature)*100), '0'), '.')))"
