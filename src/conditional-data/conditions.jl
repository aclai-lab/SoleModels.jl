using SoleLogics: AbstractAlphabet

abstract type AbstractCondition end # TODO parametric?

# Base.show(io::IO, m::AbstractCondition) = print(io, "$(syntaxstring(m))")

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
    "$(_syntaxstring_feature_test_operator_pair(feature(m),test_operator(m))) ⍰"

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

# TODO fix: here, I'm assuming that metacondition isa FeatMetaCondition
feature(c::FeatCondition) = feature(c.metacond)
test_operator(c::FeatCondition) = test_operator(c.metacond)
threshold(c::FeatCondition) = c.a

function inverse(c::FeatCondition)
    FeatCondition(feature(decision), test_operator_inverse(test_operator(decision)), threshold(decision))
end

syntaxstring(m::FeatCondition; threshold_decimals = nothing, kwargs...) =
    "$(_syntaxstring_feature_test_operator_pair(feature(m), test_operator(m))) $((isnothing(threshold_decimals) ? threshold(m) : round(threshold(m); digits=threshold_decimals)))"

# Alphabet of conditions
abstract type AbstractConditionalAlphabet{M,C<:FeatCondition{M}} <: AbstractAlphabet{C} end

# Infinite alphabet of conditions induced from a set of metaconditions
struct ExplicitConditionalAlphabet{M,C<:FeatCondition{M}} <: AbstractConditionalAlphabet{M,C}
  metaconditions::Vector{M}
end

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
