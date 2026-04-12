using SoleBase: CLabel
using DataFrames
using SoleModels: apply, DecisionList, solemodel, info, models, weighted_aggregation
using SoleModels
using SoleData
using MLJ
using CategoricalArrays: CategoricalValue, CategoricalArray
using StatsBase
using Statistics
using Random

DecisionTreeClassifier = @load DecisionTreeClassifier pkg=DecisionTree

function rdl_tree_wrapper(X, y, w; rng, kwargs...)
    # Prepare data for MLJ
    X_fixed = DataFrame(X)  
    y_fixed = categorical(y) 

    # TODO: actually implement this into machine()
    actual_w = isnothing(w) ? nothing : collect(Float64, w)

    tree_model = DecisionTreeClassifier(rng = rng)
    
    mach = machine(tree_model, X_fixed, y_fixed)

    fit!(mach, verbosity = 0)
    
    trained_features = report(mach).features        # set of features from X

    sole_tree = solemodel(fitted_params(mach).tree; featurenames = trained_features)

    return sole_tree    
end

X,y = MLJ.@load_iris
X = DataFrame(X) |> PropositionalLogiset
y = string.(y)

rng = Xoshiro(42)

train_ratio = 0.7

train, test = partition(eachindex(y), train_ratio; shuffle=true, rng)
X_train, y_train = X[train, :], y[train]
X_test, y_test = X[test, :], y[test]


# function called to train the actual base models in the list
model_wrapper(X, y, w; rng, iteration, kwargs...) = rdl_tree_wrapper(X, y, w; rng = rng, kwargs...)

ensemble_model = build_ensemble(X_train, y_train, 25, model_wrapper)

ensemble_preds = apply(ensemble_model, X_test);
ensemble_accuracy = mean(ensemble_preds .== y_test)
println("Ensemble test accuracy: $ensemble_accuracy")