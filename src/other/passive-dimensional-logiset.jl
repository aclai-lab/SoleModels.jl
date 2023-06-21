using SoleData: slicedataset
import SoleData: get_instance, ninstances, nvariables, channelsize, maxchannelsize, dimensionality, eltype
using SoleData: AbstractDimensionalDataset,
                UniformDimensionalDataset

"""
Scalar logiset with  of dimensionality `N`.

See also
...
[`AbstractLogiset`](@ref).
"""
struct PassiveDimensionalLogiset{
    N,
    W<:AbstractWorld,
    DOM<:AbstractDimensionalDataset,
    FR<:AbstractDimensionalFrame{N,W},
} <: AbstractLogiset{W,U where U,FT where FT<:VarFeature,FR}

    d::DOM

    function PassiveDimensionalLogiset{N,W,DOM,FR}(
        d::DOM,
    ) where {N,W<:AbstractWorld,DOM<:AbstractDimensionalDataset,FR<:AbstractDimensionalFrame{N,W}}
        ty = "PassiveDimensionalLogiset{$(N),$(W),$(DOM),$(FR)}"
        @assert N == dimensionality(d) "ERROR! Dimensionality mismatch: " *
            "can't instantiate $(ty) with underlying structure" *
            "$(DOM). $(N) == $(dimensionality(d)) should hold."
        @assert SoleLogics.goeswithdim(W, N) "ERROR! Dimensionality mismatch: " *
            "can't interpret worldtype $(W) on PassiveDimensionalLogiset" *
            "of dimensionality = $(N)"
        new{N,W,DOM,FR}(d)
    end
    
    function PassiveDimensionalLogiset{N,W,DOM}(
        d::DOM,
    ) where {N,W<:AbstractWorld,DOM<:AbstractDimensionalDataset}
        FR = typeof(_frame(d))
        _W = worldtype(FR)
        @assert W <: _W "This should hold: $(W) <: $(_W)"
        PassiveDimensionalLogiset{N,_W,DOM,FR}(d)
    end

    function PassiveDimensionalLogiset{N,W}(
        d::DOM,
    ) where {N,W<:AbstractWorld,DOM<:AbstractDimensionalDataset}
        PassiveDimensionalLogiset{N,W,DOM}(d)
    end

    function PassiveDimensionalLogiset(
        d::AbstractDimensionalDataset,
        # worldtype::Type{<:AbstractWorld},
    )
        W = worldtype(_frame(d))
        PassiveDimensionalLogiset{dimensionality(d),W}(d)
    end
end

function featchannel(
    X::PassiveDimensionalLogiset,
    i_instance::Integer,
    f::AbstractFeature,
)
    get_instance(X.d, i_instance)
end

function readfeature(
    X::PassiveDimensionalLogiset,
    featchannel::Any,
    w::W,
    f::AbstractFeature{U},
) where {U,W<:AbstractWorld}
    w_values = interpret_world(w, featchannel)
    computefeature(f, w_values)::U
end

ninstances(X::PassiveDimensionalLogiset)                  = ninstances(X.d)
frame(X::PassiveDimensionalLogiset, i_instance::Integer) = _frame(X.d, i_instance)

function allfeatvalues(
    X::PassiveDimensionalLogiset,
    i_instance,
    f,
)
    [readfeature(X, featchannel(X, i_instance, f), w, f) for w in allworlds(X, i_instance)]
end

Base.size(X::PassiveDimensionalLogiset)                 = Base.size(X.d)

nvariables(X::PassiveDimensionalLogiset)               = nvariables(X.d)
channelsize(X::PassiveDimensionalLogiset)              = channelsize(X.d)
maxchannelsize(X::PassiveDimensionalLogiset)          = maxchannelsize(X.d)
dimensionality(X::PassiveDimensionalLogiset)            = dimensionality(X.d)
eltype(X::PassiveDimensionalLogiset)                    = eltype(X.d)

get_instance(X::PassiveDimensionalLogiset, args...)     = get_instance(X.d, args...)

function instances(
    X::PassiveDimensionalLogiset,
    inds::AbstractVector{<:Integer},
    return_view::Union{Val{true},Val{false}} = Val(false);
    kwargs...
) where {N,W}
    PassiveDimensionalLogiset{N,W}(instances(X.d, inds, args...; kwargs...))
end

function concatdatasets(Xs::PassiveDimensionalLogiset{N,W}...) where {N,W}
    PassiveDimensionalLogiset(concatdatasets([X.d for X in Xs]...))
end


function displaystructure(Xm::PassiveDimensionalLogiset; indent_str = "", include_ninstances = true, include_nmetaconditions = true, include_nrelations = true)
    padattribute(l,r) = string(l) * lpad(r,32+length(string(r))-(length(indent_str)+2+length(l)))
    pieces = []
    push!(pieces, "PassiveDimensionalLogiset ($(memoizationinfo(Xm)), $(humansize(Xm)))")
    push!(pieces, "$(padattribute("worldtype:", worldtype(Xm)))")
    push!(pieces, "$(padattribute("featvaltype:", featvaltype(Xm)))")
    push!(pieces, "$(padattribute("featuretype:", featuretype(Xm)))")
    push!(pieces, "$(padattribute("frametype:", frametype(Xm)))")
    push!(pieces, "$(padattribute("dimensionality:", dimensionality(Xm)))")
    if include_ninstances
        push!(pieces, "$(padattribute("# instances:", ninstances(Xm)))")
    end
    push!(pieces, "$(padattribute("# variables:", nvariables(Xm)))")
    push!(pieces, "$(padattribute("channelsize:", channelsize(Xm)))")
    push!(pieces, "$(padattribute("size × eltype:", "$(size(Xm.d)) × $(eltype(Xm.d))"))")

    return join(pieces, "\n$(indent_str)├ ", "\n$(indent_str)└ ")
end

hasnans(X::PassiveDimensionalLogiset) = hasnans(X.d)

worldtype(X::PassiveDimensionalLogiset{N,W}) where {N,W} = W


############################################################################################

_frame(X::Union{UniformDimensionalDataset,AbstractArray}, i_instance::Integer) = _frame(X)
_frame(X::Union{UniformDimensionalDataset,AbstractArray}) = FullDimensionalFrame(channelsize(X))
