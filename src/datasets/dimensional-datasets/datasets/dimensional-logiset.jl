
############################################################################################
# Interpreted modal dataset
############################################################################################
# 
# A modal dataset can be instantiated in *implicit* form, from a dimensional domain, and a few
#  objects inducing an interpretation on the domain; mainly, an ontology (determining worlds and
#  relations), and structures for interpreting features onto the domain.
# 
############################################################################################

struct DimensionalLogiset{
    V<:Number,
    N,
    W<:AbstractWorld,
    D<:PassiveDimensionalDataset{N,W},
    FT<:AbstractFeature{V},
    G1<:AbstractVector{<:AbstractDict{<:Aggregator,<:AbstractVector{<:TestOperator}}},
    G2<:AbstractVector{<:AbstractVector{Tuple{<:Integer,<:Aggregator}}},
} <: AbstractActiveScalarLogiset{W,V,FT,Bool,FullDimensionalFrame{N,W,Bool}}

    # Core data (a dimensional domain)
    domain                  :: D
    
    # Worlds & Relations
    ontology                :: Ontology{W} # Union{Nothing,}
    
    # Test operators associated with each feature, grouped by their respective aggregator
    # Note: currently, cannot specify the full type (probably due to @computed)
    grouped_featsaggrsnops  :: G1

    # Features and Aggregators
    grouped_featsnaggrs     :: G2

    # Initial world(s)
    initialworld :: Union{Nothing,W,AbstractWorldSet{<:W}}

    ########################################################################################
    
    function DimensionalLogiset{V,N,W}(
        domain::PassiveDimensionalDataset{N},
        ontology::Ontology{W},
        features::AbstractVector{<:AbstractFeature},
        grouped_featsaggrsnops::AbstractVector{<:AbstractDict{<:Aggregator,<:AbstractVector{<:TestOperator}}};
        allow_no_instances = false,
        initialworld = nothing,
    ) where {V,N,W<:AbstractWorld}
        ty = "DimensionalLogiset{$(V),$(N),$(W)}"
        features = collect(features)
        FT = Union{typeof.(features)...}
        features = Vector{FT}(features)
        @assert allow_no_instances || nsamples(domain) > 0 "" *
            "Can't instantiate $(ty) with no instance. (domain's type $(typeof(domain)))"
        @assert length(features) == length(grouped_featsaggrsnops) "" *
            "Can't instantiate $(ty) with mismatching length(features) and" *
            " length(grouped_featsaggrsnops):" *
            " $(length(features)) != $(length(grouped_featsaggrsnops))"
        @assert length(grouped_featsaggrsnops) > 0 &&
            sum(length.(grouped_featsaggrsnops)) > 0 &&
            sum(vcat([[length(test_ops) for test_ops in aggrs] for aggrs in grouped_featsaggrsnops]...)) > 0 "" *
            "Can't instantiate $(ty) with no test operator: $(grouped_featsaggrsnops)"
        grouped_featsnaggrs = features_grouped_featsaggrsnops2grouped_featsnaggrs(features, grouped_featsaggrsnops)
        check_initialworld(DimensionalLogiset, initialworld, W)
        new{
            V,
            N,
            W,
            typeof(domain),
            FT,
            typeof(grouped_featsaggrsnops),
            typeof(grouped_featsnaggrs),
        }(
            domain,
            ontology,
            features,
            grouped_featsaggrsnops,
            grouped_featsnaggrs,
            initialworld,
        )
    end

    ########################################################################################

    function DimensionalLogiset{V,N,W}(
        domain             :: Union{PassiveDimensionalDataset{N,W},AbstractDimensionalDataset},
        ontology           :: Ontology{W},
        features           :: AbstractVector{<:AbstractFeature},
        grouped_featsnops  :: AbstractVector;
        kwargs...,
    ) where {V,N,W<:AbstractWorld}
        domain = (domain isa AbstractDimensionalDataset ? PassiveDimensionalDataset{N,W}(domain) : domain)
        grouped_featsaggrsnops = grouped_featsnops2grouped_featsaggrsnops(grouped_featsnops)
        DimensionalLogiset{V,N,W}(domain, ontology, features, grouped_featsaggrsnops; kwargs...)
    end

    function DimensionalLogiset{V,N,W}(
        domain           :: Union{PassiveDimensionalDataset{N,W},AbstractDimensionalDataset},
        ontology         :: Ontology{W},
        mixed_features   :: AbstractVector;
        kwargs...,
    ) where {V,N,W<:AbstractWorld}
        domain = (domain isa AbstractDimensionalDataset ? PassiveDimensionalDataset{N,W}(domain) : domain)

        @assert all(isa.(mixed_features, MixedFeature)) "Unknown feature encountered!" *
            " $(filter(f->!isa(f, MixedFeature), mixed_features)), " *
            " $(typeof.(filter(f->!isa(f, MixedFeature), mixed_features)))"

        mixed_features = Vector{MixedFeature}(mixed_features)

        _features, featsnops = begin
            _features = AbstractFeature[]
            featsnops = Vector{<:TestOperator}[]

            # readymade features
            cnv_feat(cf::AbstractFeature) = ([≥, ≤], cf)
            cnv_feat(cf::Tuple{TestOperator,AbstractFeature}) = ([cf[1]], cf[2])
            # single-attribute features
            cnv_feat(cf::Any) = cf
            cnv_feat(cf::CanonicalFeature) = cf
            cnv_feat(cf::Function) = ([≥, ≤], cf)
            cnv_feat(cf::Tuple{TestOperator,Function}) = ([cf[1]], cf[2])

            mixed_features = cnv_feat.(mixed_features)

            readymade_cfs          = filter(x->
                # isa(x, Tuple{<:AbstractVector{<:TestOperator},AbstractFeature}),
                isa(x, Tuple{AbstractVector,AbstractFeature}),
                mixed_features,
            )
            attribute_specific_cfs = filter(x->
                isa(x, CanonicalFeature) ||
                # isa(x, Tuple{<:AbstractVector{<:TestOperator},Function}) ||
                (isa(x, Tuple{AbstractVector,Function}) && !isa(x, Tuple{AbstractVector,AbstractFeature})),
                mixed_features,
            )

            @assert length(readymade_cfs) + length(attribute_specific_cfs) == length(mixed_features) "" *
                "Unexpected" *
                " mixed_features. $(mixed_features)." *
                " $(filter(x->(! (x in readymade_cfs) && ! (x in attribute_specific_cfs)), mixed_features))." *
                " $(length(readymade_cfs)) + $(length(attribute_specific_cfs)) == $(length(mixed_features))."

            for (test_ops,cf) in readymade_cfs
                push!(_features, cf)
                push!(featsnops, test_ops)
            end

            single_attr_feats_n_featsnops(i_attr,cf::SoleModels.CanonicalFeatureGeq) = ([≥],DimensionalDatasets.UnivariateMin{V}(i_attr))
            single_attr_feats_n_featsnops(i_attr,cf::SoleModels.CanonicalFeatureLeq) = ([≤],DimensionalDatasets.UnivariateMax{V}(i_attr))
            single_attr_feats_n_featsnops(i_attr,cf::SoleModels.CanonicalFeatureGeqSoft) = ([≥],DimensionalDatasets.UnivariateSoftMin{V}(i_attr, cf.alpha))
            single_attr_feats_n_featsnops(i_attr,cf::SoleModels.CanonicalFeatureLeqSoft) = ([≤],DimensionalDatasets.UnivariateSoftMax{V}(i_attr, cf.alpha))
            single_attr_feats_n_featsnops(i_attr,(test_ops,cf)::Tuple{<:AbstractVector{<:TestOperator},typeof(minimum)}) = (test_ops,DimensionalDatasets.UnivariateMin{V}(i_attr))
            single_attr_feats_n_featsnops(i_attr,(test_ops,cf)::Tuple{<:AbstractVector{<:TestOperator},typeof(maximum)}) = (test_ops,DimensionalDatasets.UnivariateMax{V}(i_attr))
            single_attr_feats_n_featsnops(i_attr,(test_ops,cf)::Tuple{<:AbstractVector{<:TestOperator},Function})        = (test_ops,DimensionalDatasets.UnivariateFeature{V}(i_attr, (x)->(V(cf(x)))))
            single_attr_feats_n_featsnops(i_attr,::Any) = throw_n_log("Unknown mixed_feature type: $(cf), $(typeof(cf))")

            for i_attr in 1:nattributes(domain)
                for (test_ops,cf) in map((cf)->single_attr_feats_n_featsnops(i_attr,cf),attribute_specific_cfs)
                    push!(featsnops, test_ops)
                    push!(_features, cf)
                end
            end
            _features, featsnops
        end
        DimensionalLogiset{V,N,worldtype(ontology)}(domain, ontology, _features, featsnops; kwargs...)
    end

    ########################################################################################

    function DimensionalLogiset{V,N}(
        domain             :: Union{PassiveDimensionalDataset{N,W},AbstractDimensionalDataset},
        ontology           :: Ontology{W},
        args...;
        kwargs...,
    ) where {V,N,W<:AbstractWorld}
        domain = (domain isa AbstractDimensionalDataset ? PassiveDimensionalDataset{N,W}(domain) : domain)
        DimensionalLogiset{V,N,W}(domain, ontology, args...; kwargs...)
    end

    ########################################################################################

    function DimensionalLogiset{V}(
        domain             :: Union{PassiveDimensionalDataset,AbstractDimensionalDataset},
        args...;
        kwargs...,
    ) where {V}
        DimensionalLogiset{V,dimensionality(domain)}(domain, args...; kwargs...)
    end

    ########################################################################################

    function DimensionalLogiset(
        domain             :: Union{PassiveDimensionalDataset{N,W},AbstractDimensionalDataset},
        ontology           :: Ontology{W},
        features           :: AbstractVector{<:AbstractFeature},
        args...;
        kwargs...,
    ) where {N,W<:AbstractWorld}
        V = Union{featvaltype.(features)...}
        DimensionalLogiset{V}(domain, ontology, features, args...; kwargs...)
    end

    preserves_type(::Any) = false
    preserves_type(::CanonicalFeature) = true
    preserves_type(::typeof(minimum)) = true # TODO fix
    preserves_type(::typeof(maximum)) = true # TODO fix

    function DimensionalLogiset(
        domain           :: Union{PassiveDimensionalDataset{N,W},AbstractDimensionalDataset},
        ontology         :: Ontology{W},
        mixed_features   :: AbstractVector;
        kwargs...,
    ) where {N,W<:AbstractWorld}
        domain = (domain isa AbstractDimensionalDataset ? PassiveDimensionalDataset{dimensionality(domain),W}(domain) : domain)
        @assert all((f)->(preserves_type(f)), mixed_features) "Please, specify the feature output type V upon construction, as in: DimensionalLogiset{V}(...)." # TODO highlight and improve
        V = eltype(domain)
        DimensionalLogiset{V}(domain, ontology, mixed_features; kwargs...)
    end

end

domain(X::DimensionalLogiset)                 = X.domain
ontology(X::DimensionalLogiset)               = X.ontology
features(X::DimensionalLogiset)               = X.features
grouped_featsaggrsnops(X::DimensionalLogiset) = X.grouped_featsaggrsnops
grouped_featsnaggrs(X::DimensionalLogiset)    = X.grouped_featsnaggrs

function Base.getindex(X::DimensionalLogiset, args...)
    domain(X)[args...]::featvaltype(X)
end

Base.size(X::DimensionalLogiset)              = Base.size(domain(X))

dimensionality(X::DimensionalLogiset{V,N,W}) where {V,N,W} = N
worldtype(X::DimensionalLogiset{V,N,W}) where {V,N,W} = W

nsamples(X::DimensionalLogiset)               = nsamples(domain(X))
nattributes(X::DimensionalLogiset)            = nattributes(domain(X))

relations(X::DimensionalLogiset)              = relations(ontology(X))
nrelations(X::DimensionalLogiset)             = length(relations(X))
nfeatures(X::DimensionalLogiset)              = length(features(X))

channel_size(X::DimensionalLogiset, args...)     = channel_size(domain(X), args...)
max_channel_size(X::DimensionalLogiset)          = max_channel_size(domain(X))

get_instance(X::DimensionalLogiset, args...)     = get_instance(domain(X), args...)

_slice_dataset(X::DimensionalLogiset, inds::AbstractVector{<:Integer}, args...; kwargs...)    =
    DimensionalLogiset(_slice_dataset(domain(X), inds, args...; kwargs...), ontology(X), features(X), grouped_featsaggrsnops(X); initialworld = initialworld(X))

frame(X::DimensionalLogiset, i_sample) = frame(domain(X), i_sample)
initialworld(X::DimensionalLogiset) = X.initialworld
function initialworld(X::DimensionalLogiset, i_sample)
    initialworld(X) isa AbstractWorldSet ? initialworld(X)[i_sample] : initialworld(X)
end

function displaystructure(X::DimensionalLogiset; indent_str = "")
    out = "$(typeof(X))\t$(Base.summarysize(X) / 1024 / 1024 |> x->round(x, digits=2)) MBs\n"
    out *= indent_str * "├ relations:\t($((nrelations(X))))\t[$(join(syntaxstring.(relations(X)), ", "))]\n"
    out *= indent_str * "├ features:\t($((nfeatures(X))))\t[$(join(syntaxstring.(features(X)), ", "))]\n"
    out *= indent_str * "├ domain shape:\t\t$(Base.size(domain(X)))\n"
    out *= indent_str * "├ nsamples:\t\t$(nsamples(X))\n"
    out *= indent_str * "├ nattributes:\t\t$(nattributes(X))\n"
    out *= indent_str * "├ max_channel_size:\t$(max_channel_size(X))\n"
    out *= indent_str * "└ initialworld(s):\t$(initialworld(X))"
    out
end

hasnans(X::DimensionalLogiset) = hasnans(domain(X))

