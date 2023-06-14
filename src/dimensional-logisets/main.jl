module DimensionalDatasets


import Base: size, show, getindex, iterate, length, push!, eltype

using BenchmarkTools
using ComputedFieldTypes
using DataStructures
using ThreadSafeDicts
using ProgressMeter

using SoleBase

using SoleLogics
using SoleLogics: AbstractFormula, AbstractWorld, AbstractRelation
using SoleLogics: AbstractFrame, AbstractDimensionalFrame, FullDimensionalFrame
import SoleLogics: worldtype, accessibles, allworlds, alphabet, initialworld

using SoleData
import SoleData: _isnan, hasnans, nvariables, max_channel_size, channel_size
import SoleData: instance, get_instance, slicedataset, instances
import SoleData: dimensionality

############################################################################################

function check_initialworld(FD::Type{<:AbstractLogiset}, initialworld, W)
    @assert isnothing(initialworld) || initialworld isa W "Cannot instantiate " *
        "$(FD) with worldtype = $(W) but initialworld of type $(typeof(initialworld))."
end

using SoleModels.utils

# # Dataset structures
include("passive-dimensional-logiset.jl")

include("dimensional-logiset.jl")

# Frame-specific featured world datasets and supports
include("dimensional-fwds.jl")

include("dimensional-supports.jl")

# export parsecondition

# # Conditions on features for dimensional datasets
# include("_parse-dimensional-condition.jl")

# # Concrete type for ontologies
# include("ontology.jl") # TODO frame inside the ontology?

# export DimensionalLogiset, Logiset, SupportedScalarLogiset

# const GenericModalDataset = Union{AbstractDimensionalDataset,AbstractLogiset,MultiLogiset}

# # Dimensional ontologies
# include("dimensional-ontologies.jl")

using SoleLogics: Full0DFrame, Full1DFrame, Full2DFrame
using SoleLogics: X, Y, Z

# Representatives for dimensional frames
include("representatives/Full0DFrame.jl")
include("representatives/Full1DFrame.jl")
include("representatives/Full1DFrame+IA.jl")
include("representatives/Full1DFrame+RCC.jl")
include("representatives/Full2DFrame.jl")

end
