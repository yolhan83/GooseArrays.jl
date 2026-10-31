module GooseArraysLinearAlgebraExt

using GooseArrays, LinearAlgebra

_matprod(x,y) = x*y + x*y

const ArenaReal = Union{Float32,Float64}

# Small dense matrix/vector products avoid a foreign-call setup. Empty shapes
# keep Base's scaling and no-access conventions. As with Base.mul!, y must not
# alias x or A. Only built-in real coefficients enter this callback-free path.
@inline function LinearAlgebra.mul!(y::AbstractGooseArray{T,1},
        A::AbstractGooseArray{T,2}, x::AbstractGooseArray{T,1},
        alpha::Union{Bool,T}, beta::Union{Bool,T}) where {T<:ArenaReal}
    m,k = size(A)
    length(x)==k && length(y)==m || throw(DimensionMismatch("matrix/vector dimensions must match"))
    if m==0 || k==0
        return invoke(mul!,Tuple{AbstractVector,AbstractMatrix,AbstractVector,Number,Number},y,A,x,alpha,beta)
    end
    GooseArrays._checklive(A,x,y)
    GC.@preserve A x y begin
        # Constant static dimensions allow bounded loop expansion up to 16.
        # Runtime row-dot loops use the shorter cutoff; BLAS wins beyond it.
        if (m<=8 && k<=8) || (A isa StaticGooseArray && m<=16 && k<=16)
            for i in 1:m
                if iszero(alpha)
                    acc=iszero(beta) ? zero(T) : beta*unsafe_load(y.ptr,i)
                else
                    acc=zero(T)
                    for j in 1:k
                        acc += unsafe_load(A.ptr,i+(j-1)*m)*unsafe_load(x.ptr,j)
                    end
                    acc *= alpha
                    if !iszero(beta)
                        acc += beta*unsafe_load(y.ptr,i)
                    end
                end
                GooseArrays._store_payload!(y.ptr,acc,i)
            end
            return y
        end
        return BLAS.gemv!('N',alpha,A,x,beta,y)
    end
end

@inline function LinearAlgebra.axpy!(alpha::Union{Bool,T},
        x::AbstractGooseArray{T}, y::AbstractGooseArray{T}) where {T<:ArenaReal}
    n=length(x)
    n==length(y) || throw(DimensionMismatch("axpy! lengths must match"))
    GooseArrays._checklive(x,y)
    GC.@preserve x y begin
        if n<=2048
            if !iszero(alpha)
                @simd for i in 1:n
                    value=alpha*unsafe_load(x.ptr,i)+unsafe_load(y.ptr,i)
                    GooseArrays._store_payload!(y.ptr,value,i)
                end
            end
            return y
        end
        BLAS.axpy!(n,T(alpha),x.ptr,1,y.ptr,1)
    end
    y
end

@inline function LinearAlgebra.axpby!(alpha::Union{Bool,T},
        x::AbstractGooseArray{T}, beta::Union{Bool,T},
        y::AbstractGooseArray{T}) where {T<:ArenaReal}
    n=length(x)
    n==length(y) || throw(DimensionMismatch("axpby! lengths must match"))
    GooseArrays._checklive(x,y)
    GC.@preserve x y begin
        if n<=2048
            if !(iszero(alpha) && isone(beta))
                @simd for i in 1:n
                    if iszero(alpha)
                        value=iszero(beta) ? zero(T) : beta*unsafe_load(y.ptr,i)
                    else
                        value=alpha*unsafe_load(x.ptr,i)
                        if !iszero(beta)
                            value += beta*unsafe_load(y.ptr,i)
                        end
                    end
                    GooseArrays._store_payload!(y.ptr,value,i)
                end
            end
            return y
        end
        BLAS.axpby!(n,T(alpha),x.ptr,1,T(beta),y.ptr,1)
    end
    y
end

# Native real arithmetic cannot call back into user code or invalidate the
# arena. Validate all owners/lifetimes once, preserve them, and use only indices
# implied by the dimensions. Large matrices retain LinearAlgebra's algorithms.
@inline function LinearAlgebra.mul!(C::AbstractGooseArray{T,2},
        A::AbstractGooseArray{T,2}, B::AbstractGooseArray{T,2},
        alpha::Union{Bool,T}, beta::Union{Bool,T}) where {T<:ArenaReal}
    m,k = size(A)
    k2,n = size(B)
    if 0 < m <= 4 && 0 < k <= 4 && 0 < n <= 4
        GooseArrays._checklive(A)
        GooseArrays._checklive(B)
        GooseArrays._checklive(C)
        k == k2 && size(C) == (m,n) || throw(DimensionMismatch("matrix dimensions must match"))
        GC.@preserve A B C begin
            for j in 1:n, i in 1:m
                acc = zero(T)
                if !iszero(alpha)
                    for p in 1:k
                        acc += unsafe_load(A.ptr,i+(p-1)*m) * unsafe_load(B.ptr,p+(j-1)*k)
                    end
                    acc *= alpha
                end
                if !iszero(beta)
                    acc += beta * unsafe_load(C.ptr,i+(j-1)*m)
                end
                GooseArrays._store_payload!(C.ptr,acc,i+(j-1)*m)
            end
        end
        return C
    end
    GooseArrays._checklive(A)
    GooseArrays._checklive(B)
    GooseArrays._checklive(C)
    BLAS.gemm!('N','N',alpha,A,B,beta,C)
end

@inline function LinearAlgebra.dot(x::AbstractGooseArray{T}, y::AbstractGooseArray{T}) where {T<:ArenaReal}
    GooseArrays._checklive(x,y)
    n = length(x)
    n == length(y) || throw(DimensionMismatch("dot product lengths must match"))
    GC.@preserve x y begin
        if n <= 2048
            acc = zero(T)
            @simd for i in 1:n
                acc += unsafe_load(x.ptr,i) * unsafe_load(y.ptr,i)
            end
            return acc
        end
        return BLAS.dot(n,x.ptr,1,y.ptr,1)
    end
end

@inline function Base.:*(A::GooseArray{T,2}, B::GooseArray{T,2}) where {T<:ArenaReal}
    GooseArrays._checklive(A,B)
    size(A,2)==size(B,1) || throw(DimensionMismatch("matrix dimensions must match"))
    C=similar(B,T,(size(A,1),size(B,2)))
    mul!(C,A,B)
end

# Exactly static operands determine the output shape. mul! selects the native
# small-real kernel above or LinearAlgebra's BLAS/generic implementations.
@inline function Base.:*(A::StaticGooseArray{T,2}, B::StaticGooseArray{U,2}) where {T,U}
    GooseArrays._checklive(A,B)
    size(A,2)==size(B,1) || throw(DimensionMismatch("matrix dimensions must match"))
    R=Base.promote_op(_matprod,T,U)
    C=StaticGooseArray{R}(B.stack,undef,Val((size(A,1),size(B,2))))
    mul!(C,A,B)
end

@inline function Base.:*(A::StaticGooseArray{T,2}, b::StaticGooseArray{U,1}) where {T,U}
    GooseArrays._checklive(A,b)
    size(A,2)==length(b) || throw(DimensionMismatch("matrix/vector dimensions must match"))
    R=Base.promote_op(_matprod,T,U)
    c=StaticGooseArray{R}(b.stack,undef,Val((size(A,1),)))
    mul!(c,A,b)
end

end
