using Raylib

function main()

    screenWidth = 800
    screenHeight = 450

    Raylib.InitWindow(screenWidth, screenHeight, "raylib [core] example - gamepad input")

    Raylib.SetTargetFPS(60)

    gamepad = 1

    while !Raylib.WindowShouldClose()

        Raylib.BeginDrawing()

        Raylib.ClearBackground(Raylib.RAYWHITE)

        if Raylib.IsGamepadAvailable(gamepad)

            gamepad_name = unsafe_string(Raylib.GetGamepadName(gamepad))
            Raylib.DrawText("GP1: $(gamepad_name)", 10, 10, 10, Raylib.BLACK)

            Raylib.DrawText("- GENERIC GAMEPAD -", 280, 180, 20, Raylib.GRAY)

            Raylib.DrawText("DETECTED AXIS [$(Raylib.GetGamepadAxisCount(gamepad))]:", 10, 50, 10, Raylib.MAROON)

            for i in 0:Raylib.GetGamepadAxisCount(gamepad)-1
                Raylib.DrawText("AXIS $i: $(Raylib.GetGamepadAxisMovement(gamepad, i))", 20, 70 + 20*i, 10, Raylib.DARKGRAY)
            end

            if Raylib.GetGamepadButtonPressed() != -1
                Raylib.DrawText("DETECTED BUTTON: $(Raylib.GetGamepadButtonPressed())", 10, 430, 10, Raylib.RED)
            else 
                Raylib.DrawText("DETECTED BUTTON: NONE", 10, 430, 10, Raylib.GRAY)
            end
        
        else
            Raylib.DrawText("GP1: NOT DETECTED", 10, 10, 10, Raylib.GRAY)
        end

        Raylib.EndDrawing()

    end

    Raylib.CloseWindow()    

end
