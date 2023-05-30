
############################################################################################

"""
    struct ScalarMetaCondition{F<:AbstractFeature,O<:TestOperator} <: AbstractCondition{F}
        feature::F
        test_operator::O
    end

A metacondition representing a scalar comparison method.
Here, the `feature` is a scalar function that can be computed on a world
of an instance of a logical dataset.
A test operator is a binary mathematical relation, comparing the computed feature value
and an external threshold value (see `ScalarCondition`). A metacondition can also be used
for representing the infinite set of conditions that arise with a free threshold
(see `UnboundedExplicitConditionalAlphabet`): \${min(V1) ≥ a, a ∈ ℝ}\$.

See also
[`AbstractCondition`](@ref),
[`negation`](@ref),
[`ScalarCondition`](@ref).
"""
struct ScalarMetaCondition{F<:AbstractFeature,O<:TestOperator} <: AbstractCondition{F}

  # Feature: a scalar function that can be computed on a world
  feature::F

  # Test operator (e.g. ≥)
  test_operator::O

end

# TODO
# featuretype(::Type{<:ScalarMetaCondition{F}}) where {F<:AbstractFeature} = F
# featuretype(m::ScalarMetaCondition) = featuretype(typeof(F))

feature(m::ScalarMetaCondition) = m.feature
test_operator(m::ScalarMetaCondition) = m.test_operator

negation(m::ScalarMetaCondition) = ScalarMetaCondition(feature(m), inverse_test_operator(test_operator(m)))

syntaxstring(m::ScalarMetaCondition; kwargs...) =
    "$(_syntaxstring_metacondition(m; kwargs...)) ⍰"

function _syntaxstring_metacondition(
    m::ScalarMetaCondition;
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
    struct ScalarCondition{U,F,M<:ScalarMetaCondition{F}} <: AbstractCondition{F}
        metacond::M
        a::U
    end

A scalar condition comparing a computed feature value (see `ScalarMetaCondition`)
and a threshold value `a`.
It can be evaluated on a world of an instance of a logical dataset.

For example: \$min(V1) ≥ 10\$, which translates to
"Within this world, the minimum of variable 1 is greater or equal than 10."
In this case, the feature a [`UnivariateMin`](@ref) object.

See also
[`AbstractCondition`](@ref),
[`negation`](@ref),
[`ScalarMetaCondition`](@ref).
"""
struct ScalarCondition{U,F,M<:ScalarMetaCondition{F}} <: AbstractCondition{F}

  # Metacondition
  metacond::M

  # Threshold value
  threshold::U

  function ScalarCondition(
      metacond       :: M,
      threshold      :: U
  ) where {F<:AbstractFeature,M<:ScalarMetaCondition{F},U}
      new{U,F,M}(metacond, threshold)
  end

  function ScalarCondition(
      condition      :: ScalarCondition{U,M},
      threshold      :: U
  ) where {F<:AbstractFeature,M<:ScalarMetaCondition{F},U}
      new{U,F,M}(metacond(condition), threshold)
  end

  function ScalarCondition(
      feature       :: AbstractFeature,
      test_operator :: TestOperator,
      threshold     :: U
  ) where {U}
      metacond = ScalarMetaCondition(feature, test_operator)
      ScalarCondition(metacond, threshold)
  end
end

metacond(c::ScalarCondition) = c.metacond
threshold(c::ScalarCondition) = c.threshold

feature(c::ScalarCondition) = feature(metacond(c))
test_operator(c::ScalarCondition) = test_operator(metacond(c))

negation(c::ScalarCondition) = ScalarCondition(negation(metacond(c)), threshold(c))

syntaxstring(m::ScalarCondition; threshold_decimals = nothing, kwargs...) =
    "$(_syntaxstring_metacondition(metacond(m); kwargs...)) $((isnothing(threshold_decimals) ? threshold(m) : round(threshold(m); digits=threshold_decimals)))"

############################################################################################
############################################################################################
############################################################################################

"""
    abstract type AbstractConditionalAlphabet{C<:ScalarCondition} <: AbstractAlphabet{C} end

Abstract type for alphabets of conditions.

See also
[`ScalarCondition`](@ref),
[`ScalarMetaCondition`](@ref),
[`AbstractAlphabet`](@ref).
"""
abstract type AbstractConditionalAlphabet{C<:ScalarCondition} <: AbstractAlphabet{C} end

"""
    struct UnboundedExplicitConditionalAlphabet{C<:ScalarCondition} <: AbstractConditionalAlphabet{C}
        metaconditions::Vector{<:ScalarMetaCondition}
    end

An infinite alphabet of conditions induced from a finite set of metaconditions.
For example, if `metaconditions = [ScalarMetaCondition(UnivariateMin(1), ≥)]`,
the alphabet represents the (infinite) set: \${min(V1) ≥ a, a ∈ ℝ}\$.

See also
[`BoundedExplicitConditionalAlphabet`](@ref),
[`ScalarCondition`](@ref),
[`ScalarMetaCondition`](@ref),
[`AbstractAlphabet`](@ref).
"""
struct UnboundedExplicitConditionalAlphabet{C<:ScalarCondition} <: AbstractConditionalAlphabet{C}
    metaconditions::Vector{<:ScalarMetaCondition}

    function UnboundedExplicitConditionalAlphabet{C}(
        metaconditions::Vector{<:ScalarMetaCondition}
    ) where {C<:ScalarCondition}
        new{C}(metaconditions)
    end

    function UnboundedExplicitConditionalAlphabet(
        features       :: AbstractVector{C},
        test_operators :: AbstractVector,
    ) where {C<:ScalarCondition}
        metaconditions =
            [ScalarMetaCondition(f, t) for f in features for t in test_operators]
        UnboundedExplicitConditionalAlphabet{C}(metaconditions)
    end
end

Base.isfinite(::Type{<:UnboundedExplicitConditionalAlphabet}) = false

function Base.in(p::Proposition{<:ScalarCondition}, a::UnboundedExplicitConditionalAlphabet)
    fc = atom(p)
    idx = findfirst(mc->mc == metacond(fc), a.metaconditions)
    return !isnothing(idx)
end

"""
    struct BoundedExplicitConditionalAlphabet{C<:ScalarCondition} <: AbstractConditionalAlphabet{C}
        grouped_featconditions::Vector{Tuple{<:ScalarMetaCondition,Vector}}
    end

A finite alphabet of conditions, grouped by (a finite set of) metaconditions.

See also
[`UnboundedExplicitConditionalAlphabet`](@ref),
[`ScalarCondition`](@ref),
[`ScalarMetaCondition`](@ref),
[`AbstractAlphabet`](@ref).
"""
# Finite alphabet of conditions induced from a set of metaconditions
struct BoundedExplicitConditionalAlphabet{C<:ScalarCondition} <: AbstractConditionalAlphabet{C}
    grouped_featconditions::Vector{<:Tuple{ScalarMetaCondition,Vector}}

    function BoundedExplicitConditionalAlphabet{C}(
        grouped_featconditions::Vector{<:Tuple{ScalarMetaCondition,Vector}}
    ) where {C<:ScalarCondition}
        new{C}(grouped_featconditions)
    end

    function BoundedExplicitConditionalAlphabet{C}(
        metaconditions::Vector{<:ScalarMetaCondition},
        thresholds::Vector{<:Vector},
    ) where {C<:ScalarCondition}
        length(metaconditions) != length(thresholds) &&
            error("Can't instantiate BoundedExplicitConditionalAlphabet with mismatching" *
                " number of `metaconditions` and `thresholds`" *
                " ($(metaconditions) != $(thresholds)).")
        grouped_featconditions = collect(zip(metaconditions, thresholds))
        BoundedExplicitConditionalAlphabet{C}(grouped_featconditions)
    end

    function BoundedExplicitConditionalAlphabet(
        features       :: AbstractVector{C},
        test_operators :: AbstractVector,
        thresholds     :: Vector
    ) where {C<:ScalarCondition}
        metaconditions =
            [ScalarMetaCondition(f, t) for f in features for t in test_operators]
        BoundedExplicitConditionalAlphabet{C}(metaconditions, thresholds)
    end
end

function propositions(a::BoundedExplicitConditionalAlphabet)
    Iterators.flatten(
        map(
            ((mc,thresholds),)->map(
                threshold->Proposition(ScalarCondition(mc, threshold)),
                thresholds),
            a.grouped_featconditions
        )
    ) |> collect
end

function Base.in(p::Proposition{<:ScalarCondition}, a::BoundedExplicitConditionalAlphabet)
    fc = atom(p)
    grouped_featconditions = a.grouped_featconditions
    idx = findfirst(((mc,thresholds),)->mc == metacond(fc), grouped_featconditions)
    return !isnothing(idx) && Base.in(threshold(fc), last(grouped_featconditions[idx]))
end
