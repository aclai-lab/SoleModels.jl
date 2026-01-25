using CSV
using DataFrames
using CategoricalArrays
using SoleXplorer
const SX = SoleXplorer

# debug
# filepath = "/home/paso/Documents/Laravel/wekavel/storage/app/public/uploads/1/document/iris_1769203923.csv"
# target = "decision_tree"

if length(ARGS) == 2
    filename = ARGS[1]
    target   = ARGS[2]

    filepath = joinpath(pwd(), "storage", filename)

    if !isfile(filepath)
        println("Error: File not found at $filepath")
        exit(1)
    end

    df = CSV.read(filepath, DataFrame)
    X  = select(df, 1:ncol(df)-1)
    y  = CategoricalArrays.categorical(df[!, end])

    model = Dict(
        "decision_tree" => (X, y) -> SX.symbolic_analysis(
            X, y;
            model=SX.DecisionTreeClassifier(max_depth=4),
            resampling=Holdout(fraction_train=0.7, shuffle=true),
        ),
        "random_forest" => (X, y) -> SX.symbolic_analysis(
            X, y;
            model=SX.RandomForestClassifier(max_depth=4, n_trees=5),
            resampling=Holdout(fraction_train=0.7, shuffle=true),
        ),
        "ada_boost"     => (X, y) -> SX.symbolic_analysis(
            X, y;
            model=SX.AdaBoostStumpClassifier(n_iter=10),
            resampling=Holdout(fraction_train=0.7, shuffle=true),
        ),
        "xgboost"       => (X, y) -> SX.symbolic_analysis(
            X, y;
            model=SX.XGBoostClassifier(),
            resampling=Holdout(fraction_train=0.7, shuffle=true),
        )
    )

    result = model[target](X, y)
end

@show result
