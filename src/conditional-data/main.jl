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
include("parse-condition.jl")
include("representatives.jl")
include("datasets.jl")

include("dimensional-datasets/main.jl")

include("random.jl")
