module DecisionTreeExt

using  SoleModels
using  SoleBase:   Label
import SoleModels: alphabet
import SoleModels: solemodel

import DecisionTree as DT

# ---------------------------------------------------------------------------- #
#                                  utilities                                   #
# ---------------------------------------------------------------------------- #
get_classlabels(tree::DT.InfoNode)::Vector{<:Label} = tree.info.classlabels

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
    model        :: DT.Ensemble{T,O};
    weights      :: Vector{<:Number}=Number[],
    classlabels  :: Vector{<:Label}=Label[],
    featurenames :: Vector{Symbol}=Symbol[]
)::DecisionEnsemble where {T,O}
    trees = map(t -> SoleModels.solemodel(t; classlabels, featurenames), model.trees)
    info = isempty(featurenames) ? (;) : (; featurenames=featurenames, )
    parity_func=x->first(sort(collect(keys(x))))

    isnothing(weights) ?
        DecisionEnsemble{O}(trees, info; parity_func) :
        DecisionEnsemble{O}(trees, weights, info; parity_func)
end

function SoleModels.solemodel(
    tree         :: DT.InfoNode{T,O};
    featurenames :: Vector{Symbol}=Symbol[]
)::DecisionTree where {T,O}
    classlabels  = hasproperty(tree.info, :classlabels) ? get_classlabels(tree) : Label[]
    root = SoleModels.solemodel(tree.node; classlabels, featurenames)
    DecisionTree(root, (;))
end

function SoleModels.solemodel(
    tree         :: DT.Node;
    classlabels  :: Vector{<:Label}=Label[],
    featurenames :: Vector{Symbol}=Symbol[]
)::Branch
    cond = get_condition(tree.featid, tree.featval, featurenames)
    antecedent = Atom(cond)
    lefttree  = SoleModels.solemodel(tree.left;  classlabels, featurenames)
    righttree = SoleModels.solemodel(tree.right; classlabels, featurenames)
    return Branch(antecedent, lefttree, righttree)
end

function SoleModels.solemodel(
    tree         :: DT.Leaf;
    classlabels  :: Vector{<:Label}=Label[],
    featurenames :: Vector{Symbol}=Symbol[]
)::ConstantModel
    prediction = isempty(classlabels) ? tree.majority : classlabels[tree.majority]
    SoleModels.ConstantModel(prediction)
end

end

