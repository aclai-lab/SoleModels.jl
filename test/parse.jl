using Test
using Logging
using SoleModels
using SoleData
using SoleData: AbstractUnivariateFeature, Feature
using SoleData: ScalarCondition
using SoleData: feature

# @test_nowarn parsefeature(VarFeature, "min[V1]")
# @test_nowarn parsefeature(VarFeature, "min[V1]"; featvaltype = Float64)
# @test_nowarn parsefeature(VarFeature, "min[V1]"; featvaltype = Int64)
# @test_nowarn parsefeature(AbstractUnivariateFeature, "min[V1]")
# # @test_logs (:warn,) parsefeature(UnivariateMin, "min[V1]")
# @test_nowarn parsefeature(UnivariateMin, "min[V1]")



# @test_logs (:warn,) parsecondition(ScalarCondition, "F1 > 2"; featuretype = Feature)
# @test_logs (:warn,) parsecondition(ScalarCondition, "1 > 2"; featuretype = Feature{Int})

# C = ScalarCondition

# @test_logs min_level=Logging.Error parsecondition(C, "min[V1] <= 32")
# @test_logs (:warn,) parsecondition(C, "min[V1] <= 32"; featvaltype = Float64)
# @test_nowarn parsecondition(C, "min[V1] <= 32"; featvaltype = Float64, featuretype = AbstractUnivariateFeature)

# @test_nowarn parsecondition(C, "min[V1] <= 32"; featvaltype = Float64, featuretype = AbstractUnivariateFeature)
# @test_nowarn parsecondition(C, "max[V2] <= 435"; featvaltype = Float64, featuretype = AbstractUnivariateFeature)
# @test_nowarn parsecondition(C, "minimum[V6]    > 250.631"; featvaltype = Float64, featuretype = AbstractUnivariateFeature)
# @test_throws AssertionError parsecondition(C, "   minimum   [V7]    > 11.2"; featvaltype = Float64, featuretype = AbstractUnivariateFeature)
# @test_throws AssertionError parsecondition(C, "avg [V8]    > 63.2  "; featvaltype = Float64, featuretype = AbstractUnivariateFeature)
# @test_nowarn parsecondition(C, "mean[V9] <= 1.0e100"; featvaltype = Float64, featuretype = AbstractUnivariateFeature)

# @test_nowarn parsecondition(C, "max{3] <= 12"; featvaltype = Float64, opening_parenthesis="{", variable_name_prefix = "", featuretype = AbstractUnivariateFeature)
# @test_nowarn parsecondition(C, "  min[V4}    > 43.25  "; featvaltype = Float64, closing_parenthesis="}", featuretype = AbstractUnivariateFeature)
# @test_nowarn parsecondition(C, "max{5} <= 250"; featvaltype = Float64, opening_parenthesis="{", closing_parenthesis="}", variable_name_prefix = "", featuretype = AbstractUnivariateFeature)
# @test_nowarn parsecondition(C, "mean[V9] <= 1.0e100"; featvaltype = Float64, featuretype = AbstractUnivariateFeature)
# @test_nowarn parsecondition(C, "mean🌅V9🌄 <= 1.0e100"; featvaltype = Float64, opening_parenthesis="🌅", closing_parenthesis="🌄", featuretype = AbstractUnivariateFeature)

# @test_nowarn feature(parsecondition(C, "mean[V10]    > 462.2"; featvaltype = Float64, featuretype = AbstractUnivariateFeature))
# @test_nowarn feature(parsecondition(C, "mean[V11] < 1.0e100"; featvaltype = Float64, featuretype = AbstractUnivariateFeature))


# @test_nowarn parsecondition(C, "max[V15] <= 723"; featvaltype = Float64, featuretype = AbstractUnivariateFeature)
# @test_nowarn parsecondition(C, "mean[V16] == 54.2"; featvaltype = Float64, featuretype = AbstractUnivariateFeature)

# @test_throws Exception parsecondition(C, "5345.4 < avg [V13]    < 32.2 < 12.2"; featuretype = AbstractUnivariateFeature)
# @test_throws AssertionError parsecondition(C, "avg [V14] < 12.2 <= 6127.2"; featuretype = AbstractUnivariateFeature)
# @test_throws AssertionError parsecondition(C, "mean189]    > 113.2"; featuretype = AbstractUnivariateFeature)
# @test_throws AssertionError parsecondition(C, "123.4 < avg [V12]    > 777.2  "; featuretype = AbstractUnivariateFeature)
# @test_throws Exception parsecondition(C, "mimimum [V17] < 23.2 <= 156.2"; featuretype = AbstractUnivariateFeature)
# @test_throws AssertionError parsecondition(C, "max[V3} <= 12"; opening_parenthesis="{", featuretype = AbstractUnivariateFeature)
# @test_throws AssertionError parsecondition(C, "max{18] <= 12"; opening_parenthesis="}", variable_name_prefix = "", featuretype = AbstractUnivariateFeature)


# Orange parser


# Attenzione, ai fini del confronto ho dovuto cambiare le classi di orange_decisionlis.
# "Iris-setosa"     -> "setosa"
# "Iris-versicolor" -> "versicolor"
# "Iris-virginica"  -> "virginica"

include("../src/parse.jl")

orange_decisionlist = """
    [49, 0, 0] IF petal length<=3.0 AND sepal width>=2.9 THEN iris=setosa  -0.0
    [0, 0, 39] IF petal width>=1.8 AND sepal length>=6.0 THEN iris=virginica  -0.0
    [0, 8, 0] IF sepal length>=4.9 AND sepal width>=3.1 THEN iris=versicolor  -0.0
    [0, 0, 2] IF petal length<=4.9 AND petal width>=1.7 THEN iris=virginica  -0.0
    [0, 0, 5] IF petal width>=1.8 THEN iris=virginica  -0.0
    [0, 35, 0] IF petal length<=5.0 AND sepal width>=2.4 THEN iris=versicolor  -0.0
    [0, 0, 2] IF sepal width>=2.8 THEN iris=virginica  -0.0
    [50, 50, 50] IF TRUE THEN iris=setosa  -1.584962500721156 """ |> SoleModels.orange_decision_list
@test orange_decisionlist isa DecisionList
# @test apply(orange_decisionlist, X_test) isa Vector{CLabel}

orange_decisionlist = """
    [50, 50, 50] IF TRUE THEN iris=setosa  -1.584962500721156 """ |>  SoleModels.orange_decision_list
@test orange_decisionlist isa DecisionList



# Test malformed decision list
@test_throws ErrorException """ [49, 0, 0] IF petal length<=3.0 AND sepal width>=2.9 THEN iris=setosa  -0.0
    [0, 0, 39] IF petal width>=1.8 AND sepal length>=6.0 THEN iris=virginica  -0.0
    [0, 8, 0] IF sepal length>=4.9 AND sepal width>=3.1 THEN iris=versicolor  -0.0
    [0, 0, 2] IF petal length<=4.9 AND petal width>=1.7 THEN iris=virginica  -0.0
    [0, 0, 5] IF petal width>=1.8 THEN iris=virginica  -0.0
    [0, 35, 0] IF petal length<=5.0 AND sepal width>=2.4 THEN iris=versicolor  -0.0
    [0, 0, 2] IF sepal width>=2.8 THEN iris=virginica  -0.0
    [0, 0, 1] IF sepal length>=6.0 THEN iris=virginica  -0.0 """ |>  SoleModels.orange_decision_list

@test_throws ErrorException """ This is not a decision list """ |>  SoleModels.orange_decision_list
@test_throws ErrorException """ """ |>  SoleModels.orange_decision_list
