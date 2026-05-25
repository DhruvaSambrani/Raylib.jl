using Raylib
using Raylib: rayvector, RayVector2

function vector2rotate(v, angle)
    x = v[1] * cos(angle) - v[2] * sin(angle)
    y = v[1] * sin(angle) + v[2] * cos(angle)
    return rayvector(x, y)
end

function draw_texture_poly(texture, center, points, texcoords, point_count, tint)
    Raylib.rlSetTexture(texture.id)
    Raylib.rlBegin(0x0004)
    Raylib.rlColor4ub(reinterpret.(UInt8, (tint.r, tint.g, tint.b, tint.alpha))...)

    for i in point_count-1:-1:1
        Raylib.rlTexCoord2f(0.5, 0.5)
        Raylib.rlVertex2f(center.x, center.y)

        Raylib.rlTexCoord2f(texcoords[i]...)
        Raylib.rlVertex2f((points[i] + center)...)

        Raylib.rlTexCoord2f(texcoords[i + 1]...)
        Raylib.rlVertex2f((points[i + 1] + center)...)
    end
    Raylib.rlEnd()
    Raylib.rlSetTexture(0)
end

function main()
    screenWidth = 800
    screenHeight = 450

    MAX_POINTS = 11
    
    Raylib.InitWindow(screenWidth, screenHeight, "raylib [textures] example - textured polygon")

    texcoords = [
        rayvector(0.75, 0.0),
        rayvector(0.25, 0.0),
        rayvector(0.0, 0.5),
        rayvector(0.0, 0.75),
        rayvector(0.25, 1.0),
        rayvector(0.375, 0.875),
        rayvector(0.625, 0.875),
        rayvector(0.75, 1.0),
        rayvector(1.0, 0.75),
        rayvector(1.0, 0.5),
        rayvector(0.75, 0.0),
    ]

    points = Vector{RayVector2}(undef, MAX_POINTS)
    for i = 1:MAX_POINTS
        points[i] = (texcoords[i] .- 0.5f0) .* 256
    end

    positions = copy(points)

    texture = Raylib.LoadTexture(joinpath(@__DIR__, "resources/cat.png"))

    angle = 0.0

    Raylib.SetTargetFPS(60)

    while !Raylib.WindowShouldClose()
        angle+=1
        map!(Base.Fix2(vector2rotate, deg2rad(angle)), positions, points)
        
        Raylib.BeginDrawing()
        Raylib.ClearBackground(Raylib.RAYWHITE)
        Raylib.DrawText("textured polygon", 20, 20, 20, Raylib.DARKGRAY)
        draw_texture_poly(
            texture, rayvector(Raylib.GetScreenWidth()/2, Raylib.GetScreenHeight()/2),
            positions, texcoords, MAX_POINTS, Raylib.WHITE
        )
        Raylib.EndDrawing()
    end

    Raylib.UnloadTexture(texture)
    Raylib.CloseWindow()

end
