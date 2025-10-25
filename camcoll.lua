-- Startup delay (seconds). Set to 0 to disable.
local STARTUP_DELAY = 3
if STARTUP_DELAY > 0 then
    if task and task.wait then
        task.wait(STARTUP_DELAY)
    else
        wait(STARTUP_DELAY)
    end
end


local Players = game:GetService('Players')
local RunService = game:GetService('RunService')
local LocalPlayer = Players.LocalPlayer

local UserInputService = game:GetService('UserInputService')

local screenGui = Instance.new('ScreenGui')
screenGui.Name = 'CameraToggleGui'
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = LocalPlayer:WaitForChild('PlayerGui')

local mainFrame = Instance.new('Frame')
mainFrame.Size = UDim2.new(0, 120, 0, 35)
-- Default on-screen position. Change this to move where the UI appears by default.
-- Examples:
--  - Top-left:  UDim2.new(0, 30, 0, 80)
--  - Center:    UDim2.new(0.5, -60, 0.5, -17)
--  - Top-right: UDim2.new(1, -150, 0, 80)
local defaultPosition = UDim2.new(0.78, -115, 0.78, -490)
mainFrame.Position = defaultPosition
mainFrame.BackgroundTransparency = 1
mainFrame.Active = true
mainFrame.Parent = screenGui

local button = Instance.new('TextButton')
button.Size = UDim2.new(1, 0, 1, 0)
button.Position = UDim2.new(0, 0, 0, 0)
button.BackgroundColor3 = Color3.fromRGB(20, 20, 20) -- dark background
button.Text = 'Cam Collision'
button.Font = Enum.Font.GothamBold
button.TextSize = 16
button.TextColor3 = Color3.fromRGB(255, 255, 255) -- will be overwritten by rainbow
button.AutoButtonColor = false
button.Parent = mainFrame

local corner = Instance.new('UICorner')
corner.CornerRadius = UDim.new(0, 8) -- less rounded, more rectangular
corner.Parent = button

local stroke = Instance.new('UIStroke')
stroke.Thickness = 2
stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
stroke.Parent = button

-- Inner rounded rectangle (inset) with its own border
local innerRect = Instance.new('Frame')
innerRect.Size = UDim2.new(0.9, 0, 0.62, 0)
innerRect.Position = UDim2.new(0.05, 0, 0.19, 0)
innerRect.BackgroundTransparency = 1 -- container for inner fill + stroke
innerRect.Parent = button
-- Keep innerRect behind the button so the button text remains visible
-- Keep innerRect at button layer so its stroke shows; label will sit above it
innerRect.ZIndex = button.ZIndex
local innerCorner = Instance.new('UICorner')
innerCorner.CornerRadius = UDim.new(0, 6)
innerCorner.Parent = innerRect
local innerStroke = Instance.new('UIStroke')
innerStroke.Thickness = 1
innerStroke.Transparency = 0.78 -- make the inner stroke faint
innerStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
innerStroke.Parent = innerRect

-- Inner filled rounded rect (dark center) so the stroke appears as a colored outline
-- subtle inner shadow (offset, semi-transparent) to simulate a soft border
local innerShadow = Instance.new('Frame')
innerShadow.Size = UDim2.new(1, -8, 1, -8)
innerShadow.Position = UDim2.new(0, 6, 0, 6)
innerShadow.BackgroundColor3 = Color3.fromRGB(32, 31, 19)
innerShadow.BackgroundTransparency = 0.2
innerShadow.Parent = innerRect
local innerShadowCorner = Instance.new('UICorner')
innerShadowCorner.CornerRadius = UDim.new(0, 4)
innerShadowCorner.Parent = innerShadow
innerShadow.ZIndex = innerRect.ZIndex

local innerFill = Instance.new('Frame')
innerFill.Size = UDim2.new(1, -8, 1, -8)
innerFill.Position = UDim2.new(0, 4, 0, 4)
innerFill.BackgroundColor3 = Color3.fromRGB(28, 30, 38) -- center color
innerFill.BackgroundTransparency = 0
innerFill.Visible = true
innerFill.Parent = innerRect
local innerFillCorner = Instance.new('UICorner')
innerFillCorner.CornerRadius = UDim.new(0, 4)
innerFillCorner.Parent = innerFill
-- Ensure the inner fill sits above the subtle shadow but behind the label
innerFill.ZIndex = innerRect.ZIndex + 1

-- Create the visible label inside the inner fill (so text sits inside the white frame)
local label = Instance.new('TextLabel')
label.Size = UDim2.new(1, 0, 1, 0)
label.Position = UDim2.new(0, 0, 0, 0)
label.BackgroundTransparency = 1
label.Font = button.Font
label.Text = button.Text
label.TextSize = button.TextSize
label.TextColor3 = Color3.fromRGB(0, 0, 0) -- dark text to contrast white fill
label.TextXAlignment = Enum.TextXAlignment.Center
label.TextYAlignment = Enum.TextYAlignment.Center
label.Parent = innerFill
label.ZIndex = innerFill.ZIndex + 2

-- Hide the default button text (we keep the button for input/drags)
button.TextTransparency = 1

-- Text shadow glow effect (using TextLabel behind the button)
-- Multi-layer text shadow / glow (three labels behind the button text)
local function makeShadow(offsetX, offsetY, transparency)
    local s = Instance.new('TextLabel')
    s.Size = UDim2.new(1, 0, 1, 0)
    s.Position = UDim2.new(0, offsetX, 0, offsetY)
    s.BackgroundTransparency = 1
    s.Font = button.Font
    s.Text = button.Text
    s.TextSize = button.TextSize
    s.TextColor3 = Color3.fromRGB(255, 255, 255)
    s.TextTransparency = transparency
    s.Parent = innerFill
    s.ZIndex = label.ZIndex - 1
    s.TextXAlignment = Enum.TextXAlignment.Center
    s.TextYAlignment = Enum.TextYAlignment.Center
    return s
end

local shadowLabel1 = makeShadow(1, 1, 0.7)
local shadowLabel2 = makeShadow(0, 2, 0.88)
local shadowLabel3 = makeShadow(-1, 1, 0.92)

button:GetPropertyChangedSignal('Text'):Connect(function()
    shadowLabel1.Text = button.Text
    shadowLabel2.Text = button.Text
    shadowLabel3.Text = button.Text
    label.Text = button.Text
end)

-- Rainbow color cycling on border and text (including shadow)
local hue = 0
-- framerate-independent rainbow cycle (slow)
RunService.RenderStepped:Connect(function(dt)
    hue = (hue + dt * 60) % 360 -- 60 degrees per second
    local rainbowColor = Color3.fromHSV(hue / 360, 1, 1)
    -- Color the visible label and shadows
    label.TextColor3 = rainbowColor
    stroke.Color = rainbowColor
    shadowLabel1.TextColor3 = rainbowColor
    shadowLabel2.TextColor3 = rainbowColor
    shadowLabel3.TextColor3 = rainbowColor
    innerStroke.Color = rainbowColor
end)

-- Dragging logic
local dragging = false
local dragStart, startPos

local function updateDrag(input)
    local delta = input.Position - dragStart
    -- Preserve the original scale components so elements with non-zero scale
    -- (like defaultPosition) don't get forced to scale 0 and disappear.
    mainFrame.Position = UDim2.new(
        startPos.X.Scale,
        startPos.X.Offset + delta.X,
        startPos.Y.Scale,
        startPos.Y.Offset + delta.Y
    )
end

button.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = mainFrame.Position

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        updateDrag(input)
    end
end)

-- Press R to reset the UI to the default position
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then
        return
    end
    if
        input.UserInputType == Enum.UserInputType.Keyboard
        and input.KeyCode == Enum.KeyCode.R
    then
        mainFrame.Position = defaultPosition
    end
end)

-- Camera toggle logic: start disabled by default
local cameraCollisionDisabled = true

local function updateCameraMode()
    if cameraCollisionDisabled then
        LocalPlayer.DevCameraOcclusionMode = Enum.DevCameraOcclusionMode.Zoom
        button.Text = 'Cam: Off'
    else
        LocalPlayer.DevCameraOcclusionMode = Enum.DevCameraOcclusionMode.Invisicam
        button.Text = 'Cam: On'
    end
end

button.MouseButton1Click:Connect(function()
    cameraCollisionDisabled = not cameraCollisionDisabled
    updateCameraMode()
end)

-- Initial camera setup
LocalPlayer.CameraMode = Enum.CameraMode.Classic
LocalPlayer.DevComputerCameraMode = Enum.DevComputerCameraMovement.UserChoice
LocalPlayer.DevTouchCameraMode = Enum.DevTouchCameraMovement.UserChoice
updateCameraMode()
