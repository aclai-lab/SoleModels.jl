using Test

using MLJ
using MLJBase
using DataFrames

using MLJDecisionTreeInterface
using SoleModels

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

Tree = MLJ.@load DecisionTreeClassifier pkg=DecisionTree

model = Tree(
  max_depth=-1,
  min_samples_leaf=1,
  min_samples_split=2,
)

# Bind the model and data into a machine
mach = machine(model, X_train, y_train)
# Fit the model
fit!(mach)


solem = solemodel(fitted_params(mach).tree)
solem = solemodel(fitted_params(mach).tree; keep_condensed = false)

@test SoleData.scalarlogiset(X_test; allow_propositional = true) isa PropositionalLogiset

# Make test instances flow into the model
preds = apply(solem, X_test)
preds2 = apply!(solem, X_test, y_test)

@test preds == preds2
@test sum(preds .== y_test)/length(y_test) > 0.7

# apply!(solem, X_test, y_test, mode = :append)

solem = @test_nowarn solemodel(fitted_params(mach).tree; keep_condensed = true)
solem = @test_nowarn solemodel(fitted_params(mach).tree; keep_condensed = false)

printmodel(solem; max_depth = 7, show_intermediate_finals = true, show_metrics = true)

printmodel.(listrules(solem, min_lift = 1.0, min_ninstances = 0); show_metrics = true);

printmodel.(listrules(solem, min_lift = 1.0, min_ninstances = 0); show_metrics = true, show_subtree_metrics = true);

printmodel.(listrules(solem, min_lift = 1.0, min_ninstances = 0); show_metrics = true, show_subtree_metrics= true, tree_mode=true);

readmetrics.(listrules(solem; min_lift=1.0, min_ninstances = 0))

printmodel.(listrules(solem, min_lift = 1.0, min_ninstances = 0); show_metrics = true);

interesting_rules = listrules(solem; min_lift=1.0, min_ninstances = 0, custom_thresholding_callback = (ms)->ms.coverage*ms.ninstances >= 4)
# printmodel.(sort(interesting_rules, by = readmetrics); show_metrics = (; round_digits = nothing, ));
printmodel.(sort(interesting_rules, by = readmetrics); show_metrics = (; round_digits = nothing, additional_metrics = (; length = r->natoms(antecedent(r)))));

@test length(joinrules(interesting_rules)) == 3
@test (natoms.((interesting_rules)) |> sum) == (natoms.(joinrules(interesting_rules)) |> sum)
