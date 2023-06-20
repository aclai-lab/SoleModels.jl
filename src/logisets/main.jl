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

export MultiLogiset,  modalities, worldtypes, nmodalities

# Multiframe version of logisets, for representing multimodal datasets
include("multilogiset.jl")

export check, AnchoredFormula

# Model checking algorithms for logisets and multilogisets
include("check-modes.jl")
include("check.jl")

# TODO remove?
function nfeatures end

include("scalar/main.jl")

include("dimensional-structures/main.jl")

# export get_ontology,
#        get_interval_ontology

# export DimensionalLogiset, Logiset, SupportedScalarLogiset

# using .DimensionalDatasets: nfeatures, nrelations,
#                             #
#                             relations,
#                             #
#                             GenericModalDataset,
#                             AbstractLogiset,
#                             AbstractActiveScalarLogiset,
#                             DimensionalLogiset,
#                             Logiset,
#                             SupportedScalarLogiset

# using .DimensionalDatasets: AbstractWorld, AbstractRelation
# using .DimensionalDatasets: AbstractWorldSet, WorldSet
# using .DimensionalDatasets: FullDimensionalFrame

# using .DimensionalDatasets: Ontology, worldtype

# using .DimensionalDatasets: get_ontology,
#                             get_interval_ontology

# using .DimensionalDatasets: OneWorld, OneWorldOntology

# using .DimensionalDatasets: Interval, Interval2D

# using .DimensionalDatasets: IARelations

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
