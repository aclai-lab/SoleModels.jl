import SoleModels: parsecondition

using StatsBase

#= ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Code purpose ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Parse a string "min[V189] <= 250" into the corresponding ScalarCondition `parsecondition`.

A ScalarCondition is built of three parts; for example, the ScalarCondition above has:
    1) feature          ->      UnivariateMin(189),
    2) test_operator    ->      <=,
    3) threshold        ->      250,
which are assembled by `ScalarCondition(ScalarMetaCondition(feature, test_operator), threshold)`.

`parsecondition` can be used within SoleLogics to recognize Proposition{ScalarCondition},
when parsing a logical expression:
    SoleLogics.parseformulatree(
        "min[V189] <= 250 ∧ min[V37] > 20"; proposition_parser = parsecondition);
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ =#

"""
Aliases for specific features used for parsing `ScalarCondition`s.
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

DEFAULT_FEATVALTYPE = Float64

"""
    parsecondition(
        expression::String;
        featvaltype::Type = $(DEFAULT_FEATVALTYPE),
        opening_bracket::String = $(repr(UVF_OPENING_BRACKET)),
        closing_bracket::String = $(repr(UVF_CLOSING_BRACKET)),
        custom_feature_aliases = Dict{String,Union{Type,Function}}(),
        variable_names_map::Union{Nothing,AbstractDict,AbstractVector} = nothing,
        variable_name_prefix::Union{Nothing,String} = nothing,
    )::ScalarCondition

Return a `ScalarCondition` which is the result of parsing `expression`.
This can be integrated with the `SoleLogics` parsing system (see Examples section).
Currently, this function can only parse `UnivariateFeature`s; for example, "min[V189]",
which is parsed as `UnivariateMin(189)`.

With $(repr(UVF_OPENING_BRACKET)) and
$(repr(UVF_CLOSING_BRACKET)) for **opening\\_bracket** and
**closing\\_bracket**, respectively,
each `ScalarCondition` is shaped as follows:

    `"**feature[variable] test\\_operator threshold.**""`

where:
- *feature* is the name of a Julia `Function` (such as `minimum` or `maximum`),
    whose return type is `featvaltype`;
- *variable* is the name of a dataset variable;
- *test\\_operator* is a Julia `Function` for binary comparison (e.g., `[<=, >]`);
- *threshold* is a scalar value of type `featvaltype` to be compared with the
    computed feature value.

# Arguments
- `expression::String`: the string to be parsed;
- `featvaltype::Type`: type of the value wrapped by the feature;
- `opening_bracket::String = $(repr(UVF_OPENING_BRACKET))`: the feature's opening bracket;
- `closing_bracket::String = $(repr(UVF_CLOSING_BRACKET))`: the feature's closing bracket;
- `custom_feature_aliases = Dict{String,Union{Type,Function}}`: mapping from string
    to feature types (or Julia `Function`s), for correctly recognizing
    custom features/functions;
    if not provided, `SoleModels.BASE_FEATURE_ALIASES` will be used.

`variable_names_map`, `variable_name_prefix` can influence the
parsing of the variable name; please, refer to `variable_name` for their behavior.

# Examples
```julia-repl
julia> syntaxstring(SoleModels.parsecondition("min[V1] <= 32"))
"min[V1] <= 32.0"

julia> syntaxstring(parseformulatree("min[V1] <= 15 ∧ max[V1] >= 85"; proposition_parser=(x)->parsecondition(x; featvaltype = Int64,)))
"min[V1] <= 15 ∧ max[V1] >= 85"
```

See also
[`variable_name`](@ref),
[`ScalarCondition`](@ref),
[`ScalarMetaCondition`](@ref),
[`parseformulatree`](@ref),
[`syntaxstring`](@ref).
"""
function parsecondition(
    expression::String;
    featvaltype::Union{Nothing,Type} = nothing,
    opening_bracket::String = UVF_OPENING_BRACKET,
    closing_bracket::String = UVF_CLOSING_BRACKET,
    custom_feature_aliases = Dict{String,Union{Type,Function}}(),
    variable_names_map::Union{Nothing,AbstractDict,AbstractVector} = nothing,
    variable_name_prefix::Union{Nothing,String} = nothing,
)
    @assert isnothing(variable_names_map) || isnothing(variable_name_prefix) "" *
        "Cannot parse variable with both variable_names_map and variable_name_prefix." *
        " (expression = $(repr(expression)))"

    if isnothing(featvaltype)
        featvaltype = DEFAULT_FEATVALTYPE
        @warn "Please, specify a type for the feature values (featvaltype = ...)." *
            " $(featvaltype) will be used, but note that this may raise type errors." *
            " (expression = $(repr(expression)))"
    end

    @assert length(opening_bracket) == 1 || length(closing_bracket)
        "Brackets must be single-character strings!" *
        " $(repr(opening_bracket)) and $(repr(closing_bracket)) encountered."

    featdict = merge(BASE_FEATURE_ALIASES, custom_feature_aliases)

    (_feature, _variable, _test_operator, _threshold) = begin
        # 4 slices are found initially in this order:
        #   1) a feature name (e.g. "min"),
        #   2) an variable inside feature's brackets (e.g. "[V189]"),
        #   3) a test operator ("<=", ">=", "<" or ">"),
        #   4) a threshold value.
        # Regex is more or less:
        # (\w*) *(\[.*\]) *(<=|>=|<|>) *(\d*).
        variable_name_prefix = isnothing(variable_name_prefix) &&
            isnothing(variable_names_map) ? UVF_VARPREFIX : variable_name_prefix
        variable_name_prefix = isnothing(variable_name_prefix) ? "" : variable_name_prefix

        r = Regex("^\\s*(\\w+)\\s*\\$(opening_bracket)\\s*$(variable_name_prefix)(\\S+)\\s*\\$(closing_bracket)\\s*([^\\s\\d]+)\\s*(\\S+)\\s*\$")
        # r = Regex("^\\s*(\\w+)\\s*\\$(opening_bracket)\\s*$(variable_name_prefix)(\\S+)\\s*\\$(closing_bracket)\\s*(\\S+)\\s+(\\S+)\\s*\$")
        slices = string.(match(r, expression))

        # Assert for malformed strings (e.g. "123.4<avg[V189]>250.2")
        @assert length(slices) == 4 "Could not parse condition from" *
            " expression $(repr(expression))."

        (slices[1], slices[2], slices[3], slices[4])
    end

    threshold, featvaltype = begin
        if isconcretetype(featvaltype)
            threshold = tryparse(featvaltype, _threshold)
            if isnothing(threshold)
                error("Could not parse condition from" *
                    " expression `$expression`: could not parse" *
                    " $(repr(_threshold)) as $(featvaltype)")
            end
            threshold, featvaltype
        else
            threshold = nothing
            # threshold = isnothing(threshold) ? tryparse(Int, _threshold)     : threshold
            threshold = isnothing(threshold) ? tryparse(Float64, _threshold) : threshold
            if threshold isa featvaltype
                @warn "Please, specify a concrete type for the feature values" *
                    " (featvaltype = ...); $(typeof(threshold)) was inferred."
            else
                error("Could not correctly infer feature value type from" *
                    " threshold $(repr(_threshold)) ($(typeof(threshold)) was inferred)." *
                    " Please, specify a concrete type for the feature values" *
                    " (featvaltype = ...).")
            end
            threshold, typeof(threshold)
        end
    end

    feature = begin
        i_var = begin
            if isnothing(variable_names_map)
                parse(Int, _variable)
            elseif variable_names_map isa Union{AbstractDict,AbstractVector}
                findfirst(variable_names_map, variable)
            else
                error("Unexpected variable_names_map of type $(typeof(variable_names_map))" *
                    " encountered.")
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

    test_operator = eval(Meta.parse(_test_operator))
    metacond = ScalarMetaCondition(feature, test_operator)

    return ScalarCondition(metacond, threshold)
end
