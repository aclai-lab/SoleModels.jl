


atoms(m::LeafModel) = Atom[]
connectives(m::LeafModel) = Connective[]
syntaxleaves(m::LeafModel) = SyntaxLeaf[]
natoms(m::LeafModel) = 0
nconnectives(m::LeafModel) = 0
nsyntaxleaves(m::LeafModel) = 0


atoms(m::Union{Rule,Branch}) = vcat(atoms(antecedent(m)), atoms.(immediatesubmodels(m))...)
connectives(m::Union{Rule,Branch}) = vcat(connectives(antecedent(m)), connectives.(immediatesubmodels(m))...)
syntaxleaves(m::Union{Rule,Branch}) = vcat(syntaxleaves(antecedent(m)), syntaxleaves.(immediatesubmodels(m))...)
natoms(m::Union{Rule,Branch}) =  sum([natoms(antecedent(m)), natoms.(immediatesubmodels(m))...])
nconnectives(m::Union{Rule,Branch}) =  sum([nconnectives(antecedent(m)), nconnectives.(immediatesubmodels(m))...])
nsyntaxleaves(m::Union{Rule,Branch}) =  sum([nsyntaxleaves(antecedent(m)), nsyntaxleaves.(immediatesubmodels(m))...])


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
    unique && (atms = Base.unique(atms))
    convert(SoleLogics.AbstractAlphabet, atms)
end
