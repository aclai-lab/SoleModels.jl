using Test
using StatsBase
using Random
using SoleLogics
using SoleModels
using SoleModels.DimensionalDatasets

for (X,relations) in [
    # (Array(reshape(1.0:20.0, 2,10)),[identityrel,globalrel]),
    # (Array(reshape(1.0:20.0, 2,10)),[identityrel]),
    # (Array(reshape(1.0:60.0, 3,2,10)),[IARelations..., identityrel]),
    # (Array(reshape(1.0:180.0, 3,3,2,10)),[IA2DRelations..., identityrel]),
    (Array(reshape(1.0:60.0, 3,2,10)),[IARelations..., globalrel]),
    (Array(reshape(1.0:180.0, 3,3,2,10)),[IA2DRelations..., globalrel]),
]

nvars = nvariables(X)
features = collect(Iterators.flatten([[UnivariateMax{Float64}(i_var), UnivariateMin{Float64}(i_var)] for i_var in 1:nvars]))
logiset = scalarlogiset(X, features)

metaconditions = [ScalarMetaCondition(feature, >) for feature in features]
@test_nowarn SupportedLogiset(logiset, ())
@test_throws AssertionError SupportedLogiset(logiset, [Dict()])
@test_throws AssertionError SupportedLogiset(logiset, [Dict{SyntaxTree,WorldSet{worldtype(logiset)}}()])
@test_nowarn SupportedLogiset(logiset, [Dict{SyntaxTree,WorldSet{worldtype(logiset)}}() for i in 1:10])
@test_throws AssertionError SupportedLogiset(logiset, ([Dict{SyntaxTree,WorldSet{worldtype(logiset)}}() for i in 1:10], [Dict{SyntaxTree,WorldSet{worldtype(logiset)}}() for i in 1:10]))
@test_throws AssertionError SupportedLogiset(logiset; use_full_memoization = false)
@test_throws AssertionError SupportedLogiset(logiset; use_onestep_memoization = true)
supported_logiset = @test_nowarn SupportedLogiset(logiset; use_full_memoization = true, use_onestep_memoization = true, conditions = metaconditions, relations = relations)
@test_throws AssertionError SupportedLogiset(logiset, (supported_logiset, [Dict{SyntaxTree,WorldSet{worldtype(logiset)}}() for i in 1:10]))
supported_logiset = @test_nowarn SupportedLogiset(logiset; use_full_memoization = false, use_onestep_memoization = true, conditions = metaconditions, relations = relations)

@test_nowarn SupportedLogiset(logiset, (supported_logiset, [Dict{SyntaxTree,WorldSet{worldtype(logiset)}}() for i in 1:10]))
@test_nowarn SupportedLogiset(logiset, ([Dict{SyntaxTree,WorldSet{worldtype(logiset)}}() for i in 1:10], supported_logiset))

supported_logiset = @test_nowarn SupportedLogiset(logiset; use_full_memoization = true, conditions = metaconditions, relations = relations)

metaconditions = vcat([[ScalarMetaCondition(feature, >), ScalarMetaCondition(feature, <)] for feature in features]...)
complete_supported_logiset = @test_nowarn SupportedLogiset(logiset; use_full_memoization = true, conditions = metaconditions, relations = relations)

rng = Random.MersenneTwister(1)
alph = ExplicitAlphabet([SoleModels.ScalarCondition(rand(rng, features), rand(rng, [>, <]), rand(rng)) for i in 1:10]);
syntaxstring.(alph)
_formulas = [randformulatree(rng, 3, alph, [SoleLogics.BASE_MULTIMODAL_OPERATORS..., vcat([[DiamondRelationalOperator(r), BoxRelationalOperator(r)] for r in relations]...)[1:16:end]...]) for i in 1:20];
syntaxstring.(_formulas) .|> println;

i_instance = 1
@test_nowarn checkcondition(atom(alph.propositions[1]), logiset, i_instance, first(allworlds(X, i_instance)))

c1 = @test_nowarn [
        [check(φ, logiset, i_instance, w) for φ in _formulas]
    for w in allworlds(X, i_instance)]
@test_throws ErrorException [
        [check(φ, supported_logiset, i_instance, w) for φ in _formulas]
    for w in allworlds(X, i_instance)]
c3 = @test_nowarn [
        [check(φ, complete_supported_logiset, i_instance, w) for φ in _formulas]
    for w in allworlds(X, i_instance)]

@test c1 == c3

@test_nowarn concatdatasets(logiset, logiset, logiset)
@test_broken concatdatasets(complete_supported_logiset, complete_supported_logiset)
end
