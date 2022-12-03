module SoleModels


abstract type AbstractInstance end


using SoleLogics
using SoleData

using Reexport

using SoleLogics: AbstractLogic, Formula

using FunctionWrappers: FunctionWrapper

import Base: convert


export AbstractModel

export FinalOutcome, outcome_type, output_type
export print_model

export Consequent
export Performance

export Rule, Branch

export DecisionList, RuleCascade
export DecisionTree, MixedSymbolicModel

include("models/base.jl")
include("models/print.jl")
include("models/symbolic-utils.jl")

include("machine-learning.jl")

include("confusion-matrix.jl")

end
