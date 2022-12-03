module SoleModels


abstract type AbstractInstance end


using SoleLogics
using SoleData

using Reexport

using SoleLogics: AbstractLogic, Formula

using FunctionWrappers: FunctionWrapper

import Base: convert


export AbstractModel
export Consequent
export Performance

export Rule, Branch

export DecisionList, RuleCascade
export DecisionTree, MixedSymbolicModel

include("models.jl")

include("confusion-matrix.jl")

end
