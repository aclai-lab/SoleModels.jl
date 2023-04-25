using SoleLogics: OneWorld, Interval, Interval2D
using SoleLogics: Full0DFrame, Full1DFrame, Full2DFrame
using SoleLogics: X, Y, Z
using SoleLogics: AbstractWorld, IdentityRel
import SoleLogics: syntaxstring
import SoleLogics: frame

include("minify.jl")

include("features.jl")
include("test-operators.jl")
include("conditions.jl")
include("representatives.jl")
include("datasets.jl")

include("dimensional-datasets/main.jl")

include("random.jl")
