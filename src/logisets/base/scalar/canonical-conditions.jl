
abstract type CanonicalFeature end

# ⪴ and ⪳, that is, "*all* of the values on this world are at least, or at most ..."
struct CanonicalFeatureGeq <: CanonicalFeature end; const canonical_geq  = CanonicalFeatureGeq();
struct CanonicalFeatureLeq <: CanonicalFeature end; const canonical_leq  = CanonicalFeatureLeq();

# ⪴_α and ⪳_α, that is, "*at least α⋅100 percent* of the values on this world are at least, or at most ..."

struct CanonicalFeatureGeqSoft  <: CanonicalFeature
  alpha :: AbstractFloat
  CanonicalFeatureGeqSoft(a::T) where {T<:Real} = (a > 0 && a < 1) ? new(a) : throw_n_log("Invalid instantiation for test operator: CanonicalFeatureGeqSoft($(a))")
end;
struct CanonicalFeatureLeqSoft  <: CanonicalFeature
  alpha :: AbstractFloat
  CanonicalFeatureLeqSoft(a::T) where {T<:Real} = (a > 0 && a < 1) ? new(a) : throw_n_log("Invalid instantiation for test operator: CanonicalFeatureLeqSoft($(a))")
end;

const canonical_geq_95  = CanonicalFeatureGeqSoft((Rational(95,100)));
const canonical_geq_90  = CanonicalFeatureGeqSoft((Rational(90,100)));
const canonical_geq_85  = CanonicalFeatureGeqSoft((Rational(85,100)));
const canonical_geq_80  = CanonicalFeatureGeqSoft((Rational(80,100)));
const canonical_geq_75  = CanonicalFeatureGeqSoft((Rational(75,100)));
const canonical_geq_70  = CanonicalFeatureGeqSoft((Rational(70,100)));
const canonical_geq_60  = CanonicalFeatureGeqSoft((Rational(60,100)));

const canonical_leq_95  = CanonicalFeatureLeqSoft((Rational(95,100)));
const canonical_leq_90  = CanonicalFeatureLeqSoft((Rational(90,100)));
const canonical_leq_85  = CanonicalFeatureLeqSoft((Rational(85,100)));
const canonical_leq_80  = CanonicalFeatureLeqSoft((Rational(80,100)));
const canonical_leq_75  = CanonicalFeatureLeqSoft((Rational(75,100)));
const canonical_leq_70  = CanonicalFeatureLeqSoft((Rational(70,100)));
const canonical_leq_60  = CanonicalFeatureLeqSoft((Rational(60,100)));
