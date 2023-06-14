import SoleModels: AbstractFeature

using SoleData: AbstractDimensionalChannel, channelvariable

import Base: isequal, hash, show
import SoleLogics: syntaxstring

# Feature brackets
const UVF_OPENING_BRACKET = "["
const UVF_CLOSING_BRACKET = "]"
# Default prefix for variables
const UVF_VARPREFIX = "V"

"""
    abstract type VarFeature{U} <: AbstractFeature end

Abstract type for feature functions that can be applied on (multi)variate data.

See also [`featvaltype`](@ref), [`computefeature`](@ref).
"""
abstract type VarFeature{U} <: AbstractFeature end

DEFAULT_VARFEATVALTYPE = Real


"""
    featvaltype(::Type{<:VarFeature{U}}) where {U} = U
    featvaltype(::VarFeature{U}) where {U} = U

Return the output type of the feature function.

See also [`AbstractWorld`](@ref).
"""
featvaltype(::Type{<:VarFeature{U}}) where {U} = U
featvaltype(::VarFeature{U}) where {U} = U

"""
    computefeature(f::VarFeature{U}, channel; kwargs...)::U where {U}

Compute a feature on a channel (i.e., world reading) of an instance.

See also [`VarFeature`](@ref).
"""
function computefeature(f::VarFeature{U}, channel; kwargs...) where {U}
    error("Please, provide method computefeature(::$(typeof(f)), channel::$(typeof(channel)); kwargs...)::U.")
end

@inline (f::AbstractFeature)(args...) = computefeature(f, args...)

############################################################################################

"""
    struct MultivariateFeature{U} <: VarFeature{U}
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
[`VarFeature`](@ref), [`AbstractFeature`](@ref).
"""
struct MultivariateFeature{U} <: VarFeature{U}
    f::Function
end
function computefeature(f::MultivariateFeature{U}, channel::AbstractDimensionalChannel{T})::U where {U,T}
    (f.f(channel))
end
syntaxstring(f::MultivariateFeature, args...; kwargs...) = "$(f.f)"

############################################################################################

"""
    abstract type AbstractUnivariateFeature{U} <: VarFeature{U} end

A dimensional feature represented by the application of a function to a single variable of a
dimensional channel.
For example, it can wrap a scalar function computing
how much red a `Interval2D` world, when interpreted on an image, contains.

See also [`Interval`](@ref),
[`Interval2D`](@ref),
[`UnivariateFeature`](@ref),
[`VarFeature`](@ref), [`AbstractFeature`](@ref).
"""
abstract type AbstractUnivariateFeature{U} <: VarFeature{U} end

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

function syntaxstring(
    f::AbstractUnivariateFeature;
    opening_bracket::String = UVF_OPENING_BRACKET,
    closing_bracket::String = UVF_CLOSING_BRACKET,
    kwargs...
)
    n = variable_name(f; kwargs...)
    "$(featurename(f))$opening_bracket$n$closing_bracket"
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
[`VarFeature`](@ref), [`AbstractFeature`](@ref).
"""
struct UnivariateFeature{U} <: AbstractUnivariateFeature{U}
    i_variable::Integer
    f::Function
end
function computefeature(f::UnivariateFeature{U}, channel::AbstractDimensionalChannel{T}) where {U,T}
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
[`VarFeature`](@ref), [`AbstractFeature`](@ref).
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

"""
    struct UnivariateMin{U} <: AbstractUnivariateFeature{U}
        i_variable::Integer
    end

Notable univariate feature computing the minimum value for a given variable.

See also [`Interval`](@ref),
[`Interval2D`](@ref),
[`AbstractUnivariateFeature`](@ref),
[`UnivariateMax`](@ref),
[`VarFeature`](@ref), [`AbstractFeature`](@ref).
"""
struct UnivariateMin{U} <: AbstractUnivariateFeature{U}
    i_variable::Integer
    function UnivariateMin{U}(i_variable::Integer) where {U<:Real}
        return new{U}(i_variable)
    end
    function UnivariateMin(i_variable::Integer)
        @warn "Please specify the feature value type for UnivariateMin. " *
            "For example: UnivariateMin{Float64}($(i_variable))."
        return UnivariateMin{DEFAULT_VARFEATVALTYPE}(i_variable)
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
[`VarFeature`](@ref), [`AbstractFeature`](@ref).
"""
struct UnivariateMax{U} <: AbstractUnivariateFeature{U}
    i_variable::Integer
    function UnivariateMax{U}(i_variable::Integer) where {U<:Real}
        return new{U}(i_variable)
    end
    function UnivariateMax(i_variable::Integer)
        @warn "Please specify the feature value type for UnivariateMax. " *
            "For example: UnivariateMax{Float64}($(i_variable))."
        return UnivariateMax{DEFAULT_VARFEATVALTYPE}(i_variable)
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
[`VarFeature`](@ref), [`AbstractFeature`](@ref).
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
[`VarFeature`](@ref), [`AbstractFeature`](@ref).
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


_st_featop_abbr(f::UnivariateMin,     ::typeof(≥); kwargs...) = "$(variable_name(f; kwargs...)) ⪴"
_st_featop_abbr(f::UnivariateMax,     ::typeof(≤); kwargs...) = "$(variable_name(f; kwargs...)) ⪳"
_st_featop_abbr(f::UnivariateSoftMin, ::typeof(≥); kwargs...) = "$(variable_name(f; kwargs...)) $("⪴" * utils.subscriptnumber(rstrip(rstrip(string(alpha(f)*100), '0'), '.')))"
_st_featop_abbr(f::UnivariateSoftMax, ::typeof(≤); kwargs...) = "$(variable_name(f; kwargs...)) $("⪳" * utils.subscriptnumber(rstrip(rstrip(string(alpha(f)*100), '0'), '.')))"

_st_featop_abbr(f::UnivariateMin,     ::typeof(<); kwargs...) = "$(variable_name(f; kwargs...)) ⪶"
_st_featop_abbr(f::UnivariateMax,     ::typeof(>); kwargs...) = "$(variable_name(f; kwargs...)) ⪵"
_st_featop_abbr(f::UnivariateSoftMin, ::typeof(<); kwargs...) = "$(variable_name(f; kwargs...)) $("⪶" * utils.subscriptnumber(rstrip(rstrip(string(alpha(f)*100), '0'), '.')))"
_st_featop_abbr(f::UnivariateSoftMax, ::typeof(>); kwargs...) = "$(variable_name(f; kwargs...)) $("⪵" * utils.subscriptnumber(rstrip(rstrip(string(alpha(f)*100), '0'), '.')))"

_st_featop_abbr(f::UnivariateMin,     ::typeof(≤); kwargs...) = "$(variable_name(f; kwargs...)) ↘"
_st_featop_abbr(f::UnivariateMax,     ::typeof(≥); kwargs...) = "$(variable_name(f; kwargs...)) ↗"
_st_featop_abbr(f::UnivariateSoftMin, ::typeof(≤); kwargs...) = "$(variable_name(f; kwargs...)) $("↘" * utils.subscriptnumber(rstrip(rstrip(string(alpha(f)*100), '0'), '.')))"
_st_featop_abbr(f::UnivariateSoftMax, ::typeof(≥); kwargs...) = "$(variable_name(f; kwargs...)) $("↗" * utils.subscriptnumber(rstrip(rstrip(string(alpha(f)*100), '0'), '.')))"

############################################################################################

import SoleModels: parsefeature

using StatsBase

"""
Syntaxstring aliases for specific features
"""
const BASE_FEATURE_ALIASES = Dict{String,Union{Type,Function}}(
    #
    "minimum" => UnivariateMin,
    "min"     => UnivariateMin,
    "maximum" => UnivariateMax,
    "max"     => UnivariateMax,
    #
    "avg"     => StatsBase.mean,
    "mean"    => StatsBase.mean,
)

function parsefeature(
    ::Type{FT},
    expression::String;
    featvaltype::Union{Nothing,Type} = nothing,
    kwargs...
) where {FT<:VarFeature}
    if isnothing(featvaltype)
        featvaltype = DEFAULT_VARFEATVALTYPE
        @warn "Please, specify a type for the feature values (featvaltype = ...). " *
            "$(featvaltype) will be used, but note that this may raise type errors. " *
            "(expression = $(repr(expression)))"
    end
    _parsefeature(FT{featvaltype}, expression; kwargs...)
end

function parsefeature(
    ::Type{FT},
    expression::String;
    featvaltype::Union{Nothing,Type} = nothing,
    kwargs...
) where {U,FT<:VarFeature{U}}
    @assert isnothing(featvaltype) || featvaltype == U "Cannot parse feature of type $(FT) with " *
        "featvaltype = $(featvaltype). (expression = $(repr(expression)))"
    _parsefeature(FT, expression; kwargs...)
end

function _parsefeature(
    ::Type{FT},
    expression::String;
    opening_bracket::String = UVF_OPENING_BRACKET,
    closing_bracket::String = UVF_CLOSING_BRACKET,
    custom_feature_aliases = Dict{String,Union{Type,Function}}(),
    variable_names_map::Union{Nothing,AbstractDict,AbstractVector} = nothing,
    variable_name_prefix::Union{Nothing,String} = nothing,
    kwargs...
) where {U,FT<:VarFeature{U}}
    @assert isnothing(variable_names_map) || isnothing(variable_name_prefix) "" *
        "Cannot parse variable with both variable_names_map and variable_name_prefix. " *
        "(expression = $(repr(expression)))"

    featvaltype = U

    @assert length(opening_bracket) == 1 || length(closing_bracket)
        "Brackets must be single-character strings! " *
        "$(repr(opening_bracket)) and $(repr(closing_bracket)) encountered."

    featdict = merge(BASE_FEATURE_ALIASES, custom_feature_aliases)

    variable_name_prefix = isnothing(variable_name_prefix) &&
        isnothing(variable_names_map) ? UVF_VARPREFIX : variable_name_prefix
    variable_name_prefix = isnothing(variable_name_prefix) ? "" : variable_name_prefix

    r = Regex("^\\s*(\\w+)\\s*\\$(opening_bracket)\\s*$(variable_name_prefix)(\\S+)\\s*\\$(closing_bracket)\\s*\$")
    slices = match(r, expression)

    # Assert for malformed strings (e.g. "123.4<avg[V189]>250.2")
    @assert !isnothing(slices) && length(slices) == 2 "Could not parse variable " *
        "feature from expression $(repr(expression))."

    slices = string.(slices)
    (_feature, _variable) = (slices[1], slices[2])

    feature = begin
        i_var = begin
            if isnothing(variable_names_map)
                parse(Int, _variable)
            elseif variable_names_map isa Union{AbstractDict,AbstractVector}
                i_var = findfirst(variable_names_map, variable)
                @assert !isnothing(i_var) "Could not find variable $variable in the " *
                    "specified map. ($(@show variable_names_map))"
            else
                error("Unexpected variable_names_map of type $(typeof(variable_names_map)) " *
                    "encountered.")
            end
        end
        if haskey(featdict, _feature)
            # If it is a known feature get it as
            #  a type (e.g., `UnivariateMin`), or Julia function (e.g., `minimum`).
            feat_or_fun = featdict[_feature]
            # If it is a function, wrap it into a UnivariateFeature
            #  otherwise, it is a feature, and it is used as a constructor.
            if feat_or_fun isa Function
                UnivariateFeature{featvaltype}(i_var, feat_or_fun)
            else
                feat_or_fun{featvaltype}(i_var)
            end
        else
            # If it is not a known feature, interpret it as a Julia function,
            #  and wrap it into a UnivariateFeature.
            f = eval(Meta.parse(_feature))
            UnivariateFeature{featvaltype}(i_var, f)
        end
    end

    # if !(feature isa FT)
    #     @warn "Could not parse expression $(repr(expression)) as feature of type $(FT); " *
    #         " $(typeof(feature)) was used."
    # end

    return feature
end
