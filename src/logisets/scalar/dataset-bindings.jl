using ProgressMeter
using SoleData: AbstractMultiModalDataset
import SoleData: ninstances, nvariables, nmodalities, eachmodality

function islogiseed(dataset)
    return error("Please, provide method islogiseed(dataset::$(typeof(dataset))).")
end
function initlogiset(dataset, features)
    return error("Please, provide method initlogiset(dataset::$(typeof(dataset)), features::$(typeof(features))).")
end
function ninstances(dataset)
    return error("Please, provide method ninstances(dataset::$(typeof(dataset))).")
end
function nvariables(dataset)
    return error("Please, provide method nvariables(dataset::$(typeof(dataset))).")
end
function frame(dataset, i_instance)
    return error("Please, provide method frame(dataset::$(typeof(dataset)), i_instance::Integer).")
end
function featvalue(dataset, i_instance, w, feature)
    return error("Please, provide method featvalue(dataset::$(typeof(dataset)), i_instance::Integer, w::$(typeof(w)), feature::$(typeof(feature))).")
end
function vareltype(dataset, i_variable)
    return error("Please, provide method vareltype(dataset::$(typeof(dataset)), i_variable::Integer).")
end

function allworlds(dataset, i_instance)
    allworlds(frame(dataset, i_instance))
end

# Multimodal dataset interface
function ismultilogiseed(dataset)
    false
end
function nmodalities(dataset)
    return error("Please, provide method nmodalities(dataset::$(typeof(dataset))).")
end
function eachmodality(dataset)
    return error("Please, provide method eachmodality(dataset::$(typeof(dataset))).")
end

function ismultilogiseed(dataset::MultiLogiset)
    true
end
function ismultilogiseed(dataset::AbstractMultiModalDataset)
    true
end

function ismultilogiseed(dataset::Union{AbstractVector,Tuple})
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
    frame(dataset, i_instance::Integer)
    featvalue(dataset, i_instance::Integer, w::AbstractWorld, feature::VarFeature)
    vareltype(dataset, i_variable::Integer)
```

If `dataset` represents a multimodal dataset, the following methods should be defined,
while its modalities (iterated via `eachmodality`) should provide the methods above:

```julia
    ismultilogiseed(dataset)
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
    print_progress                   :: Bool = false,
)
    some_features_were_specified = !isnothing(features)

    if ismultilogiseed(dataset)

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
        features = begin
            if isnothing(conditions)
                is_propositional_dataset = all(i_instance->nworlds(frame(dataset, i_instance)) == 1, 1:ninstances(dataset))
                if is_propositional_dataset
                    [UnivariateValue{vareltype(dataset, i_var)}(i_var) for i_var in 1:nvariables(dataset)]
                else
                    vcat([[UnivariateMax{vareltype(dataset, i_var)}(i_var), UnivariateMin{vareltype(dataset, i_var)}(i_var)] for i_var in 1:nvariables(dataset)]...)
                end
            else
                unique(feature.(conditions))
            end
        end
    end

    features_ok = filter(f->isconcretetype(SoleModels.featvaltype(f)), features)
    features_notok = filter(f->!isconcretetype(SoleModels.featvaltype(f)), features)

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
                    "features: $(displaysyntaxvector(features_notok))"
        end
    end
    features = UniqueVector(features)
    
    # Initialize the logiset structure
    X = initlogiset(dataset, features)

    # Load explicit features (if any)
    if any(isa.(features, ExplicitFeature))
        i_external_features = first.(filter(((i_feature,isexplicit),)->(isexplicit), collect(enumerate(isa.(features, ExplicitFeature)))))
        for i_feature in i_external_features
            feature = features[i_feature]
            featvalues!(X, feature.X, i_feature)
        end
    end

    # Load internal features
    i_features = first.(filter(((i_feature,isexplicit),)->!(isexplicit), collect(enumerate(isa.(features, ExplicitFeature)))))
    enum_features = zip(i_features, features[i_features])

    _ninstances = ninstances(dataset)

    # Compute features
    if print_progress
        p = Progress(_ninstances, 1, "Computing logiset...")
    end
    @inbounds Threads.@threads for i_instance in 1:_ninstances
        for w in allworlds(dataset, i_instance)
            for (i_feature,feature) in enum_features
                featval = featvalue(dataset, i_instance, w, feature)
                featvalue!(X, featval, i_instance, w, feature, i_feature)
            end
        end
        if print_progress
            next!(p)
        end
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


const MixedCondition = Union{
    <:Union{SoleModels.VarFeature,Base.Callable},                       # feature (i.e., callables to be associated to all variables, or SoleModels.VarFeature objects);
    <:Tuple{Base.Callable,Integer},                                     # (callable,var_id);
    <:Tuple{TestOperator,<:Union{SoleModels.VarFeature,Base.Callable}}, # (test_operator,features);
    <:ScalarMetaCondition,                                              # ScalarMetaCondition;
}

function naturalconditions(
    dataset,
    mixed_conditions   :: AbstractVector,
    featvaltype        :: Type = DEFAULT_VARFEATVALTYPE
)
    nvars = nvariables(dataset)

    @assert all(isa.(mixed_conditions, MixedCondition)) "" *
        "Unknown condition seed encountered! " *
        "$(filter(f->!isa(f, MixedCondition), mixed_conditions)), " *
        "$(typeof.(filter(f->!isa(f, MixedCondition), mixed_conditions)))"

    mixed_conditions = Vector{MixedCondition}(mixed_conditions)

    is_propositional_dataset = all(i_instance->nworlds(frame(dataset, i_instance)) == 1, 1:ninstances(dataset))

    def_test_operators = is_propositional_dataset ? [≥] : [≥, <]

    # univar_condition(i_var,cond::SoleModels.CanonicalFeatureGeq) = ([≥],DimensionalDatasets.UnivariateMin{featvaltype}(i_var))
    # univar_condition(i_var,cond::SoleModels.CanonicalFeatureLeq) = ([<],DimensionalDatasets.UnivariateMax{featvaltype}(i_var))
    # univar_condition(i_var,cond::SoleModels.CanonicalFeatureGeqSoft) = ([≥],DimensionalDatasets.UnivariateSoftMin{featvaltype}(i_var, cond.alpha))
    # univar_condition(i_var,cond::SoleModels.CanonicalFeatureLeqSoft) = ([<],DimensionalDatasets.UnivariateSoftMax{featvaltype}(i_var, cond.alpha))
    function univar_condition(i_var,(test_ops,cond)::Tuple{<:AbstractVector{<:TestOperator},typeof(identity)})
        V = vareltype(dataset, i_var)
        if !isconcretetype(V)
            @warn "Building UnivariateValue with non-concrete feature type: $(V)."
        end
        return (test_ops,DimensionalDatasets.UnivariateValue{V}(i_var))
    end
    function univar_condition(i_var,(test_ops,cond)::Tuple{<:AbstractVector{<:TestOperator},typeof(minimum)})
        V = vareltype(dataset, i_var)
        if !isconcretetype(V)
            @warn "Building UnivariateMin with non-concrete feature type: $(V)."
        end
        return (test_ops,DimensionalDatasets.UnivariateMin{V}(i_var))
    end
    function univar_condition(i_var,(test_ops,cond)::Tuple{<:AbstractVector{<:TestOperator},typeof(maximum)})
        V = vareltype(dataset, i_var)
        if !isconcretetype(V)
            @warn "Building UnivariateMax with non-concrete feature type: $(V)."
        end
        return (test_ops,DimensionalDatasets.UnivariateMax{V}(i_var))
    end
    function univar_condition(i_var,(test_ops,cond)::Tuple{<:AbstractVector{<:TestOperator},Base.Callable})
        V = featvaltype
        if !isconcretetype(V)
            @warn "Building UnivariateFeature with non-concrete feature type: $(V)."
                "Please provide `featvaltype` parameter to naturalconditions."
        end
        # f = function (x) return V(cond(x)) end # breaks because it does not create a closure.
        f = cond
        return (test_ops,DimensionalDatasets.UnivariateFeature{V}(i_var, f))
    end
    univar_condition(i_var,::Any) = throw_n_log("Unknown mixed_feature type: $(cond), $(typeof(cond))")


    # readymade conditions
    unpackcondition(cond::ScalarMetaCondition) = [cond]
    unpackcondition(feature::AbstractFeature) = [ScalarMetaCondition(feature, test_op) for test_op in def_test_operators]
    unpackcondition(cond::Tuple{TestOperator,AbstractFeature}) = [ScalarMetaCondition(cond[2], cond[1])]

    # single-variable conditions
    unpackcondition(cond::Any) = cond
    # unpackcondition(cond::CanonicalFeature) = cond
    unpackcondition(cond::Base.Callable) = (def_test_operators, cond)
    function unpackcondition(cond::Tuple{Base.Callable,Integer})
        return univar_condition(cond[2], (def_test_operators, cond[1]))
    end
    unpackcondition(cond::Tuple{TestOperator,Base.Callable}) = ([cond[1]], cond[2])

    metaconditions = ScalarMetaCondition[]

    mixed_conditions = unpackcondition.(mixed_conditions)

    readymade_conditions          = filter(x->
        isa(x, Vector{ScalarMetaCondition}),
        mixed_conditions,
    )
    variable_specific_conditions = filter(x->
        # isa(x, CanonicalFeature) ||
        # isa(x, Tuple{<:AbstractVector{<:TestOperator},Base.Callable}) ||
        (isa(x, Tuple{AbstractVector,Base.Callable}) && !isa(x, Tuple{AbstractVector,AbstractFeature})),
        mixed_conditions,
    )

    @assert length(readymade_conditions) + length(variable_specific_conditions) == length(mixed_conditions) "" *
        "Unexpected " *
        "mixed_conditions. $(mixed_conditions). " *
        "$(filter(x->(! (x in readymade_conditions) && ! (x in variable_specific_conditions)), mixed_conditions)). " *
        "$(length(readymade_conditions)) + $(length(variable_specific_conditions)) == $(length(mixed_conditions))."

    for cond in readymade_conditions
        push!(metaconditions, cond)
    end

    for i_var in 1:nvars
        for (test_ops,feature) in map((cond)->univar_condition(i_var,cond),variable_specific_conditions)
            for test_op in test_ops
                cond = ScalarMetaCondition(feature, test_op)
                push!(metaconditions, cond)
            end
        end
    end

    metaconditions
end

"""
    naturalgrouping(
        X::AbstractDataFrame;
        allow_variable_drop = false,
    )::AbstractVector{<:AbstractVector{<:Symbol}}

Return variables grouped by their logical nature;
the nature of a variable is automatically derived
from its type (e.g., Real, Vector{<:Real} or Matrix{<:Real}) and frame.
All instances must have the same frame (e.g., channel size/number of worlds).

TODO example
"""
function naturalgrouping(
    X::AbstractDataFrame;
    allow_variable_drop = false,
    # allow_nonuniform_variable_types = false,
    # allow_nonuniform_variables = false,
) #::AbstractVector{<:AbstractVector{<:Symbol}}

    coltypes = eltype.(eachcol(X))

    function _frame(datacolumn, i_instance)
        if hasmethod(frame, (typeof(datacolumn), Integer))
            frame(datacolumn, i_instance)
        else
            missing
        end
    end

    # Check that columns with same dimensionality have same eltype's.
    for T in [Real, Vector, Matrix]
        these_coltypes = filter((t)->(t<:T), coltypes)
        @assert all([eltype(t) <: Real for t in these_coltypes]) "$(these_coltypes). Cannot " *
          "apply this algorithm on variables types with non-Real " *
          "eltype's: $(filter((t)->(!(eltype(t) <: Real)), these_coltypes))."
        @assert length(unique(these_coltypes)) <= 1 "$(these_coltypes). Cannot " *
          "apply this algorithm on dataset with non-uniform types for variables " *
          "with eltype = $(T). Please, convert all values to $(promote_type(these_coltypes...))."
    end

    columnnames = names(X)
    percol_framess = [unique(map((i_instance)->(_frame(X[:,col], i_instance)), 1:ninstances(X))) for col in columnnames]

    # Must have common frame across instances
    _uniform_columns = (length.(percol_framess) .== 1)
    _framed_columns = (((cs)->all((!).(ismissing.(cs)))).(percol_framess))

    __nonuniform_cols = columnnames[(!).(_uniform_columns)]
    if length(__nonuniform_cols) > 0
        if allow_variable_drop
            @warn "Dropping columns due to non-uniform frame across instances: $(join(__nonuniform_cols, ", "))..."
        else
            error("Non-uniform frame across instances for columns $(join(__nonuniform_cols, ", "))")
        end
    end
    __uniform_nonframed_cols = columnnames[_uniform_columns .&& (!).(_framed_columns)]
    if length(__uniform_nonframed_cols) > 0
        if allow_variable_drop
            @warn "Dropping columns due to unspecified frame: $(join(__uniform_nonframed_cols, ", "))..."
        else
            error("Could not derive frame for columns $(join(__uniform_nonframed_cols, ", "))")
        end
    end

    _good_columns = _uniform_columns .&& _framed_columns

    if length(_good_columns) == 0
        error("Could not find any suitable variables in DataFrame.")
    end

    percol_framess = percol_framess[_good_columns]
    columnnames = Symbol.(columnnames[_good_columns])
    percol_frames = getindex.(percol_framess, 1)

    var_grouping = begin
        unique_frames = sort(unique(percol_frames); lt = (x,y)->begin
            if hasmethod(dimensionality, (typeof(x),)) && hasmethod(dimensionality, (typeof(y),))
                if dimensionality(x) == dimensionality(y)
                    isless(SoleData.channelsize(x), SoleData.channelsize(y))
                else
                    isless(dimensionality(x), dimensionality(y))
                end
            elseif hasmethod(dimensionality, (typeof(x),))
                true
            else
                false
            end
        end)

        percol_modality = [findfirst((ucs)->(ucs==cs), unique_frames) for cs in percol_frames]

        var_grouping = Dict([modality => [] for modality in unique(percol_modality)])
        for (modality, col) in zip(percol_modality, columnnames)
            push!(var_grouping[modality], col)
        end
        [var_grouping[modality] for modality in unique(percol_modality)]
    end

    var_grouping
end