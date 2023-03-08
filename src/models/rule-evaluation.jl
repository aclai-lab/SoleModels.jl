using SoleModels
using SoleModels: FinalModel
using SoleLogics: npropositions

# TODO @Michele clean this file and document

"""
Function for evaluating a rule
"""
function evaluate_rule(
    rule::Rule,
    X::AbstractInterpretationSet,
    Y::AbstractVector{<:Label}
)
    # Antecedent satisfaction. For each instances in X:
    #  - `false` when not satisfiable,
    #  - `true` when satisfiable.
    ant_sat = check_antecedent(rule,X)

    # Indices of satisfiable instances
    idxs_sat = findall(ant_sat .== true)

    # Consequent satisfaction. For each instances in X:
    #  - `false` when not satisfiable,
    #  - `true` when satisfiable,
    #  - `nothing` when antecedent does not hold.
    #=
    cons_sat = begin
        cons_sat = Vector{Union{Bool,Nothing}}(fill(nothing, length(Y)))
        idxs_true = begin
            idx_cons = findall(outcome(consequent(rule)) .== Y)
            intersect(idxs_sat,idx_cons)
        end
        idxs_false = begin
            idx_cons = findall(outcome(consequent(rule)) .!= Y)
            intersect(idxs_sat,idx_cons)
        end
        cons_sat[idxs_true]  .= true
        cons_sat[idxs_false] .= false
        cons_sat
    end
    =#

    y_pred = begin
        y_pred = Vector{Union{Label,Nothing}}(fill(nothing, length(Y)))
        y_pred[idxs_sat] .= outcome(consequent(rule))
        y_pred
    end

    return (;
        ant_sat   = ant_sat,
        idxs_sat  = idxs_sat,
        #cons_sat  = cons_sat,
        y_pred    = y_pred,
    )
end

"""
Length of the rule
"""
rule_length(rule::Rule{O,<:TrueCondition}) where {O} = 1
function rule_length(rule::Rule{O,C}) where {O,C<:LogicalTruthCondition}
    npropositions(formula(antecedent(rule)))
end

"""
Metrics of the rule
"""
function rule_metrics(
    rule::Rule,
    X::AbstractInterpretationSet,
    Y::AbstractVector{<:Label}
)
    eval_result = evaluate_rule(rule, X, Y)
    n_instances = nsamples(X)
    n_satisfy = sum(eval_result[:ant_sat])

    # Support of the rule
    rule_support =  n_satisfy / n_instances

    # Error of the rule
    rule_error = begin
        if outcometype(consequent(rule)) <: CLabel
            # Number of incorrectly classified instances divided by number of instances
            # satisfying the rule condition.
            misclassified_instances = length(findall(eval_result[:y_pred] .== Y))
            misclassified_instances / n_satisfy
        elseif outcometype(consequent(rule)) <: RLabel
            # Mean Squared Error (mse)
            idxs_sat = eval_result[:idxs_sat]
            mse(eval_result[:y_pred][idxs_sat], Y[idxs_sat])
        end
    end

    return (;
        support   = rule_support,
        error     = rule_error,
        length    = rule_length(rule),
    )
end

############################################################################################
############################################################################################
############################################################################################
