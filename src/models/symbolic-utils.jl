
############################################################################################
# Symbolic modeling utils
############################################################################################

"""
    immediate_submodels(m::AbstractModel)

Returns a list of immediate child models.
Note: if the model is final, then the list is empty.

See also
[`submodels`](@ref),
[`FinalModel`](@ref),
[`AbstractModel`](@ref).
"""
function immediate_submodels(
    m::AbstractModel{O}
)::Vector{<:{AbstractModel{<:O}}} where {O}
    error("Please, provide method immediate_submodels(::$(typeof(m))).")
end

immediate_submodels(m::FinalModel{O}) where {O} = Vector{<:AbstractModel{<:O}}[]
immediate_submodels(m::Rule) = [consequent(m)]
immediate_submodels(m::Branch) = [posconsequent(m), negconsequent(m)]
immediate_submodels(m::DecisionList) = [rulebase(m)..., consequent(m)]
immediate_submodels(m::RuleCascade) = [consequent(m)]
immediate_submodels(m::DecisionTree) = immediate_submodels(root(m))
immediate_submodels(m::MixedSymbolicModel) = immediate_submodels(root(m))

"""
This function provides access to the list of all child models in the sub-tree.

See also
[`immediate_submodels`](@ref),
[`FinalModel`](@ref),
[`AbstractModel`](@ref).
"""
submodels(m::AbstractModel) = [Iterators.flatten(_submodels.(immediate_submodels(m)))...]
_submodels(m::AbstractModel) = [m, Iterators.flatten(_submodels.(immediate_submodels(m)))...]


############################################################################################
############################################################################################
############################################################################################

# When `assumed_formula` is assumed, and `f` is known to be true, their conjuction holds.
advance_formula(f::AbstractFormula, assumed_formula::Union{Nothing,AbstractFormula}) =
    isnothing(assumed_formula) ? f : ∧(assumed_formula, f)

advance_formula(r::R where {R<:Rule}, assumed_formula::Union{Nothing,AbstractFormula}) =
    R(advance_formula(antecedent(r), assumed_formula), consequent(r), info(r))

############################################################################################
############################################################################################
############################################################################################

"""
    immediate_rules(m::AbstractModel{O} where {O})::Rule{<:O}

Returns the immediate rules equivalent to a model. TODO explain

See also [`unroll_rules`](@ref), [`unroll_rules_cascade`](@ref), [`issymbolic`](@ref),
[`AbstractModel`](@ref).
"""
immediate_rules(m::AbstractModel{O} where {O})::Rule{<:O} =
    error(begin
        if issymbolic(m)
            "Please, provide method immediate_rules(::$(typeof(m))) ($(typeof(m)) is a symbolic model)."
        else
            "Models of type $(typeof(m)) are not symbolic, and thus have no rules associated."
        end
    end)

immediate_rules(m::FinalModel) = [Rule(⊤, m)]

immediate_rules(m::Rule) = [m]

immediate_rules(m::Branch{O,FM}) where {O,FM} = [
    Rule{O,FM}(antecedent(m), posconsequent(m)),
    Rule{O,FM}(SoleLogics.NEGATION(antecedent(m)), negconsequent(m)),
]

function immediate_rules(m::DecisionList{O,FM}) where {O,FM}
    assumed_formula = nothing
    normalized_rules = Vector{eltype(rulebase(m))}[]
    for rule in rulebase(m)
        rule = advance_formula(rule, assumed_formula)
        assumed_formula = advance_formula(SoleLogics.NEGATION(antecedent(rule)), assumed_formula)
    end
    default_antecedent = isnothing(assumed_formula) ? ⊤ : assumed_formula
    push!(normalized_rules, Rule{O,FM}(default_antecedent, defaultconsequent(m)))
    normalized_rules
end

immediate_rules(m::RuleCascade) = [convert(Rule, m)]

immediate_rules(m::DecisionTree) = immediate_rules(root(m))

immediate_rules(m::MixedSymbolicModel) = immediate_rules(root(m))

############################################################################################
############################################################################################
############################################################################################

"""
This function extracts the behavior of a symbolic model and represents it as a
set of mutually exclusive (and jointly exaustive, if the model is closed) rules,
which can be useful
for many purposes.

See also [`immediate_rules`](@ref), [`unroll_rules_cascade`](@ref),
[`issymbolic`](@ref), [`AbstractModel`](@ref).
"""
# TODO remove or merge with unroll_rules_cascade?
# function unroll_rules(m::AbstractModel)
#     # TODO @Michele
#     # [advance_formula(rule) for rule in unroll_rules(m)]
#     error(begin
#         if issymbolic(m)
#             "Please, provide method unroll_rules(::$(typeof(m))) ($(typeof(m)) is a symbolic model)."
#         else
#             "Models of type $(typeof(m)) are not symbolic, and thus have no rules associated."
#         end
#     end)
# end

function unroll_rules(m::AbstractModel)
    ms = unroll_rules_cascade(m)
    return map(m->begin
        if m isa RuleCascade && conditiontype(m) <: Union{TrueCondition,LogicalTruthCondition}
            convert(Rule, m)
        elseif m isa FinalModel
            m
        else
            error("Unknown model type encountered in unroll_rules: $(typeof(m))")
        end
    end, ms)
end

############################################################################################
############################################################################################
############################################################################################

"""
This function extracts the behavior of a symbolic model and represents it as a
set of mutually exclusive (and jointly exaustive, if the model is closed) rules cascade
vectors, which can be useful for many purposes.

See also [`immediate_rules`](@ref), [`issymbolic`](@ref), [`AbstractModel`](@ref),
[`unroll_rules`](@ref).
"""
function unroll_rules_cascade(m::AbstractModel)
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

function unroll_rules_cascade(
    m::Rule{O,<:Union{TrueCondition,LogicalTruthCondition}}
) where {O}
    rules = begin
        r = unroll_rules_cascade(consequent(m))
        if antecedent(m) isa TrueCondition
            r isa Vector{<:FinalModel} ?
                [RuleCascade(fm) for fm in r] :
                [RuleCascade(antecedents(rule), consequent(rule)) for rule in r]
        elseif antecedent(m) isa LogicalTruthCondition
            ant = antecedent(m)

            r isa Vector{<:FinalModel} ?
                [RuleCascade([ant], fm) for fm in r] :
                [RuleCascade([ant,antecedents(rule)...], consequent(rule)) for rule in r]
        end
    end

    return [rules...]
end

function unroll_rules_cascade(
    m::Branch{O,<:Union{TrueCondition,LogicalTruthCondition}}
) where {O}
    pos_rules = begin
        r = unroll_rules_cascade(posconsequent(m))

        if antecedent(m) isa TrueCondition
            r isa Vector{<:FinalModel} ?
                [RuleCascade(fm) for fm in r] :
                [RuleCascade(antecedents(rule), consequent(rule)) for rule in r]
        elseif antecedent(m) isa LogicalTruthCondition
            ant = antecedent(m)

            r isa Vector{<:FinalModel} ?
                [RuleCascade([ant], fm) for fm in r] :
                [RuleCascade([ant,antecedents(rule)...], consequent(rule)) for rule in r]
        end
    end

    neg_rules = begin
        r = unroll_rules_cascade(negconsequent(m))

        if antecedent(m) isa TrueCondition
            r isa Vector{<:FinalModel} ?
                [RuleCascade(fm) for fm in r] :
                [RuleCascade(antecedents(rule), consequent(rule)) for rule in r]
        elseif antecedent(m) isa LogicalTruthCondition
            ant = LogicalTruthCondition(¬(formula(antecedent(m))))

            r isa Vector{<:FinalModel} ?
                [RuleCascade([ant], fm) for fm in r] :
                [RuleCascade([ant,antecedents(rule)...], consequent(rule)) for rule in r]
        end
    end

    return [
        pos_rules...,
        neg_rules...,
    ]
end

function unroll_rules_cascade(
    m::DecisionList{O,<:Union{TrueCondition,LogicalTruthCondition}}
) where {O}
    [
        reduce(vcat,[unroll_rules_cascade(rule) for rule in rulebase(m)])...,
        RuleCascade(unroll_rules_cascade(defaultconsequent(m))...),
    ]
end

unroll_rules_cascade(m::RuleCascade) = [m]

unroll_rules_cascade(m::DecisionTree) = unroll_rules_cascade(root(m))

unroll_rules_cascade(m::MixedSymbolicModel) = unroll_rules_cascade(root(m))

############################################################################################
############################################################################################
############################################################################################

"""
List all paths of a decision tree by performing a tree traversal
"""
# """
# List all paths of a decision tree by performing a tree traversal
# TODO @Michele
# """
# function list_paths(tree::DecisionTree{L<:AbstractLogic,O})::AbstractVector{<:AbstractVector{Union{Any,Rule{L,O}}}}
#     return immediate_rules(root(tree))
# end
#=
function list_paths(tree::DecisionTree)
    # tree(f) [where f is a AbstractFormula object] is used to
    # retrieve the root FNode of the formula(syntax) tree
    pathset = list_paths(root(tree))

    (length(pathset) == 1) && (return [RuleCascade(⊤,pathset[1])])

    return [RuleCascade(path[1:end-1],path[end]) for path in pathset]
end

function list_paths(node::Branch)
    positive_path  = [antecedent(node)]
    negative_path = [NEGATION(tree(formula(antecedent(node))))]
    return [
        list_paths(posconsequent(node),  positive_path)...,
        list_paths(negconsequent(node), negative_path)...,
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
        list_paths(posconsequent(node),  positive_path)...,
        list_paths(negconsequent(node), negative_path)...,
    ]
end

function list_paths(node::AbstractModel,this_path::AbstractVector)
    return [[this_path..., node], ]
end
=#

############################################################################################
############################################################################################
############################################################################################
