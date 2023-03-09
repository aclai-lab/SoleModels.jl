using SoleModels
using SoleModels: FinalModel
using SoleLogics: npropositions

"""
    evaluate_rule(rule::Rule,X::AbstractInterpretationSet,Y::AbstractVector{<:Label})

Let X dataset and Y vector of labels, evaluate_rule evaluates the input rule and
returns a NamedTuple consisting of:
 - :ant_sat
    Antecedent satisfaction. For each instances in X:
     - `false` when not satisfiable,
     - `true` when satisfiable.
 - :idxs_sat
    Indices of satisfiable instances
 - :cons_sat
    Consequent satisfaction. For each instances in X:
     - `false` when not satisfiable,
     - `true` when satisfiable,
     - `nothing` when antecedent does not hold.
 - :y_pred
    Consequent prediction. For each instances in X:
     - `consequent of input rule` when satisfiable,
     - `nothing` when not satisfiable.

# Examples
```julia-repl
julia> evaluate_rule(rule,X,Y)
...
```

See also
[`Rule`](@ref),
[`AbstractInterpretationSet`](@ref),
[`Label`](@ref),
[`check_antecedent`](@ref).
"""
function evaluate_rule(
    rule::Rule,
    X::AbstractInterpretationSet,
    Y::AbstractVector{<:Label}
)
    ant_sat = check_antecedent(rule,X)

    idxs_sat = findall(ant_sat .== true)

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
    rule_length(rule::Rule{O,<:TrueCondition}) where {O}
    rule_length(rule::Rule{O,C}) where {O,C<:LogicalTruthCondition}

Calculates the length of the input rule, that is counts the number of conjuncts of
the input rule

See also
[`Rule`](@ref),
[`TrueCondition`](@ref),
[`LogicalTruthCondition`](@ref),
[`antecedent`](@ref),
[`formula`](@ref),
[`n_propositions`](@ref).
"""
rule_length(rule::Rule{O,<:TrueCondition}) where {O} = 1
function rule_length(rule::Rule{O,C}) where {O,C<:LogicalTruthCondition}
    npropositions(formula(antecedent(rule)))
end

"""
    rule_metrics(rule::Rule,X::AbstractInterpretationSet,Y::AbstractVector{<:Label})

Calculates metrics of the rule and returns a NamedTuple consisting of:
 - :support
    Number of samples of the true response that lies in each class of target values
 - :error
 - :length
    Number of conjuncts of the input rule

# Examples
```julia-repl
julia> rule_metrics(rule,X,Y)
...
```

See also
[`Rule`](@ref),
[`AbstractInterpretationSet`](@ref),
[`Label`](@ref),
[`evaluate_rule`](@ref),
[`nsamples`](@ref),
[`outcometype`](@ref),
[`consequent`](@ref),
[`rule_length`](@ref).
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
        else
            error("The outcome type of the consequent of the input rule $(outcometype(consequent(rule))) is not among those accepted")
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
