using SoleLogics: AbstractMultiModalFrame, AbstractRelation, _RelationGlob, _RelationId, accessibles

#

# It is also convenient to deploy some optimizations when you have intel about the decision
#  to test. For example, when you need to test a decision ⟨L⟩ (minimum(A2) ≥ 10) on a world w,
#  instead of computing minimum(A2) on all worlds, computing it on a single world is enough
#  to decide the truth. A few cases arise depending on the relation, the feature and the aggregator induced by the test
#  operator, thus one can provide optimized methods that return iterators to a few *representative*
#  worlds.
# accessibles_aggr(fr::AbstractMultiModalFrame{W}, f::AbstractFeature, a::Aggregator, S::AbstractWorldSet{W}, ::R)
# Of course, the fallback is enumerating all accessible worlds via `accessibles`
accessibles_aggr(fr::AbstractMultiModalFrame{W}, ::AbstractFeature, ::Aggregator, w::W, r::AbstractRelation) where {W<:AbstractWorld} = accessibles(fr, w, r)

accessibles_aggr(fr::AbstractMultiModalFrame{W}, ::AbstractFeature, ::Aggregator, w::W, r::_RelationId) where {W<:AbstractWorld} =
    accessibles(fr, w, r)

# `accessibles_aggr(fr::AbstractMultiModalFrame{W}, f::AbstractFeature, a::Aggregator, S::AbstractWorldSet{WT}, ::_RelationGlob)`

include("full-dimensional-frame/Full0DFrame.jl")
include("full-dimensional-frame/Full1DFrame.jl")
include("full-dimensional-frame/Full1DFrame+IA.jl")
include("full-dimensional-frame/Full1DFrame+RCC.jl")
include("full-dimensional-frame/Full2DFrame.jl")
