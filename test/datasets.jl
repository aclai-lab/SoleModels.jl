using Test
using StatsBase
using SoleLogics
using SoleModels
using SoleModels.DimensionalDatasets

X = Array(reshape(1.0:180.0, 3,3,2,10))

ontology = get_interval_ontology(2)
@test_nowarn DimensionalFeaturedDataset{Float64}(X, ontology, [SoleModels.CanonicalFeatureGeq(), SoleModels.CanonicalFeatureLeq()])

dfd = @test_nowarn DimensionalFeaturedDataset(X, ontology, [SoleModels.CanonicalFeatureGeq(), SoleModels.CanonicalFeatureLeq()])

@test_nowarn DimensionalFeaturedDataset{Float64}(X, ontology, [minimum, maximum])
dfd2 = @test_nowarn DimensionalFeaturedDataset(X, ontology, [minimum, maximum])

@test_throws AssertionError DimensionalFeaturedDataset(X, ontology, [StatsBase.mean])


@test_nowarn dfd |> alphabet |> propositions
@test_nowarn length(alphabet(dfd))
@test_nowarn length(collect(propositions(alphabet(dfd))))
@test length(collect(propositions(alphabet(dfd))))*2 == length(collect(propositions(alphabet(dfd2))))

@test all(((propositions(dfd |> SupportedFeaturedDataset |> alphabet))) .==
    ((propositions(dfd |> alphabet))))


dfd3 = @test_nowarn DimensionalFeaturedDataset{Float64}(X, ontology, [SoleModels.CanonicalFeatureGeq(), SoleModels.CanonicalFeatureLeq()]; initialworld = Interval2D((2,3),(2,3)))

check(SyntaxTree(⊤), dfd, 1)
check(SyntaxTree(⊤), dfd2, 1)
check(SyntaxTree(⊤), dfd3, 1)
