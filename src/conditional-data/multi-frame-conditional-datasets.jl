"""
    struct MultiFrameConditionalDataset{MD<:AbstractConditionalDataset}
        modalities  :: Vector{<:MD}
    end

A multi-frame conditional dataset. This structure is useful for representing
multimodal datasets in logical terms.

See also
[`AbstractConditionalDataset`](@ref),
[`minify`](@ref).
"""
struct MultiFrameConditionalDataset{MD<:AbstractConditionalDataset}

    modalities  :: Vector{<:MD}

    function MultiFrameConditionalDataset{MD}(X::MultiFrameConditionalDataset{MD}) where {MD<:AbstractConditionalDataset}
        MultiFrameConditionalDataset{MD}(X.modalities)
    end
    function MultiFrameConditionalDataset{MD}(Xs::AbstractVector) where {MD<:AbstractConditionalDataset}
        Xs = collect(Xs)
        @assert length(Xs) > 0 && length(unique(ninstances.(Xs))) == 1 "Can't create an empty MultiFrameConditionalDataset or with mismatching number of samples (nmodalities: $(length(Xs)), frame_sizes: $(ninstances.(Xs)))."
        new{MD}(Xs)
    end
    function MultiFrameConditionalDataset{MD}() where {MD<:AbstractConditionalDataset}
        new{MD}(MD[])
    end
    function MultiFrameConditionalDataset{MD}(X::MD) where {MD<:AbstractConditionalDataset}
        MultiFrameConditionalDataset{MD}(MD[X])
    end
    function MultiFrameConditionalDataset(Xs::AbstractVector{<:MD}) where {MD<:AbstractConditionalDataset}
        MultiFrameConditionalDataset{MD}(Xs)
    end
    function MultiFrameConditionalDataset(X::MD) where {MD<:AbstractConditionalDataset}
        MultiFrameConditionalDataset{MD}(X)
    end
end

modalities(X::MultiFrameConditionalDataset) = X.modalities

Base.iterate(X::MultiFrameConditionalDataset, state=1)                     = state > length(X) ? nothing : (get_instance(X, state), state+1)
Base.length(X::MultiFrameConditionalDataset)                               = ninstances(X)
Base.push!(X::MultiFrameConditionalDataset, f::AbstractConditionalDataset) = push!(modalities(X), f)

Base.size(X::MultiFrameConditionalDataset)                                 = map(size, modalities(X))

frame(X::MultiFrameConditionalDataset, i_frame::Integer)                   = nmodalities(X) > 0 ? modalities(X)[i_frame] : error("MultiFrameConditionalDataset has no frame!")
nmodalities(X::MultiFrameConditionalDataset)                                   = length(modalities(X))
ninstances(X::MultiFrameConditionalDataset)                                  = ninstances(frame(X, 1))

# max_channel_size(X::MultiFrameConditionalDataset) = map(max_channel_size, modalities(X)) # TODO: figure if this is useless or not. Note: channel_size doesn't make sense at this point.
nfeatures(X::MultiFrameConditionalDataset) = map(nfeatures, modalities(X)) # Note: used for safety checks in fit_tree.jl
# nrelations(X::MultiFrameConditionalDataset) = map(nrelations, modalities(X)) # TODO: figure if this is useless or not
nfeatures(X::MultiFrameConditionalDataset,  i_frame::Integer) = nfeatures(frame(X, i_frame))
nrelations(X::MultiFrameConditionalDataset, i_frame::Integer) = nrelations(frame(X, i_frame))
worldtype(X::MultiFrameConditionalDataset,  i_frame::Integer) = worldtype(frame(X, i_frame))
worldtypes(X::MultiFrameConditionalDataset) = Vector{Type{<:AbstractWorld}}(worldtype.(modalities(X)))

get_instance(X::MultiFrameConditionalDataset,  i_frame::Integer, idx_i::Integer, args...)  = get_instance(frame(X, i_frame), idx_i, args...)
# get_instance(X::MultiFrameConditionalDataset, idx_i::Integer, args...)  = get_instance(frame(X, i), idx_i, args...) # TODO should slice across the modalities!

instances(X::MultiFrameConditionalDataset{MD}, inds::AbstractVector{<:Integer}, return_view::Union{Val{true},Val{false}} = Val(false)) where {MD<:AbstractConditionalDataset} =
    MultiFrameConditionalDataset{MD}(Vector{MD}(map(frame->instances(frame, inds, return_view), modalities(X))))

function display_structure(Xs::MultiFrameConditionalDataset; indent_str = "")
    out = "$(typeof(Xs))" # * "\t\t\t$(Base.summarysize(Xs) / 1024 / 1024 |> x->round(x, digits=2)) MBs"
    for (i_frame, X) in enumerate(modalities(Xs))
        if i_frame == nmodalities(Xs)
            out *= "\n$(indent_str)└ "
        else
            out *= "\n$(indent_str)├ "
        end
        out *= "[$(i_frame)] "
        # \t\t\t$(Base.summarysize(X) / 1024 / 1024 |> x->round(x, digits=2)) MBs\t(worldtype: $(worldtype(X)))"
        out *= display_structure(X; indent_str = indent_str * (i_frame == nmodalities(Xs) ? "   " : "│  ")) * "\n"
    end
    out
end

hasnans(Xs::MultiFrameConditionalDataset) = any(hasnans.(modalities(Xs)))

isminifiable(::MultiFrameConditionalDataset) = true

function minify(Xs::MultiFrameConditionalDataset)
    if !any(map(isminifiable, modalities(Xs)))
        if !all(map(isminifiable, modalities(Xs)))
            @error "Cannot perform minification with modalities of types $(typeof.(modalities(Xs))). Please use a minifiable format (e.g., SupportedFeaturedDataset)."
        else
            @warn "Cannot perform minification on some of the modalities provided. Please use a minifiable format (e.g., SupportedFeaturedDataset) ($(typeof.(modalities(Xs))) were used instead)."
        end
    end
    Xs, backmap = zip([!isminifiable(X) ? minify(X) : (X, identity) for X in modalities(Xs)]...)
    Xs, backmap
end
