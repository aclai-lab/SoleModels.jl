
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

function syntaxstring(c::AbstractCondition; kwargs...)
    error("Please, provide method syntaxstring(::$(typeof(c)); kwargs...)." *
        " Note that this value must be unique.")
end

function Base.show(io::IO, c::AbstractCondition)
    # print(io, "Feature of type $(typeof(c))\n\t-> $(syntaxstring(c))")
    print(io, "$(typeof(c)): $(syntaxstring(c))")
    # print(io, "$(syntaxstring(c))")
end

Base.isequal(a::AbstractCondition, b::AbstractCondition) = syntaxstring(a) == syntaxstring(b) # nameof(x) == nameof(feature)
Base.hash(a::AbstractCondition) = Base.hash(syntaxstring(a))

function parsecondition(
    expression::String;
    kwargs...
)
    error("Please, provide method parsecondition(expression::$(typeof(expression)); kwargs...).")
end
