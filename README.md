<div align="center"><a href="https://github.com/aclai-lab/Sole.jl"><img src="logo.png" alt="" title="This package is part of Sole.jl" width="200"></a></div>

# SoleModels.jl – Symbolic Learning Models

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://aclai-lab.github.io/SoleModels.jl/stable)
[![Build Status](https://api.cirrus-ci.com/github/aclai-lab/SoleModels.jl.svg?branch=main)](https://cirrus-ci.com/github/aclai-lab/SoleModels.jl)
[![Coverage](https://codecov.io/gh/aclai-lab/SoleModels.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/aclai-lab/SoleModels.jl)
[![Binder](https://mybinder.org/badge_logo.svg)](https://mybinder.org/v2/gh/aclai-lab/SoleModels.jl/HEAD?labpath=pluto-demo.jl)
<!-- [![Code Style: Blue](https://img.shields.io/badge/code%20style-blue-4495d1.svg)](https://github.com/invenia/BlueStyle) -->

<!-- [![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://aclai-lab.github.io/SoleModels.jl/dev) -->

## In a nutshell

*SoleModels.jl* defines the building blocks of *symbolic* modeling and learning.
It features:
- Definitions for symbolic models (decision trees/forests, rules, branches, etc.);
- Tools for evaluate them, and extracting rules from them;
- Support for mixed, neuro-symbolic computation.

These definitions provide a unified base for implementing symbolic algorithms, such as:
- Decision tree/random forest learning;
- Classification/regression rule extraction;
- Association rule mining.

## Models

Basic models are:
- Leaf models: wrapping native Julia computation (e.g., constants, functions);
- Rules: structures with `IF antecedent THEN consequent END` semantics;
- Branches: structures with `IF antecedent THEN pos_consequent ELSE neg_consequent END` semantics.

Remember that:
- An antecedent is a logical formula that can be checked on a logical interpretation (that is, an *instance* of a symbolic learning dataset), yielding a truth value (e.g., `true/false`);
- A consequent is another model, for example, a (final) constant model or branch to be applied.

Within this framework, a decision tree is no other than a branch with branch and final consequents.
Note that antecedents can consist of *logical formulas* and, in such case, the symbolic models
are can be applied to *logical interpretations*.
For more information, refer to [*SoleLogics.jl*](https://github.com/aclai-lab/SoleLogics.jl), the underlying logical layer.

Other noteworthy models include:
- Decision List (or decision table): see [Wikipedia](https://en.wikipedia.org/wiki/Decision_list);
- Decision Tree: see [Wikipedia](https://en.wikipedia.org/wiki/Decision_tree);
- Decision Forest (or tree ensamble): see [Wikipedia](https://en.wikipedia.org/wiki/Random_forest);
- Mixed Symbolic Model: a nested structure, mixture of many symbolic models.

## Usage: rule extraction from a decision tree

First, train a decision tree:
```julia
# Load packages
begin
    Pkg.add("MLJ"); using MLJ
    Pkg.add("MLJDecisionTreeInterface"); using MLJDecisionTreeInterface
    Pkg.add("DataFrames"); using DataFrames
    Pkg.add("Random"); using Random
end

# Load dataset
X, y = begin
    X, y = @load_iris;
    X = DataFrame(X)
    X, y
end

# Split dataset
X_train, y_train, X_test, y_test = begin
    train, test = partition(eachindex(y), 0.8, shuffle=true, rng = Random.MersenneTwister(42));
    X_train, y_train = X[train, :], y[train];
    X_test, y_test = X[test, :], y[test];
    X_train, y_train, X_test, y_test
end;

# Train tree
mach = begin
    Tree = MLJ.@load DecisionTreeClassifier pkg=DecisionTree
    model = Tree(max_depth=-1, rng = Random.MersenneTwister(42))
    machine(model, X_train, y_train) |> fit!
end

# Inspect the tree
🌱 = fitted_params(mach).tree
```

Then, port it to Sole and play with it:
```julia
Pkg.add("DecisionTree"); import DecisionTree as DT

# Convert to 🌞-compliant model
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
```

<!-- Be careful extracting rules from tree ensembles; there is a combinatorial explosion! -->

## Want to know more?
The formal foundations of the Sole framework are given in [giopaglia](https://github.com/giopaglia/)'s PhD thesis:
[*Modal Symbolic Learning: from theory to practice*, G. Pagliarini (2024)](https://scholar.google.com/citations?view_op=view_citation&hl=en&user=FRo4yrcAAAAJ&citation_for_view=FRo4yrcAAAAJ:LkGwnXOMwfcC)

<!-- TODO explain -->

## About

The package is developed by the [ACLAI Lab](https://aclai.unife.it/en/) @ University of Ferrara.

*SoleModels.jl* mainly builds upon [*SoleLogics.jl*](https://github.com/aclai-lab/SoleLogics.jl) and [*SoleData.jl*](https://github.com/aclai-lab/SoleData.jl), 
and it is the core module of [*Sole.jl*](https://github.com/aclai-lab/Sole.jl), an open-source framework for symbolic machine learning.
