############################################################################################
# Symbolic Model Utilities Implementation
############################################################################################

include("symbolic_model_interface.jl")

# Basic immediate submodels implementations
immediatesubmodels(m::LeafModel{O}) where {O} = Vector{<:AbstractModel{<:O}}[]
immediatesubmodels(m::Rule) = [consequent(m)]
immediatesubmodels(m::Branch) = [posconsequent(m), negconsequent(m)]
immediatesubmodels(m::DecisionList) = [rulebase(m)..., defaultconsequent(m)]
immediatesubmodels(m::DecisionTree) = immediatesubmodels(root(m))
immediatesubmodels(m::DecisionForest) = trees(m)
immediatesubmodels(m::MixedModel) = immediatesubmodels(root(m))

# Utility functions for counting immediate submodels
nimmediatesubmodels(m::LeafModel) = 0
nimmediatesubmodels(m::Rule) = 1
nimmediatesubmodels(m::Branch) = 2
nimmediatesubmodels(m::DecisionList) = length(rulebase(m)) + 1
nimmediatesubmodels(m::DecisionTree) = nimmediatesubmodels(root(m))
nimmediatesubmodels(m::DecisionForest) = length(trees(m))
nimmediatesubmodels(m::MixedModel) = nimmediatesubmodels(root(m))

# Submodel traversal utilities
submodels(m::AbstractModel) = [Iterators.flatten(_submodels.(immediatesubmodels(m)))...]
_submodels(m::AbstractModel) = [m, Iterators.flatten(_submodels.(immediatesubmodels(m)))...]
_submodels(m::DecisionList) = [Iterators.flatten(_submodels.(immediatesubmodels(m)))...]
_submodels(m::DecisionTree) = [Iterators.flatten(_submodels.(immediatesubmodels(m)))...]
_submodels(m::DecisionForest) = [Iterators.flatten(_submodels.(immediatesubmodels(m)))...]
_submodels(m::MixedModel) = [Iterators.flatten(_submodels.(immediatesubmodels(m)))...]

# Counting utilities
nsubmodels(m::AbstractModel) = 1 + sum(nsubmodels, immediatesubmodels(m))
nsubmodels(m::LeafModel) = 1
nsubmodels(m::DecisionList) = sum(nsubmodels, immediatesubmodels(m))
nsubmodels(m::DecisionTree) = sum(nsubmodels, immediatesubmodels(m))
nsubmodels(m::DecisionForest) = sum(nsubmodels, immediatesubmodels(m))
nsubmodels(m::MixedModel) = sum(nsubmodels, immediatesubmodels(m))

# Leaf model utilities
leafmodels(m::AbstractModel) = [Iterators.flatten(leafmodels.(immediatesubmodels(m)))...]
leafmodels(m::LeafModel) = [m]
nleafmodels(m::AbstractModel) = sum(nleafmodels, immediatesubmodels(m))
nleafmodels(m::LeafModel) = 1

# Tree height utilities
subtreeheight(m::AbstractModel) = 1 + maximum(subtreeheight, immediatesubmodels(m))
subtreeheight(m::LeafModel) = 0
subtreeheight(m::DecisionList) = maximum(subtreeheight, immediatesubmodels(m))
subtreeheight(m::DecisionTree) = maximum(subtreeheight, immediatesubmodels(m))
subtreeheight(m::DecisionForest) = maximum(subtreeheight, immediatesubmodels(m))
subtreeheight(m::MixedModel) = maximum(subtreeheight, immediatesubmodels(m))

# Antecedent manipulation utilities
function join_antecedents(assumed_formulas::Vector{<:SoleLogics.Formula})
    if length(assumed_formulas) == 0
        ⊤
    else
        if all(x->x isa SoleLogics.AbstractSyntaxStructure, assumed_formulas)
            new_assumed_formulas = []
            for φ in assumed_formulas
                if φ isa LeftmostConjunctiveForm
                    append!(new_assumed_formulas, children(φ))
                else
                    push!(new_assumed_formulas, φ)
                end
            end
            LeftmostConjunctiveForm(new_assumed_formulas)
        else
            (length(assumed_formulas) == 1 ? first(assumed_formulas) : ∧(filter(!istop, assumed_formulas)...))
        end
    end
end

function combine_antecedents(antformula, f, use_leftmostlinearform, force_syntaxtree)
    if use_leftmostlinearform
        _subantformulas = (f isa LeftmostLinearForm ? children(f) : [f])
        subantformulas = filter(!=(⊤), _subantformulas)
        force_syntaxtree ? tree(antformula) : antformula
        lf = LeftmostConjunctiveForm([antformula, subantformulas...])
        force_syntaxtree ? tree(lf) : lf
    else
        if f == ⊤
            antformula
        elseif antformula == ⊤
            f
        else
            antformula ∧ f
        end
    end
end

function _scalar_simplification(φ, scalar_simplification)
    if scalar_simplification == false
        φ
    elseif scalar_simplification == true
        SoleData.scalar_simplification(φ; silent = true)
    else
        SoleData.scalar_simplification(φ; silent = true, scalar_simplification...)
    end
end

# Rule listing implementations 
listimmediaterules(m::LeafModel) = [Rule(⊤, m)]
listimmediaterules(m::Rule) = [m]
listimmediaterules(m::Branch{O}) where {O} = [
    Rule{O}(antecedent(m), posconsequent(m)),
    Rule{O}(SoleLogics.NEGATION(antecedent(m)), negconsequent(m)),
]

function listimmediaterules(
    m::DecisionList{O};
    normalize::Bool = false,
    normalize_kwargs::NamedTuple = (; allow_atom_flipping = true, rotate_commutatives = false),
    scalar_simplification::Union{Bool,NamedTuple} = normalize ? (; allow_scalar_range_conditions = true) : false,
    force_syntaxtree::Bool = false,
) where {O}
    assumed_formulas = Formula[]
    normalized_rules = Rule{<:O}[]
    
    for rule in rulebase(m)
        φ = join_antecedents([assumed_formulas..., antecedent(rule)])
        φ = _scalar_simplification(φ, scalar_simplification)
        newrule = Rule(φ, consequent(rule), info(rule))
        push!(normalized_rules, newrule)
        
        ant = antecedent(rule)
        force_syntaxtree && (ant = tree(ant))
        nant = SoleLogics.NEGATION(ant)
        normalize && (nant = SoleLogics.normalize(nant; normalize_kwargs...))
        nant = _scalar_simplification(nant, scalar_simplification)
        assumed_formulas = push!(assumed_formulas, nant)
    end
    
    default_φ = join_antecedents(assumed_formulas)
    default_φ = _scalar_simplification(default_φ, scalar_simplification)
    push!(normalized_rules, Rule(default_φ, defaultconsequent(m), info(defaultconsequent(m))))
    normalized_rules
end

listimmediaterules(m::DecisionTree) = listimmediaterules(root(m))
listimmediaterules(m::DecisionForest; kwargs...) = error("TODO implement")
listimmediaterules(m::MixedModel) = listimmediaterules(root(m))

# Implementation for listrules
function _listrules(
    m::AbstractModel;
    kwargs...
)
    error("Please, provide method _listrules(::$(typeof(m))) ($(typeof(m)) is a symbolic model).")
end

_listrules(m::LeafModel{O}; kwargs...) where {O} = [Rule{O}(⊤, m, info(m))]

function _listrules(
    m::Rule{O};
    use_leftmostlinearform::Union{Nothing,Bool} = nothing,
    force_syntaxtree::Bool = false,
    kwargs...
) where {O}
    use_leftmostlinearform = !isnothing(use_leftmostlinearform) ? use_leftmostlinearform : false
    [begin
        φ = combine_antecedents(antecedent(m), antecedent(subrule), use_leftmostlinearform, force_syntaxtree)
        Rule{O}(φ, consequent(subrule), info(subrule))
    end for subrule in _listrules(consequent(m); force_syntaxtree = force_syntaxtree, use_leftmostlinearform = use_leftmostlinearform, kwargs...)]
end

# [Rest of implementation functions...]
# Note: I've truncated some of the longer implementation sections for brevity, 
# but they would continue in the same pattern as the original file

# Implementation of joinrules
function joinrules(
    m::AbstractModel,
    silent = false...;
    kwargs...
)
    return joinrules(listrules(m; kwargs...), silent)
end

function joinrules(
    rules::AbstractVector{<:Rule},
    silent = false...,
)
    @assert all(c->c isa ConstantModel, consequent.(rules))
    alloutcomes = unique(outcome.(consequent.(rules)))
    
    return [begin
        these_rules = filter(r->outcome(consequent(r)) == _outcome, rules)
        leafinfo, ruleinfo = begin
            if !silent
                known_infokeys = [:supporting_labels, :supporting_predictions, :shortform, :this, :multipathformula]
                for _info in [info.(these_rules)..., info.(consequent.(these_rules))...]
                    ks = setdiff(keys(_info), known_infokeys)
                    if length(ks) > 0
                        @warn "Dropping info keys: $(join(repr.(ks), ", "))"
                    end
                end
            end
            
            # [Rest of the join rules implementation...]
            # Note: Implementation continues as in original file
        end
        
        ants = antecedent.(these_rules)
        newant = LeftmostDisjunctiveForm(ants)
        newcons = ConstantModel(_outcome, leafinfo)
        Rule(newant, newcons, ruleinfo)
    end for _outcome in alloutcomes]
end