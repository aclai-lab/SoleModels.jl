using SoleLogics: AbstractRelation

import SoleLogics: value

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

value(f::ScalarPropositionFormula) = Atom(f.p)
feature(f::ScalarPropositionFormula) = feature(value(f))
test_operator(f::ScalarPropositionFormula) = test_operator(value(f))
threshold(f::ScalarPropositionFormula) = threshold(value(f))

tree(f::ScalarPropositionFormula) = SyntaxTree(f.p)
hasdual(f::ScalarPropositionFormula) = true
dual(f::ScalarPropositionFormula{U}) where {U} =
    ScalarPropositionFormula{U}(dual(p))

############################################################################################

abstract type ScalarOneStepFormula{U} <: ScalarFormula{U} end

relation(f::ScalarOneStepFormula) = f.relation
value(f::ScalarOneStepFormula) = Atom(f.p)
metacond(f::ScalarOneStepFormula) = metacond(value(value(f)))
feature(f::ScalarOneStepFormula) = feature(value(value(f)))
test_operator(f::ScalarOneStepFormula) = test_operator(value(value(f)))
threshold(f::ScalarOneStepFormula) = threshold(value(value(f)))

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

tree(f::ScalarExistentialFormula) = DiamondRelationalOperator(f.relation)(Atom(f.p))

"""
Templated formula for [R] f ⋈ t.
"""
struct ScalarUniversalFormula{U} <: ScalarOneStepFormula{U}
    relation  :: AbstractRelation
    p         :: ScalarCondition{U}
end

tree(f::ScalarUniversalFormula) = BoxRelationalOperator(f.relation)(Atom(f.p))

hasdual(f::ScalarExistentialFormula) = true
function dual(formula::ScalarExistentialFormula{U}) where {U}
    ScalarUniversalFormula{U}(
        relation(formula),
        dual(value(formula))
    )
end
hasdual(f::ScalarUniversalFormula) = true
function dual(formula::ScalarUniversalFormula{U}) where {U}
    ScalarExistentialFormula{U}(
        relation(formula),
        dual(value(formula))
    )
end
