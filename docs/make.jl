using SoleBase
using SoleLogics
using SoleData
using SoleData: DimensionalDatasets
using SoleModels
using Documenter

DocMeta.setdocmeta!(SoleBase, :DocTestSetup, :(using SoleBase); recursive=true)
DocMeta.setdocmeta!(SoleLogics, :DocTestSetup, :(using SoleLogics); recursive=true)
DocMeta.setdocmeta!(SoleData, :DocTestSetup, :(using SoleData); recursive=true)
DocMeta.setdocmeta!(SoleModels, :DocTestSetup, :(using SoleModels); recursive=true)

makedocs(;
    modules=[SoleBase, SoleLogics, SoleData, SoleData.DimensionalDatasets, SoleModels],
    authors="Michele Ghiotti, Giovanni Pagliarini, Eduard I. Stan",
    repo=Documenter.Remotes.GitHub("aclai-lab", "SoleModels.jl"),
    sitename="SoleModels.jl",
    format=Documenter.HTML(;
        size_threshold = 4000000,
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://aclai-lab.github.io/SoleModels.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
        "Logical foundations" => "logic.md",
        "Symbolic models" => "models.md",
        "Parsing models from other frameworks" => "parse.md",
        "Full reference" => "autodocs.md",
    ],
    warnonly = true, # TODO remove?
)

@info "`makedocs` has finished running. "

deploydocs(;
    repo="github.com/aclai-lab/SoleModels.jl",
    target = "build",
    branch = "gh-pages",
    versions = ["main" => "main", "stable" => "v^", "v#.#", "dev" => "dev"],
)
