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
        pad_str = indentation_str*repeat(" ", length(pipe)-length(indentation_last_space)+1)
        print(io, "$(pad_str*indentation_last_first)$("✔ ")")
        ind = pad_str*indentation_last_space*repeat(" ", length("✔ ")+1)
        @print_submodel io m.consequent ind indentation depth max_depth kwargs
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
    !header || println(io, "$(indentation_str)$(typeof(m))\n$(indentation_str)Info:$(info(m))")
    if isnothing(max_depth) || depth < max_depth
        println(io, "$(indentation_list_children)")
        for (i_rule, rule) in enumerate(m.rules)
            # pipe = indentation_any_first
            pipe = indentation_any_first*"[$(i_rule)/$(length(m.rules))]┐"
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
        @print_submodel io m.default_consequent ind indentation depth max_depth kwargs
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
    !header || println(io, "$(indentation_str)$(typeof(m))\n$(indentation_str)Info:$(info(m))")
    if isnothing(max_depth) || depth < max_depth
        pipe = "$(indentation_list_children)"
        # println(io, "$(indentation_str*pipe)$("⩚"*join(", ", antecedents(m)))")
        println(io, "$(pipe)$("⩚"*join(", ", antecedents(m)))")
        pad_str = indentation_str*repeat(" ", length(pipe)-length(indentation_last_space)+1)
        print(io, "$(pad_str*indentation_last_first)$("✔ ")")
        ind = pad_str*indentation_last_space*repeat(" ", length("✔ ")+1)
        @print_submodel io m.consequent ind indentation depth max_depth kwargs
    else
        println(io, "[...]")
    end
end


print_model(io::IO, m::DecisionTree; kwargs...) = print_model(io, m.root; kwargs...)

print_model(io::IO, m::MixedSymbolicModel; kwargs...) = print_model(io, m.root; kwargs...)

