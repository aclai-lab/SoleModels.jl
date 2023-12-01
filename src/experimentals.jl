module experimentals

export formula2natlang

using SoleModels
using SoleLogics
import SoleLogics.experimentals: formula2natlang

function formula2natlang(φ::MultiFormula; kwargs...)
    @assert length(modforms(φ)) == 1 "Cannot apply formula2natlang to MultiFormula with $(length(modforms(φ))) modforms"
    formula2natlang(first(values(modforms(φ))); kwargs...)
end

end
