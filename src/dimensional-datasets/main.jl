
include("dimensional-features.jl")
include("dimensional-conditions.jl")
include("parse-dimensional-condition.jl")

include("dimensional-representatives/Full0DFrame.jl")
include("dimensional-representatives/Full1DFrame.jl")
include("dimensional-representatives/Full1DFrame+IA.jl")
include("dimensional-representatives/Full1DFrame+RCC.jl")
include("dimensional-representatives/Full2DFrame.jl")

export get_ontology,
       get_interval_ontology

module DimensionalDatasets

import Base: size, show, getindex, iterate, length, push!

using BenchmarkTools
using ComputedFieldTypes
using DataStructures

using Logging: @logmsg
using SoleBase: LogOverview, LogDebug, LogDetail, throw_n_log

using SoleLogics
using SoleLogics: FullDimensionalFrame
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

import SoleModels: nfeatures, nrelations

using SoleModels: MultiFrameConditionalDataset, AbstractActiveConditionalDataset

using SoleModels: AbstractMultiModalFrame
using ThreadSafeDicts

using SoleLogics: AbstractRelation

############################################################################################

# Concrete type for ontologies
include("ontology.jl")

# Dataset structures
include("datasets/main.jl")
# 
include("gamma-access.jl")

#
# TODO figure out which convert function works best: convert(::Type{<:MultiFrameConditionalDataset{T}}, X::MD) where {T,MD<:AbstractConditionalDataset{T}} = MultiFrameConditionalDataset{MD}([X])
# convert(::Type{<:MultiFrameConditionalDataset}, X::AbstractConditionalDataset) = MultiFrameConditionalDataset([X])
# 
const ActiveMultiFrameConditionalDataset{T} = MultiFrameConditionalDataset{<:AbstractActiveFeaturedDataset{<:T}}
#
const GenericModalDataset = Union{AbstractDimensionalDataset,AbstractConditionalDataset,MultiFrameConditionalDataset}
# 

# Dimensional Ontologies
include("dimensional-ontologies.jl")

############################################################################################

end
