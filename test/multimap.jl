@inline stage_binary(x,y)=x*y
@inline stage_ternary(x,y,z)=x+y*z
@noinline stage_multi_map2!(d,a,b)=map!(stage_binary,d,a,b)
@noinline stage_multi_map3!(d,a,b,c)=map!(stage_ternary,d,a,b,c)
@noinline stage_multi_map2sum(a,b)=sum(map(stage_binary,a,b))
@noinline stage_multi_map3sum(a,b,c)=sum(map(stage_ternary,a,b,c))
@noinline stage_multi_reduce2(a,b)=mapreduce(stage_binary,+,a,b)
@noinline stage_multi_reduce3(a,b,c)=mapreduce(stage_ternary,+,a,b,c)
@noinline stage_unknown(x,y)=x>1 ? y : missing
struct StageScale
    value::Float64
end
(s::StageScale)(x,y)=s.value*x+y
@noinline stage_scaled_reduce(f,a,b)=mapreduce(f,+,a,b)

@testset "multi-input map shapes, promotion, aliases and fallback" begin
    shapes=(((0,),(3,)),((3,),(0,)),((3,),(5,)),((5,),(3,)),((2,3),(2,3)),
        ((2,3),(6,)),((6,),(2,3)),((),()),((),(3,)),((0,2),(0,2)))
    for static in (false,true), T in (Float32,Float64,Int32,ComplexF64)
        with_datastack(1<<24) do s
            make(v)=static ? StaticGooseArray(s,v,Val(size(v))) : GooseArray(s,v)
            for (ashape,bshape) in shapes
                av=reshape(T.(1:prod(ashape)),ashape);bv=reshape(T.(2:prod(bshape)+1),bshape)
                a=make(av);b=make(bv);expected=map(stage_binary,av,bv)
                result=map(stage_binary,a,b)
                @test Array(result)==expected
                @test size(result)==size(expected)
                @test static ? result isa StaticGooseArray : result isa GooseArray
                @test mapreduce(stage_binary,+,a,b)==mapreduce(stage_binary,+,av,bv)
                @test mapreduce(stage_binary,+,a,b;init=T(3))==mapreduce(stage_binary,+,av,bv;init=T(3))
                dest=make(fill(T(-1),max(length(a),length(b))+1));dv=Array(dest)
                map!(stage_binary,dv,av,bv)
                @test map!(stage_binary,dest,a,b)===dest
                @test Array(dest)==dv
            end
            a=make(reshape(T.(1:6),2,3));b=make(ones(T,2,3))
            for dim in (1,2)
                @test Array(mapreduce(stage_binary,+,a,b;dims=dim,init=T(2)))==mapreduce(stage_binary,+,Array(a),Array(b);dims=dim,init=T(2))
            end
            before=bytesused(s)
            wrong=make(ones(T,3,2));before=bytesused(s)
            @test_throws DimensionMismatch map(stage_binary,a,wrong)
            @test bytesused(s)==before
            @test_throws DimensionMismatch mapreduce(stage_binary,+,a,wrong)
            @test bytesused(s)==before
            @test mapreduce(stage_binary,*,a,b)==mapreduce(stage_binary,*,Array(a),Array(b))
            av=T.(1:6);bv=T.(2:7);a=make(av);b=make(bv)
            map!(+,av,av,bv);map!(+,a,a,b)
            @test Array(a)==av
            map!(stage_ternary,bv,av,bv,bv);map!(stage_ternary,b,a,b,b)
            @test Array(b)==bv
            for arity in 2:5
                inputs=ntuple(i->make(fill(T(i),4)),arity)
                f=(xs...)->sum(xs)
                @test all(==(sum(1:arity)),map(f,inputs...))
                @test mapreduce(f,+,inputs...)==4sum(1:arity)
            end
        end
    end
    with_datastack(1<<20) do s
        a=GooseArray(s,[1.0,2.0,3.0]);b=GooseArray(s,[2.0,3.0,4.0])
        sa=StaticGooseArray(a,Val((3,)));sb=StaticGooseArray(b,Val((3,)))
        @test map(stage_binary,sa,b) isa GooseVector
        @test map(stage_binary,a,sb) isa GooseVector
        @test map(stage_binary,sa,sb) isa StaticGooseVector{Float64,3}
        result=map(stage_unknown,a,b)
        @test result isa Array
        @test isequal(result,map(stage_unknown,Array(a),Array(b)))
        @test mapreduce(stage_binary,+,a,b;init=BigFloat(3))==BigFloat(23)
        @test map(stage_binary,a,Array(b))==[2,6,12]
        dest=GooseArray(s,fill(-1,3));bad=GooseArray(s,[1.0,2.5,3.0]);one=GooseArray(s,ones(3))
        @test_throws InexactError map!(stage_binary,dest,bad,one)
        @test dest==[1,-1,-1]
        for n in (0,1,3)
            a=GooseArray(s,trues(n));b=GooseArray(s,trues(n))
            @test mapreduce(&,+,a,b)==mapreduce(&,+,trues(n),trues(n))
        end
    end
end

@testset "multi callbacks, invalidation and eager custom operators" begin
    for arity in (2,3), when in (:before,:callback,:conversion), operation in (reset!,close,finalize)
        with_datastack(4096) do source
            args=ntuple(_->GooseArray(source,ones(3)),arity)
            target=DataStack(4096);dest=GooseArray(target,fill(-1.0,3));events=Symbol[]
            map_conversion_events[]=events
            map_conversion_action[]=when==:conversion ? (() -> operation(target)) : nothing
            when==:before && operation(target)
            f=(xs...)->(push!(events,:callback);when==:callback && operation(target);MapConversionEvent(sum(xs)))
            try
                @test_throws InvalidatedArrayError map!(f,dest,args...)
                @test events==(when==:conversion ? [:callback,:convert] : [:callback])
            finally
                map_conversion_events[]=nothing;map_conversion_action[]=nothing;close(target)
            end
        end
    end
    for operation in (reset!,close,finalize), stop in (1,3), reduction in (false,true)
        with_datastack(4096) do source
            other=DataStack(4096);a=GooseArray(source,ones(3));b=GooseArray(other,fill(2.0,3));calls=Ref(0)
            f=(x,y)->(calls[]+=1;calls[]==stop && operation(other);x*y)
            try
                if reduction
                    if stop==1
                        @test_throws InvalidatedArrayError mapreduce(f,+,a,b)
                    else
                        @test mapreduce(f,+,a,b)==6
                    end
                else
                    dest=GooseArray(source,fill(-1.0,3))
                    if stop==1
                        @test_throws InvalidatedArrayError map!(f,dest,a,b)
                        @test dest==[2,-1,-1]
                    else
                        @test map!(f,dest,a,b)==[2,2,2]
                    end
                end
                @test calls[]==stop
            finally
                close(other)
            end
        end
    end
    with_datastack(4096) do s
        a=GooseArray(s,[1.0,2.0,3.0,4.0]);b=GooseArray(s,ones(4));events=Symbol[]
        f=(x,y)->(push!(events,:map);x*y)
        op=(x,y)->(push!(events,:reduce);x+y)
        expected=mapreduce(f,op,Array(a),Array(b));order=copy(events);empty!(events)
        @test mapreduce(f,op,a,b)==expected
        @test events==order
        empty=alloc!(s,Float64,0);dest=alloc!(s,Float64,3);close(s);calls=Ref(0)
        @test map!((x,y)->(calls[]+=1;x+y),dest,empty,empty)===dest
        @test calls[]==0
    end
end

@testset "multi-input numeric kernels allocate no GC and preserve runtime specialization" begin
    for static in (false,true)
        with_datastack(1<<26) do s
            for n in (0,1,2,3,4,8,16,32,64,1000,10000,100000)
                with_scope(s) do _
                    make()=static ? StaticGooseVector{Float64,n}(s,undef) : alloc!(s,Float64,n)
                    a,b,c,d=make(),make(),make(),make();fill!(a,2);fill!(b,2);fill!(c,2)
                    @test stage_multi_map2!(d,a,b)===d
                    @test all(==(4),d)
                    @test stage_multi_map3!(d,a,b,c)===d
                    @test all(==(6),d)
                    @test stage_multi_map2sum(a,b)==4n
                    @test stage_multi_map3sum(a,b,c)==6n
                    before=bytesused(s)
                    @test stage_multi_reduce2(a,b)==4n
                    @test stage_multi_reduce3(a,b,c)==6n
                    @test bytesused(s)==before
                    @test measure_bytes(stage_multi_map2!,d,a,b)==0
                    @test measure_bytes(stage_multi_map3!,d,a,b,c)==0
                    @test measure_bytes(stage_multi_map2sum,a,b)==0
                    @test measure_bytes(stage_multi_map3sum,a,b,c)==0
                    @test measure_bytes(stage_multi_reduce2,a,b)==0
                    @test measure_bytes(stage_multi_reduce3,a,b,c)==0
                end
            end
        end
    end
    for repeat in 1:20
        with_datastack(4096) do s
            a=GooseArray(s,ones(3));b=GooseArray(s,ones(3));scale=StageScale(Float64(repeat))
            @test stage_scaled_reduce(scale,a,b)==3(repeat+1)
            @test measure_bytes(stage_scaled_reduce,scale,a,b)==0
        end
    end
    for probe in (stage_multi_map2!,stage_multi_reduce2,stage_multi_reduce3)
        m=only(methods(probe))
        instances=[mi for mi in Base.specializations(m) if mi isa Core.MethodInstance && all(t->t===GooseVector{Float64},mi.specTypes.parameters[2:end])]
        @test length(instances)==1
    end
    # Julia also caches a generic forwarding entry with Any array arguments.
    # Count the concrete kernel, as in the length-specialization checks above.
    instances=[mi for mi in Base.specializations(only(methods(stage_scaled_reduce))) if mi isa Core.MethodInstance && mi.specTypes.parameters[2]===StageScale && all(t->t===GooseVector{Float64},mi.specTypes.parameters[3:end])]
    @test length(instances)==1
    @test isempty(Test.detect_ambiguities(GooseArrays,Base,LinearAlgebra;recursive=false))
end
