module DimensionalDatasets

import SoleLogics: worldtype

using SoleModels.utils

# Feature brackets
const UVF_OPENING_BRACKET = "["
const UVF_CLOSING_BRACKET = "]"
# Default prefix for variables
const UVF_VARPREFIX = "V"

export UnivariateMin, UnivariateMax,
        UnivariateSoftMin, UnivariateSoftMax,
        MultivariateFeature

# Features for dimensional datasets
include("dimensional-features.jl")

export parsecondition

# Conditions on features for dimensional datasets
include("parse-dimensional-condition.jl")

# Concrete type for ontologies
include("ontology.jl") # TODO frame inside the ontology?

export DimensionalFeaturedDataset, FeaturedDataset, SupportedFeaturedDataset

# Dataset structures
include("datasets/main.jl")

const GenericModalDataset = Union{AbstractDimensionalDataset,AbstractConditionalDataset,MultiFrameConditionalDataset}

# TODO?
include("gamma-access.jl")

# Dimensional ontologies
include("dimensional-ontologies.jl")

using SoleLogics: Full0DFrame, Full1DFrame, Full2DFrame
using SoleLogics: X, Y, Z

# Representatives for dimensional modalities
include("representatives/Full0DFrame.jl")
include("representatives/Full1DFrame.jl")
include("representatives/Full1DFrame+IA.jl")
include("representatives/Full1DFrame+RCC.jl")
include("representatives/Full2DFrame.jl")

_st_featop_abbr(f::UnivariateMin,     ::typeof(≥); kwargs...) = "$(attribute_name(f; kwargs...)) ⪴"
_st_featop_abbr(f::UnivariateMax,     ::typeof(≤); kwargs...) = "$(attribute_name(f; kwargs...)) ⪳"
_st_featop_abbr(f::UnivariateSoftMin, ::typeof(≥); kwargs...) = "$(attribute_name(f; kwargs...)) $("⪴" * utils.subscriptnumber(rstrip(rstrip(string(alpha(f)*100), '0'), '.')))"
_st_featop_abbr(f::UnivariateSoftMax, ::typeof(≤); kwargs...) = "$(attribute_name(f; kwargs...)) $("⪳" * utils.subscriptnumber(rstrip(rstrip(string(alpha(f)*100), '0'), '.')))"

_st_featop_abbr(f::UnivariateMin,     ::typeof(<); kwargs...) = "$(attribute_name(f; kwargs...)) ⪶"
_st_featop_abbr(f::UnivariateMax,     ::typeof(>); kwargs...) = "$(attribute_name(f; kwargs...)) ⪵"
_st_featop_abbr(f::UnivariateSoftMin, ::typeof(<); kwargs...) = "$(attribute_name(f; kwargs...)) $("⪶" * utils.subscriptnumber(rstrip(rstrip(string(alpha(f)*100), '0'), '.')))"
_st_featop_abbr(f::UnivariateSoftMax, ::typeof(>); kwargs...) = "$(attribute_name(f; kwargs...)) $("⪵" * utils.subscriptnumber(rstrip(rstrip(string(alpha(f)*100), '0'), '.')))"

_st_featop_abbr(f::UnivariateMin,     ::typeof(≤); kwargs...) = "$(attribute_name(f; kwargs...)) ↘"
_st_featop_abbr(f::UnivariateMax,     ::typeof(≥); kwargs...) = "$(attribute_name(f; kwargs...)) ↗"
_st_featop_abbr(f::UnivariateSoftMin, ::typeof(≤); kwargs...) = "$(attribute_name(f; kwargs...)) $("↘" * utils.subscriptnumber(rstrip(rstrip(string(alpha(f)*100), '0'), '.')))"
_st_featop_abbr(f::UnivariateSoftMax, ::typeof(≥); kwargs...) = "$(attribute_name(f; kwargs...)) $("↗" * utils.subscriptnumber(rstrip(rstrip(string(alpha(f)*100), '0'), '.')))"

end
