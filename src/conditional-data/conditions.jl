using SoleLogics: AbstractAlphabet
import SoleLogics: negation

import Base: isequal, hash, in, iterate, isfinite, length, rand

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

# TODO fix: here, I'm assuming that metacondition isa FeatMetaCondition
feature(c::FeatCondition) = feature(c.metacond)
test_operator(c::FeatCondition) = test_operator(c.metacond)
threshold(c::FeatCondition) = c.a

function negation(c::FeatCondition)
    FeatCondition(feature(c), test_operator_inverse(test_operator(c)), threshold(c))
end

syntaxstring(m::FeatCondition; threshold_decimals = nothing, kwargs...) =
    "$(_syntaxstring_feature_test_operator_pair(feature(m), test_operator(m))) $((isnothing(threshold_decimals) ? threshold(m) : round(threshold(m); digits=threshold_decimals)))"

############################################################################################

#TODO Michi
# Alphabet of conditions
abstract type AbstractConditionalAlphabet{M,C<:FeatCondition{M}} <: AbstractAlphabet{C} end

# Infinite alphabet of conditions induced from a set of metaconditions
struct UnboundedExplicitConditionalAlphabet{M,C<:FeatCondition{M}} <: AbstractConditionalAlphabet{M,C}
    metaconditions::Vector{M}
end

Base.isfinite(::Type{UnboundedExplicitConditionalAlphabet}) = false
Base.isiterable(::Type{UnboundedExplicitConditionalAlphabet}) = false

# Finite alphabet of conditions induced from a set of metaconditions
# TODO: to complete -> who is C ??
struct BoundedExplicitConditionalAlphabet{M,C<:FeatCondition{M}} <: AbstractConditionalAlphabet{M,C}
    featconditions::Vector{Tuple{M,Vector}}

    function BoundedExplicitConditionalAlphabet{M,C}(
        featconditions::Vector{Tuple{M,Vector}}
    ) where {M,C<:FeatCondition{M}}
        new{M,C}(featconditions)
    end

    function BoundedExplicitConditionalAlphabet(
        featmetaconditions::Vector{<:FeatMetaCondition},
        thresholds::Vector,
    )
        length(featmetaconditions) != length(thresholds) &&
            error("featmetaconditions vector's length don't match with thresholds" *
                  "vector's length")
        featconditions =
            map(i->(featmetaconditions[i],thresholds[i]),length(featmetaconditions))
        M = SoleBase._typejoin(typeof.(featmetaconditions)...)
        BoundedExplicitConditionalAlphabet{M,C}(featconditions)
    end

    #=function BoundedExplicitConditionalAlphabet(
        features       :: Vector,
        test_operators :: Vector,
        thresholds     :: Vector
    )
        featmetaconditions =
            [FeatMetaCondition(f,t) for f in features for t in test_operators]
        BoundedExplicitConditionalAlphabet(featmetaconditions,thresholds)
    end=#
end

featconditions(a::BoundedExplicitConditionalAlphabet) = a.featconditions

propositions(a::BoundedExplicitConditionalAlphabet) =
    reduce(vcat, map(f-> map(a-> FeatCondition(f[1], a), f[2]), featconditions(a)))

function Base.in(fc::FeatCondition, a::BoundedExplicitConditionalAlphabet)
    return Base.in(fc,proportions(a))
end

Base.iterate(a::BoundedExplicitConditionalAlphabet) = Base.iterate(propositions(a))
function Base.iterate(a::BoundedExplicitConditionalAlphabet, state)
    return Base.iterate(propositions(a), state)
end

Base.isfinite(::Type{BoundedExplicitConditionalAlphabet}) = true
Base.isfinite(a::BoundedExplicitConditionalAlphabet) = Base.isfinite(typeof(a))

Base.length(a::BoundedExplicitConditionalAlphabet) = length(propositions(a))

function Base.rand(
    rng::AbstractRNG,
    a::BoundedExplicitConditionalAlphabet;
    original_featcondition::FeatCondition = nothing,
    featcondition_rand::Bool = true,
    not_feature_rand::Bool = false,
    threshold_rand::Bool = false,
    kwargs...
)::FeatCondition
    if (featcondition_rand, not_feature_rand, threshold_rand) ∉
            [(true,false,false), (false,true,false), (false,false,true)]
        error("More active rand options")
    end

    if not_feature_rand || threshold_rand
        isnothing(original_featcondition) && error("Missing input feat condition")
    end

    featconds = featconditions(a)
    f = feature(original_featcondition)
    t_op = test_operator(original_featcondition)

    fc = begin
        if featcondition_rand
            rand(rng,featconds)
        elseif not_feature_rand
            fc_f = filter(p-> feature(p[1]) == f, featconds)
            rand(rng, fc_f)
        elseif threshold_rand
            fc = filter(p-> feature(p[1]) == f && test_operator(p[1]) == t_op, featconds)
            length(fc) != 1 && error("There can't be more than one feat condition with " *
                                     "that feature and test operator")
            fc
        else
            error("A rand pick was not indicated")
        end
    end

    return FeatCondition(fc[1],rand(rng,fc[2]))
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
