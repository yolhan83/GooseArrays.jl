# Compatibility with FixedSizeArrays.jl

The goal is to offer a broad Julia array interface with arena-backed storage,
not a drop-in replacement for every constructor or extension in the original
package. An explicit arena owner is still required.

| Feature | GooseArrays 0.1 |
| --- | --- |
| Fixed-size mutable elements, arbitrary rank | Yes, including rank 0 |
| Dynamic lengths not encoded in the type | Yes for `GooseArray`; `StaticGooseArray` encodes its shape |
| `undef`, tuple, and separate-dimension constructors | Yes, with an explicit arena |
| Copy or convert an `AbstractArray` | Yes, with 1-based indices |
| Vector and matrix aliases | Yes |
| Linear / Cartesian / slice / mask indexing | Generic Julia interface |
| `size`, `length`, `axes`, `strides`, `elsize`, `isassigned` | Yes |
| Iteration, destructuring, reductions, `map` | Yes; unary `map` preserves static shapes |
| Unary and multi-input `map!` between Goose arrays | Indexed path; minimum length, aliasing, and conversion semantics as in Base |
| Multi-input `map` with Goose arrays | Typed result in the first arena; static if all inputs are static, Base fallback for unknown types |
| Multi-input `mapreduce` with Goose arrays | Native global numeric `+` reduction without an intermediate; fallback for custom `dims` / operators / `init` |
| `mul!(y,A,x)`, `axpy!`, `axpby!` | Short native real-valued kernels, BLAS for larger inputs, fallback for other scalar types |
| `similar`, `copy`, `copy!`, `copyto!` | Yes, without resizing |
| In-place and out-of-place broadcasting, fusion | Yes; results allocated in a Goose arena |
| Rank-0 broadcasting | Returns a scalar, as in Base |
| `reshape`, inferred `:` dimensions, `vec`, views | Yes, sharing storage |
| Pointers, C and BLAS calls, `mul!`, `dot` | Yes; raw pointer lifetime restrictions apply |
| `rand!` | Generic implementation, without a direct `Random` package dependency |
| Objects with GC-tracked references | Rejected; raw storage is not GC-scanned |
| `isbits Union` and zero-sized types | Rejected in this version |
| Explicit static dimensions | `StaticGooseArray` through aliases or `Val(tuple)`; no Static.jl dependency |
| Static matrix and vector products | Optional `LinearAlgebra` extension; preserves result shape |
| Conversion between static and dynamic shapes | Shared storage, no copy; preserves the original lifetime |
| Configurable `Vector` / `Memory` backend | Replaced with `DataStack`'s memory mapping |
| Ownerless `similar(Type, dims)` | No implicit global arena |
| Zero-copy wrapping of an existing `Vector` | Unsupported; the arena must own the storage |
| `collect_as`, StaticArrayInterface extensions | No dedicated dependencies or extensions |
| Adapt, GPU, MPI | No dedicated extensions or validated compatibility |
| `push!`, `resize!` | Unsupported, as expected for fixed-size arrays |

Explicit test coverage is in `test/runtests.jl`; inheriting generic algorithms
does not imply compatibility with every package in the Julia ecosystem. The
provided CI is intended to validate the supported Julia versions on macOS and
Linux. The original release archive was prepared without running remote CI.
