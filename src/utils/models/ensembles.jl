using SoleBase: bestguess

############################################################################################
################################# DecisionEnsemble #########################################
############################################################################################

"""
    struct DecisionEnsemble{O,T<:AbstractModel,A<:Base.Callable} <: AbstractModel{O}
        models::Vector{T}
        aggregation::A
        info::NamedTuple
    end

A `DecisionEnsemble` is an ensemble of models of type `T`. Upon prediction, all
models are used, and an `aggregation` function is used to pool their outputs.

See also [`DecisionForest`](@ref), [`DecisionTree`](@ref), [`MultiDecisionBag`](@ref).
"""
struct DecisionEnsemble{O,T<:AbstractModel,A<:Base.Callable,W<:Union{Nothing,AbstractVector}} <: AbstractModel{O}
    models::Vector{T}
    aggregation::A
    weights::W
    info::NamedTuple

    function DecisionEnsemble{O}(
        models::Vector,
        aggregation::Union{Nothing,Base.Callable},
        weights::Union{Nothing,AbstractVector},
        info::NamedTuple = (;);
        suppress_parity_warning = nothing,
    ) where {O}
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
        T = typeof(models)
        W = typeof(weights)
        A = typeof(aggregation)
        new{O,T,W,A}(models, aggregation, weights, info)
    end
    
    function DecisionEnsemble{O}(
        models::Vector;
        kwargs...
    ) where {O}
        info = (;)
        DecisionEnsemble{O}(models, nothing, nothing, info; kwargs...)
    end

    function DecisionEnsemble{O}(
        models::Vector,
        info::NamedTuple;
        kwargs...
    ) where {O}
        DecisionEnsemble{O}(models, nothing, nothing, info; kwargs...)
    end

    function DecisionEnsemble{O}(
        models::Vector,
        aggregation::Union{Nothing,Base.Callable},
        info::NamedTuple = (;);
        kwargs...
    ) where {O}
        DecisionEnsemble{O}(models, aggregation, nothing, info; kwargs...)
    end

    function DecisionEnsemble(
        models::Vector,
        args...; kwargs...
    ) where {T<:AbstractModel}
        @assert length(models) > 0 "Cannot instantiate empty ensemble!"
        models = wrap.(models)
        O = Union{outcometype.(models)...}
        DecisionEnsemble{O}(models, args...; kwargs...)
    end

end

modelstype(m::DecisionEnsemble{O,T}) where {O,T} = T
models(m::DecisionEnsemble) = m.models
nmodels(m::DecisionEnsemble) = length(models(m))

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
    preds = hcat([apply(subm, d; kwargs...) for subm in models(m)]...)
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

See also [`DecisionEnsemble`](@ref), [`DecisionTree`](@ref), [`MultiDecisionBag`](@ref), [`bestguess`](@ref).
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
