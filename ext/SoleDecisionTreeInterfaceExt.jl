module SoleDecisionTreeInterfaceExt

using SoleModels, SoleDecisionTreeInterface

# TODO document, together with issymbolic and listrules
"""
    solemodel(m::Any)

This function translates a symbolic model to a symbolic model using the structures defined in SoleModel.jl.
# Interface

See also [`AbstractModel`](@ref), [`ConstantModel`](@ref), [`FunctionModel`](@ref),
[`LeafModel`](@ref).
"""
function solemodel(o::Any, args...; kwargs...)
    try
        convert(FM, wrap(o))
        # FM TODO
    catch e
        if e isa MethodError
            throw(MethodError("Please, provide solemodel(::$(typeof(o)))"))
        else
            rethrow(e)
        end
    end
end

end # module