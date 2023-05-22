using SoleLogics: OneWorld, Interval, Interval2D
using SoleLogics: Full0DFrame, Full1DFrame, Full2DFrame
using SoleLogics: X, Y, Z
using SoleLogics: AbstractWorld, IdentityRel
import SoleLogics: syntaxstring
import SoleLogics: frame

# Minification interface for lossless data compression
include("minify.jl")

# Feature brackets
const UNIVARIATEFEATURE_OPENING_BRACKET = "["
const UNIVARIATEFEATURE_CLOSING_BRACKET = "]"

# Default prefix for variables
const UNIVARIATEFEATURE_VARPREFIX = "V"

include("features.jl")
include("test-operators.jl")
include("conditions.jl")

export MixedFeature, CanonicalFeature, canonical_geq, canonical_leq

export canonical_geq_95, canonical_geq_90, canonical_geq_85, canonical_geq_80, canonical_geq_75, canonical_geq_70, canonical_geq_60,
       canonical_leq_95, canonical_leq_90, canonical_leq_85, canonical_leq_80, canonical_leq_75, canonical_leq_70, canonical_leq_60

include("canonical-conditions.jl") # TODO fix

const MixedFeature = Union{AbstractFeature,CanonicalFeature,Function,Tuple{TestOperator,Function},Tuple{TestOperator,AbstractFeature}}

include("parse-condition.jl")

include("representatives.jl")
include("datasets.jl")
include("dimensional-datasets/main.jl")

include("random.jl")
