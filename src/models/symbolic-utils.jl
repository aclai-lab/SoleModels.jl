
############################################################################################
# Symbolic modeling utils
############################################################################################

"""
    immediate_submodels(m::AbstractModel)

Returns a list of immediate child models.
Note: if the model is final, then the list is empty.

See also
[`submodels`](@ref),
[`FinalModel`](@ref),
[`AbstractModel`](@ref).
"""
function immediate_submodels(
    m::AbstractModel{O}
)::Vector{<:{AbstractModel{<:O}}} where {O}
    error("Please, provide method immediate_submodels(::$(typeof(m))).")
end

immediate_submodels(m::FinalModel{O}) where {O} = Vector{<:AbstractModel{<:O}}[]
immediate_submodels(m::Rule) = [consequent(m)]
immediate_submodels(m::Branch) = [posconsequent(m), negconsequent(m)]
immediate_submodels(m::DecisionList) = [rulebase(m)..., defaultconsequent(m)]
immediate_submodels(m::RuleCascade) = [consequent(m)]
immediate_submodels(m::DecisionTree) = immediate_submodels(root(m))
immediate_submodels(m::MixedSymbolicModel) = immediate_submodels(root(m))

"""
    submodels(m::AbstractModel)

This function provides access to the list of all child models in the sub-tree.

See also
[`immediate_submodels`](@ref),
[`FinalModel`](@ref),
[`AbstractModel`](@ref).
"""
submodels(m::AbstractModel) = [Iterators.flatten(_submodels.(immediate_submodels(m)))...]
_submodels(m::AbstractModel) = [m, Iterators.flatten(_submodels.(immediate_submodels(m)))...]


############################################################################################
############################################################################################
############################################################################################

# When `assumed_formula` is assumed, and `f` is known to be true, their conjuction holds.
advance_formula(f::AbstractFormula, assumed_formula::Union{Nothing,AbstractFormula}) =
    isnothing(assumed_formula) ? f : ∧(assumed_formula, f)

advance_formula(r::R where {R<:Rule}, assumed_formula::Union{Nothing,AbstractFormula}) =
    R(advance_formula(antecedent(r), assumed_formula), consequent(r), info(r))

############################################################################################
############################################################################################
############################################################################################

"""
    immediate_rules(m::AbstractModel{O} where {O})::Rule{<:O}

Returns the immediate rules equivalent to a model. TODO explain

See also [`unroll_rules`](@ref), [`unroll_rules_cascade`](@ref), [`issymbolic`](@ref),
[`AbstractModel`](@ref).
"""
immediate_rules(m::AbstractModel{O} where {O})::Rule{<:O} =
    error(begin
        if issymbolic(m)
            "Please, provide method immediate_rules(::$(typeof(m))) ($(typeof(m)) is a symbolic model)."
        else
            "Models of type $(typeof(m)) are not symbolic, and thus have no rules associated."
        end
    end)

immediate_rules(m::FinalModel) = [Rule(⊤, m)]

immediate_rules(m::Rule) = [m]

immediate_rules(m::Branch{O,FM}) where {O,FM} = [
    Rule{O,FM}(antecedent(m), posconsequent(m)),
    Rule{O,FM}(SoleLogics.NEGATION(antecedent(m)), negconsequent(m)),
]

function immediate_rules(m::DecisionList{O,FM}) where {O,FM}
    assumed_formula = nothing
    normalized_rules = Vector{eltype(rulebase(m))}[]
    for rule in rulebase(m)
        rule = advance_formula(rule, assumed_formula)
        assumed_formula = advance_formula(SoleLogics.NEGATION(antecedent(rule)), assumed_formula)
    end
    default_antecedent = isnothing(assumed_formula) ? ⊤ : assumed_formula
    push!(normalized_rules, Rule{O,FM}(default_antecedent, defaultconsequent(m)))
    normalized_rules
end

immediate_rules(m::RuleCascade) = [convert(Rule, m)]

immediate_rules(m::DecisionTree) = immediate_rules(root(m))

immediate_rules(m::MixedSymbolicModel) = immediate_rules(root(m))

############################################################################################
############################################################################################
############################################################################################

"""
    unroll_rules(m::AbstractModel)

This function extracts the behavior of a symbolic model and represents it as a
set of mutually exclusive (and jointly exaustive, if the model is closed) rules,
which can be useful for many purposes.

    # Examples
```julia-repl
julia> unroll_rules(outcome_int) isa Vector{<:ConstantModel}
true

julia> unroll_rules(rule)
1-element Vector{Rule{String, LogicalTruthCondition{SyntaxTree{Union{SoleLogics.NamedOperator{:¬}, Proposition{String}}, SoleLogics.NamedOperator{:¬}}}, ConstantModel{String}}}:
 Rule{String, LogicalTruthCondition{SyntaxTree{Union{SoleLogics.NamedOperator{:¬}, Proposition{String}}, SoleLogics.NamedOperator{:¬}}}, ConstantModel{String}}
┐¬(r)
└ ✔ YES

julia> unroll_rules(decision_list)
3-element Vector{Rule{String, C, ConstantModel{String}} where C<:SoleModels.AbstractBooleanCondition}:
 Rule{String, LogicalTruthCondition{SyntaxTree{Union{SoleLogics.NamedOperator{:∧}, Proposition{String}}, SoleLogics.NamedOperator{:∧}}}, ConstantModel{String}}
┐(r ∧ s) ∧ t
└ ✔ YES

 Rule{String, LogicalTruthCondition{SyntaxTree{Union{SoleLogics.NamedOperator{:¬}, Proposition{String}}, SoleLogics.NamedOperator{:¬}}}, ConstantModel{String}}
┐¬(r)
└ ✔ YES

 Rule{String, LogicalTruthCondition{SyntaxTree{SoleLogics.TopOperator, SoleLogics.TopOperator}}, ConstantModel{String}}
┐⊤
└ ✔ YES

julia> unroll_rules(rcmodel)
1-element Vector{Rule{Int64, LogicalTruthCondition{Formula{BaseLogic{SoleLogics.CompleteFlatGrammar{AlphabetOfAny{String}, Union{SoleLogics.NamedOperator{:∨}, SoleLogics.NamedOperator{:∧}}}, SoleLogics.BooleanAlgebra}}}, ConstantModel{Int64}}}:
 Rule{Int64, LogicalTruthCondition{Formula{BaseLogic{SoleLogics.CompleteFlatGrammar{AlphabetOfAny{String}, Union{SoleLogics.NamedOperator{:∨}, SoleLogics.NamedOperator{:∧}}}, SoleLogics.BooleanAlgebra}}}, ConstantModel{Int64}}
┐(p ∧ (q ∨ r)) ∧ ((p ∧ (q ∨ r)) ∧ (p ∧ (q ∨ r)))
└ ✔ 1

julia> unroll_rules(branch)
3-element Vector{Rule{String, C, ConstantModel{String}} where C<:SoleModels.AbstractBooleanCondition}:
 Rule{String, LogicalTruthCondition{SyntaxTree{Union{SoleLogics.NamedOperator{:∧}, Proposition{String}}, SoleLogics.NamedOperator{:∧}}}, ConstantModel{String}}
┐t ∧ q
└ ✔ YES

 Rule{String, LogicalTruthCondition{SyntaxTree{Union{SoleLogics.NamedOperator{:∧}, SoleLogics.NamedOperator{:¬}, Proposition{String}}, SoleLogics.NamedOperator{:∧}}}, ConstantModel{String}}
┐t ∧ (¬(q))
└ ✔ NO

 Rule{String, LogicalTruthCondition{SyntaxTree{Union{SoleLogics.NamedOperator{:¬}, Proposition{String}}, SoleLogics.NamedOperator{:¬}}}, ConstantModel{String}}
┐¬(t)
└ ✔ YES

julia> unroll_rules(decision_tree)
5-element Vector{Rule{String, C, ConstantModel{String}} where C<:SoleModels.AbstractBooleanCondition}:
 Rule{String, LogicalTruthCondition{SyntaxTree{Union{SoleLogics.NamedOperator{:∧}, Proposition{String}}, SoleLogics.NamedOperator{:∧}}}, ConstantModel{String}}
┐r ∧ s
└ ✔ YES

 Rule{String, LogicalTruthCondition{SyntaxTree{Union{SoleLogics.NamedOperator{:∧}, SoleLogics.NamedOperator{:¬}, Proposition{String}}, SoleLogics.NamedOperator{:∧}}}, ConstantModel{String}}
┐r ∧ (¬(s))
└ ✔ NO

 Rule{String, LogicalTruthCondition{SyntaxTree{Union{SoleLogics.NamedOperator{:∧}, SoleLogics.NamedOperator{:¬}, Proposition{String}}, SoleLogics.NamedOperator{:∧}}}, ConstantModel{String}}
┐(¬(r)) ∧ (t ∧ q)
└ ✔ YES

 Rule{String, LogicalTruthCondition{SyntaxTree{Union{SoleLogics.NamedOperator{:∧}, SoleLogics.NamedOperator{:¬}, Proposition{String}}, SoleLogics.NamedOperator{:∧}}}, ConstantModel{String}}
┐(¬(r)) ∧ (t ∧ (¬(q)))
└ ✔ NO

 Rule{String, LogicalTruthCondition{SyntaxTree{Union{SoleLogics.NamedOperator{:∧}, SoleLogics.NamedOperator{:¬}, Proposition{String}}, SoleLogics.NamedOperator{:∧}}}, ConstantModel{String}}
┐(¬(r)) ∧ (¬(t))
└ ✔ YES

julia> unroll_rules(mixed_symbolic_model)
2-element Vector{Rule}:
 Rule{Int64, LogicalTruthCondition{SyntaxTree{Proposition{String}, Proposition{String}}}, ConstantModel{Int64}}
┐q
└ ✔ 2

 Rule{Float64, LogicalTruthCondition{SyntaxTree{Union{SoleLogics.NamedOperator{:¬}, Proposition{String}}, SoleLogics.NamedOperator{:¬}}}, ConstantModel{Float64}}
┐¬(q)
└ ✔ 1.5

```

See also [`immediate_rules`](@ref), [`unroll_rules_cascade`](@ref),
[`issymbolic`](@ref), [`FinalModel`](@ref), [`AbstractModel`](@ref).
"""
function unroll_rules(m::AbstractModel)
    try
        ms = unroll_rules_cascade(m)
        return map(m->begin
            if m isa RuleCascade && conditiontype(m) <: Union{TrueCondition,LogicalTruthCondition}
                convert(Rule, m)
            elseif m isa FinalModel
                m
            else
                error("Unknown model type encountered in unroll_rules: $(typeof(m))")
            end
        end, ms)
    catch err
        if err isa ErrorException
            error(begin
                if issymbolic(m)
                    "Please, provide method unroll_rules(::$(typeof(m))) ($(typeof(m)) is a symbolic model)."
                else
                    "Models of type $(typeof(m)) are not symbolic, and thus have no rules associated."
                end
            end)
        end
    end
end

############################################################################################
############################################################################################
############################################################################################

"""
    unroll_rules_cascade(m::AbstractModel)

This function extracts the behavior of a symbolic model and represents it as a
set of mutually exclusive (and jointly exaustive, if the model is closed) rules cascade
vectors, which can be useful for many purposes.

# Examples
```julia-repl
julia> unroll_rules_cascade(outcome_int) isa Vector{<:ConstantModel}
true

julia> unroll_rules_cascade(rule)
1-element Vector{RuleCascade{String, LogicalTruthCondition{SyntaxTree{Union{SoleLogics.NamedOperator{:∧}, Proposition{String}}, SoleLogics.NamedOperator{:∧}}}, ConstantModel{String}}}:
 RuleCascade{String, LogicalTruthCondition{SyntaxTree{Union{SoleLogics.NamedOperator{:∧}, Proposition{String}}, SoleLogics.NamedOperator{:∧}}}, ConstantModel{String}}
┐⩚((r ∧ s) ∧ t)
└ ✔ YES

julia> unroll_rules_cascade(rule_cascade)
1-element Vector{RuleCascade{String, LogicalTruthCondition{SyntaxTree{Proposition{String}, Proposition{String}}}, ConstantModel{String}}}:
 RuleCascade{String, LogicalTruthCondition{SyntaxTree{Proposition{String}, Proposition{String}}}, ConstantModel{String}}
┐⩚(r, s, t)
└ ✔ YES

julia> unroll_rules_cascade(branch)
2-element Vector{RuleCascade{String, C, ConstantModel{String}} where C<:SoleModels.AbstractBooleanCondition}:
 RuleCascade{String, LogicalTruthCondition{SyntaxTree{Proposition{String}, Proposition{String}}}, ConstantModel{String}}
┐⩚(s)
└ ✔ YES

 RuleCascade{String, LogicalTruthCondition{SyntaxTree{Union{SoleLogics.NamedOperator{:¬}, Proposition{String}}, SoleLogics.NamedOperator{:¬}}}, ConstantModel{String}}
┐⩚(¬(s))
└ ✔ NO

julia> unroll_rules_cascade(decision_list)
3-element Vector{RuleCascade{String, C, ConstantModel{String}} where C<:SoleModels.AbstractBooleanCondition}:
 RuleCascade{String, LogicalTruthCondition{SyntaxTree{Union{SoleLogics.NamedOperator{:∧}, Proposition{String}}, SoleLogics.NamedOperator{:∧}}}, ConstantModel{String}}
┐⩚((r ∧ s) ∧ t)
└ ✔ YES

 RuleCascade{String, LogicalTruthCondition{SyntaxTree{Union{SoleLogics.NamedOperator{:¬}, Proposition{String}}, SoleLogics.NamedOperator{:¬}}}, ConstantModel{String}}
┐⩚(¬(r))
└ ✔ YES

 RuleCascade{String, TrueCondition, ConstantModel{String}}
┐⩚(⊤)
└ ✔ YES

julia> unroll_rules_cascade(decision_tree)
3-element Vector{RuleCascade{String, C, ConstantModel{String}} where C<:SoleModels.AbstractBooleanCondition}:
 RuleCascade{String, LogicalTruthCondition{SyntaxTree{Proposition{String}, Proposition{String}}}, ConstantModel{String}}
┐⩚(t, q)
└ ✔ YES

 RuleCascade{String, LogicalTruthCondition, ConstantModel{String}}
┐⩚(t, ¬(q))
└ ✔ NO

 RuleCascade{String, LogicalTruthCondition{SyntaxTree{Union{SoleLogics.NamedOperator{:¬}, Proposition{String}}, SoleLogics.NamedOperator{:¬}}}, ConstantModel{String}}
┐⩚(¬(t))
└ ✔ YES

julia> unroll_rules_cascade(mixed_symbolic_model)
2-element Vector{RuleCascade}:
 RuleCascade{Int64, LogicalTruthCondition{SyntaxTree{Proposition{String}, Proposition{String}}}, ConstantModel{Int64}}
┐⩚(q)
└ ✔ 2

 RuleCascade{Float64, LogicalTruthCondition{SyntaxTree{Union{SoleLogics.NamedOperator{:¬}, Proposition{String}}, SoleLogics.NamedOperator{:¬}}}, ConstantModel{Float64}}
┐⩚(¬(q))
└ ✔ 1.5
```


See also [`immediate_rules`](@ref), [`issymbolic`](@ref), [`AbstractModel`](@ref),
[`unroll_rules`](@ref).
"""
function unroll_rules_cascade(m::AbstractModel)
    error(begin
        if issymbolic(m)
            "Please, provide method unroll_rules_cascade(::$(typeof(m))) ($(typeof(m)) is a symbolic model)."
        else
            "Models of type $(typeof(m)) are not symbolic, and thus have no rules associated."
        end
    end)
end

unroll_rules_cascade(m::FinalModel) = [m]

function unroll_rules_cascade(m::Rule{O,<:TrueCondition}) where {O}
    rules = begin
        submodels = unroll_rules_cascade(consequent(m))

        if submodels isa Vector{<:FinalModel}
            [RuleCascade(fm) for fm in submodels]
        else
            [RuleCascade(antecedents(rule), consequent(rule)) for rule in submodels]
        end
    end

    return [rules...]
end

function unroll_rules_cascade(m::Rule{O,<:LogicalTruthCondition}) where {O}
    rules = begin
        submodels = unroll_rules_cascade(consequent(m))
        ant = antecedent(m)

        if submodels isa Vector{<:FinalModel}
            [RuleCascade([ant], fm) for fm in submodels]
        else
            [RuleCascade([ant,antecedents(rule)...], consequent(rule)) for rule in submodels]
        end
    end

    return [rules...]
end

function unroll_rules_cascade(m::Branch{O,<:TrueCondition}) where {O}
    pos_rules = begin
        submodels = unroll_rules_cascade(posconsequent(m))
        if submodels isa Vector{<:FinalModel}
            [RuleCascade(fm) for fm in r]
        else
            [RuleCascade(antecedents(rule), consequent(rule)) for rule in submodels]
        end
    end

    neg_rules = begin
        submodels = unroll_rules_cascade(negconsequent(m))

        if submodels isa Vector{<:FinalModel}
            [RuleCascade(fm) for fm in submodels]
        else
            [RuleCascade(antecedents(rule), consequent(rule)) for rule in submodels]
        end
    end

    return [
        pos_rules...,
        neg_rules...,
    ]
end

function unroll_rules_cascade(m::Branch{O,<:LogicalTruthCondition}) where {O}
    pos_rules = begin
        submodels = unroll_rules_cascade(posconsequent(m))
        ant = antecedent(m)

        if submodels isa Vector{<:FinalModel}
            [RuleCascade([ant], fm) for fm in submodels]
        else
            [RuleCascade([ant,antecedents(rule)...], consequent(rule)) for rule in submodels]
        end
    end

    neg_rules = begin
        submodels = unroll_rules_cascade(negconsequent(m))
        ant = LogicalTruthCondition(¬(formula(antecedent(m))))

        if submodels isa Vector{<:FinalModel}
            [RuleCascade([ant], fm) for fm in submodels]
        else
            [RuleCascade([ant,antecedents(rule)...], consequent(rule)) for rule in submodels]
        end
    end

    return [
        pos_rules...,
        neg_rules...,
    ]
end

function unroll_rules_cascade(
    m::DecisionList{O,<:Union{TrueCondition,LogicalTruthCondition}}
) where {O}
    [
        reduce(vcat,[unroll_rules_cascade(rule) for rule in rulebase(m)])...,
        RuleCascade(unroll_rules_cascade(defaultconsequent(m))...),
    ]
end

unroll_rules_cascade(m::RuleCascade) = [m]

unroll_rules_cascade(m::DecisionTree) = unroll_rules_cascade(root(m))

unroll_rules_cascade(m::MixedSymbolicModel) = unroll_rules_cascade(root(m))

############################################################################################
############################################################################################
############################################################################################
