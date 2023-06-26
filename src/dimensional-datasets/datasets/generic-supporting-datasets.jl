
struct GenericSupportingDataset{
    W<:AbstractWorld,
    FR<:AbstractFrame{W,Bool},
    M<:AbstractVector{<:AbstractDict{<:AbstractFormula,Vector{W}}},
} <: SupportingDataset{W,FR}
    
    memo::M

    function GenericSupportingDataset{W,FR,M}(
        memo :: M,
    ) where {W<:AbstractWorld,FR<:AbstractFrame{W,Bool},M<:AbstractVector{<:AbstractDict{<:AbstractFormula,Vector{W}}}}
        new{W,FR,M}(memo)
    end

    function GenericSupportingDataset(
        fd :: FeaturedDataset{V,W,FR},
    ) where {V,W<:AbstractWorld,FR<:AbstractFrame{W,Bool}}
        memo = Vector{ThreadSafeDict{AbstractFormula,Vector{W}}}(undef, ninstances(fd))
        for i_sample in 1:ninstances(fd)
            memo[i_sample] = ThreadSafeDict{AbstractFormula,Vector{W}}()
        end
        GenericSupportingDataset{W,FR,typeof(memo)}(memo)
    end
end

usesmemo(X::GenericSupportingDataset) = true

Base.size(X::GenericSupportingDataset) = ()
capacity(X::GenericSupportingDataset) = Inf
nmemoizedvalues(X::GenericSupportingDataset) = sum(length.(X.d))

function instances(X::GFSD, inds::AbstractVector{<:Integer}, return_view::Union{Val{true},Val{false}} = Val(false)) where {GFSD<:GenericSupportingDataset}
    GFSD(X.w0, instances(X.memo[inds], return_view))
end

hasnans(X::GenericSupportingDataset) = false # TODO double check that this is intended

isminifiable(X::GenericSupportingDataset) = false # TODO double check that this is intended

struct ChainedFeaturedSupportingDataset{
    V<:Number,
    W<:AbstractWorld,
    FR<:AbstractFrame{W,Bool},
    M<:AbstractVector{<:AbstractDict{<:AbstractFormula,V}},
} <: SupportingDataset{W,FR}
    
    w0::W

    memo::M

    function ChainedFeaturedSupportingDataset{V,W,FR,M}(
        memo :: M,
    ) where {V,W<:AbstractWorld,FR<:AbstractFrame{W,Bool},M<:AbstractVector{<:AbstractDict{<:AbstractFormula,V}}}
        new{V,W,FR,M}(memo)
    end

    function ChainedFeaturedSupportingDataset(
        fd :: FeaturedDataset{V,W,FR},
    ) where {V,W<:AbstractWorld,FR<:AbstractFrame{W,Bool}}
        memo = Vector{ThreadSafeDict{AbstractFormula,Vector{W}}}(undef, ninstances(fd))
        for i_sample in 1:ninstances(fd)
            memo[i_sample] = ThreadSafeDict{AbstractFormula,Vector{W}}()
        end
        ChainedFeaturedSupportingDataset{V,W,FR,typeof(memo)}(memo)
    end
end

usesmemo(X::ChainedFeaturedSupportingDataset) = true

Base.size(X::ChainedFeaturedSupportingDataset) = ()
capacity(X::ChainedFeaturedSupportingDataset) = Inf
nmemoizedvalues(X::ChainedFeaturedSupportingDataset) = sum(length.(X.d))

function instances(X::CFSD, inds::AbstractVector{<:Integer}, return_view::Union{Val{true},Val{false}} = Val(false)) where {CFSD<:ChainedFeaturedSupportingDataset}
    CFSD(X.w0, instances(X.memo[inds], return_view))
end

hasnans(X::ChainedFeaturedSupportingDataset) = false # TODO double check that this is intended

isminifiable(X::ChainedFeaturedSupportingDataset) = false # TODO double check that this is intended
