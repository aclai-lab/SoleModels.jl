using SoleLogics: AbstractAlphabet

abstract type AbstractCondition end # TODO parametric?

############################################################################################

# TODO add TruthType: T as in:
#  struct FeatMetaCondition{F<:AbstractFeature,T,O<:TestOperatorFun} <: AbstractCondition
struct FeatMetaCondition{F<:AbstractFeature,O<:TestOperatorFun} <: AbstractCondition
  
  # Feature: a scalar function that can be computed on a world
  feature::F

  # Test operator (e.g. ≥)
  test_operator::O

end

feature(m::FeatMetaCondition) = m.feature
test_operator(m::FeatMetaCondition) = m.test_operator

############################################################################################

struct FeatCondition{U,M<:FeatMetaCondition} <: AbstractCondition
  
  # Metacondition
  metacond::M
 
  # Threshold value
  a::U

  function FeatCondition(
      metacond       :: M,
      a              :: U
  ) where {M<:FeatMetaCondition,U}
      new{U,M}(metacond, a)
  end

  function FeatCondition(
      condition      :: FeatCondition{U,M},
      a              :: U
  ) where {M<:FeatMetaCondition,U}
      new{U,M}(condition.metacond, a)
  end

  function FeatCondition(
      feature       :: AbstractFeature,
      test_operator :: TestOperatorFun,
      threshold     :: U
  ) where {U}
      metacond = FeatMetaCondition(feature, test_operator)
      FeatCondition(metacond, threshold)
  end
end

# TODO fix: here, I'm assuming that metacondition isa FeatMetaCondition
feature(d::FeatCondition) = feature(d.metacond)
test_operator(d::FeatCondition) = test_operator(d.metacond)
threshold(d::FeatCondition) = d.a


# Alphabet of conditions
abstract type AbstractConditionalAlphabet{M,C<:FeatCondition{M}} <: AbstractAlphabet{C} end

# Infinite alphabet of conditions induced from a set of metaconditions
struct ExplicitConditionalAlphabet{M,C<:FeatCondition{M}} <: AbstractConditionalAlphabet{M,C}
  metaconditions::Vector{M}
end

############################################################################################

# abstract type AbstractConditionalKripkeDataset{M<:AbstractKripkeStructure} <: AbstractLogicalModelSet{M} end

# check(::AbstractConditionalKripkeDataset, ::Int, ::W, Letter{<:FeatCondition})
# accessibles(::AbstractConditionalKripkeDataset, ::Int, ::W, AbstractRelation)

# # active = ha un alphabet. Ci puoi checkare e imparare formule.
# abstract type ActiveConditionalKripkeDataset{M<:AbstractKripkeStructure} <: AbstractConditionalKripkeDataset{M} end

# alphabet(::ActiveConditionalKripkeDataset)


# # passive = non ha un alphabet. Ci puoi solo checkare formule
# abstract type PassiveConditionalKripkeDataset{M<:AbstractKripkeStructure} <: AbstractConditionalKripkeDataset{M} end

# abstract type PassiveFeaturedKripkeDataset{N,U,W<:AbstractWorld,C<:FeatCondition,FR,FRS<:AbstractFrameSet{FR},M<:AbstractKripkeStructure{W,C,T,FR}} <: PassiveConditionalKripkeDataset{M} end

# featurevalue(::PassiveFeaturedKripkeDataset, ::Int, ::W, AbstractFeature)


# # forma passiva implicita del dataset (simile a ontological dataset)
# struct ImplicitConditionalDataset{N,U,W<:AbstractWorld,C<:FeatCondition,FR,FRS<:AbstractFrameSet{FR},M<:AbstractKripkeStructure{W,C,T,FR}} <: PassiveFeaturedKripkeDataset{M} end
#   domain::AbstractArray{N,U} # TODO questo non dovrebbe essere necessariamente dimensionale! C'è un altro Layer qui in mezzo.
#   frameset::FRS
# end

# # forma passiva esplicita (= tabella proposizionale)
# struct UniformFullDimensionalFeaturedConditionalDataset{N,U,W<:AbstractWorld,... TODO, MDA} <: PassiveFeaturedKripkeDataset{M} end
#   domain::MDA
#   features::Vector{AbstractFeature{U}}
# end

# # TODO funzioni che tipo convertono da ImplicitConditionalDataset a UniformFullDimensionalFeaturedConditionalDataset (e viceversa?).

# # forma attiva = pronta per essere learnata
# struct ConditionalKripkeDataset{
#   W<:AbstractWorld,
#   T<:TruthValue,
#   M<:AbstractKripkeStructure{W,T},
#   C<:FeatCondition, # Nota che le non sono! Quando checcki formule, devi avere vere condizioni.
#   PCD<:PassiveFeaturedKripkeDataset{U,W,C},
#   AL<:AbstractConditionalAlphabet{C}, # Però questo alfabeto può essere implementato come un vettore di MetaCondition's, che induce un alfabeto infinito di FeatCondition's
# } <: ActiveConditionalKripkeDataset{M}
#   cd:PCD
#   alphabet::AL
# end

# check(ms::ConditionalKripkeDataset{W, T, M, C}, args...) = check(ms.cd, args...) # TODO scrivere in forma estesa oppure col forward, e indica che le lettere e formule devono avere atomi di tipo C.
# accessibles(ms::ConditionalKripkeDataset{W, T, M, C}, args...) = accessibles(ms.cd, args...) # TODO scrivere in forma estesa oppure col forward, e indica che le lettere e formule devono avere atomi di tipo C.


# # TODO from here onwards

# {
#   ConditionalKripkeDatasetWithMemo <: ActiveConditionalKripkeDataset che wrappa:
#     dataset::ConditionalKripkeDataset
#     H::ConditionalKripkeDatasetMemoStructure
#   end

#   abstract ConditionalKripkeDatasetMemoStructure
# }

# abstract type AbstractDimensionalFrame{N,W<:AbstractWorld,T<:TruthValue} <: AbstractMultiModalFrame{W,T} end

# struct FullDimensionalFrame{N,W<:AbstractWorld,T<:TruthValue} <: AbstractDimensionalFrame{W,T}
#   size::NTuple{N,Int}
# end

