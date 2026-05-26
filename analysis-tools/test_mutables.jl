# Standalone test script to verify programmatic MUTABLE_TYPES discovery (v2)
using JSON

maybe(f, x) = f(x)
maybe(f, ::Nothing) = nothing
maybe(f) = Base.Fix1(maybe, f)

function parse_type(type_s)
    m = match(r"(const )?([^\[\*]+)(?:\[(\d+)\])?(\*+)?", type_s)
    isnothing(m) && return nothing

    cst, type_name, arr_sz, stars = map(maybe(strip), m.captures)
    iscst = !isnothing(cst)
    nptr = maybe(length, stars)
    sz = isnothing(arr_sz) ? nothing : parse(Int, arr_sz)

    return iscst, type_name, sz, nptr
end

function run_verification()
    apis = map(
        f -> joinpath(@__DIR__, "../api_reference/", f),
        ("raylib_api.json", "rlgl_api.json", "raymath_api.json", "raygui_api.json")
    )

    println("Loading API JSONs...")
    jsons = Dict()
    for api_file in apis
        if !isfile(api_file)
            error("Could not find file: $api_file")
        end
        jsons[api_file] = JSON.parse(read(api_file, String))
    end
    println("✓ API files successfully loaded.")

    # 1. Collect all valid C struct names and aliases from the JSON files
    struct_names = Set{String}()
    alias_map = Dict{String, String}() # Maps alias -> base struct

    for api in apis
        json = jsons[api]
        if haskey(json, "structs")
            for s in json["structs"]
                push!(struct_names, s["name"])
            end
        end
        if haskey(json, "aliases")
            for a in json["aliases"]
                alias_map[a["name"]] = a["type"]
                # Treat aliases as valid struct names for parameter lookup
                push!(struct_names, a["name"])
            end
        end
    end
    println("✓ Discovered $(length(struct_names)) base structs and aliases in the API schemas.")

    # 2. Scan function parameters for non-const pointers to known structs
    MUTABLE_TYPES = Set{String}()
    mutable_triggers = Dict{String, Vector{String}}()

    for api in apis
        json = jsons[api]
        haskey(json, "functions") || continue
        for f in json["functions"]
            haskey(f, "params") || continue
            for p in f["params"]
                parsed = parse_type(p["type"])
                isnothing(parsed) && continue
                iscst, type_name, sz, nptr = parsed
                
                # If we find a non-const, non-array pointer to a known struct/alias
                if !iscst && !isnothing(nptr) && nptr == 1 && type_name in struct_names
                    push!(MUTABLE_TYPES, type_name)
                    
                    trigger = "$(f["name"])($(p["name"]): $(p["type"]))"
                    push!(get!(mutable_triggers, type_name, String[]), trigger)
                end
            end
        end
    end

    # 3. Propagate mutability from aliases to their underlying base structs
    # (e.g. if "Camera" is mutable, then "Camera3D" must be mutable too)
    for type_name in collect(MUTABLE_TYPES)
        if haskey(alias_map, type_name)
            base_type = alias_map[type_name]
            push!(MUTABLE_TYPES, base_type)
            # Link the triggers for visibility in report
            mutable_triggers[base_type] = get(mutable_triggers, type_name, String[])
        end
    end

    # 4. Strict overrides: Types we absolutely must keep immutable
    # for performance, stack-passing, and StaticArrays integration.
    IMMUTABLE_OVERRIDES = Set([
        "Color", "Vector2", "Vector3", "Vector4", "Quaternion", 
        "Matrix", "Rectangle"
    ])

    setdiff!(MUTABLE_TYPES, IMMUTABLE_OVERRIDES)

    # 5. Print detailed diagnostic report
    println("\n==============================================")
    println("      MUTABLE STRUCT DISCOVERY REPORT         ")
    println("==============================================")
    
    for (struct_name, triggers) in sort(collect(mutable_triggers), by=x->x[1])
        if struct_name in IMMUTABLE_OVERRIDES
            println("• Struct: $struct_name → [OVERRIDDEN TO IMMUTABLE]")
            continue
        end
        println("\n• Struct: $struct_name")
        println("  Detected as MUTABLE because of $(length(triggers)) FFI function(s):")
        for trigger in first(triggers, 3)
            println("    → $trigger")
        end
        if length(triggers) > 3
            println("    ... and $(length(triggers) - 3) more.")
        end
    end
    println("\n==============================================")
    println("Discovered $(length(MUTABLE_TYPES)) programmatically mutable structs.")
    println("Active Mutable Set: ", collect(MUTABLE_TYPES))
    println("==============================================")
end

run_verification()
