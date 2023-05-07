import Base: rand

"""
    function Base.rand(
        rng::AbstractRNG,
        a::BoundedExplicitConditionalAlphabet;
        metaconditions::Union{Nothing,FeatMetaCondition,AbstractVector{<:FeatMetaCondition}} = nothing,
        feature::Union{Nothing,AbstractFeature,AbstractVector{<:AbstractFeature}} = nothing,
        test_operator::Union{Nothing,TestOperatorFun,AbstractVector{<:TestOperatorFun}} = nothing,
    )::Proposition

Randomly samples a `Proposition` (holding a `FeatCondition`) from conditional alphabet `a`,
such that:
- if `metaconditions` are specified, then the set of metaconditions (feature-operator pairs)
is limited to `metaconditions`;
- if `feature` is specified, then the set of metaconditions (feature-operator pairs)
is limited to those with `feature`;
- if `test_operator` is specified, then the set of metaconditions (feature-operator pairs)
is limited to those with `test_operator`.

See also
[`BoundedExplicitConditionalAlphabet`](@ref),
[`FeatCondition`](@ref),
[`FeatMetaCondition`](@ref),
[`AbstractAlphabet'](@ref).
"""
function Base.rand(
    rng::AbstractRNG,
    a::BoundedExplicitConditionalAlphabet;
    metaconditions::Union{Nothing,FeatMetaCondition,AbstractVector{<:FeatMetaCondition}} = nothing,
    features::Union{Nothing,AbstractFeature,AbstractVector{<:AbstractFeature}} = nothing,
    test_operators::Union{Nothing,TestOperatorFun,AbstractVector{<:TestOperatorFun}} = nothing,
)::Proposition

    # Transform values to singletons
    metaconditions = metaconditions isa FeatMetaCondition ? [metaconditions] : metaconditions
    features = features isa AbstractFeature ? [features] : features
    test_operators = test_operators isa TestOperatorFun ? [test_operators] : test_operators

    @assert !(!isnothing(metaconditions) &&
        (!isnothing(features) || !isnothing(test_operators)))
            "Ambiguous output, there are more choices; only one metacondition, one " *
            "feature or one operator must be specified\n Now: \n" *
            "metaconditions: $(metaconditions)\n" *
            "feature: $(feature)\n" *
            "test operator: $(test_operator)\n"

    featconds = featconditions(a)

    filtered_featconds = begin
        if !isnothing(metaconditions)
            filtered_featconds = filter(mc_thresholds->first(mc_thresholds) in metaconditions, featconds)
            @assert length(filtered_featconds) == length(metaconditions)
                "There is at least one metacondition passed that is not among the " *
                "possible ones\n metaconditions: $(metaconditions)\n filtered " *
                "metaconditions: $(filtered_featconds)"
            filtered_featconds
        elseif !isnothing(features) || !isnothing(test_operators)
            filtered_featconds = filter(mc_thresholds->begin
                mc = first(mc_thresholds)
                return (isnothing(features) || SoleLogics.feature(mc) in feature) &&
                    (isnothing(test_operators) || SoleLogics.test_operator(mc) in test_operator)
            end, featconds)
            @assert length(filtered_featconds) == length(metaconditions)
                "There is at least one metacondition passed that is not among the " *
                "possible ones\n metaconditions: $(metaconditions)\n filtered " *
                "metaconditions: $(filtered_featconds)"
            filtered_featconds
        else
            featconds
        end
    end

    mc_thresholds = rand(rng, filtered_featconds)

    return Proposition(FeatCondition(first(mc_thresholds), rand(rng, last(mc_thresholds))))
end
