
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
    typeof(a)(children(a)[idxs])
    # Rule{O}(typeof(a)(children(a)[idxs]), consequent(m))
end

function Base.getindex(
    m::Rule{O},
    ind::Integer,
) where {O}
    a = antecedent(m)
    @assert a isa LeftmostLinearForm "Cannot slice Rule with antecedent of type $(a)"
    children(a)[ind]
    # Rule{O}(children(a)[ind], consequent(m))
end

# Helper: slice a Branch's antecedent
function Base.getindex(
    m::Branch{O},
    idxs::Union{AbstractVector,Colon},
) where {O}
    a = antecedent(m)
    @assert a isa LeftmostLinearForm "Cannot slice Branch with antecedent of type $(a)"
    typeof(a)(children(a)[idxs])
    # Branch{O}(typeof(a)(children(a)[idxs]), posconsequent(m), negconsequent(m))
end
function Base.getindex(
    m::Branch{O},
    ind::Integer,
) where {O}
    a = antecedent(m)
    @assert a isa LeftmostLinearForm "Cannot slice Branch with antecedent of type $(a)"
    children(a)[ind]
    # Branch{O}(children(a)[ind], posconsequent(m), negconsequent(m))
end
