using SoleData
using SoleLogics
using SoleModels
import SoleData: feature, varname
const SPACE = " "
const UNDERCORE = "_"

# This file contains utility functions for porting symbolic models from string and custom representations.

"""
    orange_decision_list(decision_list, ignoredefaultrule = false; featuretype = SoleData.UnivariateSymbolValue)

Parser for [orange](https://orange3.readthedocs.io/)-style decision lists.
Reference: https://orange3.readthedocs.io/projects/orange-visual-programming/en/latest/widgets/model/cn2ruleinduction.html

# Arguments

* `decision_list` is an `AbstractString` containing the orange-style representation of a decision list;
* `ignoredefaultrule` is an optional, Boolean parameter indicating whether to use the default rule
    as the default rule for the resulting decision list.
    When `false`, the last rule is ignored, and the second last is used as the default rule;
* `featuretype` specifies the feature type used in the parsed `ScalarCondition`s.

# Examples
```julia-repl
julia> dl = "
[49, 0, 0] IF petal length<=3.0 AND sepal width>=2.9 THEN iris=Iris-setosa  -0.0
[0, 0, 39] IF petal width>=1.8 AND sepal length>=6.0 THEN iris=Iris-virginica  -0.0
[0, 8, 0] IF sepal length>=4.9 AND sepal width>=3.1 THEN iris=Iris-versicolor  -0.0
[0, 0, 2] IF petal length<=4.9 AND petal width>=1.7 THEN iris=Iris-virginica  -0.0
[0, 0, 5] IF petal width>=1.8 THEN iris=Iris-virginica  -0.0
[0, 35, 0] IF petal length<=5.0 AND sepal width>=2.4 THEN iris=Iris-versicolor  -0.0
[0, 0, 2] IF sepal width>=2.8 THEN iris=Iris-virginica  -0.0
[0, 3, 0] IF petal width<=1.0 AND sepal length>=5.0 THEN iris=Iris-versicolor  -0.0
[0, 1, 0] IF sepal width>=2.7 THEN iris=Iris-versicolor  -0.0
[0, 0, 1] IF sepal width>=2.6 THEN iris=Iris-virginica  -0.0
[0, 2, 0] IF sepal length>=5.5 AND sepal length>=6.2 THEN iris=Iris-versicolor  -0.0
[0, 1, 0] IF sepal length<=5.5 AND petal length>=4.0 THEN iris=Iris-versicolor  -0.0
[0, 0, 1] IF sepal length>=6.0 THEN iris=Iris-virginica  -0.0
[1, 0, 0] IF sepal length<=4.5 THEN iris=Iris-setosa  -0.0
[50, 50, 50] IF TRUE THEN iris=Iris-setosa  -1.584962500721156
" |> SoleModels.orange_decision_list

julia> listrules(dl; normalize = true)
15-element Vector{ClassificationRule{String, A, SoleModels.ConstantModel{String}} where A<:Formula}:
 ▣ ((:petal_length ≤ 3.0) ∧ (:sepal_width ≥ 2.9))  ↣  Iris-setosa

 ▣ ((:petal_length > 3.0) ∨ (:sepal_width < 2.9)) ∧ ((:petal_width ≥ 1.8) ∧ (:sepal_length ≥ 6.0))  ↣  Iris-virginica

 ▣ ((:petal_length > 3.0) ∨ (:sepal_width < 2.9)) ∧ ((:petal_width < 1.8) ∨ (:sepal_length < 6.0)) ∧ ((:sepal_length ≥ 4.9) ∧ (:sepal_width ≥ 3.1))  ↣  Iris-versicolor

 ▣ ((:petal_length > 3.0) ∨ (:sepal_width < 2.9)) ∧ ((:petal_width < 1.8) ∨ (:sepal_length < 6.0)) ∧ ((:sepal_length < 4.9) ∨ (:sepal_width < 3.1)) ∧ ((:petal_length ≤ 4.9) ∧ (:petal_width ≥ 1.7))  ↣  Iris-virginica

 ▣ ((:petal_length > 3.0) ∨ (:sepal_width < 2.9)) ∧ ((:petal_width < 1.8) ∨ (:sepal_length < 6.0)) ∧ ((:sepal_length < 4.9) ∨ (:sepal_width < 3.1)) ∧ ((:petal_length > 4.9) ∨ (:petal_width < 1.7)) ∧ (:petal_width ≥ 1.8)  ↣  Iris-virginica

 ▣ ((:petal_length > 3.0) ∨ (:sepal_width < 2.9)) ∧ ((:petal_width < 1.8) ∨ (:sepal_length < 6.0)) ∧ ((:sepal_length < 4.9) ∨ (:sepal_width < 3.1)) ∧ ((:petal_length > 4.9) ∨ (:petal_width < 1.7)) ∧ (:petal_width < 1.8) ∧ ((:petal_length ≤ 5.0) ∧ (:sepal_width ≥ 2.4))  ↣  Iris-versicolor

 ▣ ((:petal_length > 3.0) ∨ (:sepal_width < 2.9)) ∧ ((:petal_width < 1.8) ∨ (:sepal_length < 6.0)) ∧ ((:sepal_length < 4.9) ∨ (:sepal_width < 3.1)) ∧ ((:petal_length > 4.9) ∨ (:petal_width < 1.7)) ∧ (:petal_width < 1.8) ∧ ((:petal_length > 5.0) ∨ (:sepal_width < 2.4)) ∧ (:sepal_width ≥ 2.8)  ↣  Iris-virginica

 ▣ ((:petal_length > 3.0) ∨ (:sepal_width < 2.9)) ∧ ((:petal_width < 1.8) ∨ (:sepal_length < 6.0)) ∧ ((:sepal_length < 4.9) ∨ (:sepal_width < 3.1)) ∧ ((:petal_length > 4.9) ∨ (:petal_width < 1.7)) ∧ (:petal_width < 1.8) ∧ ((:petal_length > 5.0) ∨ (:sepal_width < 2.4)) ∧ (:sepal_width < 2.8) ∧ ((:petal_width ≤ 1.0) ∧ (:sepal_length ≥ 5.0))  ↣  Iris-versicolor

 ▣ ((:petal_length > 3.0) ∨ (:sepal_width < 2.9)) ∧ ((:petal_width < 1.8) ∨ (:sepal_length < 6.0)) ∧ ((:sepal_length < 4.9) ∨ (:sepal_width < 3.1)) ∧ ((:petal_length > 4.9) ∨ (:petal_width < 1.7)) ∧ (:petal_width < 1.8) ∧ ((:petal_length > 5.0) ∨ (:sepal_width < 2.4)) ∧ (:sepal_width < 2.8) ∧ ((:petal_width > 1.0) ∨ (:sepal_length < 5.0)) ∧ (:sepal_width ≥ 2.7)  ↣  Iris-versicolor

 ▣ ((:petal_length > 3.0) ∨ (:sepal_width < 2.9)) ∧ ((:petal_width < 1.8) ∨ (:sepal_length < 6.0)) ∧ ((:sepal_length < 4.9) ∨ (:sepal_width < 3.1)) ∧ ((:petal_length > 4.9) ∨ (:petal_width < 1.7)) ∧ (:petal_width < 1.8) ∧ ((:petal_length > 5.0) ∨ (:sepal_width < 2.4)) ∧ (:sepal_width < 2.8) ∧ ((:petal_width > 1.0) ∨ (:sepal_length < 5.0)) ∧ (:sepal_width < 2.7) ∧ (:sepal_width ≥ 2.6)  ↣  Iris-virginica

 ▣ ((:petal_length > 3.0) ∨ (:sepal_width < 2.9)) ∧ ((:petal_width < 1.8) ∨ (:sepal_length < 6.0)) ∧ ((:sepal_length < 4.9) ∨ (:sepal_width < 3.1)) ∧ ((:petal_length > 4.9) ∨ (:petal_width < 1.7)) ∧ (:petal_width < 1.8) ∧ ((:petal_length > 5.0) ∨ (:sepal_width < 2.4)) ∧ (:sepal_width < 2.8) ∧ ((:petal_width > 1.0) ∨ (:sepal_length < 5.0)) ∧ (:sepal_width < 2.7) ∧ (:sepal_width < 2.6) ∧ ((:sepal_length ≥ 5.5) ∧ (:sepal_length ≥ 6.2))  ↣  Iris-versicolor

 ▣ ((:petal_length > 3.0) ∨ (:sepal_width < 2.9)) ∧ ((:petal_width < 1.8) ∨ (:sepal_length < 6.0)) ∧ ((:sepal_length < 4.9) ∨ (:sepal_width < 3.1)) ∧ ((:petal_length > 4.9) ∨ (:petal_width < 1.7)) ∧ (:petal_width < 1.8) ∧ ((:petal_length > 5.0) ∨ (:sepal_width < 2.4)) ∧ (:sepal_width < 2.8) ∧ ((:petal_width > 1.0) ∨ (:sepal_length < 5.0)) ∧ (:sepal_width < 2.7) ∧ (:sepal_width < 2.6) ∧ ((:sepal_length < 5.5) ∨ (:sepal_length < 6.2)) ∧ ((:sepal_length ≤ 5.5) ∧ (:petal_length ≥ 4.0))  ↣  Iris-versicolor

 ▣ ((:petal_length > 3.0) ∨ (:sepal_width < 2.9)) ∧ ((:petal_width < 1.8) ∨ (:sepal_length < 6.0)) ∧ ((:sepal_length < 4.9) ∨ (:sepal_width < 3.1)) ∧ ((:petal_length > 4.9) ∨ (:petal_width < 1.7)) ∧ (:petal_width < 1.8) ∧ ((:petal_length > 5.0) ∨ (:sepal_width < 2.4)) ∧ (:sepal_width < 2.8) ∧ ((:petal_width > 1.0) ∨ (:sepal_length < 5.0)) ∧ (:sepal_width < 2.7) ∧ (:sepal_width < 2.6) ∧ ((:sepal_length < 5.5) ∨ (:sepal_length < 6.2)) ∧ ((:sepal_length > 5.5) ∨ (:petal_length < 4.0)) ∧ (:sepal_length ≥ 6.0)  ↣  Iris-virginica

 ▣ ((:petal_length > 3.0) ∨ (:sepal_width < 2.9)) ∧ ((:petal_width < 1.8) ∨ (:sepal_length < 6.0)) ∧ ((:sepal_length < 4.9) ∨ (:sepal_width < 3.1)) ∧ ((:petal_length > 4.9) ∨ (:petal_width < 1.7)) ∧ (:petal_width < 1.8) ∧ ((:petal_length > 5.0) ∨ (:sepal_width < 2.4)) ∧ (:sepal_width < 2.8) ∧ ((:petal_width > 1.0) ∨ (:sepal_length < 5.0)) ∧ (:sepal_width < 2.7) ∧ (:sepal_width < 2.6) ∧ ((:sepal_length < 5.5) ∨ (:sepal_length < 6.2)) ∧ ((:sepal_length > 5.5) ∨ (:petal_length < 4.0)) ∧ (:sepal_length < 6.0) ∧ (:sepal_length ≤ 4.5)  ↣  Iris-setosa

 ▣ ((:petal_length > 3.0) ∨ (:sepal_width < 2.9)) ∧ ((:petal_width < 1.8) ∨ (:sepal_length < 6.0)) ∧ ((:sepal_length < 4.9) ∨ (:sepal_width < 3.1)) ∧ ((:petal_length > 4.9) ∨ (:petal_width < 1.7)) ∧ (:petal_width < 1.8) ∧ ((:petal_length > 5.0) ∨ (:sepal_width < 2.4)) ∧ (:sepal_width < 2.8) ∧ ((:petal_width > 1.0) ∨ (:sepal_length < 5.0)) ∧ (:sepal_width < 2.7) ∧ (:sepal_width < 2.6) ∧ ((:sepal_length < 5.5) ∨ (:sepal_length < 6.2)) ∧ ((:sepal_length > 5.5) ∨ (:petal_length < 4.0)) ∧ (:sepal_length < 6.0) ∧ (:sepal_length > 4.5)  ↣  Iris-setosa

```

See also [`DecisionList`](@ref).
"""
function parse_orange_decision_list(
    decision_list::AbstractString,
    ignoredefaultrule::Bool = false;
    featuretype::Type{<:SoleData.AbstractFeature} = SoleData.UnivariateSymbolValue
)
    # Strip whitespaces
    decision_list_str = strip(decision_list)
        isempty(decision_list_str) && Base.error("Empty decision list")

    # read last line of the input string (decision_list_str) to capture the total distribution of examples.
    lastline = foldl((x,y)->y, eachline(IOBuffer(decision_list_str)))
    res = match(r"\s*\[([\d\s,]+)\]\s*IF\s*(.*)\s*THEN\s*(.*)=(.*)\s+([+-]?\d+\.\d*)", lastline)

    # Checks on default rule
    if isnothing(res) || (strip(res.captures[2]) != "TRUE")
        Base.error("Malformed decision list, `$(lastline)` is not an acceptable defaultrule")
    end
    uncovered_distribution_str = res.captures[1]
    uncovered_distribution = parse.(Int, split(uncovered_distribution_str, ','))

    rulebase = SoleModels.Rule[]
    defaultconsequent = nothing

    # Iterate over lines (rules)
    for orangerule_str in eachline(IOBuffer(decision_list_str))

        res = match(r"\s*\[([\d\s,]+)\]\s*IF\s*(.*)\s*THEN\s*(.*)=(.*)\s+([+-]?\d+\.\d*)", orangerule_str)
        if isnothing(res) || length(res.captures) != 5
            Base.error("Malformed decision list line: $(orangerule_str)")
        end
        distribution_str, antecedents_str, consequent_class_name_str, consequent_str, evaluation_str = String.(strip.(res.captures))
        # Trigger for the default rule
        if antecedents_str == "TRUE"
            if ignoredefaultrule
                defaultconsequent = rulebase[end].consequent
                rulebase = rulebase[1:(end-1)]
            else
                info = (;
                    evaluation = parse(Float64, evaluation_str),
                )
                defaultconsequent = SoleModels.ConstantModel(consequent_str, info)
            end
            break
        end
        currentrule_distribution = parse.(Int, split(distribution_str, ','))
        antecedent_conditions = String.(strip.(split(antecedents_str, "AND")))
        antecedent_conditions = replace.(antecedent_conditions, SPACE=>UNDERCORE)
        antecedent_conditions = match.(r"(.+?)([<>]=?|==|!=)(.*)", antecedent_conditions)

        antecedent = LeftmostConjunctiveForm([begin
            varname, test_operator, threshold_str = condition.captures[:]

            varname = strip(varname)
            test_operator = strip(test_operator)
            threshold = tryparse(Float64, strip(threshold_str))

            if isnothing(threshold)
                threshold = threshold_str
            end
            Atom{ScalarCondition}(SoleData.ScalarCondition(
                    featuretype(Symbol(varname)),
                    eval(Meta.parse(test_operator)),
                    threshold
            ))
        end for condition in antecedent_conditions])

        # Info ConstantModel
        info_cm = (;
            evaluation = parse(Float64, evaluation_str),
            supporting_labels = currentrule_distribution
        )
        consequent_cm = SoleModels.ConstantModel(consequent_str, info_cm)

        # Info Rule
        info_r = (;
            supporting_labels = uncovered_distribution
        )
        push!(rulebase, Rule(antecedent, consequent_cm, info_r))
        uncovered_distribution = uncovered_distribution.-currentrule_distribution
    end
    return SoleModels.DecisionList(rulebase, defaultconsequent)
end
