module SoleModels


abstract type AbstractInstance end


using SoleLogics
using SoleData
using SoleData: AbstractDimensionalInstance, get_instance_attribute

using Reexport

using SoleLogics: AbstractLogic, Formula

using FunctionWrappers: FunctionWrapper

using Logging: LogLevel, @logmsg

using StatsBase

import Base: convert


export AbstractModel

export outcometype, output_type
export print_model

export Consequent
export Performance

export Rule, Branch

export DecisionList, RuleCascade
export DecisionTree, MixedSymbolicModel

export evaluate_antecedent, evaluate_rule
export rule_metrics
export convert, list_paths

include("models/base.jl")
include("models/print.jl")
include("models/symbolic-utils.jl")

include("machine-learning.jl")

include("confusion-matrix.jl")

include("data/features.jl")
include("data/test-operators.jl")
include("data/conditional-data-prototype.jl")


end
