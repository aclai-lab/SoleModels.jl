############################################################################################
# Symbolic modeling utils
############################################################################################

"""
This function provides access to the list of immediate child models; 
the list is empty for `FinalModel`s.

See also [`all_submodels`](@ref), [`BoundedModel`](@ref), [`FinalModel`](@ref).
"""
immediate_submodels(m::AbstractModel{F} where {F})::Vector{<:{AbstractModel{<:F}}} =
    error("Please, provide method immediate_submodels(::$(typeof(m))).")

immediate_submodels(m::FinalModel{F}) where {F} = Vector{<:AbstractModel{<:F}}[]
immediate_submodels(m::Rule) = [consequent(m)]
immediate_submodels(m::Branch) = [positive_consequent(m), negative_consequent(m)]
immediate_submodels(m::DecisionList) = [rules(m)..., consequent(m)]
immediate_submodels(m::RuleCascade) = [consequent(m)]
immediate_submodels(m::DecisionTree) = immediate_submodels(root(m))
immediate_submodels(m::MixedSymbolicModel) = immediate_submodels(root(m))

"""
This function provides access to the list of all child models in the sub-tree.

See also [`immediate_submodels`](@ref), [`BoundedModel`](@ref), [`FinalModel`](@ref).
"""
all_submodels(m::AbstractModel) = [Iterators.flatten(_all_submodels.(immediate_submodels(m)))...]
_all_submodels(m::AbstractModel) = [m, Iterators.flatten(_all_submodels.(immediate_submodels(m)))...]


############################################################################################
############################################################################################
############################################################################################

"""
When `assumed_formula` is assumed, and `f` is known to be true, their conjuction holds.
"""
advance_formula(f::Formula, assumed_formula::Union{Nothing,Formula}) = 
    isnothing(assumed_formula) ? f : SoleLogics.CONJUNCTION(assumed_formula, f)

advance_formula(r::R where {R<:Rule}, assumed_formula::Union{Nothing,Formula}) = 
    R(advance_formula(antecedent(r), assumed_formula), consequent(r), info(r))

############################################################################################
############################################################################################
############################################################################################

"""
$(doc_symbolic)
Every symbolic model must provide access to its corresponding immediate rules via the
`list_immediate_rules` trait.

See also [`unroll_rules`](@ref), [`is_symbolic`](@ref), [`AbstractModel`](@ref).
"""
list_immediate_rules(m::AbstractModel{F} where {F})::Rule{<:F} =
    error(begin
        if is_symbolic(m)
            "Please, provide method list_immediate_rules(::$(typeof(m))) ($(typeof(m)) is a symbolic model)."
        else
            "Models of type $(typeof(m)) are not symbolic, and thus have no rules associated."
        end
    end)

list_immediate_rules(m::FinalModel) = [Rule(SoleLogics.TOP, m)]

list_immediate_rules(m::Rule) = [m]

list_immediate_rules(m::Branch{F, L, FIM}) where {F,L,FIM} = [
    Rule{F,L,FIM}(antecedent(m), positive_consequent(m)),
    Rule{F,L,FIM}(SoleLogics.NEGATION(antecedent(m)), negative_consequent(m)),
]

function list_immediate_rules(m::DecisionList{F,L,FIM}) where {F,L,FIM}
    assumed_formula = nothing
    normalized_rules = Vector{eltype(rules(m))}[]
    for rule in rules(m)
        rule = advance_formula(rule, assumed_formula)
        assumed_formula = advance_formula(SoleLogics.NEGATION(antecedent(rule)), assumed_formula)
    end
    default_antecedent = isnothing(assumed_formula) ? SoleLogics.TOP : assumed_formula
    push!(normalized_rules, Rule{F,L,FIM}(default_antecedent, default_consequent(m)))
    normalized_rules
end

list_immediate_rules(m::RuleCascade) = [to_rule(m)]

list_immediate_rules(m::DecisionTree) = list_immediate_rules(root(m))

list_immediate_rules(m::MixedSymbolicModel) = list_immediate_rules(root(m))

############################################################################################
############################################################################################
############################################################################################

"""
$(doc_symbolic)
This function extracts the behavior of a symbolic model and represents it as a
set of mutually exclusive (and jointly exaustive, if the model is closed) rules,
which can be useful
for many purposes.

See also [`list_immediate_rules`](@ref), [`is_symbolic`](@ref), [`AbstractModel`](@ref).
"""
function unroll_rules(m::AbstractModel, assumed_formula = nothing)
    # TODO @Michele
    # [advance_formula(rule) for rule in unroll_rules(m)]
end

# """
# List all paths of a decision tree by performing a tree traversal
# TODO @Michele
# """
# function list_paths(tree::DecisionTree{L<:AbstractLogic, O<:Outcome})::AbstractVector{<:AbstractVector{Union{FinalOutcome,Rule{L,O}}}}
#     return list_immediate_rules(root(tree))
# end
