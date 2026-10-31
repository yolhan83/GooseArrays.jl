using GooseArrays, FixedSizeArrays, StaticArrays, Printf

# Run in a fresh process. Timings exclude package loading and array construction.
# The first call includes JIT compilation. Later dimensions reuse dynamic types.
@noinline function compilation_probe(a)
    total = zero(eltype(a))
    @inbounds for i in eachindex(a)
        total += a[i]
    end
    total
end

const RESULT_DIR = get(ENV, "GOOSE_BENCH_OUT", joinpath(@__DIR__, "results"))
mkpath(RESULT_DIR)
const observations = NamedTuple[]
function observe(family, n, a)
    # invokelatest prevents the enclosing observe specialization from compiling
    # the callee before the timer starts. Warm latency includes this call barrier.
    stats = @timed Base.invokelatest(compilation_probe, a)
    warm = @timed Base.invokelatest(compilation_probe, a)
    method = which(compilation_probe, (typeof(a),))
    instances = [mi for mi in Base.specializations(method) if mi isa Core.MethodInstance]
    count_family = count(mi -> mi.specTypes.parameters[2] <: typeof(a).name.wrapper, instances)
    compile_s = hasproperty(stats, :compile_time) ? stats.compile_time : NaN
    row = (; family, n, array_type=string(typeof(a)), first_seconds=stats.time,
           compile_seconds=compile_s, warm_seconds=warm.time, method_instances=count_family)
    push!(observations, row)
    @printf("%-15s n=%6d first=%9.3f ms compile=%9.3f ms instances=%d\n",
            family, n, 1000stats.time, 1000compile_s, count_family)
    flush(stdout)
end

for family in ("Array", "FixedSizeArray", "GooseArray", "StaticGooseArray", "MVector", "SVector")
    with_datastack(1 << 24) do s
        for n in (2,3,4,8,16,32,64,100,1000,10000,100000)
            family in ("MVector", "SVector") && n > 1000 && continue
            a = if family == "Array"
                ones(n)
            elseif family == "FixedSizeArray"
                FixedSizeArray(ones(n))
            elseif family == "GooseArray"
                a = alloc!(s, Float64, n); fill!(a, 1.0); a
            elseif family == "StaticGooseArray"
                a=StaticGooseArray{Float64}(s,undef,Val((n,)));fill!(a,1.0);a
            elseif family == "MVector"
                MVector{n,Float64}(ntuple(_ -> 1.0, n))
            else
                SVector{n,Float64}(ntuple(_ -> 1.0, n))
            end
            observe(family, n, a)
        end
    end
end

open(joinpath(RESULT_DIR, "specialization.csv"), "w") do io
    println(io, "family,n,array_type,first_seconds,compile_seconds,warm_seconds,method_instances")
    for r in observations
        println(io, join((r.family, r.n, '"' * r.array_type * '"', r.first_seconds,
                         r.compile_seconds, r.warm_seconds, r.method_instances), ','))
    end
end
