
using SoleLogics: AbstractAlphabet
using Random
import SoleLogics: negation, propositions

import Base: isequal, hash, in, isfinite, length

"""
    abstract type AbstractCondition{F<:AbstractFeature} end

Abstract type for representing conditions that can be interpreted and evaluated
on worlds of instances of a logical dataset. In logical contexts,
these are wrapped into `Proposition`s.

See also
[`Proposition`](@ref),
[`syntaxstring`](@ref),
[`ScalarMetaCondition`](@ref),
[`ScalarCondition`](@ref).
"""
abstract type AbstractCondition{F<:AbstractFeature} end

# Check a condition (e.g, on a world of a logiset instance)
function checkcondition(c::AbstractCondition, args...; kwargs...)
    error("Please, provide method checkcondition(::$(typeof(c)), " *
        join(map(t->"::$(t)", typeof.(args)), ", ") * "; kwargs...). " *
        "Note that this value must be unique.")
end

# function checkcondition(
#     c::AbstractCondition,
#     X::AbstractLogiset{W,U,F},
#     i_instance::Integer,
#     w::W,
# ) where {W<:AbstractWorld,U,F<:AbstractFeature}
#     error("Please, provide method checkcondition(c::$(typeof(c)), X::$(typeof(X)), i_instance::$(typeof(i_instance)), w::$(typeof(w))).")
# end

function syntaxstring(c::AbstractCondition; kwargs...)
    error("Please, provide method syntaxstring(::$(typeof(c)); kwargs...). " *
        "Note that this value must be unique.")
end

function Base.show(io::IO, c::AbstractCondition)
    # print(io, "Feature of type $(typeof(c))\n\t-> $(syntaxstring(c))")
    print(io, "$(typeof(c)): $(syntaxstring(c))")
    # print(io, "$(syntaxstring(c))")
end

Base.isequal(a::AbstractCondition, b::AbstractCondition) = syntaxstring(a) == syntaxstring(b) # nameof(x) == nameof(feature)
Base.hash(a::AbstractCondition) = Base.hash(syntaxstring(a))

function parsecondition(
    C::Type{<:AbstractCondition},
    expression::String;
    kwargs...
)
    error("Please, provide method parsecondition(::$(Type{C}), expression::$(typeof(expression)); kwargs...).")
end

############################################################################################

"""
    struct ValueCondition{F<:AbstractFeature} <: AbstractCondition{F}
        feature::F
    end

A condition which yields a truth value equal to the value of a feature.

See also [`AbstractFeature`](@ref).
"""
struct ValueCondition{F<:AbstractFeature} <: AbstractCondition{F}
    feature::F
end

checkcondition(c::ValueCondition, args...; kwargs...) = featvalue(c.feature, args...; kwargs...)

syntaxstring(c::ValueCondition; kwargs...) = string(c.feature)

function parsecondition(
    ::Type{ValueCondition},
    expression::String;
    featuretype = Feature,
    kwargs...
)
    ValueCondition(featuretype(expression))
end

############################################################################################

"""
    struct FunctionalCondition{F<:AbstractFeature} <: AbstractCondition{F}
        feature::F
        f::F
    end

A condition which yields a truth value equal to the value of a function.

See also [`AbstractFeature`](@ref).
"""
struct FunctionalCondition{F<:AbstractFeature} <: AbstractCondition{F}
    feature::F
    f::Function
end

checkcondition(c::FunctionalCondition, args...; kwargs...) = (c.f)(featvalue(c.feature, args...; kwargs...))

syntaxstring(c::FunctionalCondition; kwargs...) = "$(c.f)($(c.feature))"

function parsecondition(
    ::Type{FunctionalCondition},
    expression::String;
    featuretype = Feature,
    kwargs...
)
    r = Regex("^\\s*(\\w+)\\(\\s*(\\w+)\\s*\\)\\s*\$")
    slices = match(r, expression)

    @assert !isnothing(slices) && length(slices) == 2 "Could not parse FunctionalCondition from " *
        "expression $(repr(expression))."

    slices = string.(slices)

    feature = featuretype(slices[1])
    f = eval(Meta.parse(slices[2]))

    FunctionalCondition(feature, f)
end
