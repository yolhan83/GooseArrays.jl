struct GooseArrayStyle{N} <: Base.Broadcast.AbstractArrayStyle{N} end
GooseArrayStyle{N}(::Val{M}) where {N,M} = GooseArrayStyle{M}()
Base.BroadcastStyle(::Type{<:GooseArray{T,N}}) where {T,N} = GooseArrayStyle{N}()
Base.BroadcastStyle(::Type{<:SubArray{T,N,<:GooseArray}}) where {T,N} = GooseArrayStyle{N}()
Base.BroadcastStyle(::GooseArrayStyle{N}, ::GooseArrayStyle{M}) where {N,M} = GooseArrayStyle{max(N,M)}()
Base.BroadcastStyle(::GooseArrayStyle{N}, ::Base.Broadcast.DefaultArrayStyle{M}) where {N,M} = GooseArrayStyle{max(N,M)}()
Base.BroadcastStyle(::Base.Broadcast.DefaultArrayStyle{M}, ::GooseArrayStyle{N}) where {N,M} = GooseArrayStyle{max(N,M)}()

_broadcast_stack(a::AbstractGooseArray) = (_checklive(a); a.stack)
_broadcast_stack(a::SubArray) = _broadcast_stack(parent(a))
_broadcast_stack(bc::Base.Broadcast.Broadcasted) = _broadcast_stack(bc.args)
_broadcast_stack(::Any) = nothing
_broadcast_stack(::Tuple{}) = nothing
@inline function _broadcast_stack(args::Tuple)
    stack = _broadcast_stack(first(args))
    stack === nothing ? _broadcast_stack(Base.tail(args)) : stack
end

@inline function Base.similar(bc::Base.Broadcast.Broadcasted{GooseArrayStyle{N}}, ::Type{T}) where {N,T}
    stack = _broadcast_stack(bc)
    stack === nothing && throw(ArgumentError("broadcast needs a GooseArray arena"))
    alloc!(stack, T, map(length, axes(bc)))
end

# Match Base's convention: zero-dimensional out-of-place broadcast returns a scalar.
Base.copy(bc::Base.Broadcast.Broadcasted{GooseArrayStyle{0}}) = bc[CartesianIndex()]

# Preserve statically known shapes for static operands and scalar broadcasts.
# Mixing with dynamically shaped arrays intentionally produces GooseArray.
struct StaticGooseArrayStyle{S,N} <: Base.Broadcast.AbstractArrayStyle{N} end
Base.BroadcastStyle(::Type{<:StaticGooseArray{T,N,S}}) where {T,N,S} = StaticGooseArrayStyle{S,N}()
Base.BroadcastStyle(::Type{<:SubArray{T,N,<:StaticGooseArray}}) where {T,N} = GooseArrayStyle{N}()

function Base.BroadcastStyle(::StaticGooseArrayStyle{S,N}, ::StaticGooseArrayStyle{R,M}) where {S,N,R,M}
    a, b = _static_dims(S), _static_dims(R)
    dims = ntuple(Val(max(N,M))) do i
        x, y = i <= N ? a[i] : 1, i <= M ? b[i] : 1
        x == y ? x : x == 1 ? y : y == 1 ? x : throw(DimensionMismatch("incompatible static broadcast shapes"))
    end
    StaticGooseArrayStyle{Tuple{dims...},max(N,M)}()
end
Base.BroadcastStyle(s::StaticGooseArrayStyle, ::Base.Broadcast.DefaultArrayStyle{0}) = s
Base.BroadcastStyle(::Base.Broadcast.DefaultArrayStyle{0}, s::StaticGooseArrayStyle) = s
Base.BroadcastStyle(::StaticGooseArrayStyle{S,N}, ::Base.Broadcast.DefaultArrayStyle{M}) where {S,N,M} = GooseArrayStyle{max(N,M)}()
Base.BroadcastStyle(::Base.Broadcast.DefaultArrayStyle{M}, ::StaticGooseArrayStyle{S,N}) where {S,N,M} = GooseArrayStyle{max(N,M)}()
Base.BroadcastStyle(::StaticGooseArrayStyle{S,N}, ::GooseArrayStyle{M}) where {S,N,M} = GooseArrayStyle{max(N,M)}()
Base.BroadcastStyle(::GooseArrayStyle{M}, ::StaticGooseArrayStyle{S,N}) where {S,N,M} = GooseArrayStyle{max(N,M)}()

@inline function Base.similar(bc::Base.Broadcast.Broadcasted{StaticGooseArrayStyle{S,N}}, ::Type{T}) where {S,N,T}
    stack = _broadcast_stack(bc)
    stack === nothing && throw(ArgumentError("broadcast needs a GooseArray arena"))
    axes(bc) == map(Base.OneTo,_static_dims(S)) ||
        throw(DimensionMismatch("broadcast axes do not match the static shape"))
    StaticGooseArray{T,N,S}(stack, undef)
end
Base.copy(bc::Base.Broadcast.Broadcasted{StaticGooseArrayStyle{S,0}}) where {S} = bc[CartesianIndex()]

# Unary shape-preserving broadcasts can share map's indexed materialization.
# Other broadcasts retain Base's singleton expansion, fusion and type widening.
@inline function _copy_arena_broadcast(bc)
    R = Base.Broadcast.combine_eltypes(bc.f,bc.args)
    if isconcretetype(R) && isbitstype(R) && sizeof(R) > 0
        dest = similar(bc,R)
        if bc.args isa Tuple{AbstractGooseArray} && axes(bc) == axes(bc.args[1])
            return _map_same_shape!(bc.f,dest,bc.args[1])
        end
        # This is a fresh bump allocation, disjoint from all live inputs. No
        # destination alias analysis/copying is needed. Base still prepares
        # singleton dimensions and fused expression indexing. Indexed stores
        # retain their checks after callbacks/conversions.
        prepared = Base.Broadcast.preprocess(nothing,bc)
        @inbounds @simd for I in eachindex(prepared)
            dest[I] = prepared[I]
        end
        return dest
    end
    invoke(copy,Tuple{Base.Broadcast.Broadcasted},bc)
end
@inline Base.copy(bc::Base.Broadcast.Broadcasted{GooseArrayStyle{N}}) where {N} = _copy_arena_broadcast(bc)
@inline Base.copy(bc::Base.Broadcast.Broadcasted{StaticGooseArrayStyle{S,N}}) where {S,N} = _copy_arena_broadcast(bc)
