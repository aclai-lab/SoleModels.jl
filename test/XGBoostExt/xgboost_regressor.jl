using Test
using SoleXplorer
using MLJ, DataFrames, Random

X, y = @load_boston
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
XGTrees = MLJ.@load XGBoostRegressor pkg=XGBoost

model = XGTrees(;
    num_round=5,
    max_depth=6,
    objective="reg:squarederror"
)

# Bind the model and data into a machine
mach = machine(model, X_train, y_train)
# Fit the model
fit!(mach; verbosity=0)

trees = XGB.trees(mach.fitresult[1])
featurenames = mach.report.vals[1].features

solem = solemodel(trees, Matrix(X_train), y_train; featurenames)
solem = solemodel(trees, Matrix(X_train), y_train; featurenames, keep_condensed = false)

@test SoleData.scalarlogiset(X_test; allow_propositional = true) isa PropositionalLogiset

X_test_f32 = mapcols(col -> Float32.(col), X_test)

base_score = mean(y_train)

preds = apply!(solem, X_test_f32, y_test; base_score)

@test solem.info.supporting_predictions == Float32.(preds)
@test solem.info.supporting_labels == y_test

# ---------------------------------------------------------------------------- #
#                               XGBoost Alphabet                               #
# ---------------------------------------------------------------------------- #
@test_nowarn alphabet(fitted_params(mach).fitresult[1])

# ---------------------------------------------------------------------------- #
#                                Data Validation                               #
# ---------------------------------------------------------------------------- #
@testset "data validation" begin
    XGTrees = MLJ.@load XGBoostRegressor pkg=XGBoost verbosity=0

    for train_ratio in 0.6:0.1:0.9
        for seed in 1:40
            train, test = partition(eachindex(y), train_ratio; shuffle=true, rng=Xoshiro(seed))
            X_train, y_train = X[train, :], y[train]
            X_test, y_test = X[test, :], y[test]
            base_score = mean(y_train)

            for num_round in 10:10:50
                for max_depth in 2:6
                    model = XGTrees(; num_round, max_depth, objective="reg:squarederror")
                    mach = machine(model, X_train, y_train)
                    mach.model.base_score = base_score
                    fit!(mach, verbosity=0)
                    trees = XGB.trees(mach.fitresult[1])
                    featurenames = mach.report.vals[1].features
                    solem = solemodel(trees, Matrix(X_train), y_train; featurenames)
                    X_test_f32 = mapcols(col -> Float32.(col), X_test)
                    preds = apply!(solem, X_test_f32, y_test; base_score)

                    bst = XGB.xgboost((X_train, y_train); num_round, max_depth, objective="reg:squarederror")
                    xg_preds = XGB.predict(bst, X_test)

                    @show train_ratio, seed, num_round, max_depth
                    @test isapprox(Float32.(preds), xg_preds; rtol=1e-6)
                end
            end
        end
    end
end

