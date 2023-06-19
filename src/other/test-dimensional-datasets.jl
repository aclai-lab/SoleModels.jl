using Test
using StatsBase
using SoleLogics
using SoleModels
using SoleModels.DimensionalDatasets

X = Array(reshape(1.0:180.0, 3,3,2,10))

ontology = get_interval_ontology(2)
@test_nowarn DimensionalLogiset{Float64}(X, ontology, [SoleModels.canonical_geq, SoleModels.canonical_leq])

dfd = @test_nowarn DimensionalLogiset(X, ontology, [SoleModels.canonical_geq, SoleModels.canonical_leq])

@test_nowarn DimensionalLogiset{Float64}(X, ontology, [minimum, maximum])
dfd2 = @test_nowarn DimensionalLogiset(X, ontology, [minimum, maximum])

@test_throws AssertionError DimensionalLogiset(X, ontology, [StatsBase.mean])


@test_nowarn dfd |> alphabet |> propositions
@test_nowarn length(alphabet(dfd))
@test_nowarn length(collect(propositions(alphabet(dfd))))
@test length(collect(propositions(alphabet(dfd))))*2 == length(collect(propositions(alphabet(dfd2))))

@test all(((propositions(dfd |> SupportedScalarLogiset |> alphabet))) .==
    ((propositions(dfd |> alphabet))))


dfd3 = @test_nowarn DimensionalLogiset{Float64}(X, ontology, [SoleModels.canonical_geq, SoleModels.canonical_leq]; initialworld = Interval2D((2,3),(2,3)))

check(SyntaxTree(⊤), dfd, 1)
check(SyntaxTree(⊤), dfd2, 1)
check(SyntaxTree(⊤), dfd3, 1)



X = Array(reshape(1.0:180.0, 3,3,2,10));


d = DimensionalLogiset{UInt16}(
X,
get_ontology(2, :interval, :RCC5),
[minimum, maximum];
initialworld = SoleLogics.Interval2D((2,3),(2,3)),
)
@assert SoleLogics.Interval2D((2,3),(2,3)) == initialworld(d)
@assert SoleLogics.Interval2D((2,3),(2,3)) == initialworld(d, 1)



