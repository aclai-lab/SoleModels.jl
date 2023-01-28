export immediate_submodels, unroll_rules, list_immediate_rules, unroll_rules_cascade, list_paths

############################################################################################
# Symbolic modeling utils
############################################################################################

"""
This function provides access to the list of immediate child models;
the list is empty for `FinalModel`s.

See also [`all_submodels`](@ref), [`ConstrainedModel`](@ref), [`FinalModel`](@ref).
"""
immediate_submodels(m::AbstractModel{O} where {O})::Vector{<:{AbstractModel{<:O}}} =
    error("Please, provide method immediate_submodels(::$(typeof(m))).")

immediate_submodels(m::FinalModel{O}) where {O} = Vector{<:AbstractModel{<:O}}[]
immediate_submodels(m::Rule) = [consequent(m)]
immediate_submodels(m::Branch) = [positive_consequent(m), negative_consequent(m)]
immediate_submodels(m::DecisionList) = [rules(m)..., consequent(m)]
immediate_submodels(m::RuleCascade) = [consequent(m)]
immediate_submodels(m::DecisionTree) = immediate_submodels(root(m))
immediate_submodels(m::MixedSymbolicModel) = immediate_submodels(root(m))

"""
This function provides access to the list of all child models in the sub-tree.

See also [`immediate_submodels`](@ref), [`ConstrainedModel`](@ref), [`FinalModel`](@ref).
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

See also [`unroll_rules`](@ref), [`unroll_rules_cascade`](@ref), [`issymbolic`](@ref),
[`AbstractModel`](@ref).
"""
list_immediate_rules(m::AbstractModel{O} where {O})::Rule{<:O} =
    error(begin
        if issymbolic(m)
            "Please, provide method list_immediate_rules(::$(typeof(m))) ($(typeof(m)) is a symbolic model)."
        else
            "Models of type $(typeof(m)) are not symbolic, and thus have no rules associated."
        end
    end)

list_immediate_rules(m::FinalModel) = [Rule(TOP, m)]

list_immediate_rules(m::Rule) = [m]

list_immediate_rules(m::Branch{O, FM}) where {O, FM} = [
    Rule{O,FM}(antecedent(m), positive_consequent(m)),
    Rule{O,FM}(SoleLogics.NEGATION(antecedent(m)), negative_consequent(m)),
]

function list_immediate_rules(m::DecisionList{O,FM}) where {O,FM}
    assumed_formula = nothing
    normalized_rules = Vector{eltype(rules(m))}[]
    for rule in rules(m)
        rule = advance_formula(rule, assumed_formula)
        assumed_formula = advance_formula(SoleLogics.NEGATION(antecedent(rule)), assumed_formula)
    end
    default_antecedent = isnothing(assumed_formula) ? TOP : assumed_formula
    push!(normalized_rules, Rule{O,FM}(default_antecedent, default_consequent(m)))
    normalized_rules
end

list_immediate_rules(m::RuleCascade) = [convert(Rule, m)]

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

See also [`list_immediate_rules`](@ref), [`unroll_rules_cascade`](@ref),
[`issymbolic`](@ref), [`AbstractModel`](@ref).
"""
function unroll_rules(m::AbstractModel, assumed_formula = nothing)
    # TODO @Michele
    # [advance_formula(rule) for rule in unroll_rules(m)]
    error(begin
        if issymbolic(m)
            "Please, provide method unroll_rules(::$(typeof(m))) ($(typeof(m)) is a symbolic model)."
        else
            "Models of type $(typeof(m)) are not symbolic, and thus have no rules associated."
        end
    end)
end

unroll_rules(m::FinalModel) = [m]

unroll_rules(m::Rule) = [m]

function unroll_rules(m::Branch{O,<:LogicalTruthCondition}) where {O}
    pos_rules = begin
        r = unroll_rules(positive_consequent(m))
        r isa Vector{<:FinalModel} ?
            [Rule(antecedent(m),fm) for fm in r] :
            [Rule(
                LogicalTruthCondition(
                    ∧(formula(antecedent(m)),formula(antecedent(rule)))
                ),
                consequent(rule),
            ) for rule in r]
    end

    neg_rules = begin
        r = unroll_rules(negative_consequent(m))
        r isa Vector{<:FinalModel} ?
            [Rule(
                LogicalTruthCondition(¬(formula(antecedent(m))))
                ,fm) for fm in r] :
            [Rule(
                LogicalTruthCondition(
                    ∧(¬(formula(antecedent(m))),formula(antecedent(rule)))
                ),
                consequent(rule),
            ) for rule in r]
    end

    return [
        pos_rules...,
        neg_rules...,
    ]
end

unroll_rules(m::DecisionList) = [
    rules(m)...,
    Rule(
        LogicalTruthCondition(SyntaxTree(⊤)),
        unroll_rules(default_consequent(m))...,
    ),
]

function unroll_rules(m::RuleCascade)
    rules = begin
        r = unroll_rules(consequent(m))
        r isa Vector{<:FinalModel} ?
            [Rule(antecedent(m),fm) for fm in r] :
            [Rule(
                LogicalTruthCondition(
                    ∧(formula(antecedent(m)),formula(antecedent(rule)))
                ),
                consequent(rule),
            ) for rule in r]
    end

    return [rules...]
end

unroll_rules(m::DecisionTree) = unroll_rules(root(m))

unroll_rules(m::MixedSymbolicModel) = unroll_rules(root(m))

############################################################################################
############################################################################################
############################################################################################

"""
$(doc_symbolic)
This function extracts the behavior of a symbolic model and represents it as a
set of mutually exclusive (and jointly exaustive, if the model is closed) rules cascade
vectors, which can be useful for many purposes.

See also [`list_immediate_rules`](@ref), [`issymbolic`](@ref), [`AbstractModel`](@ref),
[`unroll_rules`](@ref).
"""
function unroll_rules_cascade(m::AbstractModel, assumed_formula = nothing)
    # TODO @Michele
    # [advance_formula(rule) for rule in unroll_rules(m)]
    error(begin
        if issymbolic(m)
            "Please, provide method unroll_rules_cascade(::$(typeof(m))) ($(typeof(m)) is a symbolic model)."
        else
            "Models of type $(typeof(m)) are not symbolic, and thus have no rules associated."
        end
    end)
end

unroll_rules_cascade(m::FinalModel) = [m]

function unroll_rules_cascade(m::Rule)
    rules = begin
        r = unroll_rules_cascade(consequent(m))
        r isa Vector{<:FinalModel} ?
            [RuleCascade(LogicalTruthCondition[antecedent(m)],fm) for fm in r] :
            [RuleCascade(
                LogicalTruthCondition[antecedent(m),antecedents(rule)...],
                consequent(rule),
            ) for rule in r]
    end

    return [rules...]
end

function unroll_rules_cascade(m::Branch{O}) where {O}
    pos_rules = begin
        r = unroll_rules_cascade(positive_consequent(m))
        r isa Vector{<:FinalModel} ?
            [RuleCascade(LogicalTruthCondition[antecedent(m)],fm) for fm in r] :
            [RuleCascade(
                LogicalTruthCondition[antecedent(m),antecedents(rule)...],
                consequent(rule),
            ) for rule in r]
    end

    neg_rules = begin
        r = unroll_rules_cascade(negative_consequent(m))
        r isa Vector{<:FinalModel} ?
            [RuleCascade(
                LogicalTruthCondition[
                    LogicalTruthCondition(¬(formula(antecedent(m))))
                ],fm) for fm in r] :
            [RuleCascade(
                LogicalTruthCondition[
                    LogicalTruthCondition(¬(formula(antecedent(m)))),
                    antecedents(rule)...
                ],
                consequent(rule),
            ) for rule in r]
    end

    return [
        pos_rules...,
        neg_rules...,
    ]
end

unroll_rules_cascade(m::DecisionList) = [
    [unroll_rules_cascade(rule) for rule in rules(m)]...,
    RuleCascade(
        LogicalTruthCondition[
            LogicalTruthCondition(SyntaxTree(⊤))],
        unroll_rules_cascade(default_consequent(m))...,
    ),
]

unroll_rules_cascade(m::RuleCascade) = [m]

unroll_rules_cascade(m::DecisionTree) = unroll_rules_cascade(root(m))

unroll_rules_cascade(m::MixedSymbolicModel) = unroll_rules_cascade(root(m))

############################################################################################
############################################################################################
############################################################################################

"""
$(doc_symbolic)
List all paths of a decision tree by performing a tree traversal
"""
# """
# List all paths of a decision tree by performing a tree traversal
# TODO @Michele
# """
# function list_paths(tree::DecisionTree{L<:AbstractLogic, O})::AbstractVector{<:AbstractVector{Union{Any,Rule{L,O}}}}
#     return list_immediate_rules(root(tree))
# end
#=
function list_paths(tree::DecisionTree)
    # tree(f) [where f is a Formula object] is used to
    # retrieve the root FNode of the formula(syntax) tree
    pathset = list_paths(root(tree))

    (length(pathset) == 1) && (return [RuleCascade(TOP,pathset[1])])

    return [RuleCascade(path[1:end-1],path[end]) for path in pathset]
end

function list_paths(node::Branch)
    positive_path  = [antecedent(node)]
    negative_path = [NEGATION(tree(formula(antecedent(node))))]
    return [
        list_paths(positive_consequent(node),  positive_path)...,
        list_paths(negative_consequent(node), negative_path)...,
    ]
end

function list_paths(node::AbstractModel)
    return [node]
end

function list_paths(node::Branch, this_path::AbstractVector)
    # NOTE: antecedent(node) or tree(formula(antecedent(node))) to obtain a FNode?
    positive_path  = [this_path..., antecedent(node)]
    negative_path = [this_path..., NEGATION(tree(formula(antecedent(node))))]
    return [
        list_paths(positive_consequent(node),  positive_path)...,
        list_paths(negative_consequent(node), negative_path)...,
    ]
end

function list_paths(node::AbstractModel,this_path::AbstractVector)
    return [[this_path..., node], ]
end
=#

############################################################################################
############################################################################################
############################################################################################
