"""
A logiset associated to a number of cascading memoization structures, that are used
when checking formulas.

# Examples
TODO add example showing that checking is faster when using this structure.

See also
[`SuportedLogiset`](@ref),
[`AbstractMemoset`](@ref),
[`AbstractLogiset`](@ref).
"""
struct SupportedLogiset{
    L<:AbstractLogiset,
    N,
    MS<:NTuple{N,AbstractMemoset},
} <: AbstractLogiset{W where W<:AbstractWorld,U where U,F where F<:AbstractFeature,FR where FR<:AbstractFrame{W where W<:AbstractWorld}}

    # Core dataset
    base                 :: L
    # Support structures
    supports             :: MS

    function SupportedLogiset(
        base::L,
        supports::_MS
    ) where {L<:AbstractLogiset,_N,_MS<:NTuple{_N,<:Union{<:AbstractVector{<:AbstractDict},<:AbstractMemoset,<:SupportedLogiset}}}
        @assert !(base isa SupportedLogiset) "Cannot instantiate SupportedLogiset " *
            "with a SupportedLogiset base."
        if length(supports) == 0
            supports = (Memoset(base),)
        end
        supports = Tuple(vcat(map(supp->begin
            if supp isa AbstractVector{<:AbstractDict{<:AbstractFormula,<:WorldSet}}
                [Memoset(supp)]
            elseif supp isa SupportedLogiset
                @assert base == SoleModels.base(supp) "Cannot inherit supports from " *
                    "SupportedLogiset with different base."
                collect(SoleModels.supports(supp))
            else
                [supp]
            end
        end, supports)...))

        @assert !(any(isa.(supports, SupportedLogiset))) "Cannot instantiate " *
            "SupportedLogiset with a SupportedLogiset support."
        for (i_supp,supp) in enumerate(supports)
            @assert worldtype(base) <: worldtype(supp) "Cannot instantiate " *
                "SupportedLogiset with unsupported worldtypes for $(i_supp)-th support: " *
                "$(worldtype(base)) <: $(worldtype(supp)) should hold."
            @assert featvaltype(base) <: featvaltype(supp) "Cannot instantiate " *
                "SupportedLogiset with unsupported featvaltypes for $(i_supp)-th support: " *
                "$(featvaltype(base)) <: $(featvaltype(supp)) should hold."
            @assert featuretype(base) <: featuretype(supp) "Cannot instantiate " *
                "SupportedLogiset with unsupported featuretypes for $(i_supp)-th support: " *
                "$(featuretype(base)) <: $(featuretype(supp)) should hold."
            @assert frametype(base) <: frametype(supp) "Cannot instantiate " *
                "SupportedLogiset with unsupported frametypes for $(i_supp)-th support: " *
                "$(frametype(base)) <: $(frametype(supp)) should hold."
        end
        _fullmemo = usesfullmemo.(supports)
        @assert sum(_fullmemo) <= 1 "Cannot instantiate SupportedLogiset with " *
            "more than one full memoization set. $(sum(_fullmemo)) were provided." *
            "$(@show typeof.(supports))"

        @assert all((!).(_fullmemo)) || (last(_fullmemo) && all((!).(_fullmemo[1:end-1]))) "" *
            "Please, provide cascading supports so that the full memoization set appears " *
            "last. $(@show typeof.(supports))"

        N = length(supports)
        MS = typeof(supports)
        new{L,N,MS}(base, supports)
    end

    function SupportedLogiset(
        base::AbstractLogiset,
        supports::AbstractVector{<:Union{AbstractVector{<:AbstractDict},AbstractMemoset,SupportedLogiset}}
    )
        SupportedLogiset(base, Tuple(supports))
    end

    # Helper
    function SupportedLogiset(
        base::AbstractLogiset,
        supports::Union{<:AbstractVector{<:AbstractDict},<:AbstractMemoset,<:SupportedLogiset}...
    )
        SupportedLogiset(base, supports)
    end
end

base(X::SupportedLogiset)     = X.base
supports(X::SupportedLogiset) = X.supports

nsupports(X::SupportedLogiset) = length(X.supports)

capacity(X::SupportedLogiset) = sum(capacity.(supports(X)))
nmemoizedvalues(X::SupportedLogiset) = sum(nmemoizedvalues.(supports(X)))


function featvalue(
    X::SupportedLogiset,
    i_instance::Integer,
    w::W,
    f::AbstractFeature,
) where {W<:AbstractWorld}
    featvalue(base(X), i_instance, w, f)
end

frame(X::SupportedLogiset, i_instance::Integer) = frame(base(X), i_instance)

ninstances(X::SupportedLogiset) = ninstances(base(X))

function allfeatvalues(
    X::SupportedLogiset,
)
    allfeatvalues(base(X))
end

function allfeatvalues(
    X::SupportedLogiset,
    i_instance::Integer,
)
    allfeatvalues(base(X), i_instance)
end

function allfeatvalues(
    X::SupportedLogiset,
    i_instance::Integer,
    feature::AbstractFeature,
)
    allfeatvalues(base(X), i_instance, feature)
end


usesfullmemo(X::SupportedLogiset) = usesfullmemo(last(supports(X)))
fullmemo(X::SupportedLogiset) = usesfullmemo(X) ? last(supports(X)) : error("This " *
    "dataset does not have a full memoization set.")

isminifiable(X::SupportedLogiset) = isminifiable(base(X)) && all(isminifiable.(supports(X)))

function minify(X::SL) where {SL<:SupportedLogiset}
    (new_sl, new_supports...), backmap =
        minify([
            base(X),
            supports(X)...,
        ])

    X = SL(
        new_sl,
        new_supports,
    )
    X, backmap
end

hasnans(X::SupportedLogiset) = hasnans(base(X)) || any(hasnans.(supports(X)))

function instances(
    X::SupportedLogiset,
    inds::AbstractVector{<:Integer},
    return_view::Union{Val{true},Val{false}} = Val(false);
    kwargs...
)
    _instances = (X)->instances(X, inds, return_view; kwargs...)
    SupportedLogiset(
        _instances(base(X)),
        [_instances(supp) for supp in supports(X)]...,
    )
end

function concatdatasets(Xs::SupportedLogiset...)
    SupportedLogiset(
        concatdatasets([base(X) for X in Xs]),
        [concatdatasets([supports(X)[i_supp] for X in Xs]...) for i_supp in 1:nsupports(Xs)]...,
    )
end

function displaystructure(X::SupportedLogiset; indent_str = "", include_ninstances = true)
    padattribute(l,r) = string(l) * lpad(r,32+length(string(r))-(length(indent_str)+2+length(l))-1)
    pieces = []
    push!(pieces, " \n")
    if include_ninstances
        push!(pieces, " " * padattribute("# instances:", "$(ninstances(X))\n"))
    end
    push!(pieces, " " * padattribute("usesfullmemo:", "$(usesfullmemo(X))\n"))
    push!(pieces, " base:\n")
    push!(pieces, " " * displaystructure(base(X); indent_str = "$(indent_str)│ ", include_ninstances = false))
    push!(pieces, " " * padattribute("# supports:", "$(nsupports(X))\n"))
    for (i_supp,supp) in enumerate(supports(X))
        push!(pieces, "[$(i_supp)] $(displaystructure(supp; indent_str = (i_supp == nsupports(X) ? "$(indent_str)  " : "$(indent_str)│ "), include_ninstances = false))\n")
    end
    return "SupportedLogiset ($(humansize(X)))" *
        join(pieces, "$(indent_str)├", "$(indent_str)└") * "\n"
end

# ############################################################################################

# Base.getindex(X::SupportedLogiset, args...)     = Base.getindex(base(X), args...)::featvaltype(X)
# Base.size(X::SupportedLogiset)                  = (size(base(X)), size(support(X)))
# features(X::SupportedLogiset)                   = features(base(X))
# grouped_featsaggrsnops(X::SupportedLogiset)     = grouped_featsaggrsnops(base(X))
# grouped_featsnaggrs(X::SupportedLogiset)        = grouped_featsnaggrs(base(X))
# nfeatures(X::SupportedLogiset)                  = nfeatures(base(X))
# nrelations(X::SupportedLogiset)                 = nrelations(base(X))
# ninstances(X::SupportedLogiset)                   = ninstances(base(X))
# relations(X::SupportedLogiset)                  = relations(base(X))
# fwd(X::SupportedLogiset)                        = fwd(base(X))
# worldtype(X::SupportedLogiset{V,W}) where {V,W} = W

# usesmemo(X::SupportedLogiset) = usesmemo(support(X))
