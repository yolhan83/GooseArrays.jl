# Getting started

## Installation

To install directly from the repository before a possible Julia General
registry release:

```julia
using Pkg
Pkg.add(url = "https://github.com/yolhan83/GooseArrays.jl")
```

## Dynamic and static arrays

```@example start
using GooseArrays, LinearAlgebra

result = with_datastack(1 << 20) do s
    x = GooseVector{Float64}(s, undef, 4)
    fill!(x, 2.0)
    y = StaticGooseVector{Float64,4}(s, undef)
    y .= 2 .* x .+ 1
    (sum(y), Array(y))  # independent copy outside the arena
end
result
```

`GooseArray{T,N}` stores dimensions **outside the type**, making it suitable
for lengths chosen at runtime. `StaticGooseArray{T,N,S}` encodes the shape in
its type, trading additional specialization for shape-aware code.

## Scopes and invalidation

```@example start
with_datastack(4096) do s
    outer = GooseArray(s, [1, 2, 3])
    escaped = with_scope(s) do scope
        a = GooseArray(scope, [4, 5, 6])
        copy(a)  # copy within the same arena; invalid after scope exit
    end
    (sum(outer), try
        sum(escaped)
    catch err
        typeof(err)
    end)
end
```

To retain data beyond `with_scope` or `with_datastack`, call `Array(a)`
**before the scope ends**. Never retain or reuse raw pointers into an arena
after it has been closed or reset.

## Reductions and linear algebra

`map`, `map!`, broadcasting, and standard reductions work with Goose arrays.
Out-of-place `map` creates its result in the first Goose operand's arena;
numeric `mapreduce` can avoid materializing an intermediate array.
`LinearAlgebra` also provides `mul!`, `dot`, `axpy!`, `axpby!`, and compatible
static-shape products.

Runnable examples are available in
[`examples/`](https://github.com/yolhan83/GooseArrays.jl/tree/main/examples).
