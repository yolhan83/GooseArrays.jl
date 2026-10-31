module GooseArrays

export DataStack, AbstractGooseArray, GooseArray, GooseVector, GooseMatrix,
       StaticGooseArray, StaticGooseVector, StaticGooseMatrix,
       alloc!, with_datastack, with_scope, reset!, bytesused, capacity, available,
       InvalidatedArrayError

"""Common dense-array interface for checked arena arrays with dynamic or static shapes."""
abstract type AbstractGooseArray{T,N} <: DenseArray{T,N} end

include("arena.jl")
include("payload.jl")
include("array.jl")
include("static_array.jl")
include("map.jl")
include("multimap.jl")
include("broadcast.jl")

end
