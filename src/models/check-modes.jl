import SoleLogics: syntaxstring

using SoleLogics: AbstractMultiModalFrame

"""
Abstract type for model checking modes.

See also
[`GlobalCheck`](@ref),
[`CenteredCheck`](@ref),
[`WorldCheck`](@ref).
"""
abstract type CheckMode end

function check(
    checkmode::CheckMode,
    φ::SoleLogics.AbstractFormula,
    X,
    i_instance::Integer,
    args...;
    kwargs...
)
    check(φ, X, i_instance, getworld(frame(X, i_instance), checkmode), args...; kwargs...)
end

"""
A model checking mode where the formula to check is global and no specific
world is required.

See also
[`CheckMode`](@ref).
"""
struct GlobalCheck          <: CheckMode end;

function getworld(fr::AbstractMultiModalFrame{W}, checkmode::GlobalCheck) where {W<:AbstractWorld}
    nothing
end

syntaxstring(::GlobalCheck) = "global"

abstract type GroundedCheck <: CheckMode end

"""
A model checking mode where the formula is checked on the central world;
(whenever the notion of "central" makes sense).

See also
[`CheckMode`](@ref).
"""
struct CenteredCheck                   <: GroundedCheck end;

syntaxstring(::CenteredCheck) = "center"

function getworld(fr::AbstractMultiModalFrame{W}, checkmode::CenteredCheck) where {W<:AbstractWorld}
    SoleLogics.centeredworld(fr)
end

"""
A model checking mode where the formula is checked on a specific world `w`.

See also
[`CheckMode`](@ref),
[`centeredworld`](@ref),
[`CenteredCheck`](@ref).
"""
struct WorldCheck{W<:AbstractWorld}  <: GroundedCheck
    w::W
end
syntaxstring(checkmode::WorldCheck) = "$(getworld(checkmode))"

function getworld(::AbstractMultiModalFrame{W}, checkmode::WorldCheck{W}) where {W<:AbstractWorld}
    checkmode.w
end
