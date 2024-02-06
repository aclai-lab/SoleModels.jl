using SoleBase: CLabel, RLabel, Label, _CLabel, _Label
using SoleBase: bestguess
using SoleBase: default_weights, balanced_weights, slice_weights

const AssociationRule{F} = Rule{F} where {F<:Formula}
const ClassificationRule{L} = Rule{L} where {L<:CLabel}
const RegressionRule{L} = Rule{L} where {L<:RLabel}
