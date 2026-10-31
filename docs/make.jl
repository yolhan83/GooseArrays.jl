using Documenter, GooseArrays

makedocs(
    modules = [GooseArrays],
    sitename = "GooseArrays.jl",
    authors = "GooseArrays.jl contributors",
    format = Documenter.HTML(; prettyurls = get(ENV, "CI", "false") == "true"),
    checkdocs = :none,
    pages = [
        "Home" => "index.md",
        "Getting started" => "guide.md",
        "API" => "api.md",
        "Architecture" => "architecture.md",
        "Compatibility" => "compatibility.md",
        "Performance" => "performance.md",
        "Contributing and CI" => "contributing.md",
    ],
)
