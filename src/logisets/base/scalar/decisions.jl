using SoleLogics: identityrel, globalrel

using SoleLogics: AbstractRelation
using SoleModels: AbstractFeature, TestOperator, ScalarCondition
using SoleModels: syntaxstring
using SoleModels.DimensionalDatasets: alpha

export ExistentialScalarDecision,
       #
       relation, feature, test_operator, threshold,
       is_propositional_decision,
       is_global_decision,
       #
       display_decision, display_decision_inverse

############################################################################################
# Decision
############################################################################################

# A decision inducing a branching/split (e.g., ⟨L⟩ (minimum(A2) ≥ 10) )
abstract type AbstractDecision  <: SoleLogics.AbstractFormula end

import SoleModels: negation

function Base.show(io::IO, decision::AbstractDecision)
    println(io, display_decision(decision))
end
function display_decision(
    frameid::FrameId,
    decision::AbstractDecision;
    variable_names_map::Union{Nothing,AbstractVector{<:AbstractVector},AbstractVector{<:AbstractDict}} = nothing,
    kwargs...,
)
    _variable_names_map = isnothing(variable_names_map) ? nothing : variable_names_map[frameid]
    "{$frameid} $(display_decision(decision; variable_names_map = _variable_names_map, kwargs...))"
end

############################################################################################

abstract type SimpleDecision <: AbstractDecision end

function display_decision_inverse(decision::SimpleDecision, kwargs...; args...)
    display_decision(negation(decision), kwargs...; args...)
end

function display_decision_inverse(frameid::FrameId, decision::SimpleDecision, kwargs...; args...)
    display_decision(frameid, negation(decision), kwargs...; args...)
end

display_existential(rel::AbstractRelation; kwargs...) = SoleLogics.syntaxstring(DiamondRelationalOperator{typeof(rel)}(); kwargs...)
display_universal(rel::AbstractRelation; kwargs...)   = SoleLogics.syntaxstring(BoxRelationalOperator{typeof(rel)}(); kwargs...)

############################################################################################

# ⊤
struct TopDecision <: SimpleDecision end
display_decision(::TopDecision) = "⊤"
negation(::TopDecision) = BotDecision()

# ⊥
struct BotDecision <: SimpleDecision end
display_decision(::BotDecision) = "⊥"
negation(::BotDecision) = TopDecision()

# ⟨R⟩⊤
struct ExistentialTopDecision{R<:AbstractRelation} <: SimpleDecision end
display_decision(::ExistentialTopDecision{R}) where {R<:AbstractRelation} = "$(display_existential(R))⊤"
negation(::ExistentialTopDecision{R}) where {R<:AbstractRelation} = UniversalBotDecision{R}()

# [R]⊥
struct UniversalBotDecision{R<:AbstractRelation} <: SimpleDecision end
display_decision(::UniversalBotDecision{R}) where {R<:AbstractRelation} = "$(display_universal(R))⊥"
negation(::UniversalBotDecision{R}) where {R<:AbstractRelation} = ExistentialTopDecision{R}()

############################################################################################
############################################################################################
############################################################################################

# Decisions based on dimensional conditions
abstract type ScalarDecision{U} <: SimpleDecision end

# p
struct PropositionalScalarDecision{U} <: ScalarDecision{U}
    p :: ScalarCondition{U}
end

proposition(d::PropositionalScalarDecision) = d.p
feature(d::PropositionalScalarDecision) = feature(proposition(d))
test_operator(d::PropositionalScalarDecision) = test_operator(proposition(d))
threshold(d::PropositionalScalarDecision) = threshold(proposition(d))

negation(p::PropositionalScalarDecision{U}) where {U} =
    PropositionalScalarDecision{U}(negation(p))

############################################################################################

abstract type ModalScalarDecision{U} <: ScalarDecision{U} end

relation(d::ModalScalarDecision) = d.relation
proposition(d::ModalScalarDecision) = d.p
feature(d::ModalScalarDecision) = feature(proposition(d))
test_operator(d::ModalScalarDecision) = test_operator(proposition(d))
threshold(d::ModalScalarDecision) = threshold(proposition(d))

is_propositional_decision(d::ModalScalarDecision) = (relation(d) == identityrel)
is_global_decision(d::ModalScalarDecision) = (relation(d) == globalrel)

# ⟨R⟩p
struct ExistentialScalarDecision{U} <: ModalScalarDecision{U}

    # Relation, interpreted as an existential modal operator
    relation  :: AbstractRelation

    p         :: ScalarCondition{U}

    function ExistentialScalarDecision{U}() where {U}
        new{U}()
    end

    function ExistentialScalarDecision{U}(
        relation      :: AbstractRelation,
        p             :: ScalarCondition{U}
    ) where {U}
        new{U}(relation, p)
    end

    function ExistentialScalarDecision(
        relation      :: AbstractRelation,
        p             :: ScalarCondition{U}
    ) where {U}
        ExistentialScalarDecision{U}(relation, p)
    end

    function ExistentialScalarDecision{U}(
        relation      :: AbstractRelation,
        feature       :: AbstractFeature,
        test_operator :: TestOperator,
        threshold     :: U
    ) where {U}
        p = ScalarCondition(feature, test_operator, threshold)
        ExistentialScalarDecision{U}(relation, p)
    end

    function ExistentialScalarDecision(
        relation      :: AbstractRelation,
        feature       :: AbstractFeature,
        test_operator :: TestOperator,
        threshold     :: U
    ) where {U}
        ExistentialScalarDecision{U}(relation, feature, test_operator, threshold)
    end

    function ExistentialScalarDecision(
        decision      :: ExistentialScalarDecision{U},
        threshold_f   :: Function
    ) where {U}
        q = ScalarCondition(decision.p, threshold_f(threshold(decision.p)))
        ExistentialScalarDecision{U}(relation(decision), q)
    end
end

# [R]p
struct UniversalScalarDecision{U} <: ModalScalarDecision{U}
    relation  :: AbstractRelation
    p         :: ScalarCondition{U}
end

function negation(decision::ExistentialScalarDecision{U}) where {U}
    UniversalScalarDecision{U}(
        relation(decision),
        negation(proposition(decision))
    )
end
function negation(decision::UniversalScalarDecision{U}) where {U}
    ExistentialScalarDecision{U}(
        relation(decision),
        negation(proposition(decision))
    )
end

function display_decision(
    decision::Union{ExistentialScalarDecision,UniversalScalarDecision};
    threshold_display_method::Function = x -> x,
    variable_names_map::Union{Nothing,AbstractVector,AbstractDict} = nothing,
    use_feature_abbreviations::Bool = false,
)
    prop_decision_str = syntaxstring(
        decision.p;
        threshold_display_method = threshold_display_method,
        variable_names_map = variable_names_map,
        use_feature_abbreviations = use_feature_abbreviations,
    )
    if !is_propositional_decision(decision)
        rel_display_fun = (decision isa ExistentialScalarDecision ? display_existential : display_universal)
        "$(rel_display_fun(relation(decision))) ($prop_decision_str)"
    else
        "$prop_decision_str"
    end
end


############################################################################################
