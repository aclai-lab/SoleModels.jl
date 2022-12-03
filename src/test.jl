using Revise

using SoleLogics
using SoleModels
using SoleModels: ConstantModel
using Test

dtmodel = DecisionTree(branch_r, (;))
msmodel = MixedSymbolicModel(dtmodel)
