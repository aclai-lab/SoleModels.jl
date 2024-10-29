############################################################################################
# Evaluate Interface
############################################################################################

using StatsBase
using SoleModels
using SoleModels: LeafModel
import SoleLogics: natoms

"""
Abstract interface for computing accuracy between true and predicted labels.
"""
function accuracy end

"""
Abstract interface for computing error between true and predicted labels.
"""
function _error end

"""
Abstract interface for computing mean absolute error.
"""
function mae end

"""
Abstract interface for computing mean squared error.
"""
function mse end

"""
Abstract interface for reading metrics from a model.
"""
function readmetrics end

"""
Abstract interface for evaluating a rule on a dataset.
"""
function evaluaterule end

"""
Abstract interface for computing rule-specific metrics.
"""
function rulemetrics end

"""
Represents the result of rule evaluation.
Contains antecedent satisfaction and predictions.
"""
struct RuleEvaluation{T}
    antsat::Vector{Bool}
    ys::Vector{Union{Nothing,T}}
end

"""
Represents the metrics computed for a rule.
"""
struct RuleMetrics
    antsat::Vector{Bool}
    support::Float64
    error::Float64
    length::Int
end

"""
Represents the metrics table configuration.
"""
struct MetricsTableConfig
    metrics_kwargs::NamedTuple
    syntaxstring_kwargs::NamedTuple
    pretty_table_kwargs::NamedTuple
end

# Type declarations for metric computation results
const MetricResult = Union{Float64,Nothing}
const MetricsDict = Dict{Symbol,MetricResult}
const ModelMetrics = NamedTuple

# Export the interface
export accuracy, _error, mae, mse, readmetrics, evaluaterule, rulemetrics
export RuleEvaluation, RuleMetrics, MetricsTableConfig
export MetricResult, MetricsDict, ModelMetrics