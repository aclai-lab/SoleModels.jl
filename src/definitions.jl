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

# const CLabel = Union{String, Integer}
# const RLabel = AbstractFloat
# const Label  = Union{CLabel, RLabel}

const Consequent{O <: AbstractOutcome} = Union{O, AbstractModel{O}}

struct Rule{L<:Logic, C<:Consequent}
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

const AssociationRule{L<:Logic} = Rule{L, Formula{L}} #NOTE: maybe where {L<:Logic}

# NOTE: this has to be switched in ml.jl
const ClassificationRule = Rule{L,CLabel} where {L<:Logic}
const RegressionRule = Rule{L,RLabel} where {L<:Logic}

struct Branch{L<:Logic, C<:Consequent}
    antecedent::Formula{L}
    consequent::NTuple{2, Union{Formula{L}, C}}
    infos::NamedTuple
end

struct DecisionList{L<:Logic, C<:Consequent}
    rules::Vector{<:Rule{L,C}}
end
rules(model::DecisionList) = model.rules

const ClassificationDL = DecisionList{L,CLabel} where {L<:Logic}
const RegressionDL = DecisionList{L,RLabel} where {L<:Logic}

struct DecisionTree{L<:Logic, C<:Consequent}
    node::Union{Rule{L,C}, Branch{L,C}}
end

#= REPL example

    antecedent = build_tree("a")
    consequent = "class1"
    performance = Performance((m1=1, m2=2, m3=3))

    rule = Rule(antecedent, consequent, performance)
=#

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

# Remember this is the constructor of a Formula
# a = Formula{typeof(MODAL_LOGIC)}(b)
# where
# b = FNode(token, logic) = FNode{typeof(logic)}(token, logic)

# This has to be done
# c = Rule(consequent, logic) = Rule{typeof(consequent), typeof{logic}}(consequent, logic)
# or Rule{typeof(consequent), typeof(DEFAULT_LOGIC)}(consequent, DEFAULT_LOGIC)

############################################################################################
# NOTE: this might be shifted to some metrics.jl
# const PerformanceMetrics = NamedTuple{(:m1, :m2, :m3), Tuple{Float64, Float64, Float64}}

############################################################################################
# NOTE: il mondo iniziale fa parte del dataset
