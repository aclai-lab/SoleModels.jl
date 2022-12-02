function Base.show(io::IO, ::MIME"text/plain", m::AbstractModel)
    io = IOBuffer()
    print_model(io, m)
    String(take!(io))
end

print_model(m::AbstractModel; kwargs...) = print_model(stdout, m; kwargs...)

# TODO @macro print_submodel (there any/last)


default_indentation_list_children = "┐"
default_indentation_any_first  = "├ "
default_indentation_any_space  = "│ "
default_indentation_last_first = "└ "
default_indentation_last_space = "  "

default_indentation = (default_indentation_list_children, default_indentation_any_first, default_indentation_any_space, default_indentation_last_first, default_indentation_last_space)


# "╭✔ "
# "╰✘ "



function print_model(
        io::IO,
        m::ConstantModel;
        indentation_str="",
        header = true,
        kwargs...,
    )
    !header || println(io, "$(indentation_str)$(typeof(m))\n$(indentation_str)Info:$(info(m))")
    println(io, "$(m.final_outcome)")
end

function print_model(
        io::IO,
        m::FunctionModel;
        header = true,
        indentation_str="",
        kwargs...,
    )
    !header || println(io, "$(indentation_str)$(typeof(m))\n$(indentation_str)Info:$(info(m))")
    println(io, "$(m.f)")
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
    !header || println(io, "$(indentation_str)$(typeof(m))\n$(indentation_str)Info:$(info(m))")
    if isnothing(max_depth) || depth < max_depth
        pipe = "$(indentation_list_children)"
        # println(io, "$(indentation_str*pipe)$(m.antecedent)")
        println(io, "$(pipe)$(m.antecedent)")
        pad_str = indentation_str*repeat(" ", length(pipe)-length(indentation_last_space))
        print(io, "$(pad_str*indentation_last_first)$("✔ ")")
        print_model(io, m.consequent;
            indentation_str = pad_str*indentation_last_space*repeat(" ", length("✔ ")+1),
            indentation = indentation,
            header = false,
            depth = depth+1,
            max_depth = max_depth,
            kwargs...,
        )
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
    !header || println(io, "$(indentation_str)$(typeof(m))\n$(indentation_str)Info:$(info(m))")
    if isnothing(max_depth) || depth < max_depth
        pipe = "$(indentation_list_children) "
        println(io, "$(pipe)$(m.antecedent)")
        for (consequent, indentation_flag_space, indentation_flag_first, f) in [(m.positive_consequent, indentation_any_space, indentation_any_first, "✔ "), (m.negative_consequent, indentation_last_space, indentation_last_first, "✘ ")]
            # pad_str = indentation_str*indentation_flag_first**repeat(" ", length(pipe)-length(indentation_flag_first))
            pad_str = "$(indentation_str*indentation_flag_first)$(f)"
            print(io, "$(pad_str)")
            print_model(io, consequent;
                indentation_str = indentation_str*indentation_flag_space*repeat(" ", length(f)+1),
                indentation = indentation,
                header = false,
                depth = depth+1,
                max_depth = max_depth,
                kwargs...,
            )
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
    !header || println(io, "$(indentation_str)$(typeof(m))\n$(indentation_str)Info:$(info(m))")
    if isnothing(max_depth) || depth < max_depth
        println(io, "$(indentation_list_children)")
        for (i_rule, rule) in enumerate(m.rules)
            # pipe = indentation_any_first
            pipe = indentation_any_first*"[$(i_rule)/$(length(m.rules))]┐"
            println(io, "$(indentation_str*pipe) $(antecedent(rule))")
            pad_str = indentation_str*indentation_any_space*repeat(" ", length(pipe)-length(indentation_any_space)-1)
            print(io, "$(pad_str*indentation_last_first)")
            print_model(io, consequent(rule);
                indentation_str = pad_str*indentation_last_space,
                indentation = indentation,
                header = false,
                depth = depth+1,
                max_depth = max_depth,
                kwargs...,
            )
        end
        pipe = indentation_last_first*"$("✘ ")"
        print(io, "$(indentation_str*pipe)")
        # print(io, "$(indentation_str*indentation_last_space*repeat(" ", length(pipe)-length(indentation_last_space)-1)*indentation_last_space)")
        print_model(io, m.default_consequent;
            indentation_str = indentation_str*indentation_last_space*repeat(" ", length(pipe)-length(indentation_last_space)-1)*indentation_last_space,
            # indentation_str = indentation_str*indentation_last_space,
            indentation = indentation,
            header = false,
            depth = depth+1,
            max_depth = max_depth,
            kwargs...,
        )
    else
        println(io, "[...]")
    end
end
