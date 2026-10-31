struct _Validated end
const _validated = _Validated()

mutable struct _ScopeState
    generation::UInt64
end

"""An array's owning scope has ended, or its arena has been closed/reset."""
struct InvalidatedArrayError <: Exception end
Base.showerror(io::IO, ::InvalidatedArrayError) =
    print(io, "GooseArray storage is no longer live (scope exited, arena reset or closed)")

"""
    DataStack(capacity::Integer; max_scopes=64)

Reserve `capacity` bytes using anonymous mmap. Allocations never move or grow
the mapping. Metadata and scope slots are allocated once at construction.
An arena belongs to the creating Julia Task. Call `close` for deterministic
release; a finalizer is only a fallback. Supported backends: macOS/Linux/FreeBSD.
"""
mutable struct DataStack
    base::Ptr{UInt8}
    top::Int
    const capacity::Int
    const generations::Vector{_ScopeState}
    depth::Int
    serial::UInt64
    const owner::Task
    function DataStack(::_Validated, base, capacity, generations)
        new(base, 0, capacity, generations, 1, UInt64(1), current_task())
    end
end

@static if Sys.isapple()
    const _MAP_ANONYMOUS = 0x1000
elseif Sys.islinux()
    const _MAP_ANONYMOUS = 0x20
elseif Sys.isfreebsd()
    const _MAP_ANONYMOUS = 0x1000
else
    const _MAP_ANONYMOUS = 0
end

function DataStack(nbytes::Integer; max_scopes::Integer=64)
    (Sys.isapple() || Sys.islinux() || Sys.isfreebsd()) ||
        throw(ArgumentError("anonymous mmap backend supports macOS, Linux and FreeBSD"))
    n = Int(nbytes)
    n > 0 || throw(ArgumentError("capacity must be positive"))
    levels = Int(max_scopes)
    levels >= 0 || throw(ArgumentError("max_scopes must be nonnegative"))
    generations = [_ScopeState(0) for _ in 1:Base.checked_add(levels, 1)]
    generations[1].generation = 1
    # PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANONYMOUS, fd=-1, offset=0.
    mem = ccall(:mmap, Ptr{Cvoid},
                (Ptr{Cvoid}, Csize_t, Cint, Cint, Cint, Int64),
                C_NULL, n, 3, 2 | _MAP_ANONYMOUS, -1, 0)
    UInt(mem) == typemax(UInt) && Base.systemerror("mmap", true)
    stack = DataStack(_validated, Ptr{UInt8}(mem), n, generations)
    try
        finalizer(_finalize!, stack)
    catch
        ccall(:munmap, Cint, (Ptr{Cvoid}, Csize_t), mem, n)
        rethrow()
    end
    stack
end

@inline function _checkowner(stack::DataStack)
    stack.owner === current_task() ||
        throw(ArgumentError("DataStack may only be used by its creating Task"))
    nothing
end

@inline function _checkopen(stack::DataStack)
    _checkowner(stack)
    isopen(stack) || throw(InvalidatedArrayError())
    nothing
end

Base.isopen(stack::DataStack) = stack.base != C_NULL
capacity(stack::DataStack) = stack.capacity
bytesused(stack::DataStack) = stack.top
available(stack::DataStack) = isopen(stack) ? stack.capacity - stack.top : 0

function _finalize!(stack::DataStack)
    if isopen(stack)
        # A finalizer must neither throw nor depend on the current Task.
        ret = ccall(:munmap, Cint, (Ptr{Cvoid}, Csize_t), stack.base, stack.capacity)
        if ret == 0
            # Explicit finalize can run even during a nested scope. Retire
            # every active token; inactive slots were retired on scope exit.
            @inbounds for i in 1:stack.depth
                stack.generations[i].generation = 0
            end
            stack.base = C_NULL
            stack.top = 0
        end
    end
    nothing
end

"""Release a root arena and invalidate its arrays. Idempotent; forbidden inside a scope."""
function Base.close(stack::DataStack)
    _checkowner(stack)
    isopen(stack) || return nothing
    stack.depth == 1 || throw(ArgumentError("cannot close an arena inside with_scope"))
    ret = ccall(:munmap, Cint, (Ptr{Cvoid}, Csize_t), stack.base, stack.capacity)
    Base.systemerror("munmap", ret != 0)
    # close is only allowed at the root. No nested token can still be live.
    @inbounds stack.generations[1].generation = 0
    stack.base = C_NULL
    stack.top = 0
    nothing
end

@inline function _nextserial(stack::DataStack)
    stack.serial == typemax(UInt64) && throw(OverflowError("scope generation exhausted"))
    stack.serial + UInt64(1)
end

"""Rewind a root arena and invalidate all previous arrays; retain the mapping."""
function reset!(stack::DataStack)
    _checkopen(stack)
    stack.depth == 1 || throw(ArgumentError("cannot reset an arena inside with_scope"))
    serial = _nextserial(stack)
    stack.serial = serial
    stack.generations[1].generation = serial
    stack.top = 0
    stack
end

"""
    with_scope(f, stack)

Call `f(stack)` and rewind to the entry cursor in `finally`, including on error.
Arrays created in this scope become invalid. Arrays in enclosing scopes survive.
Scope slots are reused without allocation; nesting is bounded by `max_scopes`.
Returning an array is allowed, but accessing it after this scope throws.
"""
@inline function with_scope(f::F, stack::DataStack) where {F}
    _checkopen(stack)
    depth = stack.depth + 1
    depth <= length(stack.generations) || throw(ArgumentError("maximum scope depth exceeded"))
    serial = _nextserial(stack)
    saved = stack.top
    stack.serial = serial
    @inbounds stack.generations[depth].generation = serial
    stack.depth = depth
    try
        f(stack)
    finally
        @inbounds stack.generations[depth].generation = 0
        stack.top = saved
        stack.depth = depth - 1
    end
end

"""Create an arena, call `f(stack)`, and close in `finally`. Setup may allocate."""
function with_datastack(f::F, nbytes::Integer; max_scopes::Integer=64) where {F}
    stack = DataStack(nbytes; max_scopes)
    try
        f(stack)
    finally
        close(stack)
    end
end
