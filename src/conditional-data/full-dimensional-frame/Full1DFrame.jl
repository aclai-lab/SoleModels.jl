using SoleLogics: intervals_in, short_intervals_in

representatives(fr::Full1DFrame, r::GlobalRel, ::FeatMetaCondition) = intervals_in(1, X(fr)+1)

representatives(fr::Full1DFrame, r::GlobalRel, ::Union{SingleAttributeMin,SingleAttributeMax}, ::Union{typeof(minimum),typeof(maximum)}) = short_intervals_in(1, X(fr)+1)
representatives(fr::Full1DFrame, r::GlobalRel, ::SingleAttributeMax, ::typeof(maximum)) = [Interval(1, X(fr)+1)  ]
representatives(fr::Full1DFrame, r::GlobalRel, ::SingleAttributeMin, ::typeof(minimum)) = [Interval(1, X(fr)+1)  ]

# TODO correct?
# representatives(fr::Full1DFrame, r::GlobalRel, ::Union{SingleAttributeSoftMax,SingleAttributeSoftMin}, ::Union{typeof(minimum),typeof(maximum)}) = short_intervals_in(1, X(fr)+1)
representatives(fr::Full1DFrame, r::GlobalRel, ::SingleAttributeSoftMax, ::typeof(maximum)) = [Interval(1, X(fr)+1)  ]
representatives(fr::Full1DFrame, r::GlobalRel, ::SingleAttributeSoftMin, ::typeof(minimum)) = [Interval(1, X(fr)+1)  ]
