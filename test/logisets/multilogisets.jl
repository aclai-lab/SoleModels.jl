using Test
using StatsBase
using Random
using SoleLogics
using SoleModels
using SoleModels.DimensionalDatasets


n_instances = 2
_nvars = 2

multidataset, multirelations = collect.(zip([
    (Array(reshape(1.0:4.0, _nvars,n_instances)), [globalrel]),
    (Array(reshape(1.0:12.0, 3,_nvars,n_instances)), [IARelations..., globalrel]),
    (Array(reshape(1.0:36.0, 3,3,_nvars,n_instances)), [IA2DRelations..., globalrel]),
]...))

multilogiset = @test_nowarn scalarlogiset(multidataset)

generic_features = collect(Iterators.flatten([[UnivariateMax(i_var), UnivariateMin(i_var)] for i_var in 1:_nvars]))
metaconditions = [ScalarMetaCondition(feature, >) for feature in generic_features]
multilogiset = @test_nowarn scalarlogiset(multidataset; use_full_memoization = false, use_onestep_memoization = true, conditions = metaconditions, relations = multirelations)
multilogiset = @test_nowarn scalarlogiset(multidataset; use_full_memoization = true, use_onestep_memoization = true, conditions = metaconditions, relations = multirelations)

metaconditions = vcat([[ScalarMetaCondition(feature, >), ScalarMetaCondition(feature, <)] for feature in generic_features]...)
complete_supported_multilogiset = @test_nowarn scalarlogiset(multidataset; use_full_memoization = true, use_onestep_memoization = true, conditions = metaconditions, relations = multirelations)


@test_nowarn slicedataset(multilogiset, [2,1])
@test_nowarn slicedataset(complete_supported_multilogiset, [2,1])
@test_nowarn concatdatasets(multilogiset, multilogiset, multilogiset)
@test_nowarn concatdatasets(complete_supported_multilogiset, complete_supported_multilogiset)


rng = Random.MersenneTwister(1)
alph = ExplicitAlphabet([SoleModels.ScalarCondition(rand(rng, generic_features), rand(rng, [>, <]), rand(rng)) for i in 1:n_instances]);
# syntaxstring.(alph)

i_instance = 1

@test_broken multiformulas = [begin
    _formulas_dict = Dict{Int,SoleLogics.AbstractFormula}()
    for (i_modality, relations) in enumerate(multirelations)
        f = randformula(rng, 3, alph, [SoleLogics.BASE_PROPOSITIONAL_OPERATORS..., vcat([[DiamondRelationalOperator(r), BoxRelationalOperator(r)] for r in relations]...)[1:32:end]...])
        if rand(Bool)
            # coin = rand(1:3)
            coin = rand(2:3)
            f = begin
                if coin == 1
                    AnchoredFormula(f, SoleModels.GlobalCheck())
                elseif coin == 2
                    AnchoredFormula(f, SoleModels.CenteredCheck())
                else
                    AnchoredFormula(f, SoleModels.WorldCheck(rand(collect(allworlds(modality(multilogiset, i_modality), i_instance)))))
                end
            end
            _formulas_dict[i_modality] = f
        end
    end
    MultiAntecedent(_formulas_dict)
end for i in 1:200];
# syntaxstring.(multiformulas) .|> println;

@test_throws MethodError checkcondition(atom(alph.propositions[1]), multilogiset, i_instance)

c1 = @test_nowarn [check(φ, multilogiset, i_instance) for φ in multiformulas]
c3 = @test_nowarn [check(φ, complete_supported_multilogiset, i_instance) for φ in multiformulas]

@test c1 == c3
