using SoleModels
using SoleModels: FinalModel
using SoleLogics: npropositions

"""
Function for evaluating the antecedent of a rule
"""

function evaluate_antecedent(rule::Rule, X::AbstractInterpretationSet)
    # TODO
    x = check(antecedent(rule), X) #rand([true,false],nsamples(X))
    #@show
    return x
end

"""
Function for evaluating a rule
"""
function evaluate_rule(
    rule::Rule,
    X::AbstractInterpretationSet,
    Y::AbstractVector{<:Label}
)
    # Antecedent satisfaction. For each instances in X:
    #  - `false` when not satisfiable,
    #  - `true` when satisfiable.
    ant_sat = evaluate_antecedent(rule,X)

    # Indices of satisfiable instances
    idxs_sat = findall(ant_sat .== true)

    # Consequent satisfaction. For each instances in X:
    #  - `false` when not satisfiable,
    #  - `true` when satisfiable,
    #  - `nothing` when antecedent does not hold.
    #=
    cons_sat = begin
        cons_sat = Vector{Union{Bool,Nothing}}(fill(nothing, length(Y)))
        idxs_true = begin
            idx_cons = findall(outcome(consequent(rule)) .== Y)
            intersect(idxs_sat,idx_cons)
        end
        idxs_false = begin
            idx_cons = findall(outcome(consequent(rule)) .!= Y)
            intersect(idxs_sat,idx_cons)
        end
        cons_sat[idxs_true]  .= true
        cons_sat[idxs_false] .= false
        cons_sat
    end
    =#

    y_pred = begin
        y_pred = Vector{Union{Label,Nothing}}(fill(nothing, length(Y)))
        y_pred[idxs_sat] .= outcome(consequent(rule))
        y_pred
    end

    return (;
        ant_sat   = ant_sat,
        idxs_sat  = idxs_sat,
        #cons_sat  = cons_sat,
        y_pred    = y_pred,
    )
end

"""
Length of the rule
"""
rule_length(rule::Rule{O,<:TrueCondition}) where {O} = 1
function rule_length(rule::Rule{O,C}) where {O,C<:LogicalTruthCondition}
    npropositions(formula(antecedent(rule)))
end

"""
Metrics of the rule
"""

function rule_metrics(
    rule::Rule,
    X::AbstractInterpretationSet,
    Y::AbstractVector{<:Label}
)
    eval_result = evaluate_rule(rule, X, Y)
    n_instances = nsamples(X)
    n_satisfy = sum(eval_result[:ant_sat])

    # Support of the rule
    rule_support =  n_satisfy / n_instances

    # Error of the rule
    rule_error = begin
        if outcometype(consequent(rule)) <: CLabel
            # Number of incorrectly classified instances divided by number of instances
            # satisfying the rule condition.
            misclassified_instances = length(findall(eval_result[:y_pred] .== Y))
            misclassified_instances / n_satisfy
        elseif outcometype(consequent(rule)) <: RLabel
            # Mean Squared Error (mse)
            idxs_sat = eval_result[:idxs_sat]
            mse(eval_result[:y_pred][idxs_sat], Y[idxs_sat])
        end
    end

    return (;
        support   = rule_support,
        error     = rule_error,
        length    = rule_length(rule),
    )
end

############################################################################################

############################################################################################
# Rule evaluation
############################################################################################

# # Evaluation for an antecedent

# evaluate_antecedent(antecedent::AbstractFormula, X::MultiFrameModalDataset) =
#     evaluate_antecedent(extract_decisions(antecedent), X)

# function evaluate_antecedent(decs::AbstractVector{<:Decision}, X::MultiFrameModalDataset)
#     D = hcat([evaluate_decision(d, X) for d in decs]...)
#     # If all values in a row is true, then true (and logical)
#     return map(all, eachrow(D))
# end

# # Evaluation for a rule

# # From rule to antecedent and consequent
# evaluate_rule(rule::Rule, X::MultiFrameModalDataset, Y::AbstractVector{<:Consequent}) =
#     evaluate_rule(antecedent(rule), consequent(rule), X, Y)

# # From antecedent to decision
# evaluate_rule(
#     ant::AbstractFormula,
#     cons::Consequent,
#     X::MultiFrameModalDataset,
#     Y::AbstractVector{<:Consequent}
# ) = evaluate_rule(extract_decisions(ant),cons,X,Y)

# # Use decision and consequent
# function evaluate_rule(
#     decs::AbstractVector{<:Decision},
#     cons::Consequent,
#     X::MultiFrameModalDataset,
#     Y::AbstractVector{<:Consequent}
# )
#     # Antecedent satisfaction. For each instances in X:
#     #  - `false` when not satisfiable,
#     #  - `true` when satisfiable.
#     ant_sat = evaluate_antecedent(decs,X)

#     # Indices of satisfiable instances
#     idxs_sat = findall(ant_sat .== true)

#     # Consequent satisfaction. For each instances in X:
#     #  - `false` when not satisfiable,
#     #  - `true` when satisfiable,
#     #  - `nothing` when antecedent does not hold.
#     cons_sat = begin
#         cons_sat = Vector{Union{Bool,Nothing}}(fill(nothing, length(Y)))
#         idxs_true = begin
#             idx_cons = findall(cons .== Y)
#             intersect(idxs_sat,idx_cons)
#         end
#         idxs_false = begin
#             idx_cons = findall(cons .!= Y)
#             intersect(idxs_sat,idx_cons)
#         end
#         cons_sat[idxs_true]  .= true
#         cons_sat[idxs_false] .= false
#     end

#     y_pred = begin
#         y_pred = Vector{Union{Consequent,Nothing}}(fill(nothing, length(Y)))
#         y_pred[idxs_sat] .= C
#         y_pred
#     end

#     return (;
#         ant_sat   = ant_sat,
#         idxs_sat  = idxs_sat,
#         cons_sat  = cons_sat,
#         y_pred    = y_pred,
#     )
# end


#     # """
#     #     rule_length(node::FNode, operators::Operators) -> Int

#     #     Compute the number of pairs in a rule (length of the rule)

#     # # Arguments
#     # - `node::FNode`: node on which you refer
#     # - `operators::Operators`: set of operators of the considered logic

#     # # Returns
#     # - `Int`: number of pairs
#     # """
#     # function rule_length(node::FNode, operators::Operators)
#     #     left_size = 0
#     #     right_size = 0

#     #     if !isdefined(node, :leftchild) && !isdefined(node, :rightchild)
#     #         # Leaf
#     #         if token(node) in operators
#     #             return 0
#     #         else
#     #             return 1
#     #         end
#     #     end

#     #     isdefined(node, :leftchild) && (left_size = rule_length(leftchild(node), operators))
#     #     isdefined(node, :rightchild) && (right_size = rule_length(rightchild(node), operators))

#     #     if token(node) in operators
#     #         return left_size + right_size
#     #     else
#     #         return 1 + left_size + right_size
#     #     end
#     # end

#     rule_metrics(rule::Rule{L,C}, X::MultiFrameModalDataset, Y::AbstractVector{<:Consequent}) =
#         rule_metrics(extract_decisions(antecedent(rule)),cons,X,Y)

#     """
#         rule_metrics(args...) -> AbstractVector

#         Compute frequency, error and length of the rule

#     # Arguments
#     - `decs::AbstractVector{<:Decision}`: vector of decisions
#     - `cons::Consequent`: rule's consequent
#     - `X::MultiFrameModalDataset`: dataset
#     - `Y::AbstractVector{<:Consequent}`: target values of X

#     # Returns
#     - `AbstractVector`: metrics values vector of the rule
#     """
#     function rule_metrics(
#         decs::AbstractVector{<:Decision},
#         cons::Consequent,
#         X::MultiFrameModalDataset,
#         Y::AbstractVector{<:Consequent}
#     )
#         eval_result = evaluate_rule(decs, cons, X, Y)
#         n_instances = size(X, 1)
#         n_satisfy = sum(eval_result[:ant_sat])

#         # Support of the rule
#         rule_support =  n_satisfy / n_instances

#         # Error of the rule
#         rule_error = begin
#             if typeof(cons) <: CLabel
#                 # Number of incorrectly classified instances divided by number of instances
#                 # satisfying the rule condition.
#                 misclassified_instances = length(findall(eval_result[:y_pred] .== Y))
#                 misclassified_instances / n_satisfy
#             elseif typeof(cons) <: RLabel
#                 # Mean Squared Error (mse)
#                 idxs_sat = eval_result[:idxs_sat]
#                 mse(eval_result[:y_pred][idxs_sat], Y[idxs_sat])
#             end
#         end

#         return (;
#             support   = rule_support,
#             error     = rule_error,
#             length    = rule_length(decs,
#         )
#     end

# ############################################################################################
# ############################################################################################
# ############################################################################################
