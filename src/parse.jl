# This file contains utility functions for porting symbolic models from string and custom representations.

"""
Parser for [orange](https://orange3.readthedocs.io/)-style decision lists.
Reference: https://orange3.readthedocs.io/projects/orange-visual-programming/en/latest/widgets/model/cn2ruleinduction.html

# Examples
```julia-repl
julia> """
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
""" |> orange_decision_list
TODO finish example with output...
```

See also
[`DecisionList`](@ref).

"""
function orange_decision_list(decision_list::AbstractString)
    # Trim decision_list
    # rulebase = Rule[]
    # for line in readlines(decision_list)
    #     Capture with a regex:
    #     - the class distribution of the instances (e.g., [number, number, number, ...])
    #     - the antecedent string (between IF and THEN)
    #     - the consequent string (after THEN, but before a sequence of 2 or more whitespaces)
    #     - The last (floating-point) number (see https://www.oreilly.com/library/view/regular-expressions-cookbook/9781449327453/ch06s10.html ) (by the way, what is it..? The entropy gain...?)
    #     antecedent = parse(Formula, antecedent_string)
    #     consequent = prendi la parte dopo il segno di uguaglianza da consequent_string, e wrappalo in un ConstantModel mettendogli un campo `supporting_labels` nelle `info`
    #     push!(rulebase, Rule(antecedent, consequent))
    #     avoid producing a rule for the last row, but remember its consequent.
    #     Maybe: And disregard the class distribution of the last rule (it's imprecise...) Actually it can be computed if one provides the original class distribution as a kwarg parameter
    # 
    # return DecisionList(rulebase, ConstantModel(consequent of the last row))
end