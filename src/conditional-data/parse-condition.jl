using StatsBase

#= ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Code purpose ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Given a string "min[A189] <= 250", build the corresponding
FeatCondition using a method `parsecondition`.

A FeatCondition is built of three parts
    1) feature          is      UnivariateMin(189),
    2) metacondition    is      SoleModels.FeatMetaCondition(feature, >),
    3) threshold        is      250,
which are assembled by the constructor SoleModels.FeatCondition(metacondition, threshold).

We want to recognize Proposition{FeatCondition} while parsing an expression;
this can be done by integrating `parsecondition` with SoleLogics parsing system:
    SoleLogics.parseformulatree(
        "min[189] <= 250 ∧ min[189] <= 250", proposition_parser = parsecondition);
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ =#

const UVF_OPENING_BRACKET = Symbol(UNIVARIATEFEATURE_OPENING_BRACKET)
const UVF_CLOSING_BRACKET = Symbol(UNIVARIATEFEATURE_CLOSING_BRACKET)

# Shortcuts for feature names
const _BASE_FEATURES = Dict{String,Union{Type,Function}}(
    #
    "minimum" => UnivariateMin,
    "min"     => UnivariateMin,
    "maximum" => UnivariateMax,
    "max"     => UnivariateMax,
    #
    "avg"     => StatsBase.mean,
    "mean"    => StatsBase.mean,
)

"""
    parsecondition(
        expression::String;
        featvaltype = Real,
        opening_bracket::Union{String,Symbol} = UVF_OPENING_BRACKET,
        closing_bracket::Union{String,Symbol} = UVF_CLOSING_BRACKET,
        additional_shortcuts = Dict{String,Union{Type,Function}}()
    )

Return a `FeatCondition` which is the result of parsing `expression`.
This can be integrated with the `SoleLogics` parsing system (see Examples section).
Each `FeatCondition` is shaped as follows (whitespaces are not relevant):

**feature\\_name opening\\_bracket attribute closing\\_bracket operator threshold.**

* *feature\\_name* can be a julia Function (such as `minimum` or `maximum`),
    whose return type is `featvaltype`;
* *opening\\_bracket* and *closing\\_bracket* wrap the attribute; defaulted
    to `$(repr(UVF_OPENING_BRACKET))`, `$(repr(UVF_CLOSING_BRACKET))`;
* *attribute* is a key label to access data of `featvaltype` type;
* *operator* is an element of `[<=, >=, <, >]`;
* *threshold* is a value to be compared with the data wrapped by attribute.

# Arguments
- `expression::String`: the string to be parsed;
- `featvaltype`: type of the value wrapped by the feature;
- `opening_bracket::Union{String,Symbol} = $(repr(UVF_OPENING_BRACKET))`: the feature's opening bracket;
- `closing_bracket::Union{String,Symbol} = $(repr(UVF_CLOSING_BRACKET))`: the feature's closing bracket;
- `additional_shortcuts = Dict{String,Union{Type,Function}}`: mapping of strings
    to functions, needed to correctly recognize functions that are not available by default.

# Examples
```julia-repl
julia> syntaxstring(SoleModels.parsecondition("min[1] <= 32"))
"min[V1] <= 32.0"

julia> syntaxstring(parseformulatree("min[1] <= 15 ∧ max[1] >= 85"; proposition_parser=(x)->parsecondition(x; featvaltype = Int64,)))
"min[V1] <= 15 ∧ max[V1] >= 85"
```
"""
function parsecondition(
    expression::String;
    featvaltype::Union{Nothing,Type} = nothing,
    opening_bracket::Union{String,Symbol} = UVF_OPENING_BRACKET,
    closing_bracket::Union{String,Symbol} = UVF_CLOSING_BRACKET,
    additional_shortcuts = Dict{String,Union{Type,Function}}()
)
    if isnothing(featvaltype)
        @warn "Please, specify a type for the feature values (featvaltype = ...)." *
            " Float64 will be used, but note that this may raise type errors."
        featvaltype = Float64
    end

    @assert length(string(opening_bracket)) == 1 || length(string(closing_bracket))
        "Brackets must be single-character strings."
    opening_bracket = Symbol(opening_bracket)
    closing_bracket = Symbol(closing_bracket)

    featdict = merge(_BASE_FEATURES, additional_shortcuts)

    # Get a string;
    # return (if possible) a Tuple containing 4 substrings:
    #   [feature, attribute, operator, threshold].
    function _cut(expression::String)::NTuple{4, String}
        # 4 slices are found initially in this order:
        #   1) a feature name (e.g. "min"),
        #   2) an attribute inside feature's brackets (e.g. "[A189]"),
        #   3) an operator ("<=", ">=", "<" or ">"),
        #   4) a threshold value.
        # Regex is (consider "[", "]" as `opening_bracket` and `closing_bracket`):
        # (\w*) *(\[.*\]) *(<=|>=|<|>) *(\d*).
        expression = filter(x -> !isspace(x), expression)
        r = Regex("(\\w*) *(\\$(opening_bracket).*\\$(closing_bracket)) *(<=|>=|<|>)(.*)")
        slices = string.(match(r, expression))

        # Assert for malformed strings (e.g. "123.4<avg[189]>250.2")
        @assert sum([length(x) for x in slices]) == length(expression) &&
            length(slices) == 4 "Expression $expression is not formatted properly. " *
            "Correct formatting is: feature$(opening_bracket)attribute" *
            "$(closing_bracket) operator threshold."

        @assert (string(slices[2][1]) == string(opening_bracket) &&
            string(slices[2][end]) == string(closing_bracket))
            "Malformed brackets in $(slices[2])."

        # Return tuple is: (feature, attribute, test_operator, threshold)
        return (slices[1], string(chop(slices[2], head=1, tail=1)), slices[3], slices[4])
    end

    (_feature, _attribute, _test_operator, _threshold) = _cut(expression)

    threshold, featvaltype = begin
        if isconcretetype(featvaltype)
            parse(featvaltype, _threshold), featvaltype
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

    i_attr = parse(Int, _attribute)
    feature = begin
        if haskey(featdict, strip(lowercase(_feature)))
            # If it is a known feature get it as
            #  a type (e.g., `UnivariateMin`), or Julia function (e.g., `minimum`).
            feat_or_fun = featdict[strip(lowercase(_feature))]
            feat_or_fun = begin
                # If it is a function, wrap it into a UnivariateGenericFeature
                #  otherwise, it is a feature, and it is used as a constructor.
                if feat_or_fun isa Function
                    UnivariateGenericFeature{featvaltype}(i_attr, feat_or_fun)
                else
                    feat_or_fun{featvaltype}(i_attr)
                end
            end
            feat_or_fun
        else
            # If it is not a known feature, interpret it as a Julia function,
            #  and wrap it into a UnivariateGenericFeature.
            f = eval(Meta.parse(_feature))
            UnivariateGenericFeature{featvaltype}(i_attr, f)
        end
    end
    test_operator = eval(Meta.parse(_test_operator))
    metacond = FeatMetaCondition(feature, test_operator)

    return FeatCondition(metacond, threshold)
end
