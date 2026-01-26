using CSV
using DataFrames
using CategoricalArrays
using SoleXplorer
const SX = SoleXplorer

filepath = "/home/paso/Documents/Datasets/iris_1769203923.csv"
target = "decision_tree"

df = CSV.read(filepath, DataFrame)
X  = DataFrames.select(df, 1:ncol(df)-1)
y  = CategoricalArrays.categorical(df[!, end])

model = SX.symbolic_analysis(
    X, y;
    model=SX.XGBoostClassifier(),
    resampling=Holdout(fraction_train=0.7, shuffle=true),
)

