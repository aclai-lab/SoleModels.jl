import Base: convert, length, getindex, isopen

using SoleData: slicedataset

import SoleLogics: check, syntaxstring, conjuncts, nconjuncts, disjuncts, ndisjuncts
using SoleLogics: LeftmostLinearForm, LeftmostConjunctiveForm, LeftmostDisjunctiveForm

import SoleLogics: nleaves, height

############################################################################################
################################### ConstantModel ##########################################
############################################################################################

"""
    struct ConstantModel{O} <: LeafModel{O}
        outcome::O
        info::NamedTuple
    end

The simplest type of model is the `ConstantModel`;
it is a [`LeafModel`](@ref) that always outputs the same outcome.

# Examples
```julia-repl
julia> cm = ConstantModel(2);
julia> outcome(cm)
2
```

See also [`apply`](@ref), [`LeafModel`](@ref)."""
struct ConstantModel{O} <: LeafModel{O}
    outcome::O
    info::NamedTuple

    function ConstantModel{O}(
        outcome::O2,
        info::NamedTuple = (;),
    ) where {O,O2}
        new{O}(convert(O, outcome), info)
    end

    function ConstantModel(
        outcome::O,
        info::NamedTuple = (;),
    ) where {O}
        ConstantModel{O}(outcome, info)
    end

    function ConstantModel{O}(m::ConstantModel) where {O}
        ConstantModel{O}(m.outcome, m.info)
    end

    function ConstantModel(m::ConstantModel)
        ConstantModel(m.outcome, m.info)
    end
end

"""
    outcome(m::ConstantModel)

Getter for the constant outcome wrapped by `m`.

See also [`ConstantModel`](@ref).
"""
outcome(m::ConstantModel) = m.outcome

isopen(::ConstantModel) = false

apply(m::ConstantModel, i::AbstractInterpretation; kwargs...) = outcome(m)
apply(
    m::ConstantModel,
    d::AbstractInterpretationSet,
    i_instance::Integer;
    kwargs...
) = outcome(m)
apply(
    m::ConstantModel,
    d::AbstractInterpretationSet;
    kwargs...
) = Fill(outcome(m), ninstances(d))

wrap(o::O) where {O} = convert(ConstantModel{O}, o)

convert(::Type{ConstantModel{O}}, o::O) where {O} = ConstantModel{O}(o)
convert(::Type{<:AbstractModel{F}}, m::ConstantModel) where {F} = ConstantModel{F}(m)

############################################################################################
################################### FunctionModel ##########################################
############################################################################################

"""
    struct FunctionModel{O} <: LeafModel{O}
        f::FunctionWrapper{O}
        info::NamedTuple
    end

A `FunctionModel` is a `LeafModel` that applies a native Julia `Function` in order to
compute the outcome.

!!! warning
    Over efficiency concerns, it is mandatory to make explicit the output type `O` by
    wrapping the `Function` into an object of type `FunctionWrapper{O}`
    (see [FunctionWrappers](https://github.com/yuyichao/FunctionWrappers.jl).

See also [`LeafModel`](@ref).
"""
struct FunctionModel{O} <: LeafModel{O}
    f::FunctionWrapper{O}
    info::NamedTuple

    function FunctionModel{O}(
        f::FunctionWrapper{O},
        info::NamedTuple = (;),
    ) where {O}
        new{O}(f, info)
    end

    function FunctionModel(
        f::FunctionWrapper{O},
        info::NamedTuple = (;),
    ) where {O}
        FunctionModel{O}(f, info)
    end

    function FunctionModel{O}(
        f::Function,
        info::NamedTuple = (;);
        silent = false
    ) where {O}
        # TODO fix warning
        if !silent
            @warn "Over efficiency concerns, please consider wrapping " *
            "Julia Function's into FunctionWrapper{O,Tuple{T}} structures " *
            "where T<:SoleModels.AbstractInterpretation is the interpretation type."
        end
        f = FunctionWrapper{O,Tuple{AbstractInterpretation}}(f)
        FunctionModel{O}(f, info)
    end

    function FunctionModel(
        f::Function,
        info::NamedTuple = (;),
    )
        FunctionModel{Any}(f, info)
    end

    function FunctionModel{O}(m::FunctionModel) where {O}
        FunctionModel{O}(m.f, m.info)
    end

    function FunctionModel(m::FunctionModel)
        FunctionModel(m.f, m.info)
    end
end

"""
    f(m::FunctionModel)

Getter for the `FunctionWrapper` within `m`.

See also [`FunctionModel`](@ref),
[FunctionWrappers](https://github.com/yuyichao/FunctionWrappers.jl).
"""
f(m::FunctionModel) = m.f

isopen(::FunctionModel) = false

function apply(
    m::FunctionModel,
    i::AbstractInterpretation;
    functional_models_gets_single_instance::Bool = false,
    functional_args::Tuple = (),
    functional_kwargs::NamedTuple = (;),
    kwargs...,
)
    @assert functional_models_gets_single_instance
    f(m)(i, functional_args...; functional_kwargs...)
end
function apply(
    m::FunctionModel,
    d::AbstractInterpretationSet,
    i_instance::Integer;
    functional_models_gets_single_instance::Bool = false,
    functional_args::Tuple = (),
    functional_kwargs::NamedTuple = (;),
    kwargs...,
)
    if functional_models_gets_single_instance
        interpretation = get_instance(d, i_instance)
        f(m)(interpretation, functional_args...; functional_kwargs...)
    else
        f(m)(d, i_instance, functional_args...; functional_kwargs...)
    end
end

convert(::Type{<:AbstractModel{F}}, m::FunctionModel) where {F} = FunctionModel{F}(m)

wrap(o::Function) = FunctionModel(o)
wrap(o::FunctionWrapper{O}) where {O} = FunctionModel{O}(o)

############################################################################################
####################################### Rule ###############################################
############################################################################################

# this is never used
doc_symbolic_basics = """
Symbolic modeling builds onto two basic building blocks, which are `AbstractModel`s
themselves:
- `Rule`: IF (antecedent) THEN (consequent) END
- `Branch`: IF (antecedent) THEN (posconsequent) ELSE (negconsequent) END
The *antecedent* is a formula of a certain logic, that can typically evaluate to true or
false when the model is applied on an instance object;
the *consequent*s are `AbstractModel`s themselves, that are to be applied to the instance
object in order to obtain an outcome.
"""

"""
    struct Rule{O} <: AbstractModel{O}
        antecedent::Formula
        consequent::M where {M<:AbstractModel{<:O}}
        info::NamedTuple
    end

A `Rule` is one of the fundamental building blocks of symbolic modeling, and has
the semantics:

    IF (antecedent) THEN (consequent) END

where the [`antecedent`](@ref) is a formula to be checked, and the [`consequent`](@ref) is
the local outcome of the block.

# Examples
```julia-repl

```

See also [`AbstractModel`](@ref). [`antecedent`](@ref), [`consequent`](@ref),
`SoleLogics.Formula`.
"""
struct Rule{O} <: AbstractModel{O}
    antecedent::Formula
    consequent::M where {M<:AbstractModel{<:O}}
    info::NamedTuple

    function Rule{O}(
        antecedent::Formula,
        consequent::Any,
        info::NamedTuple = (;),
    ) where {O}
        consequent = wrap(consequent, AbstractModel{O})
        new{O}(antecedent, consequent, info)
    end

    function Rule(
        antecedent::Formula,
        consequent::Any,
        info::NamedTuple = (;),
    )
        consequent = wrap(consequent)
        O = outcometype(consequent)
        Rule{O}(antecedent, consequent, info)
    end

    function Rule(
        consequent::Any,
        info::NamedTuple = (;),
    )
        antecedent = ⊤
        consequent = wrap(consequent)
        O = outcometype(consequent)
        Rule{O}(antecedent, consequent, info)
    end
end

"""
    antecedent(m::Union{Rule,Branch})::Formula

Return the antecedent of a rule/branch,
that is, the formula to be checked upon applying the model.

See also
[`apply`](@ref),
[`consequent`](@ref),
[`checkantecedent`](@ref),
[`Rule`](@ref),
[`Branch`](@ref).
"""
antecedent(m::Rule) = m.antecedent

"""
    consequent(m::Rule)::AbstractModel

Return the consequent of a rule.

See also
[`antecedent`](@ref),
[`Rule`](@ref).
"""
consequent(m::Rule) = m.consequent

"""
    checkantecedent(
        m::Union{Rule,Branch},
        args...;
        kwargs...
    )
        check(antecedent(m), args...; kwargs...)
    end

Simply check the antecedent of a rule on an instance or dataset.

See also
[`antecedent`](@ref),
[`Rule`](@ref),
[`Branch`](@ref).
"""
function checkantecedent end

function apply(
    m::Rule,
    i::AbstractInterpretation;
    check_args::Tuple = (),
    check_kwargs::NamedTuple = (;),
    kwargs...
)
    if checkantecedent(m, i, check_args...; check_kwargs...)
        apply(consequent(m), i;
            check_args = check_args,
            check_kwargs = check_kwargs,
            kwargs...
        )
    else
        nothing
    end
end

function apply(
    m::Rule,
    d::AbstractInterpretationSet,
    i_instance::Integer;
    check_args::Tuple = (),
    check_kwargs::NamedTuple = (;),
    kwargs...
)
    if checkantecedent(m, d, i_instance, check_args...; check_kwargs...)
        apply(consequent(m), d, i_instance;
            check_args = check_args,
            check_kwargs = check_kwargs,
            kwargs...
        )
    else
        nothing
    end
end


# Helpers
# TODO remove probably
function conjuncts(m::Rule)
    @assert antecedent(m) isa LeftmostConjunctiveForm
    conjuncts(antecedent(m))
end
function nconjuncts(m::Rule)
    @assert antecedent(m) isa LeftmostConjunctiveForm
    nconjuncts(antecedent(m))
end
function disjuncts(m::Rule)
    @assert antecedent(m) isa LeftmostDisjunctiveForm
    disjuncts(antecedent(m))
end
function ndisjuncts(m::Rule)
    @assert antecedent(m) isa LeftmostDisjunctiveForm
    ndisjuncts(antecedent(m))
end

# Helper: slice a Rule's antecedent
# TODO remove?
function Base.getindex(
    m::Rule{O},
    idxs::AbstractVector,
) where {O}
    a = antecedent(m)
    @assert a isa LeftmostLinearForm "Cannot slice Rule with antecedent of type $(a)"
    Rule{O}(typeof(a)(children(a)[idxs]), consequent(m))
end


############################################################################################

"""
    struct Branch{O} <: AbstractModel{O}
        antecedent::Formula
        posconsequent::M where {M<:AbstractModel{<:O}}
        negconsequent::M where {M<:AbstractModel{<:O}}
        info::NamedTuple
    end

A `Branch` is one of the fundamental building blocks of symbolic modeling, and has
the semantics:

    IF (antecedent) THEN (positive consequent) ELSE (negative consequent) END

where the antecedent is a formula to be checked and the consequents are the feasible
local outcomes of the block. If checking the antecedent evaluates to the top of the algebra,
then the positive consequent is applied; otherwise, the negative consequenti is applied.


See also
[`antecedent`](@ref),
[`posconsequent`](@ref),
[`negconsequent`](@ref),
[`SoleLogics.check`](@ref),
[`SoleLogics.Formula`](@ref),
[`Rule`](@ref), [`AbstractModel`](@ref).
"""
struct Branch{O} <: AbstractModel{O}
    antecedent::Formula
    posconsequent::M where {M<:AbstractModel{<:O}}
    negconsequent::M where {M<:AbstractModel{<:O}}
    info::NamedTuple

    function Branch(
        antecedent::Formula,
        posconsequent::Any,
        negconsequent::Any,
        info::NamedTuple = (;),
    )
        A = typeof(antecedent)
        posconsequent = wrap(posconsequent)
        negconsequent = wrap(negconsequent)
        O = Union{outcometype(posconsequent),outcometype(negconsequent)}
        new{O}(antecedent, posconsequent, negconsequent, info)
    end

    function Branch(
        antecedent::Formula,
        (posconsequent, negconsequent)::Tuple{Any,Any},
        info::NamedTuple = (;),
    )
        Branch(antecedent, posconsequent, negconsequent, info)
    end

end

antecedent(m::Branch) = m.antecedent

"""
    posconsequent(m::Branch)::AbstractModel

Return the positive consequent of a branch;
that is, the model to be applied if the antecedent evaluates to `true`.

See also
[`antecedent`](@ref),
[`Branch`](@ref).
"""
posconsequent(m::Branch) = m.posconsequent

"""
    negconsequent(m::Branch)::AbstractModel

Return the negative consequent of a branch;
that is, the model to be applied if the antecedent evaluates to `false`.

See also
[`antecedent`](@ref),
[`Branch`](@ref).
"""
negconsequent(m::Branch) = m.negconsequent

isopen(m::Branch) = isopen(posconsequent(m)) || isopen(negconsequent(m))

function apply(
    m::Branch,
    i::AbstractInterpretation;
    check_args::Tuple = (),
    check_kwargs::NamedTuple = (;),
    kwargs...
)
    if checkantecedent(m, i, check_args...; check_kwargs...)
        apply(posconsequent(m), i;
            check_args = check_args,
            check_kwargs = check_kwargs,
            kwargs...
        )
    else
        apply(negconsequent(m), i;
            check_args = check_args,
            check_kwargs = check_kwargs,
            kwargs...
        )
    end
end

function apply(
    m::Branch,
    d::AbstractInterpretationSet,
    i_instance::Integer;
    check_args::Tuple = (),
    check_kwargs::NamedTuple = (;),
    kwargs...
)
    if checkantecedent(m, d, i_instance, check_args...; check_kwargs...)
        apply(posconsequent(m), d, i_instance;
            check_args = check_args,
            check_kwargs = check_kwargs,
            kwargs...
        )
    else
        apply(negconsequent(m), d, i_instance;
            check_args = check_args,
            check_kwargs = check_kwargs,
            kwargs...
        )
    end
end

function apply(
    m::Branch,
    d::AbstractInterpretationSet;
    check_args::Tuple = (),
    check_kwargs::NamedTuple = (;),
    kwargs...
)
    checkmask = checkantecedent(m, d, check_args...; check_kwargs...)
    preds = Vector{outputtype(m)}(undef,length(checkmask))
    preds[checkmask] .= apply(
        posconsequent(m),
        slicedataset(d, checkmask; return_view = true, allow_no_instances = true);
        check_args = check_args,
        check_kwargs = check_kwargs,
        kwargs...
    )
    preds[(!).(checkmask)] .= apply(
        negconsequent(m),
        slicedataset(d, (!).(checkmask); return_view = true, allow_no_instances = true);
        check_args = check_args,
        check_kwargs = check_kwargs,
        kwargs...
    )
    preds
end

# Helper: slice a Branch's antecedent
# TODO remove?
function Base.getindex(
    m::Branch{O},
    idxs::AbstractVector,
) where {O}
    a = antecedent(m)
    @assert a isa LeftmostLinearForm "Cannot slice Branch with antecedent of type $(a)"
    Branch{O}(typeof(a)(children(a)[idxs]), posconsequent(m), negconsequent(m))
end

############################################################################################
############################################################################################

checkantecedent(m::Union{Rule,Branch}, i::AbstractInterpretation, args...; kwargs...) = check(antecedent(m), i, args...; kwargs...)
checkantecedent(m::Union{Rule,Branch}, d::AbstractInterpretationSet, i_instance::Integer, args...; kwargs...) = check(antecedent(m), d, i_instance, args...; kwargs...)
checkantecedent(m::Union{Rule,Branch}, d::AbstractInterpretationSet, args...; kwargs...) = check(antecedent(m), d, args...; kwargs...)

# TODO remove:
# checkantecedent(::Union{Rule{O,Top},Branch{O,Top}}, i::AbstractInterpretation, args...; kwargs...) where {O} = true
# checkantecedent(::Union{Rule{O,Top},Branch{O,Top}}, d::AbstractInterpretationSet, i_instance::Integer, args...; kwargs...) where {O} = true
# checkantecedent(::Union{Rule{O,Top},Branch{O,Top}}, d::AbstractInterpretationSet, args...; kwargs...) where {O} = fill(true, ninstances(d))

############################################################################################
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

where the antecedents are formulas to be, and the consequents are the feasible
local outcomes of the block.
Using the classical semantics, the antecedents are evaluated in order,
and a consequent is returned as soon as a valid antecedent is found,
or when the computation reaches the ELSE clause.

See also
[`Rule`](@ref),
[`DecisionTree`](@ref),
[`AbstractModel`](@ref).
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

rulebase(m::DecisionList) = m.rulebase
defaultconsequent(m::DecisionList) = m.defaultconsequent

isopen(m::DecisionList) = isopen(defaultconsequent(m))

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

"""
A `DecisionTree` is a symbolic model that operates as a nested structure of
IF-THEN-ELSE blocks:

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

where the antecedents are formulas to be, and the consequents are the feasible
local outcomes of the block.

In practice, a `DecisionTree` simply wraps a constrained
sub-tree of `Branch` and `LeafModel`:

    struct DecisionTree{O} <: AbstractModel{O}
        root::M where {M<:AbstractModel}
        info::NamedTuple
    end

Note that this structure also includes an `info::NamedTuple` for storing additional
information.

See also [`MixedModel`](@ref), [`DecisionList`](@ref).
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

root(m::DecisionTree) = m.root

isopen(::DecisionTree) = false

# TODO join these two or note that they are kept separate due to possible dispatch ambiguities.
function apply(
    m::DecisionTree,
    #id::Union{AbstractInterpretation,AbstractInterpretationSet};
    id::AbstractInterpretation;
    kwargs...
)
    preds = apply(root(m), id; kwargs...)
    if haskey(info(m), :apply_postprocess)
        apply_postprocess_f = info(m, :apply_postprocess)
        preds = apply_postprocess_f.(preds)
    end
    preds
end

function apply(
    m::DecisionTree,
    d::AbstractInterpretationSet;
    kwargs...,
)
    preds = apply(root(m), d; kwargs...)
    if haskey(info(m), :apply_postprocess)
        apply_postprocess_f = info(m, :apply_postprocess)
        preds = apply_postprocess_f.(preds)
    end
    preds
end

function nnodes(t::DecisionTree)
    nsubmodels(t)
end

function nleaves(t::DecisionTree)
    nleafmodels(t)
end

function height(t::DecisionTree)
    subtreeheight(t)
end

############################################################################################

"""
A `Decision Forest` is a symbolic model that wraps an ensemble of models

    struct DecisionForest{O} <: AbstractModel{O}
        trees::Vector{<:DecisionTree}
        info::NamedTuple
    end


See also [`MixedModel`](@ref), [`DecisionList`](@ref),
[`DecisionTree`](@ref).
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
    return [bestguess(pred[i,:]; suppress_parity_warning = suppress_parity_warning) for i in 1:size(pred,1)]
end

function nnodes(f::DecisionForest)
    nsubmodels(f)
end

function nleaves(f::DecisionForest)
    nleafmodels(f)
end

function height(f::DecisionForest)
    subtreeheight(f)
end

############################################################################################
############################################################################################
############################################################################################

"""
A `MixedModel` is a symbolic model that operaters as a free nested structure of IF-THEN-ELSE
and IF-ELSEIF-ELSE blocks:

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

where the antecedents are formulas to be checked, and the consequents are the feasible
local outcomes of the block.

In Sole.jl, this logic can implemented using `AbstractModel`s such as
`Rule`s, `Branch`s, `DecisionList`s, `DecisionTree`s, and the be wrapped into
a `MixedModel`:

    struct MixedModel{O,FM<:AbstractModel} <: AbstractModel{O}
        root::M where {M<:AbstractModel{<:O}}
        info::NamedTuple
    end

Note that `FM` refers to the Feasible Models (`FM`) allowed in the model's sub-tree.

See also [`DecisionTree`](@ref), [`DecisionList`](@ref).
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

root(m::MixedModel) = m.root

isopen(::MixedModel) = isopen(root)

function apply(
    m::MixedModel,
    id::Union{AbstractInterpretation,AbstractInterpretationSet};
    kwargs...
)
    apply(root(m), id; kwargs...)
end
