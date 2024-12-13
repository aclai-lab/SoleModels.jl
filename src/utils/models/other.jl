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
################################### DecisionTree ###########################################
############################################################################################

"""
    struct DecisionTree{O} <: AbstractModel{O}
        root::M where {M<:Union{LeafModel{O},Branch{O}}}
        info::NamedTuple
    end

[`DecisionTree`](@ref) wraps a constrained sub-tree of [`Branch`](@ref) and
[`LeafModel`](@ref).

In other words, a [`DecisionTree`](@ref) is a symbolic model that operates as a nested
structure of IF-THEN-ELSE blocks:

    IF (antecedent_1) THEN
        IF (antecedent_2) THEN
            (consequent_1)
        ELSE
            (consequent_2)
        END
    ELSE
        IF (antecedent_3) THEN
            (consequent_3)
        ELSE
            (consequent_4)
        END
    END

where the [`antecedent`](@ref)s are formulas to be, and the [`consequent`](@ref)s are the
feasible local outcomes of the block.

!!!note
    Note that this structure also includes an `info::NamedTuple` for storing additional
    information.

See also [`Branch`](@ref), [`DecisionList`](@ref), [`DecisionForest`](@ref),
[`LeafModel`](@ref), [`MixedModel`](@ref).
"""
struct DecisionTree{O} <: AbstractModel{O}
    root::M where {M<:Union{LeafModel{O},Branch{O}}}
    info::NamedTuple

    # function DecisionTree{O}(
    #     root::Union{LeafModel,Branch},
    #     info::NamedTuple = (;),
    # )
    #     new{O}(root, info)
    # end

    function DecisionTree(
        root::Union{LeafModel{O},Branch{O}},
        info::NamedTuple = (;),
    ) where {O}
        new{O}(root, info)
    end

    function DecisionTree(
        root::Any,
        info::NamedTuple = (;),
    )
        root = wrap(root)
        M = typeof(root)
        O = outcometype(root)
        @assert M <: Union{LeafModel{O},Branch{O}} "" *
            "Cannot instantiate DecisionTree{$(O)}(...) with root of " *
            "type $(typeof(root)). Note that the should be either a LeafModel or a " *
            "Branch. " *
            "$(M) <: $(Union{LeafModel,Branch{<:O}}) should hold."
        new{O}(root, info)
    end

    function DecisionTree(
        antecedent::Formula,
        posconsequent::Any,
        negconsequent::Any,
        info::NamedTuple = (;),
    )
        posconsequent isa DecisionTree && (posconsequent = root(posconsequent))
        negconsequent isa DecisionTree && (negconsequent = root(negconsequent))
        return DecisionTree(Branch(antecedent, posconsequent, negconsequent, info))
    end
end

"""
    root(m::DecisionTree)

Return the `root` of the tree `m`.

See also [`DecisionTree`](@ref).
"""
root(m::DecisionTree) = m.root

iscomplete(::DecisionTree) = true

function apply(
    m::DecisionTree,
    i::AbstractInterpretation;
    kwargs...
)
    preds = apply(root(m), i; kwargs...)
    __apply_post(m, preds)
end

# Don't join (dispatch ambiguities)
function apply(
    m::DecisionTree,
    d::AbstractInterpretationSet;
    kwargs...
)
    preds = apply(root(m), d; kwargs...)
    __apply_post(m, preds)
end


function apply!(
    m::DecisionTree,
    d::AbstractInterpretationSet,
    y::AbstractVector;
    mode = :replace,
    leavesonly = false,
    kwargs...
)
    y = __apply_pre(m, d, y)
    # _d = SupportedLogiset(d) TODO?
    preds = apply!(root(m), d, y;
        mode = mode,
        leavesonly = leavesonly,
        kwargs...
    )
    return __apply!(m, mode, preds, y, leavesonly)
end

"""
    function nnodes(m::DecisionTree)

Return the number of nodes in `m`.

See also [`DecisionTree`](@ref).
"""
function nnodes(m::DecisionTree)
    nsubmodels(m)
end

"""
    function nleaves(m::DecisionTree)

Return the number of leaves in `m`.

See also [`DecisionTree`](@ref).
"""
function nleaves(m::DecisionTree)
    nleafmodels(m)
end

"""
    function height(m::DecisionTree)

Return the height of `m`.

See also [`DecisionTree`](@ref).
"""
function height(m::DecisionTree)
    subtreeheight(m)
end

immediatesubmodels(m::DecisionTree) = immediatesubmodels(root(m))
nimmediatesubmodels(m::DecisionTree) = nimmediatesubmodels(root(m))
listimmediaterules(m::DecisionTree) = listimmediaterules(root(m))

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
        DecisionSet{O}(rules, iscomplete, isnonoverlapping, info)
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

############################################################################################
##################################### MixedModel ###########################################
############################################################################################

"""
    struct MixedModel{O,FM<:AbstractModel} <: AbstractModel{O}
        root::M where {M<:AbstractModel{<:O}}
        info::NamedTuple
    end

A [`MixedModel`](@ref) is a wrapper of multiple [`AbstractModel`](@ref)s such as
[`Rule`](@ref)s, [`Branch`](@ref)s, [`DecisionList`](@ref)s, [`DecisionTree`](@ref).

In other words, a [`MixedModel`](@ref) is a symbolic model that operates as a free nested
structure of IF-THEN-ELSE and IF-ELSEIF-ELSE blocks:

    IF (antecedent_1) THEN
        IF (antecedent_1)     THEN (consequent_1)
        ELSEIF (antecedent_2) THEN (consequent_2)
        ELSE (consequent_1_default) END
    ELSE
        IF (antecedent_3) THEN
            (consequent_3)
        ELSE
            (consequent_4)
        END
    END

where the [`antecedent`](@ref)s are formulas to be checked, and the [`consequent`](@ref)s
are the feasible local outcomes of the block.

!!! note
    Note that `FM` refers to the Feasible Models (`FM`) allowed in the model's sub-tree.

See also [`AbstractModel`](@ref), [`Branch`](@ref)s, [`DecisionList`](@ref)s,
[`DecisionTree`](@ref), [`Rule`](@ref)s.
"""
struct MixedModel{O,FM<:AbstractModel} <: AbstractModel{O}
    root::M where {M<:AbstractModel{<:O}}
    info::NamedTuple

    function MixedModel{O,FM}(
        root::AbstractModel{<:O},
        info::NamedTuple = (;)
    ) where {O,FM<:AbstractModel}
        root = wrap(root)
        subm = submodels(root)
        wrong_subm = filter(m->!(m isa FM), subm)
        @assert length(wrong_subm) == 0 "$(length(wrong_subm))/$(length(subm)) " *
            "submodels break the type " *
            "constraint on the model sub-tree! All models should be of type $(FM)," *
            "but models were found of types: $(unique(typeof.(subm)))."
        new{O,FM}(root, info)
    end

    function MixedModel(
        root::Any,
        info::NamedTuple = (;)
    )
        root = wrap(root)
        subm = submodels(root)
        O = outcometype(root)
        FM = Union{typeof.(subm)...}
        new{O,FM}(root, info)
    end
end

"""
    root(m::MixedModel)

Return the `root` of model `m`.

See also [`MixedModel`](@ref).
"""
root(m::MixedModel) = m.root

iscomplete(::MixedModel) = iscomplete(root)

immediatesubmodels(m::MixedModel) = immediatesubmodels(root(m))
nimmediatesubmodels(m::MixedModel) = nimmediatesubmodels(root(m))
listimmediaterules(m::MixedModel) = listimmediaterules(root(m))

function apply(
    m::MixedModel,
    id::Union{AbstractInterpretation,AbstractInterpretationSet};
    kwargs...
)
    apply(root(m), id; kwargs...)
end



