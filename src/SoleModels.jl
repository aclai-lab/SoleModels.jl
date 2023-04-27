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

# TODO export?
export immediatesubmodels, unrollrules, immediaterules

include("models/symbolic-utils.jl")

include("machine-learning.jl")

include("models/rule-evaluation.jl")

# TODO avoid?
export AbstractFeature,
        DimensionalFeature, SingleAttributeFeature,
        SingleAttributeNamedFeature,
        SingleAttributeMin, SingleAttributeMax,
        SingleAttributeSoftMin, SingleAttributeSoftMax,
        SingleAttributeGenericFeature, MultiAttributeFeature,
        NamedFeature, ExternalFWDFeature

export propositions

export compute_feature

include("conditional-data/main.jl")

end
