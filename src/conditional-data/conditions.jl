using SoleLogics: AbstractAlphabet

abstract type AbstractCondition end # TODO parametric?

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

# Alphabet of conditions
abstract type AbstractConditionalAlphabet{M,C<:FeatCondition{M}} <: AbstractAlphabet{C} end

# Infinite alphabet of conditions induced from a set of metaconditions
struct ExplicitConditionalAlphabet{M,C<:FeatCondition{M}} <: AbstractConditionalAlphabet{M,C}
  metaconditions::Vector{M}
end
