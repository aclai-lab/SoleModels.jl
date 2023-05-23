
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
the alphabet represents the (infinite) set: \${min(V1) ≥ a, a ∈ ℝ}\$.

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
