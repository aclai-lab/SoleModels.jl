import SoleBase: frame

using SoleLogics: OneWorld, Interval, Interval2D
using SoleLogics: Full0DFrame, Full1DFrame, Full2DFrame
using SoleLogics: X, Y, Z
using SoleLogics: AbstractWorld, IdentityRel
import SoleLogics: syntaxstring

import SoleData: nsamples, nfeatures
import SoleData: nframes, frames, hasnans, _slice_dataset

# Features to be computed on worlds of dataset instances
include("features.jl")

# Conditions on the features, to be wrapped in Proposition's
include("conditions.jl")

export check, accessibles, allworlds, representatives, initialworld

# Interface for representative accessibles, for optimized model checking on specific frames
include("representatives.jl")

# Logical datasets, where the instances are Kripke models with conditional alphabets
include("logiset-interface.jl")

# Logical dataset based on a lookup
include("logiset.jl")

# include("supported-logiset.jl")

# export nframes, frames, frame,
#         displaystructure,
#         MultiFrameLogiset,
#         worldtypes

# # Multiframe version of logisets, for representing multimodal datasets
# include("multiframe-logiset.jl") # TODO define interface

# const ActiveMultiFrameLogiset = MultiFrameLogiset{<:AbstractLogiset}
# const ActiveMultiFrameScalarLogiset = MultiFrameScalarLogiset{<:AbstractActiveScalarLogiset}



# include("generic-supporting-datasets.jl")
# include("generic-supports.jl")


# #
# # TODO figure out which convert function works best:
# convert(::Type{<:MultiFrameLogiset{T}}, X::MD) where {T,MD<:AbstractLogiset{T}} = MultiFrameLogiset{MD}([X])
# convert(::Type{<:MultiFrameLogiset}, X::AbstractLogiset) = MultiFrameLogiset([X])
