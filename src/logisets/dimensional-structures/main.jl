module DimensionalDatasets


import Base: size, show, getindex, iterate, length, push!, eltype

using BenchmarkTools
using ProgressMeter
using UniqueVectors

using SoleBase

using SoleLogics
using SoleLogics: AbstractFormula, AbstractWorld, AbstractRelation
using SoleLogics: AbstractFrame, AbstractDimensionalFrame, FullDimensionalFrame
import SoleLogics: worldtype, accessibles, allworlds, alphabet, initialworld

using SoleData
import SoleData: _isnan, hasnans, nvariables, max_channel_size, channel_size
import SoleData: instance, get_instance, instances, concatdatasets
import SoleData: displaystructure
import SoleData: dimensionality


using SoleModels
using SoleModels.utils
using SoleModels: Aggregator, AbstractCondition
using SoleModels: BoundedScalarConditions
using SoleModels: CanonicalFeatureGeq, CanonicalFeatureGeqSoft, CanonicalFeatureLeq, CanonicalFeatureLeqSoft
using SoleModels: AbstractLogiset, AbstractMultiModalFrame
using SoleModels: MultiLogiset, AbstractLogiset
using SoleModels: apply_test_operator, existential_aggregator, aggregator_bottom, aggregator_to_binary

using SoleModels: worldtype, featvaltype, featuretype, frametype

import SoleModels: representatives, ScalarMetaCondition, ScalarCondition, featvaltype
import SoleModels: ninstances, nrelations, nfeatures, check, instances, minify
import SoleModels: displaystructure, frame
import SoleModels: alphabet, isminifiable

import SoleModels: nmetaconditions
import SoleModels: capacity, nmemoizedvalues
using SoleModels: memoizationinfo


import SoleModels: initlogiset
import SoleModels: worldtype, allworlds, featvalue, featvalue!
import SoleModels: featchannel, readfeature, featvalues!, allfeatvalues
import SoleData: get_instance, ninstances, nvariables, channel_size, eltype

export nvariables

############################################################################################

# Frame-specific logisets
include("logiset.jl")

include("onestep-memosets.jl")

export initlogiset, ninstances, max_channel_size, worldtype, dimensionality, allworlds, featvalue

# Bindings for interpreting dataset structures as logisets
include("dataset-bindings.jl")

using SoleLogics: Full0DFrame, Full1DFrame, Full2DFrame
using SoleLogics: X, Y, Z

# Representatives for dimensional frames
include("representatives/Full0DFrame.jl")
include("representatives/Full1DFrame.jl")
include("representatives/Full1DFrame+IA.jl")
include("representatives/Full1DFrame+RCC.jl")
include("representatives/Full2DFrame.jl")

end
