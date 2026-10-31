"""
    StaticGooseArray{T}(stack, undef, Val((dims...)))
    StaticGooseVector{T,L}(stack, undef)
    StaticGooseMatrix{T,M,N}(stack, undef)
    StaticGooseArray(array::AbstractGooseArray, Val((dims...)))

Checked arena array whose shape is encoded in the type. Unlike `GooseArray`,
each shape intentionally specializes consuming code. Data remains in mmap
storage, with the same owner and scope checks; native-stack placement is not
implied. The final type parameter is a tuple *type*, e.g. `Tuple{2,3}`.

Constructors with a stack allocate data. Wrapping an existing arena array is
zero-copy and retains its original lifetime. New explicit runtime dimensions
in `similar`/`reshape` return GooseArray; use `Val` to request a static shape.
"""
struct StaticGooseArray{T,N,S<:Tuple} <: AbstractGooseArray{T,N}
    stack::DataStack
    ptr::Ptr{T}
    scope::_ScopeState
    generation::UInt64
    function StaticGooseArray{T,N,S}(::_Validated, stack, ptr, scope, generation) where {T,N,S<:Tuple}
        new{T,N,S}(stack, ptr, scope, generation)
    end
end

const StaticGooseVector{T,L} = StaticGooseArray{T,1,Tuple{L}}
const StaticGooseMatrix{T,M,N} = StaticGooseArray{T,2,Tuple{M,N}}

@generated function _static_dims(::Type{S}) where {S<:Tuple}
    dims = Tuple(S.parameters)
    if !all(d -> d isa Int && d >= 0, dims)
        return :(throw(ArgumentError("static dimensions must be nonnegative Int values")))
    end
    QuoteNode(dims)
end

@inline function _shape_type(::Val{D}) where {D}
    D isa Tuple || throw(ArgumentError("a static shape must be a tuple, e.g. Val((3,))"))
    all(d -> d isa Integer, D) || throw(ArgumentError("static dimensions must be integers"))
    dims = map(Int, D)
    _checkedlength(dims)
    Tuple{dims...}
end

@inline function StaticGooseArray{T,N,S}(s::DataStack, ::UndefInitializer) where {T,N,S<:Tuple}
    dims = _static_dims(S)
    length(dims) == N || throw(DimensionMismatch("static shape does not match array rank"))
    _checkopen(s)
    ptr,scope,generation = _bump_storage!(s,T,_checkedlength(dims))
    StaticGooseArray{T,N,S}(_validated,s,ptr,scope,generation)
end

@inline function StaticGooseArray{T}(s::DataStack, u::UndefInitializer, shape::Val) where {T}
    S = _shape_type(shape)
    StaticGooseArray{T,length(_static_dims(S)),S}(s, u)
end

function StaticGooseArray{T,N,S}(s::DataStack, src::AbstractArray) where {T,N,S<:Tuple}
    Base.require_one_based_indexing(src)
    size(src) == _static_dims(S) || throw(DimensionMismatch("source does not match static shape"))
    a = StaticGooseArray{T,N,S}(s, undef)
    copyto!(a, src)
end

function StaticGooseArray{T}(s::DataStack, src::AbstractArray, shape::Val) where {T}
    S = _shape_type(shape)
    StaticGooseArray{T,length(_static_dims(S)),S}(s, src)
end
StaticGooseArray(s::DataStack, src::AbstractArray{T}, shape::Val) where {T} =
    StaticGooseArray{T}(s, src, shape)

function StaticGooseArray{T,N,S}(a::AbstractGooseArray{T}) where {T,N,S<:Tuple}
    _checklive(a)
    dims = _static_dims(S)
    length(dims) == N || throw(DimensionMismatch("static shape does not match array rank"))
    size(a) == dims || throw(DimensionMismatch("array does not match static shape"))
    StaticGooseArray{T,N,S}(_validated, a.stack, a.ptr, a.scope, a.generation)
end
function StaticGooseArray(a::AbstractGooseArray{T}, shape::Val) where {T}
    S = _shape_type(shape)
    StaticGooseArray{T,length(_static_dims(S)),S}(a)
end

"""Erase a StaticGooseArray's shape parameters without copying its data or changing its lifetime."""
function GooseArray(a::StaticGooseArray{T,N}) where {T,N}
    _checklive(a)
    GooseArray{T,N}(_validated, a.stack, a.ptr, size(a), length(a), a.scope, a.generation)
end

Base.size(::StaticGooseArray{T,N,S}) where {T,N,S} = _static_dims(S)
Base.length(a::StaticGooseArray) = prod(size(a))

@inline function Base.similar(a::StaticGooseArray{T,N,S}, ::Type{U}) where {T,N,S,U}
    _checklive(a)
    ptr,scope,generation = _bump_storage!(a.stack,U,length(a))
    StaticGooseArray{U,N,S}(_validated,a.stack,ptr,scope,generation)
end
function Base.similar(a::AbstractGooseArray, ::Type{T}, shape::Val) where {T}
    _checklive(a)
    StaticGooseArray{T}(a.stack, undef, shape)
end
Base.similar(a::AbstractGooseArray, shape::Val) = similar(a, eltype(a), shape)

Base.reshape(a::AbstractGooseArray{T,N}, ::Val{N}) where {T,N} = a

function Base.reshape(a::AbstractGooseArray{T}, shape::Val{D}) where {T,D}
    # Base uses Val(integer_rank) internally when constructing views.
    # Our public static-shape form uses Val(tuple_of_dimensions).
    D isa Integer && return invoke(reshape, Tuple{AbstractArray,Val{D}}, a, shape)
    _checklive(a)
    S = _shape_type(shape)
    dims = _static_dims(S)
    _checkedlength(dims) == length(a) || throw(DimensionMismatch("reshape must preserve length"))
    StaticGooseArray{T,length(dims),S}(_validated, a.stack, a.ptr, a.scope, a.generation)
end
