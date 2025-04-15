module XGBoostExt

using SoleModels
using XGBoost

using CategoricalArrays

import SoleModels: alphabet, solemodel

function alphabet(model::XGBoost.Booster; kwargs...)
    # error("TODO fix and test.")
    function _alphabet!(a::Vector, model::XGBoost.Booster; kwargs...)
        return a
    end
    function _alphabet!(a::Vector, tree::XGBoost.Node; kwargs...)
        # Base case: if it's a leaf node
        if length(tree.children) == 0
            return a
        end

        # Recursive case: split node
        feature = Sole.VariableValue(tree.split isa String ? Symbol(tree.split) : tree.split)
        condition = ScalarCondition(feature, (<), tree.split_condition) # TODO verify.
        push!(a, condition)
        if length(tree.children) == 2
            _alphabet!(a, tree.children[1]; with_stats, kwargs...)
            _alphabet!(a, tree.children[2]; with_stats, kwargs...)
        else
            error("Found $(length(tree.children)) children while 2 were expected: $(tree.children).")
        end
        return a
    end
    _alphabet!(Atom{ScalarCondition}[], model; kwargs...)
end

# TODO fix and test. Problem: where are the tree weights? How do I write this in the multi-class case?
# leaf values are actually the weight of the tree

# # Convert an XGBoost.Booster to a Sole Ensemble
# function solemodel(model::XGBoost.Booster; with_stats::Bool = true, kwargs...)
#     # Extract weights (global scaling factors for trees, if any)
#     weights = nothing  # XGBoost trees usually don't have individual weights, but modify here if needed.

#     model.params[:objective] == "multi:softprob" || error("Unexpected objective encountered: $(model.params[:objective]).")
#     isempty(model.feature_names) || error("Unexpected objective encountered: $(model.params[:objective]).")

#     # Convert all trees into Sole models
#     trees = [solemodel(tree; with_stats, kwargs...) for tree in XGBoost.trees(model; with_stats = with_stats)]

#     # Return a Sole Ensemble
#     return Sole.Ensemble(trees, weights)
# end

# # Convert a single XGBoost tree into a Sole tree
# function solemodel(tree::XGBoost.Node; with_stats::Bool = true, kwargs...)
#     function _makeleaf(value)
#         SoleModels.ConstantModel(value, (; supporting_predictions=repeat("yes", tree.yes), supporting_labels=repeat("yes", tree.yes)))
#     end
    
#     # Base case: if it's a leaf node
#     if length(tree.children) == 0
#         return _makeleaf(tree.leaf)
#     end

#     # Recursive case: split node
#     feature = Sole.VariableValue(tree.split isa String ? Symbol(tree.split) : tree.split)
#     condition = ScalarCondition(feature, (<), tree.split_condition)
#     antecedent = Atom(condition)
    
#     # Recursively convert left and right branches
    
#     if length(tree.children) == 2
#         left_tree = solemodel(tree.children[1]; with_stats, kwargs...)
#         right_tree = solemodel(tree.children[2]; with_stats, kwargs...)
#     else
#         error("Found $(length(tree.children)) children while 2 were expected: $(tree.children).")
#     end

#     # Aggregate info (e.g., supporting predictions) from children
#     info = (;
#         # supporting_predictions=[left_tree.info[:supporting_predictions]..., right_tree.info[:supporting_predictions]...],
#         # supporting_labels=[left_tree.info[:supporting_labels]..., right_tree.info[:supporting_labels]...],
#         this=_makeleaf(tree.leaf),
#         xgboost_gain = tree.gain,
#         xgboost_yes = tree.yes,
#         xgboost_no = tree.no,
#         xgboost_cover = tree.cover,
#     )

#     # Create and return a Sole Branch
#     return Branch(antecedent, left_tree, right_tree, info)
# end

function get_condition(featidstr, featval, featurenames; test_operator)
    featid = parse(Int, featidstr[2:end]) + 1 # considering 0-based indexing in XGBoost feature ids
    feature = isnothing(featurenames) ? VariableValue(featid) : VariableValue(featid, featurenames[featid])
    return ScalarCondition(feature, test_operator, featval)
end

function get_condition(class_idx, featurenames; test_operator, featval)
    feature = isnothing(featurenames) ? VariableValue(class_idx) : VariableValue(class_idx, featurenames[class_idx])
    return ScalarCondition(feature, test_operator, featval)
end

get_operator(atom::Atom{<:ScalarCondition}) = atom.value.metacond.test_operator
get_i_variable(atom::Atom{<:ScalarCondition}) = atom.value.metacond.feature.i_variable
get_threshold(atom::Atom{<:ScalarCondition}) = atom.value.threshold

function satisfies_conditions(row, formula)
    all(atom -> get_operator(atom)(
                    row[get_i_variable(atom)],
                    get_threshold(atom)), formula
                )
end

function bitmap_check_conditions(X, formula)
    BitVector([satisfies_conditions(row, formula) for row in eachrow(X)])
end

function early_return(leaf, antecedent, clabel, classl)
    info =(;
    leaf_values = leaf,
    supporting_predictions = clabel,
    supporting_labels = [classl],
    )

    return Branch(
            antecedent,
            SoleModels.ConstantModel(first(clabel), info),
            SoleModels.ConstantModel(first(clabel), info),
            info
        )
end

# ---------------------------------------------------------------------------- #
#                          DecisionXGBoost solemodel                           #
# ---------------------------------------------------------------------------- #
function SoleModels.solemodel(
    model::Vector{<:XGBoost.Node},
    X::AbstractMatrix,
    y::AbstractVector;
    classlabels,
    featurenames=nothing,
    keep_condensed=false,
    use_float32::Bool=true,
    kwargs...
)
    keep_condensed && error("Cannot keep condensed XGBoost.Node.")

    nclasses = length(classlabels)

    trees = map(enumerate(model)) do (i, t)
        class_idx = (i - 1) % nclasses + 1
        clabels = categorical([classlabels[class_idx]])
        # xgboost trees could be composed of only one leaf, without any split
        if isnothing(t.split)
            antecedent = Atom(get_condition(class_idx, featurenames; test_operator=(<), featval=Inf))
            leaf = use_float32 ? Float32(t.leaf) : t.leaf
            early_return(leaf, antecedent, clabels, classlabels[class_idx])
        else
            SoleModels.solemodel(t, X, y; classlabels, class_idx, clabels, featurenames, use_float32, kwargs...)
        end
    end

    info = merge(
        isnothing(featurenames) ? (;) : (;featurenames=featurenames),
        (;
            leaf_values = reduce(vcat, getindex.(getproperty.(trees, :info), :leaf_values)),
            supporting_predictions = reduce(vcat, getindex.(getproperty.(trees, :info), :supporting_predictions)),
            supporting_labels = reduce(vcat, getindex.(getproperty.(trees, :info), :supporting_labels))
        )
    )

    return DecisionXGBoost(trees, info)
end

"""
    solemodel(tree::XGBoost.Node; fl=Formula[], fr=Formula[], classlabels=nothing, featurenames=nothing, keep_condensed=false)

Traverses a learned XGBoost tree, collecting the path conditions for each branch. 
Left paths (<) store conditions in `fl`, right paths (≥) store conditions in `fr`. 
When reaching a leaf, calls `xgbleaf` with the path's collected conditions.
"""
function SoleModels.solemodel(
    tree::XGBoost.Node,
    X::AbstractMatrix,
    y::AbstractVector;
    classlabels,
    class_idx,
    clabels,
    featurenames=nothing,
    path_conditions=Formula[],
    use_float32::Bool,
)
split_condition = use_float32 ? Float32(tree.split_condition) : tree.split_condition
    antecedent = Atom(get_condition(tree.split, split_condition, featurenames; test_operator=(<)))

    # create a new path for the left branch
    left_path = copy(path_conditions)
    push!(left_path, Atom(get_condition(tree.split, split_condition, featurenames; test_operator=(<))))
    
    # create a new path for the right branch
    right_path = copy(path_conditions)
    push!(right_path, Atom(get_condition(tree.split, split_condition, featurenames; test_operator=(≥))))
    
    lefttree = if isnothing(tree.children[1].split)
        # @show SoleModels.join_antecedents(left_path)
        xgbleaf(tree.children[1], left_path, X, y; use_float32)
    else
        SoleModels.solemodel(tree.children[1], X, y; path_conditions=left_path, classlabels, class_idx, clabels, featurenames, use_float32)
    end
    isnothing(lefttree) && 
    begin 
        return early_return(tree.children[1].leaf, antecedent, clabels, classlabels[class_idx])
    end

    righttree = if isnothing(tree.children[2].split)
        # @show SoleModels.join_antecedents(right_path)
        xgbleaf(tree.children[2], right_path, X, y; use_float32)
    else
        SoleModels.solemodel(tree.children[2], X, y; path_conditions=right_path, classlabels, class_idx, clabels, featurenames, use_float32)
    end
    isnothing(righttree) && 
    begin
        return early_return(tree.children[2].leaf, antecedent, clabels, classlabels[class_idx])
    end

    info = (;
        leaf_values = [lefttree.info[:leaf_values]..., righttree.info[:leaf_values]...],
        supporting_predictions = [lefttree.info[:supporting_predictions]..., righttree.info[:supporting_predictions]...],
        supporting_labels = [lefttree.info[:supporting_labels]..., righttree.info[:supporting_labels]...],
    )
    return Branch(antecedent, lefttree, righttree, info)
end

function xgbleaf(
    leaf::XGBoost.Node,
    formula::Vector{<:Formula},
    X::AbstractMatrix,
    y::AbstractVector;
    use_float32::Bool,
)
    bitX = bitmap_check_conditions(X, formula)
    prediction = SoleModels.bestguess(y[bitX]; suppress_parity_warning=true)
    labels = unique(y)

    isnothing(prediction) && return nothing

    leaf_values = use_float32 ? Float32(leaf.leaf) : leaf.leaf

    info = (;
        leaf_values,
        supporting_predictions = fill(prediction, length(labels)),
        supporting_labels = labels,
    )

    return SoleModels.ConstantModel(prediction, info)
end

end
