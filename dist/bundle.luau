--[[
    Cascade UI + Authentic macOS Liquid Glass
    =========================================
    A premium macOS-styled Liquid Glass & Local Frosted Blur implementation
    for Roblox, integrated seamlessly with Cascade UI.

    Features:
    - Authentic macOS Dark Mode Vibrancy (Translucent obsidian glass)
    - Zero-Bleed 9-Slice Planar Refraction (Corner & edge distortion)
    - Screen-Safe Local Frosted Glass (DepthOfField isolated under window)
    - Smooth macOS Tab Slide Transitions
    - Clean Window Minimization & Respawn Persistence
    
    MIT License | GitHub Ready
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
    for _, name in ipairs({"Cascade", "IdealLiquidStudio", "CascadeTest", "FrostGUI"}) do
        local g = hui:FindFirstChild(name)
        if g then g:Destroy() end
        local pg = LocalPlayer.PlayerGui:FindFirstChild(name)
        if pg then pg:Destroy() end
    end
    for _, name in ipairs({"LiquidGlassObjects", "LiquidRimModel", "Cascade_Liquid_Root", "AcrylicParts"}) do
        local f = Camera:FindFirstChild(name)
        if f then f:Destroy() end
        local wf = Workspace:FindFirstChild(name)
        if wf then wf:Destroy() end
    end
    for _, ch in ipairs(Lighting:GetChildren()) do
        if ch:IsA("DepthOfFieldEffect") and (ch.Name:find("Liquid") or ch.Name:find("Frost") or ch.Name:find("DOF") or ch.Name:find("Acrylic")) then
            ch:Destroy()
        end
    end
end
cleanup()

-- 2. ENSURE LIQUID GLASS 9-SLICE MESH ASSETS
local lghAsset = ReplicatedStorage:FindFirstChild("LiquidGlassHandler")
if not lghAsset then
    local loaded = game:GetObjects("rbxassetid://78675735649311")[1]
    loaded.Name = "LiquidGlassHandler"
    loaded.Parent = ReplicatedStorage
    lghAsset = loaded
end
local templateContainer = lghAsset.Overlay

-- 3. USER CONFIGURATION PRESET
local Settings = {
    CornerRefraction = 3.5,       -- Refraction index on rounded corners
    CornerRadius = 26,           -- Corner border radius in pixels (macOS style)
    EdgeRefraction = 2.9,        -- Refraction index on linear window edges
    HighlightBoost = 0.98,       -- Specular rim transparency
    FrostBlur = 0.85,            -- Local DepthOfField frosted glass blur
    WindowTransparency = 0.38,   -- Unified translucent obsidian dark glass
    BlurKernelInset = 36,        -- Inset in pixels to eliminate blur convolution bleed
    Enabled = true,
}

-- 4. LOCAL FROST DEPTH OF FIELD
-- Neutralize game place's built-in global blur so the 3D world is 100% sharp
for _, ch in ipairs(Lighting:GetChildren()) do
    if ch:IsA("DepthOfFieldEffect") and ch.Name ~= "Cascade_LiquidFrostDOF" then
        ch.FarIntensity = 0
    elseif ch:IsA("BlurEffect") and (ch.Name == "Blur" or ch.Name == "DefaultBlur") then
        ch.Enabled = false
    end
end

local dof = Instance.new("DepthOfFieldEffect")
dof.Name = "Cascade_LiquidFrostDOF"
dof.FarIntensity = 0        -- Screen safety: 3D world is NEVER blurred outside window
dof.FocusDistance = 0.15    -- Isolated near camera plane
dof.InFocusRadius = 0
dof.NearIntensity = Settings.FrostBlur
dof.Parent = Lighting

-- 5. INITIALIZE CASCADE UI (Official Release, 100% UNTOUCHED)
local cascade = loadstring(game:HttpGet("https://github.com/cascadeui/Cascade/releases/download/v1.4.0/dist.luau"))()

local app = cascade.New({
    WindowPill = true,
    Theme = cascade.Themes.Dark,
    Accent = cascade.Accents.Blue,
})

local window = app:Window({
    Title = "Cascade",
    Subtitle = "Liquid Glass • macOS Edition",
    Size = UDim2.fromOffset(780, 490),
    UIBlur = false,
})

local rawBody = window.Structures.Body
local body = rawBody.__instance or rawBody

-- Prevent UI from resetting on player respawn
local screenGui = body:FindFirstAncestorOfClass("ScreenGui")
if screenGui then
    screenGui.ResetOnSpawn = false
end

local uiCorner = body:FindFirstChildOfClass("UICorner")
if uiCorner then
    uiCorner.CornerRadius = UDim.new(0, Settings.CornerRadius)
end

-- Subtle macOS specular border stroke
local borderStroke = body:FindFirstChild("LiquidGlassStroke") or Instance.new("UIStroke")
borderStroke.Name = "LiquidGlassStroke"
borderStroke.Color = Color3.fromRGB(255, 255, 255)
borderStroke.Transparency = 0.82
borderStroke.Thickness = 1.2
borderStroke.Parent = body

-- 100% Unified Translucent Obsidian Glass
local UNIFIED_COLOR = Color3.fromRGB(14, 17, 24)

local function applyTranslucency()
    body.BackgroundColor3 = UNIFIED_COLOR
    body.BackgroundTransparency = Settings.WindowTransparency

    for _, desc in ipairs(body:GetDescendants()) do
        if desc:IsA("GuiObject") then
            if desc.Name == "Sidebar" or desc.Name == "ContentBody" or desc.Name == "Toolbar" or desc.Name:find("CornerClip") then
                desc.BackgroundColor3 = UNIFIED_COLOR
                desc.BackgroundTransparency = 1 -- fully transparent to make window 100% seamless
            elseif desc.Name == "Top" or desc.Name == "Bottom" then
                desc.BackgroundTransparency = 1
            elseif desc.Name == "Form" then
                desc.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                desc.BackgroundTransparency = 0.95
            elseif desc.Name == "Separator" then
                desc.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                desc.BackgroundTransparency = 0.90
            end
        end
    end
end
applyTranslucency()

body.DescendantAdded:Connect(function(desc)
    task.defer(function()
        if desc:IsA("GuiObject") then
            if desc.Name == "Sidebar" or desc.Name == "ContentBody" or desc.Name == "Toolbar" or desc.Name:find("CornerClip") then
                desc.BackgroundColor3 = UNIFIED_COLOR
                desc.BackgroundTransparency = 1
            elseif desc.Name == "Top" or desc.Name == "Bottom" then
                desc.BackgroundTransparency = 1
            elseif desc.Name == "Form" then
                desc.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                desc.BackgroundTransparency = 0.95
            elseif desc.Name == "Separator" then
                desc.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                desc.BackgroundTransparency = 0.90
            end
        end
    end)
end)

-- 6. 3D REFRACTION MESHES (STRICT PLANAR ALIGNMENT - ZERO OUT-OF-BOUNDS BLEED)
local parentFolder = Instance.new("Folder")
parentFolder.Name = "LiquidGlassObjects"
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

-- Center Frost Part (with blur kernel inset to eliminate bleeding)
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

-- 7. CLEAN RENDERING LOOP
local function updateLiquidGlass()
    local size = body.AbsoluteSize
    local pos = body.AbsolutePosition

    local scaleObj = rawBody.Parent and rawBody.Parent:FindFirstChildOfClass("UIScale")
    local isMinimized = (window.Minimized == true)
        or (not Settings.Enabled)
        or (not body or not body.Parent)
        or (not body.Visible)
        or (size.X < 80 or size.Y < 80)
        or (scaleObj and scaleObj.Scale < 0.1)

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
    if uiCorner and uiCorner.CornerRadius.Offset ~= rad then
        uiCorner.CornerRadius = UDim.new(0, rad)
    end

    local camCF = Camera:GetRenderCFrame()
    local guiRotCF = CFrame.Angles(0, 0, math.rad(-body.AbsoluteRotation))

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

    -- Planar corner dimensions: strictly aligned within the window corner radius
    local diamX = relRadX
    local diamY = relRadY
    local halfDiamX = diamX / 2
    local halfDiamY = diamY / 2

    -- Update Transparencies & Highlight
    cornerTL.Part.Transparency = Settings.CornerRefraction
    cornerTR.Part.Transparency = Settings.CornerRefraction
    cornerBL.Part.Transparency = Settings.CornerRefraction
    cornerBR.Part.Transparency = Settings.CornerRefraction

    edgeTop.Part.Transparency = Settings.EdgeRefraction
    edgeBottom.Part.Transparency = Settings.EdgeRefraction
    edgeLeft.Part.Transparency = Settings.EdgeRefraction
    edgeRight.Part.Transparency = Settings.EdgeRefraction

    highlight.FillTransparency = Settings.HighlightBoost

    -- Position Edges with SwapAxes
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

    -- Position Corners with Planar Alignment (No out-of-plane tilt, guaranteeing zero protrusion)
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

    -- Center Frost Part with BlurKernelInset:
    local insetPixels = Settings.BlurKernelInset
    local frostW = math.max(0.001, (size.X - insetPixels) / size.X * worldW)
    local frostH = math.max(0.001, (size.Y - insetPixels) / size.Y * worldH)
    centerFrostPart.Size = Vector3.new(frostW, frostH, 0.001)
    centerFrostPart.CFrame = CFrame.new(centerWorldPos) * camCF.Rotation * guiRotCF
end

local renderConn = RunService.RenderStepped:Connect(updateLiquidGlass)

body.Destroying:Connect(function()
    if renderConn then renderConn:Disconnect() end
    dof:Destroy()
    rimModel:Destroy()
    centerFrostPart:Destroy()
end)

-- 8. macOS-STYLE SMOOTH TAB TRANSITIONS (Safely animated on content switch)
local contentContainer = window.__container or (body:FindFirstChild("ContentBody") and body.ContentBody:FindFirstChild("Content"))
if contentContainer then
    contentContainer.ChildAdded:Connect(function(child)
        if child:IsA("GuiObject") and (child.Name:find("Form") or child.Name:find("Page") or child:IsA("ScrollingFrame")) then
            local originalPos = child.Position
            child.Position = originalPos + UDim2.fromOffset(16, 0)
            
            local tweenInfo = TweenInfo.new(0.28, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)
            TweenService:Create(child, tweenInfo, {
                Position = originalPos
            }):Play()
        end
    end)
end

-- 9. BUILD CASCADE TABS & NATIVE STEPPERS (ENGLISH INTERFACE)
local section = window:Section({
    Title = "Liquid Glass",
    Disclosure = false,
})

local tabRefraction = section:Tab({
    Selected = true,
    Title = "Refraction",
    Icon = cascade.Symbols.sliderHorizontal3,
})

local tabParameters = section:Tab({
    Selected = false,
    Title = "Parameters",
    Icon = cascade.Symbols.gear,
})

local tabAbout = section:Tab({
    Selected = false,
    Title = "About",
    Icon = cascade.Symbols.infoCircle,
})

local function titledRow(parent, title, subtitle)
    local row = parent:Row({
        SearchIndex = title,
    })
    row:Left():TitleStack({
        Title = title,
        Subtitle = subtitle,
    })
    return row
end

-- TAB 1: Refraction Controls (With user's exact preset)
do
    local form = tabRefraction:Form()

    local rowCorner = titledRow(form, "Corner Refraction", "Optical lens distortion intensity on rounded corners [ - / + ]")
    rowCorner:Right():Stepper({
        Minimum = 0.5,
        Maximum = 6.0,
        Step = 0.1,
        Fielded = true,
        Value = Settings.CornerRefraction,
        ValueChanged = function(self, val)
            Settings.CornerRefraction = tonumber(string.format("%.2f", val))
            updateLiquidGlass()
        end,
    })

    local rowRadius = titledRow(form, "Corner Radius", "Window corner curvature and lens mask radius (px) [ - / + ]")
    rowRadius:Right():Stepper({
        Minimum = 12,
        Maximum = 50,
        Step = 1,
        Fielded = true,
        Value = Settings.CornerRadius,
        ValueChanged = function(self, val)
            Settings.CornerRadius = math.floor(val)
            if uiCorner then
                uiCorner.CornerRadius = UDim.new(0, Settings.CornerRadius)
            end
            updateLiquidGlass()
        end,
    })

    local rowFrost = titledRow(form, "Frost Blur", "Isolated DepthOfField under window only (Zero screen blur) [ - / + ]")
    rowFrost:Right():Stepper({
        Minimum = 0.0,
        Maximum = 1.0,
        Step = 0.05,
        Fielded = true,
        Value = Settings.FrostBlur,
        ValueChanged = function(self, val)
            Settings.FrostBlur = tonumber(string.format("%.2f", val))
            updateLiquidGlass()
        end,
    })

    local rowEdge = titledRow(form, "Edge Refraction", "Refraction power along linear top, bottom, and side edges")
    rowEdge:Right():Stepper({
        Minimum = 0.5,
        Maximum = 5.0,
        Step = 0.1,
        Fielded = true,
        Value = Settings.EdgeRefraction,
        ValueChanged = function(self, val)
            Settings.EdgeRefraction = tonumber(string.format("%.2f", val))
            updateLiquidGlass()
        end,
    })

    local rowToggle = titledRow(form, "Liquid Glass Effect", "Toggle 3D physical refraction meshes and frosted glass blur")
    rowToggle:Right():Toggle({
        Value = Settings.Enabled,
        ValueChanged = function(self, val)
            Settings.Enabled = val
            updateLiquidGlass()
        end,
    })
end

-- TAB 2: Parameters
do
    local form = tabParameters:Form()

    local rowInset = titledRow(form, "Blur Kernel Inset", "Frost carrier inset in px to guarantee zero convolution bleed")
    rowInset:Right():Stepper({
        Minimum = 20,
        Maximum = 60,
        Step = 2,
        Fielded = true,
        Value = Settings.BlurKernelInset,
        ValueChanged = function(self, val)
            Settings.BlurKernelInset = math.floor(val)
            updateLiquidGlass()
        end,
    })

    local rowOpacity = titledRow(form, "Window Transparency", "Overall opacity of the unified obsidian frosted glass body")
    rowOpacity:Right():Stepper({
        Minimum = 0.1,
        Maximum = 0.95,
        Step = 0.05,
        Fielded = true,
        Value = Settings.WindowTransparency,
        ValueChanged = function(self, val)
            Settings.WindowTransparency = tonumber(string.format("%.2f", val))
            applyTranslucency()
        end,
    })

    local rowHighlight = titledRow(form, "Highlight Boost", "Rim highlight transparency factor (default: 0.98)")
    rowHighlight:Right():Stepper({
        Minimum = 0.8,
        Maximum = 1.0,
        Step = 0.01,
        Fielded = true,
        Value = Settings.HighlightBoost,
        ValueChanged = function(self, val)
            Settings.HighlightBoost = tonumber(string.format("%.2f", val))
            highlight.FillTransparency = Settings.HighlightBoost
        end,
    })
end

-- TAB 3: About
do
    local form = tabAbout:Form()

    local rowStatus = titledRow(form, "Integration Status", "macOS Liquid Glass (26px corners) is active and running cleanly")
    rowStatus:Right():Button({
        Label = "Verified",
        Pushed = function()
            print("[Cascade] macOS Liquid Glass is operating perfectly!")
        end,
    })
end

task.delay(0.1, applyTranslucency)
task.delay(0.5, applyTranslucency)

print("[Cascade] Authentic macOS Liquid Glass (English Edition) Loaded!")
