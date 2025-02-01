module MLJXGBoostInterfaceExt

using SoleModels
import SoleModels: solemodel, fitted_params

using MLJXGBoostInterface
using MLJXGBoostInterface: XGB, MMI

using AbstractTrees

get_encoding(classes_seen) = Dict(MMI.int(c) => c for c in MMI.classes(classes_seen))
get_classlabels(encoding) = [string(encoding[i]) for i in sort(keys(encoding) |> collect)]

struct InfoXGBNode
    node::XGB.Node
    info::NamedTuple
end
AbstractTrees.nodevalue(n::InfoXGBNode) = n.node

struct InfoXGBLeaf
    node::XGB.Node
    info::NamedTuple
end
AbstractTrees.nodevalue(l::InfoXGBLeaf) = l.node

isleaf(node::XGB.Node) = isempty(node.children) ? true : false

SoleModels.wrap(vecnode::Vector{<:XGB.Node}, info::NamedTuple=NamedTuple()) = SoleModels.wrap.(vecnode, Ref(info))
SoleModels.wrap(node::XGB.Node, info::NamedTuple=NamedTuple()) = isleaf(node) ? InfoXGBLeaf(node, info) : InfoXGBNode(node, info)

function SoleModels.fitted_params(mach)
    raw_stumps = XGB.trees(mach.fitresult[1])
    encoding = get_encoding(mach.fitresult[2])
    features = mach.report.vals[1][1]
    classlabels = get_classlabels(encoding)
    info = (featurenames=features, classlabels)
    stumps = SoleModels.wrap(raw_stumps, info,)
    (; stumps, encoding)
end

split2id(str::String) = parse(Int, filter(isdigit, str)) + 1

function SoleModels.solemodel(
    stumps::Vector{<:InfoXGBNode},
    encoding::Dict;
    kwargs...
)
    dt = DecisionTree[]
    for (i, t) in enumerate(stumps)
        idx = (i - 1) % length(encoding) + 1
        push!(dt, SoleModels.solemodel(t; majority=encoding[idx], kwargs...))
    end

    return dt
end

function SoleModels.solemodel(tree::InfoXGBNode, keep_condensed = false; majority, use_featurenames = true, kwargs...)
    # @show fieldnames(typeof(tree))
    use_featurenames = use_featurenames ? tree.info.featurenames : false
    root, info = begin
        if keep_condensed
            root = SoleModels.solemodel(tree.node; majority=majority, use_featurenames = use_featurenames, kwargs...)
            info = (;
                apply_preprocess=(y -> UInt32(findfirst(x -> x == y, tree.info.classlabels))),
                apply_postprocess=(y -> tree.info.classlabels[y]),
            )
            root, info
        else
            root = SoleModels.solemodel(tree.node; majority=majority, replace_classlabels = tree.info.classlabels, use_featurenames = use_featurenames, kwargs...)
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

function SoleModels.solemodel(tree::XGB.Node; majority, replace_classlabels = nothing, use_featurenames = false)
    if isempty(tree.children)
    # leaf
        prediction = majority.ref
        # labels = tree.leaf
        # if !isnothing(replace_classlabels)
        #     prediction = replace_classlabels[prediction]
        #     labels = replace_classlabels[labels]
        # end
        # info = (;
        #     supporting_predictions = fill(prediction, length(labels)),
        #     supporting_labels = labels,
        # )
        ### TODO
        labels = [1,1,1,1]
        info = (;
        supporting_predictions = fill(prediction, length(labels)),
        supporting_labels = labels,
    )
        return ConstantModel(prediction, info)
    else
    # node
        test_operator = (<)
        # @show fieldnames(typeof(tree))
        feature = (use_featurenames != false) ? VariableValue(use_featurenames[split2id(tree.split)]) : VariableValue(split2id(tree.split))
        cond = ScalarCondition(feature, test_operator, tree.split_condition)
        antecedent = Atom(cond)
        lefttree = SoleModels.solemodel(tree.children[1]; majority=majority, replace_classlabels=replace_classlabels, use_featurenames=use_featurenames)
        righttree = SoleModels.solemodel(tree.children[2]; majority=majority, replace_classlabels=replace_classlabels, use_featurenames=use_featurenames)
        info = (;
            supporting_predictions = [lefttree.info[:supporting_predictions]..., righttree.info[:supporting_predictions]...],
            supporting_labels = [lefttree.info[:supporting_labels]..., righttree.info[:supporting_labels]...],
        )
        return Branch(antecedent, lefttree, righttree, info)
    end
end

# MMI.reports_feature_importances(::Type{<:XGBoostAbstractRegressor}) = true
# MMI.reports_feature_importances(::Type{<:XGBoostAbstractClassifier}) = true

# export XGBoostClassifier, XGBoostCount, XGBoostRegressor

# function MMI.fit(
#     m::XGBoostClassifier,
#     verbosity::Int,
#     X,
#     y,
#     features,
#     classes,
#     )

#     integers_seen = unique(y)
#     classes_seen  = MMI.decoder(classes)(integers_seen)

#     # dX = if isnothing(weight)
#     #     XGB.DMatrix(X, y_code; feature_names=names(X))
#     #     # XGB.DMatrix(MMI.matrix(X), y_code)
#     # else
#     #     XGB.DMatrix(X, y_code; feature_names=names(X), weight = weight)
#     #     # XGB.DMatrix(MMI.matrix(X), y_code; feature_names=names(X), weight = weight)
#     # end

#     # bst = xgboost(dm; kwargs(model, verbosity, objective)..., num_class...)
#     nclass = length(classes_seen)
#     if isnothing(m.objective)
#         m.objective = nclass == 2 ? "binary:logistic" : "multi:softprob"
#     end
    
#     params = Dict((field, getfield(m, field)) for field in fieldnames(typeof(m)))
#     bst = XGB.xgboost((X, y.-1); verbosity=verbosity, params..., num_class=nclass)

#     # imp = XGB.importancetable(bst)
#     ts = XGB.trees(bst)

#     verbosity < 2 || AbstractTrees.print_tree(ts, m.max_depth)

#     fitresult = (bst, classes_seen, integers_seen, features)

#     cache  = nothing
#     report = (
#         classes_seen=nclass,
#         print_tree=TreePrinter(ts, features),
#         features=features,
#     )
#     return fitresult, cache, report
# end

# get_encoding(classes_seen) = Dict(MMI.int(c) => c for c in classes(classes_seen))
# classlabels(encoding) = [string(encoding[i]) for i in sort(keys(encoding) |> collect)]

# struct InfoXGBNode
#     node::XGB.Node
#     info::NamedTuple
# end
# AbstractTrees.nodevalue(n::InfoXGBNode) = n.node

# struct InfoXGBLeaf
#     node::XGB.Node
#     info::NamedTuple
# end
# AbstractTrees.nodevalue(l::InfoXGBLeaf) = l.node

# # struct InfoNode{S,T} <: AbstractTrees.AbstractNode{DecisionTree.Node{S,T}}
# #     node::DecisionTree.Node{S,T}
# #     info::NamedTuple
# # end
# # AbstractTrees.nodevalue(n::InfoNode) = n.node

# # struct InfoLeaf{T} <: AbstractTrees.AbstractNode{DecisionTree.Leaf{T}}
# #     leaf::DecisionTree.Leaf{T}
# #     info::NamedTuple
# # end
# # AbstractTrees.nodevalue(l::InfoLeaf) = l.leaf

# isleaf(node::XGB.Node) = isempty(node.children) ? true : false

# wrap(vecnode::Vector{<:XGB.Node}, info::NamedTuple=NamedTuple()) = MLJXGBoostInterface.wrap.(vecnode, Ref(info))
# # wrap(tree::DecisionTree.Root, info::NamedTuple=NamedTuple()) = wrap(tree.node, info)
# wrap(node::XGB.Node, info::NamedTuple=NamedTuple()) = isleaf(node) ? InfoXGBLeaf(node, info) : InfoXGBNode(node, info)
# # wrap(leaf::DecisionTree.Leaf, info::NamedTuple=NamedTuple()) = InfoLeaf(leaf, info)

# function MMI.fitted_params(::XGBoostAbstractClassifier, fitresult)
#     raw_tree = XGB.trees(fitresult[1])
#     encoding = get_encoding(fitresult[2])
#     features = fitresult[4]
#     classlabels = MLJXGBoostInterface.classlabels(encoding)
#     info = (featurenames=features, classlabels)
#     tree = MLJXGBoostInterface.wrap(raw_tree, info,)
#     (; tree, raw_tree, encoding, features)
# end

# function AbstractTrees.children(node::InfoXGBNode) 
#     (wrap(node.children[1], node.info), wrap(node.children[2], node.info))
# end
# AbstractTrees.children(node::InfoXGBLeaf) = ()

# # to get column names based on table access type:
# _columnnames(X) = _columnnames(X, Val(Tables.columnaccess(X))) |> collect
# _columnnames(X, ::Val{true}) = Tables.columnnames(Tables.columns(X))
# _columnnames(X, ::Val{false}) = Tables.columnnames(first(Tables.rows(X)))

# MMI.reformat(::XGBoostAbstractClassifier, X, y) =
#     (XGB.DMatrix(X), MMI.int(y), _columnnames(X), classes(y))
# # MMI.reformat(::Regressor, X, y) =
# #     (Tables.matrix(X), float(y), _columnnames(X))
# # MMI.selectrows(::TreeModel, I, Xmatrix, y, meta...) =
# #     (view(Xmatrix, I, :), view(y, I), meta...)

# split2id(str::String) = parse(Int, filter(isdigit, str)) + 1



end