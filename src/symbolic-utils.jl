
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

function join_antecedents(assumed_formulas::Vector{<:SoleLogics.Formula})
    if length(assumed_formulas) == 0
        ⊤
    else
        if all(x->x isa SoleLogics.AbstractSyntaxStructure, assumed_formulas)
            new_assumed_formulas = []
            for φ in assumed_formulas
                if φ isa LeftmostConjunctiveForm
                    append!(new_assumed_formulas, children(φ))
                else
                    push!(new_assumed_formulas, φ)
                end
            end
            LeftmostConjunctiveForm(new_assumed_formulas)
        else
            (length(assumed_formulas) == 1 ? first(assumed_formulas) : ∧(assumed_formulas...))
        end
    end
end
# TODO unique function for join_antecedents and combine_antecedents
function combine_antecedents(antformula, f, use_leftmostlinearform, force_syntaxtree)
    if use_leftmostlinearform
        subantformulas = (f isa LeftmostLinearForm ? children(f) : [f])
        force_syntaxtree ? tree(antformula) : antformula
        lf = LeftmostConjunctiveForm([antformula, subantformulas...])
        force_syntaxtree ? tree(lf) : lf
    else
        if f == ⊤
            antformula
        elseif antformula == ⊤
            f
        else
            antformula ∧ f
        end
    end
end

function _scalar_simplification(φ, scalar_simplification)
    if scalar_simplification == false
        φ
    elseif scalar_simplification == true
        SoleData.scalar_simplification(φ; silent = false)
    else
        SoleData.scalar_simplification(φ; silent = false, scalar_simplification...)
    end
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
    scalar_simplification::Union{Bool,NamedTuple} = normalize ? (; allow_scalar_range_conditions = true) : false,
    force_syntaxtree::Bool = false,
) where {O}
    assumed_formulas = Formula[]
    normalized_rules = Rule{<:O}[]
    for rule in rulebase(m)
        # @show assumed_formulas
        # @show consequent(rule).info
        # @show eltype([assumed_formulas..., antecedent(rule)])
        # @show assumed_formulas
        # @show antecedent(rule)
        φ = join_antecedents([assumed_formulas..., antecedent(rule)])
        # @show typeof(φ)
        # normalize && (φ = SoleLogics.normalize(φ; normalize_kwargs...))
        # @show typeof(φ)
        # @show φ
        φ = _scalar_simplification(φ, scalar_simplification)
        newrule = Rule(φ, consequent(rule), info(rule))
        push!(normalized_rules, newrule)
        ant = antecedent(rule)
        force_syntaxtree && (ant = tree(ant))
        # @show ant
        nant = SoleLogics.NEGATION(ant)
        # @show typeof(nant)
        normalize && (nant = SoleLogics.normalize(nant; normalize_kwargs...))
        # @show typeof(nant)
        nant = _scalar_simplification(nant, scalar_simplification)
        # @show typeof(nant)
        assumed_formulas = push!(assumed_formulas, nant)
    end
    # @show eltype(assumed_formulas)
    default_φ = join_antecedents(assumed_formulas)
    # @show default_φ
    default_φ = _scalar_simplification(default_φ, scalar_simplification)
    # normalize && (default_φ = SoleLogics.normalize(default_φ; normalize_kwargs...))
    push!(normalized_rules, Rule(default_φ, defaultconsequent(m), info(defaultconsequent(m))))
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
function listrules(m::AbstractModel;
    compute_metrics::Union{Nothing,Bool} = false,
    metrics_kwargs::NamedTuple = (;),
    #
    use_shortforms::Bool = true,
    use_leftmostlinearform::Bool = false,
    normalize::Bool = false,
    normalize_kwargs::NamedTuple = (; allow_atom_flipping = true, rotate_commutatives = false, ),
    scalar_simplification::Union{Bool,NamedTuple} = normalize ? (; allow_scalar_range_conditions = true) : false,
    force_syntaxtree::Bool = false,
    min_coverage::Union{Nothing,Number} = nothing,
    min_ncovered::Union{Nothing,Number} = nothing,
    min_ninstances::Union{Nothing,Number} = nothing,
    min_confidence::Union{Nothing,Number} = nothing,
    min_lift::Union{Nothing,Number} = nothing,
    metric_filter_callback::Union{Nothing,Base.Callable} = nothing,
    kwargs...,
)
    subkwargs = (;
        use_shortforms = use_shortforms,
        use_leftmostlinearform = use_leftmostlinearform,
        normalize = normalize,
        normalize_kwargs = normalize_kwargs,
        scalar_simplification = scalar_simplification,
        force_syntaxtree = force_syntaxtree,
        metrics_kwargs = metrics_kwargs,
        min_ninstances = min_ninstances,
        min_coverage = min_coverage,
        min_ncovered = min_ncovered,
        min_confidence = min_confidence,
        min_lift = min_lift,
        metric_filter_callback = metric_filter_callback,
        kwargs...)

    @assert compute_metrics in [false] "TODO implement"

    # if isnothing(compute_metrics)
    #     compute_metrics = (!isnothing(min_confidence) || !isnothing(min_coverage) || !isnothing(min_ncovered) || !isnothing(min_ninstances) || !isnothing(min_lift))
    # end

    rules = _listrules(m; subkwargs...)

    if compute_metrics || !isnothing(min_confidence) || !isnothing(min_coverage) || !isnothing(min_ncovered) || !isnothing(min_ninstances) || !isnothing(min_lift)
        rules = filter(r->begin
            ms = readmetrics(r; metrics_kwargs...)
            compute_metrics && (info!(r, ms))
            return (isnothing(min_ninstances) || (ms.ninstances >= min_ninstances)) &&
            (isnothing(min_coverage) || (ms.coverage >= min_coverage)) &&
            (isnothing(min_ncovered) || (ms.ncovered >= min_ncovered)) &&
            (isnothing(min_confidence) || (ms.confidence >= min_confidence)) &&
            (isnothing(min_lift) || (ms.lift >= min_lift)) &&
            (isnothing(metric_filter_callback) || metric_filter_callback(ms))
        end, rules)
    end

    return rules
end

function _listrules(m::AbstractModel; kwargs...)
    error("Please, provide method _listrules(::$(typeof(m))) ($(typeof(m)) is a symbolic model).")
end

_listrules(m::LeafModel{O}; kwargs...) where {O} = [Rule{O}(⊤, m, info(m))]

function _listrules(
    m::Rule{O};
    use_leftmostlinearform::Bool = false,
    force_syntaxtree::Bool = false,
    kwargs...
) where {O}
    [begin
        φ = combine_antecedents(antecedent(m), antecedent(subrule), use_leftmostlinearform, force_syntaxtree)
        Rule{O}(φ, consequent(subrule), info(subrule))
    end for subrule in _listrules(consequent(m); force_syntaxtree = force_syntaxtree, kwargs...)]
end

function _listrules(
    m::Branch{O};
    use_shortforms::Bool = true,
    use_leftmostlinearform::Bool = false,
    normalize::Bool = false,
    normalize_kwargs::NamedTuple = (; allow_atom_flipping = true, rotate_commutatives = false, ),
    scalar_simplification::Union{Bool,NamedTuple} = normalize ? (; allow_scalar_range_conditions = true) : false,
    force_syntaxtree::Bool = false,
    min_confidence::Union{Nothing,Number} = nothing,
    min_coverage::Union{Nothing,Number} = nothing,
    min_ninstances::Union{Nothing,Number} = nothing,
    kwargs...,
) where {O}

    subkwargs = (;
        use_shortforms = use_shortforms,
        use_leftmostlinearform = use_leftmostlinearform,
        normalize = normalize,
        normalize_kwargs = normalize_kwargs,
        scalar_simplification = scalar_simplification,
        force_syntaxtree = force_syntaxtree,
        min_confidence = min_confidence,
        min_coverage = min_coverage,
        min_ninstances = min_ninstances,
        kwargs...)

    _subrules = []
    if isnothing(min_ninstances) || (haskey(info(m), :supporting_labels) && length(info(m, :supporting_labels)) >= min_ninstances)
    # if (haskey(info(m), :supporting_labels) && length(info(m, :supporting_labels)) >= min_ninstances) &&
    #     (haskey(info(m), :supporting_labels) && length(info(m, :supporting_labels))/ntotinstances >= min_coverage)
        append!(_subrules, [(true,  r) for r in _listrules(posconsequent(m); subkwargs...)])
        append!(_subrules, [(false, r) for r in _listrules(negconsequent(m); subkwargs...)])
    end

    rules = map(((flag, subrule),)->begin
            # @show info(subrule)
            known_infokeys = [:supporting_labels, :supporting_predictions, :shortform, :this, :multipathformula]
            ks = setdiff(keys(info(m)), known_infokeys)
            if length(ks) > 0
                @warn "Dropping info keys: $(join(repr.(ks), ", "))"
            end

            _info = (;)
            if haskey(info(m), :supporting_labels) && haskey(info(m), :supporting_predictions)
                _info = merge((;), (;
                    supporting_labels = info(m).supporting_labels,
                # ))
            # end
            # if haskey(info(m), :supporting_predictions)
                # _info = merge((;), (;
                    supporting_predictions = info(m).supporting_predictions,
                ))
            elseif (haskey(info(m), :supporting_labels) != haskey(info(m), :supporting_predictions))
                @warn "List rules encountered an unexpected case. Both " *
                    " supporting_labels and supporting_predictions are necessary for correctly computing performance metrics. "
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
                ant = _scalar_simplification(ant, scalar_simplification)
                subi = (;)
                # if use_shortforms
                #     subi = merge((;), (;
                #         shortform = ant
                #     ))
                # end
                Rule(ant, subrule, merge(info(subrule), subi, _info))
            elseif subrule isa Rule
                ant = begin
                    if using_shortform
                        antformula
                    else
                        # Combine antecedents
                        combine_antecedents(antformula, antecedent(subrule), use_leftmostlinearform, force_syntaxtree)
                    end
                end
                normalize && (ant = SoleLogics.normalize(ant; normalize_kwargs...))
                ant = _scalar_simplification(ant, scalar_simplification)
                Rule(ant, consequent(subrule), merge(info(subrule), _info))
            else
                error("Unexpected rule type: $(typeof(subrule)).")
            end
        end, _subrules)

    return rules
end

function _listrules(
    m::DecisionList;
    # use_shortforms::Bool = true,
    # use_leftmostlinearform::Bool = false,
    # normalize::Bool = false,
    # normalize_kwargs::NamedTuple = (; allow_atom_flipping = true, ),
    # force_syntaxtree::Bool = false,
    normalize::Bool = false,
    normalize_kwargs::NamedTuple = (; allow_atom_flipping = true, ),
    scalar_simplification::Union{Bool,NamedTuple} = normalize ? (; allow_scalar_range_conditions = true) : false,
    force_syntaxtree::Bool = false,
    kwargs...
)
    rules = listimmediaterules(m;
        normalize = normalize,
        scalar_simplification = scalar_simplification,
        normalize_kwargs = normalize_kwargs,
        force_syntaxtree = force_syntaxtree,
    )
    return rules
end

_listrules(m::DecisionTree; kwargs...) = _listrules(root(m); kwargs...)

_listrules(m::DecisionForest; kwargs...) = error("TODO implement")

_listrules(m::MixedModel; kwargs...) = _listrules(root(m); kwargs...)

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
    silent = falsesilent...,
)
    allconsequents = unique(consequent.(rules))
    # @show info.(rules)
    # @show info.(consequent.(rules))
    return [begin
        these_rules = filter(r->consequent(r) == _consequent, rules)
        leafinfo, ruleinfo = begin
            if !silent
                known_infokeys = [:supporting_labels, :supporting_predictions, :shortform, :this, :multipathformula]
                for _info in [info.(these_rules)..., info.(consequent.(these_rules))...]
                    ks = setdiff(keys(_info), known_infokeys)
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
