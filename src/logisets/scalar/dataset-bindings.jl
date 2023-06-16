using DataFrames

function initlogiset(dataset, features)
    error("Please, provide method initlogiset(dataset::$(typeof(dataset)), features::$(typeof(features))).")
end
function ninstances(dataset)
    error("Please, provide method ninstances(dataset::$(typeof(dataset)).")
end
function worldtype(dataset)
    error("Please, provide method worldtype(dataset::$(typeof(dataset)).")
end
function allworlds(dataset, i_instance)
    error("Please, provide method allworlds(dataset::$(typeof(dataset)), i_instance::Integer).")
end
function featvalue(dataset, i_instance, w, feature)
    error("Please, provide method featvalue(dataset::$(typeof(dataset)), i_instance::Integer, w::$(typeof(w)), feature::$(typeof(feature))).")
end

"""
    scalarlogiset(dataset, features::AbstractVector{<:VarFeature})

Converts a dataset structure to a logiset with scalar-valued features.
"""
function scalarlogiset(
    dataset,
    features::AbstractVector{<:VarFeature},
)
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
    X
end
