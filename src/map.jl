# The generic AbstractArray map collects a Generator and checks/widens its
# result type during iteration. When inference gives a concrete supported
# element type, allocate the exact shape once and use indexed map!, whose
# indices are known valid and whose loop can vectorize. Unknown result types
# retain Julia's generic collection behavior.
@inline function Base.map(f::F, a::AbstractGooseArray{T}) where {F,T}
    _checklive(a)
    R = Base.promote_op(f, T)
    if isconcretetype(R) && isbitstype(R) && sizeof(R) > 0
        dest = similar(a, R)
        return _map_same_shape!(f, dest, a)
    end
    result = invoke(map, Tuple{Any,AbstractArray}, f, a)
    _map_result(a,result)
end

@inline _map_result(::GooseArray,result) = result
@inline _map_result(::StaticGooseArray{T,N,S},result) where {T,N,S} =
    StaticGooseArray{eltype(result),N,S}(result)

# Only used when construction or an axes check proves equal shapes. There are
# no bounds checks in the loop. A callback/conversion can invalidate storage,
# so its lifetime is checked again before the store, including the last one.
# Validate materialization before the empty/loop split; public map! below must
# instead keep Base's no-access behavior when its minimum range is empty.
@inline function _map_same_shape!(f::F, dest::AbstractGooseArray{R}, a::AbstractGooseArray) where {F,R}
    _checklive(a,dest)
    _map_indices!(f,dest,a,length(a))
end

# Base's unary map! visits the minimum of the two linear index ranges, even
# across different ranks/shapes. No pointer is accessed for an empty range.
# Provide the two-argument form also on Julia versions before Base added it.
@inline Base.map!(f::F,a::AbstractGooseArray) where {F}=map!(f,a,a)
@inline function Base.map!(f::F, dest::AbstractGooseArray, a::AbstractGooseArray) where {F}
    _map_indices!(f,dest,a,min(length(dest),length(a)))
end

@inline function _map_indices!(f::F, dest::AbstractGooseArray{R}, a::AbstractGooseArray, n::Int) where {F,R}
    GC.@preserve a dest begin
        for i in 1:n
            _checklive(a)
            mapped = f(unsafe_load(a.ptr,i))
            # Match indexed assignment: a callback that invalidates dest must
            # fail before invoking its conversion, and conversion is checked
            # again before any store. Unknown callbacks keep these checks.
            _checklive(dest)
            value = convert(R,mapped)::R
            _checklive(dest)
            _store_payload!(dest.ptr,value,i)
        end
    end
    dest
end
