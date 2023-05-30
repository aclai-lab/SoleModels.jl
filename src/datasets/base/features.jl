import Base: isequal, hash, show
import SoleLogics: syntaxstring

"""
    abstract type AbstractFeature{U} end

Abstract type for features of worlds of
[Kripke structures](https://en.wikipedia.org/wiki/Kripke_structure_(model_checking).

See also [`featvaltype`](@ref), [`computefeature`](@ref), [`AbstractWorld`](@ref).
"""
abstract type AbstractFeature{U} end

"""
    featvaltype(::Type{<:AbstractFeature{U}}) where {U} = U
    featvaltype(::AbstractFeature{U}) where {U} = U

Return the type returned by the feature.

See also [`AbstractWorld`](@ref).
"""
featvaltype(::Type{<:AbstractFeature{U}}) where {U} = U
featvaltype(::AbstractFeature{U}) where {U} = U

"""
    computefeature(f::AbstractFeature{U}, channel; kwargs...)::U where {U}

Compute a feature on a channel (i.e., world reading) of an instance.

See also [`AbstractFeature`](@ref).
"""
function computefeature(f::AbstractFeature{U}, channel; kwargs...) where {U}
    error("Please, provide method computefeature(::$(typeof(f)), channel::$(typeof(channel)); kwargs...)::U.")
end

function syntaxstring(f::AbstractFeature; kwargs...)
    error("Please, provide method syntaxstring(::$(typeof(f)); kwargs...)."
        * " Note that this value must be unique.")
end

@inline (f::AbstractFeature)(args...) = computefeature(f, args...)

function Base.show(io::IO, f::AbstractFeature)
    # print(io, "Feature of type $(typeof(f))\n\t-> $(syntaxstring(f))")
    print(io, "$(typeof(f)): $(syntaxstring(f))")
    # print(io, "$(syntaxstring(f))")
end

Base.isequal(a::AbstractFeature, b::AbstractFeature) = syntaxstring(a) == syntaxstring(b)
Base.hash(a::AbstractFeature) = Base.hash(syntaxstring(a))

############################################################################################

"""
    struct PropositionFeature{U} <: AbstractFeature{U}
        name::String
    end

A feature that identifies a propositional letter.

See also [`AbstractFeature`](@ref).
"""
struct PropositionFeature{U<:Proposition} <: AbstractFeature{U}
    proposition::U
end
function computefeature(f::PropositionFeature{U}, channel; kwargs...) where {U}
    error("Please, provide method computefeature(::$(typeof(f)), channel::$(typeof(channel)); kwargs...)::U.")
end

featurename(f::PropositionFeature) = string(f.proposition)

############################################################################################

"""
    struct NamedFeature{U} <: AbstractFeature{U}
        name::String
    end

A feature solely identified by its name.

See also [`AbstractFeature`](@ref).
"""
struct NamedFeature{U} <: AbstractFeature{U}
    name::String
end
function computefeature(f::NamedFeature, channel)
    @error "Can't intepret NamedFeature on any structure at all."
end
featurename(f::NamedFeature) = f.name

############################################################################################

"""
    struct ExternalFWDFeature{U} <: AbstractFeature{U}
        name::String
        fwd::Any
    end

A feature encoded explicitly as (a slice of) an FWD structure (see `AbstractFeatureLookupSet`).

See also
[`AbstractFeatureLookupSet`](@ref), [`AbstractFeature`](@ref).
"""
struct ExternalFWDFeature{U} <: AbstractFeature{U}
    name::String
    fwd::Any
end
function computefeature(f::ExternalFWDFeature, channel)
    @error "Can't intepret ExternalFWDFeature on any structure at all."
end
featurename(f::ExternalFWDFeature) = f.name

############################################################################################
