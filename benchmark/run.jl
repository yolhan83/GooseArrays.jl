using GooseArrays, FixedSizeArrays, StaticArrays, BenchmarkTools, LinearAlgebra, Printf
include(joinpath(@__DIR__, "..", "test", "kernels.jl"))

const SECONDS = parse(Float64, get(ENV, "GOOSE_BENCH_SECONDS", "0.2"))
const SAMPLES = parse(Int, get(ENV, "GOOSE_BENCH_SAMPLES", "2000"))
const RESULT_DIR = get(ENV, "GOOSE_BENCH_OUT", joinpath(@__DIR__, "results"))
const LENGTHS = parse.(Int, split(get(ENV,"GOOSE_BENCH_LENGTHS","2,3,4,8,16,32,64,100,1000,10000,100000"),','))
const MATRIX_SIZES = parse.(Int, split(get(ENV,"GOOSE_BENCH_MATRIX_SIZES","2,3,4,8,16,64,256"),','))
const STATICARRAYS_MAX = parse(Int,get(ENV,"GOOSE_BENCH_STATICARRAYS_MAX","1000"))
mkpath(RESULT_DIR)
BLAS.set_num_threads(1)

@inline affine(x) = 2.0*x + 1.0
@noinline make_base(n) = Vector{Float64}(undef,n)
@noinline make_fixed(n) = FixedSizeArray{Float64}(undef,n)
@noinline make_goose(s,n) = alloc!(s,Float64,n)
@noinline make_staticgoose(s,::Val{L}) where {L} = StaticGooseVector{Float64,L}(s,undef)
@noinline make_mvector(::Val{L}) where {L} = MVector{L,Float64}(undef)
@noinline make_svector(::Val{L}) where {L} = SVector{L,Float64}(ntuple(i->Float64(i),Val(L)))

@noinline function store_goose!(sink,s,n)
    reset!(s); sink[] = make_goose(s,n); nothing
end
@noinline function store_staticgoose!(sink,s,v)
    reset!(s); sink[] = make_staticgoose(s,v); nothing
end
@noinline function fill_sum(make,arg)
    a=make(arg); fill!(a,2.0); sum(a)
end
@noinline function static_scoped_construct(s,::Val{L}) where {L}
    with_scope(s) do s
        a=StaticGooseVector{Float64,L}(s,undef)
        length(a)
    end
end
@noinline function static_scoped_fill_sum(s,::Val{L}) where {L}
    with_scope(s) do s
        a=StaticGooseVector{Float64,L}(s,undef)
        fill!(a,2.0); sum(a)
    end
end
@noinline function loop_update!(a,b)
    @inbounds for i in eachindex(a,b); a[i]=affine(b[i]); end
    nothing
end
@noinline map_update!(a,b) = (map!(affine,a,b); nothing)
@noinline broadcast_update!(a,b) = (a .= affine.(b); nothing)
@noinline map_then_sum(a) = sum(map(affine,a))
@noinline broadcast_then_sum(a) = sum(affine.(a))
@noinline broadcast_expr_then_sum(a) = sum(2.0 .* a .+ 1.0)
@noinline broadcast_expr_update!(a,b) = (a .= 2.0 .* b .+ 1.0;nothing)
@noinline reduction(a) = mapreduce(abs2,+,a)
@noinline fused_sum(a) = sum(affine,a)
@noinline matrix_then_sum(A,B) = sum(A*B)

# Out-of-place arena results are consumed within a scope, then rewound. The
# ordinary-array cases perform the identical calculation with their own storage.
@noinline scoped_map_sum(a::AbstractGooseArray) = with_scope(_ -> map_then_sum(a),a.stack)
@noinline scoped_broadcast_sum(a::AbstractGooseArray) = with_scope(_ -> broadcast_then_sum(a),a.stack)
@noinline scoped_broadcast_expr_sum(a::AbstractGooseArray) = with_scope(_ -> broadcast_expr_then_sum(a),a.stack)
@noinline scoped_matrix_sum(A::AbstractGooseArray,B) = with_scope(_ -> matrix_then_sum(A,B),A.stack)

const rows = NamedTuple[]
function record!(family,n,operation,bench;arena_bytes=0)
    tune!(bench;seconds=0.02)
    trial=run(bench;seconds=SECONDS,samples=SAMPLES)
    best,middle=minimum(trial),median(trial)
    ordered=sort(trial.times)
    # BenchmarkTools already reports trial.times per evaluation, in ns.
    p95=ordered[max(1,ceil(Int,0.95length(ordered)))]
    @assert 0 < best.time <= middle.time <= p95
    row=(;family,n,operation,min_ns=best.time,median_ns=middle.time,p95_ns=p95,
         gc_bytes=best.memory,gc_allocs=best.allocs,arena_bytes,
         evals=trial.params.evals,samples=length(ordered))
    push!(rows,row)
    @printf("%-18s n=%6d %-23s %11.1f ns %8d GC bytes\n",family,n,operation,middle.time,best.memory)
    flush(stdout)
end

function existing!(family,a,b)
    n=length(a)
    fill!(a,1.0); fill!(b,2.0)
    record!(family,n,"fill!",@benchmarkable fill!($a,2.0))
    record!(family,n,"sum",@benchmarkable sum($b))
    record!(family,n,"mapreduce",@benchmarkable reduction($b))
    record!(family,n,"sum_fused",@benchmarkable fused_sum($b))
    index=Ref(cld(n,2))
    record!(family,n,"getindex",@benchmarkable getindex($b,$index[]))
    record!(family,n,"copyto!",@benchmarkable copyto!($a,$b))
    record!(family,n,"dot",@benchmarkable dot($a,$b))
    record!(family,n,"loop_update!",@benchmarkable loop_update!($a,$b))
    record!(family,n,"map!",@benchmarkable map_update!($a,$b))
    record!(family,n,"broadcast_update!",@benchmarkable broadcast_update!($a,$b))
    record!(family,n,"broadcast_expr!",@benchmarkable broadcast_expr_update!($a,$b))
    if a isa AbstractGooseArray
        record!(family,n,"map_then_sum",@benchmarkable scoped_map_sum($b);arena_bytes=8n)
        record!(family,n,"broadcast_then_sum",@benchmarkable scoped_broadcast_sum($b);arena_bytes=8n)
        record!(family,n,"broadcast_expr_then_sum",@benchmarkable scoped_broadcast_expr_sum($b);arena_bytes=8n)
    else
        record!(family,n,"map_then_sum",@benchmarkable map_then_sum($b))
        record!(family,n,"broadcast_then_sum",@benchmarkable broadcast_then_sum($b))
        record!(family,n,"broadcast_expr_then_sum",@benchmarkable broadcast_expr_then_sum($b))
    end
    @assert all(==(5.0),a)
    @assert sum(b)==2n
    @assert reduction(b)==4n
end

function dynamic!(n)
    sink=Ref{Any}(nothing)
    record!("Array",n,"construct_escape",@benchmarkable $sink[]=make_base($n))
    record!("FixedSizeArray",n,"construct_escape",@benchmarkable $sink[]=make_fixed($n))
    record!("Array",n,"construct_fill_sum",@benchmarkable fill_sum(make_base,$n))
    record!("FixedSizeArray",n,"construct_fill_sum",@benchmarkable fill_sum(make_fixed,$n))
    existing!("Array",ones(n),fill(2.0,n))
    existing!("FixedSizeArray",FixedSizeArray(ones(n)),FixedSizeArray(fill(2.0,n)))
    with_datastack(max(1<<20,64n)) do s
        record!("GooseArray",n,"construct_escape",@benchmarkable store_goose!($sink,$s,$n);arena_bytes=8n)
        reset!(s)
        record!("GooseArray",n,"construct_scoped",@benchmarkable construction_kernel($s,$n);arena_bytes=8n)
        record!("GooseArray",n,"construct_fill_sum",@benchmarkable scoped_kernel($s,$n);arena_bytes=8n)
        a,b=alloc!(s,Float64,n),alloc!(s,Float64,n)
        existing!("GooseArray",a,b)
    end
end

function staticgoose!(::Val{L}) where {L}
    v=Val(L); sink=Ref{Any}(nothing)
    with_datastack(max(1<<20,64L)) do s
        record!("StaticGooseArray",L,"construct_escape",@benchmarkable store_staticgoose!($sink,$s,$v);arena_bytes=8L)
        reset!(s)
        record!("StaticGooseArray",L,"construct_scoped",@benchmarkable static_scoped_construct($s,$v);arena_bytes=8L)
        record!("StaticGooseArray",L,"construct_fill_sum",@benchmarkable static_scoped_fill_sum($s,$v);arena_bytes=8L)
        a,b=make_staticgoose(s,v),make_staticgoose(s,v)
        existing!("StaticGooseArray",a,b)
    end
end

function staticarrays!(::Val{L}) where {L}
    v=Val(L); sink=Ref{Any}(nothing)
    record!("MVector",L,"construct_escape",@benchmarkable $sink[]=make_mvector($v))
    record!("MVector",L,"construct_fill_sum",@benchmarkable fill_sum(make_mvector,$v))
    existing!("MVector",make_mvector(v),make_mvector(v))
    # Immutable reference, kept out of the five mutable-vector columns.
    sv=make_svector(v)
    record!("SVector",L,"sum",@benchmarkable sum($sv))
    record!("SVector",L,"mapreduce",@benchmarkable reduction($sv))
    record!("SVector",L,"sum_fused",@benchmarkable fused_sum($sv))
    record!("SVector",L,"map_then_sum",@benchmarkable map_then_sum($sv))
    record!("SVector",L,"broadcast_then_sum",@benchmarkable broadcast_then_sum($sv))
    record!("SVector",L,"broadcast_expr_then_sum",@benchmarkable broadcast_expr_then_sum($sv))
end

for n in LENGTHS
    dynamic!(n)
    staticgoose!(Val(n))
    n<=STATICARRAYS_MAX && staticarrays!(Val(n))
end

function matrix_existing!(family,A,B,C)
    n=size(A,1)
    fill!(A,1.0);fill!(B,2.0);fill!(C,0.0)
    record!(family,n,"matrix_mul!",@benchmarkable mul!($C,$A,$B))
    if A isa AbstractGooseArray
        record!(family,n,"matrix_*_then_sum",@benchmarkable scoped_matrix_sum($A,$B);arena_bytes=8n*n)
    else
        record!(family,n,"matrix_*_then_sum",@benchmarkable matrix_then_sum($A,$B))
    end
    @assert C[1,1]==2n
    @assert matrix_then_sum(A,B)==2n^3
end

function static_matrices!(::Val{L}) where {L}
    with_datastack(max(1<<20,64L*L)) do s
        A,B,C=(StaticGooseMatrix{Float64,L,L}(s,undef) for _ in 1:3)
        matrix_existing!("StaticGooseArray",A,B,C)
    end
    if L<=16
        A,B,C=(MMatrix{L,L,Float64}(undef) for _ in 1:3)
        matrix_existing!("MMatrix",A,B,C)
        SA,SB=SMatrix(A),SMatrix(B)
        record!("SMatrix",L,"matrix_*_then_sum",@benchmarkable matrix_then_sum($SA,$SB))
    end
end

for n in MATRIX_SIZES
    for (family,make) in (("Array",identity),("FixedSizeArray",FixedSizeArray))
        A,B,C=make(ones(n,n)),make(fill(2.0,n,n)),make(zeros(n,n))
        matrix_existing!(family,A,B,C)
    end
    with_datastack(max(1<<20,64n*n)) do s
        A,B,C=(alloc!(s,Float64,n,n) for _ in 1:3)
        matrix_existing!("GooseArray",A,B,C)
    end
    static_matrices!(Val(n))
end

record!("GooseArray",1048576,"arena_setup_close",@benchmarkable close(DataStack(1<<20)))
open(joinpath(RESULT_DIR,"benchmarks.csv"),"w") do io
    println(io,"family,n,operation,min_ns,median_ns,p95_ns,gc_bytes,gc_allocs,arena_bytes,evals,samples")
    for r in rows;println(io,join(values(r),','));end
end
open(joinpath(RESULT_DIR,"environment.txt"),"w") do io
    println(io,"GooseArrays: ",pkgversion(GooseArrays))
    println(io,"Julia: ",VERSION,"; kernel: ",Sys.KERNEL,"; architecture: ",Sys.ARCH)
    println(io,"CPU: ",Sys.cpu_info()[1].model)
    println(io,"Julia threads: ",Threads.nthreads(),"; BLAS threads: ",BLAS.get_num_threads())
    println(io,"FixedSizeArrays: ",pkgversion(FixedSizeArrays))
    println(io,"StaticArrays: ",pkgversion(StaticArrays))
    println(io,"BenchmarkTools: ",pkgversion(BenchmarkTools))
    println(io,"Seconds per case: ",SECONDS,"; max samples: ",SAMPLES)
    println(io,"Lengths: ",join(LENGTHS,','),"; StaticArrays max: ",STATICARRAYS_MAX)
    println(io,"Square matrix sides: ",join(MATRIX_SIZES,','))
    println(io,"BLAS: ",BLAS.get_config())
end
println("Results: ",RESULT_DIR,"; measured cases: ",length(rows))
