############################################################################################
# Abstract Symbolic Model Interface
############################################################################################

"""
    immediatesubmodels(m::AbstractModel)

Return the list of immediate child models.
Note: if the model is a leaf model, then the returned list will be empty.

See also [`submodels`](@ref), [`LeafModel`](@ref), [`AbstractModel`](@ref).
"""
function immediatesubmodels(
    m::AbstractModel{O}
)::Vector{<:{AbstractModel{<:O}}} where {O}
    return error("Please, provide method immediatesubmodels(::$(typeof(m))).")
end

"""
    listimmediaterules(m::AbstractModel{O} where {O})::Rule{<:O}

List the immediate rules equivalent to a symbolic model.

See also [`listrules`](@ref), [`AbstractModel`](@ref).
"""
listimmediaterules(m::AbstractModel{O} where {O})::Rule{<:O} =
    error("Please, provide method listimmediaterules(::$(typeof(m))) ($(typeof(m)) is a symbolic model).")

"""
    listrules(
        m::AbstractModel;
        use_shortforms::Bool = true,
        use_leftmostlinearform::Union{Nothing,Bool} = nothing,
        normalize::Bool = false,
        force_syntaxtree::Bool = false,
    )::Vector{<:Rule}

Return a list of rules capturing the knowledge enclosed in symbolic model.
The behavior of any symbolic model can be synthesised and represented as a
set of mutually exclusive (and jointly exaustive, if the model is closed) rules.

See also [`listimmediaterules`](@ref), [`SoleLogics.CONJUNCTION`](@ref),
[`joinrules`](@ref), [`LeafModel`](@ref), [`AbstractModel`](@ref).
"""
function listrules(m::AbstractModel;
    compute_metrics::Union{Nothing,Bool} = false,
    metrics_kwargs::NamedTuple = (;),
    use_shortforms::Bool = true,
    use_leftmostlinearform::Union{Nothing,Bool} = nothing,
    normalize::Bool = false,
    normalize_kwargs::NamedTuple = (; allow_atom_flipping = true, rotate_commutatives = false, ),
    scalar_simplification::Union{Bool,NamedTuple} = normalize ? (; allow_scalar_range_conditions = true) : false,
    force_syntaxtree::Bool = false,
    min_coverage::Union{Nothing,Number} = nothing,
    min_ncovered::Union{Nothing,Number} = nothing,
    min_ninstances::Union{Nothing,Number} = nothing,
    min_confidence::Union{Nothing,Number} = nothing,
    min_lift::Union{Nothing,Number} = nothing,
    metric_filter_callback::Union{Nothing,Base.Callable} = nothing,
    kwargs...,
)
    error("Please, provide method listrules for your model type")
end

"""
    joinrules(rules::AbstractVector{<:Rule})::Vector{<:Rule}

Return a set of rules, with exactly one rule per different outcome from the input set of rules.
For each outcome, the output rule is computed as the logical disjunction of the antecedents
of the input rules for that outcome.

See also [`listrules`](@ref), [`SoleLogics.DISJUNCTION`](@ref), 
[`LeafModel`](@ref), [`AbstractModel`](@ref).
"""
function joinrules(
    rules::AbstractVector{<:Rule},
    silent = false...,
)
    error("Please, provide method joinrules for your rule type")
end

# AbstracTrees interface
import AbstractTrees: children
children(m::AbstractModel) = submodels(m)