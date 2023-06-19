using FillArrays

doc_supervised_ml = """
    const CLabel  = Union{String,Integer}
    const RLabel  = AbstractFloat
    const Label   = Union{CLabel,RLabel}

Types for supervised machine learning labels (classification and regression).
"""

"""$(doc_supervised_ml)"""
const CLabel  = Union{String,Integer}
"""$(doc_supervised_ml)"""
const RLabel  = AbstractFloat
"""$(doc_supervised_ml)"""
const Label   = Union{CLabel,RLabel}

# Raw labels
const _CLabel = Integer # (classification labels are internally represented as integers)
const _Label  = Union{_CLabel,RLabel}

const AssociationRule{F} = Rule{F} where {F<:AbstractFormula}
const ClassificationRule{L} = Rule{L} where {L<:CLabel}
const RegressionRule{L} = Rule{L} where {L<:RLabel}

############################################################################################

# Convert a list of labels to categorical form
Base.@propagate_inbounds @inline function get_categorical_form(Y::AbstractVector)
    class_names = unique(Y)

    dict = Dict{eltype(Y),Int64}()
    @simd for i in 1:length(class_names)
        @inbounds dict[class_names[i]] = i
    end

    _Y = Array{Int64}(undef, length(Y))
    @simd for i in 1:length(Y)
        @inbounds _Y[i] = dict[Y[i]]
    end

    return class_names, _Y
end

############################################################################################

"""
    bestguess(
        labels::AbstractVector{<:Label},
        weights::Union{Nothing,AbstractVector} = nothing;
        suppress_parity_warning = false,
    )

Return the best guess for a set of labels; that is, the label that best approximates the
labels provided. For classification labels, this function returns the majority class; for
regression labels, the average value.
If no labels are provided, `nothing` is returned.
The computation can be weighted.

See also
[`CLabel`](@ref),
[`RLabel`](@ref),
[`Label`](@ref).
"""
function bestguess(
    labels::AbstractVector{<:Label},
    weights::Union{Nothing,AbstractVector} = nothing;
    suppress_parity_warning = false,
) end

# Classification: (weighted) majority vote
function bestguess(
    labels::AbstractVector{<:CLabel},
    weights::Union{Nothing,AbstractVector} = nothing;
    suppress_parity_warning = false,
)
    if length(labels) == 0
        return nothing
    end

    counts = begin
        if isnothing(weights)
            countmap(labels)
        else
            @assert length(labels) === length(weights) "Cannot compute " *
             "best guess with uneven number of votes " *
             "$(length(labels)) and weights $(length(weights))."
            countmap(labels, weights)
        end
    end

    if !suppress_parity_warning && sum(counts[argmax(counts)] .== values(counts)) > 1
        println("Warning: parity encountered in bestguess.")
        println("Counts ($(length(labels)) elements): $(counts)")
        println("Argmax: $(argmax(counts))")
        println("Max: $(counts[argmax(counts)]) (sum = $(sum(values(counts))))")
    end
    argmax(counts)
end

# Regression: (weighted) mean (or other central tendency measure?)
function bestguess(
    labels::AbstractVector{<:RLabel},
    weights::Union{Nothing,AbstractVector} = nothing;
    suppress_parity_warning = false,
)
    if length(labels) == 0
        return nothing
    end

    (isnothing(weights) ? StatsBase.mean(labels) : sum(labels .* weights)/sum(weights))
end

############################################################################################

# Default weights are optimized using FillArrays
"""
    default_weights(n::Integer)::AbstractVector{<:Number}

Return a default weight vector of `n` values.
"""
function default_weights(n::Integer)
    Ones{Int64}(n)
end
default_weights(Y::AbstractVector) = default_weights(length(Y))

# Class rebalancing weights (classification case)
"""
    default_weights(Y::AbstractVector{L}) where {L<:CLabel}::AbstractVector{<:Number}

Return a class-rebalancing weight vector, given a label vector `Y`.
"""
function balanced_weights(Y::AbstractVector{L}) where {L<:CLabel}
    class_counts_dict = countmap(Y)
    if length(unique(values(class_counts)_dict)) == 1 # balanced case
        default_weights(length(Y))
    else
        # Assign weights in such a way that the dataset becomes balanced
        tot = sum(values(class_counts_dict))
        balanced_tot_per_class = tot/length(class_counts_dict)
        weights_map = Dict{L,Float64}([class => (balanced_tot_per_class/n_instances)
            for (class,n_instances) in class_counts_dict])
        W = [weights_map[y] for y in Y]
        W ./ sum(W)
    end
end

slice_weights(W::Ones{Int64}, inds::AbstractVector) = default_weights(length(inds))
slice_weights(W::Any,         inds::AbstractVector) = @view W[inds]
slice_weights(W::Ones{Int64}, i::Integer) = 1
slice_weights(W::Any,         i::Integer) = W[i]
