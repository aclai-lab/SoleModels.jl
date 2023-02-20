
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
