
using SoleLogics: LeftmostConjunctiveForm
import SoleLogics: conjuncts, nconjuncts, disjuncts, ndisjuncts

function conjuncts(m::Rule)
    @assert antecedent(m) isa LeftmostConjunctiveForm
    conjuncts(antecedent(m))
end
function nconjuncts(m::Rule)
    @assert antecedent(m) isa LeftmostConjunctiveForm
    nconjuncts(antecedent(m))
end
function disjuncts(m::Rule)
    @assert antecedent(m) isa LeftmostDisjunctiveForm
    disjuncts(antecedent(m))
end
function ndisjuncts(m::Rule)
    @assert antecedent(m) isa LeftmostDisjunctiveForm
    ndisjuncts(antecedent(m))
end

# Helper: slice a Rule's antecedent
function Base.getindex(
    m::Rule{O},
    idxs::Union{AbstractVector,Colon},
) where {O}
    a = antecedent(m)
    @assert a isa LeftmostLinearForm "Cannot slice Rule with antecedent of type $(a)"
    typeof(a)(SoleLogics.grandchildren(a)[idxs])
    # Rule{O}(typeof(a)(SoleLogics.grandchildren(a)[idxs]), consequent(m))
end

function Base.getindex(
    m::Rule{O},
    ind::Integer,
) where {O}
    a = antecedent(m)
    @assert a isa LeftmostLinearForm "Cannot slice Rule with antecedent of type $(a)"
    SoleLogics.grandchildren(a)[ind]
    # Rule{O}(SoleLogics.grandchildren(a)[ind], consequent(m))
end

# Helper: slice a Branch's antecedent
function Base.getindex(
    m::Branch{O},
    idxs::Union{AbstractVector,Colon},
) where {O}
    a = antecedent(m)
    @assert a isa LeftmostLinearForm "Cannot slice Branch with antecedent of type $(a)"
    typeof(a)(SoleLogics.grandchildren(a)[idxs])
    # Branch{O}(typeof(a)(SoleLogics.grandchildren(a)[idxs]), posconsequent(m), negconsequent(m))
end
function Base.getindex(
    m::Branch{O},
    ind::Integer,
) where {O}
    a = antecedent(m)
    @assert a isa LeftmostLinearForm "Cannot slice Branch with antecedent of type $(a)"
    SoleLogics.grandchildren(a)[ind]
    # Branch{O}(SoleLogics.grandchildren(a)[ind], posconsequent(m), negconsequent(m))
end
