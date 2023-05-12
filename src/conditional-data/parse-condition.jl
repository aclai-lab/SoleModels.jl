using StatsBase

#= ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Code purpose ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Given a string "min[A189] <= 250", build the corresponding FeatCondition.

In the example:
1) feature          is      SingleAttributeMin(189)
2) metacondition    is      SoleModels.FeatMetaCondition(feature, >)
3) threshold        is      250

This can be done by integrating this code with SoleLogics parsing system:
    SoleLogics.parseformulatree(
        "min[189] <= 250 ∧ min[189] <= 250", proposition_parser = parsecondition);
    as you notice, featconbuilder is passed to parseformulatree to interpret
    each proposition found as Proposition{FeatCondition} instead of Proposition{String}.
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ =#

#= ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Limitations ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Here are listed the current limitations in parsecondition: in other words,
the limitations that has to be considered when converting a string
shaped like "feature[attribute] operator threshold" into a FeatCondition.

- Legal features are only "min" and "max" (see _BASE_FEATURES).
- In "min[A189] <= 250", a space between "<=" and "250" is required:
    this is because otherwise we don't know when the operator string finishes;
    a solution could be to take a vector of legal operators from the user, and provide
    a default one.
- In "min[A189] <= 250", "min" has to be written exactly like this ("min  " is illegal).
- Features are always Type{Real}.
- Thresholds are always Type{Float64}.
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

# A FeatCondition constructor that can be integrated with SoleLogics' parsing methods;
# at the moment:
# - features are only "min" (SingleAttributeMin) and "max" (SingleAttributeMax)
# - attribute is always considered as integer;
# - threshold is always considered as real;
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
        # 3 slices are found initially, thanks to the following regex, in this order:
        # a feature name (e.g. "min"),
        # an attribute inside feature's brackets (e.g. "[A189]"),
        # a remaining part (hopefully, a legal operator and then anything)
        # NOTE: this could work too ^([^<>]*)\w*(<|>|<=|>=)\w*([^<>]*)$
        slices = string.(split(expression, r"((?<=\])|(?=\[))"))

        @assert length(slices) == 3 "Expression $expression is not formatted properly. " *
            "Correct formatting is: feature$(opening_bracket)attribute" *
            "$(closing_bracket) operator threshold."

        @assert (string(slices[2][1]) == string(opening_bracket) &&
            string(slices[2][end]) == string(closing_bracket))
            "Malformed brackets in $(slices[2])."

        # NOTE: a space between operator and threhsold MUST exist
        feature = slices[1]
        attribute = string(chop(slices[2], head=1, tail=1))
        test_operator, threshold = string.(split(strip(slices[3]), " "))

        return (feature, attribute, test_operator, threshold)
    end

    (_feature, _attribute, _test_operator, _threshold) = _cut(expression)

    i_attr = parse(Int, _attribute)
    feature = begin
        if haskey(featdict, lowercase(_feature))
            # If it is a known feature get it as
            #  a type (e.g., `SingleAttributeMin`), or Julia function (e.g., `minimum`).
            feat_or_fun = featdict[lowercase(_feature)]
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
