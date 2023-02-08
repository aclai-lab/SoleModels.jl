using SoleLogics: AbstractMultiModalFrame, AbstractRelation, _RelationGlob, _RelationId, accessibles

#

# It is also convenient to deploy some optimizations when you have intel about the decision
#  to test. For example, when you need to test a decision ⟨L⟩ (minimum(A2) ≥ 10) on a world w,
#  instead of computing minimum(A2) on all worlds, computing it on a single world is enough
#  to decide the truth. A few cases arise depending on the relation, the feature and the aggregator induced by the test
#  operator, thus one can provide optimized methods that return iterators to a few *representative*
#  worlds.
# representatives(fr::AbstractMultiModalFrame{W}, S::AbstractWorldSet{W}, ::R, ::FeatMetaCondition)
# Of course, the fallback is enumerating all accessible worlds via `accessibles`
# TODO why existential? Is this canonical?
representatives(fr::AbstractMultiModalFrame{W}, w::W, r::AbstractRelation, mc::FeatMetaCondition) where {W<:AbstractWorld} =
    representatives(fr, w, r, feature(mc), existential_aggregator(test_operator(mc)))
representatives(fr::AbstractMultiModalFrame{W}, w::W, r::AbstractRelation, ::AbstractFeature, ::Aggregator) where {W<:AbstractWorld} = accessibles(fr, w, r)

representatives(fr::AbstractMultiModalFrame{W}, w::W, r::_RelationGlob, f::AbstractFeature, a::Aggregator) where {W<:AbstractWorld} = representatives(fr, r, f, a)

representatives(fr::AbstractMultiModalFrame{W}, r::_RelationGlob, f::AbstractFeature, a::Aggregator) where {W<:AbstractWorld} = accessibles(fr, r)

# # TODO remove but probably we need this to stay because of ambiguities!
# representatives(fr::AbstractMultiModalFrame{W}, w::W, r::_RelationId, ::AbstractFeature, ::Aggregator) where {W<:AbstractWorld} = accessibles(fr, w, r)


# TODO need this?
# `representatives(fr::AbstractMultiModalFrame{W}, S::AbstractWorldSet{WT}, ::_RelationGlob, ::FeatMetaCondition)`

include("full-dimensional-frame/Full0DFrame.jl")
include("full-dimensional-frame/Full1DFrame.jl")
include("full-dimensional-frame/Full1DFrame+IA.jl")
include("full-dimensional-frame/Full1DFrame+RCC.jl")
include("full-dimensional-frame/Full2DFrame.jl")
