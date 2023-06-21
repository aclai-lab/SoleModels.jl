
"""
Active scalar datasets are active logical datasets with scalar features.
"""
const AbstractScalarLogiset{
    W<:AbstractWorld,
    V<:Number,
    FT<:AbstractFeature{V},
    FR<:AbstractFrame{W}
} = AbstractLogiset{W,V,FT,FR}

function grouped_featsaggrsnops(X::AbstractScalarLogiset)
    return error("Please, provide method grouped_featsaggrsnops(::$(typeof(X))).")
end

function check(
    p::Proposition{<:ScalarCondition},
    X::AbstractScalarLogiset{W},
    i_instance::Integer,
    w::W,
) where {W<:AbstractWorld}
    cond = atom(p)
    featval = featvalue(X, i_instance, w, feature(cond))
    apply_test_operator(test_operator(cond), featval, threshold(cond))
end

function grouped_metaconditions(X::AbstractScalarLogiset)
    grouped_featsnops = grouped_featsaggrsnops2grouped_featsnops(grouped_featsaggrsnops(X))
    [begin
        (feat,[ScalarMetaCondition(feat,op) for op in ops])
    end for (feat,ops) in zip(features(X),grouped_featsnops)]
end

function alphabet(X::AbstractScalarLogiset)
    conds = vcat([begin
        thresholds = unique([
                X[i_instance, w, feature]
                for i_instance in 1:ninstances(X)
                    for w in allworlds(X, i_instance)
            ])
        [(mc, thresholds) for mc in metaconditions]
    end for (feature, metaconditions) in grouped_metaconditions(X)]...)
    C = ScalarCondition{featvaltype(X),featuretype(X),ScalarMetaCondition{featuretype(X)}}
    BoundedScalarConditions{C}(collect(conds))
end


# Convenience functions
function grouped_featsnops2grouped_featsaggrsnops(
    grouped_featsnops::AbstractVector{<:AbstractVector{<:TestOperator}}
)::AbstractVector{<:AbstractDict{<:Aggregator,<:AbstractVector{<:TestOperator}}}
    grouped_featsaggrsnops = Dict{<:Aggregator,<:AbstractVector{<:TestOperator}}[]
    for (i_feature, test_operators) in enumerate(grouped_featsnops)
        aggrsnops = Dict{Aggregator,AbstractVector{<:TestOperator}}()
        for test_operator in test_operators
            aggregator = existential_aggregator(test_operator)
            if (!haskey(aggrsnops, aggregator))
                aggrsnops[aggregator] = TestOperator[]
            end
            push!(aggrsnops[aggregator], test_operator)
        end
        push!(grouped_featsaggrsnops, aggrsnops)
    end
    grouped_featsaggrsnops
end

function grouped_featsaggrsnops2grouped_featsnops(
    grouped_featsaggrsnops::AbstractVector{<:AbstractDict{<:Aggregator,<:AbstractVector{<:TestOperator}}}
)::AbstractVector{<:AbstractVector{<:TestOperator}}
    grouped_featsnops = [begin
        vcat(values(grouped_featsaggrsnops)...)
    end for grouped_featsaggrsnops in grouped_featsaggrsnops]
    grouped_featsnops
end

function features_grouped_featsaggrsnops2featsnaggrs_grouped_featsnaggrs(features, grouped_featsaggrsnops)
    featsnaggrs = Tuple{<:AbstractFeature,<:Aggregator}[]
    grouped_featsnaggrs = AbstractVector{Tuple{<:Integer,<:Aggregator}}[]
    i_featsnaggr = 1
    for (feat,aggrsnops) in zip(features, grouped_featsaggrsnops)
        aggrs = []
        for aggr in keys(aggrsnops)
            push!(featsnaggrs, (feat,aggr))
            push!(aggrs, (i_featsnaggr,aggr))
            i_featsnaggr += 1
        end
        push!(grouped_featsnaggrs, aggrs)
    end
    featsnaggrs, grouped_featsnaggrs
end

function features_grouped_featsaggrsnops2featsnaggrs(features, grouped_featsaggrsnops)
    featsnaggrs = Tuple{<:AbstractFeature,<:Aggregator}[]
    for (feat,aggrsnops) in zip(features, grouped_featsaggrsnops)
        for aggr in keys(aggrsnops)
            push!(featsnaggrs, (feat,aggr))
        end
    end
    featsnaggrs
end

function features_grouped_featsaggrsnops2grouped_featsnaggrs(features, grouped_featsaggrsnops)
    grouped_featsnaggrs = AbstractVector{Tuple{<:Integer,<:Aggregator}}[]
    i_featsnaggr = 1
    for (feat,aggrsnops) in zip(features, grouped_featsaggrsnops)
        aggrs = []
        for aggr in keys(aggrsnops)
            push!(aggrs, (i_featsnaggr,aggr))
            i_featsnaggr += 1
        end
        push!(grouped_featsnaggrs, aggrs)
    end
    grouped_featsnaggrs
end
