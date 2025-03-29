module XGBoostExt

using SoleModels
using XGBoost

import SoleModels: alphabet, solemodel

function alphabet(model::XGBoost.Booster; kwargs...)
    error("TODO fix and test.")
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

function satisfies_conditions(row, formula)
    # check_cond = true
    # for atom in formula
    #     if !atom.value.metacond.test_operator(row[atom.value.metacond.feature.i_variable], atom.value.threshold)
    #         check_cond = false
    #     end
    # end
    # return check_cond

    all(atom -> atom.value.metacond.test_operator(
                    row[atom.value.metacond.feature.i_variable],
                    atom.value.threshold), formula
                )
end

function bitmap_check_conditions(X, formula)
    BitVector([satisfies_conditions(row, formula) for row in eachrow(X)])
end

function SoleModels.solemodel(
    model::Vector{<:XGBoost.Node},
    # args...;
    X::AbstractMatrix,
    y::AbstractVector;
    weights::Union{AbstractVector{<:Number}, Nothing}=nothing,
    classlabels = nothing,
    featurenames = nothing,
    keep_condensed = false,
    kwargs...
)
    # TODO
    if keep_condensed && !isnothing(classlabels)
        # info = (;
        #     apply_preprocess=(y -> orig_O(findfirst(x -> x == y, classlabels))),
        #     apply_postprocess=(y -> classlabels[y]),
        # )
        info = (;
            apply_preprocess=(y -> findfirst(x -> x == y, classlabels)),
            apply_postprocess=(y -> classlabels[y]),
        )
        keep_condensed = !keep_condensed
        # O = eltype(classlabels)
    else
        info = (;)
        # O = orig_O
    end
    
    trees = map(t -> begin
        # isnothing(t.split) ?
        # xgbleaf(t, Formula[], X, y; classlabels, featurenames) :
        SoleModels.solemodel(t, X, y; classlabels, featurenames, keep_condensed, kwargs...)
    end, model)

    if !isnothing(featurenames)
        info = merge(info, (; featurenames=featurenames, ))
    end

    info = merge(info, (;
            leaf_values=vcat([t.info[:leaf_values] for t in trees]...),
            supporting_predictions=vcat([t.info[:supporting_predictions] for t in trees]...),
            supporting_labels=vcat([t.info[:supporting_labels] for t in trees]...),
        )
    )

    return isnothing(weights) ?
        DecisionEnsemble(trees, info) :
        DecisionEnsemble(trees, weights, info)
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
    path_conditions = Formula[],
    classlabels=nothing,
    featurenames=nothing,
    keep_condensed=false
)
    keep_condensed && error("Cannot keep condensed XGBoost.Node.")

    # xgboost trees could be composed of only one leaf, without any split
    # isnothing(tree.split) && return nothing
    isnothing(tree.split) && return xgbleaf(tree, Formula[], X, y; classlabels, featurenames)

    antecedent = Atom(get_condition(tree.split, tree.split_condition, featurenames; test_operator=(<)))
    
    # Create a new path for the left branch
    left_path = copy(path_conditions)
    push!(left_path, Atom(get_condition(tree.split, tree.split_condition, featurenames; test_operator=(<))))
    
    # Create a new path for the right branch
    right_path = copy(path_conditions)
    push!(right_path, Atom(get_condition(tree.split, tree.split_condition, featurenames; test_operator=(≥))))
    
    lefttree = if isnothing(tree.children[1].split)
        # @show SoleModels.join_antecedents(left_path)
        xgbleaf(tree.children[1], left_path, X, y; classlabels, featurenames)
    else
        SoleModels.solemodel(tree.children[1], X, y; path_conditions=left_path, classlabels=classlabels, featurenames=featurenames)
    end
    isnothing(lefttree) && return Nothing
    
    righttree = if isnothing(tree.children[2].split)
        # @show SoleModels.join_antecedents(right_path)
        xgbleaf(tree.children[2], right_path, X, y; classlabels, featurenames)
    else
        SoleModels.solemodel(tree.children[2], X, y; path_conditions=right_path, classlabels=classlabels, featurenames=featurenames)
    end
    isnothing(righttree) && return Nothing

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
    classlabels=nothing,
    featurenames=nothing,
    keep_condensed=false
)
    keep_condensed && error("Cannot keep condensed XGBoost.Node.")

    bitX = bitmap_check_conditions(X, formula)
    push!(bitX, 0)

    labels = unique(y)
    prediction = SoleModels.bestguess(y[bitX]; suppress_parity_warning=true)

    isnothing(prediction) && (prediction = labels[findfirst(x -> x == "nothing", labels)])

    info = (;
    leaf_values = leaf.leaf,
    supporting_predictions = fill(prediction, length(labels)),
    supporting_labels = labels,
)
    return SoleModels.ConstantModel(prediction, info)
end

end
