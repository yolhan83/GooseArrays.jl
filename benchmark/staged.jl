using GooseArrays,FixedSizeArrays,StaticArrays,BenchmarkTools,LinearAlgebra,Printf
const SECONDS=parse(Float64,get(ENV,"GOOSE_BENCH_SECONDS","0.25"))
const SAMPLES=parse(Int,get(ENV,"GOOSE_BENCH_SAMPLES","3000"))
const OUT=get(ENV,"GOOSE_STAGE_OUT",joinpath(@__DIR__,"results"))
const LENGTHS=parse.(Int,split(get(ENV,"GOOSE_STAGE_LENGTHS","2,3,4,8,16,64,1000,10000,100000"),','))
const SIDES=parse.(Int,split(get(ENV,"GOOSE_STAGE_SIDES","2,3,4,8,16,64,256"),','))
BLAS.set_num_threads(1);mkpath(OUT)
@inline binary(x,y)=x*y
@inline ternary(x,y,z)=x+y*z
@noinline map2!(d,a,b)=(map!(binary,d,a,b);nothing)
@noinline map3!(d,a,b,c)=(map!(ternary,d,a,b,c);nothing)
@noinline map2sum(a,b)=sum(map(binary,a,b))
@noinline map3sum(a,b,c)=sum(map(ternary,a,b,c))
@noinline reduce2(a,b)=mapreduce(binary,+,a,b)
@noinline reduce3(a,b,c)=mapreduce(ternary,+,a,b,c)
@noinline scoped2(f,a,b)=with_scope(_->f(a,b),a.stack)
@noinline scoped3(f,a,b,c)=with_scope(_->f(a,b,c),a.stack)
@noinline axpy_step!(y,x)=(axpy!(0.25,x,y);nothing)
@noinline axpby_step!(y,x)=(axpby!(0.25,x,0.5,y);nothing)
@noinline matvec!(y,A,x)=(mul!(y,A,x);nothing)
@noinline matvecsum(A,x)=sum(A*x)
@noinline scoped_matvecsum(A,x)=with_scope(_->matvecsum(A,x),A.stack)
const rows=NamedTuple[]
const STATICGOOSE_MAX=parse(Int,get(ENV,"GOOSE_STAGE_STATICGOOSE_MAX","100000"))
function record(family,n,op,bench)
    tune!(bench;seconds=0.02)
    t=run(bench;seconds=SECONDS,samples=SAMPLES);best=minimum(t);mid=median(t)
    p95=sort(t.times)[ceil(Int,0.95length(t.times))]
    @assert 0<best.time<=mid.time<=p95
    push!(rows,(;family,n,operation=op,min_ns=best.time,median_ns=mid.time,p95_ns=p95,
        gc_bytes=best.memory,gc_allocs=best.allocs,evals=t.params.evals,samples=length(t.times)))
    @printf("%-17s %6d %-24s %12.2f ns %8d bytes\n",family,n,op,mid.time,best.memory);flush(stdout)
    open(joinpath(OUT,"staged.csv"),"w") do io
        println(io,"family,n,operation,min_ns,median_ns,p95_ns,gc_bytes,gc_allocs,evals,samples")
        for r in rows;println(io,join(values(r),','));end
    end
end
function vectors(family,a,b,c,d)
    n=length(a);fill!(a,1);fill!(b,2);fill!(c,3);fill!(d,0)
    record(family,n,"map2!",@benchmarkable map2!($d,$a,$b))
    record(family,n,"map3!",@benchmarkable map3!($d,$a,$b,$c))
    record(family,n,"axpy!",@benchmarkable axpy_step!($d,$b))
    record(family,n,"axpby!",@benchmarkable axpby_step!($d,$b))
    if a isa AbstractGooseArray
        record(family,n,"map2_then_sum",@benchmarkable scoped2(map2sum,$a,$b))
        record(family,n,"map3_then_sum",@benchmarkable scoped3(map3sum,$a,$b,$c))
        record(family,n,"mapreduce2",@benchmarkable scoped2(reduce2,$a,$b))
        record(family,n,"mapreduce3",@benchmarkable scoped3(reduce3,$a,$b,$c))
    else
        record(family,n,"map2_then_sum",@benchmarkable map2sum($a,$b))
        record(family,n,"map3_then_sum",@benchmarkable map3sum($a,$b,$c))
        record(family,n,"mapreduce2",@benchmarkable reduce2($a,$b))
        record(family,n,"mapreduce3",@benchmarkable reduce3($a,$b,$c))
    end
    @assert map2sum(a,b)==2n && map3sum(a,b,c)==7n
    @assert reduce2(a,b)==2n && reduce3(a,b,c)==7n
end
function statics(n,::Val{N}) where N
    if N<=STATICGOOSE_MAX
        with_datastack(max(1<<20,80n)) do s
            vectors("StaticGooseArray",(StaticGooseVector{Float64,N}(s,undef) for _ in 1:4)...)
        end
    end
    N<=1000 && vectors("MVector",(MVector{N,Float64}(undef) for _ in 1:4)...)
end
for n in LENGTHS
    for (family,make) in (("Array",identity),("FixedSizeArray",FixedSizeArray))
        vectors(family,(make(zeros(n)) for _ in 1:4)...)
    end
    with_datastack(max(1<<20,80n)) do s
        vectors("GooseArray",(alloc!(s,Float64,n) for _ in 1:4)...)
    end
    statics(n,Val(n))
end
function matrices(family,A,x,y)
    n=length(x);fill!(A,1);fill!(x,2);fill!(y,0)
    record(family,n,"matvec_mul!",@benchmarkable matvec!($y,$A,$x))
    if A isa AbstractGooseArray
        record(family,n,"matvec_*_then_sum",@benchmarkable scoped_matvecsum($A,$x))
    else
        record(family,n,"matvec_*_then_sum",@benchmarkable matvecsum($A,$x))
    end
    @assert all(==(2n),y) && matvecsum(A,x)==2n*n
end
function staticmatrices(n,::Val{N}) where N
    with_datastack(max(1<<20,32n*n)) do s
        matrices("StaticGooseArray",StaticGooseMatrix{Float64,N,N}(s,undef),
            StaticGooseVector{Float64,N}(s,undef),StaticGooseVector{Float64,N}(s,undef))
    end
    N<=16 && matrices("MVector",MMatrix{N,N,Float64}(undef),MVector{N,Float64}(undef),MVector{N,Float64}(undef))
end
for n in SIDES
    for (family,make) in (("Array",identity),("FixedSizeArray",FixedSizeArray))
        matrices(family,make(zeros(n,n)),make(zeros(n)),make(zeros(n)))
    end
    with_datastack(max(1<<20,32n*n)) do s
        matrices("GooseArray",alloc!(s,Float64,n,n),alloc!(s,Float64,n),alloc!(s,Float64,n))
    end
    staticmatrices(n,Val(n))
end
open(joinpath(OUT,"staged.csv"),"w") do io
    println(io,"family,n,operation,min_ns,median_ns,p95_ns,gc_bytes,gc_allocs,evals,samples")
    for r in rows;println(io,join(values(r),','));end
end
write(joinpath(OUT,"staged-environment.txt"),"GooseArrays=$(pkgversion(GooseArrays))\nJulia=$VERSION\nCPU=$(Sys.cpu_info()[1].model)\nBLAS=$(BLAS.get_config())\nthreads=$(Threads.nthreads()), BLAS=$(BLAS.get_num_threads())\nseconds=$SECONDS, samples=$SAMPLES\nlengths=$(join(LENGTHS,','))\nStaticGoose max=$STATICGOOSE_MAX\nsides=$(join(SIDES,','))\n")
println("Staged cases: ",length(rows))
