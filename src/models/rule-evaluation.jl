using SoleModels
using SoleModels: FinalModel
using SoleLogics: npropositions

"""
    evaluate_rule(rule::Rule,X::AbstractInterpretationSet,Y::AbstractVector{<:Label})

Let X dataset and Y vector of labels, evaluate_rule evaluates the input rule and
returns a NamedTuple consisting of:
 - `:ant_sat`: antecedent satisfaction. For each instance in X:
     - `false` when not satisfied
     - `true` when satisfied.
 - :idxs_sat
    Indices of satisfiable instances TODO: true e false
 - `:cons_sat`: consequent satisfaction. For each instance in X:
     - `false` when not satisfied,
     - `true` when satisfied,
     - `nothing` when antecedent does not hold.
 - `:rule_output`: consequent prediction. For each instance in X:
     - `consequent of input rule` when satisfied,
     - `nothing` when not satisfied.

# Examples
```julia-repl
julia> evaluate_rule(rule,X,Y)
TODO
```

See also
[`Rule`](@ref),
[`AbstractInterpretationSet`](@ref),
[`Label`](@ref),
[`check_antecedent`](@ref).
"""
function evaluate_rule(
    rule::Rule{O, C, FM},
    X::AbstractInterpretationSet,
    Y::AbstractVector{<:Label}
) where {O,C,FM<:AbstractModel}
    rule_output = apply(rule,X)

    ant_sat = rule_output .!= nothing

    cons_sat = begin
        idxs_sat = findall(ant_sat .== true)
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

    return (;
        rule_output = rule_output,
        ant_sat     = ant_sat,
        cons_sat    = cons_sat,
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
    npropositions(antecedent(rule))
end

"""
    rule_metrics(rule::Rule,X::AbstractInterpretationSet,Y::AbstractVector{<:Label})

Calculates metrics of the rule and returns a NamedTuple consisting of:
 - `:support`: number of instances satisfying the antecedent of the rule relative to the number of total instances
 - `:error`:
    - `Classification Problems:` number of instances that were not classified correctly compared to the number of total instances
    - `Regression Problems:` mean squared error
 - `:length`: number of conjuncts of the input rule

# Examples
```julia-repl
julia> rule_metrics(rule,X,Y)
TODO
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
    rule::Rule{O, C, FM},
    X::AbstractInterpretationSet,
    Y::AbstractVector{<:Label}
) where {O,C,FM<:AbstractModel}
    eval_result = evaluate_rule(rule, X, Y)
    rule_output = eval_result[:rule_output]
    ant_sat = eval_result[:ant_sat]
    n_instances = nsamples(X)
    n_satisfy = sum(ant_sat)

    rule_support =  n_satisfy / n_instances

    rule_error = begin
        if outcometype(consequent(rule)) <: CLabel
            # Number of incorrectly classified instances divided by number of instances
            # satisfying the rule condition.
            # TODO: failure
            misclassified_instances = length(findall(rule_output .!= Y))
            misclassified_instances / n_satisfy
        elseif outcometype(consequent(rule)) <: RLabel
            # Mean Squared Error (mse)
            mse(rule_output[ant_sat], Y[ant_sat])
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
