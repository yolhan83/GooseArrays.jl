# Arena data cannot alias Julia object fields. Use Julia's *array buffer* TBAA
# category for stores, rather than unsafe_store!'s broad jtbaa_data category.
# This also preserves aliasing with Array wrappers of arena pointers: do not use
# a private/disjoint payload category. Scope generations live in object fields,
# not array buffers, so LLVM can hoist checks across these stores when justified.
# Unknown calls and metadata mutations still invalidate those loads normally.

const _PayloadScalar = Union{Bool, Int8, UInt8, Int16, UInt16, Int32, UInt32,
    Int64, UInt64, Int128, UInt128, Float16, Float32, Float64, Char, ComplexF32, ComplexF64}

# Compiler-internal TBAA layout verified for the delivered Julia 1.13 build.
# Other versions retain the portable pointer-store fallback until verified.
const _PAYLOAD_TBAA_SUPPORTED = v"1.13" <= VERSION < v"1.14"

for U in (UInt8, UInt16, UInt32, UInt64, UInt128)
    word = "i$(Sys.WORD_SIZE)"
    bits = "i$(8sizeof(U))"
    ir = """
    define void @entry($word %address, $word %index, $bits %value) alwaysinline {
      %base = inttoptr $word %address to $bits*
      %offset = sub $word %index, 1
      %element = getelementptr inbounds $bits, $bits* %base, $word %offset
      store $bits %value, $bits* %element, align 1, !tbaa !4
      ret void
    }
    !0 = !{!"jtbaa"}
    !1 = !{!"jtbaa", !0, i64 0}
    !2 = !{!"jtbaa_data", !1, i64 0}
    !3 = !{!"jtbaa_arraybuf", !2, i64 0}
    !4 = !{!3, !3, i64 0}
    """
    @eval @inline function _store_bits!(p::Ptr{$U}, value::$U, i::Int)
        Base.llvmcall(($ir, "entry"), Cvoid, Tuple{UInt,Int,$U}, UInt(p), i, value)
        nothing
    end
end

@inline function _store_payload!(p::Ptr{T}, value::T, i::Int) where {T<:_PayloadScalar}
    if _PAYLOAD_TBAA_SUPPORTED
        U = sizeof(T) == 1 ? UInt8 : sizeof(T) == 2 ? UInt16 :
            sizeof(T) == 4 ? UInt32 : sizeof(T) == 8 ? UInt64 : UInt128
        _store_bits!(Ptr{U}(p), reinterpret(U, value), i)
    else
        Core.Intrinsics.pointerset(p, value, i, 1)
    end
    nothing
end

@inline _store_payload!(p::Ptr{T}, value::T, i::Int) where {T} =
    (Core.Intrinsics.pointerset(p, value, i, 1); nothing)
