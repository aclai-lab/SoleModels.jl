
# Features for (multi)variate data
include("var-features.jl")

# Test operators to be used for comparing features and threshold values
include("test-operators.jl")

# Alphabets of conditions on the features, to be used in logical datasets
include("conditions.jl")

# Templates for formulas of scalar conditions (e.g., templates for ⊤, f ⋈ t, ⟨R⟩ f ⋈ t, etc.)
include("templated-formulas.jl")

# Types for representing common associations between features and operators
include("canonical-conditions.jl")

const MixedFeature = Union{AbstractFeature,CanonicalFeature,Function,Tuple{TestOperator,Function},Tuple{TestOperator,AbstractFeature}}

include("random.jl")

include("representatives.jl")

include("dataset-bindings.jl")

include("memosets.jl")

include("onestep-memoset.jl")
