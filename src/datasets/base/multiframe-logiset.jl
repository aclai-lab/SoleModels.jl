"""
    struct MultiFrameLogiset{MD<:AbstractLogiset}
        frames  :: Vector{<:MD}
    end

A multiframe logical dataset; this structure is useful for representing
multimodal datasets in logical terms.

See also
[`AbstractLogiset`](@ref),
[`minify`](@ref).
"""
struct MultiFrameLogiset{MD<:AbstractLogiset}

    frames  :: Vector{<:MD}

    function MultiFrameLogiset{MD}(X::MultiFrameLogiset{MD}) where {MD<:AbstractLogiset}
        MultiFrameLogiset{MD}(X.frames)
    end
    function MultiFrameLogiset{MD}(Xs::AbstractVector) where {MD<:AbstractLogiset}
        Xs = collect(Xs)
        @assert length(Xs) > 0 && length(unique(nsamples.(Xs))) == 1 "Can't create an empty MultiFrameLogiset or with mismatching number of samples (nframes: $(length(Xs)), frame_sizes: $(nsamples.(Xs)))."
        new{MD}(Xs)
    end
    function MultiFrameLogiset{MD}() where {MD<:AbstractLogiset}
        new{MD}(MD[])
    end
    function MultiFrameLogiset{MD}(X::MD) where {MD<:AbstractLogiset}
        MultiFrameLogiset{MD}(MD[X])
    end
    function MultiFrameLogiset(Xs::AbstractVector{<:MD}) where {MD<:AbstractLogiset}
        MultiFrameLogiset{MD}(Xs)
    end
    function MultiFrameLogiset(X::MD) where {MD<:AbstractLogiset}
        MultiFrameLogiset{MD}(X)
    end
end

frames(X::MultiFrameLogiset) = X.frames

Base.iterate(X::MultiFrameLogiset, state=1)                     = state > length(X) ? nothing : (get_instance(X, state), state+1)
Base.length(X::MultiFrameLogiset)                               = nsamples(X)
Base.push!(X::MultiFrameLogiset, f::AbstractLogiset) = push!(frames(X), f)

Base.size(X::MultiFrameLogiset)                                 = map(size, frames(X))

frame(X::MultiFrameLogiset, i_frame::Integer)                   = nframes(X) > 0 ? frames(X)[i_frame] : error("MultiFrameLogiset has no frame!")
nframes(X::MultiFrameLogiset)                                   = length(frames(X))
nsamples(X::MultiFrameLogiset)                                  = nsamples(frame(X, 1))

# max_channel_size(X::MultiFrameLogiset) = map(max_channel_size, frames(X)) # TODO: figure if this is useless or not. Note: channel_size doesn't make sense at this point.
nfeatures(X::MultiFrameLogiset) = map(nfeatures, frames(X)) # Note: used for safety checks in fit_tree.jl
# nrelations(X::MultiFrameLogiset) = map(nrelations, frames(X)) # TODO: figure if this is useless or not
nfeatures(X::MultiFrameLogiset,  i_frame::Integer) = nfeatures(frame(X, i_frame))
nrelations(X::MultiFrameLogiset, i_frame::Integer) = nrelations(frame(X, i_frame))
worldtype(X::MultiFrameLogiset,  i_frame::Integer) = worldtype(frame(X, i_frame))
worldtypes(X::MultiFrameLogiset) = Vector{Type{<:AbstractWorld}}(worldtype.(frames(X)))

get_instance(X::MultiFrameLogiset,  i_frame::Integer, idx_i::Integer, args...)  = get_instance(frame(X, i_frame), idx_i, args...)
# get_instance(X::MultiFrameLogiset, idx_i::Integer, args...)  = get_instance(frame(X, i), idx_i, args...) # TODO should slice across the frames!

_slice_dataset(X::MultiFrameLogiset{MD}, inds::AbstractVector{<:Integer}, args...; kwargs...) where {MD<:AbstractLogiset} =
    MultiFrameLogiset{MD}(Vector{MD}(map(frame->_slice_dataset(frame, inds, args...; kwargs...), frames(X))))

function displaystructure(Xs::MultiFrameLogiset; indent_str = "")
    out = "$(typeof(Xs))" # * "\t\t\t$(Base.summarysize(Xs) / 1024 / 1024 |> x->round(x, digits=2)) MBs"
    for (i_frame, X) in enumerate(frames(Xs))
        if i_frame == nframes(Xs)
            out *= "\n$(indent_str)└ "
        else
            out *= "\n$(indent_str)├ "
        end
        out *= "[$(i_frame)] "
        # \t\t\t$(Base.summarysize(X) / 1024 / 1024 |> x->round(x, digits=2)) MBs\t(worldtype: $(worldtype(X)))"
        out *= displaystructure(X; indent_str = indent_str * (i_frame == nframes(Xs) ? "   " : "│  ")) * "\n"
    end
    out
end

hasnans(Xs::MultiFrameLogiset) = any(hasnans.(frames(Xs)))

isminifiable(::MultiFrameLogiset) = true

function minify(Xs::MultiFrameLogiset)
    if !any(map(isminifiable, frames(Xs)))
        if !all(map(isminifiable, frames(Xs)))
            @error "Cannot perform minification with frames of types $(typeof.(frames(Xs))). Please use a minifiable format (e.g., SupportedScalarLogiset)."
        else
            @warn "Cannot perform minification on some of the frames provided. Please use a minifiable format (e.g., SupportedScalarLogiset) ($(typeof.(frames(Xs))) were used instead)."
        end
    end
    Xs, backmap = zip([!isminifiable(X) ? minify(X) : (X, identity) for X in frames(Xs)]...)
    Xs, backmap
end
