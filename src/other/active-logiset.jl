
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
        i_instance  :: Integer,
        w           :: W,
        feature     :: FT,
    ) where {V,FT<:AbstractFeature,W<:AbstractWorld,FR<:AbstractFrame{W}}

Return the feature value for `f` at world `w` on the `i`-th instance.

See also
[`AbstractFeatureLookupSet`](@ref).
"""
function featvalue(
    featstruct  :: AbstractFeatureLookupSet{V,FR},
    i_instance  :: Integer,
    w           :: W,
    feature     :: FT,
)::V where {V,FT<:AbstractFeature,W<:AbstractWorld,FR<:AbstractFrame{W}}
    error("Please, provide method featvalue(::$(typeof(featstruct)), i_instance::$(typeof(i_instance)), w::$(typeof(w)), feature::$(typeof(feature)))::$(V).")
end

"""
    @inline function featvalue(
        featstruct  :: AbstractFeatureLookupSet{V,FR},
        i_instance  :: Integer,
        w           :: W,
        i_feature   :: Integer,
    ) where {V,W<:AbstractWorld,FR<:AbstractFrame{W}}

Return the value for the `i_feature`-th at world `w` on the `i`-th instance.

See also
[`AbstractFeatureLookupSet`](@ref).
"""
function featvalue(
    featstruct  :: AbstractFeatureLookupSet{V,FR},
    i_instance  :: Integer,
    w           :: W,
    i_feature   :: Integer,
)::V where {V,W<:AbstractWorld,FR<:AbstractFrame{W}}
    error("Please, provide method featvalue(::$(typeof(featstruct)), i_instance::$(typeof(i_instance)), w::$(typeof(w)), i_feature::$(typeof(i_feature)))::$(V).")
end

@inline Base.getindex(featstruct::AbstractFeatureLookupSet, args...) = featvalue(featstruct, args...)

############################################################################################
############################################################################################
############################################################################################

# # The most generic featstruct structure is a matrix of dictionaries of size (ninstances × nfeatures)
# struct GenericFWD{
#     V,
#     FT<:AbstractFeature,
#     W<:AbstractWorld,
#     FR<:AbstractFrame{W},
#     D<:AbstractVector{<:AbstractDict{<:W,<:AbstractVector{<:V}}}
# } <: AbstractFeatureLookupSet{V,FT,FR}
#     d :: D
#     nfeatures :: Integer
# end

# Base.size(featstruct::GenericFWD{V}, args...) where {V} = size(featstruct.d, args...)
# ninstances(featstruct::GenericFWD{V}) where {V}  = size(featstruct, 1)
# nfeatures(featstruct::GenericFWD{V}) where {V} = featstruct.d

# # The matrix is initialized with #undef values
# function fwd_init(::Type{GenericFWD}, X::AbstractLogiset{W,V}) where {W,V}
#     d = Array{Dict{W,V}, 2}(undef, ninstances(X))
#     for i in 1:ninstances
#         d[i] = Dict{W,Array{V,1}}()
#     end
#     GenericFWD{V}(d, nfeatures(X))
# end

# # A function for initializing individual world slices
# function fwd_init_world_slice(featstruct::GenericFWD{V}, i_instance::Integer, w::AbstractWorld) where {V}
#     featstruct.d[i_instance][w] = Array{V,1}(undef, featstruct.nfeatures)
# end

# # A function for getting a threshold value from the lookup table
# Base.@propagate_inbounds @inline featvalue(
#     featstruct  :: GenericFWD{V},
#     i_instance  :: Integer,
#     w           :: AbstractWorld,
#     i_feature   :: Integer) where {V} = featstruct.d[i_instance][w][i_feature]

# # A function for setting a threshold value in the lookup table
# Base.@propagate_inbounds @inline function fwd_set(featstruct::GenericFWD{V}, w::AbstractWorld, i_instance::Integer, i_feature::Integer, threshold::V) where {V}
#     featstruct.d[i_instance][w][i_feature] = threshold
# end

# # A function for setting threshold values for a single feature (from a feature slice, experimental)
# Base.@propagate_inbounds @inline function fwd_set_feature(featstruct::GenericFWD{V}, i_feature::Integer, fwdslice::Any) where {V}
#     throw_n_log("Warning! fwd_set_feature with GenericFWD is not yet implemented!")
#     for ((i_instance,w),threshold::V) in read_fwdslice(fwdslice)
#         featstruct.d[i_instance][w][i_feature] = threshold
#     end
# end

# # A function for slicing the dataset
# function instances(featstruct::GenericFWD{V}, inds::AbstractVector{<:Integer}, return_view::Union{Val{true},Val{false}} = Val(false)) where {V}
#     GenericFWD{V}(if return_view == Val(true) @view featstruct.d[inds] else featstruct.d[inds] end, featstruct.nfeatures)
# end

# Others...
# Base.@propagate_inbounds @inline fwdread_channeaoeu(featstruct::GenericFWD{V}, i_instance::Integer, i_feature::Integer) where {V} = TODO
# const GenericFeaturedChannel{V} = TODO
# readfeature(fwc::GenericFeaturedChannel{V}, w::AbstractWorld) where {V} = TODO

# isminifiable(::AbstractFeatureLookupSet) = true

# function minify(featstruct::AbstractFeatureLookupSet)
#     minify(featstruct.d) #TODO improper
# end

"""
Basic structure for representing active logisets, that is, logical datasets with features. ... TODO
It stores the feature values in a lookup table.


"""
struct ActiveLogiset{
    V,
    W<:AbstractWorld,
    FR<:AbstractFrame{W},
    FT<:AbstractFeature,
    FWD<:AbstractFeatureLookupSet{V,FR},
} <: AbstractLogiset{W,V,FT,Bool,FR}

    # Feature lookup structure
    featstruct              :: FWD

    # Features
    features                :: Vector{FT}

    # Accessibility relations
    relations               :: Vector{<:AbstractRelation}

    # Initial world(s)
    initialworld :: Union{Nothing,W,AbstractWorldSet{<:W}}

    function ActiveLogiset{V,W,FR,FT,FWD}(
        featstruct              :: FWD,
        features                :: AbstractVector{FT},
        relations               :: AbstractVector{<:AbstractRelation},
        ;
        allow_no_instances = false,
        initialworld = nothing,
    ) where {V,W<:AbstractWorld,FR<:AbstractFrame{W},FWD<:AbstractFeatureLookupSet{V,FR},FT<:AbstractFeature}
        features = collect(features)
        ty = "ActiveLogiset{$(V),$(W),$(FR),$(FT)}"
        @assert allow_no_instances || ninstances(featstruct) > 0     "Cannot instantiate $(ty) with no instance. (featstruct's type $(typeof(featstruct)))"
        @assert nfeatures(featstruct) == length(features)          "Cannot instantiate $(ty) with different numbers of instances $(ninstances(featstruct)) and of features $(length(features))."
        check_initialworld(ActiveLogiset, initialworld, W)
        new{
            V,
            W,
            FR,
            FT,
            FWD,
        }(
            featstruct,
            features,
            relations,
            initialworld,
        )
    end

    function ActiveLogiset{V,W,FR}(
        featstruct              :: FWD,
        features                :: AbstractVector{<:AbstractFeature},
        args...;
        kwargs...
    ) where {V,W<:AbstractWorld,FR<:AbstractFrame{W},FWD<:AbstractFeatureLookupSet{V,FR}}
        features = collect(features)
        FT = Union{typeof.(features)...}
        features = Vector{FT}(features)
        ActiveLogiset{V,W,FR,FT,FWD}(featstruct, features, args...; kwargs...)
    end

    function ActiveLogiset{V,W}(
        featstruct              :: AbstractFeatureLookupSet{V,FR},
        args...;
        kwargs...
    ) where {V,W<:AbstractWorld,FR<:AbstractFrame{W}}
        ActiveLogiset{V,W,FR}(featstruct, args...; kwargs...)
    end

    function ActiveLogiset(
        featstruct             :: AbstractFeatureLookupSet{V,FR},
        args...;
        kwargs...,
    ) where {V,W<:AbstractWorld,FR<:AbstractFrame{W}}
        ActiveLogiset{V,W}(featstruct, args...; kwargs...)
    end
end


@inline function Base.getindex(X::ActiveLogiset{V,W}, args...) where {V,W<:AbstractWorld}
    Base.getindex(featstruct(X), args...)::V
end

@inline function featvalue(X::ActiveLogiset{V,W}, args...) where {V,W<:AbstractWorld}
    featvalue(featstruct(X), args...)::V
end

Base.size(X::ActiveLogiset)              = Base.size(featstruct(X))

featstruct(X::ActiveLogiset)                    = X.featstruct
relations(X::ActiveLogiset)              = X.relations
features(X::ActiveLogiset)               = X.features

nfeatures(X::ActiveLogiset)              = length(features(X))
nrelations(X::ActiveLogiset)             = length(relations(X))
ninstances(X::ActiveLogiset)               = ninstances(featstruct(X))
worldtype(X::ActiveLogiset{V,W}) where {V,W<:AbstractWorld} = W

frame(X::ActiveLogiset, i_instance::Integer) = frame(featstruct(X), i_instance)
initialworld(X::ActiveLogiset) = X.initialworld
function initialworld(X::ActiveLogiset, i_instance::Integer)
    initialworld(X) isa AbstractWorldSet ? initialworld(X)[i_instance] : initialworld(X)
end

function instances(X::ActiveLogiset, inds::AbstractVector{<:Integer}, args...; kwargs...)
    ActiveLogiset(
        instances(featstruct(X), inds, args...; kwargs...),
        features(X),
        relations(X),
        initialworld = initialworld(X)
    )
end

function displaystructure(X::ActiveLogiset; indent_str = "")
    out = "$(typeof(X))\t$(humansize(X))\n"
    out *= indent_str * "├ features:\t\t$((length(features(X))))\t$(features(X))\n"
    out *= indent_str * "├ relations:\t\t$((length(relations(X))))\t$(relations(X))\n"
    out *= indent_str * "├ featstruct:\t\t$(typeof(featstruct(X)))\t$(Base.summarysize(featstruct(X)) / 1024 / 1024 |> x->round(x, digits=2)) MBs\n"
    out *= indent_str * "└ initialworld(s)\t$(initialworld(X))"
    out
end

hasnans(X::ActiveLogiset) = hasnans(featstruct(X))

isminifiable(::ActiveLogiset) = true

function minify(X::ActiveLogiset)
    new_fwd, backmap = minify(featstruct(X))
    X = ActiveLogiset(
        new_fwd,
        features(X),
        relations(X),
    )
    X, backmap
end
