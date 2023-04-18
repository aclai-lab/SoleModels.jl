
############################################################################################
# Symbolic modeling utils
############################################################################################

"""
    immediate_submodels(m::AbstractModel)

Returns a list of immediate child models.
Note: if the model is final, then the list is empty.

# Examples
```julia-repl
julia> print(join(displaymodel.(immediate_submodels(rule); header = false)))
YES

julia> print(join(displaymodel.(immediate_submodels(rcmodel); header = false)))
1

julia> print(join(displaymodel.(immediate_submodels(branch); header = false)))
┐ q
├ ✔ YES
└ ✘ NO
YES

julia> print(join(displaymodel.(immediate_submodels(decision_list); header = false)))
┐(r ∧ s) ∧ t
└ ✔ YES
┐¬(r)
└ ✔ YES
YES

julia> print(join(displaymodel.(immediate_submodels(decision_tree); header = false)))
┐ s
├ ✔ YES
└ ✘ NO
┐ t
├ ✔ ┐ q
│   ├ ✔ YES
│   └ ✘ NO
└ ✘ YES

julia> print(join(displaymodel.(immediate_submodels(mixed_symbolic_model); header = false)))
2
1.5
```

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
immediate_submodels(m::DecisionTree) = immediate_submodels(root(m))
immediate_submodels(m::MixedSymbolicModel) = immediate_submodels(root(m))

"""
    submodels(m::AbstractModel)

This function provides access to the list of all child models in the sub-tree.

# Examples
```julia-repl
julia> print(join(displaymodel.(submodels(rule); header = false)))
YES

@test submodels(rc1_string) isa Vector{<:AbstractModel}
julia> print(join(displaymodel.(submodels(rule_cascade); header = false)))
YES

julia> print(join(displaymodel.(submodels(branch); header = false)))
┐ s
├ ✔ YES
└ ✘ NO
YES
NO
┐ t
├ ✔ ┐ q
│   ├ ✔ YES
│   └ ✘ NO
└ ✘ YES
┐ q
├ ✔ YES
└ ✘ NO
YES
NO
YES

julia> print(join(displaymodel.(submodels(decision_list); header = false)))
┐(r ∧ s) ∧ t
└ ✔ YES
YES
┐¬(r)
└ ✔ YES
YES
YES

julia> print(join(displaymodel.(submodels(decision_tree); header = false)))
┐ q
├ ✔ YES
└ ✘ NO
YES
NO
YES

julia> print(join(displaymodel.(submodels(mixed_symbolic_model); header = false)))
2
1.5
```

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

See also [`unroll_rules`](@ref), [`issymbolic`](@ref), [`AbstractModel`](@ref).
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

immediate_rules(m::DecisionTree) = immediate_rules(root(m))

immediate_rules(m::MixedSymbolicModel) = immediate_rules(root(m))

############################################################################################
############################################################################################
############################################################################################

"""
    unroll_rules(m::AbstractModel; tree::Bool=false)

This function extracts the behavior of a symbolic model and represents it as a
set of mutually exclusive (and jointly exaustive, if the model is closed) rules,
which can be useful for many purposes.

`tree` is a kwarg which when set to true then returns a vector of rules where the
antecedent is constructed as SyntaxTree

# Examples
```julia-repl
@test unroll_rules(r2_string) isa Vector{<:Rule}
julia> print(join(displaymodel.(unroll_rules(rule); header = false)))
┐¬(r)
└ ✔ YES

julia> print(join(displaymodel.(unroll_rules(decision_list); header = false)))
┐(r ∧ s) ∧ t
└ ✔ YES
┐¬(r)
└ ✔ YES
┐⊤
└ ✔ YES

@test unroll_rules(rcmodel) isa Vector{<:Rule}
julia> print(join(displaymodel.(unroll_rules(rule_cascade); header = false)))
┐(p ∧ (q ∨ r)) ∧ ((p ∧ (q ∨ r)) ∧ (p ∧ (q ∨ r)))
└ ✔ 1

julia> print(join(displaymodel.(unroll_rules(branch); header = false)))
┐r ∧ s
└ ✔ YES
┐r ∧ (¬(s))
└ ✔ NO
┐(¬(r)) ∧ (t ∧ q)
└ ✔ YES
┐(¬(r)) ∧ (t ∧ (¬(q)))
└ ✔ NO
┐(¬(r)) ∧ (¬(t))
└ ✔ YES

julia> print(join(displaymodel.(unroll_rules(decision_tree); header = false)))
┐r ∧ s
└ ✔ YES
┐r ∧ (¬(s))
└ ✔ NO
┐(¬(r)) ∧ (t ∧ q)
└ ✔ YES
┐(¬(r)) ∧ (t ∧ (¬(q)))
└ ✔ NO
┐(¬(r)) ∧ (¬(t))
└ ✔ YES

julia> print(join(displaymodel.(unroll_rules(mixed_symbolic_model); header = false)))
┐q
└ ✔ 2
┐¬(q)
└ ✔ 1.5
```

See also [`immediate_rules`](@ref), [`issymbolic`](@ref), [`FinalModel`](@ref),
[`AbstractModel`](@ref).
"""
function unroll_rules(m::AbstractModel; kwargs...)
    error(begin
        if issymbolic(m)
            "Please, provide method unroll_rules(::$(typeof(m))) ($(typeof(m)) is a symbolic model)."
        else
            "Models of type $(typeof(m)) are not symbolic, and thus have no rules associated."
        end
    end)
end

unroll_rules(m::FinalModel; kwargs...) = [m]

unroll_rules(m::Rule; tree::Bool=false) = [ begin
   !tree ? m : Rule(
        LogicalTruthCondition(tree(formula(antecedent(m)))),
        consequent(m),
        info(m)
    )
end ]

function unroll_rules(m::Branch{O,<:TrueCondition}; kwargs...) where {O}
    pos_rules = begin
        submodels = unroll_rules(posconsequent(m); kwargs...)
        submodels isa Vector{<:FinalModel} ? [Rule(fm) for fm in submodels] : submodels
    end

    neg_rules = begin
        submodels = unroll_rules(negconsequent(m); kwargs...)
        submodels isa Vector{<:FinalModel} ? [Rule(fm) for fm in submodels] : submodels
    end

    return [
        pos_rules...,
        neg_rules...,
    ]
end

function unroll_rules(m::Branch{O,<:LogicalTruthCondition}; tree::Bool=false) where {O}
    pos_rules = begin
        submodels = unroll_rules(posconsequent(m); tree=tree)
        ant = tree(formula(antecedent(m)))

        map(subm-> begin
            if subm isa FinalModel
                Rule(LogicalTruthCondition(ant), subm)
            else
                f = formula(antecedent(subm))
                subants = f isa LeftmostLinearForm ? children(f) : [f]
                Rule(
                    LogicalTruthCondition( begin
                        lf = LeftmostConjunctiveForm([ant, subants...])
                        tree ? tree(lf) : lf
                    end ),
                    consequent(subm)
                )
            end
        end, submodels)
    end

    neg_rules = begin
        submodels = unroll_rules(negconsequent(m); tree=tree)
        ant = ¬(tree(formula(antecedent(m))))

        map(subm-> begin
            if subm isa FinalModel
                Rule(LogicalTruthCondition(ant), subm)
            else
                f = formula(antecedent(subm))
                subants = f isa LeftmostLinearForm ? children(f) : [f]
                Rule(
                    LogicalTruthCondition( begin
                        lf = LeftmostConjunctiveForm([ant, subants...])
                        tree ? tree(lf) : lf
                    end ),
                    consequent(subm)
                )
            end
        end, submodels)
    end

    return [
        pos_rules...,
        neg_rules...,
    ]
end

function unroll_rules(
    m::DecisionList{O,<:Union{TrueCondition,LogicalTruthCondition}};
    kwargs...,
) where {O}
    [
        reduce(vcat,[unroll_rules(rule; kwargs...) for rule in rulebase(m)])...,
        Rule(unroll_rules(defaultconsequent(m); kwargs...)...),
    ]
end

unroll_rules(m::DecisionTree; kwargs...) = unroll_rules(root(m); kwargs...)

unroll_rules(m::MixedSymbolicModel; kwargs...) = unroll_rules(root(m); kwargs...)

############################################################################################
############################################################################################
############################################################################################
