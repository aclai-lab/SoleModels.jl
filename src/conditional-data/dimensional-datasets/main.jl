module ModalLogic

export nfeatures, nrelations,
       nframes, frames, get_frame,
       display_structure,
       #
       relations,
       #
       GenericModalDataset,
       ActiveMultiFrameModalDataset,
       MultiFrameModalDataset,
       ActiveFeaturedDataset,
       DimensionalFeaturedDataset,
       FeaturedDataset,
       SupportedFeaturedDataset

# Reexport from SoleLogics:
export AbstractWorld, AbstractRelation
export AbstractWorldSet, WorldSet

export Ontology, worldtype

import Base: size, show, getindex, iterate, length, push!

using BenchmarkTools
using ComputedFieldTypes
using DataStructures

using Logging: @logmsg
using SoleBase: LogOverview, LogDebug, LogDetail, throw_n_log

using SoleLogics
using SoleLogics: AbstractRelation, AbstractWorld
import SoleLogics: worldtype

using SoleData: _isnan
import SoleData: hasnans

import SoleData: nsamples
import SoleData: nattributes, max_channel_size, get_instance,
       instance_channel_size

using SoleModels
using SoleModels: Aggregator

using SoleLogics: AbstractFrame, AbstractDimensionalFrame, FullDimensionalFrame
using SoleModels: AbstractConditionalDataset, AbstractCondition

import SoleLogics: accessibles, allworlds
import SoleModels: representatives, FeatMetaCondition, FeatCondition
import SoleModels: minify

using SoleModels: AbstractMultiModalFrame
using ThreadSafeDicts


# Concrete type for ontologies
include("ontology.jl")

# Dataset structures
# 
include("datasets/main.jl")
# 
include("gamma-access.jl")
# 
# Define the multi-modal version of modal datasets (basically, a vector of datasets with the
#  same number of instances)
# 
include("multi-frame-dataset.jl")
# 
# TODO figure out which convert function works best: convert(::Type{<:MultiFrameModalDataset{T}}, X::MD) where {T,MD<:AbstractConditionalDataset{T}} = MultiFrameModalDataset{MD}([X])
# convert(::Type{<:MultiFrameModalDataset}, X::AbstractConditionalDataset) = MultiFrameModalDataset([X])
# 
const ActiveMultiFrameModalDataset{T} = MultiFrameModalDataset{<:ActiveFeaturedDataset{<:T}}
#
const GenericModalDataset = Union{AbstractDimensionalDataset,AbstractConditionalDataset,MultiFrameModalDataset}
# 

# Dimensional Ontologies
include("dimensional-ontologies.jl")

############################################################################################

end # module
