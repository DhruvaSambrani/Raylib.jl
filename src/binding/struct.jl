# 1. Fallback for when no value is provided (defaults to c_default)
c_convert(::Type{T}, ::Nothing) where {T} = c_default(T)
c_convert(::Type{T}, value::T) where {T} = value
function c_convert(::Type{Ptr{T}}, value::AbstractArray) where {T}
    typed_data = eltype(value) === T ? value : convert(AbstractArray{T}, value)
    nbytes = length(typed_data) * sizeof(T)
    c_ptr = convert(Ptr{T}, MemAlloc(nbytes))
    GC.@preserve typed_data begin
        unsafe_copyto!(c_ptr, pointer(typed_data), length(typed_data))
    end
    return c_ptr
end
c_convert(::Type{Ptr{T}}, value::Ptr{T}) where {T} = value
c_convert(::Type{Ptr{T}}, value::Ptr) where {T} = convert(Ptr{T}, value)
c_convert(::Type{T}, value) where {T} = convert(T, value)


c_default(::Type{R}) where {R<:Number} = zero(R)
c_default(::Type{Ptr{R}}) where {R} = Ptr{R}(0)
c_default(::Type{NTuple{N,R}}) where {N,R} = ntuple(_ -> c_default(R), Val(N))

function c_default(::Type{K}) where {K}
    println(K)
    if isbitstype(K) && !isprimitivetype(K)
        args = map(c_default, fieldtypes(K))
        return K(args...)
    else
        return zero(K)
    end
end

macro c_struct(expr, destructor = nothing)
    expr.head === :struct || error("Macro must be applied to a struct definition")
    name = expr.args[2] isa Expr ? expr.args[2].args[1] : expr.args[2]

    args = [a for a in expr.args[3].args if !(a isa LineNumberNode)]
    fields = [a isa Expr && a.head === :(::) ? a.args[1] : a for a in args]
    types = [a isa Expr && a.head === :(::) ? a.args[2] : :Any for a in args]

    kws = [Expr(:kw, f, :nothing) for f in fields]
    converts = [:(c_convert($t, $f)) for (f, t) in zip(fields, types)]

    return esc(quote
        $expr
        $name(; $(kws...)) = begin
            obj = $name($(converts...))
            obj
        end
    end)
end

function Base.cconvert(::Type{Ptr{Cstring}}, v::Vector{String})
    return (Base.unsafe_convert.(Cstring, v), v)
end
function Base.unsafe_convert(::Type{Ptr{Cstring}}, x::Tuple{Vector{Cstring},Vector{String}})
    return Base.unsafe_convert(Ptr{Cstring}, x[1])
end
