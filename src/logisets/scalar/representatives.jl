using SoleLogics: AbstractUniModalFrame, AbstractFrame, AbstractRelation, GlobalRel, IdentityRel, accessibles

# TODO: AbstractFrame -> AbstractMultiModalFrame, and provide the same for AbstractUniModalFrame

"""
    function representatives(
        fr::AbstractFrame{W},
        S::W,
        ::AbstractRelation,
        ::ScalarMetaCondition
    ) where {W<:AbstractWorld}

Return an iterator to the (few) *representative* accessible worlds that are
really necessary, upon collation, for computing and propagating truth values
through existential modal operators.

This allows for some optimizations when model checking specific conditional
formulas. For example, it turns out that when you need to test a formula "⟨L⟩
(MyFeature ≥ 10)" on a world w, instead of computing "MyFeature" on all worlds
and then maximizing, computing it on a single world is enough to decide the
truth. A few cases arise depending on the relation, the feature and the test
operator (or, better, its *aggregator*).
"""
function representatives( # Dispatch on feature/aggregator pairs
    fr::AbstractFrame{W},
    w::W,
    r::AbstractRelation,
    metacond::ScalarMetaCondition
) where {W<:AbstractWorld}
    representatives(fr, w, r, feature(metacond), existential_aggregator(test_operator(metacond)))
end

function representatives(
    fr::AbstractUniModalFrame{W},
    w::W,
    metacond::ScalarMetaCondition
) where {W<:AbstractWorld}
    representatives(fr, w, feature(metacond), existential_aggregator(test_operator(metacond)))
end

# Fallbacks to `accessibles`
function representatives(
    fr::AbstractFrame{W},
    w::W,
    r::AbstractRelation,
    ::AbstractFeature,
    ::Aggregator
) where {W<:AbstractWorld}
    accessibles(fr, w, r)
end

# Global relation: dispatch on feature/aggregator pairs
function representatives(
    fr::AbstractFrame{W},
    w::W,
    r::GlobalRel,
    f::AbstractFeature,
    a::Aggregator
) where {W<:AbstractWorld}
    representatives(fr, r, f, a)
end

# Global relation: fallbacks to `accessibles`
function representatives(
    fr::AbstractFrame{W},
    r::GlobalRel,
    f::AbstractFeature,
    a::Aggregator
) where {W<:AbstractWorld}
    accessibles(fr, r)
end

# # TODO remove but probably we need this to stay because of ambiguities!
# representatives(fr::AbstractFrame{W}, w::W, r::IdentityRel, ::AbstractFeature, ::Aggregator) where {W<:AbstractWorld} = accessibles(fr, w, r)
# TODO need this?
# `representatives(fr::AbstractFrame{W}, S::AbstractWorldSet{W}, ::GlobalRel, ::ScalarMetaCondition)`
