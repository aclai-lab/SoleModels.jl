#= This entire page is temporarily commented out for compiling purposes
using SoleLogics: LeftmostLinearForm, LeftmostConjunctiveForm, LeftmostDisjunctiveForm

# Helpers
function conjuncts(m::Rule{O,<:LogicalTruthCondition{<:LeftmostConjunctiveForm}}) where {O}
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
=#

#=
function Base.getindex(
    m::Rule{O,C},
    idxs::AbstractVector{<:Integer},
) where {O,C<:LogicalTruthCondition{SS},SS<:LeftmostLinearForm}
    Rule{O,C}(
        LogicalTruthCondition{SS}(begin
            ants = children(formula(m))
            SS(ants[idxs])
        end),
        consequent(m)
    )
end
Base.getindex(m::Rule{O,C}, args...) where {O,C<:TrueCondition} = m

Base.getindex(m::Branch, args...) = Base.getindex(formula(m), args...)
=#
