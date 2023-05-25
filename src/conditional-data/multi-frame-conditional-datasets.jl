"""
    struct MultiFrameConditionalDataset{MD<:AbstractConditionalDataset}
        frames  :: Vector{<:MD}
    end

A multi-frame conditional dataset. This structure is useful for representing
multimodal datasets in logical terms.

See also
[`AbstractConditionalDataset`](@ref),
[`minify`](@ref).
"""
struct MultiFrameConditionalDataset{MD<:AbstractConditionalDataset}

    frames  :: Vector{<:MD}

    function MultiFrameConditionalDataset{MD}(X::MultiFrameConditionalDataset{MD}) where {MD<:AbstractConditionalDataset}
        MultiFrameConditionalDataset{MD}(X.frames)
    end
    function MultiFrameConditionalDataset{MD}(Xs::AbstractVector) where {MD<:AbstractConditionalDataset}
        Xs = collect(Xs)
        @assert length(Xs) > 0 && length(unique(nsamples.(Xs))) == 1 "Can't create an empty MultiFrameConditionalDataset or with mismatching number of samples (nframes: $(length(Xs)), frame_sizes: $(nsamples.(Xs)))."
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

frames(X::MultiFrameConditionalDataset) = X.frames

Base.iterate(X::MultiFrameConditionalDataset, state=1)                     = state > length(X) ? nothing : (get_instance(X, state), state+1)
Base.length(X::MultiFrameConditionalDataset)                               = nsamples(X)
Base.push!(X::MultiFrameConditionalDataset, f::AbstractConditionalDataset) = push!(frames(X), f)

Base.size(X::MultiFrameConditionalDataset)                                 = map(size, frames(X))

frame(X::MultiFrameConditionalDataset, i_frame::Integer)                   = nframes(X) > 0 ? frames(X)[i_frame] : error("MultiFrameConditionalDataset has no frame!")
nframes(X::MultiFrameConditionalDataset)                                   = length(frames(X))
nsamples(X::MultiFrameConditionalDataset)                                  = nsamples(frame(X, 1))

# max_channel_size(X::MultiFrameConditionalDataset) = map(max_channel_size, frames(X)) # TODO: figure if this is useless or not. Note: channel_size doesn't make sense at this point.
nfeatures(X::MultiFrameConditionalDataset) = map(nfeatures, frames(X)) # Note: used for safety checks in fit_tree.jl
# nrelations(X::MultiFrameConditionalDataset) = map(nrelations, frames(X)) # TODO: figure if this is useless or not
nfeatures(X::MultiFrameConditionalDataset,  i_frame::Integer) = nfeatures(frame(X, i_frame))
nrelations(X::MultiFrameConditionalDataset, i_frame::Integer) = nrelations(frame(X, i_frame))
worldtype(X::MultiFrameConditionalDataset,  i_frame::Integer) = worldtype(frame(X, i_frame))
worldtypes(X::MultiFrameConditionalDataset) = Vector{Type{<:AbstractWorld}}(worldtype.(frames(X)))

get_instance(X::MultiFrameConditionalDataset,  i_frame::Integer, idx_i::Integer, args...)  = get_instance(frame(X, i_frame), idx_i, args...)
# get_instance(X::MultiFrameConditionalDataset, idx_i::Integer, args...)  = get_instance(frame(X, i), idx_i, args...) # TODO should slice across the frames!

_slice_dataset(X::MultiFrameConditionalDataset{MD}, inds::AbstractVector{<:Integer}, args...; kwargs...) where {MD<:AbstractConditionalDataset} =
    MultiFrameConditionalDataset{MD}(Vector{MD}(map(frame->_slice_dataset(frame, inds, args...; kwargs...), frames(X))))

function display_structure(Xs::MultiFrameConditionalDataset; indent_str = "")
    out = "$(typeof(Xs))" # * "\t\t\t$(Base.summarysize(Xs) / 1024 / 1024 |> x->round(x, digits=2)) MBs"
    for (i_frame, X) in enumerate(frames(Xs))
        if i_frame == nframes(Xs)
            out *= "\n$(indent_str)└ "
        else
            out *= "\n$(indent_str)├ "
        end
        out *= "[$(i_frame)] "
        # \t\t\t$(Base.summarysize(X) / 1024 / 1024 |> x->round(x, digits=2)) MBs\t(worldtype: $(worldtype(X)))"
        out *= display_structure(X; indent_str = indent_str * (i_frame == nframes(Xs) ? "   " : "│  ")) * "\n"
    end
    out
end

hasnans(Xs::MultiFrameConditionalDataset) = any(hasnans.(frames(Xs)))

isminifiable(::MultiFrameConditionalDataset) = true

function minify(Xs::MultiFrameConditionalDataset)
    if !any(map(isminifiable, frames(Xs)))
        if !all(map(isminifiable, frames(Xs)))
            @error "Cannot perform minification with frames of types $(typeof.(frames(Xs))). Please use a minifiable format (e.g., SupportedFeaturedDataset)."
        else
            @warn "Cannot perform minification on some of the frames provided. Please use a minifiable format (e.g., SupportedFeaturedDataset) ($(typeof.(frames(Xs))) were used instead)."
        end
    end
    Xs, backmap = zip([!isminifiable(X) ? minify(X) : (X, identity) for X in frames(Xs)]...)
    Xs, backmap
end
