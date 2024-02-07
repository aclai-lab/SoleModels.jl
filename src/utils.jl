module utils

using SoleBase
using SoleLogics: syntaxstring
# using SoleLogics: displaysyntaxvector

# export displaysyntaxvector

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

end
