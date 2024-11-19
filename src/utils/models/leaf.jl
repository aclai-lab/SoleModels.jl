import Base: convert, length, getindex

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

Return the constant outcome wrapped by `m`.

See also [`ConstantModel`](@ref).
"""
outcome(m::ConstantModel) = m.outcome

iscomplete(::ConstantModel) = true

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

function apply!(
    m::ConstantModel,
    d::AbstractInterpretationSet,
    y::AbstractVector;
    mode = :replace,
    leavesonly = false,
    kwargs...
)
    # @assert length(y) == ninstances(d) "$(length(y)) == $(ninstances(d))"
    if mode == :replace
        recursivelyemptysupports!(m, leavesonly)
        mode = :append
    end
    preds = fill(outcome(m), ninstances(d))
    # @show m.info
    # @show y
    return __apply!(m, mode, preds, y, leavesonly)
end

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

Return the `FunctionWrapper` within `m`.

See also [`FunctionModel`](@ref),
[FunctionWrappers](https://github.com/yuyichao/FunctionWrappers.jl).
"""
f(m::FunctionModel) = m.f

iscomplete(::FunctionModel) = true

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
