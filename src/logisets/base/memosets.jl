"""
    abstract type AbstractMemoset{
        W<:AbstractWorld,
        U,
        F<:AbstractFeature,
        FR<:AbstractFrame,
    } <: AbstractLogiset{W,U,F,FR} end

Abstract type for memoization structures to be used when checking
formulas on logisets.

See also
[`Memoset`](@ref),
[`SuportedLogiset`](@ref),
[`AbstractLogiset`](@ref).
"""
abstract type AbstractMemoset{
    W<:AbstractWorld,
    U,
    F<:AbstractFeature,
    FR<:AbstractFrame,
} <: AbstractLogiset{W,U,F,FR} end
# } <: AbstractInterpretationSet{AbstractKripkeStructure{W,C where C<:AbstractCondition{_F where _F<:F},T where T<:TruthValue,FR where FR<:AbstractFrame}} end

function capacity(Xm::AbstractMemoset)
    error("Please, provide method capacity(::$(typeof(Xm))).")
end

function nmemoizedvalues(Xm::AbstractMemoset)
    error("Please, provide method nmemoizedvalues(::$(typeof(Xm))).")
end

function nonnothingshare(Xm::AbstractMemoset)
    (isinf(capacity(Xm)) ? NaN : nmemoizedvalues(Xm)/capacity(Xm))
end

function displaystructure(Xm::AbstractMemoset; indent_str = "", include_ninstances = true)
    padattribute(l,r) = string(l) * lpad(r,32+length(string(r))-(length(indent_str)+2+length(l)))
    pieces = []
    push!(pieces, "")
    push!(pieces, "$(padattribute("worldtype:", worldtype(Xm)))")
    push!(pieces, "$(padattribute("featvaltype:", featvaltype(Xm)))")
    push!(pieces, "$(padattribute("featuretype:", featuretype(Xm)))")
    push!(pieces, "$(padattribute("frametype:", frametype(Xm)))")
    if include_ninstances
        push!(pieces, "$(padattribute("# instances:", ninstances(Xm)))")
    end
    push!(pieces, "$(padattribute("# memoized values:", nmemoizedvalues(Xm)))")

    return "Memoset ($(humansize(Xm)))" *
        join(pieces, "\n$(indent_str)├ ", "\n$(indent_str)└ ") * "\n"
end

############################################################################################

"""
A generic, full memoization structure that works for any *crisp* logic;
For each instance of a dataset,
this structure associates formulas to the set of worlds where the
formula holds; it was introduced by Emerson-Clarke for the
well-known model checking algorithm for CTL*.

# Examples
TODO add example showing that checking is faster when using this structure.

See also
[`SuportedLogiset`](@ref),
[`AbstractMemoset`](@ref),
[`AbstractLogiset`](@ref).
"""
struct Memoset{
    W<:AbstractWorld,
    D<:AbstractVector{<:AbstractDict{<:AbstractFormula,<:WorldSet{W}}},
} <: AbstractMemoset{W,U where U,F where F<:AbstractFeature,FR where FR<:AbstractFrame{W}}

    d :: D

    function Memoset{W,D}(
        d::D
    ) where {W,D<:AbstractVector{<:AbstractDict{<:AbstractFormula,<:Union{<:AbstractVector{W},Nothing}}}}
        new{W,D}(d)
    end

    function Memoset(
        d::D
    ) where {W,D<:AbstractVector{<:AbstractDict{<:AbstractFormula,<:Union{<:AbstractVector{W},Nothing}}}}
        new{W,D}(d)
    end

    function Memoset(
        X::AbstractLogiset{W,U,F,FR},
        perform_initialization = false,
    ) where {W,U,F<:AbstractFeature,FR<:AbstractFrame{W}}
        d = [ThreadSafeDict{SyntaxTree,WorldSet{W}}() for i in 1:ninstances(X)]
        D = typeof(d)
        Memoset{W,D}(d)
    end
end

ninstances(Xm::Memoset)      = length(Xm.d)

capacity(Xm::Memoset)        = Inf
nmemoizedvalues(Xm::Memoset) = sum(length.(Xm.d))

@inline function Base.haskey(
    Xm           :: Memoset{W},
    i_instance   :: Integer,
    f            :: AbstractFormula,
) where {W<:AbstractWorld}
    haskey(Xm.d[i_instance], f)
end

@inline function Base.getindex(
    Xm           :: Memoset{W},
    i_instance   :: Integer,
) where {W<:AbstractWorld}
    Xm.d[i_instance]
end
@inline function Base.getindex(
    Xm           :: Memoset{W},
    i_instance   :: Integer,
    f            :: AbstractFormula,
) where {W<:AbstractWorld}
    Xm.d[i_instance][f]
end
@inline function Base.setindex!(
    Xm           :: Memoset{W},
    i_instance   :: Integer,
    f            :: AbstractFormula,
    ws           :: WorldSet{W},
) where {W}
    Xm.d[i_instance][f] = ws
end

function check(
    f::AbstractFormula,
    Xm::Memoset{W},
    i_instance::Integer,
    w::W;
    kwargs...
) where {W<:AbstractWorld}
    w in Base.getindex(Xm, i_instance, f)
end

function instances(
    Xm::Memoset,
    inds::AbstractVector{<:Integer},
    return_view::Union{Val{true},Val{false}} = Val(false);
    kwargs...
)
    Memoset(if return_view == Val(true) @view Xm.d[inds] else Xm.d[inds] end)
end

function concatdatasets(Xms::Memoset...)
    Memoset(vcat([Xm.d for Xm in Xms]...))
end

usesfullmemo(::Memoset) = true
fullmemo(Xm::Memoset) = Xm

hasnans(::Memoset) = false

# Base.size(::Memoset) = ()

############################################################################################
