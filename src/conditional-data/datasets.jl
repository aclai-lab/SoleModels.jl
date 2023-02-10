using SoleLogics: AbstractKripkeStructure, AbstractInterpretationSet, AbstractFrame
import SoleLogics: check, accessibles

abstract type AbstractConditionalDataset{
    W<:AbstractWorld,
    A<:AbstractCondition,
    T<:TruthValue,
    FR<:AbstractFrame{W,T},
} <: AbstractInterpretationSet{AbstractKripkeStructure{W,A,T,FR}} end

worldtype(::Type{<:AbstractConditionalDataset{W,A,T,FR}}) where {W,A,T,FR} = W
worldtype(d::AbstractConditionalDataset) = worldtype(typeof(d))

frametype(::Type{<:AbstractConditionalDataset{W,A,T,FR}}) where {W,A,T,FR} = FR
frametype(d::AbstractConditionalDataset) = frametype(typeof(d))

truthtype(::Type{<:AbstractConditionalDataset{W,A,T,FR}}) where {W,A,T,FR} = T
truthtype(d::AbstractConditionalDataset) = truthtype(typeof(d))

function check(
    ::AbstractConditionalDataset{W,AA,T},
    i_sample,
    ::W,
    ::Proposition{A},
)::T where {W<:AbstractWorld,AA<:AbstractCondition,T<:TruthValue,A<:AA}
    error("Please, provide ...")
end

function check(
    ::AbstractConditionalDataset{W,A,T},
    i_sample,
    ::W,
    ::Formula,
)::T where {W<:AbstractWorld,A<:AbstractCondition,T<:TruthValue}
    error("Please, provide ...")
end


function accessibles(
    ::AbstractConditionalDataset{W,A,T},
    i_sample,
    ::W,
    ::AbstractRelation,
) where {W<:AbstractWorld,A<:AbstractCondition,T<:TruthValue}
    error("Please, provide ...")
end

# TODO from here onwards

# # active = has an alphabet. Ci puoi checkare e imparare formule.
# abstract type ActiveConditionalDataset{
#     W<:AbstractWorld,
#     A<:AbstractCondition,
#     T<:TruthValue,
#     FR<:AbstractFrame{W,T},
# } <: AbstractConditionalDataset{W,A,T,FR} end

# # alphabet(::ActiveConditionalDataset)

# # passive = non ha un alphabet. Ci puoi solo checkare formule
# abstract type PassiveConditionalDataset{
#     W<:AbstractWorld,
#     A<:AbstractCondition,
#     T<:TruthValue,
#     FR<:AbstractFrame{W,T},
# } <: AbstractConditionalDataset{W,A,T,FR} end

# abstract type PassiveFeaturedDataset{N,U,W<:AbstractWorld,C<:AbstractCondition,FR,FRS<:AbstractFrameSet{FR},M<:AbstractKripkeStructure{W,C,T,FR}} <: PassiveConditionalDataset{M} end

# featvalue(::PassiveFeaturedDataset, i_sample, ::W, AbstractFeature)


# # forma passiva implicita del dataset (simile a ontological dataset)
# struct ImplicitConditionalDataset{N,U,W<:AbstractWorld,C<:AbstractCondition,FR,FRS<:AbstractFrameSet{FR},M<:AbstractKripkeStructure{W,C,T,FR}} <: PassiveFeaturedDataset{M} end
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
#   C<:AbstractCondition, # Nota che le non sono! Quando checcki formule, devi avere vere condizioni.
#   PCD<:PassiveFeaturedDataset{U,W,C},
#   AL<:AbstractConditionalAlphabet{C}, # Però questo alfabeto può essere implementato come un vettore di MetaCondition's, che induce un alfabeto infinito di AbstractCondition's
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

