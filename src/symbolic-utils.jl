
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
immediatesubmodels(m::MixedModel) = immediatesubmodels(root(m))

nimmediatesubmodels(m::LeafModel) = 0
nimmediatesubmodels(m::Rule) = 1
nimmediatesubmodels(m::Branch) = 2
nimmediatesubmodels(m::DecisionList) = length(rulebase(m)) + 1
nimmediatesubmodels(m::DecisionTree) = nimmediatesubmodels(root(m))
nimmediatesubmodels(m::DecisionForest) = length(trees(m))
nimmediatesubmodels(m::MixedModel) = nimmediatesubmodels(root(m))

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
[`LeafModel`](@ref),
[`AbstractModel`](@ref).
"""
submodels(m::AbstractModel) = [Iterators.flatten(_submodels.(immediatesubmodels(m)))...]
_submodels(m::AbstractModel) = [m, Iterators.flatten(_submodels.(immediatesubmodels(m)))...]
_submodels(m::DecisionList) = [Iterators.flatten(_submodels.(immediatesubmodels(m)))...]
_submodels(m::DecisionTree) = [Iterators.flatten(_submodels.(immediatesubmodels(m)))...]
_submodels(m::DecisionForest) = [Iterators.flatten(_submodels.(immediatesubmodels(m)))...]
_submodels(m::MixedModel) = [Iterators.flatten(_submodels.(immediatesubmodels(m)))...]

nsubmodels(m::AbstractModel) = 1 + sum(nsubmodels, immediatesubmodels(m))
nsubmodels(m::LeafModel) = 1
nsubmodels(m::DecisionList) = sum(nsubmodels, immediatesubmodels(m))
nsubmodels(m::DecisionTree) = sum(nsubmodels, immediatesubmodels(m))
nsubmodels(m::DecisionForest) = sum(nsubmodels, immediatesubmodels(m))
nsubmodels(m::MixedModel) = sum(nsubmodels, immediatesubmodels(m))

leafmodels(m::AbstractModel) = [Iterators.flatten(leafmodels.(immediatesubmodels(m)))...]
leafmodels(m::LeafModel) = [m]

nleafmodels(m::AbstractModel) = sum(nleafmodels, immediatesubmodels(m))
nleafmodels(m::LeafModel) = 1

subtreeheight(m::AbstractModel) = 1 + maximum(subtreeheight, immediatesubmodels(m))
subtreeheight(m::LeafModel) = 0
subtreeheight(m::DecisionList) = maximum(subtreeheight, immediatesubmodels(m))
subtreeheight(m::DecisionTree) = maximum(subtreeheight, immediatesubmodels(m))
subtreeheight(m::DecisionForest) = maximum(subtreeheight, immediatesubmodels(m))
subtreeheight(m::MixedModel) = maximum(subtreeheight, immediatesubmodels(m))

# AbstracTrees interface
import AbstractTrees: children

children(m::AbstractModel) = submodels(m)

############################################################################################
############################################################################################
############################################################################################

# # When `assumed_formulas` is assumed, and `f` is known to be true, their conjuction holds.
# advanceformula(f::Formula, assumed_formulas::Union{Nothing,Formula}) =
#     isnothing(assumed_formulas) ? f : ∧(assumed_formulas, f)

function join_antecedents(assumed_formulas::Vector{<:SoleLogics.AbstractSyntaxStructure})
    return length(assumed_formulas) == 0 ? ⊤ : LeftmostConjunctiveForm(assumed_formulas)
end

function join_antecedents(assumed_formulas::Vector{<:SoleLogics.Formula})
    return length(assumed_formulas) == 0 ? ⊤ : (
        length(assumed_formulas) == 1 ? first(assumed_formulas) : ∧(assumed_formulas...)
    )
end

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

See also [`listrules`](@ref), [`AbstractModel`](@ref).
"""
listimmediaterules(m::AbstractModel{O} where {O})::Rule{<:O} =
    error("Please, provide method listimmediaterules(::$(typeof(m))) ($(typeof(m)) is a symbolic model).")

listimmediaterules(m::LeafModel) = [Rule(⊤, m)]

listimmediaterules(m::Rule) = [m]

listimmediaterules(m::Branch{O}) where {O} = [
    Rule{O}(antecedent(m), posconsequent(m)),
    Rule{O}(SoleLogics.NEGATION(antecedent(m)), negconsequent(m)),
]

function listimmediaterules(
    m::DecisionList{O};
    # use_shortforms::Bool = true,
    # use_leftmostlinearform::Bool = false,
    normalize::Bool = false,
    normalize_kwargs::NamedTuple = (; allow_atom_flipping = true, rotate_commutatives = false),
    force_syntaxtree::Bool = false,
) where {O}
    assumed_formulas = Formula[]
    normalized_rules = Rule{<:O}[]
    for rule in rulebase(m)
        # @show assumed_formulas
        newrule = Rule(join_antecedents([assumed_formulas..., antecedent(rule)]), consequent(rule), info(rule))
        push!(normalized_rules, newrule)
        ant = antecedent(rule)
        force_syntaxtree && (ant = tree(ant))
        # @show ant
        nant = SoleLogics.NEGATION(ant)
        normalize && (nant = SoleLogics.normalize(nant; normalize_kwargs...))
        assumed_formulas = push!(assumed_formulas, nant)
    end
    default_antecedent = join_antecedents(assumed_formulas)
    push!(normalized_rules, Rule{O}(default_antecedent, defaultconsequent(m)))
    normalized_rules
end

listimmediaterules(m::DecisionTree) = listimmediaterules(root(m))

listimmediaterules(m::DecisionForest; kwargs...) = error("TODO implement")

listimmediaterules(m::MixedModel) = listimmediaterules(root(m))

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

See also [`listimmediaterules`](@ref),
[`SoleLogics.CONJUNCTION`](@ref),
[`joinrules`](@ref), [`LeafModel`](@ref),
[`AbstractModel`](@ref).
"""
function listrules(m::AbstractModel; kwargs...)
    error("Please, provide method listrules(::$(typeof(m))) ($(typeof(m)) is a symbolic model).")
end

listrules(m::LeafModel; kwargs...) = [m]

function listrules(
    m::Rule{O};
    force_syntaxtree::Bool = false,
) where {O}
    ant = force_syntaxtree ? tree(antecedent(m)) : antecedent(m)
    [(force_syntaxtree ? Rule{O}(ant, consequent(m), info(m)) : m)]
end

function listrules(
    m::Branch{O};
    use_shortforms::Bool = true,
    use_leftmostlinearform::Bool = false,
    normalize::Bool = false,
    normalize_kwargs::NamedTuple = (; allow_atom_flipping = true, ),
    force_syntaxtree::Bool = false,
    compute_metrics::Union{Nothing,Bool} = nothing,
    min_confidence::Union{Nothing,Number} = nothing,
    min_coverage::Union{Nothing,Number} = nothing,
    min_ninstances::Union{Nothing,Number} = nothing,
    ntotinstances::Union{Nothing,Int} = nothing,
    kwargs...,
) where {O}

    if isnothing(compute_metrics)
        compute_metrics = (!isnothing(min_confidence) || !isnothing(min_coverage) || !isnothing(min_ninstances) || !isnothing(ntotinstances))
    end

    subkwargs = (;
        use_shortforms = use_shortforms,
        use_leftmostlinearform = use_leftmostlinearform,
        normalize = normalize,
        force_syntaxtree = force_syntaxtree,
        compute_metrics = false, # I'm computing them here, afterall
        min_confidence = min_confidence,
        min_coverage = min_coverage,
        min_ninstances = min_ninstances,
        kwargs...)

    _subrules = []
    if isnothing(min_ninstances) || (haskey(info(m), :supporting_predictions) && length(info(m, :supporting_predictions)) >= min_ninstances)
    # if (haskey(info(m), :supporting_predictions) && length(info(m, :supporting_predictions)) >= min_ninstances) &&
    #     (haskey(info(m), :supporting_predictions) && length(info(m, :supporting_predictions))/ntotinstances >= min_coverage)
        append!(_subrules, [(true,  r) for r in listrules(posconsequent(m); subkwargs...)])
        append!(_subrules, [(false, r) for r in listrules(negconsequent(m); subkwargs...)])
    end

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
                normalize && (ant = SoleLogics.normalize(ant; normalize_kwargs...))
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
                normalize && (ant = SoleLogics.normalize(ant; normalize_kwargs...))
                Rule(ant, consequent(subrule), merge(info(subrule), i))
            else
                error("Unexpected rule type: $(typeof(subrule)).")
            end
        end, _subrules)

    if compute_metrics
        ms = readmetrics.(rules)
        info!(rules, ms)
    end

    return rules
end

function listrules(
    m::DecisionList;
    # use_shortforms::Bool = true,
    # use_leftmostlinearform::Bool = false,
    # normalize::Bool = false,
    # normalize_kwargs::NamedTuple = (; allow_atom_flipping = true, ),
    # force_syntaxtree::Bool = false,
    kwargs...
)
    rules = reduce(vcat, listimmediaterules(m; kwargs...))
    return rules
end

listrules(m::DecisionTree; kwargs...) = listrules(root(m); kwargs...)

listrules(m::DecisionForest; kwargs...) = error("TODO implement")

listrules(m::MixedModel; kwargs...) = listrules(root(m); kwargs...)

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

See also [`listrules`](@ref),
[`SoleLogics.DISJUNCTION`](@ref), [`LeafModel`](@ref),
[`AbstractModel`](@ref).
"""
function joinrules(
    rules::AbstractVector{<:Rule},
    silent = false
)
    allconsequents = unique(consequent.(rules))
    # @show info.(rules)
    # @show info.(consequent.(rules))
    return [begin
        these_rules = filter(r->consequent(r) == _consequent, rules)
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
        newcons = deepcopy(_consequent)
        info!(newcons, leafinfo)
        Rule(newant, newcons, ruleinfo)
    end for _consequent in allconsequents]
end
