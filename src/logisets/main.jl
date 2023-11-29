using SoleLogics
import SoleLogics: frame

using SoleLogics: OneWorld, Interval, Interval2D
using SoleLogics: Full0DFrame, Full1DFrame, Full2DFrame
using SoleLogics: X, Y, Z
using SoleLogics: AbstractWorld, IdentityRel
import SoleLogics: syntaxstring

import SoleData: ninstances
import SoleData: hasnans, instances, concatdatasets
import SoleData: displaystructure

# TODO fix
import SoleData: eachinstance
import Tables: istable, rows, subset, getcolumn, columnnames, rowaccess

# Features to be computed on worlds of dataset instances
include("features.jl")

# Conditions on the features, to be wrapped in Atom's
include("conditions.jl")

# Templates for formulas of conditions (e.g., templates for ⊤, p, ⟨R⟩p, etc.)
include("templated-formulas.jl")

export accessibles, allworlds, representatives

# Interface for representative accessibles, for optimized model checking on specific frames
include("representatives.jl")

export ninstances, featvalue, displaystructure, isminifiable, minify

# Logical datasets, where the instances are Kripke structures with conditional alphabets
include("logiset.jl")

include("memosets.jl")

include("supported-logiset.jl")

export MultiLogiset, eachmodality, modality, nmodalities

export MultiFormula, modforms

# Multi-frame version of logisets, for representing multimodal datasets
include("multilogiset.jl")

export check

# Model checking algorithms for logisets and multilogisets
include("check.jl")

export nfeatures

include("scalar/main.jl")

# Tables interface for logiset's, so that it can be integrated with MLJ
include("MLJ-interface.jl")

export initlogiset, ninstances, maxchannelsize, worldtype, dimensionality, allworlds, featvalue

export nvariables

include("dimensional-structures/main.jl")

function default_relmemoset_type(X::AbstractLogiset)
    # if X isa DimensionalDatasets.UniformFullDimensionalLogiset
    frames = [SoleLogics.frame(X, i_instance) for i_instance in 1:ninstances(X)]
    if allequal(frames) # Uniform logiset
        _frame = first(unique(frames))
        if _frame isa DimensionalDatasets.FullDimensionalFrame
            DimensionalDatasets.UniformFullDimensionalOneStepRelationalMemoset
        else
            # error("Unknown frame of type $(typeof(_frame)).")
            ScalarOneStepRelationalMemoset
        end
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
