using Test, LinearAlgebra, Random, GooseArrays
include("kernels.jl")
include("optimization.jl")

struct AlignedValue
    x::NTuple{4,VecElement{Float64}}
end
struct ResetOnConvert
    stack::DataStack
end
Base.convert(::Type{Float64}, x::ResetOnConvert) = (reset!(x.stack); 3.0)

@testset "arena setup and fixed-size array interface" begin
    @test_throws ArgumentError DataStack(0)
    @test_throws ArgumentError DataStack(-1)
    @test_throws ArgumentError DataStack(8; max_scopes=-1)
    with_datastack(1 << 20) do s
        @test isopen(s)
        @test capacity(s) == 1 << 20
        @test bytesused(s) == 0
        a = @inferred GooseVector{Float64}(s, undef, 6)
        @test a isa GooseArray{Float64,1}
        @test size(a) == (6,)
        @test axes(a) == (Base.OneTo(6),)
        @test size(a, 2) == 1
        @test length(a) == 6
        @test strides(a) == (1,)
        @test stride(a, 3) == 6
        @test_throws ArgumentError stride(a, 0)
        @test Base.elsize(typeof(a)) == 8
        @test IndexStyle(typeof(a)) == IndexLinear()
        @test !isbitstype(typeof(a))
        copyto!(a, 1.0:6.0)
        @test collect(a) == collect(1.0:6.0)
        @test sum(a) == 21
        @test mapreduce(abs2, +, a) == 91
        @test a[begin] == 1
        @test a[end] == 6
        @test isassigned(a, 1)
        @test !isassigned(a, 7)
        @test_throws BoundsError a[0]
        @test_throws BoundsError a[7]
        @test_throws BoundsError (a[0] = 1)
        a[2] = 9
        @test a[2] === 9.0
        @test_throws InexactError (a[1] = 1 + im)
        b = @inferred GooseMatrix{Int}(s, undef, (2, 3))
        copyto!(b, reshape(1:6, 2, 3))
        @test size(b) == (2, 3)
        @test strides(b) == (1, 2)
        @test b[2, 3] == 6
        b[CartesianIndex(1, 2)] = 42
        @test b[1, 2] == 42
        @test b[2, 3, 1] == 6
        @test_throws BoundsError b[1, 4]
        z = @inferred alloc!(s, Float64, ())
        z[] = 2
        @test size(z) == ()
        @test z[] == 2
        @test z .+ 1 == 3
        empty = alloc!(s, Int, 0, 3)
        @test isempty(empty)
        @test sum(empty) == 0
        @test size(empty) == (0, 3)
        @test alloc!(s, Float64, Int32(2)) isa GooseVector{Float64}
        @test available(s) + bytesused(s) == capacity(s)
    end
end

@testset "allocation validation, alignment and transactional failure" begin
    with_datastack(1024) do s
        for bad in (String, Any, Vector{Int}, Nothing, Union{Int,Float64})
            @test_throws ArgumentError alloc!(s, bad, 2)
            @test bytesused(s) == 0
        end
        @test_throws ArgumentError alloc!(s, Int, -1)
        @test_throws OverflowError alloc!(s, Int, typemax(Int), 2)
        @test_throws OutOfMemoryError alloc!(s, Int, typemax(Int))
        @test bytesused(s) == 0
        alloc!(s, UInt8, 1)
        a = alloc!(s, AlignedValue, 2)
        @test UInt(pointer(a)) % Base.datatype_alignment(AlignedValue) == 0
        value = AlignedValue(ntuple(i -> VecElement(Float64(i)), 4))
        a[1] = value
        @test a[1] == value
        top = bytesused(s)
        @test_throws OutOfMemoryError alloc!(s, Float64, 10000)
        @test bytesused(s) == top
    end
    s = DataStack(8)
    a = alloc!(s, Float64, 1)
    a[1] = 1
    @test bytesused(s) == 8
    @test_throws OutOfMemoryError alloc!(s, UInt8, 1)
    close(s)
    close(s)
    @test !isopen(s)
    @test available(s) == 0
    @test_throws InvalidatedArrayError a[1]
    @test_throws InvalidatedArrayError pointer(a)
    @test_throws InvalidatedArrayError alloc!(s, Float64, 1)
end

@testset "nested scopes, stale handles, exception cleanup and Task ownership" begin
    with_datastack(4096; max_scopes=2) do s
        outer = GooseArray(s, [1.0, 2.0])
        saved = bytesused(s)
        escaped = with_scope(s) do s
            a = GooseArray(s, [3.0, 4.0])
            deeper = with_scope(s) do s
                @test_throws ArgumentError with_scope(identity, s)
                GooseArray(s, [7.0])
            end
            @test_throws InvalidatedArrayError deeper[1]
            @test a[1] == 3
            @test outer[2] == 2
            @test_throws ArgumentError close(s)
            @test_throws ArgumentError reset!(s)
            a
        end
        @test bytesused(s) == saved
        @test_throws InvalidatedArrayError escaped[1]
        @test_throws InvalidatedArrayError (@inbounds escaped[1])
        with_scope(s) do s
            replacement = GooseArray(s, [9.0, 10.0])
            @test replacement.ptr == escaped.ptr
            @test_throws InvalidatedArrayError escaped[1]
        end
        @test_throws ErrorException with_scope(s) do s
            alloc!(s, Int, 100)
            error("intentional")
        end
        @test bytesused(s) == saved
        @test outer[1] == 1
        task_error = fetch(@async try outer[1] catch e; e end)
        @test task_error isa ArgumentError
        task_alloc_error = fetch(@async try alloc!(s, Int, 1) catch e; e end)
        @test task_alloc_error isa ArgumentError
        reset!(s)
        @test bytesused(s) == 0
        @test_throws InvalidatedArrayError outer[1]
        fresh = GooseArray(s, [5.0])
        @test_throws InvalidatedArrayError (fresh[1] = ResetOnConvert(s))
        @test bytesused(s) == 0
    end
    escaped = with_datastack(s -> GooseArray(s, [1.0]), 128)
    @test_throws InvalidatedArrayError escaped[1]
    s = DataStack(128; max_scopes=0)
    @test_throws ArgumentError with_scope(identity, s)
    close(s)
    # An array retains its owner even when the creating function returns.
    retained = let s = DataStack(128)
        GooseArray(s, [42.0])
    end
    GC.gc(true)
    @test retained[1] == 42
    close(retained.stack)
end

@testset "copying, reshape, views, broadcast, random and linear algebra" begin
    with_datastack(1 << 22) do s
        a = GooseArray(s, collect(1.0:12.0))
        @test GooseVector(s, [1, 2]) isa GooseVector{Int}
        @test GooseMatrix(s, [1 2; 3 4]) isa GooseMatrix{Int}
        b = @inferred copy(a)
        @test b isa GooseVector{Float64}
        @test b == a
        @test pointer(a) != pointer(b)
        c = @inferred similar(a, Int, (3, 4))
        @test c isa GooseMatrix{Int}
        @test similar(a, Float32) isa GooseVector{Float32}
        @test similar(a, (2, 6)) isa GooseMatrix{Float64}
        @test_throws ArgumentError similar(a, String)
        m = @inferred reshape(a, (3, 4))
        @test m isa GooseMatrix{Float64}
        @test reshape(a, 3, 4) isa GooseMatrix{Float64}
        @test reshape(a, 3, :) isa GooseMatrix{Float64}
        @test vec(m) isa GooseVector{Float64}
        @test pointer(m) == pointer(a)
        m[2, 2] = 50
        @test a[5] == 50
        @test_throws DimensionMismatch reshape(a, 5, 5)
        @test_throws ArgumentError reshape(a, (-3, -4))
        v = view(a, 2:5)
        v .= 3
        @test collect(v) == fill(3.0, 4)
        @test a[2:5] isa GooseVector{Float64}
        @test a[:] isa GooseVector{Float64}
        @test (a .+ 2) isa GooseVector{Float64}
        @test a .+ 2 == collect(a) .+ 2
        @test 2 .+ a == collect(a) .+ 2
        @test (a .+ ones(12)) isa GooseVector{Float64}
        @test (view(a, :) .+ 1) isa GooseVector{Float64}
        @test map(abs2, a) == abs2.(collect(a))
        a .= 2 .* b .+ 1
        @test a == 2 .* collect(b) .+ 1
        @test Base.mightalias(a, reshape(a, 3, 4))
        @test !Base.mightalias(a, b)
        x = GooseArray(s, collect(1:6))
        copyto!(x, 2, x, 1, 5)
        @test collect(x) == [1, 1, 2, 3, 4, 5]
        @test copyto!(x, 7, x, 7, 0) === x
        @test_throws BoundsError copyto!(x, 7, x, 1, 1)
        @test_throws ArgumentError copyto!(x, 1, x, 1, -1)
        @test copy!(x, fill(2, 6)) === x
        @test_throws DimensionMismatch copy!(x, [1, 2])
        copyto!(x, 1:6)
        x[2:6] .= view(x, 1:5)
        @test collect(x) == [1, 1, 2, 3, 4, 5]
        rng = MersenneTwister(7)
        rand!(rng, a)
        @test all(z -> 0 <= z < 1, a)
        @test dot(a, a) ≈ sum(abs2, collect(a))
        A0 = [2.0 1.0; 0.0 3.0]
        B0 = [1.0 2.0; 4.0 5.0]
        A = GooseArray(s, A0)
        B = GooseArray(s, B0)
        C = similar(A)
        mul!(C, A, B)
        @test C ≈ A0 * B0
        @test A * B ≈ A0 * B0
        @test transpose(A) * B ≈ transpose(A0) * B0
        @test sum(A; dims=1) ≈ sum(A0; dims=1)
        out = zeros(2, 2)
        copyto!(out, A)
        @test out == A0
        GC.@preserve a @test unsafe_load(pointer(a), 1) == a[1]
        staleview = with_scope(s) do s
            view(GooseArray(s, [1.0, 2.0]), :)
        end
        @test_throws InvalidatedArrayError staleview[1]
        @test_throws InvalidatedArrayError fill!(a, ResetOnConvert(s))
    end
end

@testset "method compatibility" begin
    @test isempty(Test.detect_ambiguities(GooseArrays, Base; recursive=false))
end

@testset "zero GC allocations after warmup (typed nonescaping kernels)" begin
    # Ensure the allocation-measurement wrapper itself is allocation-free.
    @test measure_bytes(identity, 123) == 0
    with_datastack(1 << 24) do s
        a = alloc!(s, Float64, 1000)
        b = alloc!(s, Float64, 1000)
        fill!(b, 2.0)
        for n in (100, 1000, 10000, 100000)
            @test measure_bytes(construction_kernel, s, n) == 0
            @test measure_bytes(scoped_kernel, s, n) == 0
        end
        @test measure_bytes(compute_kernel!, a, b) == 0
        @test measure_bytes(broadcast_kernel!, a, b) == 0
        @test measure_bytes(copy_kernel!, a, b) == 0
        @test measure_bytes(derived_kernel, s, 1000) == 0
        @test derived_kernel(s, 1000) == 3000
        @test compute_kernel!(a, b) == 5000
    end
end

@testset "runtime shapes do not multiply type or MethodInstance" begin
    with_datastack(1 << 22) do s
        for n in (1, 100)
            a = alloc!(s, Float64, n)
            fill!(a, 1)
            @test typeof(a) === GooseVector{Float64}
            shape_probe(a)
        end
        method = which(shape_probe, (GooseVector{Float64},))
        instances() = Set(mi.specTypes for mi in Base.specializations(method) if mi isa Core.MethodInstance)
        before = instances()
        for n in 1:500
            with_scope(s) do s
                a = alloc!(s, Float64, n)
                fill!(a, 1)
                @test typeof(a) === GooseVector{Float64}
                @test shape_probe(a) == 2
            end
        end
        @test instances() == before
        for n in 1:50
            @test typeof(alloc!(s, Float64, (n, 2))) === GooseMatrix{Float64}
        end
    end
end

include("static_array.jl")
include("performance_paths.jl")
include("validity_map.jl")

include("stages.jl")
include("multimap.jl")
