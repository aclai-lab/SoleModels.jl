using SoleLogics: AbstractWorld, AbstractRelation
using SoleModels: AbstractFeature, Aggregator

############################################################################################

@inline function onestep_accessible_aggregation(
    X::PassiveDimensionalDataset{N,W},
    i_instance::Integer,
    w::W,
    r::AbstractRelation,
    f::AbstractFeature{V},
    aggr::Aggregator,
    args...,
) where {N,V,W<:AbstractWorld}
    vs = [X[i_instance, w2, f] for w2 in representatives(X, i_instance, w, r, f, aggr)]
    return (length(vs) == 0 ? aggregator_bottom(aggr, V) : aggr(vs))
end

@inline function onestep_accessible_aggregation(
    X::PassiveDimensionalDataset{N,W},
    i_instance::Integer,
    r::GlobalRel,
    f::AbstractFeature{V},
    aggr::Aggregator,
    args...
) where {N,V,W<:AbstractWorld}
    vs = [X[i_instance, w2, f] for w2 in representatives(X, i_instance, r, f, aggr)]
    return (length(vs) == 0 ? aggregator_bottom(aggr, V) : aggr(vs))
end

############################################################################################

@inline function onestep_accessible_aggregation(
    X::DimensionalLogiset{VV,N,W},
    i_instance::Integer,
    w::W,
    r::AbstractRelation,
    f::AbstractFeature{V},
    aggr::Aggregator,
    args...,
) where {VV,N,V<:VV,W<:AbstractWorld}
    onestep_accessible_aggregation(domain(X), i_instance, w, r, f, aggr, args...)
end
@inline function onestep_accessible_aggregation(
    X::DimensionalLogiset{VV,N,W},
    i_instance::Integer,
    r::GlobalRel,
    f::AbstractFeature{V},
    aggr::Aggregator,
    args...,
) where {VV,N,V<:VV,W<:AbstractWorld}
    onestep_accessible_aggregation(domain(X), i_instance, r, f, aggr, args...)
end
