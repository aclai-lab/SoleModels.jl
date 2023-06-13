
"""
Abstract type for one-step memoization structure for checking formulas of type `⟨R⟩ (f ⋈ t)`,
for a generic relation `R`.
"""
abstract type AbstractScalarOneStepRelationalMemoset{W<:AbstractWorld,U,FR<:AbstractFrame{W}} <: AbstractMemoset{W,U,F where F<:AbstractFeature,FR}     end

@inline function Base.getindex(
    memoset      :: AbstractScalarOneStepRelationalMemoset{W},
    i_instance   :: Integer,
    w            :: W,
    i_metacond   :: Integer,
    i_relation   :: Integer
) where {W}
    error("Please, provide method Base.getindex(" *
        "memoset::$(typeof(memoset)), " *
        "i_instance::$(typeof(i_instance)), " *
        "w::$(typeof(w)), " *
        "i_metacond::$(typeof(i_metacond)), " *
        "i_relation::$(typeof(i_relation))" *
    ").")
end

"""
Abstract type for one-step memoization structure for checking "global" formulas
of type `⟨G⟩ (f ⋈ t)`.
"""
abstract type AbstractScalarOneStepGlobalMemoset{W<:AbstractWorld,U} <: AbstractMemoset{W,U,F where F<:AbstractFeature,FR where FR<:AbstractFrame{W}} end

@inline function Base.getindex(
    memoset      :: AbstractScalarOneStepGlobalMemoset{W},
    i_instance   :: Integer,
    i_metacond   :: Integer,
) where {W}
    error("Please, provide method Base.getindex(" *
        "memoset::$(typeof(memoset)), " *
        "i_instance::$(typeof(i_instance)), " *
        "i_metacond::$(typeof(i_metacond))" *
    ").")
end

# Access inner structure
function innerstruct(Xm::Union{AbstractScalarOneStepRelationalMemoset,AbstractScalarOneStepGlobalMemoset})
    error("Please, provide method innerstruct(::$(typeof(Xm))).")
end

isminifiable(::Union{AbstractScalarOneStepRelationalMemoset,AbstractScalarOneStepGlobalMemoset}) = true

function minify(Xm::Union{AbstractScalarOneStepRelationalMemoset,AbstractScalarOneStepGlobalMemoset})
    minify(innerstruct(Xm))
end

############################################################################################
############################################################################################
############################################################################################

# Compute modal dataset propositions and 1-modal decisions
struct ScalarOneStepMemoset{
    U<:Number,
    W<:AbstractWorld,
    FR<:AbstractFrame{W},
    UU<:Union{U,Nothing},
    RM<:AbstractScalarOneStepRelationalMemoset{W,UU,FR},
    GM<:Union{AbstractScalarOneStepGlobalMemoset{W,U},Nothing},
} <: AbstractOneStepMemoset{W,U,F where F<:AbstractFeature,FR}

    metaconditions          :: UniqueVector{<:ScalarMetaCondition}
    relations               :: UniqueVector{<:AbstractRelation}

    # Relational memoset
    relmemoset              :: RM

    # Global memoset
    globmemoset             :: GM

    function ScalarOneStepMemoset(
        metaconditions::AbstractVector{<:ScalarMetaCondition},
        relations::AbstractVector{<:AbstractRelation},
        relmemoset::RM,
        globmemoset::GM,
    ) where {
        U<:Number,
        W<:AbstractWorld,
        FR<:AbstractFrame{W},
        UU<:Union{U,Nothing},
        RM<:AbstractScalarOneStepRelationalMemoset{W,UU,FR},
        GM<:Union{AbstractScalarOneStepGlobalMemoset{W,U},Nothing},
    }
        metaconditions = UniqueVector(metaconditions)
        relations = UniqueVector(relations)

        if globalrel in relations && isnothing(globmemoset)
            @warn "Using global relation in a relational memoset. This is not optimal."
        end

        @assert nmetaconditions(relmemoset) == length(metaconditions)  "Can't instantiate " *
            "$(ty) with mismatching nmetaconditions for relmemoset and " *
            "provided metaconditions: $(nmetaconditions(relmemoset)) and $(length(metaconditions))"
        @assert nrelations(relmemoset) == length(relations)            "Can't instantiate " *
            "$(ty) with mismatching nrelations for relmemoset and " *
            "provided relations: $(nrelations(relmemoset)) and $(length(relations))"

        if !isnothing(globmemoset)
            @assert nmetaconditions(globmemoset) == length(metaconditions) "Can't " *
                "instantiate $(ty) with mismatching nmetaconditions for " *
                "globmemoset and provided metaconditions: " *
                "$(nmetaconditions(globmemoset)) and $(length(metaconditions))"
            @assert ninstances(globmemoset) == ninstances(relmemoset)      "Can't " *
                "instantiate $(ty) with mismatching ninstances for " *
                "globmemoset and relmemoset memoset: " *
                "$(ninstances(globmemoset)) and $(ninstances(relmemoset))"
        end

        new{U,W,FR,UU,RM,GM}(metaconditions, relations, relmemoset, globmemoset)
    end

    Base.@propagate_inbounds function ScalarOneStepMemoset(
        X                       :: AbstractLogiset{W,U},
        metaconditions          :: AbstractVector{<:ScalarMetaCondition},
        relations               :: AbstractVector{<:AbstractRelation},
        relational_memoset_type :: Type{<:AbstractScalarOneStepRelationalMemoset} = default_relmemoset_type(X);
        precompute_globmemoset  :: Bool = true,
        precompute_relmemoset   :: Bool = false,
    ) where {W<:AbstractWorld,U}

        _fwd = fwd(X)

        _features = features(X)
        _grouped_featsnaggrs =  grouped_featsnaggrs(X)
        featsnaggrs = features_grouped_featsaggrsnops2featsnaggrs(features(X), grouped_featsaggrsnops(X))

        compute_globmemoset = begin
            if globalrel in relations
                relations = filter!(l->l≠globalrel, relations)
                true
            else
                false
            end
        end

        _n_instances = ninstances(X)
        nrelations = length(relations)
        nmetaconditions = sum(length.(_grouped_featsnaggrs))

        # Prepare relmemoset
        perform_initialization = !precompute_relmemoset
        relmemoset = relational_memoset_type(X, perform_initialization)

        # Prepare globmemoset
        globmemoset = begin
            if compute_globmemoset
                ScalarOneStepGlobalMemoset(X)
            else
                nothing
            end
        end

        # p = Progress(_n_instances, 1, "Computing EMD supports...")
        Threads.@threads for i_instance in 1:_n_instances
            # @logmsg LogDebug "Instance $(i_instance)/$(_n_instances)"

            # if i_instance == 1 || ((i_instance+1) % (floor(Int, ((_n_instances)/4))+1)) == 0
            #     @logmsg LogOverview "Instance $(i_instance)/$(_n_instances)"
            # end

            for (i_feature,aggregators) in enumerate(_grouped_featsnaggrs)
                feature = _features[i_feature]
                # @logmsg LogDebug "Feature $(i_feature)"

                fwdslice = fwdread_channel(_fwd, i_instance, i_feature)

                # @logmsg LogDebug fwdslice

                # Global relation (independent of the current world)
                if compute_globmemoset && precompute_globmemoset
                    # @logmsg LogDebug "globalrel"

                    # TODO optimize: all aggregators are likely reading the same raw values.
                    for (i_featsnaggr,aggr) in aggregators
                    # Threads.@threads for (i_featsnaggr,aggr) in aggregators

                        gamma = fwdslice_onestep_accessible_aggregation(X, fwdslice, i_instance, globalrel, feature, aggr)

                        # @logmsg LogDebug "Aggregator[$(i_featsnaggr)]=$(aggr)  -->  $(gamma)"

                        globmemoset[i_instance, i_featsnaggr] = gamma
                    end
                end

                if precompute_relmemoset
                    # Other relations
                    for (i_relation,relation) in enumerate(relations)

                        # @logmsg LogDebug "Relation $(i_relation)/$(nrelations)"

                        for (i_featsnaggr,aggr) in aggregators
                            relmemoset_init_world_slice(relmemoset, i_instance, i_featsnaggr, i_relation)
                        end

                        for w in allworlds(X, i_instance)

                            # @logmsg LogDebug "World" w

                            # TODO optimize: all aggregators are likely reading the same raw values.
                            for (i_featsnaggr,aggr) in aggregators

                                gamma = fwdslice_onestep_accessible_aggregation(X, fwdslice, i_instance, w, relation, feature, aggr)

                                # @logmsg LogDebug "Aggregator" aggr gamma

                                relmemoset[i_instance, w, i_featsnaggr, i_relation] = gamma
                            end
                        end
                    end
                end
            end
            # next!(p)
        end
        ScalarOneStepMemoset(relmemoset, globmemoset, featsnaggrs)
    end
end

metaconditions(Xm::ScalarOneStepMemoset) = Xm.metaconditions
relations(Xm::ScalarOneStepMemoset) = Xm.relations
nmetaconditions(Xm::ScalarOneStepMemoset) = length(Xm.metaconditions)
nrelations(Xm::ScalarOneStepMemoset) = length(Xm.relations)

relmemoset(Xm::ScalarOneStepMemoset) = Xm.relmemoset
globmemoset(Xm::ScalarOneStepMemoset) = Xm.globmemoset

ninstances(Xm::ScalarOneStepMemoset) = ninstances(relmemoset(Xm))

function check(
    f::ScalarExistentialFormula,
    Xm::ScalarOneStepMemoset,
    i_instance::Integer,
    w::W;
    kwargs...
) where {W<:AbstractWorld}
    _rel = relation(f)
    _metacond = metacond(f)
    i_metacond = findfirst(isequal(_metacond), Xm.metaconditions)
    if isnothing(i_metacond)
        error("Could not find metacondition $(_metacond) in memoset of type $(typeof(Xm)).")
    end
    gamma = begin
        if _rel
            Base.getindex(globmemoset(Xm), i_instance, i_metacond)
        else
            i_rel = findfirst(isequal(_rel), Xm.relations)
            if isnothing(i_rel)
                error("Could not find relation $(_rel) in memoset of type $(typeof(Xm)).")
            end
            Base.getindex(relmemoset(Xm), i_instance, w, i_metacond, i_rel)
        end
    end
    if !isnothing(gamma)
        return apply_test_operator(test_operator(f), gamma, threshold(f))
    else
        return nothing
    end
end

function instances(Xm::ScalarOneStepMemoset, inds::AbstractVector{<:Integer}, return_view::Union{Val{true},Val{false}} = Val(false))
    ScalarOneStepMemoset(
        metaconditions(Xm),
        relations(Xm),
        instances(relmemoset(Xm), inds, return_view),
        (isnothing(globmemoset(Xm)) ? nothing : instances(globmemoset(Xm), inds, return_view)),
    )
end

function concatdatasets(Xms::ScalarOneStepMemoset...)
    @assert allequal(metaconditions.(Xms)) "Cannot concat " *
        "ScalarOneStepMemoset's with different metaconditions: " *
        "$(@show metaconditions.(Xms))"
    @assert allequal(relations.(Xms)) "Cannot concat " *
        "ScalarOneStepMemoset's with different relations: " *
        "$(@show relations.(Xms))"
    ScalarOneStepMemoset(
        metaconditions(first(Xms)),
        relations(first(Xms)),
        concatdatasets(relmemoset.(Xms)),
        concatdatasets(globmemoset.(Xms)),
    )
end

function hasnans(Xm::ScalarOneStepMemoset)
    hasnans(relmemoset(Xm)) || (!isnothing(globmemoset(Xm)) && hasnans(globmemoset(Xm)))
end

isminifiable(Xm::ScalarOneStepMemoset) = isminifiable(relmemoset(Xm)) && (isnothing(globmemoset(Xm)) || isminifiable(globmemoset(Xm)))

function minify(Xm::OSSD) where {OSSD<:ScalarOneStepMemoset}
    (new_relmemoset, new_globmemoset), backmap =
        minify([
            relmemoset(Xm),
            globmemoset(Xm),
        ])

    Xm = OSSD(
        new_relmemoset,
        new_globmemoset,
        featsnaggrs(Xm),
    )
    Xm, backmap
end

function displaystructure(Xm::ScalarOneStepMemoset; indent_str = "", include_ninstances = true)
    padattribute(l,r) = string(l) * lpad(r,32+length(string(r))-(length(indent_str)+2+length(l))-1)
    pieces = []
    push!(pieces, " \n")

    if include_ninstances
        push!(pieces, " " * padattribute("# instances:", "$(ninstances(Xm))\n"))
    end

    push!(pieces, "$(padattribute("# metaconditions:", nmetaconditions(Xm)))")
    push!(pieces, "$(padattribute("# relations:", nrelations(Xm)))")

    push!(pieces, "$(padattribute("metaconditions:", "$(eltype(metaconditions(Xm)))[$(join(syntaxstring.(metaconditions(Xm))))]", ",")))")
    push!(pieces, "$(padattribute("relations:", relations(Xm)))")

    push!(pieces, " relational memoset ($(round(nonnothingshare(relmemoset(Xm))*100, digits=2))% memoized):\n")
    push!(pieces, " " * displaystructure(relmemoset(Xm); indent_str = "$(indent_str)│ ", include_ninstances = false, include_nmetaconditions = false, include_nrelations = false))
    if !isnothing(globmemoset(Xm))
        push!(pieces, " global memoset ($(round(nonnothingshare(globmemoset(Xm))*100, digits=2))% memoized):\n")
        push!(pieces, " " * displaystructure(globmemoset(Xm); indent_str = "$(indent_str)│ ", include_ninstances = false, include_nmetaconditions = false))
    else
        push!(pieces, " global memoset: −\n")
    end

    return "ScalarOneStepMemoset ($(humansize(Xm)))" *
        join(pieces, "$(indent_str)├", "$(indent_str)└") * "\n"
end

############################################################################################

"""
A generic, one-step memoization structure used for checking specific formulas
of scalar conditions on
datasets with scalar features. The formulas are of type ⟨R⟩ (f ⋈ t)

TODO explain

See also
[`Memoset`](@ref),
[`SuportedLogiset`](@ref),
[`AbstractLogiset`](@ref).
"""
struct ScalarOneStepRelationalMemoset{
    W<:AbstractWorld,
    U,
    FR<:AbstractFrame{W},
    D<:AbstractArray{<:AbstractDict{W,U}, 3},
} <: AbstractScalarOneStepRelationalMemoset{W,U,FR}

    d :: D

    function ScalarOneStepRelationalMemoset{W,U,FR}(
        d::D,
    ) where {W<:AbstractWorld,U,FR<:AbstractFrame{W},D<:AbstractArray{<:AbstractDict{W,U}, 3}}
        new{W,U,FR,D}(d)
    end

    function ScalarOneStepRelationalMemoset(
        X::AbstractLogiset{W,U,F,FR},
        metaconditions::AbstractVector{<:ScalarMetaCondition},
        relations::AbstractVector{<:AbstractRelation},
        perform_initialization = false
    ) where {W,U,F<:AbstractFeature,FR<:AbstractFrame{W}}
        nmetaconditions = length(metaconditions)
        nrelations = length(relations)
        d = begin
            d = Array{Dict{W,U}, 3}(undef, ninstances(X), nmetaconditions, nrelations)
            if perform_initialization
                for idx in eachindex(d)
                    d[idx] = ThreadSafeDict{W,U}()
                end
            end
            d
        end
        ScalarOneStepRelationalMemoset{W,U,FR}(d)
    end
end

innerstruct(Xm::ScalarOneStepRelationalMemoset)     = Xm.d

ninstances(Xm::ScalarOneStepRelationalMemoset)      = size(Xm.d, 1)
nmetaconditions(Xm::ScalarOneStepRelationalMemoset) = size(Xm.d, 2)
nrelations(Xm::ScalarOneStepRelationalMemoset)      = size(Xm.d, 3)

capacity(Xm::ScalarOneStepRelationalMemoset)        = Inf
nmemoizedvalues(Xm::ScalarOneStepRelationalMemoset) = sum(length.(Xm.d))

@inline function Base.getindex(
    Xm           :: ScalarOneStepRelationalMemoset{W},
    i_instance   :: Integer,
    w            :: W,
    i_metacond   :: Integer,
    i_relation   :: Integer
) where {W<:AbstractWorld}
    get(Xm.d[i_instance, i_metacond, i_relation], w, nothing)
end

usesfullmemo(::ScalarOneStepRelationalMemoset) = false

function hasnans(Xm::ScalarOneStepRelationalMemoset)
    any(map(d->(any(_isnan.(collect(values(d))))), Xm.d))
end

function instances(Xm::ScalarOneStepRelationalMemoset{W,U,FR}, inds::AbstractVector{<:Integer}, return_view::Union{Val{true},Val{false}} = Val(false)) where {W,U,FR}
    ScalarOneStepRelationalMemoset{W,U,FR}(if return_view == Val(true) @view Xm.d[inds,:,:] else Xm.d[inds,:,:] end)
end

function concatdatasets(Xms::ScalarOneStepRelationalMemoset...)
    ScalarOneStepRelationalMemoset(cat([Xm.d for Xm in Xms]...; dims=1))
end


function displaystructure(Xm::ScalarOneStepRelationalMemoset; indent_str = "", include_ninstances = true, include_nmetaconditions = true, include_nrelations = true)
    padattribute(l,r) = string(l) * lpad(r,32+length(string(r))-(length(indent_str)+2+length(l)))
    pieces = []
    push!(pieces, "$(padattribute("worldtype:", worldtype(Xm)))")
    push!(pieces, "$(padattribute("featvaltype:", featvaltype(Xm)))")
    push!(pieces, "$(padattribute("featuretype:", featuretype(Xm)))")
    push!(pieces, "$(padattribute("frametype:", frametype(Xm)))")
    if include_ninstances
        push!(pieces, "$(padattribute("# instances:", ninstances(Xm)))")
    end
    if include_nmetaconditions
        push!(pieces, "$(padattribute("# metaconditions:", nmetaconditions(Xm)))")
    end
    if include_nrelations
        push!(pieces, "$(padattribute("# relations:", nrelations(Xm)))")
    end
    push!(pieces, "$(padattribute("# memoized values:", nmemoizedvalues(Xm)))")

    return "ScalarOneStepRelationalMemoset ($(humansize(Xm)))" *
        join(pieces, "\n$(indent_str)├ ", "\n$(indent_str)└ ") * "\n"
end

# fwd_rs_init_world_slice(Xm::ScalarOneStepRelationalMemoset{W,U}, i_instance::Integer, i_featsnaggr::Integer, i_relation::Integer) where {W,U} =
#     Xm.d[i_instance, i_featsnaggr, i_relation] = Dict{W,U}()
# @inline function Base.setindex!(Xm::ScalarOneStepRelationalMemoset{W,U}, threshold::U, i_instance::Integer, w::AbstractWorld, i_featsnaggr::Integer, i_relation::Integer) where {W,U}
#     Xm.d[i_instance, i_featsnaggr, i_relation][w] = threshold
# end

############################################################################################

# Note: the global Xm is world-agnostic
struct ScalarOneStepGlobalMemoset{
    W<:AbstractWorld,
    U,
    D<:AbstractArray{UU,2} where {UU<:Union{U,Nothing}}
} <: AbstractScalarOneStepGlobalMemoset{W,U}

    d :: D

    function ScalarOneStepGlobalMemoset{W,U}(
        d::D
    ) where {W<:AbstractWorld,U,D<:AbstractArray{UU,2} where {UU<:Union{U,Nothing}}
        new{W,U,D}(d)
    end

    function ScalarOneStepGlobalMemoset(
        X::AbstractLogiset{W,U},
        metaconditions::AbstractVector{<:ScalarMetaCondition},
        perform_initialization = false
    ) where {W<:AbstractWorld,U}
        @assert worldtype(X) != OneWorld "TODO adjust this note: note that you should not use a global Xm when not using global decisions"
        nmetaconditions = length(metaconditions)
        d = Array{Union{U,Nothing},2}(undef, ninstances(X), length(metaconditions))
        if perform_initialization
            fill!(d, nothing)
        end
        ScalarOneStepGlobalMemoset{W,U}(d)
    end
end

innerstruct(Xm::ScalarOneStepGlobalMemoset)     = Xm.d

ninstances(Xm::ScalarOneStepGlobalMemoset)      = size(Xm.d, 1)
nmetaconditions(Xm::ScalarOneStepGlobalMemoset) = size(Xm.d, 2)

capacity(Xm::ScalarOneStepGlobalMemoset)        = prod(size(Xm.d))
nmemoizedvalues(Xm::ScalarOneStepGlobalMemoset) = sum((!).((isnothing).(Xm.d)))

@inline function Base.getindex(
    Xm           :: ScalarOneStepRelationalMemoset{W},
    i_instance   :: Integer,
    i_metacond   :: Integer,
) where {W<:AbstractWorld}
    Xm.d[i_instance, i_metacond]
end

usesfullmemo(::ScalarOneStepGlobalMemoset) = false

function hasnans(Xm::ScalarOneStepGlobalMemoset)
    # @show any(_isnan.(Xm.d))
    any(_isnan.(Xm.d))
end

function instances(Xm::ScalarOneStepGlobalMemoset{W,U}, inds::AbstractVector{<:Integer}, return_view::Union{Val{true},Val{false}} = Val(false)) where {W,U}
    ScalarOneStepGlobalMemoset{W,U}(if return_view == Val(true) @view Xm.d[inds,:] else Xm.d[inds,:] end)
end

function concatdatasets(Xms::ScalarOneStepGlobalMemoset...)
    ScalarOneStepGlobalMemoset(cat([Xm.d for Xm in Xms]...; dims=1))
end


function displaystructure(Xm::ScalarOneStepGlobalMemoset; indent_str = "", include_ninstances = true, include_nmetaconditions = true)
    padattribute(l,r) = string(l) * lpad(r,32+length(string(r))-(length(indent_str)+2+length(l)))
    pieces = []
    push!(pieces, "$(padattribute("worldtype:", worldtype(Xm)))")
    push!(pieces, "$(padattribute("featvaltype:", featvaltype(Xm)))")
    push!(pieces, "$(padattribute("featuretype:", featuretype(Xm)))")
    push!(pieces, "$(padattribute("frametype:", frametype(Xm)))")
    if include_ninstances
        push!(pieces, "$(padattribute("# instances:", ninstances(Xm)))")
    end
    if include_nmetaconditions
        push!(pieces, "$(padattribute("# metaconditions:", nmetaconditions(Xm)))")
    end
    push!(pieces, "$(padattribute("capacity:", capacity(Xm)))")
    push!(pieces, "$(padattribute("# memoized values:", nmemoizedvalues(Xm)))")

    return "ScalarOneStepGlobalMemoset ($(humansize(Xm)))" *
        join(pieces, "\n$(indent_str)├ ", "\n$(indent_str)└ ") * "\n"
end

