# Changelog

## 0.1.1 — 2026-10-31

Linux / Julia 1.10 compatibility fixes: `mul!` now handles `alpha == 0`
explicitly, without reading the operands (including in the BLAS path).
Allocation tests now force specialization of their variadic measurement helper.
Additional tests cover `NaN` inputs and scaling factors.

## 0.1.0 — 2026-10-31

First public release, based on the final prototype implementation: `DataStack`,
`GooseArray` (dynamic shape), `StaticGooseArray` (static shape), scoped lifetimes
and invalidation, multi-input `map` / `mapreduce`, broadcasting, and the
`LinearAlgebra` extension.

The prototype benchmark results (previously labeled internally as `0.6.0`)
are preserved as the initial reference. Earlier iterations and cross-version
comparison scripts are not included in this release.
