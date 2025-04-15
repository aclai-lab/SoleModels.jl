using Test

using MLJ
using MLJBase
using DataFrames

using MLJDecisionTreeInterface
using SoleModels
using Random

import DecisionTree as DT

X, y = @load_iris
X = DataFrame(X)

train_ratio = 0.7
rng = Xoshiro(11)

train, test = partition(eachindex(y), train_ratio; shuffle=true, rng)
X_train, y_train = X[train, :], y[train]
X_test, y_test = X[test, :], y[test]

println("Training set size: ", size(X_train), " - ", size(y_train))
println("Test set size: ", size(X_test), " - ", size(y_test))
println("Training set type: ", typeof(X_train), " - ", typeof(y_train))
println("Test set type: ", typeof(X_test), " - ", typeof(y_test))

# ---------------------------------------------------------------------------- #
#                              AdaBoost solemodel                              #
# ---------------------------------------------------------------------------- #
Stump = MLJ.@load AdaBoostStumpClassifier pkg=DecisionTree

model = Stump(;
    n_iter=10, 
    feature_importance=:impurity, 
    rng
)

# Bind the model and data into a machine
mach = machine(model, X_train, y_train)
# Fit the model
fit!(mach)

weights = mach.fitresult[2]
classlabels = sort(mach.fitresult[3])
featurenames = MLJ.report(mach).features

solem = solemodel(MLJ.fitted_params(mach).stumps; weights, classlabels, featurenames)
solem = solemodel(MLJ.fitted_params(mach).stumps; weights, classlabels, featurenames, keep_condensed = false)

@test SoleData.scalarlogiset(X_test; allow_propositional = true) isa PropositionalLogiset

# Make test instances flow into the model
preds = apply(solem, X_test)
preds2 = apply!(solem, X_test, y_test)

@test preds == preds2

# apply!(solem, X_test, y_test, mode = :append)

printmodel(solem; max_depth = 7, show_intermediate_finals = true, show_metrics = true)

# @test_broken printmodel.(listrules(solem, min_lift = 1.0, min_ninstances = 0); show_metrics = true);

# ---------------------------------------------------------------------------- #
#                            AdaBoost decisiontree                             #
# ---------------------------------------------------------------------------- #
# train adaptive-boosted stumps, using 10 iterations
dt_model, dt_coeffs = DT.build_adaboost_stumps(y_train, Matrix(X_train), 10)
# apply learned model
dt_preds = apply_adaboost_stumps(dt_model, dt_coeffs, Matrix(X_test))
# get the probability of each label
dt_proba = apply_adaboost_stumps_proba(dt_model, dt_coeffs, Matrix(X_test), classlabels)

@test preds == dt_preds

# ---------------------------------------------------------------------------- #
#                                    Accuracy                                  #
# ---------------------------------------------------------------------------- #
ada_accuracy = sum(preds .== y_test)/length(y_test)
# @test accuracy >= 0.8

# decision tree
Tree = MLJ.@load DecisionTreeClassifier pkg=DecisionTree
dt_model = Tree(max_depth=-1, min_samples_leaf=1, min_samples_split=2)
dt_mach = machine(dt_model, X_train, y_train)
fit!(dt_mach)
dt_solem = solemodel(fitted_params(dt_mach).tree)
dt_preds = apply(dt_solem, X_test)
dt_accuracy = sum(dt_preds .== y_test)/length(y_test)

# random forest
Forest = MLJ.@load RandomForestClassifier pkg=DecisionTree
rm_model = Forest(max_depth=3, min_samples_leaf=1, min_samples_split=2, n_trees=10)
rm_mach = machine(rm_model, X_train, y_train)
fit!(rm_mach)
classlabels = (rm_mach).fitresult[2]
classlabels = classlabels[sortperm((rm_mach).fitresult[3])]
featurenames = report(rm_mach).features
rm_solem = solemodel(fitted_params(rm_mach).forest; classlabels, featurenames)
rm_preds = apply(rm_solem, X_test)
rm_accuracy = sum(rm_preds .== y_test)/length(y_test)

println("AdaBoost     accuracy: ", ada_accuracy)
println("DecisionTree accuracy: ", dt_accuracy)
println("RandomForest accuracy: ", rm_accuracy)

@test ada_accuracy ≥ rm_accuracy ≥ dt_accuracy

# ---------------------------------------------------------------------------- #
#                                Data Validation                               #
# ---------------------------------------------------------------------------- #
@testset "data validation" begin
    Stump = MLJ.@load AdaBoostStumpClassifier pkg=DecisionTree

    for train_ratio in 0.5:0.1:0.9
        for seed in 1:40
            train, test = partition(eachindex(y), train_ratio; shuffle=true, rng=Xoshiro(seed))
            X_train, y_train = X[train, :], y[train]
            X_test, y_test = X[test, :], y[test]

            for n_iter in 10:10:100
                # solemodel
                model = Stump(; n_iter, rng=Xoshiro(seed))
                mach = machine(model, X_train, y_train)
                fit!(mach)
                weights = mach.fitresult[2]
                classlabels = sort(mach.fitresult[3])
                featurenames = MLJ.report(mach).features
                solem = solemodel(MLJ.fitted_params(mach).stumps; weights, classlabels, featurenames)
                preds = apply(solem, X_test)

                # decisiontree
                yl_train = CategoricalArrays.levelcode.(y_train)
                dt_model, dt_coeffs = DT.build_adaboost_stumps(yl_train, Matrix(X_train), n_iter; rng=Xoshiro(seed))
                dt_preds = apply_adaboost_stumps(dt_model, dt_coeffs, Matrix(X_test))

                code_preds = CategoricalArrays.levelcode.(preds)
                @test code_preds == dt_preds
            end
        end
    end
end

