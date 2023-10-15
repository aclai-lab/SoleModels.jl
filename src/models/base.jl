import Base: convert, length, getindex, isopen

using SoleData: slicedataset

import SoleLogics: check, syntaxstring
using SoleLogics: LeftmostLinearForm, LeftmostConjunctiveForm, LeftmostDisjunctiveForm
using SoleModels: TopFormula

# Util
typename(::Type{T}) where T = eval(nameof(T))

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

Return the outcome type of a model (type).

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

Return whether a model is open.
$(doc_open_model)
[`Rule`](@ref) is an example of an *open* model, while [`Branch`](@ref)
is an example of *closed* model.

See also [`AbstractModel`](@ref).
"""
isopen(::AbstractModel) = true

"""
    outputtype(m::AbstractModel)

Return a supertype for the outputs obtained when `apply`ing a model.
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

Return the output prediction of the model on an instance, or on each instance of a dataset.
The predictions can be `nothing` if the model is *open*.

`check_args` and `check_kwargs` can influence check's behavior at the time
of its computation (see [`check`](@ref))

`functional_args` and `functional_kwargs` can influence FunctionModel's
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
    return error("Please, provide method apply(::$(typeof(m)), ::$(typeof(i))).")
end

function apply(
    m::AbstractModel,
    d::AbstractInterpretationSet,
    i_instance::Integer;
    kwargs...
)::outputtype(m)
    interpretation = get_instance(d, i_instance)
    apply(m, interpretation; kwargs...)
end

function apply(
    m::AbstractModel,
    d::AbstractInterpretationSet;
    kwargs...
)::AbstractVector{<:outputtype(m)}
    map(i_instance->apply(m, d, i_instance; kwargs...), 1:ninstances(d))
end

# Symbolic models encode a *rule-based thought process*,
# and provide a form of transparent and interpretable computation.
"""
    issymbolic(::AbstractModel)::Bool

Return whether a model is symbolic or not.
A model is said to be `symbolic` when its application relies on checking formulas
of a certain logical language (see [`SoleLogics`](@ref) package) on the instance.
Symbolic models provide a form of transparent and interpretable modeling,
as a symbolic model can be synthethised into a set of mutually exclusive logical rules
that can often be translated into natural language.

Examples of purely symbolic models are [`Rule`](@ref)s, [`Branch`](@ref),
[`DecisionList`](@ref)s and [`DecisionTree`](@ref)s.
Examples of non-symbolic models are those encoding algebraic mathematical
functions (e.g., neural networks). Note that [`DecisionForest`](@ref)s are
not purely symbolic, as they rely on an algebraic aggregation step.

See also
[`apply`](@ref),
[`listrules`](@ref),
[`AbstractModel`](@ref).
"""
issymbolic(::AbstractModel) = false

"""
    info(m::AbstractModel)::NamedTuple = m.info
    info(m::AbstractModel, key) = m.info[key]
    info(m::AbstractModel, key, defaultval)
    info!(m::AbstractModel, key, val)

Return the `info` structure for model `m`; this structure is used
for storing additional information that does not affect the model's behavior.
This structure can hold, for example, information
about the model's statistical performance during the learning phase.
"""
info(m::AbstractModel)::NamedTuple = m.info
info(m::AbstractModel, key) = m.info[key]
info(m::AbstractModel, key, defaultval) = Base.get(m.info, key, defaultval)
info!(m::AbstractModel, key, value) = (m.info[key] = value; m)


############################################################################################
############################################################################################
############################################################################################

"""
    abstract type LeafModel{O} <: AbstractModel{O} end

Abstract type for leaf models, that is, models which outcomes do not depend
other models, and represents the bottom of the computation.
In general, an `AbstractModel` can generally wrap other `AbstractModel`s;
in such case, the outcome can
depend on the inner models being applied on the instance object. Otherwise, the model is
considered as a *leaf*, or *final*, and is the *leaf* of a tree of `AbstractModel`s.

See also [`ConstantModel`](@ref), [`FunctionModel`](@ref), [`AbstractModel`](@ref).
"""
abstract type LeafModel{O} <: AbstractModel{O} end

"""
    struct ConstantModel{O} <: LeafModel{O}
        outcome::O
        info::NamedTuple
    end

The simplest type of model is the `ConstantModel`;
it is a `LeafModel` that always outputs the same outcome.

# Examples
```julia-repl
julia> SoleModels.LeafModel(2) isa SoleModels.ConstantModel

julia> SoleModels.LeafModel(sum) isa SoleModels.FunctionModel
┌ Warning: Over efficiency concerns, please consider wrappingJulia Function's into FunctionWrapper{O,Tuple{SoleModels.AbstractInterpretation}} structures,where O is their return type.
└ @ SoleModels ~/.julia/dev/SoleModels/src/models/base.jl:337
true

```

See also
[`apply`](@ref),
[`FunctionModel`](@ref),
[`LeafModel`](@ref).
"""
struct ConstantModel{O} <: LeafModel{O}
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
apply(m::ConstantModel, d::AbstractInterpretationSet, i_instance::Integer; kwargs...) = outcome(m)
apply(m::ConstantModel, d::AbstractInterpretationSet; kwargs...) = fill(outcome(m), ninstances(d))

convert(::Type{ConstantModel{O}}, o::O) where {O} = ConstantModel{O}(o)
convert(::Type{<:AbstractModel{F}}, m::ConstantModel) where {F} = ConstantModel{F}(m)

# TODO @Michele explain functional_args/functional_kwargs
"""
    struct FunctionModel{O} <: LeafModel{O}
        f::FunctionWrapper{O}
        info::NamedTuple
    end

A `FunctionModel` is a `LeafModel` that applies a native Julia `Function`
in order to compute the outcome. Over efficiency concerns, it is mandatory to make explicit
the output type `O` by wrapping the `Function` into an object of type
`FunctionWrapper{O}`.

See also [`ConstantModel`](@ref), [`FunctionWrapper`](@ref), [`LeafModel`](@ref).
"""
struct FunctionModel{O} <: LeafModel{O}
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
    i_instance::Integer;
    functional_models_gets_single_instance::Bool = false,
    functional_args::Tuple = (),
    functional_kwargs::NamedTuple = (;),
    kwargs...,
)
    if functional_models_gets_single_instance
        interpretation = get_instance(d, i_instance)
        f(m)(interpretation, functional_args...; functional_kwargs...)
    else
        f(m)(d, i_instance, functional_args...; functional_kwargs...)
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
[`ConstrainedModel`](@ref), [`LeafModel`](@ref).
"""
wrap(o::Any, FM::Type{<:AbstractModel}) = convert(FM, wrap(o))
wrap(m::AbstractModel) = m
wrap(o::Function) = FunctionModel(o)
wrap(o::FunctionWrapper{O}) where {O} = FunctionModel{O}(o)
wrap(o::O) where {O} = convert(ConstantModel{O}, o)

# Helper
LeafModel(o) = wrap(o)

############################################################################################
############################################################################################
############################################################################################

"""
An `AbstractModel` can wrap another `AbstractModel`, and use it to compute the outcome.
As such, an `AbstractModel` can actually be the result of a composition of many models,
and enclose a *tree* of `AbstractModel`s (with `LeafModel`s at the leaves).
In order to typebound the Feasible Models (`FM`) allowed in the sub-tree,
the `ConstrainedModel` type is introduced:

    abstract type ConstrainedModel{O,FM<:AbstractModel} <: AbstractModel{O} end

For example, `ConstrainedModel{String,Union{Branch{String},ConstantModel{String}}}`
supertypes models that with `String` outcomes that make use of `Branch{String}` and
`ConstantModel{String}` (essentially, a decision trees with `String`s at the leaves).

See also [`LeafModel`](@ref), [`AbstractModel`](@ref).
"""
abstract type ConstrainedModel{O,FM<:AbstractModel} <: AbstractModel{O} end

"""
    feasiblemodelstype(m::AbstractModel)

Return a `Union` of the Feasible Models (`FM`) allowed in the sub-tree of any
AbstractModel. Note that for a `ConstrainedModel{O,FM<:AbstractModel}`, it
simply returns `FM`.

See also [`ConstrainedModel`](@ref).
"""
feasiblemodelstype(::Type{M}) where {O,M<:AbstractModel{O}} = AbstractModel{<:O}
feasiblemodelstype(::Type{M}) where {M<:AbstractModel} = AbstractModel
feasiblemodelstype(::Type{M}) where {O,M<:LeafModel{O}} = Union{}
feasiblemodelstype(::Type{M}) where {M<:LeafModel} = Union{}
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
    @assert I_O <: FM_O "Cannot instantiate $(M) with inner model outcometype " *
        "$(I_O)! $(I_O) <: $(FM_O) should hold."
    # @assert I_M <: FM || typename(I_M) <: typename(FM) "Cannot instantiate $(M) with inner model $(I_M))! $(I_M) <: $(FM) || $(typename(I_M)) <: $(typename(FM)) should hold."
    @assert I_M <: FM "Cannot instantiate $(M) with inner model $(I_M))! " *
        "$(I_M) <: $(FM) should hold."
    if ! (I_M<:LeafModel{<:FM_O})
        # @assert I_M<:ConstrainedModel{FM_O,<:FM} "ConstrainedModels require I_M<:ConstrainedModel{O,<:FM}, but $(I_M) does not subtype $(ConstrainedModel{FM_O,<:FM})."
        @assert I_M<:ConstrainedModel{<:FM_O,<:FM} "ConstrainedModels require " *
            "I_M<:ConstrainedModel{<:O,<:FM}, but $(I_M) does not " *
            "subtype $(ConstrainedModel{<:FM_O,<:FM})."
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
        A<:Formula,
        FM<:AbstractModel
    } <: ConstrainedModel{O,FM}
        antecedent::A
        consequent::FM
        info::NamedTuple
    end

A `Rule` is one of the fundamental building blocks of symbolic modeling, and has
the semantics:

    IF (antecedent) THEN (consequent) END

where the antecedent is a formula to be checked,
and the consequent is the local outcome of the block.

Note that `FM` refers to the Feasible Models (`FM`) allowed in the model's sub-tree.

See also
[`antecedent`](@ref),
[`consequent`](@ref),
[`Formula`](@ref),
[`ConstrainedModel`](@ref),
[`AbstractModel`](@ref).
"""
struct Rule{
    O,
    A<:Formula,
    FM<:AbstractModel
} <: ConstrainedModel{O,FM}
    antecedent::A
    consequent::FM
    info::NamedTuple

    function Rule{O}(
        antecedent::Union{AbstractSyntaxToken,Formula},
        consequent::Any,
        info::NamedTuple = (;),
    ) where {O}
        A = typeof(antecedent)
        consequent = wrap(consequent, AbstractModel{O})
        FM = typeintersect(propagate_feasiblemodels(consequent), AbstractModel{<:O})
        check_model_constraints(Rule{O}, typeof(consequent), FM, O)
        new{O,A,FM}(antecedent, consequent, info)
    end

    function Rule(
        antecedent::Union{AbstractSyntaxToken,Formula},
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
        antecedent = TopFormula()
        consequent = wrap(consequent)
        O = outcometype(consequent)
        Rule{O}(antecedent, consequent, info)
    end
end

"""
    antecedent(m::Union{Rule,Branch})::Formula

Return the antecedent of a rule/branch,
that is, the formula to be checked upon applying the model.

See also
[`apply`](@ref),
[`consequent`](@ref),
[`antecedenttops`](@ref),
[`Rule`](@ref),
[`Branch`](@ref).
"""
antecedent(m::Rule) = m.antecedent

"""
    consequent(m::Rule)::AbstractModel

Return the consequent of a rule.

See also
[`antecedent`](@ref),
[`Rule`](@ref).
"""
consequent(m::Rule) = m.consequent

antecedenttype(::Type{M}) where {M<:Rule{O,A}} where {O,A} = A
antecedenttype(m::Rule) = antecedenttype(typeof(m))

issymbolic(::Rule) = true

"""
    function antecedenttops(
        m::Union{Rule,Branch},
        args...;
        kwargs...
    )
        check(antecedent(m), args...; kwargs...)
    end

Simply check the antecedent of a rule on an instance or dataset.

See also
[`antecedent`](@ref),
[`Rule`](@ref),
[`Branch`](@ref).
"""
function antecedenttops end

function apply(
    m::Rule,
    i::AbstractInterpretation;
    check_args::Tuple = (),
    check_kwargs::NamedTuple = (;),
    kwargs...
)
    if antecedenttops(m, i, check_args...; check_kwargs...)
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
    i_instance::Integer;
    check_args::Tuple = (),
    check_kwargs::NamedTuple = (;),
    kwargs...
)
    if antecedenttops(m, d, i_instance, check_args...; check_kwargs...)
        apply(consequent(m), d, i_instance;
            check_args = check_args,
            check_kwargs = check_kwargs,
            kwargs...
        )
    else
        nothing
    end
end

# Helpers
function conjuncts(m::Rule{O,<:LeftmostConjunctiveForm}) where {O}
    conjuncts(antecedent(m))
end
function nconjuncts(m::Rule{O,<:LeftmostConjunctiveForm}) where {O}
    nconjuncts(antecedent(m))
end
function disjuncts(m::Rule{O,<:LeftmostDisjunctiveForm}) where {O}
    disjuncts(antecedent(m))
end
function ndisjuncts(m::Rule{O,<:LeftmostDisjunctiveForm}) where {O}
    ndisjuncts(antecedent(m))
end

# Helper
function Base.getindex(
    m::Rule{O,A},
    idxs::AbstractVector{<:Integer},
) where {O,A<:LeftmostLinearForm}
    a = antecedent(m)
    Rule{O}(A(children(a)[idxs]), consequent(m))
end


############################################################################################

"""
    struct Branch{
        O,
        A<:Formula,
        FM<:AbstractModel
    } <: ConstrainedModel{O,FM}
        antecedent::A
        posconsequent::FM
        negconsequent::FM
        info::NamedTuple
    end

A `Branch` is one of the fundamental building blocks of symbolic modeling, and has
the semantics:

    IF (antecedent) THEN (positive consequent) ELSE (negative consequent) END

where the antecedent is a formula to be checked and the consequents are the feasible
local outcomes of the block. If checking the antecedent evaluates to the top of the algebra,
then the positive consequent is applied; otherwise, the negative consequenti is applied.


Note that `FM` refers to the Feasible Models (`FM`) allowed in the model's sub-tree.

See also
[`antecedent`](@ref),
[`posconsequent`](@ref),
[`negconsequent`](@ref),
[`istop`](@ref),
[`Formula`](@ref),
[`Rule`](@ref),
[`ConstrainedModel`](@ref), [`AbstractModel`](@ref).
"""
struct Branch{
    O,
    A<:Formula,
    FM<:AbstractModel
} <: ConstrainedModel{O,FM}
    antecedent::A
    posconsequent::FM
    negconsequent::FM
    info::NamedTuple

    function Branch(
        antecedent::Union{AbstractSyntaxToken,Formula},
        posconsequent::Any,
        negconsequent::Any,
        info::NamedTuple = (;),
    )
        A = typeof(antecedent)
        posconsequent = wrap(posconsequent)
        negconsequent = wrap(negconsequent)
        O = Union{outcometype(posconsequent),outcometype(negconsequent)}
        FM = typeintersect(Union{propagate_feasiblemodels(posconsequent),propagate_feasiblemodels(negconsequent)}, AbstractModel{<:O})
        check_model_constraints(Branch{O}, typeof(posconsequent), FM, O)
        check_model_constraints(Branch{O}, typeof(negconsequent), FM, O)
        new{O,A,FM}(antecedent, posconsequent, negconsequent, info)
    end

    function Branch(
        antecedent::Union{AbstractSyntaxToken,Formula},
        (posconsequent, negconsequent)::Tuple{Any,Any},
        info::NamedTuple = (;),
    )
        Branch(antecedent, posconsequent, negconsequent, info)
    end

end

antecedent(m::Branch) = m.antecedent

"""
    posconsequent(m::Branch)::AbstractModel

Return the positive consequent of a branch;
that is, the model to be applied if the antecedent evaluates to `true`.

See also
[`antecedent`](@ref),
[`Branch`](@ref).
"""
posconsequent(m::Branch) = m.posconsequent

"""
    negconsequent(m::Branch)::AbstractModel

Return the negative consequent of a branch;
that is, the model to be applied if the antecedent evaluates to `false`.

See also
[`antecedent`](@ref),
[`Branch`](@ref).
"""
negconsequent(m::Branch) = m.negconsequent

antecedenttype(::Type{M}) where {M<:Branch{O,A}} where {O,A} = A
antecedenttype(m::Branch) = antecedenttype(typeof(m))

issymbolic(::Branch) = true

isopen(m::Branch) = isopen(posconsequent(m)) || isopen(negconsequent(m))

function apply(
    m::Branch,
    i::AbstractInterpretation;
    check_args::Tuple = (),
    check_kwargs::NamedTuple = (;),
    kwargs...
)
    if antecedenttops(m, i, check_args...; check_kwargs...)
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
    m::Branch,
    d::AbstractInterpretationSet,
    i_instance::Integer;
    check_args::Tuple = (),
    check_kwargs::NamedTuple = (;),
    kwargs...
)
    if antecedenttops(m, d, i_instance, check_args...; check_kwargs...)
        apply(posconsequent(m), d, i_instance;
            check_args = check_args,
            check_kwargs = check_kwargs,
            kwargs...
        )
    else
        apply(negconsequent(m), d, i_instance;
            check_args = check_args,
            check_kwargs = check_kwargs,
            kwargs...
        )
    end
end

function apply(
    m::Branch,
    d::AbstractInterpretationSet;
    check_args::Tuple = (),
    check_kwargs::NamedTuple = (;),
    kwargs...
)
    cs = antecedenttops(m, d, check_args...; check_kwargs...)
    cpos = findall((c)->c==true, cs)
    cneg = findall((c)->c==false, cs)
    out = Array{outputtype(m)}(undef,length(cs))
    if !isempty(cpos)
        out[cpos] .= apply(
            posconsequent(m),
            slicedataset(d, cpos; return_view = true);
            check_args = check_args,
            check_kwargs = check_kwargs,
            kwargs...
        )
    end
    if !isempty(cneg)
        out[cneg] .= apply(
            negconsequent(m),
            slicedataset(d, cneg; return_view = true);
            check_args = check_args,
            check_kwargs = check_kwargs,
            kwargs...
        )
    end
    out
end

# Helper
function Base.getindex(
    m::Branch{O,A},
    idxs::AbstractVector{<:Integer},
) where {O,A<:LeftmostLinearForm}
    a = antecedent(m)
    Branch{O}(A(children(a)[idxs]), posconsequent(m), negconsequent(m))
end

############################################################################################
############################################################################################

antecedenttops(m::Union{Rule,Branch}, i::AbstractInterpretation, args...; kwargs...) = istop(check(antecedent(m), i, args...; kwargs...))
antecedenttops(m::Union{Rule,Branch}, d::AbstractInterpretationSet, i_instance::Integer, args...; kwargs...) = istop(check(antecedent(m), d, i_instance, args...; kwargs...))
antecedenttops(m::Union{Rule,Branch}, d::AbstractInterpretationSet, args...; kwargs...) = istop.(check(antecedent(m), d, args...; kwargs...))

antecedenttops(::Union{Rule{O,<:TopFormula},Branch{O,<:TopFormula}}, i::AbstractInterpretation, args...; kwargs...) where {O} = true
antecedenttops(::Union{Rule{O,<:TopFormula},Branch{O,<:TopFormula}}, d::AbstractInterpretationSet, i_instance::Integer, args...; kwargs...) where {O} = true
antecedenttops(::Union{Rule{O,<:TopFormula},Branch{O,<:TopFormula}}, d::AbstractInterpretationSet, args...; kwargs...) where {O} = fill(true, ninstances(d))

############################################################################################
############################################################################################

"""
    struct DecisionList{
        O,
        A<:Formula,
        FM<:AbstractModel
    } <: ConstrainedModel{O,FM}
        rulebase::Vector{Rule{_O,_C,_FM} where {_O<:O,_C<:A,_FM<:FM}}
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

where the antecedents are formulas to be, and the consequents are the feasible
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
    A<:Formula,
    FM<:AbstractModel
} <: ConstrainedModel{O,FM}
    rulebase::Vector{Rule{_O,_C,_FM} where {_O<:O,_C<:A,_FM<:FM}}
    defaultconsequent::FM
    info::NamedTuple

    function DecisionList(
        rulebase::Vector{<:Rule},
        defaultconsequent::Any,
        info::NamedTuple = (;),
    )
        defaultconsequent = wrap(defaultconsequent)
        O = Union{outcometype(defaultconsequent),outcometype.(rulebase)...}
        A = Union{antecedenttype.(rulebase)...}
        FM = typeintersect(Union{propagate_feasiblemodels(defaultconsequent),propagate_feasiblemodels.(rulebase)...}, AbstractModel{<:O})
        # FM = typeintersect(Union{propagate_feasiblemodels(defaultconsequent),propagate_feasiblemodels.(rulebase)...}, AbstractModel{O})
        # FM = Union{propagate_feasiblemodels(defaultconsequent),propagate_feasiblemodels.(rulebase)...}
        check_model_constraints.(DecisionList{O}, typeof.(rulebase), FM, O)
        check_model_constraints(DecisionList{O}, typeof(defaultconsequent), FM, O)
        new{O,A,FM}(rulebase, defaultconsequent, info)
    end
end

rulebase(m::DecisionList) = m.rulebase
defaultconsequent(m::DecisionList) = m.defaultconsequent

antecedenttype(::Type{M}) where {M<:DecisionList{O,A}} where {O,A} = A
antecedenttype(m::DecisionList) = antecedenttype(typeof(m))

issymbolic(::DecisionList) = true

isopen(m::DecisionList) = isopen(defaultconsequent(m))

function apply(
    m::DecisionList,
    i::AbstractInterpretation;
    check_args::Tuple = (),
    check_kwargs::NamedTuple = (;),
)
    for rule in rulebase(m)
        if antecedenttops(rule, i, check_args...; check_kwargs...)
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
) where {O}
    nsamp = ninstances(d)
    pred = Vector{O}(undef, nsamp)
    uncovered_idxs = 1:nsamp

    for rule in rulebase(m)
        length(uncovered_idxs) == 0 && break

        uncovered_d = slicedataset(d, uncovered_idxs; return_view = true)

        idxs_sat = findall(
            antecedenttops(rule, uncovered_d, check_args...; check_kwargs...)
        )
        idxs_sat = uncovered_idxs[idxs_sat]
        uncovered_idxs = setdiff(uncovered_idxs, idxs_sat)

        map((i)->(pred[i] = outcome(consequent(rule))), idxs_sat)
    end

    length(uncovered_idxs) != 0 &&
        map((i)->(pred[i] = outcome(defaultconsequent(m))), uncovered_idxs)

    return pred
end

#TODO: write apply! for the other models
#TODO write in docstring that possible values for compute_metrics are: :append, true, false
function apply!(
    m::DecisionList{O},
    d::AbstractInterpretationSet;
    check_args::Tuple = (),
    check_kwargs::NamedTuple = (;),
    compute_metrics::Union{Symbol,Bool} = false,
) where {O}
    nsamp = ninstances(d)
    pred = Vector{O}(undef, nsamp)
    delays = Vector{Integer}(undef, nsamp)
    uncovered_idxs = 1:nsamp
    rules = rulebase(m)

    for (n, rule) in enumerate(rules)
        length(uncovered_idxs) == 0 && break

        uncovered_d = slicedataset(d, uncovered_idxs; return_view = true)

        idxs_sat = findall(
            antecedenttops(rule, uncovered_d, check_args...; check_kwargs...)
        )
        idxs_sat = uncovered_idxs[idxs_sat]
        uncovered_idxs = setdiff(uncovered_idxs, idxs_sat)

        delays[idxs_sat] .= (n-1)
        map((i)->(pred[i] = outcome(consequent(rule))), idxs_sat)
    end

    if length(uncovered_idxs) != 0
        map((i)->(pred[i] = outcome(defaultconsequent(m))), uncovered_idxs)
        length(rules) == 0 ? (delays .= 0) : (delays[uncovered_idxs] .= length(rules))
    end

    (length(rules) != 0) && (delays = delays ./ length(rules))

    iprev = info(m)
    inew = compute_metrics == false ? iprev : begin
        if :delays ∉ keys(iprev)
            merge(iprev, (; delays = delays))
        else
            prev = iprev[:delays]
            ntwithout = (; [p for p in pairs(nt) if p[1] != :delays]...)
            if compute_metrics == :append
                merge(ntwithout,(; delays = [prev..., delays...]))
            elseif compute_metrics == true
                merge(ntwithout,(; delays = delays))
            end
        end
    end

    inewnew = begin
        if :pred ∉ keys(inew)
            merge(inew, (; pred = pred))
        else
            prev = inew[:pred]
            ntwithout = (; [p for p in pairs(nt) if p[1] != :pred]...)
            if compute_metrics == :append
                merge(ntwithout,(; pred = [prev..., pred...]))
            elseif compute_metrics == true
                merge(ntwithout,(; pred = pred))
            end
        end
    end

    return DecisionList(rules, defaultconsequent(m), inewnew)
end

# TODO: if delays not in info(m) ?
function meandelaydl(m::DecisionList)
    i = info(m)

    if :delays in keys(i)
        return mean(i[:delays])
    end
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

where the antecedents are formulas to be, and the consequents are the feasible
local outcomes of the block.

In practice, a `DecisionTree` simply wraps a constrained
sub-tree of `Branch` and `LeafModel`:

    struct DecisionTree{
    O,
        A<:Formula,
        FFM<:LeafModel
    } <: ConstrainedModel{O,Union{<:Branch{<:O,<:A},<:FFM}}
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
    A<:Formula,
    FFM<:LeafModel
} <: ConstrainedModel{O,Union{<:Branch{<:O,<:A},<:FFM}}
    root::M where {M<:Union{FFM,Branch}}
    info::NamedTuple

    function DecisionTree(
        root::Union{FFM,Branch{O,A,Union{Branch{<:O,A2},FFM}}},
        info::NamedTuple = (;),
    ) where {O,A<:Formula,A2<:A,FFM<:LeafModel{<:O}}
        new{O,root isa LeafModel ? Formula : A,FFM}(root, info)
    end

    function DecisionTree(
        root::Any,
        info::NamedTuple = (;),
    )
        root = wrap(root)
        M = typeof(root)
        O = outcometype(root)
        A = (root isa LeafModel ? Formula : antecedenttype(M))
        # FM = typeintersect(Union{M,feasiblemodelstype(M)}, AbstractModel{<:O})
        FM = typeintersect(Union{propagate_feasiblemodels(M)}, AbstractModel{<:O})
        FFM = typeintersect(FM, LeafModel{<:O})
        @assert M <: Union{<:FFM,<:Branch{<:O,<:A,<:Union{Branch,FFM}}} "" *
            "Cannot instantiate DecisionTree{$(O),$(A),$(FFM)}(...) with root of " *
            "type $(typeof(root)). Note that the should be either a LeafModel or a " *
            "bounded Branch. " *
            "$(M) <: $(Union{LeafModel,Branch{<:O,<:A,<:Union{Branch,FFM}}}) should hold."
        check_model_constraints(DecisionTree{O}, typeof(root), FM, O)
        new{O,A,FFM}(root, info)
    end
end

root(m::DecisionTree) = m.root

antecedenttype(::Type{M}) where {M<:DecisionTree{O,A}} where {O,A} = A
antecedenttype(::Type{M}) where {M<:DecisionTree{O,A,FFM}} where {O,A,FFM} = A
antecedenttype(m::DecisionTree) = antecedenttype(typeof(m))

issymbolic(::DecisionTree) = true

isopen(::DecisionTree) = false

# TODO join these two or note that they are kept separate due to possible dispatch ambiguities.
function apply(
    m::DecisionTree,
    #id::Union{AbstractInterpretation,AbstractInterpretationSet};
    id::AbstractInterpretation;
    kwargs...
)
    apply(root(m), id; kwargs...)
end

function apply(
    m::DecisionTree,
    d::AbstractInterpretationSet;
    kwargs...,
)
    apply(root(m), d; kwargs...)
end

function nnodes(t::DecisionTree)
    nsubmodels(t)
end

function nleaves(t::DecisionTree)
    nleafmodels(t)
end

function height(t::DecisionTree)
    subtreeheight(t)
end

############################################################################################

"""
A `Decision Forest` is a symbolic model that wraps an ensemble of models

    struct DecisionForest{
        O,
        A<:Formula,
        FFM<:LeafModel
    } <: ConstrainedModel{O,Union{<:Branch{<:O,<:A},<:FFM}}
        trees::Vector{<:DecisionTree}
        info::NamedTuple
    end


See also [`ConstrainedModel`](@ref), [`MixedSymbolicModel`](@ref), [`DecisionList`](@ref),
[`DecisionTree`](@ref)
"""
struct DecisionForest{
    O,
    A<:Formula,
    FFM<:LeafModel
} <: ConstrainedModel{O,Union{<:Branch{<:O,<:A},<:FFM}}
    trees::Vector{<:DecisionTree}
    info::NamedTuple

    function DecisionForest(
        trees::Vector{<:DecisionTree},
        info::NamedTuple = (;),
    )
        @assert length(trees) > 0 "Cannot instantiate forest with no trees!"
        O = Union{outcometype.(trees)...}
        A = Union{antecedenttype.(trees)...}
        FM = typeintersect(Union{propagate_feasiblemodels.(trees)...}, AbstractModel{<:O})
        FFM = typeintersect(FM, LeafModel{<:O})
        check_model_constraints.(DecisionForest{O}, typeof.(trees), FM, O)
        new{O,A,FFM}(trees, info)
    end
end

trees(forest::DecisionForest) = forest.trees

antecedenttype(::Type{M}) where {M<:DecisionForest{O,A}} where {O,A} = A
antecedenttype(m::DecisionForest) = antecedenttype(typeof(m))

issymbolic(::DecisionForest) = false

# TODO check these two.
function apply(
    f::DecisionForest,
    id::AbstractInterpretation;
    kwargs...
)
    bestguess([apply(t, d; kwargs...) for t in trees(f)])
end

function apply(
    f::DecisionForest,
    d::AbstractInterpretationSet;
    kwargs...
)
    pred = hcat([apply(t, d; kwargs...) for t in trees(f)]...)
    return [bestguess(pred[i,:]) for i in 1:size(pred,1)]
end

function nnodes(f::DecisionForest)
    nsubmodels(f)
end

function nleaves(f::DecisionForest)
    nleafmodels(f)
end

function height(f::DecisionForest)
    subtreeheight(f)
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

where the antecedents are formulas to be checked, and the consequents are the feasible
local outcomes of the block.

In Sole.jl, this logic can implemented using `ConstrainedModel`s such as
`Rule`s, `Branch`s, `DecisionList`s, `DecisionTree`s, and the be wrapped into
a `MixedSymbolicModel`:

    struct MixedSymbolicModel{O,FM<:AbstractModel} <: ConstrainedModel{O,FM}
        root::M where {M<:Union{LeafModel{<:O},ConstrainedModel{<:O,<:FM}}}
        info::NamedTuple
    end

Note that `FM` refers to the Feasible Models (`FM`) allowed in the model's sub-tree.

See also [`ConstrainedModel`](@ref), [`DecisionTree`](@ref), [`DecisionList`](@ref).
"""
struct MixedSymbolicModel{O,FM<:AbstractModel} <: ConstrainedModel{O,FM}
    root::M where {M<:Union{LeafModel{<:O},ConstrainedModel{<:O,<:FM}}}
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
