using MLJ
using DataFrames

import MLJModelInterface as MMI
using SoleModels
import XGBoost as XGB
using CategoricalArrays
using Random

# References:
# https://github.com/chengjunhou/xgb2sql/issues/1
# https://xgboost.readthedocs.io/en/latest/R-package/xgboostfromJSON.html

# per me
# https://xgboost.readthedocs.io/en/latest/build.html

function predict_xgboost_bag(trees, X; n_classes=0, objective="binary:logistic")
    n_samples = size(X, 1)
    ntree_limit = length(trees)
    n_classes == 0 && throw(ArgumentError("n_classes must be specified for multi-class predictions"))
    
    # Initialize predictions
    if startswith(objective, "multi:softprob") || startswith(objective, "multi:softmax")
        # For multi-class probabilities, we need a matrix
        raw_preds = zeros(Float32, n_samples, n_classes)
    else
        # For binary and regression, a vector is sufficient
        raw_preds = zeros(Float32, n_samples)
    end
    
    # Iterate through trees and accumulate predictions
    for i in 1:ntree_limit
        tree = trees[i]
        tree_preds = predict_tree(tree, X)

        if startswith(objective, "multi:softprob") || startswith(objective, "multi:softmax")
            # For multi-class softprob, each tree outputs predictions for a specific class
            class_idx = (i - 1) % n_classes + 1
            raw_preds[:, class_idx] .+= tree_preds
        else
            # For binary or regression, simply add the predictions
            raw_preds .+= tree_preds
        end
    end
    # Apply appropriate transformation based on objective
    if objective == "binary:logistic"
        # Apply sigmoid transformation
        return 1.0 ./ (1.0 .+ exp.(-raw_preds))
    elseif objective == "multi:softprob"
        # Apply softmax transformation
        exp_preds = exp.(raw_preds)
        row_sums = sum(exp_preds, dims=2)
        return exp_preds ./ row_sums
    elseif objective == "multi:softmax"
        # Return class with highest score
        if n_classes > 1
            _, indices = findmax(raw_preds, dims=2)
            return [idx[2] for idx in indices]
        else
            return raw_preds .> 0
        end
    elseif objective == "count:poisson"
        # Apply exponential transformation for Poisson
        return exp.(raw_preds)
    else
        # For regression or other objectives, return raw predictions
        return raw_preds
    end
end

function predict_tree(tree, X)
    n_samples = size(X, 1)
    predictions = zeros(Float32, n_samples)
    
    for i in 1:n_samples
        predictions[i] = traverse_tree(tree, X[i, :])
    end
    return predictions
end

function traverse_tree(tree, x)
    # Start at root node
    node = tree  # Adjust based on your tree structure
    
    # Traverse until reaching a leaf
    while !isempty(node.children)
        # Get the split feature and value
        feature_idx = node.split
        split_value = Float32(node.split_condition)
        
        # Decide which child to go to
        if x[feature_idx] < split_value
            node = node.children[1]
        else
            node = node.children[2]
        end
    end
    # Return the leaf value
    return Float32(node.leaf)
end

X, y = @load_iris
X = DataFrame(X)
train_ratio = 0.8
seed, num_round, eta = 3, 1, 0.1
rng = Xoshiro(seed)
train, test = partition(eachindex(y), train_ratio; shuffle=true, rng)
X_train, y_train = X[train, :], y[train]
X_test, y_test = X[test, :], y[test]

XGTrees = MLJ.@load XGBoostClassifier pkg=XGBoost
model = XGTrees(; num_round, eta, objective="multi:softprob")
mach = machine(model, X_train, y_train)
fit!(mach)
# mlj_predict = predict(mach, DataFrame(X_test[27,:]))
mlj_predict = predict(mach, DataFrame(X_test[28,:]))

trees = XGB.trees(mach.fitresult[1])
get_encoding(classes_seen) = Dict(MMI.int(c) => c for c in MMI.classes(classes_seen))
get_classlabels(encoding)  = [string(encoding[i]) for i in sort(keys(encoding) |> collect)]
encoding     = get_encoding(mach.fitresult[2])
classlabels  = get_classlabels(encoding)
featurenames = mach.report.vals[1].features

solem = solemodel(trees, Matrix(X_train), y_train; classlabels, featurenames, use_float32=false)
preds = apply(solem, DataFrame(reshape(Float32.(Vector(X_test[28,:])), 1, :), :auto)) # NOT WORKING
@test preds[1] == "versicolor"

solem = solemodel(trees, Matrix(X_train), y_train; classlabels, featurenames, use_float32=true)
preds = apply(solem, DataFrame(reshape(Float32.(Vector(X_test[28,:])), 1, :), :auto)) # WORKING
@test preds[1] == "virginica"

solem = solemodel(trees, Matrix(X_train), y_train; classlabels, featurenames)
preds = apply(solem, DataFrame(reshape(Float32.(Vector(X_test[28,:])), 1, :), :auto)) # WORKING
@test preds[1] == "virginica"

predsl = CategoricalArrays.levelcode.(categorical(preds)) .- 1

yl_train = CategoricalArrays.levelcode.(categorical(y_train)) .- 1
bst = XGB.xgboost((X_train, yl_train); num_round, eta, num_class=3, objective="multi:softprob")
xtrs = XGB.trees(bst)
# yyy = XGB.predict(bst, DataFrame(X_test[27,:])) # WORKING
yyy = XGB.predict(bst, DataFrame(X_test[28,:])) # NOT WORKING


# # For multi-class classification
rename!(X_test, [:f0, :f1, :f2, :f3])
# class_probs = predict_xgboost_bag(trees, DataFrame(X_test[27,:]); n_classes=3, objective="multi:softprob") # WORKING
class_probs = predict_xgboost_bag(trees, DataFrame(X_test[28,:]); n_classes=3, objective="multi:softprob") # NOT WORKING
class_preds = [argmax(probs) for probs in eachrow(class_probs)] .-1

X_train32 = DataFrame(Float32.(Matrix(X_train)), [:f0, :f1, :f2, :f3])
bst32 = XGB.xgboost((X_train32, yl_train); num_round, eta, num_class=3, objective="multi:softprob")
xtrs32 = XGB.trees(bst32)
X_test32 = DataFrame(reshape(Float32.(Vector(X_test[28,:])), 1, :), [:f0, :f1, :f2, :f3])
class_probs32 = predict_xgboost_bag(xtrs32, X_test32; n_classes=3, objective="multi:softprob") # NOT WORKING
