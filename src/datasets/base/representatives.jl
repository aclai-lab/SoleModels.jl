using SoleLogics: AbstractMultiModalFrame, AbstractRelation, accessibles

"""
    function representatives(
        fr::AbstractMultiModalFrame{W},
        S::W,
        ::AbstractRelation,
        ::AbstractCondition
    ) where {W<:AbstractWorld}

Return an iterator to the (few) *representative* accessible worlds that are
really necessary, upon collation, for computing and propagating truth values
through existential modal operators.

This allows for some optimizations when model checking specific conditional
formulas. For example, with scalar conditions,
it turns out that when you need to test a formula "⟨L⟩
(MyFeature ≥ 10)" on a world w, instead of computing "MyFeature" on all worlds
and then maximizing, computing it on a single world is enough to decide the
truth. A few cases arise depending on the relation, the feature and the test
operator (or, better, its *aggregator*).

Note that this method fallsback to `accessibles`.

See also
[`accessibles`](@ref),
[`ScalarCondition`](@ref),
[`AbstractMultiModalFrame`](@ref).
"""
function representatives( # Dispatch on feature/aggregator pairs
    fr::AbstractMultiModalFrame{W},
    w::W,
    r::AbstractRelation,
    mc::AbstractCondition
) where {W<:AbstractWorld}
    accessibles(fr, w, r)
end
