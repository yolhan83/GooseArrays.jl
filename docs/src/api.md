# API reference

## Allocation and arenas

```@docs
DataStack
with_datastack
with_scope
alloc!
reset!
```

## Array types

```@docs
GooseArray
```

`GooseVector`, `GooseMatrix`, `StaticGooseVector`, and `StaticGooseMatrix`
are convenient aliases for one- and two-dimensional arrays. `AbstractGooseArray`
is the common parent type.

## Errors and introspection

```@docs
InvalidatedArrayError
```

`bytesused(s)` returns the number of arena bytes in use, `capacity(s)` the
reserved capacity, and `available(s)` the remaining space. `close(s)` unmaps
the arena and invalidates its array descriptors.

Standard `Base` and `LinearAlgebra` methods are covered in the
[Getting started](guide.md) and [Compatibility](compatibility.md) pages.
