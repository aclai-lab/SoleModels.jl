import SoleLogics: frame

using SoleLogics: OneWorld, Interval, Interval2D
using SoleLogics: Full0DFrame, Full1DFrame, Full2DFrame
using SoleLogics: X, Y, Z
using SoleLogics: AbstractWorld, IdentityRel
import SoleLogics: syntaxstring

import SoleData: ninstances
import SoleData: hasnans, instances, concatdatasets
import SoleData: displaystructure

# Features to be computed on worlds of dataset instances
include("features.jl")

# Conditions on the features, to be wrapped in Proposition's
include("conditions.jl")

# Templates for formulas of conditions (e.g., templates for ⊤, p, ⟨R⟩p, etc.)
include("templated-formulas.jl")

export accessibles, allworlds, representatives

# Interface for representative accessibles, for optimized model checking on specific frames
include("representatives.jl")

export ninstances, featvalue, displaystructure, isminifiable, minify

# Logical datasets, where the instances are Kripke models with conditional alphabets
include("logiset.jl")

include("memosets.jl")

include("supported-logiset.jl")

export MultiLogiset, eachmodality, modality, nmodalities

# Multiframe version of logisets, for representing multimodal datasets
include("multilogiset.jl")

export check, AnchoredFormula

# Model checking algorithms for logisets and multilogisets
include("check-modes.jl")
include("check.jl")

export nfeatures

include("scalar/main.jl")


include("Tables.jl")

export initlogiset, ninstances, maxchannelsize, worldtype, dimensionality, allworlds, featvalue

export nvariables

include("dimensional-structures/main.jl")

function default_relmemoset_type(X::AbstractLogiset)
    # TODO?
    # frames = [frame(X, i_instance) for i_instance in 1:ninstances(X)]
    # if allequal(frames) && first(unique(frames)) isa FullDimensionalFrame
    if X isa DimensionalDatasets.UniformFullDimensionalLogiset
        DimensionalDatasets.UniformFullDimensionalOneStepRelationalMemoset
    else
        ScalarOneStepRelationalMemoset
    end
end

function default_onestep_memoset_type(X::AbstractLogiset)
    if featvaltype(X) <: Real
        ScalarOneStepMemoset
    else
        OneStepMemoset
    end
end
function default_full_memoset_type(X::AbstractLogiset)
    # if ...
    #     ScalarChainedMemoset TODO
    # else
        FullMemoset
    # end
end
