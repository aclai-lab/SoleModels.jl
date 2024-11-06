import SoleLogics: alphabet,
                    atoms,
                    connectives,
                    # leaves,
                    natoms,
                    nconnectives
                    # nleaves

doc_syntax_utils_models = """
    atoms(::AbstractModel)
    connectives(::AbstractModel)
    syntaxleaves(::AbstractModel)
    
    natoms(::AbstractModel)
    nconnectives(::AbstractModel)
    nsyntaxleaves(::AbstractModel)

See also
[`AbstractModel`](@ref),
[`listrules`](@ref).
"""

"""$doc_syntax_utils_models"""
atoms(m::AbstractModel) = error("Please, provide method atoms(::$(typeof(m))).")
"""$doc_syntax_utils_models"""
connectives(m::AbstractModel) = error("Please, provide method connectives(::$(typeof(m))).")
"""$doc_syntax_utils_models"""
syntaxleaves(m::AbstractModel) = error("Please, provide method syntaxleaves(::$(typeof(m))).")

"""$doc_syntax_utils_models"""
natoms(m::AbstractModel) = error("Please, provide method natoms(::$(typeof(m))).")
"""$doc_syntax_utils_models"""
nconnectives(m::AbstractModel) = error("Please, provide method nconnectives(::$(typeof(m))).")
"""$doc_syntax_utils_models"""
nsyntaxleaves(m::AbstractModel) = error("Please, provide method nsyntaxleaves(::$(typeof(m))).")



atoms(m::LeafModel) = Atom[]
connectives(m::LeafModel) = Connective[]
syntaxleaves(m::LeafModel) = SyntaxLeaf[]
natoms(m::LeafModel) = 0
nconnectives(m::LeafModel) = 0
nsyntaxleaves(m::LeafModel) = 0


atoms(m::Union{Rule,Branch}) = vcat(atoms(antecedent(m)), atoms(consequent(m)))
connectives(m::Union{Rule,Branch}) = vcat(connectives(antecedent(m)), connectives(consequent(m)))
syntaxleaves(m::Union{Rule,Branch}) = vcat(syntaxleaves(antecedent(m)), syntaxleaves(consequent(m)))
natoms(m::Union{Rule,Branch}) = natoms(antecedent(m)) + natoms(consequent(m))
nconnectives(m::Union{Rule,Branch}) = nconnectives(antecedent(m)) + nconnectives(consequent(m))
nsyntaxleaves(m::Union{Rule,Branch}) = nsyntaxleaves(antecedent(m)) + nsyntaxleaves(consequent(m))


atoms(m::Union{DecisionTree,MixedModel}) = atoms(root(m))
connectives(m::Union{DecisionTree,MixedModel}) = connectives(root(m))
syntaxleaves(m::Union{DecisionTree,MixedModel}) = syntaxleaves(root(m))
natoms(m::Union{DecisionTree,MixedModel}) = natoms(root(m))
nconnectives(m::Union{DecisionTree,MixedModel}) = nconnectives(root(m))
nsyntaxleaves(m::Union{DecisionTree,MixedModel}) = nsyntaxleaves(root(m))


atoms(m::DecisionForest) = vcat(map(atoms, trees(m))...)
connectives(m::DecisionForest) = vcat(map(connectives, trees(m))...)
syntaxleaves(m::DecisionForest) = vcat(map(syntaxleaves, trees(m))...)
natoms(m::DecisionForest) = sum(natoms, trees(m))
nconnectives(m::DecisionForest) = sum(nconnectives, trees(m))
nsyntaxleaves(m::DecisionForest) = sum(nsyntaxleaves, trees(m))



# """
#     alphabet(::AbstractModel)

# See also
# [`listrules`](@ref),
# [`atoms`](@ref),
# [`SoleLogics.Formula`](@ref).
# """
# alphabet(m::AbstractModel) = error("Please, provide method alphabet(::$(typeof(m))).")
alphabet(m::LeafModel) = SoleLogics.EmptyAlphabet()
function alphabet(m::AbstractModel, unique = true)
    atms = atoms(m)
    unique && (atms = unique(atms))
    convert(SoleLogics.AbstractAlphabet, atms)
end
