module DecisionTreeExt

using  SoleModels
using  SoleBase:   Label
import SoleModels: alphabet
import SoleModels: solemodel

import DecisionTree as DT

# ---------------------------------------------------------------------------- #
#                                  utilities                                   #
# ---------------------------------------------------------------------------- #
function get_featurenames(tree::Union{DT.Ensemble, DT.InfoNode})
    if !hasproperty(tree, :info)
        throw(ArgumentError("Please provide featurenames."))
    end
    return tree.info.featurenames
end
get_classlabels(tree::Union{DT.Ensemble, DT.InfoNode})::Vector{<:Label} = tree.info.classlabels

function get_condition(featid, featval, featurenames)
    test_operator = (<)
    feature = isnothing(featurenames) ? VariableValue(featid) : VariableValue(featid, featurenames[featid])
    return ScalarCondition(feature, test_operator, featval)
end

# ---------------------------------------------------------------------------- #
#                                   alphabet                                   #
# ---------------------------------------------------------------------------- #
function SoleModels.alphabet(
    model::Union{
        DT.Ensemble,
        DT.InfoNode,
        DT.Node,
        DT.Leaf,
    },
    args...;
    kwargs...
)

    function _alphabet!(a::Vector, model::DT.Ensemble, args...; featurenames = nothing, kwargs...)
        map(t -> _alphabet!(a, t, args...; featurenames, kwargs...), model.trees)
        return a
    end

    function _alphabet!(a::Vector, model::DT.InfoNode, args...; featurenames = true, kwargs...)
        featurenames = featurenames == true ? model.info.featurenames : featurenames
        _alphabet!(a, model.left, args...; featurenames, kwargs...)
        _alphabet!(a, model.right, args...; featurenames, kwargs...)
        return a
    end

    function _alphabet!(a::Vector, model::DT.Node, args...; featurenames, kwargs...)
        push!(a, Atom(get_condition(model.featid, model.featval, featurenames)))
        return a
    end

    function _alphabet!(a::Vector, model::DT.Leaf, args...; kwargs...)
        return a
    end
    
    return SoleData.scalaralphabet(_alphabet!(Atom{ScalarCondition}[], model, args...; kwargs...))
end

# ---------------------------------------------------------------------------- #
#                                  solemodel                                   #
# ---------------------------------------------------------------------------- #
function SoleModels.solemodel(
    model          :: DT.Ensemble{T,O};
    featurenames   :: Vector{Symbol}=Symbol[],
    weights        :: Vector{<:Number}=Number[],
    classlabels    :: AbstractVector{<:Label}=Label[],
    keep_condensed :: Bool=false,
    parity_func    :: Base.Callable=x->first(sort(collect(keys(x))))
)::DecisionEnsemble where {T,O}
    isempty(featurenames) && (featurenames = get_featurenames(model))
    if keep_condensed && !isempty(classlabels)
        info = (;
            apply_preprocess=(y->O(findfirst(x -> x == y, classlabels))),
            apply_postprocess=(y->classlabels[y]),
        )
        keep_condensed = !keep_condensed
    else
        info = (;)
    end

    trees = map(t -> SoleModels.solemodel(t, featurenames; classlabels), model.trees)
    info = merge(info, (;
            featurenames=featurenames, 
            supporting_predictions=vcat([t.info[:supporting_predictions] for t in trees]...),
            supporting_labels=vcat([t.info[:supporting_labels] for t in trees]...),
        )
    )

    isnothing(weights) ?
        DecisionEnsemble{O}(trees, info; parity_func) :
        DecisionEnsemble{O}(trees, weights, info; parity_func)
end

function SoleModels.solemodel(
    tree           :: DT.InfoNode{T,O};
    featurenames   :: Vector{Symbol}=Symbol[],
    keep_condensed :: Bool=false,
)::DecisionTree where {T,O}
    isempty(featurenames) && (featurenames = get_featurenames(tree))
    classlabels  = hasproperty(tree.info, :classlabels) ? get_classlabels(tree) : Label[]

    root, info = begin
        if keep_condensed
            root = SoleModels.solemodel(tree.node, featurenames; classlabels)
            info = (;
                apply_preprocess=(y -> UInt32(findfirst(x -> x == y, classlabels))),
                apply_postprocess=(y -> classlabels[y]),
            )
            root, info
        else
            root = SoleModels.solemodel(tree.node, featurenames; classlabels)
            info = (;)
            root, info
        end
    end

    info = merge(info, (;
            featurenames=featurenames,
            supporting_predictions=root.info[:supporting_predictions],
            supporting_labels=root.info[:supporting_labels],
        )
    )

    DecisionTree(root, info)
end

function SoleModels.solemodel(
    tree         :: DT.Node,
    featurenames :: Vector{Symbol};
    classlabels  :: AbstractVector{<:Label}=Label[],
)::Branch
    cond = get_condition(tree.featid, tree.featval, featurenames)
    antecedent = Atom(cond)
    lefttree  = SoleModels.solemodel(tree.left, featurenames; classlabels )
    righttree = SoleModels.solemodel(tree.right, featurenames; classlabels )

    info = (;
        supporting_predictions = [lefttree.info[:supporting_predictions]..., righttree.info[:supporting_predictions]...],
        supporting_labels = [lefttree.info[:supporting_labels]..., righttree.info[:supporting_labels]...],
    )

    return Branch(antecedent, lefttree, righttree, info)
end

function SoleModels.solemodel(
    tree         :: DT.Leaf,
                 :: Vector{Symbol};
    classlabels  :: AbstractVector{<:Label}=Label[]
)::ConstantModel
    prediction, labels = isempty(classlabels) ? 
        (tree.majority, tree.values) : 
        (classlabels[tree.majority], classlabels[tree.values])

    info = (;
        supporting_predictions = fill(prediction, length(labels)),
        supporting_labels = labels,
    )

    SoleModels.ConstantModel(prediction, info)
end

end

