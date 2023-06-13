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
        perform_initialization = false,
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
    error("TODO implement")
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


############################################################################################

"""
Abstract type for one-step memoization structure for checking formulas of type `⟨R⟩ (f ⋈ t)`.
"""
abstract type AbstractScalarOneStepMemoset{U,W,F<:AbstractFeature,FR<:AbstractFrame{W}} <: AbstractMemoset{W,U,F,FR}     end

# Access inner structure
function innerstruct(memoset::AbstractScalarOneStepMemoset)
    error("Please, provide method innerstruct(::$(typeof(memoset))).")
end

isminifiable(::AbstractScalarOneStepMemoset) = true

function minify(memoset::AbstractScalarOneStepMemoset)
    minify(innerstruct(memoset))
end

"""
Abstract type for one-step memoization structure for checking formulas of type `⟨R⟩ (f ⋈ t)`,
for a generic relation `R`.
"""
abstract type AbstractScalarOneStepRelationalMemoset{U,W,FR<:AbstractFrame{W}} <: AbstractScalarOneStepMemoset{W,U,F where F<:AbstractFeature,FR}     end
"""
Abstract type for one-step memoization structure for checking "global" formulas
of type `⟨G⟩ (f ⋈ t)`.
"""
abstract type AbstractScalarOneStepGlobalMemoset{W,U} <: AbstractScalarOneStepMemoset{W,U,F where F<:AbstractFeature,FR<:AbstractFrame{W}} end

############################################################################################

"""
A generic, one-step memoization structure used for checking specific formulas
of scalar conditions on
datasets with scalar features. The formulas are of type ⟨R⟩ (f ⋈ t)

TODO explain

See also
[`Memoset`](@ref),
[`SuportedLogiset`](@ref),
[`AbstractLogiset`](@ref).
"""
struct ScalarOneStepRelationalMemoset{
    W<:AbstractWorld,
    U,
    FR<:AbstractFrame{W},
    D<:AbstractArray{<:AbstractDict{W,VV}, 3} where VV<:Union{U,Nothing},
} <: AbstractScalarOneStepRelationalMemoset{W,U,FR}

    d :: D

    function ScalarOneStepRelationalMemoset{W,U,FR}(d::D) where {W<:AbstractWorld,U,FR<:AbstractFrame{W},D<:AbstractArray{U,2}}
        new{W,U,FR,D}(d)
    end

    function ScalarOneStepRelationalMemoset(
        X::AbstractLogiset{W,U,F,FR},
        # TODO: metaconditions, relations,
        perform_initialization = false
    ) where {W,U,F<:AbstractFeature,FR<:AbstractFrame{W}}
        _nfeatsnaggrs = nfeatsnaggrs(X)
        _fwd_rs = begin
            if perform_initialization
                _fwd_rs = Array{Dict{W,Union{U,Nothing}}, 3}(undef, ninstances(X), _nfeatsnaggrs, nrelations(X))
                fill!(_fwd_rs, nothing)
            else
                Array{Dict{W,U}, 3}(undef, ninstances(X), _nfeatsnaggrs, nrelations(X))
            end
        end
        ScalarOneStepRelationalMemoset{W,U,FR}(_fwd_rs)
    end
end

# default_fwd_rs_type(::Type{<:AbstractWorld}) = ScalarOneStepRelationalMemoset # TODO implement similar pattern used for fwd

function hasnans(memoset::ScalarOneStepRelationalMemoset)
    # @show any(map(d->(any(_isnan.(collect(values(d))))), memoset.d))
    any(map(d->(any(_isnan.(collect(values(d))))), memoset.d))
end

innerstruct(memoset::ScalarOneStepRelationalMemoset)        = memoset.d
ninstances(memoset::ScalarOneStepRelationalMemoset)        = size(memoset, 1)
nfeatsnaggrs(memoset::ScalarOneStepRelationalMemoset)    = size(memoset, 2)
nrelations(memoset::ScalarOneStepRelationalMemoset)      = size(memoset, 3)
capacity(memoset::ScalarOneStepRelationalMemoset)        = Inf
nmemoizedvalues(memoset::ScalarOneStepRelationalMemoset) = sum(length.(memoset.d))

@inline function Base.getindex(
    memoset      :: ScalarOneStepRelationalMemoset{W,U},
    i_instance   :: Integer,
    w            :: W,
    i_featsnaggr :: Integer,
    i_relation   :: Integer
) where {W<:AbstractWorld,U}
    memoset.d[i_instance, i_featsnaggr, i_relation][w]
end
Base.size(memoset::ScalarOneStepRelationalMemoset, args...) = size(memoset.d, args...)

fwd_rs_init_world_slice(memoset::ScalarOneStepRelationalMemoset{W,U}, i_instance::Integer, i_featsnaggr::Integer, i_relation::Integer) where {W,U} =
    memoset.d[i_instance, i_featsnaggr, i_relation] = Dict{W,U}()
@inline function Base.setindex!(memoset::ScalarOneStepRelationalMemoset{W,U}, threshold::U, i_instance::Integer, w::AbstractWorld, i_featsnaggr::Integer, i_relation::Integer) where {W,U}
    memoset.d[i_instance, i_featsnaggr, i_relation][w] = threshold
end
function instances(memoset::ScalarOneStepRelationalMemoset{W,U,FR}, inds::AbstractVector{<:Integer}, return_view::Union{Val{true},Val{false}} = Val(false)) where {W,U,FR}
    ScalarOneStepRelationalMemoset{W,U,FR}(if return_view == Val(true) @view memoset.d[inds,:,:] else memoset.d[inds,:,:] end)
end

############################################################################################

# Note: the global memoset is world-agnostic
struct ScalarOneStepGlobalMemoset{
    W<:AbstractWorld,
    U,
    D<:AbstractArray{U,2}
} <: AbstractScalarOneStepGlobalMemoset{W,U}

    d :: D

    function ScalarOneStepGlobalMemoset{W,U,D}(d::D) where {U,D<:AbstractArray{U,2}}
        new{W,U,D}(d)
    end
    function ScalarOneStepGlobalMemoset{W,U}(d::D) where {U,D<:AbstractArray{U,2}}
        ScalarOneStepGlobalMemoset{W,U,D}(d)
    end

    function ScalarOneStepGlobalMemoset(X::AbstractLogiset{W,U}) where {W<:AbstractWorld,U}
        @assert worldtype(X) != OneWorld "TODO adjust this note: note that you should not use a global memoset when not using global decisions"
        _nfeatsnaggrs = nfeatsnaggrs(X)
        ScalarOneStepGlobalMemoset{W,U}(Array{U,2}(undef, ninstances(X), _nfeatsnaggrs))
    end
end

capacity(memoset::ScalarOneStepGlobalMemoset)        = prod(size(memoset.d))
nmemoizedvalues(memoset::ScalarOneStepGlobalMemoset) = sum(memoset.d)
innerstruct(memoset::ScalarOneStepGlobalMemoset)        = memoset.d

# default_fwd_gs_type(::Type{<:AbstractWorld}) = ScalarOneStepGlobalMemoset # TODO implement similar pattern used for fwd

function hasnans(memoset::ScalarOneStepGlobalMemoset)
    # @show any(_isnan.(memoset.d))
    any(_isnan.(memoset.d))
end

ninstances(memoset::ScalarOneStepGlobalMemoset)  = size(memoset, 1)
nfeatsnaggrs(memoset::ScalarOneStepGlobalMemoset) = size(memoset, 2)
Base.getindex(
    memoset      :: ScalarOneStepGlobalMemoset,
    i_instance   :: Integer,
    i_featsnaggr  :: Integer) = memoset.d[i_instance, i_featsnaggr]
Base.size(memoset::ScalarOneStepGlobalMemoset{U}, args...) where {U} = size(memoset.d, args...)

Base.setindex!(memoset::ScalarOneStepGlobalMemoset{U}, threshold::U, i_instance::Integer, i_featsnaggr::Integer) where {U} =
    memoset.d[i_instance, i_featsnaggr] = threshold
function instances(memoset::ScalarOneStepGlobalMemoset{U}, inds::AbstractVector{<:Integer}, return_view::Union{Val{true},Val{false}} = Val(false)) where {U}
    ScalarOneStepGlobalMemoset{U}(if return_view == Val(true) @view memoset.d[inds,:] else memoset.d[inds,:] end)
end

abstract type FeaturedMemoset{U<:Number,W<:AbstractWorld,FR<:AbstractFrame{W}} <: AbstractMemoset{W,U,F where F<:AbstractFeature,FR} end

