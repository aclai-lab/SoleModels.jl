import Base: convert, length, getindex, isopen
import SoleLogics: check, syntaxstring
using SoleData: slice_dataset

# Util
typename(::Type{T}) where T = eval(nameof(T))

"""
    abstract type AbstractBooleanCondition end

A boolean condition is a condition that evaluates to a boolean truth value (`true`/`false`),
when checked on a logical interpretation.

See also
[`TrueCondition`](@ref),
[`LogicalTruthCondition`](@ref),
[`check`](@ref),
[`syntaxstring`](@ref).
"""
abstract type AbstractBooleanCondition end

function syntaxstring(c::AbstractBooleanCondition; kwargs...)
    error("Please, provide method syntaxstring(::$(typeof(c)); kwargs...).")
end

function Base.show(io::IO, c::AbstractBooleanCondition)
    print(io, "$(typeof(c))($(syntaxstring(c)))")
end

# Check on a boolean condition
function check(c::AbstractBooleanCondition, i::AbstractInterpretation, args...; kwargs...)
    error("Please, provide method check(::$(typeof(c))," *
        " i::$(typeof(i)), args...; kwargs...).")
end
function check(
    c::AbstractBooleanCondition,
    d::AbstractInterpretationSet,
    args...;
    kwargs...
)
    map(
        i_sample->check(c, slice_dataset(d, [i_sample]), args...; kwargs...)[1],
        1:nsamples(d)
    )
end

"""
    abstract type AbstractLogicalBooleanCondition <: AbstractBooleanCondition end

A boolean condition based on a formula of a given logic, that is
to be checked on a logical interpretation.

See also
[`formula`](@ref),
[`syntaxstring`](@ref),
[`check`](@ref),
[`AbstractBooleanCondition`](@ref).
"""
abstract type AbstractLogicalBooleanCondition <: AbstractBooleanCondition end

"""
    formula(c::AbstractLogicalBooleanCondition)::AbstractFormula

Returns the logical formula (see [`SoleLogics`](@ref) package) of a given
logical boolean condition.

See also
[`syntaxstring`](@ref),
[`AbstractLogicalBooleanCondition`](@ref).
"""
function formula(c::AbstractLogicalBooleanCondition)::AbstractFormula
    error("Please, provide method formula(::$(typeof(c))).")
end

function syntaxstring(c::AbstractLogicalBooleanCondition; kwargs...)
    syntaxstring(formula(c); kwargs...)
end

"""
    struct TrueCondition <: AbstractLogicalBooleanCondition end

A true condition is the boolean condition that always yields `true`.

See also
[`LogicalTruthCondition`](@ref),
[`AbstractLogicalBooleanCondition`](@ref).
"""
struct TrueCondition <: AbstractLogicalBooleanCondition end

formula(::TrueCondition) = SyntaxTree(⊤)
check(::TrueCondition, i::AbstractInterpretation, args...; kwargs...) = true
check(::TrueCondition, d::AbstractInterpretationSet, args...; kwargs...) =
    fill(true, nsamples(d))

"""
    struct LogicalTruthCondition{F<:AbstractFormula} <: AbstractLogicalBooleanCondition
        formula::F
    end

A boolean condition that, on a given logical interpretation,
a logical formula evaluates to the `top` of the logic's algebra.

See also
[`formula`](@ref),
[`AbstractLogicalBooleanCondition`](@ref).
"""
struct LogicalTruthCondition{F<:AbstractFormula} <: AbstractLogicalBooleanCondition
    formula::F

    function LogicalTruthCondition{F}(
        formula::F
    ) where {F<:AbstractFormula}
        new{F}(formula)
    end

    function LogicalTruthCondition(
        formula::F
    ) where {F<:AbstractFormula}
        LogicalTruthCondition{F}(formula)
    end
end

formula(c::LogicalTruthCondition) = c.formula

function check(c::LogicalTruthCondition, i::AbstractInterpretation, args...; kwargs...)
    tops(check(formula(c), i, args...; kwargs...))
end
function check(c::LogicalTruthCondition, d::AbstractInterpretationSet, args...; kwargs...)
    # TODO use get_instance instead?
    map(
        i_sample->tops(
            check(formula(c), slice_dataset(d, [i_sample]), args...; kwargs...)[1]
        ), 1:nsamples(d)
    )
end

############################################################################################

# Helpers
convert(::Type{AbstractBooleanCondition}, f::AbstractFormula) = LogicalTruthCondition(f)
convert(::Type{AbstractBooleanCondition}, tok::AbstractSyntaxToken) = LogicalTruthCondition(SyntaxTree(tok))
convert(::Type{AbstractBooleanCondition}, ::typeof(⊤)) = TrueCondition()

############################################################################################

"""
    abstract type AbstractModel{O} end

Abstract type for mathematical models that,
given an instance object (i.e., a piece of data), output an
outcome of type `O`.

See also
[`Rule`](@ref),
[`Branch`](@ref),
[`isopen`](@ref),
[`apply`](@ref),
[`issymbolic`](@ref),
[`info`](@ref),
[`outcometype`](@ref).
"""
abstract type AbstractModel{O} end

"""
    outcometype(::Type{<:AbstractModel{O}}) where {O} = O
    outcometype(m::AbstractModel) = outcometype(typeof(m))

Returns the outcome type of a model (type).

See also [`AbstractModel`](@ref).
"""
outcometype(::Type{<:AbstractModel{O}}) where {O} = O
outcometype(m::AbstractModel) = outcometype(typeof(m))

doc_open_model = """
An `AbstractModel{O}` is *closed* if it is always able to provide an outcome of type `O`.
Otherwise, the model can output `nothing` values and is referred to as *open*.
"""

"""
    isopen(::AbstractModel)::Bool

Returns whether a model is open.
$(doc_open_model)
[`Rule`](@ref) is an example of an *open* model, while [`Branch`](@ref)
is an example of *closed* model.

See also [`AbstractModel`](@ref).
"""
isopen(::AbstractModel) = true

"""
    outputtype(m::AbstractModel)

Returns a supertype for the outputs obtained when `apply`ing a model.
The result depends on whether the model is open or closed:

    outputtype(M::AbstractModel{O}) = isopen(M) ? Union{Nothing,O} : O

Note that if the model is closed, then `outputtype(m)` is equal to `outcometype(m)`.

See also
[`isopen`](@ref),
[`apply`](@ref),
[`outcometype`](@ref),
[`AbstractModel`](@ref).
"""
function outputtype(m::AbstractModel)
    isopen(m) ? Union{Nothing,outcometype(m)} : outcometype(m)
end

"""
    apply(
        m::AbstractModel,
        i::AbstractInterpretation;
        check_args::Tuple = (),
        check_kwargs::NamedTuple = (;),
        functional_args::Tuple = (),
        functional_kwargs::NamedTuple = (;),
        kwargs...
    )::outputtype(m)

    apply(
        m::AbstractModel,
        d::AbstractInterpretationSet;
        check_args::Tuple = (),
        check_kwargs::NamedTuple = (;),
        functional_args::Tuple = (),
        functional_kwargs::NamedTuple = (;),
        kwargs...
    )::AbstractVector{<:outputtype(m)}

Returns the output prediction of the model on an instance, or on each instance of a dataset.
The predictions can be `nothing` if the model is *open*

`check_args` and `check_kwargs` are kwargs that can influence check's behavior at the time
of its computation (see [`check`](@ref))

`functional_args` and `functional_kwargs` are kwargs that can influence FunctionModel's
behavior when the corresponding function is applied to AbstractInterpretation (see
[`FunctionModel`](@ref), [`AbstractInterpretation`](@ref))

See also
[`isopen`](@ref),
[`outcometype`](@ref),
[`outputtype`](@ref),
[`AbstractModel`](@ref),
[`AbstractInterpretation`](@ref),
[`AbstractInterpretationSet`](@ref).
"""
function apply(
    m::AbstractModel,
    i::AbstractInterpretation;
    check_args::Tuple = (),
    check_kwargs::NamedTuple = (;),
    functional_args::Tuple = (),
    functional_kwargs::NamedTuple = (;),
    kwargs...,
)::outputtype(m)
    error("Please, provide method apply(::$(typeof(m)), ::$(typeof(i))).")
end

function apply(
    m::AbstractModel,
    d::AbstractInterpretationSet,
    i_sample::Integer;
    kwargs...
)::outputtype(m)
    interpretation = get_instance(d, i_sample)
    apply(m, interpretation; kwargs...)
end

function apply(
    m::AbstractModel,
    d::AbstractInterpretationSet;
    kwargs...
)::AbstractVector{<:outputtype(m)}
    map(i_sample->apply(m, d, i_sample; kwargs...), 1:nsamples(d))
end

"""
    issymbolic(::AbstractModel)::Bool

Returns whether a model is symbolic or not.
A model is said to be `symbolic` when its application relies on checking formulas
of a certain logical language (see [`SoleLogics`](@ref) package) on the instance.
Symbolic models provide a form of transparent and interpretable modeling.

Instead, a model is said to be functional when it encodes an algebraic mathematical
function (e.g., a neural network).
TODO explain unroll_rules/cascade/rules A symbolic model is one where the computation has a *rule-base structure*.

See also
[`apply`](@ref),
[`unroll_rules`](@ref),
[`AbstractModel`](@ref).
"""
issymbolic(::AbstractModel) = false

"""
    info(m::AbstractModel)::NamedTuple = m.info

Returns the `info` structure for model `m`; this structure is used
for storing additional information that does not affect the model's behavior.
This structure can hold, for example, information
about the model's statistical performance during the learning phase.
"""
info(m::AbstractModel)::NamedTuple = m.info


############################################################################################
############################################################################################
############################################################################################

"""
    abstract type FinalModel{O} <: AbstractModel{O} end

A `FinalModel` is a model which outcomes do not depend on another model.
An `AbstractModel` can generally wrap other `AbstractModel`s. In such case, the outcome can
depend on the inner models being applied on the instance object. Otherwise, the model is
considered final; that is, it is a leaf of a tree of `AbstractModel`s.

See also [`ConstantModel`](@ref), [`FunctionModel`](@ref), [`AbstractModel`](@ref).
"""
abstract type FinalModel{O} <: AbstractModel{O} end

"""
    struct ConstantModel{O} <: FinalModel{O}
        outcome::O
        info::NamedTuple
    end

The simplest type of model is the `ConstantModel`;
it is a `FinalModel` that always outputs the same outcome.

# Examples
```julia-repl
julia> SoleModels.FinalModel(2) isa SoleModels.ConstantModel

julia> SoleModels.FinalModel(sum) isa SoleModels.FunctionModel
┌ Warning: Over efficiency concerns, please consider wrappingJulia Function's into FunctionWrapper{O,Tuple{SoleModels.AbstractInterpretation}} structures,where O is their return type.
└ @ SoleModels ~/.julia/dev/SoleModels/src/models/base.jl:337
true

```

See also
[`apply`](@ref),
[`FunctionModel`](@ref),
[`FinalModel`](@ref).
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
apply(m::ConstantModel, i::AbstractInterpretation; kwargs...) = outcome(m)
apply(m::ConstantModel, d::AbstractInterpretationSet, i_sample::Integer; kwargs...) = outcome(m)
apply(m::ConstantModel, d::AbstractInterpretationSet; kwargs...) = fill(outcome(m), nsamples(d))

convert(::Type{ConstantModel{O}}, o::O) where {O} = ConstantModel{O}(o)
convert(::Type{<:AbstractModel{F}}, m::ConstantModel) where {F} = ConstantModel{F}(m)

"""
    struct FunctionModel{O} <: FinalModel{O}
        f::FunctionWrapper{O}
        info::NamedTuple
    end

A `FunctionModel` is a `FinalModel` that applies a native Julia `Function`
in order to compute the outcome. Over efficiency concerns, it is mandatory to make explicit
the output type `O` by wrapping the `Function` into an object of type
`FunctionWrapper{O}`.

TODO @Michele explain functional_args/functional_kwargs

See also [`ConstantModel`](@ref), [`FunctionWrapper`](@ref), [`FinalModel`](@ref).
"""
struct FunctionModel{O} <: FinalModel{O}
    f::FunctionWrapper{O}
    # isopen::Bool TODO
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

    function FunctionModel{O}(
        f::Function,
        info::NamedTuple = (;),
    ) where {O}
        @warn "Over efficiency concerns, please consider wrapping"*
        "Julia Function's into FunctionWrapper{O,Tuple{SoleModels.AbstractInterpretation}}"*
        " structures,where O is their return type."
        f = FunctionWrapper{O,Tuple{AbstractInterpretation}}(f)
        FunctionModel{O}(f, info)
    end

    function FunctionModel(
        f::Function,
        info::NamedTuple = (;),
    )
        FunctionModel{Any}(f, info)
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
function apply(
    m::FunctionModel,
    i::AbstractInterpretation;
    functional_models_gets_single_instance::Bool = false,
    functional_args::Tuple = (),
    functional_kwargs::NamedTuple = (;),
    kwargs...,
)
    @assert functional_models_gets_single_instance
    f(m)(i, functional_args...; functional_kwargs...)
end
function apply(
    m::FunctionModel,
    d::AbstractInterpretationSet,
    i_sample::Integer;
    functional_models_gets_single_instance::Bool = false,
    functional_args::Tuple = (),
    functional_kwargs::NamedTuple = (;),
    kwargs...,
)
    if functional_models_gets_single_instance
        interpretation = get_instance(d, i_sample)
        f(m)(interpretation, functional_args...; functional_kwargs...)
    else
        f(m)(d, i_sample, functional_args...; functional_kwargs...)
    end
end

convert(::Type{<:AbstractModel{F}}, m::FunctionModel) where {F} = FunctionModel{F}(m)

"""
    wrap(o::Any)::AbstractModel

This function wraps anything into an AbstractModel.
The default behavior is the following:
- when called on an `AbstractModel`, the model is
simply returned (no wrapping is performed);
- `Function`s and `FunctionWrapper`s are wrapped into a `FunctionModel`;
- every other object is wrapped into a `ConstantModel`.

See also
[`ConstantModel`](@ref), [`FunctionModel`](@ref),
[`ConstrainedModel`](@ref), [`FinalModel`](@ref).
"""
wrap(o::Any, FM::Type{<:AbstractModel}) = convert(FM, wrap(o))
wrap(m::AbstractModel) = m
wrap(o::Function) = FunctionModel(o)
wrap(o::FunctionWrapper{O}) where {O} = FunctionModel{O}(o)
wrap(o::O) where {O} = convert(ConstantModel{O}, o)

# Helper
FinalModel(o) = wrap(o)

############################################################################################
############################################################################################
############################################################################################

"""
An `AbstractModel` can wrap another `AbstractModel`, and use it to compute the outcome.
As such, an `AbstractModel` can actually be the result of a composition of many models,
and enclose a *tree* of `AbstractModel`s (with `FinalModel`s at the leaves).
In order to typebound the Feasible Models (`FM`) allowed in the sub-tree,
the `ConstrainedModel` type is introduced:

    abstract type ConstrainedModel{O,FM<:AbstractModel} <: AbstractModel{O} end

For example, `ConstrainedModel{String, Union{Branch{String}, ConstantModel{String}}}`
supertypes models that with `String` outcomes that make use of `Branch{String}` and
`ConstantModel{String}` (essentially, a decision trees with `String`s at the leaves).

See also [`FinalModel`](@ref), [`AbstractModel`](@ref).
"""
abstract type ConstrainedModel{O,FM<:AbstractModel} <: AbstractModel{O} end

"""
    feasiblemodelstype(m::AbstractModel)

Returns a `Union` of the Feasible Models (`FM`) allowed in the sub-tree of any
AbstractModel. Note that for a `ConstrainedModel{O,FM<:AbstractModel}`, it
simply returns `FM`.

See also [`ConstrainedModel`](@ref).
"""
feasiblemodelstype(::Type{M}) where {O, M<:AbstractModel{O}} = AbstractModel{<:O}
feasiblemodelstype(::Type{M}) where {M<:AbstractModel} = AbstractModel
feasiblemodelstype(::Type{M}) where {O, M<:FinalModel{O}} = Union{}
feasiblemodelstype(::Type{M}) where {M<:FinalModel} = Union{}
feasiblemodelstype(::Type{<:ConstrainedModel{O,FM}}) where {O,FM} = FM
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
function check_model_constraints(
    M::Type{<:AbstractModel},
    I_M::Type{<:AbstractModel},
    FM::Type{<:AbstractModel},
    FM_O::Type = outcometype(FM)
)
    I_O = outcometype(I_M)
    # FM_O = outcometype(FM)
    @assert I_O <: FM_O "Can't instantiate $(M) with inner model outcometype" *
        " $(I_O)! $(I_O) <: $(FM_O) should hold."
    # @assert I_M <: FM || typename(I_M) <: typename(FM) "Can't instantiate $(M) with inner model $(I_M))! $(I_M) <: $(FM) || $(typename(I_M)) <: $(typename(FM)) should hold."
    @assert I_M <: FM "Can't instantiate $(M) with inner model $(I_M))!" *
        " $(I_M) <: $(FM) should hold."
    if ! (I_M<:FinalModel{<:FM_O})
        # @assert I_M<:ConstrainedModel{FM_O,<:FM} "ConstrainedModels require I_M<:ConstrainedModel{O,<:FM}, but $(I_M) does not subtype $(ConstrainedModel{FM_O,<:FM})."
        @assert I_M<:ConstrainedModel{<:FM_O,<:FM} "ConstrainedModels require" *
            " I_M<:ConstrainedModel{<:O,<:FM}, but $(I_M) does not" *
            " subtype $(ConstrainedModel{<:FM_O,<:FM})."
    end
end

############################################################################################
############################################################################################
############################################################################################

doc_symbolic_basics = """
Symbolic modeling builds onto two basic building blocks, which are `AbstractModel`s themselves:
- `Rule`: IF (antecedent) THEN (consequent) END
- `Branch`: IF (antecedent) THEN (posconsequent) ELSE (negconsequent) END
The *antecedent* is a formula of a certain logic, that can typically evaluate to true or false
when the model is applied on an instance object;
the *consequent*s are `AbstractModel`s themselves, that are to be applied to the instance object
in order to obtain an outcome.
"""

"""
    struct Rule{
        O,
        C<:AbstractBooleanCondition,
        FM<:AbstractModel
    } <: ConstrainedModel{O,FM}
        antecedent::C
        consequent::FM
        info::NamedTuple
    end

A `Rule` is one of the fundamental building blocks of symbolic modeling, and has
the semantics:

    IF (antecedent) THEN (consequent) END

where the antecedent is a condition to be tested and the consequent is the local outcome of the block.

Note that `FM` refers to the Feasible Models (`FM`) allowed in the model's sub-tree.

See also
[`antecedent`](@ref),
[`consequent`](@ref),
[`AbstractBooleanCondition`](@ref),
[`ConstrainedModel`](@ref),
[`AbstractModel`](@ref).
"""
struct Rule{
    O,
    C<:AbstractBooleanCondition,
    FM<:AbstractModel
} <: ConstrainedModel{O,FM}
    antecedent::C
    consequent::FM
    info::NamedTuple

    function Rule{O}(
        antecedent::Union{AbstractSyntaxToken,AbstractFormula,AbstractBooleanCondition},
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
        antecedent::Union{AbstractSyntaxToken,AbstractFormula,AbstractBooleanCondition},
        consequent::Any,
        info::NamedTuple = (;),
    )
        consequent = wrap(consequent)
        O = outcometype(consequent)
        Rule{O}(antecedent, consequent, info)
    end

    function Rule(
        consequent::Any,
        info::NamedTuple = (;),
    )
        antecedent = TrueCondition()
        consequent = wrap(consequent)
        O = outcometype(consequent)
        Rule{O}(antecedent, consequent, info)
    end
end

"""
    antecedent(m::Union{Rule,Branch})::AbstractBooleanCondition

Returns the antecedent of a rule/branch;
that is, the condition to be evaluated upon applying the model.

See also
[`apply`](@ref),
[`consequent`](@ref),
[`check_antecedent`](@ref),
[`Rule`](@ref),
[`Branch`](@ref).
"""
antecedent(m::Rule) = m.antecedent

"""
    consequent(m::Rule)::AbstractModel

Returns the consequent of a rule.

See also
[`antecedent`](@ref),
[`Rule`](@ref).
"""
consequent(m::Rule) = m.consequent

conditiontype(::Type{M}) where {M<:Rule{O,C}} where {O,C} = C
conditiontype(m::Rule) = conditiontype(typeof(m))

issymbolic(::Rule) = true

"""
    function check_antecedent(
        m::Union{Rule,Branch},
        args...;
        kwargs...
    )
        check(antecedent(m), id, args...; kwargs...)
    end

Simply checks the antecedent of a rule on an instance or dataset.

See also
[`antecedent`](@ref),
[`Rule`](@ref),
[`Branch`](@ref).
"""
function check_antecedent(
    m::Rule,
    args...;
    kwargs...
)
    check(antecedent(m), args...; kwargs...)
end

function apply(
    m::Rule,
    i::AbstractInterpretation;
    check_args::Tuple = (),
    check_kwargs::NamedTuple = (;),
    kwargs...
)
    if check_antecedent(m, i, check_args...; check_kwargs...)
        apply(consequent(m), i;
            check_args = check_args,
            check_kwargs = check_kwargs,
            kwargs...
        )
    else
        nothing
    end
end

function apply(
    m::Rule,
    d::AbstractInterpretationSet,
    i_sample::Integer;
    check_args::Tuple = (),
    check_kwargs::NamedTuple = (;),
    kwargs...
)
    if check_antecedent(m, d, i_sample, check_args...; check_kwargs...) == true
        apply(consequent(m), d, i_sample;
            check_args = check_args,
            check_kwargs = check_kwargs,
            kwargs...
        )
    else
        nothing
    end
end

# Helper
function formula(m::Rule{O,<:Union{LogicalTruthCondition,TrueCondition}}) where {O}
    formula(antecedent(m))
end

############################################################################################

"""
    struct Branch{
        O,
        C<:AbstractBooleanCondition,
        FM<:AbstractModel
    } <: ConstrainedModel{O,FM}
        antecedent::C
        posconsequent::FM
        negconsequent::FM
        info::NamedTuple
    end

A `Branch` is one of the fundamental building blocks of symbolic modeling, and has
the semantics:

    IF (antecedent) THEN (consequent_1) ELSE (consequent_2) END

where the antecedent is boolean condition to be tested and the consequents are the feasible
local outcomes of the block.

Note that `FM` refers to the Feasible Models (`FM`) allowed in the model's sub-tree.

See also
[`antecedent`](@ref),
[`posconsequent`](@ref),
[`negconsequent`](@ref),
[`AbstractBooleanCondition`](@ref),
[`Rule`](@ref),
[`ConstrainedModel`](@ref), [`AbstractModel`](@ref).
"""
struct Branch{
    O,
    C<:AbstractBooleanCondition,
    FM<:AbstractModel
} <: ConstrainedModel{O,FM}
    antecedent::C
    posconsequent::FM
    negconsequent::FM
    info::NamedTuple

    function Branch(
        antecedent::Union{AbstractSyntaxToken,AbstractFormula,AbstractBooleanCondition},
        posconsequent::Any,
        negconsequent::Any,
        info::NamedTuple = (;),
    )
        antecedent = convert(AbstractBooleanCondition, antecedent)
        C = typeof(antecedent)
        posconsequent = wrap(posconsequent)
        negconsequent = wrap(negconsequent)
        O = Union{outcometype(posconsequent),outcometype(negconsequent)}
        FM = typeintersect(Union{propagate_feasiblemodels(posconsequent),propagate_feasiblemodels(negconsequent)}, AbstractModel{<:O})
        check_model_constraints(Branch{O}, typeof(posconsequent), FM, O)
        check_model_constraints(Branch{O}, typeof(negconsequent), FM, O)
        new{O,C,FM}(antecedent, posconsequent, negconsequent, info)
    end

    function Branch(
        antecedent::Union{AbstractSyntaxToken,AbstractFormula,AbstractBooleanCondition},
        (posconsequent, negconsequent)::Tuple{Any,Any},
        info::NamedTuple = (;),
    )
        Branch(antecedent, posconsequent, negconsequent, info)
    end

end

antecedent(m::Branch) = m.antecedent

"""
    posconsequent(m::Branch)::AbstractModel

Returns the positive consequent of a branch;
that is, the model to be applied if the antecedent evaluates to `true`.

See also
[`antecedent`](@ref),
[`Branch`](@ref).
"""
posconsequent(m::Branch) = m.posconsequent

"""
    negconsequent(m::Branch)::AbstractModel

Returns the negative consequent of a branch;
that is, the model to be applied if the antecedent evaluates to `false`.

See also
[`antecedent`](@ref),
[`Branch`](@ref).
"""
negconsequent(m::Branch) = m.negconsequent

conditiontype(::Type{M}) where {M<:Branch{O,C}} where {O,C} = C
conditiontype(m::Branch) = conditiontype(typeof(m))

issymbolic(::Branch) = true

isopen(m::Branch) = isopen(posconsequent(m)) || isopen(negconsequent(m))

function check_antecedent(
    m::Branch,
    args...;
    kwargs...
)
    check(antecedent(m), args...; kwargs...)
end

function apply(
    m::Branch,
    i::AbstractInterpretation;
    check_args::Tuple = (),
    check_kwargs::NamedTuple = (;),
    kwargs...
)
    if check_antecedent(m, i, check_args...; check_kwargs...)
        apply(posconsequent(m), i;
            check_args = check_args,
            check_kwargs = check_kwargs,
            kwargs...
        )
    else
        apply(negconsequent(m), i;
            check_args = check_args,
            check_kwargs = check_kwargs,
            kwargs...
        )
    end
end

function apply(
    m::Branch{O,<:LogicalTruthCondition},
    d::AbstractInterpretationSet,
    i_sample::Integer;
    check_args::Tuple = (),
    check_kwargs::NamedTuple = (;),
    kwargs...
) where {O}
    if check_antecedent(m, d, i_sample, check_args...; check_kwargs...) == true
        apply(posconsequent(m), d, i_sample;
            check_args = check_args,
            check_kwargs = check_kwargs,
            kwargs...
        )
    else
        apply(negconsequent(m), d, i_sample;
            check_args = check_args,
            check_kwargs = check_kwargs,
            kwargs...
        )
    end
end

function apply(
    m::Branch{O,<:LogicalTruthCondition},
    d::AbstractInterpretationSet;
    check_args::Tuple = (),
    check_kwargs::NamedTuple = (;),
    kwargs...
) where {O}
    cs = check_antecedent(m, d, check_args...; check_kwargs...)
    cpos = findall((c)->c==true, cs)
    cneg = findall((c)->c==false, cs)
    out = fill(true, length(cs))
    out[cpos] = apply(posconsequent(m), slice_dataset(d, cpos);
                    check_args = check_args,
                    check_kwargs = check_kwargs,
                    kwargs...
                )
    out[cneg] = apply(negconsequent(m), slice_dataset(d, cneg);
                    check_args = check_args,
                    check_kwargs = check_kwargs,
                    kwargs...
                )
    out
end

# Helper
function formula(m::Branch{O,<:Union{LogicalTruthCondition,TrueCondition}}) where {O}
    formula(antecedent(m))
end

############################################################################################

"""
    struct DecisionList{
        O,
        C<:AbstractBooleanCondition,
        FM<:AbstractModel
    } <: ConstrainedModel{O,FM}
        rulebase::Vector{Rule{_O,_C,_FM} where {_O<:O,_C<:C,_FM<:FM}}
        defaultconsequent::FM
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

See also
[`Rule`](@ref),
[`ConstrainedModel`](@ref),
[`DecisionTree`](@ref),
[`AbstractModel`](@ref).
"""
struct DecisionList{
    O,
    C<:AbstractBooleanCondition,
    FM<:AbstractModel
} <: ConstrainedModel{O,FM}
    rulebase::Vector{Rule{_O,_C,_FM} where {_O<:O,_C<:C,_FM<:FM}}
    defaultconsequent::FM
    info::NamedTuple

    function DecisionList(
        rulebase::Vector{<:Rule},
        defaultconsequent::Any,
        info::NamedTuple = (;),
    )
        defaultconsequent = wrap(defaultconsequent)
        O = Union{outcometype(defaultconsequent),outcometype.(rulebase)...}
        C = Union{conditiontype.(rulebase)...}
        FM = typeintersect(Union{propagate_feasiblemodels(defaultconsequent),propagate_feasiblemodels.(rulebase)...}, AbstractModel{<:O})
        # FM = typeintersect(Union{propagate_feasiblemodels(defaultconsequent),propagate_feasiblemodels.(rulebase)...}, AbstractModel{O})
        # FM = Union{propagate_feasiblemodels(defaultconsequent),propagate_feasiblemodels.(rulebase)...}
        check_model_constraints.(DecisionList{O}, typeof.(rulebase), FM, O)
        check_model_constraints(DecisionList{O}, typeof(defaultconsequent), FM, O)
        new{O,C,FM}(rulebase, defaultconsequent, info)
    end
end

rulebase(m::DecisionList) = m.rulebase
defaultconsequent(m::DecisionList) = m.defaultconsequent

conditiontype(::Type{M}) where {M<:DecisionList{O,C}} where {O,C} = C
conditiontype(m::DecisionList) = conditiontype(typeof(m))

issymbolic(::DecisionList) = true

isopen(m::DecisionList) = isopen(defaultconsequent(m))

function apply(
    m::DecisionList,
    i::AbstractInterpretation;
    check_args::Tuple = (),
    check_kwargs::NamedTuple = (;),
    kwargs...
)
    for rule in rulebase(m)
        if check(m, i, check_args...; check_kwargs...)
            return consequent(rule)
        end
    end
    defaultconsequent(m)
end

function apply(
    m::DecisionList{O},
    d::AbstractInterpretationSet;
    check_args::Tuple = (),
    check_kwargs::NamedTuple = (;),
    kwargs...
) where {O}
    nsamp = nsamples(d)
    pred = Vector{O}(undef, nsamp)
    uncovered_idxs = 1:nsamp

    for rule in rulebase(m)
        length(uncovered_idxs) == 0 && break

        idxs_sat = findall(
            check(antecedent(rule),d, check_args...; check_kwargs...) .== true
        )
        uncovered_idxs = setdiff(uncovered_idxs,idxs_sat)

        map((i)->(pred[i] = outcome(consequent(rule))), idxs_sat)
    end

    length(uncovered_idxs) != 0 &&
        map((i)->(pred[i] = outcome(defaultconsequent(m))), uncovered_idxs)

    return pred
end

############################################################################################

"""
A `DecisionTree` is a symbolic model that operates as a nested structure of
IF-THEN-ELSE blocks:

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

In practice, a `DecisionTree` simply wraps a constrained
sub-tree of `Branch` and `FinalModel`:

    struct DecisionTree{
    O,
        C<:AbstractBooleanCondition,
        FFM<:FinalModel
    } <: ConstrainedModel{O, Union{<:Branch{<:O,<:C}, <:FFM}}
        root::M where {M<:Union{FFM,Branch}}
        info::NamedTuple
    end

Note that `FM` refers to the Feasible Models (`FM`) allowed in the model's sub-tree.
Also note that this structure also includes an `info::NamedTuple` for storing additional
information.

See also [`ConstrainedModel`](@ref), [`MixedSymbolicModel`](@ref), [`DecisionList`](@ref).
"""
struct DecisionTree{
    O,
    C<:AbstractBooleanCondition,
    FFM<:FinalModel
} <: ConstrainedModel{O, Union{<:Branch{<:O,<:C}, <:FFM}}
    root::M where {M<:Union{FFM,Branch}}
    info::NamedTuple

    function DecisionTree(
        root::Union{FFM,Branch{O,C,Union{<:Branch{<:O,C2},FFM}}},
        info::NamedTuple = (;),
    ) where {O, C<:AbstractBooleanCondition, C2<:C, FFM<:FinalModel{<:O}}
        new{O,C,FFM}(root, info)
    end

    function DecisionTree(
        root::Any,
        info::NamedTuple = (;),
    )
        root = wrap(root)
        M = typeof(root)
        O = outcometype(root)
        C = (root isa FinalModel ? AbstractBooleanCondition : conditiontype(M))
        # FM = typeintersect(Union{M,feasiblemodelstype(M)}, AbstractModel{<:O})
        FM = typeintersect(Union{propagate_feasiblemodels(M)}, AbstractModel{<:O})
        FFM = typeintersect(FM, FinalModel{<:O})
        @assert M <: Union{<:FFM,<:Branch{<:O,<:C,<:Union{Branch,FFM}}} "" *
            "Cannot instantiate DecisionTree{$(O),$(C),$(FFM)}(...) with root of" *
            " type $(typeof(root)). Note that the should be either a FinalNode or a" *
            " bounded Branch." *
            " $(M) <: $(Union{FinalModel,Branch{<:O,<:C,<:Union{Branch,FFM}}}) should hold."
        check_model_constraints(DecisionTree{O}, typeof(root), FM, O)
        new{O,C,FFM}(root, info)
    end
end

root(m::DecisionTree) = m.root

conditiontype(::Type{M}) where {M<:DecisionTree{O,C}} where {O,C} = C
conditiontype(m::DecisionTree) = conditiontype(typeof(m))

issymbolic(::DecisionTree) = true

isopen(::DecisionTree) = false

function apply(
    m::DecisionTree,
    id::Union{AbstractInterpretation,AbstractInterpretationSet};
    kwargs...
)
    apply(root(m), id; kwargs...)
end

############################################################################################

"""
A `Decision Forest` is a symbolic model that wraps an ensemble of models

    struct DecisionForest{
        O,
        C<:AbstractBooleanCondition,
        FFM<:FinalModel
    } <: ConstrainedModel{O, Union{<:Branch{<:O,<:C}, <:FFM}}
        trees::Vector{<:DecisionTree}
        info::NamedTuple
    end


See also [`ConstrainedModel`](@ref), [`MixedSymbolicModel`](@ref), [`DecisionList`](@ref),
[`DecisionTree`](@ref)
"""
struct DecisionForest{
    O,
    C<:AbstractBooleanCondition,
    FFM<:FinalModel
} <: ConstrainedModel{O, Union{<:Branch{<:O,<:C}, <:FFM}}
    trees::Vector{<:DecisionTree}
    info::NamedTuple

    function DecisionForest(
        trees::Vector{<:DecisionTree},
        info::NamedTuple = (;),
    )
        @assert length(trees) > 0 "Cannot instantiate forest with no trees!"
        O = Union{outcometype.(trees)...}
        C = Union{conditiontype.(trees)...}
        FM = typeintersect(Union{propagate_feasiblemodels.(trees)...}, AbstractModel{<:O})
        FFM = typeintersect(FM, FinalModel{<:O})
        check_model_constraints.(DecisionForest{O}, typeof.(trees), FM, O)
        new{O,C,FFM}(trees, info)
    end
end

trees(forest::DecisionForest) = forest.trees

conditiontype(::Type{M}) where {M<:DecisionForest{O,C}} where {O,C} = C
conditiontype(m::DecisionForest) = conditiontype(typeof(m))

issymbolic(::DecisionForest) = false

function apply(
    f::DecisionForest,
    id::Union{AbstractInterpretation,AbstractInterpretationSet};
    kwargs...
)
    best_guess([apply(t, id; kwargs...) for t in trees(f)])
end

############################################################################################

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
`Rule`s, `Branch`s, `DecisionList`s, `DecisionTree`s, and the be wrapped into
a `MixedSymbolicModel`:

    struct MixedSymbolicModel{O,FM<:AbstractModel} <: ConstrainedModel{O,FM}
        root::M where {M<:Union{FinalModel{<:O},ConstrainedModel{<:O,<:FM}}}
        info::NamedTuple
    end

Note that `FM` refers to the Feasible Models (`FM`) allowed in the model's sub-tree.

See also [`ConstrainedModel`](@ref), [`DecisionTree`](@ref), [`DecisionList`](@ref).
"""
struct MixedSymbolicModel{O,FM<:AbstractModel} <: ConstrainedModel{O,FM}
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

issymbolic(m::MixedSymbolicModel) = issymbolic(root(m))

isopen(::MixedSymbolicModel) = isopen(root)

function apply(
    m::MixedSymbolicModel,
    id::Union{AbstractInterpretation,AbstractInterpretationSet};
    kwargs...
)
    apply(root(m), id; kwargs...)
end

############################################################################################
