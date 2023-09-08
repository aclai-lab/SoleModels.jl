using MLJBase

_nvars = 2
n_instances = 20

multidataset, multirelations = collect.(zip([
           (Array(reshape(1.0:40.0, _nvars,n_instances)), [globalrel]),
           (Array(reshape(1.0:120.0, 3,_nvars,n_instances)), [IARelations..., globalrel]),
           (Array(reshape(1.0:360.0, 3,3,_nvars,n_instances)), [IA2DRelations..., globalrel]),
       ]...))

multilogiset = @test_nowarn min_level=Logging.Error scalarlogiset(multidataset)
multilogiset = scalarlogiset(multidataset; relations = multirelations, conditions = vcat([[SoleModels.ScalarMetaCondition(UnivariateMin(i), >), SoleModels.ScalarMetaCondition(UnivariateMax(i), <)] for i in 1:_nvars]...))

X = @test_nowarn modality(multilogiset, 1)
@test_nowarn selectrows(X, 1:10)
@test_nowarn selectrows(multilogiset, 1:10)
@test_nowarn selectrows(SoleModels.base(X), 1:10)
X = @test_nowarn modality(multilogiset, 2)
@test_nowarn selectrows(SoleModels.base(X), 1:10)

mod2 = modality(multilogiset, 2)
mod2_part = modality(MLJBase.partition(multilogiset, 0.8)[1], 2)
check(SyntaxTree(Proposition(ScalarCondition(UnivariateMin(2), >, 301))), mod2_part, 1, SoleModels.Interval(1,2))
check((DiamondRelationalOperator(IA_L)(Proposition(ScalarCondition(UnivariateMin(2), >, 0)))), mod2_part, 1, SoleModels.Interval(1,2))

@test mod2_part != MLJBase.partition(mod2, 0.8)[1]
@test nmemoizedvalues(mod2_part) == nmemoizedvalues(MLJBase.partition(mod2, 0.8)[1])
