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

<!-- BEGIN GENERATED BENCHMARK: vectors -->

| Size | Operation | Vector | FixedSizeVector | GooseVector | StaticGooseVector | MVector |
| ---: | --- | ---: | ---: | ---: | ---: | ---: |
| 2 | in-place map! | 2.4 / 0 | 2.4 / 0 | 2.9 / 0 | 2.8 / 0 | 1.5 / 0 |
| 2 | map then sum | 7.3 / 80 | 5.5 / 48 | 14.0 / 0 | 11.2 / 0 | 1.5 / 0 |
| 2 | fused sum(f) | 1.5 / 0 | 2.0 / 0 | 3.0 / 0 | 2.2 / 0 | 1.5 / 0 |
| 2 | abs2 reduction | 2.8 / 0 | 2.5 / 0 | 3.0 / 0 | 2.7 / 0 | 1.5 / 0 |
| 2 | in-place broadcast | 2.8 / 0 | 2.9 / 0 | 6.0 / 0 | 5.5 / 0 | 1.3 / 0 |
| 2 | broadcast then sum | 7.7 / 80 | 5.6 / 48 | 13.8 / 0 | 11.3 / 0 | 1.5 / 0 |
| 2 | 2 .* b .+ 1 then sum | 7.5 / 80 | 5.6 / 48 | 13.8 / 0 | 11.2 / 0 | 1.3 / 0 |
| 3 | in-place map! | 2.6 / 0 | 2.8 / 0 | 3.9 / 0 | 3.2 / 0 | 1.8 / 0 |
| 3 | map then sum | 7.8 / 80 | 5.8 / 48 | 14.1 / 0 | 13.8 / 0 | 1.8 / 0 |
| 3 | fused sum(f) | 2.1 / 0 | 1.9 / 0 | 3.0 / 0 | 2.5 / 0 | 1.8 / 0 |
| 3 | abs2 reduction | 2.8 / 0 | 2.8 / 0 | 2.8 / 0 | 2.9 / 0 | 1.5 / 0 |
| 3 | in-place broadcast | 2.9 / 0 | 3.1 / 0 | 6.5 / 0 | 5.9 / 0 | 1.8 / 0 |
| 3 | broadcast then sum | 8.4 / 80 | 6.3 / 48 | 14.1 / 0 | 13.8 / 0 | 1.8 / 0 |
| 3 | 2 .* b .+ 1 then sum | 8.0 / 80 | 6.0 / 48 | 14.2 / 0 | 14.7 / 0 | 1.8 / 0 |
| 4 | in-place map! | 3.0 / 0 | 3.0 / 0 | 3.2 / 0 | 3.2 / 0 | 1.8 / 0 |
| 4 | map then sum | 8.5 / 96 | 6.9 / 64 | 14.3 / 0 | 14.0 / 0 | 1.8 / 0 |
| 4 | fused sum(f) | 2.4 / 0 | 2.2 / 0 | 3.1 / 0 | 2.6 / 0 | 1.8 / 0 |
| 4 | abs2 reduction | 3.0 / 0 | 3.2 / 0 | 3.2 / 0 | 2.6 / 0 | 1.5 / 0 |
| 4 | in-place broadcast | 3.2 / 0 | 3.1 / 0 | 6.3 / 0 | 5.9 / 0 | 1.8 / 0 |
| 4 | broadcast then sum | 9.2 / 96 | 6.6 / 64 | 14.1 / 0 | 14.2 / 0 | 1.8 / 0 |
| 4 | 2 .* b .+ 1 then sum | 8.6 / 96 | 7.0 / 64 | 14.0 / 0 | 13.7 / 0 | 1.8 / 0 |
| 8 | in-place map! | 2.2 / 0 | 2.4 / 0 | 3.2 / 0 | 3.6 / 0 | 2.0 / 0 |
| 8 | map then sum | 10.0 / 128 | 8.6 / 96 | 14.5 / 0 | 14.9 / 0 | 2.0 / 0 |
| 8 | fused sum(f) | 3.0 / 0 | 3.1 / 0 | 4.2 / 0 | 2.8 / 0 | 2.0 / 0 |
| 8 | abs2 reduction | 4.0 / 0 | 4.3 / 0 | 4.1 / 0 | 2.8 / 0 | 1.8 / 0 |
| 8 | in-place broadcast | 3.1 / 0 | 3.2 / 0 | 6.1 / 0 | 6.6 / 0 | 1.8 / 0 |
| 8 | broadcast then sum | 8.8 / 128 | 6.7 / 96 | 14.4 / 0 | 14.8 / 0 | 1.9 / 0 |
| 8 | 2 .* b .+ 1 then sum | 8.5 / 128 | 6.8 / 96 | 14.3 / 0 | 14.6 / 0 | 2.0 / 0 |
| 16 | in-place map! | 2.6 / 0 | 2.8 / 0 | 3.7 / 0 | 4.8 / 0 | 2.9 / 0 |
| 16 | map then sum | 12.5 / 192 | 11.1 / 160 | 17.2 / 0 | 16.6 / 0 | 2.6 / 0 |
| 16 | fused sum(f) | 4.3 / 0 | 4.3 / 0 | 5.6 / 0 | 4.6 / 0 | 2.8 / 0 |
| 16 | abs2 reduction | 5.0 / 0 | 5.2 / 0 | 5.8 / 0 | 4.5 / 0 | 2.3 / 0 |
| 16 | in-place broadcast | 3.8 / 0 | 3.7 / 0 | 6.7 / 0 | 7.8 / 0 | 2.4 / 0 |
| 16 | broadcast then sum | 12.1 / 192 | 9.7 / 160 | 17.0 / 0 | 15.9 / 0 | 2.6 / 0 |
| 16 | 2 .* b .+ 1 then sum | 11.9 / 192 | 9.7 / 160 | 17.1 / 0 | 16.2 / 0 | 2.6 / 0 |
| 32 | in-place map! | 3.7 / 0 | 3.5 / 0 | 4.7 / 0 | 4.4 / 0 | 4.8 / 0 |
| 32 | map then sum | 15.5 / 320 | 13.8 / 288 | 17.9 / 0 | 16.0 / 0 | 5.2 / 0 |
| 32 | fused sum(f) | 5.2 / 0 | 5.2 / 0 | 6.5 / 0 | 5.6 / 0 | 5.2 / 0 |
| 32 | abs2 reduction | 5.2 / 0 | 5.4 / 0 | 6.3 / 0 | 5.4 / 0 | 3.5 / 0 |
| 32 | in-place broadcast | 4.9 / 0 | 5.2 / 0 | 8.1 / 0 | 7.4 / 0 | 4.0 / 0 |
| 32 | broadcast then sum | 15.3 / 320 | 13.4 / 288 | 17.7 / 0 | 16.4 / 0 | 5.3 / 0 |
| 32 | 2 .* b .+ 1 then sum | 15.1 / 320 | 13.2 / 288 | 17.5 / 0 | 15.6 / 0 | 5.2 / 0 |
| 64 | in-place map! | 4.8 / 0 | 5.4 / 0 | 6.7 / 0 | 6.2 / 0 | 8.8 / 0 |
| 64 | map then sum | 20.2 / 576 | 18.0 / 544 | 20.1 / 0 | 18.7 / 0 | 12.9 / 0 |
| 64 | fused sum(f) | 7.0 / 0 | 6.8 / 0 | 8.2 / 0 | 7.2 / 0 | 10.6 / 0 |
| 64 | abs2 reduction | 6.9 / 0 | 6.9 / 0 | 7.2 / 0 | 6.3 / 0 | 8.5 / 0 |
| 64 | in-place broadcast | 7.0 / 0 | 6.9 / 0 | 11.3 / 0 | 9.0 / 0 | 14.2 / 0 |
| 64 | broadcast then sum | 20.3 / 576 | 18.1 / 544 | 19.8 / 0 | 18.5 / 0 | 12.9 / 0 |
| 64 | 2 .* b .+ 1 then sum | 20.2 / 576 | 17.9 / 544 | 19.7 / 0 | 18.5 / 0 | 12.9 / 0 |
| 100 | in-place map! | 7.6 / 0 | 8.0 / 0 | 8.8 / 0 | 8.9 / 0 | 14.2 / 0 |
| 100 | map then sum | 26.1 / 928 | 23.6 / 896 | 23.3 / 0 | 21.7 / 0 | 26.8 / 0 |
| 100 | fused sum(f) | 9.0 / 0 | 9.1 / 0 | 9.5 / 0 | 9.5 / 0 | 18.9 / 0 |
| 100 | abs2 reduction | 7.0 / 0 | 7.2 / 0 | 7.6 / 0 | 6.8 / 0 | 15.5 / 0 |
| 100 | in-place broadcast | 8.8 / 0 | 8.8 / 0 | 15.9 / 0 | 11.8 / 0 | 28.4 / 0 |
| 100 | broadcast then sum | 25.8 / 928 | 24.2 / 896 | 23.4 / 0 | 21.3 / 0 | 26.7 / 0 |
| 100 | 2 .* b .+ 1 then sum | 25.9 / 928 | 24.3 / 896 | 23.4 / 0 | 23.8 / 0 | 25.1 / 0 |
| 1000 | in-place map! | 63.9 / 0 | 63.3 / 0 | 65.2 / 0 | 64.9 / 0 | 125.2 / 0 |
| 1000 | map then sum | 200.8 / 8256 | 202.2 / 8224 | 147.4 / 0 | 144.3 / 0 | 589.6 / 0 |
| 1000 | fused sum(f) | 83.4 / 0 | 84.4 / 0 | 84.2 / 0 | 87.8 / 0 | 421.3 / 0 |
| 1000 | abs2 reduction | 75.7 / 0 | 75.8 / 0 | 76.4 / 0 | 75.3 / 0 | 401.0 / 0 |
| 1000 | in-place broadcast | 64.8 / 0 | 65.5 / 0 | 71.0 / 0 | 67.2 / 0 | 273.3 / 0 |
| 1000 | broadcast then sum | 182.1 / 8256 | 182.2 / 8224 | 147.1 / 0 | 144.2 / 0 | 589.6 / 0 |
| 1000 | 2 .* b .+ 1 then sum | 181.4 / 8256 | 182.7 / 8224 | 146.9 / 0 | 144.1 / 0 | 589.6 / 0 |
| 10000 | in-place map! | 634.1 / 0 | 629.3 / 0 | 633.4 / 0 | 625.9 / 0 | — |
| 10000 | map then sum | 2175.9 / 81984 | 2129.6 / 81952 | 1541.7 / 0 | 1525.0 / 0 | — |
| 10000 | fused sum(f) | 867.1 / 0 | 869.4 / 0 | 874.4 / 0 | 877.7 / 0 | — |
| 10000 | abs2 reduction | 906.7 / 0 | 905.8 / 0 | 904.8 / 0 | 904.3 / 0 | — |
| 10000 | in-place broadcast | 633.0 / 0 | 631.8 / 0 | 631.4 / 0 | 628.2 / 0 | — |
| 10000 | broadcast then sum | 2115.7 / 81984 | 2025.0 / 81952 | 1541.7 / 0 | 1525.0 / 0 | — |
| 10000 | 2 .* b .+ 1 then sum | 2115.7 / 81984 | 2029.1 / 81952 | 1541.6 / 0 | 1533.3 / 0 | — |
| 100000 | in-place map! | 11500.0 / 0 | 11000.0 / 0 | 11375.0 / 0 | 11500.0 / 0 | — |
| 100000 | map then sum | 20791.0 / 802880 | 20834.0 / 802848 | 19250.0 / 0 | 19250.0 / 0 | — |
| 100000 | fused sum(f) | 8805.3 / 0 | 8805.7 / 0 | 8861.0 / 0 | 8847.3 / 0 | — |
| 100000 | abs2 reduction | 9375.0 / 0 | 9375.0 / 0 | 9375.0 / 0 | 9375.0 / 0 | — |
| 100000 | in-place broadcast | 11542.0 / 0 | 11000.0 / 0 | 11500.0 / 0 | 11333.0 / 0 | — |
| 100000 | broadcast then sum | 20583.0 / 802880 | 20542.0 / 802848 | 19250.0 / 0 | 19250.0 / 0 | — |
| 100000 | 2 .* b .+ 1 then sum | 20916.5 / 802880 | 20541.0 / 802848 | 19209.0 / 0 | 19375.0 / 0 | — |

<!-- END GENERATED BENCHMARK: vectors -->

### Matrix multiplication

Square `Float64` matrices. `mul!` uses a preallocated destination; multiplying
and then summing includes allocation and consumption of the result. `MMatrix`
is only measured up to 16×16.

<!-- BEGIN GENERATED BENCHMARK: matrices -->

| Size | Operation | Matrix | FixedSizeMatrix | GooseMatrix | StaticGooseMatrix | MMatrix |
| ---: | --- | ---: | ---: | ---: | ---: | ---: |
| 2×2 | in-place mul! | 12.3 / 0 | 17.0 / 0 | 9.2 / 0 | 5.4 / 0 | — |
| 2×2 | multiply then sum | 18.7 / 112 | 44.4 / 64 | 20.0 / 0 | 16.9 / 0 | — |
| 3×3 | in-place mul! | 13.9 / 0 | 18.2 / 0 | 15.4 / 0 | 7.2 / 0 | — |
| 3×3 | multiply then sum | 22.5 / 144 | 46.7 / 96 | 25.4 / 0 | 18.3 / 0 | — |
| 4×4 | in-place mul! | 43.6 / 0 | 47.1 / 0 | 30.3 / 0 | 10.4 / 0 | — |
| 4×4 | multiply then sum | 54.2 / 208 | 56.8 / 160 | 40.8 / 0 | 22.1 / 0 | — |
| 8×8 | in-place mul! | 79.6 / 0 | 82.4 / 0 | 77.7 / 0 | 75.9 / 0 | — |
| 8×8 | multiply then sum | 92.7 / 592 | 102.0 / 544 | 101.7 / 0 | 91.5 / 0 | — |
| 16×16 | in-place mul! | 223.9 / 0 | 217.9 / 0 | 214.0 / 0 | 212.7 / 0 | — |
| 16×16 | multiply then sum | 268.8 / 2128 | 278.3 / 2080 | 254.1 / 0 | 245.4 / 0 | — |
| 64×64 | in-place mul! | 19208.0 / 0 | 19375.0 / 0 | 19209.0 / 0 | 19208.0 / 0 | — |
| 64×64 | multiply then sum | 20958.0 / 32848 | 19417.0 / 32800 | 19333.0 / 0 | 19209.0 / 0 | — |
| 256×256 | in-place mul! | 632583.0 / 0 | 634875.0 / 0 | 634187.5 / 0 | 634291.0 / 0 | — |
| 256×256 | multiply then sum | 648083.0 / 524368 | 638833.5 / 524320 | 643542.0 / 0 | 639021.0 / 0 | — |

<!-- END GENERATED BENCHMARK: matrices -->

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

<!-- BEGIN GENERATED BENCHMARK: multi-input -->

| Size | Operation | Vector | FixedSizeVector | GooseVector | StaticGooseVector | MVector |
| ---: | --- | ---: | ---: | ---: | ---: | ---: |
| 2 | two-input map! | 4.1 / 0 | 2.6 / 0 | 3.0 / 0 | 2.8 / 0 | 3.5 / 0 |
| 2 | three-input map! | 6.3 / 0 | 6.5 / 0 | 3.8 / 0 | 3.5 / 0 | 3.5 / 0 |
| 2 | two-input map then sum | 9.2 / 80 | 9.8 / 80 | 14.4 / 0 | 11.6 / 0 | 1.5 / 0 |
| 2 | three-input map then sum | 9.9 / 80 | 10.5 / 80 | 14.7 / 0 | 11.5 / 0 | 1.5 / 0 |
| 2 | two-input mapreduce | 9.2 / 80 | 9.7 / 80 | 12.2 / 0 | 11.0 / 0 | 1.5 / 0 |
| 2 | three-input mapreduce | 10.0 / 80 | 10.6 / 80 | 12.5 / 0 | 10.8 / 0 | 1.6 / 0 |
| 2 | axpy! | 5.3 / 0 | 5.7 / 0 | 2.9 / 0 | 3.8 / 0 | 3.6 / 0 |
| 2 | axpby! | 4.8 / 0 | 4.8 / 0 | 3.0 / 0 | 4.4 / 0 | 4.3 / 0 |
| 3 | two-input map! | 4.4 / 0 | 3.0 / 0 | 3.2 / 0 | 2.9 / 0 | 3.6 / 0 |
| 3 | three-input map! | 6.6 / 0 | 6.8 / 0 | 4.1 / 0 | 3.7 / 0 | 3.8 / 0 |
| 3 | two-input map then sum | 9.8 / 80 | 10.2 / 80 | 14.6 / 0 | 14.0 / 0 | 1.5 / 0 |
| 3 | three-input map then sum | 10.8 / 80 | 11.0 / 80 | 14.8 / 0 | 14.1 / 0 | 1.8 / 0 |
| 3 | two-input mapreduce | 9.8 / 80 | 10.1 / 80 | 12.2 / 0 | 11.0 / 0 | 1.5 / 0 |
| 3 | three-input mapreduce | 10.6 / 80 | 11.0 / 80 | 12.8 / 0 | 10.8 / 0 | 1.8 / 0 |
| 3 | axpy! | 5.3 / 0 | 6.0 / 0 | 3.2 / 0 | 3.9 / 0 | 3.4 / 0 |
| 3 | axpby! | 5.0 / 0 | 4.9 / 0 | 3.2 / 0 | 4.4 / 0 | 4.3 / 0 |
| 4 | two-input map! | 4.6 / 0 | 3.2 / 0 | 3.5 / 0 | 3.2 / 0 | 3.8 / 0 |
| 4 | three-input map! | 6.8 / 0 | 7.0 / 0 | 4.4 / 0 | 4.0 / 0 | 4.0 / 0 |
| 4 | two-input map then sum | 10.1 / 96 | 10.7 / 96 | 15.4 / 0 | 14.7 / 0 | 1.8 / 0 |
| 4 | three-input map then sum | 11.0 / 96 | 11.6 / 96 | 15.1 / 0 | 14.7 / 0 | 1.7 / 0 |
| 4 | two-input mapreduce | 10.2 / 96 | 10.6 / 96 | 12.2 / 0 | 10.9 / 0 | 1.8 / 0 |
| 4 | three-input mapreduce | 11.1 / 96 | 11.6 / 96 | 12.7 / 0 | 11.0 / 0 | 1.8 / 0 |
| 4 | axpy! | 5.4 / 0 | 6.4 / 0 | 3.4 / 0 | 3.9 / 0 | 3.6 / 0 |
| 4 | axpby! | 5.3 / 0 | 5.3 / 0 | 3.3 / 0 | 4.5 / 0 | 4.4 / 0 |
| 8 | two-input map! | 5.8 / 0 | 4.0 / 0 | 3.5 / 0 | 3.9 / 0 | 4.7 / 0 |
| 8 | three-input map! | 6.5 / 0 | 7.0 / 0 | 4.2 / 0 | 4.8 / 0 | 5.4 / 0 |
| 8 | two-input map then sum | 11.4 / 128 | 12.0 / 128 | 15.1 / 0 | 16.0 / 0 | 1.9 / 0 |
| 8 | three-input map then sum | 12.5 / 128 | 13.3 / 128 | 16.2 / 0 | 15.5 / 0 | 2.2 / 0 |
| 8 | two-input mapreduce | 11.7 / 128 | 12.1 / 128 | 12.3 / 0 | 10.7 / 0 | 1.8 / 0 |
| 8 | three-input mapreduce | 12.7 / 128 | 13.2 / 128 | 13.2 / 0 | 10.7 / 0 | 2.2 / 0 |
| 8 | axpy! | 6.3 / 0 | 7.2 / 0 | 3.3 / 0 | 4.0 / 0 | 3.8 / 0 |
| 8 | axpby! | 5.3 / 0 | 5.2 / 0 | 3.9 / 0 | 4.5 / 0 | 4.5 / 0 |
| 16 | two-input map! | 6.7 / 0 | 5.0 / 0 | 4.2 / 0 | 5.0 / 0 | 6.2 / 0 |
| 16 | three-input map! | 7.5 / 0 | 7.7 / 0 | 5.1 / 0 | 7.2 / 0 | 9.0 / 0 |
| 16 | two-input map then sum | 14.2 / 192 | 14.8 / 192 | 17.0 / 0 | 17.0 / 0 | 2.5 / 0 |
| 16 | three-input map then sum | 15.6 / 192 | 16.4 / 192 | 18.3 / 0 | 18.1 / 0 | 3.3 / 0 |
| 16 | two-input mapreduce | 14.4 / 192 | 15.3 / 192 | 17.8 / 0 | 15.6 / 0 | 2.5 / 0 |
| 16 | three-input mapreduce | 16.0 / 192 | 17.0 / 192 | 20.5 / 0 | 18.1 / 0 | 3.4 / 0 |
| 16 | axpy! | 8.2 / 0 | 9.4 / 0 | 4.2 / 0 | 5.7 / 0 | 5.4 / 0 |
| 16 | axpby! | 5.8 / 0 | 6.0 / 0 | 4.5 / 0 | 6.5 / 0 | 6.0 / 0 |
| 64 | two-input map! | 10.4 / 0 | 8.8 / 0 | 8.1 / 0 | 7.8 / 0 | 14.2 / 0 |
| 64 | three-input map! | 13.6 / 0 | 12.3 / 0 | 11.1 / 0 | 10.6 / 0 | 19.5 / 0 |
| 64 | two-input map then sum | 22.2 / 576 | 22.3 / 576 | 22.1 / 0 | 20.2 / 0 | 13.3 / 0 |
| 64 | three-input map then sum | 25.0 / 576 | 24.8 / 576 | 25.9 / 0 | 23.8 / 0 | 15.9 / 0 |
| 64 | two-input mapreduce | 22.5 / 576 | 21.8 / 576 | 20.5 / 0 | 17.8 / 0 | 11.0 / 0 |
| 64 | three-input mapreduce | 24.9 / 576 | 24.6 / 576 | 25.5 / 0 | 21.9 / 0 | 14.2 / 0 |
| 64 | axpy! | 10.0 / 0 | 10.1 / 0 | 8.1 / 0 | 7.3 / 0 | 7.5 / 0 |
| 64 | axpby! | 10.7 / 0 | 10.5 / 0 | 8.4 / 0 | 8.3 / 0 | 8.0 / 0 |
| 1000 | two-input map! | 95.0 / 0 | 95.2 / 0 | 90.3 / 0 | 89.7 / 0 | 169.5 / 0 |
| 1000 | three-input map! | 123.8 / 0 | 127.5 / 0 | 122.7 / 0 | 122.0 / 0 | 245.5 / 0 |
| 1000 | two-input map then sum | 219.2 / 8256 | 222.7 / 8256 | 162.4 / 0 | 169.6 / 0 | 621.4 / 0 |
| 1000 | three-input map then sum | 246.0 / 8256 | 250.9 / 8256 | 198.5 / 0 | 203.8 / 0 | 769.0 / 0 |
| 1000 | two-input mapreduce | 220.1 / 8256 | 225.5 / 8256 | 105.1 / 0 | 103.3 / 0 | 437.1 / 0 |
| 1000 | three-input mapreduce | 245.0 / 8256 | 251.6 / 8256 | 138.6 / 0 | 135.6 / 0 | 494.2 / 0 |
| 1000 | axpy! | 83.2 / 0 | 85.8 / 0 | 92.1 / 0 | 91.9 / 0 | 92.8 / 0 |
| 1000 | axpby! | 94.4 / 0 | 94.7 / 0 | 92.3 / 0 | 91.9 / 0 | 93.3 / 0 |
| 10000 | two-input map! | 1583.4 / 0 | 1616.7 / 0 | 1487.5 / 0 | 1720.9 / 0 | — |
| 10000 | three-input map! | 2310.1 / 0 | 2300.9 / 0 | 2262.5 / 0 | 2301.0 / 0 | — |
| 10000 | two-input map then sum | 2731.4 / 81984 | 2731.4 / 81984 | 2263.9 / 0 | 2263.9 / 0 | — |
| 10000 | three-input map then sum | 3437.5 / 81984 | 3432.2 / 81984 | 2921.3 / 0 | 2898.2 / 0 | — |
| 10000 | two-input mapreduce | 2736.1 / 81984 | 2740.7 / 81984 | 1038.2 / 0 | 1089.7 / 0 | — |
| 10000 | three-input mapreduce | 3437.5 / 81984 | 3447.9 / 81984 | 1625.0 / 0 | 1666.6 / 0 | — |
| 10000 | axpy! | 1300.0 / 0 | 1400.0 / 0 | 1441.7 / 0 | 1437.5 / 0 | — |
| 10000 | axpby! | 1462.5 / 0 | 1458.3 / 0 | 1450.0 / 0 | 1512.5 / 0 | — |
| 100000 | two-input map! | 17917.0 / 0 | 17875.0 / 0 | 17875.0 / 0 | 17916.0 / 0 | — |
| 100000 | three-input map! | 23792.0 / 0 | 23750.0 / 0 | 23709.0 / 0 | 23709.0 / 0 | — |
| 100000 | two-input map then sum | 26750.0 / 802880 | 26750.0 / 802880 | 26459.0 / 0 | 26375.0 / 0 | — |
| 100000 | three-input map then sum | 33145.5 / 802880 | 33042.0 / 802880 | 32375.0 / 0 | 32750.0 / 0 | — |
| 100000 | two-input mapreduce | 26917.0 / 802880 | 26750.0 / 802880 | 12417.0 / 0 | 12375.0 / 0 | — |
| 100000 | three-input mapreduce | 33354.5 / 802880 | 33208.0 / 802880 | 19333.0 / 0 | 19209.0 / 0 | — |
| 100000 | axpy! | 14500.0 / 0 | 14666.0 / 0 | 14459.0 / 0 | 14459.0 / 0 | — |
| 100000 | axpby! | 15292.0 / 0 | 15291.0 / 0 | 14834.0 / 0 | 15417.0 / 0 | — |

<!-- END GENERATED BENCHMARK: multi-input -->

### Matrix–vector products

Square n×n matrices and n-element vectors. `mul!` uses a preallocated
output; multiplication followed by summation includes allocation and
consumption of the result, as in the matrix–matrix benchmarks.

<!-- BEGIN GENERATED BENCHMARK: matvec -->

| Size | Operation | Matrix × Vector | FixedSizeMatrix × FixedSizeVector | GooseMatrix × GooseVector | StaticGooseMatrix × StaticGooseVector | MMatrix × MVector |
| ---: | --- | ---: | ---: | ---: | ---: | ---: |
| 2×2 | matrix–vector mul! | 19.7 / 0 | 18.9 / 0 | 6.2 / 0 | 4.2 / 0 | 5.3 / 0 |
| 2×2 | multiply then sum | 28.1 / 80 | 26.7 / 48 | 19.5 / 0 | 15.9 / 0 | 1.5 / 0 |
| 3×3 | matrix–vector mul! | 24.6 / 0 | 24.8 / 0 | 7.4 / 0 | 4.8 / 0 | 6.0 / 0 |
| 3×3 | multiply then sum | 34.3 / 80 | 34.2 / 48 | 20.3 / 0 | 17.3 / 0 | 1.8 / 0 |
| 4×4 | matrix–vector mul! | 21.1 / 0 | 20.0 / 0 | 10.4 / 0 | 5.1 / 0 | 6.5 / 0 |
| 4×4 | multiply then sum | 28.9 / 96 | 27.6 / 64 | 21.3 / 0 | 17.7 / 0 | 2.0 / 0 |
| 8×8 | matrix–vector mul! | 34.5 / 0 | 34.6 / 0 | 23.1 / 0 | 11.0 / 0 | 13.8 / 0 |
| 8×8 | multiply then sum | 45.6 / 128 | 43.8 / 96 | 35.5 / 0 | 20.8 / 0 | 4.5 / 0 |
| 16×16 | matrix–vector mul! | 65.5 / 0 | 65.3 / 0 | 70.1 / 0 | 16.6 / 0 | 41.3 / 0 |
| 16×16 | multiply then sum | 78.1 / 192 | 77.3 / 160 | 101.8 / 0 | 25.6 / 0 | 19.5 / 0 |
| 64×64 | matrix–vector mul! | 452.5 / 0 | 452.1 / 0 | 455.2 / 0 | 453.9 / 0 | — |
| 64×64 | multiply then sum | 584.8 / 576 | 589.1 / 544 | 493.4 / 0 | 466.8 / 0 | — |
| 256×256 | matrix–vector mul! | 7700.0 / 0 | 7687.5 / 0 | 7698.0 / 0 | 7700.0 / 0 | — |
| 256×256 | multiply then sum | 7770.9 / 2112 | 7885.5 / 2080 | 7750.0 / 0 | 7739.5 / 0 | — |

<!-- END GENERATED BENCHMARK: matvec -->

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

<!-- BEGIN GENERATED BENCHMARK: additional -->

| Size | Operation | Vector | FixedSizeVector | GooseVector | StaticGooseVector | MVector |
| ---: | --- | ---: | ---: | ---: | ---: | ---: |
| 2 | escaping construction | 6.8 / 80 | 7.5 / 80 | 7.3 / 64 | 9.3 / 48 | 3.4 / 32 |
| 2 | construct + fill + sum | 7.8 / 80 | 5.5 / 48 | 13.6 / 0 | 11.1 / 0 | 3.5 / 32 |
| 2 | fill! | 1.5 / 0 | 1.5 / 0 | 2.8 / 0 | 2.8 / 0 | 1.1 / 0 |
| 2 | sum | 1.7 / 0 | 1.3 / 0 | 2.2 / 0 | 2.0 / 0 | 1.0 / 0 |
| 2 | indexing | 1.1 / 0 | 1.1 / 0 | 2.2 / 0 | 2.2 / 0 | 1.1 / 0 |
| 2 | copyto! | 2.8 / 0 | 3.0 / 0 | 5.8 / 0 | 4.6 / 0 | 1.8 / 0 |
| 2 | dot | 6.3 / 0 | 6.5 / 0 | 2.4 / 0 | 2.1 / 0 | 1.1 / 0 |
| 2 | affine loop | 2.2 / 0 | 2.2 / 0 | 2.9 / 0 | 2.7 / 0 | 1.5 / 0 |
| 2 | in-place broadcast expression | 2.8 / 0 | 3.0 / 0 | 6.0 / 0 | 5.7 / 0 | 1.5 / 0 |
| 3 | escaping construction | 7.3 / 80 | 8.0 / 80 | 7.5 / 64 | 9.5 / 48 | 3.4 / 32 |
| 3 | construct + fill + sum | 8.5 / 80 | 7.8 / 48 | 14.8 / 0 | 14.4 / 0 | 3.7 / 32 |
| 3 | fill! | 1.5 / 0 | 1.8 / 0 | 4.3 / 0 | 4.2 / 0 | 1.1 / 0 |
| 3 | sum | 1.3 / 0 | 1.3 / 0 | 2.4 / 0 | 2.3 / 0 | 0.9 / 0 |
| 3 | indexing | 1.1 / 0 | 1.2 / 0 | 2.4 / 0 | 2.2 / 0 | 1.1 / 0 |
| 3 | copyto! | 3.1 / 0 | 3.1 / 0 | 6.3 / 0 | 4.9 / 0 | 1.7 / 0 |
| 3 | dot | 6.2 / 0 | 7.0 / 0 | 2.6 / 0 | 2.2 / 0 | 1.3 / 0 |
| 3 | affine loop | 2.0 / 0 | 2.5 / 0 | 3.8 / 0 | 3.0 / 0 | 1.8 / 0 |
| 3 | in-place broadcast expression | 3.1 / 0 | 3.2 / 0 | 6.4 / 0 | 5.9 / 0 | 1.8 / 0 |
| 4 | escaping construction | 7.3 / 96 | 8.0 / 96 | 7.3 / 64 | 9.2 / 48 | 3.7 / 48 |
| 4 | construct + fill + sum | 16.0 / 96 | 10.3 / 64 | 13.8 / 0 | 13.7 / 0 | 3.8 / 48 |
| 4 | fill! | 1.8 / 0 | 2.0 / 0 | 2.8 / 0 | 2.8 / 0 | 1.1 / 0 |
| 4 | sum | 1.3 / 0 | 1.8 / 0 | 2.6 / 0 | 2.2 / 0 | 1.1 / 0 |
| 4 | indexing | 1.1 / 0 | 1.3 / 0 | 2.2 / 0 | 2.2 / 0 | 1.1 / 0 |
| 4 | copyto! | 3.6 / 0 | 3.2 / 0 | 6.2 / 0 | 5.0 / 0 | 1.8 / 0 |
| 4 | dot | 7.0 / 0 | 7.1 / 0 | 2.6 / 0 | 2.1 / 0 | 1.3 / 0 |
| 4 | affine loop | 2.5 / 0 | 2.6 / 0 | 3.2 / 0 | 3.0 / 0 | 1.8 / 0 |
| 4 | in-place broadcast expression | 3.2 / 0 | 3.5 / 0 | 6.3 / 0 | 6.1 / 0 | 1.5 / 0 |
| 8 | escaping construction | 7.7 / 128 | 8.5 / 128 | 7.2 / 64 | 9.2 / 48 | 4.1 / 80 |
| 8 | construct + fill + sum | 9.2 / 128 | 7.2 / 96 | 14.8 / 0 | 14.5 / 0 | 4.4 / 80 |
| 8 | fill! | 1.5 / 0 | 1.7 / 0 | 3.8 / 0 | 3.8 / 0 | 1.1 / 0 |
| 8 | sum | 2.4 / 0 | 2.7 / 0 | 3.5 / 0 | 2.2 / 0 | 1.3 / 0 |
| 8 | indexing | 1.1 / 0 | 1.3 / 0 | 2.2 / 0 | 2.2 / 0 | 1.1 / 0 |
| 8 | copyto! | 2.8 / 0 | 3.4 / 0 | 6.1 / 0 | 5.3 / 0 | 2.1 / 0 |
| 8 | dot | 7.4 / 0 | 7.6 / 0 | 2.4 / 0 | 2.1 / 0 | 1.3 / 0 |
| 8 | affine loop | 2.2 / 0 | 2.2 / 0 | 3.1 / 0 | 3.7 / 0 | 2.0 / 0 |
| 8 | in-place broadcast expression | 3.3 / 0 | 3.2 / 0 | 6.1 / 0 | 6.7 / 0 | 1.8 / 0 |
| 16 | escaping construction | 20.0 / 192 | 20.5 / 192 | 7.3 / 64 | 9.8 / 48 | 10.9 / 144 |
| 16 | construct + fill + sum | 13.2 / 192 | 9.6 / 160 | 16.7 / 0 | 15.1 / 0 | 6.0 / 144 |
| 16 | fill! | 1.8 / 0 | 2.2 / 0 | 3.8 / 0 | 3.8 / 0 | 1.6 / 0 |
| 16 | sum | 3.7 / 0 | 3.7 / 0 | 5.0 / 0 | 3.9 / 0 | 1.5 / 0 |
| 16 | indexing | 1.1 / 0 | 1.3 / 0 | 2.2 / 0 | 2.2 / 0 | 1.2 / 0 |
| 16 | copyto! | 3.0 / 0 | 3.6 / 0 | 6.5 / 0 | 5.8 / 0 | 3.3 / 0 |
| 16 | dot | 9.4 / 0 | 9.9 / 0 | 2.9 / 0 | 2.7 / 0 | 2.0 / 0 |
| 16 | affine loop | 2.6 / 0 | 2.6 / 0 | 3.7 / 0 | 4.8 / 0 | 3.0 / 0 |
| 16 | in-place broadcast expression | 3.8 / 0 | 3.7 / 0 | 6.7 / 0 | 7.8 / 0 | 2.4 / 0 |
| 32 | escaping construction | 30.5 / 320 | 25.9 / 320 | 7.5 / 64 | 9.2 / 48 | 14.8 / 272 |
| 32 | construct + fill + sum | 17.4 / 320 | 12.5 / 288 | 17.9 / 0 | 16.3 / 0 | 8.3 / 272 |
| 32 | fill! | 2.8 / 0 | 3.2 / 0 | 4.8 / 0 | 4.8 / 0 | 2.4 / 0 |
| 32 | sum | 4.5 / 0 | 4.8 / 0 | 5.6 / 0 | 4.5 / 0 | 2.2 / 0 |
| 32 | indexing | 1.1 / 0 | 1.3 / 0 | 2.2 / 0 | 2.2 / 0 | 1.0 / 0 |
| 32 | copyto! | 4.0 / 0 | 4.7 / 0 | 7.3 / 0 | 6.4 / 0 | 5.2 / 0 |
| 32 | dot | 7.6 / 0 | 7.6 / 0 | 4.1 / 0 | 4.0 / 0 | 3.0 / 0 |
| 32 | affine loop | 3.2 / 0 | 3.5 / 0 | 4.6 / 0 | 4.3 / 0 | 2.8 / 0 |
| 32 | in-place broadcast expression | 4.9 / 0 | 4.8 / 0 | 8.1 / 0 | 7.3 / 0 | 4.0 / 0 |
| 64 | escaping construction | 15.3 / 576 | 27.3 / 576 | 7.5 / 64 | 9.2 / 48 | 8.8 / 544 |
| 64 | construct + fill + sum | 21.8 / 576 | 16.6 / 544 | 20.3 / 0 | 18.9 / 0 | 16.8 / 544 |
| 64 | fill! | 4.5 / 0 | 5.0 / 0 | 7.2 / 0 | 7.0 / 0 | 4.1 / 0 |
| 64 | sum | 6.0 / 0 | 5.6 / 0 | 6.6 / 0 | 5.8 / 0 | 5.6 / 0 |
| 64 | indexing | 0.9 / 0 | 1.3 / 0 | 2.2 / 0 | 2.2 / 0 | 1.1 / 0 |
| 64 | copyto! | 6.0 / 0 | 6.6 / 0 | 9.0 / 0 | 8.4 / 0 | 4.7 / 0 |
| 64 | dot | 9.9 / 0 | 9.8 / 0 | 6.7 / 0 | 6.5 / 0 | 5.5 / 0 |
| 64 | affine loop | 5.0 / 0 | 5.3 / 0 | 6.5 / 0 | 6.2 / 0 | 4.5 / 0 |
| 64 | in-place broadcast expression | 6.9 / 0 | 6.8 / 0 | 11.1 / 0 | 9.1 / 0 | 14.2 / 0 |
| 100 | escaping construction | 18.3 / 928 | 19.9 / 928 | 7.5 / 64 | 9.4 / 48 | 8.9 / 816 |
| 100 | construct + fill + sum | 27.8 / 928 | 22.1 / 896 | 22.9 / 0 | 21.6 / 0 | 30.6 / 816 |
| 100 | fill! | 7.1 / 0 | 7.5 / 0 | 9.0 / 0 | 9.0 / 0 | 8.1 / 0 |
| 100 | sum | 5.9 / 0 | 6.1 / 0 | 6.8 / 0 | 6.1 / 0 | 11.0 / 0 |
| 100 | indexing | 1.1 / 0 | 1.3 / 0 | 2.2 / 0 | 2.2 / 0 | 1.1 / 0 |
| 100 | copyto! | 7.8 / 0 | 8.5 / 0 | 10.8 / 0 | 10.5 / 0 | 7.2 / 0 |
| 100 | dot | 13.2 / 0 | 13.4 / 0 | 9.6 / 0 | 9.4 / 0 | 9.0 / 0 |
| 100 | affine loop | 7.5 / 0 | 8.0 / 0 | 9.0 / 0 | 8.8 / 0 | 7.5 / 0 |
| 100 | in-place broadcast expression | 8.9 / 0 | 8.8 / 0 | 15.9 / 0 | 11.7 / 0 | 28.4 / 0 |
| 1000 | escaping construction | 37.8 / 8256 | 36.9 / 8256 | 7.5 / 64 | 9.2 / 48 | 25.7 / 8064 |
| 1000 | construct + fill + sum | 172.6 / 8256 | 170.0 / 8224 | 140.6 / 0 | 139.9 / 0 | 574.7 / 8064 |
| 1000 | fill! | 59.2 / 0 | 57.6 / 0 | 57.9 / 0 | 57.6 / 0 | 105.7 / 0 |
| 1000 | sum | 59.3 / 0 | 59.2 / 0 | 60.2 / 0 | 59.7 / 0 | 378.3 / 0 |
| 1000 | indexing | 0.9 / 0 | 1.3 / 0 | 2.2 / 0 | 2.2 / 0 | 1.1 / 0 |
| 1000 | copyto! | 65.7 / 0 | 65.5 / 0 | 68.4 / 0 | 67.0 / 0 | 63.1 / 0 |
| 1000 | dot | 97.5 / 0 | 97.6 / 0 | 84.7 / 0 | 84.4 / 0 | 83.5 / 0 |
| 1000 | affine loop | 64.4 / 0 | 65.0 / 0 | 64.2 / 0 | 64.5 / 0 | 64.2 / 0 |
| 1000 | in-place broadcast expression | 63.9 / 0 | 63.9 / 0 | 71.4 / 0 | 67.3 / 0 | 273.3 / 0 |
| 10000 | escaping construction | 159.3 / 81984 | 162.6 / 81984 | 7.5 / 64 | 9.5 / 48 | — |
| 10000 | construct + fill + sum | 1533.3 / 81984 | 1537.5 / 81952 | 1208.3 / 0 | 1204.2 / 0 | — |
| 10000 | fill! | 551.4 / 0 | 550.3 / 0 | 546.3 / 0 | 546.1 / 0 | — |
| 10000 | sum | 614.3 / 0 | 615.7 / 0 | 603.5 / 0 | 602.3 / 0 | — |
| 10000 | indexing | 1.1 / 0 | 1.3 / 0 | 2.2 / 0 | 2.2 / 0 | — |
| 10000 | copyto! | 746.2 / 0 | 776.3 / 0 | 740.0 / 0 | 572.1 / 0 | — |
| 10000 | dot | 1104.2 / 0 | 1104.2 / 0 | 1054.2 / 0 | 1070.8 / 0 | — |
| 10000 | affine loop | 645.9 / 0 | 633.7 / 0 | 625.0 / 0 | 625.0 / 0 | — |
| 10000 | in-place broadcast expression | 628.4 / 0 | 631.9 / 0 | 634.5 / 0 | 626.8 / 0 | — |
| 100000 | escaping construction | 696.2 / 802880 | 698.4 / 802880 | 7.6 / 64 | 9.8 / 48 | — |
| 100000 | construct + fill + sum | 14333.0 / 802880 | 14375.0 / 802848 | 12792.0 / 0 | 12875.0 / 0 | — |
| 100000 | fill! | 5444.5 / 0 | 5465.2 / 0 | 5430.5 / 0 | 5430.5 / 0 | — |
| 100000 | sum | 6775.0 / 0 | 6725.0 / 0 | 6800.0 / 0 | 6800.0 / 0 | — |
| 100000 | indexing | 1.1 / 0 | 1.3 / 0 | 2.2 / 0 | 2.2 / 0 | — |
| 100000 | copyto! | 8194.3 / 0 | 8153.0 / 0 | 8152.7 / 0 | 8153.0 / 0 | — |
| 100000 | dot | 11584.0 / 0 | 11542.0 / 0 | 11583.0 / 0 | 11584.0 / 0 | — |
| 100000 | affine loop | 11375.0 / 0 | 11000.0 / 0 | 11375.0 / 0 | 11417.0 / 0 | — |
| 100000 | in-place broadcast expression | 11542.0 / 0 | 11042.0 / 0 | 11500.0 / 0 | 11583.0 / 0 | — |

<!-- END GENERATED BENCHMARK: additional -->

Construction inside a non-escaping scope is measured separately in the CSV for
both Goose variants. The CSV also reports arena bytes consumed. Zero GC bytes
does not mean zero memory usage: for these `Float64` arrays, elements occupy
8×n bytes, plus initial metadata and any escaping descriptors.

## Immutable StaticArrays reference results

<!-- BEGIN GENERATED BENCHMARK: svector -->

| n | SVector sum | SVector abs2 reduction | SVector map then sum | SVector broadcast then sum |
| ---: | ---: | ---: | ---: | ---: |
| 2 | 1.1 / 0 | 1.5 / 0 | 1.5 / 0 | 1.5 / 0 |
| 3 | 1.1 / 0 | 1.5 / 0 | 1.8 / 0 | 1.8 / 0 |
| 4 | 1.0 / 0 | 1.5 / 0 | 1.8 / 0 | 1.8 / 0 |
| 8 | 1.3 / 0 | 1.8 / 0 | 1.9 / 0 | 1.9 / 0 |
| 16 | 1.5 / 0 | 2.1 / 0 | 2.3 / 0 | 2.4 / 0 |
| 32 | 2.2 / 0 | 3.5 / 0 | 5.0 / 0 | 5.0 / 0 |
| 64 | 6.0 / 0 | 9.3 / 0 | 12.5 / 0 | 12.5 / 0 |
| 100 | 11.0 / 0 | 17.3 / 0 | 23.6 / 0 | 23.6 / 0 |
| 1000 | 378.3 / 0 | 401.0 / 0 | 589.1 / 0 | 589.1 / 0 |

<!-- END GENERATED BENCHMARK: svector -->

`SMatrix` multiplication followed by summation is also available in the CSV
for small matrices.

## Compilation and specialization

Measurements use a fresh process, excluding input construction and package
loading. The first call uses `invokelatest` to include compilation of the
measured kernel. Timings depend on call order and compiler behavior, so these
do not constitute a full startup benchmark. Counts refer to `MethodInstance`
objects, not an exhaustive inventory of `CodeInstance` objects.

<!-- BEGIN GENERATED BENCHMARK: specialization -->

| Family | Shapes tested | Concrete types | Final kernel instances | Cumulative kernel compilation (ms) |
| ---: | ---: | ---: | ---: | ---: |
| Array | 11 | 1 | 1 | 4.080 |
| FixedSizeArray | 11 | 1 | 1 | 15.825 |
| GooseArray | 11 | 1 | 1 | 7.212 |
| StaticGooseArray | 11 | 11 | 11 | 73.773 |
| MVector | 9 | 9 | 9 | 54.738 |
| SVector | 9 | 9 | 9 | 25.656 |

<!-- END GENERATED BENCHMARK: specialization -->

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

### Refresh the displayed tables

All benchmark tables in this page and the README are generated by a **Julia-only**
script from the CSV files in `benchmark/reference/m5-max-2026-10-31/`:

```sh
julia --startup-file=no benchmark/update_tables.jl
```

For a new campaign, first save the `benchmarks.csv`, `staged.csv`, and, if
available, `specialization.csv` files in a version-controlled reference folder.
Then refresh both Markdown files in one command:

```sh
julia --startup-file=no benchmark/update_tables.jl --source benchmark/reference/my-new-run
```

If `specialization.csv` is missing, its existing table is left unchanged.
Update the written hardware, Julia version, date, case counts, and methodology
separately: the generator only replaces the tables, not their contextual text.
For CI-style consistency checks, use `--check` instead of regenerating files.


Out-of-place `map` timings include consuming the result and, for Goose arrays,
leaving the scope. Zero reported GC allocation does not mean the arena uses
zero bytes. Escaping descriptors and arena initialization can allocate on the
GC heap. Results depend on the machine, Julia version, and execution context.
