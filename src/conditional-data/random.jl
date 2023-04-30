
"""
    function StatsBase.sample(
        rng::AbstractRNG,
        a::BoundedExplicitConditionalAlphabet{C};
        metaconditions::Union{Nothing,FeatMetaCondition,AbstractVector{<:FeatMetaCondition}} = nothing,
        feature::Union{Nothing,AbstractFeature,AbstractVector{<:AbstractFeature}} = nothing,
        test_operator::Union{Nothing,TestOperatorFun,AbstractVector{<:TestOperatorFun}} = nothing,
    )::Proposition where {C} # TODO {C} where {C}

Randomly samples a `FeatCondition` from conditional alphabet `a`, such that:
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
[`AbstractAlphabet].
"""
function StatsBase.sample(
    rng::AbstractRNG,
    a::BoundedExplicitConditionalAlphabet{C};
    metaconditions::Union{Nothing,FeatMetaCondition,AbstractVector{<:FeatMetaCondition}} = nothing,
    features::Union{Nothing,AbstractFeature,AbstractVector{<:AbstractFeature}} = nothing,
    test_operators::Union{Nothing,TestOperatorFun,AbstractVector{<:TestOperatorFun}} = nothing,
)::Proposition where {C} # TODO {C} where {C}

    # Transform values to singletons
    metaconditions = metaconditions isa FeatMetaCondition ? [metaconditions] : metaconditions
    features = features isa AbstractFeature ? [features] : features
    test_operators = test_operators isa TestOperatorFun ? [test_operators] : test_operators

    @assert !(!isnothing(metaconditions) &&
        (!isnothing(features) || !isnothing(test_operators))) "" *
            "Ambiguous output, there are more choices; only one metacondition, one " *
            "feature or one operator must be specified\n Now: \n" *
            "metaconditions: $(metaconditions)\n" *
            "feature: $(feature)\n" *
            "test operator: $(test_operator)\n"

    grouped_featconditions = a.grouped_featconditions

    filtered_featconds = begin
        if !isnothing(metaconditions)
            filtered_featconds = filter(mc_thresholds->first(mc_thresholds) in [metaconditions..., negation.(metaconditions)], grouped_featconditions)
            @assert length(filtered_featconds) == length(metaconditions) "" *
                "There is at least one metacondition passed that is not among the " *
                "possible ones\n metaconditions: $(metaconditions)\n filtered " *
                "metaconditions: $(filtered_featconds)\n" *
                "grouped_featconditions: $(map(first,grouped_featconditions))"
            filtered_featconds
        elseif !isnothing(features) || !isnothing(test_operators)
            filtered_featconds = filter(mc_thresholds->begin
                mc = first(mc_thresholds)
                return (isnothing(features) || feature(mc) in features) &&
                    (isnothing(test_operators) || test_operator(mc) in test_operators)
            end, grouped_featconditions)
            # TODO check with alphabet
            #=@assert length(filtered_featconds) == length(metaconditions) "" *
                "There is at least one metacondition passed that is not among the " *
                "possible ones\n metaconditions: $(metaconditions)\n filtered " *
                "metaconditions: $(filtered_featconds)" *
                "grouped_featconditions: $(map(first,grouped_featconditions))" =#
            filtered_featconds
        else
            grouped_featconditions
        end
    end

    mc_thresholds = rand(rng, filtered_featconds)

    return Proposition(FeatCondition(first(mc_thresholds), rand(rng, last(mc_thresholds))))
end
