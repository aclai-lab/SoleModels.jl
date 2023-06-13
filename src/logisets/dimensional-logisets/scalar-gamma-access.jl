
############################################################################################

@inline function onestep_accessible_aggregation(X::Logiset{VV,W}, i_instance::Integer, w::W, r::AbstractRelation, f::AbstractFeature{V}, aggr::Aggregator, args...) where {VV,V<:VV,W<:AbstractWorld}
    vs = [X[i_instance, w2, f] for w2 in representatives(X, i_instance, w, r, f, aggr)]
    return (length(vs) == 0 ? aggregator_bottom(aggr, V) : aggr(vs))
end

@inline function onestep_accessible_aggregation(X::Logiset{VV,W}, i_instance::Integer, r::GlobalRel, f::AbstractFeature{V}, aggr::Aggregator, args...) where {VV,V<:VV,W<:AbstractWorld}
    vs = [X[i_instance, w2, f] for w2 in representatives(X, i_instance, r, f, aggr)]
    return (length(vs) == 0 ? aggregator_bottom(aggr, V) : aggr(vs))
end

############################################################################################

function onestep_accessible_aggregation(
    X::SupportedScalarLogiset,
    i_instance::Integer,
    w::W,
    relation::AbstractRelation,
    feature::AbstractFeature{V},
    aggr::Aggregator,
    i_featsnaggr::Union{Nothing,Integer} = nothing,
    i_relation::Integer = findrelation(X, relation),
) where {V,W<:AbstractWorld}
    compute_modal_gamma(support(X), fd(X), i_instance, w, relation, feature, aggregator, i_featsnaggr, i_relation)
end

@inline function onestep_accessible_aggregation(
    X::SupportedScalarLogiset,
    i_instance::Integer,
    r::GlobalRel,
    f::AbstractFeature{V},
    aggr::Aggregator,
    args...
) where {V,W<:AbstractWorld}
    compute_global_gamma(support(X), fd(X), i_instance, f, aggr, args...)
end

############################################################################################

function fwdslice_onestep_accessible_aggregation(fd::Logiset, fwdslice::FWDFeatureSlice, i_instance, r::GlobalRel, f, aggr, args...)
    # accessible_worlds = allworlds(fd, i_instance)
    accessible_worlds = representatives(fd, i_instance, r, f, aggr)
    gamma = apply_aggregator(fwdslice, accessible_worlds, aggr)
end

function fwdslice_onestep_accessible_aggregation(fd::Logiset, fwdslice::FWDFeatureSlice, i_instance, w, r::AbstractRelation, f, aggr, args...)
    # accessible_worlds = accessibles(fd, i_instance, w, r)
    accessible_worlds = representatives(fd, i_instance, w, r, f, aggr)
    gamma = apply_aggregator(fwdslice, accessible_worlds, aggr)
end

# TODO remove
# function fwdslice_onestep_accessible_aggregation(fd::SupportedScalarLogiset, fwdslice::FWDFeatureSlice, i_instance, args...)
#     fwdslice_onestep_accessible_aggregation(support(X), fd(X), fwdslice, i_instance, args...)
# end


function fwdslice_onestep_accessible_aggregation(X::SupportedScalarLogiset, fwdslice::FWDFeatureSlice, i_instance, r::GlobalRel, f, aggr, args...)
    fwdslice_onestep_accessible_aggregation(support(X), fd(X), fwdslice, i_instance, r, f, aggr, args...)
end

function fwdslice_onestep_accessible_aggregation(X::SupportedScalarLogiset, fwdslice::FWDFeatureSlice, i_instance, w, r::AbstractRelation, f, aggr, args...)
    fwdslice_onestep_accessible_aggregation(support(X), fd(X), fwdslice, i_instance, w, r, f, aggr, args...)
end

############################################################################################

function fwdslice_onestep_accessible_aggregation(
    X::ScalarOneStepMemoset{V,W},
    fd::Logiset{V,W},
    fwdslice::FWDFeatureSlice,
    i_instance::Integer,
    r::GlobalRel,
    feature::AbstractFeature,
    aggr::Aggregator,
    i_featsnaggr::Integer = find_featsnaggr_id(X, feature, aggr),
) where {V,W<:AbstractWorld}
    _fwd_gs = fwd_gs(X)
    if isnothing(_fwd_gs[i_instance, i_featsnaggr])
        gamma = fwdslice_onestep_accessible_aggregation(fd, fwdslice, i_instance, r, feature, aggr)
        _fwd_gs[i_instance, i_featsnaggr] = gamma
    end
    _fwd_gs[i_instance, i_featsnaggr]
end

function fwdslice_onestep_accessible_aggregation(
    X::ScalarOneStepMemoset{V,W},
    fd::Logiset{V,W},
    fwdslice::FWDFeatureSlice,
    i_instance::Integer,
    w::W,
    r::AbstractRelation,
    feature::AbstractFeature,
    aggr::Aggregator,
    i_featsnaggr = find_featsnaggr_id(X, feature, aggr),
    i_relation = nothing, # TODO fix
)::V where {V,W<:AbstractWorld}
    _fwd_rs = fwd_rs(X)
    if isnothing(_fwd_rs[i_instance, w, i_featsnaggr, i_relation])
        gamma = fwdslice_onestep_accessible_aggregation(fd, fwdslice, i_instance, w, r, feature, aggr)
        _fwd_rs[i_instance, w, i_featsnaggr, i_relation] = gamma
    end
    _fwd_rs[i_instance, w, i_featsnaggr, i_relation]
end

############################################################################################
