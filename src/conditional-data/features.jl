
using SoleData: AbstractDimensionalInstance, instance

import Base: isequal, hash

import SoleLogics: syntaxstring

############################################################################################
############################################################################################
############################################################################################

# A feature represents a function that can be computed on a world.
abstract type AbstractFeature{U<:Real} end

featvaltype(::Type{<:AbstractFeature{U}}) where {U} = U
featvaltype(::AbstractFeature{U}) where {U} = U

@inline (f::AbstractFeature)(args...) = compute_feature(f, args...)

# TODO explain that it must be unique.
function syntaxstring(f::AbstractFeature; kwargs...)
    error("Please, provide method syntaxstring(::$(typeof(f)); kwargs...). Note that this value must be unique.")
end

Base.isequal(a::AbstractFeature, b::AbstractFeature) = syntaxstring(a) == syntaxstring(b) # nameof(x) == nameof(feature)
Base.hash(a::AbstractFeature) = Base.hash(syntaxstring(a))

################################################################################
################################################################################

# A dimensional feature represents a function that can be computed when the world
#  is an entity that lives in a dimensional context; for example, the world
#  can be a region of the matrix representing a b/w image.
# The simplest dimensional feature is, min(A1), which computes the minimum for attribute 1
#  for a given world.
# The value of a feature for a given world can be then evaluated in a condition,
#  such as: min(A1) >= 10.
abstract type DimensionalFeature{U} <: AbstractFeature{U} end

# Dimensional features functions are computed on dimensional channels,
#  namely, interpretations of worlds on a dimensional contexts
# const DimensionalFeatureFunction = FunctionWrapper{Number,Tuple{AbstractArray{<:Number}}}

############################################################################################

# A dimensional feature represented by the application of a function to a channel
#  (e.g., how much a region of the image resembles a horse)
struct MultiAttributeFeature{U} <: DimensionalFeature{U}
    f::Function
end
function compute_feature(f::MultiAttributeFeature{U}, inst::AbstractDimensionalInstance{T})::U where {U<:Real,T}
    (f.f(inst))
end
syntaxstring(f::MultiAttributeFeature, args...; kwargs...) = "$(f.f)"

############################################################################################

abstract type SingleAttributeFeature{U} <: DimensionalFeature{U} end

i_attribute(f::SingleAttributeFeature) = f.i_attribute
function attribute_name(
    f::SingleAttributeFeature;
    attribute_names_map::Union{Nothing,AbstractDict,AbstractVector} = nothing,
    attribute_name_prefix::Union{Nothing,String} = nothing,
    kwargs...,
)
    if isnothing(attribute_names_map)
        # Default prefix for "V" (for "variable")
        attribute_name_prefix = isnothing(attribute_name_prefix) ? "V" : attribute_name_prefix
        "$(attribute_name_prefix)$(i_attribute(f))"
    else
        @assert isnothing(attribute_name_prefix)
        "$(attribute_names_map[i_attribute(f)])"
    end
end


# A feature can be just a name
struct SingleAttributeNamedFeature{U} <: SingleAttributeFeature{U}
    i_attribute::Integer
    name::String
end
function compute_feature(f::SingleAttributeNamedFeature, inst::AbstractDimensionalInstance{T}) where {T}
    @error "Can't intepret SingleAttributeNamedFeature on any structure at all."
end
function syntaxstring(f::SingleAttributeNamedFeature; kwargs...)
    n = attribute_name(f; kwargs...)
    (f.name == "" ? "$(n)" : "$(f.name)($n)")
end

############################################################################################

############################################################################################

# Notable single-attribute features: minimum and maximum of a given attribute
#  e.g., min(A1), max(A10)
struct SingleAttributeMin{U} <: SingleAttributeFeature{U}
    i_attribute::Integer
    function SingleAttributeMin{U}(i_attribute::Integer) where {U<:Real}
        return new{U}(i_attribute)
    end
    function SingleAttributeMin(i_attribute::Integer)
        @warn "Please specify the type of the feature for SingleAttributeMin." *
            " For example: SingleAttributeMin{Float64}($(i_attribute))."
        return SingleAttributeMin{Real}(i_attribute)
    end
end
function compute_feature(f::SingleAttributeMin{U}, inst::AbstractDimensionalInstance{T}) where {U<:Real,T}
    (minimum(instance(inst,f.i_attribute)))::U
end
function syntaxstring(f::SingleAttributeMin; kwargs...)
    n = attribute_name(f; kwargs...)
    "min($n)"
end

struct SingleAttributeMax{U} <: SingleAttributeFeature{U}
    i_attribute::Integer
    function SingleAttributeMax{U}(i_attribute::Integer) where {U<:Real}
        return new{U}(i_attribute)
    end
    function SingleAttributeMax(i_attribute::Integer)
        @warn "Please specify the type of the feature for SingleAttributeMax." *
            " For example: SingleAttributeMax{Float64}($(i_attribute))."
        return SingleAttributeMax{Real}(i_attribute)
    end
end
function compute_feature(f::SingleAttributeMax{U}, inst::AbstractDimensionalInstance{T}) where {U<:Real,T}
    (maximum(instance(inst,f.i_attribute)))::U
end
function syntaxstring(f::SingleAttributeMax; kwargs...)
    n = attribute_name(f; kwargs...)
    "max($n)"
end

############################################################################################

# Softened versions (quantiles) of single-attribute minimum and maximum
#  e.g., min80(A1), max80(A10)
struct SingleAttributeSoftMin{U,T<:AbstractFloat} <: SingleAttributeFeature{U}
    i_attribute::Integer
    alpha::T
    function SingleAttributeSoftMin{U}(i_attribute::Integer, alpha::T) where {U<:Real,T}
        @assert !(alpha > 1.0 || alpha < 0.0) "Can't instantiate SingleAttributeSoftMin with alpha = $(alpha)"
        @assert !isone(alpha) "Can't instantiate SingleAttributeSoftMin with alpha = $(alpha). Use SingleAttributeMin instead!"
        new{U,T}(i_attribute, alpha)
    end
end
alpha(f::SingleAttributeSoftMin) = f.alpha
function syntaxstring(f::SingleAttributeSoftMin; kwargs...)
    "min" *
        utils.subscriptnumber(rstrip(rstrip(string(f.alpha*100), '0'), '.')) *
        "($(attribute_name(f; kwargs...)))"
end

function compute_feature(f::SingleAttributeSoftMin{U}, inst::AbstractDimensionalInstance{T}) where {U<:Real,T}
    utils.softminimum(instance(inst,f.i_attribute), f.alpha)::U
end
struct SingleAttributeSoftMax{U,T<:AbstractFloat} <: SingleAttributeFeature{U}
    i_attribute::Integer
    alpha::T
    function SingleAttributeSoftMax{U}(i_attribute::Integer, alpha::T) where {U<:Real,T}
        @assert !(alpha > 1.0 || alpha < 0.0) "Can't instantiate SingleAttributeSoftMax with alpha = $(alpha)"
        @assert !isone(alpha) "Can't instantiate SingleAttributeSoftMax with alpha = $(alpha). Use SingleAttributeMax instead!"
        new{U,T}(i_attribute, alpha)
    end
end
function compute_feature(f::SingleAttributeSoftMax{U}, inst::AbstractDimensionalInstance{T}) where {U<:Real,T}
    utils.softmaximum(instance(inst,f.i_attribute), f.alpha)::U
end
alpha(f::SingleAttributeSoftMax) = f.alpha
function syntaxstring(f::SingleAttributeSoftMax; kwargs...)
    "max" *
        utils.subscriptnumber(rstrip(rstrip(string(f.alpha*100), '0'), '.')) *
        "($(attribute_name(f; kwargs...)))"
end

# TODO simplify OneWorld case:
# function compute_feature(f::SingleAttributeSoftMin, inst::AbstractDimensionalInstance{T}) where {T}
#     instance(inst,f.i_attribute)::T
# end
# function compute_feature(f::SingleAttributeSoftMax, inst::AbstractDimensionalInstance{T}) where {T}
#     instance(inst,f.i_attribute)::T
# end
# Note: Maybe features should dispatch on WorldType, (as well or on the type of underlying data?)

############################################################################################

# A dimensional feature represented by the application of a function to a
#  single attribute (e.g., avg(red), that is, how much red is in an image region)
struct SingleAttributeGenericFeature{U} <: SingleAttributeFeature{U}
    i_attribute::Integer
    f::Function
end
function compute_feature(f::SingleAttributeGenericFeature{U}, inst::AbstractDimensionalInstance{T}) where {U<:Real,T}
    (f.f(SoleBase.vectorize(instance(inst,f.i_attribute));))::U
end
function syntaxstring(f::SingleAttributeGenericFeature; kwargs...)
    "$(f.f)($(attribute_name(f; kwargs...)))"
end

############################################################################################

# These features collapse to a single value; this can be useful to know
is_collapsing_single_attribute_feature(f::Union{SingleAttributeMin,SingleAttributeMax,SingleAttributeSoftMin,SingleAttributeSoftMax}) = true
is_collapsing_single_attribute_feature(f::SingleAttributeGenericFeature) = (f.f in [minimum, maximum, mean])

############################################################################################

# A feature can also be just a name
struct NamedFeature{U} <: AbstractFeature{U}
    name::String
end
function compute_feature(f::NamedFeature, inst::AbstractDimensionalInstance{T}) where {T}
    @error "Can't intepret NamedFeature on any structure at all."
end
function syntaxstring(f::NamedFeature; kwargs...)
    "$(f.name)"
end

############################################################################################


# A feature can be imported from a FWD (FWD) structure (see ModalLogic module)
struct ExternalFWDFeature{U} <: AbstractFeature{U}
    name::String
    fwd::Any
end
function compute_feature(f::ExternalFWDFeature, inst::AbstractDimensionalInstance{T}) where {T}
    @error "Can't intepret ExternalFWDFeature on any structure at all."
end
function syntaxstring(f::ExternalFWDFeature; kwargs...)
    "$(f.name)"
end

################################################################################
