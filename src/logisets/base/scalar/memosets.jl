using UniqueVectors

"""
A full memoization structure used for checking formulas of scalar conditions on
datasets with scalar features. This structure is the equivalent to [`Memoset`](@ref),
but with scalar features some important optimizations can be done.

TODO explain

See also
[`Memoset`](@ref),
[`SuportedLogiset`](@ref),
[`AbstractLogiset`](@ref).
"""
struct ScalarMemoset{
    W<:AbstractWorld,
    U,
    FR<:AbstractFrame{W},
    D<:AbstractVector{<:AbstractDict{<:AbstractFormula,U}},
} <: AbstractMemoset{W,U,F where F<:AbstractFeature,FR}

    d :: D

    function ScalarMemoset{W,U,FR,D}(
        d::D
    ) where {W<:AbstractWorld,U,FR<:AbstractFrame{W},D<:AbstractVector{<:AbstractDict{<:AbstractFormula,U}}}
        new{W,U,FR,D}(d)
    end

    function ScalarMemoset(
        X::AbstractLogiset{W,U,F,FR},
        # perform_initialization = false,
    ) where {W<:AbstractWorld,U,F<:AbstractFeature,FR<:AbstractFrame{W}}
        d = [ThreadSafeDict{SyntaxTree,WorldSet{W}}() for i in 1:ninstances(X)]
        D = typeof(d)
        ScalarMemoset{W,U,FR,D}(d)
    end
end

ninstances(Xm::ScalarMemoset)      = length(Xm.d)

capacity(Xm::ScalarMemoset)        = Inf
nmemoizedvalues(Xm::ScalarMemoset) = sum(length.(Xm.d))


@inline function Base.haskey(
    Xm           :: ScalarMemoset,
    i_instance   :: Integer,
    f            :: AbstractFormula,
)
    haskey(Xm.d[i_instance], f)
end

@inline function Base.getindex(
    Xm           :: ScalarMemoset,
    i_instance   :: Integer,
)
    Xm.d[i_instance]
end
@inline function Base.getindex(
    Xm           :: ScalarMemoset,
    i_instance   :: Integer,
    f            :: AbstractFormula,
)
    Xm.d[i_instance][f]
end
@inline function Base.setindex!(
    Xm           :: ScalarMemoset,
    i_instance   :: Integer,
    f            :: AbstractFormula,
    threshold    :: U,
) where {U}
    Xm.d[i_instance][f] = threshold
end

function check(
    f::AbstractFormula,
    Xm::ScalarMemoset{W},
    i_instance::Integer,
    w::W;
    kwargs...
) where {W<:AbstractWorld}
    error("TODO implement chained threshold checking algorithm.")
end

function instances(
    Xm::ScalarMemoset,
    inds::AbstractVector{<:Integer},
    return_view::Union{Val{true},Val{false}} = Val(false);
    kwargs...
)
    ScalarMemoset(if return_view == Val(true) @view Xm.d[inds] else Xm.d[inds] end)
end

function concatdatasets(Xms::ScalarMemoset...)
    ScalarMemoset(vcat([Xm.d for Xm in Xms]...))
end

usesfullmemo(::ScalarMemoset) = true
fullmemo(Xm::ScalarMemoset) = Xm

hasnans(::ScalarMemoset) = false
