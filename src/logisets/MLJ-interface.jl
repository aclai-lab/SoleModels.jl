
function eachinstance(X::AbstractLogiset)
    map(i_instance->(X,i_instance), 1:ninstances(X))
end

function eachinstance(X::MultiLogiset)
    map(i_instance->(X,i_instance), 1:ninstances(X))
end



function featchannel(
    X::AbstractLogiset{W},
    i_instance::Integer,
    i_feature::Integer,
) where {W<:AbstractWorld}
    featchannel(X, i_instance, features(X)[i_feature])
end

function readfeature(
    X::AbstractLogiset{W},
    featchannel::Any,
    w::W,
    i_feature::Integer,
) where {W<:AbstractWorld}
    readfeature(X, featchannel, w, features(X)[i_feature])
end


function featvalue(
    X::AbstractLogiset{W},
    i_instance::Integer,
    w::W,
    i_feature::Integer,
) where {W<:AbstractWorld}
    featvalue(X, i_instance, w, features(X)[i_feature])
end

function featvalue!(
    X::AbstractLogiset{W},
    featval,
    i_instance::Integer,
    w::W,
    i_feature::Integer,
) where {W<:AbstractWorld}
    featvalue(X, featval, i_instance, w, features(X)[i_feature])
end

function featvalues!(
    X::AbstractLogiset{W},
    featslice,
    i_feature::Integer,
) where {W<:AbstractWorld}
    featvalues(X, featslice, features(X)[i_feature])
end

Tables.istable(X::AbstractLogiset) = true
Tables.istable(X::MultiLogiset) = true

Tables.rowaccess(X::AbstractLogiset) = true
Tables.rowaccess(X::MultiLogiset) = true

function Tables.rows(X::AbstractLogiset)
    eachinstance(X)
end
function Tables.rows(X::MultiLogiset)
    eachinstance(X)
end

function Tables.subset(X::AbstractLogiset, inds; viewhint = nothing)
    slicedataset(X, inds; return_view = (isnothing(viewhint) || viewhint == true))
end

function Tables.subset(X::MultiLogiset, inds; viewhint = nothing)
    slicedataset(X, inds; return_view = (isnothing(viewhint) || viewhint == true))
end

function Tables.getcolumn(row::Tuple{AbstractLogiset,Integer}, i::Int)
    (features(row[1])[i],featchannel(row[1], row[2], i))
end

function Tables.columnnames(row::Tuple{AbstractLogiset,Integer})
    1:nfeatures(row[1])
end

function Tables.getcolumn(row::Tuple{MultiLogiset,Integer}, i::Int)
    m = modality(row[1], i)
    (Tables.getcolumn((m, row[2]), i_feature) for i_feature in 1:nfeatures(m))
end

function Tables.columnnames(row::Tuple{MultiLogiset,Integer})
    1:nmodalities(row[1])
end

using MLJBase
using MLJModelInterface
import MLJModelInterface: selectrows, _selectrows

# From MLJModelInferface.jl/src/data_utils.jl
function MLJModelInterface.selectrows(::MLJBase.FI, ::Val{:table}, X::Union{AbstractLogiset,MultiLogiset}, r)
    r = r isa Integer ? (r:r) : r
    return Tables.subset(X, r)
end



import Base: vcat

Base.vcat(Xs::AbstractLogiset...) = concatdatasets(Xs...)
Base.vcat(Xs::MultiLogiset...) = concatdatasets(Xs...)

