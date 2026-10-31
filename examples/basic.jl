using GooseArrays, LinearAlgebra

function example()
    stack = DataStack(16 * 1024 * 1024)
    try
        for n in (100, 1000, 10000)
            result = with_scope(stack) do s
                a = alloc!(s, Float64, n)
                b = similar(a)
                fill!(a, 2.0)
                b .= 3 .* a .+ 1
                sum(b)
            end
            @assert result == 7n
            @assert bytesused(stack) == 0
            println("n=", n, ", result=", result)
        end
        saved = with_scope(stack) do s
            a = GooseMatrix(s, [1.0 2.0; 3.0 4.0])
            Array(a * a) # Copy into GC-owned memory before leaving the scope.
        end
        @assert saved == [7.0 10.0; 15.0 22.0]
        saved
    finally
        close(stack)
    end
end

example()
