using SoleData
using SoleLogics
using SoleModels
import SoleData: feature, varname
const SPACE = " "
const UNDERCORE = "_"

# This file contains utility functions for porting symbolic models from string and custom representations.

"""
Parser for [orange](https://orange3.readthedocs.io/)-style decision lists.
    Reference: https://orange3.readthedocs.io/projects/orange-visual-programming/en/latest/widgets/model/cn2ruleinduction.html
    # Examples
```julia-repl
julia> "
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
" |> orange_decision_list
    TODO finish example with output...
    ```
    See also
    [`DecisionList`](@ref).
"""

#=
C’è! Per ora è il campo info::NamedTuple, che ciascun modello simbolico ha.
Nel fare la traduzione a modelli di sole,

- nella info di una Rule metti supp_labels che è un vettore delle labels delle istanze su
cui la regola è costruita (ovvero, quelle che non sono coperte dalle regole precedenti),

- nella info del ConstantModel ci metti un campo supp_labels con le labels delle istanze che,
tra queste, sono coperte dalla regola.

Valuteremo se bisogna aggiungere anche un campo predicted_labels con le labels predette
dal modello, ma in principio le support_labels sono sufficienti per calcolare diverse metriche
=#


function orange_decision_list(
    decision_list::AbstractString;
    featuretype = SoleData.UnivariateSymbolValue
)
    decision_list = strip(decision_list)
    length(decision_list) == 0 && error("Empty decision list")

    defaultrule = nothing
    lastline = foldl((x,y)->y, eachline(IOBuffer(decision_list)))
    res = match(r"\[([\d\s,]+)\].*(TRUE)", lastline)

    # Mi assicuro che esista la regola di default
    if isnothing(res) || length(res.captures) != 2
        error("Malformed decision list, no default rule provided")
    end
    uncovered_distribution_str = res.captures[1]
    uncovered_distribution = parse.(Int, split(uncovered_distribution_str, ','))

    # Start For over rules
    rulebase = SoleModels.Rule[]
    for orangerule_str in eachline(IOBuffer(decision_list))

        res = match(r"\s*\[([\d\s,]+)\]\s*IF\s*(.*)\s*THEN\s*(.*)=(.*)\s+([+-]?\d+\.\d*)", orangerule_str)
        if isnothing(res) || length(res.captures) != 5
            error("Malformed decision list line: $(orangerule_str)")
        end

        distribution_str, antecedents_str, _ ,consequent_str, evaluation_str = String.(strip.(res.captures))
        # è un controllo accettabile ?
        if antecedents_str == "TRUE"
            info = (;
                evaluation = parse(Float64, evaluation_str),
            )
            defaultrule = SoleModels.ConstantModel(consequent_str, info)
            break
        end

        currentrule_distribution = parse.(Int, split(distribution_str, ','))
        antecedent_conditions = String.(strip.(split(antecedents_str, "AND")))
        antecedent_conditions = replace.(antecedent_conditions, SPACE=>UNDERCORE)
        antecedent_conditions = match.(r"(.+?)([<>]=?|==)(.*)", antecedent_conditions)

        antecedent = LeftmostConjunctiveForm([begin
            varname, test_operator, treshold = condition.captures[:]

            varname = strip(varname)
            test_operator = strip(test_operator)
            threshold = tryparse(Float64, strip(treshold))

            if isnothing(threshold)
                threshold = treshold_str
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
            supp_labels = currentrule_distribution
        )
        consequent_cm = SoleModels.ConstantModel(consequent_str, info_cm)

        # Info Rule
        info_r = (;
            supp_lables = uncovered_distribution
        )
        push!(rulebase, Rule(antecedent, consequent_cm, info_r))
        uncovered_distribution = uncovered_distribution.-currentrule_distribution
    end

    return SoleModels.DecisionList(rulebase, defaultrule)
end

    # Gio:
    #   - The last (floating-point) number (see https://www.oreilly.com/library/view/regular-expressions-cookbook/9781449327453/ch06s10.html )
    #                                      (by the way, what is it..? The entropy gain...? yes)
    #   antecedent = parse(Formula, antecedent_string)
    #   consequent = prendi la parte dopo il segno di uguaglianza da consequent_str, e
    #   wrappalo in un ConstantModel mettendogli un campo `supporting_labels` nelle `info`

    #   avoid producing a rule for the last row, but remember its consequent.
    #   Maybe: And disregard the class distribution of the last rule (it's imprecise...)
    #   Actually it can be computed if one provides the original class distribution as a kwarg parameter
