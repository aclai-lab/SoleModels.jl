module SoleModels

using Reexport
using StatsBase
using ThreadSafeDicts
using Lazy
using Lazy: @forward
using FunctionWrappers: FunctionWrapper
using CategoricalArrays

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
export iscomplete
export outcometype, outputtype
export immediatesubmodels, nimmediatesubmodels, listimmediaterules
export apply, apply!
export info, info!, hasinfo
export wrap

export LeafModel

export ConstantModel
export outcome

export FunctionModel

export Rule, Branch
export antecedent, consequent
export checkantecedent
export posconsequent, negconsequent

export DecisionList
export rulebase, defaultconsequent

export DecisionTree
export root
export nnodes, nleaves
export height

export DecisionEnsemble, models
export DecisionForest, trees
export DecisionSet, rules, nrules

export DecisionXGBoost

export MixedModel

export haslistrules, solemodel

export isensemble

include("types/model.jl")
include("types/AbstractTrees.jl")
include("types/api.jl")

include("utils/models/leaf.jl")
include("utils/models/rule-and-branch.jl")
include("utils/models/other.jl")
include("utils/models/meta.jl") # TODO deprecate?
include("utils/models/ensembles.jl")
include("utils/models/linear-forms-utilities.jl")
include("utils/models/wrap.jl")
include("utils/models/syntax-utilities.jl")


export printmodel, displaymodel

include("print.jl")

export submodels, nsubmodels
export leafmodels, nleafmodels
export subtreeheight

include("symbolic-utils.jl")

export PlainRuleExtractor
export extractrules, listrules, joinrules

include("rule-extraction.jl")

export AssociationRule, ClassificationRule, RegressionRule

include("machine-learning.jl")

export rulemetrics, readmetrics, metricstable

include("evaluate.jl")

include("experimentals.jl")

include("parse.jl")

include("deprecate.jl")

end
