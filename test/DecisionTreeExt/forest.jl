# using SoleModels
# using MLJ
# using DataFrames, Random
# using DecisionTree
# const DT = DecisionTree

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
MLJ.fit!(mach)


classlabels = (mach).fitresult[2]
classlabels = classlabels[sortperm((mach).fitresult[3])]
featurenames = report(mach).features

solem = solemodel(fitted_params(mach).forest; classlabels, featurenames)
solem = solemodel(fitted_params(mach).forest; classlabels, featurenames, keep_condensed = false)

@test SoleData.scalarlogiset(X_test; allow_propositional = true) isa PropositionalLogiset

# Make test instances flow into the model
preds = apply(solem, X_test)
preds2 = apply!(solem, X_test, y_test)

@test preds == preds2
accuracy = sum(preds .== y_test)/length(y_test)
@test accuracy >= 0.8

# apply!(solem, X_test, y_test, mode = :append)

printmodel(solem; max_depth = 7, show_intermediate_finals = true, show_metrics = true)

# @test_broken printmodel.(listrules(solem, min_lift = 1.0, min_ninstances = 0); show_metrics = true);

# ---------------------------------------------------------------------------- #
#                                Data Validation                               #
# ---------------------------------------------------------------------------- #
@testset "data validation" begin
    Forest = MLJ.@load RandomForestClassifier pkg=DecisionTree

    for train_ratio in 0.7:0.1:0.9
        for seed in 1:10
            train, test = partition(eachindex(y), train_ratio; shuffle=true, rng=Xoshiro(seed))
            X_train, y_train = X[train, :], y[train]
            X_test, y_test = X[test, :], y[test]

            for n_trees in 10:10:50
                # solemodel
                model = Forest(; n_trees, rng=Xoshiro(seed))
                mach = machine(model, X_train, y_train)
                MLJ.fit!(mach, verbosity=0)
                classlabels = (mach).fitresult[2][sortperm((mach).fitresult[3])]
                featurenames = MLJ.report(mach).features
                solem = solemodel(MLJ.fitted_params(mach).forest; classlabels, featurenames, dt_bestguess=true)
                preds = apply!(solem, X_test, y_test)

                # decisiontree
                # rf_model = DT.build_forest(y_train, Matrix(X_train), -1, n_trees; rng=Xoshiro(seed))
                # rf_preds = DT.apply_forest(rf_model, Matrix(X_test))
                rf_preds = MLJ.predict_mode(mach, X_test)

                @test preds == rf_preds
            end
        end
    end
end

(train_ratio, seed, n_trees) = (0.7, 2, 20)
train, test = partition(eachindex(y), train_ratio; shuffle=true, rng=Xoshiro(seed))
X_train, y_train = X[train, :], y[train]
X_test, y_test = X[test, :], y[test]

model = Forest(; n_trees, rng=Xoshiro(seed))
mach = machine(model, X_train, y_train)
MLJ.fit!(mach, verbosity=0)
classlabels = (mach).fitresult[2][sortperm((mach).fitresult[3])]
featurenames = MLJ.report(mach).features
solem = solemodel(MLJ.fitted_params(mach).forest; classlabels, featurenames)
preds = apply!(solem, X_test, y_test)

# decisiontree
rf_model = DT.build_forest(y_train, Matrix(X_train), -1, n_trees; rng=Xoshiro(seed))
rf_preds = DT.apply_forest(rf_model, Matrix(X_test))