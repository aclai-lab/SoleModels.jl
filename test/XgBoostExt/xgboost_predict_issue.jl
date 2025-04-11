using MLJ
using DataFrames
using MLJXGBoostInterface
import MLJModelInterface as MMI
using SoleModels
import XGBoost as XGB
using CategoricalArrays
using Random

function predict_xgboost_bag(trees, X; n_classes=0, objective="binary:logistic")
    n_samples = size(X, 1)
    ntree_limit = length(trees)
    n_classes == 0 && throw(ArgumentError("n_classes must be specified for multi-class predictions"))
    
    # Initialize predictions
    if startswith(objective, "multi:softprob") || startswith(objective, "multi:softmax")
        # For multi-class probabilities, we need a matrix
        raw_preds = zeros(Float64, n_samples, n_classes)
    else
        # For binary and regression, a vector is sufficient
        raw_preds = zeros(Float64, n_samples)
    end
    
    # Iterate through trees and accumulate predictions
    for i in 1:ntree_limit
        tree = trees[i]
        tree_preds = predict_tree(tree, X)
        @show tree_preds
        if startswith(objective, "multi:softprob") || startswith(objective, "multi:softmax")
            # For multi-class softprob, each tree outputs predictions for a specific class
            class_idx = (i - 1) % n_classes + 1
            raw_preds[:, class_idx] .+= tree_preds
            @show class_idx
            @show raw_preds
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
        @show exp_preds
        @show row_sums
        @show exp_preds ./ row_sums
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
    predictions = zeros(Float64, n_samples)
    
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
        split_value = node.split_condition
        
        # Decide which child to go to
        if x[feature_idx] < split_value
            node = node.children[1]
        else
            node = node.children[2]
        end
    end
    # Return the leaf value
    return node.leaf
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
# mlj_predict = predict(mach, DataFrame(X_test[27,:])) # WORKING
mlj_predict = predict(mach, DataFrame(X_test[28,:])) # NOT WORKING
trees = XGB.trees(mach.fitresult[1])
get_encoding(classes_seen) = Dict(MMI.int(c) => c for c in MMI.classes(classes_seen))
get_classlabels(encoding)  = [string(encoding[i]) for i in sort(keys(encoding) |> collect)]
encoding     = get_encoding(mach.fitresult[2])
classlabels  = get_classlabels(encoding)
@show classlabels
featurenames = mach.report.vals[1].features
solem = solemodel(trees, Matrix(X_train), y_train; classlabels, featurenames)
# preds = apply(solem, DataFrame(X_test[27,:])) # WORKING
preds = apply(solem, DataFrame(X_test[28,:])) # NOT WORKING
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

isapprox(Float32.(class_probs), yyy, atol=1e-5)

# # For regression
# reg_preds = predict_xgboost_bag(mtrs, X_test, objective="reg:squarederror")

# num_round = 20
# eta = 0.3
# yl_train = CategoricalArrays.levelcode.(categorical(y_train)) .- 1
# bst = XGB.xgboost((X_train, yl_train); num_round, eta, num_class=3, objective="multi:softmax")
# ŷ = XGB.predict(bst, X_test)

### TREE 1
"""
xtrs[1].cover = 53.3333282
xtrs[1].gain = 55.7546806
xtrs[1].nmissing = 2
xtrs[1].yes = 1
xtrs[1].no = 2
xtrs[1].split = "petal_length"
xtrs[1].split_condition = 3.0

xtrs[1].children[1].cover = 16.8888874
xtrs[1].children[1].id = 1
xtrs[1].children[1].leaf = 0.141614899

xtrs[1].children[2].cover = 36.4444427
xtrs[1].children[2].id = 2
xtrs[1].children[2].leaf = -0.072997041

solem.models[1].info =
(leaf_values = [0.141614899, -0.072997041],
 supporting_predictions = CategoricalValue{String, UInt32}["setosa", "setosa", "setosa", "virginica", "virginica", "virginica"],
 supporting_labels = ["setosa", "virginica", "versicolor", "setosa", "virginica", "versicolor"],)

 sole.models[1].antecedent =
Atom{ScalarCondition{Float64, VariableValue{Int64, Symbol}, ScalarMetaCondition{VariableValue{Int64, Symbol}, typeof(<)}}}: [petal_length] < 3.0

solem.models[1].posconsequent.outcome = CategoricalValue{String, UInt32} "setosa"
solem.models[1].posconsequent.info =
(leaf_values = 0.141614899,
 supporting_predictions = CategoricalValue{String, UInt32}["setosa", "setosa", "setosa"],
 supporting_labels = ["setosa", "virginica", "versicolor"],)

solem.models[1].negconsequent.outcome = CategoricalValue{String, UInt32} "virginica"
 solem.models[1].negconsequent.info =
(leaf_values = -0.072997041,
 supporting_predictions = CategoricalValue{String, UInt32}["virginica", "virginica", "virginica"],
 supporting_labels = ["setosa", "virginica", "versicolor"],)
"""

### TREE 2
"""
xtrs[2].cover = 53.3333282
xtrs[2].gain = 11.9339008
xtrs[2].nmissing = 2
xtrs[2].yes = 1
xtrs[2].no = 2
xtrs[2].split = "petal_length"
xtrs[2].split_condition = 3.0

    xtrs[2]children[1].cover = 16.8888874
    xtrs[2]children[1].id = 1
    xtrs[2]children[1].leaf = -0.070807457

    xtrs[2].children[2].cover = 36.4444427
    xtrs[2].children[2].gain = 35.383049
    xtrs[2].children[2].nmissing = 4
    xtrs[2].children[2].yes = 3
    xtrs[2].children[2].no = 4
    xtrs[2].children[2].split = "petal_length"
    xtrs[2].children[2].split_condition = 4.9000001

        xtrs[2].children[2].children[1].cover = 17.7777767
        xtrs[2].children[2].children[1].gain = 4.09395218
        xtrs[2].children[2].children[1].nmissing = 6
        xtrs[2].children[2].children[1].yes = 5
        xtrs[2].children[2].children[1].no = 6
        xtrs[2].children[2].children[1].split = "petal_width"
        xtrs[2].children[2].children[1].split_condition = 1.70000005

            xtrs[2].children[2].children[1].children[1].cover = 15.999999
            xtrs[2].children[2].children[1].children[1].id = 5
            xtrs[2].children[2].children[1].children[1].leaf = 0.141176477

            xtrs[2].children[2].children[1].children[2].cover = 1.77777767
            xtrs[2].children[2].children[1].children[2].id = 6
            xtrs[2].children[2].children[1].children[2].leaf = -0.0120000029

        xtrs[2].children[2].children[2].cover = 18.666666
        xtrs[2].children[2].children[2].gain = 0.264455795
        xtrs[2].children[2].children[2].nmissing = 8
        xtrs[2].children[2].children[2].yes = 7
        xtrs[2].children[2].children[2].no = 8
        xtrs[2].children[2].children[2].split = "petal_width"
        xtrs[2].children[2].children[2].split_condition = 1.70000005

            xtrs[2].children[2].children[2].children[1].cover = 2.22222209
            xtrs[2].children[2].children[2].children[1].id = 7
            xtrs[2].children[2].children[2].children[1].leaf = -0.0206896588

            xtrs[2].children[2].children[2].children[2].cover = 16.4444427
            xtrs[2].children[2].children[2].children[2].id = 8
            xtrs[2].children[2].children[2].children[2].leaf = -0.0707006454

solem.models[2].info =
(leaf_values = [-0.070807457, 0.141176477, -0.0120000029, -0.0206896588, -0.0707006454],
 supporting_predictions = CategoricalValue{String, UInt32}["setosa", "setosa", "setosa", "versicolor", "versicolor", "versicolor", "virginica", "virginica", "virginica", "virginica", "virginica", "virginica", "virginica", "virginica", "virginica"],
 supporting_labels = ["setosa", "virginica", "versicolor", "setosa", "virginica", "versicolor", "setosa", "virginica", "versicolor", "setosa", "virginica", "versicolor", "setosa", "virginica", "versicolor"],)
solem.models[2].antecedent =
Atom{ScalarCondition{Float64, VariableValue{Int64, Symbol}, ScalarMetaCondition{VariableValue{Int64, Symbol}, typeof(<)}}}: [petal_length] < 3.0

    solem.models[2].posconsequent.outcome = CategoricalValue{String, UInt32} "setosa"
    solem.models[2].posconsequent.info =
    (leaf_values = -0.070807457,
    supporting_predictions = CategoricalValue{String, UInt32}["setosa", "setosa", "setosa"],
    supporting_labels = ["setosa", "virginica", "versicolor"],)

    solem.models[2].negconsequent.antecedent =
    Atom{ScalarCondition{Float64, VariableValue{Int64, Symbol}, ScalarMetaCondition{VariableValue{Int64, Symbol}, typeof(<)}}}: [petal_length] < 4.9000001
    solem.models[2].negconsequent.info =
    (leaf_values = [0.141176477, -0.0120000029, -0.0206896588, -0.0707006454],
    supporting_predictions = CategoricalValue{String, UInt32}["versicolor", "versicolor", "versicolor", "virginica", "virginica", "virginica", "virginica", "virginica", "virginica", "virginica", "virginica", "virginica"],
    supporting_labels = ["setosa", "virginica", "versicolor", "setosa", "virginica", "versicolor", "setosa", "virginica", "versicolor", "setosa", "virginica", "versicolor"],)

        solem.models[2].negconsequent.posconsequent.antecedent =
        Atom{ScalarCondition{Float64, VariableValue{Int64, Symbol}, ScalarMetaCondition{VariableValue{Int64, Symbol}, typeof(<)}}}: [petal_width] < 1.70000005
        solem.models[2].negconsequent.posconsequent.info =
        (leaf_values = [0.141176477, -0.0120000029],
        supporting_predictions = CategoricalValue{String, UInt32}["versicolor", "versicolor", "versicolor", "virginica", "virginica", "virginica"],
        supporting_labels = ["setosa", "virginica", "versicolor", "setosa", "virginica", "versicolor"],)

            solem.models[2].negconsequent.posconsequent.posconsequent.outcome = CategoricalValue{String, UInt32} "versicolor"
            solem.models[2].negconsequent.posconsequent.posconsequent.info =
            (leaf_values = 0.141176477,
            supporting_predictions = CategoricalValue{String, UInt32}["versicolor", "versicolor", "versicolor"],
            supporting_labels = ["setosa", "virginica", "versicolor"],)

            solem.models[2].negconsequent.posconsequent.negconsequent.outcome = CategoricalValue{String, UInt32} "virginica"
            solem.models[2].negconsequent.posconsequent.negconsequent.info =
            (leaf_values = -0.0120000029,
            supporting_predictions = CategoricalValue{String, UInt32}["virginica", "virginica", "virginica"],
            supporting_labels = ["setosa", "virginica", "versicolor"],)

        solem.models[2].negconsequent.negconsequent.antecedent =
        Atom{ScalarCondition{Float64, VariableValue{Int64, Symbol}, ScalarMetaCondition{VariableValue{Int64, Symbol}, typeof(<)}}}: [petal_width] < 1.70000005
        solem.models[2].negconsequent.negconsequent.info =
        (leaf_values = [-0.0206896588, -0.0707006454],
        supporting_predictions = CategoricalValue{String, UInt32}["virginica", "virginica", "virginica", "virginica", "virginica", "virginica"],
        supporting_labels = ["setosa", "virginica", "versicolor", "setosa", "virginica", "versicolor"],)

            solem.models[2].negconsequent.negconsequent.posconsequent.outcome = CategoricalValue{String, UInt32} "virginica"
            solem.models[2].negconsequent.negconsequent.posconsequent.info =
            (leaf_values = -0.0206896588,
            supporting_predictions = CategoricalValue{String, UInt32}["virginica", "virginica", "virginica"],
            supporting_labels = ["setosa", "virginica", "versicolor"],)

            solem.models[2].negconsequent.negconsequent.negconsequent.outcome = CategoricalValue{String, UInt32} "virginica"
            solem.models[2].negconsequent.negconsequent.negconsequent.info =
            (leaf_values = -0.0707006454,
            supporting_predictions = CategoricalValue{String, UInt32}["virginica", "virginica", "virginica"],
            supporting_labels = ["setosa", "virginica", "versicolor"],)
"""

### TREE 3
"""
xtrs[3].cover = 53.3333282
xtrs[3].gain = 51.9276886
xtrs[3].nmissing = 2
xtrs[3].yes = 1
xtrs[3].no = 2
xtrs[3].split = "petal_length"
xtrs[3].split_condition = 4.80000019

    xtrs[3].children[1].cover = 32.8888855
    xtrs[3].children[1].gain = 0.676908493
    xtrs[3].children[1].nmissing = 4
    xtrs[3].children[1].yes = 3
    xtrs[3].children[1].no = 4
    xtrs[3].children[1].split = "petal_width"
    xtrs[3].children[1].split_condition = 1.60000002

        xtrs[3].children[1].children[1].cover = 31.5555534
        xtrs[3].children[1].children[1].id = 3
        xtrs[3].children[1].children[1].leaf = -0.0726962537

        xtrs[3].children[1].children[2].cover = 1.33333325
        xtrs[3].children[1].children[2].id = 4
        xtrs[3].children[1].children[2].leaf = -2.55448485e-9

    xtrs[3].children[2].cover = 20.4444427
    xtrs[3].children[2].gain = 1.53349686
    xtrs[3].children[2].nmissing = 6
    xtrs[3].children[2].yes = 5
    xtrs[3].children[2].no = 6
    xtrs[3].children[2].split = "petal_length"
    xtrs[3].children[2].split_condition = 4.9000001

        xtrs[3].children[2].children[1].cover = 1.77777767
        xtrs[3].children[2].children[1].id = 5
        xtrs[3].children[2].children[1].leaf = 0.0239999983

        xtrs[3].children[2].children[2].cover = 18.666666
        xtrs[3].children[2].children[2].id = 6
        xtrs[3].children[2].children[2].leaf = 0.137288138

solem.models[3].info =
(leaf_values = [-0.0726962537, -2.55448485e-9, 0.0239999983, 0.137288138],
 supporting_predictions = CategoricalValue{String, UInt32}["setosa", "setosa", "setosa", "virginica", "virginica", "virginica", "virginica", "virginica", "virginica", "virginica", "virginica", "virginica"],
 supporting_labels = ["setosa", "virginica", "versicolor", "setosa", "virginica", "versicolor", "setosa", "virginica", "versicolor", "setosa", "virginica", "versicolor"],)
solem.models[3].antecedent = Atom{ScalarCondition{Float64, VariableValue{Int64, Symbol}, ScalarMetaCondition{VariableValue{Int64, Symbol}, typeof(<)}}}: [petal_length] < 4.80000019

    solem.models[3].posconsequent.info =
    (leaf_values = [-0.0726962537, -2.55448485e-9],
    supporting_predictions = CategoricalValue{String, UInt32}["setosa", "setosa", "setosa", "virginica", "virginica", "virginica"],
    supporting_labels = ["setosa", "virginica", "versicolor", "setosa", "virginica", "versicolor"],)
    solem.models[3].posconsequent.antecedent = Atom{ScalarCondition{Float64, VariableValue{Int64, Symbol}, ScalarMetaCondition{VariableValue{Int64, Symbol}, typeof(<)}}}: [petal_width] < 1.60000002

        solem.models[3].posconsequent.posconsequent.info
        (leaf_values = -0.0726962537,
        supporting_predictions = CategoricalValue{String, UInt32}["setosa", "setosa", "setosa"],
        supporting_labels = ["setosa", "virginica", "versicolor"],)
        solem.models[3].posconsequent.posconsequent.outcome = CategoricalValue{String, UInt32} "setosa"

        solem.models[3].posconsequent.negconsequent.info =
        (leaf_values = -2.55448485e-9,
        supporting_predictions = CategoricalValue{String, UInt32}["virginica", "virginica", "virginica"],
        supporting_labels = ["setosa", "virginica", "versicolor"],)
        solem.models[3].posconsequent.negconsequent.outcome = CategoricalValue{String, UInt32} "virginica"

    solem.models[3].negconsequent.info =
    (leaf_values = [0.0239999983, 0.137288138],
    supporting_predictions = CategoricalValue{String, UInt32}["virginica", "virginica", "virginica", "virginica", "virginica", "virginica"],
    supporting_labels = ["setosa", "virginica", "versicolor", "setosa", "virginica", "versicolor"],)
    solem.models[3].negconsequent.antecedent = Atom{ScalarCondition{Float64, VariableValue{Int64, Symbol}, ScalarMetaCondition{VariableValue{Int64, Symbol}, typeof(<)}}}: [petal_length] < 4.9000001

        solem.models[3].negconsequent.posconsequent.info =
        (leaf_values = 0.0239999983,
        supporting_predictions = CategoricalValue{String, UInt32}["virginica", "virginica", "virginica"],
        supporting_labels = ["setosa", "virginica", "versicolor"],)
        solem.models[3].negconsequent.posconsequent.outcome = CategoricalValue{String, UInt32} "virginica"

        solem.models[3].negconsequent.negconsequent.info =
        (leaf_values = 0.137288138,
        supporting_predictions = CategoricalValue{String, UInt32}["virginica", "virginica", "virginica"],
        supporting_labels = ["setosa", "virginica", "versicolor"],)
        solem.models[3].negconsequent.negconsequent.outcome = CategoricalValue{String, UInt32} "virginica"
"""

# calculating the probabilities

#  Row │ sepal_length  sepal_width  petal_length  petal_width 
#      │ Float64       Float64      Float64       Float64     
# ─────┼──────────────────────────────────────────────────────
#    1 │          6.9          3.1           4.9          1.5

### TREE 1: probability of setosa
"""
"petal_length" < 3.0 -- no >> leaf = -0.072997041
"""

### TREE 2: probability of versicolor
"""
"petal_length" < 3.0 -- no > "petal_length" < 4.9000001 -- yes > "petal_width" < 1.70000005 -- yes >> leaf = 0.141176477
"""

### TREE 1: probability of virginica
"""
"petal_length" < 4.80000019 -- no > "petal_length" < 4.9000001 -- yes >> leaf = 0.0239999983
"""

### calculatin multi:softprob
"""
exp_preds = exp.(-0.072997041 0.141176477 0.0239999983) = 0.929604  1.15163  1.02429
row_sums = sum(exp_preds, dims=2) = 3.1055217627515077
probability = exp_preds / row_sums = 0.299339  0.370832  0.329829

XGBoost probability:  0.304161  0.320495  0.375344
"""

"""
### ragionamento per assurdo: problema di arrotondamento ###
"petal_length" = 4.9
"petal_length" < 4.9000001 viene valutato come false

quindi: 
# tree 2
"petal_length" < 3.0 -- no > "petal_length" < 4.9000001 -- no > "petal_width" < 1.70000005 -- yes >> leaf = -0.0206896588
# tree 3
"petal_length" < 4.80000019 -- no > "petal_length" < 4.9000001 -- no >> leaf = 0.137288138
"""
exp_preds = exp.([-0.072997041, -0.0206896588, 0.137288138])
row_sums = sum(exp_preds)
probability = exp_preds ./ row_sums

"""
# 3-element Vector{Float64}:
#  0.3041612750760762
#  0.320494608175597
#  0.3753441167483268

#  XGBoost probability:  0.304161  0.320495  0.375344

PROBLEMA RISOLTO
se si valuta
4.9 < 4.9000001 false
allora si ottiene il risaultato del predict XGBoost
"""