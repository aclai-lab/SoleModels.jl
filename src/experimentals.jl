module experimentals

export formula2natlang

using SoleModels
using SoleLogics
import SoleLogics.experimentals: formula2natlang

function formula2natlang(
    f::MultiFormula;
    hidemodality = false,
    variable_names_map::Union{Nothing,AbstractDict,AbstractVector,AbstractVector{<:Union{AbstractDict,AbstractVector}}} = nothing,
    kwargs...
)
    map_is_multimodal = begin
        if !isnothing(variable_names_map) && all(e->!(e isa Union{AbstractDict,AbstractVector}), variable_names_map)
            (haskey(kwargs, :silent) && kwargs[:silent]) ||
                @warn "With multimodal formulas, variable_names_map should be a vector of vectors/maps of " *
                    "variable names. Got $(typeof(variable_names_map)) instead. This may fail, " *
                    "or lead to unexpected results."
            false
        else
            !isnothing(variable_names_map)
        end
    end
    join([begin
        _variable_names_map = map_is_multimodal ? variable_names_map[i_modality] : variable_names_map
        φ = formula2natlang(modforms(f)[i_modality]; variable_names_map = _variable_names_map, kwargs...)
        hidemodality ? "$φ" : "On modality $(i_modality): $φ"
    end for i_modality in sort(collect(keys(modforms(f))))], "\n\tAND\n")
end
    for (i_modality, φ) in pairs(modforms(φ))
        if hidemodality
            println(" $i_modality: $(formula2natlang(φ; kwargs...))\n")
        else
            @assert length(modforms(φ)) == 1 "Cannot apply formula2natlang to MultiFormula with $(length(modforms(φ))) modforms"
            println(formula2natlang(φ; kwargs...))
        end
    end
end

end
