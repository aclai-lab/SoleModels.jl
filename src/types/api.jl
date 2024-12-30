# TODO document, together with issymbolic and listrules
"""
    haslistrules(m::Any)

This function extracts symbolic final rules from a symbolic model..

See also [`AbstractModel`](@ref), [`listrules`](@ref)
[`LeafModel`](@ref).
"""
haslistrules(m) = false
haslistrules(m::AbstractModel) = true

# TODO document, together with issymbolic and listrules
"""
    solemodel(m::Any)

This function translates a symbolic model to a symbolic model using the structures defined in SoleModel.jl.

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


import SoleLogics: alphabet,
                    atoms,
                    connectives,
                    # leaves,
                    natoms,
                    nconnectives
                    # nleaves

doc_syntax_utils_models = """
    atoms(::AbstractModel)
    connectives(::AbstractModel)
    syntaxleaves(::AbstractModel)
    
    natoms(::AbstractModel)
    nconnectives(::AbstractModel)
    nsyntaxleaves(::AbstractModel)

See also
[`AbstractModel`](@ref),
[`listrules`](@ref).
"""

"""$doc_syntax_utils_models"""
atoms(m::AbstractModel) = error("Please, provide method atoms(::$(typeof(m))).")
"""$doc_syntax_utils_models"""
connectives(m::AbstractModel) = error("Please, provide method connectives(::$(typeof(m))).")
"""$doc_syntax_utils_models"""
syntaxleaves(m::AbstractModel) = error("Please, provide method syntaxleaves(::$(typeof(m))).")

"""$doc_syntax_utils_models"""
natoms(m::AbstractModel) = error("Please, provide method natoms(::$(typeof(m))).")
"""$doc_syntax_utils_models"""
nconnectives(m::AbstractModel) = error("Please, provide method nconnectives(::$(typeof(m))).")
"""$doc_syntax_utils_models"""
nsyntaxleaves(m::AbstractModel) = error("Please, provide method nsyntaxleaves(::$(typeof(m))).")


# TODO
isensemble(m) = false