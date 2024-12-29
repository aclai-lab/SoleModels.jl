import Base: convert, length, getindex

using SoleData: slicedataset

import SoleLogics: check, syntaxstring
using SoleLogics: LeftmostLinearForm, LeftmostConjunctiveForm, LeftmostDisjunctiveForm

import SoleLogics: nleaves, height

############################################################################################
################################### DecisionList ###########################################
############################################################################################

"""
    struct DecisionList{O} <: AbstractModel{O}
        rulebase::Vector{Rule{_O} where {_O<:O}}
        defaultconsequent::M where {M<:AbstractModel{<:O}}
        info::NamedTuple
    end

A `DecisionList` (or *decision table*, or *rule-based model*) is a symbolic model that
has the semantics of an IF-ELSEIF-ELSE block:

    IF (antecedent_1)     THEN (consequent_1)
    ELSEIF (antecedent_2) THEN (consequent_2)
    ...
    ELSEIF (antecedent_n) THEN (consequent_n)
    ELSE (consequent_default) END

where the [`antecedent`](@ref)s are formulas to be, and the [`consequent`](@ref)s are the
feasible local outcomes of the block.

Using the classical semantics, the [`antecedent`](@ref)s are evaluated in order, and a
[`consequent`](@ref) is returned as soon as a valid antecedent is found, or when the
computation reaches the ELSE clause.

See also [`AbstractModel`](@ref), [`DecisionTree`](@ref), [`Rule`](@ref).
"""
struct DecisionList{O} <: AbstractModel{O}
    rulebase::Vector{Rule{_O} where {_O<:O}}
    defaultconsequent::M where {M<:AbstractModel{<:O}}
    info::NamedTuple

    function DecisionList(
        rulebase::Vector{<:Rule},
        defaultconsequent::Any,
        info::NamedTuple = (;),
    )
        defaultconsequent = wrap(defaultconsequent)
        O = Union{outcometype(defaultconsequent),outcometype.(rulebase)...}
        new{O}(rulebase, defaultconsequent, info)
    end
end

"""
    rulebase(m::DecisionList)

Return the rulebase of `m`.

See also [`DecisionList`](@ref), [`Rule`](@ref).
"""
rulebase(m::DecisionList) = m.rulebase

"""
    defaultconsequent(m::DecisionList)

Return the default [`consequent`](@ref) of `m`.

!!! note
    The returned model is complete if and only if `m` is complete.
    See also [`iscomplete`](@ref).

See also [`AbstractModel`](@ref), [`DecisionList`](@ref), [`Rule`](@ref).
"""
defaultconsequent(m::DecisionList) = m.defaultconsequent

iscomplete(m::DecisionList) = iscomplete(defaultconsequent(m))

immediatesubmodels(m::DecisionList) = [rulebase(m)..., defaultconsequent(m)]
nimmediatesubmodels(m::DecisionList) = length(rulebase(m)) + 1
function listimmediaterules(
    m::DecisionList{O};
    # use_shortforms::Bool = true,
    # use_leftmostlinearform::Union{Nothing,Bool} = nothing,
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

function apply(
    m::DecisionList,
    i::AbstractInterpretation;
    check_args::Tuple = (),
    check_kwargs::NamedTuple = (;),
)
    for rule in rulebase(m)
        if checkantecedent(rule, i, check_args...; check_kwargs...)
            return consequent(rule)
        end
    end
    defaultconsequent(m)
end

function apply(
    m::DecisionList{O},
    d::AbstractInterpretationSet;
    check_args::Tuple = (),
    check_kwargs::NamedTuple = (;),
) where {O}
    nsamp = ninstances(d)
    preds = Vector{O}(undef, nsamp)
    uncovered_idxs = 1:nsamp

    for rule in rulebase(m)
        length(uncovered_idxs) == 0 && break

        uncovered_d = slicedataset(d, uncovered_idxs; return_view = true)

        idxs_sat = findall(
            checkantecedent(rule, uncovered_d, check_args...; check_kwargs...)
        )
        idxs_sat = uncovered_idxs[idxs_sat]
        uncovered_idxs = setdiff(uncovered_idxs, idxs_sat)

        foreach((i)->(preds[i] = outcome(consequent(rule))), idxs_sat)
    end

    length(uncovered_idxs) != 0 &&
        foreach((i)->(preds[i] = outcome(defaultconsequent(m))), uncovered_idxs)

    return preds
end

function apply!(
    m::DecisionList{O},
    d::AbstractInterpretationSet,
    y::AbstractVector;
    mode = :replace,
    leavesonly = false,
    show_progress = false, # length(rulebase(m)) > 15,
    kwargs...
) where {
    O
}
    # @assert length(y) == ninstances(d) "$(length(y)) == $(ninstances(d))"
    if mode == :replace
        recursivelyemptysupports!(m, leavesonly)
        mode = :append
    end
    nsamp = ninstances(d)
    preds = Vector{outputtype(m)}(undef,nsamp)
    uncovered_idxs = 1:nsamp

    if show_progress
        p = Progress(length(rulebase(m)); dt = 1, desc = "Applying list...")
    end

    for subm in [rulebase(m)..., defaultconsequent(m)]
        length(uncovered_idxs) == 0 && break

        uncovered_d = slicedataset(d, uncovered_idxs; return_view = true)

        # @show length(uncovered_idxs)
        cur_preds = apply!(subm, uncovered_d, y[uncovered_idxs], mode = mode, leavesonly = leavesonly, kwargs...)
        idxs_sat = findall(!isnothing, cur_preds)
        # @show cur_preds[idxs_sat]
        preds[uncovered_idxs[idxs_sat]] .= cur_preds[idxs_sat]
        uncovered_idxs = setdiff(uncovered_idxs, uncovered_idxs[idxs_sat])

        !show_progress || next!(p)
    end

    return preds
end

#TODO write in docstring that possible values for compute_metrics are: :append, true, false
function _apply!(
    m::DecisionList{O},
    d::AbstractInterpretationSet;
    check_args::Tuple = (),
    check_kwargs::NamedTuple = (;),
    compute_metrics::Union{Symbol,Bool} = false,
) where {
    O
}
    nsamp = ninstances(d)
    pred = Vector{O}(undef, nsamp)
    delays = Vector{Integer}(undef, nsamp)
    uncovered_idxs = 1:nsamp
    rules = rulebase(m)

    for (n, rule) in enumerate(rules)
        length(uncovered_idxs) == 0 && break

        uncovered_d = slicedataset(d, uncovered_idxs; return_view = true)

        idxs_sat = findall(
            checkantecedent(rule, uncovered_d, check_args...; check_kwargs...)
        )
        idxs_sat = uncovered_idxs[idxs_sat]
        uncovered_idxs = setdiff(uncovered_idxs, idxs_sat)

        delays[idxs_sat] .= (n-1)
        map((i)->(pred[i] = outcome(consequent(rule))), idxs_sat)
    end

    if length(uncovered_idxs) != 0
        map((i)->(pred[i] = outcome(defaultconsequent(m))), uncovered_idxs)
        length(rules) == 0 ? (delays .= 0) : (delays[uncovered_idxs] .= length(rules))
    end

    (length(rules) != 0) && (delays = delays ./ length(rules))

    iprev = info(m)
    inew = compute_metrics == false ? iprev : begin
        if :delays ∉ keys(iprev)
            merge(iprev, (; delays = delays))
        else
            prev = iprev[:delays]
            ntwithout = (; [p for p in pairs(nt) if p[1] != :delays]...)
            if compute_metrics == :append
                merge(ntwithout,(; delays = [prev..., delays...]))
            elseif compute_metrics == true
                merge(ntwithout,(; delays = delays))
            end
        end
    end

    inewnew = begin
        if :pred ∉ keys(inew)
            merge(inew, (; pred = pred))
        else
            prev = inew[:pred]
            ntwithout = (; [p for p in pairs(nt) if p[1] != :pred]...)
            if compute_metrics == :append
                merge(ntwithout,(; pred = [prev..., pred...]))
            elseif compute_metrics == true
                merge(ntwithout,(; pred = pred))
            end
        end
    end

    return DecisionList(rules, defaultconsequent(m), inewnew)
end

############################################################################################
################################### DecisionSet ############################################
############################################################################################


"""
    struct DecisionSet{O} <: AbstractModel{O}

A `DecisionSet` is a symbolic model that wraps a set of final rules.
A `DecisionSet` is non-overlapping (`isnonoverlapping`) if all rules are mutually exclusive,
and is complete (`iscomplete`) if all rules jointly exaustive.
Any symbolic model can be transformed into a non-overlapping DecisionSet (via [`ruleset`](@ref)),
and if the starting model is complete, then also the resulting decision set is complete.

If the model is non-overlapping, then at most one rule applies to any given an logical interpretation.
If the model is complete, then at least one rule applies to any given an logical interpretation.

TODO how are racing cases handled???

See also [`AbstractModel`](@ref), [`DecisionSet`](@ref), [`Rule`](@ref).
"""
struct DecisionSet{O} <: AbstractModel{O}
    rules::Vector{Rule{_O} where {_O<:O}}
    isnonoverlapping::Bool
    iscomplete::Bool
    info::NamedTuple

    function DecisionSet{O}(
        rules::Vector{<:Rule},
        iscomplete::Bool = false,
        isnonoverlapping::Bool = false,
        info::NamedTuple = (;),
    ) where {O}
        new{O}(rules, iscomplete, isnonoverlapping, info)
    end

    function DecisionSet(
        rules::Vector{<:Rule},
        iscomplete::Bool = false,
        isnonoverlapping::Bool = false,
        info::NamedTuple = (;),
    )
        O = Union{outcometype.(rules)...}
        DecisionSet{O}(rules, iscomplete, isnonoverlapping, info)
    end

    function DecisionSet(
        model,
        args...; kwargs...
    )
        issymbolicmodel(model) || error("Cannot instantiate DecisionSet from non-symbolic model.")
        O = Union{outcometype.(rules)...}
        DecisionSet{O}(listrules(model), args...; kwargs...)
    end
end

rules(m::DecisionSet) = m.rules
nrules(m::DecisionSet) = length(rules(m))

iscomplete(m::DecisionSet) = m.iscomplete
isnonoverlapping(m::DecisionSet) = m.isnonoverlapping

function listrules(m::DecisionSet)
    isnonoverlapping || error("Cannot listrules from non-overlapping decision set. Try `extractrules` with heuristics, instead.")
    rules(m)
end

function apply(m::DecisionSet, interpretation::AbstractInterpretation, args...; kwargs...)
    for rule in rules(m)
        pred = apply(rule, interpretation, args...; kwargs...)
        isnothing(pred) || return consequent(rule)
    end
    return nothing
end

function apply!(m::DecisionSet, args...; kwargs...)
    map(r->apply!(r, args...; kwargs...), rules(m))
end

# Helper
ruleset(m::AbstractModel) = DecisionSet(listrules(m))
