
using SoleLogics: AbstractLogic, Formula

"""
A `FinalOutcome` is something that a model outputs.
"""
const FinalOutcome = Any

"""
A Machine Learning `Model` is a mathematical model that outputs a `FinalOutcome` given an
instance object (i.e., a piece of data).
"""
abstract type Model{F <: FinalOutcome} end

doc_symbolic =
"""
A `Model` is said to be `symbolic` when it is based on certain a logical language (or "logic",
see `SoleLogics` package).
Symbolic models provide a form of transparent and interpretable modeling.
"""

"""
$(doc_symbolic)
The `is_symbolic` trait, defaulted to `false` can be used to specify that a model is symbolic.
"""
is_symbolic(::Model) = false

"""
$(doc_symbolic)
Every symbolic model must provide access to its corresponding `Logic` type via the `logic` trait.
"""
logic(m::Model) = error("Method logic($(typeof(m))) is undefined; is this Model symbolic at all?")

"""
Instead, a `Model` is said to be functional when it encodes an algebraic mathematical function.
"""

doc_info = """
In Sole, each `Model` encompasses an `info::NamedTuple` field for storing additional information,
that does not affect on the model's behavior. This structure can hold, for example, information
about the `Model`'s statistical performance during the learning phase.
"""

"""
$(doc_info)
The `has_info` trait, defaulted to `true`, can be used to specify models that do not implement an
`info` field.
"""
has_info(m::Model) = true

"""
$(doc_info)
The `info` getter function accesses this structure.
"""
info(m::T) where {T<:Model} = has_info(T) ? m.info : error("Model $(typeof(m)) doesn't have `info` field.")

"""
The simplest type of `Model` is the `ConstantModel`, that always outputs the same value.
"""
struct ConstantModel{F<:FinalOutcome} <: Model{F}
    final_outcome::F
    info::NamedTuple
end

############################################################################################
############################################################################################
############################################################################################

"""
A `Model` can wrap another `Model`, and encompass it as an output value. In such case, 
the output model is to be applied on the instance object, in order to (eventually) yield a 
final outcome. We distinguish between this intermediate output (`Outcome`) and the final
outcome (`Outcome`) that is output at the end of the cascade of applications.

    const Outcome{F <: FinalOutcome, M <: Model{F}} = Union{F, M}

For example, `Outcome{F}` supertypes any `value` such that `value::F`, or any model that outputs
a `value` such that `value::F`.
"""
const Outcome{F <: FinalOutcome, M <: Model{F}} = Union{F, M}

"""
A `Model` can also be a composition of many models:

    abstract type CompositeModel{F <: FinalOutcome, M <: Model{F}} <: Model{F} end

In this case, we can constrain the types of the underlying sub-`Model`'s.
For example, `CompositeModel{String, Branch{String}}` indicates any `Model`
that is the composition of `Branch`'s which output `String` values;
this structure is, essentially, a Decision Tree that outputs `String`s.
"""
abstract type CompositeModel{F <: FinalOutcome, M <: Model{F}} <: Model{F} end

"""
A `Model`
"""
const CompositeOutcome{F <: FinalOutcome, M <: CompositeModel{F}} = Union{F, M}

############################################################################################
############################################################################################
############################################################################################

# TODO improve and lighten this doc
doc_base = """
Symbolic modeling builds onto two basic building blocks, which are regarded as `Model`'s themselves:
- `Rule`: IF (antecedent) THEN (consequent) END
- `Branch`: IF (antecedent) THEN (consequent_1) ELSE (consequent_2) END
The `antecedent` is a formula of a certain logic, that can typically evaluate to true or false;
the `consequent`'s, which are the feasible `Outcome`'s of the block and, thus, can either be
the `FinalOutcome` of the block, or another block (or, more generally, another `Model`) that
is has to be applied in order to obtain a `FinalOutcome`.
"""


"""
$(doc_base)
A `rule` is one of the fundamental building blocks of symbolic modeling, and has the form:

    IF (antecedent) THEN (consequent) END
where the antecedent is a logical formula and the consequent is the outcome of the block.

In Sole, a `Rule{F<:FinalOutcome, L<:AbstractLogic}` wraps an `antecedent::Formula{L}`, that is, a formula of a given logic L,
and a `consequent::O` holding the outcome.
It also includes an `info::NamedTuple` for storing additional information.
"""
struct Rule{F<:FinalOutcome, L<:AbstractLogic, M<:Model{F}} <: CompositeModel{F, M} # where {Rule{F, L, M} <: M}
    antecedent::Formula{L}
    consequent::Outcome{F, M}
    info::NamedTuple

    # TODO write constructors!
end

antecedent(rule::Rule) = rule.antecedent
consequent(rule::Rule) = rule.consequent

"""
$(doc_base)
A `branch` is one of the fundamental building blocks of symbolic modeling, and has the form:

    IF (antecedent) THEN (consequent_1) ELSE (consequent_2) END
where the antecedent is a logical formula and the consequents are the feasible outcomes of the block.

In Sole, a `Branch{L<:AbstractLogic, O<:Outcome}` wraps an `antecedent::Formula{L}`, that is, a formula of a given logic L,
and a `consequents::NTuple{2, O}` structure holding the two outcomes.
It also includes an `info::NamedTuple` for storing additional information.
"""
struct Branch{F<:FinalOutcome, L<:AbstractLogic, M<:Model{F}} <: CompositeModel{F, M} # where {Branch{F, L, M} <: M}
    antecedent::Formula{L}
    consequents::NTuple{2, Outcome{F, M}}
    info::NamedTuple
end

antecedent(rule::Branch) = rule.antecedent
consequents(rule::Branch) = rule.consequents

"""
A `decision list` (or `decision table`, or `rule-based model`) is a symbolic model that has the form:
    IF (antecedent_1)     THEN (consequent_1)
    ELSEIF (antecedent_2) THEN (consequent_2)
    ...
    ELSEIF (antecedent_n) THEN (consequent_n)
    ELSE (consequent_default) END
where the antecedents are logical formulas and the consequents are the feasible outcomes of the block.

In Sole, a `DecisionList{L<:AbstractLogic, O<:Outcome}` encodes this structure as a vector of rules 
`rules::Vector{<:Rule{L,O}}`, plus a default consequent value `default::O`.
It also includes an `info::NamedTuple` for storing additional information.
"""
struct DecisionList{F<:FinalOutcome, L<:AbstractLogic} <: SymbolicModel{F}
    rules::Vector{<:Rule{L,Outcome{F}}}
    default::Outcome{F}
    info::NamedTuple
end
rules(model::DecisionList) = model.rules
default(model::DecisionList) = model.default


const DecisionTreeNode = Union{F, Branch{L,F}}

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

In Sole, a `DecisionTree{L<:AbstractLogic, O<:Outcome}` encodes this structure by simply wrapping
a root block `root::Union{O, Branch{L,O}}` which (note!) it can be an if-then-else block, but also
more simply a consequent.
It also includes an `info::NamedTuple` for storing additional information.
"""
struct DecisionTree{F<:FinalOutcome, L<:AbstractLogic} <: SymbolicModel{F}
    root::DecisionTreeNode
    info::NamedTuple
end
root(model::DecisionTree) = model.root

TODO fix from here onwards:
############################################################################################
# List rules
############################################################################################

"""
List all rules of a decision tree by performing a tree traversal
"""
function list_rules(tree::DecisionTree{L<:AbstractLogic, O<:Outcome})::AbstractVector{Rule{L,O}}
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

function list_rules(node::Branch{L}, this_formula::Formula{L}) where {L<:AbstractLogic}
    # left  child formula = father formula ∧   current_antecedent
    # right child formula = father formula ∧ ¬ current_antecedent
    left_formula  = SoleLogics.CONJUCTION(this_formula, antecedent(node)) # TODO rename into condition?
    right_formula = SoleLogics.CONJUCTION(this_formula, SoleLogics.NEG(antecedent(node)))
    return [
        list_rules(leftchild(node),  left_formula)...,
        list_rules(rightchild(node), right_formula)...,
    ]
end

function list_rules(node::F,this_formula::Formula{L}) where {F<:FinalOutcome,L<:AbstractLogic}
    return [Rule{L,F}(this_formula, prediction(node))]
end

############################################################################################

"""
List all paths of a decision tree by performing a tree traversal
TODO @Michele
"""
function list_paths(tree::DecisionTree{L<:AbstractLogic, O<:Outcome})::AbstractVector{<:AbstractVector{Union{FinalOutcome,Rule{L,O}}}}
    return list_rules(root(tree))
end

# const RuleNest = Rule{L, Outcome{F,Rule{L, Outcome{F,Rule{L, Outcome{F}}}}}}
const RuleNest{L<:AbstractLogic,F<:Outcome{F}} = Union{F,Rule{L, Outcome{F,RuleNest{L,O}}}}
# TODO @Michele: list_rulenests/list_nests::Rule/RuleNest

# Evaluation for single decision
# TODO
function evaluate_decision(dec::Decision, X::MultiFrameModalDataset) end

############################################################################################
############################################################################################
############################################################################################

# Extract decisions from rule
function extract_decisions(formula::Formula{L}) where {L<:AbstractLogic}
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

evaluate_antecedent(antecedent::Formula{L}, X::MultiFrameModalDataset) where {L<:AbstractLogic} =
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
) where {L<:AbstractLogic} = evaluate_rule(extract_decisions(ant),cons,X,Y)

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


# Classification and regression labels
const CLabel  = Union{String,Integer}
const RLabel  = AbstractFloat
const Label   = Union{CLabel,RLabel}
# Raw labels
const _CLabel = Integer # (classification labels are internally represented as integers)
const _Label  = Union{_CLabel,RLabel}


const AssociationRule{L<:AbstractLogic} = Rule{L, Formula{L}} #NOTE: maybe where {L<:AbstractLogic}

# NOTE: this has to be switched in ml.jl
const ClassificationRule = Rule{L,CLabel} where {L<:AbstractLogic}
const RegressionRule = Rule{L,RLabel} where {L<:AbstractLogic}

# const CLabel = Union{String, Integer}
# const RLabel = AbstractFloat
# const Label  = Union{CLabel, RLabel}


const ClassificationDL = DecisionList{L,CLabel} where {L<:AbstractLogic}
const RegressionDL = DecisionList{L,RLabel} where {L<:AbstractLogic}



# Translate a list of labels into categorical form
Base.@propagate_inbounds @inline function get_categorical_form(Y :: AbstractVector{T}) where {T}
    class_names = unique(Y)

    dict = Dict{T, Int64}()
    @simd for i in 1:length(class_names)
        @inbounds dict[class_names[i]] = i
    end

    _Y = Array{Int64}(undef, length(Y))
    @simd for i in 1:length(Y)
        @inbounds _Y[i] = dict[Y[i]]
    end

    return class_names, _Y
end
