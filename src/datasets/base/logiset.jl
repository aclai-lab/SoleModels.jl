
"""
    abstract type AbstractFeatureLookupSet{V,FR<:AbstractFrame} end

Abstract type for feature lookup tables.
Structures of this type provide a feature value for each world of each instance
of a logiset. More specifically, if `featstruct isa AbstractFeatureLookupSet`, then
`featstruct[i, w, f]` is the value of feature `f` on world `w` on the `i`-th instance of the
dataset.

See also
[`featvalue`](@ref).
"""
abstract type AbstractFeatureLookupSet{V,FR<:AbstractFrame} end

featvaltype(::Type{<:AbstractFeatureLookupSet{V}}) where {V} = V
featvaltype(d::AbstractFeatureLookupSet) = featvaltype(typeof(d))

"""
    @inline function featvalue(
        featstruct  :: AbstractFeatureLookupSet{V,FR},
        i_sample    :: Integer,
        w           :: W,
        feature     :: F,
    ) where {V,F<:AbstractFeature,W<:AbstractWorld,FR<:AbstractFrame{W}}

Return the feature value for `f` at world `w` on the `i`-th instance.

See also
[`AbstractFeatureLookupSet`](@ref).
"""
function featvalue(
    featstruct  :: AbstractFeatureLookupSet{V,FR},
    i_sample    :: Integer,
    w           :: W,
    feature     :: F,
)::V where {V,F<:AbstractFeature,W<:AbstractWorld,FR<:AbstractFrame{W}}
    error("Please, provide method featvalue(::$(typeof(featstruct)), i_sample::$(typeof(i_sample)), w::$(typeof(w)), feature::$(typeof(feature)))::$(V).")
end

"""
    @inline function featvalue(
        featstruct  :: AbstractFeatureLookupSet{V,FR},
        i_sample    :: Integer,
        w           :: W,
        i_feature   :: Integer,
    ) where {V,W<:AbstractWorld,FR<:AbstractFrame{W}}

Return the value for the `i_feature`-th at world `w` on the `i`-th instance.

See also
[`AbstractFeatureLookupSet`](@ref).
"""
function featvalue(
    featstruct  :: AbstractFeatureLookupSet{V,FR},
    i_sample    :: Integer,
    w           :: W,
    i_feature   :: Integer,
)::V where {V,W<:AbstractWorld,FR<:AbstractFrame{W}}
    error("Please, provide method featvalue(::$(typeof(featstruct)), i_sample::$(typeof(i_sample)), w::$(typeof(w)), i_feature::$(typeof(i_feature)))::$(V).")
end

@inline Base.getindex(featstruct::AbstractFeatureLookupSet, args...) = featvalue(featstruct, args...)

############################################################################################
############################################################################################
############################################################################################

# # The most generic featstruct structure is a matrix of dictionaries of size (nsamples × nfeatures)
# struct GenericFWD{
#     V,
#     F<:AbstractFeature{V},
#     W<:AbstractWorld,
#     FR<:AbstractFrame{W},
#     D<:AbstractVector{<:AbstractDict{<:W,<:AbstractVector{<:V}}}
# } <: AbstractFeatureLookupSet{V,F,FR}
#     d :: D
#     nfeatures :: Integer
# end

# Base.size(featstruct::GenericFWD{V}, args...) where {V} = size(featstruct.d, args...)
# nsamples(featstruct::GenericFWD{V}) where {V}  = size(featstruct, 1)
# nfeatures(featstruct::GenericFWD{V}) where {V} = featstruct.d

# # The matrix is initialized with #undef values
# function fwd_init(::Type{GenericFWD}, X::AbstractLogiset{W,V}) where {W,V}
#     d = Array{Dict{W,V}, 2}(undef, nsamples(X))
#     for i in 1:nsamples
#         d[i] = Dict{W,Array{V,1}}()
#     end
#     GenericFWD{V}(d, nfeatures(X))
# end

# # A function for initializing individual world slices
# function fwd_init_world_slice(featstruct::GenericFWD{V}, i_sample::Integer, w::AbstractWorld) where {V}
#     featstruct.d[i_sample][w] = Array{V,1}(undef, featstruct.nfeatures)
# end

# # A function for getting a threshold value from the lookup table
# Base.@propagate_inbounds @inline featvalue(
#     featstruct  :: GenericFWD{V},
#     i_sample    :: Integer,
#     w           :: AbstractWorld,
#     i_feature   :: Integer) where {V} = featstruct.d[i_sample][w][i_feature]

# # A function for setting a threshold value in the lookup table
# Base.@propagate_inbounds @inline function fwd_set(featstruct::GenericFWD{V}, w::AbstractWorld, i_sample::Integer, i_feature::Integer, threshold::V) where {V}
#     featstruct.d[i_sample][w][i_feature] = threshold
# end

# # A function for setting threshold values for a single feature (from a feature slice, experimental)
# Base.@propagate_inbounds @inline function fwd_set_feature(featstruct::GenericFWD{V}, i_feature::Integer, fwdslice::Any) where {V}
#     throw_n_log("Warning! fwd_set_feature with GenericFWD is not yet implemented!")
#     for ((i_sample,w),threshold::V) in read_fwdslice(fwdslice)
#         featstruct.d[i_sample][w][i_feature] = threshold
#     end
# end

# # A function for slicing the dataset
# function _slice_dataset(featstruct::GenericFWD{V}, inds::AbstractVector{<:Integer}, return_view::Val = Val(false)) where {V}
#     GenericFWD{V}(if return_view == Val(true) @view featstruct.d[inds] else featstruct.d[inds] end, featstruct.nfeatures)
# end

# Others...
# Base.@propagate_inbounds @inline fwdread_channeaoeu(featstruct::GenericFWD{V}, i_sample::Integer, i_feature::Integer) where {V} = TODO
# const GenericFeaturedChannel{V} = TODO
# fwd_channel_interpret_world(fwc::GenericFeaturedChannel{V}, w::AbstractWorld) where {V} = TODO

# isminifiable(::AbstractFeatureLookupSet) = true

# function minify(featstruct::AbstractFeatureLookupSet)
#     minify(featstruct.d) #TODO improper
# end

"""
Basic structure for representing active logisets, that is, logical datasets with features. ... TODO
It stores the feature values in a lookup table.


"""
struct Logiset{
    V,
    W<:AbstractWorld,
    FR<:AbstractFrame{W,Bool},
    F<:AbstractFeature{V},
    FWD<:AbstractFeatureLookupSet{V,FR},
} <: AbstractLogiset{W,V,F,Bool,FR}

    # Feature lookup structure
    featstruct              :: FWD

    # Features
    features                :: Vector{F}

    # Accessibility relations
    relations               :: Vector{<:AbstractRelation}

    # Initial world(s)
    initialworld :: Union{Nothing,W,AbstractWorldSet{<:W}}

    function Logiset{V,W,FR,F,FWD}(
        featstruct              :: FWD,
        features                :: AbstractVector{F},
        relations               :: AbstractVector{<:AbstractRelation},
        ;
        allow_no_instances = false,
        initialworld = nothing,
    ) where {V,W<:AbstractWorld,FR<:AbstractFrame{W,Bool},FWD<:AbstractFeatureLookupSet{V,FR},F<:AbstractFeature{V}}
        features = collect(features)
        ty = "Logiset{$(V),$(W),$(FR),$(F)}"
        @assert allow_no_instances || nsamples(featstruct) > 0     "Can't instantiate $(ty) with no instance. (featstruct's type $(typeof(featstruct)))"
        @assert nfeatures(featstruct) == length(features)          "Can't instantiate $(ty) with different numbers of instances $(nsamples(featstruct)) and of features $(length(features))."
        check_initialworld(Logiset, initialworld, W)
        new{
            V,
            W,
            FR,
            F,
            FWD,
        }(
            featstruct,
            features,
            relations,
            initialworld,
        )
    end

    function Logiset{V,W,FR}(
        featstruct              :: FWD,
        features                :: AbstractVector{<:AbstractFeature},
        args...;
        kwargs...
    ) where {V,W<:AbstractWorld,FR<:AbstractFrame{W,Bool},FWD<:AbstractFeatureLookupSet{V,FR}}
        features = collect(features)
        F = Union{typeof.(features)...}
        features = Vector{F}(features)
        Logiset{V,W,FR,F,FWD}(featstruct, features, args...; kwargs...)
    end

    function Logiset{V,W}(
        featstruct              :: AbstractFeatureLookupSet{V,FR},
        args...;
        kwargs...
    ) where {V,W<:AbstractWorld,FR<:AbstractFrame{W,Bool}}
        Logiset{V,W,FR}(featstruct, args...; kwargs...)
    end

    function Logiset(
        featstruct             :: AbstractFeatureLookupSet{V,FR},
        args...;
        kwargs...,
    ) where {V,W<:AbstractWorld,FR<:AbstractFrame{W,Bool}}
        Logiset{V,W}(featstruct, args...; kwargs...)
    end
end


@inline function Base.getindex(X::Logiset{V,W}, args...) where {V,W<:AbstractWorld}
    Base.getindex(featstruct(X), args...)::V
end

@inline function featvalue(X::Logiset{V,W}, args...) where {V,W<:AbstractWorld}
    featvalue(featstruct(X), args...)::V
end

Base.size(X::Logiset)              = Base.size(featstruct(X))

featstruct(X::Logiset)                    = X.featstruct
relations(X::Logiset)              = X.relations
features(X::Logiset)               = X.features

nfeatures(X::Logiset)              = length(features(X))
nrelations(X::Logiset)             = length(relations(X))
nsamples(X::Logiset)               = nsamples(featstruct(X))
worldtype(X::Logiset{V,W}) where {V,W<:AbstractWorld} = W

frame(X::Logiset, i_sample) = frame(featstruct(X), i_sample)
initialworld(X::Logiset) = X.initialworld
function initialworld(X::Logiset, i_sample)
    initialworld(X) isa AbstractWorldSet ? initialworld(X)[i_sample] : initialworld(X)
end

function _slice_dataset(X::Logiset, inds::AbstractVector{<:Integer}, args...; kwargs...)
    Logiset(
        _slice_dataset(featstruct(X), inds, args...; kwargs...),
        features(X),
        relations(X),
        initialworld = initialworld(X)
    )
end

function displaystructure(X::Logiset; indent_str = "")
    out = "$(typeof(X))\t$(Base.summarysize(X) / 1024 / 1024 |> x->round(x, digits=2)) MBs\n"
    out *= indent_str * "├ features:\t\t$((length(features(X))))\t$(features(X))\n"
    out *= indent_str * "├ relations:\t\t$((length(relations(X))))\t$(relations(X))\n"
    out *= indent_str * "├ featstruct:\t\t$(typeof(featstruct(X)))\t$(Base.summarysize(featstruct(X)) / 1024 / 1024 |> x->round(x, digits=2)) MBs\n"
    out *= indent_str * "└ initialworld(s)\t$(initialworld(X))"
    out
end

hasnans(X::Logiset) = hasnans(featstruct(X))

isminifiable(::Logiset) = true

function minify(X::Logiset)
    new_fwd, backmap = minify(featstruct(X))
    X = Logiset(
        new_fwd,
        features(X),
        relations(X),
    )
    X, backmap
end
