module DecisionTreeExt

using SoleModels
import SoleModels: solemodel
import SoleModels: alphabet

import DecisionTree as DT

function get_condition(featid, featval, featurenames)
    test_operator = (<)
    # @show fieldnames(typeof(tree))
    feature = !isnothing(featurenames) ? VariableValue(featurenames[featid]) : VariableValue(featid)
    return ScalarCondition(feature, test_operator, featval)
end

function SoleModels.alphabet(
    model::Union{
        DT.Ensemble,
        DT.InfoNode,
        DT.Node,
        DT.Leaf,
    },
    args...;
    kwargs...
)

    function _alphabet!(a::Vector, model::DT.Ensemble, args...; kwargs...)
        map(t -> _alphabet!(a, t, args...; kwargs...), model.trees)
        return a
    end

    function _alphabet!(a::Vector, model::DT.InfoNode, args...; kwargs...)
        _alphabet!(a, model.left, args...; kwargs...)
        _alphabet!(a, model.right, args...; kwargs...)
        return a
    end

    function _alphabet!(a::Vector, model::DT.Node, args...;
        featurenames = true,
        kwargs...
    )
        featurenames = featurenames == true ? model.info.featurenames : featurenames
        push!(a, Atom(get_condition(model.featid, model.featval, featurenames)))
        return a
    end

    function _alphabet!(a::Vector, model::DT.Leaf, args...; kwargs...)
        return a
    end
    
    return SoleData.scalaralphabet(_alphabet!(Atom{ScalarCondition}[], model, args...; kwargs...))
end


function SoleModels.solemodel(
    model::DT.Ensemble,
    args...;
    classlabels = nothing,
    featurenames = nothing,
    keep_condensed = true,
    kwargs...
)
    if isnothing(classlabels)
        error("Please, provide classlabels argument, as in solemodel(forest; classlabels = classlabels, kwargs...). If your forest was trained via MLJ, use `classlabels = (mach).fitresult[2][sortperm((mach).fitresult[3])]`. Also consider providing `featurenames = report(mach).features`.")
    end
    if keep_condensed
        info = (;
            apply_preprocess=(y -> UInt32(findfirst(x -> x == y, classlabels))),
            apply_postprocess=(y -> classlabels[y]),
        )
        keep_condensed = !keep_condensed
        # O = UInt32
    else
        info = (;)
        # O = UInt32
    end
    trees = map(t -> SoleModels.solemodel(t, args...; keep_condensed, featurenames, kwargs...), model.trees)
    # trees = map(t -> let b = SoleModels.solemodel(t, args...; keep_condensed, featurenames, kwargs...); SoleModels.DecisionTree(b, 
    #     (;
    #         supporting_predictions=b.info[:supporting_predictions],
    #         supporting_labels=b.info[:supporting_labels],
    #     )
    # ) end, model.trees)

    if !isnothing(featurenames)
        info = merge(info, (; featurenames=featurenames, ))
    end

    info = merge(info, (;
            supporting_predictions=vcat([t.info[:supporting_predictions] for t in trees]...),
            supporting_labels=vcat([t.info[:supporting_labels] for t in trees]...),
        )
    )

    if !isnothing(classlabels)
        O = eltype(classlabels)
        # O = eltype(levels(classnames))
    else
        O = nothing
    end

    if isnothing(O)
        m = DecisionEnsemble(trees, info)
    else
        m = DecisionEnsemble{O}(trees, info)
    end
    return m
end

function SoleModels.solemodel(tree::DT.InfoNode; keep_condensed = true, featurenames = true, classlabels = tree.info.classlabels, kwargs...)
    # @show fieldnames(typeof(tree))
    featurenames = featurenames == true ? tree.info.featurenames : featurenames
    
    root, info = begin
        if keep_condensed
            root = SoleModels.solemodel(tree.node; featurenames, kwargs...)
            info = (;
                apply_preprocess=(y -> UInt32(findfirst(x -> x == y, classlabels))),
                apply_postprocess=(y -> classlabels[y]),
            )
            keep_condensed = !keep_condensed
            root, info
        else
            root = SoleModels.solemodel(tree.node; replace_classlabels = classlabels, featurenames, kwargs...)
            info = (;)
            root, info
        end
    end

    info = merge(info, (;
            featurenames=tree.info.featurenames,
            # 
            supporting_predictions=root.info[:supporting_predictions],
            supporting_labels=root.info[:supporting_labels],
        )
    )
    
    # if !isnothing(classlabels)
    #     O = eltype(classlabels)
    # else
    #     O = nothing
    # end

    # if isnothing(O)
        dt = DecisionTree(root, info)
    # else
    #     dt = DecisionTree{O}(root, info)
    # end
    return dt
end

# function SoleModels.solemodel(tree::DT.Root)
#     root = SoleModels.solemodel(tree.node)
#     # @show fieldnames(typeof(tree))
#     info = (;
#         n_feat = tree.n_feat,
#         featim = tree.featim,
#         supporting_predictions = root.info[:supporting_predictions],
#         supporting_labels = root.info[:supporting_labels],
#     )
#     return DecisionTree(root, info)
# end

function SoleModels.solemodel(tree::DT.Node; replace_classlabels = nothing, featurenames = nothing, keep_condensed = false)
    keep_condensed && error("Cannot keep condensed DecisionTree.Node.")
    cond = get_condition(tree.featid, tree.featval, featurenames)
    antecedent = Atom(cond)
    lefttree = SoleModels.solemodel(tree.left; replace_classlabels, featurenames)
    righttree = SoleModels.solemodel(tree.right; replace_classlabels, featurenames)
    info = (;
        supporting_predictions = [lefttree.info[:supporting_predictions]..., righttree.info[:supporting_predictions]...],
        supporting_labels = [lefttree.info[:supporting_labels]..., righttree.info[:supporting_labels]...],
    )
    return Branch(antecedent, lefttree, righttree, info)
end

function SoleModels.solemodel(tree::DT.Leaf; replace_classlabels = nothing, featurenames = nothing, keep_condensed = false)
    keep_condensed && error("Cannot keep condensed DecisionTree.Node.")
    # @show fieldnames(typeof(tree))
    prediction = tree.majority
    labels = tree.values
    if !isnothing(replace_classlabels)
        prediction = replace_classlabels[prediction]
        labels = replace_classlabels[labels]
    end
    info = (;
        supporting_predictions = fill(prediction, length(labels)),
        supporting_labels = labels,
    )
    return SoleModels.ConstantModel(prediction, info)
end

end
