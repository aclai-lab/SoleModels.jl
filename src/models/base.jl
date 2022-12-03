
############################################################################################
# TODO move this stuff
############################################################################################
import SoleLogics: CONJUCTION
function SoleLogics.CONJUNCTION(formulas::Formula...)
    if length(formulas) > 2
        SoleLogics.CONJUNCTION(tree(formulas[1]),SoleLogics.CONJUNCTION(formulas[2:end]...))
    else
        SoleLogics.CONJUNCTION(tree(formulas[1]),tree(formulas[2]))
    end
end

function check(::Formula, ::AbstractInstance) end
function check(::Formula, ::AbstractDataset) end
############################################################################################

"""
A `FinalOutcome` is something that a model outputs.
"""
const FinalOutcome = Union{String,Number}

"""
A Machine Learning model (`AbstractModel`) is a mathematical model that outputs a `FinalOutcome` given an
instance object (i.e., a piece of data).
"""
abstract type AbstractModel{F <: FinalOutcome} end

"""
`outcome_type` simply returns the outcome type of the model
"""
outcome_type(m::AbstractModel{F}) where {F} = F
outcome_type(::Type{<:AbstractModel{F}}) where {F} = F

doc_open_model = """
An `AbstractModel{F}` is *closed* if it is always able to provide an outcome of type `F`.
Otherwise, the model can produce `nothing` as outcome and is referred to as *open*.
"""

"""
$(doc_open_model)
This behavior can be expressed via the `is_open` trait, which defaults to `true`:

    is_open(::AbstractModel) = true
"""
is_open(::AbstractModel) = true

"""
$(doc_open_model)
`output_type` leverages the `is_open` trait to provide the type for the outcome of a model:

    output_type(M::AbstractModel{F}) = is_open(M) ? Union{Nothing,F} : F

See also [`is_open`](@ref), [`AbstractModel`](@ref).
"""
output_type(m::AbstractModel{F}) where {F} = is_open(m) ? Union{Nothing,outcome_type(m)} : outcome_type(m)

"""
Any `AbstractModel` can be applied to an instance object or a dataset of instance objects.

See also [`AbstractModel`](@ref), [`AbstractInstance`](@ref), [`AbstractDataset`](@ref).
"""
apply(m::AbstractModel, i::AbstractInstance)::output_type(m) = error("Please, provide method apply(::$(typeof(m)), ::$(typeof(i)))")
apply(m::AbstractModel, d::AbstractDataset)::AbstractVector{<:output_type(m)} = map(i->apply(m, i), iterate_instances(d))


doc_symbolic = """
A `AbstractModel` is said to be `symbolic` when it is based on certain a logical language (or "logic",
see [`SoleLogics`](@ref) package).
Symbolic models provide a form of transparent and interpretable modeling.
"""

"""
$(doc_symbolic)
The `is_symbolic` trait, defaulted to `false` can be used to specify that a model is symbolic.

See also [`logic`](@ref), [`unroll_rules`](@ref), [`AbstractModel`](@ref).
"""
is_symbolic(::AbstractModel) = false

"""
$(doc_symbolic)
Every symbolic model must provide access to its corresponding `Logic` type via the `logic` trait.

See also [`is_symbolic`](@ref), [`AbstractModel`](@ref).
"""
logic(m::AbstractModel)::AbstractLogic = error(is_symbolic(m) ? "Please, provide method logic(::$(typeof(m))) ($(typeof(m)) is a symbolic model)." : "Models of type $(typeof(m)) are not symbolic, and thus have no logic associated.")

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
The `has_info` trait, defaulted to `true`, can be used to specify models that do not implement an
`info` field.
"""
has_info(::AbstractModel) = true

"""
$(doc_info)
The `info` getter function accesses this structure.
"""
info(m::AbstractModel) = has_info(m) ? m.info : error("Type $(typeof(m)) does not have an `info` field.")


############################################################################################
############################################################################################
############################################################################################

"""
A `FinalModel` is a model which outcomes do not depend on another model.
An `AbstractModel` can generally wrap other `AbstractModel`s. In such case, the outcome can 
depend on the inner models being applied on the instance object. Otherwise, the model is
considered final; that is, it is a leaf of a tree of `AbstractModel`s.
"""
abstract type FinalModel{F <: FinalOutcome} <: AbstractModel{F} end

# """
# TODO remove and simply use wrap?
# Since `FinalModel` rely on native Julia computation (e.g., a constant or a function),
# they should be easily instantiated; each subtype `M` of `FinalModel` should implement at
# least one `convert(::Type{M<:FinalModel{F}, ::T}` method (where `T` is any type).

# See also [`FinalModel`](@ref).
# """
# convert(::Type{M}, ::T) where {M<:FinalModel,T} = error("Please, provide method convert(::Type{$(M)}, ::$(T)).")

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
struct ConstantModel{F<:FinalOutcome} <: FinalModel{F}
    final_outcome::F
    info::NamedTuple

    function ConstantModel{F}(
        final_outcome::F,
        info::NamedTuple = (;),
    ) where {F<:FinalOutcome}
        new{F}(final_outcome, info)
    end

    function ConstantModel(
        final_outcome::F,
        info::NamedTuple = (;),
    ) where {F<:FinalOutcome}
        ConstantModel{F}(final_outcome, info)
    end

    function ConstantModel{F}(m::ConstantModel) where {F<:FinalOutcome}
        ConstantModel{F}(m.final_outcome, m.info)
    end

    function ConstantModel(m::ConstantModel)
        ConstantModel(m.final_outcome, m.info)
    end
end

convert(::Type{ConstantModel}, m::ConstantModel) = ConstantModel(m)
convert(::Type{ConstantModel{F}}, o::F) where {F} = ConstantModel{F}(o)
convert(::Type{<:AbstractModel{F1}}, m::ConstantModel) where {F1} = ConstantModel{F1}(m)

apply(m::ConstantModel, i::AbstractInstance) = m.final_outcome
apply(m::ConstantModel, d::AbstractDataset) = m.final_outcome

"""
A `FunctionModel` is a final model (`FinalModel`) that applies a native Julia `Function`
in order to compute the outcome. Over efficiency concerns, it is mandatory to make explicit
the output type `F` by wrapping the `Function` into a `FunctionWrapper{F}`

See also [`ConstantModel`](@ref), [`FunctionWrapper`](@ref), [`FinalModel`](@ref).
"""
struct FunctionModel{F<:FinalOutcome} <: FinalModel{F}
    f::FunctionWrapper{F}
    info::NamedTuple

    function FunctionModel{F}(
        f::FunctionWrapper{F},
        info::NamedTuple = (;),
    ) where {F<:FinalOutcome}
        new{F}(f, info)
    end

    function FunctionModel(
        f::FunctionWrapper{F},
        info::NamedTuple = (;),
    ) where {F<:FinalOutcome}
        FunctionModel{F}(f, info)
    end

    function FunctionModel{F}(m::FunctionModel) where {F<:FinalOutcome}
        FunctionModel{F}(m.f, m.info)
    end

    function FunctionModel(m::FunctionModel)
        FunctionModel(m.f, m.info)
    end
end

convert(::Type{FunctionModel}, m::FunctionModel) = FunctionModel(m)
convert(::Type{FunctionModel{F}}, f::FunctionWrapper) where {F} = FunctionModel{F}(f)
convert(::Type{FunctionModel{F}}, f::Function) where {F} = error("Please, wrap Julia functions in FunctionWrappers{F}, where F is their return type.")
# function convert(::Type{FunctionModel{F}}, f::Function) where {F<:FinalOutcome}
#     @warn "Over efficiency concerns, please consider wrapping Function's into FunctionWrapper's."
#     FunctionModel{F}(f)
# end
convert(::Type{<:AbstractModel{F1}}, m::FunctionModel) where {F1} = FunctionModel{F1}(m)


apply(m::FunctionModel, i::AbstractInstance) = m.f(i)

"""
This function is used to specify the default `FinalModel` used for wrapping native computation. 
The default behavior is the following: `Function`s and `FunctionWrapper`s are wrapped into a
`FunctionModel`, while every other `FinalOutcome` object is wrapped into a `ConstantModel`.
When called on an `AbstractModel`, the model is simply returned (without wrapping it).
An error is thrown when wrapping objects of all other types.

See also [`ConstantModel`](@ref), [`FunctionModel`](@ref), [`ConstrainedModel`](@ref), [`FinalModel`](@ref).
"""
wrap(o::Any, FIM::Type{<:AbstractModel}) = convert(FIM, wrap(o))
wrap(o::Any) = error("Can't wrap object of type $(o).")
wrap(m::AbstractModel) = m
wrap(o::F) where {F<:FinalOutcome} = convert(ConstantModel{F}, o)
wrap(o::Union{Function,FunctionWrapper{F}}) where {F<:FinalOutcome} = convert(FunctionModel{F}, o)

############################################################################################
############################################################################################
############################################################################################

"""
An `AbstractModel` can wrap another `AbstractModel`, and use it to compute the outcome.
As such, an `AbstractModel` can actually be the result of a composition of many models,
and enclose a *tree* of `AbstractModel`s (with `FinalModel`s at the leaves).
In order to typebound the Feasible Inner Models (`FIM`) allowed in the sub-tree,
the `ConstrainedModel` type is introduced:

    ConstrainedModel{F <: FinalOutcome, FIM <: AbstractModel{FF where FF<:F}} <: AbstractModel{F}

For example, `ConstrainedModel{String, Union{Branch{String},ConstantModel{String}}}` supertypes models
that with `String` outcomes that make use of `Branch{String}` and `ConstantModel{String}`
(essentially, a decision trees with `String`s at the leaves).

See also [`FinalModel`](@ref), [`AbstractModel`](@ref).
"""
abstract type ConstrainedModel{F <: FinalOutcome, FIM <: AbstractModel{FF where FF<:F}} <: AbstractModel{F} end

"""
This function is used when constructing `ConstrainedModel`s to check that the inner
models satisfy the desired type constraints.

See also [`ConstrainedModel`](@ref), [`Rule`](@ref), [`Branch`](@ref).
"""
function check_model_constraints(::Type{M}, IM::Type{<:AbstractModel{IF}}, FIM::Type{<:AbstractModel{<:F}}) where {F, IF, M<:AbstractModel{F}}
    @assert IF <: F "Can't instantiate $(M) with inner model outcome_type $(IF)! $(IF) <: $(F) should hold."
    # TODO now it's kinda implicit, but one day maybe not:
    # @assert IM <: FIM "Can't instantiate $(M) with inner model $(IM))! $(IM) <: $(FIM) should hold."
    if ! (IM<:FinalModel{<:F})
        @assert IM<:ConstrainedModel{F,FIM} "ConstrainedModels require IM<:ConstrainedModel{F,FIM}, but $(IM) does not subtype $(ConstrainedModel{F,FIM})"
    end
end

"""
Some `ConstrainedModel`s (e.g., decision trees) inherently rely on specific `ConstrainedModel` types.
In such cases, the bounding type parameter only serves to constrain the type of `FinalModel`s in the sub-tree:

    FinallyConstrainedModel{F <: FinalOutcome, FFM <: FinalModel{FF where FF<:F}} <: ConstrainedModel{F, FFM}

For example, `FinallyConstrainedModel{String, ConstantModel{String}}` supertypes implementations
of decision lists with `String`s as consequents, and decision trees with `String`s at the leaves.

See also [`ConstrainedModel`](@ref), [`FinalModel`](@ref), [`DecisionList`](@ref), [`DecisionTree`](@ref).
"""
abstract type FinallyConstrainedModel{F <: FinalOutcome, FFM <: FinalModel{FF where FF<:F}} <: ConstrainedModel{F, FFM} end

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
in order to obtain a `FinalOutcome`.
"""


"""
A *rule* is one of the fundamental building blocks of symbolic modeling, and has the form:

    IF (antecedent) THEN (consequent) END

where the antecedent is a logical formula and the consequent is the outcome of the block.


In Sole, a `Rule{F<:FinalOutcome, L<:AbstractLogic}` wraps an `antecedent::Formula{L}`, that is, a formula of a given logic L,
and a `consequent::AbstractModel{<:F}` that is to be applied to obtain an outcome.

It also includes an `info::NamedTuple` for storing additional information.

# Extended help
Being a `ConstrainedModel`, this struct is actually defined as:

    struct Rule{F<:FinalOutcome, L<:AbstractLogic, FIM<:AbstractModel{<:F}} <: ConstrainedModel{F, FIM}

where `FIM` refers to the Feasible Inner Models (`FIM`) allowed in the sub-tree.

See also [`Branch`](@ref), [`ConstrainedModel`](@ref), [`AbstractModel`](@ref).
"""
struct Rule{F<:FinalOutcome, L<:AbstractLogic, FIM<:AbstractModel{FF where FF<:F}} <: ConstrainedModel{F, FIM}
    antecedent::Formula{L}
    consequent::FIM
    # consequent::AbstractModel{<:F} #TODO test FIM in check_model_constraints
    info::NamedTuple

    function Rule{F, L, FIM}(
        antecedent::Formula{L},
        consequent::Any,
        info::NamedTuple = (;),
    ) where {F<:FinalOutcome, L<:AbstractLogic, FIM<:AbstractModel{FF where FF<:F}}
        consequent = wrap(consequent, FIM)
        check_model_constraints(Rule{F}, typeof(consequent), FIM)
        new{F,L,FIM}(antecedent, consequent, info)
    end

    function Rule{F, L}(
        antecedent::Formula{L},
        consequent::Any,
        info::NamedTuple = (;),
    ) where {F<:FinalOutcome, L<:AbstractLogic}
        FIM = AbstractModel{F}
        new{F,L,FIM}(antecedent, wrap(consequent,FIM), info)
    end

    function Rule{F}(
        antecedent::Formula{L},
        consequent::Any,
        info::NamedTuple = (;),
    ) where {F<:FinalOutcome, L<:AbstractLogic}
        FIM = AbstractModel{F}
        new{F,L,FIM}(antecedent, wrap(consequent,FIM), info)
    end

    function Rule(
        antecedent::Formula{L},
        consequent::Any,
        info::NamedTuple = (;),
    ) where {L<:AbstractLogic}
        consequent = wrap(consequent)
        F = outcome_type(consequent)
        FIM = AbstractModel{F}
        new{F,L,FIM}(antecedent, consequent, info)
    end

    function Rule{F, L, FIM}(m::Rule) where {F<:FinalOutcome, L<:AbstractLogic, FIM<:AbstractModel{FF where FF<:F}}
        Rule{F, L, FIM}(m.antecedent, m.consequent, m.info)
    end

    function Rule(m::Rule{F, L, FIM}) where {F<:FinalOutcome, L<:AbstractLogic, FIM<:AbstractModel{FF where FF<:F}}
        Rule{F, L, FIM}(m)
    end
end

antecedent(m::Rule) = m.antecedent
consequent(m::Rule) = m.consequent

is_symbolic(::Rule) = true
logic(::Rule{F,L}) where {F, L} = L

convert(::Type{<:AbstractModel{F1}}, m::Rule{F2, L, FIM}) where {F1, F2, L, FIM} = Rule{F1, L, FIM}(m)

check(m::Rule, id) = check(m.antecedent, id)
apply(m::Rule, id) = check(m.antecedent, id) ? apply(m.consequent, id) : nothing

outcome_type(::Type{<:Rule{F}}) where {F} = F

"""
A *branch* is one of the fundamental building blocks of symbolic modeling, and has the form:

    IF (antecedent) THEN (consequent_1) ELSE (consequent_2) END

where the antecedent is a logical formula and the consequents are the feasible outcomes of the block.

In Sole, a `Branch{F<:FinalOutcome, L<:AbstractLogic}` wraps an `antecedent::Formula{L}`, that is, a formula of a given logic L,
and two `AbstractModel{<:F}`s (*positive_consequent*, *negative_consequent*) that are to be
applied to obtain an outcome.

It also includes an `info::NamedTuple` for storing additional information.

# Extended help
Being a `ConstrainedModel`, this struct is actually defined as:

    struct Branch{F<:FinalOutcome, L<:AbstractLogic, FIM<:AbstractModel{<:F}} <: ConstrainedModel{F, FIM}

where `FIM` refers to the Feasible Inner Models (`FIM`) allowed in the sub-tree.

See also [`Rule`](@ref), [`ConstrainedModel`](@ref), [`AbstractModel`](@ref).
"""
struct Branch{F<:FinalOutcome, L<:AbstractLogic, FIM<:AbstractModel{FF where FF<:F}} <: ConstrainedModel{F, FIM}
    antecedent::Formula{L}
    positive_consequent::FIM
    negative_consequent::FIM
    info::NamedTuple

    function Branch{F, L, FIM}(
        antecedent::Formula{L},
        positive_consequent::Any,
        negative_consequent::Any,
        info::NamedTuple = (;),
    ) where {F<:FinalOutcome, L<:AbstractLogic, FIM<:AbstractModel{FF where FF<:F}}
        positive_consequent = wrap(positive_consequent, FIM)
        negative_consequent = wrap(negative_consequent, FIM)
        check_model_constraints(Branch{F}, typeof(positive_consequent), FIM)
        check_model_constraints(Branch{F}, typeof(negative_consequent), FIM)
        new{F,L,FIM}(antecedent, positive_consequent, negative_consequent, info)
    end

    function Branch{F, L}(
        antecedent::Formula{L},
        positive_consequent::Any,
        negative_consequent::Any,
        info::NamedTuple = (;),
    ) where {F<:FinalOutcome, L<:AbstractLogic}
        FIM = AbstractModel{F}
        new{F,L,FIM}(antecedent, wrap(positive_consequent, FIM), wrap(negative_consequent, FIM), info)
    end

    function Branch{F}(
        antecedent::Formula{L},
        positive_consequent::Any,
        negative_consequent::Any,
        info::NamedTuple = (;),
    ) where {F<:FinalOutcome, L<:AbstractLogic}
        FIM = AbstractModel{F}
        new{F,L,FIM}(antecedent, wrap(positive_consequent, FIM), wrap(negative_consequent, FIM), info)
    end

    function Branch(
        antecedent::Formula{L},
        positive_consequent::Any,
        negative_consequent::Any,
        info::NamedTuple = (;),
    ) where {L<:AbstractLogic}
        positive_consequent = wrap(positive_consequent)
        negative_consequent = wrap(negative_consequent)
        F1 = outcome_type(positive_consequent)
        F2 = outcome_type(negative_consequent)
        F = Union{F1, F2}
        FIM = AbstractModel{F}
        new{F,L,FIM}(antecedent, positive_consequent, negative_consequent, info)
    end

    function Branch(
        antecedent::Formula{L},
        (positive_consequent, negative_consequent)::Tuple{Any,Any},
        info::NamedTuple = (;),
    ) where {L<:AbstractLogic}
        Branch(antecedent, positive_consequent, negative_consequent, info)
    end

    function Branch{F, L, FIM}(m::Branch) where {F<:FinalOutcome, L<:AbstractLogic, FIM<:AbstractModel{FF where FF<:F}}
        Branch{F, L, FIM}(m.antecedent, m.positive_consequent, m.negative_consequent, m.info)
    end

    function Branch(m::Branch{F, L, FIM}) where {F<:FinalOutcome, L<:AbstractLogic, FIM<:AbstractModel{FF where FF<:F}}
        Branch{F, L, FIM}(m)
    end
end

antecedent(m::Branch) = m.antecedent
positive_consequent(m::Branch) = m.positive_consequent
negative_consequent(m::Branch) = m.negative_consequent

is_symbolic(::Branch) = true
logic(::Branch{F,L}) where {F<:FinalOutcome, L<:AbstractLogic} = L

is_open(::Branch) = false

convert(::Type{<:AbstractModel{F1}}, m::Branch{F2, L, FIM}) where {F1, F2, L, FIM} = Branch{F1, L, FIM}(m)

check(m::Branch, i::AbstractInstance) = check(m.antecedent, i)
apply(m::Branch, d::Union{AbstractInstance,AbstractDataset}) = check(m.antecedent, d) ? apply(m.positive_consequent, d) : apply(m.negative_consequent, d)

"""
A *decision list* (or *decision table*, or *rule-based model*) is a symbolic model that has the form:

    IF (antecedent_1)     THEN (consequent_1)
    ELSEIF (antecedent_2) THEN (consequent_2)
    ...
    ELSEIF (antecedent_n) THEN (consequent_n)
    ELSE (consequent_default) END

where the antecedents are logical formulas and the consequents are the feasible outcomes of the block.

This model has the classical operational semantics of an IF-ELSEIF-ELSE block, where the
antecedents are evaluated in order, and a consequent is returned as soon as a valid antecedent is found,
(or when the computation reaches the ELSE clause).

In Sole, a `DecisionList{F<:FinalOutcome, L<:AbstractLogic, FIM<:AbstractModel{<:F}}` encodes
this structure as a vector `rules::Vector{<:Rule{F,L,FIM}}`, plus a default consequent value `default_consequent::F`.
Note that `FIM` refers to the Feasible Inner Models (`FIM`) allowed in the sub-tree (see also
[`ConstrainedModel`](@ref)).

It also includes an `info::NamedTuple` for storing additional information.

See also [`Rule`](@ref), [`ConstrainedModel`](@ref), [`DecisionTree`](@ref), [`AbstractModel`](@ref).
"""

struct DecisionList{F<:FinalOutcome, L<:AbstractLogic, FIM<:AbstractModel{FF where FF<:F}} <: ConstrainedModel{F, FIM}
    rules::Vector{Rule{<:F,L}}
    # rules::Vector{typeintersect(Rule{<:F,L},FIM)}
    # rules::Vector{typeintersect(Rule{<:F,L},M where M<:FIM)}
    # rules::Vector{M} where {M<:Rule{<:F,L}}
    # rules::Vector{M where {M<:Rule{<:F,L},M<:FIM}}
    # rules::Vector{<:FIM}
    default_consequent::FIM # TODO fix error maybe with AbstractModel/AbstractModel{FF}?
    info::NamedTuple

    function DecisionList{F, L, FIM}(
        rules::Vector{<:Rule},
        default_consequent::Any,
        info::NamedTuple = (;),
    ) where {F<:FinalOutcome, L<:AbstractLogic, FIM<:AbstractModel{FF where FF<:F}}
        default_consequent = wrap(default_consequent, FIM)
        check_model_constraints.(DecisionList{F}, typeof.(rules), FIM)
        # check_model_constraints.(DecisionList{F}, typeof.(consequent.(rules)), FIM) TODO remove?
        check_model_constraints(DecisionList{F}, typeof(default_consequent), FIM)
        new{F,L,FIM}(rules, default_consequent, info)
    end

    function DecisionList{F, L}(
        rules::Vector{<:Rule},
        default_consequent::Any,
        info::NamedTuple = (;),
    ) where {F<:FinalOutcome, L<:AbstractLogic}
        FIM = AbstractModel{F}
        default_consequent = wrap(default_consequent, FIM)
        new{F,L,AbstractModel{F}}(rules, default_consequent, info)
    end

    function DecisionList{F}(
        rules::Vector{<:Rule{<:FinalOutcome,L}},
        default_consequent::Any,
        info::NamedTuple = (;),
    ) where {F<:FinalOutcome, L<:AbstractLogic}
        FIM = AbstractModel{F}
        default_consequent = wrap(default_consequent, FIM)
        new{F,L,AbstractModel{F}}(rules, default_consequent, info)
    end

    function DecisionList(
        rules::Vector{<:Rule{<:FinalOutcome,L}},
        default_consequent::Any,
        info::NamedTuple = (;),
    ) where {L<:AbstractLogic}
        default_consequent = wrap(default_consequent)
        F1 = outcome_type(default_consequent)
        Fs = outcome_type.(rules)
        F = Union{F1, Fs...}
        FIM = AbstractModel{F}
        # TODO fix this structure. Doesn't work properly.
        # println("1")
        # println(eltype(rules))
        # println(T where T<:Rule{<:F,L,<:AbstractModel{FF where FF<:F}})
        # println("1")
        # println(typeof(rules))
        # println(Vector{<:Rule{<:F,L,<:AbstractModel{FF where FF<:F}}})
        # # rules = Vector{Rule{<:F,L,<:AbstractModel{FF where FF<:F}}}(rules)
        # rules = Vector{Rule{<:F,L,<:AbstractModel{<:F}}}(rules)
        # println("1")
        new{F,L,AbstractModel{F}}(rules, default_consequent, info)
    end

    function DecisionList{F, L, FIM}(m::DecisionList) where {F<:FinalOutcome, L<:AbstractLogic, FIM<:AbstractModel{FF where FF<:F}}
        DecisionList{F, L, FIM}(m.rules, m.default_consequent, m.info)
    end

    function DecisionList(m::DecisionList{F, L, FIM}) where {F<:FinalOutcome, L<:AbstractLogic, FIM<:AbstractModel{FF where FF<:F}}
        DecisionList{F, L, FIM}(m)
    end
end

rules(m::DecisionList) = m.rules
default_consequent(m::DecisionList) = m.default_consequent

is_symbolic(::DecisionList) = true
logic(::DecisionList{F,L}) where {F<:FinalOutcome, L<:AbstractLogic} = L

is_open(::DecisionList) = false

convert(::Type{<:AbstractModel{F1}}, m::DecisionList{F2, L, FIM}) where {F1, F2, L, FIM} = DecisionList{F1, L, FIM}(m)

function apply(m::DecisionList, i::AbstractInstance)
    for rule in m.rules
        if check(m, i)
            return rule.consequent
        end
    end
    m.default_consequent
end

"""
A `rule nest` is a symbolic model that consists of a nested structure of IF-THEN blocks:

    IF (antecedent_1) THEN
        IF (antecedent_2) THEN
            ...
                IF (antecedent_n) THEN
                    (consequent)
                END
            ...
        END
    END

where the antecedents are logical formulas and the consequent is the feasible outcome of the block.

In Sole, this logic can be instantiated as a `RuleCascade{F<:FinalOutcome, L<:AbstractLogic, FFM<:FinalModel{<:F}}`,
A `RuleCascade` encodes this logic by wrapping an object `antecedents::Vector{Formula{L}}`
and a `consequent::FFM`.

It also includes an `info::NamedTuple` for storing additional information.

See also [`Rule`](@ref), [`ConstrainedModel`](@ref), [`DecisionList`](@ref), [`AbstractModel`](@ref).
"""
struct RuleCascade{F<:FinalOutcome, L<:AbstractLogic, FIM<:AbstractModel{FF where FF<:F}} <: ConstrainedModel{F, FIM}
    antecedents::Vector{Formula{L}}
    consequent::FIM
    info::NamedTuple

    function RuleCascade{F, L, FIM}(
        antecedents::Vector{Formula{L}},
        consequent::Any,
        info::NamedTuple = (;),
    ) where {F<:FinalOutcome, L<:AbstractLogic, FIM<:AbstractModel{FF where FF<:F}}
        consequent = wrap(consequent, FIM)
        check_model_constraints(RuleCascade{F}, typeof(consequent), FIM)
        new{F,L,FIM}(antecedents, consequent, info)
    end

    function RuleCascade{F, L}(
        antecedents::Vector{Formula{L}},
        consequent::Any,
        info::NamedTuple = (;),
    ) where {F<:FinalOutcome, L<:AbstractLogic}
        FIM = AbstractModel{F}
        new{F,L,AbstractModel{F}}(antecedents, wrap(consequent, FIM), info)
    end

    function RuleCascade{F}(
        antecedents::Vector{Formula{L}},
        consequent::Any,
        info::NamedTuple = (;),
    ) where {F<:FinalOutcome, L<:AbstractLogic}
        FIM = AbstractModel{F}
        new{F,L,AbstractModel{F}}(antecedents, wrap(consequent, FIM), info)
    end

    function RuleCascade(
        antecedents::Vector{Formula{L}},
        consequent::Any,
        info::NamedTuple = (;),
    ) where {L<:AbstractLogic}
        consequent = wrap(consequent)
        F = outcome_type(consequent)
        FIM = AbstractModel{F}
        new{F,L,AbstractModel{F}}(antecedents, consequent, info)
    end

    function RuleCascade{F, L, FIM}(m::RuleCascade) where {F<:FinalOutcome, L<:AbstractLogic, FIM<:AbstractModel{FF where FF<:F}}
        RuleCascade{F, L, FIM}(m.antecedents, m.consequent, m.info)
    end

    function RuleCascade(m::RuleCascade{F, L, FIM}) where {F<:FinalOutcome, L<:AbstractLogic, FIM<:AbstractModel{FF where FF<:F}}
        RuleCascade{F, L, FIM}(m)
    end
end

antecedents(m::RuleCascade) = m.antecedents
consequent(m::RuleCascade) = m.consequent

is_symbolic(::RuleCascade) = true
logic(::RuleCascade{F,L}) where {F<:FinalOutcome, L<:AbstractLogic} = L

convert(::Type{<:AbstractModel{F1}}, m::RuleCascade{F2, L, FIM}) where {F1, F2, L, FIM} = RuleCascade{F1, L, FIM}(m)

function apply(m::RuleCascade, i::AbstractInstance)
    for antecedent in m.antecedents
        if ! check(antecedent, i)
            return nothing
        end
    end
    m.consequent
end

function to_rule(m::RuleCascade{F, L, FIM}) where {F<:FinalOutcome, L<:AbstractLogic, FIM<:AbstractModel}
    Rule{F,L,FIM}(SoleLogics.CONJUNCTION(m.antecedents...), m.consequent, m.info)
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

where the antecedents are logical formulas and the consequents are the feasible outcomes of the block.

In Sole, this logic can be instantiated as a `DecisionTree{F<:FinalOutcome, L<:AbstractLogic, FFM<:FinalModel{<:F}}`.
A `DecisionTree` simply wraps a constrained sub-tree of `Branch` and `FinalModel`s via a
field `root::Union{FFM,Branch{<:F,L,Union{Branch{<:F,L},FFM}}}`
IF-THEN block, but also more simply a consequent.

It also includes an `info::NamedTuple` for storing additional information.

See also [`DecisionTree`](@ref), [`MixedSymbolicModel`](@ref), [`DecisionList`](@ref), [`FinallyConstrainedModel`](@ref).
"""

struct DecisionTree{F<:FinalOutcome, L<:AbstractLogic, FFM<:FinalModel{FF where FF<:F}} <: FinallyConstrainedModel{F, FFM}
    root::Union{FFM,ConstrainedModel{<:F,<:Union{Branch{<:F,L},FFM}}}
    info::NamedTuple
end
root(m::DecisionTree) = m.root

is_symbolic(::DecisionTree) = true
logic(::DecisionTree{F,L}) where {F<:FinalOutcome, L<:AbstractLogic} = L

is_open(::DecisionTree) = false

convert(::Type{<:AbstractModel{F1}}, m::DecisionTree{F2, L, FIM}) where {F1, F2, L, FIM} = DecisionTree{F1, L, FIM}(m)

apply(m::DecisionTree, i::AbstractInstance) = apply(m.root, i)

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

where the antecedents are logical formulas and the consequents are the feasible outcomes of the block.

In Sole, this logic can be instantiated as a `MixedSymbolicModel{F<:FinalOutcome, L<:AbstractLogic, FFM<:FinalModel{<:F}}`.
A `MixedSymbolicModel` simply wraps a constrained sub-tree of `DecisionList`s, `DecisionTree`s, and `FinalModel`s via a
field `root::Union{FFM,ConstrainedModel{F,<:Union{DecisionList{<:F,L},DecisionTree{<:F,L},FFM}}}`.

It also includes an `info::NamedTuple` for storing additional information.

See also [`MixedSymbolicModel`](@ref), [`DecisionTree`](@ref), [`DecisionList`](@ref), [`FinallyConstrainedModel`](@ref).
"""

struct MixedSymbolicModel{F<:FinalOutcome, L<:AbstractLogic, FFM<:FinalModel{FF where FF<:F}} <: FinallyConstrainedModel{F, FFM}
    root::Union{FFM,ConstrainedModel{<:F,<:Union{DecisionList{<:F,L},DecisionTree{<:F,L},FFM}}}
    info::NamedTuple
end
root(m::MixedSymbolicModel) = m.root

is_symbolic(::MixedSymbolicModel) = true
logic(::MixedSymbolicModel{F,L}) where {F<:FinalOutcome, L<:AbstractLogic} = L

is_open(::MixedSymbolicModel) = false

convert(::Type{<:AbstractModel{F1}}, m::MixedSymbolicModel{F2, L, FIM}) where {F1, F2, L, FIM} = MixedSymbolicModel{F1, L, FIM}(m)

apply(m::MixedSymbolicModel, i::AbstractInstance) = apply(m.root, i)

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
