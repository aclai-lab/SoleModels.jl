using IterTools


"""
An exact or heuristic logical method for extracting logical rule from symbolic models.

Refer to [SolePostHoc](https://github.com/aclai-lab/SolePostHoc.jl) for rule extraction methods.

See also [`extractrules`](@ref), [`Rule`](@ref)], [`issymbolicmodel`](@ref).
"""
abstract type RuleExtractor end

"""
Return whether a rule extraction method is known to be exact (as opposed to heuristic).
"""
isexact(::RuleExtractor) = false

"""
    extractrules(re::RuleExtractor, m, args...; kwargs...)

Extract rules from symbolic model `m`, using a rule extraction method `re`.
"""
function extractrules(re::RuleExtractor, m, args...; kwargs...)
    return error("Please, provide method extractrules(::$(typeof(m)), args...; kwargs...).")
end

# Helpers
function (RE::Type{<:RuleExtractor})(args...; kwargs...)
    return extractrules(RE(), args...; kwargs...)
end

# Helpers
function (re::RuleExtractor)(args...; kwargs...)
    return extractrules(re, args...; kwargs...)
end

"""
Plain extraction method involves listing one rule per each possible symbolic path within the model.
With this method, [`extractrules`](@ref) redirects to [`listrules`](@ref).

See also [`listrules`](@ref), [`Rule`](@ref)], [`issymbolicmodel`](@ref).
"""
struct PlainRuleExtractor <: RuleExtractor end
isexact(::PlainRuleExtractor) = true
function extractrules(::PlainRuleExtractor, m, args...; kwargs...)
    if haslistrules(m)
        listrules(m, args...; kwargs...)
    else
        listrules(solemodel(m), args...; kwargs...)
    end
end

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
                    append!(new_assumed_formulas, SoleLogics.grandchildren(φ))
                else
                    push!(new_assumed_formulas, φ)
                end
            end
            LeftmostConjunctiveForm(new_assumed_formulas)
        else
            (length(assumed_formulas) == 1 ? first(assumed_formulas) : ∧(filter(!istop, assumed_formulas)...))
        end
    end
end
# TODO unique function for join_antecedents and combine_antecedents
function combine_antecedents(antformula, f, use_leftmostlinearform, force_syntaxtree)
    # @show use_leftmostlinearform, force_syntaxtree
    if use_leftmostlinearform
        _subantformulas = (f isa LeftmostLinearForm ? SoleLogics.grandchildren(f) : [f])
        # @show _subantformulas
        subantformulas = filter(!=(⊤), _subantformulas)
        force_syntaxtree ? tree(antformula) : antformula
        lf = LeftmostConjunctiveForm([antformula, subantformulas...])
        φ2 = force_syntaxtree ? tree(lf) : lf
        # @show φ2
        φ2
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
        SoleData.scalar_simplification(φ; silent = true)
    else
        # @show φ
        # @show SoleData.scalar_simplification(φ; silent = true, scalar_simplification...)
        SoleData.scalar_simplification(φ; silent = true, scalar_simplification...)
    end
end

############################################################################################
############################################################################################
############################################################################################

"""
    listrules(
        m::AbstractModel;
        use_shortforms::Bool = true,
        use_leftmostlinearform::Union{Nothing,Bool} = nothing,
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

See also [`AbstractModel`](@ref), [`SoleLogics.CONJUNCTION`](@ref), [`joinrules`](@ref),
[`listimmediaterules`](@ref), [`LeafModel`](@ref).
"""
function listrules(
    m;
    compute_metrics::Union{Nothing,Bool} = false,
    metrics_kwargs::NamedTuple = (;),
    #
    use_shortforms::Bool = true,
    use_leftmostlinearform::Union{Nothing,Bool} = nothing,
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
    @assert issymbolicmodel(m) "Model m is not symbolic. Please provide method issymbolicmodel(::$(typeof(m)))."

    # if isnothing(compute_metrics)
    #     compute_metrics = (!isnothing(min_confidence) || !isnothing(min_coverage) || !isnothing(min_ncovered) || !isnothing(min_ninstances) || !isnothing(min_lift))
    # end

    rules = _listrules(m; subkwargs...)

    if compute_metrics || !isnothing(min_confidence) || !isnothing(min_coverage) || !isnothing(min_ncovered) || !isnothing(min_ninstances) || !isnothing(min_lift)
        rules = Iterators.filter(r->begin
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
    
    rules = collect(rules) # TODO remove in the future?

    return rules
end

function _listrules(m::AbstractModel; kwargs...)
    error("Please, provide method _listrules(::$(typeof(m))) ($(typeof(m)) is a symbolic model).")
end

_listrules(m::LeafModel{O}; kwargs...) where {O} = [Rule{O}(⊤, m, info(m))]

function _listrules(
    m::Rule{O};
    use_leftmostlinearform::Union{Nothing,Bool} = nothing,
    force_syntaxtree::Bool = false,
    kwargs...
) where {O}
    use_leftmostlinearform = !isnothing(use_leftmostlinearform) ? use_leftmostlinearform : false
    [begin
        φ = combine_antecedents(antecedent(m), antecedent(subrule), use_leftmostlinearform, force_syntaxtree)
        Rule{O}(φ, consequent(subrule), info(subrule))
    end for subrule in _listrules(consequent(m); force_syntaxtree = force_syntaxtree, use_leftmostlinearform = use_leftmostlinearform, kwargs...)]
end

function _listrules(
    m::Branch{O};
    use_shortforms::Bool = true,
    use_leftmostlinearform::Union{Nothing,Bool} = nothing,
    normalize::Bool = false,
    normalize_kwargs::NamedTuple = (; allow_atom_flipping = true, rotate_commutatives = false, ),
    scalar_simplification::Union{Bool,NamedTuple} = normalize ? (; allow_scalar_range_conditions = true) : false,
    force_syntaxtree::Bool = false,
    min_confidence::Union{Nothing,Number} = nothing,
    min_coverage::Union{Nothing,Number} = nothing,
    min_ninstances::Union{Nothing,Number} = nothing,
    kwargs...,
) where {O}
    use_leftmostlinearform = !isnothing(use_leftmostlinearform) ? use_leftmostlinearform : (antecedent(m) isa SoleLogics.AbstractSyntaxStructure) # TODO default to true

    subkwargs = (;
        use_shortforms = use_shortforms,
        use_leftmostlinearform = use_leftmostlinearform,
        normalize = false,
        normalize_kwargs = normalize_kwargs,
        scalar_simplification = false,
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
                        φ = combine_antecedents(antformula, antecedent(subrule), use_leftmostlinearform, force_syntaxtree)
                        # @show 3
                        # @show φ
                        φ
                    end
                end
                normalize && (ant = SoleLogics.normalize(ant; normalize_kwargs...))
                # @show ant
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
    # use_leftmostlinearform::Union{Nothing,Bool} = nothing,
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
        # kwargs...
    )
    return rules
end

_listrules(m::DecisionTree; kwargs...) = _listrules(root(m); kwargs...)

function _listrules(
    m::DecisionEnsemble;
    # weights::Union{Nothing, AbstractVector} = nothing,
    suppress_parity_warning = true,
    kwargs...
)
    # error("TODO check method & implement more efficient strategies for specific cases.")
    modelrules = [_listrules(subm; kwargs...) for subm in models(m)]
    @assert all(r->consequent(r) isa ConstantModel, Iterators.flatten(modelrules))

    IterTools.imap(rulecombination->begin
        rulecombination = collect(rulecombination)
        ant = join_antecedents(antecedent.(rulecombination))
        o_cons = bestguess(outcome.(consequent.(rulecombination)), m.weights; suppress_parity_warning)
        i_cons = merge(info.(consequent.(rulecombination))...)
        cons = ConstantModel(o_cons, i_cons)
        infos = merge(info.(rulecombination)...)
        Rule(ant, cons, infos)
        end, Iterators.product(modelrules...)
    )
end

_listrules(m::MixedModel; kwargs...) = _listrules(root(m); kwargs...)

############################################################################################
############################################################################################
############################################################################################

function joinrules(
    m::AbstractModel,
    silent = false...;
    kwargs...
)
    return joinrules(listrules(m; kwargs...), silent)
end

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
    rules,
    silent = false...,
)
    # !Base.isiterable(typeof(rules)) || error("Unexpected ruleset encountered, type: $(typeof(rules)).")
    rules = collect(rules)
    @assert all(c->c isa ConstantModel, consequent.(rules))
    alloutcomes = unique(outcome.(consequent.(rules)))
    # @show info.(rules)
    # @show info.(consequent.(rules))
    return [begin
        these_rules = filter(r->outcome(consequent(r)) == _outcome, rules)
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
        newcons = ConstantModel(_outcome, leafinfo)
        # newcons = deepcopy(_outcome)
        # TODO bring back!!!
        # @show info(newcons)
        # @show leafinfo
        # info!(newcons, leafinfo)
        Rule(newant, newcons, ruleinfo)
    end for _outcome in alloutcomes]
end
