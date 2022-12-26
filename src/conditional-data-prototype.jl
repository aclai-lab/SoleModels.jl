abstract type AbstractCondition end # TODO parametric?

abstract type AbstractMetaCondition <: AbstractCondition end # TODO parametric?

struct Condition{M<:AbstractMetaCondition,U} <: AbstractCondition
  metacond::M
  a::U
end


abstract AbstractConditionalAlphabet{M,C<:Condition{M, U}} <: AbstractAlphabet{C} end

ExplicitConditionalAlphabet{M,C<:Condition{M, U}}
  metaconditions::Vector{M}
end

############################################################################################

abstract type AbstractFeature{U} end

struct FeaturedMetaCondition{F<:AbstractFeature,T,O<:FunctionWrapper{T}} <: AbstractMetaCondition
  feature::F
  operator::O
end

############################################################################################

abstract type AbstractConditionalKripkeDataset{M<:AbstractKripkeModel} <: AbstractLogicalModelSet{M} end

check(::AbstractConditionalKripkeDataset, ::Int, ::W, Letter{<:Condition})
accessibles(::AbstractConditionalKripkeDataset, ::Int, ::W, AbstractRelation)

abstract type ActiveConditionalKripkeDataset{M<:AbstractKripkeModel} <: AbstractConditionalKripkeDataset{M} end

alphabet(::ActiveConditionalKripkeDataset)

abstract type PassiveConditionalKripkeDataset{M<:AbstractKripkeModel} <: AbstractConditionalKripkeDataset{M} end

abstract type PassiveFeaturedKripkeDataset{N,U,W<:AbstractWorld,C<:Condition,KF,KFS<:AbstractFrameSet{KF},M<:AbstractKripkeModel{W,C,T,KF}} <: PassiveConditionalKripkeDataset{M} end

featurevalue(::PassiveFeaturedKripkeDataset, ::Int, ::W, AbstractFeature)


struct ImplicitConditionalDataset{N,U,W<:AbstractWorld,C<:Condition,KF,KFS<:AbstractFrameSet{KF},M<:AbstractKripkeModel{W,C,T,KF}} <: PassiveFeaturedKripkeDataset{M} end
  domain::AbstractArray{N,U} # TODO questo non dovrebbe essere necessariamente dimensionale! C'è un altro Layer qui in mezzo.
  frameset::KFS
end

struct UniformFullDimensionalFeaturedConditionalDataset{N,U,W<:AbstractWorld,... TODO, MDA} <: PassiveFeaturedKripkeDataset{M} end
  domain::MDA
  features::Vector{AbstractFeature{U}}
end



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



TODO{
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

