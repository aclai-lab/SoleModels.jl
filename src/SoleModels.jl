module SoleModels

using SoleBase
using SoleData
using SoleLogics
using SoleLogics: AbstractInterpretation, AbstractInterpretationSet
using SoleLogics: AbstractSyntaxToken
using SoleLogics: AbstractFormula, Formula, synstruct
using SoleLogics: ⊤, ¬, ∧

using FunctionWrappers: FunctionWrapper
using StatsBase
using ThreadSafeDicts

include("utils.jl")

export outcometype, outputtype

export Rule, Branch
export check_antecedent
export antecedent, consequent
export posconsequent, negconsequent

export DecisionList
export rulebase, defaultconsequent

export DecisionTree
export root

export MixedSymbolicModel, DecisionForest

include("models/base.jl")

export printmodel, displaymodel

include("models/print.jl")

export immediatesubmodels, listimmediaterules
export listrules

include("models/symbolic-utils.jl")

export Label, bestguess

include("machine-learning.jl")

export rulemetrics

include("models/rule-evaluation.jl")

# TODO avoid?
export AbstractFeature,
        DimensionalFeature, AbstractUnivariateFeature,
        UnivariateNamedFeature,
        UnivariateMin, UnivariateMax,
        UnivariateSoftMin, UnivariateSoftMax,
        UnivariateFeature, MultivariateFeature,
        NamedFeature, ExternalFWDFeature

export propositions

export computefeature

export parsecondition

include("conditional-data/main.jl")

export nsamples, nframes, frames, nfeatures

include("dimensional-datasets/main.jl")

using .DimensionalDatasets: nfeatures, nrelations,
                            #
                            relations,
                            #
                            GenericModalDataset,
                            ActiveMultiFrameConditionalDataset,
                            AbstractActiveFeaturedDataset,
                            DimensionalFeaturedDataset,
                            FeaturedDataset,
                            SupportedFeaturedDataset

using .DimensionalDatasets: AbstractWorld, AbstractRelation
using .DimensionalDatasets: AbstractWorldSet, WorldSet
using .DimensionalDatasets: FullDimensionalFrame

using .DimensionalDatasets: Ontology, worldtype

using .DimensionalDatasets: get_ontology,
                            get_interval_ontology

using .DimensionalDatasets: OneWorld, OneWorldOntology

using .DimensionalDatasets: Interval, Interval2D

using .DimensionalDatasets: IARelations

end
