module DecisionTreeExt

using SoleModels

import DecisionTree as DT

function SoleModels.solemodel(model::DT.Ensemble, args...; kwargs...)
    return SoleModels.DecisionForest(map(t -> SoleModels.DecisionTree(SoleModels.solemodel(t, args...; kwargs...)), model.trees))
end

function SoleModels.solemodel(tree::DT.InfoNode, keep_condensed = false; use_featurenames = true, kwargs...)
    # @show fieldnames(typeof(tree))
    use_featurenames = use_featurenames ? tree.info.featurenames : false
    root, info = begin
        if keep_condensed
            root = SoleModels.solemodel(tree.node; use_featurenames = use_featurenames, kwargs...)
            info = (;
                apply_preprocess=(y -> UInt32(findfirst(x -> x == y, tree.info.classlabels))),
                apply_postprocess=(y -> tree.info.classlabels[y]),
            )
            root, info
        else
            root = SoleModels.solemodel(tree.node; replace_classlabels = tree.info.classlabels, use_featurenames = use_featurenames, kwargs...)
            info = (;)
            root, info
        end
    end

    info = merge(info, (;
            featurenames=tree.info.featurenames,
            # 
            supporting_predictions=root.info[:supporting_predictions],
            supporting_labels=root.info[:supporting_labels],
        )
    )
    return DecisionTree(root, info)
end

# function SoleModels.solemodel(tree::DT.Root)
#     root = SoleModels.solemodel(tree.node)
#     # @show fieldnames(typeof(tree))
#     info = (;
#         n_feat = tree.n_feat,
#         featim = tree.featim,
#         supporting_predictions = root.info[:supporting_predictions],
#         supporting_labels = root.info[:supporting_labels],
#     )
#     return DecisionTree(root, info)
# end

function SoleModels.solemodel(tree::DT.Node; replace_classlabels = nothing, use_featurenames = false)
    test_operator = (<)
    # @show fieldnames(typeof(tree))
    feature = (use_featurenames != false) ? VariableValue(use_featurenames[tree.featid]) : VariableValue(tree.featid)
    cond = ScalarCondition(feature, test_operator, tree.featval)
    antecedent = Atom(cond)
    lefttree = SoleModels.solemodel(tree.left; replace_classlabels = replace_classlabels, use_featurenames = use_featurenames)
    righttree = SoleModels.solemodel(tree.right; replace_classlabels = replace_classlabels, use_featurenames = use_featurenames)
    info = (;
        supporting_predictions = [lefttree.info[:supporting_predictions]..., righttree.info[:supporting_predictions]...],
        supporting_labels = [lefttree.info[:supporting_labels]..., righttree.info[:supporting_labels]...],
    )
    return Branch(antecedent, lefttree, righttree, info)
end

function SoleModels.solemodel(tree::DT.Leaf; replace_classlabels = nothing, use_featurenames = false)
    # @show fieldnames(typeof(tree))
    prediction = tree.majority
    labels = tree.values
    if !isnothing(replace_classlabels)
        prediction = replace_classlabels[prediction]
        labels = replace_classlabels[labels]
    end
    info = (;
        supporting_predictions = fill(prediction, length(labels)),
        supporting_labels = labels,
    )
    return SoleModels.ConstantModel(prediction, info)
end

end
