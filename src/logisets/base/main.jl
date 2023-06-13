import SoleLogics: frame

using SoleLogics: OneWorld, Interval, Interval2D
using SoleLogics: Full0DFrame, Full1DFrame, Full2DFrame
using SoleLogics: X, Y, Z
using SoleLogics: AbstractWorld, IdentityRel
import SoleLogics: syntaxstring

import SoleData: ninstances
import SoleData: hasnans, instances

# Features to be computed on worlds of dataset instances
include("features.jl")

# Conditions on the features, to be wrapped in Proposition's
include("conditions.jl")

export check, accessibles, allworlds, representatives, initialworld

# Interface for representative accessibles, for optimized model checking on specific frames
include("representatives.jl")

export ninstances, featvalue, displaystructure, isminifiable, minify

# Logical datasets, where the instances are Kripke models with conditional alphabets
include("logiset.jl")

include("memosets.jl")

include("supported-logiset.jl")

export MultiLogiset,  modalities, worldtypes, nmodalities

# Multiframe version of logisets, for representing multimodal datasets
include("multilogiset.jl")

# Model checking algorithms for logisets and multilogisets
include("check.jl")

include("scalar/main.jl")

# # TODO figure out which convert function works best:
# convert(::Type{<:MultiLogiset{T}}, X::MD) where {T,MD<:AbstractLogiset{T}} = MultiLogiset{MD}([X])
# convert(::Type{<:MultiLogiset}, X::AbstractLogiset) = MultiLogiset([X])
