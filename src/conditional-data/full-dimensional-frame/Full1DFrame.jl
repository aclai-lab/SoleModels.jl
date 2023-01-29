using SoleLogics: intervals_in, short_intervals_in

representatives(fr::Full1DFrame, r::_RelationGlob, ::FeatMetaCondition) = intervals_in(1, X(fr)+1)

representatives(fr::Full1DFrame, r::_RelationGlob, ::Union{SingleAttributeMin,SingleAttributeMax}, ::Union{typeof(minimum),typeof(maximum)}) = short_intervals_in(1, X(fr)+1)
representatives(fr::Full1DFrame, r::_RelationGlob, ::SingleAttributeMax, ::typeof(maximum)) = Interval[Interval(1, X(fr)+1)  ]
representatives(fr::Full1DFrame, r::_RelationGlob, ::SingleAttributeMin, ::typeof(minimum)) = Interval[Interval(1, X(fr)+1)  ]

# TODO correct?
# representatives(fr::Full1DFrame, r::_RelationGlob, ::Union{SingleAttributeSoftMax,SingleAttributeSoftMin}, ::Union{typeof(minimum),typeof(maximum)}) = short_intervals_in(1, X(fr)+1)
representatives(fr::Full1DFrame, r::_RelationGlob, ::SingleAttributeSoftMax, ::typeof(maximum)) = Interval[Interval(1, X(fr)+1)  ]
representatives(fr::Full1DFrame, r::_RelationGlob, ::SingleAttributeSoftMin, ::typeof(minimum)) = Interval[Interval(1, X(fr)+1)  ]
