# Function barriers keep measurements independent of global-variable boxing.
@noinline function construction_kernel(stack, n)
    with_scope(stack) do s
        a = alloc!(s, Float64, n)
        length(a)
    end
end

@noinline function compute_kernel!(a, b)
    @inbounds for i in eachindex(a, b)
        a[i] = 2 * b[i] + 1
    end
    sum(a)
end

@noinline function broadcast_kernel!(a, b)
    a .= 2 .* b .+ 1
    sum(a)
end

@noinline function scoped_kernel(stack, n)
    with_scope(stack) do s
        a = alloc!(s, Float64, n)
        fill!(a, 2.0)
        sum(a)
    end
end

@noinline shape_probe(a) = isempty(a) ? zero(eltype(a)) : (@inbounds a[1] + a[end])

@noinline function copy_kernel!(a, b)
    copyto!(a, b)
    sum(a)
end

@noinline function derived_kernel(stack, n)
    with_scope(stack) do s
        a = alloc!(s, Float64, n)
        fill!(a, 2.0)
        b = copy(a)
        c = b .+ 1.0
        m = reshape(c, 1, n)
        sum(view(m, 1, :))
    end
end

# Force specialization on the callee and vararg arity. Julia (notably 1.10)
# may otherwise allocate a small varargs/dispatch wrapper in the measuring
# function, even when the measured kernel itself is allocation-free.
@noinline function measure_bytes(f::F, args::Vararg{Any,N}) where {F,N}
    f(args...)
    @allocated f(args...)
end
