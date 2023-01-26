using SoleLogics: intervals2D_in

accessibles_aggr(fr::Full2DFrame, f::Union{SingleAttributeMin,SingleAttributeMax}, a::Union{typeof(minimum),typeof(maximum)}, ::AbstractWorldSet{Interval2D}, r::_RelationGlob) = intervals2D_in(1,X(fr)+1,1,Y(fr)+1)
accessibles_aggr(fr::Full2DFrame, f::Union{SingleAttributeMax}, a::typeof(maximum), ::AbstractWorldSet{Interval2D}, r::_RelationGlob) = Interval2D[Interval2D(Interval(1,X(fr)+1), Interval(1,Y(fr)+1))  ]
accessibles_aggr(fr::Full2DFrame, f::Union{SingleAttributeMin}, a::typeof(minimum), ::AbstractWorldSet{Interval2D}, r::_RelationGlob) = Interval2D[Interval2D(Interval(1,X(fr)+1), Interval(1,Y(fr)+1))  ]

accessibles_aggr(fr::Full2DFrame, f::Union{SingleAttributeSoftMin,SingleAttributeSoftMax}, a::Union{typeof(minimum),typeof(maximum)}, ::AbstractWorldSet{Interval2D}, r::_RelationGlob) = intervals2D_in(1,X(fr)+1,1,Y(fr)+1)
accessibles_aggr(fr::Full2DFrame, f::Union{SingleAttributeSoftMax}, a::typeof(maximum), ::AbstractWorldSet{Interval2D}, r::_RelationGlob) = Interval2D[Interval2D(Interval(1,X(fr)+1), Interval(1,Y(fr)+1))  ]
accessibles_aggr(fr::Full2DFrame, f::Union{SingleAttributeSoftMin}, a::typeof(minimum), ::AbstractWorldSet{Interval2D}, r::_RelationGlob) = Interval2D[Interval2D(Interval(1,X(fr)+1), Interval(1,Y(fr)+1))  ]

# TODO add bindings for Full2DFrame+IA and Full2DFrame+RCC
