const MixedSymbolicModel = MixedModel

const List = DecisionList
const Tree = DecisionTree
const Forest = DecisionForest
const modalextractrules = extractrules; export modalextractrules


@inline function apply(
    m::AbstractModel,
    d::AbstractInterpretationSet,
    i_instance::Integer;
    kwargs...
)::outputtype(m)
    @warn "apply(model, dataset, i_instance) is deprecating... Please use apply(model, get_instance(dataset, i_instance)) instead."
    interpretation = get_instance(d, i_instance)
    apply(m, interpretation; kwargs...)
end