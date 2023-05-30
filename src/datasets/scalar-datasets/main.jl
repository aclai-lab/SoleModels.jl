
export inverse_test_operator, dual_test_operator,
        apply_test_operator,
        TestOperator

# Test operators to be used for comparing features and threshold values
include("test-operators.jl")

# Alphabets of conditions on the features, to be used in logical datasets
include("scalar-conditions.jl")

export MixedFeature, CanonicalFeature, canonical_geq, canonical_leq

export canonical_geq_95, canonical_geq_90, canonical_geq_85, canonical_geq_80, canonical_geq_75, canonical_geq_70, canonical_geq_60,
       canonical_leq_95, canonical_leq_90, canonical_leq_85, canonical_leq_80, canonical_leq_75, canonical_leq_70, canonical_leq_60

# TODO remove?
# Types for representing common associations between features and operators
include("canonical-scalar-conditions.jl")

const MixedFeature = Union{AbstractFeature,CanonicalFeature,Function,Tuple{TestOperator,Function},Tuple{TestOperator,AbstractFeature}}

include("random.jl")

############################################################################################
############################################################################################
############################################################################################


include("active-scalar-logiset.jl") # TODO sort out and precisely define interface
