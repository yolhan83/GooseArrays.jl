using GooseArrays

@noinline function work!(stack, n)
    with_scope(stack) do s
        a = alloc!(s, Float64, n)
        fill!(a, 2.0)
        sum(a)
    end
end

function check_allocations()
    stack = DataStack(16 * 1024 * 1024)
    try
        for n in (100, 1000, 10000, 100000)
            work!(stack, n) # compile first
            bytes = @allocated work!(stack, n)
            @assert bytes == 0
            println("n=", n, ", GC bytes=", bytes)
        end
    finally
        close(stack)
    end
end

check_allocations()
