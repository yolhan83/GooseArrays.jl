# Five-vector comparison — GooseArrays (prototype measurements retained for v0.1)

Measurements from October 31, 2026: **1,406 cases** (996 original + 410 additional)
and **6,030 passing assertions**, using Julia 1.13.3 on an Apple M5 Max with
one Julia task and one BLAS thread.

Each cell reports **median time in nanoseconds / GC-allocated bytes**.
Arena initialization and compilation are excluded from these operations and
measured separately. `—` means **not measured**, never zero. Differences of a
few percent may be measurement noise.

The five vector types are measured at lengths 2, 3, 4, 8, 16, 32, 64, 100,
and 1,000. `MVector` cases with 10,000 or 100,000 elements are omitted to limit
StaticArrays code expansion and compilation; `StaticGooseArray` is measured at
those lengths.

### Vector mapping, reductions, and broadcasting

The mapping function is `map(x -> 2x+1, b)` and the reduction is
`mapreduce(abs2,+,b)`. Fused summation is `sum(x -> 2x+1, b)` and does not
materialize an intermediate result. Out-of-place operations are followed by
`sum` to consume the result, measuring the full pipeline. For arena-backed
arrays, this includes entering and leaving the scope.

| Size | Operation | Vector | FixedSizeVector | GooseVector | StaticGooseVector | MVector |
| ---: | --- | ---: | ---: | ---: | ---: | ---: |
| 2 | in-place map! | 2.6 / 0 | 2.4 / 0 | 2.9 / 0 | 2.9 / 0 | 1.5 / 0 |
| 2 | map then sum | 7.5 / 80 | 5.9 / 48 | 13.6 / 0 | 11.3 / 0 | 1.5 / 0 |
| 2 | fused sum(f) | 1.8 / 0 | 2.0 / 0 | 2.8 / 0 | 2.2 / 0 | 1.4 / 0 |
| 2 | abs2 reduction | 2.8 / 0 | 2.4 / 0 | 2.8 / 0 | 2.7 / 0 | 1.5 / 0 |
| 2 | in-place broadcast | 2.9 / 0 | 2.9 / 0 | 6.2 / 0 | 6.1 / 0 | 1.5 / 0 |
| 2 | broadcast then sum | 7.9 / 80 | 5.8 / 48 | 13.5 / 0 | 11.3 / 0 | 1.5 / 0 |
| 2 .* b .+ 1 then sum | 7.8 / 80 | 5.9 / 48 | 13.3 / 0 | 11.0 / 0 | 1.3 / 0 |
| 3 | in-place map! | 2.8 / 0 | 2.8 / 0 | 3.3 / 0 | 3.0 / 0 | 1.6 / 0 |
| 3 | map then sum | 8.1 / 80 | 6.0 / 48 | 13.8 / 0 | 13.7 / 0 | 1.6 / 0 |
| 3 | fused sum(f) | 1.8 / 0 | 2.0 / 0 | 2.8 / 0 | 2.7 / 0 | 1.7 / 0 |
| 3 | abs2 reduction | 3.0 / 0 | 2.6 / 0 | 2.8 / 0 | 2.7 / 0 | 1.5 / 0 |
| 3 | in-place broadcast | 3.1 / 0 | 3.1 / 0 | 6.4 / 0 | 5.9 / 0 | 1.8 / 0 |
| 3 | broadcast then sum | 8.4 / 80 | 6.2 / 48 | 13.9 / 0 | 13.5 / 0 | 1.8 / 0 |
| 3 | 2 .* b .+ 1 then sum | 8.3 / 80 | 6.1 / 48 | 13.9 / 0 | 13.7 / 0 | 1.5 / 0 |
| 4 | in-place map! | 3.0 / 0 | 3.0 / 0 | 3.4 / 0 | 3.2 / 0 | 1.8 / 0 |
| 4 | map then sum | 8.6 / 96 | 9.1 / 64 | 14.2 / 0 | 13.9 / 0 | 1.8 / 0 |
| 4 | fused sum(f) | 2.3 / 0 | 2.2 / 0 | 3.2 / 0 | 2.7 / 0 | 1.8 / 0 |
| 4 | abs2 reduction | 3.2 / 0 | 3.0 / 0 | 3.2 / 0 | 2.7 / 0 | 1.5 / 0 |
| 4 | in-place broadcast | 3.2 / 0 | 3.3 / 0 | 6.7 / 0 | 6.2 / 0 | 1.8 / 0 |
| 4 | broadcast then sum | 8.9 / 96 | 6.8 / 64 | 14.2 / 0 | 14.1 / 0 | 1.5 / 0 |
| 4 | 2 .* b .+ 1 then sum | 8.7 / 96 | 6.6 / 64 | 14.1 / 0 | 14.4 / 0 | 1.6 / 0 |
| 8 | in-place map! | 2.5 / 0 | 2.5 / 0 | 3.3 / 0 | 3.7 / 0 | 2.0 / 0 |
| 8 | map then sum | 10.3 / 128 | 9.2 / 96 | 14.7 / 0 | 15.1 / 0 | 2.0 / 0 |
| 8 | fused sum(f) | 3.5 / 0 | 3.0 / 0 | 4.2 / 0 | 2.8 / 0 | 2.0 / 0 |
| 8 | abs2 reduction | 3.9 / 0 | 4.3 / 0 | 4.1 / 0 | 2.9 / 0 | 1.7 / 0 |
| 8 | in-place broadcast | 3.2 / 0 | 3.3 / 0 | 6.5 / 0 | 7.1 / 0 | 1.8 / 0 |
| 8 | broadcast then sum | 9.2 / 128 | 7.1 / 96 | 14.3 / 0 | 15.2 / 0 | 2.0 / 0 |
| 8 | 2 .* b .+ 1 then sum | 9.0 / 128 | 7.0 / 96 | 14.6 / 0 | 14.6 / 0 | 2.0 / 0 |
| 16 | in-place map! | 2.7 / 0 | 2.8 / 0 | 3.8 / 0 | 4.8 / 0 | 3.0 / 0 |
| 16 | map then sum | 13.6 / 192 | 11.6 / 160 | 17.8 / 0 | 16.8 / 0 | 2.8 / 0 |
| 16 | fused sum(f) | 4.3 / 0 | 4.3 / 0 | 5.8 / 0 | 4.8 / 0 | 2.8 / 0 |
| 16 | abs2 reduction | 5.2 / 0 | 5.2 / 0 | 5.8 / 0 | 4.8 / 0 | 2.2 / 0 |
| 16 | in-place broadcast | 3.9 / 0 | 3.8 / 0 | 7.1 / 0 | 8.0 / 0 | 2.5 / 0 |
| 16 | broadcast then sum | 12.6 / 192 | 10.0 / 160 | 17.5 / 0 | 16.2 / 0 | 2.8 / 0 |
| 16 | 2 .* b .+ 1 then sum | 12.5 / 192 | 10.0 / 160 | 17.9 / 0 | 17.1 / 0 | 2.8 / 0 |
| 32 | in-place map! | 3.5 / 0 | 3.7 / 0 | 5.0 / 0 | 4.7 / 0 | 5.2 / 0 |
| 32 | map then sum | 16.0 / 320 | 13.9 / 288 | 18.9 / 0 | 16.9 / 0 | 5.5 / 0 |
| 32 | fused sum(f) | 5.3 / 0 | 5.5 / 0 | 6.8 / 0 | 5.9 / 0 | 5.5 / 0 |
| 32 | abs2 reduction | 5.7 / 0 | 6.1 / 0 | 6.3 / 0 | 5.8 / 0 | 3.7 / 0 |
| 32 | in-place broadcast | 5.2 / 0 | 5.1 / 0 | 8.6 / 0 | 7.8 / 0 | 4.2 / 0 |
| 32 | broadcast then sum | 15.5 / 320 | 13.1 / 288 | 18.3 / 0 | 16.6 / 0 | 5.5 / 0 |
| 32 | 2 .* b .+ 1 then sum | 15.1 / 320 | 12.9 / 288 | 18.8 / 0 | 16.3 / 0 | 5.5 / 0 |
| 64 | in-place map! | 5.1 / 0 | 5.5 / 0 | 7.0 / 0 | 6.9 / 0 | 9.3 / 0 |
| 64 | map then sum | 21.0 / 576 | 18.6 / 544 | 20.8 / 0 | 20.4 / 0 | 13.7 / 0 |
| 64 | fused sum(f) | 6.9 / 0 | 7.1 / 0 | 8.4 / 0 | 7.7 / 0 | 11.3 / 0 |
| 64 | abs2 reduction | 7.0 / 0 | 7.0 / 0 | 7.4 / 0 | 6.8 / 0 | 9.0 / 0 |
| 64 | in-place broadcast | 7.2 / 0 | 7.2 / 0 | 11.4 / 0 | 11.4 / 0 | 14.3 / 0 |
| 64 | broadcast then sum | 21.3 / 576 | 18.8 / 544 | 21.0 / 0 | 19.8 / 0 | 13.7 / 0 |
| 64 | 2 .* b .+ 1 then sum | 21.0 / 576 | 18.5 / 544 | 21.1 / 0 | 19.8 / 0 | 13.7 / 0 |
| 100 | in-place map! | 8.1 / 0 | 8.0 / 0 | 9.4 / 0 | 9.4 / 0 | 14.0 / 0 |
| 100 | map then sum | 25.9 / 928 | 24.1 / 896 | 24.4 / 0 | 23.0 / 0 | 26.6 / 0 |
| 100 | fused sum(f) | 9.4 / 0 | 9.4 / 0 | 9.5 / 0 | 9.7 / 0 | 20.1 / 0 |
| 100 | abs2 reduction | 7.6 / 0 | 7.2 / 0 | 8.1 / 0 | 6.8 / 0 | 16.5 / 0 |
| 100 | in-place broadcast | 9.2 / 0 | 9.4 / 0 | 16.8 / 0 | 14.9 / 0 | 26.5 / 0 |
| 100 | broadcast then sum | 26.4 / 928 | 24.5 / 896 | 24.9 / 0 | 22.2 / 0 | 26.6 / 0 |
| 100 | 2 .* b .+ 1 then sum | 27.4 / 928 | 25.2 / 896 | 25.2 / 0 | 22.8 / 0 | 26.6 / 0 |
| 1000 | in-place map! | 66.2 / 0 | 67.7 / 0 | 66.8 / 0 | 66.5 / 0 | 133.1 / 0 |
| 1000 | map then sum | 217.0 / 8256 | 211.0 / 8224 | 156.1 / 0 | 152.7 / 0 | 589.8 / 0 |
| 1000 | fused sum(f) | 87.7 / 0 | 87.7 / 0 | 87.8 / 0 | 87.8 / 0 | 421.9 / 0 |
| 1000 | abs2 reduction | 79.2 / 0 | 78.5 / 0 | 77.9 / 0 | 79.2 / 0 | 409.8 / 0 |
| 1000 | in-place broadcast | 67.8 / 0 | 69.5 / 0 | 73.7 / 0 | 71.2 / 0 | 283.7 / 0 |
| 1000 | broadcast then sum | 196.4 / 8256 | 194.4 / 8224 | 156.2 / 0 | 153.4 / 0 | 590.0 / 0 |
| 1000 | 2 .* b .+ 1 then sum | 195.9 / 8256 | 194.2 / 8224 | 156.1 / 0 | 152.6 / 0 | 589.6 / 0 |
| 10000 | in-place map! | 779.0 / 0 | 686.9 / 0 | 697.7 / 0 | 720.6 / 0 | — |
| 10000 | map then sum | 2259.2 / 81984 | 2263.9 / 81952 | 1641.7 / 0 | 1620.8 / 0 | — |
| 10000 | fused sum(f) | 891.9 / 0 | 896.7 / 0 | 890.0 / 0 | 889.2 / 0 | — |
| 10000 | abs2 reduction | 962.3 / 0 | 973.6 / 0 | 961.2 / 0 | 960.3 / 0 | — |
| 10000 | in-place broadcast | 705.1 / 0 | 669.5 / 0 | 783.8 / 0 | 725.9 / 0 | — |
| 10000 | broadcast then sum | 2222.2 / 81984 | 2158.3 / 81952 | 1641.7 / 0 | 1625.0 / 0 | — |
| 10000 | 2 .* b .+ 1 then sum | 2287.1 / 81984 | 2150.0 / 81952 | 1637.5 / 0 | 1633.3 / 0 | — |
| 100000 | in-place map! | 12125.0 / 0 | 12250.0 / 0 | 12084.0 / 0 | 12277.7 / 0 | — |
| 100000 | map then sum | 22125.0 / 802880 | 22125.0 / 802848 | 20417.0 / 0 | 20375.0 / 0 | — |
| 100000 | fused sum(f) | 8847.0 / 0 | 8819.3 / 0 | 8861.3 / 0 | 8875.0 / 0 | — |
| 100000 | abs2 reduction | 10000.0 / 0 | 10000.0 / 0 | 9958.0 / 0 | 9959.0 / 0 | — |
| 100000 | in-place broadcast | 12083.0 / 0 | 12292.0 / 0 | 12125.0 / 0 | 12042.0 / 0 | — |
| 100000 | broadcast then sum | 21791.0 / 802880 | 21791.0 / 802848 | 20417.0 / 0 | 20375.0 / 0 | — |
| 100000 | 2 .* b .+ 1 then sum | 21791.0 / 802880 | 21792.0 / 802848 | 20375.0 / 0 | 20500.0 / 0 | — |

### Matrix multiplication

Square `Float64` matrices. `mul!` uses a preallocated destination; multiplying
and then summing includes allocation and consumption of the result. `MMatrix`
is only measured up to 16×16.

| Size | Operation | Matrix | FixedSizeMatrix | GooseMatrix | StaticGooseMatrix | MMatrix |
| ---: | --- | ---: | ---: | ---: | ---: | ---: |
| 2×2 | in-place mul! | 12.4 / 0 | 18.2 / 0 | 9.2 / 0 | 6.0 / 0 | 2.3 / 0 |
| 2×2 | multiply then sum | 19.3 / 112 | 47.1 / 64 | 20.3 / 0 | 17.5 / 0 | 1.6 / 0 |
| 3×3 | in-place mul! | 14.1 / 0 | 19.5 / 0 | 15.5 / 0 | 7.7 / 0 | 3.2 / 0 |
| 3×3 | multiply then sum | 22.7 / 144 | 49.7 / 96 | 25.1 / 0 | 19.3 / 0 | 2.5 / 0 |
| 4×4 | in-place mul! | 45.5 / 0 | 49.0 / 0 | 28.3 / 0 | 10.8 / 0 | 3.7 / 0 |
| 4×4 | multiply then sum | 54.6 / 208 | 66.2 / 160 | 39.3 / 0 | 23.7 / 0 | 3.6 / 0 |
| 8×8 | in-place mul! | 84.4 / 0 | 86.6 / 0 | 81.9 / 0 | 79.6 / 0 | 28.3 / 0 |
| 8×8 | multiply then sum | 95.2 / 592 | 106.4 / 544 | 102.8 / 0 | 91.3 / 0 | 76.7 / 0 |
| 16×16 | in-place mul! | 232.1 / 0 | 235.0 / 0 | 228.3 / 0 | 225.5 / 0 | 220.4 / 0 |
| 16×16 | multiply then sum | 285.3 / 2128 | 309.2 / 2080 | 268.2 / 0 | 256.2 / 0 | 294.6 / 0 |
| 64×64 | in-place mul! | 19042.0 / 0 | 20708.0 / 0 | 19209.0 / 0 | 19125.0 / 0 | — |
| 64×64 | multiply then sum | 21208.0 / 32848 | 19625.0 / 32800 | 19500.0 / 0 | 19417.0 / 0 | — |
| 256×256 | in-place mul! | 653979.0 / 0 | 655292.0 / 0 | 653145.5 / 0 | 656021.0 / 0 | — |
| 256×256 | multiply then sum | 666083.0 / 524368 | 659292.0 / 524320 | 660541.0 / 0 | 659458.0 / 0 | — |

Additional operations, construction allocations, `SVector` / `SMatrix`, and
specialization are covered below and in the CSV files under
`benchmark/reference/m5-max-2026-10-31/`.

### Multiple inputs and scaling operations

Functions: f₂(x,y)=x*y and f₃(x,y,z)=x+y*z. Mapping followed by summation
remains two operations and materializes an intermediate result. Native global
numeric `+` `mapreduce` implementations do not store mapped elements. For Goose
arrays, out-of-place operations and multi-input reductions use the same scope
per invocation across all four benchmark groups, including after temporaries
are released. `axpy!` uses α=0.25; `axpby!` uses α=0.25 and β=0.5. All 410
additional cases use the same kernels at each stage.

| Size | Operation | Vector | FixedSizeVector | GooseVector | StaticGooseVector | MVector |
| ---: | --- | ---: | ---: | ---: | ---: | ---: |
| 2 | two-input map! | 4.2 / 0 | 2.5 / 0 | 3.0 / 0 | 3.0 / 0 | 3.7 / 0 |
| 2 | three-input map! | 6.4 / 0 | 6.8 / 0 | 3.8 / 0 | 3.5 / 0 | 3.8 / 0 |
| 2 | two-input map then sum | 9.5 / 80 | 10.1 / 80 | 15.4 / 0 | 12.4 / 0 | 1.6 / 0 |
| 2 | three-input map then sum | 10.3 / 80 | 10.9 / 80 | 15.7 / 0 | 12.2 / 0 | 1.5 / 0 |
| 2 | two-input mapreduce | 9.5 / 80 | 10.2 / 80 | 12.8 / 0 | 11.8 / 0 | 1.5 / 0 |
| 2 | three-input mapreduce | 10.2 / 80 | 11.0 / 80 | 13.2 / 0 | 11.3 / 0 | 1.5 / 0 |
| 2 | axpy! | 5.1 / 0 | 5.9 / 0 | 3.0 / 0 | 4.0 / 0 | 3.8 / 0 |
| 2 | axpby! | 4.8 / 0 | 5.0 / 0 | 3.0 / 0 | 4.7 / 0 | 4.2 / 0 |
| 3 | two-input map! | 4.4 / 0 | 3.0 / 0 | 3.2 / 0 | 3.1 / 0 | 3.7 / 0 |
| 3 | three-input map! | 6.6 / 0 | 7.2 / 0 | 4.1 / 0 | 3.7 / 0 | 3.8 / 0 |
| 3 | two-input map then sum | 10.0 / 80 | 10.6 / 80 | 15.4 / 0 | 15.3 / 0 | 1.5 / 0 |
| 3 | three-input map then sum | 10.8 / 80 | 11.4 / 80 | 15.3 / 0 | 14.8 / 0 | 1.8 / 0 |
| 3 | two-input mapreduce | 10.0 / 80 | 10.6 / 80 | 12.8 / 0 | 11.7 / 0 | 1.6 / 0 |
| 3 | three-input mapreduce | 10.8 / 80 | 11.4 / 80 | 13.2 / 0 | 11.4 / 0 | 1.6 / 0 |
| 3 | axpy! | 5.4 / 0 | 6.0 / 0 | 3.2 / 0 | 4.1 / 0 | 3.6 / 0 |
| 3 | axpby! | 5.3 / 0 | 5.2 / 0 | 3.1 / 0 | 4.7 / 0 | 4.3 / 0 |
| 4 | two-input map! | 5.0 / 0 | 3.0 / 0 | 3.5 / 0 | 3.3 / 0 | 3.9 / 0 |
| 4 | three-input map! | 6.8 / 0 | 7.4 / 0 | 4.4 / 0 | 4.0 / 0 | 4.0 / 0 |
| 4 | two-input map then sum | 10.5 / 96 | 10.9 / 96 | 15.5 / 0 | 15.7 / 0 | 1.8 / 0 |
| 4 | three-input map then sum | 11.2 / 96 | 11.9 / 96 | 15.7 / 0 | 15.2 / 0 | 1.8 / 0 |
| 4 | two-input mapreduce | 10.4 / 96 | 10.9 / 96 | 12.8 / 0 | 11.5 / 0 | 1.8 / 0 |
| 4 | three-input mapreduce | 11.2 / 96 | 12.0 / 96 | 13.5 / 0 | 11.8 / 0 | 1.8 / 0 |
| 4 | axpy! | 5.8 / 0 | 6.3 / 0 | 3.4 / 0 | 4.1 / 0 | 3.8 / 0 |
| 4 | axpby! | 5.3 / 0 | 5.3 / 0 | 3.3 / 0 | 4.8 / 0 | 4.3 / 0 |
| 8 | two-input map! | 5.8 / 0 | 4.2 / 0 | 3.5 / 0 | 3.9 / 0 | 4.8 / 0 |
| 8 | three-input map! | 6.6 / 0 | 7.0 / 0 | 4.2 / 0 | 4.8 / 0 | 5.5 / 0 |
| 8 | two-input map then sum | 11.9 / 128 | 12.3 / 128 | 15.9 / 0 | 16.1 / 0 | 2.0 / 0 |
| 8 | three-input map then sum | 13.0 / 128 | 13.6 / 128 | 17.1 / 0 | 16.3 / 0 | 2.3 / 0 |
| 8 | two-input mapreduce | 11.8 / 128 | 12.3 / 128 | 12.8 / 0 | 11.2 / 0 | 2.0 / 0 |
| 8 | three-input mapreduce | 13.0 / 128 | 13.8 / 128 | 13.7 / 0 | 11.4 / 0 | 2.3 / 0 |
| 8 | axpy! | 6.9 / 0 | 7.6 / 0 | 3.4 / 0 | 4.3 / 0 | 4.0 / 0 |
| 8 | axpby! | 5.5 / 0 | 5.5 / 0 | 3.9 / 0 | 4.8 / 0 | 4.7 / 0 |
| 16 | two-input map! | 6.6 / 0 | 5.0 / 0 | 4.2 / 0 | 5.3 / 0 | 6.4 / 0 |
| 16 | three-input map! | 7.5 / 0 | 7.7 / 0 | 5.2 / 0 | 7.6 / 0 | 9.5 / 0 |
| 16 | two-input map then sum | 15.5 / 192 | 16.1 / 192 | 18.2 / 0 | 17.9 / 0 | 2.7 / 0 |
| 16 | three-input map then sum | 17.0 / 192 | 17.7 / 192 | 19.0 / 0 | 18.5 / 0 | 3.5 / 0 |
| 16 | two-input mapreduce | 14.8 / 192 | 15.1 / 192 | 19.0 / 0 | 15.7 / 0 | 2.7 / 0 |
| 16 | three-input mapreduce | 16.3 / 192 | 17.1 / 192 | 21.6 / 0 | 18.6 / 0 | 3.5 / 0 |
| 16 | axpy! | 8.5 / 0 | 9.4 / 0 | 4.2 / 0 | 6.0 / 0 | 5.8 / 0 |
| 16 | axpby! | 6.0 / 0 | 5.9 / 0 | 4.5 / 0 | 6.5 / 0 | 6.0 / 0 |
| 64 | two-input map! | 10.5 / 0 | 8.9 / 0 | 8.2 / 0 | 7.8 / 0 | 15.1 / 0 |
| 64 | three-input map! | 14.4 / 0 | 12.7 / 0 | 11.2 / 0 | 10.6 / 0 | 20.8 / 0 |
| 64 | two-input map then sum | 23.3 / 576 | 23.9 / 576 | 22.2 / 0 | 20.5 / 0 | 13.3 / 0 |
| 64 | three-input map then sum | 26.0 / 576 | 26.2 / 576 | 26.3 / 0 | 24.3 / 0 | 16.8 / 0 |
| 64 | two-input mapreduce | 23.4 / 576 | 23.0 / 576 | 20.7 / 0 | 18.0 / 0 | 10.9 / 0 |
| 64 | three-input mapreduce | 25.5 / 576 | 25.5 / 576 | 25.8 / 0 | 22.6 / 0 | 14.1 / 0 |
| 64 | axpy! | 10.6 / 0 | 10.7 / 0 | 8.1 / 0 | 7.7 / 0 | 7.6 / 0 |
| 64 | axpby! | 10.8 / 0 | 10.5 / 0 | 8.4 / 0 | 8.3 / 0 | 8.1 / 0 |
| 1000 | two-input map! | 95.3 / 0 | 93.3 / 0 | 93.0 / 0 | 92.9 / 0 | 177.0 / 0 |
| 1000 | three-input map! | 128.0 / 0 | 126.0 / 0 | 124.9 / 0 | 124.2 / 0 | 252.9 / 0 |
| 1000 | two-input map then sum | 227.3 / 8256 | 230.1 / 8256 | 168.7 / 0 | 168.9 / 0 | 621.4 / 0 |
| 1000 | three-input map then sum | 249.2 / 8256 | 261.9 / 8256 | 204.3 / 0 | 203.8 / 0 | 772.7 / 0 |
| 1000 | two-input mapreduce | 227.7 / 8256 | 231.1 / 8256 | 105.0 / 0 | 103.9 / 0 | 441.2 / 0 |
| 1000 | three-input mapreduce | 249.6 / 8256 | 261.5 / 8256 | 138.8 / 0 | 136.2 / 0 | 523.0 / 0 |
| 1000 | axpy! | 86.1 / 0 | 87.5 / 0 | 92.4 / 0 | 92.2 / 0 | 93.0 / 0 |
| 1000 | axpby! | 94.4 / 0 | 94.4 / 0 | 92.6 / 0 | 92.0 / 0 | 93.3 / 0 |
| 10000 | two-input map! | 1600.0 / 0 | 1720.8 / 0 | 1733.4 / 0 | 1333.3 / 0 | — |
| 10000 | three-input map! | 2408.4 / 0 | 2449.0 / 0 | 2279.2 / 0 | 1795.9 / 0 | — |
| 10000 | two-input map then sum | 2884.3 / 81984 | 2870.3 / 81984 | 2361.1 / 0 | 2365.8 / 0 | — |
| 10000 | three-input map then sum | 3614.5 / 81984 | 3609.4 / 81984 | 3083.3 / 0 | 3069.4 / 0 | — |
| 10000 | two-input mapreduce | 2888.9 / 81984 | 2819.4 / 81984 | 1065.1 / 0 | 1064.1 / 0 | — |
| 10000 | three-input mapreduce | 3645.8 / 81984 | 3625.0 / 81984 | 1629.1 / 0 | 1620.9 / 0 | — |
| 10000 | axpy! | 1395.8 / 0 | 1470.8 / 0 | 1362.5 / 0 | 1481.2 / 0 | — |
| 10000 | axpby! | 1454.2 / 0 | 1533.3 / 0 | 1529.2 / 0 | 1529.1 / 0 | — |
| 100000 | two-input map! | 18291.5 / 0 | 18958.0 / 0 | 18917.0 / 0 | 18875.0 / 0 | — |
| 100000 | three-input map! | 25125.0 / 0 | 25125.0 / 0 | 25083.0 / 0 | 25125.0 / 0 | — |
| 100000 | two-input map then sum | 28375.0 / 802880 | 28375.0 / 802880 | 27791.0 / 0 | 27833.0 / 0 | — |
| 100000 | three-input map then sum | 34916.0 / 802880 | 35042.0 / 802880 | 33917.0 / 0 | 33875.0 / 0 | — |
| 100000 | two-input mapreduce | 28334.0 / 802880 | 28417.0 / 802880 | 12458.0 / 0 | 12459.0 / 0 | — |
| 100000 | three-input mapreduce | 35000.0 / 802880 | 34875.0 / 802880 | 19291.0 / 0 | 19333.0 / 0 | — |
| 100000 | axpy! | 15417.0 / 0 | 15375.0 / 0 | 15250.0 / 0 | 15375.0 / 0 | — |
| 100000 | axpby! | 15375.0 / 0 | 15375.0 / 0 | 15417.0 / 0 | 15458.0 / 0 | — |

### Matrix–vector products

Square n×n matrices and n-element vectors. `mul!` uses a preallocated
output; multiplication followed by summation includes allocation and
consumption of the result, as in the matrix–matrix benchmarks.

| Size | Operation | Matrix × Vector | FixedSizeMatrix × FixedSizeVector | GooseMatrix × GooseVector | StaticGooseMatrix × StaticGooseVector | MMatrix × MVector |
| ---: | --- | ---: | ---: | ---: | ---: | ---: |
| 2×2 | matrix–vector mul! | 19.7 / 0 | 19.4 / 0 | 6.2 / 0 | 4.2 / 0 | 5.2 / 0 |
| 2×2 | multiply then sum | 28.3 / 80 | 27.5 / 48 | 19.5 / 0 | 16.7 / 0 | 1.6 / 0 |
| 3×3 | matrix–vector mul! | 30.4 / 0 | 31.7 / 0 | 7.4 / 0 | 4.7 / 0 | 5.7 / 0 |
| 3×3 | multiply then sum | 38.7 / 80 | 38.7 / 48 | 20.6 / 0 | 17.7 / 0 | 1.8 / 0 |
| 4×4 | matrix–vector mul! | 21.5 / 0 | 20.0 / 0 | 11.0 / 0 | 5.1 / 0 | 6.5 / 0 |
| 4×4 | multiply then sum | 29.2 / 96 | 28.0 / 64 | 21.5 / 0 | 17.6 / 0 | 2.1 / 0 |
| 8×8 | matrix–vector mul! | 34.5 / 0 | 34.8 / 0 | 23.3 / 0 | 10.9 / 0 | 14.1 / 0 |
| 8×8 | multiply then sum | 46.5 / 128 | 44.9 / 96 | 34.9 / 0 | 20.6 / 0 | 4.5 / 0 |
| 16×16 | matrix–vector mul! | 65.9 / 0 | 65.3 / 0 | 70.5 / 0 | 16.7 / 0 | 42.5 / 0 |
| 16×16 | multiply then sum | 78.9 / 192 | 77.6 / 160 | 106.1 / 0 | 25.8 / 0 | 19.6 / 0 |
| 64×64 | matrix–vector mul! | 453.1 / 0 | 452.9 / 0 | 456.2 / 0 | 455.2 / 0 | — |
| 64×64 | multiply then sum | 605.8 / 576 | 607.4 / 544 | 502.6 / 0 | 469.5 / 0 | — |
| 256×256 | matrix–vector mul! | 7708.2 / 0 | 7708.4 / 0 | 7718.8 / 0 | 7718.8 / 0 | — |
| 256×256 | multiply then sum | 8078.1 / 2112 | 7927.2 / 2080 | 7770.8 / 0 | 7750.0 / 0 | — |

## Exact benchmark environment

```text
GooseArrays: 0.6.0 (measured before the prototype was renamed to v0.1.0)
Julia: 1.13.3; kernel: Darwin; architecture: aarch64
CPU: Apple M5 Max
Julia threads: 1; BLAS threads: 1
FixedSizeArrays: 1.5.1
StaticArrays: 1.9.24
BenchmarkTools: 1.8.0
Seconds per case: 0.25; max samples: 3000
Lengths: 2,3,4,8,16,32,64,100,1000,10000,100000; StaticArrays max: 1000
Square matrix sides: 2,3,4,8,16,64,256
BLAS: LBTConfig([ILP64] libopenblas64_.0.3.30.dylib)
```

Additional benchmark campaign:

```text
GooseArrays=0.6.0 (measured before the prototype was renamed to v0.1.0)
Julia=1.13.3
CPU=Apple M5 Max
BLAS=LBTConfig([ILP64] libopenblas64_.0.3.30.dylib)
threads=1, BLAS=1
seconds=0.25, samples=3000
lengths=2,3,4,8,16,64,1000,10000,100000
StaticGoose max=100000
sides=2,3,4,8,16,64,256
```

The four packages are Base, FixedSizeArrays, GooseArrays, and StaticArrays.
The five vector columns contain mutable vectors. Immutable `SVector` and
`SMatrix` provide additional reference points, not replacements for in-place
operations.

## Construction, indexing, and additional operations

Units: nanoseconds / GC bytes. Escaping constructors store their result in
`Ref{Any}`; arena cases call `reset!` to reuse storage. Construction plus
computation fills the array with 2 and then reduces it. This workload can be
optimized substantially when the array length is known.

| Size | Operation | Vector | FixedSizeVector | GooseVector | StaticGooseVector | MVector |
| ---: | --- | ---: | ---: | ---: | ---: | ---: |
| 2 | escaping construction | 6.7 / 80 | 7.7 / 80 | 7.5 / 64 | 9.4 / 48 | 3.4 / 32 |
| 2 | construct + fill + sum | 8.1 / 80 | 6.0 / 48 | 13.5 / 0 | 11.0 / 0 | 3.7 / 32 |
| 2 | fill! | 1.5 / 0 | 1.4 / 0 | 2.9 / 0 | 2.8 / 0 | 1.1 / 0 |
| 2 | sum | 1.8 / 0 | 1.2 / 0 | 2.2 / 0 | 2.0 / 0 | 1.1 / 0 |
| 2 | indexing | 1.1 / 0 | 1.3 / 0 | 2.2 / 0 | 2.3 / 0 | 1.1 / 0 |
| 2 | copyto! | 2.8 / 0 | 3.0 / 0 | 5.8 / 0 | 4.6 / 0 | 1.5 / 0 |
| 2 | dot | 6.2 / 0 | 6.5 / 0 | 2.5 / 0 | 2.2 / 0 | 1.1 / 0 |
| 2 | affine loop | 2.0 / 0 | 2.2 / 0 | 2.9 / 0 | 2.7 / 0 | 1.5 / 0 |
| 2 | in-place broadcast expression | 3.0 / 0 | 2.9 / 0 | 6.4 / 0 | 5.4 / 0 | 1.4 / 0 |
| 3 | escaping construction | 7.0 / 80 | 8.1 / 80 | 7.4 / 64 | 9.4 / 48 | 3.4 / 32 |
| 3 | construct + fill + sum | 9.0 / 80 | 7.8 / 48 | 14.7 / 0 | 14.7 / 0 | 3.7 / 32 |
| 3 | fill! | 1.8 / 0 | 1.8 / 0 | 4.1 / 0 | 4.5 / 0 | 1.1 / 0 |
| 3 | sum | 1.3 / 0 | 1.5 / 0 | 2.3 / 0 | 2.3 / 0 | 1.1 / 0 |
| 3 | indexing | 1.1 / 0 | 1.3 / 0 | 2.2 / 0 | 2.2 / 0 | 1.1 / 0 |
| 3 | copyto! | 3.0 / 0 | 3.1 / 0 | 5.9 / 0 | 4.9 / 0 | 1.7 / 0 |
| 3 | dot | 6.6 / 0 | 6.8 / 0 | 2.5 / 0 | 2.2 / 0 | 1.3 / 0 |
| 3 | affine loop | 2.4 / 0 | 2.5 / 0 | 3.3 / 0 | 3.0 / 0 | 1.6 / 0 |
| 3 | in-place broadcast expression | 3.0 / 0 | 3.1 / 0 | 6.4 / 0 | 5.9 / 0 | 1.8 / 0 |
| 4 | escaping construction | 7.3 / 96 | 8.3 / 96 | 7.2 / 64 | 9.4 / 48 | 3.6 / 48 |
| 4 | construct + fill + sum | 15.8 / 96 | 9.3 / 64 | 13.8 / 0 | 13.7 / 0 | 3.8 / 48 |
| 4 | fill! | 2.0 / 0 | 2.0 / 0 | 3.2 / 0 | 2.9 / 0 | 1.0 / 0 |
| 4 | sum | 1.8 / 0 | 1.3 / 0 | 2.8 / 0 | 2.3 / 0 | 1.1 / 0 |
| 4 | indexing | 1.1 / 0 | 1.2 / 0 | 2.2 / 0 | 2.2 / 0 | 1.1 / 0 |
| 4 | copyto! | 3.2 / 0 | 3.5 / 0 | 6.1 / 0 | 4.9 / 0 | 1.6 / 0 |
| 4 | dot | 6.9 / 0 | 7.0 / 0 | 2.6 / 0 | 2.2 / 0 | 1.3 / 0 |
| 4 | affine loop | 2.4 / 0 | 2.6 / 0 | 3.5 / 0 | 3.0 / 0 | 1.8 / 0 |
| 4 | in-place broadcast expression | 3.2 / 0 | 3.3 / 0 | 6.7 / 0 | 6.1 / 0 | 1.8 / 0 |
| 8 | escaping construction | 8.1 / 128 | 8.7 / 128 | 7.4 / 64 | 9.6 / 48 | 4.0 / 80 |
| 8 | construct + fill + sum | 9.6 / 128 | 7.5 / 96 | 15.0 / 0 | 14.7 / 0 | 4.4 / 80 |
| 8 | fill! | 1.5 / 0 | 1.7 / 0 | 3.9 / 0 | 3.8 / 0 | 1.2 / 0 |
| 8 | sum | 2.6 / 0 | 2.2 / 0 | 3.7 / 0 | 2.3 / 0 | 1.3 / 0 |
| 8 | indexing | 1.1 / 0 | 1.3 / 0 | 2.2 / 0 | 2.2 / 0 | 0.9 / 0 |
| 8 | copyto! | 2.8 / 0 | 3.4 / 0 | 6.0 / 0 | 5.2 / 0 | 2.1 / 0 |
| 8 | dot | 7.8 / 0 | 7.8 / 0 | 2.5 / 0 | 2.2 / 0 | 1.3 / 0 |
| 8 | affine loop | 2.4 / 0 | 2.3 / 0 | 3.3 / 0 | 3.7 / 0 | 2.0 / 0 |
| 8 | in-place broadcast expression | 3.2 / 0 | 3.2 / 0 | 6.5 / 0 | 7.1 / 0 | 1.8 / 0 |
| 16 | escaping construction | 14.0 / 192 | 20.6 / 192 | 7.7 / 64 | 9.6 / 48 | 10.3 / 144 |
| 16 | construct + fill + sum | 14.2 / 192 | 10.0 / 160 | 17.3 / 0 | 15.1 / 0 | 5.5 / 144 |
| 16 | fill! | 1.8 / 0 | 2.1 / 0 | 3.9 / 0 | 3.8 / 0 | 1.5 / 0 |
| 16 | sum | 5.0 / 0 | 3.9 / 0 | 5.1 / 0 | 4.1 / 0 | 1.5 / 0 |
| 16 | indexing | 1.1 / 0 | 1.3 / 0 | 2.4 / 0 | 2.2 / 0 | 1.1 / 0 |
| 16 | copyto! | 3.1 / 0 | 3.8 / 0 | 6.7 / 0 | 5.8 / 0 | 3.1 / 0 |
| 16 | dot | 9.8 / 0 | 9.5 / 0 | 3.0 / 0 | 2.8 / 0 | 2.0 / 0 |
| 16 | affine loop | 2.5 / 0 | 2.8 / 0 | 3.9 / 0 | 4.8 / 0 | 2.9 / 0 |
| 16 | in-place broadcast expression | 3.9 / 0 | 3.8 / 0 | 7.0 / 0 | 8.2 / 0 | 2.5 / 0 |
| 32 | escaping construction | 21.2 / 320 | 32.0 / 320 | 7.6 / 64 | 9.7 / 48 | 6.0 / 272 |
| 32 | construct + fill + sum | 17.6 / 320 | 12.3 / 288 | 19.0 / 0 | 17.1 / 0 | 8.0 / 272 |
| 32 | fill! | 2.8 / 0 | 3.2 / 0 | 5.0 / 0 | 4.8 / 0 | 2.4 / 0 |
| 32 | sum | 5.8 / 0 | 5.0 / 0 | 5.7 / 0 | 4.4 / 0 | 2.3 / 0 |
| 32 | indexing | 1.1 / 0 | 1.3 / 0 | 2.3 / 0 | 2.2 / 0 | 1.1 / 0 |
| 32 | copyto! | 4.2 / 0 | 5.0 / 0 | 7.4 / 0 | 6.5 / 0 | 5.2 / 0 |
| 32 | dot | 7.8 / 0 | 7.8 / 0 | 4.4 / 0 | 4.0 / 0 | 3.0 / 0 |
| 32 | affine loop | 3.5 / 0 | 3.5 / 0 | 4.9 / 0 | 4.4 / 0 | 3.0 / 0 |
| 32 | in-place broadcast expression | 5.2 / 0 | 5.0 / 0 | 8.7 / 0 | 7.5 / 0 | 4.2 / 0 |
| 64 | escaping construction | 18.3 / 576 | 20.0 / 576 | 7.8 / 64 | 10.0 / 48 | 7.3 / 544 |
| 64 | construct + fill + sum | 22.6 / 576 | 17.6 / 544 | 21.0 / 0 | 21.0 / 0 | 15.1 / 544 |
| 64 | fill! | 4.5 / 0 | 5.0 / 0 | 7.2 / 0 | 7.5 / 0 | 4.1 / 0 |
| 64 | sum | 6.9 / 0 | 5.7 / 0 | 7.0 / 0 | 6.0 / 0 | 5.9 / 0 |
| 64 | indexing | 0.9 / 0 | 1.3 / 0 | 2.4 / 0 | 2.3 / 0 | 0.9 / 0 |
| 64 | copyto! | 6.4 / 0 | 7.1 / 0 | 9.3 / 0 | 9.0 / 0 | 4.8 / 0 |
| 64 | dot | 10.3 / 0 | 10.4 / 0 | 6.9 / 0 | 6.9 / 0 | 5.5 / 0 |
| 64 | affine loop | 5.2 / 0 | 5.6 / 0 | 6.9 / 0 | 6.7 / 0 | 4.8 / 0 |
| 64 | in-place broadcast expression | 7.2 / 0 | 7.2 / 0 | 11.9 / 0 | 9.6 / 0 | 14.3 / 0 |
| 100 | escaping construction | 18.7 / 928 | 20.2 / 928 | 7.7 / 64 | 9.7 / 48 | 8.2 / 816 |
| 100 | construct + fill + sum | 25.1 / 928 | 23.8 / 896 | 23.8 / 0 | 22.5 / 0 | 30.3 / 816 |
| 100 | fill! | 7.1 / 0 | 7.4 / 0 | 9.2 / 0 | 9.0 / 0 | 8.1 / 0 |
| 100 | sum | 6.4 / 0 | 6.2 / 0 | 7.2 / 0 | 6.4 / 0 | 11.7 / 0 |
| 100 | indexing | 1.1 / 0 | 1.1 / 0 | 2.3 / 0 | 2.2 / 0 | 0.9 / 0 |
| 100 | copyto! | 8.2 / 0 | 9.0 / 0 | 11.5 / 0 | 11.3 / 0 | 7.3 / 0 |
| 100 | dot | 13.8 / 0 | 14.1 / 0 | 10.1 / 0 | 10.0 / 0 | 8.5 / 0 |
| 100 | affine loop | 7.8 / 0 | 8.2 / 0 | 9.5 / 0 | 9.4 / 0 | 7.4 / 0 |
| 100 | in-place broadcast expression | 9.2 / 0 | 9.4 / 0 | 16.1 / 0 | 12.6 / 0 | 26.5 / 0 |
| 1000 | escaping construction | 39.0 / 8256 | 38.4 / 8256 | 7.8 / 64 | 9.8 / 48 | 26.1 / 8064 |
| 1000 | construct + fill + sum | 177.5 / 8256 | 176.7 / 8224 | 140.9 / 0 | 140.5 / 0 | 582.2 / 8064 |
| 1000 | fill! | 56.0 / 0 | 56.4 / 0 | 57.9 / 0 | 57.5 / 0 | 105.8 / 0 |
| 1000 | sum | 64.5 / 0 | 62.7 / 0 | 64.2 / 0 | 63.3 / 0 | 402.6 / 0 |
| 1000 | indexing | 1.1 / 0 | 1.2 / 0 | 2.3 / 0 | 2.4 / 0 | 1.1 / 0 |
| 1000 | copyto! | 68.1 / 0 | 70.0 / 0 | 71.2 / 0 | 71.4 / 0 | 65.1 / 0 |
| 1000 | dot | 102.1 / 0 | 99.3 / 0 | 89.6 / 0 | 87.4 / 0 | 88.8 / 0 |
| 1000 | affine loop | 70.8 / 0 | 69.0 / 0 | 67.2 / 0 | 66.7 / 0 | 65.2 / 0 |
| 1000 | in-place broadcast expression | 67.3 / 0 | 66.8 / 0 | 73.8 / 0 | 72.4 / 0 | 284.0 / 0 |
| 10000 | escaping construction | 183.3 / 81984 | 186.4 / 81984 | 8.2 / 64 | 9.9 / 48 | — |
| 10000 | construct + fill + sum | 1566.6 / 81984 | 1554.2 / 81952 | 1225.0 / 0 | 1208.3 / 0 | — |
| 10000 | fill! | 604.8 / 0 | 631.9 / 0 | 546.8 / 0 | 546.3 / 0 | — |
| 10000 | sum | 662.1 / 0 | 655.4 / 0 | 640.9 / 0 | 638.8 / 0 | — |
| 10000 | indexing | 1.1 / 0 | 1.2 / 0 | 2.4 / 0 | 2.4 / 0 | — |
| 10000 | copyto! | 610.2 / 0 | 608.8 / 0 | 638.4 / 0 | 603.4 / 0 | — |
| 10000 | dot | 1225.0 / 0 | 1154.1 / 0 | 1106.3 / 0 | 1112.8 / 0 | — |
| 10000 | affine loop | 742.9 / 0 | 694.5 / 0 | 701.2 / 0 | 722.7 / 0 | — |
| 10000 | in-place broadcast expression | 776.6 / 0 | 751.9 / 0 | 724.4 / 0 | 777.2 / 0 | — |
| 100000 | escaping construction | 570.9 / 802880 | 544.7 / 802880 | 8.4 / 64 | 10.0 / 48 | — |
| 100000 | construct + fill + sum | 15125.0 / 802880 | 14625.0 / 802848 | 13750.0 / 0 | 13542.0 / 0 | — |
| 100000 | fill! | 5597.2 / 0 | 5576.3 / 0 | 5451.3 / 0 | 5437.5 / 0 | — |
| 100000 | sum | 7175.0 / 0 | 7158.2 / 0 | 7216.6 / 0 | 7198.0 / 0 | — |
| 100000 | indexing | 1.0 / 0 | 1.4 / 0 | 2.4 / 0 | 2.2 / 0 | — |
| 100000 | copyto! | 8722.0 / 0 | 8680.7 / 0 | 8680.7 / 0 | 8722.0 / 0 | — |
| 100000 | dot | 12291.0 / 0 | 12250.0 / 0 | 12291.0 / 0 | 12291.0 / 0 | — |
| 100000 | affine loop | 11625.0 / 0 | 12167.0 / 0 | 12083.0 / 0 | 12042.0 / 0 | — |
| 100000 | in-place broadcast expression | 9625.0 / 0 | 12292.0 / 0 | 12000.0 / 0 | 12125.0 / 0 | — |

Construction inside a non-escaping scope is measured separately in the CSV for
both Goose variants. The CSV also reports arena bytes consumed. Zero GC bytes
does not mean zero memory usage: for these `Float64` arrays, elements occupy
8×n bytes, plus initial metadata and any escaping descriptors.

## Immutable StaticArrays reference results

| n | SVector sum | SVector abs2 reduction | SVector map then sum | SVector broadcast then sum |
| ---: | ---: | ---: | ---: | ---: |
| 2 | 1.1 / 0 | 1.5 / 0 | 1.4 / 0 | 1.5 / 0 |
| 3 | 0.9 / 0 | 1.5 / 0 | 1.7 / 0 | 1.5 / 0 |
| 4 | 1.1 / 0 | 1.5 / 0 | 1.8 / 0 | 1.5 / 0 |
| 8 | 1.3 / 0 | 1.6 / 0 | 1.9 / 0 | 1.9 / 0 |
| 16 | 1.5 / 0 | 2.1 / 0 | 2.5 / 0 | 2.5 / 0 |
| 32 | 2.3 / 0 | 3.7 / 0 | 5.2 / 0 | 5.2 / 0 |
| 64 | 5.9 / 0 | 9.3 / 0 | 13.2 / 0 | 13.2 / 0 |
| 100 | 11.7 / 0 | 17.0 / 0 | 25.4 / 0 | 25.1 / 0 |
| 1000 | 378.3 / 0 | 420.7 / 0 | 602.3 / 0 | 631.9 / 0 |

`SMatrix` multiplication followed by summation is also available in the CSV
for small matrices.

## Compilation and specialization

Measurements use a fresh process, excluding input construction and package
loading. The first call uses `invokelatest` to include compilation of the
measured kernel. Timings depend on call order and compiler behavior, so these
do not constitute a full startup benchmark. Counts refer to `MethodInstance`
objects, not an exhaustive inventory of `CodeInstance` objects.

| Family | Shapes tested | Concrete types | Final kernel instances | Cumulative kernel compilation (ms) |
| --- | ---: | ---: | ---: | ---: |
| Array | 11 | 1 | 1 | 4.080 |
| FixedSizeArray | 11 | 1 | 1 | 15.825 |
| GooseArray | 11 | 1 | 1 | 7.212 |
| StaticGooseArray | 11 | 11 | 11 | 73.773 |
| MVector | 9 | 9 | 9 | 54.738 |
| SVector | 9 | 9 | 9 | 25.656 |

`GooseArray` retains a single concrete type across all tested lengths.
`StaticGooseArray` and StaticArrays intentionally specialize by shape.
Generation tokens and arena identities are not type parameters; tests cover
recreating arrays with identical shapes.

## Validation and limitations

**6,030 assertions passed** via `Pkg.test` with `--check-bounds=yes` in the
original benchmark campaign. The tests cover shapes, zero-copy conversions,
aliasing, nested scopes, memory reuse, callbacks that invalidate arenas, matrix
operations, allocations, and specialization. Both Goose array variants retain
lifetime checks even under `@inbounds`; as in Julia, bounds checks may still be
disabled by `@inbounds`.

Results cover warmed-up kernels with concrete types. The arena and scope states
are allocated once, while descriptors can still incur GC allocations if they
escape. Static dimensions do not imply inline tuples or native stack placement.
The LLVM optimization is enabled on Julia 1.13.x (tested on 1.13.3), with a
portable fallback on other versions. Static shapes do not guarantee a speedup
for every operation.

The benchmark case count includes all families and sizes; it is not a count of
wins by any one type. Minimum and p95 values are in the CSV files; the tables
show medians. RSS and physical memory pages were not measured. No direct
speed comparison with the Goose language was performed.

## Reproduce these measurements

Public release `0.1.0` uses code from the last prototype iteration, which
was still internally numbered `0.6.0` when these measurements were collected.
The CSV files are **historical reference measurements**, not universal
performance guarantees. Raw values and environment details are available in
`benchmark/reference/m5-max-2026-10-31/`.

From the repository root:

```sh
julia --startup-file=no benchmark/bench.jl
julia --startup-file=no benchmark/bench.jl --full
```

The first command runs a short selection; the second runs both full suites.
Outputs are written to the untracked `benchmark/results/` directory. Use
`--out path/to/directory` for a different destination.

Out-of-place `map` timings include consuming the result and, for Goose arrays,
leaving the scope. Zero reported GC allocation does not mean the arena uses
zero bytes. Escaping descriptors and arena initialization can allocate on the
GC heap. Results depend on the machine, Julia version, and execution context.
