@noinline opaque_float(x) = Base.inferencebarrier(Float64(x) + 0.5)
@noinline optimized_map_probe(a) = with_scope(_ -> sum(map(abs2,a)),a.stack)
@noinline optimized_broadcast_probe(a) = with_scope(_ -> sum(abs2.(a)),a.stack)
@noinline optimized_dot_probe(a,b) = dot(a,b)
@noinline optimized_mul_probe(C,A,B) = mul!(C,A,B)
@noinline optimized_product_probe(A,B) = with_scope(_ -> sum(A*B),A.stack)

struct CallbackBits
    value::Float64
end
const conversion_stack = Ref{Any}(nothing)
const conversion_operation = Ref{Any}(nothing)
function Base.convert(::Type{CallbackBits}, x::CallbackBits)
    s = conversion_stack[]
    s === nothing || conversion_operation[](s)
    x
end

@testset "indexed map and broadcast preserve values, shapes and callback safety" begin
    for static in (false,true)
        with_datastack(1<<20) do s
            make(x) = static ? StaticGooseArray(s,x,Val(size(x))) : GooseArray(s,x)
            for shape in ((),(0,),(2,),(3,),(17,),(2,3),(0,3))
                values = reshape(Float64.(1:prod(shape)),shape)
                a = make(values)
                b = map(x -> Float32(2x+1),a)
                @test size(b) == shape
                @test eltype(b) == Float32
                @test Array(b) == map(x -> Float32(2x+1),values)
                @test (b isa StaticGooseArray) == static
                @test pointer(a) != pointer(b) || isempty(a)
                if !isempty(a)
                    c = map(opaque_float,a)
                    @test Array(c) == map(x -> x+0.5,values)
                    @test (c isa StaticGooseArray) == static
                end
                bc = Float32.(a)
                @test bc == Float32.(values)
                if !isempty(shape)
                    @test size(bc) == shape
                    @test (bc isa StaticGooseArray) == static
                end
            end
            a = make([1.0,2.0,3.0])
            calls = Int[]
            f(x) = (push!(calls,Int(x)); x+1)
            @test map(f,a) == [2,3,4]
            @test calls == [1,2,3]
            empty!(calls)
            @test f.(a) == [2,3,4]
            @test calls == [1,2,3]
            nested(x) = with_scope(s) do child
                scratch=alloc!(child,Float64,2)
                fill!(scratch,x)
                sum(scratch)
            end
            @test map(nested,a) == [2,4,6]
            @test nested.(a) == [2,4,6]
            @test 2 .* a .+ 1 == [3,5,7]
            @test nested.(a) .+ 1 == [3,5,7]
            GC.@preserve a begin
                wrapped=unsafe_wrap(Array,pointer(a),size(a);own=false)
                @test a .+ wrapped .+ 1 == [3,5,7]
                @test a == [1,2,3]
            end
            style=GooseArrays.StaticGooseArrayStyle{Tuple{1},1}()
            malformed=Base.Broadcast.Broadcasted(style,identity,(a,),axes(a))
            @test_throws DimensionMismatch copy(malformed)
            @test a == [1,2,3]
            used=bytesused(s)
            @test_throws ErrorException with_scope(s) do _
                map(x -> (x==2 && error("callback failure");x),a)
            end
            @test bytesused(s) == used
            @test a == [1,2,3]
            @test measure_bytes(optimized_map_probe,a) == 0
            @test measure_bytes(optimized_broadcast_probe,a) == 0
        end
        for operation in (reset!,close), stop in (1,3), mode in (:map,:broadcast,:expression)
            s=DataStack(4096)
            a=static ? StaticGooseVector{Float64,3}(s,[1,2,3]) : GooseArray(s,[1.0,2.0,3.0])
            calls=Ref(0)
            f(x)=(calls[]+=1;calls[]==stop && operation(s);x+1)
            @test_throws InvalidatedArrayError (mode==:map ? map(f,a) : mode==:broadcast ? f.(a) : f.(a) .+ 1)
            @test calls[] == stop
            close(s)
        end
        for operation in (reset!,close), mode in (:map,:broadcast)
            s=DataStack(4096)
            a=static ? StaticGooseVector{Float64,3}(s,[1,2,3]) : GooseArray(s,[1.0,2.0,3.0])
            conversion_stack[]=s
            conversion_operation[]=operation
            try
                @test_throws InvalidatedArrayError (mode==:map ? map(CallbackBits,a) : CallbackBits.(a))
            finally
                conversion_stack[]=nothing
                conversion_operation[]=nothing
                close(s)
            end
        end
    end
end

@testset "real small matrix products and dot preserve numeric and lifetime behavior" begin
    rng=MersenneTwister(739)
    for T in (Float32,Float64), static in (false,true)
        with_datastack(1<<24) do s
            make(x) = static ? StaticGooseArray(s,x,Val(size(x))) : GooseArray(s,x)
            for (m,k,n) in ((1,1,1),(2,2,2),(3,3,3),(4,4,4),(2,4,3),(4,2,1),
                            (0,2,3),(2,0,3),(2,3,0),(5,3,2),(8,8,8),(16,16,16))
                av=randn(rng,T,m,k);bv=randn(rng,T,k,n);cv=randn(rng,T,m,n)
                A=make(av);B=make(bv);C=make(cv)
                @test mul!(C,A,B) === C
                @test Array(C) ≈ av*bv
                D=A*B
                @test Array(D) ≈ av*bv
                @test (D isa StaticGooseArray) == static
                for (alpha,beta) in ((true,false),(false,false),(false,true),
                                     (T(2),T(-0.5)),(T(0),T(2)))
                    copyto!(C,cv)
                    @test mul!(C,A,B,alpha,beta) === C
                    @test Array(C) ≈ alpha*(av*bv)+beta*cv
                end
                fill!(C,T(NaN))
                mul!(C,A,B,true,false)
                @test Array(C) ≈ av*bv
                if !isempty(A) && !isempty(B)
                    fill!(A,T(NaN));fill!(B,T(NaN));fill!(C,T(NaN))
                    mul!(C,A,B,false,false)
                    @test all(iszero,C)
                    # The zero-alpha path must not read NaNs from A or B,
                    # including for sizes handled by the BLAS fallback.
                    fill!(C,T(3))
                    @test mul!(C,A,B,false,true) === C
                    @test all(==(T(3)),C)
                    @test mul!(C,A,B,false,T(2)) === C
                    @test all(==(T(6)),C)
                end
            end
            for n in (0,1,2,3,16,1000,2048,2049,10000)
                xv=randn(rng,T,n);yv=randn(rng,T,n)
                x=make(xv);y=make(yv)
                # Different SIMD/BLAS reduction orders can differ relatively
                # near cancellation. Use a scale-aware absolute tolerance and
                # also check against a high-precision mathematical reference.
                bound=4eps(T)*sum(abs,Float64.(xv).*Float64.(yv))
                @test isapprox(dot(x,y),dot(xv,yv);rtol=sqrt(eps(T)),atol=bound)
                reference=sum(BigFloat.(xv).*BigFloat.(yv))
                @test abs(BigFloat(dot(x,y))-reference) <= bound
                @test dot(x,x) ≈ dot(xv,xv)
                @test dot(x,y) isa T
                @test measure_bytes(optimized_dot_probe,x,y) == 0
            end
            A=make(ones(T,3,3));B=make(ones(T,3,3));C=similar(A)
            @test measure_bytes(optimized_mul_probe,C,A,B) == 0
            @test measure_bytes(optimized_product_probe,A,B) == 0
            bad=make(ones(T,2,3))
            @test_throws DimensionMismatch mul!(C,A,bad)
            @test_throws DimensionMismatch mul!(bad,A,B)
            @test_throws DimensionMismatch dot(vec(A),make(ones(T,2)))
            reset!(s)
            @test_throws InvalidatedArrayError mul!(C,A,B)
            @test_throws InvalidatedArrayError dot(vec(A),vec(B))
        end
        for operation in (reset!,close)
            s=DataStack(4096)
            A=static ? StaticGooseMatrix{T,2,2}(s,ones(T,2,2)) : GooseArray(s,ones(T,2,2))
            C=similar(A)
            operation(s)
            @test_throws InvalidatedArrayError mul!(C,A,A)
            @test_throws InvalidatedArrayError A*A
            @test_throws InvalidatedArrayError dot(vec(A),vec(A))
            close(s)
        end
    end
    ext=Base.get_extension(GooseArrays,:GooseArraysLinearAlgebraExt)
    ambiguities=Test.detect_ambiguities(GooseArrays,Base,LinearAlgebra,ext;recursive=false)
    ours=filter(pair->any(m->m.module in (GooseArrays,ext),pair),ambiguities)
    @test isempty(ours)
end

@testset "optimized dynamic maps do not specialize by length" begin
    with_datastack(1<<22) do s
        for n in (2,3,4,8,16,32,64,1000,10000)
            a=alloc!(s,Float64,n)
            fill!(a,2)
            @test optimized_map_probe(a) == 4n
            @test optimized_broadcast_probe(a) == 4n
            @test measure_bytes(optimized_map_probe,a) == 0
            @test measure_bytes(optimized_broadcast_probe,a) == 0
        end
    end
    for f in (optimized_map_probe,optimized_broadcast_probe)
        instances=[mi for mi in Base.specializations(only(methods(f))) if mi isa Core.MethodInstance &&
            mi.specTypes.parameters[2] <: GooseArray]
        @test length(instances) == 1
    end
end
