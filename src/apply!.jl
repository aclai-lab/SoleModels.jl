using ProgressMeter

# function apply!(
#     m::AbstractModel,
#     i::AbstractInterpretation,
#     y;
#     mode = :replace,
#     kwargs...
# ) where {O}
#     @assert mode in [:append, :replace] "Unexpected apply mode: $mode."
#     return apply(m, i; mode = mode, y = y, kwargs...)
# end

# function apply!(
#     m::AbstractModel,
#     d::AbstractInterpretationSet,
#     y::AbstractVector;
#     mode = :replace,
#     kwargs...
# ) where {O}
#     @assert mode in [:append, :replace] "Unexpected apply mode: $mode."
#     return apply(m, d; mode = mode, y = y, kwargs...)
# end


# function apply!(
#     m::AbstractModel,
#     d::AbstractInterpretationSet,
#     i_instance::Integer,
#     y;
#     mode = :replace,
#     kwargs...
# ) where {O}
#     @assert mode in [:append, :replace] "Unexpected apply mode: $mode."
#     return apply(m, d, i_instance; mode = mode, y = y, kwargs...)
# end

function emptysupports!(m)
    haskey(m.info, :supporting_predictions) && empty!(m.info.supporting_predictions)
    empty!(m.info.supporting_labels)
    nothing
end

function recursivelyemptysupports!(m, leavesonly)
    (!leavesonly || (m isa LeafModel)) && emptysupports!(m)
    recursivelyemptysupports!.(immediatesubmodels(m), leavesonly)
    nothing
end

function __apply!(m, mode, preds, y, leavesonly)
    if !leavesonly || m isa LeafModel
        # idxs = filter(i->!isnothing(preds[i]), 1:length(preds))
        # _preds = preds[idxs]
        # _y = y[idxs]
        if mode == :replace
            if haskey(m.info, :supporting_predictions)
                empty!(m.info.supporting_predictions)
                append!(m.info.supporting_predictions, preds)
            end
            empty!(m.info.supporting_labels)
            append!(m.info.supporting_labels, y)
        elseif mode == :append
            if haskey(m.info, :supporting_predictions)
                append!(m.info.supporting_predictions, preds)
            end
            append!(m.info.supporting_labels, y)
        else
            error("Unexpected apply mode: $mode.")
        end
    end
    return preds
end

# function __apply!(m, mode, preds, y)

#     if mode == :replace
#         m.info.supporting_predictions = preds
#         m.info.supporting_labels = y
#         preds
#     elseif mode == :replace
#         m.info.supporting_predictions = [info(m, :supporting_predictions)..., preds...]
#         m.info.supporting_labels = [info(m, :supporting_labels)..., y...]
#         preds
#     else
#         error("Unexpected apply mode: $mode.")
#     end
# end


function apply!(m::AbstractModel, d::Any, y::AbstractVector; kwargs...)
    apply!(m, SoleData.scalarlogiset(d; allow_propositional = true), y; kwargs...)
end

function apply!(m::ConstantModel, d::AbstractInterpretationSet, y::AbstractVector; mode = :replace, leavesonly = false, kwargs...)
    # @assert length(y) == ninstances(d) "$(length(y)) == $(ninstances(d))"
    if mode == :replace
        recursivelyemptysupports!(m, leavesonly)
        mode = :append
    end
    preds = fill(outcome(m), ninstances(d))
    # @show m.info
    # @show y
    return __apply!(m, mode, preds, y, leavesonly)
end


function apply!(m::Rule, d::AbstractInterpretationSet, y::AbstractVector;
    check_args::Tuple = (),
    check_kwargs::NamedTuple = (;),
    mode = :replace,
    leavesonly = false,
    kwargs...)
    # @assert length(y) == ninstances(d) "$(length(y)) == $(ninstances(d))"
    if mode == :replace
        recursivelyemptysupports!(m, leavesonly)
        mode = :append
    end
    checkmask = checkantecedent(m, d, check_args...; check_kwargs...)
    # @show checkmask
    preds = Vector{outputtype(m)}(fill(nothing, ninstances(d)))
    if any(checkmask)
        preds[checkmask] .= apply!(consequent(m), slicedataset(d, checkmask; return_view = true), y[checkmask];
            check_args = check_args,
            check_kwargs = check_kwargs,
            mode = mode,
            leavesonly = leavesonly,
            kwargs...
        )
    end
    return __apply!(m, mode, preds, y, leavesonly)
end


function apply!(m::Branch, d::AbstractInterpretationSet, y::AbstractVector;
    check_args::Tuple = (),
    check_kwargs::NamedTuple = (;),
    mode = :replace,
    leavesonly = false,
    # show_progress = true,
    kwargs...)
    # @assert length(y) == ninstances(d) "$(length(y)) == $(ninstances(d))"
    if mode == :replace
        recursivelyemptysupports!(m, leavesonly)
        mode = :append
    end
    checkmask = checkantecedent(m, d, check_args...; check_kwargs...)
    preds = Vector{outputtype(m)}(undef,length(checkmask))
    @sync begin
        if any(checkmask)
            l = Threads.@spawn apply!(
                posconsequent(m),
                slicedataset(d, checkmask; return_view = true),
                y[checkmask];
                check_args = check_args,
                check_kwargs = check_kwargs,
                mode = mode,
                leavesonly = leavesonly,
                kwargs...
            )
        end
        ncheckmask = (!).(checkmask)
        if any(ncheckmask)
            r = Threads.@spawn apply!(
                negconsequent(m),
                slicedataset(d, ncheckmask; return_view = true),
                y[ncheckmask];
                check_args = check_args,
                check_kwargs = check_kwargs,
                mode = mode,
                leavesonly = leavesonly,
                kwargs...
            )
        end
        if any(checkmask)
            preds[checkmask] .= fetch(l)
        end
        if any(ncheckmask)
            preds[ncheckmask] .= fetch(r)
        end
    end
    return __apply!(m, mode, preds, y, leavesonly)
end


function apply!(m::DecisionTree, d::AbstractInterpretationSet, y::AbstractVector;
    mode = :replace,
    leavesonly = false,
    kwargs...)
    @assert length(y) == ninstances(d) "$(length(y)) == $(ninstances(d))"
    if haskey(info(m), :apply_preprocess)
        apply_preprocess_f = info(m, :apply_preprocess)
        y = apply_preprocess_f.(y)
    end
    # _d = SupportedLogiset(d) TODO?
    preds = apply!(root(m), d, y;
        mode = mode,
        leavesonly = leavesonly,
        kwargs...
    )
    if haskey(info(m), :apply_postprocess)
        apply_postprocess_f = info(m, :apply_postprocess)
        preds = apply_postprocess_f.(preds)
    end
    return __apply!(m, mode, preds, y, leavesonly)
end


function apply!(m::DecisionList{O}, d::AbstractInterpretationSet, y::AbstractVector;
    mode = :replace,
    leavesonly = false,
    show_progress = false, # length(rulebase(m)) > 15,
    kwargs...) where {O}
    # @assert length(y) == ninstances(d) "$(length(y)) == $(ninstances(d))"
    if mode == :replace
        recursivelyemptysupports!(m, leavesonly)
        mode = :append
    end
    nsamp = ninstances(d)
    preds = Vector{outputtype(m)}(undef,nsamp)
    uncovered_idxs = 1:nsamp

    if show_progress
        p = Progress(length(rulebase(m)); dt = 1, desc = "Applying list...")
    end

    for subm in [rulebase(m)..., defaultconsequent(m)]
        length(uncovered_idxs) == 0 && break

        uncovered_d = slicedataset(d, uncovered_idxs; return_view = true)
        
        # @show length(uncovered_idxs)
        cur_preds = apply!(subm, uncovered_d, y[uncovered_idxs], mode = mode, leavesonly = leavesonly, kwargs...)
        idxs_sat = findall(!isnothing, cur_preds)
        # @show cur_preds[idxs_sat]
        preds[uncovered_idxs[idxs_sat]] .= cur_preds[idxs_sat]
        uncovered_idxs = setdiff(uncovered_idxs, uncovered_idxs[idxs_sat])

        !show_progress || next!(p)
    end

    return preds
end


#TODO write in docstring that possible values for compute_metrics are: :append, true, false
function _apply!(
    m::DecisionList{O},
    d::AbstractInterpretationSet;
    check_args::Tuple = (),
    check_kwargs::NamedTuple = (;),
    compute_metrics::Union{Symbol,Bool} = false,
) where {O}
    nsamp = ninstances(d)
    pred = Vector{O}(undef, nsamp)
    delays = Vector{Integer}(undef, nsamp)
    uncovered_idxs = 1:nsamp
    rules = rulebase(m)

    for (n, rule) in enumerate(rules)
        length(uncovered_idxs) == 0 && break

        uncovered_d = slicedataset(d, uncovered_idxs; return_view = true)

        idxs_sat = findall(
            checkantecedent(rule, uncovered_d, check_args...; check_kwargs...)
        )
        idxs_sat = uncovered_idxs[idxs_sat]
        uncovered_idxs = setdiff(uncovered_idxs, idxs_sat)

        delays[idxs_sat] .= (n-1)
        map((i)->(pred[i] = outcome(consequent(rule))), idxs_sat)
    end

    if length(uncovered_idxs) != 0
        map((i)->(pred[i] = outcome(defaultconsequent(m))), uncovered_idxs)
        length(rules) == 0 ? (delays .= 0) : (delays[uncovered_idxs] .= length(rules))
    end

    (length(rules) != 0) && (delays = delays ./ length(rules))

    iprev = info(m)
    inew = compute_metrics == false ? iprev : begin
        if :delays ∉ keys(iprev)
            merge(iprev, (; delays = delays))
        else
            prev = iprev[:delays]
            ntwithout = (; [p for p in pairs(nt) if p[1] != :delays]...)
            if compute_metrics == :append
                merge(ntwithout,(; delays = [prev..., delays...]))
            elseif compute_metrics == true
                merge(ntwithout,(; delays = delays))
            end
        end
    end

    inewnew = begin
        if :pred ∉ keys(inew)
            merge(inew, (; pred = pred))
        else
            prev = inew[:pred]
            ntwithout = (; [p for p in pairs(nt) if p[1] != :pred]...)
            if compute_metrics == :append
                merge(ntwithout,(; pred = [prev..., pred...]))
            elseif compute_metrics == true
                merge(ntwithout,(; pred = pred))
            end
        end
    end

    return DecisionList(rules, defaultconsequent(m), inewnew)
end

# TODO: if delays not in info(m) ?
function _meandelaydl(m::DecisionList)
    i = info(m)

    if :delays in keys(i)
        return mean(i[:delays])
    end
end
