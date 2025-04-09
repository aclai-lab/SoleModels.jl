using Test

using MLJ
using MLJBase
using DataFrames

using MLJXGBoostInterface
using SoleModels

import MLJModelInterface as MMI
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
    num_round=1,
    max_depth=6,
    objective="multi:softmax"
)

# Bind the model and data into a machine
mach = machine(model, X_train, y_train)
# Fit the model
fit!(mach)

trees = XGB.trees(mach.fitresult[1])

get_encoding(classes_seen) = Dict(MMI.int(c) => c for c in MMI.classes(classes_seen))
get_classlabels(encoding)  = [string(encoding[i]) for i in sort(keys(encoding) |> collect)]
encoding     = get_encoding(mach.fitresult[2])
classlabels  = get_classlabels(encoding)
featurenames = mach.report.vals[1].features
# ds_safetest = vcat(y_train, "nothing")

# solem = solemodel(trees, Matrix(X_train), y_train)
solem = solemodel(trees, Matrix(X_train), y_train; classlabels, featurenames)
solem = solemodel(trees, Matrix(X_train), y_train; classlabels, featurenames, keep_condensed = false)

@test SoleData.scalarlogiset(X_test; allow_propositional = true) isa PropositionalLogiset

# Make test instances flow into the model
preds = apply(solem, X_test)
# preds2 = apply!(solem, X_test, y_test)

# @test preds == preds2
accuracy = sum(preds .== y_test)/length(y_test)
@test accuracy > 0.9

# apply!(solem, X_test, y_test, mode = :append)

solem = @test_throws ErrorException solemodel(trees, Matrix(X_train), y_train; classlabels, keep_condensed = true)
solem = @test_nowarn solemodel(trees, Matrix(X_train), y_train; classlabels, keep_condensed = false)

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

predsl = CategoricalArrays.levelcode.(categorical(preds)) .- 1
@test predsl == ŷ

outperform = 0
underperform = 0
i = 0

for seed in 1:40
    rng = Xoshiro(seed)
    train, test = partition(eachindex(y), train_ratio; shuffle=true, rng)
    X_train, y_train = X[train, :], y[train]
    X_test, y_test = X[test, :], y[test]
    for num_round in 10:10:100
        for eta in 0.1:0.1:0.9
            model = XGTrees(; num_round, eta, objective="multi:softmax")
            mach = machine(model, X_train, y_train)
            fit!(mach)
            trees = XGB.trees(mach.fitresult[1])
            solem = solemodel(trees, Matrix(X_train), y_train; classlabels, featurenames)
            preds = apply(solem, X_test)
            predsl = CategoricalArrays.levelcode.(categorical(preds))

            yl_train = CategoricalArrays.levelcode.(categorical(y_train)) .- 1
            bst = XGB.xgboost((X_train, yl_train); num_round, eta, num_class=3, objective="multi:softmax")
            ŷ = XGB.predict(bst, X_test)

            sole_accuracy = sum(predsl .== CategoricalArrays.levelcode.(categorical(y_test)))/length(y_test)
            xgb_accuracy = sum(ŷ .== CategoricalArrays.levelcode.(categorical(y_test)) .- 1)/length(y_test)

            sole_accuracy > xgb_accuracy && global outperform += 1
            sole_accuracy < xgb_accuracy && global underperform += 1
            i += 1
        end
    end
end

@test outperform > underperform
println("SoleModel outperformed XGBoost in $outperform out of $i tests.")
println("SoleModel underperform XGBoost in $underperform out of $i tests.")

