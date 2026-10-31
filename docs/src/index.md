# GooseArrays.jl

Inspired by **Goose**, GooseArrays.jl brings temporary arrays with controlled
lifetimes to Julia's `AbstractArray` interface. Elements live in a preallocated
**`mmap` arena**, without requiring a separate GC allocation for each data
buffer. Shapes can be dynamic (`GooseArray`) or encoded in the type
(`StaticGooseArray`). Arrays become invalid when their scope ends or their arena
is reset or closed.

!!! warning "Not the native stack"
    `DataStack` describes an allocation and lifetime discipline. Neither the
    array data nor its descriptors are guaranteed to reside on the native call
    stack. Escaping array descriptors may still allocate on the GC heap.

Start with [Getting started](guide.md) and the [API reference](api.md).
Benchmark methodology is described in [Performance](performance.md).

## How it works

- Create an arena with `DataStack` or `with_datastack`.
- Use `alloc!` or the `GooseArray` / `StaticGooseArray` constructors to allocate
  contiguous, non-resizable arrays from the arena.
- Use `with_scope` for temporary allocations; the arena cursor is restored when
  the scope exits.
- `reset!` and `close` invalidate affected arrays. Invalid access raises
  `InvalidatedArrayError`, even under `@inbounds`.
- Each arena belongs to the Julia `Task` that created it; arenas cannot be
  shared across tasks.

Only positive-size `isbits` element types are supported.
Currently supported backends: Linux, macOS, and FreeBSD.
