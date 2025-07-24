# ---------------------------------------------------------------------------- #
#                     DecisionTree apply from DataFrame X                      #
# ---------------------------------------------------------------------------- #
function apply!(
    solem :: DecisionEnsemble{O,T,A,W},
    X     :: AbstractDataFrame,
    y     :: AbstractVector;
    suppress_parity_warning::Bool=false
)::Nothing where {O,T,A,W}
    predictions = permutedims(hcat([apply(s, X, y) for s in get_models(solem)]...))
    predictions = aggregate(solem, predictions, suppress_parity_warning)
    solem.info  = set_predictions(solem.info, predictions, y)
    return nothing
end

function apply!(
    solem :: DecisionTree{T},
    X     :: AbstractDataFrame,
    y     :: AbstractVector{S}
)::Nothing where {T, S<:Label}
    predictions = [apply(solem.root, x) for x in eachrow(X)]
    solem.info  = set_predictions(solem.info, predictions, y)
    return nothing
end

function apply(
    solebranch :: Branch{T},
    X          :: AbstractDataFrame,
    y          :: AbstractVector{S}
) where {T, S<:Label}
    predictions     = Label[apply(solebranch, x) for x in eachrow(X)]
    solebranch.info = set_predictions(solebranch.info, predictions, y)
    return predictions
end

function apply(
    solebranch :: Branch{T},
    x          :: DataFrameRow
)::T where T
    featid, cond, thr = get_featid(solebranch), get_cond(solebranch), get_thr(solebranch)
    feature_value     = x[featid]
    condition_result  = cond(feature_value, thr)
    
    return condition_result ?
        apply(solebranch.posconsequent, x) :
        apply(solebranch.negconsequent, x)
end

function apply(leaf::ConstantModel{T}, ::DataFrameRow)::T where T
    leaf.outcome
end

# ---------------------------------------------------------------------------- #
#                   DecisionXGBoost apply from DataFrame X                     #
# ---------------------------------------------------------------------------- #
# function apply!(
#     m::DecisionXGBoost{<:CLabel},
#     X     :: AbstractDataFrame,
#     y::AbstractVector;
#     mode::Symbol=:replace,
#     leavesonly::Bool=false,
#     suppress_parity_warning::Bool=true,
#     kwargs...
# )
#     y = __apply_pre(m, d, y)

#     preds = hcat([apply_leaf_scores(subm, d; suppress_parity_warning, kwargs...) for subm in models(m)]...)
#     preds = __apply_post(m, preds)
#     preds = [
#         scored_aggregation(m)(pred, sort(unique(m.info.supporting_labels)))
#         for pred in eachrow(preds)
#     ]
#     preds = __apply_pre(m, d, preds)

#     return __apply!(m, mode, preds, y, leavesonly)
# end

# function apply!(
#     m::DecisionXGBoost{<:RLabel},
#     X     :: AbstractDataFrame,
#     y::AbstractVector;
#     base_score::AbstractFloat,
#     mode::Symbol=:replace,
#     leavesonly::Bool=false,
#     suppress_parity_warning::Bool=true,
#     kwargs...
# )
#     y = __apply_pre(m, d, y)

#     preds = hcat([apply!(subm, d, y; mode, leavesonly) for subm in models(m)]...)
#     preds = __apply_post(m, preds)
#     preds = [aggregation(m)(p) for p in eachrow(preds)]
#     preds = __apply_pre(m, d, preds) * length(m.models) .+ base_score

#     __apply!(m, mode, preds, y, leavesonly)
# end
# function apply!(
#     solem :: DecisionEnsemble{O,T,A,W},
#     X     :: AbstractDataFrame,
#     y     :: AbstractVector;
#     suppress_parity_warning::Bool=false
# )::Nothing where {O,T,A,W}
#     predictions = permutedims(hcat([apply(s, X, y) for s in get_models(solem)]...))
#     predictions = aggregate(solem, predictions, suppress_parity_warning)
#     solem.info  = set_predictions(solem.info, predictions, y)
#     return nothing
# end

function apply(
    solem :: DecisionXGBoost{T},
    X     :: AbstractDataFrame
) where {T<:CLabel}
    # we expect X_test * classlabels * nrounds trees, because for every round,
    # XGBoost creates a tree for every classlabel.
    # So, in every subm model, we'll find as much trees as classlabels.
    predictions = hcat([apply(s, X) for s in get_models(solem)]...)
    predictions = [
        scored_aggregation(solem)(predictions, sort(unique(solem.info.supporting_labels)))
        for pred in eachrow(predictions)
    ]
    return predictions
end

# function apply(
#     m::DecisionXGBoost{<:CLabel},
#     id::AbstractInterpretation;
#     suppress_parity_warning=false,
#     kwargs...
# )
#     preds = [apply_leaf_scores(subm, d; suppress_parity_warning, kwargs...) for subm in models(m)]
#     preds = __apply_post(m, preds)
#     scored_aggregation(m)(preds, sort(unique(m.info.supporting_labels)); suppress_parity_warning)
# end

####################à BRANCH

# function apply!(
#     m::Branch,
#     d::AbstractInterpretationSet,
#     y::AbstractVector;
#     check_args::Tuple = (),
#     check_kwargs::NamedTuple = (;),
#     mode = :replace,
#     leavesonly = false,
#     # show_progress = true,
#     kwargs...
# )
#     # @assert length(y) == ninstances(d) "$(length(y)) == $(ninstances(d))"
#     if mode == :replace
#         recursivelyemptysupports!(m, leavesonly)
#         mode = :append
#     end
#     checkmask = checkantecedent(m, d, check_args...; check_kwargs...)
#     preds = Vector{outputtype(m)}(undef,length(checkmask))
#     @sync begin
#         if any(checkmask)
#             l = Threads.@spawn apply!(
#                 posconsequent(m),
#                 slicedataset(d, checkmask; return_view = true),
#                 y[checkmask];
#                 check_args = check_args,
#                 check_kwargs = check_kwargs,
#                 mode = mode,
#                 leavesonly = leavesonly,
#                 kwargs...
#             )
#         end
#         ncheckmask = (!).(checkmask)
#         if any(ncheckmask)
#             r = Threads.@spawn apply!(
#                 negconsequent(m),
#                 slicedataset(d, ncheckmask; return_view = true),
#                 y[ncheckmask];
#                 check_args = check_args,
#                 check_kwargs = check_kwargs,
#                 mode = mode,
#                 leavesonly = leavesonly,
#                 kwargs...
#             )
#         end
#         if any(checkmask)
#             preds[checkmask] .= fetch(l)
#         end
#         if any(ncheckmask)
#             preds[ncheckmask] .= fetch(r)
#         end
#     end
#     return __apply!(m, mode, preds, y, leavesonly)
# end

function apply(
    solebranch :: Branch{T},
    X          :: AbstractDataFrame
) where T
    checkmask = check_condition(solebranch, X)

    predictions = Vector(undef,length(checkmask))
    predictions[checkmask] .= apply(
        posconsequent(solebranch),
        X[checkmask, :]
    )
    predictions[(!).(checkmask)] .= apply(
        negconsequent(solebranch),
        X[(!).(checkmask), :]
    )
    return predictions
end

function apply(
    leaf{T}::ConstantModel,
    X::AbstractDataFrame
)::T where T
    Fill((outcome(leaf), outcome_leaf_value(leaf)), nrow(X))
end



############à LEAFS

# function apply_leaf_scores!(
#     m::ConstantModel,
#     d::AbstractInterpretationSet,
#     y::AbstractVector;
#     mode = :replace,
#     leavesonly = false,
#     kwargs...
# )
#     # @assert length(y) == ninstances(d) "$(length(y)) == $(ninstances(d))"
#     if mode == :replace
#         recursivelyemptysupports!(m, leavesonly)
#         mode = :append
#     end

#     preds = fill((outcome(m), outcome_leaf_value(m)), ninstances(d))

#     return __apply!(m, mode, preds, y, leavesonly)
# end

# apply_leaf_scores(m::ConstantModel, i::AbstractInterpretation; kwargs...) = outcome(m)

# apply_leaf_scores(
#     m::ConstantModel,
#     d::AbstractInterpretationSet,
#     i_instance::Integer;
#     kwargs...
# ) = (outcome(m), outcome_leaf_value(m))



# ---------------------------------------------------------------------------- #
#                                   methods                                    #
# ---------------------------------------------------------------------------- #
get_models(s::DecisionEnsemble) = s.models
get_models(s::DecisionXGBoost)  = s.models

get_featid(s::Branch) = s.antecedent.value.metacond.feature.i_variable
get_cond(s::Branch)   = s.antecedent.value.metacond.test_operator
get_thr(s::Branch)    = s.antecedent.value.threshold

# get_condition(m::Union{Rule,Branch}) = antecedent(m).value
outcome_leaf_value(m::ConstantModel) = m.info.leaf_value


function aggregate(
    solem :: DecisionEnsemble,
    preds :: AbstractMatrix{T},
    suppress_parity_warning :: Bool
)::Vector{T} where T<:Label
    [weighted_aggregation(solem)(p; suppress_parity_warning) for p in eachcol(preds)]
end

function set_predictions(
    info  :: NamedTuple,
    preds :: Vector{T},
    y     :: AbstractVector{S}
)::NamedTuple where {T,S<:Label}
    merge(info, (supporting_predictions=preds, supporting_labels=y))
end

function check_condition(
    solebranch::Branch{T},
    X::AbstractDataFrame
)::BitVector where {T<:CLabel}
    featid, cond, thr = get_featid(solebranch), get_cond(solebranch), get_thr(solebranch)
    @fastmath cond.(X[!,featid], thr)
end
