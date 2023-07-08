
############################################################################################
# Symbolic modeling utils
############################################################################################

"""
    immediatesubmodels(m::AbstractModel)

Return the list of immediate child models.
Note: if the model is a leaf model, then the returned list will be empty.

# Examples
```julia-repl
julia> using SoleLogics

julia> branch = Branch(SoleLogics.parsebaseformula("p∧q∨r"), "YES", "NO");

julia> immediatesubmodels(branch)
2-element Vector{SoleModels.ConstantModel{String}}:
 SoleModels.ConstantModel{String}
YES

 SoleModels.ConstantModel{String}
NO

julia> branch2 = Branch(SoleLogics.parsebaseformula("s→p"), branch, 42);


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
[`LeafModel`](@ref),
[`AbstractModel`](@ref).
"""
function immediatesubmodels(
    m::AbstractModel{O}
)::Vector{<:{AbstractModel{<:O}}} where {O}
    return error("Please, provide method immediatesubmodels(::$(typeof(m))).")
end

immediatesubmodels(m::LeafModel{O}) where {O} = Vector{<:AbstractModel{<:O}}[]
immediatesubmodels(m::Rule) = [consequent(m)]
immediatesubmodels(m::Branch) = [posconsequent(m), negconsequent(m)]
immediatesubmodels(m::DecisionList) = [rulebase(m)..., defaultconsequent(m)]
immediatesubmodels(m::DecisionTree) = immediatesubmodels(root(m))
immediatesubmodels(m::DecisionForest) = trees(m)
immediatesubmodels(m::MixedSymbolicModel) = immediatesubmodels(root(m))

nimmediatesubmodels(m::LeafModel) = 0
nimmediatesubmodels(m::Rule) = 1
nimmediatesubmodels(m::Branch) = 2
nimmediatesubmodels(m::DecisionList) = length(rulebase(m)) + 1
nimmediatesubmodels(m::DecisionTree) = nimmediatesubmodels(root(m))
nimmediatesubmodels(m::DecisionForest) = length(trees(m))
nimmediatesubmodels(m::MixedSymbolicModel) = nimmediatesubmodels(root(m))

"""
    submodels(m::AbstractModel)

Enumerate all submodels in the sub-tree. This function is
the transitive closure of `immediatesubmodels`; in fact, the returned list
includes the immediate submodels (`immediatesubmodels(m)`), but also
their immediate submodels, and so on.

# Examples
```julia-repl
julia> using SoleLogics

julia> branch = Branch(SoleLogics.parsebaseformula("p∧q∨r"), "YES", "NO");

julia> submodels(branch)
2-element Vector{SoleModels.ConstantModel{String}}:
 ConstantModel
YES

 ConstantModel
NO


julia> branch2 = Branch(SoleLogics.parsebaseformula("s→p"), branch, 42);

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
[`LeafModel`](@ref),
[`AbstractModel`](@ref).
"""
submodels(m::AbstractModel) = [Iterators.flatten(_submodels.(immediatesubmodels(m)))...]
_submodels(m::AbstractModel) = [m, Iterators.flatten(_submodels.(immediatesubmodels(m)))...]
_submodels(m::DecisionList) = [Iterators.flatten(_submodels.(immediatesubmodels(m)))...]
_submodels(m::DecisionTree) = [Iterators.flatten(_submodels.(immediatesubmodels(m)))...]
_submodels(m::DecisionForest) = [Iterators.flatten(_submodels.(immediatesubmodels(m)))...]
_submodels(m::MixedSymbolicModel) = [Iterators.flatten(_submodels.(immediatesubmodels(m)))...]

nsubmodels(m::AbstractModel) = 1 + sum(nsubmodels, immediatesubmodels(m))
nsubmodels(m::DecisionList) = sum(nsubmodels, immediatesubmodels(m))
nsubmodels(m::DecisionTree) = sum(nsubmodels, immediatesubmodels(m))
nsubmodels(m::DecisionForest) = sum(nsubmodels, immediatesubmodels(m))
nsubmodels(m::MixedSymbolicModel) = sum(nsubmodels, immediatesubmodels(m))

leafmodels(m::AbstractModel) = [Iterators.flatten(leafmodels.(immediatesubmodels(m)))...]

nleafmodels(m::AbstractModel) = sum(nleafmodels, immediatesubmodels(m))

subtreeheight(m::AbstractModel) = 1 + maximum(subtreeheight, immediatesubmodels(m))
subtreeheight(m::LeafModel) = 0
subtreeheight(m::DecisionList) = maximum(subtreeheight, immediatesubmodels(m))
subtreeheight(m::DecisionTree) = maximum(subtreeheight, immediatesubmodels(m))
subtreeheight(m::DecisionForest) = maximum(subtreeheight, immediatesubmodels(m))
subtreeheight(m::MixedSymbolicModel) = maximum(subtreeheight, immediatesubmodels(m))

############################################################################################
############################################################################################
############################################################################################

# When `assumed_formula` is assumed, and `f` is known to be true, their conjuction holds.
advanceformula(f::AbstractFormula, assumed_formula::Union{Nothing,AbstractFormula}) =
    isnothing(assumed_formula) ? f : ∧(assumed_formula, f)

advanceformula(r::Rule, assumed_formula::Union{Nothing,AbstractFormula}) =
    Rule(TruthAntecedent(advanceformula(formula(r), assumed_formula)), consequent(r), info(r))

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

listimmediaterules(m::LeafModel) = [Rule(TrueAntecedent, m)]

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
    default_antecedent = isnothing(assumed_formula) ? TrueAntecedent : TruthAntecedent(assumed_formula)
    push!(normalized_rules, Rule(default_antecedent, defaultconsequent(m)))
    normalized_rules
end

listimmediaterules(m::DecisionTree) = listimmediaterules(root(m))

listimmediaterules(m::MixedSymbolicModel) = listimmediaterules(root(m))

############################################################################################
############################################################################################
############################################################################################

"""
    listrules(
        m::AbstractModel;
        force_syntaxtree::Bool = false,
        use_shortforms::Bool = true,
        use_leftmostlinearform::Bool = false,
    )::Vector{<:Rule}

Return a list of rules capturing the knowledge enclosed in symbolic model.
The behavior of any symbolic model can be extracted and represented as a
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

See also [`listimmediaterules`](@ref), [`issymbolic`](@ref), [`LeafModel`](@ref),
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

listrules(m::LeafModel; kwargs...) = [m]

function listrules(
    m::Rule{O,<:TrueAntecedent};
    kwargs...,
) where {O}
    [m]
end

function listrules(
    m::Rule{O,<:TruthAntecedent};
    force_syntaxtree::Bool = false
) where {O}
    ant = force_syntaxtree ? tree(formula(m)) : formula(m)
    [(force_syntaxtree ? Rule{O}(TruthAntecedent(ant), consequent(m), info(m)) : m)]
end

function listrules(
    m::Branch{O,<:TrueAntecedent};
    kwargs...,
) where {O}
    pos_rules = begin
        submodels = listrules(posconsequent(m); kwargs...)
        submodels isa Vector{<:LeafModel} ? [Rule{O,TrueAntecedent}(fm) for fm in submodels] : submodels
    end

    neg_rules = begin
        submodels = listrules(negconsequent(m); kwargs...)
        submodels isa Vector{<:LeafModel} ? [Rule{O,TrueAntecedent}(fm) for fm in submodels] : submodels
    end

    return [
        pos_rules...,
        neg_rules...,
    ]
end

function listrules(
    m::Branch{O,<:TruthAntecedent};
    use_shortforms::Bool = true,
    force_syntaxtree::Bool = false,
    use_leftmostlinearform::Bool = false,
    kwargs...,
) where {O}

    _subrules = [
        [(true, r) for r in listrules(posconsequent(m); use_shortforms = use_shortforms, use_leftmostlinearform = use_leftmostlinearform, force_syntaxtree = force_syntaxtree, kwargs...)]...,
        [(false, r) for r in listrules(negconsequent(m); use_shortforms = use_shortforms, use_leftmostlinearform = use_leftmostlinearform, force_syntaxtree = force_syntaxtree, kwargs...)]...
    ]

    rules = map(((flag, subrule),)->begin
            # @show info(subrule)
            known_infokeys = [:supporting_labels, :supporting_predictions, :shortform, :this, :multipathformula]
            ks = setdiff(keys(info(m)), known_infokeys)
            if length(ks) > 0
                @warn "Dropping info keys: $(join(repr.(ks), ", "))"
            end

            i = (;)
            if haskey(info(m), :supporting_labels)
                i = merge((;), (;
                    supporting_labels = info(m).supporting_labels,
                ))
            end
            if haskey(info(m), :supporting_predictions)
                i = merge((;), (;
                    supporting_predictions = info(m).supporting_predictions,
                ))
            end

            antformula, using_shortform = begin
                if (use_shortforms && haskey(info(subrule), :shortform))
                    formula(info(subrule)[:shortform]), true
                else
                    (flag ? formula(antecedent(m)) : ¬formula(antecedent(m))), false
                end
            end
            antformula = force_syntaxtree ? tree(antformula) : antformula
            # @show using_shortform
            # @show antformula
            # @show typeof(subrule)

            if subrule isa LeafModel
                ant = TruthAntecedent(SoleLogics.normalize(antformula; allow_proposition_flipping = true))
                subi = (;)
                # if use_shortforms
                #     subi = merge((;), (;
                #         shortform = ant
                #     ))
                # end
                Rule(ant, subrule, merge(info(subrule), subi, i))
            elseif subrule isa Rule
                ant = begin
                    if using_shortform
                        TruthAntecedent(antformula)
                    else
                        # Combine antecedents
                        f = begin
                            f = formula(subrule)
                            if use_leftmostlinearform
                                subantformulas = (f isa LeftmostLinearForm ? children(f) : [f])
                                lf = LeftmostConjunctiveForm([antformula, subantformulas...])
                                force_syntaxtree ? tree(lf) : lf
                            else
                                antformula ∧ f
                            end
                        end
                        TruthAntecedent(SoleLogics.normalize(f; allow_proposition_flipping = true))
                    end
                end
                Rule(ant, consequent(subrule), merge(info(subrule), i))
            else
                error("Unexpected rule type: $(typeof(subrule)).")
            end
        end, _subrules)

    return rules
end

function listrules(m::DecisionList; kwargs...)
    reduce(vcat,[listrules(rule; kwargs...) for rule in listimmediaterules(m)])
end

listrules(m::DecisionTree; kwargs...) = listrules(root(m); kwargs...)

listrules(m::MixedSymbolicModel; kwargs...) = listrules(root(m); kwargs...)

############################################################################################
############################################################################################
############################################################################################


function joinrules(
    rules::AbstractVector{
        <:Rule{<:Any,<:SoleModels.AbstractAntecedent,<:SoleModels.ConstantModel}
    },
    silent = false
)
    alloutcomes = unique(outcome.(consequent.(rules)))
    # @show info.(rules)
    # @show info.(consequent.(rules))
    return [begin
        these_rules = filter(r->outcome(consequent(r)) == _outcome, rules)
        leafinfo, ruleinfo = begin
            if !silent
                known_infokeys = [:supporting_labels, :supporting_predictions, :shortform, :this, :multipathformula]
                for i in [info.(these_rules)..., info.(consequent.(these_rules))...]
                    ks = setdiff(keys(i), known_infokeys)
                    if length(ks) > 0
                        @warn "Dropping info keys: $(join(repr.(ks), ", "))"
                    end
                end
            end
            leafinfo = begin
                leafinfo = (;)
                if any([haskey(info(c), :supporting_labels) for c in consequent.(these_rules)])
                    leafinfo = merge(leafinfo, (;
                        supporting_labels = vcat([info(c, :supporting_labels) for c in consequent.(these_rules) if haskey(info(c), :supporting_labels)]...)
                    ))
                end
                if any([haskey(info(c), :supporting_predictions) for c in consequent.(these_rules)])
                    leafinfo = merge(leafinfo, (;
                        supporting_predictions = vcat([info(c, :supporting_predictions) for c in consequent.(these_rules) if haskey(info(c), :supporting_predictions)]...)
                    ))
                end
                leafinfo
            end
            ruleinfo = begin
                ruleinfo = (;)
                if any([haskey(info(r), :supporting_labels) for r in these_rules])
                    ruleinfo = merge(ruleinfo, (;
                        supporting_labels = vcat([info(r, :supporting_labels) for r in these_rules if haskey(info(r), :supporting_labels)]...)
                    ))
                end
                if any([haskey(info(r), :supporting_predictions) for r in these_rules])
                    ruleinfo = merge(ruleinfo, (;
                        supporting_predictions = vcat([info(r, :supporting_predictions) for r in these_rules if haskey(info(r), :supporting_predictions)]...)
                    ))
                end
                if any([haskey(info(r), :shortform) for r in these_rules])
                    ruleinfo = merge(ruleinfo, (;
                        shortform = LeftmostDisjunctiveForm(vcat([formula(info(r, :shortform)) for r in these_rules if haskey(info(r), :shortform)]...))
                    ))
                end
                ruleinfo
            end
            leafinfo, ruleinfo
        end
        formulas = formula.(antecedent.(these_rules))
        newant = LeftmostDisjunctiveForm(formulas)
        newcons = ConstantModel(_outcome, leafinfo)
        Rule(newant, newcons, ruleinfo)
    end for _outcome in alloutcomes]
end
