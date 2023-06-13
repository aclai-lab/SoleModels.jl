module DimensionalDatasets

import SoleLogics: worldtype

using SoleModels.utils

# export parsecondition

# # Conditions on features for dimensional datasets
# include("_parse-dimensional-condition.jl")

# # Concrete type for ontologies
# include("ontology.jl") # TODO frame inside the ontology?

# export DimensionalLogiset, Logiset, SupportedScalarLogiset

# # Dataset structures
# include("datasets/main.jl")

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
