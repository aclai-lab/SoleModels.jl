using SoleLogics: intervals_in, short_intervals_in

using SoleLogics: _IA_A, _IA_L, _IA_B, _IA_E, _IA_D, _IA_O,
                  _IA_Ai, _IA_Li, _IA_Bi, _IA_Ei, _IA_Di, _IA_Oi

using SoleLogics: _IA_AorO, _IA_AiorOi, _IA_DorBorE, _IA_DiorBiorEi, _IA_I, IA72IARelations

# TODO remove:
# Note: only needed for a smooth definition of IA2DRelations
# _accessibles(fr::Full1DFrame, w::Interval, ::IdentityRel) = [(w.x, w.y)]


############################################################################################
# When defining `representatives` for minimum & maximum features, we find that we can
#  categorized  interval relations according to their behavior.
# Consider the decision ⟨R⟩ (minimum(A1) ≥ 10) evaluated on a world w = (x,y):
#  - With R = identityrel, it requires computing minimum(A1) on w;
#  - With R = globalrel, it requires computing maximum(A1) on 1:(X(fr)+1) (the largest world);
#  - With R = Begins inverse, it requires computing minimum(A1) on (x,y+1), if such interval exists;
#  - With R = During, it requires computing maximum(A1) on (x+1,y-1), if such interval exists;
#  - With R = After, it requires reading the single value in (y,y+1) (or, alternatively, computing minimum(A1) on it), if such interval exists;
#
# Here is the categorization assuming feature = minimum and test_operator = ≥:
#
#                                    .----------------------.
#                                    |(  Id  minimum)       |
#                                    |IA_Bi  minimum        |
#                                    |IA_Ei  minimum        |
#                                    |IA_Di  minimum        |
#                                    |IA_O   minimum        |
#                                    |IA_Oi  minimum        |
#                                    |----------------------|
#                                    |(Glob  maximum)       |
#                                    |IA_L   maximum        |
#                                    |IA_Li  maximum        |
#                                    |IA_D   maximum        |
#                                    |----------------------|
#                                    |IA_A   single-value   |
#                                    |IA_Ai  single-value   |
#                                    |IA_B   single-value   |
#                                    |IA_E   single-value   |
#                                    '----------------------'
#
# When feature = maximum, the two categories minimum and maximum swap roles.
# Furthermore, if test_operator = ≤, or, more generally, existential_aggregator(test_operator)
#  is minimum instead of maximum, again, the two categories minimum and maximum swap roles.
############################################################################################

# e.g., minimum + ≥
representatives(fr::Full1DFrame, w::Interval{Int}, r::_IA_Bi, ::SingleAttributeMin, ::typeof(maximum)) = (w.y < X(fr)+1)                 ?  Interval{Int}[Interval(w.x,   w.y+1)] : Interval{Int}[]
representatives(fr::Full1DFrame, w::Interval{Int}, r::_IA_Ei, ::SingleAttributeMin, ::typeof(maximum)) = (1 < w.x)                   ?  Interval{Int}[Interval(w.x-1, w.y  )] : Interval{Int}[]
representatives(fr::Full1DFrame, w::Interval{Int}, r::_IA_Di, ::SingleAttributeMin, ::typeof(maximum)) = (1 < w.x && w.y < X(fr)+1)      ?  Interval{Int}[Interval(w.x-1, w.y+1)] : Interval{Int}[]
representatives(fr::Full1DFrame, w::Interval{Int}, r::_IA_O,  ::SingleAttributeMin, ::typeof(maximum)) = (w.x+1 < w.y && w.y < X(fr)+1)  ?  Interval{Int}[Interval(w.y-1, w.y+1)] : Interval{Int}[]
representatives(fr::Full1DFrame, w::Interval{Int}, r::_IA_Oi, ::SingleAttributeMin, ::typeof(maximum)) = (1 < w.x && w.x+1 < w.y)    ?  Interval{Int}[Interval(w.x-1, w.x+1)] : Interval{Int}[]

# e.g., maximum + ≤
representatives(fr::Full1DFrame, w::Interval{Int}, r::_IA_Bi, ::SingleAttributeMax, ::typeof(minimum)) = (w.y < X(fr)+1)                 ?  Interval{Int}[Interval(w.x,   w.y+1)] : Interval{Int}[]
representatives(fr::Full1DFrame, w::Interval{Int}, r::_IA_Ei, ::SingleAttributeMax, ::typeof(minimum)) = (1 < w.x)                   ?  Interval{Int}[Interval(w.x-1, w.y  )] : Interval{Int}[]
representatives(fr::Full1DFrame, w::Interval{Int}, r::_IA_Di, ::SingleAttributeMax, ::typeof(minimum)) = (1 < w.x && w.y < X(fr)+1)      ?  Interval{Int}[Interval(w.x-1, w.y+1)] : Interval{Int}[]
representatives(fr::Full1DFrame, w::Interval{Int}, r::_IA_O,  ::SingleAttributeMax, ::typeof(minimum)) = (w.x+1 < w.y && w.y < X(fr)+1)  ?  Interval{Int}[Interval(w.y-1, w.y+1)] : Interval{Int}[]
representatives(fr::Full1DFrame, w::Interval{Int}, r::_IA_Oi, ::SingleAttributeMax, ::typeof(minimum)) = (1 < w.x && w.x+1 < w.y)    ?  Interval{Int}[Interval(w.x-1, w.x+1)] : Interval{Int}[]

# e.g., minimum + ≥
representatives(fr::Full1DFrame, w::Interval{Int}, r::_IA_Bi, ::SingleAttributeMin, ::typeof(minimum)) = (w.y < X(fr)+1)                 ?  Interval{Int}[Interval(w.x,   X(fr)+1)]   : Interval{Int}[]
representatives(fr::Full1DFrame, w::Interval{Int}, r::_IA_Ei, ::SingleAttributeMin, ::typeof(minimum)) = (1 < w.x)                   ?  Interval{Int}[Interval(1,     w.y  )] : Interval{Int}[]
representatives(fr::Full1DFrame, w::Interval{Int}, r::_IA_Di, ::SingleAttributeMin, ::typeof(minimum)) = (1 < w.x && w.y < X(fr)+1)      ?  Interval{Int}[Interval(1,     X(fr)+1  )] : Interval{Int}[]
representatives(fr::Full1DFrame, w::Interval{Int}, r::_IA_O,  ::SingleAttributeMin, ::typeof(minimum)) = (w.x+1 < w.y && w.y < X(fr)+1)  ?  Interval{Int}[Interval(w.x+1, X(fr)+1  )] : Interval{Int}[]
representatives(fr::Full1DFrame, w::Interval{Int}, r::_IA_Oi, ::SingleAttributeMin, ::typeof(minimum)) = (1 < w.x && w.x+1 < w.y)    ?  Interval{Int}[Interval(1,     w.y-1)] : Interval{Int}[]

# e.g., maximum + ≤
representatives(fr::Full1DFrame, w::Interval{Int}, r::_IA_Bi, ::SingleAttributeMax, ::typeof(maximum)) = (w.y < X(fr)+1)                 ?  Interval{Int}[Interval(w.x,   X(fr)+1)]   : Interval{Int}[]
representatives(fr::Full1DFrame, w::Interval{Int}, r::_IA_Ei, ::SingleAttributeMax, ::typeof(maximum)) = (1 < w.x)                   ?  Interval{Int}[Interval(1,     w.y  )] : Interval{Int}[]
representatives(fr::Full1DFrame, w::Interval{Int}, r::_IA_Di, ::SingleAttributeMax, ::typeof(maximum)) = (1 < w.x && w.y < X(fr)+1)      ?  Interval{Int}[Interval(1,     X(fr)+1  )] : Interval{Int}[]
representatives(fr::Full1DFrame, w::Interval{Int}, r::_IA_O,  ::SingleAttributeMax, ::typeof(maximum)) = (w.x+1 < w.y && w.y < X(fr)+1)  ?  Interval{Int}[Interval(w.x+1, X(fr)+1  )] : Interval{Int}[]
representatives(fr::Full1DFrame, w::Interval{Int}, r::_IA_Oi, ::SingleAttributeMax, ::typeof(maximum)) = (1 < w.x && w.x+1 < w.y)    ?  Interval{Int}[Interval(1,     w.y-1)] : Interval{Int}[]

############################################################################################

# e.g., minimum + ≥
representatives(fr::Full1DFrame, w::Interval{Int}, r::_IA_L,  ::SingleAttributeMin, ::typeof(maximum)) = (w.y+1 < X(fr)+1)   ? short_intervals_in(w.y+1, X(fr)+1)   : Interval{Int}[]
representatives(fr::Full1DFrame, w::Interval{Int}, r::_IA_Li, ::SingleAttributeMin, ::typeof(maximum)) = (1 < w.x-1)     ? short_intervals_in(1, w.x-1)     : Interval{Int}[]
representatives(fr::Full1DFrame, w::Interval{Int}, r::_IA_D,  ::SingleAttributeMin, ::typeof(maximum)) = (w.x+1 < w.y-1) ? short_intervals_in(w.x+1, w.y-1) : Interval{Int}[]

# e.g., maximum + ≤
representatives(fr::Full1DFrame, w::Interval{Int}, r::_IA_L,  ::SingleAttributeMax, ::typeof(minimum)) = (w.y+1 < X(fr)+1)   ? short_intervals_in(w.y+1, X(fr)+1)   : Interval{Int}[]
representatives(fr::Full1DFrame, w::Interval{Int}, r::_IA_Li, ::SingleAttributeMax, ::typeof(minimum)) = (1 < w.x-1)     ? short_intervals_in(1, w.x-1)     : Interval{Int}[]
representatives(fr::Full1DFrame, w::Interval{Int}, r::_IA_D,  ::SingleAttributeMax, ::typeof(minimum)) = (w.x+1 < w.y-1) ? short_intervals_in(w.x+1, w.y-1) : Interval{Int}[]

# e.g., minimum + ≥
representatives(fr::Full1DFrame, w::Interval{Int}, r::_IA_L,  ::SingleAttributeMin, ::typeof(minimum)) = (w.y+1 < X(fr)+1)   ? Interval{Int}[Interval(w.y+1, X(fr)+1)  ] : Interval{Int}[]
representatives(fr::Full1DFrame, w::Interval{Int}, r::_IA_Li, ::SingleAttributeMin, ::typeof(minimum)) = (1 < w.x-1)     ? Interval{Int}[Interval(1, w.x-1)    ] : Interval{Int}[]
representatives(fr::Full1DFrame, w::Interval{Int}, r::_IA_D,  ::SingleAttributeMin, ::typeof(minimum)) = (w.x+1 < w.y-1) ? Interval{Int}[Interval(w.x+1, w.y-1)] : Interval{Int}[]

# e.g., maximum + ≤
representatives(fr::Full1DFrame, w::Interval{Int}, r::_IA_L,  ::SingleAttributeMax, ::typeof(maximum)) = (w.y+1 < X(fr)+1)   ? Interval{Int}[Interval(w.y+1, X(fr)+1)  ] : Interval{Int}[]
representatives(fr::Full1DFrame, w::Interval{Int}, r::_IA_Li, ::SingleAttributeMax, ::typeof(maximum)) = (1 < w.x-1)     ? Interval{Int}[Interval(1, w.x-1)    ] : Interval{Int}[]
representatives(fr::Full1DFrame, w::Interval{Int}, r::_IA_D,  ::SingleAttributeMax, ::typeof(maximum)) = (w.x+1 < w.y-1) ? Interval{Int}[Interval(w.x+1, w.y-1)] : Interval{Int}[]

############################################################################################

# e.g., minimum + ≥
representatives(fr::Full1DFrame, w::Interval{Int}, ::_IA_A,  ::SingleAttributeMin, ::typeof(maximum)) = (w.y < X(fr)+1)     ?   Interval{Int}[Interval(w.y,   w.y+1)] : Interval{Int}[] #  _ReprVal(Interval   )# [Interval(w.y, X(fr)+1)]
representatives(fr::Full1DFrame, w::Interval{Int}, ::_IA_Ai, ::SingleAttributeMin, ::typeof(maximum)) = (1 < w.x)       ?   Interval{Int}[Interval(w.x-1, w.x  )] : Interval{Int}[] #  _ReprVal(Interval   )# [Interval(1, w.x)]
representatives(fr::Full1DFrame, w::Interval{Int}, ::_IA_B,  ::SingleAttributeMin, ::typeof(maximum)) = (w.x < w.y-1)   ?   Interval{Int}[Interval(w.x,   w.x+1)] : Interval{Int}[] #  _ReprVal(Interval   )# [Interval(w.x, w.y-1)]
representatives(fr::Full1DFrame, w::Interval{Int}, ::_IA_E,  ::SingleAttributeMin, ::typeof(maximum)) = (w.x+1 < w.y)   ?   Interval{Int}[Interval(w.y-1, w.y  )] : Interval{Int}[] #  _ReprVal(Interval   )# [Interval(w.x+1, w.y)]

# e.g., maximum + ≤
representatives(fr::Full1DFrame, w::Interval{Int}, ::_IA_A,  ::SingleAttributeMax, ::typeof(minimum)) = (w.y < X(fr)+1)     ?   Interval{Int}[Interval(w.y,   w.y+1)] : Interval{Int}[] #  _ReprVal(Interval   )# [Interval(w.y, X(fr)+1)]
representatives(fr::Full1DFrame, w::Interval{Int}, ::_IA_Ai, ::SingleAttributeMax, ::typeof(minimum)) = (1 < w.x)       ?   Interval{Int}[Interval(w.x-1, w.x  )] : Interval{Int}[] #  _ReprVal(Interval   )# [Interval(1, w.x)]
representatives(fr::Full1DFrame, w::Interval{Int}, ::_IA_B,  ::SingleAttributeMax, ::typeof(minimum)) = (w.x < w.y-1)   ?   Interval{Int}[Interval(w.x,   w.x+1)] : Interval{Int}[] #  _ReprVal(Interval   )# [Interval(w.x, w.y-1)]
representatives(fr::Full1DFrame, w::Interval{Int}, ::_IA_E,  ::SingleAttributeMax, ::typeof(minimum)) = (w.x+1 < w.y)   ?   Interval{Int}[Interval(w.y-1, w.y  )] : Interval{Int}[] #  _ReprVal(Interval   )# [Interval(w.x+1, w.y)]

# e.g., minimum + ≥
representatives(fr::Full1DFrame, w::Interval{Int}, ::_IA_A,  ::SingleAttributeMin, ::typeof(minimum)) = (w.y < X(fr)+1)     ?   Interval{Int}[Interval(w.y,   X(fr)+1  )] : Interval{Int}[] #  _ReprVal(Interval(w.y, w.y+1)   )# [Interval(w.y, X(fr)+1)]
representatives(fr::Full1DFrame, w::Interval{Int}, ::_IA_Ai, ::SingleAttributeMin, ::typeof(minimum)) = (1 < w.x)       ?   Interval{Int}[Interval(1,     w.x  )] : Interval{Int}[] #  _ReprVal(Interval(w.x-1, w.x)   )# [Interval(1, w.x)]
representatives(fr::Full1DFrame, w::Interval{Int}, ::_IA_B,  ::SingleAttributeMin, ::typeof(minimum)) = (w.x < w.y-1)   ?   Interval{Int}[Interval(w.x,   w.y-1)] : Interval{Int}[] #  _ReprVal(Interval(w.x, w.x+1)   )# [Interval(w.x, w.y-1)]
representatives(fr::Full1DFrame, w::Interval{Int}, ::_IA_E,  ::SingleAttributeMin, ::typeof(minimum)) = (w.x+1 < w.y)   ?   Interval{Int}[Interval(w.x+1, w.y  )] : Interval{Int}[] #  _ReprVal(Interval(w.y-1, w.y)   )# [Interval(w.x+1, w.y)]

# e.g., maximum + ≤
representatives(fr::Full1DFrame, w::Interval{Int}, ::_IA_A,  ::SingleAttributeMax, ::typeof(maximum)) = (w.y < X(fr)+1)     ?   Interval{Int}[Interval(w.y,   X(fr)+1  )] : Interval{Int}[] #  _ReprVal(Interval(w.y, w.y+1)   )# [Interval(w.y, X(fr)+1)]
representatives(fr::Full1DFrame, w::Interval{Int}, ::_IA_Ai, ::SingleAttributeMax, ::typeof(maximum)) = (1 < w.x)       ?   Interval{Int}[Interval(1,     w.x  )] : Interval{Int}[] #  _ReprVal(Interval(w.x-1, w.x)   )# [Interval(1, w.x)]
representatives(fr::Full1DFrame, w::Interval{Int}, ::_IA_B,  ::SingleAttributeMax, ::typeof(maximum)) = (w.x < w.y-1)   ?   Interval{Int}[Interval(w.x,   w.y-1)] : Interval{Int}[] #  _ReprVal(Interval(w.x, w.x+1)   )# [Interval(w.x, w.y-1)]
representatives(fr::Full1DFrame, w::Interval{Int}, ::_IA_E,  ::SingleAttributeMax, ::typeof(maximum)) = (w.x+1 < w.y)   ?   Interval{Int}[Interval(w.x+1, w.y  )] : Interval{Int}[] #  _ReprVal(Interval(w.y-1, w.y)   )# [Interval(w.x+1, w.y)]

############################################################################################
# Similarly, here is the categorization for IA7 & IA3 assuming feature = minimum and test_operator = ≥:
#
#                               .-----------------------------.
#                               |(  Id         minimum)       |
#                               |IA_AorO       minimum        |
#                               |IA_AiorOi     minimum        |
#                               |IA_DiorBiorEi minimum        |
#                               |-----------------------------|
#                               |IA_DorBorE    maximum        |
#                               |-----------------------------|
#                               |IA_I          ?              |
#                               '-----------------------------'
# TODO write the correct `representatives` methods, instead of these fallbacks:
representatives(fr::Full1DFrame, w::Interval, r::_IA_AorO, f::AbstractFeature, a::Aggregator) =
    Iterators.flatten([representatives(fr, w, r, f, a) for r in IA72IARelations(IA_AorO)])
representatives(fr::Full1DFrame, w::Interval, r::_IA_AiorOi, f::AbstractFeature, a::Aggregator) =
    Iterators.flatten([representatives(fr, w, r, f, a) for r in IA72IARelations(IA_AiorOi)])
representatives(fr::Full1DFrame, w::Interval, r::_IA_DorBorE, f::AbstractFeature, a::Aggregator) =
    Iterators.flatten([representatives(fr, w, r, f, a) for r in IA72IARelations(IA_DorBorE)])
representatives(fr::Full1DFrame, w::Interval, r::_IA_DiorBiorEi, f::AbstractFeature, a::Aggregator) =
    Iterators.flatten([representatives(fr, w, r, f, a) for r in IA72IARelations(IA_DiorBiorEi)])
representatives(fr::Full1DFrame, w::Interval, r::_IA_I, f::AbstractFeature, a::Aggregator) =
    Iterators.flatten([representatives(fr, w, r, f, a) for r in IA72IARelations(IA_I)])
