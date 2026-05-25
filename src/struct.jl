using StaticArrays
import Accessors

import Base: propertynames, getproperty, setproperty!

macro mutate(expr)
    return Accessors.setmacro(identity, expr; overwrite=true)
end

struct MutableString
    buffer::Vector{UInt8}

    function MutableString(s::String, maxsize::Int = 256)
        buf = zeros(UInt8, maxsize)
        s_bytes = codeunits(s)
        len = min(length(s_bytes), maxsize - 1)
        buf[1:len] .= s_bytes[1:len]
        return new(buf)
    end
end

Base.unsafe_convert(::Type{Ptr{UInt8}}, ms::MutableString) =
    Base.unsafe_convert(Ptr{UInt8}, ms.buffer)
Base.unsafe_convert(::Type{Cstring}, ms::MutableString) =
    Base.unsafe_convert(Cstring, ms.buffer)
Base.String(ms::MutableString) = unsafe_string(pointer(ms.buffer))
function Base.setindex!(ms::MutableString, s::String)
    fill!(ms.buffer, 0x00)
    s_bytes = codeunits(s)
    maxsize = length(ms.buffer)
    len = min(length(s_bytes), maxsize - 1)
    ms.buffer[1:len] .= s_bytes[1:len]
    return ms
end
Base.getindex(ms::MutableString) = String(ms)

struct RayVector2 <: FieldVector{2,Cfloat}
    x::Cfloat
    y::Cfloat
end

struct RayVector3 <: FieldVector{3,Cfloat}
    x::Cfloat
    y::Cfloat
    z::Cfloat
end

struct RayVector4 <: FieldVector{4,Cfloat}
    x::Cfloat
    y::Cfloat
    z::Cfloat
    w::Cfloat
end

const RayQuaternion = RayVector4

rayvector(v::Vararg{Real,2}) = RayVector2(v)
rayvector(v::Vararg{Real,3}) = RayVector3(v)
rayvector(v::Vararg{Real,4}) = RayVector4(v)

const RayMatrix = SMatrix{4,4,Cfloat,16}
const RayMatrix2x2 = SMatrix{2,2,Cfloat,4}

