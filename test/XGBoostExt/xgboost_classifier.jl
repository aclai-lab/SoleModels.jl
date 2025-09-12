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
#                              XGBoost solemodel                               #
# ---------------------------------------------------------------------------- #
XGTrees = MLJ.@load XGBoostClassifier pkg=XGBoost

model = XGTrees(;
    num_round=10,
    tree_method="exact",
    objective="multi:softmax"
)

# Bind the model and data into a machine
mach = machine(model, X_train, y_train)
# Fit the model
fit!(mach; verbosity=0)

get_encoding(classes_seen) = Dict(MMI.int(c) => c for c in MMI.classes(classes_seen))
get_classlabels(encoding)  = [string(encoding[i]) for i in sort(keys(encoding) |> collect)]
trees = XGB.trees(mach.fitresult[1])
encoding     = get_encoding(mach.fitresult[2])
classlabels  = get_classlabels(encoding)
featurenames = mach.report.vals[1].features

solem = solemodel(trees, Matrix(X_train), y_train; classlabels, featurenames)
solem = solemodel(trees, Matrix(X_train), y_train; classlabels, featurenames, keep_condensed = false)

@test SoleData.scalarlogiset(X_test; allow_propositional = true) isa PropositionalLogiset

# Make test instances flow into the model
X_test_f32 = mapcols(col -> Float32.(col), X_test)
preds = apply(solem, X_test_f32)
predsl = CategoricalArrays.levelcode.(CategoricalArrays.categorical(preds)) .- 1

apply!(solem, X_test, y_test)
@test solem.info.supporting_predictions == preds
@test solem.info.supporting_labels == y_test

# ---------------------------------------------------------------------------- #
#                                 julia XGBoost                                #
# ---------------------------------------------------------------------------- #
yl_train = CategoricalArrays.levelcode.(CategoricalArrays.categorical(y_train)) .- 1
# create and train a gradient boosted tree model of 5 trees
bst = XGB.xgboost(
    (X_train, yl_train),
    num_round=10,
    num_class=3,
    tree_method="exact",
    objective="multi:softmax"
)
# obtain model predictions
xg_preds = XGB.predict(bst, X_test)

@test predsl == xg_preds

# ---------------------------------------------------------------------------- #
#                                    Accuracy                                  #
# ---------------------------------------------------------------------------- #
xg_accuracy = sum(preds .== y_test)/length(y_test)
# @test accuracy >= 0.8

# decision tree
Tree = MLJ.@load DecisionTreeClassifier pkg=DecisionTree
dt_model = Tree(max_depth=-1, min_samples_leaf=1, min_samples_split=2)
dt_mach = machine(dt_model, X_train, y_train)
fit!(dt_mach, verbosity=0)
dt_solem = solemodel(fitted_params(dt_mach).tree)
dt_preds = apply(dt_solem, X_test)
dt_accuracy = sum(dt_preds .== y_test)/length(y_test)

# random forest
Forest = MLJ.@load RandomForestClassifier pkg=DecisionTree
rm_model = Forest(;max_depth=3, min_samples_leaf=1, min_samples_split=2, n_trees=10, rng)
rm_mach = machine(rm_model, X_train, y_train)
fit!(rm_mach, verbosity=0)
classlabels = (rm_mach).fitresult[2]
classlabels = classlabels[sortperm((rm_mach).fitresult[3])]
featurenames = report(rm_mach).features
rm_solem = solemodel(fitted_params(rm_mach).forest; classlabels, featurenames)
rm_preds = apply(rm_solem, X_test)
rm_accuracy = sum(rm_preds .== y_test)/length(y_test)

println("XGBoost      accuracy: ", xg_accuracy)
println("DecisionTree accuracy: ", dt_accuracy)
println("RandomForest accuracy: ", rm_accuracy)

@test xg_accuracy ≥ rm_accuracy ≥ dt_accuracy

# ---------------------------------------------------------------------------- #
#                               XGBoost Alphabet                               #
# ---------------------------------------------------------------------------- #
@test_nowarn alphabet(fitted_params(mach).fitresult[1])

# ---------------------------------------------------------------------------- #
#                                Data Validation                               #
# ---------------------------------------------------------------------------- #
@testset "data validation" begin
    XGTrees = MLJ.@load XGBoostClassifier pkg=XGBoost

    for train_ratio in 0.7:0.1:0.9
        for seed in 1:10
            train, test = partition(eachindex(y), train_ratio; shuffle=true, rng=Xoshiro(seed))
            X_train, y_train = X[train, :], y[train]
            X_test, y_test = X[test, :], y[test]

            for num_round in 10:10:20
                for eta in 0.1:0.1:0.3
                    model = XGTrees(; num_round, eta, objective="multi:softmax")
                    mach = machine(model, X_train, y_train)
                    fit!(mach, verbosity=0)
                    trees = XGB.trees(mach.fitresult[1])
                    encoding     = get_encoding(mach.fitresult[2])
                    classlabels  = get_classlabels(encoding)
                    featurenames = mach.report.vals[1].features
                    solem = solemodel(trees, Matrix(X_train), y_train; classlabels, featurenames)
                    X_test_f32 = mapcols(col -> Float32.(col), X_test)
                    apply!(solem, X_test_f32, y_test)
                    preds = solem.info.supporting_predictions
                    predsl = CategoricalArrays.levelcode.(CategoricalArrays.categorical(preds)) .- 1

                    yl_train = CategoricalArrays.levelcode.(CategoricalArrays.categorical(y_train)) .- 1
                    bst = XGB.xgboost((X_train, yl_train); num_round, eta, num_class=3, objective="multi:softmax")
                    xg_preds = XGB.predict(bst, X_test)

                    @test predsl == xg_preds
                end
            end
        end
    end
end

# ---------------------------------------------------------------------------- #
#                               Binary Validation                              #
# ---------------------------------------------------------------------------- #
data_path = joinpath(@__DIR__, "respiratory_juliacon2025.jld2")
data  = JLD2.load(data_path)
X = data["X"]
y = MLJ.CategoricalArray{String,1,UInt32}(data["y"])

@testset "binary validation" begin
    XGTrees = MLJ.@load XGBoostClassifier pkg=XGBoost

    for fraction_train in 0.7:0.1:0.9
        for seed in 1:10
            for num_round in 10:10:20
                for eta in 0.1:0.1:0.3
                    resampling=Holdout(; fraction_train, rng=seed, shuffle=true)
                    i  = MLJ.MLJBase.train_test_pairs(resampling, 1:length(y))
                    train, test = i[1][1], i[1][2]
                    X_train, y_train = X[train, :], y[train]
                    X_test, y_test = X[test, :], y[test]
                    model = XGTrees(; num_round, eta, seed)
                    mach = machine(model, X, y)
                    fit!(mach, rows=train, verbosity=0)
                    trees = XGB.trees(mach.fitresult[1])
                    encoding     = get_encoding(mach.fitresult[2])
                    classlabels  = get_classlabels(encoding)
                    featurenames = mach.report.vals[1].features
                    solem = solemodel(trees, Matrix(X_train), y_train; classlabels, featurenames)
                    X_test_f32 = mapcols(col -> Float32.(col), X_test)
                    apply!(solem, X_test_f32, y_test)
                    # preds = solem.info.supporting_predictions
                    # predsl = CategoricalArrays.levelcode.(CategoricalArrays.categorical(preds)) .- 1
                    sole_accuracy = MLJ.accuracy(solem.info.supporting_predictions, solem.info.supporting_labels)

                    mlj_xgboost = evaluate(
                        model, X, y;
                        resampling=Holdout(; fraction_train, rng=seed, shuffle=true),
                        measures=[MLJ.accuracy],
                        per_observation=false,
                        verbosity=0
                    )

                    @test sole_accuracy == mlj_xgboost.measurement[1]
                end
            end
        end
    end
end