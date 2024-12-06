module XGBoostExt

using XGBoost

import Sole: alphabet, solemodel

function alphabet(model::XGBoost.Booster; kwargs...)
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
        condition = ScalarCondition(feature, (<), tree.split_condition)
        push!(a, condition)
        if length(tree.children) == 2
            _alphabet!(a, tree.children[1]; with_stats, kwargs...)
            _alphabet!(a, tree.children[2]; with_stats, kwargs...)
        else
            error("Found $(length(tree.children)) children while 2 were expected: $(tree.children).")
        end
        return a
    end
    _alphabet!([], model; kwargs...)
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
#         SoleModels.ConstantModel(value, (; supporting_predictions=[value]))
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
#         supporting_predictions=[left_tree.info[:supporting_predictions]..., right_tree.info[:supporting_predictions]...],
#         this=_makeleaf(tree.leaf),
#         xgboost_gain = tree.gain,
#         xgboost_yes = tree.yes,
#         xgboost_no = tree.no,
#         xgboost_cover = tree.cover,
#     )

#     # Create and return a Sole Branch
#     return Branch(antecedent, left_tree, right_tree, info)
# end
# solemodel(model)


end
