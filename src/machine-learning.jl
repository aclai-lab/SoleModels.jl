# Classification and regression labels
const CLabel  = Union{String,Integer}
const RLabel  = AbstractFloat
const Label   = Union{CLabel,RLabel}
# Raw labels
const _CLabel = Integer # (classification labels are internally represented as integers)
const _Label  = Union{_CLabel,RLabel}


const AssociationRule{L<:AbstractLogic} = Rule{L, Formula{L}} #NOTE: maybe where {L<:AbstractLogic}

# const ClassificationRule = Rule{L,CLabel} where {L<:AbstractLogic}
# const RegressionRule = Rule{L,RLabel} where {L<:AbstractLogic}


# const ClassificationDL = DecisionList{L,CLabel} where {L<:AbstractLogic}
# const RegressionDL = DecisionList{L,RLabel} where {L<:AbstractLogic}



# Translate a list of labels into categorical form
Base.@propagate_inbounds @inline function get_categorical_form(Y :: AbstractVector{T}) where {T}
    class_names = unique(Y)

    dict = Dict{T, Int64}()
    @simd for i in 1:length(class_names)
        @inbounds dict[class_names[i]] = i
    end

    _Y = Array{Int64}(undef, length(Y))
    @simd for i in 1:length(Y)
        @inbounds _Y[i] = dict[Y[i]]
    end

    return class_names, _Y
end
