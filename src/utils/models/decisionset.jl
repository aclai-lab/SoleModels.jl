
############################################################################################
################################### DecisionSet ############################################
############################################################################################


"""
    struct DecisionSet{O} <: AbstractModel{O}

A `DecisionSet` is a symbolic model that wraps a set of final rules.
A `DecisionSet` is non-overlapping (`isnonoverlapping`) if all rules are mutually exclusive,
and is complete (`iscomplete`) if all rules jointly exaustive.
Any symbolic model can be transformed into a non-overlapping DecisionSet (via [`ruleset`](@ref)),
and if the starting model is complete, then also the resulting decision set is complete.

If the model is non-overlapping, then at most one rule applies to any given an logical interpretation.
If the model is complete, then at least one rule applies to any given an logical interpretation.

TODO how are racing cases handled???

See also [`AbstractModel`](@ref), [`DecisionSet`](@ref), [`Rule`](@ref).
"""
struct DecisionSet{O} <: AbstractModel{O}
    rules::Vector{Rule{_O} where {_O<:O}}
    isnonoverlapping::Bool
    iscomplete::Bool
    info::NamedTuple

    function DecisionSet{O}(
        rules::Vector{<:Rule},
        iscomplete::Bool = false,
        isnonoverlapping::Bool = false,
        info::NamedTuple = (;),
    ) where {O}
        new{O}(rules, iscomplete, isnonoverlapping, info)
    end

    function DecisionSet(
        rules::Vector{<:Rule},
        iscomplete::Bool = false,
        isnonoverlapping::Bool = false,
        info::NamedTuple = (;),
    )
        O = Union{outcometype.(rules)...}
        DecisionSet{O}(rules, iscomplete, isnonoverlapping, info)
    end

    function DecisionSet(
        model,
        args...; kwargs...
    )
        issymbolicmodel(model) || error("Cannot instantiate DecisionSet from non-symbolic model.")
        O = Union{outcometype.(rules)...}
        DecisionSet{O}(listrules(model), args...; kwargs...)
    end
end

rules(m::DecisionSet) = m.rules
nrules(m::DecisionSet) = length(rules(m))

# Helpers
@forward DecisionSet.rules (
    Base.length,
    Base.getindex,
    Base.setindex!,
    Base.push!,
    Base.pushfirst!,
    Base.append!,
    Base.iterate, Base.IteratorSize, Base.IteratorEltype,
    Base.firstindex, Base.lastindex,
    Base.keys, Base.values,
)

iscomplete(m::DecisionSet) = m.iscomplete
isnonoverlapping(m::DecisionSet) = m.isnonoverlapping

function listrules(m::DecisionSet)
    isnonoverlapping || error("Cannot listrules from non-overlapping decision set. Try `extractrules` with heuristics, instead.")
    rules(m)
end

function apply(m::DecisionSet, interpretation::AbstractInterpretation, args...; kwargs...)
    if isnonoverlapping
      for rule in rules(m)
          pred = apply(rule, interpretation, args...; kwargs...)
          isnothing(pred) || return consequent(rule)
      end
    else
      error("Not implemented.")
      return filter(!isnothing, apply(rule, interpretation, args...; kwargs...) for rule in rules(m))
    end
    return nothing
end

function apply!(m::DecisionSet, args...; kwargs...)
    map(r->apply!(r, args...; kwargs...), rules(m))
end

# Helper
ruleset(m::AbstractModel) = DecisionSet(listrules(m))
convert(::Type{DecisionSet}, m) = ruleset(m)
