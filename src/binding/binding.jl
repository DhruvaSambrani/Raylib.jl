module Binding
using Raylib_jll
using JSON

using CEnum
using StaticArrays

import ..Raylib:
    RayColor, RayVector2, RayVector3, RayVector4, RayQuaternion, RayMatrix, RayMatrix2x2

include("./pointer.jl")
include("./struct.jl")

to_cstring(::Nothing) = C_NULL
to_cstring(s::String) = s
to_cstring(p::Union{Cstring,Ptr}) = p

let
    parse_json(f) = JSON.parse(read(f, String))
    builder = function ()
        # Define which C struct types must be generated as `mutable struct`
        MUTABLE_TYPES = Set([
            "Mesh",
            "Image",
            "Camera",
            "Camera3D",
            "Camera2D",
            "Model",
            "Material",
            "Wave",
        ])

        # Updated to safely handle `nothing` pointers for simple value-type 'char' fields
        special_ptr = Dict{String,Any}(
            "char" =>
                (name, n) ->
                    isnothing(n) ? (name, n) : (n == 2 ? ("char **", 0) : ("$name *", n-1)),
        )

        typemap_dict = Dict{String,Any}(
            "void" => (:Cvoid, :Nothing),
            "char" => (:Cchar, :Char),
            "char **" => (:(Ptr{Cstring}), :(Vector{String})),
            "int" => (:Cint, :(Union{Integer,CEnum.Cenum})),
            "long" => (:Clong, :Integer),
            "long long" => (:Clonglong, :Integer),
            "short" => (:Cshort, :Integer),
            "float" => (:Cfloat, :Real),
            "double" => (:Cdouble, :Real),
            "unsigned char" => (:Cuchar, :UInt8),
            "unsigned int" => (:Cuint, :(Union{Integer,CEnum.Cenum})),
            "unsigned long" => (:Culong, :Integer),
            "unsigned long long" => (:Culonglong, :Integer),
            "unsigned short" => (:Cushort, :Integer),
            "bool" => (:Bool, :Bool, :Bool),
            "float3" => :(NTuple{3,Cfloat}),
            "float16" => :(NTuple{16,Cfloat}),
            "Color" => :RayColor,
            "Camera" => :RayCamera3D,
            "Camera3D" => :RayCamera3D,
            "Camera2D" => :RayCamera2D,
            "Rectangle" => :RayRectangle,
            "Texture" => :RayTexture,
            "Texture2D" => :RayTexture,
            "TextureCubemap" => :RayTexture,
            "RenderTexture" => :RayRenderTexture,
            "RenderTexture2D" => :RayRenderTexture,
            "NPatchInfo" => :RayNPatchInfo,
            "Image" => :RayImage,
            "GlyphInfo" => :RayGlyphInfo,
            "Font" => :RayFont,
            "Mesh" => :RayMesh,
            "Shader" => :RayShader,
            "MaterialMap" => :RayMaterialMap,
            "Material" => :RayMaterial,
            "Transform" => :RayTransform,
            "BoneInfo" => :RayBoneInfo,
            "Model" => :RayModel,
            "ModelAnimation" => :RayModelAnimation,
            "Ray" => :Ray,
            "RayCollision" => :RayCollision,
            "BoundingBox" => :RayBoundingBox,
            "Wave" => :RayWave,
            "AudioStream" => :RayAudioStream,
            "Sound" => :RaySound,
            "Music" => :RayMusic,
            "FilePathList" => :RayFilePathList,
            "VrDeviceInfo" => :RayVrDeviceInfo,
            "VrStereoConfig" => :RayVrStereoConfig,
            "Matrix" => :RayMatrix,
            "Matrix2x2" => :RayMatrix2x2,
            "Vector2" => (:RayVector2, :(StaticVector{2})),
            "Vector3" => (:RayVector3, :(StaticVector{3})),
            "Vector4" => (:RayVector4, :(StaticVector{4})),
            "Quaternion" => (:RayVector4, :(StaticVector{4})),
            "GuiStyleProp" => :RayGuiStyleProp,
            "rAudioBuffer" => :Cvoid,
            "rAudioProcessor" => :Cvoid,
            "ModelAnimPose" => :(Ptr{RayTransform}),
            "TraceLogCallback" => :(Ptr{Cvoid}),
            "LoadFileDataCallback" => :(Ptr{Cvoid}),
            "SaveFileDataCallback" => :(Ptr{Cvoid}),
            "LoadFileTextCallback" => :(Ptr{Cvoid}),
            "SaveFileTextCallback" => :(Ptr{Cvoid}),
            "AudioCallback" => :(Ptr{Cvoid}),
        )

        maybe(f, x) = f(x)
        maybe(f, ::Nothing) = nothing
        maybe(f) = Base.Fix1(maybe, f)

        function nested_X(X, T, n, abs = false)
            P = T
            for i = 1:n
                if abs
                    P = Expr(:<:, P)
                end
                P = Expr(:curly, X, P)
            end
            return P
        end
        nested_ptr(T, n, abs = false) = nested_X(:Ptr, T, n, abs)
        nested_refptr(T, n, abs = false) =
            n >= 1 ? nested_X(:Ref, nested_X(:Ptr, T, n-1, abs), 1, abs) : T

        # Updated regex to capture inline array sizes, e.g., "float[4]" -> arr_sz = "4"
        function parse_type(type_s)
            m = match(r"(const )?([^\[\*]+)(?:\[(\d+)\])?(\*+)?", type_s)
            isnothing(m) && return nothing

            cst, type_name, arr_sz, stars = map(maybe(strip), m.captures)
            iscst = !isnothing(cst)
            nptr = maybe(length, stars)
            sz = isnothing(arr_sz) ? nothing : parse(Int, arr_sz)

            return iscst, type_name, sz, nptr
        end

        get_type(x::Tuple, n, i) = i <= length(x) ? x[i] : nothing
        get_type(x, n, i) = x
        get_type(x::Function, n, i) = x(n, i)

        # Resolves the raw base type matching without arrays or pointer modifications
        function x_typemap_base(i, iscst, type_name)
            if type_name == "char *"
                if iscst || i == 3  # If it's const, or if it's a return type
                    return i == 1 ? :Cstring : (i == 2 ? :(Union{String,Nothing}) : :String)
                else
                    return i == 1 ? :(Ptr{UInt8}) : :(MutableString)
                end
            end
            T = maybe(get(typemap_dict, type_name, nothing)) do x
                get_type(x, type_name, i)
            end

            if isnothing(T) && i <= 2
                @debug "\ttypemap $type_name not found"
            end
            return T
        end

        # Composes the final type by applying NTuples and/or pointer wrappers
        function x_typemap(i, iscst, type_name, sz, nptr)
            if haskey(special_ptr, type_name)
                type_name, nptr = special_ptr[type_name](type_name, nptr)
            end

            is_pointer = !isnothing(nptr) && nptr > 0
            target_i = (!isnothing(sz) || is_pointer) ? 1 : i

            T = x_typemap_base(target_i, iscst, type_name)
            isnothing(T) && return nothing

            # Wrap in NTuple if we parsed a fixed array size
            if !isnothing(sz)
                T = :(NTuple{$sz,$T})
            end

            # Wrap in Ptr or Ref if we parsed asterisk pointer depth
            if !isnothing(nptr)
                isabs = try
                    isabstracttype(eval(T))
                catch
                    return nothing
                end
                T =
                    isone(i) ? nested_ptr(T, nptr, isabs) : nested_refptr(T, nptr, isabs)
            end

            return T
        end

        c_typemap(iscst, type_name, sz, nptr) = x_typemap(1, iscst, type_name, sz, nptr)
        jl_typemap(iscst, type_name, sz, nptr) =
            x_typemap(2, iscst, type_name, sz, nptr)
        jlret_typemap(iscst, type_name, sz, nptr) =
            x_typemap(3, iscst, type_name, sz, nptr)

        parse_c_type(s) = maybe(x->c_typemap(x...), parse_type(s))
        parse_jl_type(s) = maybe(x->jl_typemap(x...), parse_type(s))
        parse_jlret_type(s) = maybe(x->jlret_typemap(x...), parse_type(s))

        valid_name(s) = (
            m = match(r"^[_a-zA-Z][_a-zA-Z0-9]*$", s);
            isnothing(m) ? nothing : Symbol(s)
        )

        function gen_enum(def)
            name = Symbol(def["name"])
            vcount = length(def["values"])
            iszero(vcount) && return nothing
            values = def["values"]

            values_ex = map(values) do v
                i = v.value
                n = Symbol(v.name)
                isnothing(i) ? :($n) : :($n = $i)
            end
            body = Expr(:block, values_ex...)

            return Expr(:macrocall, Symbol("@cenum"), nothing, name, body)
        end

        function typeassert_expr(name, type)
            return isnothing(type) ? name : Expr(:(::), name, type)
        end

        function gen_struct(def)
            name = def["name"]
            fields = def["fields"]

            fields_ex = map(fields) do f
                T = parse_c_type(f.type)
                vname = valid_name(f.name)
                isnothing(T) || isnothing(vname) ? nothing : typeassert_expr(vname, T)
            end
            any(isnothing, fields_ex) && return nothing

            body = Expr(:block, fields_ex...)
            prefix = startswith(name, "Ray") ? "" : "Ray"
            name_ex = Symbol(prefix * name)

            # Dynamically determine if this struct should be mutable
            is_mutable = name in MUTABLE_TYPES
            struct_expr = Expr(:struct, is_mutable, name_ex, body)

            return Expr(:macrocall, Symbol("@c_struct"), nothing, struct_expr)
        end

        jl_type_handler(_, ex) = ex
        jl_type_handler(x::Symbol, ex) = jl_type_handler(eval(x), ex)
        jl_type_handler(::Type{String}, ex) = :(Base.unsafe_string($ex))

        function func_doc(code, desc)
            code_s = replace(string(code), '\n'=>"\n    ")
            return "    $code_s\n\n$desc"
        end

        function gen_func(def, use_desc = true)
            name = Symbol(def["name"])
            rT = def["returnType"]
            desc = use_desc ? def["description"] : ""
            hasparams = haskey(def, "params")
            params = hasparams ? def["params"] : ()

            c_param_ex = if hasparams
                map(params) do p
                    T = parse_c_type(p.type)
                    vname = valid_name(p.name)
                    if isnothing(T) || isnothing(vname)
                        nothing
                    else
                        val = T === :Cstring ? :(to_cstring($vname)) : vname
                        typeassert_expr(val, T)
                    end
                end
            else
                Expr[]
            end
            c_rT = parse_c_type(rT)

            (any(isnothing, c_param_ex) || isnothing(c_rT)) && return nothing

            jl_param_ex = if hasparams
                map(params) do p
                    if occursin("void *", p.type)
                        T = nothing
                    else
                        T = parse_jl_type(p.type)
                    end
                    typeassert_expr(Symbol(p.name), T)
                end
            else
                Expr[]
            end
            jl_rT = parse_jlret_type(rT)

            c_sig = typeassert_expr(
                Expr(:call, Expr(:., :libraylib, QuoteNode(name)), c_param_ex...),
                c_rT,
            )
            call_ex = Expr(:macrocall, Symbol("@ccall"), nothing, c_sig)

            jl_call = Expr(:call, name, jl_param_ex...)
            jl_sig = isnothing(jl_rT) ? jl_call : typeassert_expr(jl_call, jl_rT)

            func_body = Expr(:return, jl_type_handler(jl_rT, call_ex))
            func_def = Expr(:function, jl_sig, func_body)

            docstring = func_doc(func_def, desc)
            return quote
                Core.@doc $docstring
                $func_def
            end
        end

        function gen(f, lib, s, defs, nf = Symbol, depth = 1)
            type = defs[("$(lowercase(string(s)))s")]
            n_entry = length(type)
            iszero(n_entry) && return nothing

            postpone = nothing
            for d = 1:depth
                entries = isone(d) ? type : postpone
                postpone = []

                for entry in entries
                    name = nf(entry["name"])

                    if isdefined(@__MODULE__, name)
                        @debug "skip duplicate $name from $lib."
                        continue
                    end
                    expr = f(entry)

                    if isnothing(expr)
                        @debug "failed to generate $name $s from $lib. skip $d"

                        if s == :Struct
                            push!(postpone, entry)
                        end
                    else
                        @eval $expr

                        if s == :Struct
                            c_name = entry["name"]
                            if !haskey(typemap_dict, c_name)
                                typemap_dict[c_name] = name
                                @debug "register $c_name => $name"
                            end
                        end
                    end
                end
            end

            return nothing
        end

        return gen_enum, gen_struct, gen_func, gen
    end

    gen_enum, gen_struct, gen_func, gen = builder()

    apis = map(
        f->joinpath(@__DIR__, "../../api_reference/", f),
        ("raylib_api.json", "rlgl_api.json", "raymath_api.json", "raygui_api.json"),
    )

    jsons = Dict(map(apis) do api_file
        api_file=>parse_json(api_file)
    end)


    for api in apis
        json = jsons[api]
        lib = split(basename(api), '_')[1]

        defs = json
        gen(gen_enum, lib, :Enum, defs)


        gen(
            gen_struct,
            lib,
            :Struct,
            defs,
            s -> Symbol(startswith(s, "Ray") ? s : "Ray" * s),
            2,
        )

        if lib == "raylib"
            gen(gen_func, lib, :Function, defs)
        else
            gen(Base.Fix2(gen_func, false), lib, :Function, defs)
        end
    end

end

const RayCamera = RayCamera3D
const RayTexture2D = RayTexture
const RayRenderTexture2D = RayRenderTexture

let allsym = filter(names(@__MODULE__; all = true, imported = true)) do sym
        Base.isidentifier(sym) && sym ∉ (Symbol(@__MODULE__), :include, :eval)
    end
    @eval export $(allsym...)
end

end
