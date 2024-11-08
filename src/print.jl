import Base: display

############################################################################################

# const default_indentation_list_children = "┐"
# const default_indentation_hspace     = " "
# const default_indentation_any_first  = "├" # "╭✔ "
# const default_indentation_any_space  = "│"
# const default_indentation_last_first = "└" # "╰✘ "
# const default_indentation_last_space = " "

const default_indentation_list_children = ""
const default_indentation_hspace     = " "
const default_indentation_any_first  = "├" # "╭✔ "
const default_indentation_any_space  = "│"
const default_indentation_last_first = "└" # "╰✘ "
const default_indentation_last_space = " "

# const TICK = "✅"
# const TICK = "✔️"
# const TICK = "☑"
const TICK = "✔"
# const TICK = "🟩"
# const CROSS = "❎"
# const CROSS = "❌"
# const CROSS = "☒"
# const CROSS = "〤"
const CROSS = "✘"

const MODEL_SYMBOL = "\e[34m▣\e[0m"
# const MODEL_SYMBOL = "▣"

# TODO figure out what is the expected behaviour of show_symbols = false, and comply with it?

const default_intermediate_finals_rpad = 100

const default_indentation = (
    default_indentation_list_children,
    default_indentation_hspace,
    default_indentation_any_first,
    default_indentation_any_space,
    default_indentation_last_first,
    default_indentation_last_space,
)

############################################################################################

Base.show(io::IO, m::AbstractModel) = printmodel(io, m)
Base.show(io::IO, ::MIME"text/plain", m::AbstractModel) = printmodel(io, m)


# const DEFAULT_HEADER = :brief
const DEFAULT_HEADER = false

doc_printdisplay_model = """
    printmodel(io::IO, m::AbstractModel; kwargs...)
    displaymodel(m::AbstractModel; kwargs...)

print or return a string representation of model `m`.

# Arguments
- `header::Bool = $(DEFAULT_HEADER)`: when set to `true`, a header is printed, displaying the `info` structure for `m`;
- `show_subtree_info::Bool = false`: when set to `true`, the header is printed for models in the sub-tree of `m`;
- `show_metrics::Bool = false`: when set to `true`, performance metrics at each point of the subtree are shown, whenever they are available in the `info` structure;
- `max_depth::Union{Nothing,Int} = nothing`: when it is an `Int`, models in the sub-tree with a depth higher than `max_depth` are ellipsed with "...";
- `syntaxstring_kwargs::NamedTuple = (;)`: kwargs to be passed to `syntaxstring` for formatting logical formulas.

See also [`syntaxstring`](@ref), [`AbstractModel`](@ref).
"""

"""$(doc_printdisplay_model)"""
printmodel(m::AbstractModel; kwargs...) = printmodel(stdout, m; kwargs...)

"""$(doc_printdisplay_model)"""
function displaymodel(m::AbstractModel; kwargs...)
    io = IOBuffer()
    printmodel(io, m; kwargs...)
    String(take!(io))
end

# function printmodel(io::IO, m::AbstractModel; kwargs...)
#     println(io, displaymodel(m; kwargs...))
# end

# Utility macro for recursively displaying submodels
macro _print_submodel(
    io,
    submodel,
    indentation_str,
    indentation,
    depth,
    max_depth,
    show_subtree_info,
    show_metrics,
    show_subtree_metrics,
    show_shortforms,
    show_intermediate_finals,
    tree_mode,
    show_symbols,
    syntaxstring_kwargs,
    parenthesize_atoms,
    kwargs
)
    quote
        printmodel($(esc(io)), $(esc(submodel));
            indentation_str = $(esc(indentation_str)),
            indentation = $(esc(indentation)),
            depth = $(esc(depth))+1,
            max_depth = $(esc(max_depth)),
            header = $(esc(show_subtree_info)),
            show_subtree_info = $(esc(show_subtree_info)),
            show_metrics = $(esc(show_metrics)),
            show_subtree_metrics = $(esc(show_subtree_metrics)),
            show_shortforms = $(esc(show_shortforms)),
            show_intermediate_finals = $(esc(show_intermediate_finals)),
            tree_mode = $(esc(tree_mode)),
            show_symbols = $(esc(show_symbols)),
            syntaxstring_kwargs = $(esc(syntaxstring_kwargs)),
            parenthesize_atoms = $(esc(parenthesize_atoms)),
            $(esc(kwargs))...,
        )
    end
end


macro _antecedent_syntaxstring(φ, m, parenthesize_atoms, syntaxstring_kwargs, kwargs)
    quote
        syntaxstring($(esc(φ)); get(info($(esc(m))), :syntaxstring_kwargs, (;))..., parenthesize_atoms = $(esc(parenthesize_atoms)), $(esc(syntaxstring_kwargs))..., $(esc(kwargs))...)
    end
end

# function displaymodel(
#     m::AbstractModel;
#     kwargs...
# )
#     _displaymodel(m; kwargs...)
# end

# function _displaymodel(
#     m::AbstractModel;
#     kwargs...,
# )
#     println("Please, provide method _displaymodel(::$(typeof(m)); kwargs...). " *
#         "See help for displaymodel.")
# end

############################################################################################
############################################################################################
############################################################################################

function get_metrics_string(
    m::AbstractModel;
    round_digits = 2,
    kwargs...
)
    metrics = readmetrics(m; round_digits = round_digits, kwargs...)
    if m isa LeafModel
        metrics = (; filter(((k,v),)->k != :coverage, [k => metrics[k] for k in keys(metrics)])...)
    end
    "$(metrics)"
end

function printmodel(
    io::IO,
    m::ConstantModel;
    header = DEFAULT_HEADER,
    indentation_str = "",
    show_subtree_info = false,
    show_subtree_metrics = false,
    show_metrics = false,
    show_shortforms = false,
    show_intermediate_finals = false,
    tree_mode = false,
    show_symbols = true,
    depth = 0,
    syntaxstring_kwargs = (;),
    parenthesize_atoms = true,
    kwargs...,
)
    if header != false
        _typestr = string(header == true ? typeof(m) :
            header == :brief ? nameof(typeof(m)) :
                error("Unexpected value for parameter header: $(header).")
        )
        println(io, "$(indentation_str)$(_typestr)$((length(info(m)) == 0) ?
        "" : "\n$(indentation_str)Info: $(info(m))")")
    end
    depth == 0 && show_symbols && print(io, MODEL_SYMBOL)
    print(io, " $(outcome(m))")
    (show_subtree_metrics || show_metrics != false) && print(io, " : $(get_metrics_string(m; (show_metrics isa NamedTuple ? show_metrics : [])...))")
    show_shortforms != false && haskey(info(m), :shortform) && print(io, "\t\t\t\t\t\t\tSHORTFORM: $(@_antecedent_syntaxstring info(m)[:shortform] m parenthesize_atoms syntaxstring_kwargs kwargs)")
    println(io, "")
    nothing
end

function printmodel(
    io::IO,
    m::FunctionModel;
    header = DEFAULT_HEADER,
    indentation_str = "",
    depth = 0,
    show_subtree_info = false,
    show_subtree_metrics = false,
    show_metrics = false,
    show_shortforms = false,
    show_intermediate_finals = false,
    tree_mode = false,
    show_symbols = true,
    syntaxstring_kwargs = (;),
    parenthesize_atoms = true,
    kwargs...,
)
    if header != false
        _typestr = string(header == true ? typeof(m) :
            header == :brief ? nameof(typeof(m)) :
                error("Unexpected value for parameter header: $(header).")
        )
        println(io, "$(indentation_str)$(_typestr)$((length(info(m)) == 0) ?
        "" : "\n$(indentation_str)Info: $(info(m))")")
    end
    depth == 0 && show_symbols && print(io, MODEL_SYMBOL)
    print(io, " $(f(m))")
    (show_subtree_metrics || show_metrics != false) && print(io, " : $(get_metrics_string(m; (show_metrics isa NamedTuple ? show_metrics : [])...))")
    show_shortforms != false && haskey(info(m), :shortform) && print(io, "\t\t\t\t\t\t\tSHORTFORM: $(@_antecedent_syntaxstring info(m)[:shortform] m parenthesize_atoms syntaxstring_kwargs kwargs)")
    println(io, "")
    nothing
end

function printmodel(
    io::IO,
    m::Rule;
    header = DEFAULT_HEADER,
    indentation_str = "",
    indentation = default_indentation,
    depth = 0,
    max_depth = nothing,
    show_subtree_info = false,
    show_subtree_metrics = false,
    show_metrics = false,
    show_shortforms = false,
    show_intermediate_finals = false,
    tree_mode = (subtreeheight(m) != 1),
    show_symbols = true,
    syntaxstring_kwargs = (;),
    #
    parenthesize_atoms = true,
    arrow = "↣", # "🠮", # ⮞, 🡆, 🠮, 🠲, =>
    kwargs...,
)
    (
        indentation_list_children,
        indentation_hspace,
        indentation_any_first,
        indentation_any_space,
        indentation_last_first,
        indentation_last_space
    ) = indentation
    if header != false
        _typestr = string(header == true ? typeof(m) :
            header == :brief ? nameof(typeof(m)) :
                error("Unexpected value for parameter header: $(header).")
        )
        println(io, "$(indentation_str)$(_typestr)$((length(info(m)) == 0) ?
        "" : "\n$(indentation_str)Info: $(info(m))")")
    end
    depth == 0 && show_symbols && print(io, MODEL_SYMBOL)
    ########################################################################################
    if isnothing(max_depth) || depth < max_depth
        pipe = "$(indentation_list_children) "
        # println(io, "$(indentation_str*pipe)$(antecedent(m))")
        #println(io, "$(pipe)$(antecedent(m))")
        if show_intermediate_finals != false && haskey(info(m), :this)
            @warn "One intermediate final was hidden. TODO expand code!"
        end
        ant_str =@_antecedent_syntaxstring antecedent(m) m parenthesize_atoms syntaxstring_kwargs kwargs
        if tree_mode
            show_shortforms != false && haskey(info(m), :shortform) && print(io, "\t\t\t\t\t\t\tSHORTFORM: $(@_antecedent_syntaxstring info(m)[:shortform] m parenthesize_atoms syntaxstring_kwargs kwargs)")
            print(io, "$(pipe)$(ant_str)")
            (show_subtree_metrics || show_metrics != false) && print(io, " : $(get_metrics_string(m; (show_metrics isa NamedTuple ? show_metrics : [])...))")
            println(io, "")
            pad_str = indentation_str*repeat(indentation_hspace, length(pipe)-length(indentation_last_space)+2)
            print(io, "$(pad_str*indentation_last_first)$(TICK)")
            ind_str = pad_str*indentation_last_space*repeat(indentation_hspace, length(TICK)-length(indentation_last_space)+2)
            @_print_submodel io consequent(m) ind_str indentation depth max_depth show_subtree_info false show_subtree_metrics show_shortforms show_intermediate_finals tree_mode show_symbols syntaxstring_kwargs parenthesize_atoms kwargs
            println(io, "")
        else
            line = "$(pipe)$(ant_str)" * "  $(arrow) "
            ind_str = indentation_str * repeat(" ", length(line) + length(MODEL_SYMBOL) + 1)
            if (show_subtree_metrics || show_metrics != false)
                print(io, line)
                _io = IOBuffer()
                @_print_submodel _io consequent(m) ind_str indentation depth max_depth show_subtree_info false show_subtree_metrics show_shortforms show_intermediate_finals tree_mode show_symbols syntaxstring_kwargs parenthesize_atoms kwargs
                subm_str = String(take!(_io))
                (subm_str = rstrip(subm_str, '\n') * " : $(get_metrics_string(m; (show_metrics isa NamedTuple ? show_metrics : [])...))")
                print(io, subm_str)
                println(io, "")
            else
                print(io, line)
                @_print_submodel io consequent(m) ind_str indentation depth max_depth show_subtree_info false show_subtree_metrics show_shortforms show_intermediate_finals tree_mode show_symbols syntaxstring_kwargs parenthesize_atoms kwargs
            end
        end
    else
        depth != 0 && print(io, " ")
        println(io, "[...]")
    end
    nothing
end

function printmodel(
    io::IO,
    m::Branch;
    header = DEFAULT_HEADER,
    indentation_str = "",
    indentation = default_indentation,
    depth = 0,
    max_depth = nothing,
    show_subtree_info = false,
    show_subtree_metrics = false,
    show_metrics = false,
    show_shortforms = false,
    show_intermediate_finals = false,
    tree_mode = true, # subtreeheight(m) != 1
    show_symbols = true,
    syntaxstring_kwargs = (;),
    #
    parenthesize_atoms = true,
    kwargs...,
)
    (
        indentation_list_children,
        indentation_hspace,
        indentation_any_first,
        indentation_any_space,
        indentation_last_first,
        indentation_last_space
    ) = indentation
    if header != false
        _typestr = string(header == true ? typeof(m) :
            header == :brief ? nameof(typeof(m)) :
                error("Unexpected value for parameter header: $(header).")
        )
        println(io, "$(indentation_str)$(_typestr)$((length(info(m)) == 0) ?
        "" : "\n$(indentation_str)Info: $(info(m))")")
    end
    depth == 0 && show_symbols && print(io, MODEL_SYMBOL)
    ########################################################################################
    if isnothing(max_depth) || depth < max_depth
        pipe = "$(indentation_list_children) "
        ss =@_antecedent_syntaxstring antecedent(m) m parenthesize_atoms syntaxstring_kwargs kwargs
        line_str = "$(pipe)$(ss)"
        if show_intermediate_finals != false && haskey(info(m), :this)
            ind_str = ""
            show_shortforms != false && haskey(info(m), :shortform) && (line_str = rpad(line_str, "\t\t\t\t\t\t\tSHORTFORM: $(@_antecedent_syntaxstring info(m)[:shortform] m parenthesize_atoms syntaxstring_kwargs kwargs)"))
            line_str = rpad(line_str, show_intermediate_finals isa Integer ? show_intermediate_finals : default_intermediate_finals_rpad)
            print(io, line_str)
            @_print_submodel io info(m).this ind_str indentation (depth-1) max_depth show_subtree_info show_metrics show_subtree_metrics show_shortforms show_intermediate_finals tree_mode false syntaxstring_kwargs parenthesize_atoms kwargs
            # show_shortforms != false && haskey(info(m), :shortform) && print(io, "\t\t\t\t\t\t\tSHORTFORM: $(@_antecedent_syntaxstring info(m)[:shortform] m parenthesize_atoms syntaxstring_kwargs kwargs)")
        else
            print(io, line_str)
            show_shortforms != false && haskey(info(m), :shortform) && print(io, "\t\t\t\t\t\t\tSHORTFORM: $(@_antecedent_syntaxstring info(m)[:shortform] m parenthesize_atoms syntaxstring_kwargs kwargs)")
            println(io)
        end
        for (consequent, indentation_flag_space, indentation_flag_first, f) in [
            (posconsequent(m), indentation_any_space, indentation_any_first, TICK),
            (negconsequent(m), indentation_last_space, indentation_last_first, CROSS)
        ]
            # pad_str = indentation_str*indentation_flag_first**repeat(indentation_hspace, length(pipe)-length(indentation_flag_first))
            pad_str = "$(indentation_str*indentation_flag_first)$(f)"
            print(io, "$(pad_str)")

            (show_subtree_metrics) && print(io, " : $(get_metrics_string(m; (show_metrics isa NamedTuple ? show_metrics : [])...))")
            ind_str = indentation_str*indentation_flag_space*repeat(indentation_hspace, length(f))
            @_print_submodel io consequent ind_str indentation depth max_depth show_subtree_info show_metrics show_subtree_metrics show_shortforms show_intermediate_finals tree_mode show_symbols syntaxstring_kwargs parenthesize_atoms kwargs
        end
    else
        depth != 0 && print(io, " ")
        println(io, "[...]")
    end
    nothing
end


function printmodel(
    io::IO,
    m::DecisionList;
    header = DEFAULT_HEADER,
    indentation_str = "",
    indentation = default_indentation,
    depth = 0,
    max_depth = nothing,
    show_subtree_info = false,
    show_rule_metrics = true,
    show_subtree_metrics = false,
    show_metrics = false,
    show_shortforms = false,
    show_intermediate_finals = false,
    tree_mode = false,
    show_symbols = true,
    syntaxstring_kwargs = (;),
    #
    parenthesize_atoms = true,
    kwargs...,
)
    (
        indentation_list_children,
        indentation_hspace,
        indentation_any_first,
        indentation_any_space,
        indentation_last_first,
        indentation_last_space
    ) = indentation
    if header != false
        _typestr = string(header == true ? typeof(m) :
            header == :brief ? nameof(typeof(m)) :
                error("Unexpected value for parameter header: $(header).")
        )
        println(io, "$(indentation_str)$(_typestr)$((length(info(m)) == 0) ?
        "" : "\n$(indentation_str)Info: $(info(m))")")
    end
    depth == 0 && show_symbols && print(io, MODEL_SYMBOL)
    ########################################################################################
    _show_rule_metrics = show_rule_metrics
    # TODO show this metrics if show_metrics
    ########################################################################################
    if isnothing(max_depth) || depth < max_depth
        println(io, "$(indentation_list_children)")
        for (i_rule, rule) in enumerate(rulebase(m))
            # pipe = indentation_any_first
            pipe = indentation_any_first*"[$(i_rule)/$(length(rulebase(m)))]┐"
            # println(io, "$(indentation_str*pipe)$(syntaxstring(antecedent(rule); (haskey(info(rule), :syntaxstring_kwargs) ? info(rule).syntaxstring_kwargs : (;))..., syntaxstring_kwargs..., parenthesize_atoms = parenthesize_atoms, kwargs...))")
            pad_str = indentation_str*indentation_any_space*repeat(indentation_hspace, length(pipe)-length(indentation_any_space)-1)
            # print(io, "$(pad_str*indentation_last_first)")
            ind_str = pad_str*indentation_last_space
            # @_print_submodel io consequent(rule) ind_str indentation depth max_depth show_subtree_info false show_subtree_metrics show_shortforms show_intermediate_finals tree_mode show_symbols syntaxstring_kwargs parenthesize_atoms kwargs
            print(io, pipe)
            @_print_submodel io rule ind_str indentation depth max_depth show_subtree_info _show_rule_metrics show_subtree_metrics show_shortforms show_intermediate_finals tree_mode show_symbols syntaxstring_kwargs parenthesize_atoms kwargs
        end
        pipe = indentation_last_first*"$(CROSS)"
        print(io, "$(indentation_str*pipe)")
        # print(io, "$(indentation_str*indentation_last_space*repeat(indentation_hspace, length(pipe)-length(indentation_last_space)-1)*indentation_last_space)")
        ind_str = indentation_str*indentation_last_space*repeat(indentation_hspace, length(pipe)-length(indentation_last_space)-1)*indentation_last_space
        # ind_str = indentation_str*indentation_last_space,
        @_print_submodel io defaultconsequent(m) ind_str indentation depth max_depth show_subtree_info _show_rule_metrics show_subtree_metrics show_shortforms show_intermediate_finals tree_mode show_symbols syntaxstring_kwargs parenthesize_atoms kwargs
    else
        depth != 0 && print(io, " ")
        println(io, "[...]")
    end
    nothing
end

function printmodel(
    io::IO,
    m::DecisionTree;
    header = DEFAULT_HEADER,
    indentation_str = "",
    indentation = default_indentation,
    depth = 0,
    max_depth = nothing,
    show_subtree_info = false,
    show_subtree_metrics = false,
    show_metrics = false,
    show_shortforms = false,
    show_intermediate_finals = false,
    tree_mode = true,
    show_symbols = true,
    syntaxstring_kwargs = (;),
    #
    parenthesize_atoms = true,
    kwargs...,
)
    (
        indentation_list_children,
        indentation_hspace,
        indentation_any_first,
        indentation_any_space,
        indentation_last_first,
        indentation_last_space
    ) = indentation
    if header != false
        _typestr = string(header == true ? typeof(m) :
            header == :brief ? nameof(typeof(m)) :
                error("Unexpected value for parameter header: $(header).")
        )
        println(io, "$(indentation_str)$(_typestr)$((length(info(m)) == 0) ?
        "" : "\n$(indentation_str)Info: $(info(m))")")
    end

    ########################################################################################
    @_print_submodel io root(m) indentation_str indentation (depth-1) max_depth show_subtree_info show_metrics show_subtree_metrics show_shortforms show_intermediate_finals tree_mode show_symbols syntaxstring_kwargs parenthesize_atoms kwargs
    nothing
end

function printmodel(
    io::IO,
    m::DecisionForest;
    header = DEFAULT_HEADER,
    indentation_str = "",
    indentation = default_indentation,
    depth = 0,
    max_depth = nothing,
    show_subtree_info = false,
    show_rule_metrics = true,
    show_subtree_metrics = false,
    show_metrics = false,
    show_shortforms = false,
    show_intermediate_finals = false,
    tree_mode = true,
    show_symbols = true,
    syntaxstring_kwargs = (;),
    #
    parenthesize_atoms = true,
    kwargs...,
)
    (
        indentation_list_children,
        indentation_hspace,
        indentation_any_first,
        indentation_any_space,
        indentation_last_first,
        indentation_last_space
    ) = indentation
    if header != false
        _typestr = string(header == true ? typeof(m) :
            header == :brief ? nameof(typeof(m)) :
                error("Unexpected value for parameter header: $(header).")
        )
        println(io, "$(indentation_str)$(_typestr)$((length(info(m)) == 0) ?
        "" : "\n$(indentation_str)Info: $(info(m))")")
    end

    ########################################################################################
    depth == 0 && show_symbols && print(io, "$(MODEL_SYMBOL) Forest of $(ntrees(m)) trees")
    if isnothing(max_depth) || depth < max_depth
        _show_rule_metrics = show_rule_metrics
        println(io, "$(indentation_list_children)")
        for (i_tree, tree) in enumerate(trees(m))
            if i_tree < ntrees(m)
                pipe = indentation_any_first*"[$i_tree/$(ntrees(m))]┐"
                pad_str = indentation_str*indentation_any_space*repeat(indentation_hspace, length(pipe)-length(indentation_any_space)-1-1)
                ind_str = pad_str*indentation_last_space
            else
                pipe = indentation_last_first*"[$i_tree/$(ntrees(m))]┐"
                ind_str = indentation_str*indentation_last_space*repeat(indentation_hspace, length(pipe)-length(indentation_last_space)-1-1)*indentation_last_space
            end
            print(io, pipe)
            
            @_print_submodel io tree ind_str indentation depth max_depth show_subtree_info _show_rule_metrics show_subtree_metrics show_shortforms show_intermediate_finals tree_mode show_symbols syntaxstring_kwargs parenthesize_atoms kwargs
        end
    else
        depth != 0 && print(io, " ")
        println(io, "[...]")
    end
    
    nothing
end

function printmodel(
    io::IO,
    m::MixedModel;
    header = DEFAULT_HEADER,
    indentation_str = "",
    indentation = default_indentation,
    depth = 0,
    max_depth = nothing,
    show_subtree_info = false,
    show_subtree_metrics = false,
    show_metrics = false,
    show_shortforms = false,
    show_intermediate_finals = false,
    tree_mode = true,
    show_symbols = true,
    syntaxstring_kwargs = (;),
    #
    parenthesize_atoms = true,
    kwargs...,
)
    (
        indentation_list_children,
        indentation_hspace,
        indentation_any_first,
        indentation_any_space,
        indentation_last_first,
        indentation_last_space
    ) = indentation
    if header != false
        _typestr = string(header == true ? typeof(m) :
            header == :brief ? nameof(typeof(m)) :
                error("Unexpected value for parameter header: $(header).")
        )
        println(io, "$(indentation_str)$(_typestr)$((length(info(m)) == 0) ?
        "" : "\n$(indentation_str)Info: $(info(m))")")
    end

    ########################################################################################
    @_print_submodel io root(m) indentation_str indentation (depth-1) max_depth show_subtree_info false show_subtree_metrics show_shortforms show_intermediate_finals tree_mode show_symbols syntaxstring_kwargs parenthesize_atoms kwargs
    nothing
end
