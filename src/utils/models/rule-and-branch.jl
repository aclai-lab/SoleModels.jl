import Base: convert, length, getindex

using SoleData: slicedataset

import SoleLogics: check, syntaxstring
using SoleLogics: LeftmostLinearForm, LeftmostConjunctiveForm, LeftmostDisjunctiveForm

import SoleLogics: nleaves, height

############################################################################################
####################################### Rule ###############################################
############################################################################################

"""
    struct Rule{O} <: AbstractModel{O}
        antecedent::Formula
        consequent::M where {M<:AbstractModel{<:O}}
        info::NamedTuple
    end

A `Rule` is one of the fundamental building blocks of symbolic modeling, and has
the semantics:

    IF (antecedent) THEN (consequent) END

where the [`antecedent`](@ref) is a formula to be checked, and the [`consequent`](@ref) is
the local outcome of the block.

# Examples
```julia-repl
julia> Rule(CONJUNCTION(Atom("p"), Atom("q")), ConstantModel(2))
▣ (p) ∧ (q)  ↣  2
```

See also [`AbstractModel`](@ref), [`antecedent`](@ref), [`consequent`](@ref),
`SoleLogics.Formula`.
"""
struct Rule{O} <: AbstractModel{O}
    antecedent::Formula
    consequent::M where {M<:AbstractModel{<:O}}
    info::NamedTuple

    function Rule{O}(
        antecedent::Formula,
        consequent::Any,
        info::NamedTuple = (;),
    ) where {O}
        consequent = wrap(consequent, AbstractModel{O})
        new{O}(antecedent, consequent, info)
    end

    function Rule(
        antecedent::Formula,
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
        antecedent = ⊤
        consequent = wrap(consequent)
        O = outcometype(consequent)
        Rule{O}(antecedent, consequent, info)
    end
end

iscomplete(m::Rule) = false

"""
    antecedent(m::Union{Rule,Branch})::Formula

Return the antecedent of a [`Rule`](@ref) or a [`Branch`](@ref), that is, the formula to be
checked upon applying the model.

See also [`apply`](@ref), [`Branch`](@ref), [`checkantecedent`](@ref), [`consequent`](@ref),
[`Rule`](@ref).
"""
antecedent(m::Rule) = m.antecedent

"""
    consequent(m::Rule)::AbstractModel

Return the consequent of `m`.

See also [`antecedent`](@ref), [`Rule`](@ref).
"""
consequent(m::Rule) = m.consequent

"""
    checkantecedent(
        m::Union{Rule,Branch},
        args...;
        kwargs...
    )
        check(antecedent(m), args...; kwargs...)
    end

Check the [`antecedent`](@ref) of a [`Rule`](@ref) or a [`Branch`](@ref), on an instance or
dataset.

See also [`antecedent`](@ref), [`Rule`](@ref), [`Branch`](@ref).
"""
function checkantecedent end

function apply(
    m::Rule,
    i::AbstractInterpretation;
    check_args::Tuple = (),
    check_kwargs::NamedTuple = (;),
    kwargs...
)
    if checkantecedent(m, i, check_args...; check_kwargs...)
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
    if checkantecedent(m, d, i_instance, check_args...; check_kwargs...)
        apply(consequent(m), d, i_instance;
            check_args = check_args,
            check_kwargs = check_kwargs,
            kwargs...
        )
    else
        nothing
    end
end

function apply!(
    m::Rule,
    d::AbstractInterpretationSet,
    y::AbstractVector;
    check_args::Tuple = (),
    check_kwargs::NamedTuple = (;),
    mode = :replace,
    leavesonly = false,
    kwargs...
)
    # @assert length(y) == ninstances(d) "$(length(y)) == $(ninstances(d))"
    if mode == :replace
        recursivelyemptysupports!(m, leavesonly)
        mode = :append
    end
    checkmask = checkantecedent(m, d, check_args...; check_kwargs...)
    # @show checkmask
    preds = Vector{outputtype(m)}(fill(nothing, ninstances(d)))
    if any(checkmask)
        preds[checkmask] .= apply!(consequent(m), slicedataset(d, checkmask; return_view = true), y[checkmask];
            check_args = check_args,
            check_kwargs = check_kwargs,
            mode = mode,
            leavesonly = leavesonly,
            kwargs...
        )
    end
    return __apply!(m, mode, preds, y, leavesonly)
end

############################################################################################
###################################### Branch ##############################################
############################################################################################

"""
    struct Branch{O} <: AbstractModel{O}
        antecedent::Formula
        posconsequent::M where {M<:AbstractModel{<:O}}
        negconsequent::M where {M<:AbstractModel{<:O}}
        info::NamedTuple
    end

A `Branch` is one of the fundamental building blocks of symbolic modeling, and has
the semantics:

    IF (antecedent) THEN (positive consequent) ELSE (negative consequent) END

where the [`antecedent`](@ref) is a formula to be checked and the [`consequent`](@ref)s are
the feasible local outcomes of the block. If checking the antecedent evaluates to the top
of the algebra, then the positive consequent is applied; otherwise, the negative
consequent is applied.

See also [`AbstractModel`](@ref), [`antecedent`](@ref), `SoleLogics.check`,
`SoleLogics.Formula`, [`negconsequent`](@ref), [`posconsequent`](@ref), [`Rule`](@ref).
"""
struct Branch{O} <: AbstractModel{O}
    antecedent::Formula
    posconsequent::M where {M<:AbstractModel{<:O}}
    negconsequent::M where {M<:AbstractModel{<:O}}
    info::NamedTuple

    function Branch{O}(
        antecedent::Formula,
        posconsequent::Any,
        negconsequent::Any,
        info::NamedTuple = (;),
    ) where {O}
        A = typeof(antecedent)
        posconsequent = wrap(posconsequent)
        negconsequent = wrap(negconsequent)
        new{O}(antecedent, posconsequent, negconsequent, info)
    end

    function Branch(
        antecedent::Formula,
        posconsequent::Any,
        negconsequent::Any,
        info::NamedTuple = (;),
    )
        A = typeof(antecedent)
        posconsequent = wrap(posconsequent)
        negconsequent = wrap(negconsequent)
        O = Union{outcometype(posconsequent),outcometype(negconsequent)}
        Branch{O}(antecedent, posconsequent, negconsequent, info)
    end

    function Branch(
        antecedent::Formula,
        (posconsequent, negconsequent)::Tuple{Any,Any},
        info::NamedTuple = (;),
    )
        Branch(antecedent, posconsequent, negconsequent, info)
    end

end

antecedent(m::Branch) = m.antecedent

"""
    posconsequent(m::Branch)::AbstractModel

Return the positive consequent of a branch, that is, the model to be applied if the
[`antecedent`](@ref) evaluates to `true`.

See also [`antecedent`](@ref), [`Branch`](@ref), [`negconsequent`](@ref).
"""
posconsequent(m::Branch) = m.posconsequent

"""
    negconsequent(m::Branch)::AbstractModel

Return the negative [`consequent`](@ref) of a branch; that is, the model to be applied if
the antecedent evaluates to `false`.

See also [`antecedent`](@ref), [`Branch`](@ref), [`posconsequent`](@ref).
"""
negconsequent(m::Branch) = m.negconsequent

iscomplete(m::Branch) = iscomplete(posconsequent(m)) && iscomplete(negconsequent(m))

function apply(
    m::Branch,
    i::AbstractInterpretation;
    check_args::Tuple = (),
    check_kwargs::NamedTuple = (;),
    kwargs...
)
    if checkantecedent(m, i, check_args...; check_kwargs...)
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
    if checkantecedent(m, d, i_instance, check_args...; check_kwargs...)
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
    checkmask = checkantecedent(m, d, check_args...; check_kwargs...)
    preds = Vector{outputtype(m)}(undef,length(checkmask))
    preds[checkmask] .= apply(
        posconsequent(m),
        slicedataset(d, checkmask; return_view = true, allow_no_instances = true);
        check_args = check_args,
        check_kwargs = check_kwargs,
        kwargs...
    )
    preds[(!).(checkmask)] .= apply(
        negconsequent(m),
        slicedataset(d, (!).(checkmask); return_view = true, allow_no_instances = true);
        check_args = check_args,
        check_kwargs = check_kwargs,
        kwargs...
    )
    preds
end

function apply!(
    m::Branch,
    d::AbstractInterpretationSet,
    y::AbstractVector;
    check_args::Tuple = (),
    check_kwargs::NamedTuple = (;),
    mode = :replace,
    leavesonly = false,
    # show_progress = true,
    kwargs...
)
    # @assert length(y) == ninstances(d) "$(length(y)) == $(ninstances(d))"
    if mode == :replace
        recursivelyemptysupports!(m, leavesonly)
        mode = :append
    end
    checkmask = checkantecedent(m, d, check_args...; check_kwargs...)
    preds = Vector{outputtype(m)}(undef,length(checkmask))
    @sync begin
        if any(checkmask)
            l = Threads.@spawn apply!(
                posconsequent(m),
                slicedataset(d, checkmask; return_view = true),
                y[checkmask];
                check_args = check_args,
                check_kwargs = check_kwargs,
                mode = mode,
                leavesonly = leavesonly,
                kwargs...
            )
        end
        ncheckmask = (!).(checkmask)
        if any(ncheckmask)
            r = Threads.@spawn apply!(
                negconsequent(m),
                slicedataset(d, ncheckmask; return_view = true),
                y[ncheckmask];
                check_args = check_args,
                check_kwargs = check_kwargs,
                mode = mode,
                leavesonly = leavesonly,
                kwargs...
            )
        end
        if any(checkmask)
            preds[checkmask] .= fetch(l)
        end
        if any(ncheckmask)
            preds[ncheckmask] .= fetch(r)
        end
    end
    return __apply!(m, mode, preds, y, leavesonly)
end

############################################################################################
############################################################################################
############################################################################################

checkantecedent(
    m::Union{Rule,Branch},
    i::AbstractInterpretation,
    args...;
    kwargs...
) = check(antecedent(m), i, args...; kwargs...)
checkantecedent(
    m::Union{Rule,Branch},
    d::AbstractInterpretationSet,
    i_instance::Integer,
    args...;
    kwargs...
) = check(antecedent(m), d, i_instance, args...; kwargs...)
checkantecedent(
    m::Union{Rule,Branch},
    d::AbstractInterpretationSet,
    args...;
    kwargs...
) = check(antecedent(m), d, args...; kwargs...)
