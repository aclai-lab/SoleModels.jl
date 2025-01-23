using SoleBase: Label, CLabel, RLabel, bestguess

abstract type AbstractDecisionEnsemble{O} <: AbstractModel{O} end

############################################################################################
################################# DecisionEnsemble #########################################
############################################################################################

"""
    struct DecisionEnsemble{O,T<:AbstractModel,A<:Base.Callable,W<:Union{Nothing,AbstractVector}} <: AbstractDecisionEnsemble{O}
        models::Vector{T}
        aggregation::A
        weights::W
        info::NamedTuple
    end

A `DecisionEnsemble` is an ensemble of models; upon prediction, all
models are used, and an `aggregation` function is used to pool their outputs.
Optionally, model weights can be specified.

See also [`DecisionForest`](@ref), [`DecisionTree`](@ref), [`MaxDecisionBag`](@ref).
"""
struct DecisionEnsemble{O,T<:AbstractModel,A<:Base.Callable,W<:Union{Nothing,AbstractVector}} <: AbstractDecisionEnsemble{O}
    models::Vector{T}
    aggregation::A
    weights::W
    info::NamedTuple

    function DecisionEnsemble{O}(
        models::AbstractVector{T},
        aggregation::Union{Nothing,Base.Callable},
        weights::Union{Nothing,AbstractVector},
        info::NamedTuple = (;);
        suppress_parity_warning = nothing,
    ) where {O,T<:AbstractModel}
        @assert length(models) > 0 "Cannot instantiate empty ensemble!"
        models = wrap.(models)
        if isnothing(aggregation)
            # if a suppress_parity_warning parameter is provided, then the aggregation's suppress_parity_warning defaults to it;
            #  otherwise, it defaults to bestguess's suppress_parity_warning
            if isnothing(suppress_parity_warning)
                aggregation = function (args...; kwargs...) bestguess(args...; kwargs...) end
            else
                aggregation = function (args...; suppress_parity_warning = suppress_parity_warning, kwargs...) bestguess(args...; suppress_parity_warning, kwargs...) end
            end
        else
            isnothing(suppress_parity_warning) || @warn "Unexpected value for suppress_parity_warning: $(suppress_parity_warning)."
        end
        # T = typeof(models)
        W = typeof(weights)
        A = typeof(aggregation)
        new{O,T,A,W}(collect(models), aggregation, weights, info)
    end
    
    function DecisionEnsemble{O}(
        models::AbstractVector;
        kwargs...
    ) where {O}
        info = (;)
        DecisionEnsemble{O}(models, nothing, nothing, info; kwargs...)
    end

    function DecisionEnsemble{O}(
        models::AbstractVector,
        info::NamedTuple;
        kwargs...
    ) where {O}
        DecisionEnsemble{O}(models, nothing, nothing, info; kwargs...)
    end

    function DecisionEnsemble{O}(
        models::AbstractVector,
        aggregation::Union{Nothing,Base.Callable},
        info::NamedTuple = (;);
        kwargs...
    ) where {O}
        DecisionEnsemble{O}(models, aggregation, nothing, info; kwargs...)
    end

    function DecisionEnsemble{O}(
        models::AbstractVector,
        weights::AbstractVector,
        info::NamedTuple = (;);
        kwargs...
    ) where {O}
        DecisionEnsemble{O}(models, nothing, weights, info; kwargs...)
    end

    function DecisionEnsemble(
        models::AbstractVector,
        args...; kwargs...
    )
        @assert length(models) > 0 "Cannot instantiate empty ensemble!"
        models = wrap.(models)
        O = Union{outcometype.(models)...}
        DecisionEnsemble{O}(models, args...; kwargs...)
    end
end


isensemble(m::DecisionEnsemble) = true

modelstype(m::DecisionEnsemble{O,T}) where {O,T} = T
models(m::DecisionEnsemble) = m.models
nmodels(m::DecisionEnsemble) = length(models(m))

iscomplete(m::DecisionEnsemble) = any(iscomplete.(models(m)))

aggregation(m::DecisionEnsemble) = m.aggregation
weights(m::DecisionEnsemble) = m.weights
# Returns the aggregation function, patched by weights if the model has them.
function weighted_aggregation(m::DecisionEnsemble)
    if isnothing(weights(m))
        aggregation(m)
    else
        function (labels; kwargs...)
            aggregation(m)(labels, weights(m); kwargs...)
        end
    end
end

"""
    function nnodes(m::DecisionEnsemble)

Return the number of nodes within `m`, that is, the sum of the nodes number in each
wrapped [`DecisionTree`](@ref).

See also [`DecisionEnsemble`](@ref), [`DecisionTree`](@ref).
"""
function nnodes(m::DecisionEnsemble)
    nsubmodels(m)
end

"""
    function nleaves(m::DecisionEnsemble)

Return the number of [`LeafModel`](@ref) within `m`.

See also [`DecisionEnsemble`](@ref), [`DecisionTree`](@ref), [`LeafModel`](@ref).
"""
function nleaves(m::DecisionEnsemble)
    nleafmodels(m)
end

"""
    function height(m::DecisionEnsemble)

Return the maximum height across all the [`DecisionTree`](@ref)s within `m`.

See also [`DecisionEnsemble`](@ref), [`DecisionTree`](@ref).
"""
function height(m::DecisionEnsemble)
    subtreeheight(m)
end

immediatesubmodels(m::DecisionEnsemble) = trees(m)
nimmediatesubmodels(m::DecisionEnsemble) = length(trees(m))
listimmediaterules(m::DecisionEnsemble; kwargs...) = error("TODO implement")

# TODO check these two.
function apply(
    m::DecisionEnsemble,
    id::AbstractInterpretation;
    suppress_parity_warning = false,
    kwargs...
)
    preds = [apply(subm, d; suppress_parity_warning, kwargs...) for subm in models(m)]
    preds = __apply_post(m, preds)
    weighted_aggregation(m)(preds; suppress_parity_warning)
end

# TODO parallelize
function apply(
    m::DecisionEnsemble,
    d::AbstractInterpretationSet;
    suppress_parity_warning = false,
    kwargs...
)
    preds = hcat([apply(subm, d; suppress_parity_warning, kwargs...) for subm in models(m)]...)
    preds = __apply_post(m, preds)
    preds = [
        weighted_aggregation(m)(preds[i,:]; suppress_parity_warning)
        for i in 1:size(preds,1)
    ]
    return preds
end

# TODO parallelize
function apply!(
    m::DecisionEnsemble,
    d::AbstractInterpretationSet,
    y::AbstractVector;
    mode = :replace,
    leavesonly = false,
    # show_progress = false, # length(ntrees(m)) > 15,
    suppress_parity_warning = false,
    kwargs...
)
    # @show y
    y = __apply_pre(m, d, y)
    # _d = SupportedLogiset(d) TODO?
    # @show y
    preds = hcat([apply!(subm, d, y; mode, leavesonly, kwargs...) for subm in models(m)]...)

    preds = __apply_post(m, preds)

    preds = [
        weighted_aggregation(m)(preds[i,:]; suppress_parity_warning, kwargs...)
        for i in 1:size(preds,1)
    ]

    preds = __apply_pre(m, d, preds)
    return __apply!(m, mode, preds, y, leavesonly)
end



"""
    const DecisionForest{O} = DecisionEnsemble{<:DecisionTree{O}}

A [`DecisionForest`](@ref) is an ensemble of (unweighted) [`DecisionTree`](@ref)'s,
aggregated by `bestguess`.

See also [`DecisionEnsemble`](@ref), [`DecisionTree`](@ref), [`MaxDecisionBag`](@ref), [`bestguess`](@ref).
"""
const DecisionForest{O} = DecisionEnsemble{O,<:DecisionTree,typeof(bestguess),Nothing}

function DecisionForest(trees::Vector{<:DecisionTree}, info::NamedTuple = (;),)
    DecisionEnsemble(trees, bestguess, info)
end

function DecisionForest{O}(trees::Vector{<:DecisionTree}, info::NamedTuple = (;),) where {O}
    DecisionEnsemble{O}(trees, bestguess, info)
end

"""
    trees(m::DecisionForest)

Return all the [`DecisionTree`](@ref)s wrapped within a forest.

See also [`DecisionTree`](@ref).
"""
trees(m::DecisionForest) = models(m)

"""
    function ntrees(m::DecisionForest)

Return the number of trees within `m`.

See also [`DecisionForest`](@ref), [`DecisionTree`](@ref), [`trees`](@ref).
"""
function ntrees(m::DecisionForest)
    length(trees(m))
end




"""
A `MaxDecisionBag` is an ensemble of models, weighted by a set of other models.
In this simplified implementation, only the model with the highest (`max`) weight is responsible for the outcome.

See also [`DecisionForest`](@ref), [`DecisionTree`](@ref), [`DecisionEnsemble`](@ref), [`MaxDecisionBag`](@ref).
"""
struct MaxDecisionBag{O,TO<:AbstractModel,TU<:AbstractModel
    # ,A<:Base.Callable
    # ,W<:Union{Nothing,AbstractVector}
    } <: AbstractDecisionEnsemble{O}
    output_producing_models::Vector{TO}
    weight_producing_models::Vector{TU}
    # aggregation::A
    # weights::W
    info::NamedTuple

    function MaxDecisionBag{O}(
        output_producing_models::Vector,
        weight_producing_models::Vector,
        # aggregation::Union{Nothing,Base.Callable},
        # weights::Union{Nothing,AbstractVector},
        info::NamedTuple = (;);
        suppress_parity_warning = nothing,
    ) where {O}
        @assert length(output_producing_models) > 0 "Cannot instantiate empty bagoutput-producing models!"
        @assert length(weight_producing_models) > 0 "Cannot instantiate empty bagweight-producing models!"
        @assert length(output_producing_models) == length(weight_producing_models) "Cannot instantiate bag with different numbers of output and weight producing models: $(length(output_producing_models)) != $(length(weight_producing_models))."
        output_producing_models = wrap.(output_producing_models)
        weight_producing_models = wrap.(weight_producing_models)
        # if isnothing(aggregation)
        #     # if a suppress_parity_warning parameter is provided, then the aggregation's suppress_parity_warning defaults to it;
        #     #  otherwise, it defaults to bestguess's suppress_parity_warning
        #     if isnothing(suppress_parity_warning)
        #         aggregation = function (args...; kwargs...) bestguess(args...; kwargs...) end
        #     else
        #         aggregation = function (args...; suppress_parity_warning = suppress_parity_warning, kwargs...) bestguess(args...; suppress_parity_warning, kwargs...) end
        #     end
        # else
        #     isnothing(suppress_parity_warning) || @warn "Unexpected value for suppress_parity_warning: $(suppress_parity_warning)."
        # end
        TO = typeof(output_producing_models)
        TU = typeof(weight_producing_models)
        # W = typeof(weights)
        # A = typeof(aggregation)
        new{O,TO,TU}(output_producing_models, weight_producing_models, aggregation, info) # , weights
    end
    
    function MaxDecisionBag(
        output_producing_models::Vector,
        weight_producing_models::Vector,
        args...; kwargs...
    )
        @assert length(output_producing_models) > 0 "Cannot instantiate empty bagoutput-producing models!"
        @assert length(weight_producing_models) > 0 "Cannot instantiate empty bagweight-producing models!"
        @assert length(output_producing_models) == length(weight_producing_models) "Cannot instantiate bag with different numbers of output and weight producing models: $(length(output_producing_models)) != $(length(weight_producing_models))."
        output_producing_models = wrap.(output_producing_models)
        weight_producing_models = wrap.(weight_producing_models)
        O = Union{outcometype.(output_producing_models)...}
        MaxDecisionBag{O}(output_producing_models, weight_producing_models, args...; kwargs...)
    end
end

isensemble(m::MaxDecisionBag) = true

function apply(m::MaxDecisionBag, d::AbstractInterpretation; suppress_parity_warning = false, kwargs...)
    weights = [apply(wm, d; suppress_parity_warning, kwargs...) for wm in m.weight_producing_models]
    om = m.output_producing_models[argmax(weights)]
    pred = apply(om, d; suppress_parity_warning, kwargs...)
    # preds = [apply(om, d; suppress_parity_warning, kwargs...) for om in m.output_producing_models]
    # pred = aggregation(m)(preds, weights; suppress_parity_warning)
    pred
end

# TODO Add a keyword argument that toggles the soft or hard behavior. The hard behavior is one where you first find the bestguess among the weights, and then perform the apply only on the first

# TODO parallelize
function apply(
    m::MaxDecisionBag,
    d::AbstractInterpretationSet;
    suppress_parity_warning = false,
    kwargs...
)
    weights = hcat([apply(wm, d; suppress_parity_warning, kwargs...) for wm in m.weight_producing_models]...)
    preds = __apply_post(m, preds)
    preds = [
        apply(m.output_producing_models[im], d; suppress_parity_warning, kwargs...)
        for im in argmax(weights; dims=2)
    ]
    preds = __apply_pre(m, d, preds)
    return preds
end

function apply!(m::MaxDecisionBag, d::AbstractInterpretationSet, y::AbstractVector; mode = :replace, leavesonly = false, suppress_parity_warning = false, kwargs...)
    y = __apply_pre(m, d, y)
    weights = hcat([apply!(wm, d, y; mode, leavesonly, suppress_parity_warning, kwargs...) for wm in m.weight_producing_models]...)
    preds = __apply_post(m, preds)
    preds = [
        apply!(m.output_producing_models[im], d, y; mode, leavesonly, suppress_parity_warning, kwargs...)
        for im in argmax(weights; dims=2)
    ]
    preds = __apply_pre(m, d, preds)
    return __apply!(m, mode, preds, y, leavesonly)
end

"""
TODO explain. The output of XGBoost via the strategy "multi:softmax".
"""
const MaxTreeBag{O,W<:RLabel,A<:typeof(+),WW<:RLabel} = MaxDecisionBag{O,ConstantModel{O},DecisionEnsemble{W,DecisionTree,A,WW}}

function unique_with_indices(x)
    unique_vals = unique(x)
    indices = [findall(==(val), x) for val in unique_vals]
    return unique_vals, indices
end

# function apply!(
#     dbag::SoleModels.DecisionBag, 
#     X,
#     y, 
#     classlabels
# )
#     n_stumps = length(dbag.output_producing_models)
#     values, idx_groups = unique_with_indices(dbag.info.supporting_predictions)

#     count_trees = Dict()
#     for i in 1:n_stumps
#         prediction = DecisionTree.apply_tree(dbag.output_producing_models[i], classlabels)
#         count_trees[prediction] = get(count_trees, prediction, 0.0) + weights[i]
#     end
#     top_prediction = dbag.output_producing_models[1].left.majority
#     top_count = -Inf
#     for (k, v) in count_trees
#         if v > top_count
#             top_prediction = k
#             top_count = v
#         end
#     end
#     return top_prediction

#     dbag.info.supporting_labels = y
#     dbag.info.supporting_predictions = top_prediction
# end

