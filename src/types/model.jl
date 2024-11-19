"""
    abstract type AbstractModel{O} end

Abstract type for symbolic models that,
given an instance object (i.e., a piece of data), output an
outcome of type `O`.

A model is said to be *symbolic* when its application relies on checking formulas
of a certain logical language
(see [SoleLogics.jl](https://github.com/aclai-lab/SoleLogics.jl) package)
on the instance.
Symbolic models provide a form of transparent and *interpretable modeling*,
as a symbolic model can be synthethised into a set of mutually exclusive logical rules
that can often be translated into natural language.

Examples of symbolic models are [`Rule`](@ref)s, [`Branch`](@ref)es,
[`DecisionList`](@ref)s and [`DecisionTree`](@ref)s.
Examples of non-symbolic (or *sub-symbolic*) models include those encoding algebraic
mathematical functions (e.g., neural networks).

Symbolic models can wrap other `AbstractModel`s, and use them to compute the outcome.
As such, an `AbstractModel` can actually be the result of a composition of many models,
and enclose a *tree* of `AbstractModel`s (with `LeafModel`s at the leaves).

# TODO - bring missing dispatches here (do the same for other model types)
# Interface
- `apply(m::AbstractModel, i::AbstractInterpretation; kwargs...)`
- `iscomplete(m::AbstractModel)`
- `outcometype(m::AbstractModel)`
- `outputtype(m::AbstractModel)`

- `immediatesubmodels(m::AbstractModel)`
- `nimmediatesubmodels(m::AbstractModel)`
- `listimmediaterules(m::AbstractModel)`

- `info(m::AbstractModel, [key, [defaultval]])`
- `info!(m::AbstractModel, key, value)`
- `hasinfo(m::AbstractModel, key)`

# Utility functions
- `apply(m::AbstractModel, i::AbstractInterpretationSet; kwargs...)`
- See AbstractTrees...

- `submodels(m::AbstractModel)`
- `nsubmodels(m::AbstractModel)`
- `leafmodels(m::AbstractModel)`
- `nleafmodels(m::AbstractModel)`

- `subtreeheight(m::AbstractModel)`
- `listrules(
        m::AbstractModel;
        use_shortforms::Bool=true,
        use_leftmostlinearform::Union{Nothing,Bool}=nothing,
        normalize::Bool=false,
        force_syntaxtree::Bool=false,
    )`
- `joinrules(m::AbstractModel, silent=false; kwargs...)`

# Examples
TODO

See also [`apply`](@ref), [`Branch`](@ref), [`info`](@ref), [`iscomplete`](@ref),
[`LeafModel`](@ref), [`outcometype`](@ref), [`Rule`](@ref).
"""
abstract type AbstractModel{O} end

"""
    iscomplete(::AbstractModel)::Bool

Return whether a model is complete.

An [`AbstractModel`](@ref) is *complete* if it is always able to provide an outcome of type
`O`. Otherwise, the model can output `nothing` values and is referred to as *incomplete*.

[`Rule`](@ref) is an example of an *incomplete* model, while [`Branch`](@ref) is an example of
*complete* model.

See also [`AbstractModel`](@ref).
"""
iscomplete(m::AbstractModel) = error("Please, provide method iscomplete($(typeof(m))).")


"""
    outcometype(::Type{<:AbstractModel{O}}) where {O} = O
    outcometype(m::AbstractModel) = outcometype(typeof(m))

Return the outcome type of a model (type).

See also [`AbstractModel`](@ref).
"""
outcometype(::Type{<:AbstractModel{O}}) where {O} = O
outcometype(m::AbstractModel) = outcometype(typeof(m))

"""
    outputtype(m::AbstractModel)

Return a supertype for the outputs obtained when `apply`ing a model.

# Implementation
The result depends on whether the model is incomplete or complete
```julia-repl
julia> outputtype(m::AbstractModel{O}) where {O} = iscomplete(m) ? O : Union{Nothing,O}
```

Note that if the model is complete, then `outputtype(m)` is equal to `outcometype(m)`.

See also [`AbstractModel`](@ref), [`apply`](@ref), [`iscomplete`](@ref), [`outcometype`](@ref).
"""
function outputtype(m::AbstractModel)
    iscomplete(m) ? outcometype(m) : Union{Nothing,outcometype(m)}
end

"""
    apply(m::AbstractModel, i::AbstractInterpretation; kwargs...)::outputtype(m)

    apply(
        m::AbstractModel,
        d::AbstractInterpretationSet;
        kwargs...
    )::AbstractVector{<:outputtype(m)}

Return the output prediction of a model `m` on a logical interpretation `i`,
on the `i_instance` of a dataset `d`, or on all instances of a dataset `d`.
Note that predictions can be `nothing` if the model is *incomplete* (e.g., if the model is a `Rule`).

# Keyword Arguments
- `check_args::Tuple = ()`;
- `check_kwargs::NamedTuple = (;)`;
- `functional_args::Tuple = ()`;
- `functional_kwargs::NamedTuple = (;)`;
- Any additional keyword argument is passed down to the model subtree's leaves

`check_args` and `check_kwargs` can influence check's behavior at the time
of its computation (see [`SoleLogics.check`](@ref)).

`functional_args` and `functional_kwargs` can influence FunctionModel's
behavior when the corresponding function is applied to AbstractInterpretation (see
[`FunctionModel`](@ref), [`SoleLogics.AbstractInterpretation`](@ref))

A model state-changing version of the function, [`apply!`], exist.
While producing the output, this function affects the info keys `:supporting_labels` and
`:supporting_predictions`, which are useful for inspecting the statistical performance of
parts of the model.

See also `SoleLogics.AbstractInterpretation`, `SoleLogics.AbstractInterpretationSet`,
[`AbstractModel`](@ref), [`iscomplete`](@ref), [`readmetrics`](@ref).
"""
function apply(
    m::AbstractModel,
    i::AbstractInterpretation;
    check_args::Tuple = (),
    check_kwargs::NamedTuple = (;),
    functional_args::Tuple = (),
    functional_kwargs::NamedTuple = (;),
    kwargs...,
)::outputtype(m)
    return error("Please, provide method apply(::$(typeof(m)), ::$(typeof(i)); kwargs...).")
end

@inline function apply(
    m::AbstractModel,
    d::AbstractInterpretationSet;
    kwargs...
)::AbstractVector{<:outputtype(m)}
    map(i_instance->apply(m, d, i_instance; kwargs...), 1:ninstances(d))
end

# function apply!(
#     m::AbstractModel,
#     i::AbstractInterpretation,
#     y;
#     mode = :replace,
#     kwargs...
# ) where {O}
#     @assert mode in [:append, :replace] "Unexpected apply mode: $mode."
#     return apply(m, i; mode = mode, y = y, kwargs...)
# end

# function apply!(
#     m::AbstractModel,
#     d::AbstractInterpretationSet,
#     y::AbstractVector;
#     mode = :replace,
#     kwargs...
# ) where {O}
#     @assert mode in [:append, :replace] "Unexpected apply mode: $mode."
#     return apply(m, d; mode = mode, y = y, kwargs...)
# end


# function apply!(
#     m::AbstractModel,
#     d::AbstractInterpretationSet,
#     i_instance::Integer,
#     y;
#     mode = :replace,
#     kwargs...
# ) where {O}
#     @assert mode in [:append, :replace] "Unexpected apply mode: $mode."
#     return apply(m, d, i_instance; mode = mode, y = y, kwargs...)
# end

function apply!(m::AbstractModel, d::Any, y::AbstractVector; kwargs...)
    apply!(m, SoleData.scalarlogiset(d; allow_propositional = true), y; kwargs...)
end

"""
    info(m::AbstractModel)::NamedTuple = m.info
    info(m::AbstractModel, key) = m.info[key]
    info(m::AbstractModel, key, defaultval)

Return the `info` structure for model `m`; this structure is used for storing additional
information that does not affect the model's behavior.

This structure can hold, for example, information about the model's statistical performance
during the learning phase.

See also [`AbstractModel`](@ref), [`info!`](@ref).
"""
info(m::AbstractModel)::NamedTuple = m.info
info(m::AbstractModel, key) = m.info[key]
info(m::AbstractModel, key, defaultval) = Base.get(m.info, key, defaultval)

"""
    info!(m::AbstractModel, info::NamedTuple; replace::Bool=false)
    info!(m::AbstractModel, key, val)

Overwrite the `info` structure within `m`.

# Keyword Arguments
- `replace::Bool`: overwrite the entire info structure.

See also [`AbstractModel`](@ref), [`info`](@ref).
"""
function info!(m::AbstractModel, info; replace::Bool=false)
    if replace
        m.info = info
    else
        foreach(((key, value),)->info!(m, key, value), pairs(info))
    end
end
info!(m::AbstractModel, key, value) = (m.info = merge((; key = value), m.info); m)

"""
    hasinfo(m::AbstractModel, key)

See also [`AbstractModel`](@ref), [`info`](@ref).
"""
hasinfo(m::AbstractModel, key) = haskey(info(m), key)

"""
    wrap(o::Any, FM::Type{<:AbstractModel})
    wrap(m::AbstractModel)
    wrap(o::Any)::AbstractModel

This function wraps anything into an AbstractModel.
The default behavior is the following:
    - when called on an `AbstractModel`, the model is simply returned (no wrapping is
        performed);
    - Function`s and `FunctionWrapper`s are wrapped into a [`FunctionModel`](@ref);
    - every other object is wrapped into a `ConstantModel`.

See also [`AbstractModel`](@ref), [`ConstantModel`](@ref), [`FunctionModel`](@ref),
[`LeafModel`](@ref).
"""
wrap(o::Any, FM::Type{<:AbstractModel}) = convert(FM, wrap(o))
wrap(m::AbstractModel) = m
# wrap(o::Any)::AbstractModel = error("Please, provide method wrap($(typeof(o))).")

"""
    immediatesubmodels(m::AbstractModel)

Return the list of immediate child models.

!!! note
    If the model is a leaf model, then the returned list will be empty.

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

See also [`AbstractModel`](@ref), [`LeafModel`](@ref), [`submodels`](@ref).
"""
function immediatesubmodels(
    m::AbstractModel{O}
)::Vector{<:{AbstractModel{<:O}}} where {O}
    return error("Please, provide method immediatesubmodels(::$(typeof(m))).")
end

"""
    nimmediatesubmodels(m::AbstractModel)

Return the number of models returned by [`immediatesubmodels`](@ref).

See also [`AbstractModel`](@ref), [`immediatesubmodels`](@ref).
"""
function nimmediatesubmodels(m::AbstractModel)
    return error("Please, provide method nimmediatesubmodels(::$(typeof(m))).")
end

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

See also [`AbstractModel`](@ref), [`listrules`](@ref).
"""
listimmediaterules(m::AbstractModel{O} where {O})::Rule{<:O} =
    error("Please, provide method listimmediaterules(::$(typeof(m))) " *
        "($(typeof(m)) is a symbolic model).")


############################################################################################
##################################### LeafModel ############################################
############################################################################################

"""
    abstract type LeafModel{O} <: AbstractModel{O} end

Abstract type for leaf models, that is, models which outcomes do not depend other models,
and represents the bottom of the computation.

In general, an [`AbstractModel`](@ref) can generally wrap other `AbstractModel`s;
in such case, the outcome can depend on the inner models being applied on the instance
object. Otherwise, the model is considered as a *leaf*, or *final*, and is the *leaf* of a
tree of `AbstractModel`s.

# Examples
```julia-repl
julia> SoleModels.LeafModel(2) isa SoleModels.ConstantModel

julia> SoleModels.LeafModel(sum) isa SoleModels.FunctionModel
┌ Warning: Over efficiency concerns, please consider wrappingJulia Function's into FunctionWrapper{O,Tuple{SoleModels.AbstractInterpretation}} structures,where O is their return type.
└ @ SoleModels ~/.julia/dev/SoleModels/src/base.jl:337
true
```

See also [`AbstractModel`](@ref), [`ConstantModel`](@ref), [`FunctionModel`](@ref).
"""
abstract type LeafModel{O} <: AbstractModel{O} end

LeafModel(o) = wrap(o)

immediatesubmodels(m::LeafModel{O}) where {O} = Vector{<:AbstractModel{<:O}}[]
nimmediatesubmodels(m::LeafModel) = 0
listimmediaterules(m::LeafModel) = [Rule(⊤, m)]

function emptysupports!(m)
    haskey(m.info, :supporting_predictions) && empty!(m.info.supporting_predictions)
    empty!(m.info.supporting_labels)
    nothing
end

function recursivelyemptysupports!(m, leavesonly)
    (!leavesonly || (m isa LeafModel)) && emptysupports!(m)
    recursivelyemptysupports!.(immediatesubmodels(m), leavesonly)
    nothing
end

function __apply!(m, mode, preds, y, leavesonly)
    if !leavesonly || m isa LeafModel
        # idxs = filter(i->!isnothing(preds[i]), 1:length(preds))
        # _preds = preds[idxs]
        # _y = y[idxs]
        if mode == :replace
            if haskey(m.info, :supporting_predictions)
                empty!(m.info.supporting_predictions)
                append!(m.info.supporting_predictions, preds)
            end
            empty!(m.info.supporting_labels)
            append!(m.info.supporting_labels, y)
        elseif mode == :append
            if haskey(m.info, :supporting_predictions)
                append!(m.info.supporting_predictions, preds)
            end
            append!(m.info.supporting_labels, y)
        else
            error("Unexpected apply mode: $mode.")
        end
    end
    return preds
end

# function __apply!(m, mode, preds, y)

#     if mode == :replace
#         m.info.supporting_predictions = preds
#         m.info.supporting_labels = y
#         preds
#     elseif mode == :replace
#         m.info.supporting_predictions = [info(m, :supporting_predictions)..., preds...]
#         m.info.supporting_labels = [info(m, :supporting_labels)..., y...]
#         preds
#     else
#         error("Unexpected apply mode: $mode.")
#     end
# end
