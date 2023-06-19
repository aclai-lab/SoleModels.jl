
############################################################################################
# Check modes
############################################################################################

using SoleLogics: AbstractMultiModalFrame

"""
Abstract type for model checking modes.

See also
[`GlobalCheck`](@ref),
[`CenteredCheck`](@ref),
[`WorldCheck`](@ref).
"""
abstract type CheckMode end

"""
A model checking mode where the formula to check is global and no specific
world is required.

See also
[`CheckMode`](@ref).
"""
struct GlobalCheck               <: CheckMode end;

abstract type GroundedCheck <: CheckMode end

"""
A model checking mode where the formula is checked on the central world;
note that the central world must be defined via

See also
[`CheckMode`](@ref).
"""
struct CenteredCheck                   <: GroundedCheck end;

function getworld(fr::AbstractMultiModalFrame{W}, checkmode::CenteredCheck) where {W<:AbstractWorld}
    SoleLogics.centeredworld(fr)
end

"""
A model checking mode where the formula is checked on the central world

See also
[`CheckMode`](@ref),
[`CenteredCheck`](@ref).
"""
struct WorldCheck{W<:AbstractWorld}  <: GroundedCheck
    w::W
end

function getworld(::AbstractMultiModalFrame{W}, checkmode::WorldCheck{W}) where {W<:AbstractWorld}
    checkmode.w
end

function check(
    φ::SoleLogics.AbstractFormula,
    X::AbstractLogiset,
    i_instance::Integer,
    checkmode::GlobalCheck,
    args...;
    kwargs...
)
    check(φ, X, i_instance, nothing, args...; kwargs...)
end

function check(
    φ::SoleLogics.AbstractFormula,
    X::AbstractLogiset,
    i_instance::Integer,
    checkmode::GroundedCheck,
    args...;
    kwargs...
)
    check(φ, X, i_instance, getworld(frame(X, i_instance), checkmode), args...; kwargs...)
end

############################################################################################

import SoleLogics: tree

struct AnchoredFormula{
    F<:AbstractFormula,
    C<:CheckMode,
} <: AbstractSyntaxStructure

    formula::F

    checkmode::C
end

# tree(f::AnchoredFormula) = tree(f.formula)
function SoleLogics.tree(f::AnchoredFormula)
    error("Cannot convert object of type AnchoredFormula to a SyntaxTree.")
end

function syntaxstring(f::AnchoredFormula; kwargs...)
    "@$(f.checkmode)($(syntaxstring(f.formula)))"
end

function check(
    φ::AnchoredFormula,
    X::AbstractLogiset,
    i_instance::Integer,
    args...;
    kwargs...
)
    check(φ.formula, X, i_instance, φ.checkmode, args...; kwargs...)
end
