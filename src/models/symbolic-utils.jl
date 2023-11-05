
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
advanceformula(f::Formula, assumed_formula::Union{Nothing,Formula}) =
    isnothing(assumed_formula) ? f : ∧(assumed_formula, f)

advanceformula(r::Rule, assumed_formula::Union{Nothing,Formula}) =
    Rule(advanceformula(antecedent(r), assumed_formula), consequent(r), info(r))

############################################################################################
############################################################################################
############################################################################################

"""
    listimmediaterules(m::AbstractModel{O} where {O})::Rule{<:O}

List the immediate rules equivalent to a symbolic model.

# Examples
```julia-repl
julia> using SoleLogics

julia> branch = Branch(SoleLogics.parseformula("p"), Branch(SoleLogics.parseformula("q"), "YES", "NO"), "NO")
 p
├✔ q
│├✔ YES
│└✘ NO
└✘ NO


julia> printmodel.(listimmediaterules(branch); tree_mode = true);
▣ p
└✔ q
 ├✔ YES
 └✘ NO

▣ ¬(p)
└✔ NO


```

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

listimmediaterules(m::LeafModel) = [Rule(⊤, m)]

listimmediaterules(m::Rule) = [m]

listimmediaterules(m::Branch{O}) where {O} = [
    Rule{O}(antecedent(m), posconsequent(m)),
    Rule{O}(SoleLogics.NEGATION(antecedent(m)), negconsequent(m)),
]

function listimmediaterules(m::DecisionList{O}) where {O}
    assumed_formula = nothing
    normalized_rules = []
    for rule in rulebase(m)
        rule = advanceformula(rule, assumed_formula)
        push!(normalized_rules, rule)
        assumed_formula = advanceformula(SoleLogics.NEGATION(antecedent(rule)), assumed_formula)
    end
    default_antecedent = isnothing(assumed_formula) ? ⊤ : assumed_formula
    push!(normalized_rules, Rule{O}(default_antecedent, defaultconsequent(m)))
    normalized_rules
end

listimmediaterules(m::DecisionTree) = listimmediaterules(root(m))

listimmediaterules(m::MixedSymbolicModel) = listimmediaterules(root(m))

############################################################################################
############################################################################################
############################################################################################

# TODO @Michi esempi
"""
    listrules(
        m::AbstractModel;
        use_shortforms::Bool = true,
        use_leftmostlinearform::Bool = false,
        normalize::Bool = false,
        force_syntaxtree::Bool = false,
    )::Vector{<:Rule}

Return a list of rules capturing the knowledge enclosed in symbolic model.
The behavior of any symbolic model can be synthesised and represented as a
set of mutually exclusive (and jointly exaustive, if the model is closed) rules,
which can be useful for many purposes.

The keyword argument `force_syntaxtree`, when set to true, causes the logical antecedents
in the returned rules to be represented as `SyntaxTree`s, as opposed to other syntax
structure (e.g., `LeftmostConjunctiveForm`).

# Examples
```julia-repl
julia> using SoleLogics

julia> branch = Branch(SoleLogics.parseformula("p"), Branch(SoleLogics.parseformula("q"), "YES", "NO"), "NO")
 p
├✔ q
│├✔ YES
│└✘ NO
└✘ NO


julia> printmodel.(listrules(branch); tree_mode = true);
▣ p ∧ q
└✔ YES

▣ p ∧ ¬q
└✔ NO

▣ ¬p
└✔ NO

```

See also [`listimmediaterules`](@ref), [`joinrules`](@ref), [`issymbolic`](@ref), [`LeafModel`](@ref),
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
    m::Rule{O,Top};
    kwargs...,
) where {O}
    [m]
end

function listrules(
    m::Rule{O};
    force_syntaxtree::Bool = false
) where {O}
    ant = force_syntaxtree ? tree(antecedent(m)) : antecedent(m)
    [(force_syntaxtree ? Rule{O}(ant, consequent(m), info(m)) : m)]
end

function listrules(
    m::Branch{O,Top};
    kwargs...,
) where {O}
    pos_rules = begin
        submodels = listrules(posconsequent(m); kwargs...)
        submodels isa Vector{<:LeafModel} ? [Rule{O,Top}(fm) for fm in submodels] : submodels
    end

    neg_rules = begin
        submodels = listrules(negconsequent(m); kwargs...)
        submodels isa Vector{<:LeafModel} ? [Rule{O,Top}(fm) for fm in submodels] : submodels
    end

    return [
        pos_rules...,
        neg_rules...,
    ]
end

function listrules(
    m::Branch{O};
    use_shortforms::Bool = true,
    use_leftmostlinearform::Bool = false,
    normalize::Bool = false,
    force_syntaxtree::Bool = false,
    kwargs...,
) where {O}

    _subrules = [
        [(true, r) for r in listrules(posconsequent(m); use_shortforms = use_shortforms, use_leftmostlinearform = use_leftmostlinearform, normalize = normalize, force_syntaxtree = force_syntaxtree, kwargs...)]...,
        [(false, r) for r in listrules(negconsequent(m); use_shortforms = use_shortforms, use_leftmostlinearform = use_leftmostlinearform, normalize = normalize, force_syntaxtree = force_syntaxtree, kwargs...)]...
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
                    info(subrule)[:shortform], true
                else
                    (flag ? antecedent(m) : ¬antecedent(m)), false
                end
            end
            antformula = force_syntaxtree ? tree(antformula) : antformula
            # @show using_shortform
            # @show antformula
            # @show typeof(subrule)

            if subrule isa LeafModel
                ant = antformula
                normalize && (ant = SoleLogics.normalize(ant; allow_atom_flipping = true))
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
                        antformula
                    else
                        # Combine antecedents
                        f = antecedent(subrule)
                        if use_leftmostlinearform
                            subantformulas = (f isa LeftmostLinearForm ? children(f) : [f])
                            lf = LeftmostConjunctiveForm([antformula, subantformulas...])
                            force_syntaxtree ? tree(lf) : lf
                        else
                            antformula ∧ f
                        end
                    end
                end
                normalize && (ant = SoleLogics.normalize(ant; allow_atom_flipping = true))
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


"""
    joinrules(rules::AbstractVector{<:Rule})::Vector{<:Rule}

Return a set of rules, with exactly one rule per different outcome from the input set of rules.
For each outcome, the output rule is computed as the logical disjunction of the antecedents
of the input rules for that outcome.

# Examples
```julia-repl
julia> using SoleLogics

julia> branch = Branch(SoleLogics.parseformula("p"), Branch(SoleLogics.parseformula("q"), "YES", "NO"), "NO")
 p
├✔ q
│├✔ YES
│└✘ NO
└✘ NO


julia> printmodel.(listrules(branch); tree_mode = true);
▣ p ∧ q
└✔ YES

▣ p ∧ ¬q
└✔ NO

▣ ¬p
└✔ NO

julia> printmodel.(joinrules(listrules(branch)); tree_mode = true);
▣ (p ∧ q)
└✔ YES

▣ (p ∧ ¬q) ∨ ¬p
└✔ NO

```

See also [`listrules`](@ref), [`issymbolic`](@ref), [`DISJUNCTION`](@ref), [`LeafModel`](@ref),
[`AbstractModel`](@ref).
"""
function joinrules(
    rules::AbstractVector{
        <:Rule{<:Any,<:SoleModels.Formula,<:SoleModels.ConstantModel}
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
                        shortform = LeftmostDisjunctiveForm(vcat([info(r, :shortform) for r in these_rules if haskey(info(r), :shortform)]...))
                    ))
                end
                ruleinfo
            end
            leafinfo, ruleinfo
        end
        ants = antecedent.(these_rules)
        newant = LeftmostDisjunctiveForm(ants)
        newcons = ConstantModel(_outcome, leafinfo)
        Rule(newant, newcons, ruleinfo)
    end for _outcome in alloutcomes]
end
