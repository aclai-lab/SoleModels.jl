module SoleModels

using Reexport

using SoleBase

@reexport using SoleData

using SoleData: AbstractLogiset, ismultilogiseed

@reexport using SoleLogics
using SoleLogics
using SoleLogics: AbstractInterpretation, AbstractInterpretationSet
using SoleLogics: SyntaxToken
using SoleLogics: Formula, synstruct
using SoleLogics: ⊤, ¬, ∧

using FunctionWrappers: FunctionWrapper
using StatsBase
using ThreadSafeDicts
using Lazy

using SoleData: load_arff_dataset

############################################################################################
############################################################################################
############################################################################################

using SoleData.DimensionalDatasets: OneWorld, Interval, Interval2D
using SoleData.DimensionalDatasets: IARelations
using SoleData.DimensionalDatasets: IA2DRelations
using SoleData.DimensionalDatasets: identityrel
using SoleData.DimensionalDatasets: globalrel

############################################################################################
############################################################################################
############################################################################################

export outcometype, outputtype

export ConstantModel

export Rule, Branch
export checkantecedent
export antecedent, consequent
export posconsequent, negconsequent

export DecisionList
export rulebase, defaultconsequent

export apply, apply!

export DecisionTree
export root

export MixedModel, DecisionForest

include("base.jl")

include("apply!.jl")

export printmodel, displaymodel

include("print.jl")

export immediatesubmodels, listimmediaterules
export listrules, joinrules

include("symbolic-utils.jl")

export AssociationRule, ClassificationRule, RegressionRule

include("machine-learning.jl")

export rulemetrics, readmetrics

include("evaluation.jl")

include("experimentals.jl")

include("parse.jl")

include("deprecate.jl")

end
