using StatsBase

#= ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Code purpose ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Given a string "min[A189] <= 250", build the corresponding
FeatCondition using a method `parsecondition`.

A FeatCondition is built of three parts
    1) feature          is      SingleAttributeMin(189),
    2) metacondition    is      SoleModels.FeatMetaCondition(feature, >),
    3) threshold        is      250,
which are assembled by the constructor SoleModels.FeatCondition(metacondition, threshold).

We want to recognize Proposition{FeatCondition} while parsing an expression;
this can be done by integrating `parsecondition` with SoleLogics parsing system:
    SoleLogics.parseformulatree(
        "min[189] <= 250 ∧ min[189] <= 250", proposition_parser = parsecondition);
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ =#

# Feature brackets
const _OPENING_BRACKET = "["
const _CLOSING_BRACKET = "]"

const OPENING_BRACKET = Symbol(_OPENING_BRACKET)
const CLOSING_BRACKET = Symbol(_CLOSING_BRACKET)

# Shortcuts for feature names
const _BASE_FEATURES = Dict{String,Union{Type,Function}}(
    #
    "minimum" => SingleAttributeMin,
    "min"     => SingleAttributeMin,
    "maximum" => SingleAttributeMax,
    "max"     => SingleAttributeMax,
    #
    "avg"     => StatsBase.mean,
    "mean"    => StatsBase.mean,
)

"""
    parsecondition(
        expression::String;
        featvaltype = Real,
        opening_bracket::Union{String,Symbol} = OPENING_BRACKET,
        closing_bracket::Union{String,Symbol} = CLOSING_BRACKET,
        additional_shortcuts = Dict{String,Union{Type,Function}}()
    )

Returns a `FeatCondition` which is the result of parsing `expression`.
This can be integrated with `TODO: gotta go, write about parseformulatree here`
Each `FeatCondition` is shaped as follows (whitespaces are not relevant):

**feature_name opening_bracket attribute closing_bracket operator threshold.**

* *feature_name* can be a julia built-in method such as `minimum` or `maximum` (visit
    @LINK TO DOC HERE@ to see which features are available by default), or a custom
    valid function whose (only) argument type is the same as attribute's wrapped data type;
* *opening_bracket* and *closing_bracket* wraps the attribute; are defaulted to `[`, `]`;
* *attribute* is a key label to access data of a certain type (TODO: fix this wording);
* *operator* is an element of `[<=, >=, <, >]`;
* *threshold* is a value to be compared with attribute's wrapped data.

# Examples
```julia-repl
julia> SoleModels.parsecondition("min[1] <= 32")
SoleModels.FeatCondition{Float64, SoleModels.FeatMetaCondition{SingleAttributeMin{Real},
typeof(<=)}}(SoleModels.FeatMetaCondition{SingleAttributeMin{Real}, typeof(<=)}
(SingleAttributeMin{Real}(1), <=), 32.0)

julia> parseformulatree("min[1] <= 15 ∧ max[1] >= 85", proposition_parser=parsecondition)
TODO: write result here (I still need to pull from SoleLogics. Complications occurred.)
```

"""
function parsecondition(
    expression::String;
    featvaltype = Real,
    opening_bracket::Union{String,Symbol} = OPENING_BRACKET,
    closing_bracket::Union{String,Symbol} = CLOSING_BRACKET,
    additional_shortcuts = Dict{String,Union{Type,Function}}()
)
    @assert length(string(opening_bracket)) == 1 || length(string(closing_bracket))
        "Brackets must be a single-character symbol."
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

    i_attr = parse(Int, _attribute)
    feature = begin
        if haskey(featdict, strip(lowercase(_feature)))
            # If it is a known feature get it as
            #  a type (e.g., `SingleAttributeMin`), or Julia function (e.g., `minimum`).
            feat_or_fun = featdict[strip(lowercase(_feature))]
            feat_or_fun = begin
                # If it is a function, wrap it into a SingleAttributeGenericFeature
                #  otherwise, it is a feature, and it is used as a constructor.
                if feat_or_fun isa Function
                    SingleAttributeGenericFeature{featvaltype}(i_attr, feat_or_fun)
                else
                    feat_or_fun{featvaltype}(i_attr)
                end
            end
            feat_or_fun
        else
            # If it is not a known feature, interpret it as a Julia function,
            #  and wrap it into a SingleAttributeGenericFeature.
            f = eval(Meta.parse(_feature))
            SingleAttributeGenericFeature{featvaltype}(i_attr, f)
        end
    end
    test_operator = eval(Meta.parse(_test_operator))
    metacond = FeatMetaCondition(feature, test_operator)

    return FeatCondition(metacond, parse(Float64, _threshold))
end
