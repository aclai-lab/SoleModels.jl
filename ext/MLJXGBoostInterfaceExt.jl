module MLJXGBoostInterfaceExt

using SoleModels
import SoleModels: solemodel, fitted_params

using MLJXGBoostInterface
using MLJXGBoostInterface: XGB, MMI

# struct XGBNode
#     node::XGB.Node
#     info::NamedTuple
# end
# AbstractTrees.nodevalue(n::XGBNode) = n.node

# struct XGBLeaf
#     node::XGB.Node
#     info::NamedTuple
# end
# AbstractTrees.nodevalue(l::XGBLeaf) = l.node

# isleaf(node::XGB.Node) = isempty(node.children) ? true : false

# SoleModels.wrap(vecnode::Vector{<:XGB.Node}, info::NamedTuple=NamedTuple()) = SoleModels.wrap.(vecnode, Ref(info))
# SoleModels.wrap(node::XGB.Node, info::NamedTuple=NamedTuple()) = isleaf(node) ? XGBLeaf(node, info) : XGBNode(node, info)

# function SoleModels.fitted_params(mach)
#     raw_trees = XGB.trees(mach.fitresult[1])
#     encoding = get_encoding(mach.fitresult[2])
#     featurenames = mach.report.vals[1][1]
#     classlabels = get_classlabels(encoding)
#     info = (;featurenames, classlabels)
#     trees = SoleModels.wrap(raw_trees, info,)
#     (; trees, encoding)
# end

# function get_condition(featidstr, featval, featurenames; test_operator)
#     featid = parse(Int, featidstr[2:end]) + 1 # considering 0-based indexing in XGBoost feature ids
#     feature = isnothing(featurenames) ? VariableValue(featid) : VariableValue(featid, featurenames[featid])
#     return ScalarCondition(feature, test_operator, featval)
# end

# function satisfies_conditions(row, formula)
#     # check_cond = true
#     # for atom in formula
#     #     if !atom.value.metacond.test_operator(row[atom.value.metacond.feature.i_variable], atom.value.threshold)
#     #         check_cond = false
#     #     end
#     # end
#     # return check_cond

#     all(atom -> atom.value.metacond.test_operator(
#                     row[atom.value.metacond.feature.i_variable],
#                     atom.value.threshold), formula
#                 )
# end

# function bitmap_check_conditions(X, formula)
#     BitVector([satisfies_conditions(row, formula) for row in eachrow(X)])
# end

# function SoleModels.solemodel(
#     model::Vector{<:XGB.Node},
#     args...;
#     weights::Union{AbstractVector{<:Number}, Nothing}=nothing,
#     classlabels = nothing,
#     featurenames = nothing,
#     keep_condensed = false,
#     kwargs...
# )
#     # TODO
#     if keep_condensed && !isnothing(classlabels)
#         # info = (;
#         #     apply_preprocess=(y -> orig_O(findfirst(x -> x == y, classlabels))),
#         #     apply_postprocess=(y -> classlabels[y]),
#         # )
#         info = (;
#             apply_preprocess=(y -> findfirst(x -> x == y, classlabels)),
#             apply_postprocess=(y -> classlabels[y]),
#         )
#         keep_condensed = !keep_condensed
#         # O = eltype(classlabels)
#     else
#         info = (;)
#         # O = orig_O
#     end
    
#     # trees = map(t -> SoleModels.solemodel(t, args...; classlabels, featurenames, keep_condensed, kwargs...), model.trees)
#     trees = map(t -> SoleModels.solemodel(t, args...; classlabels, featurenames, keep_condensed, kwargs...), model)

#     if !isnothing(featurenames)
#         info = merge(info, (; featurenames=featurenames, ))
#     end

#     info = merge(info, (;
#             leaf_values=vcat([t.info[:leaf_values] for t in trees]...),
#             supporting_predictions=vcat([t.info[:supporting_predictions] for t in trees]...),
#             supporting_labels=vcat([t.info[:supporting_labels] for t in trees]...),
#         )
#     )

#     if isnothing(weights)
#         m = DecisionEnsemble(trees, info)
#     else
#         m = DecisionEnsemble(trees, weights, info)
#     end
#     return m
# end

# """
#     solemodel(tree::XGBoost.Node; fl=Formula[], fr=Formula[], classlabels=nothing, featurenames=nothing, keep_condensed=false)

# Traverses a learned XGBoost tree, collecting the path conditions for each branch. 
# Left paths (<) store conditions in `fl`, right paths (≥) store conditions in `fr`. 
# When reaching a leaf, calls `xgbleaf` with the path's collected conditions.
# """
# function SoleModels.solemodel(
#     tree::XGB.Node,
#     X,
#     y::AbstractVector;
#     path_conditions = Formula[],
#     classlabels=nothing,
#     featurenames=nothing,
#     keep_condensed=false
# )
#     keep_condensed && error("Cannot keep condensed XGBoost.Node.")

#     antecedent = Atom(get_condition(tree.split, tree.split_condition, featurenames; test_operator=(<)))
    
#     # Create a new path for the left branch
#     left_path = copy(path_conditions)
#     push!(left_path, Atom(get_condition(tree.split, tree.split_condition, featurenames; test_operator=(<))))
    
#     # Create a new path for the right branch
#     right_path = copy(path_conditions)
#     push!(right_path, Atom(get_condition(tree.split, tree.split_condition, featurenames; test_operator=(≥))))
    
#     lefttree = if isnothing(tree.children[1].split)
#         # @show SoleModels.join_antecedents(left_path)
#         xgbleaf(tree.children[1], left_path, X, y; classlabels, featurenames)
#     else
#         SoleModels.solemodel(tree.children[1], X, y; path_conditions=left_path, classlabels=classlabels, featurenames=featurenames)
#     end
    
#     righttree = if isnothing(tree.children[2].split)
#         # @show SoleModels.join_antecedents(right_path)
#         xgbleaf(tree.children[2], right_path, X, y; classlabels, featurenames)
#     else
#         SoleModels.solemodel(tree.children[2], X, y; path_conditions=right_path, classlabels=classlabels, featurenames=featurenames)
#     end

#     info = (;
#         leaf_values = [lefttree.info[:leaf_values]..., righttree.info[:leaf_values]...],
#         supporting_predictions = [lefttree.info[:supporting_predictions]..., righttree.info[:supporting_predictions]...],
#         supporting_labels = [lefttree.info[:supporting_labels]..., righttree.info[:supporting_labels]...],
#     )
#     return Branch(antecedent, lefttree, righttree, info)
# end

# function xgbleaf(
#     leaf::XGB.Node,
#     formula::Vector{<:Formula},
#     X,
#     y::AbstractVector;
#     classlabels=nothing,
#     featurenames=nothing,
#     keep_condensed=false
# )
#     keep_condensed && error("Cannot keep condensed XGBoost.Node.")

#     bitX = bitmap_check_conditions(X, formula)
#     prediction = SoleModels.bestguess(y[bitX]; suppress_parity_warning=true)
#     labels = unique(y)

#     # if !isnothing(classlabels)
#     #     prediction = classlabels[prediction]
#     #     labels = classlabels[labels]
#     # end

#     info = (;
#         leaf_values = leaf.leaf,
#         supporting_predictions = fill(prediction, length(labels)),
#         supporting_labels = labels,
#     )
#     return SoleModels.ConstantModel(prediction, info)
# end

end