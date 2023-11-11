```@meta
CurrentModule = SoleModels
```

# SoleModels

Documentation for [SoleModels](https://github.com/aclai-lab/SoleModels.jl).

```@index
```

## Logical foundations

[SoleLogics](https://github.com/aclai-lab/SoleLogics.jl) lays the logical foundations
for this package.
While the full reference for SoleLogics can be found [here](https://aclai-lab.github.io/SoleLogics.jl/),
these are the basic logical concepts needed for *symbolic modelling*.

```@docs
SoleLogics.Atom
SoleLogics.CONJUNCTION
SoleLogics.DISJUNCTION
SoleLogics.Formula
SoleLogics.syntaxstring

SoleLogics.AbstractAlphabet
SoleLogics.AbstractInterpretation
SoleLogics.AbstractInterpretationSet

SoleLogics.check

SoleLogics.AbstractWorld
SoleLogics.GeometricalWorld
SoleLogics.Interval
SoleLogics.Interval2D

SoleLogics.AbstractRelation
SoleLogics.globalrel
SoleLogics.IA_L

SoleLogics.AbstractFrame
SoleLogics.AbstractKripkeStructure
SoleLogics.accessibles
```

```@autodocs
Modules = [SoleModels, SoleModels.DimensionalDatasets]
```
