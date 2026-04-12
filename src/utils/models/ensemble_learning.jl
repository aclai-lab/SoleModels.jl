using SoleModels: DecisionList, DecisionEnsemble, AbstractModel
using SoleData: AbstractLogiset
using Tables
using DataFrames
using Random

"""
    build_ensemble(X, y, num_models, w = default_weights(length(y));
        use_bootstrapping = true,
        samples_ratio_per_model = 1.0,
        n_subfeatures_per_model = nothing,
        aggregation_function = nothing,
        rng = Random.default_rng(),
        model_wrapper = irepstar,
        kwargs...) -> DecisionEnsemble

Build an ensemble of models by training `num_models` base learners on random
subsets of the training data and, optionally, random subsets of features.

This function constructs an ensemble by sampling instances and features for each
member, then calling `model_wrapper` with the sampled subset. The returned
`DecisionEnsemble` contains the trained models and an optional aggregation
function for prediction.

# Arguments

- `X::PropositionalLogiset`: The training feature set.
- `y::AbstractVector{<:CLabel}`: The vector of labels.
- `num_models::Integer`: Number of ensemble members to train.
- `w::Union{Nothing, AbstractVector{U}, Symbol}`: Instance weights.
  If `nothing`, uniform weights are used.

# Keyword Arguments

- `use_bootstrapping::Bool`: If `true`, training instances are sampled with replacement.
  If `false`, instances are sampled without replacement.
- `samples_ratio_per_model::Real`: Fraction of training instances used for each model.
  Must be in `(0, 1]`. Defaults to `1.0`.
- `n_subfeatures_per_model::Union{Integer, Nothing}`: Number of randomly selected features
  per model. If `nothing`, all features are used.
- `aggregation_function::Union{Nothing, Base.Callable}`: Optional aggregation function used
  by the resulting `DecisionEnsemble` when making predictions.
- `rng::AbstractRNG`: Random number generator used for sampling.
- `model_wrapper::Base.Callable`: Callable used to train each ensemble member.
  It must accept `X_model`, `y_model`, and `w_model` and return a `SoleModel`.
- `kwargs...`: Additional keyword arguments forwarded to `model_wrapper`.

# Returns

- `DecisionEnsemble`: Ensemble containing `num_models` trained models.

# Notes

- It mus tbe possible to convert `X` to a `DataFrame` internally so that row/column indexing and
  column name extraction work reliably.
- If `n_subfeatures_per_model` is `nothing`, all features are used for each model.
- Each ensemble member is trained independently using a copied RNG to avoid
  thread-collision when sampling.

# Errors

- `AssertionError` if `samples_ratio_per_model` is not in `(0, 1]`.
- `AssertionError` if `num_models <= 0`.
- `AssertionError` if `n_subfeatures_per_model` is not in `(0, num_features]`.
- `ArgumentError` if `X` cannot be materialized as a `DataFrame`.

# Example

```julia
using ModalDecisionLists
my_custom_trainer(X, y, w; rng, iteration, kwargs...) = irepstar(X, y, w; rng = rng, kwargs...)

ensemble = build_ensemble(X_train, y_train, 20;
    samples_ratio_per_model=0.8,
    n_subfeatures_per_model=round(Int, nfeatures(X_train) * 0.7),
    model_wrapper=my_custom_trainer)

predictions = apply(ensemble, X_test)
```
"""
function build_ensemble(
    X::PropositionalLogiset,
    y::AbstractVector{<:CLabel},
    num_models::Integer,
    model_wrapper::Base.Callable,
    w::Union{Nothing, AbstractVector{U}, Symbol} = default_weights(length(y));
    
    use_bootstrapping::Bool = true,
    samples_ratio_per_model::Real = 1.0,
    n_subfeatures_per_model::Union{Integer, Nothing} = nothing,

    aggregation_function::Union{Nothing, Base.Callable} = nothing,
    rng::AbstractRNG = Random.default_rng(),

    kwargs...
)::DecisionEnsemble where {U<:Real}
    @assert (0.0 < samples_ratio_per_model ≤ 1.0) "Parameter `samples_ratio_per_model` must be in (0, 1]."
    @assert (num_models > 0) "Parameter `num_models must be ≥ 1."
    
    num_features = nfeatures(X)
    
    !isnothing(n_subfeatures_per_model) && @assert (0 < n_subfeatures_per_model ≤ num_features) "Parameter `n_subfeatures_per_model` must be > 0 and ≤ than the number of features in the dataset."
    isnothing(w) && (w = default_weights(length(y)))

    # we need functions such as row and column slicing, and column names extraction. These are not guaranteed by default by Tables, nor are they (yet) guaranteed by
    # PropositionalLogiset, which wraps around Tables.jl instances. Thus we convert the internal table to a DataFrame, and then recreate the PropositionalLogiset, which
    # is how learning methods in Sole handle data
    X = try
        PropositionalLogiset(DataFrame(X))
    catch
        throw(ArgumentError("The training data X must be materializable to a DataFrame"))
    end

    # Keep all features if the the user hasn't specified otherwise
    if isnothing(n_subfeatures_per_model)
        n_subfeatures_per_model = num_features
    end 

    num_samples = ninstances(X)
    all_feats = collect(Tables.columnnames(Tables.columns(X)))                   # list of feature names 
	n_samples_per_model = round(Integer, ninstances(X) * samples_ratio_per_model)

    models = Vector{AbstractModel}(undef, num_models)

    Threads.@threads for model_num = 1 : num_models
		local_rng = copy(rng)

        # Extract 'n_samples_per_model' random integers in [1, num_samples] (with or without replacement depending on use_bootstrapping)
        if use_bootstrapping
            model_sample_indices = rand(local_rng, 1:num_samples, n_samples_per_model)    # this allows for sampling with replacement
        else
            permutated_indices = randperm(local_rng, num_samples)
            model_sample_indices = permutated_indices[1:n_samples_per_model] 
        end

        # Extract 'n_subfeatures_per_model' features randomly 
		model_feature_names = shuffle(local_rng, all_feats)[1 : n_subfeatures_per_model]

        # use those indices to extract a dataset from X
        X_model = X[model_sample_indices, model_feature_names]            # select sampled features and instances
        y_model = @view y[model_sample_indices]
        w_model = (w isa AbstractVector) ? @view(w[model_sample_indices]) : w      # w might be nothing

        # Train the model
        model = model_wrapper(X_model, y_model, w_model; 
                                rng = rng, 
                                iteration = model_num, 
                                num_models = num_models, 
                                kwargs...)
		
        if !isa(model, AbstractModel)
            throw( ArgumentError("The function `model_wrapper` passed to `build_ensemble` must return an instance of AbstractModel from SoleModels.jl") )
        end

		models[model_num] = model
	end

    info::NamedTuple = (;)

    return DecisionEnsemble(models, aggregation_function, nothing, info)    
end