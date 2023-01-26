# RCC8RelationFromIA

#=

computeModalThresholdDual(test_operator::CanonicalFeatureGeq, w::Interval, r::RCC8RelationFromIA, channel::DimensionalChannel{T,1}) where {T} = begin
    maxExtrema(
        map((IA_r)->(yieldReprs(test_operator, enum_acc_repr(test_operator, w, IA_r, length(channel)), channel)), topo2IARelations(r))
    )
end
compute_modal_gamma(test_operator::CanonicalFeatureGeq, w::Interval, r::RCC8RelationFromIA, channel::DimensionalChannel{T,1}) where {T} = begin
    maximum(
        map((IA_r)->(yieldRepr(test_operator, enum_acc_repr(test_operator, w, IA_r, length(channel)), channel)), topo2IARelations(r))
    )
end
compute_modal_gamma(test_operator::CanonicalFeatureLeq, w::Interval, r::RCC8RelationFromIA, channel::DimensionalChannel{T,1}) where {T} = begin
    mininimum(
        map((IA_r)->(yieldRepr(test_operator, enum_acc_repr(test_operator, w, IA_r, length(channel)), channel)), topo2IARelations(r))
    )
end

enum_acc_repr(fr::Full1DFrame, test_operator::TestOperator, w::Interval, ::_Topo_NTPP,) = enum_acc_repr(test_operator, fr, w, IA_D)
enum_acc_repr(fr::Full1DFrame, test_operator::TestOperator, w::Interval, ::_Topo_NTPPi,) = enum_acc_repr(test_operator, fr, w, IA_Di)

computeModalThresholdDual(test_operator::CanonicalFeatureGeq, w::Interval, r::RCC5Relation, channel::DimensionalChannel{T,1}) where {T} = begin
    maxExtrema(
        map((IA_r)->(yieldReprs(test_operator, enum_acc_repr(test_operator, w, IA_r, size(channel)...), channel)), [IA_r for RCC8_r in RCC52RCC8Relations(r) for IA_r in topo2IARelations(RCC8_r)])
    )
end
compute_modal_gamma(test_operator::CanonicalFeatureGeq, w::Interval, r::RCC5Relation, channel::DimensionalChannel{T,1}) where {T} = begin
    maximum(
        map((IA_r)->(yieldRepr(test_operator, enum_acc_repr(test_operator, w, IA_r, size(channel)...), channel)), [IA_r for RCC8_r in RCC52RCC8Relations(r) for IA_r in topo2IARelations(RCC8_r)])
    )
end
compute_modal_gamma(test_operator::CanonicalFeatureLeq, w::Interval, r::RCC5Relation, channel::DimensionalChannel{T,1}) where {T} = begin
    mininimum(
        map((IA_r)->(yieldRepr(test_operator, enum_acc_repr(test_operator, w, IA_r, size(channel)...), channel)), [IA_r for RCC8_r in RCC52RCC8Relations(r) for IA_r in topo2IARelations(RCC8_r)])
    )
end

    
=#
