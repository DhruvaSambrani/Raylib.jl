"""
    UpdateCamera(camera::RayCamera3D, mode::CameraMode)

Return new camera with updated parameter.
"""
function Binding.UpdateCamera(camera::RayCamera3D, mode::CameraMode)
    new_camera_ref = Ref(camera)
    UpdateCamera(new_camera_ref, Cint(mode))

    return new_camera_ref[]
end

"""
    UpdateCamera!(camera::RayCamera3D, mode::CameraMode)

Update camera position for selected mode
"""
function UpdateCamera!(camera::RayCamera3D, mode::CameraMode)
    camera_ptr = convert(Ptr{RayCamera3D}, pointer_from_objref(camera))
    UpdateCamera(camera_ptr, Cint(mode))
    return camera
end

function Base.getindex(it::RayFilePathList, i)
    list = Base.unsafe_wrap(Vector{Cstring}, it.paths, it.count)
    checkbounds(list, i)
    return Base.unsafe_string(list[i])
end

"""
    RayFileData(filename::AbstractString)

Read the file data. It will be auto-unloaded when being garbage collected.
"""
struct RayFileData
    data::Vector{UInt8}

    function RayFileData(filename::AbstractString)
        bytes = Ref{Cint}(0)
        dptr = LoadFileData(filename, bytes)
        fdata = Base.unsafe_wrap(Vector{UInt8}, dptr, bytes[])
        finalizer(fdata) do x
            ptr = pointer(x)
            UnloadFileData(ptr)
        end

        return new(fdata)
    end
end

Base.length(fdata::RayFileData) = length(fdata.data)
Base.pointer(fdata::RayFileData) = pointer(fdata.data)

#Convert KeyPressed Enums to Int
for func in :(IsKeyDown, IsKeyPressed, IsKeyReleased, IsKeyUp).args
    @eval Binding.$func(k::KeyboardKey) = $func(convert(Integer, k))
end

#Convert MouseButton Enums to Int
for func in
    :(IsMouseButtonDown, IsMouseButtonPressed, IsMouseButtonReleased, IsMouseButtonUp).args

    @eval Binding.$func(m::MouseButton) = $func(convert(Integer, m))
end

#Convert MouseCursor Enums to Int
for func in :(SetMouseCursor,).args
    @eval Binding.$func(c::MouseCursor) = $func(convert(Integer, c))
end

Base.length(list::RayFilePathList) = Int(list.count)
Base.size(list::RayFilePathList) = (Int(list.count),)
Base.firstindex(list::RayFilePathList) = 1
Base.lastindex(list::RayFilePathList) = Int(list.count)

function Base.getindex(list::RayFilePathList, i::Int)
    @boundscheck 1 <= i <= Int(list.count) || throw(BoundsError(list, i))
    ptr = unsafe_load(list.paths, i)
    return unsafe_string(ptr)
end

function Base.iterate(list::RayFilePathList, state=1)
    state > Int(list.count) && return nothing
    return (list[state], state + 1)
end
