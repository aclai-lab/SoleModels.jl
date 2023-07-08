import SoleLogics: check, syntaxstring
using SoleData: slicedataset

"""
    abstract type AbstractAntecedent <: AbstractFormula end

A (boolean) antecedent, that is,
a condition based on a formula of a given logic, that is
to be checked on a logical interpretation,
evaluating to a boolean truth value (`true`/`false`).

See also
[`TrueAntecedent`](@ref),
[`TruthAntecedent`](@ref),
[`check`](@ref),
[`formula`](@ref),
[`syntaxstring`](@ref).
"""
abstract type AbstractAntecedent <: AbstractFormula end

function SoleLogics.tree(f::AbstractAntecedent)
    return error("Cannot convert object of type $(typeof(f)) to a SyntaxTree.")
end

function syntaxstring(a::AbstractAntecedent; kwargs...)
    return error("Please, provide method syntaxstring(::$(typeof(a)); kwargs...).")
end

function Base.show(io::IO, a::AbstractAntecedent)
    print(io, "$(typeof(a))($(syntaxstring(a)))")
end

# Check on a boolean antecedent
function check(a::AbstractAntecedent, i::AbstractInterpretation, args...; kwargs...)
    return error("Please, provide method check(::$(typeof(a)), " *
        "i::$(typeof(i)), args...; kwargs...).")
end
function check(
    a::AbstractAntecedent,
    d::AbstractInterpretationSet,
    args...;
    kwargs...
)
    map(
        i_instance->check(a, slicedataset(d, [i_instance]; return_view = true), args...; kwargs...)[1],
        1:ninstances(d)
    )
end

"""
    formula(a::AbstractAntecedent)::AbstractFormula

Return the logical formula (see [`SoleLogics`](@ref) package) of a given
logical antecedent.

See also
[`syntaxstring`](@ref),
[`AbstractAntecedent`](@ref).
"""
function formula(a::AbstractAntecedent)::AbstractFormula
    return error("Please, provide method formula(::$(typeof(a))).")
end

"""
    struct TrueAntecedent <: AbstractAntecedent end

A true condition is the boolean condition that always yields `true`.

See also
[`TruthAntecedent`](@ref),
[`AbstractAntecedent`](@ref).
"""
struct TrueAntecedent <: AbstractAntecedent end

tree(::TrueAntecedent) = SyntaxTree(⊤)
check(::TrueAntecedent, i::AbstractInterpretation, args...; kwargs...) = true
check(::TrueAntecedent, d::AbstractInterpretationSet, args...; kwargs...) =
    fill(true, ninstances(d))

"""
    struct TruthAntecedent{F<:AbstractFormula} <: AbstractAntecedent
        formula::F
        checkmode::C,
    end

An antecedent representing a condition that, on a given logical interpretation,
checking a logical formula evaluates to the `top` of the logic's algebra.

The evaluation can be done with respect to a checkmode (e.g., evaluate the formula
on a specific world).

See also
[`formula`](@ref),
[`CheckMode`](@ref),
[`AbstractAntecedent`](@ref).
"""
struct TruthAntecedent{
    F<:AbstractFormula,
    C<:CheckMode,
} <: AbstractAntecedent

    formula::F

    checkmode::C

    function TruthAntecedent{F,C}(
        formula::F,
        checkmode::C,
    ) where {F<:AbstractFormula,C<:CheckMode}
        new{F,C}(formula)
    end

    function TruthAntecedent{F}(
        formula::F,
        checkmode::C = GlobalCheck(),
    ) where {F<:AbstractFormula,C<:CheckMode}
        TruthAntecedent{F,C}(formula)
    end

    function TruthAntecedent(
        formula::F,
        checkmode::C = GlobalCheck(),
    ) where {F<:AbstractFormula,C<:CheckMode}
        TruthAntecedent{F}(formula)
    end
end

function syntaxstring(a::TruthAntecedent; kwargs...)
    "@$(syntaxstring(a.checkmode))($(syntaxstring(a.formula)))"
end
function syntaxstring(a::TruthAntecedent{F,C}; kwargs...) where {F,C<:GlobalCheck}
    syntaxstring(a.formula)
end


formula(a::TruthAntecedent) = a.formula
tree(a::TruthAntecedent) = tree(a.formula)
checkmode(a::TruthAntecedent) = a.checkmode

function check(a::TruthAntecedent, i::AbstractInterpretation, args...; kwargs...)
    istop(check(checkmode(φ), formula(a), i, args...; kwargs...))
end
function check(
    a::TruthAntecedent,
    d::AbstractInterpretationSet,
    args...;
    kwargs...,
)
    map(istop, check(checkmode(φ), formula(a), d, args...; kwargs...))
end

############################################################################################

# Helpers
convert(::Type{AbstractAntecedent}, f::AbstractFormula) = TruthAntecedent(f)
convert(::Type{AbstractAntecedent}, tok::AbstractSyntaxToken) = TruthAntecedent(SyntaxTree(tok))
convert(::Type{AbstractAntecedent}, ::typeof(⊤)) = TrueAntecedent()
