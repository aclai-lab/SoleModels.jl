
import Base: size, show, getindex, iterate, length, push!, eltype

using BenchmarkTools
using ComputedFieldTypes
using DataStructures
using ThreadSafeDicts
using ProgressMeter

using SoleBase
using SoleBase: LogOverview, LogDebug, LogDetail, throw_n_log
using Logging: @logmsg

using SoleLogics
using SoleLogics: AbstractFormula, AbstractWorld, AbstractRelation
using SoleLogics: AbstractFrame, AbstractDimensionalFrame, FullDimensionalFrame
import SoleLogics: worldtype, accessibles, allworlds, alphabet, initialworld

using SoleData
import SoleData: _isnan, hasnans, nvariables, max_channel_size, channel_size
import SoleData: instance, get_instance, slicedataset, instances
import SoleData: dimensionality

using SoleModels
using SoleModels: Aggregator, AbstractCondition
using SoleModels: BoundedExplicitConditionalAlphabet
using SoleModels: CanonicalFeatureGeq, CanonicalFeatureGeqSoft, CanonicalFeatureLeq, CanonicalFeatureLeqSoft
using SoleModels: AbstractConditionalDataset, AbstractMultiModalFrame
using SoleModels: MultiFrameConditionalDataset, AbstractActiveFeaturedDataset
using SoleModels: apply_test_operator, existential_aggregator, aggregator_bottom, aggregator_to_binary
import SoleModels: representatives, FeatMetaCondition, FeatCondition, featvaltype
import SoleModels: ninstances, nrelations, nfeatures, check, instances, minify
import SoleModels: nmodalities, modalities, display_structure, frame
import SoleModels: grouped_featsaggrsnops, features, grouped_metaconditions, alphabet, find_feature_id, find_relation_id, isminifiable

using SoleModels: grouped_featsnops2grouped_featsaggrsnops,
                    grouped_featsaggrsnops2grouped_featsnops,
                    features_grouped_featsaggrsnops2featsnaggrs_grouped_featsnaggrs,
                    features_grouped_featsaggrsnops2featsnaggrs,
                    features_grouped_featsaggrsnops2grouped_featsnaggrs
############################################################################################

function check_initialworld(FD::Type{<:AbstractConditionalDataset}, initialworld, W)
    @assert isnothing(initialworld) || initialworld isa W "Cannot instantiate" *
        " $(FD) with worldtype = $(W) but initialworld of type $(typeof(initialworld))."
end

include("passive-dimensional-dataset.jl")

include("dimensional-featured-dataset.jl")
include("featured-dataset.jl")

abstract type SupportingDataset{W<:AbstractWorld,FR<:AbstractFrame{W,Bool}} end

isminifiable(X::SupportingDataset) = false

worldtype(X::SupportingDataset{W}) where {W} = W

function display_structure(X::SupportingDataset; indent_str = "")
    out = "$(typeof(X))\t$((Base.summarysize(X)) / 1024 / 1024 |> x->round(x, digits=2)) MBs"
    out *= " ($(round(nmemoizedvalues(X))) values)\n"
    out
end

abstract type FeaturedSupportingDataset{V<:Number,W<:AbstractWorld,FR<:AbstractFrame{W,Bool}} <: SupportingDataset{W,FR} end


include("supported-featured-dataset.jl")

include("one-step-featured-supporting-dataset/main.jl")
include("generic-supporting-datasets.jl")

include("check.jl")
