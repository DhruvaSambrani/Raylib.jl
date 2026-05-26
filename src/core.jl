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
