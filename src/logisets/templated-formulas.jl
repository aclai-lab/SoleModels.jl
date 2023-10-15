import Base: show
import SoleLogics: tree, dual

"""
Abstract type simple formulas of given templates.
"""
abstract type AbstractTemplatedFormula <: SoleLogics.Formula end

"""
Templated formula for ⊤, which always checks top.
"""
struct TopFormula <: AbstractTemplatedFormula end
tree(::TopFormula) = SyntaxTree(⊤)
hasdual(::TopFormula) = true
dual(::TopFormula) = BotFormula()

"""
Templated formula for ⊥, which always checks bottom.
"""
struct BotFormula <: AbstractTemplatedFormula end
tree(::BotFormula) = SyntaxTree(⊥)
hasdual(::BotFormula) = true
dual(::BotFormula) = TopFormula()

"""
Templated formula for ⟨R⟩⊤.
"""
struct ExistentialTopFormula{R<:AbstractRelation} <: AbstractTemplatedFormula end
tree(::ExistentialTopFormula{R}) where {R<:AbstractRelation} = DiamondRelationalOperator{R}(⊤)
hasdual(::ExistentialTopFormula) = true
dual(::ExistentialTopFormula{R}) where {R<:AbstractRelation} = UniversalBotFormula{R}()

"""
Templated formula for [R]⊥.
"""
struct UniversalBotFormula{R<:AbstractRelation} <: AbstractTemplatedFormula end
tree(::UniversalBotFormula{R}) where {R<:AbstractRelation} = BoxRelationalOperator{R}(⊥)
hasdual(::UniversalBotFormula) = true
dual(::UniversalBotFormula{R}) where {R<:AbstractRelation} = ExistentialTopFormula{R}()
