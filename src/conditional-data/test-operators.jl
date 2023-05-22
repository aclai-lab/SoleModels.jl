export inverse_test_operator, dual_test_operator
        apply_test_operator,
        TestOperator

using SoleLogics: TruthValue

############################################################################################

"""
    const TestOperator = Function

A test operator is a binary Julia `Function` used for comparing a feature value and
a threshold. In a crisp (i.e., boolean, non-fuzzy) setting, the test operator returns
a boolean value, and `<`, `>`, `≥`, `≤`, `!=`, and `==` are typically used.
"""
const TestOperator = Function

"""
Apply a test operator by simply passing the feature value and threshold to
the (binary) test operator function.
"""
@inline apply_test_operator(
    operator::TestOperator,
    featval::T,
    threshold::T
) where {T}
    operator(featval, threshold)
end

const Aggregator = Function

############################################################################################
# Crisp operators
############################################################################################

inverse_test_operator(::typeof(≥))  = <
inverse_test_operator(::typeof(≤))  = >
inverse_test_operator(::typeof(<))  = ≥
inverse_test_operator(::typeof(>))  = ≤
inverse_test_operator(::typeof(==)) = !=
inverse_test_operator(::typeof(!=)) = ==

dual_test_operator(::typeof(≥)) = ≤
dual_test_operator(::typeof(≤)) = ≥

existential_aggregator(::typeof(>))  = maximum
existential_aggregator(::typeof(<))  = minimum
existential_aggregator(::typeof(≥))  = maximum
existential_aggregator(::typeof(≤))  = minimum
existential_aggregator(::typeof(==)) = ∪

universal_aggregator(::typeof(>))  = minimum
universal_aggregator(::typeof(<))  = maximum
universal_aggregator(::typeof(≥))  = minimum
universal_aggregator(::typeof(≤))  = maximum
universal_aggregator(::typeof(==)) = ∩

aggregator_bottom(::typeof(maximum), T::Type) = typemin(T)
aggregator_bottom(::typeof(minimum), T::Type) = typemax(T)

aggregator_to_binary(::typeof(maximum)) = max
aggregator_to_binary(::typeof(minimum)) = min

############################################################################################
# Fuzzy
############################################################################################

# # =ₕ
# function get_fuzzy_linear_eq(h::T, fuzzy_type::Type{<:Real} = Float64) where {T}
#   fun = function (x::S, y::S) where {S}
#     Δ = y-x
#     if abs(Δ) ≥ h
#       zero(fuzzy_type)
#     else
#       fuzzy_type(1-(abs(Δ)/h))
#     end
#   end
#   @eval global existential_aggregator(::typeof($fun)) = ∪
#   fun
# end


# # >ₕ
# function get_fuzzy_linear_gt(h::T, fuzzy_type::Type{<:Real} = Float64) where {T}
#   fun = function (x::S, y::S) where {S}
#     Δ = y-x
#     if Δ ≥ 0
#       zero(fuzzy_type)
#     elseif Δ ≤ -h
#       one(fuzzy_type)
#     else
#       fuzzy_type(Δ/h)
#     end
#   end
#   @eval global existential_aggregator(::typeof($fun)) = maximum
#   fun
# end

# # <ₕ
# function get_fuzzy_linear_lt(h::T, fuzzy_type::Type{<:Real} = Float64) where {T}
#   fun = function (x::S, y::S) where {S}
#     Δ = y-x
#     if Δ ≥ h
#       one(fuzzy_type)
#     elseif Δ ≤ 0
#       zero(fuzzy_type)
#     else
#       fuzzy_type(Δ/h)
#     end
#   end
#   @eval global existential_aggregator(::typeof($fun)) = minimum
#   fun
# end


# # ≧ₕ
# function get_fuzzy_linear_geq(h::T, fuzzy_type::Type{<:Real} = Float64) where {T}
#   fun = function (x::S, y::S) where {S}
#     Δ = y-x
#     if Δ ≤ 0
#       one(fuzzy_type)
#     elseif Δ ≥ h
#       zero(fuzzy_type)
#     else
#       fuzzy_type(1-Δ/h)
#     end
#   end
#   @eval global existential_aggregator(::typeof($fun)) = maximum
#   fun
# end


# # ≦ₕ
# function get_fuzzy_linear_leq(h::T, fuzzy_type::Type{<:Real} = Float64) where {T}
#   fun = function (x::S, y::S) where {S}
#     Δ = x-y
#     if Δ ≤ 0
#       one(fuzzy_type)
#     elseif Δ ≥ h
#       zero(fuzzy_type)
#     else
#       fuzzy_type(1-Δ/h)
#     end
#   end
#   @eval global existential_aggregator(::typeof($fun)) = minimum
#   fun
# end

# # ≥ₕ
# function get_fuzzy_linear_geqt(h::T, fuzzy_type::Type{<:Real} = Float64) where {T}
#   h_2 = h/2
#   fun = function (x::S, y::S) where {S}
#     Δ = y-x
#     if Δ ≥ h_2
#       zero(fuzzy_type)
#     elseif Δ ≤ -h_2
#       one(fuzzy_type)
#     else
#       fuzzy_type((h_2-Δ)/h)
#     end
#   end
#   @eval global existential_aggregator(::typeof($fun)) = maximum
#   fun
# end

# # ≤ₕ
# function get_fuzzy_linear_leqt(h::T, fuzzy_type::Type{<:Real} = Float64) where {T}
#   h_2 = h/2
#   fun = function (x::S, y::S) where {S}
#     Δ = y-x
#     if Δ ≥ h_2
#       one(fuzzy_type)
#     elseif Δ ≤ -h_2
#       zero(fuzzy_type)
#     else
#       fuzzy_type((Δ+h_2)/h)
#     end
#   end
#   @eval global existential_aggregator(::typeof($fun)) = minimum
#   fun
# end

# h = 4
# v1 = 0
# v2 = -4:4

# op_fuzzy_eq = get_fuzzy_linear_eq(h)
# op_fuzzy_gt = get_fuzzy_linear_gt(h)
# op_fuzzy_lt = get_fuzzy_linear_lt(h)
# op_fuzzy_geqt = get_fuzzy_linear_geqt(h)
# op_fuzzy_leqt = get_fuzzy_linear_leqt(h)
# op_fuzzy_geq = get_fuzzy_linear_geq(h)
# op_fuzzy_leq = get_fuzzy_linear_leq(h)

# zip(v2, eq.(v1, v2)) |> collect
# zip(v2, gt.(v1, v2)) |> collect
# zip(v2, lt.(v1, v2)) |> collect
# zip(v2, geq.(v1, v2)) |> collect
# zip(v2, leq.(v1, v2)) |> collect
# zip(v2, op_fuzzy_eq.(v1, v2)) |> collect
# zip(v2, op_fuzzy_gt.(v1, v2)) |> collect
# zip(v2, op_fuzzy_lt.(v1, v2)) |> collect
# zip(v2, op_fuzzy_geqt.(v1, v2)) |> collect
# zip(v2, op_fuzzy_leqt.(v1, v2)) |> collect
# zip(v2, op_fuzzy_geq.(v1, v2)) |> collect
# zip(v2, op_fuzzy_leq.(v1, v2)) |> collect



# (Rational(60,100))

# # TODO improved version for Rational numbers
# # TODO check
# @inline test_op_partialsort!(test_op::CanonicalFeatureGeqSoft, vals::Vector{T}) where {T} =
#   partialsort!(vals,ceil(Int, alpha(test_op)*length(vals)); rev=true)
# @inline test_op_partialsort!(test_op::CanonicalFeatureLeqSoft, vals::Vector{T}) where {T} =
#   partialsort!(vals,ceil(Int, alpha(test_op)*length(vals)))

# @inline computePropositionalThreshold(test_op::Union{CanonicalFeatureGeqSoft,CanonicalFeatureLeqSoft}, w::AbstractWorld, channel::DimensionalChannel{T,N}) where {T,N} = begin
#   vals = vec(ch_readWorld(w,channel))
#   test_op_partialsort!(test_op,vals)
# end
# @inline computePropositionalThresholdMany(test_ops::Vector{<:TestOperator}, w::AbstractWorld, channel::DimensionalChannel{T,N}) where {T,N} = begin
#   vals = vec(ch_readWorld(w,channel))
#   (test_op_partialsort!(test_op,vals) for test_op in test_ops)
# end

# @inline test_decisioaoeu(test_operator::CanonicalFeatureGeqSoft, w::AbstractWorld, channel::DimensionalChannel{T,N}, threshold::Real) where {T,N} = begin
#   ys = 0
#   # TODO write with reduce, and optimize it (e.g. by stopping early if the decision is reached already)
#   vals = ch_readWorld(w,channel)
#   for x in vals
#     if x >= threshold
#       ys+=1
#     end
#   end
#   (ys/length(vals)) >= test_operator.alpha
# end

# @inline test_decisioaoeu(test_operator::CanonicalFeatureLeqSoft, w::AbstractWorld, channel::DimensionalChannel{T,N}, threshold::Real) where {T,N} = begin
#   ys = 0
#   # TODO write with reduce, and optimize it (e.g. by stopping early if the decision is reached already)
#   vals = ch_readWorld(w,channel)
#   for x in vals
#     if x <= threshold
#       ys+=1
#     end
#   end
#   (ys/length(vals)) >= test_operator.alpha
# end

# const all_lowlevel_test_operators = [
#     canonical_geq, canonical_leq,
#     SoftenedOperators...
#   ]

# const all_ordered_test_operators = [
#     canonical_geq, canonical_leq,
#     SoftenedOperators...
#   ]
# const all_test_operators_order = [
#     canonical_geq, canonical_leq,
#     SoftenedOperators...
#   ]
# sort_test_operators!(x::Vector{TO}) where {TO<:TestOperator} = begin
#   intersect(all_test_operators_order, x)
# end
