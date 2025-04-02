using Test

using MLJ
using MLJBase
using DataFrames

using MLJXGBoostInterface
using SoleModels

import XGBoost as XGB

using Random, CategoricalArrays

X, y = @load_iris
X = DataFrame(X)

train_ratio = 0.8
rng = Xoshiro(11)

train, test = partition(eachindex(y), train_ratio; shuffle=true, rng)
X_train, y_train = X[train, :], y[train]
X_test, y_test = X[test, :], y[test]

println("Training set size: ", size(X_train), " - ", size(y_train))
println("Test set size: ", size(X_test), " - ", size(y_test))
println("Training set type: ", typeof(X_train), " - ", typeof(y_train))
println("Test set type: ", typeof(X_test), " - ", typeof(y_test))

XGTrees = MLJ.@load XGBoostClassifier pkg=XGBoost

model = XGTrees(;
    num_round=10,
    max_depth=6,
    objective="multi:softmax"
)

# Bind the model and data into a machine
mach = machine(model, X_train, y_train)
# Fit the model
fit!(mach)

trees = XGB.trees(mach.fitresult[1])

featurenames = mach.report.vals[1][1]
ds_safetest = vcat(y, "nothing")


solem = solemodel(trees, Matrix(X), ds_safetest)
solem = solemodel(trees, Matrix(X), ds_safetest; featurenames)
solem = solemodel(trees, Matrix(X), ds_safetest; featurenames, keep_condensed = false)

@test SoleData.scalarlogiset(X_test; allow_propositional = true) isa PropositionalLogiset

# Make test instances flow into the model
preds = apply(solem, X_test)
preds2 = apply!(solem, X_test, y_test)

@test preds == preds2
accuracy = sum(preds .== y_test)/length(y_test)
@test accuracy > 0.7

# apply!(solem, X_test, y_test, mode = :append)

solem = @test_throws ErrorException solemodel(trees, Matrix(X), ds_safetest; featurenames, keep_condensed = true)
solem = @test_nowarn solemodel(trees, Matrix(X), ds_safetest; featurenames, keep_condensed = false)

printmodel(solem; max_depth = 7, show_intermediate_finals = true, show_metrics = true)

# comparision with XGBoost.jl

yl_train = CategoricalArrays.levelcode.(categorical(y_train)) .- 1
# create and train a gradient boosted tree model of 5 trees
bst = XGB.xgboost(
    (X_train, yl_train),
    num_round=10,
    num_class=3,
    max_depth=6,
    objective="multi:softmax"
)
# obtain model predictions
ŷ = XGB.predict(bst, X_test)

