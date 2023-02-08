import Base: display

"""
Any `M<:AbstractModel` must provide a `printmodel(m::M; kwargs...)` method
that is used for rendering the model in text. See print.jl.

See also [`AbstractModel`](@ref).
"""
Base.show(io::IO, m::AbstractModel) = print(io, displaymodel(m))
Base.show(io::IO, ::MIME"text/plain", m::AbstractModel) = printmodel(io, m)

function printmodel(io::IO, m::AbstractModel; kwargs...)
    println(io, displaymodel(m; kwargs...))
end
printmodel(m::AbstractModel; kwargs...) = printmodel(stdout, m; kwargs...)

# display(m::AbstractModel; kwargs...) = displaymodel(m; kwargs...)

############################################################################################
# Printing utils
############################################################################################

default_indentation_list_children = "┐"
default_indentation_any_first  = "├ " # "╭✔ "
default_indentation_any_space  = "│ "
default_indentation_last_first = "└ " # "╰✘ "
default_indentation_last_space = "  "

default_indentation = (default_indentation_list_children, default_indentation_any_first, default_indentation_any_space, default_indentation_last_first, default_indentation_last_space)

macro _display_submodel(submodel, indentation_str, indentation, depth, max_depth, show_subtree_info, syntaxstring_kwargs, kwargs)
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
    indentation_str="",
    header = true,
    show_subtree_info = false,
    kwargs...,
)
    io = IOBuffer()
    !header || println(io, "$(indentation_str)$(typeof(m))$((length(info(m)) == 0) ? "" : "\n$(indentation_str)Info: $(info(m))")")
    println(io, "$(outcome(m))")
    String(take!(io))
end

function displaymodel(
    m::FunctionModel;
    indentation_str="",
    header = true,
    show_subtree_info = false,
    kwargs...,
)
    io = IOBuffer()
    !header || println(io, "$(indentation_str)$(typeof(m))$((length(info(m)) == 0) ? "" : "\n$(indentation_str)Info: $(info(m))")")
    println(io, "$(f(m))")
    String(take!(io))
end

function displaymodel(
    m::Rule;
    indentation_str="",
    header = true,
    show_subtree_info = false,
    indentation = default_indentation,
    depth = 0,
    max_depth = nothing,
    syntaxstring_kwargs = (),
    kwargs...,
)
    io = IOBuffer()
    (indentation_list_children, indentation_any_first, indentation_any_space, indentation_last_first, indentation_last_space) = indentation
    !header || println(io, "$(indentation_str)$(typeof(m))$((length(info(m)) == 0) ? "" : "\n$(indentation_str)Info: $(info(m))")")
    if isnothing(max_depth) || depth < max_depth
        pipe = "$(indentation_list_children)"
        # println(io, "$(indentation_str*pipe)$(antecedent(m))")
        #println(io, "$(pipe)$(antecedent(m))")
        println(io, "$(pipe)$(syntaxstring(antecedent(m); syntaxstring_kwargs...))")
        pad_str = indentation_str*repeat(" ", length(pipe)-length(indentation_last_space)+1)
        print(io, "$(pad_str*indentation_last_first)$("✔ ")")
        ind = pad_str*indentation_last_space*repeat(" ", length("✔ ")-length(indentation_last_space)+2)
        subm_str = @_display_submodel consequent(m) ind indentation depth max_depth show_subtree_info syntaxstring_kwargs kwargs
        print(io, subm_str)
    else
        println(io, "[...]")
    end
    String(take!(io))
end

function displaymodel(
    m::Branch;
    indentation_str="",
    header = true,
    show_subtree_info = false,
    indentation = default_indentation,
    depth = 0,
    max_depth = nothing,
    syntaxstring_kwargs = (),
    kwargs...,
)
    io = IOBuffer()
    (indentation_list_children, indentation_any_first, indentation_any_space, indentation_last_first, indentation_last_space) = indentation
    !header || println(io, "$(indentation_str)$(typeof(m))$((length(info(m)) == 0) ? "" : "\n$(indentation_str)Info: $(info(m))")")
    if isnothing(max_depth) || depth < max_depth
        pipe = "$(indentation_list_children) "
        println(io, "$(pipe)$(syntaxstring(antecedent(m); syntaxstring_kwargs...))")
        for (consequent, indentation_flag_space, indentation_flag_first, f) in [(positive_consequent(m), indentation_any_space, indentation_any_first, "✔ "), (negative_consequent(m), indentation_last_space, indentation_last_first, "✘ ")]
            # pad_str = indentation_str*indentation_flag_first**repeat(" ", length(pipe)-length(indentation_flag_first))
            pad_str = "$(indentation_str*indentation_flag_first)$(f)"
            print(io, "$(pad_str)")
            ind = indentation_str*indentation_flag_space*repeat(" ", length(f))
            subm_str = @_display_submodel consequent ind indentation depth max_depth show_subtree_info syntaxstring_kwargs kwargs
            print(io, subm_str)
        end
    else
        println(io, "[...]")
    end
    String(take!(io))
end


function displaymodel(
    m::DecisionList;
    indentation_str="",
    header = true,
    show_subtree_info = false,
    indentation = default_indentation,
    depth = 0,
    max_depth = nothing,
    syntaxstring_kwargs = (),
    kwargs...,
)
    io = IOBuffer()
    (indentation_list_children, indentation_any_first, indentation_any_space, indentation_last_first, indentation_last_space) = indentation
    !header || println(io, "$(indentation_str)$(typeof(m))$((length(info(m)) == 0) ? "" : "\n$(indentation_str)Info: $(info(m))")")
    if isnothing(max_depth) || depth < max_depth
        println(io, "$(indentation_list_children)")
        for (i_rule, rule) in enumerate(rules(m))
            # pipe = indentation_any_first
            pipe = indentation_any_first*"[$(i_rule)/$(length(rules(m)))]┐"
            println(io, "$(indentation_str*pipe) $(syntaxstring(antecedent(rule); syntaxstring_kwargs...))")
            pad_str = indentation_str*indentation_any_space*repeat(" ", length(pipe)-length(indentation_any_space)-1)
            print(io, "$(pad_str*indentation_last_first)")
            ind = pad_str*indentation_last_space
            subm_str = @_display_submodel consequent(rule) ind indentation depth max_depth show_subtree_info syntaxstring_kwargs kwargs
            print(io, subm_str)
        end
        pipe = indentation_last_first*"$("✘ ")"
        print(io, "$(indentation_str*pipe)")
        # print(io, "$(indentation_str*indentation_last_space*repeat(" ", length(pipe)-length(indentation_last_space)-1)*indentation_last_space)")
        ind = indentation_str*indentation_last_space*repeat(" ", length(pipe)-length(indentation_last_space)-1)*indentation_last_space
        # ind = indentation_str*indentation_last_space,
        subm_str = @_display_submodel default_consequent(m) ind indentation depth max_depth show_subtree_info syntaxstring_kwargs kwargs
        print(io, subm_str)
    else
        println(io, "[...]")
    end
    String(take!(io))
end


function displaymodel(
    m::RuleCascade;
    indentation_str="",
    header = true,
    show_subtree_info = false,
    indentation = default_indentation,
    depth = 0,
    max_depth = nothing,
    syntaxstring_kwargs = (),
    kwargs...,
)
    io = IOBuffer()
    (indentation_list_children, indentation_any_first, indentation_any_space, indentation_last_first, indentation_last_space) = indentation
    !header || println(io, "$(indentation_str)$(typeof(m))$((length(info(m)) == 0) ? "" : "\n$(indentation_str)Info: $(info(m))")")
    if isnothing(max_depth) || depth < max_depth
        pipe = "$(indentation_list_children)"
        # println(io, "$(indentation_str*pipe)⩚("*join(antecedents(m), ", ")*")")
        #println(io, "$(pipe)⩚("*join(antecedents(m), ", ")*")")
        println(io, "$(pipe)⩚("*join(map(a->syntaxstring(a; syntaxstring_kwargs...), antecedents(m)), ", ")*")")
        pad_str = indentation_str*repeat(" ", length(pipe)-length(indentation_last_space)+1)
        print(io, "$(pad_str*indentation_last_first)$("✔ ")")
        ind = pad_str*indentation_last_space*repeat(" ", length("✔ ")+1)
        subm_str = @_display_submodel consequent(m) ind indentation depth max_depth show_subtree_info syntaxstring_kwargs kwargs
        print(io, subm_str)
    else
        println(io, "[...]")
    end
    String(take!(io))
end


function displaymodel(
    m::DecisionTree;
    indentation_str="",
    header = true,
    show_subtree_info = false,
    indentation = default_indentation,
    depth = 0,
    max_depth = nothing,
    syntaxstring_kwargs = (),
    kwargs...,
)
    io = IOBuffer()
    (indentation_list_children, indentation_any_first, indentation_any_space, indentation_last_first, indentation_last_space) = indentation
    !header || println(io, "$(indentation_str)$(typeof(m))$((length(info(m)) == 0) ? "" : "\n$(indentation_str)Info: $(info(m))")")
    subm_str = @_display_submodel root(m) indentation_str indentation depth max_depth show_subtree_info syntaxstring_kwargs kwargs
    print(io, subm_str)
    String(take!(io))
end

function displaymodel(
    m::DecisionForest;
    indentation_str="",
    header = true,
    show_subtree_info = false,
    indentation = default_indentation,
    depth = 0,
    kwargs...,
)
    io = IOBuffer()
    (indentation_list_children, indentation_any_first, indentation_any_space, indentation_last_first, indentation_last_space) = indentation
    !header || println(io, "$(indentation_str)$(typeof(m))$((length(info(m)) == 0) ? "" : "\n$(indentation_str)Info: $(info(m))")")
    displaymodel.(io, trees(m); kwargs...)
    String(take!(io))
end

function displaymodel(
    m::MixedSymbolicModel;
    indentation_str="",
    header = true,
    show_subtree_info = false,
    indentation = default_indentation,
    depth = 0,
    kwargs...,
)
    io = IOBuffer()
    (indentation_list_children, indentation_any_first, indentation_any_space, indentation_last_first, indentation_last_space) = indentation
    !header || println(io, "$(indentation_str)$(typeof(m))$((length(info(m)) == 0) ? "" : "\n$(indentation_str)Info: $(info(m))")")
    displaymodel(io, root(m); kwargs...)
    String(take!(io))
end
