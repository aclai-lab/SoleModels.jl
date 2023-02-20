module SoleModels

using SoleLogics
using SoleData

using SoleLogics: AbstractInterpretation, AbstractInterpretationSet
using SoleLogics: AbstractTruthOperator

using FunctionWrappers: FunctionWrapper

import Base: convert, length, getindex, isopen
import SoleLogics: check, syntaxstring

export AbstractInterpretation, AbstractInterpretationSet

include("utils.jl")

# Move to SoleLogics?
# using SoleLogics: FormulaOrTree
const FormulaOrTree = Union{Formula,SyntaxTree}

include("models/base.jl")

export printmodel, displaymodel
include("models/print.jl")

# TODO from here onwards

using SoleData: AbstractDimensionalInstance, get_instance_attribute

using Reexport

using SoleLogics: AbstractLogic, Formula


using Logging: LogLevel, @logmsg

using StatsBase


export AbstractModel

export outcometype, output_type
export displaymodel, printmodel

export Performance

export Rule, Branch

export DecisionList, RuleCascade
export DecisionTree, MixedSymbolicModel
export evaluate_antecedent, evaluate_rule
export rule_metrics
export convert, list_paths
########################################################################

export antecedent, consequent, positive_consequent, negative_consequent, default_consequent, rules, root


using SoleLogics: Formula, TOP, ⊤, ¬, ∧


include("models/symbolic-utils.jl")
include("models/rule-evaluation.jl")

include("machine-learning.jl")

include("confusion-matrix.jl")

include("conditional-data/main.jl")


end
