# Active datasets comprehend structures for representing relation sets, features, enumerating worlds,
#  etc. While learning a model can be done only with active modal datasets, testing a model
#  can be done with both active and passive modal datasets.
#
abstract type AbstractActiveFeaturedDataset{
    V<:Number,
    W<:AbstractWorld,
    FR<:AbstractFrame{W,Bool},
    FT<:AbstractFeature{V}
} <: AbstractActiveConditionalDataset{W,AbstractCondition,Bool,FR} end

featvaltype(::Type{<:AbstractActiveFeaturedDataset{V}}) where {V} = V
featvaltype(d::AbstractActiveFeaturedDataset) = featvaltype(typeof(d))

featuretype(::Type{<:AbstractActiveFeaturedDataset{V,W,FR,FT}}) where {V,W,FR,FT} = FT
featuretype(d::AbstractActiveFeaturedDataset) = featuretype(typeof(d))

function grouped_featsaggrsnops(X::AbstractActiveFeaturedDataset)
    return error("Please, provide method grouped_featsaggrsnops(::$(typeof(X))).")
end

function features(X::AbstractActiveFeaturedDataset)
    return error("Please, provide method features(::$(typeof(X))).")
end

function grouped_metaconditions(X::AbstractActiveFeaturedDataset)
    grouped_featsnops = grouped_featsaggrsnops2grouped_featsnops(grouped_featsaggrsnops(X))
    [begin
        (feat,[FeatMetaCondition(feat,op) for op in ops])
    end for (feat,ops) in zip(features(X),grouped_featsnops)]
end

function alphabet(X::AbstractActiveFeaturedDataset)
    conds = vcat([begin
        thresholds = unique([
                X[i_sample, w, feature]
                for i_sample in 1:nsamples(X)
                    for w in allworlds(X, i_sample)
            ])
        [(mc, thresholds) for mc in metaconditions]
    end for (feature, metaconditions) in grouped_metaconditions(X)]...)
    C = FeatCondition{featvaltype(X),FeatMetaCondition{featuretype(X)}}
    BoundedExplicitConditionalAlphabet{C}(collect(conds))
end


# Base.length(X::AbstractActiveFeaturedDataset) = nsamples(X)
# Base.iterate(X::AbstractActiveFeaturedDataset, state=1) = state > nsamples(X) ? nothing : (get_instance(X, state), state+1)

function find_feature_id(X::AbstractActiveFeaturedDataset, feature::AbstractFeature)
    id = findfirst(x->(Base.isequal(x, feature)), features(X))
    if isnothing(id)
        error("Could not find feature $(feature) in AbstractActiveFeaturedDataset of type $(typeof(X)).")
    end
    id
end
function find_relation_id(X::AbstractActiveFeaturedDataset, relation::AbstractRelation)
    id = findfirst(x->x==relation, relations(X))
    if isnothing(id)
        error("Could not find relation $(relation) in AbstractActiveFeaturedDataset of type $(typeof(X)).")
    end
    id
end


# By default an active modal dataset cannot be minified
isminifiable(::AbstractActiveFeaturedDataset) = false

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
    i_featsnaggr = 1
    for (feat,aggrsnops) in zip(features, grouped_featsaggrsnops)
        for aggr in keys(aggrsnops)
            push!(featsnaggrs, (feat,aggr))
            i_featsnaggr += 1
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
