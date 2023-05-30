

@inline function check(
    p::Proposition{<:ScalarCondition},
    X::AbstractScalarLogiset{W},
    i_sample::Integer,
    w::W,
) where {W<:AbstractWorld}
    c = atom(p)
    apply_test_operator(SoleModels.test_operator(c), X[i_sample, w, SoleModels.feature(c)], SoleModels.threshold(c))
end


# TODO fix: SyntaxTree{A} and SyntaxTree{B} are different, but they should not be.
# getindex(::AbstractDictionary{I, T}, ::I) --> T
# keys(::AbstractDictionary{I, T}) --> AbstractIndices{I}
# isassigned(::AbstractDictionary{I, T}, ::I) --> Bool
# TODO fix?
# hasformula(memo_structure::AbstractDict{F}, φ::SyntaxTree) where {F<:AbstractFormula} = haskey(memo_structure, SoleLogics.tree(φ))
hasformula(memo_structure::AbstractDict{F}, φ::AbstractFormula) where {F<:AbstractFormula} = haskey(memo_structure, φ)
hasformula(memo_structure::AbstractDict{SyntaxTree}, φ::AbstractFormula) = haskey(memo_structure, SoleLogics.tree(φ))

function check(
    φ::SoleLogics.AbstractFormula,
    X::AbstractLogiset{W,<:AbstractFeature,<:Number,FR},
    i_sample::Integer;
    initialworld::Union{Nothing,W,AbstractVector{<:W}} = SoleLogics.initialworld(X, i_sample),
    # use_memo::Union{Nothing,AbstractVector{<:AbstractDict{<:F,<:T}}} = nothing,
    # use_memo::Union{Nothing,AbstractVector{<:AbstractDict{<:F,<:WorldSet{W}}}} = nothing,
    use_memo::Union{Nothing,AbstractVector{<:AbstractDict{<:F,<:WorldSet}}} = nothing,
    # memo_max_height = Inf,
) where {W<:AbstractWorld,T<:Bool,FR<:AbstractMultiModalFrame{W,T},F<:SoleLogics.AbstractFormula}

    @assert SoleLogics.isglobal(φ) || !isnothing(initialworld) "Cannot check non-global formula with no initialworld(s): $(syntaxstring(φ))."

    memo_structure = begin
        if isnothing(use_memo)
            ThreadSafeDict{SyntaxTree,WorldSet{W}}()
        else
            use_memo[i_sample]
        end
    end

    # forget_list = Vector{SoleLogics.FNode}()
    # hasmemo(::AbstractLogiset) = false
    # hasmemo(X)TODO

    # φ = normalize(φ; profile = :modelchecking) # TODO normalize formula and/or use a dedicate memoization structure that normalizes functions

    fr = frame(X, i_sample)

    # TODO avoid using when memo is nothing
    if !hasformula(memo_structure, φ)
        for ψ in unique(SoleLogics.subformulas(φ))
            # @show ψ
            # @show syntaxstring(ψ)
            # if height(ψ) > memo_max_height
            #     push!(forget_list, ψ)
            # end
            if !hasformula(memo_structure, ψ)
                tok = token(ψ)
                memo_structure[ψ] = begin
                    if tok isa SoleLogics.AbstractOperator
                        collect(SoleLogics.collateworlds(fr, tok, map(f->memo_structure[f], children(ψ))))
                    elseif tok isa Proposition
                        filter(w->check(tok, X, i_sample, w), collect(allworlds(fr)))
                    else
                        error("Unexpected token encountered in _check: $(typeof(tok))")
                    end
                end
            end
            # @show syntaxstring(ψ), memo_structure[ψ]
        end
    end

    # # All the worlds where a given formula is valid are returned.
    # # Then, internally, memoization-regulation is applied
    # # to forget some formula thus freeing space.
    # fcollection = deepcopy(memo(X))
    # for h in forget_list
    #     k = fhash(h)
    #     if hasformula(memo_structure, k)
    #         empty!(memo(X, k)) # Collection at memo(X)[k] is erased
    #         pop!(memo(X), k)    # Key k is deallocated too
    #     end
    # end

    ret = begin
        if isnothing(initialworld)
            length(memo_structure[φ]) > 0
        else
            initialworld in memo_structure[φ]
        end
    end

    return ret
end

############################################################################################

# function compute_chained_threshold(
#     φ::SoleLogics.AbstractFormula,
#     X::SupportedScalarLogiset{V,W,FR},
#     i_sample;
#     use_memo::Union{Nothing,AbstractVector{<:AbstractDict{F,T}}} = nothing,
# ) where {V<:Number,W<:AbstractWorld,T<:Bool,FR<:AbstractMultiModalFrame{W,T},F<:SoleLogics.AbstractFormula}

#     @assert SoleLogics.isglobal(φ) "TODO expand code to specifying a world, defaulted to an initialworld. Cannot check non-global formula: $(syntaxstring(φ))."

#     memo_structure = begin
#         if isnothing(use_memo)
#             ThreadSafeDict{SyntaxTree,V}()
#         else
#             use_memo[i_sample]
#         end
#     end

#     # φ = normalize(φ; profile = :modelchecking) # TODO normalize formula and/or use a dedicate memoization structure that normalizes functions

#     fr = frame(X, i_sample)

#     if !hasformula(memo_structure, φ)
#         for ψ in unique(SoleLogics.subformulas(φ))
#             if !hasformula(memo_structure, ψ)
#                 tok = token(ψ)
#                 memo_structure[ψ] = begin
#                     if tok isa AbstractRelationalOperator && length(children(φ)) == 1 && height(φ) == 1
#                         featcond = atom(token(children(φ)[1]))
#                         if tok isa DiamondRelationalOperator
#                             # (L) f > a <-> max(acc) > a
#                             onestep_accessible_aggregation(X, i_sample, w, relation(tok), feature(featcond), existential_aggregator(test_operator(featcond)))
#                         elseif tok isa BoxRelationalOperator
#                             # [L] f > a  <-> min(acc) > a <-> ! (min(acc) <= a) <-> ¬ <L> (f <= a)
#                             onestep_accessible_aggregation(X, i_sample, w, relation(tok), feature(featcond), universal_aggregator(test_operator(featcond)))
#                         else
#                             error("Unexpected operator encountered in onestep_collateworlds: $(typeof(tok))")
#                         end
#                     else
#                         TODO
#                     end
#                 end
#             end
#             # @show syntaxstring(ψ), memo_structure[ψ]
#         end
#     end

#     # # All the worlds where a given formula is valid are returned.
#     # # Then, internally, memoization-regulation is applied
#     # # to forget some formula thus freeing space.
#     # fcollection = deepcopy(memo(X))
#     # for h in forget_list
#     #     k = fhash(h)
#     #     if hasformula(memo_structure, k)
#     #         empty!(memo(X, k)) # Collection at memo(X)[k] is erased
#     #         pop!(memo(X), k)    # Key k is deallocated too
#     #     end
#     # end

#     return memo_structure[φ]
# end
