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

export minify, isminifiable

# Minification interface for lossless data compression
include("utils/minify.jl")

export AbstractFeature,
        NamedFeature, ExternalFWDFeature

export propositions

export computefeature, parsecondition
export frames

# Definitions for logical datasets (i.e., logisets)
include("datasets/base/main.jl")

# include("datasets/scalar-datasets/main.jl")

# export ninstances, nframes, frames, nfeatures

# export get_ontology,
#        get_interval_ontology

# export DimensionalLogiset, Logiset, SupportedScalarLogiset

# export parsecondition

# export UnivariateMin, UnivariateMax,
#         UnivariateSoftMin, UnivariateSoftMax,
#         MultivariateFeature

# export DimensionalFeature, AbstractUnivariateFeature,
#         UnivariateNamedFeature,
#         UnivariateFeature

# include("datasets/dimensional-datasets/main.jl")

# using .DimensionalDatasets: parsecondition

# using .DimensionalDatasets: nfeatures, nrelations,
#                             #
#                             relations,
#                             #
#                             GenericModalDataset,
#                             AbstractLogiset,
#                             AbstractActiveScalarLogiset,
#                             DimensionalLogiset,
#                             Logiset,
#                             SupportedScalarLogiset

# using .DimensionalDatasets: AbstractWorld, AbstractRelation
# using .DimensionalDatasets: AbstractWorldSet, WorldSet
# using .DimensionalDatasets: FullDimensionalFrame

# using .DimensionalDatasets: Ontology, worldtype

# using .DimensionalDatasets: get_ontology,
#                             get_interval_ontology

# using .DimensionalDatasets: OneWorld, OneWorldOntology

# using .DimensionalDatasets: Interval, Interval2D

# using .DimensionalDatasets: IARelations

end
