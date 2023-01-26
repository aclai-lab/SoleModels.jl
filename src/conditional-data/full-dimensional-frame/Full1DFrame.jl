using SoleLogics: intervals_in, short_intervals_in

accessibles_aggr(fr::Full1DFrame, f::AbstractFeature, a::TestOperatorFun, ::AbstractWorldSet{Interval}, r::_RelationGlob) = intervals_in(1, X(fr)+1)

accessibles_aggr(fr::Full1DFrame, f::Union{SingleAttributeMin,SingleAttributeMax}, a::Union{typeof(minimum),typeof(maximum)}, ::AbstractWorldSet{Interval}, r::_RelationGlob) = short_intervals_in(1, X(fr)+1)
accessibles_aggr(fr::Full1DFrame, f::Union{SingleAttributeMax}, a::typeof(maximum), ::AbstractWorldSet{Interval}, r::_RelationGlob) = Interval[Interval(1, X(fr)+1)  ]
accessibles_aggr(fr::Full1DFrame, f::Union{SingleAttributeMin}, a::typeof(minimum), ::AbstractWorldSet{Interval}, r::_RelationGlob) = Interval[Interval(1, X(fr)+1)  ]

accessibles_aggr(fr::Full1DFrame, f::Union{SingleAttributeSoftMin,SingleAttributeSoftMax}, a::Union{typeof(minimum),typeof(maximum)}, ::AbstractWorldSet{Interval}, r::_RelationGlob) = short_intervals_in(1, X(fr)+1)
accessibles_aggr(fr::Full1DFrame, f::Union{SingleAttributeSoftMax}, a::typeof(maximum), ::AbstractWorldSet{Interval}, r::_RelationGlob) = Interval[Interval(1, X(fr)+1)  ]
accessibles_aggr(fr::Full1DFrame, f::Union{SingleAttributeSoftMin}, a::typeof(minimum), ::AbstractWorldSet{Interval}, r::_RelationGlob) = Interval[Interval(1, X(fr)+1)  ]
