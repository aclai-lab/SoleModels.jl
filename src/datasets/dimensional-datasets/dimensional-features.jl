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
which computes the minimum for variable 1 for a given world.
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

i_variable(f::AbstractUnivariateFeature) = f.i_variable

"""
    function variable_name(
        f::AbstractUnivariateFeature;
        variable_names_map::Union{Nothing,AbstractDict,AbstractVector} = nothing,
        variable_name_prefix::Union{Nothing,String} = $(repr(UVF_VARPREFIX)),
    )::String

Return the name of the variable targeted by a univariate feature.
By default, an variable name is a number prefixed by $(repr(UVF_VARPREFIX));
however, `variable_names_map` or `variable_name_prefix` can be used to
customize variable names.
The prefix can be customized by specifying `variable_name_prefix`.
Alternatively, a mapping from string to integer (either via a Dictionary or a Vector)
can be passed as `variable_names_map`.
Note that only one in `variable_names_map` and `variable_name_prefix` should be provided.


See also
[`parsecondition`](@ref),
[`ScalarCondition`](@ref),
[`syntaxstring`](@ref).
"""
function variable_name(
    f::AbstractUnivariateFeature;
    variable_names_map::Union{Nothing,AbstractDict,AbstractVector} = nothing,
    variable_name_prefix::Union{Nothing,String} = nothing,
    kwargs..., # TODO remove this.
)
    if isnothing(variable_names_map)
        variable_name_prefix = isnothing(variable_name_prefix) ? UVF_VARPREFIX : variable_name_prefix
        "$(variable_name_prefix)$(i_variable(f))"
    else
        @assert isnothing(variable_name_prefix)
        "$(variable_names_map[i_variable(f)])"
    end
end

function featurename(f::AbstractFeature; kwargs...)
    error("Please, provide method featurename(::$(typeof(f)); kwargs...).")
end

function syntaxstring(f::AbstractUnivariateFeature; kwargs...)
    n = variable_name(f; kwargs...)
    ""
    "$(featurename(f))$UVF_OPENING_BRACKET$n$UVF_CLOSING_BRACKET"
end

############################################################################################

"""
    struct UnivariateFeature{U} <: AbstractUnivariateFeature{U}
        i_variable::Integer
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
    i_variable::Integer
    f::Function
end
function computefeature(f::UnivariateFeature{U}, channel::AbstractDimensionalChannel{T}) where {U<:Real,T}
    (f.f(SoleBase.vectorize(channelvariable(channel, f.i_variable));))::U
end
featurename(f::UnivariateFeature) = string(f.f)

"""
    struct UnivariateNamedFeature{U} <: AbstractUnivariateFeature{U}
        i_variable::Integer
        name::String
    end

A univariate feature solely identified by its name and reference variable.

See also [`Interval`](@ref),
[`Interval2D`](@ref),
[`AbstractUnivariateFeature`](@ref),
[`DimensionalFeature`](@ref), [`AbstractFeature`](@ref).
"""
struct UnivariateNamedFeature{U} <: AbstractUnivariateFeature{U}
    i_variable::Integer
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
        i_variable::Integer
    end

Notable univariate feature computing the minimum value for a given variable.

See also [`Interval`](@ref),
[`Interval2D`](@ref),
[`AbstractUnivariateFeature`](@ref),
[`UnivariateMax`](@ref),
[`DimensionalFeature`](@ref), [`AbstractFeature`](@ref).
"""
struct UnivariateMin{U} <: AbstractUnivariateFeature{U}
    i_variable::Integer
    function UnivariateMin{U}(i_variable::Integer) where {U<:Real}
        return new{U}(i_variable)
    end
    function UnivariateMin(i_variable::Integer)
        @warn "Please specify the type of the feature for UnivariateMin." *
            " For example: UnivariateMin{Float64}($(i_variable))."
        return UnivariateMin{Real}(i_variable)
    end
end
function computefeature(f::UnivariateMin{U}, channel::AbstractDimensionalChannel{T}) where {U<:Real,T}
    (minimum(channelvariable(channel, f.i_variable)))::U
end
featurename(f::UnivariateMin) = "min"

"""
    struct UnivariateMax{U} <: AbstractUnivariateFeature{U}
        i_variable::Integer
    end

Notable univariate feature computing the maximum value for a given variable.

See also [`Interval`](@ref),
[`Interval2D`](@ref),
[`AbstractUnivariateFeature`](@ref),
[`UnivariateMin`](@ref),
[`DimensionalFeature`](@ref), [`AbstractFeature`](@ref).
"""
struct UnivariateMax{U} <: AbstractUnivariateFeature{U}
    i_variable::Integer
    function UnivariateMax{U}(i_variable::Integer) where {U<:Real}
        return new{U}(i_variable)
    end
    function UnivariateMax(i_variable::Integer)
        @warn "Please specify the type of the feature for UnivariateMax." *
            " For example: UnivariateMax{Float64}($(i_variable))."
        return UnivariateMax{Real}(i_variable)
    end
end
function computefeature(f::UnivariateMax{U}, channel::AbstractDimensionalChannel{T}) where {U<:Real,T}
    (maximum(channelvariable(channel, f.i_variable)))::U
end
featurename(f::UnivariateMax) = "max"


############################################################################################

"""
    struct UnivariateSoftMin{U,T<:AbstractFloat} <: AbstractUnivariateFeature{U}
        i_variable::Integer
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
    i_variable::Integer
    alpha::T
    function UnivariateSoftMin{U}(i_variable::Integer, alpha::T) where {U<:Real,T}
        @assert !(alpha > 1.0 || alpha < 0.0) "Can't instantiate UnivariateSoftMin with alpha = $(alpha)"
        @assert !isone(alpha) "Can't instantiate UnivariateSoftMin with alpha = $(alpha). Use UnivariateMin instead!"
        new{U,T}(i_variable, alpha)
    end
end
alpha(f::UnivariateSoftMin) = f.alpha
featurename(f::UnivariateSoftMin) = "min" * utils.subscriptnumber(rstrip(rstrip(string(f.alpha*100), '0'), '.'))
function computefeature(f::UnivariateSoftMin{U}, channel::AbstractDimensionalChannel{T}) where {U<:Real,T}
    utils.softminimum(channelvariable(channel, f.i_variable), f.alpha)::U
end


"""
    struct UnivariateSoftMax{U,T<:AbstractFloat} <: AbstractUnivariateFeature{U}
        i_variable::Integer
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
    i_variable::Integer
    alpha::T
    function UnivariateSoftMax{U}(i_variable::Integer, alpha::T) where {U<:Real,T}
        @assert !(alpha > 1.0 || alpha < 0.0) "Can't instantiate UnivariateSoftMax with alpha = $(alpha)"
        @assert !isone(alpha) "Can't instantiate UnivariateSoftMax with alpha = $(alpha). Use UnivariateMax instead!"
        new{U,T}(i_variable, alpha)
    end
end
alpha(f::UnivariateSoftMax) = f.alpha
featurename(f::UnivariateSoftMax) = "max" * utils.subscriptnumber(rstrip(rstrip(string(f.alpha*100), '0'), '.'))
function computefeature(f::UnivariateSoftMax{U}, channel::AbstractDimensionalChannel{T}) where {U<:Real,T}
    utils.softmaximum(channelvariable(channel, f.i_variable), f.alpha)::U
end

# simplified propositional cases:
function computefeature(f::UnivariateSoftMin{U}, channel::AbstractDimensionalChannel{T,1}) where {U<:Real,T}
    channelvariable(channel, f.i_variable)::U
end
function computefeature(f::UnivariateSoftMax{U}, channel::AbstractDimensionalChannel{T,1}) where {U<:Real,T}
    channelvariable(channel, f.i_variable)::U
end

############################################################################################

# These features collapse to a single value; it can be useful to know this
is_collapsing_univariate_feature(f::Union{UnivariateMin,UnivariateMax,UnivariateSoftMin,UnivariateSoftMax}) = true
is_collapsing_univariate_feature(f::UnivariateFeature) = (f.f in [minimum, maximum, mean])

