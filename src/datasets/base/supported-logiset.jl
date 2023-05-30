
############################################################################################
# Explicit modal dataset with support
###########################################################################################

# The lookup table (fwd) in a featured modal dataset provides a quick answer on the truth of
#  propositional decisions; as for answering modal decisions (e.g., ⟨L⟩ (minimum(A2) ≥ 10) )
#  with an fwd, one must enumerate the accessible worlds, compute the truth on each world,
#  and aggregate the answer (by means of all/any). This process is costly; instead, it is
#  sometimes more convenient to initially spend more time computing the truth of any decision,
#  and store this information in a *support* lookup table. Similarly, one can decide to deploy
#  memoization on this table (instead of computing everything at the beginning, compute it on
#  the fly and store it for later calls).
# 
# We define an abstract type for explicit modal dataset with support lookup tables
# remove: abstract type ExplicitModalDatasetWithSupport{V,W,FR} <: AbstractActiveScalarLogiset{W,V,FT,Bool,FR} end
# And an abstract type for support lookup tables
abstract type AbstractSupport{V,W} end

function nonnothingshare(support::AbstractSupport)
    (isinf(capacity(support)) ? NaN : nmemoizedvalues(support)/capacity(support))
end
# 
# In general, one can use lookup (with or without memoization) for any decision, even the
#  more complex ones, for example:
#  ⟨G⟩ (minimum(A2) ≥ 10 ∧ (⟨O⟩ (maximum(A3) > 2) ∨ (minimum(A1) < 0)))
# 
# In practice, decision trees only ask about simple decisions such as ⟨L⟩ (minimum(A2) ≥ 10),
#  or ⟨G⟩ (maximum(A2) ≤ 50). Because the global operator G behaves differently from other
#  relations, it is natural to differentiate between global and relational support tables:
# 
abstract type AbstractRelationalSupport{V,W,FR<:AbstractFrame} <: AbstractSupport{V,W}     end
abstract type AbstractGlobalSupport{V}       <: AbstractSupport{V,W where W<:AbstractWorld} end
#
# Be an *fwd_rs* an fwd relational support, and a *fwd_gs* an fwd global support,
#  for simple support tables like these, it is convenient to store, again, modal *gamma* values.
# Similarly to fwd, gammas are basically values on the verge of truth, that can straightforwardly
#  anser simple modal questions.
# Consider the decision (w ⊨ <R> f ⋈ a) on the i-th instance, for a given feature f,
#  world w, relation R and test operator ⋈, and let gamma (γ) be:
#  - fwd_rs[i, f, a, R, w] if R is a regular relation, or
#  - fwd_gs[i, f, a]       if R is the global relation G,
#  where a = aggregator(⋈). In this context, γ is the unique value for which w ⊨ <R> f ⋈ γ holds and:
#  - if aggregator(⋈) = minimum:     ∀ a > γ:   (w ⊨ <R> f ⋈ a) does not hold
#  - if aggregator(⋈) = maximum:     ∀ a < γ:   (w ⊨ <R> f ⋈ a) does not hold
# 
# Let us define the world type-agnostic implementations for fwd_rs and fwd_gs (note that any fwd_gs
#  is actually inherently world agnostic); world type-specific implementations can be defined
#  in a similar way.

############################################################################################
############################################################################################

isminifiable(::Union{AbstractRelationalSupport,AbstractGlobalSupport}) = true

function minify(support::Union{AbstractRelationalSupport,AbstractGlobalSupport})
    minify(support.d) #TODO improper
end
