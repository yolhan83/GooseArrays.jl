@noinline function wrapped_to_goose!(a, wrapped)
    @inbounds for i in 2:length(a)
        a[i] = wrapped[i - 1] + 1
    end
    nothing
end
@noinline function goose_to_wrapped!(wrapped, a)
    @inbounds for i in 2:length(a)
        wrapped[i] = a[i - 1] + 1
    end
    nothing
end

@noinline function invalidating_loop!(a, s, stop, operation)
    @inbounds for i in eachindex(a)
        i == stop && operation(s)
        a[i] = 7.0
    end
    nothing
end

@noinline function scalar_store_kernel!(a, value)
    @inbounds for i in eachindex(a)
        a[i] = value
    end
    nothing
end

@testset "optimized scalar stores preserve values and array aliases" begin
    with_datastack(1 << 20) do s
        samples = (false, true, Int8(-19), UInt8(251), Int16(-2000), UInt16(65000),
            Int32(-200000), UInt32(4000000000), Int64(-100000000000),
            UInt64(0xfedcba9876543210), Int128(-1) << 100, UInt128(1) << 120,
            Float16(-0.0), Float32(-0.0), -0.0, Float16(Inf), Float32(NaN),
            reinterpret(Float64, UInt64(0x7ff800000000002a)), 'λ',
            ComplexF32(1, -2), ComplexF64(-0.0, Inf))
        for value in samples
            a = alloc!(s, typeof(value), 17)
            for i in eachindex(a)
                a[i] = value
            end
            @test all(x -> isequal(x, value), a)
            fill!(a, value)
            @test all(x -> isequal(x, value), a)
            @test reinterpret(UInt8, [a[1]]) == reinterpret(UInt8, [value])
            @test measure_bytes(scalar_store_kernel!, a, value) == 0
        end
        a = alloc!(s, Float64, 257)
        GC.@preserve a begin
            wrapped = unsafe_wrap(Array, pointer(a), size(a); own=false)
            fill!(a, 0.0)
            wrapped_to_goose!(a, wrapped)
            @test a == Float64.(0:256)
            fill!(a, 0.0)
            goose_to_wrapped!(wrapped, a)
            @test a == Float64.(0:256)
            a .= wrapped .+ 2
            @test wrapped == Float64.(2:258)
        end
    end
end

@testset "metadata mutation prevents unsafe check hoisting" begin
    for stop in (1, 8, 31), operation in (reset!, close)
        s = DataStack(4096)
        a = alloc!(s, Float64, 32)
        @test_throws InvalidatedArrayError invalidating_loop!(a, s, stop, operation)
        @test_throws InvalidatedArrayError (@inbounds a[1])
        close(s)
    end
    for operation in (reset!, close)
        s = DataStack(4096)
        a = GooseArray(s, ones(32))
        calls = Ref(0)
        invalidate(x) = (calls[] += 1; calls[] == 8 && operation(s); x + 1)
        @test_throws InvalidatedArrayError (a .= invalidate.(a))
        @test calls[] == 8
        close(s)
    end
    with_datastack(4096) do s
        stale = with_scope(s) do s
            GooseArray(s, ones(32))
        end
        live = GooseArray(s, ones(32))
        @test_throws InvalidatedArrayError compute_kernel!(live, stale)
        @test_throws InvalidatedArrayError broadcast_kernel!(live, stale)
        @test_throws InvalidatedArrayError compute_kernel!(stale, live)
    end
end
