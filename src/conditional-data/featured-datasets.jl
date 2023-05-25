# Featured datasets:

# const AbstractFeaturedDataset{
#     V<:Number,
#     W<:AbstractWorld,
#     FR<:AbstractFrame{W,Bool},
#     FT<:AbstractFeature{V}
# } = AbstractConditionalDataset{W,AbstractCondition,Bool,FR}

# function featvalue(
#     X::AbstractFeaturedDataset{W},
#     i_sample,
#     w::W,
#     f::AbstractFeature,
# ) where {W<:AbstractWorld}
#     error("Please, provide method featvalue(::$(typeof(X)), i_sample::$(typeof(i_sample)), w::$(typeof(w)), w::$(typeof(f))).")
# end

# function check(
#     p::Proposition{<:FeatCondition},
#     X::AbstractFeaturedDataset{W},
#     i_sample,
#     w::W,
# ) where {W<:AbstractWorld}
#     cond = atom(p)
#     featval = featvalue(X, i_sample, w, feature(cond))
#     apply_test_operator(test_operator(cond), featval, threshold(cond))
# end


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
# } <: AbstractActiveConditionalDataset{M}
#   cd:PCD
#   alphabet::AL
# end

# check(ms::ConditionalDataset{W, T, M, C}, args...) = check(ms.cd, args...) # TODO scrivere in forma estesa oppure col forward, e indica che le lettere e formule devono avere atomi di tipo C.
# accessibles(ms::ConditionalDataset{W, T, M, C}, args...) = accessibles(ms.cd, args...) # TODO scrivere in forma estesa oppure col forward, e indica che le lettere e formule devono avere atomi di tipo C.


# # TODO from here onwards

# {
#   ConditionalDatasetWithMemo <: AbstractActiveConditionalDataset che wrappa:
#     dataset::ConditionalDataset
#     H::ConditionalDatasetMemoStructure
#   end

#   abstract ConditionalDatasetMemoStructure
# }

