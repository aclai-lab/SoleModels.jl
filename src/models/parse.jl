#= ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Code purpose ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Given a string "min[A189] <= 250", build the corresponding FeatCondition.

In the example:
1) feature          is      SingleAttributeMin(189)
2) metacondition    is      SoleModels.FeatMetaCondition(feature, >)
3) threshold        is      250

This can be done by integrating this code with SoleLogics parsing system:
    SoleLogics.parseformulatree(
        "min[189] <= 250 ∧ min[189] <= 250", proposition_parser = featcondbuilder);
    as you notice, featconbuilder is passed to parseformulatree to interpret
    each proposition found as Proposition{FeatCondition} instead of Proposition{String}.
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ =#

#= ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Limitations ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Here are listed the current limitations in featcondbuilder: in other words,
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

const _BASE_FEATURES = Dict{String, Function}(
    "min" => ((x) -> SingleAttributeMin{Real}(x)),
    "max" => ((x) -> SingleAttributeMax{Real}(x))
)

# A FeatCondition constructor that can be integrated with SoleLogics' parsing methods;
# at the moment:
# - features are only "min" (SingleAttributeMin) and "max" (SingleAttributeMax)
# - attribute is always considered as integer;
# - threshold is always considered as real;
function featcondbuilder(
    expression::String;
    opening_bracket::Union{String,Symbol} = OPENING_BRACKET,
    closing_bracket::Union{String,Symbol} = CLOSING_BRACKET
)
    @assert length(string(opening_bracket)) == 1 || length(string(closing_bracket))
        "Brackets must be a single-character symbol."
    opening_bracket = Symbol(opening_bracket)
    closing_bracket = Symbol(closing_bracket)

    # Get a string;
    # return (if possible) a Tuple containing 4 substrings:
    #   [feature, attribute, operator, threshold].
    function _cut(expression::String)
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

        #NOTE: a space between operator and threhsold MUST exist
        feature = slices[1]
        attribute = string(chop(slices[2], head=1, tail=1))
        operator, threshold = string.(split(strip(slices[3]), " "))

        return (feature, attribute, operator, threshold)
    end

    # Get feature, operator and threshold string;
    # return a FeatCondition.
    function _absorb(fctokens::NTuple{4, String})
        feature  = _BASE_FEATURES[fctokens[1]](parse(Int,fctokens[2]))
        metacond = SoleModels.FeatMetaCondition(feature, eval(Meta.parse(fctokens[3])))
        return SoleModels.FeatCondition(metacond, parse(Float64,fctokens[4]))
    end

    return Proposition(_absorb(_cut(expression)));
end
