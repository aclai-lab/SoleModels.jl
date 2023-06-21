############################################################################################
# Ontologies
############################################################################################

# Here are the definitions for world types and relations for known modal logics
#

get_ontology(N::Integer, args...) = get_ontology(Val(N), args...)
get_ontology(::Val{0}, args...) = OneWorldOntology
function get_ontology(::Val{1}, world = :interval, relations::Union{Symbol,AbstractVector{<:AbstractRelation}} = :IA)
    world_possible_values = [:point, :interval, :rectangle, :hyperrectangle]
    relations_possible_values = [:IA, :IA3, :IA7, :RCC5, :RCC8]
    @assert world in world_possible_values "Unexpected value encountered for `world`: $(world). Legal values are in $(world_possible_values)"
    @assert (relations isa AbstractVector{<:AbstractRelation}) || relations in relations_possible_values "Unexpected value encountered for `relations`: $(relations). Legal values are in $(relations_possible_values)"

    if world in [:point]
        error("TODO point-based ontologies not implemented yet")
    elseif world in [:interval, :rectangle, :hyperrectangle]
        if relations isa AbstractVector{<:AbstractRelation}
            Ontology{Interval{Int}}(relations)
        elseif relations == :IA   IntervalOntology
        elseif relations == :IA3  Interval3Ontology
        elseif relations == :IA7  Interval7Ontology
        elseif relations == :RCC8 IntervalRCC8Ontology
        elseif relations == :RCC5 IntervalRCC5Ontology
        else
            error("Unexpected value encountered for `relations`: $(relations). Legal values are in $(relations_possible_values)")
        end
    else
        error("Unexpected value encountered for `world`: $(world). Legal values are in $(possible_values)")
    end
end

function get_ontology(::Val{2}, world = :interval, relations::Union{Symbol,AbstractVector{<:AbstractRelation}} = :IA)
    world_possible_values = [:point, :interval, :rectangle, :hyperrectangle]
    relations_possible_values = [:IA, :RCC5, :RCC8]
    @assert world in world_possible_values "Unexpected value encountered for `world`: $(world). Legal values are in $(world_possible_values)"
    @assert (relations isa AbstractVector{<:AbstractRelation}) || relations in relations_possible_values "Unexpected value encountered for `relations`: $(relations). Legal values are in $(relations_possible_values)"

    if world in [:point]
        error("TODO point-based ontologies not implemented yet")
    elseif world in [:interval, :rectangle, :hyperrectangle]
        if relations isa AbstractVector{<:AbstractRelation}
            Ontology{Interval2D{Int}}(relations)
        elseif relations == :IA   Interval2DOntology
        elseif relations == :RCC8 Interval2DRCC8Ontology
        elseif relations == :RCC5 Interval2DRCC5Ontology
        else
            error("Unexpected value encountered for `relations`: $(relations). Legal values are in $(relations_possible_values)")
        end
    else
        error("Unexpected value encountered for `world`: $(world). Legal values are in $(possible_values)")
    end
end

############################################################################################

get_interval_ontology(N::Integer, args...) = get_interval_ontology(Val(N), args...)
get_interval_ontology(N::Val, relations::Union{Symbol,AbstractVector{<:AbstractRelation}} = :IA) = get_ontology(N, :interval, relations)

############################################################################################
# Worlds
############################################################################################

# Any world type W must provide an `interpret_world` method for interpreting a world
#  onto a modal instance:
# interpret_world(::W, modal_instance)
# Note: for dimensional world types: modal_instance::AbstractArray

############################################################################################
# Dimensionality: 0

# Dimensional world type: it can be interpreted on dimensional instances.
interpret_world(::OneWorld, instance::AbstractArray{T,1}) where {T} = instance

const OneWorldOntology   = Ontology{OneWorld}(AbstractRelation[])

############################################################################################
# Dimensionality: 1

# Dimensional world type: it can be interpreted on dimensional instances.
interpret_world(w::Interval2D, instance::AbstractArray{T,3}) where {T} = instance[w.x.x:w.x.y-1,w.y.x:w.y.y-1,:]

const IntervalOntology       = Ontology{Interval{Int}}(IARelations)
const Interval3Ontology      = Ontology{Interval}(SoleLogics.IA3Relations)
const Interval7Ontology      = Ontology{Interval}(SoleLogics.IA7Relations)

const IntervalRCC8Ontology   = Ontology{Interval{Int}}(RCC8Relations)
const IntervalRCC5Ontology   = Ontology{Interval{Int}}(RCC5Relations)

############################################################################################
# Dimensionality: 2

# Dimensional world type: it can be interpreted on dimensional instances.
interpret_world(w::Interval, instance::AbstractArray{T,2}) where {T} = instance[w.x:w.y-1,:]

const Interval2DOntology     = Ontology{Interval2D{Int}}(IA2DRelations)
const Interval2DRCC8Ontology = Ontology{Interval2D{Int}}(RCC8Relations)
const Interval2DRCC5Ontology = Ontology{Interval2D{Int}}(RCC5Relations)

############################################################################################

# get_ontology(::AbstractDimensionalDataset{T,D}, args...) where {T,D} = get_ontology(Val(D-2), args...)
# get_interval_ontology(::AbstractDimensionalDataset{T,D}, args...) where {T,D} = get_interval_ontology(Val(D-2), args...)
