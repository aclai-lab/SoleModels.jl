using SoleData: AbstractDimensionalInstance, get_instance_attribute

import Base: isequal, hash

import SoleLogics: syntaxstring

############################################################################################
############################################################################################
############################################################################################

"""
    abstract type AbstractFeature{U<:Real} end

Abstract type for features, representing a scalar functions that can be computed on a world.

See also [`AbstractWorld`](@ref).
"""
abstract type AbstractFeature{U<:Real} end

"""
    featvaltype(::Type{<:AbstractFeature{U}}) where {U} = U
    featvaltype(::AbstractFeature{U}) where {U} = U

Return the type returned by the feature.

See also [`AbstractWorld`](@ref).
"""
featvaltype(::Type{<:AbstractFeature{U}}) where {U} = U
featvaltype(::AbstractFeature{U}) where {U} = U

@inline (f::AbstractFeature)(args...) = compute_feature(f, args...)

function syntaxstring(f::AbstractFeature; kwargs...)
    error("Please, provide method syntaxstring(::$(typeof(f)); kwargs...)."
        * " Note that this value must be unique.")
end

Base.isequal(a::AbstractFeature, b::AbstractFeature) = syntaxstring(a) == syntaxstring(b)
Base.hash(a::AbstractFeature) = Base.hash(syntaxstring(a))

################################################################################
################################################################################

"""
    abstract type DimensionalFeature{U} <: AbstractFeature{U} end

Abstract type for dimensional features,
representing function that can be computed on a world, when the world
 is an entity that lives in a *dimensional* context; for example, when the world
 is an `Interval2D` (e.g., a region of the matrix representing a b/w image).
As an example, dimensional feature is, min(A1), which computes the minimum for attribute 1
 for a given world.
The value of a feature for a given world can be then evaluated in a condition,
 such as: min(A1) >= 10.
"""
abstract type DimensionalFeature{U} <: AbstractFeature{U} end

# Dimensional features functions are computed on dimensional channels,
#  namely, interpretations of worlds on a dimensional contexts
# const DimensionalFeatureFunction = FunctionWrapper{Number,Tuple{AbstractArray{<:Number}}}

############################################################################################

# A dimensional feature represented by the application of a function to a channel
#  (e.g., how much a region of the image resembles a horse)
struct MultivariateFeature{U} <: DimensionalFeature{U}
    f::Function
end
function compute_feature(f::MultivariateFeature{U}, inst::AbstractDimensionalInstance{T})::U where {U<:Real,T}
    (f.f(inst))
end
syntaxstring(f::MultivariateFeature, args...; kwargs...) = "$(f.f)"

############################################################################################

abstract type UnivariateFeature{U} <: DimensionalFeature{U} end

i_attribute(f::UnivariateFeature) = f.i_attribute
function attribute_name(
    f::UnivariateFeature;
    attribute_names_map::Union{Nothing,AbstractDict,AbstractVector} = nothing,
    attribute_name_prefix::Union{Nothing,String} = nothing,
    kwargs...,
)
    if isnothing(attribute_names_map)
        attribute_name_prefix = isnothing(attribute_name_prefix) ? UNIVARIATEFEATURE_VARPREFIX : attribute_name_prefix
        "$(attribute_name_prefix)$(i_attribute(f))"
    else
        @assert isnothing(attribute_name_prefix)
        "$(attribute_names_map[i_attribute(f)])"
    end
end


# A feature can be just a name
struct UnivariateNamedFeature{U} <: UnivariateFeature{U}
    i_attribute::Integer
    name::String
end
function compute_feature(f::UnivariateNamedFeature, inst::AbstractDimensionalInstance{T}) where {T}
    @error "Can't intepret UnivariateNamedFeature on any structure at all."
end
function syntaxstring(f::UnivariateNamedFeature; kwargs...)
    n = attribute_name(f; kwargs...)
    (f.name == "" ? "$(n)" : "$(f.name)($n)")
end

############################################################################################

############################################################################################

# Notable single-attribute features: minimum and maximum of a given attribute
#  e.g., min(A1), max(A10)
struct UnivariateMin{U} <: UnivariateFeature{U}
    i_attribute::Integer
    function UnivariateMin{U}(i_attribute::Integer) where {U<:Real}
        return new{U}(i_attribute)
    end
    function UnivariateMin(i_attribute::Integer)
        @warn "Please specify the type of the feature for UnivariateMin." *
            " For example: UnivariateMin{Float64}($(i_attribute))."
        return UnivariateMin{Real}(i_attribute)
    end
end
function compute_feature(f::UnivariateMin{U}, inst::AbstractDimensionalInstance{T}) where {U<:Real,T}
    (minimum(get_instance_attribute(inst,f.i_attribute)))::U
end
function syntaxstring(f::UnivariateMin; kwargs...)
    n = attribute_name(f; kwargs...)
    "min$UNIVARIATEFEATURE_OPENING_BRACKET$n$UNIVARIATEFEATURE_CLOSING_BRACKET"
end

struct UnivariateMax{U} <: UnivariateFeature{U}
    i_attribute::Integer
    function UnivariateMax{U}(i_attribute::Integer) where {U<:Real}
        return new{U}(i_attribute)
    end
    function UnivariateMax(i_attribute::Integer)
        @warn "Please specify the type of the feature for UnivariateMax." *
            " For example: UnivariateMax{Float64}($(i_attribute))."
        return UnivariateMax{Real}(i_attribute)
    end
end
function compute_feature(f::UnivariateMax{U}, inst::AbstractDimensionalInstance{T}) where {U<:Real,T}
    (maximum(get_instance_attribute(inst,f.i_attribute)))::U
end
function syntaxstring(f::UnivariateMax; kwargs...)
    n = attribute_name(f; kwargs...)
    "max$UNIVARIATEFEATURE_OPENING_BRACKET$n$UNIVARIATEFEATURE_CLOSING_BRACKET"
end

############################################################################################

# Softened versions (quantiles) of single-attribute minimum and maximum
#  e.g., min80(A1), max80(A10)
struct UnivariateSoftMin{U,T<:AbstractFloat} <: UnivariateFeature{U}
    i_attribute::Integer
    alpha::T
    function UnivariateSoftMin{U}(i_attribute::Integer, alpha::T) where {U<:Real,T}
        @assert !(alpha > 1.0 || alpha < 0.0) "Can't instantiate UnivariateSoftMin with alpha = $(alpha)"
        @assert !isone(alpha) "Can't instantiate UnivariateSoftMin with alpha = $(alpha). Use UnivariateMin instead!"
        new{U,T}(i_attribute, alpha)
    end
end
alpha(f::UnivariateSoftMin) = f.alpha
function syntaxstring(f::UnivariateSoftMin; kwargs...)
    "min" *
        utils.subscriptnumber(rstrip(rstrip(string(f.alpha*100), '0'), '.')) *
        "$UNIVARIATEFEATURE_OPENING_BRACKET$(attribute_name(f; kwargs...))$UNIVARIATEFEATURE_CLOSING_BRACKET"
end

function compute_feature(f::UnivariateSoftMin{U}, inst::AbstractDimensionalInstance{T}) where {U<:Real,T}
    utils.softminimum(get_instance_attribute(inst,f.i_attribute), f.alpha)::U
end
struct UnivariateSoftMax{U,T<:AbstractFloat} <: UnivariateFeature{U}
    i_attribute::Integer
    alpha::T
    function UnivariateSoftMax{U}(i_attribute::Integer, alpha::T) where {U<:Real,T}
        @assert !(alpha > 1.0 || alpha < 0.0) "Can't instantiate UnivariateSoftMax with alpha = $(alpha)"
        @assert !isone(alpha) "Can't instantiate UnivariateSoftMax with alpha = $(alpha). Use UnivariateMax instead!"
        new{U,T}(i_attribute, alpha)
    end
end
function compute_feature(f::UnivariateSoftMax{U}, inst::AbstractDimensionalInstance{T}) where {U<:Real,T}
    utils.softmaximum(get_instance_attribute(inst,f.i_attribute), f.alpha)::U
end
alpha(f::UnivariateSoftMax) = f.alpha
function syntaxstring(f::UnivariateSoftMax; kwargs...)
    "max" *
        utils.subscriptnumber(rstrip(rstrip(string(f.alpha*100), '0'), '.')) *
        "$UNIVARIATEFEATURE_OPENING_BRACKET$(attribute_name(f; kwargs...))$UNIVARIATEFEATURE_CLOSING_BRACKET"
end

# TODO simplify OneWorld case:
# function compute_feature(f::UnivariateSoftMin, inst::AbstractDimensionalInstance{T}) where {T}
#     get_instance_attribute(inst,f.i_attribute)::T
# end
# function compute_feature(f::UnivariateSoftMax, inst::AbstractDimensionalInstance{T}) where {T}
#     get_instance_attribute(inst,f.i_attribute)::T
# end
# Note: Maybe features should dispatch on WorldType, (as well or on the type of underlying data?)

############################################################################################

# A dimensional feature represented by the application of a function to a
#  single attribute (e.g., avg(red), that is, how much red is in an image region)
struct UnivariateGenericFeature{U} <: UnivariateFeature{U}
    i_attribute::Integer
    f::Function
end
function compute_feature(f::UnivariateGenericFeature{U}, inst::AbstractDimensionalInstance{T}) where {U<:Real,T}
    (f.f(SoleBase.vectorize(get_instance_attribute(inst,f.i_attribute));))::U
end
function syntaxstring(f::UnivariateGenericFeature; kwargs...)
    "$(f.f)$UNIVARIATEFEATURE_OPENING_BRACKET$(attribute_name(f; kwargs...))$UNIVARIATEFEATURE_CLOSING_BRACKET"
end

############################################################################################

# These features collapse to a single value; this can be useful to know
is_collapsing_single_attribute_feature(f::Union{UnivariateMin,UnivariateMax,UnivariateSoftMin,UnivariateSoftMax}) = true
is_collapsing_single_attribute_feature(f::UnivariateGenericFeature) = (f.f in [minimum, maximum, mean])

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
