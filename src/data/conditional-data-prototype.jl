abstract type AbstractCondition end # TODO parametric?

abstract type AbstractMetaCondition <: AbstractCondition end # TODO parametric?

struct Condition{M<:AbstractMetaCondition,U} <: AbstractCondition
  metacond::M
  a::U
end

# Alphabet of conditions
abstract AbstractConditionalAlphabet{M,C<:Condition{M, U}} <: AbstractAlphabet{C} end

# Infinite alphabet of conditions induced from a set of metaconditions
ExplicitConditionalAlphabet{M,C<:Condition{M, U}}
  metaconditions::Vector{M}
end

############################################################################################

# Feature (modal features in ModalDecisionTrees.jl)
abstract type AbstractFeature{U} end

struct FeaturedMetaCondition{F<:AbstractFeature,T,O<:FunctionWrapper{T}} <: AbstractMetaCondition
  feature::F
  operator::O
end

############################################################################################

abstract type AbstractConditionalKripkeDataset{M<:AbstractKripkeModel} <: AbstractLogicalModelSet{M} end

check(::AbstractConditionalKripkeDataset, ::Int, ::W, Letter{<:Condition})
accessibles(::AbstractConditionalKripkeDataset, ::Int, ::W, AbstractRelation)

# active = ha un alphabet. Ci puoi checkare e imparare formule.
abstract type ActiveConditionalKripkeDataset{M<:AbstractKripkeModel} <: AbstractConditionalKripkeDataset{M} end

alphabet(::ActiveConditionalKripkeDataset)


# passive = non ha un alphabet. Ci puoi solo checkare formule
abstract type PassiveConditionalKripkeDataset{M<:AbstractKripkeModel} <: AbstractConditionalKripkeDataset{M} end

abstract type PassiveFeaturedKripkeDataset{N,U,W<:AbstractWorld,C<:Condition,KF,KFS<:AbstractFrameSet{KF},M<:AbstractKripkeModel{W,C,T,KF}} <: PassiveConditionalKripkeDataset{M} end

featurevalue(::PassiveFeaturedKripkeDataset, ::Int, ::W, AbstractFeature)


# forma passiva implicita del dataset (simile a ontological dataset)
struct ImplicitConditionalDataset{N,U,W<:AbstractWorld,C<:Condition,KF,KFS<:AbstractFrameSet{KF},M<:AbstractKripkeModel{W,C,T,KF}} <: PassiveFeaturedKripkeDataset{M} end
  domain::AbstractArray{N,U} # TODO questo non dovrebbe essere necessariamente dimensionale! C'è un altro Layer qui in mezzo.
  frameset::KFS
end

# forma passiva esplicita (= tabella proposizionale)
struct UniformFullDimensionalFeaturedConditionalDataset{N,U,W<:AbstractWorld,... TODO, MDA} <: PassiveFeaturedKripkeDataset{M} end
  domain::MDA
  features::Vector{AbstractFeature{U}}
end

# TODO funzioni che tipo convertono da ImplicitConditionalDataset a UniformFullDimensionalFeaturedConditionalDataset (e viceversa?).

# forma attiva = pronta per essere learnata
struct ConditionalKripkeDataset{
  W<:AbstractWorld,
  T<:TruthValue,
  M<:AbstractKripkeModel{W,T},
  C<:Condition, # Nota che le non sono! Quando checcki formule, devi avere vere condizioni.
  PCD<:PassiveFeaturedKripkeDataset{U,W,C},
  AL<:AbstractConditionalAlphabet{C}, # Però questo alfabeto può essere implementato come un vettore di MetaCondition's, che induce un alfabeto infinito di Condition's
} <: ActiveConditionalKripkeDataset{M}
  cd:PCD
  alphabet::AL
end

check(ms::ConditionalKripkeDataset{W, T, M, C}, args...) = check(ms.cd, args...) # TODO scrivere in forma estesa oppure col forward, e indica che le lettere e formule devono avere atomi di tipo C.
accessibles(ms::ConditionalKripkeDataset{W, T, M, C}, args...) = accessibles(ms.cd, args...) # TODO scrivere in forma estesa oppure col forward, e indica che le lettere e formule devono avere atomi di tipo C.


# TODO from here onwards

{
  ConditionalKripkeDatasetWithMemo <: ActiveConditionalKripkeDataset che wrappa:
    dataset::ConditionalKripkeDataset
    H::ConditionalKripkeDatasetMemoStructure
  end

  abstract ConditionalKripkeDatasetMemoStructure
}

abstract type AbstractDimensionalFrame{N,W<:AbstractWorld,T<:TruthValue,NR,Rs<:NTuple{NR,<:AbstractRelation}} <: AbstractMultiModalFrame{W,T,NR,Rs} end

struct FullDimensionalFrame{N,W<:AbstractWorld,T<:TruthValue,NR,Rs<:NTuple{NR,<:AbstractRelation}} <: AbstractDimensionalFrame{W,T,NR,Rs}
  size::NTuple{N,Int}
end

