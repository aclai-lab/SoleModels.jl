
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
using SoleModels: BoundedScalarConditions
using SoleModels: CanonicalFeatureGeq, CanonicalFeatureGeqSoft, CanonicalFeatureLeq, CanonicalFeatureLeqSoft
using SoleModels: AbstractLogiset, AbstractMultiModalFrame
using SoleModels: MultiLogiset, AbstractLogiset
using SoleModels: apply_test_operator, existential_aggregator, aggregator_bottom, aggregator_to_binary
import SoleModels: representatives, ScalarMetaCondition, ScalarCondition, featvaltype
import SoleModels: ninstances, nrelations, nfeatures, check, instances, minify
import SoleModels: nmodalities, frames, displaystructure, frame
import SoleModels: grouped_featsaggrsnops, features, grouped_metaconditions, alphabet, findfeature, findrelation, isminifiable

using SoleModels: grouped_featsnops2grouped_featsaggrsnops,
                    grouped_featsaggrsnops2grouped_featsnops,
                    features_grouped_featsaggrsnops2featsnaggrs_grouped_featsnaggrs,
                    features_grouped_featsaggrsnops2featsnaggrs,
                    features_grouped_featsaggrsnops2grouped_featsnaggrs
############################################################################################

function check_initialworld(FD::Type{<:AbstractLogiset}, initialworld, W)
    @assert isnothing(initialworld) || initialworld isa W "Cannot instantiate " *
        "$(FD) with worldtype = $(W) but initialworld of type $(typeof(initialworld))."
end

include("passive-dimensional-datasets.jl")

include("dimensional-logiset.jl")

# Frame-specific featured world datasets and supports
include("dimensional-fwds.jl")

_default_fwd_type(::Type{<:FullDimensionalFrame}) = UniformFullDimensionalFWD

include("dimensional-supports.jl")

include("check.jl")
