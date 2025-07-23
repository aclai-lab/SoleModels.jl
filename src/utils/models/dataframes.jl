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
#                                   methods                                    #
# ---------------------------------------------------------------------------- #
get_models(s::DecisionEnsemble) = s.models

get_featid(s::Branch) = s.antecedent.value.metacond.feature.i_variable
get_cond(s::Branch)   = s.antecedent.value.metacond.test_operator
get_thr(s::Branch)    = s.antecedent.value.threshold

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

