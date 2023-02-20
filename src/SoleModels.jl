module SoleModels

using SoleData
using SoleLogics
using SoleLogics: AbstractInterpretation, AbstractInterpretationSet
using SoleLogics: Formula
using SoleLogics: TOP, ¬, ∧

# Move to SoleLogics? Or make SyntaxTree <: AbstractFormula and use AbstractFormula
const FormulaOrTree = Union{Formula,SyntaxTree}

using FunctionWrappers: FunctionWrapper

using StatsBase

using Reexport # TODO remove

export AbstractInterpretation, AbstractInterpretationSet

include("utils.jl")

export AbstractModel
export outcometype, outputtype

export Rule, Branch
export DecisionList, RuleCascade
export DecisionTree, MixedSymbolicModel
export evaluate_antecedent, evaluate_rule # TODO need to export?
export rule_metrics # TODO need to export?

export antecedent, consequent, posconsequent, negconsequent, defaultconsequent
export rules, root

include("models/base.jl")

export printmodel, displaymodel

include("models/print.jl")

export list_paths # TODO fix this

# TODO export?
export immediate_submodels, unroll_rules, list_immediate_rules, unroll_rules_cascade

include("models/symbolic-utils.jl")

include("models/rule-evaluation.jl")

include("machine-learning.jl")

include("confusion-matrix.jl")

# TODO avoid?
export AbstractFeature,
        DimensionalFeature, SingleAttributeFeature,
        SingleAttributeNamedFeature,
        SingleAttributeMin, SingleAttributeMax,
        SingleAttributeSoftMin, SingleAttributeSoftMax,
        SingleAttributeGenericFeature, MultiAttributeFeature,
        NamedFeature, ExternalFWDFeature

export compute_feature

include("conditional-data/main.jl")


end
