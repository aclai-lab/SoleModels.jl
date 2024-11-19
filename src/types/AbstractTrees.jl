
# AbstracTrees interface
using AbstractTrees
import AbstractTrees: children

AbstractTrees.children(m::AbstractModel) = immediatesubmodels(m)
