import Base: show
import SoleLogics: tree, negation

"""
Abstract type simple formulas of given templates.
"""
abstract type AbstractTemplatedFormula <: SoleLogics.AbstractFormula end

"""
Templated formula for ⊤, which always checks top.
"""
struct TopFormula <: AbstractTemplatedFormula end
tree(::TopFormula) = SyntaxTree(⊤)
negation(::TopFormula) = BotFormula()

"""
Templated formula for ⊥, which always checks bottom.
"""
struct BotFormula <: AbstractTemplatedFormula end
tree(::BotFormula) = SyntaxTree(⊥)
negation(::BotFormula) = TopFormula()

"""
Templated formula for ⟨R⟩⊤.
"""
struct ExistentialTopFormula{R<:AbstractRelation} <: AbstractTemplatedFormula end
tree(::ExistentialTopFormula{R}) where {R<:AbstractRelation} = DiamondRelationalOperator{R}(⊤)
negation(::ExistentialTopFormula{R}) where {R<:AbstractRelation} = UniversalBotFormula{R}()

"""
Templated formula for [R]⊥.
"""
struct UniversalBotFormula{R<:AbstractRelation} <: AbstractTemplatedFormula end
tree(::UniversalBotFormula{R}) where {R<:AbstractRelation} = BoxRelationalOperator{R}(⊥)
negation(::UniversalBotFormula{R}) where {R<:AbstractRelation} = ExistentialTopFormula{R}()
