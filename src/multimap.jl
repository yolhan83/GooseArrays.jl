# Tuple recursion specializes on operand count/types, never runtime lengths.
@inline _checklive_tail(live,::Tuple{})=nothing
@inline function _checklive_tail(live,rest::Tuple)
    _checklive_known(first(rest),live)
    _checklive_tail(live,Base.tail(rest))
end
@inline function _checklive_inputs(inputs::Tuple)
    a=first(inputs)
    _checklive(a)
    _checklive_tail(a,Base.tail(inputs))
end
@inline _raw_values(::Tuple{},i)=()
@inline _raw_values(inputs::Tuple,i)=(unsafe_load(first(inputs).ptr,i),_raw_values(Base.tail(inputs),i)...)

@inline _promote_input_shape(shape,::Tuple{})=shape
@inline _promote_input_shape(shape,rest::Tuple)=
    _promote_input_shape(Base.promote_shape(shape,size(first(rest))),Base.tail(rest))
@inline function _multi_shape(inputs::Tuple)
    a=first(inputs)
    n=min(map(length,inputs)...)
    # zip combines vectors by minimum length. Different ranks have HasLength
    # and produce a vector; equal higher ranks use ordinary shape promotion.
    if ndims(a)==1 || !all(x->ndims(x)==ndims(a),inputs)
        return (n,),n
    end
    _promote_input_shape(size(a),Base.tail(inputs)),n
end
@inline _all_static_inputs(::Tuple{Vararg{StaticGooseArray}})=true
@inline _all_static_inputs(::Tuple)=false
@inline function _multi_similar(inputs::Tuple,::Type{R},dims::NTuple{N,Int},n::Int) where {R,N}
    a=first(inputs)
    # Sources are validated; shape promotion/minimum proves n == prod(dims).
    # As in similar, do not repeat owner/open/shape checks before this bump.
    ptr,scope,generation=_bump_storage!(a.stack,R,n)
    if _all_static_inputs(inputs)
        S=Tuple{dims...}
        return StaticGooseArray{R,N,S}(_validated,a.stack,ptr,scope,generation)
    end
    GooseArray{R,N}(_validated,a.stack,ptr,dims,n,scope,generation)
end

@inline function _map_multi_indices!(f::F,dest::AbstractGooseArray{R},inputs::Tuple,n::Int) where {F,R}
    GC.@preserve inputs dest begin
        for i in 1:n
            _checklive_inputs(inputs)
            mapped=f(_raw_values(inputs,i)...)
            _checklive(dest)
            value=convert(R,mapped)::R
            _checklive(dest)
            _store_payload!(dest.ptr,value,i)
        end
    end
    dest
end
@inline function Base.map!(f::F,dest::AbstractGooseArray,a::AbstractGooseArray,
        b::AbstractGooseArray,rest::Vararg{AbstractGooseArray,K}) where {F,K}
    inputs=(a,b,rest...)
    n=min(length(dest),map(length,inputs)...)
    _map_multi_indices!(f,dest,inputs,n)
end

@inline function _fallback_multimap(f,inputs::Tuple)
    invoke(map,Tuple{Any,Vararg{AbstractArray,length(inputs)}},f,inputs...)
end
@inline function Base.map(f::F,a::AbstractGooseArray,b::AbstractGooseArray,
        rest::Vararg{AbstractGooseArray,K}) where {F,K}
    inputs=(a,b,rest...)
    R=Base.promote_op(f,map(eltype,inputs)...)
    if isconcretetype(R) && isbitstype(R) && sizeof(R)>0
        _checklive_inputs(inputs)
        dims,n=_multi_shape(inputs)
        dest=_multi_similar(inputs,R,dims,n)
        return _map_multi_indices!(f,dest,inputs,n)
    end
    _fallback_multimap(f,inputs)
end

# A read-only adapter feeds Base's pairwise/SIMD reduction without storing
# mapped elements. Its length is a field, never a type parameter.
struct _MappedGoose{R,F,A<:Tuple} <: AbstractVector{R}
    f::F
    arrays::A
    len::Int
end
Base.size(a::_MappedGoose)=(a.len,)
Base.IndexStyle(::Type{<:_MappedGoose})=IndexLinear()
Base.@propagate_inbounds function Base.getindex(a::_MappedGoose{R},i::Int) where {R}
    @boundscheck checkbounds(a,i)
    inputs=a.arrays
    _checklive_inputs(inputs)
    GC.@preserve inputs a.f(_raw_values(inputs,i)...)::R
end
const _PrimitiveReductionNumber=Union{Bool,Int8,UInt8,Int16,UInt16,Int32,UInt32,
    Int64,UInt64,Int128,UInt128,Float16,Float32,Float64,ComplexF32,ComplexF64}
@inline function _native_reduction_keywords(kwargs)
    isempty(kwargs) || (length(kwargs)==1 && haskey(kwargs,:init) && kwargs[:init] isa _PrimitiveReductionNumber)
end
@inline function _small_multi_reduce(f::F,inputs::Tuple,n::Int,::Type{R}) where {F,R}
    # Same short sequential regime as Base (n < 16), without copying a mapped
    # array descriptor through its reduction call boundary. The caller proved
    # n positive and validated every source immediately before this first read.
    GC.@preserve inputs begin
        acc=Base.reduce_first(+,f(_raw_values(inputs,1)...)::R)
        for i in 2:n
            _checklive_inputs(inputs)
            acc += f(_raw_values(inputs,i)...)::R
        end
        return acc
    end
end
@inline function Base.mapreduce(f::F,op::O,a::AbstractGooseArray,b::AbstractGooseArray,
        rest::Vararg{AbstractGooseArray,K};dims=:,kwargs...) where {F,O,K}
    inputs=(a,b,rest...)
    R=Base.promote_op(f,map(eltype,inputs)...)
    if dims isa Colon && op === (+) && isconcretetype(R) && R <: _PrimitiveReductionNumber && _native_reduction_keywords(kwargs)
        _checklive_inputs(inputs)
        _,n=_multi_shape(inputs)
        if 0<n<16 && isempty(kwargs)
            return _small_multi_reduce(f,inputs,n,R)
        end
        mapped=_MappedGoose{R,F,typeof(inputs)}(f,inputs,n)
        return mapreduce(identity,op,mapped;kwargs...)
    end
    # Dimensions, custom operators/initial values and unknown results retain
    # eager mapping followed by Base's ordinary reduction semantics.
    reduce(op,map(f,inputs...);dims,kwargs...)
end
