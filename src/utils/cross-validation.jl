
using Combinatorics

abstract type CrossValidation end

abstract type AbstractCrossValidationData{CVT<:CrossValidation} end

@safeconst AbstractDatasetSlice = AbstractVector{<:Integer}
@safeconst AbstractDatasetSplit = NTuple{2,<:AbstractDatasetSlice}
@safeconst AbstractDatasetSplitOrSlice = Union{AbstractDatasetSplit,AbstractDatasetSlice}

# use concrete versions of the above aliases inside structs or for instanciating for memory performance reasons
@safeconst DatasetSlice = Vector{Int}
@safeconst DatasetSplit = NTuple{2,DatasetSlice}
@safeconst DatasetSplitOrSlice = Union{DatasetSplit,DatasetSlice}

@assert DatasetSlice <: AbstractDatasetSlice
@assert DatasetSplit <: AbstractDatasetSplit
@assert DatasetSplitOrSlice <: AbstractDatasetSplitOrSlice

struct ExplicitCV <: CrossValidation
    experiments::Vector{DatasetSplit}

    function ExplicitCV(experiments::AbstractVector{<:AbstractDatasetSplit})
        return new(experiments)
    end
    function ExplicitCV(datasplit::AbstractDatasetSplit)
        return new([datasplit])
    end
end

struct CrossValidationData{CVT} <: AbstractCrossValidationData{CVT}
    dataref::Ref{<:Tuple{Vector{<:GenericDataset},Vector}}
    cvmethod::CVT

    function CrossValidationData(
        data::Tuple{<:AbstractVector{<:GenericDataset},<:AbstractVector},
        cvmethod::CVT
    ) where CVT<:CrossValidation
        return new{CVT}(Ref(data), cvmethod)
    end

    function CrossValidationData(
        data::Tuple{<:AbstractVector{<:GenericDataset},<:AbstractVector},
        cvmethod::ExplicitCV
    )
        for (tr, te) in cvmethod.experiments
            tr_min, tr_max = extrema(tr)
            te_min, te_max = extrema(te)

            errstr = "Some of the indices provided are not in the range [1,ninstances]: {1:$(_n_instances(data))}"

            @assert 1 ≤ tr_min ≤ length(data[2]) errstr
            @assert 1 ≤ tr_max ≤ length(data[2]) errstr
            @assert 1 ≤ te_min ≤ length(data[2]) errstr
            @assert 1 ≤ te_max ≤ length(data[2]) errstr
        end

        return new{ExplicitCV}(Ref(data), cvmethod)
    end
end

_dataref(cv::AbstractCrossValidationData) = cv.dataref
_data(cv::AbstractCrossValidationData) = _dataref(cv)[]
_method(cv::AbstractCrossValidationData) = cv.cvmethod

GenericLabeledModalDataset = Union{
    Tuple{<:GenericDataset,<:AbstractVector},
    Tuple{<:AbstractVector{<:GenericDataset},<:AbstractVector},
    AbstractCrossValidationData
}

_to_results_dataset(data::Tuple{<:GenericDataset,<:AbstractVector}) = _to_results_dataset(([data[1]], data[2]))
_to_results_dataset(data::Tuple{<:AbstractVector{<:GenericDataset},<:AbstractVector}) = data
_to_results_dataset(v) = throw(ErrorException("$(typeof(v)) is not a known dataset from"))

_to_results_dataset(cv::AbstractCrossValidationData) = _data(cv)

_X(d::GenericLabeledModalDataset) = _to_results_dataset(d)[1]
_Y(d::GenericLabeledModalDataset) = _to_results_dataset(d)[2]

_n_modalities(d::GenericLabeledModalDataset) = length(_X(d))
_n_classes(d::GenericLabeledModalDataset) = length(unique(_Y(d)))
_n_instances(d::GenericLabeledModalDataset) = length(_Y(d))
_n_variables(d::GenericLabeledModalDataset) = Tuple([size(modality)[end-1] for modality in _X(d)])
_n_datadims(d::GenericLabeledModalDataset) = Tuple([length(size(modality)[1:end-2]) for modality in _X(d)])

function get_class_map(d::GenericLabeledModalDataset)
    return OrderedDict([cn => findall(x -> x == cn, _Y(d)) for cn in get_class_names(_Y(d))]...)
end

struct FullTraining <: CrossValidation end

struct KFoldCV <: CrossValidation
    k::Int
    strict::Bool

    function KFoldCV(k::Integer; strict::Bool = true)
        return new(k, strict)
    end
end

struct MonteCarloCV <: CrossValidation
    seeds::Vector{Int}
    splitthreshold::Float64

    function MonteCarloCV(seeds::AbstractVector{<:Integer}, splitthreshold::AbstractFloat)
        @assert 0 < splitthreshold ≤ 1 "`splitthreshold` has to be a value in range (0,1]"

        return new(seeds, splitthreshold)
    end
    function MonteCarloCV(niterations::Integer, args...)
        return MonteCarloCV(1:niterations, args...)
    end
    function MonteCarloCV(rng::Integer, cv::MonteCarloCV)
        return MonteCarloCV(1:rng, cv.splitthreshold)
    end
    function MonteCarloCV(rng::AbstractVector{<:Integer}, cv::MonteCarloCV)
        return MonteCarloCV(rng, cv.splitthreshold)
    end
    function MonteCarloCV(rng::AbstractRNG, cv::MonteCarloCV)
        throw(ArgumentError("MonteCarloCV does not support AbstractRNG"))
    end
end

HoldoutCV(seed::Integer, splitthreshold::AbstractFloat) = MonteCarloCV([seed], splitthreshold)

struct LeavePOutCV <: CrossValidation
    p::Int
    rng::Union{Nothing,AbstractRNG,Int}
    maxiterations::Union{Nothing,Int} # nothing = no limit

    function LeavePOutCV(
        p::Integer;
        rng::Union{Nothing,AbstractRNG,Integer} = nothing,
        maxiterations::Union{Nothing,<:Integer} = nothing
    )
        rng = isa(rng, Integer) ? MersenneTwister(rng) : rng
        return new(p, rng, maxiterations)
    end
    function LeavePOutCV(rng::AbstractRNG, cv::LeavePOutCV)
        Random.seed!(rng, rng.seed)

        return LeavePOutCV(cv.p; rng = rng, maxiterations = cv.maxiterations)
    end
    function LeavePOutCV(rng::Integer, cv::LeavePOutCV)
        return LeavePOutCV(cv.p; rng = rng, maxiterations = cv.maxiterations)
    end
    function LeavePOutCV(rng::AbstractVector{<:Integer}, cv::LeavePOutCV)
        throw(ArgumentError("LeavePOutCV does not support multiple seeds"))
    end
end

LeaveOneOutCV(; kwargs...) = LeavePOutCV(1; kwargs...)


## ALIASES

MCCV = MonteCarloCV
KFCV = KFoldCV
HOCV = HoldoutCV
LPOCV = LeavePOutCV
LOOCV = LeaveOneOutCV


## METHODS

hasrng(::CrossValidation) = false
hasrng(cv::MonteCarloCV) = true
hasrng(cv::LeavePOutCV) = true
function changerng(rng::Union{<:Integer,<:AbstractVector{<:Integer},<:AbstractRNG}, cv::T) where T<:CrossValidation
    !hasrng(cv) && throw(ErrorException(string(T, " does not support rng")))

    return T(rng, cv)
end

nexperiments(cv::FullTraining) = 1
nexperiments(cv::ExplicitCV) = length(cv.experiments)
nexperiments(cv::KFoldCV) = cv.k
nexperiments(cv::MonteCarloCV) = length(cv.seeds)
function nexperiments(cv::LeavePOutCV)
    # NOTE: can't determine number of iterations without knowing the total number of instances
    return !isnothing(cv.maxiterations) ? cv.maxiterations : nothing
end

nexperiments(cv::AbstractCrossValidationData{<:CrossValidation}) = nexperiments(_method(cv))
function nexperiments(cv::AbstractCrossValidationData{LeavePOutCV})
    b = binomial(_n_instances(_data(cv)), _method(cv).p)
    return isnothing(_method(cv).maxiterations) ? b : min(b, _method(cv).maxiterations)
end
function nexperiments(
    data::Tuple{<:AbstractVector{<:GenericDataset},<:AbstractVector},
    cv::CrossValidation
)
    return nexperiments(CrossValidationData(data, cv))
end
function nexperiments(data::GenericLabeledModalDataset, cv::CrossValidation)
    return nexperiments(_to_results_dataset(data), cv)
end

splitthreshold(datasplit::AbstractDatasetSplit) = length(datasplit[1]) / length(datasplit[2])
splitthreshold(cv::FullTraining) = nothing
function splitthreshold(cv::ExplicitCV)
    sts = splitthreshold.(_method(cv).experiments)

    if !all([s[i] ≈ s[i+1] for i in 1:(length(sts)-1)])
        @warn "Some of the experiments in the same CrossValidation have different `splitthreshold`"
    end

    return mean(sts)
end
splitthreshold(cv::KFoldCV) = 1.0 / cv.k
splitthreshold(cv::MonteCarloCV) = cv.splitthreshold
splitthreshold(cv::LeavePOutCV) = nothing

splitthreshold(cv::AbstractCrossValidationData{<:CrossValidation}) = splitthreshold(_method(cv))
splitthreshold(cv::AbstractCrossValidationData{LeavePOutCV}) = 1 - (_method(cv).p / _n_instances(_data(cv)))
function splitthreshold(
    data::Tuple{<:AbstractVector{<:GenericDataset},<:AbstractVector},
    cv::CrossValidation
)
    return splitthreshold(CrossValidationData(data, cv))
end
function splitthreshold(data::GenericLabeledModalDataset, cv::CrossValidation)
    return splitthreshold(_to_results_dataset(data), cv)
end

iterexperiments(cv::CrossValidation) = 1:nexperiments
function iterexperiments(cv::LeavePOutCV)
    nexp = nexperiments(cv)
    return isnothing(nexp) ? [nothing] : 1:nexp
end

iterexperiments(cv::AbstractCrossValidationData{<:CrossValidation}) = iterexperiments(_method(cv))
iterexperiments(cv::AbstractCrossValidationData{LeavePOutCV}) = 1:nexperiments(cv)
function iterexperiments(
    data::Tuple{<:AbstractVector{<:GenericDataset},<:AbstractVector},
    cv::CrossValidation
)
    return iterexperiments(CrossValidationData(data, cv))
end
function iterexperiments(data::GenericLabeledModalDataset, cv::CrossValidation)
    return iterexperiments(_to_results_dataset(data), cv)
end

function generatesplits(cv::AbstractCrossValidationData{FullTraining})::Vector{DatasetSplit}
    ninsts = _n_instances(_data(cv))
    return [(collect(1:ninsts), collect(1:ninsts))]
end
function generatesplits(cv::AbstractCrossValidationData{ExplicitCV})::Vector{DatasetSplit}
    return _method(cv).experiments
end
function generatesplits(cv::AbstractCrossValidationData{KFoldCV})::Vector{DatasetSplit}
    return balanced_cv_dataset_slices(_Y(cv), _method(cv).k; strict = _method(cv).strict)
end
function generatesplits(cv::AbstractCrossValidationData{MonteCarloCV})::Vector{DatasetSplit}
    stratified_indices = balanced_dataset_slice(_Y(cv), _method(cv).seeds)
    ntrain = round(Int, length(first(stratified_indices)) * splitthreshold(cv))
    ntrain -= ntrain % _n_classes(cv)

    return [(si[1:ntrain],si[(ntrain+1):end]) for si in stratified_indices]
end
function generatesplits(cv::AbstractCrossValidationData{LeavePOutCV})::Vector{DatasetSplit}
    if !isnothing(_method(cv).rng)
        Random.seed!(_method(cv).rng, _method(cv).rng.seed)
    end

    _rng_t = isnothing(_method(cv).rng) ? () : (_method(cv).rng,)

    testids =
        if isnothing(_method(cv).maxiterations)
            # TODO: fix this UGLY thing!!!!
            try
                collect(Combinatorics.combinations(shuffle(_rng_t..., 1:_n_instances(cv)), _method(cv).p))
            catch
                throw(ErrorException("Too many iterations"))
            end
        else
            [shuffle(_rng_t..., 1:_n_instances(cv))[1:_method(cv).p] for i in 1:_method(cv).maxiterations]
        end

    return [(collect(setdiff(1:_n_instances(cv),tids)),tids) for tids in testids[1:nexperiments(cv)]]
end
function generatesplits(
    data::Tuple{<:AbstractVector{<:GenericDataset},<:AbstractVector},
    cv::CrossValidation
)::Vector{DatasetSplit}
    return generatesplits(CrossValidationData(data, cv))
end
function generatesplits(data::GenericLabeledModalDataset, cv::CrossValidation)
    return generatesplits(_to_results_dataset(data), cv)
end