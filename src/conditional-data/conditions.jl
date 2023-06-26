
using SoleLogics: AbstractAlphabet
using Random
import SoleLogics: negation, propositions

import Base: isequal, hash, in, isfinite, length

"""
    abstract type AbstractCondition end

Abstract type for representing conditions that can be interpreted and evaluated
on worlds of instances of a conditional dataset. In logical contexts,
these are wrapped into `Proposition`s.

See also
[`Proposition`](@ref),
[`syntaxstring`](@ref),
[`FeatMetaCondition`](@ref),
[`FeatCondition`](@ref).
"""
abstract type AbstractCondition end # TODO parametric?

function syntaxstring(c::AbstractCondition; kwargs...)
    error("Please, provide method syntaxstring(::$(typeof(c)); kwargs...)." *
        " Note that this value must be unique.")
end

function Base.show(io::IO, c::AbstractCondition)
    # print(io, "Feature of type $(typeof(c))\n\t-> $(syntaxstring(c))")
    print(io, "$(typeof(c)): $(syntaxstring(c))")
    # print(io, "$(syntaxstring(c))")
end

Base.isequal(a::AbstractCondition, b::AbstractCondition) = syntaxstring(a) == syntaxstring(b) # nameof(x) == nameof(feature)
Base.hash(a::AbstractCondition) = Base.hash(syntaxstring(a))

############################################################################################

"""
    struct FeatMetaCondition{F<:AbstractFeature,O<:TestOperator} <: AbstractCondition
        feature::F
        test_operator::O
    end

A metacondition representing a scalar comparison method.
A feature is a scalar function that can be computed on a world
of an instance of a conditional dataset.
A test operator is a binary mathematical relation, comparing the computed feature value
and an external threshold value (see `FeatCondition`). A metacondition can also be used
for representing the infinite set of conditions that arise with a free threshold
(see `UnboundedExplicitConditionalAlphabet`): \${min(V1) ≥ a, a ∈ ℝ}\$.

See also
[`AbstractCondition`](@ref),
[`negation`](@ref),
[`FeatCondition`](@ref).
"""
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
    "$(_syntaxstring_metacondition(m; kwargs...)) ⍰"

function _syntaxstring_metacondition(
    m::FeatMetaCondition;
    use_feature_abbreviations::Bool = false,
    kwargs...,
)
    if use_feature_abbreviations
        _st_featop_abbr(feature(m), test_operator(m); kwargs...)
    else
        _st_featop_name(feature(m), test_operator(m); kwargs...)
    end
end

_st_featop_name(feature::AbstractFeature,   test_operator::TestOperator; kwargs...)     = "$(syntaxstring(feature; kwargs...)) $(test_operator)"

# Abbreviations

_st_featop_abbr(feature::AbstractFeature,   test_operator::TestOperator; kwargs...)     = _st_featop_name(feature, test_operator; kwargs...)

############################################################################################

"""
    struct FeatCondition{U,M<:FeatMetaCondition} <: AbstractCondition
        metacond::M
        a::U
    end

A scalar condition comparing a computed feature value (see `FeatMetaCondition`)
and a threshold value `a`.
It can be evaluated on a world
of an instance of a conditional dataset.

Example: \$min(V1) ≥ 10\$, which translates to
"Within this world, the minimum of variable 1 is greater or equal than 10."

See also
[`AbstractCondition`](@ref),
[`negation`](@ref),
[`FeatMetaCondition`](@ref).
"""
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
    "$(_syntaxstring_metacondition(metacond(m); kwargs...)) $((isnothing(threshold_decimals) ? threshold(m) : round(threshold(m); digits=threshold_decimals)))"
