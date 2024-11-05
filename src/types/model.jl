# TODO document, together with issymbolic and listrules
"""
    solemodel(m::Any)

This function translates a symbolic model to a symbolic model using the structures defined in SoleModel.jl.
# Interface

See also [`AbstractModel`](@ref), [`ConstantModel`](@ref), [`FunctionModel`](@ref),
[`LeafModel`](@ref).
"""
solemodel(o::Any, FM::Type{<:AbstractModel}) = convert(FM, wrap(o))


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

# Interface
- `isopen(m::AbstractModel)::Bool`
- `apply(m::AbstractModel, i::AbstractInterpretation; kwargs...)`

# Utility functions
- `outcometype(m::AbstractModel)`
- `outputtype(m::AbstractModel)`
- `info(m::AbstractModel, [key, [defaultval]])`
- `info!(m::AbstractModel, key, value)`
- `hasinfo(m::AbstractModel, key)`

# Examples
TODO

See also [`apply`](@ref), [`Branch`](@ref), [`info`](@ref), [`isopen`](@ref),
[`LeafModel`](@ref), [`outcometype`](@ref), [`Rule`](@ref).
"""
abstract type AbstractModel{O} end

"""
    isopen(::AbstractModel)::Bool

Return whether a model is open.

An [`AbstractModel`](@ref) is *closed* if it is always able to provide an outcome of type
`O`. Otherwise, the model can output `nothing` values and is referred to as *open*.

[`Rule`](@ref) is an example of an *open* model, while [`Branch`](@ref) is an example of
*closed* model.

See also [`AbstractModel`](@ref).
"""
isopen(m::AbstractModel) = error("Please, provide method isopen($(typeof(m))).")


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
The result depends on whether the model is open or closed
```julia-repl
julia> outputtype(M::AbstractModel{O}) = isopen(M) ? Union{Nothing,O} : O
```

Note that if the model is closed, then `outputtype(m)` is equal to `outcometype(m)`.

See also [`AbstractModel`](@ref), [`apply`](@ref), [`isopen`](@ref), [`outcometype`](@ref).
"""
function outputtype(m::AbstractModel)
    isopen(m) ? Union{Nothing,outcometype(m)} : outcometype(m)
end


"""
    apply(m::AbstractModel, i::AbstractInterpretation; kwargs...)::outputtype(m)

    apply(
        m::AbstractModel,
        d::AbstractInterpretationSet;
        kwargs...
    )::AbstractVector{<:outputtype(m)}

    apply(
        m::AbstractModel,
        d::AbstractInterpretationSet,
        i_instance::Integer;
        kwargs...
    )::outputtype(m)

Return the output prediction of a model `m` on a logical interpretation `i`,
on the `i_instance` of a dataset `d`, or on all instances of a dataset `d`.
Note that predictions can be `nothing` if the model is *open* (e.g., if the model is a `Rule`).

# Keyword Arguments
- `check_args::Tuple = ()`;
- `check_kwargs::NamedTuple = (;)`;
- `functional_args::Tuple = ()`;
- `functional_kwargs::NamedTuple = (;)`;
- Any additional keyword argument is passed down to the model subtree's leaves

`check_args` and `check_kwargs` can influence check's behavior at the time
of its computation (see [`SoleLogics.check`](@ref))

`functional_args` and `functional_kwargs` can influence FunctionModel's
behavior when the corresponding function is applied to AbstractInterpretation (see
[`FunctionModel`](@ref), [`SoleLogics.AbstractInterpretation`](@ref))

A model state-changing version of the function, [`apply!`], exist.
While producing the output, this function affects the info keys `:supporting_labels` and
`:supporting_predictions`, which are useful for inspecting the statistical performance of
parts of the model.

See also `SoleLogics.AbstractInterpretation`, `SoleLogics.AbstractInterpretationSet`,
[`AbstractModel`](@ref), [`isopen`](@ref), [`readmetrics`](@ref).
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

function apply(
    m::AbstractModel,
    d::AbstractInterpretationSet,
    i_instance::Integer;
    kwargs...
)::outputtype(m)
    interpretation = get_instance(d, i_instance)
    apply(m, interpretation; kwargs...)
end

function apply(
    m::AbstractModel,
    d::AbstractInterpretationSet;
    kwargs...
)::AbstractVector{<:outputtype(m)}
    map(i_instance->apply(m, d, i_instance; kwargs...), 1:ninstances(d))
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
