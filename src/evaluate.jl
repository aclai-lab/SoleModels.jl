using StatsBase
using SoleModels
using SoleModels: LeafModel
import SoleLogics: natoms

####################### Util Functions #####################

function accuracy(
    y_true::AbstractArray,
    y_pred::AbstractArray,
)
    @assert length(y_true) == length(y_pred) "Ground truth and predicted labels should have the same length, but $(length(y_true)) ≠ $(length(y_pred))."
    # @assert length(y_pred) > 0 "Cannot compute metric with empty label vectors."

    return (length(y_pred) == 0) ? NaN : sum(y_pred .== y_true)/length(y_pred)
end

function _error(
    y_true::AbstractArray,
    y_pred::AbstractArray,
)

    return 1.0 - accuracy(y_true, y_pred)
end

function mae(
    y_true::AbstractArray,
    y_pred::AbstractArray,
)
    @assert length(y_true) == length(y_pred) "Ground truth and predicted labels should have the same length, but $(length(y_true)) ≠ $(length(y_pred))."
    # @assert length(y_pred) > 0 "Cannot compute metric with empty label vectors."

    # return sum(abs.(y_pred.-y_true)) / length(y_pred)
    return (length(y_pred) == 0) ? NaN : StatsBase.mean(abs, y_true - y_pred)
end

function mse(
    y_true::AbstractArray,
    y_pred::AbstractArray,
)
    @assert length(y_true) == length(y_pred) "Ground truth and predicted labels should have the same length, but $(length(y_true)) ≠ $(length(y_pred))."
    # @assert length(y_pred) > 0 "Cannot compute metric with empty label vectors."

    # return sum((y_pred.-y_true).^2) / length(y_pred)
    return (length(y_pred) == 0) ? NaN : StatsBase.mean(abs2, y_true - y_pred)
end

#############################################################
using StatsBase
using FillArrays

function _metround(val, round_digits)
    # return isnothing(round_digits) ? val : round(val; digits = round_digits) == 0 ? val : round(val; digits = round_digits)
    return isnothing(round_digits) ? val : round(val; digits = round_digits)
end

"""
    readmetrics(m::AbstractModel; round_digits = nothing)

Return a `NamedTuple` with some performance metrics for the given symbolic model.
Performance metrics can be computed when the `info` structure of the model has the
following keys:
- `:supporting_labels`
- `:supporting_predictions`

The `round_digits` keyword argument, if provided, is used to `round` accuracy/confidence metrics.
"""
function readmetrics(m::LeafModel{L}; class_share_map = nothing, round_digits = nothing, additional_metrics = (;),) where {L<:Label}
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
                                lift       = _metround(lift, round_digits),
                            ))
                        else # if length(class_share_map) == 0
                            cmet = merge(cmet, (;
                                lift       = NaN,
                            ))
                        # else
                        #     @warn "Lift cannot be computed with class $class and class_share_map $class_share_map."
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
    end, (; coverage = 1.0)) # Note: assuming all leaf models are complete (see `iscomplete`).
end

function readmetrics(m::Rule; kwargs...)
    error("Cannot read metrics on rule of outcometype $(outcometype(m)). Is this a classification, regression rule, or what? See SoleModels.Label.")
end

default_additional_metrics = (; natoms = r->natoms(antecedent(r)))
function readmetrics(m::Rule{L}; round_digits = nothing, class_share_map = nothing, additional_metrics = (;), kwargs...) where {L<:Label}
    additional_metrics = merge(default_additional_metrics, additional_metrics)
    additional_metrics = map(metname->(metname => additional_metrics[metname](m)), keys(additional_metrics)) |> NamedTuple

    if haskey(info(m), :supporting_labels) && haskey(info(consequent(m)), :supporting_labels)
        _gts = info(m).supporting_labels
        _gts_leaf = info(consequent(m)).supporting_labels
        if L <: CLabel && isnothing(class_share_map)
            class_share_map = Dict(map(((k,v),)->k => v./length(_gts), collect(StatsBase.countmap(_gts))))
        end
        cons_metrics = readmetrics(consequent(m); round_digits = round_digits, class_share_map = class_share_map, kwargs...)
        coverage = cons_metrics.coverage * (length(_gts_leaf)/length(_gts))
        confidence = cons_metrics.confidence
        metrics = (;
            ninstances  = length(_gts),
            ncovered = length(_gts_leaf),
            coverage = _metround(coverage, round_digits),
            confidence = confidence,
        )
        if haskey(cons_metrics, :lift)
            metrics = merge(metrics, (; lift = cons_metrics.lift,))
        end
        metrics = (;
            metrics...,
            additional_metrics...
        )
        metrics
    elseif haskey(info(m), :supporting_labels)
        return (; ninstances = length(info(m).supporting_labels), additional_metrics...)
    # elseif haskey(info(consequent(m)), :supporting_labels)
    #     return (; ninstances = length(info(consequent(m)).supporting_labels), additional_metrics...)
    else
        return (;)
    end
end

using PrettyTables

# TODO document
function metricstable(ms::Vector{<:Rule}; metrics_kwargs = (;), syntaxstring_kwargs = (;), variable_names_map = nothing, pretty_table_kwargs...)
    mets = readmetrics.(ms; metrics_kwargs...)
    colnames = unique(Iterators.flatten(keys.(mets)))

    # data = hcat(AnsiTextCell.(...
    data = hcat((syntaxstring.(antecedent.(ms); variable_names_map = variable_names_map, syntaxstring_kwargs...)), strip.(displaymodel.(consequent.(ms); show_symbols = false)), [[get(met, colname, "") for met in mets] for colname in colnames]...)
    header = ["Antecedent", "Consequent", colnames...]
    pretty_table(
        data;
        # formatters    = ft_printf("%5.2f", 2:4),
        header        = header,
        header_crayon = crayon"yellow bold",
        # highlighters  = (hl_10, hl_p, hl_v),
        # tf            = tf_unicode_rounded
        pretty_table_kwargs...
    )
end

metricstable(
    m::AbstractModel;
    normalize = false,
    min_lift = nothing,
    min_confidence = nothing,
    min_ncovered = nothing,
    min_ninstances = nothing, # TODO fix this function and reroute the right params to listrules
    kwargs...) = metricstable(listrules(m; normalize = normalize, min_lift = min_lift, min_confidence = min_confidence, min_ncovered = min_ncovered, min_ninstances = min_ninstances); kwargs...)



"""
    rulemetrics(
        r::Rule,
        X::AbstractInterpretationSet,
        Y::AbstractVector{<:Label}
    )

Compute metrics for a rule with respect to a labeled dataset and returns a `NamedTuple` consisting of:
- `coverage`: number of instances satisfying the antecedent of the rule divided by
    the total number of instances;
- `error`:
    - For classification problems: number of instances that were not classified
    correctly divided by the total number of instances;
    - For regression problems: mean squared error;
- `length`: number of atoms in the rule's antecedent.

See also
[`Rule`](@ref),
[`SoleLogics.AbstractInterpretationSet`](@ref),
[`Label`](@ref),
[`evaluaterule`](@ref),
[`outcometype`](@ref),
[`consequent`](@ref).
"""
function rulemetrics(
    rule::Rule,
    X::AbstractInterpretationSet,
    Y::AbstractVector{<:Label};
    kwargs...,
)
    ys = apply(rule,X)
    checkmask = checkantecedent(rule, X; kwargs...)
    n_instances = ninstances(X)
    n_satisfy = sum(checkmask)

    rule_coverage =  n_satisfy / n_instances

    rule_error = begin
        if outcometype(consequent(rule)) <: CLabel
            # Number of incorrectly classified instances divided by number of instances
            # satisfying the rule condition.
            _error(ys[checkmask],Y[checkmask])
        elseif outcometype(consequent(rule)) <: RLabel
            # Mean Squared Error (mse)
            mse(ys[checkmask],Y[checkmask])
        else
            error("The outcome type of the consequent of the input rule $(outcometype(consequent(rule))) is not among those accepted")
        end
    end

    return (;
        checkmask    = checkmask,
        coverage   = rule_coverage,
        error     = rule_error,
        natoms    = natoms(antecedent(rule)),
    )
end


"""
    evaluaterule(
        r::Rule{O},
        X::AbstractInterpretationSet,
        Y::AbstractVector{L}
    ) where {O,L<:Label}

Evaluate the rule on a labeled dataset, and return a `NamedTuple` consisting of:
- `checkmask::Vector{Bool}`: satsfaction of the antecedent for each instance in the dataset;
- `ys::Vector{Union{Nothing,O}}`: rule prediction. For each instance in X:
    - `consequent(rule)` if the antecedent is satisfied,
    - `nothing` otherwise.

See also
[`Rule`](@ref),
[`SoleLogics.AbstractInterpretationSet`](@ref),
[`Label`](@ref),
[`checkantecedent`](@ref).
"""
function evaluaterule(
    rule::Rule,
    X::AbstractInterpretationSet,
    Y::AbstractVector{<:Label};
    kwargs...,
)
    #println("Evaluation rule in time...")
    # ys = apply(rule,X)
    #if SoleData.hassupports(X)
    #    println("# Memoized Values: $(nmemoizedvalues(X))")
    #end

    checkmask = checkantecedent(rule, X)

    cons_sat = begin
        idxs_sat = findall(checkmask .== true)
        cons_sat = Vector{Union{Bool,Nothing}}(fill(nothing, length(Y)))

        idxs_true = begin
            idx_cons = findall(outcome(consequent(rule)) .== Y)
            intersect(idxs_sat, idx_cons)
        end
        idxs_false = begin
            idx_cons = findall(outcome(consequent(rule)) .!= Y)
            intersect(idxs_sat, idx_cons)
        end
        cons_sat[idxs_true]  .= true
        cons_sat[idxs_false] .= false
        cons_sat
    end

    # - `cons_sat::Vector{Union{Nothing,Bool}}`: for each instance in the dataset:
    #     - `nothing` if antecedent is not satisfied.
    #     - `false` if the antecedent is satisfied, but the consequent does not match the ground-truth label,
    #     - `true` if the antecedent is satisfied, and the consequent matches the ground-truth label,

    return (;
        # ys = apply(rule,X),
        checkmask     = checkmask,
        # cons_sat    = cons_sat,
    )
end

"""
TODO
"""
function evaluaterule(
    rule::Rule{L},
    X::AbstractInterpretationSet,
    Y::AbstractVector{<:Label};
    compute_explanations = false,
    kwargs...,
) where {L<:CLabel}
    classmask = (Y .== outcome(consequent(rule)))
    checkmask, explanations = begin
        if compute_explanations
            # Note: This is kind of quick and dirty.
            disjs = SoleLogics.disjuncts(SoleLogics.LeftmostDisjunctiveForm(antecedent(rule)))
            checkmatrix = hcat([check(disj, X; kwargs...) for disj in disjs]...)
            # @show checkmatrix
            checkmask = map(any, eachrow(checkmatrix))
            explanations = [disjs[checkrow] for checkrow in eachrow(checkmatrix)]
            checkmask, explanations
        else
            checkmask = checkantecedent(rule, X; kwargs...)
            explanations = nothing
            checkmask, explanations
        end
    end
    pos_checkmask = checkmask[classmask]
    neg_checkmask = checkmask[(!).(classmask)]
    out = (;
        classmask = classmask,
        checkmask = checkmask,
        sensitivity = sum(pos_checkmask)/length(pos_checkmask),
        specificity = 1-(sum(neg_checkmask)/length(neg_checkmask)),
        explanations = explanations,
    )
    return out
end

# TODO: if delays not in info(m) ?
function _meandelaydl(m::DecisionList)
    i = info(m)

    if :delays in keys(i)
        return mean(i[:delays])
    end
end

############################################################################################
############################################################################################
############################################################################################
