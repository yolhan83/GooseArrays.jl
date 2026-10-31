using GooseArrays, LinearAlgebra

function static_example()
    with_datastack(1 << 20) do s
        # Runtime shape, never resized; same type for every length.
        a=GooseVector{Float64}(s,undef,3)
        fill!(a,2.0)
        # Explicit static length. This intentionally specializes by length.
        b=StaticGooseVector{Float64,3}(s,undef)
        b .= 2 .* a .+ 1
        c=map(abs2,b)
        @assert c isa StaticGooseVector{Float64,3}
        @assert sum(c)==75
        A=StaticGooseMatrix{Float64,2,2}(s,[1.0 2.0;3.0 4.0])
        C=A*A
        @assert C isa StaticGooseMatrix{Float64,2,2}
        @assert C==[7.0 10.0;15.0 22.0]
        # Shape-only views share both data and lifetime.
        view_static=StaticGooseArray(a,Val((3,)))
        view_dynamic=GooseArray(view_static)
        @assert pointer(view_dynamic)==pointer(a)
        # Copy owned by Julia before the arena is closed.
        Array(C)
    end
end

println(static_example())
