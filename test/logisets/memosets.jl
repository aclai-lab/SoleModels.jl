
############################################################################################
# Scalar memoset's
############################################################################################

using SoleModels: ScalarMetaCondition
using SoleModels: ScalarOneStepRelationalMemoset, ScalarOneStepGlobalMemoset

using Test
using StatsBase
using SoleLogics
using SoleModels
using Graphs
using Random
using ThreadSafeDicts

features = SoleModels.Feature.(string.('p':'z'))
worlds = SoleLogics.World.(1:10)
fr = SoleLogics.ExplicitCrispUniModalFrame(worlds, SimpleDiGraph(length(worlds), 4))

i_instance = 1

# Boolean
rng = Random.MersenneTwister(1)
bool_logiset = SoleModels.ExplicitBooleanLogiset([(Dict([w => sample(rng, features, 2, replace = false) for w in worlds]), fr)])

# metaconditions = [ScalarMetaCondition(features[1], >)]
metaconditions = [ScalarMetaCondition(f, test_op) for f in features for test_op in [>,<]]

@test_nowarn ScalarOneStepGlobalMemoset{Interval,Float64}(rand(1,22))

perform_initialization = true
bool_relationalmemoset = @test_nowarn ScalarOneStepRelationalMemoset(bool_logiset, metaconditions, [globalrel], perform_initialization)
bool_globalmemoset = @test_nowarn ScalarOneStepGlobalMemoset(bool_logiset, metaconditions, perform_initialization)

@test_throws MethodError SupportedLogiset(bool_logiset, bool_relationalmemoset)

using SoleModels: ScalarOneStepMemoset

relations = [identityrel, globalrel]

# bool_onestepmemoset = @test_logs (:warn,) ScalarOneStepMemoset(bool_relationalmemoset, bool_globalmemoset, metaconditions, relations)
bool_onestepmemoset = @test_logs (:warn,) ScalarOneStepMemoset{Bool}(bool_relationalmemoset, bool_globalmemoset, metaconditions, relations)

bool_onestepmemoset_empty = @test_logs (:warn,) ScalarOneStepMemoset(bool_logiset, metaconditions, relations)
bool_onestepmemoset_full = @test_logs (:warn,) ScalarOneStepMemoset(bool_logiset, metaconditions, relations; precompute_globmemoset = false, precompute_relmemoset = false)

# TODO test:
# bool_onestepmemoset_full = @test_logs (:warn,) ScalarOneStepMemoset(bool_logiset, metaconditions, relations; precompute_globmemoset = true, precompute_relmemoset = true)

@test_nowarn SupportedLogiset(bool_logiset, bool_onestepmemoset)
@test_nowarn SupportedLogiset(bool_logiset, (bool_onestepmemoset,))
@test_nowarn SupportedLogiset(bool_logiset, (bool_onestepmemoset, bool_onestepmemoset))
@test_nowarn SupportedLogiset(bool_logiset, [bool_onestepmemoset, bool_onestepmemoset])

@test_nowarn SupportedLogiset(bool_logiset, bool_onestepmemoset, memoset)
@test_nowarn SupportedLogiset(bool_logiset, (bool_onestepmemoset, memoset))
@test_nowarn SupportedLogiset(bool_logiset, [bool_onestepmemoset, memoset])

# bool_logiset_2layer = SupportedLogiset(bool_logiset, bool_onestepmemoset)
memoset = [ThreadSafeDict{SyntaxTree,WorldSet{W}}() for i_instance in 1:ninstances(bool_logiset)]
bool_logiset_2layer = SupportedLogiset(bool_logiset)
# bool_logiset_3layer = SupportedLogiset(bool_logiset, [bool_onestepmemoset, memoset])
bool_logiset_3layer = SupportedLogiset(bool_logiset, [bool_onestepmemoset_empty, memoset])
# bool_logiset_3layer = SupportedLogiset(bool_logiset, [bool_onestepmemoset_full, memoset])

rng = Random.MersenneTwister(1)
alph = ExplicitAlphabet([SoleModels.ScalarCondition(rand(rng, features), rand(rng, [>, <]), rand(rng)) for i in 1:10])
syntaxstring.(alph)
_formulas = [randformula(rng, 10, alph, SoleLogics.BASE_MULTIMODAL_OPERATORS) for i in 1:20];

# Below are the times with a testset of 1000 formulas
############################################################################################
# 223.635 ms (1459972 allocations: 59.18 MiB)
############################################################################################
c1 = @test_nowarn [check(φ, bool_logiset, 1, w) for φ in _formulas]
############################################################################################
c1 = @test_nowarn [check(φ, bool_logiset, 1, w; perform_normalization = false) for φ in _formulas]

############################################################################################
# 107.169 ms (545163 allocations: 14.71 MiB)
############################################################################################
c2 = @test_nowarn [check(φ, bool_logiset_2layer, 1, w) for φ in _formulas]
############################################################################################
c2 = @test_nowarn [check(φ, bool_logiset_2layer, 1, w; perform_normalization = false) for φ in _formulas]

############################################################################################
# 34.990 ms (301175 allocations: 14.93 MiB)
############################################################################################
memoset = [ThreadSafeDict{SyntaxTree,WorldSet{W}}() for i_instance in 1:ninstances(bool_logiset)]
bool_logiset_3layer = SupportedLogiset(bool_logiset, [bool_onestepmemoset_empty, memoset])
c4 = @test_nowarn [check(φ, bool_logiset_3layer, 1, w; perform_normalization = false) for φ in _formulas]
############################################################################################

@test c1 == c2 == c4


@test SoleModels.nmemoizedvalues(bool_logiset_3layer.supports[1].relmemoset) > 0

@test_nowarn slicedataset(bool_relationalmemoset, [1])
@test_nowarn slicedataset(bool_globalmemoset, [1])
@test_nowarn slicedataset(bool_onestepmemoset, [1])
@test_nowarn slicedataset(bool_logiset_2layer, [1])
@test_nowarn slicedataset(bool_logiset_3layer, [1])

@test_nowarn concatdatasets(bool_relationalmemoset, bool_relationalmemoset, bool_relationalmemoset)
@test_nowarn concatdatasets(bool_globalmemoset, bool_globalmemoset, bool_globalmemoset)
@test_nowarn concatdatasets(bool_onestepmemoset, bool_onestepmemoset, bool_onestepmemoset)
@test_nowarn concatdatasets(bool_logiset_2layer, bool_logiset_2layer, bool_logiset_2layer)
@test_nowarn concatdatasets(bool_logiset_3layer, bool_logiset_3layer, bool_logiset_3layer)
