module MLJXGBoostInterfaceExt

import MLJModelInterface as MMI
import XGBoost as XGB
import Tables
using CategoricalArrays
using AbstractTrees

import Sole: AbstractModel
import Sole: VariableValue, ScalarCondition, Atom, ConstantModel, Branch, DecisionTree

const PKG = "MLJXGBoostInterface"

abstract type XGBoostAbstractRegressor <: MMI.Deterministic end
abstract type XGBoostAbstractClassifier <: MMI.Probabilistic end

const XGTypes = Union{XGBoostAbstractRegressor,XGBoostAbstractClassifier}

struct TreePrinter{T}
    tree::T
    features::Vector{Symbol}
end
(c::TreePrinter)(depth) = AbstractTrees.print_tree(c.tree, depth, feature_names = c.features)
(c::TreePrinter)() = AbstractTrees.print_tree(c.tree, 5, feature_names = c.features)

Base.show(stream::IO, c::TreePrinter) =
    print(stream, "TreePrinter object (call with display depth)")

function classes(y)
    p = CategoricalArrays.pool(y)
    [p[i] for i in 1:length(p)]
end

# function modelexpr(name::Symbol, absname::Symbol, obj::AbstractString, objvalidate::Symbol)
function modelexpr(name::Symbol, absname::Symbol)
    metric = absname == :XGBoostAbstractClassifier ? "mlogloss" : "rmse"
    quote
        MMI.@mlj_model mutable struct $name <: $absname
        # MMI.@mlj_model mutable struct $name
            # ref: https://xgboost.readthedocs.io/en/stable/parameter.html
            # general parameters
            booster::String                     = "gbtree"
            # device::String                  = "cpu"
            eval_metric::String                 = $metric
            objective::Union{String, Nothing}   = nothing
            num_round::Int                      = 100::(_ ≥ 0)
            early_stopping_rounds::Int          = 0::(_ ≥ 0)
            

            # parameters for tree booster
            eta::Float64                        = 0.3::(0.0 ≤ _ ≤ 1.0)
            alpha::Float64                      = 0::(_ ≥ 0)
            gamma::Float64                      = 0::(_ ≥ 0)
            lambda::Float64                     = 1::(_ ≥ 0)

            max_depth::Int                      = 6::(_ ≥ 0)
            min_child_weight::Float64           = 1::(_ ≥ 0)
            max_delta_step::Float64             = 0::(_ ≥ 0)
            subsample::Float64                  = 1::(0 < _ ≤ 1)
            sampling_method::String             = "uniform"

            colsample_bynode::Float64           = 1::(0 < _ ≤ 1)        
            colsample_bylevel::Float64          = 1::(0 < _ ≤ 1)
            colsample_bytree::Float64           = 1::(0 < _ ≤ 1)

            tree_method::String                 = "auto"

            # scale_pos_weight::Float64           = 1.0
        end   


        #     # additional parameters for dart booster
        #     one_drop::Union{Int,Bool}       = 0::(0 ≤ _ ≤ 1)
        #     normalize_type::String          = "tree"
        #     rate_drop::Float64              = 0::(0 ≤ _ ≤ 1)
        #     sample_type::String             = "uniform"
        #     skip_drop::Float64              = 0::(0 ≤ _ ≤ 1)

        #     # additional parameters for linear booster
        #     feature_selector::String        = "cyclic"
        #     top_k::Int                      = 0::(_ ≥ 0)

        #     # additional parameters for tweedie regression
        #     tweedie_variance_power::Float64 = 1.5::(1 < _ < 2)

        #     # additional parameters for pseudo-huber
        #     # quantile_alpha TODO

        #     # additional parameters for quantile loss
        #     # quantile_alpha TODO

        #     # learning task parameters
        #     base_score::Float64             = 0.5


        #     # test::Int = 1::(_ ≥ 0)
        #     # sketch_eps::Float64 = 0.03::(0 < _ < 1)
        #     # predictor::String = "cpu_predictor"
        #     # watchlist = nothing  # if this is nothing we will not pass it so as to use default
        #     # importance_type::String = "gain"
        # end
    end
end

# eval(modelexpr(:XGBoostClassifier, :XGBoostAbstractClassifier, "automatic", :validate_class_objective))
# eval(modelexpr(:XGBoostCount, :XGBoostAbstractRegressor, "count:poisson", :validate_count_objective))
# eval(modelexpr(:XGBoostRegressor, :XGBoostAbstractRegressor, "reg:squarederror", :validate_reg_objective))

eval(modelexpr(:XGBoostClassifier, :XGBoostAbstractClassifier))
eval(modelexpr(:XGBoostCount,      :XGBoostAbstractRegressor))
eval(modelexpr(:XGBoostRegressor,  :XGBoostAbstractRegressor))

MMI.reports_feature_importances(::Type{<:XGBoostAbstractRegressor}) = true
MMI.reports_feature_importances(::Type{<:XGBoostAbstractClassifier}) = true

export XGBoostClassifier, XGBoostCount, XGBoostRegressor

function MMI.fit(
    m::XGBoostClassifier,
    verbosity::Int,
    X,
    y,
    features,
    classes,
    )

    integers_seen = unique(y)
    classes_seen  = MMI.decoder(classes)(integers_seen)

    # dX = if isnothing(weight)
    #     XGB.DMatrix(X, y_code; feature_names=names(X))
    #     # XGB.DMatrix(MMI.matrix(X), y_code)
    # else
    #     XGB.DMatrix(X, y_code; feature_names=names(X), weight = weight)
    #     # XGB.DMatrix(MMI.matrix(X), y_code; feature_names=names(X), weight = weight)
    # end

    # bst = xgboost(dm; kwargs(model, verbosity, objective)..., num_class...)
    nclass = length(classes_seen)
    if isnothing(m.objective)
        m.objective = nclass == 2 ? "binary:logistic" : "multi:softprob"
    end
    
    params = Dict((field, getfield(m, field)) for field in fieldnames(typeof(m)))
    bst = XGB.xgboost((X, y.-1); verbosity=verbosity, params..., num_class=nclass)

    # imp = XGB.importancetable(bst)
    ts = XGB.trees(bst)

    verbosity < 2 || AbstractTrees.print_tree(ts, m.max_depth)

    fitresult = (bst, classes_seen, integers_seen, features)

    cache  = nothing
    report = (
        classes_seen=nclass,
        print_tree=TreePrinter(ts, features),
        features=features,
    )
    return fitresult, cache, report
end

get_encoding(classes_seen) = Dict(MMI.int(c) => c for c in classes(classes_seen))
classlabels(encoding) = [string(encoding[i]) for i in sort(keys(encoding) |> collect)]

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

# struct InfoNode{S,T} <: AbstractTrees.AbstractNode{DecisionTree.Node{S,T}}
#     node::DecisionTree.Node{S,T}
#     info::NamedTuple
# end
# AbstractTrees.nodevalue(n::InfoNode) = n.node

# struct InfoLeaf{T} <: AbstractTrees.AbstractNode{DecisionTree.Leaf{T}}
#     leaf::DecisionTree.Leaf{T}
#     info::NamedTuple
# end
# AbstractTrees.nodevalue(l::InfoLeaf) = l.leaf

isleaf(node::XGB.Node) = isempty(node.children) ? true : false

wrap(vecnode::Vector{<:XGB.Node}, info::NamedTuple=NamedTuple()) = MLJXGBoostInterface.wrap.(vecnode, Ref(info))
# wrap(tree::DecisionTree.Root, info::NamedTuple=NamedTuple()) = wrap(tree.node, info)
wrap(node::XGB.Node, info::NamedTuple=NamedTuple()) = isleaf(node) ? InfoXGBLeaf(node, info) : InfoXGBNode(node, info)
# wrap(leaf::DecisionTree.Leaf, info::NamedTuple=NamedTuple()) = InfoLeaf(leaf, info)

function MMI.fitted_params(::XGBoostAbstractClassifier, fitresult)
    raw_tree = XGB.trees(fitresult[1])
    encoding = get_encoding(fitresult[2])
    features = fitresult[4]
    classlabels = MLJXGBoostInterface.classlabels(encoding)
    info = (featurenames=features, classlabels)
    tree = MLJXGBoostInterface.wrap(raw_tree, info,)
    (; tree, raw_tree, encoding, features)
end

function AbstractTrees.children(node::InfoXGBNode) 
    (wrap(node.children[1], node.info), wrap(node.children[2], node.info))
end
AbstractTrees.children(node::InfoXGBLeaf) = ()

# to get column names based on table access type:
_columnnames(X) = _columnnames(X, Val(Tables.columnaccess(X))) |> collect
_columnnames(X, ::Val{true}) = Tables.columnnames(Tables.columns(X))
_columnnames(X, ::Val{false}) = Tables.columnnames(first(Tables.rows(X)))

MMI.reformat(::XGBoostAbstractClassifier, X, y) =
    (XGB.DMatrix(X), MMI.int(y), _columnnames(X), classes(y))
# MMI.reformat(::Regressor, X, y) =
#     (Tables.matrix(X), float(y), _columnnames(X))
# MMI.selectrows(::TreeModel, I, Xmatrix, y, meta...) =
#     (view(Xmatrix, I, :), view(y, I), meta...)

split2id(str::String) = parse(Int, filter(isdigit, str)) + 1

function solemodel(
    tree::Vector{<:InfoXGBNode},
    raw_tree::Vector{<:XGB.Node},
    encoding::Dict,
    features::Vector{Symbol};
    kwargs...
)
    dt = DecisionTree[]
    @show encoding
    for (i, t) in enumerate(tree)
        idx = (i - 1) % length(encoding) + 1
        push!(dt, MLJXGBoostInterface.solemodel(t; majority=encoding[idx], kwargs...))
    end

    return dt
end
function solemodel(tree::InfoXGBNode, keep_condensed = false; majority, use_featurenames = true, kwargs...)
    # @show fieldnames(typeof(tree))
    use_featurenames = use_featurenames ? tree.info.featurenames : false
    root, info = begin
        if keep_condensed
            root = MLJXGBoostInterface.solemodel(tree.node; majority=majority, use_featurenames = use_featurenames, kwargs...)
            info = (;
                apply_preprocess=(y -> UInt32(findfirst(x -> x == y, tree.info.classlabels))),
                apply_postprocess=(y -> tree.info.classlabels[y]),
            )
            root, info
        else
            root = MLJXGBoostInterface.solemodel(tree.node; majority=majority, replace_classlabels = tree.info.classlabels, use_featurenames = use_featurenames, kwargs...)
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

function solemodel(tree::XGB.Node; majority, replace_classlabels = nothing, use_featurenames = false)
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
        lefttree = MLJXGBoostInterface.solemodel(tree.children[1]; majority=majority, replace_classlabels=replace_classlabels, use_featurenames=use_featurenames)
        righttree = MLJXGBoostInterface.solemodel(tree.children[2]; majority=majority, replace_classlabels=replace_classlabels, use_featurenames=use_featurenames)
        info = (;
            supporting_predictions = [lefttree.info[:supporting_predictions]..., righttree.info[:supporting_predictions]...],
            supporting_labels = [lefttree.info[:supporting_labels]..., righttree.info[:supporting_labels]...],
        )
        return Branch(antecedent, lefttree, righttree, info)
    end
end

end