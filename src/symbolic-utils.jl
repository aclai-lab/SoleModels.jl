using IterTools

############################################################################################
# Symbolic modeling utils
############################################################################################

"""
    submodels(m::AbstractModel)

Enumerate all submodels in the sub-tree. This function is
the transitive closure of [`immediatesubmodels`](@ref); in fact, the returned list
includes the immediate submodels (`immediatesubmodels(m)`), but also
their immediate submodels, and so on.

# Examples
```julia-repl
julia> using SoleLogics

julia> branch = Branch(SoleLogics.parseformula("p∧q∨r"), "YES", "NO");

julia> submodels(branch)
2-element Vector{SoleModels.ConstantModel{String}}:
 ConstantModel
YES

 ConstantModel
NO


julia> branch2 = Branch(SoleLogics.parseformula("s→p"), branch, 42);

julia> printmodel.(submodels(branch2));
Branch
┐ p ∧ (q ∨ r)
├ ✔ YES
└ ✘ NO

ConstantModel
YES

ConstantModel
NO

ConstantModel
42

julia> submodels(branch) == immediatesubmodels(branch)
true

julia> submodels(branch2) == immediatesubmodels(branch2)
false
```

See also [`AbstractModel`](@ref), [`immediatesubmodels`](@ref), [`LeafModel`](@ref).
"""
submodels(m::AbstractModel) = [Iterators.flatten(_submodels.(immediatesubmodels(m)))...]
_submodels(m::AbstractModel) = [m, Iterators.flatten(_submodels.(immediatesubmodels(m)))...]
_submodels(m::DecisionList) = [Iterators.flatten(_submodels.(immediatesubmodels(m)))...]
_submodels(m::DecisionTree) = [Iterators.flatten(_submodels.(immediatesubmodels(m)))...]
_submodels(m::DecisionEnsemble) = [Iterators.flatten(_submodels.(immediatesubmodels(m)))...]
_submodels(m::MixedModel) = [Iterators.flatten(_submodels.(immediatesubmodels(m)))...]

nsubmodels(m::AbstractModel) = 1 + sum(nsubmodels, immediatesubmodels(m))
nsubmodels(m::LeafModel) = 1
nsubmodels(m::DecisionList) = sum(nsubmodels, immediatesubmodels(m))
nsubmodels(m::DecisionTree) = sum(nsubmodels, immediatesubmodels(m))
nsubmodels(m::DecisionEnsemble) = sum(nsubmodels, immediatesubmodels(m))
nsubmodels(m::MixedModel) = sum(nsubmodels, immediatesubmodels(m))

leafmodels(m::AbstractModel) = [Iterators.flatten(leafmodels.(immediatesubmodels(m)))...]
leafmodels(m::LeafModel) = [m]

nleafmodels(m::AbstractModel) = sum(nleafmodels, immediatesubmodels(m))
nleafmodels(m::LeafModel) = 1

subtreeheight(m::AbstractModel) = 1 + maximum(subtreeheight, immediatesubmodels(m))
subtreeheight(m::LeafModel) = 0
subtreeheight(m::DecisionList) = maximum(subtreeheight, immediatesubmodels(m))
subtreeheight(m::DecisionTree) = maximum(subtreeheight, immediatesubmodels(m))
subtreeheight(m::DecisionEnsemble) = maximum(subtreeheight, immediatesubmodels(m))
subtreeheight(m::MixedModel) = maximum(subtreeheight, immediatesubmodels(m))
