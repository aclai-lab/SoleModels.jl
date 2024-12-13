# These are actually unneccessary, add no value, and bring burdens to the package.

# Problem: They only exist to wrap a root node, and inform the user
# about the nature of the models within the underlying tree structure. For example, if m is 
#  a DecisionTree, then the user will know that submodels(m) <: Union{LeafModel,Branch}.

# Maybe a more clever way to do this is to have a struct that wraps a root node, and a supertype
#  of all underlying models?

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



