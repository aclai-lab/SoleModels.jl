
function check(
    φ::SoleLogics.AbstractFormula,
    X::MultiLogiset,
    i_modality::Integer,
    i_instance::Integer,
    args...;
    kwargs...,
)
    check(φ, modality(X, i_modality), i_instance, args...; kwargs...)
end

function check(
    φ::SoleLogics.AbstractFormula,
    X::AbstractLogiset,
    i_instance::Integer;
    kwargs...
)
    check(tree(φ), X, i_instance; kwargs...)
end

function check(
    φ::SoleLogics.SyntaxTree,
    X::AbstractLogiset{W,U},
    i_instance::Integer,
    w::Union{Nothing,W,AbstractVector{<:W}} = nothing;
    use_memo::Union{Nothing,AbstractMemoset{W},AbstractVector{<:AbstractDict{<:F,<:WorldSet}}} = nothing,
    perform_normalization::Bool = true,
    memo_max_height::Union{Nothing,Int} = nothing,
) where {W<:AbstractWorld,U,F<:SoleLogics.AbstractFormula}

    if isnothing(w)
        # w = SoleLogics.initialworld(X, i_instance)
        w = nothing
    elseif w isa AbstractVector
        w = w[i_instance]
    end
    @assert SoleLogics.isglobal(φ) || !isnothing(w) "Cannot check non-global formula with no initialworld(s): $(syntaxstring(φ))."

    setformula(memo_structure::AbstractDict{<:AbstractFormula}, φ::AbstractFormula, val) = memo_structure[SoleLogics.tree(φ)] = val
    readformula(memo_structure::AbstractDict{<:AbstractFormula}, φ::AbstractFormula) = memo_structure[SoleLogics.tree(φ)]
    hasformula(memo_structure::AbstractDict{<:AbstractFormula}, φ::AbstractFormula) = haskey(memo_structure, SoleLogics.tree(φ))

    setformula(memo_structure::AbstractMemoset, φ::AbstractFormula, val) = Base.setindex!(memo_structure, i_instance, SoleLogics.tree(φ), val)
    readformula(memo_structure::AbstractMemoset, φ::AbstractFormula) = Base.getindex(memo_structure, i_instance, SoleLogics.tree(φ))
    hasformula(memo_structure::AbstractMemoset, φ::AbstractFormula) = haskey(memo_structure, i_instance, SoleLogics.tree(φ))

    X, memo_structure = begin
        if X isa SupportedLogiset && usesfullmemo(X)
            if !isnothing(use_memo)
                @warn "Dataset of type $(typeof(X)) uses full memoization, " *
                    "but a memoization structure was provided to check(...)."
            end
            base(X), fullmemo(X)
        elseif isnothing(use_memo)
            X, ThreadSafeDict{SyntaxTree,WorldSet{W}}()
        elseif use_memo isa AbstractMemoset
            X, use_memo[i_instance]
        else
            X, use_memo[i_instance]
        end
    end

    # if X isa SupportedLogiset
    #     X = base(X)
    # end

    if !isnothing(memo_max_height)
        forget_list = Vector{SoleLogics.SyntaxTree}()
    end

    if perform_normalization
        φ = normalize(φ; profile = :modelchecking)
    end

    fr = frame(X, i_instance)

    if !hasformula(memo_structure, φ)
        for ψ in unique(SoleLogics.subformulas(φ))
            # @show ψ
            if !isnothing(memo_max_height) && height(ψ) > memo_max_height
                push!(forget_list, ψ)
            end
            if !hasformula(memo_structure, ψ)
                tok = token(ψ)
                setformula(memo_structure, ψ, begin
                    if tok isa SoleLogics.AbstractOperator
                        collect(SoleLogics.collateworlds(fr, tok, map(f->readformula(memo_structure, f), children(ψ))))
                    elseif tok isa Proposition
                        filter(w->check(tok, X, i_instance, w), collect(allworlds(fr)))
                    else
                        error("Unexpected token encountered in _check: $(typeof(tok))")
                    end
                end)
            end
            # @show syntaxstring(ψ), readformula(memo_structure, ψ)
        end
    end

    if !isnothing(memo_max_height)
        for ψ in forget_list
            delete!(memo_structure, ψ)
        end
    end

    ret = begin
        if isnothing(w)
            length(readformula(memo_structure, φ)) > 0
        else
            w in readformula(memo_structure, φ)
        end
    end

    return ret
end
