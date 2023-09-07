using Test
using StatsBase
using Random
using SoleLogics
using SoleModels
using DataFrames
using SoleModels.DimensionalDatasets

n_instances = 2
_nvars = 2

dataset, relations = (DataFrame(; NamedTuple([Symbol(i_var) => [rand(3,3) for i_instance in 1:n_instances] for i_var in 1:_nvars])...), [IA2DRelations..., globalrel])

nvars = nvariables(dataset)

generic_features = collect(Iterators.flatten([[UnivariateMax(i_var), UnivariateMin(i_var)] for i_var in 1:nvars]))

float_features = collect(Iterators.flatten([[UnivariateMax{Float64}(i_var), UnivariateMin{Float64}(i_var)] for i_var in 1:nvars]))
logiset = @test_nowarn scalarlogiset(dataset, float_features; use_full_memoization = false, use_onestep_memoization = false)

int_features = collect(Iterators.flatten([[UnivariateMax{Int64}(i_var), UnivariateMin{Int64}(i_var)] for i_var in 1:nvars]))
logiset = @test_throws CompositeException scalarlogiset(dataset, int_features; use_full_memoization = false, use_onestep_memoization = false)

@test isequal(generic_features, int_features)
@test isequal(generic_features, float_features)

@test hash.(generic_features) != hash.(int_features)

logiset = @test_nowarn scalarlogiset(dataset; use_full_memoization = false, use_onestep_memoization = false)
logiset = @test_nowarn scalarlogiset(dataset; use_full_memoization = true, use_onestep_memoization = false)

int_metaconditions = [ScalarMetaCondition(feature, >) for feature in int_features]

generic_metaconditions = [ScalarMetaCondition(feature, >) for feature in generic_features]

@test isequal(generic_metaconditions, int_metaconditions)
@test (hash.(generic_metaconditions) == hash.(int_metaconditions))

println("1")
@test_nowarn scalarlogiset(dataset; use_full_memoization = true, use_onestep_memoization = true, relations = relations, conditions = generic_metaconditions)
println("2")
@test_throws AssertionError scalarlogiset(dataset; use_full_memoization = true, use_onestep_memoization = false, relations = relations, conditions = generic_metaconditions)
println("3")
@test_nowarn scalarlogiset(dataset; use_full_memoization = false, relations = relations, conditions = generic_metaconditions, onestep_precompute_globmemoset = false, onestep_precompute_relmemoset = false)
println("4")
@test_nowarn scalarlogiset(dataset; use_full_memoization = false, relations = relations, conditions = generic_metaconditions, onestep_precompute_globmemoset = true, onestep_precompute_relmemoset = true)
println("5")

logiset = @test_nowarn scalarlogiset(dataset; use_full_memoization = false, relations = relations, conditions = generic_metaconditions)

generic_complete_metaconditions = vcat([[ScalarMetaCondition(feature, >), ScalarMetaCondition(feature, <)] for feature in generic_features]...)

complete_logiset = @test_nowarn scalarlogiset(dataset; use_full_memoization = false, relations = relations, conditions = generic_complete_metaconditions)

rng = Random.MersenneTwister(1)
alph = ExplicitAlphabet([SoleModels.ScalarCondition(rand(rng, generic_features), rand(rng, [>, <]), rand(rng)) for i in 1:n_instances]);
syntaxstring.(alph)
_formulas = [randformula(rng, 3, alph, [SoleLogics.BASE_PROPOSITIONAL_OPERATORS..., vcat([[DiamondRelationalOperator(r), BoxRelationalOperator(r)] for r in relations]...)[1:16:end]...]) for i in 1:20];
syntaxstring.(_formulas) .|> println;

i_instance = 1
@test_nowarn checkcondition(atom(alph.propositions[1]), complete_logiset, i_instance, first(allworlds(complete_logiset, i_instance)))

c1 = @test_nowarn [
        [check(φ, logiset, i_instance, w) for φ in _formulas]
    for w in allworlds(logiset, i_instance)]
c2 = @test_nowarn [
        [check(φ, complete_logiset, i_instance, w) for φ in _formulas]
    for w in allworlds(complete_logiset, i_instance)]

@test c1 == c2


@test_nowarn slicedataset(logiset, [1])
@test_nowarn slicedataset(complete_logiset, [1])

@test_nowarn concatdatasets(logiset, logiset, logiset)
@test_nowarn concatdatasets(complete_logiset, complete_logiset, complete_logiset)
