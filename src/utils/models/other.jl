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
    id::Union{AbstractInterpretation,AbstractInterpretationSet};
    kwargs...
)
    preds = apply(root(m), id; kwargs...)
    if haskey(info(m), :apply_postprocess)
        apply_postprocess_f = info(m, :apply_postprocess)
        preds = apply_postprocess_f.(preds)
    end
    preds
end

"""
    function nnodes(t::DecisionTree)

Return the number of nodes in `t`.

See also [`DecisionTree`](@ref).
"""
function nnodes(t::DecisionTree)
    nsubmodels(t)
end

"""
    function nleaves(t::DecisionTree)

Return the number of leaves in `t`.

See also [`DecisionTree`](@ref).
"""
function nleaves(t::DecisionTree)
    nleafmodels(t)
end

"""
    function height(t::DecisionTree)

Return the height of `t`.

See also [`DecisionTree`](@ref).
"""
function height(t::DecisionTree)
    subtreeheight(t)
end

############################################################################################
################################## DecisionForest ##########################################
############################################################################################

"""
    struct DecisionForest{O} <: AbstractModel{O}
        trees::Vector{<:DecisionTree}
        info::NamedTuple
    end

A [`DecisionForest`](@ref) is a symbolic model that wraps an ensemble of
[`DecisionTree`](@ref).

See also [`DecisionList`](@ref), [`DecisionTree`](@ref), [`MixedModel`](@ref).
"""
struct DecisionForest{O} <: AbstractModel{O}
    trees::Vector{<:DecisionTree}
    info::NamedTuple

    function DecisionForest(
        trees::Vector{<:DecisionTree},
        info::NamedTuple = (;),
    )
        @assert length(trees) > 0 "Cannot instantiate forest with no trees!"
        O = Union{outcometype.(trees)...}
        new{O}(trees, info)
    end
end

"""
    trees(forest::DecisionForest)

Return all the [`DecisionTree`](@ref)s wrapped within `forest`.

See also [`DecisionTree`](@ref).
"""
trees(forest::DecisionForest) = forest.trees

# TODO check these two.
function apply(
    f::DecisionForest,
    id::AbstractInterpretation;
    kwargs...
)
    bestguess([apply(t, d; kwargs...) for t in trees(f)])
end

function apply(
    f::DecisionForest,
    d::AbstractInterpretationSet;
    suppress_parity_warning = false,
    kwargs...
)
    pred = hcat([apply(t, d; kwargs...) for t in trees(f)]...)
    return [
        bestguess(pred[i,:]; suppress_parity_warning = suppress_parity_warning)
        for i in 1:size(pred,1)
    ]
end

"""
    function nnodes(f::DecisionForest)

Return the number of nodes within `f`, that is, the sum of the nodes number in each
wrapped [`DecisionTree`](@ref).

See also [`DecisionForest`](@ref), [`DecisionTree`](@ref).
"""
function nnodes(f::DecisionForest)
    nsubmodels(f)
end

"""
    function nleaves(f::DecisionForest)

Return the number of [`LeafModel`](@ref) within `f`.

See also [`DecisionForest`](@ref), [`DecisionTree`](@ref), [`LeafModel`](@ref).
"""
function nleaves(f::DecisionForest)
    nleafmodels(f)
end

"""
    function height(f::DecisionForest)

Return the maximum height across all the [`DecisionTree`](@ref)s within `f`.

See also [`DecisionForest`](@ref), [`DecisionTree`](@ref).
"""
function height(f::DecisionForest)
    subtreeheight(f)
end

"""
    function ntrees(f::DecisionForest)

Return the number of trees within `f`.

See also [`DecisionForest`](@ref), [`DecisionTree`](@ref), [`trees`](@ref).
"""
function ntrees(f::DecisionForest)
    length(trees(f))
end

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

function apply(
    m::MixedModel,
    id::Union{AbstractInterpretation,AbstractInterpretationSet};
    kwargs...
)
    apply(root(m), id; kwargs...)
end
