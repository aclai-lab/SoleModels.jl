using SoleLogics: AbstractRelation

using SoleModels: AbstractFeature, TestOperator, ScalarCondition

"""
Abstract type for templated formulas on scalar conditions.
"""
abstract type ScalarFormula{U} <: AbstractTemplatedFormula end

"""
Templated formula for f ⋈ t.
"""
struct ScalarPropositionFormula{U} <: ScalarFormula{U}
    p :: ScalarCondition{U}
end

proposition(d::ScalarPropositionFormula) = Proposition(d.p)
feature(d::ScalarPropositionFormula) = feature(proposition(d))
test_operator(d::ScalarPropositionFormula) = test_operator(proposition(d))
threshold(d::ScalarPropositionFormula) = threshold(proposition(d))

tree(d::ScalarPropositionFormula) = SyntaxTree(d.p)
negation(d::ScalarPropositionFormula{U}) where {U} =
    ScalarPropositionFormula{U}(negation(p))

############################################################################################

abstract type ScalarOneStepFormula{U} <: ScalarFormula{U} end

relation(d::ScalarOneStepFormula) = d.relation
proposition(d::ScalarOneStepFormula) = Proposition(d.p)
metacond(d::ScalarOneStepFormula) = metacond(proposition(d))
feature(d::ScalarOneStepFormula) = feature(proposition(d))
test_operator(d::ScalarOneStepFormula) = test_operator(proposition(d))
threshold(d::ScalarOneStepFormula) = threshold(proposition(d))

"""
Templated formula for ⟨R⟩ f ⋈ t.
"""
struct ScalarExistentialFormula{U} <: ScalarOneStepFormula{U}

    # Relation, interpreted as an existential modal operator
    relation  :: AbstractRelation

    p         :: ScalarCondition{U}

    function ScalarExistentialFormula{U}() where {U}
        new{U}()
    end

    function ScalarExistentialFormula{U}(
        relation      :: AbstractRelation,
        p             :: ScalarCondition{U}
    ) where {U}
        new{U}(relation, p)
    end

    function ScalarExistentialFormula(
        relation      :: AbstractRelation,
        p             :: ScalarCondition{U}
    ) where {U}
        ScalarExistentialFormula{U}(relation, p)
    end

    function ScalarExistentialFormula{U}(
        relation      :: AbstractRelation,
        feature       :: AbstractFeature,
        test_operator :: TestOperator,
        threshold     :: U
    ) where {U}
        p = ScalarCondition(feature, test_operator, threshold)
        ScalarExistentialFormula{U}(relation, p)
    end

    function ScalarExistentialFormula(
        relation      :: AbstractRelation,
        feature       :: AbstractFeature,
        test_operator :: TestOperator,
        threshold     :: U
    ) where {U}
        ScalarExistentialFormula{U}(relation, feature, test_operator, threshold)
    end

    function ScalarExistentialFormula(
        formula       :: ScalarExistentialFormula{U},
        threshold_f   :: Function
    ) where {U}
        q = ScalarCondition(formula.p, threshold_f(threshold(formula.p)))
        ScalarExistentialFormula{U}(relation(formula), q)
    end
end

tree(d::ScalarExistentialFormula) = DiamondRelationalOperator(d.relation)(Proposition(d.p))

"""
Templated formula for [R] f ⋈ t.
"""
struct ScalarUniversalFormula{U} <: ScalarOneStepFormula{U}
    relation  :: AbstractRelation
    p         :: ScalarCondition{U}
end

tree(d::ScalarUniversalFormula) = BoxRelationalOperator(d.relation)(Proposition(d.p))

function negation(formula::ScalarExistentialFormula{U}) where {U}
    ScalarUniversalFormula{U}(
        relation(formula),
        negation(proposition(formula))
    )
end
function negation(formula::ScalarUniversalFormula{U}) where {U}
    ScalarExistentialFormula{U}(
        relation(formula),
        negation(proposition(formula))
    )
end
