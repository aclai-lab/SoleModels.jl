import Base: display

############################################################################################

default_indentation_list_children = "┐"
default_indentation_any_first  = "├ " # "╭✔ "
default_indentation_any_space  = "│ "
default_indentation_last_first = "└ " # "╰✘ "
default_indentation_last_space = "  "

default_indentation = (
    default_indentation_list_children,
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
- `max_depth::Union{Nothing,Int} = nothing`: when it is an `Int`, models in the sub-tree
with a depth higher than `max_depth` are ellipsed with "...";
- `syntaxstring_kwargs::NamedTuple = (;)`: kwargs to be passed to `syntaxstring` for
formatting logical formulas.

See also [`SoleLogics.syntaxstring`](@ref), [`AbstractModel`](@ref).
"""

"""$(doc_printdisplay_model)"""
function printmodel(io::IO, m::AbstractModel; kwargs...)
    println(io, displaymodel(m; kwargs...))
end
printmodel(m::AbstractModel; kwargs...) = printmodel(stdout, m; kwargs...)

"""$(doc_printdisplay_model)"""
function displaymodel(
    m::AbstractModel;
    header = :brief,
    indentation_str = "",
    indentation = default_indentation,
    depth = 0,
    max_depth = nothing,
    show_subtree_info = false,
    syntaxstring_kwargs = (;),
)
    println("Please, provide method displaymodel(::$(typeof(m)); kwargs...)." *
        " See help for displaymodel.")
end

############################################################################################
############################################################################################
############################################################################################

# Utility macro for recursively displaying submodels
macro _display_submodel(
    submodel,
    indentation_str,
    indentation,
    depth,
    max_depth,
    show_subtree_info,
    syntaxstring_kwargs,
    kwargs
)
    quote
        displaymodel($(esc(submodel));
            indentation_str = $(esc(indentation_str)),
            indentation = $(esc(indentation)),
            header = $(esc(show_subtree_info)),
            show_subtree_info = $(esc(show_subtree_info)),
            depth = $(esc(depth))+1,
            max_depth = $(esc(max_depth)),
            syntaxstring_kwargs = $(esc(syntaxstring_kwargs)),
            $(esc(kwargs))...,
        )
    end
end

function displaymodel(
    m::ConstantModel;
    header = :brief,
    indentation_str = "",
    show_subtree_info = false,
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
    println(io, "$(outcome(m))")
    String(take!(io))
end

function displaymodel(
    m::FunctionModel;
    header = :brief,
    indentation_str = "",
    show_subtree_info = false,
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
    println(io, "$(f(m))")
    String(take!(io))
end

function displaymodel(
    m::Rule;
    header = :brief,
    indentation_str = "",
    indentation = default_indentation,
    depth = 0,
    max_depth = nothing,
    show_subtree_info = false,
    syntaxstring_kwargs = (;),
    kwargs...,
)
    io = IOBuffer()
    (
        indentation_list_children,
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
    if isnothing(max_depth) || depth < max_depth
        pipe = "$(indentation_list_children)"
        # println(io, "$(indentation_str*pipe)$(antecedent(m))")
        #println(io, "$(pipe)$(antecedent(m))")
        println(io, "$(pipe)$(syntaxstring(antecedent(m); syntaxstring_kwargs...))")
        pad_str = indentation_str*repeat(" ", length(pipe)-length(indentation_last_space)+1)
        print(io, "$(pad_str*indentation_last_first)$("✔ ")")
        ind_str = pad_str*indentation_last_space*repeat(" ", length("✔ ")-length(indentation_last_space)+2)
        subm_str = @_display_submodel consequent(m) ind_str indentation depth max_depth show_subtree_info syntaxstring_kwargs kwargs
        print(io, subm_str)
    else
        println(io, "[...]")
    end
    String(take!(io))
end

function displaymodel(
    m::Branch;
    header = :brief,
    indentation_str = "",
    indentation = default_indentation,
    depth = 0,
    max_depth = nothing,
    show_subtree_info = false,
    syntaxstring_kwargs = (;),
    kwargs...,
)
    io = IOBuffer()
    (
        indentation_list_children,
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
    if isnothing(max_depth) || depth < max_depth
        pipe = "$(indentation_list_children) "
        println(io, "$(pipe)$(syntaxstring(antecedent(m); syntaxstring_kwargs...))")
        for (consequent, indentation_flag_space, indentation_flag_first, f) in [(posconsequent(m), indentation_any_space, indentation_any_first, "✔ "), (negconsequent(m), indentation_last_space, indentation_last_first, "✘ ")]
            # pad_str = indentation_str*indentation_flag_first**repeat(" ", length(pipe)-length(indentation_flag_first))
            pad_str = "$(indentation_str*indentation_flag_first)$(f)"
            print(io, "$(pad_str)")
            ind_str = indentation_str*indentation_flag_space*repeat(" ", length(f))
            subm_str = @_display_submodel consequent ind_str indentation depth max_depth show_subtree_info syntaxstring_kwargs kwargs
            print(io, subm_str)
        end
    else
        println(io, "[...]")
    end
    String(take!(io))
end


function displaymodel(
    m::DecisionList;
    header = :brief,
    indentation_str = "",
    indentation = default_indentation,
    depth = 0,
    max_depth = nothing,
    show_subtree_info = false,
    syntaxstring_kwargs = (;),
    kwargs...,
)
    io = IOBuffer()
    (
        indentation_list_children,
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
    if isnothing(max_depth) || depth < max_depth
        println(io, "$(indentation_list_children)")
        for (i_rule, rule) in enumerate(rulebase(m))
            # pipe = indentation_any_first
            pipe = indentation_any_first*"[$(i_rule)/$(length(rulebase(m)))]┐"
            println(io, "$(indentation_str*pipe) $(syntaxstring(antecedent(rule); syntaxstring_kwargs...))")
            pad_str = indentation_str*indentation_any_space*repeat(" ", length(pipe)-length(indentation_any_space)-1)
            print(io, "$(pad_str*indentation_last_first)")
            ind_str = pad_str*indentation_last_space
            subm_str = @_display_submodel consequent(rule) ind_str indentation depth max_depth show_subtree_info syntaxstring_kwargs kwargs
            print(io, subm_str)
        end
        pipe = indentation_last_first*"$("✘ ")"
        print(io, "$(indentation_str*pipe)")
        # print(io, "$(indentation_str*indentation_last_space*repeat(" ", length(pipe)-length(indentation_last_space)-1)*indentation_last_space)")
        ind_str = indentation_str*indentation_last_space*repeat(" ", length(pipe)-length(indentation_last_space)-1)*indentation_last_space
        # ind_str = indentation_str*indentation_last_space,
        subm_str = @_display_submodel defaultconsequent(m) ind_str indentation depth max_depth show_subtree_info syntaxstring_kwargs kwargs
        print(io, subm_str)
    else
        println(io, "[...]")
    end
    String(take!(io))
end

function displaymodel(
    m::DecisionTree;
    header = :brief,
    indentation_str = "",
    indentation = default_indentation,
    depth = 0,
    max_depth = nothing,
    show_subtree_info = false,
    syntaxstring_kwargs = (;),
    kwargs...,
)
    io = IOBuffer()
    (
        indentation_list_children,
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
    subm_str = @_display_submodel root(m) indentation_str indentation depth max_depth show_subtree_info syntaxstring_kwargs kwargs
    print(io, subm_str)
    String(take!(io))
end

function displaymodel(
    m::DecisionForest;
    header = :brief,
    indentation_str = "",
    indentation = default_indentation,
    depth = 0,
    max_depth = nothing,
    show_subtree_info = false,
    syntaxstring_kwargs = (;),
    kwargs...,
)
    io = IOBuffer()
    (
        indentation_list_children,
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
        subm_str = @_display_submodel tree indentation_str indentation depth max_depth show_subtree_info syntaxstring_kwargs kwargs
        print(io, subm_str)
    end
    String(take!(io))
end

function displaymodel(
    m::MixedSymbolicModel;
    header = :brief,
    indentation_str = "",
    indentation = default_indentation,
    depth = 0,
    max_depth = nothing,
    show_subtree_info = false,
    syntaxstring_kwargs = (;),
    kwargs...,
)
    io = IOBuffer()
    (
        indentation_list_children,
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
    subm_str = @_display_submodel root(m) indentation_str indentation depth max_depth show_subtree_info syntaxstring_kwargs kwargs
    print(io, subm_str)
    String(take!(io))
end
