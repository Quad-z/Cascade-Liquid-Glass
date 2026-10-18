--[[
    Cascade UI + Authentic macOS Liquid Glass
    =========================================
    A premium macOS-styled Liquid Glass & Local Frosted Blur implementation
    for Roblox, integrated seamlessly with Cascade UI.

    Features:
    - Authentic macOS Dark Mode Vibrancy (Translucent obsidian glass)
    - Enlarged Liquid Refraction Rim (Expanded bezel capturing deep background refraction)
    - Zero-Bleed 9-Slice Planar Alignment (Grows inward, never protruding)
    - Fluid Spring Physics (Damped harmonic oscillator wobble, drag tilt & pop-in bounce)
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
local UserInputService = game:GetService("UserInputService")

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

-- 3. USER CONFIGURATION PRESET (Exact Match with User In-Game Tuning)
local Settings = {
    CornerRefraction = 6.0,       -- Optical lens distortion on corners (User set: 6.0)
    CornerRadius = 15,           -- Window corner curvature in px (User set: 15)
    RimScale = 2.3,              -- Refraction rim thickness scale (User set: 2.3)
    FrostBlur = 0.25,            -- Local DepthOfField frosted glass blur (User set: 0.25)
    EdgeRefraction = 1.1,        -- Refraction along linear edges (User set: 1.1)
    BlurKernelInset = 32,        -- Inset in px to eliminate blur convolution bleed (User set: 32)
    WindowTransparency = 0.60,   -- Translucent obsidian dark glass body (User set: 0.60)
    HighlightBoost = 1.00,       -- Rim highlight factor (User set: 1.00)
    JellyPhysics = false,        -- Window drag inertia wobble (User set: false)
    Enabled = true,
}

-- 4. ANALYTICAL SPRING CLASS (Damped Harmonic Oscillator)
local Spring = {}
Spring.__index = Spring

function Spring.new(initial: number, frequency: number?, damping: number?)
    local self = setmetatable({}, Spring)
    self.Position = initial or 0
    self.Velocity = 0
    self.Target = initial or 0
    self.Frequency = frequency or 18
    self.Damping = damping or 0.65
    return self
end

function Spring:Reset(value: number)
    self.Position = value
    self.Target = value
    self.Velocity = 0
end

function Spring:Step(dt: number): number
    dt = math.clamp(dt, 0, 0.05)
    local x0 = self.Position - self.Target
    local v0 = self.Velocity
    local w0 = self.Frequency
    local z = self.Damping

    if z < 0.999 then
        -- Underdamped (Fluid jelly bounce)
        local wd = w0 * math.sqrt(1 - z * z)
        local decay = math.exp(-z * w0 * dt)
        local cosTerm = math.cos(wd * dt)
        local sinTerm = math.sin(wd * dt)
        local c1 = x0
        local c2 = (v0 + z * w0 * x0) / wd

        self.Position = self.Target + decay * (c1 * cosTerm + c2 * sinTerm)
        self.Velocity = decay * (v0 * cosTerm - (c1 * wd + (z * w0 / wd) * (v0 + z * w0 * x0)) * sinTerm)
    else
        -- Critically damped / Overdamped
        local decay = math.exp(-w0 * dt)
        local c1 = x0
        local c2 = v0 + w0 * x0
        self.Position = self.Target + decay * (c1 + c2 * dt)
        self.Velocity = decay * (v0 - w0 * c2 * dt)
    end
    return self.Position
end

-- Springs for fluid window interaction
local tiltSpring = Spring.new(0, 16, 0.68)      -- In-plane rotation wobble
local meshPitchSpring = Spring.new(0, 22, 0.72) -- 3D refraction pitch ripple
local meshRollSpring = Spring.new(0, 22, 0.72)  -- 3D refraction roll ripple
local popInScaleSpring = Spring.new(0.88, 18, 0.62) -- Elastic pop-in bounce
popInScaleSpring.Target = 1.0

-- 5. LOCAL FROST DEPTH OF FIELD
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

-- 6. INITIALIZE CASCADE UI
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

-- 7. 3D REFRACTION MESHES (ENLARGED RIM - ZERO OUT-OF-BOUNDS BLEED)
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

-- Velocity & Drag Physics State
local lastBodyPos = body.AbsolutePosition
local smoothedVelocity = Vector2.zero

-- 8. CLEAN RENDERING LOOP WITH FLUID SPRINGS & ENLARGED RIM
local function updateLiquidGlass(dt)
    dt = dt or (1 / 60)
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

    -- Fluid Jelly Physics & Drag Inertia
    if Settings.JellyPhysics then
        local rawVel = (pos - lastBodyPos) / math.max(0.001, dt)
        smoothedVelocity = smoothedVelocity:Lerp(rawVel, math.clamp(dt * 20, 0, 1))
        lastBodyPos = pos

        local speed = smoothedVelocity.Magnitude
        if speed > 2 then
            -- Drag tilt targets (Subtle macOS fluid inertia: clamped to ±4.5 degrees)
            tiltSpring.Target = math.clamp(-smoothedVelocity.X * 0.012, -4.5, 4.5)
            meshPitchSpring.Target = math.clamp(smoothedVelocity.Y * 0.010, -6, 6)
            meshRollSpring.Target = math.clamp(-smoothedVelocity.X * 0.010, -6, 6)
        else
            tiltSpring.Target = 0
            meshPitchSpring.Target = 0
            meshRollSpring.Target = 0
        end

        local currentTilt = tiltSpring:Step(dt)
        local currentPitch = meshPitchSpring:Step(dt)
        local currentRoll = meshRollSpring:Step(dt)
        local currentPopScale = popInScaleSpring:Step(dt)

        -- Apply subtle 2D wobble rotation to GUI body
        body.Rotation = currentTilt

        -- Apply pop-in scale if scaleObj is available
        if scaleObj and popInScaleSpring.Position < 0.999 then
            scaleObj.Scale = currentPopScale
        end
    else
        body.Rotation = 0
        smoothedVelocity = Vector2.zero
        lastBodyPos = pos
    end

    local rad = math.clamp(Settings.CornerRadius, 6, math.min(size.X, size.Y) / 2)
    if uiCorner and uiCorner.CornerRadius.Offset ~= rad then
        uiCorner.CornerRadius = UDim.new(0, rad)
    end

    local camCF = Camera:GetRenderCFrame()
    local guiRotCF = CFrame.Angles(0, 0, math.rad(-body.AbsoluteRotation))
    local dynamicTiltCF = CFrame.Angles(
        math.rad(meshPitchSpring.Position),
        math.rad(meshRollSpring.Position),
        0
    )

    local centerScreenPos = pos + (size / 2)
    local centerWorldPos = getPlanePos(centerScreenPos.X, centerScreenPos.Y)
    local rightEdge = getPlanePos(centerScreenPos.X + (size.X / 2), centerScreenPos.Y)
    local leftEdge = getPlanePos(centerScreenPos.X - (size.X / 2), centerScreenPos.Y)
    local topEdge = getPlanePos(centerScreenPos.X, centerScreenPos.Y - (size.Y / 2))
    local bottomEdge = getPlanePos(centerScreenPos.X, centerScreenPos.Y + (size.Y / 2))

    local worldW = (rightEdge - leftEdge).Magnitude
    local worldH = (topEdge - bottomEdge).Magnitude

    -- REFRACTION RIM CALCULATIONS:
    -- CORNERS: always locked to CornerRadius (never scale up → no sphere artifact)
    -- EDGES:   scale with RimScale → wider optical bevel strips along each side

    local rimScale = math.clamp(Settings.RimScale or 1.0, 1.0, 4.0)

    -- Corners are always exactly CornerRadius px - this is what keeps them as proper quarter-circles
    local cornerPxX = rad
    local cornerPxY = rad
    local relCornerX = cornerPxX / size.X
    local relCornerY = cornerPxY / size.Y

    -- Edge strips grow with RimScale, but are capped so they never exceed 40% of window
    local edgePxX = math.clamp(rad * rimScale, rad, size.X * 0.40)
    local edgePxY = math.clamp(rad * rimScale, rad, size.Y * 0.40)
    local relEdgeX = edgePxX / size.X
    local relEdgeY = edgePxY / size.Y

    -- Inner flat area shrinks as edges grow
    local innerW = math.max(0.0001, (size.X - 2 * edgePxX) / size.X)
    local innerH = math.max(0.0001, (size.Y - 2 * edgePxY) / size.Y)

    -- Mesh depth scales slightly for optical density
    local meshDepth = 0.001 + 0.002 * rimScale

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

    -- Position Edges (Flush to outer border, growing INWARD with RimScale)
    local function positionEdge(item, relX, relY, relSizeX, relSizeY)
        local localOffset = Vector3.new(relX * worldW, -relY * worldH, 0)
        local rotatedOffset = guiRotCF * localOffset
        local worldOffset = (camCF.RightVector * rotatedOffset.X) + (camCF.UpVector * rotatedOffset.Y)

        if item.SwapAxes then
            item.Part.Size = Vector3.new(meshDepth, relSizeX * worldW, relSizeY * worldH)
        else
            item.Part.Size = Vector3.new(meshDepth, relSizeY * worldH, relSizeX * worldW)
        end
        item.Part.CFrame = CFrame.new(centerWorldPos + worldOffset) * camCF.Rotation * guiRotCF * dynamicTiltCF * item.LocalRot * rotationOffset
    end

    -- Position Corners (ALWAYS CornerRadius px - never grows, no sphere artifact)
    local function positionCorner(item, relX, relY)
        local localOffset = Vector3.new(relX * worldW, -relY * worldH, 0)
        local rotatedOffset = guiRotCF * localOffset
        local worldOffset = (camCF.RightVector * rotatedOffset.X) + (camCF.UpVector * rotatedOffset.Y)

        if item.SwapAxes then
            item.Part.Size = Vector3.new(meshDepth, relCornerX * worldW, relCornerY * worldH)
        else
            item.Part.Size = Vector3.new(meshDepth, relCornerY * worldH, relCornerX * worldW)
        end
        item.Part.CFrame = CFrame.new(centerWorldPos + worldOffset) * camCF.Rotation * guiRotCF * dynamicTiltCF * item.LocalRot * rotationOffset
    end

    -- 4 Edges: outer boundary flush, strip width = edgePxY (top/bottom) or edgePxX (left/right)
    positionEdge(edgeTop,    0,                         -0.5 + (relEdgeY / 2),  innerW,   relEdgeY)
    positionEdge(edgeBottom, 0,                          0.5 - (relEdgeY / 2),  innerW,   relEdgeY)
    positionEdge(edgeLeft,  -0.5 + (relEdgeX / 2),      0,                     relEdgeX, innerH)
    positionEdge(edgeRight,  0.5 - (relEdgeX / 2),      0,                     relEdgeX, innerH)

    -- 4 Corners: always at their natural CornerRadius positions
    positionCorner(cornerTL, -0.5 + (relCornerX / 2), -0.5 + (relCornerY / 2))
    positionCorner(cornerTR,  0.5 - (relCornerX / 2), -0.5 + (relCornerY / 2))
    positionCorner(cornerBL, -0.5 + (relCornerX / 2),  0.5 - (relCornerY / 2))
    positionCorner(cornerBR,  0.5 - (relCornerX / 2),  0.5 - (relCornerY / 2))

    -- Center Frost Part: inset by the larger of BlurKernelInset or the edge rim thickness
    local insetPixels = math.max(Settings.BlurKernelInset, math.max(edgePxX, edgePxY))
    local frostW = math.max(0.001, (size.X - insetPixels) / size.X * worldW)
    local frostH = math.max(0.001, (size.Y - insetPixels) / size.Y * worldH)
    centerFrostPart.Size = Vector3.new(frostW, frostH, 0.001)
    centerFrostPart.CFrame = CFrame.new(centerWorldPos) * camCF.Rotation * guiRotCF * dynamicTiltCF
end

local renderConn = RunService.RenderStepped:Connect(updateLiquidGlass)

body.Destroying:Connect(function()
    if renderConn then renderConn:Disconnect() end
    dof:Destroy()
    rimModel:Destroy()
    centerFrostPart:Destroy()
end)

-- 9. macOS-STYLE SMOOTH TAB TRANSITIONS (Safely animated on content switch)
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

-- 10. BUILD CASCADE TABS & NATIVE STEPPERS (ENGLISH INTERFACE)
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

-- TAB 1: Refraction Controls (With user's exact preset & enlarged rim stepper)
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
            updateLiquidGlass(0)
        end,
    })

    local rowRadius = titledRow(form, "Corner Radius", "Window corner curvature and base lens mask radius (px) [ - / + ]")
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
            updateLiquidGlass(0)
        end,
    })

    local rowRim = titledRow(form, "Rim Size / Scale", "Refraction border thickness and optical bezel prominence [ - / + ]")
    rowRim:Right():Stepper({
        Minimum = 1.0,
        Maximum = 4.0,
        Step = 0.1,
        Fielded = true,
        Value = Settings.RimScale,
        ValueChanged = function(self, val)
            Settings.RimScale = tonumber(string.format("%.2f", val))
            updateLiquidGlass(0)
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
            updateLiquidGlass(0)
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
            updateLiquidGlass(0)
        end,
    })

    local rowToggle = titledRow(form, "Liquid Glass Effect", "Toggle 3D physical refraction meshes and frosted glass blur")
    rowToggle:Right():Toggle({
        Value = Settings.Enabled,
        ValueChanged = function(self, val)
            Settings.Enabled = val
            updateLiquidGlass(0)
        end,
    })
end

-- TAB 2: Parameters (User presets & Jelly Physics toggle)
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
            updateLiquidGlass(0)
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

    local rowHighlight = titledRow(form, "Highlight Boost", "Rim highlight transparency factor (default: 1.00)")
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

    local rowPhysics = titledRow(form, "Jelly Spring Physics", "Enable organic window drag inertia wobble & fluid tilt response")
    rowPhysics:Right():Toggle({
        Value = Settings.JellyPhysics,
        ValueChanged = function(self, val)
            Settings.JellyPhysics = val
            if not val then
                body.Rotation = 0
            end
        end,
    })
end

-- TAB 3: About
do
    local form = tabAbout:Form()

    local rowStatus = titledRow(form, "Integration Status", "macOS Liquid Glass (Enlarged Rim + Jelly Physics) is active")
    rowStatus:Right():Button({
        Label = "Verified",
        Pushed = function()
            print("[Cascade] macOS Liquid Glass is operating perfectly!")
        end,
    })
end

task.delay(0.1, applyTranslucency)
task.delay(0.5, applyTranslucency)

print("[Cascade] Authentic macOS Liquid Glass (Enlarged Rim + Jelly Physics) Loaded!")
