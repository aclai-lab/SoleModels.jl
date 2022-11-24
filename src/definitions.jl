"""
A `FinalOutcome` is whatever a model can output
"""
const FinalOutcome = Any

"""
A Machine Learning `Model` is a mathematical model that predicts a `FinalOutcome` given an
instance object (i.e., a piece of data).
"""
abstract type Model{F <: FinalOutcome} end

"""
A `SymbolicModel` is a `Model` that is based on certain a logical language (or "logic"),
and can be easily interpreted by humans.
"""
abstract type SymbolicModel{L, F} <: Model{F} end

"""
A `FunctionalModel` is a `Model` that encodes an algebrain mathematical function.
"""
abstract type FunctionalModel{F}  <: Model{F} end

############################################################################################
############################################################################################
############################################################################################

"""
In Sole, `Model`'s may encompass an `info::NamedTuple` field for storing additional information,
that do not affect on the model's behavior.
"""
has_info(m::Model) = false
# info(m::Model) = has_info(m) ? m.info : error("Model $(typeof(m)) doesn't have `info` field")
info(m::T) where {T<:Model} = info(Val(has_info(T)))
info(::Val{true}) = m.info
info(::Val{false}) = error("Model $(typeof(m)) doesn't have `info` field")

"""
Symbolic modeling builds on two basic building blocks:
- Rule: IF (antecedent) THEN (consequent) END
- Branch: IF (antecedent) THEN (consequent_1) ELSE (consequent_2) END
The `antecedent` is a formula of a certain logic, that can evaluate to true or false;
the `consequent`s, which is the outcome of the block, can be a `FinalOutcome` of a given model,
or another model that is has to be applied in order to obtain a `FinalOutcome`.
"""
const Outcome{F <: FinalOutcome} = Union{F, Model{F}}

"""
A `rule` is a fundamental building block of symbolic modeling, and has the form:
    IF (antecedent) THEN (consequent) END
where the antecedent is a logical formula and the consequent is the outcome of the block.

In Sole, a `Rule{L<:Logic, O<:Outcome}` wraps an `antecedent::Formula{L}`, that is, a formula of a given logic L,
and a `consequent::O` holding the outcome.
It also includes an `info::NamedTuple` for storing additional information.
"""
struct Rule{L<:Logic, O<:Outcome} <: SymbolicModel{F<:FinalOutcome}
    antecedent::Formula{L}
    consequent::O
    info::NamedTuple

    function Rule{L,O}(
        antecedent::Formula{L},
        consequent::O,
        performance::NamedTuple
    ) where {L<:Logic, O<:Outcome}
        new{L, O}(antecedent, consequent, performance)
    end

    function Rule(
        antecedent::Formula{L},
        consequent::O,
        performance::NamedTuple
    ) where {L<:Logic, O<:Outcome}
        Rule{L, O}(antecedent, consequent, performance)
    end
end

antecedent(rule::Rule) = rule.antecedent
consequent(rule::Rule) = rule.consequent
has_info(rule::Rule) = true

"""
A `branch` is a fundamental building block of symbolic modeling, and has the form:
    IF (antecedent) THEN (consequent_1) ELSE (consequent_2) END
where the antecedent is a logical formula and the consequents are the feasible outcomes of the block.

In Sole, a `Branch{L<:Logic, O<:Outcome}` wraps an `antecedent::Formula{L}`, that is, a formula of a given logic L,
and a `consequents::NTuple{2, O}` structure holding the two outcomes.
It also includes an `info::NamedTuple` for storing additional information.
"""
struct Branch{L<:Logic, O<:Outcome} <: SymbolicModel{F<:FinalOutcome}
    antecedent::Formula{L}
    consequents::NTuple{2, O}
    info::NamedTuple
end

antecedent(rule::Branch) = rule.antecedent
consequents(rule::Branch) = rule.consequents
has_info(rule::Branch) = true

"""
A `decision list` (or `decision table`, or `rule-based model`) is a symbolic model that has the form:
    IF (antecedent_1)     THEN (consequent_1)
    ELSEIF (antecedent_2) THEN (consequent_2)
    ...
    ELSEIF (antecedent_n) THEN (consequent_n)
    ELSE (consequent_default) END
where the antecedents are logical formulas and the consequents are the feasible outcomes of the block.

In Sole, a `DecisionList{L<:Logic, O<:Outcome}` encodes this structure as a vector of rules 
`rules::Vector{<:Rule{L,O}}`, plus a default consequent value `default::O`.
It also includes an `info::NamedTuple` for storing additional information.
"""
struct DecisionList{L<:Logic, O<:Outcome} <: SymbolicModel{F<:FinalOutcome}
    rules::Vector{<:Rule{L,O}}
    default::O
    info::NamedTuple
end
rules(model::DecisionList) = model.rules
default(model::DecisionList) = model.default
has_info(model::DecisionList) = true

"""
A `decision tree` is a symbolic model that consists of a nested structure of if-then-else blocks:
    IF (antecedent_1) THEN
        IF (antecedent_2) THEN
            (consequent_1)
        ELSE
            (consequent_2)
        END
    ELSE
        IF (antecedent_3) THEN
            (consequent_3)
        ELSE
            (consequent_4)
        END
    END
where the antecedents are logical formulas and the consequents are the feasible outcomes of the block.

In Sole, a `DecisionTree{L<:Logic, O<:Outcome}` encodes this structure by simply wrapping
a root block `root::Union{O, Branch{L,O}}` which (note!) it can be an if-then-else block, but also
more simply a consequent.
It also includes an `info::NamedTuple` for storing additional information.
"""
struct DecisionTree{L<:Logic, O<:Outcome} <: SymbolicModel{F<:FinalOutcome}
    root::Union{O, Branch{L,O}}
    info::NamedTuple
end
root(model::DecisionTree) = model.root
has_info(model::DecisionTree) = true

TODO fix from here onwards:
############################################################################################
# List rules
############################################################################################

"""
List all rules of a decision tree by performing a tree traversal
"""
function list_rules(tree::DecisionTree)
    # tree(f) [where f is a Formula object] is used to
    # retrieve the root FNode of the formula(syntax) tree
    return list_rules(root(tree))
end

function list_rules(node::Branch)
    left_formula  = condition(node)
    right_formula = NEG(condition(node))
    return [
        list_rules(leftchild(node),  left_formula)...,
        list_rules(rightchild(node), right_formula)...,
    ]
end

function list_rules(node::F) where {F<:FinalOutcome}
    return [Rule{L,F}(SoleLogics.TOP, prediction(node))]
end

function list_rules(node::Branch, this_formula::Formula)
    # left  child formula = father formula ∧   current_condition
    # right child formula = father formula ∧ ¬ current_condition
    left_formula  = SoleLogics.CONJUCTION(this_formula, condition(node))
    right_formula = SoleLogics.CONJUCTION(this_formula, NEG(condition(node)))
    return [
        list_rules(leftchild(node),  left_formula)...,
        list_rules(rightchild(node), right_formula)...,
    ]
end

function list_rules(node::F,this_formula::Formula{L}) where {F<:FinalOutcome,L<:AbstractLogic}
    return [Rule{L,F}(this_formula, prediction(node))]
end

# # OLD
# function list_rules(node::Branch, this_formula::FNode{L}) where {L<:AbstractLogic}
#     # left  child formula = father formula ∧   current_condition
#     # right child formula = father formula ∧ ¬ current_condition
#     conj = FNode{L}(CONJUNCTION)
#     left_formula  = link_nodes(conj, this_formula, tree(formula(node)))
#     right_formula = link_nodes(conj, this_formula, tree(NEG(formula(node))))
#     return [
#         list_rules(leftchild(node),  left_formula)...,
#         list_rules(rightchild(node), right_formula)...,
#     ]
# end

# function list_rules(
#     node::F,
#     this_formula::FNode{L}
#     ) where {F<:FinalOutcome,L<:AbstractLogic}
#     return [Rule{L,F}(this_formula, prediction(node))]
# end
# Evaluation for single decision
# TODO
function evaluate_decision(dec::Decision, X::MultiFrameModalDataset) end

############################################################################################
############################################################################################
############################################################################################

# Extract decisions from rule
function extract_decisions(formula::Formula{L}) where {L<:Logic}
    # TODO remove in favor of operators_set = operators(L)
    operators_set = operators(logic(formula))
    function _extract_decisions(node::FNode, decs::AbstractVector{<:Decision})
        # Leaf or internal node
        if !isdefined(node, :leftchild) && !isdefined(node, :rightchild)
            if token(node) in operators_set
                return decs
            else
                return push!(decs, token(node))
            end
        else
            isdefined(node, :leftchild)  && _extract_decisions(leftchild(node),  decs)
            isdefined(node, :rightchild) && _extract_decisions(rightchild(node), decs)

            if !(token(node) in operators_set)
                return push!(decs, token(node))
            end
            decs
        end
    end
    _extract_decisions(tree(formula), [])
end

############################################################################################
# Formula Update
############################################################################################

function formula_update(formula::Formula{L},nodes_deleted::AbstractVector)
    root = tree(formula)

    function _transplant(u::FNode,v::FNode)
        #u è radice
        u == root ? root = v : nothing

        #u è figlio sx
        u == leftchild(parent(u)) ? leftchild!(parent(u),v) : nothing

        #u è figlio dx
        u == rightchild(parent(u)) ? rightchild!(parent(u),v) : nothing

        #v definito
        isdefined(v,:token) ? parent!(v,parent(u)) : nothing

        return nothing
    end

    function _formula_update(node::FNode,node_deleted::FNode)

        #è il nodo da eliminare
        if node == node_deleted
            if leftchild(parent(node)) == node
                return _transplant(parent(node),rightchild(parent(node)))
            else
                return _transplant(parent(node),leftchild(parent(node)))
            end
        end

        #non è il nodo da eliminare

        #se non sono in una foglia, passo ai rami
        isdefined(node, :leftchild)  && _formula_update(leftchild(node), node_deleted)
        isdefined(node, :rightchild) && _formula_update(rightchild(node), node_deleted)

        return nothing
    end

    for node in nodes_deleted
        _formula_update(root,node)
    end

    return Formula{L}(root)
end

############################################################################################
# Rule evaluation
############################################################################################

# Evaluation for an antecedent

evaluate_antecedent(antecedent::Formula{L}, X::MultiFrameModalDataset) where {L<:Logic} =
    evaluate_antecedent(extract_decisions(antecedent), X)

function evaluate_antecedent(decs::AbstractVector{<:Decision}, X::MultiFrameModalDataset)
    D = hcat([evaluate_decision(d, X) for d in decs]...)
    # If all values in a row is true, then true (and logical)
    return map(all, eachrow(D))
end

# Evaluation for a rule

# From rule to antecedent and consequent
evaluate_rule(rule::Rule, X::MultiFrameModalDataset, Y::AbstractVector{<:Consequent}) =
    evaluate_rule(antecedent(rule), consequent(rule), X, Y)

# From antecedent to decision
evaluate_rule(
    ant::Formula{L},
    cons::Consequent,
    X::MultiFrameModalDataset,
    Y::AbstractVector{<:Consequent}
) where {L<:Logic} = evaluate_rule(extract_decisions(ant),cons,X,Y)

# Use decision and consequent
function evaluate_rule(
    decs::AbstractVector{<:Decision},
    cons::Consequent,
    X::MultiFrameModalDataset,
    Y::AbstractVector{<:Consequent}
)
    # Antecedent satisfaction. For each instances in X:
    #  - `false` when not satisfiable,
    #  - `true` when satisfiable.
    ant_sat = evaluate_antecedent(decs,X)

    # Indices of satisfiable instances
    idxs_sat = findall(ant_sat .== true)

    # Consequent satisfaction. For each instances in X:
    #  - `false` when not satisfiable,
    #  - `true` when satisfiable,
    #  - `nothing` when antecedent does not hold.
    cons_sat = begin
        cons_sat = Vector{Union{Bool, Nothing}}(fill(nothing, length(Y)))
        idxs_true = begin
            idx_cons = findall(cons .== Y)
            intersect(idxs_sat,idx_cons)
        end
        idxs_false = begin
            idx_cons = findall(cons .!= Y)
            intersect(idxs_sat,idx_cons)
        end
        cons_sat[idxs_true]  .= true
        cons_sat[idxs_false] .= false
    end

    y_pred = begin
        y_pred = Vector{Union{Consequent, Nothing}}(fill(nothing, length(Y)))
        y_pred[idxs_sat] .= C
        y_pred
    end

    return (;
        ant_sat   = ant_sat,
        idxs_sat  = idxs_sat,
        cons_sat  = cons_sat,
        y_pred    = y_pred,
    )
end


    # """
    #     rule_length(node::FNode, operators::Operators) -> Int

    #     Computer the number of pairs in a rule (length of the rule)

    # # Arguments
    # - `node::FNode`: node on which you refer
    # - `operators::Operators`: set of operators of the considered logic

    # # Returns
    # - `Int`: number of pairs
    # """
    # function rule_length(node::FNode, operators::Operators)
    #     left_size = 0
    #     right_size = 0

    #     if !isdefined(node, :leftchild) && !isdefined(node, :rightchild)
    #         # Leaf
    #         if token(node) in operators
    #             return 0
    #         else
    #             return 1
    #         end
    #     end

    #     isdefined(node, :leftchild) && (left_size = rule_length(leftchild(node), operators))
    #     isdefined(node, :rightchild) && (right_size = rule_length(rightchild(node), operators))

    #     if token(node) in operators
    #         return left_size + right_size
    #     else
    #         return 1 + left_size + right_size
    #     end
    # end

    rule_metrics(rule::Rule{L,C}, X::MultiFrameModalDataset, Y::AbstractVector{<:Consequent}) =
        rule_metrics(extract_decisions(antecedent(rule)),cons,X,Y)

    """
        rule_metrics(args...) -> AbstractVector

        Compute frequency, error and length of the rule

    # Arguments
    - `decs::AbstractVector{<:Decision}`: vector of decisions
    - `cons::Consequent`: rule's consequent
    - `X::MultiFrameModalDataset`: dataset
    - `Y::AbstractVector{<:Consequent}`: target values of X

    # Returns
    - `AbstractVector`: metrics values vector of the rule
    """
    function rule_metrics(
        decs::AbstractVector{<:Decision},
        cons::Consequent,
        X::MultiFrameModalDataset,
        Y::AbstractVector{<:Consequent}
    )
        eval_result = evaluate_rule(decs, cons, X, Y)
        n_instances = size(X, 1)
        n_satisfy = sum(eval_result[:ant_sat])

        # Support of the rule
        rule_support =  n_satisfy / n_instances

        # Error of the rule
        rule_error = begin
            if typeof(cons) <: CLabel
                # Number of incorrectly classified instances divided by number of instances
                # satisfying the rule condition.
                misclassified_instances = length(findall(eval_result[:y_pred] .== Y))
                misclassified_instances / n_satisfy
            elseif typeof(cons) <: RLabel
                # Mean Squared Error (mse)
                idxs_sat = eval_result[:idxs_sat]
                mse(eval_result[:y_pred][idxs_sat], Y[idxs_sat])
            end
        end

        return (;
            support   = rule_support,
            error     = rule_error,
            length    = rule_length(decs,
        )
    end

############################################################################################
############################################################################################
############################################################################################

#TODO: Define Open versions
# DecisionList doesn't have default value
# DecisionTree can also have Rule{L,F}

"""ML.JL
const AssociationRule{L<:Logic} = Rule{L, Formula{L}} #NOTE: maybe where {L<:Logic}

# NOTE: this has to be switched in ml.jl
const ClassificationRule = Rule{L,CLabel} where {L<:Logic}
const RegressionRule = Rule{L,RLabel} where {L<:Logic}

# const CLabel = Union{String, Integer}
# const RLabel = AbstractFloat
# const Label  = Union{CLabel, RLabel}


const ClassificationDL = DecisionList{L,CLabel} where {L<:Logic}
const RegressionDL = DecisionList{L,RLabel} where {L<:Logic}
"""
