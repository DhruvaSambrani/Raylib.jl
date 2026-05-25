# 1. Fallback for when no value is provided (defaults to c_default)
c_convert(::Type{T}, ::Nothing) where T = c_default(T)
c_convert(::Type{T}, value::T) where T = value
function c_convert(::Type{Ptr{T}}, value::AbstractArray) where T
    typed_data = eltype(value) === T ? value : convert(AbstractArray{T}, value)
    nbytes = length(typed_data) * sizeof(T)
    c_ptr = convert(Ptr{T}, MemAlloc(nbytes))
    GC.@preserve typed_data begin
        unsafe_copyto!(c_ptr, pointer(typed_data), length(typed_data))
    end
    return c_ptr
end
c_convert(::Type{Ptr{T}}, value::Ptr{T}) where T = value
c_convert(::Type{Ptr{T}}, value::Ptr) where T = convert(Ptr{T}, value)
c_convert(::Type{T}, value) where T = convert(T, value)


c_default(::Type{R}) where {R<:Number} = zero(R)
c_default(::Type{Ptr{R}}) where R = Ptr{R}(0)
c_default(::Type{NTuple{N, R}}) where {N, R} = ntuple(_ -> c_default(R), Val(N))

function c_default(::Type{K}) where K
    println(K)
    if isbitstype(K) && !isprimitivetype(K)
        args = map(c_default, fieldtypes(K))
        return K(args...)
    else
        return zero(K)
    end
end

macro c_struct(expr, destructor=nothing)
    expr.head === :struct || error("Macro must be applied to a struct definition")
    name = expr.args[2] isa Expr ? expr.args[2].args[1] : expr.args[2]

    args = [a for a in expr.args[3].args if !(a isa LineNumberNode)]
    fields = [a isa Expr && a.head === :(::) ? a.args[1] : a for a in args]
    types  = [a isa Expr && a.head === :(::) ? a.args[2] : :Any for a in args]

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

@c_struct struct RayRectangle
    x::Cfloat        # Rectangle top-left corner position x
    y::Cfloat        # Rectangle top-left corner position y
    width::Cfloat    # Rectangle width
    height::Cfloat   # Rectangle height
end

@c_struct struct RayImage
    data::Ptr{Cvoid}         # Image raw data
    width::Cint              # Image base width
    height::Cint             # Image base height
    mipmaps::Cint            # Mipmap levels, 1 by default
    format::Cint             # Data format (PixelFormat type)
end

@c_struct struct RayTexture
    id::Cuint        # OpenGL texture id
    height::Cint     # Texture base height
    mipmaps::Cint    # Mipmap levels, 1 by default
    format::Cint     # Data format (PixelFormat type)
end

const RayTexture2D = RayTexture
const RayTextureCubemap = RayTexture

@c_struct struct RayRenderTexture
    id::Cuint                # OpenGL framebuffer object id
    texture::RayTexture      # Color buffer attachment texture
    depth::RayTexture        # Depth buffer attachment texture
end

const RayRenderTexture2D = RayRenderTexture

@c_struct struct RayNPatchInfo
    source::RayRectangle     # Texture source rectangle
    left::Cint               # Left border offset
    top::Cint                # Top border offset
    right::Cint              # Right border offset
    bottom::Cint             # Bottom border offset
    layout::Cint             # Layout of the n-patch: 3x3, 1x3 or 3x1
end

@c_struct struct RayGlyphInfo
   value::Cint              # Character value (Unicode)
   offsetX::Cint            # Character offset X when drawing
   offsetY::Cint            # Character offset Y when drawing
   advanceX::Cint           # Character advance position X
   image::RayImage          # Character image data
end

@c_struct struct RayFont
    baseSize::Cint                 # Base size (default chars height)
    glyphCount::Cint               # Number of glyph characters
    glyphPadding::Cint             # Padding around the glyph characters
    texture::RayTexture            # Texture atlas containing the glyphs
    recs::Ptr{RayRectangle}        # Rectangles in texture for the glyphs
    glyphs::Ptr{RayGlyphInfo}      # Glyphs info data
end

@c_struct struct RayMesh
    vertexCount::Cint        # Number of vertices stored in arrays
    triangleCount::Cint      # Number of triangles stored (indexed or not)

    # Vertex attributes data
    vertices::Ptr{Cfloat}        # Vertex position (XYZ - 3 components per vertex) (shader-location = 0)
    texcoords::Ptr{Cfloat}       # Vertex texture coordinates (UV - 2 components per vertex) (shader-location = 1)
    texcoords2::Ptr{Cfloat}      # Vertex second texture coordinates (useful for lightmaps) (shader-location = 5)
    normals::Ptr{Cfloat}         # Vertex normals (XYZ - 3 components per vertex) (shader-location = 2)
    tangents::Ptr{Cfloat}        # Vertex tangents (XYZW - 4 components per vertex) (shader-location = 4)
    colors::Ptr{Cuchar}          # Vertex colors (RGBA - 4 components per vertex) (shader-location = 3)
    indices::Ptr{Cuchar}         # Vertex indices (in case vertex data comes indexed)

    # Animation vertex data
    boneCount::Cint              # Number of bones (MAX: 256 bones)
    boneIndices::Ptr{Cuchar}     # Vertex bone indices, up to 4 bones influence by vertex (skinning) (shader-location = 6)
    boneWeights::Ptr{Cfloat}     # Vertex bone weights, up to 4 bones influence by vertex (skinning) (shader-location = 7)

    animVertices::Ptr{Cfloat}    # Animated vertex positions (after bones transformations)
    animNormals::Ptr{Cfloat}     # Animated normals (after bones transformations)

    # OpenGL identifiers
    vaoId::Cuint                 # OpenGL Vertex Array Object id
    vboId::Ptr{Cuint}            # OpenGL Vertex Buffer Objects id (default vertex data)
end

@c_struct struct RayShader
    id::Cuint                    # Shader program id
    locs::Ptr{Cint}              # Shader locations array (RL_MAX_SHADER_LOCATIONS)
end

@c_struct struct RayMaterialMap
    texture::RayTexture        # Material map texture
    color::RayColor            # Material map color
    value::Cfloat              # Material map value
end

@c_struct struct RayMaterial
    shader::RayShader                # Material shader
    maps::Ptr{RayMaterialMap}        # Material maps array (MAX_MATERIAL_MAPS)
    params::NTuple{4, Cfloat}        # Material generic parameters (if required)
end

@c_struct struct RayTransform
    translation::RayVector3     # Translation
    rotation::RayQuaternion     # Rotation
    scale::RayVector3           # Scale
end

@c_struct struct RayBoneInfo
    name::NTuple{32, Cchar}          # Bone name
    parent::Cint                     # Bone parent
end

@c_struct struct RayModel
    transform::RayMatrix              # Local transform matrix

    meshCount::Cint                   # Number of meshes
    materialCount::Cint               # Number of materials
    meshes::Ptr{RayMesh}              # Meshes array
    materials::Ptr{RayMaterial}       # Materials array
    meshMaterial::Ptr{Cint}           # Mesh material number

    # Animation data
    boneCount::Cint                   # Number of bones
    bones::Ptr{RayBoneInfo}           # Bones information (skeleton)
    bindPose::Ptr{RayTransform}       # Bones base transformation (pose)
end

@c_struct struct RayModelAnimation
    boneCount::Cint                # Number of bones
    frameCount::Cint               # Number of animation frames
    bones::Ptr{RayBoneInfo}        # Bones information (skeleton)
    # Transform **framePoses        # Poses array by frame
    framePoses::Ptr{Ptr{RayTransform}}        # Poses array by frame
end

@c_struct struct Ray
    position::RayVector3        # Ray position (origin)
    direction::RayVector3       # Ray direction
end

@c_struct struct RayCollision
    hit::Bool                  # Did the ray hit something?
    distance::Cfloat           # Distance to nearest hit
    point::RayVector3          # Point of nearest hit
    normal::RayVector3         # Surface normal of hit
end

@c_struct struct RayBoundingBox
    min::RayVector3     # Minimum vertex box-corner
    max::RayVector3     # Maximum vertex box-corner
end

@c_struct struct RayWave
    frameCount::Cuint      # Total number of frames (considering channels)
    sampleRate::Cuint      # Frequency (samples per second)
    sampleSize::Cuint      # Bit depth (bits per sample): 8, 16, 32 (24 not supported)
    channels::Cuint        # Number of channels (1-mono, 2-stereo, ...)
    data::Ptr{Cvoid}       # Buffer data pointer
end

@c_struct struct RayAudioStream
    # rAudioBuffer *buffer;       // Pointer to internal data used by the audio system
    buffer::Ptr{Cvoid}
    processor::Ptr{Cvoid}

    sampleRate::Cuint    # Frequency (samples per second)
    sampleSize::Cuint    # Bit depth (bits per sample): 8, 16, 32 (24 not supported)
    channels::Cuint      # Number of channels (1-mono, 2-stereo, ...)
end

@c_struct struct RaySound
    stream::RayAudioStream         # Audio stream
    frameCount::Cuint              # Total number of frames (considering channels)
end

@c_struct struct RayMusic
    stream::RayAudioStream        # Audio stream
    frameCount::Cuint             # Total number of frames (considering channels)
    looping::Bool                 # Music looping enable

    ctxType::Cint                 # Type of music context (audio filetype)
    ctxData::Ptr{Cvoid}           # Audio context data, depends on type
end

@c_struct struct RayVrDeviceInfo
    hResolution::Cint                        # Horizontal resolution in pixels
    vResolution::Cint                        # Vertical resolution in pixels
    hScreenSize::Cfloat                      # Horizontal size in meters
    vScreenSize::Cfloat                      # Vertical size in meters
    vScreenCenter::Cfloat                    # Screen center in meters
    eyeToScreenDistance::Cfloat              # Distance between eye and display in meters
    lensSeparationDistance::Cfloat           # Lens separation distance in meters
    interpupillaryDistance::Cfloat           # IPD (distance between pupils) in meters
    lensDistortionValues::NTuple{4, Cfloat}  # Lens distortion constant parameters
    chromaAbCorrection::NTuple{4, Cfloat}    # Chromatic aberration correction parameters
end

@c_struct struct RayVrStereoConfig
    projection::NTuple{2, RayMatrix}           # VR projection matrices (per eye)
    viewOffset::NTuple{2, RayMatrix}           # VR view offset matrices (per eye)
    leftLensCenter::NTuple{2, Cfloat}          # VR left lens center
    rightLensCenter::NTuple{2, Cfloat}         # VR right lens center
    leftScreenCenter::NTuple{2, Cfloat}        # VR left screen center
    rightScreenCenter::NTuple{2, Cfloat}       # VR right screen center
    scale::NTuple{2, Cfloat}                   # VR distortion scale
    scaleIn::NTuple{2, Cfloat}                 # VR distortion scale in
end

@c_struct struct RayGuiStyleProp
    controlId::Cushort
    propertyId::Cushort
    propertyValue::Cint
end


struct DynamicArray{T} <: AbstractVector{T}
    ptr::Ptr{T}
    len::Integer
end

Base.size(A::DynamicArray) = (A.len,)
Base.IndexStyle(::Type{<:DynamicArray}) = IndexLinear()

function Base.getindex(A::DynamicArray{T}, i::Int) where T
    @boundscheck 1 <= i <= A.len || throw(BoundsError(A, i))
    return unsafe_load(A.ptr, i)
end

function Base.setindex(A::DynamicArray{T}, i::Int, value::T) where T
    @boundscheck 1 <= i <= A.len || throw(BoundsError(A, i))
    return unsafe_store!(A.ptr, value, i)
end

const RayFilePathList = DynamicArray{Cstring}

function Base.cconvert(::Type{Ptr{Cstring}}, v::Vector{String})
    return (Base.unsafe_convert.(Cstring, v), v)
end
function Base.unsafe_convert(::Type{Ptr{Cstring}}, x::Tuple{Vector{Cstring}, Vector{String}})
    return Base.unsafe_convert(Ptr{Cstring}, x[1])
end

