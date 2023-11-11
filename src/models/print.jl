import Base: display

############################################################################################

# default_indentation_list_children = "┐"
# default_indentation_hspace     = " "
# default_indentation_any_first  = "├" # "╭✔ "
# default_indentation_any_space  = "│"
# default_indentation_last_first = "└" # "╰✘ "
# default_indentation_last_space = " "

default_indentation_list_children = ""
default_indentation_hspace     = ""
default_indentation_any_first  = "├" # "╭✔ "
default_indentation_any_space  = "│"
default_indentation_last_first = "└" # "╰✘ "
default_indentation_last_space = " "

# TICK = "✅"
# TICK = "✔️"
# TICK = "☑"
TICK = "✔"
# TICK = "🟩"
# CROSS = "❎"
# CROSS = "❌"
# CROSS = "☒"
# CROSS = "〤"
CROSS = "✘"


default_intermediate_finals_rpad = 100

default_indentation = (
    default_indentation_list_children,
    default_indentation_hspace,
    default_indentation_any_first,
    default_indentation_any_space,
    default_indentation_last_first,
    default_indentation_last_space,
)

############################################################################################

Base.show(io::IO, m::AbstractModel) = print(io, displaymodel(m))
Base.show(io::IO, ::MIME"text/plain", m::AbstractModel) = printmodel(io, m)


doc_printdisplay_model = """
    printmodel(io::IO, m::AbstractModel; kwargs...)
    displaymodel(m::AbstractModel; kwargs...)

prints or returns a string representation of model `m`.

# Arguments
- `header::Bool = true`: when set to `true`, a header is printed, displaying
 the `info` structure for `m`;
- `show_subtree_info::Bool = false`: when set to `true`, the header is printed for
models in the sub-tree of `m`;
- `show_metrics::Bool = false`: when set to `true`, performance metrics at each point of the
subtree are shown, whenever they are available in the `info` structure;
- `max_depth::Union{Nothing,Int} = nothing`: when it is an `Int`, models in the sub-tree
with a depth higher than `max_depth` are ellipsed with "...";
- `syntaxstring_kwargs::NamedTuple = (;)`: kwargs to be passed to `syntaxstring` for
formatting logical formulas.

See also [`syntaxstring`](@ref), [`AbstractModel`](@ref).
"""

"""$(doc_printdisplay_model)"""
function printmodel(io::IO, m::AbstractModel; kwargs...)
    println(io, displaymodel(m; kwargs...))
end
printmodel(m::AbstractModel; kwargs...) = printmodel(stdout, m; kwargs...)

# DEFAULT_HEADER = :brief
DEFAULT_HEADER = false

# Utility macro for recursively displaying submodels
macro _display_submodel(
    submodel,
    indentation_str,
    indentation,
    depth,
    max_depth,
    show_subtree_info,
    show_metrics,
    show_intermediate_finals,
    tree_mode,
    syntaxstring_kwargs,
    kwargs
)
    quote
        _displaymodel($(esc(submodel));
            indentation_str = $(esc(indentation_str)),
            indentation = $(esc(indentation)),
            depth = $(esc(depth))+1,
            max_depth = $(esc(max_depth)),
            header = $(esc(show_subtree_info)),
            show_subtree_info = $(esc(show_subtree_info)),
            show_metrics = $(esc(show_metrics)),
            show_intermediate_finals = $(esc(show_intermediate_finals)),
            tree_mode = $(esc(tree_mode)),
            syntaxstring_kwargs = $(esc(syntaxstring_kwargs)),
            $(esc(kwargs))...,
        )
    end
end

"""$(doc_printdisplay_model)"""
function displaymodel(
    m::AbstractModel;
    kwargs...
)
    _displaymodel(m; kwargs...)
end

function _displaymodel(
    m::AbstractModel;
    kwargs...,
)
    println("Please, provide method _displaymodel(::$(typeof(m)); kwargs...). " *
        "See help for displaymodel.")
end

############################################################################################
############################################################################################
############################################################################################

function get_metrics_string(
    m::AbstractModel;
    digits = 2
)
    "$(readmetrics(m; digits = digits))"
end

function _displaymodel(
    m::ConstantModel;
    header = DEFAULT_HEADER,
    indentation_str = "",
    show_subtree_info = false,
    show_metrics = false,
    show_intermediate_finals = false,
    tree_mode = false,
    depth = 0,
    kwargs...,
)
    io = IOBuffer()
    if header != false
        _typestr = string(header == true ? typeof(m) :
            header == :brief ? nameof(typeof(m)) :
                error("Unexpected value for parameter header: $(header).")
        )
        println(io, "$(indentation_str)$(_typestr)$((length(info(m)) == 0) ?
        "" : "\n$(indentation_str)Info: $(info(m))")")
    end
    depth == 0 && print(io, "▣")
    print(io, " $(outcome(m))")
    show_metrics != false && print(io, " : $(get_metrics_string(m; (show_metrics isa NamedTuple ? show_metrics : [])...))")
    println(io, "")
    String(take!(io))
end

function _displaymodel(
    m::FunctionModel;
    header = DEFAULT_HEADER,
    indentation_str = "",
    show_subtree_info = false,
    show_metrics = false,
    show_intermediate_finals = false,
    tree_mode = false,
    kwargs...,
)
    io = IOBuffer()
    if header != false
        _typestr = string(header == true ? typeof(m) :
            header == :brief ? nameof(typeof(m)) :
                error("Unexpected value for parameter header: $(header).")
        )
        println(io, "$(indentation_str)$(_typestr)$((length(info(m)) == 0) ?
        "" : "\n$(indentation_str)Info: $(info(m))")")
    end
    depth == 0 && print(io, "▣")
    print(io, "$(f(m))")
    show_metrics != false && print(io, " : $(get_metrics_string(m; (show_metrics isa NamedTuple ? show_metrics : [])...))")
    println(io, "")
    String(take!(io))
end

function _displaymodel(
    m::Rule;
    header = DEFAULT_HEADER,
    indentation_str = "",
    indentation = default_indentation,
    depth = 0,
    max_depth = nothing,
    show_subtree_info = false,
    show_metrics = false,
    show_intermediate_finals = false,
    tree_mode = (subtreeheight(m) != 1),
    syntaxstring_kwargs = (; parenthesize_atoms = true),
    arrow = "🠮", # ⮞, 🡆, 🠮, 🠲, =>
    kwargs...,
)
    io = IOBuffer()
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
    depth == 0 && print(io, "▣")
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
            print(io, "$(pipe)$(ant_str)")
            println(io, "")
            pad_str = indentation_str*repeat(indentation_hspace, length(pipe)-length(indentation_last_space)+2)
            print(io, "$(pad_str*indentation_last_first)$(TICK)")
            ind_str = pad_str*indentation_last_space*repeat(indentation_hspace, length(TICK)-length(indentation_last_space)+2)
            subm_str = @_display_submodel consequent(m) ind_str indentation depth max_depth show_subtree_info show_metrics show_intermediate_finals tree_mode syntaxstring_kwargs kwargs
            print(io, subm_str)
        else
            line = "$(pipe)$(ant_str)" * "  $(arrow) "
            ind_str = indentation_str * repeat(" ", length(line) + length("▣") + 1)
            subm_str = @_display_submodel consequent(m) ind_str indentation depth max_depth show_subtree_info false show_intermediate_finals tree_mode syntaxstring_kwargs kwargs
            show_metrics != false && (subm_str = rstrip(subm_str, '\n') * " : $(get_metrics_string(m; (show_metrics isa NamedTuple ? show_metrics : [])...))")
            print(io, line)
            print(io, subm_str)
        end
    else
        depth != 0 && print(io, " ")
        println(io, "[...]")
    end
    String(take!(io))
end

function _displaymodel(
    m::Branch;
    header = DEFAULT_HEADER,
    indentation_str = "",
    indentation = default_indentation,
    depth = 0,
    max_depth = nothing,
    show_subtree_info = false,
    show_metrics = false,
    show_intermediate_finals = false,
    tree_mode = true, # subtreeheight(m) != 1
    syntaxstring_kwargs = (; parenthesize_atoms = true),
    kwargs...,
)
    io = IOBuffer()
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
    depth == 0 && print(io, "▣")
    ########################################################################################
    if isnothing(max_depth) || depth < max_depth
        pipe = "$(indentation_list_children) "
        line_str = "$(pipe)$(syntaxstring(antecedent(m); (haskey(info(m), :syntaxstring_kwargs) ? info(m).syntaxstring_kwargs : (;))..., syntaxstring_kwargs..., kwargs...))"
        if show_intermediate_finals != false && haskey(info(m), :this)
            ind_str = ""
            subm_str = @_display_submodel info(m).this ind_str indentation (depth-1) max_depth show_subtree_info show_metrics show_intermediate_finals tree_mode syntaxstring_kwargs kwargs
            line_str = rpad(line_str, show_intermediate_finals isa Integer ? show_intermediate_finals : default_intermediate_finals_rpad) * subm_str
            print(io, line_str)
        else
            println(io, line_str)
        end
        for (consequent, indentation_flag_space, indentation_flag_first, f) in [
            (posconsequent(m), indentation_any_space, indentation_any_first, TICK),
            (negconsequent(m), indentation_last_space, indentation_last_first, CROSS)
        ]
            # pad_str = indentation_str*indentation_flag_first**repeat(indentation_hspace, length(pipe)-length(indentation_flag_first))
            pad_str = "$(indentation_str*indentation_flag_first)$(f)"
            print(io, "$(pad_str)")
            ind_str = indentation_str*indentation_flag_space*repeat(indentation_hspace, length(f))
            subm_str = @_display_submodel consequent ind_str indentation depth max_depth show_subtree_info show_metrics show_intermediate_finals tree_mode syntaxstring_kwargs kwargs
            print(io, subm_str)
        end
    else
        depth != 0 && print(io, " ")
        println(io, "[...]")
    end
    String(take!(io))
end


function _displaymodel(
    m::DecisionList;
    header = DEFAULT_HEADER,
    indentation_str = "",
    indentation = default_indentation,
    depth = 0,
    max_depth = nothing,
    show_subtree_info = false,
    show_metrics = false,
    show_intermediate_finals = false,
    tree_mode = true,
    syntaxstring_kwargs = (; parenthesize_atoms = true),
    kwargs...,
)
    io = IOBuffer()
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
    depth == 0 && print(io, "▣")
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
            subm_str = @_display_submodel consequent(rule) ind_str indentation depth max_depth show_subtree_info show_metrics show_intermediate_finals tree_mode syntaxstring_kwargs kwargs
            print(io, subm_str)
        end
        pipe = indentation_last_first*"$(CROSS)"
        print(io, "$(indentation_str*pipe)")
        # print(io, "$(indentation_str*indentation_last_space*repeat(indentation_hspace, length(pipe)-length(indentation_last_space)-1)*indentation_last_space)")
        ind_str = indentation_str*indentation_last_space*repeat(indentation_hspace, length(pipe)-length(indentation_last_space)-1)*indentation_last_space
        # ind_str = indentation_str*indentation_last_space,
        subm_str = @_display_submodel defaultconsequent(m) ind_str indentation depth max_depth show_subtree_info show_metrics show_intermediate_finals tree_mode syntaxstring_kwargs kwargs
        print(io, subm_str)
    else
        depth != 0 && print(io, " ")
        println(io, "[...]")
    end
    String(take!(io))
end

function _displaymodel(
    m::DecisionTree;
    header = DEFAULT_HEADER,
    indentation_str = "",
    indentation = default_indentation,
    depth = 0,
    max_depth = nothing,
    show_subtree_info = false,
    show_metrics = false,
    show_intermediate_finals = false,
    tree_mode = true,
    syntaxstring_kwargs = (; parenthesize_atoms = true),
    kwargs...,
)
    io = IOBuffer()
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
    subm_str = @_display_submodel root(m) indentation_str indentation (depth-1) max_depth show_subtree_info show_metrics show_intermediate_finals tree_mode syntaxstring_kwargs kwargs
    print(io, subm_str)
    String(take!(io))
end

function _displaymodel(
    m::DecisionForest;
    header = DEFAULT_HEADER,
    indentation_str = "",
    indentation = default_indentation,
    depth = 0,
    max_depth = nothing,
    show_subtree_info = false,
    show_metrics = false,
    show_intermediate_finals = false,
    tree_mode = true,
    syntaxstring_kwargs = (; parenthesize_atoms = true),
    kwargs...,
)
    io = IOBuffer()
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
        subm_str = @_display_submodel tree indentation_str indentation (depth-1) max_depth show_subtree_info show_metrics show_intermediate_finals tree_mode syntaxstring_kwargs kwargs
        print(io, subm_str)
    end
    String(take!(io))
end

function _displaymodel(
    m::MixedSymbolicModel;
    header = DEFAULT_HEADER,
    indentation_str = "",
    indentation = default_indentation,
    depth = 0,
    max_depth = nothing,
    show_subtree_info = false,
    show_metrics = false,
    show_intermediate_finals = false,
    tree_mode = true,
    syntaxstring_kwargs = (; parenthesize_atoms = true),
    kwargs...,
)
    io = IOBuffer()
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
    subm_str = @_display_submodel root(m) indentation_str indentation (depth-1) max_depth show_subtree_info show_metrics show_intermediate_finals tree_mode syntaxstring_kwargs kwargs
    print(io, subm_str)
    String(take!(io))
end
