#################################
#       Abstract Types          #
#################################
abstract type AbstractModel end

abstract type AbstractSymbolicModel{L} where {L <: AbstractLogic} <: AbstractModel end
abstract type AbstractFunctionalModel <: AbstractModel end

#################################
#       Concrete Types          #
#################################

const CLabel = Union{String, Integer}
const RLabel = AbstractFloat
const Label = Union{CLabel, RLabel}

const Consequent = Union{Label, AbstractModel}

struct Rule{L<:AbstractLogic, C<:Consequent}
    antecedent::Formula{L}
    consequent::C
end

const ClassificationRule = Rule{L,CLabel} where {L<:AbstractLogic}
const RegressionRule = Rule{L,RLabel} where {L<:AbstractLogic}

struct Branch{L<:AbstractLogic, C<:Consequent}
    rule::Rule{L,C}
    alternative::C
end

struct DecisionList{L<:AbstractLogic, C<:Consequent}
    rules::Vector{<:Rule{L,C}}
end
rules(model::DecisionList) = model.rules

const ClassificationDL = DecisionList{L,CLabel} where {L<:AbstractLogic}
const RegressionDL = DecisionList{L,RLabel} where {L<:AbstractLogic}

struct DecisionTree{L<:AbstractLogic, C<:Consequent}
    node::Union{Rule{L,C}, Branch{L,C}}
end











#=
#################################
#       Abstract Types          #
#################################
abstract type AbstractModel{O} end

abstract type AbstractSymbolicModel{L, O} <: AbstractModel{O} end
abstract type AbstractFunctionalModel{O} <: AbstractModel{O} end

abstract type AbstractOutcome{O} end

#################################
#       Concrete Types          #
#################################

const CLabel = Union{String, Integer}
const RLabel = AbstractFloat
const Label = Union{CLabel, RLabel}

# NOTE: is Outcome the correct name?
struct Outcome{O} where {O <: Union{Label, AbstractModel} <: AbstractOutcome{O}
    core::Union{AbstractOutcome{O}, AbstractModel{O}}
end

#=
struct Rule{O}
    antecedent::SoleLogics.Formula
    consequent::Outcome{O}
end

struct Branch{O}
    rule::Rule{O} # delegation pattern
    alternative::Outcome{O}
end
=#
=#
