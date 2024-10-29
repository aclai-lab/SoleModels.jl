############################################################################################
# Evaluate Implementation
############################################################################################

using StatsBase
using SoleModels
using SoleModels: LeafModel
using FillArrays
using PrettyTables
import SoleLogics: natoms
import .EvaluationTypes: accuracy, _error, mae, mse, readmetrics, evaluaterule, rulemetrics
import .EvaluationTypes: RuleEvaluation, RuleMetrics, MetricsTableConfig

####################### Metric Implementations #####################

function accuracy(y_true::AbstractArray, y_pred::AbstractArray)
    @assert length(y_true) == length(y_pred) "Ground truth and predicted labels should have the same length, but $(length(y_true)) ≠ $(length(y_pred))."
    return (length(y_pred) == 0) ? NaN : sum(y_pred .== y_true)/length(y_pred)
end

function _error(y_true::AbstractArray, y_pred::AbstractArray)
    return 1.0 - accuracy(y_true, y_pred)
end

function mae(y_true::AbstractArray, y_pred::AbstractArray)
    @assert length(y_true) == length(y_pred) "Ground truth and predicted labels should have the same length."
    return (length(y_pred) == 0) ? NaN : StatsBase.mean(abs, y_true - y_pred)
end

function mse(y_true::AbstractArray, y_pred::AbstractArray)
    @assert length(y_true) == length(y_pred) "Ground truth and predicted labels should have the same length."
    return (length(y_pred) == 0) ? NaN : StatsBase.mean(abs2, y_true - y_pred)
end

####################### Utility Functions #####################

function _metround(val, round_digits)
    return isnothing(round_digits) ? val : round(val; digits = round_digits)
end

####################### Model Metrics Implementation #####################

function readmetrics(m::LeafModel{L}; class_share_map = nothing, round_digits = nothing, 
                    additional_metrics = (;)) where {L<:Label}
    # Implementation remains the same as original
    merge(if haskey(info(m), :supporting_labels)
        _gts = info(m).supporting_labels
        if L <: CLabel && isnothing(class_share_map)
            class_share_map = Dict(map(((k,v),)->k => v./length(_gts), collect(StatsBase.countmap(_gts))))
        end
        base_metrics = (; ninstances = length(_gts), ncovered = length(_gts), )
        if (haskey(info(m), :supporting_predictions) || m isa ConstantModel)
            _preds = if haskey(info(m), :supporting_predictions)
                info(m).supporting_predictions
            elseif m isa ConstantModel
                Fill(outcome(m), length(_gts))
            else
                error("Implementation error in readmetrics.")
            end
            conf_metrics = begin
                if L <: CLabel
                    confidence = accuracy(_gts, _preds)
                    cmet = (; confidence = _metround(confidence, round_digits),)
                    if m isa ConstantModel && !isnothing(class_share_map)
                        class = outcome(m)
                        if haskey(class_share_map, class)
                            lift = confidence/class_share_map[class]
                            cmet = merge(cmet, (;
                                lift = _metround(lift, round_digits),
                            ))
                        else
                            cmet = merge(cmet, (;
                                lift = NaN,
                            ))
                        end
                    end
                    cmet
                elseif L <: RLabel
                    (;
                        mse = _metround(mse(_gts, _preds), round_digits),
                    )
                else
                    error("Could not compute readmetrics with unknown label type: $(L).")
                end
            end
            base_metrics = merge(base_metrics, conf_metrics)
        end
    else
        return (;)
    end, (; coverage = 1.0))
end

default_additional_metrics = (; natoms = r->natoms(antecedent(r)))

####################### Rule Evaluation Implementation #####################

function evaluaterule(rule::Rule, X::AbstractInterpretationSet, Y::AbstractVector{<:Label}; kwargs...)
    ys = apply(rule, X)
    antsat = ys .!= nothing
    return RuleEvaluation(antsat, ys)
end

function rulemetrics(rule::Rule, X::AbstractInterpretationSet, Y::AbstractVector{<:Label}; kwargs...)
    eval_result = evaluaterule(rule, X, Y; kwargs...)
    antsat = eval_result.antsat
    ys = eval_result.ys
    n_instances = ninstances(X)
    n_satisfy = sum(antsat)
    
    rule_support = n_satisfy / n_instances
    
    rule_error = if outcometype(consequent(rule)) <: CLabel
        _error(ys[antsat], Y[antsat])
    elseif outcometype(consequent(rule)) <: RLabel
        mse(ys[antsat], Y[antsat])
    else
        error("Unsupported outcome type: $(outcometype(consequent(rule)))")
    end
    
    return RuleMetrics(antsat, rule_support, rule_error, natoms(antecedent(rule)))
end

####################### Metrics Table Implementation #####################

function metricstable(ms::Vector{<:Rule}; metrics_kwargs = (;), 
                     syntaxstring_kwargs = (;), pretty_table_kwargs...)
    # Implementation remains the same as original
    mets = readmetrics.(ms; metrics_kwargs...)
    colnames = unique(Iterators.flatten(keys.(mets)))
    
    data = hcat(
        syntaxstring.(antecedent.(ms); syntaxstring_kwargs...),
        strip.(displaymodel.(consequent.(ms); show_symbols = false)),
        [[get(met, colname, "") for met in mets] for colname in colnames]...
    )
    
    header = ["Antecedent", "Consequent", colnames...]
    pretty_table(
        data;
        header = header,
        header_crayon = crayon"yellow bold",
        pretty_table_kwargs...
    )
end

# Export implementations
export metricstable, default_additional_metrics