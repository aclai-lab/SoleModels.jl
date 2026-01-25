# JuliaCon2024 demo

using SoleModels

# Load packages
begin
    using MLJ
    using MLJDecisionTreeInterface
    using DataFrames
    using Random
end

# Load dataset
X, y = begin
    X, y = @load_iris;
    X = DataFrame(X)
    X, y
end

# Split dataset
X_train, y_train, X_test, y_test = begin
    train, test = MLJ.partition(eachindex(y), 0.8, shuffle=true, rng = Random.MersenneTwister(42));
    X_train, y_train = X[train, :], y[train];
    X_test, y_test = X[test, :], y[test];
    X_train, y_train, X_test, y_test
end;

# Train tree
mach = begin
    Tree = MLJ.@load DecisionTreeClassifier pkg=DecisionTree
    model = Tree(max_depth=-1, rng = Random.MersenneTwister(42))
    machine(model, X_train, y_train) |> MLJ.fit!
end

# Inspect the tree
🌱 = fitted_params(mach).tree

# Convert to 🌞-compliant model
import DecisionTree as DT
🌲 = solemodel(🌱);

# Print model
printmodel(🌲);

# Inspect the rules
listrules(🌲)

# Inspect rule metrics
metricstable(🌲)

# Inspect normalized rule metrics
metricstable(🌲, normalize = true)

# Make test instances flow into the model, so that test metrics can, then, be computed.
apply!(🌲, X_test, y_test)

# Pretty table of rules and their metrics
metricstable(🌲; normalize = true, metrics_kwargs = (; additional_metrics = (; height = r->SoleLogics.height(antecedent(r)))))

# Join some rules for the same class into a single, sufficient and necessary condition for that class
metricstable(joinrules(🌲; min_ncovered = 1, normalize = true))
