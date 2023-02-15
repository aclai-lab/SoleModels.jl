export antecedent, consequent, positive_consequent, negative_consequent, default_consequent, rules, root

import Base: isopen, length, getindex

import SoleLogics: check, syntaxstring
using SoleLogics: Formula, TOP, AbstractTruthOperator, ⊤, ¬, ∧

using SoleLogics: AbstractInterpretationSet

const FormulaOrTree = Union{Formula,SyntaxTree}

############################################################################################

# Util
typename(::Type{T}) where T = eval(nameof(T))

"""
A boolean condition is a condition that evaluates to a boolean truth value (`true`/`false`).
"""
abstract type AbstractBooleanCondition end

Base.show(io::IO, c::AbstractBooleanCondition) = print(io, "$(typeof(c))($(syntaxstring(c)))")

function syntaxstring(c::AbstractBooleanCondition; kwargs...)
    error("Please, provide method syntaxstring(::$(typeof(c)); kwargs...).")
end

"""
A true condition is the boolean condition that is always true.
"""
struct TrueCondition <: AbstractBooleanCondition end

check(::TrueCondition, args...) = true

condition_length(c::TrueCondition) = 0

# Helper. Mh, what about TOP as a formula?
convert(::Type{AbstractBooleanCondition}, ::typeof(TOP)) = TrueCondition()

syntaxstring(c::TrueCondition; kwargs...) = syntaxstring(TOP; kwargs...)

"""
A logical truth condition is the boolean condition that a logical formula is true on
a logical interpretation.
Namely, that the formula checks `TOP` on the model.
"""
struct LogicalTruthCondition{F<:FormulaOrTree} <: AbstractBooleanCondition
    # formula::_F where _F<:F
    formula::F

    function LogicalTruthCondition{F}(
        formula::F
    ) where {F<:FormulaOrTree}
        new{F}(formula)
    end

    function LogicalTruthCondition(
        formula::F
    ) where {F<:FormulaOrTree}
        _F = begin
            if F<:Formula
                Formula
            elseif F<:SyntaxTree
                SyntaxTree
            else
                error("TODO explain error here")
            end
        end
        LogicalTruthCondition{_F}(formula)
    end
end

formula(c::LogicalTruthCondition) = c.formula
check(c::LogicalTruthCondition, args...) = (check(formula(c), args...) == TOP)

condition_length(c::LogicalTruthCondition) = npropositions(formula(c))

syntaxstring(c::LogicalTruthCondition; kwargs...) = syntaxstring(formula(c); kwargs...)

# Helper
convert(::Type{AbstractBooleanCondition}, f::FormulaOrTree) = LogicalTruthCondition(f)

"""
A Machine Learning model (`AbstractModel`) is a mathematical model that,
given an instance object (i.e., a piece of data), outputs an
outcome of type `O`.
"""
abstract type AbstractModel{O} end

"""
    outcometype(::Type{<:AbstractModel{O}}) where {O} = O
    outcometype(m::AbstractModel) = outcometype(typeof(m))

Returns the outcome type of the model.

See also [`AbstractModel`](@ref).
"""
outcometype(::Type{<:AbstractModel{O}}) where {O} = O
outcometype(m::AbstractModel) = outcometype(typeof(m))

doc_open_model = """
An `AbstractModel{O}` is *closed* if it is always able to provide an outcome of type `O`.
Otherwise, the model can output `nothing` values and is referred to as *open*.
"""

"""
$(doc_open_model)
This behavior can be expressed via the `isopen` trait, which defaults to `true`:

    isopen(::AbstractModel) = true

See also [`AbstractModel`](@ref).
"""
isopen(::AbstractModel) = true

"""
$(doc_open_model)
`output_type` leverages the `isopen` trait to provide the type for the outcome of a model:

    output_type(M::AbstractModel{O}) = isopen(M) ? Union{Nothing,O} : O

See also [`isopen`](@ref), [`AbstractModel`](@ref).
"""
function output_type(m::AbstractModel{O}) where {O}
    isopen(m) ? Union{Nothing, outcometype(m)} : outcometype(m)
end

"""
Any `AbstractModel` can be applied to an instance object or a dataset of instance objects.

See also [`AbstractModel`](@ref), [`AbstractInstance`](@ref), [`AbstractInterpretationSet`](@ref).
"""
apply(m::AbstractModel, i::AbstractInstance)::output_type(m) = error("Please, provide method apply(::$(typeof(m)), ::$(typeof(i))).")
apply(m::AbstractModel, d::AbstractInterpretationSet)::AbstractVector{<:output_type(m)} = map(i->apply(m, i), iterate_instances(d))


doc_symbolic = """
A `AbstractModel` is said to be `symbolic` when it is based on certain a logical language (or "logic",
see [`SoleLogics`](@ref) package).
Symbolic models provide a form of transparent and interpretable modeling.
"""

"""
$(doc_symbolic)
The `issymbolic` trait, defaulted to `false` can be used to specify that a model is symbolic.
A symbolic model is one where the computation has a *rule-base structure*.

See also [`logic`](@ref), [`unroll_rules`](@ref), [`AbstractModel`](@ref).
"""
issymbolic(::AbstractModel) = false

# """
# $(doc_symbolic)
# Every symbolic model must provide access to its corresponding `AbstractLogic` type via the `logic` trait.

# TODO remove
# See also [`issymbolic`](@ref), [`AbstractModel`](@ref).
# """
# function logic(m::AbstractModel)::AbstractLogic
#     if issymbolic(m)
#         error("Please, provide method logic(::$(typeof(m))), or define issymbolic(::$(typeof(m))) = false.")
#     else
#         error("Models of type $(typeof(m)) are not symbolic, and thus have no logic associated.")
#     end
# end

"""
Instead, a `AbstractModel` is said to be functional when it encodes an algebraic mathematical function.
"""

doc_info = """
In Sole.jl, each `AbstractModel` encompasses an `info::NamedTuple` field for storing additional information,
that does not affect on the model's behavior. This structure can hold, for example, information
about the `AbstractModel`ss statistical performance during the learning phase.
"""

"""
$(doc_info)
The `hasinfo` trait, defaulted to `true`, can be used to specify models that do not implement an
`info` field.
"""
hasinfo(::AbstractModel) = true

"""
$(doc_info)
The `info` getter function accesses this structure.
"""
info(m::AbstractModel)::NamedTuple = hasinfo(m) ? m.info : error("Type $(typeof(m)) does not have an `info` field.")


############################################################################################
############################################################################################
############################################################################################

"""
A `FinalModel` is a model which outcomes do not depend on another model.
An `AbstractModel` can generally wrap other `AbstractModel`s. In such case, the outcome can
depend on the inner models being applied on the instance object. Otherwise, the model is
considered final; that is, it is a leaf of a tree of `AbstractModel`s.
"""
abstract type FinalModel{O} <: AbstractModel{O} end

"""
Perhaps the simplest type of `AbstractModel` is the `ConstantModel`.
This is a final model (`FinalModel`) that always outputs the same outcome.

See also [`FunctionModel`](@ref), [`FinalModel`](@ref).
"""
struct ConstantModel{O} <: FinalModel{O}
    outcome::O
    info::NamedTuple

    function ConstantModel{O}(
        outcome::O,
        info::NamedTuple = (;),
    ) where {O}
        new{O}(outcome, info)
    end

    function ConstantModel(
        outcome::O,
        info::NamedTuple = (;),
    ) where {O}
        ConstantModel{O}(outcome, info)
    end

    function ConstantModel{O}(m::ConstantModel) where {O}
        ConstantModel{O}(m.outcome, m.info)
    end

    function ConstantModel(m::ConstantModel)
        ConstantModel(m.outcome, m.info)
    end
end

outcome(m::ConstantModel) = m.outcome

isopen(::ConstantModel) = false

convert(::Type{ConstantModel{O}}, o::O) where {O} = ConstantModel{O}(o)
convert(::Type{<:AbstractModel{F}}, m::ConstantModel) where {F} = ConstantModel{F}(m)

apply(m::ConstantModel, i::AbstractInstance) = outcome(m)
apply(m::ConstantModel, d::AbstractInterpretationSet) = outcome(m)

"""
A `FunctionModel` is a final model (`FinalModel`) that applies a native Julia `Function`
in order to compute the outcome. Over efficiency concerns, it is mandatory to make explicit
the output type `O` by wrapping the `Function` into a `FunctionWrapper{O}`

See also [`ConstantModel`](@ref), [`FunctionWrapper`](@ref), [`FinalModel`](@ref).
"""
struct FunctionModel{O} <: FinalModel{O}
    f::FunctionWrapper{O}
    # isopen::Bool
    info::NamedTuple

    function FunctionModel{O}(
        f::FunctionWrapper{O},
        info::NamedTuple = (;),
    ) where {O}
        new{O}(f, info)
    end

    function FunctionModel(
        f::FunctionWrapper{O},
        info::NamedTuple = (;),
    ) where {O}
        FunctionModel{O}(f, info)
    end

    function FunctionModel{O}(m::FunctionModel) where {O}
        FunctionModel{O}(m.f, m.info)
    end

    function FunctionModel(m::FunctionModel)
        FunctionModel(m.f, m.info)
    end
end

f(m::FunctionModel) = m.f

isopen(::FunctionModel) = false

convert(::Type{<:AbstractModel{F}}, m::FunctionModel) where {F} = FunctionModel{F}(m)

apply(m::FunctionModel, i::AbstractInstance) = f(m)(i)

"""
This function is used to specify the default `FinalModel` used for wrapping native computation.
The default behavior is the following:
- when called on an `AbstractModel`, the model is simply returned (without wrapping it);
- `Function`s and `FunctionWrapper`s are wrapped into a `FunctionModel`;
- every other object is wrapped into a `ConstantModel`.

See also [`ConstantModel`](@ref), [`FunctionModel`](@ref), [`ConstrainedModel`](@ref), [`FinalModel`](@ref).
"""
# TODO add `info` parameter
FinalModel(o::Any) = wrap(o)
wrap(o::Any, FM::Type{<:AbstractModel}) = convert(FM, wrap(o))
wrap(m::AbstractModel) = m
wrap(o::O) where {O} = convert(ConstantModel{O}, o)
function wrap(o::Function)
    @warn "Over efficiency concerns, please consider wrapping"*
    "Julia Function's into FunctionWrapper{O,Tuple{SoleModels.AbstractInstance}} structures,"*
    "where O is their return type."
    wrap(FunctionWrapper{Any,Tuple{AbstractInstance}}(o))
end
wrap(o::FunctionWrapper{O}) where {O} = FunctionModel{O}(o)

############################################################################################
############################################################################################
############################################################################################

"""
An `AbstractModel` can wrap another `AbstractModel`, and use it to compute the outcome.
As such, an `AbstractModel` can actually be the result of a composition of many models,
and enclose a *tree* of `AbstractModel`s (with `FinalModel`s at the leaves).
In order to typebound the Feasible Models (`FM`) allowed in the sub-tree,
the `ConstrainedModel` type is introduced:

    ConstrainedModel{O, FM <: AbstractModel} <: AbstractModel{O}

For example, `ConstrainedModel{String, Union{Branch{String}, ConstantModel{String}}}` supertypes models
that with `String` outcomes that make use of `Branch{String}` and `ConstantModel{String}`
(essentially, a decision trees with `String`s at the leaves).

See also [`FinalModel`](@ref), [`AbstractModel`](@ref).
"""
abstract type ConstrainedModel{O, FM <: AbstractModel} <: AbstractModel{O} end

"""
Returns the type of the Feasible Models (`FM`).

See also [`ConstrainedModel`](@ref).
"""
feasiblemodelstype(::Type{M}) where {O, M<:AbstractModel{O}} = AbstractModel{<:O}
feasiblemodelstype(::Type{M}) where {M<:AbstractModel} = AbstractModel
feasiblemodelstype(::Type{M}) where {O, M<:FinalModel{O}} = Union{}
feasiblemodelstype(::Type{M}) where {M<:FinalModel} = Union{}
feasiblemodelstype(::Type{<:ConstrainedModel{O, FM}}) where {O, FM} = FM
feasiblemodelstype(m::ConstrainedModel) = outcometype(typeof(m))

"""
    propagate_feasiblemodels(M::Type{<:AbstractModel}) = Union{typename(M){outcometype(M)}, feasiblemodelstype(M)}
    propagate_feasiblemodels(m::AbstractModel) = propagate_feasiblemodels(typeof(m))

This function is used upon construction of a `ConstrainedModel`,
to compute its Feasible Models (`FM`).
In general, its `FM` are a `Union` of the `FM` of its immediate child models, but
a trick is used in order to avoid unneccessary propagation of types throughout the model tree.
Note that this trick assumes that the first type parameter of any `ConstrainedModel` is
its `outcometype` `O`.

See also [`feasiblemodelstype`](@ref), [`ConstrainedModel`](@ref).
"""

propagate_feasiblemodels(M::Type{<:AbstractModel}) = Union{typename(M){outcometype(M)}, feasiblemodelstype(M)}
propagate_feasiblemodels(m::AbstractModel) = propagate_feasiblemodels(typeof(m))

"""
This function is used when constructing `ConstrainedModel`s to check that the inner
models satisfy the desired type constraints.

See also [`ConstrainedModel`](@ref), [`Rule`](@ref), [`Branch`](@ref).
"""
function check_model_constraints(M::Type{<:AbstractModel}, I_M::Type{<:AbstractModel}, FM::Type{<:AbstractModel}, FM_O::Type = outcometype(FM))
    I_O = outcometype(I_M)
    # FM_O = outcometype(FM)
    @assert I_O <: FM_O "Can't instantiate $(M) with inner model outcometype $(I_O)! $(I_O) <: $(FM_O) should hold."
    # @assert I_M <: FM || typename(I_M) <: typename(FM) "Can't instantiate $(M) with inner model $(I_M))! $(I_M) <: $(FM) || $(typename(I_M)) <: $(typename(FM)) should hold."
    @assert I_M <: FM "Can't instantiate $(M) with inner model $(I_M))! $(I_M) <: $(FM) should hold."
    if ! (I_M<:FinalModel{<:FM_O})
        # @assert I_M<:ConstrainedModel{FM_O,<:FM} "ConstrainedModels require I_M<:ConstrainedModel{O,<:FM}, but $(I_M) does not subtype $(ConstrainedModel{FM_O,<:FM})."
        @assert I_M<:ConstrainedModel{<:FM_O,<:FM} "ConstrainedModels require I_M<:ConstrainedModel{<:O,<:FM}, but $(I_M) does not subtype $(ConstrainedModel{<:FM_O,<:FM})."
    end
end

############################################################################################
############################################################################################
############################################################################################

doc_symbolic_basics = """
Symbolic modeling builds onto two basic building blocks, which are `AbstractModel`s themselves:
- `Rule`: IF (antecedent) THEN (consequent) END
- `Branch`: IF (antecedent) THEN (positive_consequent) ELSE (negative_consequent) END
The *antecedent* is a formula of a certain logic, that can typically evaluate to true or false
when the model is applied on an instance object;
the *consequent*s are `AbstractModel`s themselves, that are to be applied to the instance object
in order to obtain an outcome.
"""


"""
    struct Rule{O, C<:AbstractBooleanCondition, FM<:AbstractModel} <: ConstrainedModel{O, FM}
        antecedent::C
        consequent::FM
        info::NamedTuple
    end

A `Rule` is one of the fundamental building blocks of symbolic modeling, and has the semantics:

    IF (antecedent) THEN (consequent) END

where the antecedent is a condition to be tested and the consequent is the local outcome of the block.

Note that `FM` refers to the Feasible Models (`FM`) allowed in the model's sub-tree.
Also note that this structure also includes an `info::NamedTuple` for storing additional information.

See also [`Branch`](@ref), [`ConstrainedModel`](@ref), [`AbstractModel`](@ref).
"""
struct Rule{O, C<:AbstractBooleanCondition, FM<:AbstractModel} <: ConstrainedModel{O, FM}
    antecedent::C
    consequent::FM
    info::NamedTuple

    # function Rule{O, C, _FM, _M}(
    #     antecedent::Union{AbstractBooleanCondition, FormulaOrTree, AbstractTruthOperator},
    #     consequent::Any,
    #     info::NamedTuple = (;),
    # ) where {O, C<:AbstractBooleanCondition, _FM<:AbstractModel, _M<:AbstractModel}
    #     antecedent = convert(C, antecedent)
    #     consequent = wrap(consequent, _M)
    #     M = typeof(consequent)
    #     # FM = _FM
    #     # FM = typeintersect(Union{propagate_feasiblemodels(M), _FM}, AbstractModel{<:O})
    #     FM = propagate_feasiblemodels(M)
    #     check_model_constraints(Rule{O}, typeof(consequent), FM)
    #     new{O,C,FM,M}(antecedent, consequent, info)
    # end

    # function Rule{O, C, _FM}(
    #     antecedent::Union{AbstractBooleanCondition, FormulaOrTree, AbstractTruthOperator},
    #     consequent::Any,
    #     info::NamedTuple = (;),
    # ) where {O, C<:AbstractBooleanCondition, _FM<:AbstractModel}
    #     antecedent = convert(C, antecedent)
    #     consequent = wrap(consequent, AbstractModel{O})
    #     FM = typeintersect(Union{_FM,propagate_feasiblemodels(consequent)}, AbstractModel{<:O})
    #     check_model_constraints(Rule{O}, typeof(consequent), FM, O)
    #     new{O,C,FM}(antecedent, consequent, info)
    # end

    # function Rule{O, _FM}(
    #     antecedent::Union{AbstractBooleanCondition, FormulaOrTree, AbstractTruthOperator},
    #     consequent::Any,
    #     info::NamedTuple = (;),
    # ) where {O, _FM<:AbstractModel}
    #     antecedent = convert(AbstractBooleanCondition, antecedent)
    #     C = typeof(antecedent)
    #     consequent = wrap(consequent, AbstractModel{O})
    #     FM = typeintersect(Union{propagate_feasiblemodels(consequent), _FM}, AbstractModel{<:O})
    #     check_model_constraints(Rule{O}, typeof(consequent), FM, O)
    #     new{O,C,FM}(antecedent, consequent, info)
    # end

    function Rule{O}(
        antecedent::Union{AbstractBooleanCondition, FormulaOrTree, AbstractTruthOperator},
        consequent::Any,
        info::NamedTuple = (;),
    ) where {O}
        antecedent = convert(AbstractBooleanCondition, antecedent)
        C = typeof(antecedent)
        consequent = wrap(consequent, AbstractModel{O})
        FM = typeintersect(propagate_feasiblemodels(consequent), AbstractModel{<:O})
        check_model_constraints(Rule{O}, typeof(consequent), FM, O)
        new{O,C,FM}(antecedent, consequent, info)
    end

    function Rule(
        antecedent::Union{AbstractBooleanCondition, FormulaOrTree, AbstractTruthOperator},
        consequent::Any,
        info::NamedTuple = (;),
    )
        antecedent = convert(AbstractBooleanCondition, antecedent)
        C = typeof(antecedent)
        consequent = wrap(consequent)
        O = outcometype(consequent)
        FM = typeintersect(propagate_feasiblemodels(consequent), AbstractModel{<:O})
        check_model_constraints(Rule{O}, typeof(consequent), FM, O)
        new{O,C,FM}(antecedent, consequent, info)
    end
end

antecedent(m::Rule) = m.antecedent
consequent(m::Rule) = m.consequent

conditiontype(::Type{M}) where {M<:Rule{O, C}} where {O, C} = C
conditiontype(m::Rule) = conditiontype(typeof(m))

issymbolic(::Rule) = true

check(m::Rule, id) = check(antecedent(m), id)
apply(m::Rule, id) = check(antecedent(m), id) ? apply(consequent(m), id) : nothing


"""
    struct Branch{O, C<:AbstractBooleanCondition, FM<:AbstractModel} <: ConstrainedModel{O, FM}
        antecedent::C
        positive_consequent::FM
        negative_consequent::FM
        info::NamedTuple
    end

A `Branch` is one of the fundamental building blocks of symbolic modeling, and has the semantics:

    IF (antecedent) THEN (consequent_1) ELSE (consequent_2) END

where the antecedent is boolean condition to be tested and the consequents are the feasible
local outcomes of the block.

Note that `FM` refers to the Feasible Models (`FM`) allowed in the model's sub-tree.
Also note that this structure also includes an `info::NamedTuple` for storing additional information.

See also [`Rule`](@ref), [`ConstrainedModel`](@ref), [`AbstractModel`](@ref).
"""
struct Branch{O, C<:AbstractBooleanCondition, FM<:AbstractModel} <: ConstrainedModel{O, FM}
    antecedent::C
    positive_consequent::FM
    negative_consequent::FM
    info::NamedTuple

    # function Branch{O, C, _FM}(
    #     antecedent::Union{AbstractBooleanCondition, FormulaOrTree, AbstractTruthOperator},
    #     positive_consequent::Any,
    #     negative_consequent::Any,
    #     info::NamedTuple = (;),
    # ) where {O, C<:AbstractBooleanCondition, _FM<:AbstractModel}
    #     antecedent = convert(C, antecedent)
    #     positive_consequent = wrap(positive_consequent, AbstractModel{O})
    #     negative_consequent = wrap(negative_consequent, AbstractModel{O})
    #     FM = typeintersect(Union{_FM,propagate_feasiblemodels(positive_consequent),propagate_feasiblemodels(negative_consequent)}, AbstractModel{<:O})
    #     check_model_constraints(Branch{O}, typeof(positive_consequent), FM, O)
    #     check_model_constraints(Branch{O}, typeof(negative_consequent), FM, O)
    #     new{O,C,FM}(antecedent, positive_consequent, negative_consequent, info)
    # end

    function Branch(
        antecedent::Union{AbstractBooleanCondition, FormulaOrTree, AbstractTruthOperator},
        positive_consequent::Any,
        negative_consequent::Any,
        info::NamedTuple = (;),
    )
        antecedent = convert(AbstractBooleanCondition, antecedent)
        C = typeof(antecedent)
        positive_consequent = wrap(positive_consequent)
        negative_consequent = wrap(negative_consequent)
        O = Union{outcometype(positive_consequent), outcometype(negative_consequent)}
        FM = typeintersect(Union{propagate_feasiblemodels(positive_consequent),propagate_feasiblemodels(negative_consequent)}, AbstractModel{<:O})
        check_model_constraints(Branch{O}, typeof(positive_consequent), FM, O)
        check_model_constraints(Branch{O}, typeof(negative_consequent), FM, O)
        new{O,C,FM}(antecedent, positive_consequent, negative_consequent, info)
    end

    function Branch(
        antecedent::Union{AbstractBooleanCondition, FormulaOrTree, AbstractTruthOperator},
        (positive_consequent, negative_consequent)::Tuple{Any,Any},
        info::NamedTuple = (;),
    )
        Branch(antecedent, positive_consequent, negative_consequent, info)
    end

end

antecedent(m::Branch) = m.antecedent
positive_consequent(m::Branch) = m.positive_consequent
negative_consequent(m::Branch) = m.negative_consequent

conditiontype(::Type{M}) where {M<:Branch{O, C}} where {O, C} = C
conditiontype(m::Branch) = conditiontype(typeof(m))

issymbolic(::Branch) = true

isopen(m::Branch) = isopen(positive_consequent(m)) || isopen(negative_consequent(m))

check(m::Branch, i::AbstractInstance) = check(antecedent(m), i)
apply(m::Branch, d::Union{AbstractInstance, AbstractInterpretationSet}) = check(antecedent(m), d) ? apply(positive_consequent(m), d) : apply(negative_consequent(m), d)

"""
    struct DecisionList{O, C<:AbstractBooleanCondition, FM<:AbstractModel} <: ConstrainedModel{O, FM}
        rules::Vector{Rule{_O, _C, _FM} where {_O<:O, _C<:C, _FM<:FM}}
        default_consequent::FM
        info::NamedTuple
    end

A `DecisionList` (or *decision table*, or *rule-based model*) is a symbolic model that
has the semantics of an IF-ELSEIF-ELSE block:

    IF (antecedent_1)     THEN (consequent_1)
    ELSEIF (antecedent_2) THEN (consequent_2)
    ...
    ELSEIF (antecedent_n) THEN (consequent_n)
    ELSE (consequent_default) END

where the antecedents are conditions to be tested and the consequents are the feasible
local outcomes of the block.
Using the classical semantics, the antecedents are evaluated in order,
and a consequent is returned as soon as a valid antecedent is found,
or when the computation reaches the ELSE clause.

Note that `FM` refers to the Feasible Models (`FM`) allowed in the model's sub-tree.
Also note that this structure also includes an `info::NamedTuple` for storing additional information.

See also [`Rule`](@ref), [`ConstrainedModel`](@ref), [`DecisionTree`](@ref), [`AbstractModel`](@ref).
"""
struct DecisionList{O, C<:AbstractBooleanCondition, FM<:AbstractModel} <: ConstrainedModel{O, FM}
    rules::Vector{Rule{_O, _C, _FM} where {_O<:O, _C<:C, _FM<:FM}}
    default_consequent::FM
    info::NamedTuple

    # function DecisionList{O, C, _FM}(
    #     rules::Vector{<:Rule{<:O, <:C, <:_FM}},
    #     default_consequent::Any,
    #     info::NamedTuple = (;),
    # ) where {O, C<:AbstractBooleanCondition, _FM<:AbstractModel}
    #     default_consequent = wrap(default_consequent, AbstractModel{O})
    #     FM = typeintersect(Union{_FM,propagate_feasiblemodels(default_consequent),propagate_feasiblemodels.(rules)...}, AbstractModel{<:O})
    #     # FM = typeintersect(Union{propagate_feasiblemodels(default_consequent),propagate_feasiblemodels.(rules)...}, AbstractModel{O})
    #     # FM = Union{propagate_feasiblemodels(default_consequent),propagate_feasiblemodels.(rules)...}
    #     check_model_constraints.(DecisionList{O}, typeof.(rules), FM, O)
    #     check_model_constraints(DecisionList{O}, typeof(default_consequent), FM)
    #     new{O,C,FM}(rules, default_consequent, info)
    # end

    # function DecisionList{O}(
    #     rules::Vector{<:Rule{OO, <:C, <:FM}},
    #     default_consequent::Any,
    #     info::NamedTuple = (;),
    # ) where {O, OO<:O}
    #     default_consequent = wrap(default_consequent, AbstractModel{O})
    #     FM = typeintersect(Union{propagate_feasiblemodels(default_consequent),propagate_feasiblemodels.(rules)...}, AbstractModel{<:O})
    #     # FM = typeintersect(Union{propagate_feasiblemodels(default_consequent),propagate_feasiblemodels.(rules)...}, AbstractModel{O})
    #     # FM = Union{propagate_feasiblemodels(default_consequent),propagate_feasiblemodels.(rules)...}
    #     check_model_constraints.(DecisionList{O}, typeof.(rules), FM, O)
    #     check_model_constraints(DecisionList{O}, typeof(default_consequent), FM, O)
    #     new{O,C,FM}(rules, default_consequent, info)
    # end

    function DecisionList(
        rules::Vector{<:Rule},
        default_consequent::Any,
        info::NamedTuple = (;),
    ) where {}
        default_consequent = wrap(default_consequent)
        O = Union{outcometype(default_consequent), outcometype.(rules)...}
        C = Union{conditiontype.(rules)...}
        FM = typeintersect(Union{propagate_feasiblemodels(default_consequent),propagate_feasiblemodels.(rules)...}, AbstractModel{<:O})
        # FM = typeintersect(Union{propagate_feasiblemodels(default_consequent),propagate_feasiblemodels.(rules)...}, AbstractModel{O})
        # FM = Union{propagate_feasiblemodels(default_consequent),propagate_feasiblemodels.(rules)...}
        check_model_constraints.(DecisionList{O}, typeof.(rules), FM, O)
        check_model_constraints(DecisionList{O}, typeof(default_consequent), FM, O)
        new{O,C,FM}(rules, default_consequent, info)
    end
end

rules(m::DecisionList) = m.rules
default_consequent(m::DecisionList) = m.default_consequent

conditiontype(::Type{M}) where {M<:DecisionList{O, C}} where {O, C} = C
conditiontype(m::DecisionList) = conditiontype(typeof(m))

issymbolic(::DecisionList) = true

isopen(m::DecisionList) = isopen(default_consequent(m))

function apply(m::DecisionList, i::AbstractInstance)
    for rule in rules(m)
        if check(m, i)
            return consequent(rule)
        end
    end
    default_consequent(m)
end

"""
    struct RuleCascade{O, C<:AbstractBooleanCondition, FFM<:FinalModel} <: ConstrainedModel{O, FFM}
        antecedents::Vector{<:C}
        consequent::FFM
        info::NamedTuple
    end

A `RuleCascade` is a symbolic model that operates as a nested structure of IF-THEN blocks:

    IF (antecedent_1) THEN
        IF (antecedent_2) THEN
            ...
                IF (antecedent_n) THEN
                    (consequent)
                END
            ...
        END
    END

where the antecedents are conditions to be tested and the consequent is the feasible
local outcome of the block.

Note that `FM` refers to the Feasible Models (`FM`) allowed in the model's sub-tree.
Also note that this structure also includes an `info::NamedTuple` for storing additional information.

See also [`Rule`](@ref), [`ConstrainedModel`](@ref), [`DecisionList`](@ref), [`AbstractModel`](@ref).
"""
struct RuleCascade{O, C<:AbstractBooleanCondition, FFM<:FinalModel} <: ConstrainedModel{O, FFM}
    antecedents::Vector{<:C}
    consequent::FFM
    info::NamedTuple

    # function RuleCascade{O, C, _FFM}(
    #     antecedents::Vector{<:C},
    #     consequent::Any,
    #     info::NamedTuple = (;),
    # ) where {O, C<:AbstractBooleanCondition, _FFM<:FinalModel}
    #     antecedents = convert.(C, antecedents)
    #     consequent = wrap(consequent, AbstractModel{O})
    #     FFM = typeintersect(Union{_FM,propagate_feasiblemodels(consequent)}, FinalModel{<:O})
    #     check_model_constraints(RuleCascade{O}, typeof(consequent), FFM, O)
    #     new{O,C,FFM}(antecedents, consequent, info)
    # end

    function RuleCascade(
        antecedents::Vector{<:Union{AbstractBooleanCondition, FormulaOrTree, AbstractTruthOperator}},
        consequent::Any,
        info::NamedTuple = (;),
    )
        antecedents = convert.(AbstractBooleanCondition, antecedents)
        C = utils._typejoin(typeof.(antecedents)...)
        consequent = wrap(consequent)
        O = outcometype(consequent)
        FFM = typeintersect(propagate_feasiblemodels(consequent), FinalModel{<:O})
        check_model_constraints(RuleCascade{O}, typeof(consequent), FFM, O)
        new{O,C,FFM}(antecedents, consequent, info)
    end
end

antecedents(m::RuleCascade) = m.antecedents
consequent(m::RuleCascade) = m.consequent

conditiontype(::Type{M}) where {M<:RuleCascade{O, C}} where {O, C} = C
conditiontype(m::RuleCascade) = conditiontype(typeof(m))

issymbolic(::RuleCascade) = true

function apply(m::RuleCascade, i::AbstractInstance)
    for antecedent in antecedents(m)
        if ! check(antecedent, i)
            return nothing
        end
    end
    consequent(m)
end

"""
    Convert a rule cascade into a rule
"""
function convert(::Type{R}, m::RuleCascade{O, C}) where {R<:Rule, O, C<:LogicalTruthCondition}
    cond = LogicalTruthCondition(_antecedent(antecedents(m)))
    return R(cond, consequent(m), info(m))
end

function _antecedent(m::Vector{<:AbstractBooleanCondition})
    if length(m) == 0
        return SyntaxTree(⊤)
    elseif length(m) == 1
        return formula(m[1])
    else
        return ∧((formula.(m))...)
    end
end

Base.length(rc::RuleCascade) = length(antecedents(rc))
Base.getindex(rc::RuleCascade, idxs) = RuleCascade(antecedents(rc)[idxs], consequent(rc))

"""
A `DecisionTree` is a symbolic model that operates as a nested structure of IF-THEN-ELSE blocks:

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

where the antecedents are conditions to be tested and the consequents are the feasible
local outcomes of the block.

In practice, a `DecisionTree` simply wraps a constrained sub-tree of `Branch` and `FinalModel`:

    struct DecisionTree{O, C<:AbstractBooleanCondition, FFM<:FinalModel} <: ConstrainedModel{O, Union{<:Branch{<:O,<:C}, <:FFM}}
        root::M where {M<:Union{FFM,Branch}}
        info::NamedTuple
    end

Note that `FM` refers to the Feasible Models (`FM`) allowed in the model's sub-tree.
Also note that this structure also includes an `info::NamedTuple` for storing additional information.

See also [`ConstrainedModel`](@ref), [`MixedSymbolicModel`](@ref), [`DecisionList`](@ref).
"""
struct DecisionTree{O, C<:AbstractBooleanCondition, FFM<:FinalModel} <: ConstrainedModel{O, Union{<:Branch{<:O,<:C}, <:FFM}}
    root::M where {M<:Union{FFM,Branch}}
    info::NamedTuple

    # function DecisionTree(
    #     root::Union{FFM,Branch{O,<:C,<:Union{Branch{<:O,<:C},FFM}}},
    #     info::NamedTuple = (;),
    # ) where {O, C<:AbstractBooleanCondition, FFM<:FinalModel{<:O}}
    #     new{O,C,FFM}(root, info)
    # end
    # ) where {_O, _C<:AbstractBooleanCondition, _FFM<:FinalModel, M<:Union{_FFM,Branch{<:_O,<:_C,<:Union{Branch{<:_O,<:_C},_FFM}}}}

    function DecisionTree(
        root::Any,
        info::NamedTuple = (;),
    )
        root = wrap(root)
        M = typeof(root)
        O = outcometype(root)
        C = (root isa FinalModel ? AbstractBooleanCondition : conditiontype(M))
        # FM = typeintersect(Union{M, feasiblemodelstype(M)}, AbstractModel{<:O})
        FM = typeintersect(Union{propagate_feasiblemodels(M)}, AbstractModel{<:O})
        FFM = typeintersect(FM, FinalModel{<:O})
        @assert M <: Union{<:FFM,<:Branch{<:O,<:C,<:Union{Branch,FFM}}} "Cannot instantiate DecisionTree{$(O),$(C),$(FFM),$(M)}(...) with root of type $(typeof(root)). Note that the should be either a FinalNode or a bounded Banch. $(M) <: $(Union{FinalModel,Branch{<:O,<:C,<:Union{Branch,FFM}}}) should hold."
        check_model_constraints(DecisionTree{O}, typeof(root), FM, O)
        new{O,C,FFM}(root, info)
    end
end
root(m::DecisionTree) = m.root

issymbolic(::DecisionTree) = true

isopen(::DecisionTree) = false

apply(m::DecisionTree, i::AbstractInstance) = apply(root(m), i)

"""
A `Decision Forest` is a symbolic model that wraps an ensemble of models

    struct DecisionForest{O, C<:AbstractBooleanCondition, FFM<:FinalModel} <: ConstrainedModel{O, Union{<:Branch{<:O,<:C}, <:FFM}}
        trees::Vector{<:DecisionTree}
        info::NamedTuple
    end

Note that this structure also includes an `info::NamedTuple` for storing additional information.

See also [`ConstrainedModel`](@ref), [`MixedSymbolicModel`](@ref), [`DecisionList`](@ref),
[`DecisionTree`](@ref)
"""
struct DecisionForest{O, C<:AbstractBooleanCondition, FFM<:FinalModel} <: ConstrainedModel{O, Union{<:Branch{<:O,<:C}, <:FFM}}
    trees::Vector{<:DecisionTree}
    info::NamedTuple

    function DecisionForest(
        trees::Vector{<:DecisionTree},
        info::NamedTuple = (;),
    )
        root_tree = wrap(root(trees[1]))
        M = typeof(root_tree)
        O = outcometype(root_tree)
        C = (root_tree isa FinalModel ? AbstractBooleanCondition : conditiontype(M))
        FM = typeintersect(Union{propagate_feasiblemodels(M)}, AbstractModel{<:O})
        FFM = typeintersect(FM, FinalModel{<:O})
        @assert M <: Union{<:FFM,<:Branch{<:O,<:C,<:Union{Branch,FFM}}} "Cannot instantiate DecisionForest{$(O),$(C),$(FFM),$(M)}(...) with root first tree of type $(typeof(root)). Note that the should be either a FinalNode or a bounded Banch. $(M) <: $(Union{FinalModel,Branch{<:O,<:C,<:Union{Branch,FFM}}}) should hold."
        check_model_constraints(DecisionTree{O}, typeof(root_tree), FM, O)
        new{O,C,FFM}(trees, info)
    end
end

trees(forest::DecisionForest) = forest.trees
info(forest::DecisionForest) = forest.info

issymbolic(::DecisionForest) = false

apply_trees(f::DecisionForest, i::AbstractInstance) = [apply(t,i) for t in trees(f)]
apply(f::DecisionForest, i::AbstractInstance) = majority_vote(apply_trees(trees(f), i))

"""
A `MixedSymbolicModel` is a symbolic model that operaters as a free nested structure of IF-THEN-ELSE
and IF-ELSEIF-ELSE blocks:

    IF (antecedent_1) THEN
        IF (antecedent_1)     THEN (consequent_1)
        ELSEIF (antecedent_2) THEN (consequent_2)
        ELSE (consequent_1_default) END
    ELSE
        IF (antecedent_3) THEN
            (consequent_3)
        ELSE
            (consequent_4)
        END
    END

where the antecedents are conditinos and the consequents are the feasible
local outcomes of the block.

In Sole.jl, this logic can implemented using `ConstrainedModel`s such as
`Rule`s, `Branch`s, `RuleCascade`s, `DecisionList`s, `DecisionTree`s, and the be wrapped into
a `MixedSymbolicModel`:

    struct MixedSymbolicModel{O, FM<:AbstractModel} <: ConstrainedModel{O, FM}
        root::M where {M<:Union{FinalModel{<:O},ConstrainedModel{<:O,<:FM}}}
        info::NamedTuple
    end

Note that `FM` refers to the Feasible Models (`FM`) allowed in the model's sub-tree.
Also note that this structure also includes an `info::NamedTuple` for storing additional information.

See also [`ConstrainedModel`](@ref), [`DecisionTree`](@ref), [`DecisionList`](@ref).
"""
struct MixedSymbolicModel{O, FM<:AbstractModel} <: ConstrainedModel{O, FM}
    root::M where {M<:Union{FinalModel{<:O},ConstrainedModel{<:O,<:FM}}}
    info::NamedTuple

    function MixedSymbolicModel(
        root::Any,
        info::NamedTuple = (;),
    )
        root = wrap(root)
        M = typeof(root)
        O = outcometype(root)
        FM = typeintersect(Union{propagate_feasiblemodels(M)}, AbstractModel{<:O})
        check_model_constraints(MixedSymbolicModel{O}, typeof(root), FM, O)
        new{O,FM}(root, info)
    end
end
root(m::MixedSymbolicModel) = m.root

issymbolic(::MixedSymbolicModel) = false

isopen(::MixedSymbolicModel) = isopen(root)

apply(m::MixedSymbolicModel, i::AbstractInstance) = apply(root(m), i)

############################################################################################
############################################################################################
############################################################################################
