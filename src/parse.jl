using SoleData
using SoleLogics
import SoleData: BoundedScalarConditio

const SPACE = " "
const UNDERCORE = "_"

# This file contains utility functions for porting symbolic models from string and custom representations.


"""
Parser for [orange](https://orange3.readthedocs.io/)-style decision lists.
    Reference: https://orange3.readthedocs.io/projects/orange-visual-programming/en/latest/widgets/model/cn2ruleinduction.html
    # Examples
```julia-repl
 julia> \"\"\"
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
\"\"\" |> orange_decision_list
    TODO finish example with output...
    ```
    See also
    [`DecisionList`](@ref).

"""
""
function orange_decision_list(decision_list::AbstractString)

    # Strip whitespaces
    decision_list = strip(decision_list)

    rulebase = Rule[]
    for line in eachline(IOBuffer(decision_list))
        #   Capture with a regex:
        #   - the class distribution of the instances (e.g., [number, number, number, ...])
        res = match(r"\s*\[([\d\s,]+)\]\s*IF\s*(.*)\s*THEN\s*(.*)\s*([-+]?(?:[0-9]+(?:\\.[0-9]*)?|\\.[0-9]+))\s*", "[49, 0, 0] IF petal length<=3.0 AND sepal width>=2.9 THEN iris=Iris-setosa  -0.0")
        if isnothing(res) || length(res.captures) != 4
            error("Unexpected") # TODO
        end
        distribution_str, antecedents_str, class_str, num_TODORENAMEWHATISTHIS_str = res.captures
        distribution_list = parse.(Int, strip.(split(distribution_str, ",")))
        # println(distribution_list)

        #   - the antecedent string (between IF and THEN)
        # antecedents_str = match(r"IF\s(.*?)\sTHEN", line).captures[1]
        # spezzo l'antecedente in tutte le condizioni
        antecedent_conditions = String.(strip.(split(antecedents_str, "AND")))
        antecedent_conditions = replace.(antecedent_conditions, SPACE=>UNDERCORE)
        antecedent_conditions = match.(r"(.+?)([<>]=?|==)(.*)", antecedent_conditions)
        for condition in antecedent_conditions
            (varname, test_operator, treshold) = condition.captures[:]
            Atom(ScalarCondition(
                    UnivariateSymbolValue(Symbol(varname)),
                    # test
                    # treshold
            ))
        end

        num_TODORENAMEWHATISTHIS = parse(Float64, num_TODORENAMEWHATISTHIS_str)

        #   - the consequent string (after THEN, but before a sequence of 2 or more whitespaces)
        #   - The last (floating-point) number (see https://www.oreilly.com/library/view/regular-expressions-cookbook/9781449327453/ch06s10.html ) (by the way, what is it..? The entropy gain...?)
        #   antecedent = parse(Formula, antecedent_string)
        #   consequent = prendi la parte dopo il segno di uguaglianza da consequent_string, e wrappalo in un ConstantModel mettendogli un campo `supporting_labels` nelle `info`
        #   push!(rulebase, Rule(antecedent, consequent))
        #   avoid producing a rule for the last row, but remember its consequent.
        #   Maybe: And disregard the class distribution of the last rule (it's imprecise...) Actually it can be computed if one provides the original class distribution as a kwarg parameter
        #
        # return DecisionList(rulebase, ConstantModel(consequent of the last row))
    end

end
