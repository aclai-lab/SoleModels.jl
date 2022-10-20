#################################
#       Abstract Types          #
#################################
abstract type AbstractOutcome end

abstract type AbstractModel{O <: AbstractOutcome} end

abstract type AbstractSymbolicModel{L, O} <: AbstractModel{O} end
abstract type AbstractFunctionalModel{O}  <: AbstractModel{O} end

#################################
#       Concrete Types          #
#################################
const Consequent{O <: AbstractOutcome} = Union{O, AbstractModel{O}}

#NOTE: think about the correct types
struct Rule{L<:Logic, C<:Consequent} <: AbstractModel{O<:AbstractOutcome}
    antecedent::Formula{L}
    consequent::Union{Formula{L}, C}
    infos::NamedTuple

    function Rule{L,C}(
        antecedent::Formula{L},
        consequent::C,
        performance::NamedTuple
    ) where {L<:Logic, C<:Consequent}
        new{L, C}(antecedent, consequent, performance)
    end

    function Rule(
        antecedent::Formula{L},
        consequent::C,
        performance::NamedTuple
    ) where {L<:Logic, C<:Consequent}
        Rule{L, C}(antecedent, consequent, performance)
    end
end

#NOTE: think about the correct types
struct Branch{L<:Logic, C<:Consequent} <: AbstractModel{O<:AbstractOutcome}
    antecedent::Formula{L}
    consequent::NTuple{2, Union{Formula{L}, C}}
    infos::NamedTuple
end

#NOTE: think about the correct types
struct DecisionList{L<:Logic, C<:Consequent} <: AbstractModel{O<:AbstractOutcome}
    rules::Vector{<:Rule{L,C}}
    default::C
end
rules(model::DecisionList) = model.rules

struct DecisionTree{L<:Logic, C<:Consequent} <: AbstractModel{O<:AbstractOutcome}
    root::Union{C, Branch{L,C}}
end

#TODO: Define Open versions
# DecisionList doesn't have default value
# DecisionTree can also have Rule{L,C}

"""ML.JL
const AssociationRule{L<:Logic} = Rule{L, Formula{L}} #NOTE: maybe where {L<:Logic}

# NOTE: this has to be switched in ml.jl
const ClassificationRule = Rule{L,CLabel} where {L<:Logic}
const RegressionRule = Rule{L,RLabel} where {L<:Logic}

# const CLabel = Union{String, Integer}
# const RLabel = AbstractFloat
# const Label  = Union{CLabel, RLabel}


const ClassificationDL = DecisionList{L,CLabel} where {L<:Logic}
const RegressionDL = DecisionList{L,RLabel} where {L<:Logic}
"""
