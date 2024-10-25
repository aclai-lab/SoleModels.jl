module SoleModels

using Reexport
using StatsBase
using ThreadSafeDicts
using Lazy
using FunctionWrappers: FunctionWrapper

using SoleBase

@reexport using SoleLogics
using SoleLogics
using SoleLogics: AbstractInterpretation, AbstractInterpretationSet
using SoleLogics: SyntaxToken
using SoleLogics: Formula, synstruct
using SoleLogics: ⊤, ¬, ∧

@reexport using SoleData
using SoleData: load_arff_dataset
using SoleData: AbstractLogiset, ismultilogiseed
using SoleData.DimensionalDatasets: OneWorld, Interval, Interval2D
using SoleData.DimensionalDatasets: IARelations
using SoleData.DimensionalDatasets: IA2DRelations
using SoleData.DimensionalDatasets: identityrel
using SoleData.DimensionalDatasets: globalrel

############################################################################################
############################################################################################
############################################################################################

export AbstractModel
export isopen
export outcometype, outputtype
export apply, apply!
export info, info!, hasinfo

export LeafModel

export ConstantModel
export outcome

export Rule, Branch
export checkantecedent
export antecedent, consequent
export posconsequent, negconsequent

export DecisionList
export rulebase, defaultconsequent


export DecisionTree
export root

export MixedModel, DecisionForest

include("types/base.jl")
include("utils/base.jl")

include("apply!.jl")

export printmodel, displaymodel

include("print.jl")

export immediatesubmodels, listimmediaterules
export listrules, joinrules

include("symbolic-utils.jl")

export AssociationRule, ClassificationRule, RegressionRule

include("machine-learning.jl")

export rulemetrics, readmetrics, metricstable

include("evaluate.jl")

include("experimentals.jl")

include("parse.jl")

include("deprecate.jl")

end
