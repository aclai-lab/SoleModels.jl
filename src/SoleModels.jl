module SoleModels


abstract type AbstractInstance end


using SoleLogics
using SoleData

using Reexport

export AbstractModel
export Consequent
export Performance

export Rule, Branch

export DecisionList, RuleCascade
export DecisionTree, MixedSymbolicModel

include("definitions.jl")

include("confusion-matrix.jl")

end
