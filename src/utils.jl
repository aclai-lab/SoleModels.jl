module utils

# TODO move to SoleBase
_typejoin(S::_S) where {_S} = S
_typejoin(S::_S, T::_T) where {_S,_T} = typejoin(S, T)
_typejoin(S::_S, T::_T, args...) where {_S,_T} = typejoin(S, typejoin(T, args...))

vectorize(x::Real) = [x]
vectorize(x::AbstractVector) = x

@inline function softminimum(vals, alpha)
    _vals = vectorize(vals);
    partialsort!(_vals,ceil(Int, alpha*length(_vals)); rev=true)
end

@inline function softmaximum(vals, alpha)
    _vals = vectorize(vals);
    partialsort!(_vals,ceil(Int, alpha*length(_vals)))
end


################################################################################
# I/O utils
################################################################################

# Source: https://stackoverflow.com/questions/46671965/printing-variable-subscripts-in-julia/46674866
# '₀'
subscriptnumber(i::Int) = begin
    join([
        (if i < 0
            [Char(0x208B)]
        else [] end)...,
        [Char(0x2080+d) for d in reverse(digits(abs(i)))]...
    ])
end
# https://www.w3.org/TR/xml-entity-names/020.html
# '․', 'ₑ', '₋'
subscriptnumber(s::AbstractString) = begin
    char_to_subscript(ch) = begin
        if ch == 'e'
            'ₑ'
        elseif ch == '.'
            '․'
        elseif ch == '.'
            '․'
        elseif ch == '-'
            '₋'
        else
            subscriptnumber(parse(Int, ch))
        end
    end

    try
        join(map(char_to_subscript, [string(ch) for ch in s]))
    catch
        s
    end
end

subscriptnumber(i::AbstractFloat) = subscriptnumber(string(i))
subscriptnumber(i::Any) = i


################################################################################
# Others
################################################################################


function minify(d::AbstractVector{T}) where {T<:Union{Number,Missing,Nothing}}
    vals = unique(d)
    n_unique_vals = length(vals)
    new_T = UInt8
    for (nbits, _T) in [(8 => UInt8), (16 => UInt16), (32 => UInt32), (64 => UInt64), (128 => UInt128)]
        if n_unique_vals <= 2^nbits
            new_T = _T
            break
        end
    end
    if new_T == T
        d, identity
    else
        sort!(vals)
        new_d = map((x)->findfirst((v)->(v==x), vals), d)
        # backmap = Dict{T,new_T}([i => v for (i,v) in enumerate(vals)])
        backmap = (x)->vals[x]
        # backmap = vals
        new_d, backmap
    end
end


function minify(d::AbstractVector{<:MID}) where {MID<:Array}
    @assert all((x)->(eltype(x) <: Union{Number,Missing,Nothing}), d)
    vals = unique(Iterators.flatten(d))
    n_unique_vals = length(vals)
    new_T = UInt8
    for (nbits, _T) in [(8 => UInt8), (16 => UInt16), (32 => UInt32), (64 => UInt64), (128 => UInt128)]
        if n_unique_vals <= 2^nbits
            new_T = _T
            break
        end
    end
    sort!(vals)
    new_d = map((x1)->begin
        # new_dict_type = typeintersect(AbstractDict{Int64,Float64},MID{ID,new_T})
        Array{new_T}([findfirst((v)->(v==x2), vals) for x2 in x1])
    end, d)
    # backmap = Dict{T,new_T}([i => v for (i,v) in enumerate(vals)])
    backmap = (x)->vals[x]
    # backmap = vals
    new_d, backmap
end


function minify(d::AbstractVector{<:MID}) where {ID,MID<:Dict{<:ID,T where T<:Union{Number,Missing,Nothing}}}
    vals = unique(Iterators.flatten([values(x) for x in d]))
    n_unique_vals = length(vals)
    new_T = UInt8
    for (nbits, _T) in [(8 => UInt8), (16 => UInt16), (32 => UInt32), (64 => UInt64), (128 => UInt128)]
        if n_unique_vals <= 2^nbits
            new_T = _T
            break
        end
    end
    if new_T == T
        d, identity
    else
        sort!(vals)
        new_d = map((x1)->begin
            # new_dict_type = typeintersect(AbstractDict{Int64,Float64},MID{ID,new_T})
            Dict{ID,new_T}([id => findfirst((v)->(v==x2), vals) for (id, x2) in x1])
        end, d)
        # backmap = Dict{T,new_T}([i => v for (i,v) in enumerate(vals)])
        backmap = (x)->vals[x]
        # backmap = vals
        new_d, backmap
    end
end

# const Minifiable = Union{
#     AbstractArray{T} where {T<:Union{Number,Missing,Nothing}},
#     AbstractArray{<:AbstractArray{T}} where {T<:Union{Number,Missing,Nothing}},
#     AbstractArray{<:MID} where {T<:Union{Number,Missing,Nothing},ID,MID<:Dict{ID,T}},
# }
# const Backmap = Union{
#     Vector{<:Integer}
# }


end
