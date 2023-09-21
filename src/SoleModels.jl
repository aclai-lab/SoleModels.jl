module SoleModels

using SoleBase

using SoleData
using SoleData: _isnan

using SoleLogics
using SoleLogics: AbstractInterpretation, AbstractInterpretationSet
using SoleLogics: AbstractSyntaxToken
using SoleLogics: AbstractFormula, Formula, synstruct
using SoleLogics: ⊤, ¬, ∧

using FunctionWrappers: FunctionWrapper
using StatsBase
using ThreadSafeDicts
using Lazy

include("utils.jl")

using .utils

export minify, isminifiable

# Minification interface for lossless data compression
include("utils/minify.jl")

include("MLJ-utils.jl")

include("example-datasets.jl")

############################################################################################
############################################################################################
############################################################################################

export AbstractFeature, Feature

export atoms

export slicedataset, concatdatasets

export World, Feature, featvalue
export ValueCondition, FunctionalCondition
export parsecondition
export SupportedLogiset, nmemoizedvalues
export ExplicitBooleanLogiset, checkcondition
export ExplicitLogiset, ScalarCondition

export ninstances
export MultiLogiset, modality, nmodalities, modalities

export UnivariateNamedFeature,
        UnivariateFeature

export computefeature

export scalarlogiset

export initlogiset, maxchannelsize, worldtype, dimensionality, frame, featvalue, nvariables

export ScalarMetaCondition

export MixedCondition, CanonicalCondition, canonical_geq, canonical_leq

export canonical_geq_95, canonical_geq_90, canonical_geq_85, canonical_geq_80, canonical_geq_75, canonical_geq_70, canonical_geq_60,
       canonical_leq_95, canonical_leq_90, canonical_leq_85, canonical_leq_80, canonical_leq_75, canonical_leq_70, canonical_leq_60

export VarFeature,
        UnivariateMin, UnivariateMax,
        UnivariateSoftMin, UnivariateSoftMax,
        MultivariateFeature

export FullDimensionalFrame

# Definitions for logical datasets (i.e., logisets)
include("logisets/main.jl")

using .DimensionalDatasets: OneWorld, Interval, Interval2D
using .DimensionalDatasets: IARelations
using .DimensionalDatasets: IA2DRelations
using .DimensionalDatasets: identityrel
using .DimensionalDatasets: globalrel

############################################################################################
############################################################################################
############################################################################################

export outcometype, outputtype

export Rule, Branch
export antecedenttops
export antecedent, consequent
export posconsequent, negconsequent

export DecisionList
export rulebase, defaultconsequent

export apply, apply!

export DecisionTree
export root

export MixedSymbolicModel, DecisionForest

include("models/base.jl")

export printmodel, displaymodel

include("models/print.jl")

export immediatesubmodels, listimmediaterules
export listrules, joinrules

include("models/symbolic-utils.jl")

export Label, bestguess

include("machine-learning.jl")

export rulemetrics, readmetrics

include("models/evaluation.jl")

include("deprecate.jl")

end
