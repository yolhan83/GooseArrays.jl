# GooseArrays.jl

[![CI](https://github.com/yolhan83/GooseArrays.jl/actions/workflows/ci.yml/badge.svg)](https://github.com/yolhan83/GooseArrays.jl/actions/workflows/ci.yml)
[![Documentation](https://github.com/yolhan83/GooseArrays.jl/actions/workflows/docs.yml/badge.svg)](https://github.com/yolhan83/GooseArrays.jl/actions/workflows/docs.yml)

Inspiré de l'idée de **Goose**, GooseArrays.jl fournit des tableaux Julia temporaires
à taille fixe et durée de vie explicite, adossés à une arène mémoire réutilisable.
`GooseArray` ne spécialise pas par longueur ; `StaticGooseArray` le fait lorsque
c'est utile. Leurs données vivent dans une zone `mmap` (et non nécessairement
sur la pile native) ; les accès après fermeture ou sortie de portée sont invalidés.

## Exemple

```julia
using GooseArrays

result = with_datastack(1 << 20) do s
    x = GooseVector{Float64}(s, undef, 4)
    fill!(x, 2.0)
    y = StaticGooseVector{Float64,4}(s, undef)
    y .= 2 .* x .+ 1
    Array(y)  # copie indépendante de l'arène
end
# result == [5.0, 5.0, 5.0, 5.0]
```

## Benchmarks

Comparaison de tableaux modifiables : `Vector` (Base), `FixedSizeArray`
([FixedSizeArrays.jl](https://github.com/JuliaArrays/FixedSizeArrays.jl)),
`GooseVector`, `StaticGooseVector`, et `MVector`
([StaticArrays.jl](https://github.com/JuliaArrays/StaticArrays.jl)).

Mesures du **31 octobre 2026**, Julia **1.13.3**, **Apple M5 Max**, une Task et
un thread BLAS. Chaque cellule est **temps médian en ns / allocation GC en octets**.
`map puis sum` inclut la consommation du résultat et, pour Goose, la sortie
de portée. L'initialisation de l'arène est exclue. `—` signifie « non mesuré ».

| n | Opération | Vector | FixedSizeArray | GooseVector | StaticGooseVector | MVector |
| ---: | --- | ---: | ---: | ---: | ---: | ---: |
| 4 | `sum(map(f,x))` | 8.6 / 96 | 9.1 / 64 | 14.2 / 0 | 13.9 / 0 | 1.8 / 0 |
| 64 | `sum(map(f,x))` | 21.0 / 576 | 18.6 / 544 | 20.8 / 0 | 20.4 / 0 | 13.7 / 0 |
| 1 000 | `sum(map(f,x))` | 217.0 / 8256 | 211.0 / 8224 | 156.1 / 0 | 152.7 / 0 | 589.8 / 0 |
| 10 000 | `sum(map(f,x))` | 2259.2 / 81984 | 2263.9 / 81952 | 1641.7 / 0 | 1620.8 / 0 | — |
| 64 | `mapreduce(abs2,+,x)` | 7.0 / 0 | 7.0 / 0 | 7.4 / 0 | 6.8 / 0 | 9.0 / 0 |
| 1 000 | `sum(f.(x))` | 196.4 / 8256 | 194.4 / 8224 | 156.2 / 0 | 153.4 / 0 | 590.0 / 0 |

`0 octet GC` ne signifie pas `0 octet d'arène`. Les performances varient
selon les cas et les machines ; de petits `MVector` peuvent être plus rapides.

**Benchmark en une commande** :

```sh
julia --startup-file=no benchmark/bench.jl
```

Documentation complète : **[guide, API, sécurité, compatibilité, protocoles et
résultats](https://yolhan83.github.io/GooseArrays.jl/)**.
