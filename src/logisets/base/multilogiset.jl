"""
    struct MultiLogiset{L<:AbstractLogiset}
        modalities  :: Vector{L}
    end

A logical dataset composed of different
[modalities](https://en.wikipedia.org/wiki/Multimodal_learning));
this structure is useful for representing multimodal datasets in logical terms.

See also
[`AbstractLogiset`](@ref),
[`minify`](@ref).
"""
struct MultiLogiset{L<:AbstractLogiset}

    modalities  :: Vector{L}

    function MultiLogiset{L}(X::MultiLogiset{L}) where {L<:AbstractLogiset}
        MultiLogiset{L}(X.modalities)
    end
    function MultiLogiset{L}(X::AbstractVector) where {L<:AbstractLogiset}
        X = collect(X)
        @assert length(X) > 0 && length(unique(ninstances.(X))) == 1 "Can't create an empty MultiLogiset or with mismatching number of instances (nmodalities: $(length(X)), modality_sizes: $(ninstances.(X)))."
        new{L}(X)
    end
    function MultiLogiset{L}() where {L<:AbstractLogiset}
        new{L}(L[])
    end
    function MultiLogiset{L}(X::L) where {L<:AbstractLogiset}
        MultiLogiset{L}(L[X])
    end
    function MultiLogiset(X::AbstractVector{L}) where {L<:AbstractLogiset}
        MultiLogiset{L}(X)
    end
    function MultiLogiset(X::L) where {L<:AbstractLogiset}
        MultiLogiset{L}(X)
    end
end

modalities(X::MultiLogiset) = X.modalities

Base.length(X::MultiLogiset) = length(nmodalities(X))
Base.push!(X::MultiLogiset, f::AbstractLogiset) = push!(modalities(X), f)
Base.getindex(X::MultiLogiset, i_modality::Integer) = modalities(X)[i_modality]
Base.iterate(X::MultiLogiset, state=1)   = state > nmodalities(X) ? nothing : (modality(X, state), state+1)

modalitytype(::Type{<:MultiLogiset{L}}) where {L<:AbstractLogiset} = L
modalitytype(X::MultiLogiset) = modalitytype(typeof(X))

modality(X::MultiLogiset, i_modality::Integer) = modalities(X)[i_modality]
nmodalities(X::MultiLogiset)                   = length(modalities(X))
ninstances(X::MultiLogiset)                    = ninstances(modality(X, 1))

worldtype(X::MultiLogiset,  i_modality::Integer) = worldtype(modality(X, i_modality))
worldtypes(X::MultiLogiset) = Vector{Type{<:AbstractWorld}}(worldtype.(modalities(X)))

featvaltype(X::MultiLogiset,  i_modality::Integer) = featvaltype(modality(X, i_modality))
featvaltypes(X::MultiLogiset) = Vector{Type{<:AbstractWorld}}(featvaltype.(modalities(X)))

featuretype(X::MultiLogiset,  i_modality::Integer) = featuretype(modality(X, i_modality))
featuretypes(X::MultiLogiset) = Vector{Type{<:AbstractWorld}}(featuretype.(modalities(X)))

frametype(X::MultiLogiset,  i_modality::Integer) = frametype(modality(X, i_modality))
frametypes(X::MultiLogiset) = Vector{Type{<:AbstractWorld}}(frametype.(modalities(X)))

function instances(
    X::MultiLogiset{L},
    inds::AbstractVector{<:Integer},
    args...;
    kwargs...
) where {L<:AbstractLogiset}
    MultiLogiset{L}(Vector{L}(map(modality->instances(modality, inds, args...; kwargs...), modalities(X))))
end

function concatdatasets(Xs::MultiLogiset...)
    MultiLogiset([
        concatdatasets([modalities(X)[i_mod] for X in Xs]...) for i_mod in 1:nmodalities(Xs)
    ])
end

function Base.show(io::IO, X::MultiLogiset; kwargs...)
    println(io, displaystructure(X; kwargs...))
end

function displaystructure(X::MultiLogiset; indent_str = "", include_ninstances = true)
    out = "MultiLogiset($(humansize(X)))\n"
    if include_ninstances
        out *= indent_str * "├ # instances:\t$(ninstances(X))\n"
    end
    out *= indent_str * "├ modalitytype:\t$(modalitytype(X))\n"
    out *= indent_str * "├ # modalities:\t$(nmodalities(X))\n"
    for (i_modality, mod) in enumerate(modalities(X))
        if i_modality == nmodalities(X)
            out *= "$(indent_str)└ "
        else
            out *= "$(indent_str)├ "
        end
        out *= "[$(i_modality)] "
        # \t\t\t$(humansize(mod))\t(worldtype: $(worldtype(mod)))"
        out *= displaystructure(mod; indent_str = indent_str * (i_modality == nmodalities(X) ? "   " : "│  "), include_ninstances = false) * ""
    end
    out
end


function featvalue(
    X::MultiLogiset,
    i_modality::Integer,
    i_instance::Integer,
    w::W,
    f::AbstractFeature;
    kwargs...
) where {W<:AbstractWorld}
    featvalue(modality(X, i_modality), i_instance, w, f)
end

function check(
    p::Proposition{<:AbstractCondition},
    X::MultiLogiset,
    i_modality::Integer,
    i_instance::Integer,
    w::W;
    kwargs...
) where {W<:AbstractWorld}
    check(p, modality(X, i_modality), i_instance, w; kwargs...)
end


hasnans(X::MultiLogiset) = any(hasnans.(modalities(X)))

isminifiable(X::MultiLogiset) = any(isminifiable.(modalities(X)))

function minify(X::MultiLogiset)
    if !any(map(isminifiable, modalities(X)))
        if !all(map(isminifiable, modalities(X)))
            @error "Cannot perform minification with modalities of types $(typeof.(modalities(X))). Please use a minifiable format (e.g., SupportedScalarLogiset)."
        else
            @warn "Cannot perform minification on some of the modalities provided. Please use a minifiable format (e.g., SupportedScalarLogiset) ($(typeof.(modalities(X))) were used instead)."
        end
    end
    X, backmap = zip([!isminifiable(X) ? minify(X) : (X, identity) for X in modalities(X)]...)
    X, backmap
end

############################################################################################

function featvalue(
    f::AbstractFeature,
    X::MultiLogiset,
    i_modality::Integer,
    i_instance::Integer,
    w::W;
    kwargs...
) where {W<:AbstractWorld}
    featvalue(X, i_modality, i_instance, w, f)
end

# TODO remove:

# Base.size(X::MultiLogiset)                      = map(size, modalities(X))

# # max_channel_size(X::MultiLogiset) = map(max_channel_size, modalities(X)) # TODO: figure if this is useless or not. Note: channel_size doesn't make sense at this point.
# nfeatures(X::MultiLogiset) = map(nfeatures, modalities(X)) # Note: used for safety checks in fit_tree.jl
# # nrelations(X::MultiLogiset) = map(nrelations, modalities(X)) # TODO: figure if this is useless or not
# nfeatures(X::MultiLogiset,  i_modality::Integer) = nfeatures(modality(X, i_modality))
# nrelations(X::MultiLogiset, i_modality::Integer) = nrelations(modality(X, i_modality))
