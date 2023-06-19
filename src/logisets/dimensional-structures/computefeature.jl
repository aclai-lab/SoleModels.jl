using SoleModels: MultivariateFeature,
                    UnivariateFeature,
                    UnivariateNamedFeature,
                    UnivariateValue,
                    UnivariateMin,
                    UnivariateMax,
                    UnivariateSoftMin,
                    UnivariateSoftMax,
                    i_variable,
                    alpha

import SoleModels: computefeature, computeunivariatefeature

function computefeature(f::MultivariateFeature{U}, featchannel::Any)::U where {U}
    (f.f(featchannel))
end

function computeunivariatefeature(f::UnivariateFeature{U}, varchannel::Union{T,AbstractArray{T}}) where {U,T}
    (f.f(SoleBase.vectorize(varchannel);))::U
end
function computeunivariatefeature(f::UnivariateNamedFeature, varchannel::Union{T,AbstractArray{T}}) where {T}
    @error "Cannot intepret UnivariateNamedFeature on any structure at all."
end
function computeunivariatefeature(f::UnivariateValue{U}, varchannel::Union{T,AbstractArray{T}}) where {U<:Real,T}
    varchannel::U
end
function computeunivariatefeature(f::UnivariateMin{U}, varchannel::AbstractArray{T}) where {U<:Real,T}
    (minimum(varchannel))::U
end
function computeunivariatefeature(f::UnivariateMax{U}, varchannel::AbstractArray{T}) where {U<:Real,T}
    (maximum(varchannel))::U
end
function computeunivariatefeature(f::UnivariateSoftMin{U}, varchannel::AbstractArray{T}) where {U<:Real,T}
    utils.softminimum(varchannel, alpha(f))::U
end
function computeunivariatefeature(f::UnivariateSoftMax{U}, varchannel::AbstractArray{T}) where {U<:Real,T}
    utils.softmaximum(varchannel, alpha(f))::U
end

# simplified propositional cases:
function computeunivariatefeature(f::UnivariateMin{U}, varchannel::T) where {U<:Real,T}
    (minimum(varchannel))::U
end
function computeunivariatefeature(f::UnivariateMax{U}, varchannel::T) where {U<:Real,T}
    (maximum(varchannel))::U
end
function computeunivariatefeature(f::UnivariateSoftMin{U}, varchannel::T) where {U<:Real,T}
    varchannel::U
end
function computeunivariatefeature(f::UnivariateSoftMax{U}, varchannel::T) where {U<:Real,T}
    varchannel::U
end
