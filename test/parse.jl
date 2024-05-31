using Test
using SoleModels
using SoleData
using SoleData: AbstractUnivariateFeature, Feature
using SoleData: ScalarCondition
using SoleData: feature

############################################################################################
############################ Orange parser #################################################
############################################################################################

dl = """
    [49, 0, 0] IF petal length<=3.0 AND sepal width>=2.9 THEN iris=setosa  -0.0
    [0, 0, 39] IF petal width>=1.8 AND sepal length>=6.0 THEN iris=virginica  -0.0
    [0, 8, 0] IF sepal length>=4.9 AND sepal width>=3.1 THEN iris=versicolor  -0.0
    [0, 0, 2] IF petal length<=4.9 AND petal width>=1.7 THEN iris=virginica  -0.0
    [0, 0, 5] IF petal width>=1.8 THEN iris=virginica  -0.0
    [0, 35, 0] IF petal length<=5.0 AND sepal width>=2.4 THEN iris=versicolor  -0.0
    [0, 0, 2] IF sepal width>=2.8 THEN iris=virginica  -0.0
    [50, 50, 50] IF TRUE THEN iris=setosa  -1.584962500721156 """ |> SoleModels.parse_orange_decision_list

@test dl isa DecisionList
@test_nowarn a = readmetrics.(listrules(dl))

@test_nowarn """ [50, 50, 50] IF TRUE THEN iris=setosa  -1.584962500721156 """ |>  SoleModels.parse_orange_decision_list
@test_nowarn """
    [0, 0, 2] IF petal length<=4.9 AND petal width>=1.7 THEN iris=virginica  -0.0
    [50, 50, 50] IF TRUE THEN iris=setosa  -1.584962500721156
""" |>  SoleModels.parse_orange_decision_list

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Malformed DL ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

@test_throws ErrorException """ [49, 0, 0] IF petal length<=3.0 AND sepal width>=2.9 THEN iris=setosa  -0.0
    [0, 0, 39] IF petal width>=1.8 AND sepal length>=6.0 THEN iris=virginica  -0.0
    [0, 8, 0] IF sepal length>=4.9 AND sepal width>=3.1 THEN iris=versicolor  -0.0
    [0, 0, 2] IF petal length<=4.9 AND petal width>=1.7 THEN iris=virginica  -0.0
    [0, 0, 5] IF petal width>=1.8 THEN iris=virginica  -0.0
    [0, 35, 0] IF petal length<=5.0 AND sepal width>=2.4 THEN iris=versicolor  -0.0
    [0, 0, 2] IF sepal width>=2.8 THEN iris=virginica  -0.0
    [0, 0, 1] IF sepal length>=6.0 THEN iris=virginica  -0.0 """ |>  SoleModels.parse_orange_decision_list

@test_throws ErrorException """ This is not a decision list """ |>  SoleModels.parse_orange_decision_list
@test_throws ErrorException """ """ |>  SoleModels.parse_orange_decision_list

dl = "
    [49, 0, 0] IF petal length<=3.0 AND sepal width>=2.9 THEN iris=Iris-setosa  -0.0
    [0, 0, 39] IF petal width>=1.8 AND sepal length>=6.0 THEN iris=Iris-virginica  -0.0
    [0, 8, 0] IF sepal length>=4.9 AND sepal width>=3.1 THEN iris=Iris-versicolor  -0.0
    [0, 0, 2] IF petal length<=4.9 AND petal width>=1.7 THEN iris=Iris-virginica  -0.0
    [0, 0, 5] IF petal width>=1.8 THEN iris=Iris-virginica  -0.0
    [0, 35, 0] IF petal length<=5.0 AND sepal width>=2.4 THEN iris=Iris-versicolor  -0.0
    [0, 0, 2] IF sepal width>=2.8 THEN iris=Iris-virginica  -0.0
    [0, 3, 0] IF petal width<=1.0 AND sepal length>=5.0 THEN iris=Iris-versicolor  -0.0
    [0, 1, 0] IF sepal width>=2.7 THEN iris=Iris-versicolor  -0.0
    [0, 0, 1] IF sepal width>=2.6 THEN iris=Iris-virginica  -0.0
    [0, 2, 0] IF sepal length>=5.5 AND sepal length>=6.2 THEN iris=Iris-versicolor  -0.0
    [0, 1, 0] IF sepal length<=5.5 AND petal length>=4.0 THEN iris=Iris-versicolor  -0.0
    [0, 0, 1] IF sepal length>=6.0 THEN iris=Iris-virginica  -0.0
    [1, 0, 0] IF sepal length<=4.5 THEN iris=Iris-setosa  -0.0
    [50, 50, 50] IF TRUE THEN iris=Iris-setosa  -1.584962500721156
" |> SoleModels.parse_orange_decision_list;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


@test_nowarn listrules(dl)
@test_nowarn listrules(dl; normalize=true, force_syntaxtree=true)
@test_nowarn listrules(dl; normalize=true, force_syntaxtree=false)
@test_nowarn listrules(dl; normalize=true, force_syntaxtree=true, normalize_kwargs=(; profile=:nnf))
@test_nowarn listrules(dl; normalize=true, normalize_kwargs=(; profile=:nnf))
@test_nowarn listrules(dl; normalize=true, normalize_kwargs=(; profile=:nnf, allow_atom_flipping=true));
print("")
# TODO add (theory-basedL) formula simplifier: sepal length>=5.5 ∧ sepal length>=10 ≡ sepal length>=5.5
