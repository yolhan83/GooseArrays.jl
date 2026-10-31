@noinline function static_scoped_kernel(stack, ::Val{L}) where {L}
    with_scope(stack) do s
        a = StaticGooseVector{Float64,L}(s, undef)
        fill!(a, 2.0)
        b = a .+ 1.0
        sum(b)
    end
end

@noinline static_shape_probe(a) = (@inbounds a[1] + a[end])
@noinline static_map_sum(a) = with_scope(_ -> sum(map(abs2,a)),a.stack)
@noinline static_matrix_sum(a) = with_scope(_ -> sum(a*a),a.stack)

@testset "StaticGooseArray constructors, shape and conversions" begin
    with_datastack(1 << 20) do s
        a = @inferred StaticGooseVector{Float64,3}(s, undef)
        @test a isa AbstractGooseArray{Float64,1}
        @test size(a) === (3,)
        @test length(a) == 3
        @test sizeof(a) == 4sizeof(Int)
        @test !isbitstype(typeof(a))
        @test strides(a) == (1,)
        copyto!(a, [1,2,3])
        @test collect(a) == [1,2,3]
        @test a[end] == 3
        @test_throws BoundsError a[4]
        @test_throws BoundsError (a[0] = 1)
        b = @inferred StaticGooseArray{Int}(s, undef, Val((2,3)))
        @test b isa StaticGooseMatrix{Int,2,3}
        copyto!(b, reshape(1:6,2,3))
        @test b[2,3] == 6
        @test b[CartesianIndex(1,2)] == 3
        @test strides(b) == (1,2)
        z = StaticGooseArray{Float64}(s, undef, Val(()))
        z[] = 4
        @test z[] == 4
        @test z .+ 1 == 5
        empty = StaticGooseArray{Int}(s, undef, Val((0,3)))
        @test length(empty) == 0
        @test sum(empty) == 0
        @test size(empty .+ 1) == (0,3)
        @test StaticGooseVector{Int,3}(s,[1,2,3]) == [1,2,3]
        @test StaticGooseArray(s,[1,2,3],Val((3,))) isa StaticGooseVector{Int,3}
        @test StaticGooseArray{Float32}(s,[1,2,3],Val((3,))) isa StaticGooseVector{Float32,3}
        top = bytesused(s)
        @test_throws ArgumentError StaticGooseVector{Float64,-1}(s,undef)
        @test_throws ArgumentError StaticGooseArray{Float64}(s,undef,Val((2.5,)))
        @test_throws ArgumentError StaticGooseArray{Float64}(s,undef,Val(3))
        @test_throws ArgumentError StaticGooseVector{String,3}(s,undef)
        @test_throws DimensionMismatch StaticGooseVector{Int,2}(s,[1,2,3])
        @test_throws DimensionMismatch StaticGooseArray{Float64,2,Tuple{3}}(s,undef)
        @test_throws OverflowError StaticGooseArray{Int}(s,undef,Val((typemax(Int),2)))
        @test bytesused(s) == top
        erased = @inferred GooseArray(a)
        @test erased isa GooseVector{Float64}
        @test pointer(erased) == pointer(a)
        wrapped = @inferred StaticGooseArray(erased,Val((3,)))
        @test wrapped isa StaticGooseVector{Float64,3}
        @test pointer(wrapped) == pointer(a)
        @test_throws DimensionMismatch StaticGooseArray(erased,Val((1,3)))
        wrapped[1] = 9
        @test a[1] == 9
        @test bytesused(s) == top
    end
end

@testset "static operations and mixed array interoperability" begin
    with_datastack(1 << 22) do s
        a = StaticGooseVector{Float64,6}(s,collect(1:6))
        @test copy(a) isa StaticGooseVector{Float64,6}
        @test copy(a) == a
        @test similar(a) isa StaticGooseVector{Float64,6}
        @test similar(a,Int) isa StaticGooseVector{Int,6}
        @test similar(a,Int,(2,3)) isa GooseMatrix{Int}
        @test similar(a,Int,Val((2,3))) isa StaticGooseMatrix{Int,2,3}
        @test reshape(a,(2,3)) isa GooseMatrix{Float64}
        m = @inferred reshape(a,Val((2,3)))
        @test m isa StaticGooseMatrix{Float64,2,3}
        @test pointer(m) == pointer(a)
        @test_throws DimensionMismatch reshape(a,Val((2,4)))
        @test a[:] isa GooseVector{Float64}
        @test collect(view(a,2:4)) == [2,3,4]
        @test (a .+ 2) isa StaticGooseVector{Float64,6}
        @test (2 .+ a) isa StaticGooseVector{Float64,6}
        @test (a .+ a) isa StaticGooseVector{Float64,6}
        @test (a .+ ones(6)) isa GooseVector{Float64}
        d = GooseArray(s,ones(6))
        @test (a .+ d) isa GooseVector{Float64}
        @test (d .+ a) isa GooseVector{Float64}
        @test (view(a,:) .+ 1) isa GooseVector{Float64}
        row = StaticGooseMatrix{Float64,1,3}(s,ones(1,3))
        col = StaticGooseMatrix{Float64,2,1}(s,fill(2.0,2,1))
        expanded = @inferred row .+ col
        @test expanded isa StaticGooseMatrix{Float64,2,3}
        @test expanded == fill(3.0,2,3)
        @test (a .+ row) isa StaticGooseMatrix{Float64,6,3}
        @test_throws DimensionMismatch (a .+ col)
        mapped = map(x -> 2x + 1, a)
        @test mapped isa StaticGooseVector{Float64,6}
        @test mapped == 2 .* collect(a) .+ 1
        map!(abs2, a, a)
        @test a == [1,4,9,16,25,36]
        @test mapreduce(identity,+,a) == 91
        @test sum(m;dims=1) == sum(reshape(collect(a),2,3);dims=1)
        copyto!(a,d)
        @test a == ones(6)
        copyto!(d,a)
        @test d == a
        x = zeros(6)
        copyto!(x,a)
        @test x == ones(6)
        copyto!(a,2,a,1,5)
        @test a == ones(6)
        A = StaticGooseMatrix{Float64,2,2}(s,[1.0 2.0; 3.0 4.0])
        C = similar(A)
        mul!(C,A,A)
        @test C == [7.0 10.0;15.0 22.0]
        @test A*A == C
        @test A*A isa StaticGooseMatrix{Float64,2,2}
        v=StaticGooseVector{Float32,2}(s,[1,2])
        @test A*v isa StaticGooseVector{Float64,2}
        @test A*v == [5,11]
        @test_throws DimensionMismatch A*a
        @test dot(a,a) == 6
        rand!(MersenneTwister(3),a)
        @test all(x -> 0 <= x < 1, a)
    end
end

@testset "static lifetime checks, aliases and allocations" begin
    with_datastack(1 << 22) do s
        outer = StaticGooseVector{Float64,3}(s,[1,2,3])
        old = with_scope(s) do s
            StaticGooseVector{Float64,3}(s,[4,5,6])
        end
        with_scope(s) do s
            fresh = StaticGooseVector{Float64,3}(s,[7,8,9])
            @test fresh.ptr == old.ptr
            @test_throws InvalidatedArrayError old[1]
            @test_throws InvalidatedArrayError (@inbounds old[1])
        end
        @test outer[1] == 1
        task_error = fetch(@async try outer[1] catch e; e end)
        @test task_error isa ArgumentError
        a = StaticGooseVector{Float64,32}(s,ones(32))
        GC.@preserve a begin
            wrapped = unsafe_wrap(Array,pointer(a),size(a);own=false)
            a[1] = 0
            wrapped_to_goose!(a,wrapped)
            @test a == Float64.(0:31)
        end
        for n in (3,16,100,1000)
            @test measure_bytes(static_scoped_kernel,s,Val(n)) == 0
        end
        b = similar(a)
        fill!(b,2)
        @test measure_bytes(compute_kernel!,a,b) == 0
        @test measure_bytes(broadcast_kernel!,a,b) == 0
        @test measure_bytes(copy_kernel!,a,b) == 0
        @test measure_bytes(static_map_sum,b) == 0
        mat=StaticGooseMatrix{Float64,3,3}(s,ones(3,3))
        @test measure_bytes(static_matrix_sum,mat) == 0
        reset!(s)
        @test_throws InvalidatedArrayError outer[1]
    end
    for operation in (reset!,close)
        s=DataStack(4096)
        a=StaticGooseVector{Float64,32}(s,ones(32))
        @test_throws InvalidatedArrayError invalidating_loop!(a,s,8,operation)
        close(s)
    end
    for operation in (reset!,close)
        s=DataStack(4096)
        a=StaticGooseVector{Float64,32}(s,ones(32))
        calls=Ref(0)
        invalidate(x)=(calls[]+=1;calls[]==8 && operation(s);x+1)
        @test_throws InvalidatedArrayError (a .= invalidate.(a))
        @test calls[]==8
        close(s)
    end
    with_datastack(4096) do s
        a=StaticGooseVector{Float64,3}(s,[1,2,3])
        @test_throws InvalidatedArrayError (a[1] = ResetOnConvert(s))
    end
end

@testset "static shapes intentionally specialize, values and arenas do not" begin
    with_datastack(1 << 20) do s
        for n in (2,3,4,8)
            a=StaticGooseArray{Float64}(s,undef,Val((n,)))
            fill!(a,1)
            @test static_shape_probe(a) == 2
        end
        instances() = Set(mi.specTypes for mi in Base.specializations(only(methods(static_shape_probe)))
            if mi isa Core.MethodInstance && isconcretetype(mi.specTypes))
        before=instances()
        @test length(before) == 4
        for _ in 1:50
            with_scope(s) do s
                a=StaticGooseVector{Float64,3}(s,undef)
                fill!(a,2)
                @test static_shape_probe(a) == 4
            end
        end
        @test instances() == before
    end
    @test isempty(Test.detect_ambiguities(GooseArrays,Base;recursive=false))
end
