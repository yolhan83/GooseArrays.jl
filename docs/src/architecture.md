# Architecture

## Representation

`DataStack` is a mutable object created once. It owns an anonymous memory
mapping, a byte cursor, a capacity, the owning task, the active scope depth, and
a preallocated vector of `_ScopeState` objects. This vector holds only scope
metadata, never array elements. Each arena has a root scope and supports up to
`max_scopes` nested levels.

`GooseArray{T,N}` is an immutable descriptor containing a reference to its
owner, a `Ptr{T}`, an `NTuple{N,Int}` of dimensions, a length, a reference to a
`_ScopeState`, and a generation identifier. Lengths and addresses are fields,
not type parameters. Keeping a reference to the owner prevents premature
finalization; it also means that escaping descriptors cannot be guaranteed to
avoid GC allocation.

`StaticGooseArray{T,N,S}` stores only the owner, pointer, scope state, and
generation. Here `S` is a tuple type such as `Tuple{2,3}`; there is no separate
dimensions or length field. Its descriptor is 32 bytes, compared with 48 bytes
for `GooseVector{Float64}`. Both types subtype `AbstractGooseArray{T,N}`, itself
a dense array, and share indexing and safety methods. The static type is not
`isbits`; its elements still live in `mmap` storage. Different shapes can cause
consumer functions to specialize.

Explicit shapes are validated before allocation. `copy` and `similar` without
new dimensions preserve `S`; explicitly provided ordinary dimensions produce
a `GooseArray`. `Val(tuple)` requests a static shape, while Base's internal
`Val(rank)` retains its rank-based reshape semantics for views. Zero-copy
conversions preserve the original storage scope state.

Broadcasting has a static style that combines shapes and singleton dimensions.
Mixing static and dynamic shapes falls back to the dynamic style. The
`LinearAlgebra` extension directly constructs static results for static
matrix–matrix and matrix–vector products, then calls `mul!`. Real-valued matrix
products with dimensions from 1 to 4 use a short native loop; larger sizes use
BLAS. Short real-valued `dot` products use SIMD reduction; those with more than
2,048 elements use BLAS.

Allocation validates the element type, checks the dimension product for
overflow, verifies actual address alignment, and checks available capacity. The
cursor advances only after validation. Elements are contiguous in Julia's
column-major order. Alignment relies on `Base.datatype_alignment`, an internal
Julia interface that should be monitored across Julia versions.

## Scopes and invalidation

Entering a scope saves the cursor, activates a generation slot, and assigns it
a monotonic identifier. Each array retains its scope state and identifier.
Leaving the scope invalidates that slot and restores the cursor in a `finally`
block. Arrays from outer scopes remain valid. A later scope at the same depth
receives a different identifier, so an old reference cannot become valid again
when its address is reused. Direct references to `_ScopeState` avoid looking up
the scope depth in an array buffer on every access and keep generation metadata
separate from the element data.

The generation counter never silently wraps: exhaustion raises an error.
`reset!` replaces the root generation. `close` invalidates its generation by
setting it to zero, then clears the mapping address. Finalization invalidates
all active generations, including explicit `finalize` calls inside nested
scopes. `close` and `reset!` are forbidden inside nested scopes.

Element and pointer access checks both the owner and generation. Every
published descriptor has a nonzero identifier: generation equality also
establishes that the mapping is open, without loading its address on every
access. Allocation, reset, and scope entry always verify that the mapping is
open. Shape queries such as `size` and `length` remain usable after
invalidation because they read only descriptor metadata.

Element conversions may run user code. Consequently, `setindex!` and `fill!`
recheck validity after conversion to prevent writes if a conversion closes or
resets the arena. Escaped raw pointers and direct mutation of internal fields
are outside this safety contract.

## Interfaces and design choices

The `DenseArray{T,N}` supertype expresses contiguous storage. `IndexLinear()`
and scalar methods support generic Julia interfaces: Cartesian indexing,
views, masks, iteration, and reductions. Array-producing operations use
`similar` or the broadcasting style and allocate from the active arena.
C and BLAS operations preserve descriptors through `cconvert`.

`Base.dataids`, another internal interface, provides a storage identifier for
alias detection and avoids unnecessary copies in broadcasting. Contiguous
copies between Goose arrays of the same type use `memmove` to support
overlapping storage. A `reshape` preserves the owner, address, and generation.

## Vectorizing checked element access

Writes through `unsafe_store!` carry very general alias metadata: the compiler
must assume they might modify metadata checked on subsequent iterations.
`payload.jl` uses Julia's internal LLVM TBAA category `jtbaa_arraybuf` for
writes of common scalar types. Generations are Julia object fields, separate
from element buffers. The compiler can therefore hoist repeated checks out of
loops whose bodies do not modify those checks, then vectorize the loops.

This is the same TBAA category used by `Array` buffers, preserving aliasing
with `unsafe_wrap(Array, pointer(a), ...)`. A private category claiming all
buffers to be disjoint would be incorrect. Tests include loops with a
dependency between a Goose array and an `Array` wrapping the same storage.
Unknown calls and metadata mutations still inhibit hoisting; no annotation
declares generations immutable.

This path covers `Bool`, native 8–128-bit integers, `Float16`/`Float32`/
`Float64`, `Char`, `ComplexF32`, and `ComplexF64`. Other `isbits` types use
generic storage. The TBAA tree is an internal implementation detail: the
optimization is enabled on Julia 1.13.x (tested on 1.13.3) and falls back to
the portable path on other versions. Performance is not guaranteed to match
across all element types.

Element storage does not require Julia `Vector` or `Memory` allocations. This
does not eliminate Julia's GC or JIT compilation. The arena is a virtual memory
region, not the CPU's native call stack.

## Materializing without generic collection

When a result has a concrete, positive-size `isbits` type, `map` allocates its
exact shape once and iterates over indices known to be valid. The loop does not
perform a bounds check for every element. It checks storage before reading,
and again after the callback and conversion, before writing. Pure operations
allow the compiler to hoist these checks. Unknown result types retain Julia's
generic collection path; static shape is restored without copying.
Same-shape unary broadcasting shares this path. Other broadcasts preserve
Base's fusion and indexing. Their newly allocated result does not need the
in-place path's destination alias analysis; unknown types retain the complete
generic fallback.

The public unary `map!` between Goose arrays uses this indexed loop as well,
performing `min(length(dest), length(src))` iterations, even across different
ranks. A longer destination keeps its remaining elements. An empty iteration
does not access any storage. As with Base assignment, the callback runs before
the destination check and conversion; validity is rechecked after conversion.
Aliasing follows index order and is never assumed independent.

Native numeric paths are restricted to `Float32` and `Float64`, whose arithmetic
cannot call user code. Owners and generations are checked once, indices follow
from validated dimensions, and `GC.@preserve` keeps all owners live during raw
memory access. Custom scalar operators stay on generic paths.

## Shared operands and multiple inputs

A scope state belongs to exactly one arena. After one operand is validated,
other descriptors sharing its scope state must still carry the same generation
token. A different scope retains its own generation check, and a different
arena retains its task-ownership check. This proof does not survive a callback.
`map` loops recheck sources before reading and destinations after callbacks and
conversions.

Operand tuples are expanded based on arity and types, never dynamic lengths or
arena identities. Shapes follow `zip` / Base conventions: minimum vector
length, vector output for differing ranks, and broadcast-compatible shape
promotion for matching higher ranks. Results are allocated in the first Goose
argument's arena, using its active scope. All-static inputs retain a static
shape; other combinations produce a `GooseArray`. Unknown or unsupported
result types use Base's generic collection.

Global numeric `+` reduction uses a private `AbstractVector` adapter containing
the mapping function, operands, and an `Int` length. Its `getindex` checks the
sources and computes one value; no mapped elements are stored. Base handles
pairwise / SIMD reduction, empty inputs, and `init`. Custom operators or `init`
and reductions along dimensions materialize the mapped result before a standard
reduction. `map` remains eager, and `sum(map(...))` still uses an intermediate.

Real-valued matrix–vector products use a native path for dynamic dimensions up
to 8, or up to 16 for a static matrix whose shape permits bounded unrolling.
Empty dimensions follow Base conventions. As with Base's `mul!`, the
destination must not alias the inputs. `axpy!` and `axpby!` support exact
aliasing and use BLAS beyond 2,048 elements. Storage remains `mmap`-backed;
none of these optimizations turns it into an inline tuple or native stack
allocation.
