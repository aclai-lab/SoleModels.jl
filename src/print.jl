import Base: display

############################################################################################

# const default_indentation_list_children = "┐"
# const default_indentation_hspace     = " "
# const default_indentation_any_first  = "├" # "╭✔ "
# const default_indentation_any_space  = "│"
# const default_indentation_last_first = "└" # "╰✘ "
# const default_indentation_last_space = " "

const default_indentation_list_children = ""
const default_indentation_hspace     = ""
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


doc_printdisplay_model = """
    printmodel(io::IO, m::AbstractModel; kwargs...)
    displaymodel(m::AbstractModel; kwargs...)

print or returnPa string representation of model `m`.

# Arguments
- `header::Bool = true`: when set to `true`, a header is printed, displaying the `info` structure for `m`;
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

# const DEFAULT_HEADER = :brief
const DEFAULT_HEADER = false

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
    show_shortforms,
    show_intermediate_finals,
    tree_mode,
    show_symbols,
    syntaxstring_kwargs,
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
            show_shortforms = $(esc(show_shortforms)),
            show_intermediate_finals = $(esc(show_intermediate_finals)),
            tree_mode = $(esc(tree_mode)),
            show_symbols = $(esc(show_symbols)),
            syntaxstring_kwargs = $(esc(syntaxstring_kwargs)),
            $(esc(kwargs))...,
        )
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
    digits = 2
)
    metrics = readmetrics(m; digits = digits)
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
    show_metrics = false,
    show_shortforms = false,
    show_intermediate_finals = false,
    tree_mode = false,
    show_symbols = true,
    depth = 0,
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
    depth == 0 && show_symbols && print(io, "▣")
    print(io, " $(outcome(m))")
    show_metrics != false && print(io, " : $(get_metrics_string(m; (show_metrics isa NamedTuple ? show_metrics : [])...))")
    show_shortforms != false && haskey(info(m), :shortform) && print(io, "\t\t\t\t\t\t\tSHORTFORM: $(syntaxstring(info(m)[:shortform]))")
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
    show_metrics = false,
    show_shortforms = false,
    show_intermediate_finals = false,
    tree_mode = false,
    show_symbols = true,
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
    depth == 0 && show_symbols && print(io, "▣")
    print(io, " $(f(m))")
    show_metrics != false && print(io, " : $(get_metrics_string(m; (show_metrics isa NamedTuple ? show_metrics : [])...))")
    show_shortforms != false && haskey(info(m), :shortform) && print(io, "\t\t\t\t\t\t\tSHORTFORM: $(syntaxstring(info(m)[:shortform]))")
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
    show_metrics = false,
    show_shortforms = false,
    show_intermediate_finals = false,
    tree_mode = (subtreeheight(m) != 1),
    show_symbols = true,
    syntaxstring_kwargs = (; parenthesize_atoms = true),
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
    depth == 0 && show_symbols && print(io, "▣")
    ########################################################################################
    if isnothing(max_depth) || depth < max_depth
        pipe = "$(indentation_list_children) "
        # println(io, "$(indentation_str*pipe)$(antecedent(m))")
        #println(io, "$(pipe)$(antecedent(m))")
        if show_intermediate_finals != false && haskey(info(m), :this)
            @warn "One intermediate final was hidden. TODO expand code!"
        end
        ant_str = syntaxstring(antecedent(m); (haskey(info(m), :syntaxstring_kwargs) ? info(m).syntaxstring_kwargs : (;))..., syntaxstring_kwargs..., kwargs...)
        if tree_mode
            show_metrics != false && print(io, "$(pipe)$(get_metrics_string(m; (show_metrics isa NamedTuple ? show_metrics : [])...))")
            show_shortforms != false && haskey(info(m), :shortform) && print(io, "\t\t\t\t\t\t\tSHORTFORM: $(syntaxstring(info(m)[:shortform]))")
            print(io, "$(pipe)$(ant_str)")
            println(io, "")
            pad_str = indentation_str*repeat(indentation_hspace, length(pipe)-length(indentation_last_space)+2)
            print(io, "$(pad_str*indentation_last_first)$(TICK)")
            ind_str = pad_str*indentation_last_space*repeat(indentation_hspace, length(TICK)-length(indentation_last_space)+2)
            @_print_submodel io consequent(m) ind_str indentation depth max_depth show_subtree_info show_metrics show_shortforms show_intermediate_finals tree_mode show_symbols syntaxstring_kwargs kwargs
        else
            line = "$(pipe)$(ant_str)" * "  $(arrow) "
            ind_str = indentation_str * repeat(" ", length(line) + length("▣") + 1)
            if show_metrics != false
                print(io, line)
                _io = IOBuffer()
                @_print_submodel _io consequent(m) ind_str indentation depth max_depth show_subtree_info false show_shortforms show_intermediate_finals tree_mode show_symbols syntaxstring_kwargs kwargs
                subm_str = String(take!(io))
                (subm_str = rstrip(subm_str, '\n') * " : $(get_metrics_string(m; (show_metrics isa NamedTuple ? show_metrics : [])...))")
                print(io, subm_str)
            else
                print(io, line)
                @_print_submodel io consequent(m) ind_str indentation depth max_depth show_subtree_info false show_shortforms show_intermediate_finals tree_mode show_symbols syntaxstring_kwargs kwargs
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
    show_metrics = false,
    show_shortforms = false,
    show_intermediate_finals = false,
    tree_mode = true, # subtreeheight(m) != 1
    show_symbols = true,
    syntaxstring_kwargs = (; parenthesize_atoms = true),
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
    depth == 0 && show_symbols && print(io, "▣")
    ########################################################################################
    if isnothing(max_depth) || depth < max_depth
        pipe = "$(indentation_list_children) "
        line_str = "$(pipe)$(syntaxstring(antecedent(m); (haskey(info(m), :syntaxstring_kwargs) ? info(m).syntaxstring_kwargs : (;))..., syntaxstring_kwargs..., kwargs...))"
        if show_intermediate_finals != false && haskey(info(m), :this)
            ind_str = ""
            show_shortforms != false && haskey(info(m), :shortform) && (line_str = rpad(line_str, "\t\t\t\t\t\t\tSHORTFORM: $(syntaxstring(info(m)[:shortform]))"))
            line_str = rpad(line_str, show_intermediate_finals isa Integer ? show_intermediate_finals : default_intermediate_finals_rpad)
            print(io, line_str)
            @_print_submodel io info(m).this ind_str indentation (depth-1) max_depth show_subtree_info show_metrics show_shortforms show_intermediate_finals tree_mode false syntaxstring_kwargs kwargs
            # show_shortforms != false && haskey(info(m), :shortform) && print(io, "\t\t\t\t\t\t\tSHORTFORM: $(syntaxstring(info(m)[:shortform]))")
        else
            print(io, line_str)
            show_shortforms != false && haskey(info(m), :shortform) && print(io, "\t\t\t\t\t\t\tSHORTFORM: $(syntaxstring(info(m)[:shortform]))")
            println(io)
        end
        for (consequent, indentation_flag_space, indentation_flag_first, f) in [
            (posconsequent(m), indentation_any_space, indentation_any_first, TICK),
            (negconsequent(m), indentation_last_space, indentation_last_first, CROSS)
        ]
            # pad_str = indentation_str*indentation_flag_first**repeat(indentation_hspace, length(pipe)-length(indentation_flag_first))
            pad_str = "$(indentation_str*indentation_flag_first)$(f)"
            print(io, "$(pad_str)")
            ind_str = indentation_str*indentation_flag_space*repeat(indentation_hspace, length(f))
            @_print_submodel io consequent ind_str indentation depth max_depth show_subtree_info show_metrics show_shortforms show_intermediate_finals tree_mode show_symbols syntaxstring_kwargs kwargs
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
    show_metrics = false,
    show_shortforms = false,
    show_intermediate_finals = false,
    tree_mode = true,
    show_symbols = true,
    syntaxstring_kwargs = (; parenthesize_atoms = true),
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
    depth == 0 && show_symbols && print(io, "▣")
    ########################################################################################
    if isnothing(max_depth) || depth < max_depth
        println(io, "$(indentation_list_children)")
        for (i_rule, rule) in enumerate(rulebase(m))
            # pipe = indentation_any_first
            pipe = indentation_any_first*"[$(i_rule)/$(length(rulebase(m)))]┐"
            println(io, "$(indentation_str*pipe)$(syntaxstring(antecedent(rule); (haskey(info(rule), :syntaxstring_kwargs) ? info(rule).syntaxstring_kwargs : (;))..., syntaxstring_kwargs..., kwargs...))")
            pad_str = indentation_str*indentation_any_space*repeat(indentation_hspace, length(pipe)-length(indentation_any_space)-1)
            print(io, "$(pad_str*indentation_last_first)")
            ind_str = pad_str*indentation_last_space
            @_print_submodel io consequent(rule) ind_str indentation depth max_depth show_subtree_info show_metrics show_shortforms show_intermediate_finals tree_mode show_symbols syntaxstring_kwargs kwargs
        end
        pipe = indentation_last_first*"$(CROSS)"
        print(io, "$(indentation_str*pipe)")
        # print(io, "$(indentation_str*indentation_last_space*repeat(indentation_hspace, length(pipe)-length(indentation_last_space)-1)*indentation_last_space)")
        ind_str = indentation_str*indentation_last_space*repeat(indentation_hspace, length(pipe)-length(indentation_last_space)-1)*indentation_last_space
        # ind_str = indentation_str*indentation_last_space,
        @_print_submodel io defaultconsequent(m) ind_str indentation depth max_depth show_subtree_info show_metrics show_shortforms show_intermediate_finals tree_mode show_symbols syntaxstring_kwargs kwargs
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
    show_metrics = false,
    show_shortforms = false,
    show_intermediate_finals = false,
    tree_mode = true,
    show_symbols = true,
    syntaxstring_kwargs = (; parenthesize_atoms = true),
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
    @_print_submodel io root(m) indentation_str indentation (depth-1) max_depth show_subtree_info show_metrics show_shortforms show_intermediate_finals tree_mode show_symbols syntaxstring_kwargs kwargs
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
    show_metrics = false,
    show_shortforms = false,
    show_intermediate_finals = false,
    tree_mode = true,
    show_symbols = true,
    syntaxstring_kwargs = (; parenthesize_atoms = true),
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
    for tree in trees(m)
        @_print_submodel io tree indentation_str indentation (depth-1) max_depth show_subtree_info show_metrics show_shortforms show_intermediate_finals tree_mode show_symbols syntaxstring_kwargs kwargs
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
    show_metrics = false,
    show_shortforms = false,
    show_intermediate_finals = false,
    tree_mode = true,
    show_symbols = true,
    syntaxstring_kwargs = (; parenthesize_atoms = true),
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
    @_print_submodel io root(m) indentation_str indentation (depth-1) max_depth show_subtree_info show_metrics show_shortforms show_intermediate_finals tree_mode show_symbols syntaxstring_kwargs kwargs
    nothing
end
