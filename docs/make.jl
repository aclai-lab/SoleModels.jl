using SoleModels
using Documenter

DocMeta.setdocmeta!(SoleBase, :DocTestSetup, :(using SoleBase); recursive=true)
DocMeta.setdocmeta!(SoleLogics, :DocTestSetup, :(using SoleLogics); recursive=true)
DocMeta.setdocmeta!(SoleModels, :DocTestSetup, :(using SoleModels); recursive=true)

makedocs(;
    modules=[SoleBase, SoleLogics, SoleModels],
    authors="Michele Ghiotti, Giovanni Pagliarini, Eduard I. Stan",
    repo="https://github.com/aclai-lab/SoleModels.jl/blob/{commit}{path}#{line}",
    sitename="SoleModels.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://aclai-lab.github.io/SoleModels.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/aclai-lab/SoleModels.jl",
    devbranch = "main",
    target = "build",
    branch = "gh-pages",
    versions = ["stable" => "v^", "v#.#"],
)
