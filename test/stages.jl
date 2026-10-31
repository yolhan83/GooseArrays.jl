@testset "batched checks preserve independent tokens, scopes and owners" begin
    for static in (false,true)
        with_datastack(1<<20) do s
            make()=static ? StaticGooseVector{Float64,3}(s,[1,2,3]) : GooseArray(s,[1.0,2.0,3.0])
            old=make();reset!(s);a=make();b=make()
            @test_throws InvalidatedArrayError copyto!(a,old)
            @test_throws InvalidatedArrayError dot(a,old)
            @test_throws InvalidatedArrayError dot(old,a)
            @test a==[1,2,3]
            @test dot(a,b)==14
            @test copyto!(a,b)===a
            with_scope(s) do _
                child=make()
                @test dot(a,child)==14
                @test dot(child,a)==14
                @test copyto!(child,a)===child
                @test GooseArrays._checklive(a,child,b)===nothing
            end
            stale=with_scope(_->make(),s)
            @test_throws InvalidatedArrayError dot(a,stale)
            @test_throws InvalidatedArrayError dot(stale,a)
            with_scope(s) do _
                live=make()
                @test_throws InvalidatedArrayError dot(live,stale)
                @test_throws InvalidatedArrayError copyto!(live,stale)
                @test_throws InvalidatedArrayError GooseArrays._checklive(a,live,stale)
                @test live==[1,2,3]
            end
            with_datastack(4096) do other
                c=GooseArray(other,[1.0,2.0,3.0])
                @test dot(a,c)==14
                @test dot(c,a)==14
                @test GooseArrays._checklive(a,b,c)===nothing
                finalize(other)
                @test_throws InvalidatedArrayError dot(a,c)
                @test_throws InvalidatedArrayError copyto!(a,c)
            end
            foreign_array=fetch(@async GooseArray(DataStack(4096),[1.0,2.0,3.0]))
            try
                @test_throws ArgumentError dot(a,foreign_array)
                @test_throws ArgumentError copyto!(a,foreign_array)
                @test_throws ArgumentError GooseArrays._checklive(a,b,foreign_array)
            finally
                finalize(foreign_array.stack)
            end
            err=fetch(@async try dot(a,b);nothing catch e;e end)
            @test err isa ArgumentError
        end
    end
end

@noinline stage_matvec!(y,A,x,alpha,beta)=mul!(y,A,x,alpha,beta)
@noinline stage_axpy!(y,x,alpha)=axpy!(alpha,x,y)
@noinline stage_axpby!(y,x,alpha,beta)=axpby!(alpha,x,beta,y)

@testset "native real matrix-vector and scaled updates" begin
    rng=MersenneTwister(2048)
    for T in (Float32,Float64), static in (false,true)
        with_datastack(1<<25) do s
            make(v)=static ? StaticGooseArray(s,v,Val(size(v))) : GooseArray(s,v)
            for (m,k) in ((0,0),(0,3),(3,0),(1,1),(2,3),(3,2),(4,4),(8,8),(8,9),(9,8),(9,9),(16,16),(17,16),(16,17),(64,64))
                av=randn(rng,T,m,k);xv=randn(rng,T,k);yv=randn(rng,T,m)
                A=make(av);x=make(xv);y=make(yv)
                for (alpha,beta) in ((true,false),(T(0),T(0)),(T(0),T(1)),(T(0.25),T(-0.5)))
                    copyto!(y,yv);expected=copy(yv);mul!(expected,av,xv,alpha,beta)
                    @test stage_matvec!(y,A,x,alpha,beta)===y
                    bound=8eps(T)*(abs.(Float64.(av))*abs.(Float64.(xv))+abs.(Float64.(yv)))
                    @test all(isapprox.(Array(y),expected;rtol=16eps(T)*max(1,k),atol=maximum(bound;init=0.0)))
                    @test measure_bytes(stage_matvec!,y,A,x,alpha,beta)==0
                    if alpha===true && beta===false && (m,k) in ((3,2),(16,16),(17,16))
                        reference=BigFloat.(av)*BigFloat.(xv)
                        @test all(abs.(BigFloat.(Array(y))-reference) .<= BigFloat.(bound))
                    end
                end
            end
            for n in (0,1,2,3,16,64,2048,2049,10000)
                xv=randn(rng,T,n);yv=randn(rng,T,n);x=make(xv);y=make(yv)
                for (alpha,beta) in ((T(0),T(0)),(T(0),T(1)),(T(0.25),T(-0.5)),(true,false))
                    copyto!(y,yv);expected=copy(yv);axpy!(alpha,xv,expected)
                    @test stage_axpy!(y,x,alpha)===y
                    @test Array(y)≈expected
                    @test measure_bytes(stage_axpy!,y,x,alpha)==0
                    copyto!(y,yv);expected=copy(yv);axpby!(alpha,xv,beta,expected)
                    @test stage_axpby!(y,x,alpha,beta)===y
                    @test Array(y)≈expected
                    @test measure_bytes(stage_axpby!,y,x,alpha,beta)==0
                end
                if n>0
                    copyto!(x,xv);expected=copy(xv);axpy!(T(0.25),expected,expected)
                    @test axpy!(T(0.25),x,x)===x
                    @test Array(x)≈expected
                    copyto!(x,xv);expected=copy(xv);axpby!(T(0.25),expected,T(0.5),expected)
                    @test axpby!(T(0.25),x,T(0.5),x)===x
                    @test Array(x)≈expected
                end
            end
            # beta=0 must not read uninitialized/NaN destination elements.
            A=make(ones(T,3,3));x=make(fill(T(2),3));y=make(fill(T(NaN),3))
            @test mul!(y,A,x,true,false)==fill(T(6),3)
            fill!(A,T(NaN));fill!(x,T(NaN));fill!(y,T(NaN))
            @test mul!(y,A,x,false,false)==zeros(T,3)
            @test axpby!(false,x,false,y)==zeros(T,3)
            fill!(y,-zero(T))
            @test all(signbit,mul!(y,A,x,false,T(2)))
            fill!(y,-zero(T))
            @test all(signbit,axpby!(false,x,T(2),y))
            @test_throws DimensionMismatch mul!(make(zeros(T,2)),A,x)
            @test_throws DimensionMismatch mul!(y,A,make(zeros(T,2)))
            @test_throws DimensionMismatch axpy!(true,x,make(zeros(T,2)))
            @test_throws DimensionMismatch axpby!(true,x,false,make(zeros(T,2)))
            m=make(ones(T,2,3));v=make(ones(T,6))
            @test axpy!(T(0.5),m,v)==fill(T(1.5),6)
            stale=with_scope(_->make(ones(T,3)),s)
            @test_throws InvalidatedArrayError axpy!(true,stale,y)
            @test_throws InvalidatedArrayError axpby!(true,x,true,stale)
            @test_throws InvalidatedArrayError mul!(stale,A,x)
        end
    end
    # Other scalar/element types retain LinearAlgebra's generic paths.
    with_datastack(4096) do s
        A=GooseArray(s,ComplexF64[1 2;3 4]);x=GooseArray(s,ComplexF64[1,2]);y=similar(x)
        @test mul!(y,A,x)==[5,11]
        @test axpy!(2,x,y)==[7,15]
        @test axpby!(2,x,3,y)==[23,49]
        a=GooseArray(s,ones(2,2));v=GooseArray(s,ones(2));w=similar(v)
        @test mul!(w,a,v,2,0)==[4,4]
    end
    @test isempty(Test.detect_ambiguities(GooseArrays,Base,LinearAlgebra;recursive=false))
end

@testset "matrix-vector independent invalidation and empty semantics" begin
    with_datastack(4096) do s
        A=GooseArray(s,ones(3,3));x=GooseArray(s,ones(3));y=GooseArray(s,ones(3))
        for which in 1:3
            parts=Any[A,x,y]
            parts[which]=with_scope(s) do _
                GooseArray(s,which==1 ? ones(3,3) : ones(3))
            end
            @test_throws InvalidatedArrayError mul!(parts[3],parts[1],parts[2])
            @test y==ones(3)
        end
        foreign=fetch(@async GooseArray(DataStack(4096),ones(3)))
        try
            @test_throws ArgumentError mul!(y,A,foreign)
            @test_throws ArgumentError axpy!(true,foreign,y)
        finally
            finalize(foreign.stack)
        end
    end
    s=DataStack(4096)
    A=alloc!(s,Float64,0,3);x=alloc!(s,Float64,3);y=alloc!(s,Float64,0)
    close(s)
    @test mul!(y,A,x)===y # Base never accesses storage for zero output rows.
    s=DataStack(4096)
    A=alloc!(s,Float64,3,0);x=alloc!(s,Float64,0);close(s)
    with_datastack(4096) do target
        y=GooseArray(target,ones(3))
        @test mul!(y,A,x,true,false)==zeros(3)
    end
end
