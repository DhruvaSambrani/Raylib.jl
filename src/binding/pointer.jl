struct PointerWrapper{T}
    ptr::Ptr{T}
end

# Support tab completion in REPL
Base.propertynames(::PointerWrapper{T}) where T = fieldnames(T)

# Read directly from the C memory offset of the field
@inline function Base.getproperty(pw::PointerWrapper{T}, name::Symbol) where T
    name === :unsafe_ptr && return getfield(pw, :ptr)

    idx = findfirst(==(name), fieldnames(T))
    isnothing(idx) && error("Type $T has no field $name")

    offset = fieldoffset(T, idx)
    FT = fieldtype(T, idx)
    return unsafe_load(convert(Ptr{FT}, getfield(pw, :ptr) + offset))
end

# Write directly to the C memory offset of the field
@inline function Base.setproperty!(pw::PointerWrapper{T}, name::Symbol, value) where T
    idx = findfirst(==(name), fieldnames(T))
    isnothing(idx) && error("Type $T has no field $name")

    offset = fieldoffset(T, idx)
    FT = fieldtype(T, idx)
    unsafe_store!(convert(Ptr{FT}, getfield(pw, :ptr) + offset), convert(FT, value))
end


Base.getindex(pw::PointerWrapper{T}) where T = unsafe_load(getfield(pw, :ptr))
Base.setindex!(pw::PointerWrapper{T}, val::T) where T = unsafe_store!(getfield(pw, :ptr), val)

struct DynamicRefArray{T} <: AbstractVector{PointerWrapper{T}}
    ptr::Ptr{T}
    len::Integer
end

Base.size(A::DynamicRefArray) = (A.len,)
Base.IndexStyle(::Type{<:DynamicRefArray}) = IndexLinear()

function Base.getindex(A::DynamicRefArray{T}, i::Int) where T
    @boundscheck 1 <= i <= A.len || throw(BoundsError(A, i))
    element_ptr = A.ptr + (i - 1) * sizeof(T)
    return PointerWrapper{T}(element_ptr)
end

function Base.setindex!(A::DynamicRefArray{T}, value::T, i::Int) where T
    @boundscheck 1 <= i <= A.len || throw(BoundsError(A, i))
    unsafe_store!(A.ptr, value, i)
end
