module SoleModels

using SoleLogics
using SoleData

using Reexport

export AbstractModel
export Consequent
export Performance

export Rule, Branch
export DecisionList, DecisionTree

include("definitions.jl")

include("confusion-matrix.jl")

end
