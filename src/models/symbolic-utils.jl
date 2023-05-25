
############################################################################################
# Symbolic modeling utils
############################################################################################

"""
    immediatesubmodels(m::AbstractModel)

Return the list of immediate child models.
Note: if the model is final, then the returned list will be empty.

# Examples
```julia-repl
julia> using SoleLogics

julia> branch = Branch(SoleLogics.parseformula("p∧q∨r"), "YES", "NO");

julia> immediatesubmodels(branch)
2-element Vector{SoleModels.ConstantModel{String}}:
 SoleModels.ConstantModel{String}
YES

 SoleModels.ConstantModel{String}
NO

julia> branch2 = Branch(SoleLogics.parseformula("s→p"), branch, 42);


julia> printmodel.(immediatesubmodels(branch2));
Branch
┐ p ∧ (q ∨ r)
├ ✔ YES
└ ✘ NO

ConstantModel
42
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

Enumerate all submodels in the sub-tree. This function is
the transitive closure of `immediatesubmodels`; in fact, the returned list
includes the immediate submodels (`immediatesubmodels(m)`), but also
their immediate submodels, and so on.

# Examples
```julia-repl
julia> using SoleLogics

julia> branch = Branch(SoleLogics.parseformula("p∧q∨r"), "YES", "NO");

julia> submodels(branch)
2-element Vector{SoleModels.ConstantModel{String}}:
 ConstantModel
YES

 ConstantModel
NO


julia> branch2 = Branch(SoleLogics.parseformula("s→p"), branch, 42);

julia> printmodel.(submodels(branch2));
Branch
┐ p ∧ (q ∨ r)
├ ✔ YES
└ ✘ NO

ConstantModel
YES

ConstantModel
NO

ConstantModel
42

julia> submodels(branch) == immediatesubmodels(branch)
true

julia> submodels(branch2) == immediatesubmodels(branch2)
false
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
    listimmediaterules(m::AbstractModel{O} where {O})::Rule{<:O}

List the immediate rules equivalent to a symbolic model.

See also [`listrules`](@ref), [`issymbolic`](@ref), [`AbstractModel`](@ref).
"""
listimmediaterules(m::AbstractModel{O} where {O})::Rule{<:O} =
    error(begin
        if issymbolic(m)
            "Please, provide method listimmediaterules(::$(typeof(m))) ($(typeof(m)) is a symbolic model)."
        else
            "Models of type $(typeof(m)) are not symbolic, and thus have no rules associated."
        end
    end)

listimmediaterules(m::FinalModel) = [Rule(TrueCondition, m)]

listimmediaterules(m::Rule) = [m]

listimmediaterules(m::Branch{O,FM}) where {O,FM} = [
    Rule{O,FM}(antecedent(m), posconsequent(m)),
    Rule{O,FM}(SoleLogics.NEGATION(antecedent(m)), negconsequent(m)),
]

function listimmediaterules(m::DecisionList{O,C,FM}) where {O,C,FM}
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

listimmediaterules(m::DecisionTree) = listimmediaterules(root(m))

listimmediaterules(m::MixedSymbolicModel) = listimmediaterules(root(m))

############################################################################################
############################################################################################
############################################################################################

"""
    listrules(m::AbstractModel; force_syntaxtree::Bool = false)::Vector{<:Rule}

Return a list of rules capturing the knowledge enclosed in symbolic model.
The behavior of a symbolic model can be extracted and represented as a
set of mutually exclusive (and jointly exaustive, if the model is closed) rules,
which can be useful for many purposes.

The keyword argument `force_syntaxtree`, when set to true, causes the logical antecedents
in the returned rules to be represented as `SyntaxTree`s, as opposed to other syntax
structure (e.g., `LeftmostConjunctiveForm`).

# Examples
# TODO @Michi questi esempi non sono chiari: cosa è r2_string?
```julia-repl
@test listrules(r2_string) isa Vector{<:Rule}
julia> print(join(displaymodel.(listrules(rule); header = false)))
┐¬(r)
└ ✔ YES

julia> print(join(displaymodel.(listrules(decision_list); header = false)))
┐(r ∧ s) ∧ t
└ ✔ YES
┐¬(r)
└ ✔ YES
┐⊤
└ ✔ YES

@test listrules(rcmodel) isa Vector{<:Rule}
julia> print(join(displaymodel.(listrules(rule_cascade); header = false)))
┐(p ∧ (q ∨ r)) ∧ ((p ∧ (q ∨ r)) ∧ (p ∧ (q ∨ r)))
└ ✔ 1

julia> print(join(displaymodel.(listrules(branch); header = false)))
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

julia> print(join(displaymodel.(listrules(decision_tree); header = false)))
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

julia> print(join(displaymodel.(listrules(mixed_symbolic_model); header = false)))
┐q
└ ✔ 2
┐¬(q)
└ ✔ 1.5
```

See also [`listimmediaterules`](@ref), [`issymbolic`](@ref), [`FinalModel`](@ref),
[`AbstractModel`](@ref).
"""
function listrules(m::AbstractModel; kwargs...)
    error(begin
        if issymbolic(m)
            "Please, provide method listrules(::$(typeof(m))) ($(typeof(m)) is a symbolic model)."
        else
            "Models of type $(typeof(m)) are not symbolic, and thus have no rules associated."
        end
    end)
end

listrules(m::FinalModel; kwargs...) = [m]

function listrules(
    m::Rule{O,<:TrueCondition};
    kwargs...,
) where {O}
    [m]
end

function listrules(
    m::Rule{O,<:LogicalTruthCondition};
    force_syntaxtree::Bool = false
) where {O}
    [begin
       !force_syntaxtree ? m : Rule{O}(
            LogicalTruthCondition(tree(formula(m))),
            consequent(m),
            info(m)
        )
    end]
end

function listrules(
    m::Branch{O,<:TrueCondition};
    kwargs...,
) where {O}
    pos_rules = begin
        submodels = listrules(posconsequent(m); kwargs...)
        submodels isa Vector{<:FinalModel} ? [Rule{O,TrueCondition}(fm) for fm in submodels] : submodels
    end

    neg_rules = begin
        submodels = listrules(negconsequent(m); kwargs...)
        submodels isa Vector{<:FinalModel} ? [Rule{O,TrueCondition}(fm) for fm in submodels] : submodels
    end

    return [
        pos_rules...,
        neg_rules...,
    ]
end

function listrules(
    m::Branch{O,<:LogicalTruthCondition};
    force_syntaxtree::Bool = false,
    kwargs...,
) where {O}
    pos_rules = begin
        submodels = listrules(posconsequent(m); force_syntaxtree = force_syntaxtree, kwargs...)
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
                        force_syntaxtree ? tree(lf) : lf
                    end),
                    consequent(subm)
                )
            end
        end, submodels)
    end

    neg_rules = begin
        submodels = listrules(negconsequent(m); force_syntaxtree = force_syntaxtree, kwargs...)
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
                        force_syntaxtree ? tree(lf) : lf
                    end),
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

function listrules(m::DecisionList; kwargs...)
    reduce(vcat,[listrules(rule; kwargs...) for rule in listimmediaterules(m)])
end

listrules(m::DecisionTree; kwargs...) = listrules(root(m); kwargs...)

listrules(m::MixedSymbolicModel; kwargs...) = listrules(root(m); kwargs...)

############################################################################################
############################################################################################
############################################################################################
