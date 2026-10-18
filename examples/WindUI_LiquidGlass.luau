--[[
    WindUI + Authentic macOS Liquid Glass (Jelly Physics & Full Translucency)
    ========================================================================
    Features:
    - 100% Unified Translucent Liquid Glass across the entire window body.
    - Enlarged corner refractions capturing a broader, more dramatic lens area.
    - Elastic Jelly Wobble Animation (потряхивание типа желе):
      * Triggered when expanding/resizing the window or on button press.
      * Real-time 2D/3D squash and stretch with spring physics.
      * Refraction and blur oscillate in sync with the gelatinous motion.
    - Neutralized map global blur (100% razor-sharp 3D world).
    - Native WindUI Controls (Sliders, Toggles, Buttons).
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- 1. CLEANUP PREVIOUS INSTANCES
local function cleanup()
    local hui = (gethui and gethui()) or game:GetService("CoreGui")
    for _, name in ipairs({"WindUI", "Cascade", "IdealLiquidStudio", "CascadeTest", "FrostGUI"}) do
        local g = hui:FindFirstChild(name)
        if g then g:Destroy() end
        local pg = LocalPlayer.PlayerGui:FindFirstChild(name)
        if pg then pg:Destroy() end
    end
    for _, name in ipairs({"LiquidGlassObjects", "LiquidRimModel", "Cascade_Liquid_Root", "LiquidGlass_WindUI"}) do
        local f = Camera:FindFirstChild(name)
        if f then f:Destroy() end
        local wf = Workspace:FindFirstChild(name)
        if wf then wf:Destroy() end
    end
    for _, ch in ipairs(Lighting:GetChildren()) do
        if ch:IsA("DepthOfFieldEffect") and (ch.Name:find("Liquid") or ch.Name:find("Frost") or ch.Name:find("DOF")) then
            ch:Destroy()
        end
    end
end
cleanup()

-- 2. ASSETS
local lghAsset = ReplicatedStorage:FindFirstChild("LiquidGlassHandler")
if not lghAsset then
    local loaded = game:GetObjects("rbxassetid://78675735649311")[1]
    loaded.Name = "LiquidGlassHandler"
    loaded.Parent = ReplicatedStorage
    lghAsset = loaded
end
local templateContainer = lghAsset.Overlay

-- 3. JELLY SPRING ENGINE
local Spring = {}
Spring.__index = Spring

function Spring.new(mass, force, damping, speed)
    return setmetatable({
        Target = 1,
        Position = 1,
        Velocity = 0,
        Mass = mass or 1,
        Force = force or 28,
        Damping = damping or 3.8,
        Speed = speed or 1,
    }, Spring)
end

function Spring:Update(dt)
    local scaledDt = math.min(dt, 0.05) * self.Speed
    local d = self.Target - self.Position
    local f = d * self.Force
    local a = (f - self.Velocity * self.Damping) / self.Mass
    self.Velocity = self.Velocity + a * scaledDt
    self.Position = self.Position + self.Velocity * scaledDt
    return self.Position
end

function Spring:Impulse(velocity)
    self.Velocity = self.Velocity + velocity
end

function Spring:Reset(pos)
    self.Position = pos or 1
    self.Velocity = 0
    self.Target = pos or 1
end

local jellySpringX = Spring.new(1, 26, 3.4, 1.2)
local jellySpringY = Spring.new(1, 26, 3.4, 1.2)

-- 4. CONFIGURATION PRESET
local Settings = {
    CornerRefraction = 3.8,       -- Optical lens refraction intensity on corners
    CornerRadius = 32,           -- Enlarged corner radius for broader lens area
    CornerScaleMultiplier = 1.25, -- Broader corner lens capture area
    EdgeRefraction = 2.9,        -- Linear edges refraction
    HighlightBoost = 0.98,       -- Specular rim transparency
    FrostBlur = 0.85,            -- Local DepthOfField frosted glass blur
    WindowTransparency = 0.38,   -- Unified translucent obsidian dark glass
    BlurKernelInset = 36,        -- Inset in pixels to eliminate blur bleed
    Enabled = true,
    BaseWidth = 750,
    BaseHeight = 520,
    Expanded = false,
}

-- 5. NEUTRALIZE GAME GLOBAL BLUR
for _, ch in ipairs(Lighting:GetChildren()) do
    if ch:IsA("DepthOfFieldEffect") and ch.Name ~= "WindUI_LiquidFrostDOF" then
        ch.FarIntensity = 0
    elseif ch:IsA("BlurEffect") and (ch.Name == "Blur" or ch.Name == "DefaultBlur") then
        ch.Enabled = false
    end
end

local dof = Instance.new("DepthOfFieldEffect")
dof.Name = "WindUI_LiquidFrostDOF"
dof.FarIntensity = 0        -- Screen safety: 3D world is NEVER blurred outside window
dof.FocusDistance = 0.15    -- Isolated near camera plane
dof.InFocusRadius = 0
dof.NearIntensity = Settings.FrostBlur
dof.Parent = Lighting

-- 6. INITIALIZE WINDUI
local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()

local Window = WindUI:CreateWindow({
    Title = "WindUI • Liquid Glass (Jelly Edition)",
    Folder = "WindUILiquid",
    NewElements = true,
    Size = UDim2.fromOffset(Settings.BaseWidth, Settings.BaseHeight),
    Transparent = true,
    Topbar = {
        Height = 44,
        ButtonsType = "Mac",
    },
})

local screenGui = WindUI.ScreenGui
if screenGui then
    screenGui.ResetOnSpawn = false
end

local windowFrame = Window.UIElements and Window.UIElements.Main or screenGui.Window.Frame
windowFrame.Visible = true
local mainFrame = windowFrame:FindFirstChild("Main") or windowFrame

task.wait(0.15)

-- 7. 100% UNIFIED TRANSLUCENT OBSIDIAN GLASS
local UNIFIED_COLOR = Color3.fromRGB(14, 17, 24)

local function applyWindUIGlass()
    windowFrame.Visible = true

    -- Hide opaque 9-slice textures in windowFrame and all descendants
    for _, desc in ipairs(windowFrame:GetDescendants()) do
        if desc:IsA("ImageLabel") and (desc.Name == "Background" or desc.Name == "Blur") then
            desc.ImageTransparency = 1
        end
    end

    -- Use WindowFrame directly as the single unified glass surface
    windowFrame.BackgroundColor3 = UNIFIED_COLOR
    windowFrame.BackgroundTransparency = Settings.WindowTransparency

    -- Corners
    local frameCorner = windowFrame:FindFirstChildOfClass("UICorner")
    if frameCorner then
        frameCorner.CornerRadius = UDim.new(0, Settings.CornerRadius)
    end
    if mainFrame then
        local mainCorner = mainFrame:FindFirstChildOfClass("UICorner")
        if mainCorner then
            mainCorner.CornerRadius = UDim.new(0, Settings.CornerRadius)
        end
    end

    -- 1px Apple border stroke
    local borderStroke = windowFrame:FindFirstChild("LiquidGlassStroke") or Instance.new("UIStroke")
    borderStroke.Name = "LiquidGlassStroke"
    borderStroke.Color = Color3.fromRGB(255, 255, 255)
    borderStroke.Transparency = 0.82
    borderStroke.Thickness = 1.2
    borderStroke.Parent = windowFrame

    -- Inner containers transparent so the frosted glass is seamless
    for _, desc in ipairs(windowFrame:GetDescendants()) do
        if desc:IsA("GuiObject") and desc ~= windowFrame then
            if desc.Name == "Topbar" or desc.Name == "Main" or desc.Name == "Frame" then
                if desc.Parent == mainFrame or desc == mainFrame then
                    desc.BackgroundTransparency = 1
                end
            end
        end
    end
end
applyWindUIGlass()

-- Re-apply on descendant additions to keep glass 100% unified
windowFrame.DescendantAdded:Connect(function()
    task.defer(applyWindUIGlass)
end)

-- 8. 3D REFRACTION MESHES
local parentFolder = Instance.new("Folder")
parentFolder.Name = "LiquidGlass_WindUI"
parentFolder.Parent = Camera

local rimModel = Instance.new("Model")
rimModel.Name = "LiquidRimModel"
rimModel.Parent = parentFolder

local highlight = Instance.new("Highlight")
highlight.Name = "LiquidHighlight"
highlight.FillColor = Color3.fromRGB(0, 0, 0)
highlight.FillTransparency = Settings.HighlightBoost
highlight.OutlineTransparency = 1
highlight.Parent = rimModel

local centerFrostPart = Instance.new("Part")
centerFrostPart.Name = "CenterFrostPlane"
centerFrostPart.Material = Enum.Material.Glass
centerFrostPart.Color = Color3.fromRGB(240, 248, 255)
centerFrostPart.Transparency = 0.98
centerFrostPart.Reflectance = 0
centerFrostPart.CastShadow = false
centerFrostPart.CanCollide = false
centerFrostPart.CanTouch = false
centerFrostPart.CanQuery = false
centerFrostPart.Anchored = true
centerFrostPart.Parent = parentFolder

local DEPTH = 0.05
local rotationOffset = CFrame.Angles(0, math.rad(-90), 0)

local function makeRimPart(templateName, swapAxes, localRot)
    local p = templateContainer:FindFirstChild(templateName):Clone()
    p.Material = Enum.Material.Glass
    p.Color = Color3.fromRGB(0, 0, 0)
    p.Transparency = Settings.EdgeRefraction
    p.CastShadow = false
    p.CanCollide = false
    p.CanQuery = false
    p.CanTouch = false
    p.Anchored = true
    p.Parent = rimModel
    return {
        Part = p,
        SwapAxes = swapAxes,
        LocalRot = localRot or CFrame.identity,
    }
end

local edgeTop = makeRimPart("Edge", false, CFrame.Angles(0, 0, 0))
local edgeBottom = makeRimPart("Edge", false, CFrame.Angles(0, 0, math.rad(180)))
local edgeLeft = makeRimPart("Edge", true, CFrame.Angles(0, 0, math.rad(90)))
local edgeRight = makeRimPart("Edge", true, CFrame.Angles(0, 0, math.rad(-90)))

local cornerTL = makeRimPart("Corner", true, CFrame.Angles(0, 0, math.rad(90)))
local cornerTR = makeRimPart("Corner", false, CFrame.Angles(0, 0, 0))
local cornerBL = makeRimPart("Corner", false, CFrame.Angles(0, 0, math.rad(180)))
local cornerBR = makeRimPart("Corner", true, CFrame.Angles(0, 0, math.rad(-90)))

local function getPlanePos(pixelX, pixelY)
    local ray = Camera:ScreenPointToRay(pixelX, pixelY)
    local camCF = Camera:GetRenderCFrame()
    local dist = DEPTH / ray.Direction:Dot(camCF.LookVector)
    return ray.Origin + ray.Direction * dist
end

-- 9. JELLY PHYSICS & RESIZE INTERACTION
local UserInputService = game:GetService("UserInputService")
local isUserResizing = false
local isJellyWobbling = false

local function triggerJellyWobble(strengthX, strengthY)
    if isUserResizing then return end
    isJellyWobbling = true
    jellySpringX:Impulse((strengthX or 18) / 100)
    jellySpringY:Impulse((strengthY or -14) / 100)
end

-- Function to animate window resize with Jelly Elasticity
local function setWindowSizeJelly(targetW, targetH)
    Settings.BaseWidth = targetW
    Settings.BaseHeight = targetH
    triggerJellyWobble(22, -18)
end

-- Allow seamless interactive manual resize by user
windowFrame:GetPropertyChangedSignal("Size"):Connect(function()
    if not isJellyWobbling then
        Settings.BaseWidth = windowFrame.Size.X.Offset
        Settings.BaseHeight = windowFrame.Size.Y.Offset
    end
end)

-- Detect when user drags the WindUI resize grip in the corner
task.spawn(function()
    local bg = windowFrame:WaitForChild("Background", 5)
    local resizer = bg and bg:WaitForChild("Frame", 5)
    if resizer then
        resizer.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                isUserResizing = true
                isJellyWobbling = false
                jellySpringX:Reset(1)
                jellySpringY:Reset(1)
            end
        end)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) and isUserResizing then
        isUserResizing = false
        Settings.BaseWidth = windowFrame.Size.X.Offset
        Settings.BaseHeight = windowFrame.Size.Y.Offset
        -- Satisfying jelly bounce upon releasing resize handle!
        triggerJellyWobble(16, -14)
    end
end)

-- 10. RENDER LOOP WITH REAL-TIME JELLY PHYSICS
local function updateLiquidGlass(dt)
    -- Jelly spring oscillation
    if isJellyWobbling and not isUserResizing then
        local wobbleX = jellySpringX:Update(dt or 0.016)
        local wobbleY = jellySpringY:Update(dt or 0.016)

        if math.abs(wobbleX - 1) < 0.002 and math.abs(jellySpringX.Velocity) < 0.03
            and math.abs(wobbleY - 1) < 0.002 and math.abs(jellySpringY.Velocity) < 0.03 then
            isJellyWobbling = false
            jellySpringX:Reset(1)
            jellySpringY:Reset(1)
            windowFrame.Size = UDim2.fromOffset(Settings.BaseWidth, Settings.BaseHeight)
        else
            local currentW = math.floor(Settings.BaseWidth * wobbleX)
            local currentH = math.floor(Settings.BaseHeight * wobbleY)
            windowFrame.Size = UDim2.fromOffset(currentW, currentH)
        end
    end

    local size = windowFrame.AbsoluteSize
    local pos = windowFrame.AbsolutePosition

    local isMinimized = (Window.Closed == true)
        or (not Settings.Enabled)
        or (not windowFrame or not windowFrame.Parent)
        or (size.X < 80 or size.Y < 80)

    if isMinimized then
        rimModel.Parent = nil
        centerFrostPart.Transparency = 1
        dof.NearIntensity = 0
        return
    else
        if rimModel.Parent ~= parentFolder then rimModel.Parent = parentFolder end
        centerFrostPart.Transparency = (Settings.FrostBlur > 0.02) and 0.98 or 1.0
        dof.NearIntensity = Settings.FrostBlur
    end

    local rad = math.clamp(Settings.CornerRadius, 6, math.min(size.X, size.Y) / 2)
    local frameCorner = windowFrame:FindFirstChildOfClass("UICorner")
    if frameCorner and frameCorner.CornerRadius.Offset ~= rad then
        frameCorner.CornerRadius = UDim.new(0, rad)
    end
    if mainFrame then
        local mainCorner = mainFrame:FindFirstChildOfClass("UICorner")
        if mainCorner and mainCorner.CornerRadius.Offset ~= rad then
            mainCorner.CornerRadius = UDim.new(0, rad)
        end
    end

    local camCF = Camera:GetRenderCFrame()
    local guiRotCF = CFrame.Angles(0, 0, math.rad(-windowFrame.AbsoluteRotation))

    local centerScreenPos = pos + (size / 2)
    local centerWorldPos = getPlanePos(centerScreenPos.X, centerScreenPos.Y)
    local rightEdge = getPlanePos(centerScreenPos.X + (size.X / 2), centerScreenPos.Y)
    local leftEdge = getPlanePos(centerScreenPos.X - (size.X / 2), centerScreenPos.Y)
    local topEdge = getPlanePos(centerScreenPos.X, centerScreenPos.Y - (size.Y / 2))
    local bottomEdge = getPlanePos(centerScreenPos.X, centerScreenPos.Y + (size.Y / 2))

    local worldW = (rightEdge - leftEdge).Magnitude
    local worldH = (topEdge - bottomEdge).Magnitude

    local relRadX = rad / size.X
    local relRadY = rad / size.Y
    local innerW = math.max(0.0001, (size.X - 2 * rad) / size.X)
    local innerH = math.max(0.0001, (size.Y - 2 * rad) / size.Y)

    -- Broader corner lens dimensions: captures a larger, more dramatic corner area
    local diamX = relRadX * Settings.CornerScaleMultiplier
    local diamY = relRadY * Settings.CornerScaleMultiplier
    local halfDiamX = diamX / 2
    local halfDiamY = diamY / 2

    cornerTL.Part.Transparency = Settings.CornerRefraction
    cornerTR.Part.Transparency = Settings.CornerRefraction
    cornerBL.Part.Transparency = Settings.CornerRefraction
    cornerBR.Part.Transparency = Settings.CornerRefraction

    edgeTop.Part.Transparency = Settings.EdgeRefraction
    edgeBottom.Part.Transparency = Settings.EdgeRefraction
    edgeLeft.Part.Transparency = Settings.EdgeRefraction
    edgeRight.Part.Transparency = Settings.EdgeRefraction

    highlight.FillTransparency = Settings.HighlightBoost

    local function positionEdge(item, relX, relY, relSizeX, relSizeY)
        local localOffset = Vector3.new(relX * worldW, -relY * worldH, 0)
        local rotatedOffset = guiRotCF * localOffset
        local worldOffset = (camCF.RightVector * rotatedOffset.X) + (camCF.UpVector * rotatedOffset.Y)

        if item.SwapAxes then
            item.Part.Size = Vector3.new(0.001, relSizeX * worldW, relSizeY * worldH)
        else
            item.Part.Size = Vector3.new(0.001, relSizeY * worldH, relSizeX * worldW)
        end
        item.Part.CFrame = CFrame.new(centerWorldPos + worldOffset) * camCF.Rotation * guiRotCF * item.LocalRot * rotationOffset
    end

    local function positionCorner(item, relX, relY)
        local localOffset = Vector3.new(relX * worldW, -relY * worldH, 0)
        local rotatedOffset = guiRotCF * localOffset
        local worldOffset = (camCF.RightVector * rotatedOffset.X) + (camCF.UpVector * rotatedOffset.Y)

        if item.SwapAxes then
            item.Part.Size = Vector3.new(0.001, diamX * worldW, diamY * worldH)
        else
            item.Part.Size = Vector3.new(0.001, diamY * worldH, diamX * worldW)
        end
        item.Part.CFrame = CFrame.new(centerWorldPos + worldOffset) * camCF.Rotation * guiRotCF * item.LocalRot * rotationOffset
    end

    positionEdge(edgeTop, 0, -0.5 + (relRadY / 2), innerW, relRadY)
    positionEdge(edgeBottom, 0, 0.5 - (relRadY / 2), innerW, relRadY)
    positionEdge(edgeLeft, -0.5 + (relRadX / 2), 0, relRadX, innerH)
    positionEdge(edgeRight, 0.5 - (relRadX / 2), 0, relRadX, innerH)

    positionCorner(cornerTL, -0.5 + halfDiamX, -0.5 + halfDiamY)
    positionCorner(cornerTR, 0.5 - halfDiamX, -0.5 + halfDiamY)
    positionCorner(cornerBL, -0.5 + halfDiamX, 0.5 - halfDiamY)
    positionCorner(cornerBR, 0.5 - halfDiamX, 0.5 - halfDiamY)

    -- Center Frost plane matches dynamic jelly size with blur kernel inset
    local insetPixels = Settings.BlurKernelInset
    local frostW = math.max(0.001, (size.X - insetPixels) / size.X * worldW)
    local frostH = math.max(0.001, (size.Y - insetPixels) / size.Y * worldH)
    centerFrostPart.Size = Vector3.new(frostW, frostH, 0.001)
    centerFrostPart.CFrame = CFrame.new(centerWorldPos) * camCF.Rotation * guiRotCF
end

local renderConn = RunService.RenderStepped:Connect(updateLiquidGlass)

windowFrame.Destroying:Connect(function()
    if renderConn then renderConn:Disconnect() end
    dof:Destroy()
    rimModel:Destroy()
    centerFrostPart:Destroy()
end)

-- 11. WINDUI TABS & CONTROLS
local LiquidSection = Window:Section({
    Title = "Liquid Glass",
})

local tabRefraction = LiquidSection:Tab({
    Title = "Refraction",
    Icon = "solar:slider-horizontal-3-bold",
})

local tabJelly = LiquidSection:Tab({
    Title = "Jelly Physics",
    Icon = "solar:box-minimalistic-bold",
})

local tabParameters = LiquidSection:Tab({
    Title = "Parameters",
    Icon = "solar:settings-bold",
})

-- TAB 1: Refraction Controls
do
    tabRefraction:Slider({
        Title = "Corner Refraction",
        Desc = "Optical lens distortion intensity on corners",
        Step = 0.1,
        Value = {
            Min = 0.5,
            Max = 6.0,
            Default = Settings.CornerRefraction,
        },
        Callback = function(val)
            Settings.CornerRefraction = tonumber(string.format("%.2f", val))
        end,
    })

    tabRefraction:Slider({
        Title = "Corner Radius",
        Desc = "Curvature radius of corners (px)",
        Step = 1,
        Value = {
            Min = 16,
            Max = 60,
            Default = Settings.CornerRadius,
        },
        Callback = function(val)
            Settings.CornerRadius = math.floor(val)
            applyWindUIGlass()
        end,
    })

    tabRefraction:Slider({
        Title = "Corner Lens Coverage Area",
        Desc = "Expands the lens area captured by the corner refraction",
        Step = 0.05,
        Value = {
            Min = 0.8,
            Max = 2.0,
            Default = Settings.CornerScaleMultiplier,
        },
        Callback = function(val)
            Settings.CornerScaleMultiplier = tonumber(string.format("%.2f", val))
        end,
    })

    tabRefraction:Slider({
        Title = "Frost Blur",
        Desc = "Isolated DepthOfField under window only",
        Step = 0.05,
        Value = {
            Min = 0.0,
            Max = 1.0,
            Default = Settings.FrostBlur,
        },
        Callback = function(val)
            Settings.FrostBlur = tonumber(string.format("%.2f", val))
        end,
    })

    tabRefraction:Slider({
        Title = "Edge Refraction",
        Desc = "Refraction along linear borders",
        Step = 0.1,
        Value = {
            Min = 0.5,
            Max = 5.0,
            Default = Settings.EdgeRefraction,
        },
        Callback = function(val)
            Settings.EdgeRefraction = tonumber(string.format("%.2f", val))
        end,
    })

    tabRefraction:Toggle({
        Title = "Liquid Glass Effect",
        Desc = "Toggle 3D physical refraction meshes and frosted glass blur",
        Value = Settings.Enabled,
        Callback = function(val)
            Settings.Enabled = val
        end,
    })
end

-- TAB 2: Jelly Physics & Window Resize Animation
do
    tabJelly:Button({
        Title = "Toggle Window Size (with Jelly Animation)",
        Desc = "Expands / shrinks window with elastic rubber-band wobble",
        Callback = function()
            Settings.Expanded = not Settings.Expanded
            if Settings.Expanded then
                setWindowSizeJelly(860, 580)
            else
                setWindowSizeJelly(720, 500)
            end
        end,
    })

    tabJelly:Button({
        Title = "Trigger Jelly Shake",
        Desc = "Simulates liquid gelatinous wobble physics",
        Callback = function()
            triggerJellyWobble(24, -20)
        end,
    })

    tabJelly:Slider({
        Title = "Jelly Spring Force (Stiffness)",
        Desc = "Speed and frequency of the jelly oscillation",
        Step = 2,
        Value = {
            Min = 10,
            Max = 60,
            Default = jellySpringX.Force,
        },
        Callback = function(val)
            jellySpringX.Force = val
            jellySpringY.Force = val
        end,
    })

    tabJelly:Slider({
        Title = "Jelly Damping",
        Desc = "Controls how long the wobble lasts before settling",
        Step = 0.2,
        Value = {
            Min = 1.0,
            Max = 8.0,
            Default = jellySpringX.Damping,
        },
        Callback = function(val)
            jellySpringX.Damping = val
            jellySpringY.Damping = val
        end,
    })
end

-- TAB 3: Parameters
do
    tabParameters:Slider({
        Title = "Blur Kernel Inset",
        Desc = "Carrier inset in px to eliminate convolution blur bleed",
        Step = 2,
        Value = {
            Min = 20,
            Max = 60,
            Default = Settings.BlurKernelInset,
        },
        Callback = function(val)
            Settings.BlurKernelInset = math.floor(val)
        end,
    })

    tabParameters:Slider({
        Title = "Window Transparency",
        Desc = "Opacity of the unified obsidian frosted glass body",
        Step = 0.05,
        Value = {
            Min = 0.1,
            Max = 0.95,
            Default = Settings.WindowTransparency,
        },
        Callback = function(val)
            Settings.WindowTransparency = tonumber(string.format("%.2f", val))
            applyWindUIGlass()
        end,
    })

    tabParameters:Slider({
        Title = "Highlight Boost",
        Desc = "Rim specular highlight transparency factor",
        Step = 0.01,
        Value = {
            Min = 0.8,
            Max = 1.0,
            Default = Settings.HighlightBoost,
        },
        Callback = function(val)
            Settings.HighlightBoost = tonumber(string.format("%.2f", val))
            highlight.FillTransparency = Settings.HighlightBoost
        end,
    })
end

-- Select default tab
tabJelly:Select()

-- Trigger initial smooth jelly settle
triggerJellyWobble(14, -10)

print("[WindUI] Authentic macOS Liquid Glass with Jelly Physics Loaded!")
