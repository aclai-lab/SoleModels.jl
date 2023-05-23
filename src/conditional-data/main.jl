using SoleLogics: OneWorld, Interval, Interval2D
using SoleLogics: Full0DFrame, Full1DFrame, Full2DFrame
using SoleLogics: X, Y, Z
using SoleLogics: AbstractWorld, IdentityRel
import SoleLogics: syntaxstring
import SoleLogics: frame

import SoleData: nsamples, nfeatures
import SoleData: nframes, frames, hasnans, _slice_dataset
# import SoleData: frame # TODO

# Minification interface for lossless data compression
include("minify.jl")

# Scalar features to be computed on worlds of dataset instances
include("features.jl")

export inverse_test_operator, dual_test_operator,
        apply_test_operator,
        TestOperator

# Test operators to be used for comparing features and threshold values
include("test-operators.jl")

# Scalar conditions on the features, to be wrapped in Proposition's
include("conditions.jl")

# Alphabets of conditions on the features, to be used in logical datasets
include("conditional-alphabets.jl")

export MixedFeature, CanonicalFeature, canonical_geq, canonical_leq

export canonical_geq_95, canonical_geq_90, canonical_geq_85, canonical_geq_80, canonical_geq_75, canonical_geq_70, canonical_geq_60,
       canonical_leq_95, canonical_leq_90, canonical_leq_85, canonical_leq_80, canonical_leq_75, canonical_leq_70, canonical_leq_60

# Types for representing common associations between features and operators
include("canonical-conditions.jl") # TODO fix

const MixedFeature = Union{AbstractFeature,CanonicalFeature,Function,Tuple{TestOperator,Function},Tuple{TestOperator,AbstractFeature}}

# Representative accessibles, for optimized model checking
include("representatives.jl")

# Datasets where the instances are Kripke models with conditional alphabets
include("conditional-datasets.jl")

include("active-featured-dataset.jl")

export nframes, frames, frame,
        display_structure,
        MultiFrameConditionalDataset,
        worldtypes

# #
# # TODO figure out which convert function works best:
# convert(::Type{<:MultiFrameConditionalDataset{T}}, X::MD) where {T,MD<:AbstractConditionalDataset{T}} = MultiFrameConditionalDataset{MD}([X])
# convert(::Type{<:MultiFrameConditionalDataset}, X::AbstractConditionalDataset) = MultiFrameConditionalDataset([X])

# Multi-frame version of conditional datasets, for representing multimodal datasets
include("multi-frame-conditional-datasets.jl") # TODO define interface

const ActiveMultiFrameConditionalDataset{T} = MultiFrameConditionalDataset{<:AbstractActiveFeaturedDataset{<:T}}

# TODO decide how to name this.
getframe = frame

# include("featured-datasets.jl") TODO?

include("random.jl")
