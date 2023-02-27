using FillArrays

# Classification and regression labels
const CLabel  = Union{String,Integer}
const RLabel  = AbstractFloat
const Label   = Union{CLabel,RLabel}
# Raw labels
const _CLabel = Integer # (classification labels are internally represented as integers)
const _Label  = Union{_CLabel,RLabel}


# const AssociationRule{L<:AbstractLogic} = Rule{L, formulaofsomekind...{L}} #NOTE: maybe where {L<:AbstractLogic}

# const ClassificationRule = Rule{L,CLabel} where {L<:AbstractLogic}
# const RegressionRule = Rule{L,RLabel} where {L<:AbstractLogic}


# const ClassificationDL = DecisionList{L,CLabel} where {L<:AbstractLogic}
# const RegressionDL = DecisionList{L,RLabel} where {L<:AbstractLogic}



# Translate a list of labels into categorical form
Base.@propagate_inbounds @inline function get_categorical_form(Y :: AbstractVector{T}) where {T}
    class_names = unique(Y)

    dict = Dict{T,Int64}()
    @simd for i in 1:length(class_names)
        @inbounds dict[class_names[i]] = i
    end

    _Y = Array{Int64}(undef, length(Y))
    @simd for i in 1:length(Y)
        @inbounds _Y[i] = dict[Y[i]]
    end

    return class_names, _Y
end


average_label(labels::AbstractVector{<:CLabel}) = majority_vote(labels; suppress_parity_warning = false) # argmax(countmap(labels))
average_label(labels::AbstractVector{<:RLabel}) = majority_vote(labels; suppress_parity_warning = false) # StatsBase.mean(labels)

function majority_vote(
        labels::AbstractVector{L},
        weights::Union{Nothing,AbstractVector} = nothing;
        suppress_parity_warning = false,
    ) where {L<:CLabel}

    if length(labels) == 0
        return nothing
    end

    counts = begin
        if isnothing(weights)
            countmap(labels)
        else
            @assert length(labels) === length(weights) "Can't compute majority_vote with uneven number of votes $(length(labels)) and weights $(length(weights))."
            countmap(labels, weights)
        end
    end

    if !suppress_parity_warning && sum(counts[argmax(counts)] .== values(counts)) > 1
        println("Warning: parity encountered in majority_vote.")
        println("Counts ($(length(labels)) elements): $(counts)")
        println("Argmax: $(argmax(counts))")
        println("Max: $(counts[argmax(counts)]) (sum = $(sum(values(counts))))")
    end
    argmax(counts)
end

function majority_vote(
        labels::AbstractVector{L},
        weights::Union{Nothing,AbstractVector} = nothing;
        suppress_parity_warning = false,
    ) where {L<:RLabel}
    if length(labels) == 0
        return nothing
    end

    (isnothing(weights) ? mean(labels) : sum(labels .* weights)/sum(weights))
end


# Default weights are optimized using FillArrays
function default_weights(n::Integer)
    Ones{Int64}(n)
end
function default_weights_rebalance(Y::AbstractVector{L}) where {L<:CLabel}
    class_counts_dict = countmap(Y)
    if length(unique(values(class_counts)_dict)) == 1 # balanced case
        default_weights(length(Y))
    else
        # Assign weights in such a way that the dataset becomes balanced
        tot = sum(values(class_counts_dict))
        balanced_tot_per_class = tot/length(class_counts_dict)
        weights_map = Dict{L,Float64}([class => (balanced_tot_per_class/n_instances) for (class,n_instances) in class_counts_dict])
        W = [weights_map[y] for y in Y]
        W ./ sum(W)
    end
end
slice_weights(W::Ones{Int64}, inds::AbstractVector) = default_weights(length(inds))
slice_weights(W::Any,         inds::AbstractVector) = @view W[inds]
slice_weights(W::Ones{Int64}, i::Integer) = 1
slice_weights(W::Any,         i::Integer) = W[i]
