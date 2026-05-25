function Binding.SetShaderValue(shader::RayShader, locIndex::Integer, value::Float64)
    @warn "Float64 being cast to float32" maxlog=1
    Binding.SetShaderValue(shader, locIndex, Float32(value))
end

function Binding.SetShaderValue(shader::RayShader, locIndex::Integer, value::Float32)
    Binding.SetShaderValue(shader, locIndex, Ref(value), Int(Binding.SHADER_UNIFORM_FLOAT))
end

function Binding.SetShaderValue(shader::RayShader, locIndex::Integer, value::Integer)
    Binding.SetShaderValue(shader, locIndex, Ref(value), Int(Binding.SHADER_UNIFORM_INT))
end

function Binding.SetShaderValue(
    shader::RayShader,
    locIndex::Integer,
    value::Union{NTuple{2,Real},StaticVector{2,Real}},
)
    v32 = Float32.(value)
    Binding.SetShaderValue(shader, locIndex, Ref(v32), Int(SHADER_UNIFORM_VEC2))
end

function Binding.SetShaderValue(
    shader::RayShader,
    locIndex::Integer,
    value::Union{NTuple{3,Real},StaticVector{3,Real}},
)
    v32 = Float32.(value)
    Binding.SetShaderValue(shader, locIndex, Ref(v32), Int(SHADER_UNIFORM_VEC3))
end

Base.propertynames(::RayModel) = [fieldnames(RayModel); [:meshes_array, :materials_array]]

function Base.getproperty(model::RayModel, name::Symbol)
    if name === :materials_array
        return DynamicRefArray(model.materials, model.materialCount)
    elseif name === :meshes_array
        return DynamicRefArray(model.meshes, model.meshCount)
    else
        return getfield(model, name)
    end
end
