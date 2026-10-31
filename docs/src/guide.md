# Démarrage

## Installation

Pour utiliser la version du dépôt avant son éventuel enregistrement dans le registre Julia :

```julia
using Pkg
Pkg.add(url = "https://github.com/yolhan83/GooseArrays.jl")
```

## Tableaux dynamiques et statiques

```@example start
using GooseArrays, LinearAlgebra

result = with_datastack(1 << 20) do s
    x = GooseVector{Float64}(s, undef, 4)
    fill!(x, 2.0)
    y = StaticGooseVector{Float64,4}(s, undef)
    y .= 2 .* x .+ 1
    (sum(y), Array(y))  # copie indépendante de l'arène
end
result
```

`GooseArray{T,N}` garde les dimensions **hors du type** : utile pour des longueurs
choisies à l'exécution. `StaticGooseArray{T,N,S}` intègre la forme dans son type,
au prix d'une spécialisation du code par forme.

## Portées et invalidation

```@example start
with_datastack(4096) do s
    outer = GooseArray(s, [1, 2, 3])
    escaped = with_scope(s) do scope
        a = GooseArray(scope, [4, 5, 6])
        copy(a)  # copie dans la même arène, invalidée en sortie
    end
    (sum(outer), try
        sum(escaped)
    catch err
        typeof(err)
    end)
end
```

Pour faire survivre les données au-delà de `with_scope` ou de `with_datastack`,
utiliser `Array(a)` **avant la sortie de la portée**. Ne jamais conserver ni
réutiliser un pointeur brut vers une arène après fermeture ou réinitialisation.

## Réductions et algèbre linéaire

`map`, `map!`, les broadcasts et les réductions usuelles travaillent avec les
tableaux Goose. `map` hors place crée des résultats dans l'arène du premier
tableau Goose, et `mapreduce` numérique peut éviter toute matérialisation.
`LinearAlgebra` fournit entre autres `mul!`, `dot`, `axpy!`, `axpby!` et les
produits statiques compatibles.

Les exemples exécutables sont aussi sous [`examples/`](https://github.com/yolhan83/GooseArrays.jl/tree/main/examples).
