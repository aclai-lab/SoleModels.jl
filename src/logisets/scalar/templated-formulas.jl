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

proposition(f::ScalarPropositionFormula) = Proposition(f.p)
feature(f::ScalarPropositionFormula) = feature(proposition(f))
test_operator(f::ScalarPropositionFormula) = test_operator(proposition(f))
threshold(f::ScalarPropositionFormula) = threshold(proposition(f))

tree(f::ScalarPropositionFormula) = SyntaxTree(f.p)
negation(f::ScalarPropositionFormula{U}) where {U} =
    ScalarPropositionFormula{U}(negation(p))

############################################################################################

abstract type ScalarOneStepFormula{U} <: ScalarFormula{U} end

relation(f::ScalarOneStepFormula) = f.relation
proposition(f::ScalarOneStepFormula) = Proposition(f.p)
metacond(f::ScalarOneStepFormula) = metacond(atom(proposition(f)))
feature(f::ScalarOneStepFormula) = feature(atom(proposition(f)))
test_operator(f::ScalarOneStepFormula) = test_operator(atom(proposition(f)))
threshold(f::ScalarOneStepFormula) = threshold(atom(proposition(f)))

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

tree(f::ScalarExistentialFormula) = DiamondRelationalOperator(f.relation)(Proposition(f.p))

"""
Templated formula for [R] f ⋈ t.
"""
struct ScalarUniversalFormula{U} <: ScalarOneStepFormula{U}
    relation  :: AbstractRelation
    p         :: ScalarCondition{U}
end

tree(f::ScalarUniversalFormula) = BoxRelationalOperator(f.relation)(Proposition(f.p))

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
