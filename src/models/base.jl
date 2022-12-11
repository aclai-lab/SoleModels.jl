export antecedent, consequent, positive_consequent, negative_consequent, default_consequent, rules, root

############################################################################################
# TODO move this stuff
############################################################################################
import SoleLogics: CONJUCTION
function SoleLogics.CONJUNCTION(formulas::Formula...)
    if length(formulas) == 1
        formulas[1]
    elseif length(formulas) == 2
        SoleLogics.CONJUNCTION(tree(formulas[1]), tree(formulas[2]))
    elseif length(formulas) > 2
        SoleLogics.CONJUNCTION(tree(formulas[1]), SoleLogics.CONJUNCTION(formulas[2:end]...))
    else
        error("TODO error")
    end
end

function check(::Formula, ::AbstractInstance) end
function check(::Formula, ::AbstractDataset) end
############################################################################################

"""
A Machine Learning model (`AbstractModel`) is a mathematical model that,
given an instance object (i.e., a piece of data), outputs an
outcome of type `O`.
"""
abstract type AbstractModel{O} end

"""
Returns the outcome type of the model
"""
outcometype(::Type{<:AbstractModel{O}}) where {O} = O
outcometype(m::AbstractModel{O}) where {O} = O

doc_open_model = """
An `AbstractModel{O}` is *closed* if it is always able to provide an outcome of type `O`.
Otherwise, the model can produce `nothing` as outcome and is referred to as *open*.
"""

"""
$(doc_open_model)
This behavior can be expressed via the `isopen` trait, which defaults to `true`:

    isopen(::AbstractModel) = true
"""
isopen(::AbstractModel) = true

"""
$(doc_open_model)
`output_type` leverages the `isopen` trait to provide the type for the outcome of a model:

    output_type(M::AbstractModel{O}) = isopen(M) ? Union{Nothing,O} : O

See also [`isopen`](@ref), [`AbstractModel`](@ref).
"""
function output_type(m::AbstractModel{O}) where {O}
    isopen(m) ? Union{Nothing,outcometype(m)} : outcometype(m)
end

"""
Any `AbstractModel` can be applied to an instance object or a dataset of instance objects.

See also [`AbstractModel`](@ref), [`AbstractInstance`](@ref), [`AbstractDataset`](@ref).
"""
apply(m::AbstractModel, i::AbstractInstance)::output_type(m) = error("Please, provide method apply(::$(typeof(m)), ::$(typeof(i))).")
apply(m::AbstractModel, d::AbstractDataset)::AbstractVector{<:output_type(m)} = map(i->apply(m, i), iterate_instances(d))


doc_symbolic = """
A `AbstractModel` is said to be `symbolic` when it is based on certain a logical language (or "logic",
see [`SoleLogics`](@ref) package).
Symbolic models provide a form of transparent and interpretable modeling.
"""

"""
$(doc_symbolic)
The `issymbolic` trait, defaulted to `false` can be used to specify that a model is symbolic.

See also [`logic`](@ref), [`unroll_rules`](@ref), [`AbstractModel`](@ref).
"""
issymbolic(::AbstractModel) = false

"""
$(doc_symbolic)
Every symbolic model must provide access to its corresponding `Logic` type via the `logic` trait.

See also [`issymbolic`](@ref), [`AbstractModel`](@ref).
"""
logic(m::AbstractModel)::AbstractLogic = error(issymbolic(m) ? "Please, provide method logic(::$(typeof(m))), or define issymbolic(::$(typeof(m))) = false." : "Models of type $(typeof(m)) are not symbolic, and thus have no logic associated.")

"""
Instead, a `AbstractModel` is said to be functional when it encodes an algebraic mathematical function.
"""

doc_info = """
In Sole, each `AbstractModel` encompasses an `info::NamedTuple` field for storing additional information,
that does not affect on the model's behavior. This structure can hold, for example, information
about the `AbstractModel`'s statistical performance during the learning phase.
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

# """
# TODO remove and simply use wrap?
# Since `FinalModel` rely on native Julia computation (e.g., a constant or a function),
# they should be easily instantiated; each subtype `M` of `FinalModel` should implement at
# least one `convert(M::Type{<:FinalModel}, ::T}` method (where `T` is any type).

# See also [`FinalModel`](@ref).
# """
# convert(M::Type{<:FinalModel}, ::T) where {T} = error("Please, provide method Base.convert(::Type{$(M)}, ::$(T)).")

# """
# Conversion methods between subtypes of `AbstractModel` can be provided.
# """
# convert(::Type{M1}, m::M2) where {F1, F2, M1<:AbstractModel{F1}, M2<:AbstractModel{F2}} =
#     error("Please, provide convert method from $(M2) to $(M1).")
#     # typeintersect(M1,M2)([getfield(m, Symbol(field)) for field in fieldnames(M2)]...)

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

convert(::Type{ConstantModel}, m::ConstantModel) = ConstantModel(m)
convert(::Type{ConstantModel{O}}, o::O) where {O} = ConstantModel{O}(o)
convert(::Type{<:AbstractModel{F1}}, m::ConstantModel) where {F1} = ConstantModel{F1}(m)

apply(m::ConstantModel, i::AbstractInstance) = outcome(m)
apply(m::ConstantModel, d::AbstractDataset) = outcome(m)

"""
A `FunctionModel` is a final model (`FinalModel`) that applies a native Julia `Function`
in order to compute the outcome. Over efficiency concerns, it is mandatory to make explicit
the output type `O` by wrapping the `Function` into a `FunctionWrapper{O}`

See also [`ConstantModel`](@ref), [`FunctionWrapper`](@ref), [`FinalModel`](@ref).
"""
struct FunctionModel{O} <: FinalModel{O}
    f::FunctionWrapper{O}
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

f(m::ConstantModel) = m.f

convert(::Type{FunctionModel}, m::FunctionModel) = FunctionModel(m)
convert(::Type{FunctionModel{O}}, f::FunctionWrapper) where {O} = FunctionModel{O}(f)
convert(::Type{FunctionModel{O}}, f::Function) where {O} = error("Please, wrap Julia functions in FunctionWrappers{O}, where O is their return type.")
# function convert(::Type{FunctionModel{O}}, f::Function) where {O}
#     @warn "Over efficiency concerns, please consider wrapping Function's into FunctionWrapper's."
#     FunctionModel{O}(f)
# end
convert(::Type{<:AbstractModel{F1}}, m::FunctionModel) where {F1} = FunctionModel{F1}(m)

apply(m::FunctionModel, i::AbstractInstance) = f(m)(i)

"""
This function is used to specify the default `FinalModel` used for wrapping native computation.
The default behavior is the following:
- when called on an `AbstractModel`, the model is simply returned (without wrapping it);
- `Function`s and `FunctionWrapper`s are wrapped into a `FunctionModel`;
- every other object is wrapped into a `ConstantModel`.

See also [`ConstantModel`](@ref), [`FunctionModel`](@ref), [`ConstrainedModel`](@ref), [`FinalModel`](@ref).
"""
wrap(o::Any, FIM::Type{<:AbstractModel}) = convert(FIM, wrap(o))
wrap(m::AbstractModel) = m
wrap(o::O) where {O} = convert(ConstantModel{O}, o)
wrap(o::Union{Function, FunctionWrapper{O}}) where {O} = convert(FunctionModel{O}, o)

############################################################################################
############################################################################################
############################################################################################

"""
An `AbstractModel` can wrap another `AbstractModel`, and use it to compute the outcome.
As such, an `AbstractModel` can actually be the result of a composition of many models,
and enclose a *tree* of `AbstractModel`s (with `FinalModel`s at the leaves).
In order to typebound the Feasible Inner Models (`FIM`) allowed in the sub-tree,
the `ConstrainedModel` type is introduced:

    ConstrainedModel{O, FIM <: AbstractModel{OO where OO<:O}} <: AbstractModel{O}

For example, `ConstrainedModel{String, Union{Branch{String}, ConstantModel{String}}}` supertypes models
that with `String` outcomes that make use of `Branch{String}` and `ConstantModel{String}`
(essentially, a decision trees with `String`s at the leaves).

See also [`FinalModel`](@ref), [`AbstractModel`](@ref).
"""
abstract type ConstrainedModel{O, FIM <: AbstractModel{OO where OO<:O}} <: AbstractModel{O} end

"""
This function is used when constructing `ConstrainedModel`s to check that the inner
models satisfy the desired type constraints.

See also [`ConstrainedModel`](@ref), [`Rule`](@ref), [`Branch`](@ref).
"""
function check_model_constraints(::Type{M}, I_M::Type{<:AbstractModel{I_O}}, FIM::Type{<:AbstractModel{<:O}}) where {O, I_O, M<:AbstractModel{O}}
    @assert I_O <: O "Can't instantiate $(M) with inner model outcometype $(I_O)! $(I_O) <: $(O) should hold."
    # TODO now it's kinda implicit, but one day maybe not:
    # @assert I_M <: FIM "Can't instantiate $(M) with inner model $(I_M))! $(I_M) <: $(FIM) should hold."
    if ! (I_M<:FinalModel{<:O})
        @assert I_M<:ConstrainedModel{O,FIM} "ConstrainedModels require I_M<:ConstrainedModel{O,FIM}, but $(I_M) does not subtype $(ConstrainedModel{O,FIM})."
    end
end

"""
Some `ConstrainedModel`s (e.g., decision trees) inherently rely on specific `ConstrainedModel` types.
In such cases, the bounding type parameter only serves to constrain the type of `FinalModel`s in the sub-tree:

    FinallyConstrainedModel{O, FFM <: FinalModel{OO where OO<:O}} <: ConstrainedModel{O, FFM}

For example, `FinallyConstrainedModel{String, ConstantModel{String}}` supertypes implementations
of decision lists with `String`s as consequents, and decision trees with `String`s at the leaves.

See also [`ConstrainedModel`](@ref), [`FinalModel`](@ref), [`DecisionList`](@ref), [`DecisionTree`](@ref).
"""
abstract type FinallyConstrainedModel{O, FFM <: FinalModel{OO where OO<:O}} <: ConstrainedModel{O, FFM} end

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
A *rule* is one of the fundamental building blocks of symbolic modeling, and has the form:

    IF (antecedent) THEN (consequent) END

where the antecedent is a logical formula and the consequent is the local outcome of the block.


In Sole, a `Rule{O, L<:AbstractLogic}` wraps an `antecedent::Formula{L}`, that is, a formula of a given logic L,
and a `consequent::AbstractModel{<:O}` that is to be applied to obtain an outcome.

It also includes an `info::NamedTuple` for storing additional information.

# Extended help
Being a `ConstrainedModel`, this struct is actually defined as:

    struct Rule{O, L<:AbstractLogic, FIM<:AbstractModel{<:O}} <: ConstrainedModel{O, FIM}

where `FIM` refers to the Feasible Inner Models (`FIM`) allowed in the sub-tree.

See also [`Branch`](@ref), [`ConstrainedModel`](@ref), [`AbstractModel`](@ref).
"""
struct Rule{O, L<:AbstractLogic, FIM<:AbstractModel{OO where OO<:O}} <: ConstrainedModel{O, FIM}
    antecedent::Formula{L}
    consequent::FIM
    # consequent::AbstractModel{<:O} #TODO test FIM in check_model_constraints
    info::NamedTuple

    function Rule{O, L, FIM}(
        antecedent::Formula{L},
        consequent::Any,
        info::NamedTuple = (;),
    ) where {O, L<:AbstractLogic, FIM<:AbstractModel{OO where OO<:O}}
        consequent = wrap(consequent, FIM)
        check_model_constraints(Rule{O}, typeof(consequent), FIM)
        new{O,L,FIM}(antecedent, consequent, info)
    end

    function Rule{O, L}(
        antecedent::Formula{L},
        consequent::Any,
        info::NamedTuple = (;),
    ) where {O, L<:AbstractLogic}
        FIM = AbstractModel{O}
        new{O,L,FIM}(antecedent, wrap(consequent,FIM), info)
    end

    function Rule{O}(
        antecedent::Formula{L},
        consequent::Any,
        info::NamedTuple = (;),
    ) where {O, L<:AbstractLogic}
        FIM = AbstractModel{O}
        new{O,L,FIM}(antecedent, wrap(consequent,FIM), info)
    end

    function Rule(
        antecedent::Formula{L},
        consequent::Any,
        info::NamedTuple = (;),
    ) where {L<:AbstractLogic}
        consequent = wrap(consequent)
        O = outcometype(consequent)
        FIM = AbstractModel{O}
        new{O,L,FIM}(antecedent, consequent, info)
    end

    function Rule{O, L, FIM}(m::Rule) where {O, L<:AbstractLogic, FIM<:AbstractModel{OO where OO<:O}}
        Rule{O, L, FIM}(m.antecedent, m.consequent, m.info)
    end

    function Rule(m::Rule{O, L, FIM}) where {O, L<:AbstractLogic, FIM<:AbstractModel{OO where OO<:O}}
        Rule{O, L, FIM}(m)
    end
end

antecedent(m::Rule) = m.antecedent
consequent(m::Rule) = m.consequent

issymbolic(::Rule) = true
logic(::Rule{O,L}) where {O, L} = L

convert(::Type{<:AbstractModel{F1}}, m::Rule{F2, L, FIM}) where {F1, F2, L, FIM} = Rule{F1, L, FIM}(m)

check(m::Rule, id) = check(antecedent(m), id)
apply(m::Rule, id) = check(antecedent(m), id) ? apply(consequent(m), id) : nothing

outcometype(::Type{<:Rule{O}}) where {O} = O

"""
A *branch* is one of the fundamental building blocks of symbolic modeling, and has the form:

    IF (antecedent) THEN (consequent_1) ELSE (consequent_2) END

where the antecedent is a logical formula and the consequents are the feasible
local outcomes of the block.

In Sole, a `Branch{O, L<:AbstractLogic}` wraps an `antecedent::Formula{L}`, that is, a formula of a given logic L,
and two `AbstractModel{<:O}`s (*positive_consequent*, *negative_consequent*) that are to be
applied to obtain an outcome.

It also includes an `info::NamedTuple` for storing additional information.

# Extended help
Being a `ConstrainedModel`, this struct is actually defined as:

    struct Branch{O, L<:AbstractLogic, FIM<:AbstractModel{<:O}} <: ConstrainedModel{O, FIM}

where `FIM` refers to the Feasible Inner Models (`FIM`) allowed in the sub-tree.

See also [`Rule`](@ref), [`ConstrainedModel`](@ref), [`AbstractModel`](@ref).
"""
struct Branch{O, L<:AbstractLogic, FIM<:AbstractModel{OO where OO<:O}} <: ConstrainedModel{O, FIM}
    antecedent::Formula{L}
    positive_consequent::FIM
    negative_consequent::FIM
    info::NamedTuple

    function Branch{O, L, FIM}(
        antecedent::Formula{L},
        positive_consequent::Any,
        negative_consequent::Any,
        info::NamedTuple = (;),
    ) where {O, L<:AbstractLogic, FIM<:AbstractModel{OO where OO<:O}}
        positive_consequent = wrap(positive_consequent, FIM)
        negative_consequent = wrap(negative_consequent, FIM)
        check_model_constraints(Branch{O}, typeof(positive_consequent), FIM)
        check_model_constraints(Branch{O}, typeof(negative_consequent), FIM)
        new{O,L,FIM}(antecedent, positive_consequent, negative_consequent, info)
    end

    function Branch{O, L}(
        antecedent::Formula{L},
        positive_consequent::Any,
        negative_consequent::Any,
        info::NamedTuple = (;),
    ) where {O, L<:AbstractLogic}
        FIM = AbstractModel{O}
        new{O,L,FIM}(antecedent, wrap(positive_consequent, FIM), wrap(negative_consequent, FIM), info)
    end

    function Branch{O}(
        antecedent::Formula{L},
        positive_consequent::Any,
        negative_consequent::Any,
        info::NamedTuple = (;),
    ) where {O, L<:AbstractLogic}
        FIM = AbstractModel{O}
        new{O,L,FIM}(antecedent, wrap(positive_consequent, FIM), wrap(negative_consequent, FIM), info)
    end

    function Branch(
        antecedent::Formula{L},
        positive_consequent::Any,
        negative_consequent::Any,
        info::NamedTuple = (;),
    ) where {L<:AbstractLogic}
        positive_consequent = wrap(positive_consequent)
        negative_consequent = wrap(negative_consequent)
        F1 = outcometype(positive_consequent)
        F2 = outcometype(negative_consequent)
        O = Union{F1, F2}
        FIM = AbstractModel{O}
        new{O,L,FIM}(antecedent, positive_consequent, negative_consequent, info)
    end

    function Branch{O, L, FIM}(
        antecedent::Formula{L},
        (positive_consequent, negative_consequent)::Tuple{Any,Any},
        info::NamedTuple = (;),
    ) where {O, L, FIM}
        Branch{O, L, FIM}(antecedent, positive_consequent, negative_consequent, info)
    end

    function Branch{O, L}(
        antecedent::Formula{L},
        (positive_consequent, negative_consequent)::Tuple{Any,Any},
        info::NamedTuple = (;),
    ) where {O, L}
        Branch{O, L}(antecedent, positive_consequent, negative_consequent, info)
    end

    function Branch(
        antecedent::Formula{L},
        (positive_consequent, negative_consequent)::Tuple{Any,Any},
        info::NamedTuple = (;),
    ) where {L<:AbstractLogic}
        Branch(antecedent, positive_consequent, negative_consequent, info)
    end

    function Branch{O, L, FIM}(m::Branch) where {O, L<:AbstractLogic, FIM<:AbstractModel{OO where OO<:O}}
        Branch{O, L, FIM}(m.antecedent, m.positive_consequent, m.negative_consequent, m.info)
    end

    function Branch(m::Branch{O, L, FIM}) where {O, L<:AbstractLogic, FIM<:AbstractModel{OO where OO<:O}}
        Branch{O, L, FIM}(m)
    end
end

antecedent(m::Branch) = m.antecedent
positive_consequent(m::Branch) = m.positive_consequent
negative_consequent(m::Branch) = m.negative_consequent

issymbolic(::Branch) = true
logic(::Branch{O,L}) where {O, L<:AbstractLogic} = L

isopen(::Branch) = false

convert(::Type{<:AbstractModel{F1}}, m::Branch{F2, L, FIM}) where {F1, F2, L, FIM} = Branch{F1, L, FIM}(m)

check(m::Branch, i::AbstractInstance) = check(antecedent(m), i)
apply(m::Branch, d::Union{AbstractInstance, AbstractDataset}) = check(antecedent(m), d) ? apply(positive_consequent(m), d) : apply(negative_consequent(m), d)

"""
A *decision list* (or *decision table*, or *rule-based model*) is a symbolic model that has the form:

    IF (antecedent_1)     THEN (consequent_1)
    ELSEIF (antecedent_2) THEN (consequent_2)
    ...
    ELSEIF (antecedent_n) THEN (consequent_n)
    ELSE (consequent_default) END

where the antecedents are logical formulas and the consequents are the feasible
local outcomes of the block.

This model has the classical operational semantics of an IF-ELSEIF-ELSE block, where the
antecedents are evaluated in order, and a consequent is returned as soon as a valid antecedent is found,
(or when the computation reaches the ELSE clause).

In Sole, a `DecisionList{O, L<:AbstractLogic, FIM<:AbstractModel{<:O}}` encodes
this structure as a vector `rules::Vector{<:Rule{O,L,FIM}}`, plus a default consequent value `default_consequent::O`.
Note that `FIM` refers to the Feasible Inner Models (`FIM`) allowed in the sub-tree (see also
[`ConstrainedModel`](@ref)).

It also includes an `info::NamedTuple` for storing additional information.

See also [`Rule`](@ref), [`ConstrainedModel`](@ref), [`DecisionTree`](@ref), [`AbstractModel`](@ref).
"""

struct DecisionList{O, L<:AbstractLogic, FIM<:AbstractModel{OO where OO<:O}} <: ConstrainedModel{O, FIM}
    rules::Vector{Rule{<:O,L}}
    # rules::Vector{typeintersect(Rule{<:O,L},FIM)}
    # rules::Vector{typeintersect(Rule{<:O,L},M where M<:FIM)}
    # rules::Vector{M} where {M<:Rule{<:O,L}}
    # rules::Vector{M where {M<:Rule{<:O,L},M<:FIM}}
    # rules::Vector{<:FIM}
    default_consequent::FIM # TODO fix error maybe with AbstractModel/AbstractModel{OO}?
    info::NamedTuple

    function DecisionList{O, L, FIM}(
        rules::Vector{<:Rule},
        default_consequent::Any,
        info::NamedTuple = (;),
    ) where {O, L<:AbstractLogic, FIM<:AbstractModel{OO where OO<:O}}
        default_consequent = wrap(default_consequent, FIM)
        check_model_constraints.(DecisionList{O}, typeof.(rules), FIM)
        # check_model_constraints.(DecisionList{O}, typeof.(consequent.(rules)), FIM) TODO remove?
        check_model_constraints(DecisionList{O}, typeof(default_consequent), FIM)
        new{O,L,FIM}(rules, default_consequent, info)
    end

    function DecisionList{O, L}(
        rules::Vector{<:Rule},
        default_consequent::Any,
        info::NamedTuple = (;),
    ) where {O, L<:AbstractLogic}
        FIM = AbstractModel{O}
        default_consequent = wrap(default_consequent, FIM)
        new{O,L,AbstractModel{O}}(rules, default_consequent, info)
    end

    function DecisionList{O}(
        rules::Vector{<:Rule{<:Any,L}},
        default_consequent::Any,
        info::NamedTuple = (;),
    ) where {O, L<:AbstractLogic}
        FIM = AbstractModel{O}
        default_consequent = wrap(default_consequent, FIM)
        new{O,L,AbstractModel{O}}(rules, default_consequent, info)
    end

    function DecisionList(
        rules::Vector{<:Rule{<:Any,L}},
        default_consequent::Any,
        info::NamedTuple = (;),
    ) where {L<:AbstractLogic}
        default_consequent = wrap(default_consequent)
        F1 = outcometype(default_consequent)
        Fs = outcometype.(rules)
        O = Union{F1, Fs...}
        FIM = AbstractModel{O}
        # TODO fix this structure. Doesn't work properly.
        # println("1")
        # println(eltype(rules))
        # println(T where T<:Rule{<:O,L,<:AbstractModel{OO where OO<:O}})
        # println("1")
        # println(typeof(rules))
        # println(Vector{<:Rule{<:O,L,<:AbstractModel{OO where OO<:O}}})
        # # rules = Vector{Rule{<:O,L,<:AbstractModel{OO where OO<:O}}}(rules)
        # rules = Vector{Rule{<:O,L,<:AbstractModel{<:O}}}(rules)
        # println("1")
        new{O,L,AbstractModel{O}}(rules, default_consequent, info)
    end

    function DecisionList{O, L, FIM}(m::DecisionList) where {O, L<:AbstractLogic, FIM<:AbstractModel{OO where OO<:O}}
        DecisionList{O, L, FIM}(m.rules, m.default_consequent, m.info)
    end

    function DecisionList(m::DecisionList{O, L, FIM}) where {O, L<:AbstractLogic, FIM<:AbstractModel{OO where OO<:O}}
        DecisionList{O, L, FIM}(m)
    end
end

rules(m::DecisionList) = m.rules
default_consequent(m::DecisionList) = m.default_consequent

issymbolic(::DecisionList) = true
logic(::DecisionList{O,L}) where {O, L<:AbstractLogic} = L

isopen(::DecisionList) = false

convert(::Type{<:AbstractModel{F1}}, m::DecisionList{F2, L, FIM}) where {F1, F2, L, FIM} = DecisionList{F1, L, FIM}(m)

function apply(m::DecisionList, i::AbstractInstance)
    for rule in rules(m)
        if check(m, i)
            return consequent(rule)
        end
    end
    default_consequent(m)
end

"""
A `rule cascade` is a symbolic model that consists of a nested structure of IF-THEN blocks:

    IF (antecedent_1) THEN
        IF (antecedent_2) THEN
            ...
                IF (antecedent_n) THEN
                    (consequent)
                END
            ...
        END
    END

where the antecedents are logical formulas and the consequent is the feasible
local outcome of the block.

In Sole, this logic can be instantiated as a `RuleCascade{O, L<:AbstractLogic, FFM<:FinalModel{<:O}}`,
A `RuleCascade` encodes this logic by wrapping an object `antecedents::Vector{Formula{L}}`
and a `consequent::FFM`.

It also includes an `info::NamedTuple` for storing additional information.

See also [`Rule`](@ref), [`ConstrainedModel`](@ref), [`DecisionList`](@ref), [`AbstractModel`](@ref).
"""
struct RuleCascade{O, L<:AbstractLogic, FIM<:AbstractModel{OO where OO<:O}} <: ConstrainedModel{O, FIM}
    antecedents::Vector{Formula{L}}
    consequent::FIM
    info::NamedTuple

    function RuleCascade{O, L, FIM}(
        antecedents::Vector{Formula{L}},
        consequent::Any,
        info::NamedTuple = (;),
    ) where {O, L<:AbstractLogic, FIM<:AbstractModel{OO where OO<:O}}
        consequent = wrap(consequent, FIM)
        check_model_constraints(RuleCascade{O}, typeof(consequent), FIM)
        new{O,L,FIM}(antecedents, consequent, info)
    end

    function RuleCascade{O, L}(
        antecedents::Vector{Formula{L}},
        consequent::Any,
        info::NamedTuple = (;),
    ) where {O, L<:AbstractLogic}
        FIM = AbstractModel{O}
        new{O,L,AbstractModel{O}}(antecedents, wrap(consequent, FIM), info)
    end

    function RuleCascade{O}(
        antecedents::Vector{Formula{L}},
        consequent::Any,
        info::NamedTuple = (;),
    ) where {O, L<:AbstractLogic}
        FIM = AbstractModel{O}
        new{O,L,AbstractModel{O}}(antecedents, wrap(consequent, FIM), info)
    end

    function RuleCascade(
        antecedents::Vector{Formula{L}},
        consequent::Any,
        info::NamedTuple = (;),
    ) where {L<:AbstractLogic}
        consequent = wrap(consequent)
        O = outcometype(consequent)
        FIM = AbstractModel{O}
        new{O,L,AbstractModel{O}}(antecedents, consequent, info)
    end

    function RuleCascade{O, L, FIM}(m::RuleCascade) where {O, L<:AbstractLogic, FIM<:AbstractModel{OO where OO<:O}}
        RuleCascade{O, L, FIM}(m.antecedents, m.consequent, m.info)
    end

    function RuleCascade(m::RuleCascade{O, L, FIM}) where {O, L<:AbstractLogic, FIM<:AbstractModel{OO where OO<:O}}
        RuleCascade{O, L, FIM}(m)
    end
end

antecedents(m::RuleCascade) = m.antecedents
consequent(m::RuleCascade) = m.consequent

issymbolic(::RuleCascade) = true
logic(::RuleCascade{O,L}) where {O, L<:AbstractLogic} = L

convert(::Type{<:AbstractModel{F1}}, m::RuleCascade{F2, L, FIM}) where {F1, F2, L, FIM} = RuleCascade{F1, L, FIM}(m)

function apply(m::RuleCascade, i::AbstractInstance)
    for antecedent in antecedents(m)
        if ! check(antecedent, i)
            return nothing
        end
    end
    consequent(m)
end

"""
A `decision tree` is a symbolic model that consists of a nested structure of IF-THEN-ELSE blocks:

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

where the antecedents are logical formulas and the consequents are the feasible
local outcomes of the block.

In Sole, this logic can be instantiated as a `DecisionTree{O, L<:AbstractLogic, FFM<:FinalModel{<:O}}`.
A `DecisionTree` simply wraps a constrained sub-tree of `Branch` and `FinalModel`s via a
field `root::Union{FFM,Branch{<:O,L,Union{Branch{<:O,L},FFM}}}`
IF-THEN block, but also more simply a consequent.

It also includes an `info::NamedTuple` for storing additional information.

See also [`DecisionTree`](@ref), [`MixedSymbolicModel`](@ref), [`DecisionList`](@ref), [`FinallyConstrainedModel`](@ref).
"""

struct DecisionTree{O, L<:AbstractLogic, FFM<:FinalModel{OO where OO<:O}} <: FinallyConstrainedModel{O, FFM}
    root::Union{FFM,ConstrainedModel{<:O,<:Union{Branch{<:O,L},FFM}}}
    info::NamedTuple
end
root(m::DecisionTree) = m.root

issymbolic(::DecisionTree) = true
logic(::DecisionTree{O,L}) where {O, L<:AbstractLogic} = L

isopen(::DecisionTree) = false

convert(::Type{<:AbstractModel{F1}}, m::DecisionTree{F2, L, FIM}) where {F1, F2, L, FIM} = DecisionTree{F1, L, FIM}(m)

apply(m::DecisionTree, i::AbstractInstance) = apply(root(m), i)

"""
A `mixed symbolic model` is a symbolic model that consists of a nested structure of IF-THEN-ELSE
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

where the antecedents are logical formulas and the consequents are the feasible
local outcomes of the block.

In Sole, this logic can be instantiated as a `MixedSymbolicModel{O, L<:AbstractLogic, FFM<:FinalModel{<:O}}`.
A `MixedSymbolicModel` simply wraps a constrained sub-tree of `DecisionList`s, `DecisionTree`s, and `FinalModel`s via a
field `root::Union{FFM,ConstrainedModel{O,<:Union{DecisionList{<:O,L},DecisionTree{<:O,L},FFM}}}`.

It also includes an `info::NamedTuple` for storing additional information.

See also [`MixedSymbolicModel`](@ref), [`DecisionTree`](@ref), [`DecisionList`](@ref), [`FinallyConstrainedModel`](@ref).
"""

struct MixedSymbolicModel{O, L<:AbstractLogic, FFM<:FinalModel{OO where OO<:O}} <: FinallyConstrainedModel{O, FFM}
    root::Union{FFM,ConstrainedModel{<:O,<:Union{DecisionList{<:O,L},DecisionTree{<:O,L},FFM}}}
    info::NamedTuple
end
root(m::MixedSymbolicModel) = m.root

issymbolic(::MixedSymbolicModel) = true
logic(::MixedSymbolicModel{O,L}) where {O, L<:AbstractLogic} = L

isopen(::MixedSymbolicModel) = false

convert(::Type{<:AbstractModel{F1}}, m::MixedSymbolicModel{F2, L, FIM}) where {F1, F2, L, FIM} = MixedSymbolicModel{F1, L, FIM}(m)

apply(m::MixedSymbolicModel, i::AbstractInstance) = apply(root(m), i)


############################################################################################
############################################################################################
############################################################################################

"""
    Convert a rule cascade in a rule
"""
function convert(::Type{Rule}, m::RuleCascade{O, L, FIM}) where {O, L<:AbstractLogic, FIM<:AbstractModel}
    Rule{O, L, FIM}(_antecedent(m), consequent(m), info(m))
end
function convert(::Type{R}, m::RuleCascade) where {R<:Rule}
    R(_antecedent(m), consequent(m), info(m))
end

function _antecedent(m::RuleCascade)
    antecedents = antecedents(m)
    if length(antecedents) == 0
        Formula(FNode(SoleLogics.TOP))
    else
        SoleLogics.CONJUNCTION(antecedents...)
    end
end


"""
Convert a rule in a rule cascade
TODO does this work? Probably this should not exist.
"""

function convert(::Type{RuleCascade}, rule::Rule)
    function convert_formula(node::FNode)
        if isleaf(node)
            return [Formula(node)]
        end

        return [
            convert_formula(leftchild(node))...,
            convert_formula(rightchild(node))...,
        ]
    end

    RuleCascade(convert_formula(tree(antecedent(rule))),consequent(rule))
end

############################################################################################
############################################################################################
############################################################################################

"""
Function for evaluating the antecedent of a rule
"""

function evaluate_antecedent(rule::Rule, X::AbstractDataset)
    evaluate_antecedent(antecedent(rule), X)
end

function evaluate_antecedent(antecedent::Formula{L}, X::AbstractDataset) where L<:Logic
    check(antecedent, X)
end

"""
Function for evaluating a rule
"""
function evaluate_rule(
    rule::Rule,
    X::AbstractDataset,
    Y::AbstractVector{<:FinalModel}
)
    # Antecedent satisfaction. For each instances in X:
    #  - `false` when not satisfiable,
    #  - `true` when satisfiable.
    ant_sat = evaluate_antecedent(antecedent(rule),X)

    # Indices of satisfiable instances
    idxs_sat = findall(ant_sat .== true)

    # Consequent satisfaction. For each instances in X:
    #  - `false` when not satisfiable,
    #  - `true` when satisfiable,
    #  - `nothing` when antecedent does not hold.
    cons_sat = begin
        cons_sat = Vector{Union{Bool, Nothing}}(fill(nothing, length(Y)))
        idxs_true = begin
            idx_cons = findall(consequent(rule) .== Y)
            intersect(idxs_sat,idx_cons)
        end
        idxs_false = begin
            idx_cons = findall(consequent(rule) .!= Y)
            intersect(idxs_sat,idx_cons)
        end
        cons_sat[idxs_true]  .= true
        cons_sat[idxs_false] .= false
        cons_sat
    end

    y_pred = begin
        y_pred = Vector{Union{FinalModel, Nothing}}(fill(nothing, length(Y)))
        y_pred[idxs_sat] .= consequent(rule)
        y_pred
    end

    return (;
        ant_sat   = ant_sat,
        idxs_sat  = idxs_sat,
        cons_sat  = cons_sat,
        y_pred    = y_pred,
    )
end

############################################################################################
############################################################################################
############################################################################################

"""
Length of the rule
"""

rule_length(rule::Rule) = rule_length(antecedent(rule))
rule_length(formula::Formula) = rule_length(tree(formula))

function rule_length(node::FNode)
    if isleaf(node)
        return 1
    else
        return ((isdefined(node,:leftchild) ? rule_length(leftchild(node)) : 0)
                    + (isdefined(node,:rightchild) ? rule_length(rightchild(node)) : 0))
    end
end

"""
Metrics of the rule
"""

function rule_metrics(
    rule::Rule,
    X::AbstractDataset,
    Y::AbstractVector{<:FinalModel}
)

    eval_result = evaluate_rule(rule, X, Y)
    n_instances = Base.size(X,1)
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

# Evaluation for single decision
# TODO
# function evaluate_decision(dec::Decision, X::MultiFrameModalDataset) end

############################################################################################
# Rule evaluation
############################################################################################

# # Evaluation for an antecedent

# evaluate_antecedent(antecedent::Formula{L}, X::MultiFrameModalDataset) where {L<:AbstractLogic} =
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
#     ant::Formula{L},
#     cons::Consequent,
#     X::MultiFrameModalDataset,
#     Y::AbstractVector{<:Consequent}
# ) where {L<:AbstractLogic} = evaluate_rule(extract_decisions(ant),cons,X,Y)

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
#         cons_sat = Vector{Union{Bool, Nothing}}(fill(nothing, length(Y)))
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
#         y_pred = Vector{Union{Consequent, Nothing}}(fill(nothing, length(Y)))
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

#     #     Computer the number of pairs in a rule (length of the rule)

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
