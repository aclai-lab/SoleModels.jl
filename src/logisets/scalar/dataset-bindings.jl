using SoleData: AbstractMultiModalDataset
import SoleData: ninstances, nvariables, nmodalities, eachmodality

function initlogiset(dataset, features)
    error("Please, provide method initlogiset(dataset::$(typeof(dataset)), features::$(typeof(features))).")
end
function ninstances(dataset)
    error("Please, provide method ninstances(dataset::$(typeof(dataset))).")
end
function nvariables(dataset)
    error("Please, provide method nvariables(dataset::$(typeof(dataset))).")
end
function allworlds(dataset, i_instance)
    error("Please, provide method allworlds(dataset::$(typeof(dataset)), i_instance::Integer).")
end
function featvalue(dataset, i_instance, w, feature)
    error("Please, provide method featvalue(dataset::$(typeof(dataset)), i_instance::Integer, w::$(typeof(w)), feature::$(typeof(feature))).")
end
function vareltype(dataset, i_variable)
    error("Please, provide method vareltype(dataset::$(typeof(dataset)), i_variable::Integer).")
end

# Multimodal dataset interface
function ismultimodal(dataset)
    false
end
function nmodalities(dataset)
    error("Please, provide method nmodalities(dataset::$(typeof(dataset))).")
end
function eachmodality(dataset)
    error("Please, provide method eachmodality(dataset::$(typeof(dataset))).")
end

function ismultimodal(dataset::AbstractMultiModalDataset)
    true
end

function ismultimodal(dataset::Union{AbstractVector,Tuple})
    true
end
function nmodalities(dataset::Union{AbstractVector,Tuple})
    length(dataset)
end
function eachmodality(dataset::Union{AbstractVector,Tuple})
    dataset
end


"""
    scalarlogiset(dataset, features::AbstractVector{<:VarFeature})

Converts a dataset structure (with variables) to a logiset with scalar-valued features.
If `dataset` is not a multimodal dataset, the following methods should be defined:

```julia
    initlogiset(dataset, features::AbstractVector{<:VarFeature})
    ninstances(dataset)
    nvariables(dataset)
    allworlds(dataset, i_instance::Integer)
    featvalue(dataset, i_instance::Integer, w::AbstractWorld, feature::VarFeature)
    vareltype(dataset, i_variable::Integer)
```

If `dataset` represents a multimodal dataset, the following methods should be defined,
while its modalities (iterated via `eachmodality`) should provide the methods above:

```julia
    ismultimodal(dataset)
    nmodalities(dataset)
    eachmodality(dataset)
```

See also
[`AbstractLogiset`](@ref),
[`VarFeature`](@ref),
[`ScalarCondition`](@ref).
"""
function scalarlogiset(
    dataset,
    features::Union{Nothing,AbstractVector{<:VarFeature},AbstractVector{<:Union{Nothing,<:AbstractVector}}} = nothing;
    #
    use_full_memoization             :: Union{Bool,Type{<:Union{AbstractOneStepMemoset,AbstractFullMemoset}}} = true,
    #
    conditions                       :: Union{Nothing,AbstractVector{<:AbstractCondition},AbstractVector{<:Union{Nothing,AbstractVector}}} = nothing,
    relations                        :: Union{Nothing,AbstractVector{<:AbstractRelation},AbstractVector{<:Union{Nothing,AbstractVector}}} = nothing,
    use_onestep_memoization          :: Union{Bool,Type{<:AbstractOneStepMemoset}} = !isnothing(conditions) && !isnothing(relations),
    onestep_precompute_globmemoset   :: Bool = (use_onestep_memoization != false),
    onestep_precompute_relmemoset    :: Bool = false,
)
    some_features_were_specified = !isnothing(features)

    if ismultimodal(dataset)

        kwargs = (;
            use_full_memoization = use_full_memoization,
            use_onestep_memoization = use_onestep_memoization,
            onestep_precompute_globmemoset = onestep_precompute_globmemoset,
            onestep_precompute_relmemoset = onestep_precompute_relmemoset,
        )

        features = begin
            if features isa Union{Nothing,AbstractVector{<:VarFeature}}
                fill(features, nmodalities(dataset))
            elseif features isa AbstractVector{<:Union{Nothing,AbstractVector}}
                features
            else
                error("Cannot build multimodal scalar logiset with features " *
                    "$(displaysyntaxvector(features)).")
            end
        end

        conditions = begin
            if conditions isa Union{Nothing,AbstractVector{<:AbstractCondition}}
                fill(conditions, nmodalities(dataset))
            elseif conditions isa AbstractVector{<:Union{Nothing,AbstractVector}}
                conditions
            else
                error("Cannot build multimodal scalar logiset with conditions " *
                    "$(displaysyntaxvector(conditions)).")
            end
        end

        relations = begin
            if relations isa Union{Nothing,AbstractVector{<:AbstractRelation}}
                fill(relations, nmodalities(dataset))
            elseif relations isa AbstractVector{<:Union{Nothing,AbstractVector}}
                relations
            else
                error("Cannot build multimodal scalar logiset with relations " *
                    "$(displaysyntaxvector(relations)).")
            end
        end

        return MultiLogiset([
            scalarlogiset(_dataset, _features; conditions = _conditions, relations = _relations, kwargs...)
                for (_dataset, _features, _conditions, _relations) in
                    zip(eachmodality(dataset), features, conditions, relations)
            ])
    end

    if isnothing(features)
        features = collect(Iterators.flatten([[UnivariateMax(i_var), UnivariateMin(i_var)] for i_var in 1:nvariables(dataset)]))
    end

    features_ok = filter(f->isconcretetype(featvaltype(f)), features)
    features_notok = filter(f->!isconcretetype(featvaltype(f)), features)

    if length(features_notok) > 0
        if all(preserveseltype, features_notok) && all(f->f isa AbstractUnivariateFeature, features_notok)
            features_notok_fixed = [begin
                U = vareltype(dataset, i_variable(f))
                eval(nameof(typeof(f))){U}(f)
            end for f in features_notok]
            if some_features_were_specified
                @warn "Patching $(length(features_notok)) features using vareltype."
            end
            features = [features_ok..., features_notok_fixed...]
        else
            @warn "Could not infer feature value type for some of the specified features. " *
                    "Please specify the feature value type upon construction. Untyped " *
                    "features: $(displaysyntaxvector(features_notok_fixed))"
        end
    end
    features = UniqueVector(features)
    
    # Initialize the logiset structure
    X = initlogiset(dataset, features)

    # Load external features (if any)
    if any(isa.(features, ExternalFWDFeature))
        i_external_features = first.(filter(((i_feature,is_external_fwd),)->(is_external_fwd), collect(enumerate(isa.(features, ExternalFWDFeature)))))
        for i_feature in i_external_features
            feature = features[i_feature]
            featvalues!(X, feature.X, i_feature)
        end
    end

    # Load internal features
    i_features = first.(filter(((i_feature,is_external_fwd),)->!(is_external_fwd), collect(enumerate(isa.(features, ExternalFWDFeature)))))
    enum_features = zip(i_features, features[i_features])

    _ninstances = ninstances(dataset)

    # Compute features
    # p = Progress(_ninstances, 1, "Computing EMD...")
    @inbounds Threads.@threads for i_instance in 1:_ninstances
        for w in allworlds(dataset, i_instance)
            for (i_feature,feature) in enum_features
                featval = featvalue(dataset, i_instance, w, feature)
                featvalue!(X, featval, i_instance, w, feature, i_feature)
            end
        end
        # next!(p)
    end

    if !use_full_memoization && !use_onestep_memoization
        X
    else
        SupportedLogiset(X;
            use_full_memoization = use_full_memoization,
            use_onestep_memoization = use_onestep_memoization,
            conditions = conditions,
            relations = relations,
            onestep_precompute_globmemoset = onestep_precompute_globmemoset,
            onestep_precompute_relmemoset = onestep_precompute_relmemoset,
        )
    end
end
