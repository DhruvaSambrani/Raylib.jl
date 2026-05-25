using Raylib

const screenWidth = 800
const screenHeight = 450

const XBOX_ALIAS_1 = "xbox"
const XBOX_ALIAS_2 = "x-box"
const PS_ALIAS_1 = "playstation"
const PS_ALIAS_2 = "sony"

function main()
    gamepad = 0
    Raylib.SetConfigFlags(Raylib.FLAG_MSAA_4X_HINT)
    Raylib.SetConfigFlags(Raylib.FLAG_WINDOW_HIGHDPI)
    Raylib.InitWindow(screenWidth, screenHeight, "Input Gamepad")
    #Raylib.SetGamepadMappings(read("./gamecontrollerdb.txt", String))
    Raylib.SetTargetFPS(120)
    texXboxPad = Raylib.LoadTexture("xbox.png")

    deadzone = 0.1
    trigdeadzone = 1 - deadzone

    rumble_l = 0
    rumble_r = 0
    while !Raylib.WindowShouldClose()
        Raylib.BeginDrawing()
        Raylib.ClearBackground(Raylib.RAYWHITE)
        if (Raylib.IsKeyPressed(Raylib.KEY_LEFT)) && gamepad > 0
            gamepad -= 1
        end
        if Raylib.IsKeyPressed(Raylib.KEY_RIGHT)
            gamepad += 1
        end

        if (Raylib.IsGamepadAvailable(gamepad))
            if Raylib.IsKeyPressed(Raylib.KEY_V)
                rumble_l = (rumble_l + 1)%2 
            end
            if Raylib.IsKeyPressed(Raylib.KEY_B)
                rumble_r = (rumble_r + 1)%2 
            end
            Raylib.DrawText("GP $(gamepad): $(Raylib.GetGamepadName(gamepad))", 10, 10, 10, Raylib.BLACK)

            leftStickX = Raylib.GetGamepadAxisMovement(gamepad, Raylib.GAMEPAD_AXIS_LEFT_X)
            leftStickY = Raylib.GetGamepadAxisMovement(gamepad, Raylib.GAMEPAD_AXIS_LEFT_Y)
            rightStickX = Raylib.GetGamepadAxisMovement(gamepad, Raylib.GAMEPAD_AXIS_RIGHT_X)
            rightStickY = Raylib.GetGamepadAxisMovement(gamepad, Raylib.GAMEPAD_AXIS_RIGHT_Y)
            leftTrigger = Raylib.GetGamepadAxisMovement(gamepad, Raylib.GAMEPAD_AXIS_LEFT_TRIGGER)
            rightTrigger = Raylib.GetGamepadAxisMovement(gamepad, Raylib.GAMEPAD_AXIS_RIGHT_TRIGGER)

            leftStickX = abs(leftStickX) < deadzone ? 0. : leftStickX
            leftStickY = abs(leftStickY) < deadzone ? 0. : leftStickY
            rightStickX = abs(rightStickX) < deadzone ? 0. : rightStickX
            rightStickY = abs(rightStickY) < deadzone ? 0. : rightStickY

            Raylib.SetGamepadVibration(gamepad, rumble_l*leftTrigger, rumble_r*rightTrigger, 1)

            Raylib.DrawTexture(texXboxPad, 0, 0, Raylib.DARKGRAY)
            # Draw buttons: xbox home
            if (Raylib.IsGamepadButtonDown(gamepad, Raylib.GAMEPAD_BUTTON_MIDDLE))
                Raylib.DrawCircle(394, 89, 19, Raylib.RED)
            end

            #Raylib.Draw buttons: basic
            if (Raylib.IsGamepadButtonDown(gamepad, Raylib.GAMEPAD_BUTTON_MIDDLE_RIGHT))
                Raylib.DrawCircle(436, 150, 9, Raylib.RED)
            end
            if (Raylib.IsGamepadButtonDown(gamepad, Raylib.GAMEPAD_BUTTON_MIDDLE_LEFT))
                Raylib.DrawCircle(352, 150, 9, Raylib.RED)
            end
            if (Raylib.IsGamepadButtonDown(gamepad, Raylib.GAMEPAD_BUTTON_RIGHT_FACE_LEFT))
                Raylib.DrawCircle(501, 151, 15, Raylib.BLUE)
            end
            if (Raylib.IsGamepadButtonDown(gamepad, Raylib.GAMEPAD_BUTTON_RIGHT_FACE_DOWN))
                Raylib.DrawCircle(536, 187, 15, Raylib.LIME)
            end
            if (Raylib.IsGamepadButtonDown(gamepad, Raylib.GAMEPAD_BUTTON_RIGHT_FACE_RIGHT))
                Raylib.DrawCircle(572, 151, 15, Raylib.MAROON)
            end
            if (Raylib.IsGamepadButtonDown(gamepad, Raylib.GAMEPAD_BUTTON_RIGHT_FACE_UP))
                Raylib.DrawCircle(536, 115, 15, Raylib.GOLD)
            end

            # Draw buttons: d-pad
            Raylib.DrawRectangle(317, 202, 19, 71, Raylib.BLACK)
            Raylib.DrawRectangle(293, 228, 69, 19, Raylib.BLACK)
            if (Raylib.IsGamepadButtonDown(gamepad, Raylib.GAMEPAD_BUTTON_LEFT_FACE_UP))
                Raylib.DrawRectangle(317, 202, 19, 26, Raylib.RED)
            end
            if (Raylib.IsGamepadButtonDown(gamepad, Raylib.GAMEPAD_BUTTON_LEFT_FACE_DOWN))
                Raylib.DrawRectangle(317, 202 + 45, 19, 26, Raylib.RED)
            end
            if (Raylib.IsGamepadButtonDown(gamepad, Raylib.GAMEPAD_BUTTON_LEFT_FACE_LEFT))
                Raylib.DrawRectangle(292, 228, 25, 19, Raylib.RED)
            end
            if (Raylib.IsGamepadButtonDown(gamepad, Raylib.GAMEPAD_BUTTON_LEFT_FACE_RIGHT))
                Raylib.DrawRectangle(292 + 44, 228, 26, 19, Raylib.RED)
            end

            # Draw buttons: left-right back
            if (Raylib.IsGamepadButtonDown(gamepad, Raylib.GAMEPAD_BUTTON_LEFT_TRIGGER_1))
                Raylib.DrawCircle(259, 61, 20, Raylib.RED)
            end
            if (Raylib.IsGamepadButtonDown(gamepad, Raylib.GAMEPAD_BUTTON_RIGHT_TRIGGER_1))
                Raylib.DrawCircle(536, 61, 20, Raylib.RED)
            end

            # Draw axis: left joystick
            leftGamepadColor = Raylib.BLACK
            if (Raylib.IsGamepadButtonDown(gamepad, Raylib.GAMEPAD_BUTTON_LEFT_THUMB))
                leftGamepadColor = Raylib.RED
            end
            Raylib.DrawCircle(259, 152, 39, Raylib.BLACK)
            Raylib.DrawCircle(259, 152, 34, Raylib.LIGHTGRAY)
            Raylib.DrawCircle(259 + round(Int, leftStickX * 20),
                152 + round(Int, leftStickY * 20), 25, leftGamepadColor)

            # Raylib.Draw axis: right joystick
            rightGamepadColor = Raylib.BLACK
            if (Raylib.IsGamepadButtonDown(gamepad, Raylib.GAMEPAD_BUTTON_RIGHT_THUMB))
                rightGamepadColor = Raylib.RED
            end
            Raylib.DrawCircle(461, 237, 38, Raylib.BLACK)
            Raylib.DrawCircle(461, 237, 33, Raylib.LIGHTGRAY)
            Raylib.DrawCircle(461 + round(Int, rightStickX * 20),
                237 + round(Int, rightStickY * 20), 25, rightGamepadColor)

            # Raylib.Draw axis: left-right triggers
            Raylib.DrawRectangle(170, 30, 15, 70, Raylib.GRAY)
            Raylib.DrawRectangle(604, 30, 15, 70, Raylib.GRAY)
            Raylib.DrawRectangle(170, 30, 15, round(Int, ((1 + leftTrigger) / 2) * 70), Raylib.RED)
            Raylib.DrawRectangle(604, 30, 15, round(Int, ((1 + rightTrigger) / 2) * 70), Raylib.RED)
            if (Raylib.GetGamepadButtonPressed() != Raylib.GAMEPAD_BUTTON_UNKNOWN)
                Raylib.DrawText("DETECTED BUTTON: $(Raylib.GetGamepadButtonPressed())", 10, 430, 10, Raylib.RED)
            end
        else
            Raylib.DrawText("GP: $(gamepad) Not Found", 10, 10, 10, Raylib.GRAY)
        end
        Raylib.EndDrawing()
    end
    Raylib.CloseWindow()
end
