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
bool_condition = SoleModels.ValueCondition(features[1])

@test [SoleModels.checkcondition(bool_condition, bool_logiset, i_instance, w)
    for w in worlds] == Bool[0, 1, 1, 1, 0, 0, 0, 0, 0, 0]

# Scalar (Float)
rng = Random.MersenneTwister(1)
scalar_logiset = SoleModels.ExplicitLogiset([(Dict([w => Dict([f => rand(rng) for f in features]) for w in worlds]), fr)])
scalar_condition = SoleModels.ScalarCondition(features[1], >, 0.5)

@test [SoleModels.checkcondition(scalar_condition, scalar_logiset, i_instance, w)
    for w in worlds] == Bool[0, 0, 1, 1, 0, 1, 0, 1, 0, 0]

# Non-scalar (Vector{Float})
rng = Random.MersenneTwister(2)
nonscalar_logiset = SoleModels.ExplicitLogiset([(Dict([w => Dict([f => rand(rng, rand(rng, 1:3)) for f in features]) for w in worlds]), fr)])

@test SoleModels.featvalue(nonscalar_logiset, 1, worlds[1], features[1]) == SoleModels.featvalue(features[1], nonscalar_logiset, 1, worlds[1])

nonscalar_condition = SoleModels.FunctionalCondition(features[1], (vals)->length(vals) >= 2)

@test [SoleModels.checkcondition(nonscalar_condition, nonscalar_logiset, i_instance, w)
    for w in worlds] == Bool[0, 1, 0, 0, 1, 1, 1, 0, 1, 1]


multilogiset = MultiLogiset([bool_logiset, scalar_logiset, nonscalar_logiset])

@test SoleModels.modalitytype(multilogiset) <:
SoleModels.AbstractLogiset{SoleLogics.World{Int64}, U, SoleModels.Feature{String}, SoleLogics.ExplicitCrispUniModalFrame{SoleLogics.World{Int64}, SimpleDiGraph{Int64}}} where U

SoleModels.AbstractLogiset{SoleLogics.World{Int64}, U, Feature{String}, SoleLogics.ExplicitCrispUniModalFrame{SoleLogics.World{Int64}, SimpleDiGraph{Int64}}} where U <: SoleModels.AbstractLogiset{SoleLogics.World{Int64}, U, Feature{String}, SoleLogics.ExplicitCrispUniModalFrame{SoleLogics.World{Int64}, SimpleDiGraph{Int64}}} where U


@test_nowarn displaystructure(bool_logiset)
@test_nowarn displaystructure(scalar_logiset)
@test_nowarn displaystructure(multilogiset)


############################################################################################

for w in worlds
    @test accessibles(fr, w) == accessibles(scalar_logiset, 1, w)
    @test representatives(fr, w, scalar_condition) == representatives(scalar_logiset, 1, w, scalar_condition)
end

cond1 = SoleModels.ScalarCondition(features[1], >, 0.9)
cond2 = SoleModels.ScalarCondition(features[2], >, 0.3)

for w in worlds
    @test (featvalue(scalar_logiset, 1, w, features[1]) > 0.9) == check(Proposition(cond1) ∧ ⊤, scalar_logiset, 1, w)
    @test (featvalue(scalar_logiset, 1, w, features[2]) > 0.3) == check(Proposition(cond2) ∧ ⊤, scalar_logiset, 1, w)
end

# Propositional formula
φ = ⊤ → Proposition(cond1) ∧ Proposition(cond2)
for w in worlds
    @test ((featvalue(scalar_logiset, 1, w, features[1]) > 0.9) && (featvalue(scalar_logiset, 1, w, features[2]) > 0.3)) == check(φ, scalar_logiset, 1, w)
end

# Modal formula
φ = ◊(⊤ → Proposition(cond1) ∧ Proposition(cond2))
for w in worlds
    @test check(φ, scalar_logiset, 1, w) == (length(accessibles(fr, w)) > 0 && any([
        ((featvalue(scalar_logiset, 1, v, features[1]) > 0.9) && (featvalue(scalar_logiset, 1, v, features[2]) > 0.3))
    for v in accessibles(fr, w)]))
end

# Modal formula on multilogiset
for w in worlds
    @test check(φ, multilogiset, 2, 1, w) == (length(accessibles(fr, w)) > 0 && any([
        ((featvalue(multilogiset, 2, 1, v, features[1]) > 0.9) && (featvalue(multilogiset, 2, 1, v, features[2]) > 0.3))
    for v in accessibles(fr, w)]))
end

############################################################################################

# Check with memoset

w = worlds[1]
W = worldtype(bool_logiset)
bool_supported_logiset = SupportedLogiset(bool_logiset)
scalar_supported_logiset = SupportedLogiset(scalar_logiset)
nonscalar_supported_logiset = SupportedLogiset(nonscalar_logiset)

@test SoleModels.featvalue(nonscalar_logiset, 1, worlds[1], features[1]) == SoleModels.featvalue(nonscalar_supported_logiset, 1, worlds[1], features[1])

@test_nowarn displaystructure(bool_supported_logiset)
@test_nowarn displaystructure(scalar_supported_logiset)
@test_nowarn displaystructure(nonscalar_supported_logiset)

@test_nowarn slicedataset(bool_logiset, [1])
@test_nowarn slicedataset(bool_logiset, [1]; return_view = true)
@test_nowarn slicedataset(bool_supported_logiset, [1])

@test_nowarn SoleModels.allfeatvalues(bool_logiset)
@test_nowarn SoleModels.allfeatvalues(bool_logiset, 1)
@test_nowarn SoleModels.allfeatvalues(bool_logiset, 1, features[1])
@test_nowarn SoleModels.allfeatvalues(bool_supported_logiset)
@test_nowarn SoleModels.allfeatvalues(bool_supported_logiset, 1)
@test_nowarn SoleModels.allfeatvalues(bool_supported_logiset, 1, features[1])

@test SoleLogics.allworlds(bool_logiset, 1) == SoleLogics.allworlds(bool_supported_logiset, 1)
@test SoleLogics.nworlds(bool_logiset, 1) == SoleLogics.nworlds(bool_supported_logiset, 1)
@test SoleLogics.frame(bool_logiset, 1) == SoleLogics.frame(bool_supported_logiset, 1)


@test_throws AssertionError SoleModels.parsecondition(SoleModels.ScalarCondition, "p > 0.5")
@test_nowarn SoleModels.parsecondition(SoleModels.ScalarCondition, "p > 0.5"; featvaltype = String, featuretype = Feature)
@test SoleModels.ScalarCondition(features[1], >, 0.5) == SoleModels.parsecondition(SoleModels.ScalarCondition, "p > 0.5"; featvaltype = String, featuretype = Feature)

############################################################################################
# Memoset's
############################################################################################

memoset = [ThreadSafeDict{SyntaxTree,WorldSet{W}}() for i_instance in 1:ninstances(bool_supported_logiset)]

@test_nowarn check(φ, bool_logiset, 1, w)
@test_nowarn check(φ, bool_logiset, 1, w; use_memo = nothing)
@test_nowarn check(φ, bool_logiset, 1, w; use_memo = memoset)
@test_nowarn check(φ, bool_supported_logiset, 1, w)
@test_nowarn check(φ, bool_supported_logiset, 1, w; use_memo = nothing)
@test_logs (:warn,) check(φ, bool_supported_logiset, 1, w; use_memo = memoset)


bool_supported_logiset2 = @test_nowarn SupportedLogiset(bool_logiset, memoset)
bool_supported_logiset2 = @test_nowarn SupportedLogiset(bool_logiset, (memoset,))
bool_supported_logiset2 = @test_nowarn SupportedLogiset(bool_logiset, [memoset])

@test_throws AssertionError SupportedLogiset(bool_supported_logiset2)

@test_nowarn SupportedLogiset(bool_logiset, bool_supported_logiset2)

@test_nowarn SupportedLogiset(bool_logiset, (bool_supported_logiset2,))
@test_nowarn SupportedLogiset(bool_logiset, [bool_supported_logiset2])


rng = Random.MersenneTwister(1)
alph = ExplicitAlphabet([SoleModels.ScalarCondition(rand(rng, features), rand(rng, [>, <]), rand(rng)) for i in 1:10])
syntaxstring.(alph)
_formulas = [randformulatree(rng, 4, alph, [NEGATION, CONJUNCTION, IMPLICATION, DIAMOND, BOX]) for i in 1:10]
@test_nowarn syntaxstring.(_formulas)
@test_nowarn syntaxstring.(_formulas; threshold_decimals = 2)

c1 = @test_nowarn [check(φ, bool_logiset, 1, w) for φ in _formulas]
c2 = @test_nowarn [check(φ, bool_logiset, 1, w; use_memo = nothing) for φ in _formulas]
c3 = @test_nowarn [check(φ, bool_logiset, 1, w; use_memo = memoset) for φ in _formulas]
c4 = @test_nowarn [check(φ, SupportedLogiset(bool_logiset), 1, w) for φ in _formulas]
c5 = @test_nowarn [check(φ, SupportedLogiset(bool_logiset), 1, w; use_memo = nothing) for φ in _formulas]
# c6 = @test_logs (:warn,) [check(φ, bool_supported_logiset, 1, w; use_memo = memoset) for φ in _formulas]

@test c1 == c2 == c3 == c4 == c5

w = worlds[1]
W = worldtype(scalar_logiset)
memoset = [ThreadSafeDict{SyntaxTree,WorldSet{W}}() for i_instance in 1:ninstances(scalar_logiset)]
@test_throws AssertionError check(φ, scalar_logiset, 1; use_memo = nothing)
@time check(φ, scalar_logiset, 1, w; use_memo = nothing)
@time check(φ, scalar_logiset, 1, w; use_memo = memoset)


############################################################################################
# Scalar memoset's
############################################################################################

using SoleModels: ScalarMetaCondition
using SoleModels: ScalarOneStepRelationalMemoset, ScalarOneStepGlobalMemoset

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
bool_onestepmemoset_full = @test_logs (:warn,) ScalarOneStepMemoset(bool_logiset, metaconditions, relations; precompute_globmemoset = true, precompute_relmemoset = true)

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
_formulas = [randformulatree(rng, 10, alph, SoleLogics.BASE_MULTIMODAL_OPERATORS) for i in 1:20];

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
