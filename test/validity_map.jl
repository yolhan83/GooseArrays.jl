struct MapConversionEvent
    value::Float64
end
const map_conversion_events=Ref{Any}(nothing)
const map_conversion_action=Ref{Any}(nothing)
function Base.convert(::Type{Float64},x::MapConversionEvent)
    events=map_conversion_events[]
    events===nothing || push!(events,:convert)
    action=map_conversion_action[]
    action===nothing || action()
    x.value
end
@noinline public_map_probe!(dest,src)=map!(abs2,dest,src)
@noinline generic_map_reference!(f,dest,src)=invoke(map!,Tuple{Any,AbstractArray,AbstractArray},f,dest,src)

@testset "retired generations prove mapping invalidity, including explicit finalization" begin
    for static in (false,true), operation in (close,finalize)
        s=DataStack(4096)
        a=static ? StaticGooseVector{Float64,3}(s,[1,2,3]) : GooseArray(s,[1.0,2.0,3.0])
        alias=reshape(a,1,3)
        token=a.generation
        @test token!=0
        operation(s)
        @test !isopen(s)
        @test a.scope.generation==0
        @test a.generation==token
        @test_throws InvalidatedArrayError a[1]
        @test_throws InvalidatedArrayError (@inbounds alias[1])
        @test_throws InvalidatedArrayError (a[1]=4)
        @test_throws InvalidatedArrayError pointer(a)
        @test_throws InvalidatedArrayError fill!(a,1)
        @test_throws InvalidatedArrayError similar(a)
        @test_throws InvalidatedArrayError alloc!(s,Float64,1)
        @test size(a)==(3,)
        close(s)
    end
    for static in (false,true)
        s=DataStack(4096)
        make()=static ? StaticGooseVector{Float64,3}(s,[1,2,3]) : GooseArray(s,[1.0,2.0,3.0])
        root=make()
        descendants=Any[]
        with_scope(s) do _
            child=make();push!(descendants,child)
            with_scope(s) do _
                grandchild=make();push!(descendants,grandchild)
                finalize(s)
                for a in (root,child,grandchild)
                    @test a.scope.generation==0
                    @test_throws InvalidatedArrayError (@inbounds a[1])
                    @test_throws InvalidatedArrayError (a[1]=1)
                    @test_throws InvalidatedArrayError pointer(a)
                end
            end
            @test_throws InvalidatedArrayError child[1]
        end
        @test_throws InvalidatedArrayError root[1]
        @test_throws InvalidatedArrayError alloc!(s,Float64,3)
        close(s)
    end
    with_datastack(4096) do s
        a=GooseArray(s,[1.0,2.0,3.0])
        task_error=fetch(@async try a[1] catch e;e end)
        @test task_error isa ArgumentError
        @test a[1]==1
        reset!(s)
        @test_throws InvalidatedArrayError a[1]
        b=GooseArray(s,[4.0,5.0,6.0])
        @test b.generation != a.generation
        @test b.ptr == a.ptr
        @test_throws InvalidatedArrayError a[1]
        @test b == [4,5,6]
    end
end

@testset "public unary map! matches indexed Base semantics" begin
    for static in (false,true)
        with_datastack(1<<22) do s
            make(x)=static ? StaticGooseArray(s,x,Val(size(x))) : GooseArray(s,x)
            for (dshape,sshape) in (((3,),(3,)),((5,),(3,)),((2,),(5,)),
                                   ((2,3),(6,)),((6,),(3,2)),((),()),((0,),(3,)),
                                   ((3,),(0,)),((0,2),(0,3)))
                dv=fill(-1.0,dshape);sv=reshape(Float64.(1:prod(sshape)),sshape)
                dest=make(dv);src=make(sv)
                expected=copy(dv)
                map!(x->2x+1,expected,sv)
                @test map!(x->2x+1,dest,src)===dest
                @test Array(dest)==expected
                @test Array(src)==sv
                @test measure_bytes(public_map_probe!,dest,src)==0
            end
            a=make(Float64.(1:6))
            @test map!(abs2,a)===a
            @test a==[1,4,9,16,25,36]
            dest=static ? reshape(a,Val((2,3))) : reshape(a,2,3)
            @test map!(x->x+1,dest,a)===dest
            @test a==[2,5,10,17,26,37]
            ints=static ? StaticGooseVector{Int,3}(s,undef) : alloc!(s,Int,3)
            @test map!(Int,ints,make([1.0,2.0,3.0]))===ints
            @test ints==[1,2,3]
            fill!(ints,-1)
            @test_throws InexactError map!(identity,ints,make([1.0,2.5,3.0]))
            @test ints==[1,-1,-1]
        end
    end
    # For an empty iteration Base never accesses either operand, even closed.
    for static in (false,true), dlen in (0,3), slen in (0,3)
        min(dlen,slen)==0 || continue
        s=DataStack(4096)
        dest=static ? StaticGooseVector{Float64,dlen}(s,undef) : alloc!(s,Float64,dlen)
        src=static ? StaticGooseVector{Float64,slen}(s,undef) : alloc!(s,Float64,slen)
        close(s)
        calls=Ref(0);f(x)=(calls[]+=1;x)
        @test map!(f,dest,src)===dest
        @test calls[]==0
    end
    for implementation in (map!,generic_map_reference!), when in (:before,:callback,:conversion)
        for operation in (reset!,close,finalize)
            with_datastack(4096) do source_stack
                src=GooseArray(source_stack,[1.0,2.0,3.0])
                target_stack=DataStack(4096)
                dest=GooseArray(target_stack,[-1.0,-1.0,-1.0])
                events=Symbol[]
                map_conversion_events[]=events
                map_conversion_action[]=when==:conversion ? (() -> operation(target_stack)) : nothing
                when==:before && operation(target_stack)
                f(x)=(push!(events,:callback);when==:callback && operation(target_stack);MapConversionEvent(x))
                try
                    @test_throws InvalidatedArrayError implementation(f,dest,src)
                    @test events==(when==:conversion ? [:callback,:convert] : [:callback])
                finally
                    map_conversion_events[]=nothing;map_conversion_action[]=nothing
                    close(target_stack)
                end
            end
        end
    end
    for stop in (1,3), operation in (reset!,close,finalize)
        with_datastack(4096) do target_stack
            dest=GooseArray(target_stack,[-1.0,-1.0,-1.0])
            source_stack=DataStack(4096)
            src=GooseArray(source_stack,[1.0,2.0,3.0]);calls=Ref(0)
            f(x)=(calls[]+=1;calls[]==stop && operation(source_stack);2x)
            if stop==3
                @test map!(f,dest,src)===dest
                @test dest==[2,4,6]
            else
                @test_throws InvalidatedArrayError map!(f,dest,src)
                @test dest==[2,-1,-1]
            end
            @test calls[]==stop
            close(source_stack)
        end
    end
end

@testset "public map! has no length or arena specialization" begin
    with_datastack(1<<23) do s
        for n in (0,1,2,3,4,8,16,32,64,1000,10000,100000)
            a=alloc!(s,Float64,n);b=similar(a);fill!(a,2)
            @test public_map_probe!(b,a)===b
            @test all(==(4),b)
            @test measure_bytes(public_map_probe!,b,a)==0
        end
        for repeat in 1:20
            with_scope(s) do _
                a=GooseArray(s,[2.0,3.0]);b=similar(a)
                @test public_map_probe!(b,a)==[4,9]
            end
        end
    end
    instances=[mi for mi in Base.specializations(only(methods(public_map_probe!)))
        if mi isa Core.MethodInstance && mi.specTypes.parameters[2] === GooseVector{Float64} && mi.specTypes.parameters[3] === GooseVector{Float64}]
    @test length(instances)==1
end
