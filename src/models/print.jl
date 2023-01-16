"""
Any `M<:AbstractModel` must provide a `print_model(m::M; kwargs...)` method
that is used for rendering the model in text. See print.jl.

See also [`AbstractModel`](@ref).
"""
print_model(m::AbstractModel; kwargs...) = print_model(stdout, m; kwargs...)

function Base.show(io::IO, ::MIME"text/plain", m::AbstractModel)
    # io = IOBuffer()
    print_model(io, m)
    # String(take!(io))
end

############################################################################################
# Printing utils
############################################################################################

default_indentation_list_children = "┐"
default_indentation_any_first  = "├ " # "╭✔ "
default_indentation_any_space  = "│ "
default_indentation_last_first = "└ " # "╰✘ "
default_indentation_last_space = "  "

default_indentation = (default_indentation_list_children, default_indentation_any_first, default_indentation_any_space, default_indentation_last_first, default_indentation_last_space)

macro print_submodel(io, submodel, indentation_str, indentation, depth, max_depth, kwargs)
    quote
        print_model($(esc(io)), $(esc(submodel));
            indentation_str = $(esc(indentation_str)),
            indentation = $(esc(indentation)),
            header = false,
            depth = $(esc(depth))+1,
            max_depth = $(esc(max_depth)),
            $(esc(kwargs))...,
        )
    end
end

function print_model(
        io::IO,
        m::ConstantModel;
        indentation_str="",
        header = true,
        kwargs...,
    )
    !header || println(io, "$(indentation_str)$(typeof(m))$(length(info(m)) == 0 ? "" : "\n$(indentation_str)Info: $(info(m))")")
    println(io, "$(outcome(m))")
end

function print_model(
        io::IO,
        m::FunctionModel;
        header = true,
        indentation_str="",
        kwargs...,
    )
    !header || println(io, "$(indentation_str)$(typeof(m))$(length(info(m)) == 0 ? "" : "\n$(indentation_str)Info: $(info(m))")")
    println(io, "$(f(m))")
end

function print_model(
        io::IO,
        m::Rule;
        header = true,
        indentation_str="",
        indentation = default_indentation,
        depth = 0,
        max_depth = nothing,
        kwargs...,
    )
    (indentation_list_children, indentation_any_first, indentation_any_space, indentation_last_first, indentation_last_space) = indentation
    !header || println(io, "$(indentation_str)$(typeof(m))$(length(info(m)) == 0 ? "" : "\n$(indentation_str)Info: $(info(m))")")
    if isnothing(max_depth) || depth < max_depth
        pipe = "$(indentation_list_children)"
        # println(io, "$(indentation_str*pipe)$(antecedent(m))")
        #println(io, "$(pipe)$(antecedent(m))")
        println(io, "$(pipe)$(print_string(formula(antecedent(m))))")
        pad_str = indentation_str*repeat(" ", length(pipe)-length(indentation_last_space)+1)
        print(io, "$(pad_str*indentation_last_first)$("✔ ")")
        ind = pad_str*indentation_last_space*repeat(" ", length("✔ ")-length(indentation_last_space)+2)
        @print_submodel io consequent(m) ind indentation depth max_depth kwargs
    else
        println(io, "[...]")
    end
end

function print_model(
        io::IO,
        m::Branch;
        header = true,
        indentation_str="",
        indentation = default_indentation,
        depth = 0,
        max_depth = nothing,
        kwargs...,
    )
    (indentation_list_children, indentation_any_first, indentation_any_space, indentation_last_first, indentation_last_space) = indentation
    !header || println(io, "$(indentation_str)$(typeof(m))$(length(info(m)) == 0 ? "" : "\n$(indentation_str)Info: $(info(m))")")
    if isnothing(max_depth) || depth < max_depth
        pipe = "$(indentation_list_children) "
        println(io, "$(pipe)$(antecedent(m))")
        for (consequent, indentation_flag_space, indentation_flag_first, f) in [(positive_consequent(m), indentation_any_space, indentation_any_first, "✔ "), (negative_consequent(m), indentation_last_space, indentation_last_first, "✘ ")]
            # pad_str = indentation_str*indentation_flag_first**repeat(" ", length(pipe)-length(indentation_flag_first))
            pad_str = "$(indentation_str*indentation_flag_first)$(f)"
            print(io, "$(pad_str)")
            ind = indentation_str*indentation_flag_space*repeat(" ", length(f))
            @print_submodel io consequent ind indentation depth max_depth kwargs
        end
    else
        println(io, "[...]")
    end
end


function print_model(
        io::IO,
        m::DecisionList;
        header = true,
        indentation_str="",
        indentation = default_indentation,
        depth = 0,
        max_depth = nothing,
        kwargs...,
    )
    (indentation_list_children, indentation_any_first, indentation_any_space, indentation_last_first, indentation_last_space) = indentation
    !header || println(io, "$(indentation_str)$(typeof(m))$(length(info(m)) == 0 ? "" : "\n$(indentation_str)Info: $(info(m))")")
    if isnothing(max_depth) || depth < max_depth
        println(io, "$(indentation_list_children)")
        for (i_rule, rule) in enumerate(rules(m))
            # pipe = indentation_any_first
            pipe = indentation_any_first*"[$(i_rule)/$(length(rules(m)))]┐"
            println(io, "$(indentation_str*pipe) $(antecedent(rule))")
            pad_str = indentation_str*indentation_any_space*repeat(" ", length(pipe)-length(indentation_any_space)-1)
            print(io, "$(pad_str*indentation_last_first)")
            ind = pad_str*indentation_last_space
            @print_submodel io consequent(rule) ind indentation depth max_depth kwargs
        end
        pipe = indentation_last_first*"$("✘ ")"
        print(io, "$(indentation_str*pipe)")
        # print(io, "$(indentation_str*indentation_last_space*repeat(" ", length(pipe)-length(indentation_last_space)-1)*indentation_last_space)")
        ind = indentation_str*indentation_last_space*repeat(" ", length(pipe)-length(indentation_last_space)-1)*indentation_last_space
        # ind = indentation_str*indentation_last_space,
        @print_submodel io default_consequent(m) ind indentation depth max_depth kwargs
    else
        println(io, "[...]")
    end
end


function print_model(
        io::IO,
        m::RuleCascade;
        header = true,
        indentation_str="",
        indentation = default_indentation,
        depth = 0,
        max_depth = nothing,
        kwargs...,
    )
    (indentation_list_children, indentation_any_first, indentation_any_space, indentation_last_first, indentation_last_space) = indentation
    !header || println(io, "$(indentation_str)$(typeof(m))$(length(info(m)) == 0 ? "" : "\n$(indentation_str)Info: $(info(m))")")
    if isnothing(max_depth) || depth < max_depth
        pipe = "$(indentation_list_children)"
        # println(io, "$(indentation_str*pipe)⩚("*join(antecedents(m), ", ")*")")
        #println(io, "$(pipe)⩚("*join(antecedents(m), ", ")*")")
        println(io, "$(pipe)⩚("*join(print_string.(formula.(antecedents(m))), " AND ")*")")
        pad_str = indentation_str*repeat(" ", length(pipe)-length(indentation_last_space)+1)
        print(io, "$(pad_str*indentation_last_first)$("✔ ")")
        ind = pad_str*indentation_last_space*repeat(" ", length("✔ ")+1)
        @print_submodel io consequent(m) ind indentation depth max_depth kwargs
    else
        println(io, "[...]")
    end
end


function print_model(
        io::IO,
        m::DecisionTree;
        header = true,
        indentation_str="",
        indentation = default_indentation,
        depth = 0,
        kwargs...
    )
    (indentation_list_children, indentation_any_first, indentation_any_space, indentation_last_first, indentation_last_space) = indentation
    !header || println(io, "$(indentation_str)$(typeof(m))$(length(info(m)) == 0 ? "" : "\n$(indentation_str)Info: $(info(m))")")
    print_model(io, root(m); kwargs...)
end

function print_model(
        io::IO,
        m::MixedSymbolicModel;
        header = true,
        indentation_str="",
        indentation = default_indentation,
        depth = 0,
        kwargs...
    )
    (indentation_list_children, indentation_any_first, indentation_any_space, indentation_last_first, indentation_last_space) = indentation
    !header || println(io, "$(indentation_str)$(typeof(m))$(length(info(m)) == 0 ? "" : "\n$(indentation_str)Info: $(info(m))")")
    print_model(io, root(m); kwargs...)
end

print_model(m::Any; kwargs...) = print_model(stdout, m; kwargs...)

function print_string(f::Formula)
    print_string(tree(f))
end

function print_string(st::SyntaxTree)
    if length(children(st)) == 0
        return string(token(st))
    elseif token(st) == ¬
        return string(st)
    else
        return join([print_string(i) for i in children(st)]," ∧ ")
    end
end

function print_model(
    io::IO,
    m::Vector{<:RuleCascade};
    header = true,
    indentation_str="",
    indentation = default_indentation,
    depth = 0,
    max_depth = nothing,
    kwargs...,
)
    (indentation_list_children, indentation_any_first, indentation_any_space, indentation_last_first, indentation_last_space) = indentation
    !header || println(io, "$(length(m))-element $(typeof(m))")
    for r in m
        (indentation_list_children, indentation_any_first, indentation_any_space, indentation_last_first, indentation_last_space) = indentation
        !header || println(io, "$(indentation_str)$(typeof(r))$(length(info(r)) == 0 ? "" : "\n$(indentation_str)Info: $(info(r))")")

        if isnothing(max_depth) || depth < max_depth
            print_model(io,r; header = false)
        else
            println(io, "[...]")
        end
    end
end

function print_model(
    io::IO,
    m::Vector{<:Rule};
    header = true,
    indentation_str="",
    indentation = default_indentation,
    depth = 0,
    max_depth = nothing,
    kwargs...,
)
    (indentation_list_children, indentation_any_first, indentation_any_space, indentation_last_first, indentation_last_space) = indentation
    !header || println(io, "$(length(m))-element $(typeof(m))")
    for r in m
        (indentation_list_children, indentation_any_first, indentation_any_space, indentation_last_first, indentation_last_space) = indentation
        !header || println(io, "$(indentation_str)$(typeof(r))$(length(info(r)) == 0 ? "" : "\n$(indentation_str)Info: $(info(r))")")
        if isnothing(max_depth) || depth < max_depth
            print_model(io,r; header=false)
        else
            println(io, "[...]")
        end
    end
end
