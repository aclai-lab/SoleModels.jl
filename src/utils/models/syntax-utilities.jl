

# Syntax functions for for LeafModel
atoms(m::LeafModel) = Atom[]
connectives(m::LeafModel) = Connective[]
syntaxleaves(m::LeafModel) = SyntaxLeaf[]
natoms(m::LeafModel) = 0
nconnectives(m::LeafModel) = 0
nsyntaxleaves(m::LeafModel) = 0


# Syntax functions for Rules and Branches
atoms(m::Union{Rule,Branch}) = vcat(atoms(antecedent(m)), atoms.(immediatesubmodels(m))...)
connectives(m::Union{Rule,Branch}) = vcat(connectives(antecedent(m)), connectives.(immediatesubmodels(m))...)
syntaxleaves(m::Union{Rule,Branch}) = vcat(syntaxleaves(antecedent(m)), syntaxleaves.(immediatesubmodels(m))...)
natoms(m::Union{Rule,Branch}) =  sum([natoms(antecedent(m)), natoms.(immediatesubmodels(m))...])
nconnectives(m::Union{Rule,Branch}) =  sum([nconnectives(antecedent(m)), nconnectives.(immediatesubmodels(m))...])
nsyntaxleaves(m::Union{Rule,Branch}) =  sum([nsyntaxleaves(antecedent(m)), nsyntaxleaves.(immediatesubmodels(m))...])


# Syntax functions for Decision Trees and MixedModels
atoms(m::Union{DecisionTree,MixedModel}) = atoms(root(m))
connectives(m::Union{DecisionTree,MixedModel}) = connectives(root(m))
syntaxleaves(m::Union{DecisionTree,MixedModel}) = syntaxleaves(root(m))
natoms(m::Union{DecisionTree,MixedModel}) = natoms(root(m))
nconnectives(m::Union{DecisionTree,MixedModel}) = nconnectives(root(m))
nsyntaxleaves(m::Union{DecisionTree,MixedModel}) = nsyntaxleaves(root(m))


# Syntax functions for Decision Lists
atoms(m::DecisionList) = vcat(map(atoms, rulebase(m))..., atoms(defaultconsequent(m)))
connectives(m::DecisionList) = vcat(map(connectives, rulebase(m))..., connectives(defaultconsequent(m)))
syntaxleaves(m::DecisionList) = vcat(map(syntaxleaves, rulebase(m))..., syntaxleaves(defaultconsequent(m)))
natoms(m::DecisionList) = sum(map(natoms, rulebase(m))..., natoms(defaultconsequent(m)))
nconnectives(m::DecisionList) = sum(map(connectives, rulebase(m))..., nconnectives(defaultconsequent(m)))
nsyntaxleaves(m::DecisionList) = sum(map(syntaxleaves, rulebase(m))..., nsyntaxleaves(defaultconsequent(m)))


# Syntax functions for Decision Ensembles
atoms(m::DecisionEnsemble) = vcat(map(atoms, models(m))...)
connectives(m::DecisionEnsemble) = vcat(map(connectives, models(m))...)
syntaxleaves(m::DecisionEnsemble) = vcat(map(syntaxleaves, models(m))...)
natoms(m::DecisionEnsemble) = sum(natoms, models(m))
nconnectives(m::DecisionEnsemble) = sum(nconnectives, models(m))
nsyntaxleaves(m::DecisionEnsemble) = sum(nsyntaxleaves, models(m))


# Syntax functions for DecisionXGBoost
atoms(m::DecisionXGBoost) = vcat(map(atoms, models(m))...)
connectives(m::DecisionXGBoost) = vcat(map(connectives, models(m))...)
syntaxleaves(m::DecisionXGBoost) = vcat(map(syntaxleaves, models(m))...)
natoms(m::DecisionXGBoost) = sum(natoms, models(m))
nconnectives(m::DecisionXGBoost) = sum(nconnectives, models(m))
nsyntaxleaves(m::DecisionXGBoost) = sum(nsyntaxleaves, models(m))



# """
#     alphabet(::AbstractModel)

# See also
# [`listrules`](@ref),
# [`atoms`](@ref),
# [`SoleLogics.Formula`](@ref).
# """
# alphabet(m::AbstractModel) = error("Please, provide method alphabet(::$(typeof(m))).")
alphabet(m::LeafModel, unique = true) = SoleLogics.EmptyAlphabet()
function alphabet(m::AbstractModel, unique = true)
    atms = atoms(m)
    unique && (atms = Base.unique(atms))
    convert(SoleLogics.AbstractAlphabet, atms)
end
