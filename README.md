# *SoleModels.jl* – Symbolic Learning Models

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://aclai-lab.github.io/SoleModels.jl/stable)
[![Build Status](https://api.cirrus-ci.com/github/aclai-lab/SoleModels.jl.svg?branch=main)](https://cirrus-ci.com/github/aclai-lab/SoleModels.jl)
[![Coverage](https://codecov.io/gh/aclai-lab/SoleModels.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/aclai-lab/SoleModels.jl)
[![Code Style: Blue](https://img.shields.io/badge/code%20style-blue-4495d1.svg)](https://github.com/invenia/BlueStyle)

<!-- [![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://aclai-lab.github.io/SoleModels.jl/dev) -->

## In a nutshell

*SoleModels.jl* defines the building blocks of *symbolic* modeling and learning.
It features:
- Definitions for symbolic models (decision trees/forests, rules, branches, etc.);
- Optimized data structures, useful when learning models from machine learning datasets;
- Support for mixed, neuro-symbolic computation.

These definitions provide a unified base for implementing symbolic algorithms, such as:
- Decision tree/random forest learning;
- Classification/regression rule extraction;
- Association rule mining.

## Models

### Basic models:

- Final models: wrapping native Julia computation (e.g., constants, functions);
- Rules: structures with `IF antecedent THEN consequent END` semantics;
- Branches: structures with `IF antecedent THEN pos_consequent ELSE neg_consequent END` semantics.

Remember:
- An antecedent is any *condition* that can be checked on a machine learning *instance*, yielding a `true/false` value;
- A consequent is... anything you want, really, even another model (spoiler: a Branch with Branch consequents is a Decision Tree 😉).

More specifically, antecedents can be *logical formulas* and, in such case, the symbolic models
are can be applied to *logical interpretations*.
For more information, refer to [*SoleLogics.jl*](https://github.com/aclai-lab/SoleLogics.jl), the underlying logical layer.

### Other noteworthy models:

- Decision List (or decision table): see [Wikipedia](https://en.wikipedia.org/wiki/Decision_list);
- Decision Tree: see [Wikipedia](https://en.wikipedia.org/wiki/Decision_tree);
- Decision Forest (or tree ensamble): see [Wikipedia](https://en.wikipedia.org/wiki/Random_forest);
- Mixed Symbolic Model: a nested structure, mixture of many symbolic models.

## Dataset structures (for logical symbolic learning)

Learning logical models (that is, models with logical formulas as antecedents)
[often](https://scholar.google.com/scholar?q=Multi-Models+and+Multi-Formulas+Finite+Model+Checking+for+Modal+Logic+Formulas+Induction.)
requires performing [model checking](https://en.wikipedia.org/wiki/Model_checking) many times.
*SoleModels.jl* provides a set of structures for representing [logical datasets](https://github.com/aclai-lab/SoleLogics.jl#interpretation-sets),
specifically optimized for multiple model checking operations.

<!-- TODO explain -->

## About

The package is developed by the [ACLAI Lab](https://aclai.unife.it/en/) @ University of Ferrara.

*SoleModels.jl* mainly builds upon [*SoleLogics.jl*](https://github.com/aclai-lab/SoleLogics.jl) and [*SoleData.jl*](https://github.com/aclai-lab/SoleData.jl), 
and it is the core module of [*Sole.jl*](https://github.com/aclai-lab/Sole.jl), an open-source framework for symbolic machine learning.
