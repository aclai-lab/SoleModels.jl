import SoleModels: AbstractFeature, computefeature

using SoleData: AbstractDimensionalChannel, channelvariable

import Base: isequal, hash, show
import SoleLogics: syntaxstring

"""
    abstract type DimensionalFeature{U<:Real} <: AbstractFeature{U} end

Abstract type for dimensional features,
representing functions that can be computed on dimensional, geometrical worlds.
Dimensional worlds are geometric entity that live in a *dimensional* context;
for example, an `Interval` of a time series.
As an example of a dimensional feature, consider min(V1),
which computes the minimum for attribute 1 for a given world.
The value of a feature for a given world can be then evaluated in a `Condition`,
 such as: min(V1) >= 10.

See also [`Interval`](@ref), [`Interval2D`](@ref),
[`GeometricalWorld`](@ref), [`AbstractFeature`](@ref).
"""
abstract type DimensionalFeature{U<:Real} <: AbstractFeature{U} end

# const DimensionalFeatureFunction = FunctionWrapper{Number,Tuple{AbstractArray{<:Number}}}

############################################################################################

"""
    struct MultivariateFeature{U} <: DimensionalFeature{U}
        f::Function
    end

A dimensional feature represented by the application of a function to a dimensional channel.
For example, it can wrap a scalar function computing
how much a `Interval2D` world, when interpreted on an image, resembles a horse.
Note that the image has a number of spatial variables (3, for the case of RGB),
and "resembling a horse" may require a computation involving all variables.

See also [`Interval`](@ref),
[`Interval2D`](@ref),
[`AbstractUnivariateFeature`](@ref),
[`DimensionalFeature`](@ref), [`AbstractFeature`](@ref).
"""
struct MultivariateFeature{U} <: DimensionalFeature{U}
    f::Function
end
function computefeature(f::MultivariateFeature{U}, channel::AbstractDimensionalChannel{T})::U where {U<:Real,T}
    (f.f(channel))
end
syntaxstring(f::MultivariateFeature, args...; kwargs...) = "$(f.f)"

############################################################################################

"""
    abstract type AbstractUnivariateFeature{U} <: DimensionalFeature{U} end

A dimensional feature represented by the application of a function to a single variable of a
dimensional channel.
For example, it can wrap a scalar function computing
how much red a `Interval2D` world, when interpreted on an image, contains.

See also [`Interval`](@ref),
[`Interval2D`](@ref),
[`UnivariateFeature`](@ref),
[`DimensionalFeature`](@ref), [`AbstractFeature`](@ref).
"""
abstract type AbstractUnivariateFeature{U} <: DimensionalFeature{U} end

i_attribute(f::AbstractUnivariateFeature) = f.i_attribute

"""
    function attribute_name(
        f::AbstractUnivariateFeature;
        attribute_names_map::Union{Nothing,AbstractDict,AbstractVector} = nothing,
        attribute_name_prefix::Union{Nothing,String} = $(repr(UVF_VARPREFIX)),
    )::String

Return the name of the attribute targeted by a univariate feature.
By default, an attribute name is a number prefixed by $(repr(UVF_VARPREFIX));
however, `attribute_names_map` or `attribute_name_prefix` can be used to
customize attribute names.
The prefix can be customized by specifying `attribute_name_prefix`.
Alternatively, a mapping from string to integer (either via a Dictionary or a Vector)
can be passed as `attribute_names_map`.
Note that only one in `attribute_names_map` and `attribute_name_prefix` should be provided.


See also
[`parsecondition`](@ref),
[`ScalarCondition`](@ref),
[`syntaxstring`](@ref).
"""
function attribute_name(
    f::AbstractUnivariateFeature;
    attribute_names_map::Union{Nothing,AbstractDict,AbstractVector} = nothing,
    attribute_name_prefix::Union{Nothing,String} = nothing,
    kwargs..., # TODO remove this.
)
    if isnothing(attribute_names_map)
        attribute_name_prefix = isnothing(attribute_name_prefix) ? UVF_VARPREFIX : attribute_name_prefix
        "$(attribute_name_prefix)$(i_attribute(f))"
    else
        @assert isnothing(attribute_name_prefix)
        "$(attribute_names_map[i_attribute(f)])"
    end
end

function featurename(f::AbstractFeature; kwargs...)
    error("Please, provide method featurename(::$(typeof(f)); kwargs...).")
end

function syntaxstring(f::AbstractUnivariateFeature; kwargs...)
    n = attribute_name(f; kwargs...)
    ""
    "$(featurename(f))$UVF_OPENING_BRACKET$n$UVF_CLOSING_BRACKET"
end

############################################################################################

"""
    struct UnivariateFeature{U} <: AbstractUnivariateFeature{U}
        i_attribute::Integer
        f::Function
    end

A dimensional feature represented by the application of a generic function `f`
to a single variable of a dimensional channel.
For example, it can wrap a scalar function computing
how much red a `Interval2D` world, when interpreted on an image, contains.

See also [`Interval`](@ref),
[`Interval2D`](@ref),
[`AbstractUnivariateFeature`](@ref),
[`DimensionalFeature`](@ref), [`AbstractFeature`](@ref).
"""
struct UnivariateFeature{U} <: AbstractUnivariateFeature{U}
    i_attribute::Integer
    f::Function
end
function computefeature(f::UnivariateFeature{U}, channel::AbstractDimensionalChannel{T}) where {U<:Real,T}
    (f.f(SoleBase.vectorize(channelvariable(channel, f.i_attribute));))::U
end
featurename(f::UnivariateFeature) = string(f.f)

"""
    struct UnivariateNamedFeature{U} <: AbstractUnivariateFeature{U}
        i_attribute::Integer
        name::String
    end

A univariate feature solely identified by its name and reference variable.

See also [`Interval`](@ref),
[`Interval2D`](@ref),
[`AbstractUnivariateFeature`](@ref),
[`DimensionalFeature`](@ref), [`AbstractFeature`](@ref).
"""
struct UnivariateNamedFeature{U} <: AbstractUnivariateFeature{U}
    i_attribute::Integer
    name::String
end
function computefeature(f::UnivariateNamedFeature, channel::AbstractDimensionalChannel{T}) where {T}
    @error "Can't intepret UnivariateNamedFeature on any structure at all."
end
featurename(f::UnivariateNamedFeature) = f.name

############################################################################################

############################################################################################

"""
    struct UnivariateMin{U} <: AbstractUnivariateFeature{U}
        i_attribute::Integer
    end

Notable univariate feature computing the minimum value for a given variable.

See also [`Interval`](@ref),
[`Interval2D`](@ref),
[`AbstractUnivariateFeature`](@ref),
[`UnivariateMax`](@ref),
[`DimensionalFeature`](@ref), [`AbstractFeature`](@ref).
"""
struct UnivariateMin{U} <: AbstractUnivariateFeature{U}
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
function computefeature(f::UnivariateMin{U}, channel::AbstractDimensionalChannel{T}) where {U<:Real,T}
    (minimum(channelvariable(channel, f.i_attribute)))::U
end
featurename(f::UnivariateMin) = "min"

"""
    struct UnivariateMax{U} <: AbstractUnivariateFeature{U}
        i_attribute::Integer
    end

Notable univariate feature computing the maximum value for a given variable.

See also [`Interval`](@ref),
[`Interval2D`](@ref),
[`AbstractUnivariateFeature`](@ref),
[`UnivariateMin`](@ref),
[`DimensionalFeature`](@ref), [`AbstractFeature`](@ref).
"""
struct UnivariateMax{U} <: AbstractUnivariateFeature{U}
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
function computefeature(f::UnivariateMax{U}, channel::AbstractDimensionalChannel{T}) where {U<:Real,T}
    (maximum(channelvariable(channel, f.i_attribute)))::U
end
featurename(f::UnivariateMax) = "max"


############################################################################################

"""
    struct UnivariateSoftMin{U,T<:AbstractFloat} <: AbstractUnivariateFeature{U}
        i_attribute::Integer
        alpha::T
    end

Univariate feature computing a "softened" version of the minimum value for a given variable.

See also [`Interval`](@ref),
[`Interval2D`](@ref),
[`AbstractUnivariateFeature`](@ref),
[`UnivariateMin`](@ref),
[`DimensionalFeature`](@ref), [`AbstractFeature`](@ref).
"""
struct UnivariateSoftMin{U,T<:AbstractFloat} <: AbstractUnivariateFeature{U}
    i_attribute::Integer
    alpha::T
    function UnivariateSoftMin{U}(i_attribute::Integer, alpha::T) where {U<:Real,T}
        @assert !(alpha > 1.0 || alpha < 0.0) "Can't instantiate UnivariateSoftMin with alpha = $(alpha)"
        @assert !isone(alpha) "Can't instantiate UnivariateSoftMin with alpha = $(alpha). Use UnivariateMin instead!"
        new{U,T}(i_attribute, alpha)
    end
end
alpha(f::UnivariateSoftMin) = f.alpha
featurename(f::UnivariateSoftMin) = "min" * utils.subscriptnumber(rstrip(rstrip(string(f.alpha*100), '0'), '.'))
function computefeature(f::UnivariateSoftMin{U}, channel::AbstractDimensionalChannel{T}) where {U<:Real,T}
    utils.softminimum(channelvariable(channel, f.i_attribute), f.alpha)::U
end


"""
    struct UnivariateSoftMax{U,T<:AbstractFloat} <: AbstractUnivariateFeature{U}
        i_attribute::Integer
        alpha::T
    end

Univariate feature computing a "softened" version of the maximum value for a given variable.

See also [`Interval`](@ref),
[`Interval2D`](@ref),
[`AbstractUnivariateFeature`](@ref),
[`UnivariateMax`](@ref),
[`DimensionalFeature`](@ref), [`AbstractFeature`](@ref).
"""
struct UnivariateSoftMax{U,T<:AbstractFloat} <: AbstractUnivariateFeature{U}
    i_attribute::Integer
    alpha::T
    function UnivariateSoftMax{U}(i_attribute::Integer, alpha::T) where {U<:Real,T}
        @assert !(alpha > 1.0 || alpha < 0.0) "Can't instantiate UnivariateSoftMax with alpha = $(alpha)"
        @assert !isone(alpha) "Can't instantiate UnivariateSoftMax with alpha = $(alpha). Use UnivariateMax instead!"
        new{U,T}(i_attribute, alpha)
    end
end
alpha(f::UnivariateSoftMax) = f.alpha
featurename(f::UnivariateSoftMax) = "max" * utils.subscriptnumber(rstrip(rstrip(string(f.alpha*100), '0'), '.'))
function computefeature(f::UnivariateSoftMax{U}, channel::AbstractDimensionalChannel{T}) where {U<:Real,T}
    utils.softmaximum(channelvariable(channel, f.i_attribute), f.alpha)::U
end

# simplified propositional cases:
function computefeature(f::UnivariateSoftMin{U}, channel::AbstractDimensionalChannel{T,1}) where {U<:Real,T}
    channelvariable(channel, f.i_attribute)::U
end
function computefeature(f::UnivariateSoftMax{U}, channel::AbstractDimensionalChannel{T,1}) where {U<:Real,T}
    channelvariable(channel, f.i_attribute)::U
end

############################################################################################

# These features collapse to a single value; it can be useful to know this
is_collapsing_univariate_feature(f::Union{UnivariateMin,UnivariateMax,UnivariateSoftMin,UnivariateSoftMax}) = true
is_collapsing_univariate_feature(f::UnivariateFeature) = (f.f in [minimum, maximum, mean])

