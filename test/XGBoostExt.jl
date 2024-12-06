
# Import necessary libraries
using MLJ
using DataFrames

# Load the Iris dataset
X, y = @load_iris
X = DataFrame(X)

# Convert the target variable to categorical
y = coerce(y, Multiclass)

# Split the dataset into training and testing sets
train, test = partition(eachindex(y), 0.8, shuffle=true)
X_train, X_test = X[train, :], X[test, :]
y_train, y_test = y[train], y[test]

# Load the XGBoost classifier
XGBoostClassifier = @load XGBoostClassifier pkg=XGBoost

# Create the model and set hyperparameters
mljmodel = XGBoostClassifier()

# Wrap the model with the data
mach = machine(mljmodel, X_train, y_train)

# Train the model
fit!(mach)

# Make predictions
y_pred = predict(mach, X_test)

# Evaluate test accuracy
acc = mean(mode.(y_pred) .== y_test)

# Print the test accuracy
println("Test Accuracy: $acc")



using Sole

@test_nowarn alphabet(fitted_params(mach).fitresult[1])

model = fitted_params(mach).fitresult[1]

@test_broken solemodel(model)
