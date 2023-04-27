
############################################################################################
# Symbolic modeling utils
############################################################################################

"""
    immediatesubmodels(m::AbstractModel)

Returns a list of immediate child models.
Note: if the model is final, then the list is empty.

# Examples
```julia-repl
julia> print(join(displaymodel.(immediatesubmodels(rule); header = false)))
YES

julia> print(join(displaymodel.(immediatesubmodels(rcmodel); header = false)))
1

julia> print(join(displaymodel.(immediatesubmodels(branch); header = false)))
┐ q
├ ✔ YES
└ ✘ NO
YES

julia> print(join(displaymodel.(immediatesubmodels(decision_list); header = false)))
┐(r ∧ s) ∧ t
└ ✔ YES
┐¬(r)
└ ✔ YES
YES

julia> print(join(displaymodel.(immediatesubmodels(decision_tree); header = false)))
┐ s
├ ✔ YES
└ ✘ NO
┐ t
├ ✔ ┐ q
│   ├ ✔ YES
│   └ ✘ NO
└ ✘ YES

julia> print(join(displaymodel.(immediatesubmodels(mixed_symbolic_model); header = false)))
2
1.5
```

See also
[`submodels`](@ref),
[`FinalModel`](@ref),
[`AbstractModel`](@ref).
"""
function immediatesubmodels(
    m::AbstractModel{O}
)::Vector{<:{AbstractModel{<:O}}} where {O}
    error("Please, provide method immediatesubmodels(::$(typeof(m))).")
end

immediatesubmodels(m::FinalModel{O}) where {O} = Vector{<:AbstractModel{<:O}}[]
immediatesubmodels(m::Rule) = [consequent(m)]
immediatesubmodels(m::Branch) = [posconsequent(m), negconsequent(m)]
immediatesubmodels(m::DecisionList) = [rulebase(m)..., defaultconsequent(m)]
immediatesubmodels(m::DecisionTree) = immediatesubmodels(root(m))
immediatesubmodels(m::MixedSymbolicModel) = immediatesubmodels(root(m))

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
[`immediatesubmodels`](@ref),
[`FinalModel`](@ref),
[`AbstractModel`](@ref).
"""
submodels(m::AbstractModel) = [Iterators.flatten(_submodels.(immediatesubmodels(m)))...]
_submodels(m::AbstractModel) = [m, Iterators.flatten(_submodels.(immediatesubmodels(m)))...]


############################################################################################
############################################################################################
############################################################################################

# When `assumed_formula` is assumed, and `f` is known to be true, their conjuction holds.
advanceformula(f::AbstractFormula, assumed_formula::Union{Nothing,AbstractFormula}) =
    isnothing(assumed_formula) ? f : ∧(assumed_formula, f)

advanceformula(r::Rule, assumed_formula::Union{Nothing,AbstractFormula}) =
    Rule(LogicalTruthCondition(advanceformula(formula(r), assumed_formula)), consequent(r), info(r))

############################################################################################
############################################################################################
############################################################################################

"""
    immediaterules(m::AbstractModel{O} where {O})::Rule{<:O}

Returns the immediate rules equivalent to a model. TODO explain

See also [`unrollrules`](@ref), [`issymbolic`](@ref), [`AbstractModel`](@ref).
"""
immediaterules(m::AbstractModel{O} where {O})::Rule{<:O} =
    error(begin
        if issymbolic(m)
            "Please, provide method immediaterules(::$(typeof(m))) ($(typeof(m)) is a symbolic model)."
        else
            "Models of type $(typeof(m)) are not symbolic, and thus have no rules associated."
        end
    end)

immediaterules(m::FinalModel) = [Rule(TrueCondition, m)]

immediaterules(m::Rule) = [m]

immediaterules(m::Branch{O,FM}) where {O,FM} = [
    Rule{O,FM}(antecedent(m), posconsequent(m)),
    Rule{O,FM}(SoleLogics.NEGATION(antecedent(m)), negconsequent(m)),
]

function immediaterules(m::DecisionList{O,C,FM}) where {O,C,FM}
    assumed_formula = nothing
    normalized_rules = []
    for rule in rulebase(m)
        rule = advanceformula(rule, assumed_formula)
        push!(normalized_rules, rule)
        assumed_formula = advanceformula(SoleLogics.NEGATION(formula(rule)), assumed_formula)
    end
    default_antecedent = isnothing(assumed_formula) ? TrueCondition : LogicalTruthCondition(assumed_formula)
    push!(normalized_rules, Rule(default_antecedent, defaultconsequent(m)))
    normalized_rules
end

immediaterules(m::DecisionTree) = immediaterules(root(m))

immediaterules(m::MixedSymbolicModel) = immediaterules(root(m))

############################################################################################
############################################################################################
############################################################################################

"""
    unrollrules(m::AbstractModel; tree::Bool = false)

This function extracts the behavior of a symbolic model and represents it as a
set of mutually exclusive (and jointly exaustive, if the model is closed) rules,
which can be useful for many purposes.

`tree` is a kwarg which when set to true then returns a vector of rules where the
antecedent is constructed as SyntaxTree

# Examples
```julia-repl
@test unrollrules(r2_string) isa Vector{<:Rule}
julia> print(join(displaymodel.(unrollrules(rule); header = false)))
┐¬(r)
└ ✔ YES

julia> print(join(displaymodel.(unrollrules(decision_list); header = false)))
┐(r ∧ s) ∧ t
└ ✔ YES
┐¬(r)
└ ✔ YES
┐⊤
└ ✔ YES

@test unrollrules(rcmodel) isa Vector{<:Rule}
julia> print(join(displaymodel.(unrollrules(rule_cascade); header = false)))
┐(p ∧ (q ∨ r)) ∧ ((p ∧ (q ∨ r)) ∧ (p ∧ (q ∨ r)))
└ ✔ 1

julia> print(join(displaymodel.(unrollrules(branch); header = false)))
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

julia> print(join(displaymodel.(unrollrules(decision_tree); header = false)))
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

julia> print(join(displaymodel.(unrollrules(mixed_symbolic_model); header = false)))
┐q
└ ✔ 2
┐¬(q)
└ ✔ 1.5
```

See also [`immediaterules`](@ref), [`issymbolic`](@ref), [`FinalModel`](@ref),
[`AbstractModel`](@ref).
"""
function unrollrules(m::AbstractModel; kwargs...)
    error(begin
        if issymbolic(m)
            "Please, provide method unrollrules(::$(typeof(m))) ($(typeof(m)) is a symbolic model)."
        else
            "Models of type $(typeof(m)) are not symbolic, and thus have no rules associated."
        end
    end)
end

unrollrules(m::FinalModel; kwargs...) = [m]

function unrollrules(
    m::Rule{O,<:TrueCondition};
    kwargs...,
) where {O}
    [m]
end

function unrollrules(
    m::Rule{O,<:LogicalTruthCondition};
    syntaxtree::Bool = false
) where {O}
    [begin
       !syntaxtree ? m : Rule{O}(
            LogicalTruthCondition(tree(formula(m))),
            consequent(m),
            info(m)
        )
    end]
end

# TODO warning we loose the info
function unrollrules(
    m::Branch{O,<:TrueCondition};
    kwargs...,
) where {O}
    pos_rules = begin
        submodels = unrollrules(posconsequent(m); kwargs...)
        submodels isa Vector{<:FinalModel} ? [Rule{O,TrueCondition}(fm) for fm in submodels] : submodels
    end

    neg_rules = begin
        submodels = unrollrules(negconsequent(m); kwargs...)
        submodels isa Vector{<:FinalModel} ? [Rule{O,TrueCondition}(fm) for fm in submodels] : submodels
    end

    return [
        pos_rules...,
        neg_rules...,
    ]
end

function unrollrules(
    m::Branch{O,<:LogicalTruthCondition};
    syntaxtree::Bool = false,
    kwargs...,
) where {O}
    pos_rules = begin
        submodels = unrollrules(posconsequent(m); syntaxtree = syntaxtree, kwargs...)
        ant = tree(formula(m))

        map(subm-> begin
            if subm isa FinalModel
                Rule(LogicalTruthCondition(ant), subm)
            else
                f = formula(subm)
                subants = f isa LeftmostLinearForm ? children(f) : [f]
                Rule(
                    LogicalTruthCondition( begin
                        lf = LeftmostConjunctiveForm([ant, subants...])
                        syntaxtree ? tree(lf) : lf
                    end ),
                    consequent(subm)
                )
            end
        end, submodels)
    end

    neg_rules = begin
        submodels = unrollrules(negconsequent(m); syntaxtree = syntaxtree, kwargs...)
        ant = ¬(tree(formula(m)))

        map(subm-> begin
            if subm isa FinalModel
                Rule(LogicalTruthCondition(ant), subm)
            else
                f = formula(subm)
                subants = f isa LeftmostLinearForm ? children(f) : [f]
                Rule(
                    LogicalTruthCondition( begin
                        lf = LeftmostConjunctiveForm([ant, subants...])
                        syntaxtree ? tree(lf) : lf
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

function unrollrules(m::DecisionList; kwargs...)
    reduce(vcat,[unrollrules(rule; kwargs...) for rule in immediaterules(m)])
end

unrollrules(m::DecisionTree; kwargs...) = unrollrules(root(m); kwargs...)

unrollrules(m::MixedSymbolicModel; kwargs...) = unrollrules(root(m); kwargs...)

############################################################################################
############################################################################################
############################################################################################
