using SoleData: AbstractDimensionalDataset,
                AbstractDimensionalInstance,
                AbstractDimensionalChannel,
                UniformDimensionalDataset,
                DimensionalInstance,
                DimensionalChannel

function initlogiset(
    dataset::AbstractDimensionalDataset,
    features::AbstractVector{<:VarFeature},
)
    _ninstances = ninstances(dataset)
    _max_channel_size = max_channel_size(dataset)
    W = worldtype(dataset)
    N = dimensionality(dataset)

    features = UniqueVector(features)
    nfeatures = length(features)

    U = Union{featvaltype.(features)...}
    featstruct = Array{U,length(_max_channel_size)*2+2}(
            undef,
            vcat([[s,s+1] for s in _max_channel_size]...)...,
            _ninstances,
            length(features)
        )
    return UniformFullDimensionalLogiset{U,W,N}(featstruct, features)
end

function featchannel(
    X::AbstractDimensionalDataset,
    i_instance::Integer,
    f::AbstractFeature,
)
    get_instance(X, i_instance)
end

function readfeature(
    X::AbstractDimensionalDataset,
    featchannel::Any,
    w::W,
    f::VarFeature{U},
) where {U,W<:AbstractWorld}
    w_values = interpret_world(w, featchannel)
    computefeature(f, w_values)::U
end

interpret_world(::OneWorld, instance::DimensionalInstance{T,1}) where {T} = instance
interpret_world(w::Interval2D, instance::DimensionalInstance{T,3}) where {T} = instance[w.x.x:w.x.y-1,w.y.x:w.y.y-1,:]
interpret_world(w::Interval, instance::DimensionalInstance{T,2}) where {T} = instance[w.x:w.y-1,:]

function featvalue(
    X::AbstractDimensionalDataset,
    i_instance::Integer,
    w::W,
    feature::AbstractFeature,
) where {W<:AbstractWorld}
    readfeature(X, featchannel(X, i_instance, feature), w, feature)
end

function featvalue(
    f::AbstractFeature,
    X::AbstractDimensionalDataset,
    i_instance::Integer,
    w::W,
) where {W<:AbstractWorld}
    featvalue(X, i_instance, w, f)
end

worldtype(d::AbstractDimensionalDataset{T,2}) where {T} = OneWorld
worldtype(d::AbstractDimensionalDataset{T,3}) where {T} = Interval{Int}
worldtype(d::AbstractDimensionalDataset{T,4}) where {T} = Interval2D{Int}

frame(X::Union{UniformDimensionalDataset,AbstractArray}, i_instance::Integer) = frame(X)
frame(X::Union{UniformDimensionalDataset,AbstractArray}) = FullDimensionalFrame(channel_size(X))

allworlds(X::Union{UniformDimensionalDataset,AbstractArray}, i_instance::Integer) = allworlds(frame(X, i_instance))
