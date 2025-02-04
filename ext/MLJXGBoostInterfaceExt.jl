module MLJXGBoostInterfaceExt

using SoleModels
import SoleModels: solemodel, fitted_params

using MLJXGBoostInterface
using MLJXGBoostInterface: XGB, MMI

using AbstractTrees

get_encoding(classes_seen) = Dict(MMI.int(c) => c for c in MMI.classes(classes_seen))
get_classlabels(encoding) = [string(encoding[i]) for i in sort(keys(encoding) |> collect)]

struct XGBNode
    node::XGB.Node
    info::NamedTuple
end
AbstractTrees.nodevalue(n::XGBNode) = n.node

struct XGBLeaf
    node::XGB.Node
    info::NamedTuple
end
AbstractTrees.nodevalue(l::XGBLeaf) = l.node

isleaf(node::XGB.Node) = isempty(node.children) ? true : false

SoleModels.wrap(vecnode::Vector{<:XGB.Node}, info::NamedTuple=NamedTuple()) = SoleModels.wrap.(vecnode, Ref(info))
SoleModels.wrap(node::XGB.Node, info::NamedTuple=NamedTuple()) = isleaf(node) ? XGBLeaf(node, info) : XGBNode(node, info)

function SoleModels.fitted_params(mach)
    raw_trees = XGB.trees(mach.fitresult[1])
    encoding = get_encoding(mach.fitresult[2])
    featurenames = mach.report.vals[1][1]
    classlabels = get_classlabels(encoding)
    info = (;featurenames, classlabels)
    trees = SoleModels.wrap(raw_trees, info,)
    (; trees, encoding)
end

end