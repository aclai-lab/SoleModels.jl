using Distributed
addprocs(2)

@everywhere begin
    using SoleModels
    using SoleModels: AbstractModel
    using SoleModels: ConstantModel, LeafModel
    using SoleModels: listrules, displaymodel, submodels
    using SoleData
    using SoleData: AbstractUnivariateFeature, Feature
    using SoleData: ScalarCondition
    using SoleData: feature
    using SoleLogics
    using CategoricalArrays
    using Markdown
    using MultiData
    using InteractiveUtils
    using MLJ
    using MLJDecisionTreeInterface
    import DecisionTree as DT
    import MLJModelInterface as MMI
    import XGBoost as XGB
    using DataFrames
    using Test
    using Random
    using FunctionWrappers: FunctionWrapper
end

function run_tests(list)
    println("\n" * ("#"^50))
    for test in list
        println("TEST: $test")
        include(test)
    end
end

println("Julia version: ", VERSION)

test_suites = [
    ("Models", ["base.jl", "test_tree.jl"]),
    ("Miscellaneous", ["misc.jl", ]),
    ("Parse", ["parse.jl", ]),
    ("Rules", ["juliacon2024.jl", ]),
    ("Linear forms", ["linear-form-utilities.jl", ]),
    ("Pluto Demo", ["$(dirname(dirname(pathof(SoleModels))))/pluto-demo.jl", ]),
    ("DecisionTreeExt", ["DecisionTreeExt/tree.jl", "DecisionTreeExt/forest.jl", "DecisionTreeExt/adaboost.jl"]),
    ("XGBoostExt", ["XGBoostExt/xgboost_classifier.jl"]),
]

@testset "SoleModels.jl" begin
    for ts in eachindex(test_suites)
        name = test_suites[ts][1]
        list = test_suites[ts][2]
        let
            @testset "$name" begin
                run_tests(list)
            end
        end
    end
    println()
end
