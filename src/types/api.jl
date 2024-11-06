
# TODO document, together with issymbolic and listrules
"""
    solemodel(m::Any)

This function translates a symbolic model to a symbolic model using the structures defined in SoleModel.jl.
# Interface

See also [`AbstractModel`](@ref), [`ConstantModel`](@ref), [`FunctionModel`](@ref),
[`LeafModel`](@ref).
"""
solemodel(o::Any, FM::Type{<:AbstractModel}) = convert(FM, wrap(o))
