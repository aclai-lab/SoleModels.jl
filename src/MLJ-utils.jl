module MLJUtils

using CategoricalArrays
using MLJBase

export fix_y

function fix_y(y)
    if isnothing(y)
        return nothing, nothing
    end
    is_classification = (eltype(MLJBase.scitype(y)) != Continuous)
    classes_seen = begin
        if is_classification
            y isa CategoricalArray ? filter(in(unique(y)), MLJBase.classes(y)) : unique(y)
        else
            nothing
        end
    end
    y = Vector{(is_classification ? String : Float64)}(y)
    y, classes_seen
end

# function is_classification(y)
#     !isnothing(y) && eltype(MLJBase.scitype(y)) != Continuous
# end

end
