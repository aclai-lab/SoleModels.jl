
############################################################################################
############################################################################################
############################################################################################

struct GenericRelationalSupport{
    V,
    W<:AbstractWorld,
    FR<:AbstractFrame{W,Bool},
    D<:AbstractArray{Dict{W,VV}, 3} where VV<:Union{V,Nothing},
} <: AbstractRelationalSupport{V,W,FR}

    d :: D

    function GenericRelationalSupport{V,W,FR}(d::D) where {V,W<:AbstractArray,FR<:AbstractFrame{W,Bool},D<:AbstractArray{V,2}}
        new{V,W,FR,D}(d)
    end

    function GenericRelationalSupport(fd::FeaturedDataset{V,W,FR}, perform_initialization = false) where {V,W,FR<:AbstractFrame{W,Bool}}
        _nfeatsnaggrs = nfeatsnaggrs(fd)
        _fwd_rs = begin
            if perform_initialization
                _fwd_rs = Array{Dict{W,Union{V,Nothing}}, 3}(undef, ninstances(fd), _nfeatsnaggrs, nrelations(fd))
                fill!(_fwd_rs, nothing)
            else
                Array{Dict{W,V}, 3}(undef, ninstances(fd), _nfeatsnaggrs, nrelations(fd))
            end
        end
        GenericRelationalSupport{V,W,FR}(_fwd_rs)
    end
end

# default_fwd_rs_type(::Type{<:AbstractWorld}) = GenericRelationalSupport # TODO implement similar pattern used for fwd

function hasnans(support::GenericRelationalSupport)
    # @show any(map(d->(any(_isnan.(collect(values(d))))), support.d))
    any(map(d->(any(_isnan.(collect(values(d))))), support.d))
end

ninstances(support::GenericRelationalSupport)        = size(support, 1)
nfeatsnaggrs(support::GenericRelationalSupport)    = size(support, 2)
nrelations(support::GenericRelationalSupport)      = size(support, 3)
capacity(support::GenericRelationalSupport)        = Inf
nmemoizedvalues(support::GenericRelationalSupport) = sum(length.(support.d))

@inline function Base.getindex(
    support      :: GenericRelationalSupport{V,W},
    i_instance     :: Integer,
    w            :: W,
    i_featsnaggr :: Integer,
    i_relation   :: Integer
) where {V,W<:AbstractWorld}
    support.d[i_instance, i_featsnaggr, i_relation][w]
end
Base.size(support::GenericRelationalSupport, args...) = size(support.d, args...)

fwd_rs_init_world_slice(support::GenericRelationalSupport{V,W}, i_instance::Integer, i_featsnaggr::Integer, i_relation::Integer) where {V,W} =
    support.d[i_instance, i_featsnaggr, i_relation] = Dict{W,V}()
@inline function Base.setindex!(support::GenericRelationalSupport{V,W}, threshold::V, i_instance::Integer, w::AbstractWorld, i_featsnaggr::Integer, i_relation::Integer) where {V,W}
    support.d[i_instance, i_featsnaggr, i_relation][w] = threshold
end
function instances(support::GenericRelationalSupport{V,W,FR}, inds::AbstractVector{<:Integer}, return_view::Union{Val{true},Val{false}} = Val(false)) where {V,W,FR}
    GenericRelationalSupport{V,W,FR}(if return_view == Val(true) @view support.d[inds,:,:] else support.d[inds,:,:] end)
end

############################################################################################

# Note: the global support is world-agnostic
struct GenericGlobalSupport{V,D<:AbstractArray{V,2}} <: AbstractGlobalSupport{V}
    d :: D

    function GenericGlobalSupport{V,D}(d::D) where {V,D<:AbstractArray{V,2}}
        new{V,D}(d)
    end
    function GenericGlobalSupport{V}(d::D) where {V,D<:AbstractArray{V,2}}
        GenericGlobalSupport{V,D}(d)
    end

    function GenericGlobalSupport(fd::FeaturedDataset{V}) where {V}
        @assert worldtype(fd) != OneWorld "TODO adjust this note: note that you should not use a global support when not using global decisions"
        _nfeatsnaggrs = nfeatsnaggrs(fd)
        GenericGlobalSupport{V}(Array{V,2}(undef, ninstances(fd), _nfeatsnaggrs))
    end
end

capacity(support::GenericGlobalSupport)        = prod(size(support.d))
nmemoizedvalues(support::GenericGlobalSupport) = sum(support.d)

# default_fwd_gs_type(::Type{<:AbstractWorld}) = GenericGlobalSupport # TODO implement similar pattern used for fwd

function hasnans(support::GenericGlobalSupport)
    # @show any(_isnan.(support.d))
    any(_isnan.(support.d))
end

ninstances(support::GenericGlobalSupport)  = size(support, 1)
nfeatsnaggrs(support::GenericGlobalSupport) = size(support, 2)
Base.getindex(
    support      :: GenericGlobalSupport,
    i_instance     :: Integer,
    i_featsnaggr  :: Integer) = support.d[i_instance, i_featsnaggr]
Base.size(support::GenericGlobalSupport{V}, args...) where {V} = size(support.d, args...)

Base.setindex!(support::GenericGlobalSupport{V}, threshold::V, i_instance::Integer, i_featsnaggr::Integer) where {V} =
    support.d[i_instance, i_featsnaggr] = threshold
function instances(support::GenericGlobalSupport{V}, inds::AbstractVector{<:Integer}, return_view::Union{Val{true},Val{false}} = Val(false)) where {V}
    GenericGlobalSupport{V}(if return_view == Val(true) @view support.d[inds,:] else support.d[inds,:] end)
end
