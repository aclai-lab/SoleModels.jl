
# Helpers
function nconjuncts(m::Rule{O,<:LogicalTruthCondition{<:LeftmostConjunctiveForm}}) where {O}
    children(formula(m))
end
function nconjuncts(m::Rule{O,<:LogicalTruthCondition{<:LeftmostConjunctiveForm}}) where {O}
    nchildren(formula(m))
end
function disjuncts(m::Rule{O,<:LogicalTruthCondition{<:LeftmostDisjunctiveForm}}) where {O}
    children(formula(m))
end
function ndisjuncts(m::Rule{O,<:LogicalTruthCondition{<:LeftmostDisjunctiveForm}}) where {O}
    nchildren(formula(m))
end
function Base.getindex(
    m::Rule{O,C},
    idxs,
) where {O,C<:LogicalTruthCondition{SS},SS<:LeftmostLinearForm}
    Rule{O,C}(
        LogicalTruthCondition{SS}(begin
            ants = children(formula(m))
            SS(ants[idxs])
        end),
        consequent(m)
    )
end
