module SoleModels

using Reexport

export AbstractModel
export AbstractSymbolicModel, AbstractFunctionalModel
export AbstractOutcome

export Outcome

@reexport using SoleModelChecking

include("definitions.jl")

end
