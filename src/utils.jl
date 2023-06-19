module utils

using SoleLogics: syntaxstring

export displaysyntaxvector

using SoleBase

@inline function softminimum(vals, alpha)
    _vals = SoleBase.vectorize(vals);
    partialsort!(_vals,ceil(Int, alpha*length(_vals)); rev=true)
end

@inline function softmaximum(vals, alpha)
    _vals = SoleBase.vectorize(vals);
    partialsort!(_vals,ceil(Int, alpha*length(_vals)))
end


############################################################################################
# I/O utils
############################################################################################

# Source: https://stackoverflow.com/questions/46671965/printing-variable-subscripts-in-julia/46674866
# '₀'
function subscriptnumber(i::Integer)
    join([
        (if i < 0
            [Char(0x208B)]
        else [] end)...,
        [Char(0x2080+d) for d in reverse(digits(abs(i)))]...
    ])
end
# https://www.w3.org/TR/xml-entity-names/020.html
# '․', 'ₑ', '₋'
function subscriptnumber(s::AbstractString)
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

function displaysyntaxvector(a, maxnum = 8)
    els = begin
        if length(a) > maxnum
            [(syntaxstring.(a)[1:div(maxnum, 2)])..., "...", syntaxstring.(a)[end-div(maxnum, 2):end]...]
        else
            syntaxstring.(a)
        end
    end
    "$(eltype(a))[$(join(map(e->"\"$(e)\"", els), ", "))]"
end

end

# https://discourse.julialang.org/t/groupby-function/9896

"""
    group items of list l according to the corresponding values in list v

    julia> _groupby([31,28,31,30,31,30,31,31,30,31,30,31],
           [:Jan,:Feb,:Mar,:Apr,:May,:Jun,:Jul,:Aug,:Sep,:Oct,:Nov,:Dec])
    Dict{Int64,Array{Symbol,1}} with 3 entries:
        31 => Symbol[:Jan, :Mar, :May, :Jul, :Aug, :Oct, :Dec]
        28 => Symbol[:Feb]
        30 => Symbol[:Apr, :Jun, :Sep, :Nov]

"""
function _groupby(v::AbstractVector, l::AbstractVector)
  @assert length(v) == length(l) "$(@show v, l)"
  res = Dict{eltype(v),Vector{eltype(l)}}()
  for (k, val) in zip(v, l)
    push!(get!(res, k, similar(l, 0)), val)
  end
  res
end

"""
    group items of list l according to the values taken by function f on them

    julia> _groupby(iseven,1:10)
    Dict{Bool,Array{Int64,1}} with 2 entries:
        false => [1, 3, 5, 7, 9]
        true  => [2, 4, 6, 8, 10]

Note:in this version l is required to be non-empty since I do not know how to
access the return type of a function
"""
function _groupby(f,l::AbstractVector)
  res = Dict(f(l[1]) => [l[1]]) # l should be nonempty
  for val in l[2:end]
    push!(get!(res, f(val), similar(l, 0)), val)
  end
  res
end
