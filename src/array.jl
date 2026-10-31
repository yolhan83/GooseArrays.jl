"""
    GooseArray{T}(stack, undef, dims...)
    GooseArray(stack, source::AbstractArray)

Contiguous column-major fixed-size array backed by `stack`. `T` must be a
positive-size isbits type. Only element type `T` and rank `N` are type parameters;
dimension lengths and scope generations are runtime values. The immutable
descriptor retains its arena for GC safety and checks scope validity on access.
It is deliberately not an isbits type. Escaping/boxing a descriptor can allocate.
"""
struct GooseArray{T,N} <: AbstractGooseArray{T,N}
    stack::DataStack
    ptr::Ptr{T}
    dims::NTuple{N,Int}
    len::Int
    scope::_ScopeState
    generation::UInt64
    function GooseArray{T,N}(::_Validated, stack, ptr, dims, len, scope, generation) where {T,N}
        new{T,N}(stack, ptr, dims, len, scope, generation)
    end
end

const GooseVector{T} = GooseArray{T,1}
const GooseMatrix{T} = GooseArray{T,2}

@inline function _checklive(a::AbstractGooseArray)
    s = a.stack
    _checkowner(s)
    # A published descriptor always has a nonzero token. close/finalization
    # retire every token that could be live, so a matching generation also
    # proves the mapping is open. Allocators still check the mapping directly.
    valid = a.scope.generation == a.generation
    valid || throw(InvalidatedArrayError())
    nothing
end

# Each scope state belongs to exactly one arena. A live reference proves both
# its immutable owner and its scope token; aliases need only compare tokens.
# Different scopes still require their own current generation check.
@inline function _checklive_known(a::AbstractGooseArray, live::AbstractGooseArray)
    if a.scope === live.scope
        a.generation == live.generation || throw(InvalidatedArrayError())
    else
        a.stack === live.stack || _checkowner(a.stack)
        a.scope.generation == a.generation || throw(InvalidatedArrayError())
    end
    nothing
end
@inline function _checklive(a::AbstractGooseArray,b::AbstractGooseArray)
    _checklive(a)
    _checklive_known(b,a)
end
@inline function _checklive(a::AbstractGooseArray,b::AbstractGooseArray,c::AbstractGooseArray)
    _checklive(a,b)
    _checklive_known(c,a)
end

@inline function _checkedlength(dims::NTuple{N,Int}) where {N}
    len = 1
    for d in dims
        d >= 0 || throw(ArgumentError("dimensions must be nonnegative"))
        len = Base.checked_mul(len, d)
    end
    len
end

"""
    alloc!(stack, T, dims...)
    alloc!(stack, T, dims::NTuple)

Allocate uninitialized elements by advancing the arena cursor. A failed request
does not change the cursor. No data storage is allocated on the Julia GC heap.
Descriptor allocation depends on compiler escape analysis and calling context.
"""
@inline function alloc!(stack::DataStack, ::Type{T}, dims::NTuple{N,Int}) where {T,N}
    _checkopen(stack)
    len = _checkedlength(dims)
    ptr,scope,generation = _bump_storage!(stack,T,len)
    GooseArray{T,N}(_validated, stack, ptr, dims, len, scope, generation)
end

# Caller has checked the owner and lifetime, and proved a nonnegative element
# count. In particular, similar can reuse a validated array's count without
# checking all of its immutable dimensions again.
@inline function _bump_storage!(stack::DataStack, ::Type{T}, len::Int) where {T}
    isbitstype(T) || throw(ArgumentError("element type must be a concrete isbits type"))
    width = sizeof(T)
    width > 0 || throw(ArgumentError("zero-size element types are not supported"))
    alignment = Base.datatype_alignment(T)
    padding = Int((-UInt(stack.base + stack.top)) & UInt(alignment - 1))
    remaining = stack.capacity - stack.top
    padding <= remaining || throw(OutOfMemoryError())
    len <= (remaining - padding) ÷ width || throw(OutOfMemoryError())
    start = stack.top + padding
    ptr = Ptr{T}(stack.base + start)
    stack.top = start + len * width
    depth = stack.depth
    @inbounds scope = stack.generations[depth]
    ptr,scope,scope.generation
end

@inline alloc!(s::DataStack, ::Type{T}, dims::Vararg{Int,N}) where {T,N} = alloc!(s, T, dims)
@inline alloc!(s::DataStack, ::Type{T}, dims::Tuple{Vararg{Integer,N}}) where {T,N} =
    alloc!(s, T, map(Int, dims))
@inline alloc!(s::DataStack, ::Type{T}, dims::Vararg{Integer,N}) where {T,N} =
    alloc!(s, T, map(Int, dims))

GooseArray{T}(s::DataStack, ::UndefInitializer, dims::Tuple) where {T} = alloc!(s, T, dims)
GooseArray{T}(s::DataStack, ::UndefInitializer, dims::Vararg{Integer,N}) where {T,N} = alloc!(s, T, dims)
function GooseArray{T,N}(s::DataStack, ::UndefInitializer, dims::Tuple{Vararg{Integer,N}}) where {T,N}
    alloc!(s, T, dims)
end
GooseArray{T,N}(s::DataStack, u::UndefInitializer, dims::Vararg{Integer,N}) where {T,N} =
    GooseArray{T,N}(s, u, dims)

function GooseArray{T}(s::DataStack, src::AbstractArray) where {T}
    Base.require_one_based_indexing(src)
    a = alloc!(s, T, size(src))
    copyto!(a, src)
end
GooseArray(s::DataStack, src::AbstractArray{T}) where {T} = GooseArray{T}(s, src)
GooseVector(s::DataStack, src::AbstractVector) = GooseArray(s, src)
GooseMatrix(s::DataStack, src::AbstractMatrix) = GooseArray(s, src)
function GooseArray{T,N}(s::DataStack, src::AbstractArray{<:Any,N}) where {T,N}
    GooseArray{T}(s, src)
end

Base.size(a::GooseArray) = a.dims
Base.length(a::GooseArray) = a.len
Base.IndexStyle(::Type{<:AbstractGooseArray}) = IndexLinear()
Base.elsize(::Type{<:AbstractGooseArray{T}}) where {T} = sizeof(T)
Base.strides(a::AbstractGooseArray) = Base.size_to_strides(1, size(a)...)
function Base.stride(a::AbstractGooseArray, d::Integer)
    d > 0 || throw(ArgumentError("dimension must be positive"))
    d == 1 ? 1 : d <= ndims(a) ? strides(a)[d] : length(a)
end

Base.@propagate_inbounds function Base.getindex(a::AbstractGooseArray{T}, i::Int) where {T}
    _checklive(a) # Deliberately not inside @boundscheck: @inbounds keeps lifetime checks.
    @boundscheck checkbounds(a, i)
    GC.@preserve a unsafe_load(a.ptr, i)
end

Base.@propagate_inbounds function Base.setindex!(a::AbstractGooseArray{T}, x, i::Int) where {T}
    _checklive(a)
    @boundscheck checkbounds(a, i)
    value = convert(T, x)::T
    # Conversion can execute user code, including reset!/close: check again afterwards.
    _checklive(a)
    GC.@preserve a _store_payload!(a.ptr, value, i)
    a
end

@inline function Base.iterate(a::AbstractGooseArray, i::Int=1)
    _checklive(a)
    1 <= i <= length(a) ? (@inbounds(a[i]), i + 1) : nothing
end

function Base.isassigned(a::AbstractGooseArray, i::Int...)
    _checklive(a)
    checkbounds(Bool, a, i...)
end

@inline Base.similar(a::AbstractGooseArray, ::Type{T}, dims::Dims) where {T} =
    (_checklive(a); alloc!(a.stack, T, dims))
@inline Base.similar(a::AbstractGooseArray, ::Type{T}) where {T} = similar(a, T, size(a))
@inline Base.similar(a::AbstractGooseArray) = similar(a, eltype(a))

@inline function Base.similar(a::GooseArray{T,N}, ::Type{U}) where {T,N,U}
    _checklive(a)
    ptr,scope,generation = _bump_storage!(a.stack,U,length(a))
    GooseArray{U,N}(_validated,a.stack,ptr,size(a),length(a),scope,generation)
end

# Conversion may run user code; after it finishes this loop only writes bits.
# Validate once and retain the owner throughout the bulk operation.
@inline function Base.fill!(a::AbstractGooseArray{T}, x) where {T}
    _checklive(a)
    value = convert(T, x)::T
    _checklive(a)
    GC.@preserve a begin
        @inbounds @simd for i in 1:length(a)
            _store_payload!(a.ptr, value, i)
        end
    end
    a
end

@inline function Base.copy(a::AbstractGooseArray)
    _checklive(a)
    dest = similar(a)
    copyto!(dest, a)
end

function Base.copy!(dest::AbstractGooseArray{<:Any,1}, src::AbstractVector)
    axes(dest) == axes(src) || throw(DimensionMismatch("copy! requires equal axes"))
    copyto!(dest, src)
end

# memmove handles overlapping contiguous aliases, including reshaped arrays.
_checkmemory(a::AbstractGooseArray) = _checklive(a)
_checkmemory(::Array) = nothing
@inline _checkmemories(a,b) = (_checkmemory(a); _checkmemory(b))
@inline _checkmemories(a::AbstractGooseArray,b::AbstractGooseArray) = _checklive(a,b)
@inline _memory_pointer(a::AbstractGooseArray) = a.ptr
@inline _memory_pointer(a::Array) = pointer(a)
@inline function _copybits!(dest, doff::Integer, src, soff::Integer, n::Integer)
    d, s, count = Int(doff), Int(soff), Int(n)
    _checkmemories(dest,src)
    count >= 0 || throw(ArgumentError("copy count must be nonnegative"))
    1 <= d <= length(dest) + 1 && count <= length(dest) - (d - 1) || throw(BoundsError(dest, d))
    1 <= s <= length(src) + 1 && count <= length(src) - (s - 1) || throw(BoundsError(src, s))
    if count > 0
        GC.@preserve dest src ccall(:memmove, Ptr{Cvoid},
            (Ptr{Cvoid}, Ptr{Cvoid}, Csize_t),
            _memory_pointer(dest)+(d-1)*sizeof(eltype(dest)),
            _memory_pointer(src)+(s-1)*sizeof(eltype(src)),count*sizeof(eltype(dest)))
    end
    dest
end

Base.copyto!(dest::AbstractGooseArray{T}, doff::Integer, src::AbstractGooseArray{T}, soff::Integer, n::Integer) where {T} =
    _copybits!(dest, doff, src, soff, n)
Base.copyto!(dest::AbstractGooseArray{T}, doff::Integer, src::Array{T}, soff::Integer, n::Integer) where {T} =
    _copybits!(dest, doff, src, soff, n)
Base.copyto!(dest::Array{T}, doff::Integer, src::AbstractGooseArray{T}, soff::Integer, n::Integer) where {T} =
    _copybits!(dest, doff, src, soff, n)
Base.copyto!(dest::AbstractGooseArray{T}, src::AbstractGooseArray{T}) where {T} =
    _copybits!(dest, 1, src, 1, length(src))
Base.copyto!(dest::AbstractGooseArray{T}, src::Array{T}) where {T} =
    _copybits!(dest, 1, src, 1, length(src))
Base.copyto!(dest::Array{T}, src::AbstractGooseArray{T}) where {T} =
    _copybits!(dest, 1, src, 1, length(src))

function Base.reshape(a::AbstractGooseArray{T}, dims::NTuple{N,Int}) where {T,N}
    _checklive(a)
    _checkedlength(dims) == length(a) || throw(DimensionMismatch("reshape must preserve length"))
    GooseArray{T,N}(_validated, a.stack, a.ptr, dims, length(a), a.scope, a.generation)
end

# Keep the descriptor (and its owner) alive for foreign calls. Extracted raw pointers
# remain the caller's responsibility and cannot carry runtime lifetime checks.
Base.cconvert(::Type{Ptr{T}}, a::AbstractGooseArray{T}) where {T} = (_checklive(a); a)
Base.unsafe_convert(::Type{Ptr{T}}, a::AbstractGooseArray{T}) where {T} = (_checklive(a); a.ptr)

# Julia uses this internal hook for conservative alias detection in broadcasting.
# Distinct nonempty bump allocations are disjoint; reshapes/views share their ID.
Base.dataids(a::AbstractGooseArray) = (_checklive(a); (UInt(a.ptr),))
