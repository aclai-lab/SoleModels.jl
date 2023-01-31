using SoleLogics: AbstractKripkeStructure, AbstractInterpretationSet, AbstractFrame
import SoleLogics: check, accessibles

abstract type AbstractConditionalDataset{
    W<:AbstractWorld,
    A<:FeatCondition,
    T<:TruthValue,
    FR<:AbstractFrame{W,T},
} <: AbstractInterpretationSet{AbstractKripkeStructure{W,A,T,FR}} end

function check(
    ::AbstractConditionalDataset{W,AA,T},
    instance_id,
    ::W,
    ::Proposition{A},
)::T where {W<:AbstractWorld,AA<:FeatCondition,T<:TruthValue,A<:AA}
    error("Please, provide ...")
end

function check(
    ::AbstractConditionalDataset{W,A,T},
    instance_id,
    ::W,
    ::Formula,
)::T where {W<:AbstractWorld,A<:FeatCondition,T<:TruthValue}
    error("Please, provide ...")
end


function accessibles(
    ::AbstractConditionalDataset{W,A,T},
    instance_id,
    ::W,
    ::AbstractRelation,
) where {W<:AbstractWorld,A<:FeatCondition,T<:TruthValue}
    error("Please, provide ...")
end

# TODO from here onwards

# active = ha un alphabet. Ci puoi checkare e imparare formule.
abstract type ActiveConditionalDataset{
    W<:AbstractWorld,
    A<:FeatCondition,
    T<:TruthValue,
    FR<:AbstractFrame{W,T},
} <: AbstractConditionalDataset{W,A,T,FR} end

# alphabet(::ActiveConditionalDataset)

# passive = non ha un alphabet. Ci puoi solo checkare formule
abstract type PassiveConditionalDataset{
    W<:AbstractWorld,
    A<:FeatCondition,
    T<:TruthValue,
    FR<:AbstractFrame{W,T},
} <: AbstractConditionalDataset{W,A,T,FR} end

# abstract type PassiveFeaturedDataset{N,U,W<:AbstractWorld,C<:FeatCondition,FR,FRS<:AbstractFrameSet{FR},M<:AbstractKripkeStructure{W,C,T,FR}} <: PassiveConditionalDataset{M} end

# featurevalue(::PassiveFeaturedDataset, instance_id, ::W, AbstractFeature)


# # forma passiva implicita del dataset (simile a ontological dataset)
# struct ImplicitConditionalDataset{N,U,W<:AbstractWorld,C<:FeatCondition,FR,FRS<:AbstractFrameSet{FR},M<:AbstractKripkeStructure{W,C,T,FR}} <: PassiveFeaturedDataset{M} end
#   domain::AbstractArray{N,U} # TODO questo non dovrebbe essere necessariamente dimensionale! C'è un altro Layer qui in mezzo.
#   frameset::FRS
# end

# # forma passiva esplicita (= tabella proposizionale)
# struct UniformFullDimensionalFeaturedConditionalDataset{N,U,W<:AbstractWorld,... TODO, MDA} <: PassiveFeaturedDataset{M} end
#   domain::MDA
#   features::Vector{AbstractFeature{U}}
# end

# # TODO funzioni che tipo convertono da ImplicitConditionalDataset a UniformFullDimensionalFeaturedConditionalDataset (e viceversa?).

# # forma attiva = pronta per essere learnata
# struct ConditionalDataset{
#   W<:AbstractWorld,
#   T<:TruthValue,
#   M<:AbstractKripkeStructure{W,T},
#   C<:FeatCondition, # Nota che le non sono! Quando checcki formule, devi avere vere condizioni.
#   PCD<:PassiveFeaturedDataset{U,W,C},
#   AL<:AbstractConditionalAlphabet{C}, # Però questo alfabeto può essere implementato come un vettore di MetaCondition's, che induce un alfabeto infinito di FeatCondition's
# } <: ActiveConditionalDataset{M}
#   cd:PCD
#   alphabet::AL
# end

# check(ms::ConditionalDataset{W, T, M, C}, args...) = check(ms.cd, args...) # TODO scrivere in forma estesa oppure col forward, e indica che le lettere e formule devono avere atomi di tipo C.
# accessibles(ms::ConditionalDataset{W, T, M, C}, args...) = accessibles(ms.cd, args...) # TODO scrivere in forma estesa oppure col forward, e indica che le lettere e formule devono avere atomi di tipo C.


# # TODO from here onwards

# {
#   ConditionalDatasetWithMemo <: ActiveConditionalDataset che wrappa:
#     dataset::ConditionalDataset
#     H::ConditionalDatasetMemoStructure
#   end

#   abstract ConditionalDatasetMemoStructure
# }

