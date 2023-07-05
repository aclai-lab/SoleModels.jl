using Test
using StatsBase
using Random
using SoleLogics
using SoleModels
using SoleModels.DimensionalDatasets

n_instances = 2
_nvars = 2

for (dataset, relations) in [
    # (Array(reshape(1.0:4.0, _nvars,n_instances)), []),
    (Array(reshape(1.0:4.0, _nvars,n_instances)), [globalrel]),
    (Array(reshape(1.0:12.0, 3,_nvars,n_instances)), [IARelations..., globalrel]),
    (Array(reshape(1.0:36.0, 3,3,_nvars,n_instances)), [IA2DRelations..., globalrel]),
]

nvars = nvariables(dataset)

generic_features = collect(Iterators.flatten([[UnivariateMax(i_var), UnivariateMin(i_var)] for i_var in 1:nvars]))
logiset = @test_logs (:warn,) scalarlogiset(dataset, generic_features; use_full_memoization = false, use_onestep_memoization = false)

logiset = @test_nowarn scalarlogiset(dataset; use_full_memoization = false, use_onestep_memoization = false)

metaconditions = [ScalarMetaCondition(feature, >) for feature in generic_features]
@test_nowarn SupportedLogiset(logiset, ())
@test_throws AssertionError SupportedLogiset(logiset, [Dict()])
@test_throws AssertionError SupportedLogiset(logiset, [Dict{SyntaxTree,WorldSet{worldtype(logiset)}}()])
@test_nowarn SupportedLogiset(logiset, [Dict{SyntaxTree,WorldSet{worldtype(logiset)}}() for i in 1:n_instances])
@test_throws AssertionError SupportedLogiset(logiset, ([Dict{SyntaxTree,WorldSet{worldtype(logiset)}}() for i in 1:n_instances], [Dict{SyntaxTree,WorldSet{worldtype(logiset)}}() for i in 1:n_instances]))
@test_throws AssertionError SupportedLogiset(logiset; use_full_memoization = false)
@test_throws AssertionError SupportedLogiset(logiset; use_onestep_memoization = true)

@test_logs (:warn,) SupportedLogiset(logiset; use_full_memoization = true, use_onestep_memoization = true, conditions = metaconditions, relations = [relations..., identityrel])

supported_logiset = @test_nowarn SupportedLogiset(logiset; use_full_memoization = true, use_onestep_memoization = true, conditions = metaconditions, relations = relations)
@test_throws AssertionError SupportedLogiset(logiset, (supported_logiset, [Dict{SyntaxTree,WorldSet{worldtype(logiset)}}() for i in 1:n_instances]))
supported_logiset = @test_nowarn SupportedLogiset(logiset; use_full_memoization = false, use_onestep_memoization = true, conditions = metaconditions, relations = relations)

@test_nowarn SupportedLogiset(logiset, (supported_logiset, [Dict{SyntaxTree,WorldSet{worldtype(logiset)}}() for i in 1:n_instances]))
@test_nowarn SupportedLogiset(logiset, ([Dict{SyntaxTree,WorldSet{worldtype(logiset)}}() for i in 1:n_instances], supported_logiset))

supported_logiset = @test_nowarn SupportedLogiset(logiset; use_full_memoization = true, conditions = metaconditions, relations = relations)

metaconditions = vcat([[ScalarMetaCondition(feature, >), ScalarMetaCondition(feature, <)] for feature in generic_features]...)
complete_supported_logiset = @test_nowarn SupportedLogiset(logiset; use_full_memoization = true, conditions = metaconditions, relations = relations)

rng = Random.MersenneTwister(1)
alph = ExplicitAlphabet([SoleModels.ScalarCondition(rand(rng, generic_features), rand(rng, [>, <]), rand(rng)) for i in 1:n_instances]);
# syntaxstring.(alph)
_formulas = [randformula(rng, 3, alph, [SoleLogics.BASE_PROPOSITIONAL_OPERATORS..., vcat([[DiamondRelationalOperator(r), BoxRelationalOperator(r)] for r in relations]...)[1:16:end]...]) for i in 1:20];
# syntaxstring.(_formulas) .|> println;

i_instance = 1
@test_nowarn checkcondition(atom(alph.propositions[1]), logiset, i_instance, first(allworlds(logiset, i_instance)))

c1 = @test_nowarn [
        [check(φ, logiset, i_instance, w) for φ in _formulas]
    for w in allworlds(logiset, i_instance)]
c2 = @test_nowarn [
        [check(φ, supported_logiset, i_instance, w) for φ in _formulas]
    for w in allworlds(logiset, i_instance)]
c3 = @test_nowarn [
        [check(φ, complete_supported_logiset, i_instance, w) for φ in _formulas]
    for w in allworlds(logiset, i_instance)]

@test c1 == c3


@test_nowarn slicedataset(logiset, [1])
@test_nowarn slicedataset(complete_supported_logiset, [1])

@test_nowarn concatdatasets(logiset, logiset, logiset)
@test_nowarn concatdatasets(complete_supported_logiset, complete_supported_logiset)

end
