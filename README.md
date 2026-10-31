# GooseArrays.jl

[![CI](https://github.com/yolhan83/GooseArrays.jl/actions/workflows/ci.yml/badge.svg)](https://github.com/yolhan83/GooseArrays.jl/actions/workflows/ci.yml)
[![Documentation](https://github.com/yolhan83/GooseArrays.jl/actions/workflows/docs.yml/badge.svg)](https://github.com/yolhan83/GooseArrays.jl/actions/workflows/docs.yml)

Inspired by the idea behind **Goose**, GooseArrays.jl provides temporary,
fixed-size Julia arrays with explicit lifetimes, backed by a reusable memory arena.
`GooseArray` does not specialize on array lengths; `StaticGooseArray` can do so when
useful. Their elements reside in an `mmap` region (not necessarily on the native
stack), and access is invalidated after the owning scope or arena is closed.

## Example

```julia
using GooseArrays

result = with_datastack(1 << 20) do s
    x = GooseVector{Float64}(s, undef, 4)
    fill!(x, 2.0)
    y = StaticGooseVector{Float64,4}(s, undef)
    y .= 2 .* x .+ 1
    Array(y)  # independent copy outside the arena
end
# result == [5.0, 5.0, 5.0, 5.0]
```

## Benchmarks

Comparison of mutable arrays: `Vector` (Base), `FixedSizeArray`
([FixedSizeArrays.jl](https://github.com/JuliaArrays/FixedSizeArrays.jl)),
`GooseVector`, `StaticGooseVector`, and `MVector`
([StaticArrays.jl](https://github.com/JuliaArrays/StaticArrays.jl)).

Measured on **October 31, 2026**, with Julia **1.13.3** on an **Apple M5 Max**, using
one Julia task and one BLAS thread. Each cell reports **median time in ns / GC
allocation in bytes**. `sum(map(f, x))` includes consuming the result and, for
Goose arrays, leaving the scope. Arena initialization is excluded. `—` means
**not measured**.

| n | Operation | Vector | FixedSizeArray | GooseVector | StaticGooseVector | MVector |
| ---: | --- | ---: | ---: | ---: | ---: | ---: |
| 4 | `sum(map(f,x))` | 8.6 / 96 | 9.1 / 64 | 14.2 / 0 | 13.9 / 0 | 1.8 / 0 |
| 64 | `sum(map(f,x))` | 21.0 / 576 | 18.6 / 544 | 20.8 / 0 | 20.4 / 0 | 13.7 / 0 |
| 1,000 | `sum(map(f,x))` | 217.0 / 8256 | 211.0 / 8224 | 156.1 / 0 | 152.7 / 0 | 589.8 / 0 |
| 10,000 | `sum(map(f,x))` | 2259.2 / 81984 | 2263.9 / 81952 | 1641.7 / 0 | 1620.8 / 0 | — |
| 64 | `mapreduce(abs2,+,x)` | 7.0 / 0 | 7.0 / 0 | 7.4 / 0 | 6.8 / 0 | 9.0 / 0 |
| 1,000 | `sum(f.(x))` | 196.4 / 8256 | 194.4 / 8224 | 156.2 / 0 | 153.4 / 0 | 590.0 / 0 |

**Zero GC bytes does not mean zero arena bytes.** Performance depends on the
operation and machine; small `MVector` instances can be faster.

**Run benchmarks with one command:**

```sh
julia --startup-file=no benchmark/bench.jl
```

Full **[documentation: getting started, API, safety, compatibility, benchmarks, and
methodology](https://yolhan83.github.io/GooseArrays.jl/)**.
