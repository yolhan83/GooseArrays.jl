using Documenter, GooseArrays

makedocs(
    modules = [GooseArrays],
    sitename = "GooseArrays.jl",
    authors = "GooseArrays.jl contributors",
    format = Documenter.HTML(; prettyurls = get(ENV, "CI", "false") == "true"),
    checkdocs = :none,
    pages = [
        "Accueil" => "index.md",
        "Démarrage" => "guide.md",
        "API" => "api.md",
        "Architecture" => "architecture.md",
        "Compatibilité" => "compatibility.md",
        "Performances" => "performance.md",
        "Contribuer et CI" => "contributing.md",
    ],
)
