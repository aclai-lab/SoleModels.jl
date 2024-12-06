using Test

using MLJ
using MLJBase
using DataFrames

using MLJDecisionTreeInterface
using BenchmarkTools
using Sole

import DecisionTree as DT

X, y = @load_iris
X = DataFrame(X)

train_ratio = 0.8

train, test = partition(eachindex(y), train_ratio, shuffle=true)
X_train, y_train = X[train, :], y[train]
X_test, y_test = X[test, :], y[test]

println("Training set size: ", size(X_train), " - ", size(y_train))
println("Test set size: ", size(X_test), " - ", size(y_test))
println("Training set type: ", typeof(X_train), " - ", typeof(y_train))
println("Test set type: ", typeof(X_test), " - ", typeof(y_test))

Forest = MLJ.@load RandomForestClassifier pkg=DecisionTree

model = Forest(
  max_depth=3,
  min_samples_leaf=1,
  min_samples_split=2,
  n_trees = 10,
)

# Bind the model and data into a machine
mach = machine(model, X_train, y_train)
# Fit the model
fit!(mach)


sole_forest = solemodel(fitted_params(mach).forest)

@test SoleData.scalarlogiset(X_test; allow_propositional = true) isa PropositionalLogiset

# Make test instances flow into the model
apply!(sole_forest, X_test, y_test)

# apply!(sole_forest, X_test, y_test, mode = :append)

sole_forest = @test_nowarn @btime solemodel(fitted_params(mach).forest, true)
sole_forest = @test_nowarn @btime solemodel(fitted_params(mach).forest, false)

printmodel(sole_forest; max_depth = 7, show_intermediate_finals = true, show_metrics = true)

printmodel.(listrules(sole_forest, min_lift = 1.0, min_ninstances = 0); show_metrics = true);
