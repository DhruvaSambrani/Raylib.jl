abstract type RayListContainer <: AbstractVector{Any} end

Base.size(list::RayListContainer) = (Int(_list_count(list)),)
@inline _list_count(list) = list.count

@generated function _list_ptr_field(::Type{T}) where {T}
    for (f, t) in zip(fieldnames(T), fieldtypes(T))
        if t <: Ptr
            return QuoteNode(f)
        end
    end
    error("Type $T does not contain a Ptr field")
end

@inline function _list_ptr(list::T) where {T<:RayListContainer}
    return getfield(list, _list_ptr_field(T))
end

@inline function _list_load(list::RayListContainer, ptr, i)
    ET = eltype(ptr)

    if ET === Cstring
        return unsafe_string(unsafe_load(ptr, i))
    elseif isprimitivetype(ET)
        return unsafe_load(ptr, i)
    else
        element_ptr = ptr + (i - 1) * sizeof(ET)
        return PointerWrapper{ET}(element_ptr)
    end
end

function Base.getindex(list::RayListContainer, i::Int)
    @boundscheck 1 <= i <= Int(_list_count(list)) || throw(BoundsError(list, i))
    return _list_load(list, _list_ptr(list), i)
end

function Base.setindex!(list::RayListContainer, value, i::Int)
    @boundscheck 1 <= i <= Int(_list_count(list)) || throw(BoundsError(list, i))
    ptr = _list_ptr(list)
    ET = eltype(ptr)
    unsafe_store!(ptr, convert(ET, value), i)
end
