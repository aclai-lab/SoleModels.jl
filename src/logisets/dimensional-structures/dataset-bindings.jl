using SoleModels: AbstractUnivariateFeature

using SoleData: AbstractDimensionalDataset,
                UniformDimensionalDataset

import SoleData: ninstances, nvariables

import SoleModels:
    islogiseed, initlogiset, frame,
    featchannel, readfeature, featvalue, vareltype

function islogiseed(
    dataset::AbstractDimensionalDataset,
)
    true
end

function initlogiset(
    dataset::AbstractDimensionalDataset,
    features::AbstractVector{<:VarFeature},
)
    _ninstances = ninstances(dataset)
    _maxchannelsize = maxchannelsize(dataset)

    _worldtype(dataset::AbstractDimensionalDataset{T,2}) where {T} = OneWorld
    _worldtype(dataset::AbstractDimensionalDataset{T,3}) where {T} = Interval{Int}
    _worldtype(dataset::AbstractDimensionalDataset{T,4}) where {T} = Interval2D{Int}

    function _worldtype(dataset::AbstractDimensionalDataset)
        error("Cannot initialize logiset with dimensional dataset " *
            "with ndims = $(ndims(dataset)). Please, provide a " *
            "dataset structure of size X × Y × ... × nvariables × ninstances." *
            "Note that, currently, only ndims ≤ 4 (dimensionality = 2) is supported."
        )
    end

    W = _worldtype(dataset)
    N = dimensionality(dataset)

    features = UniqueVector(features)
    nfeatures = length(features)

    U = Union{featvaltype.(features)...}
    featstruct = Array{U,length(_maxchannelsize)*2+2}(
            undef,
            vcat([[s, s] for s in _maxchannelsize]...)...,
            _ninstances,
            length(features)
        )
    return UniformFullDimensionalLogiset{U,W,N}(featstruct, features)
end

function frame(
    dataset::Union{UniformDimensionalDataset,AbstractArray},
    i_instance::Integer
)
    FullDimensionalFrame(channelsize(dataset))
end

function featchannel(
    dataset::AbstractDimensionalDataset,
    i_instance::Integer,
    f::AbstractFeature,
)
    get_instance(dataset, i_instance)
end

function readfeature(
    dataset::AbstractDimensionalDataset,
    featchannel::Any,
    w::W,
    f::VarFeature{U},
) where {U,W<:AbstractWorld}
    _interpret_world(::OneWorld, instance::AbstractArray{T,1}) where {T} = instance
    _interpret_world(w::Interval, instance::AbstractArray{T,2}) where {T} = instance[w.x:w.y-1,:]
    _interpret_world(w::Interval2D, instance::AbstractArray{T,3}) where {T} = instance[w.x.x:w.x.y-1,w.y.x:w.y.y-1,:]
    wchannel = _interpret_world(w, featchannel)
    computefeature(f, wchannel)::U
end

function featvalue(
    dataset::AbstractDimensionalDataset,
    i_instance::Integer,
    w::W,
    feature::AbstractFeature,
) where {W<:AbstractWorld}
    readfeature(dataset, featchannel(dataset, i_instance, feature), w, feature)
end

function vareltype(
    dataset::AbstractDimensionalDataset{T},
    i_variable::Integer
) where {T}
    T
end

############################################################################################

using DataFrames

function islogiseed(
    dataset::AbstractDataFrame,
)
    true
end

function initlogiset(
    dataset::AbstractDataFrame,
    features::AbstractVector{<:VarFeature},
)
    _ninstances = nrow(dataset)

    cube, varnames = SoleData.dataframe2cube(dataset; dry_run = true)

    initlogiset(cube, features)
end

function frame(
    dataset::AbstractDataFrame,
    i_instance::Integer
)
    # dataset_cube, varnames = SoleData.dataframe2cube(dataset; dry_run = true)
    # FullDimensionalFrame(channelsize(dataset_cube))
    column = dataset[:,1]
    frame(column, i_instance)
end

function frame(
    column::Vector,
    i_instance::Integer
)
    FullDimensionalFrame(size(column[i_instance]))
end

function featchannel(
    dataset::AbstractDataFrame,
    i_instance::Integer,
    f::AbstractFeature,
)
    @views dataset[i_instance, :]
end

function readfeature(
    dataset::AbstractDataFrame,
    featchannel::Any,
    w::W,
    f::VarFeature{U},
) where {U,W<:AbstractWorld}
    _interpret_world(::OneWorld, instance::DataFrameRow) = instance
    _interpret_world(w::Interval, instance::DataFrameRow) = map(varchannel->varchannel[w.x:w.y-1], instance)
    _interpret_world(w::Interval2D, instance::DataFrameRow) = map(varchannel->varchannel[w.x.x:w.x.y-1,w.y.x:w.y.y-1], instance)
    wchannel = _interpret_world(w, featchannel)
    computefeature(f, wchannel)::U
end

function featchannel(
    dataset::AbstractDataFrame,
    i_instance::Integer,
    f::AbstractUnivariateFeature,
)
    @views dataset[i_instance, SoleModels.i_variable(f)]
end

function readfeature(
    dataset::AbstractDataFrame,
    featchannel::Any,
    w::W,
    f::AbstractUnivariateFeature{U},
) where {U,W<:AbstractWorld}
    _interpret_world(::OneWorld, varchannel::T) where {T} = varchannel
    _interpret_world(w::Interval, varchannel::AbstractArray{T,1}) where {T} = varchannel[w.x:w.y-1]
    _interpret_world(w::Interval2D, varchannel::AbstractArray{T,2}) where {T} = varchannel[w.x.x:w.x.y-1,w.y.x:w.y.y-1]
    wchannel = _interpret_world(w, featchannel)
    computeunivariatefeature(f, wchannel)::U
end

function featvalue(
    dataset::AbstractDataFrame,
    i_instance::Integer,
    w::W,
    feature::AbstractFeature,
) where {W<:AbstractWorld}
    readfeature(dataset, featchannel(dataset, i_instance, feature), w, feature)
end

function vareltype(
    dataset::AbstractDataFrame,
    i_variable::Integer
)
    eltype(eltype(dataset[:,i_variable]))
end
