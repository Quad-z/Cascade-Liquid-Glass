--[=[
    LiquidGlass.luau
    ================
    A high-performance Liquid Glass & Isolated Frosted Glass Blur library for Roblox.
    
    Features:
    - 9-Slice Planar Glass Refraction (Corner & Edge lenses)
    - Enlarged Refraction Rim (Customizable RimScale)
    - Local Isolated Frosted Glass Blur (DepthOfField with Zero Screen Bleed)
    - Dynamic Screen Tracking (Handles scaling, movement, and camera projections)
    - Optional macOS Jelly Drag Physics (Damped harmonic oscillator)
    - Clean lifecycle management (Attach, Detach, Enable/Disable)

    @author quadraz & Antigravity
    @license MIT
    @repository https://github.com/Quad-z/Cascade-Liquid-Glass
]=]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Camera = Workspace.CurrentCamera
local DEPTH = 0.05
local ROTATION_OFFSET = CFrame.Angles(0, math.rad(-90), 0)

-- Analytical Spring Class for Fluid Jelly Physics
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

function Spring:Step(dt: number): number
    dt = math.clamp(dt, 0, 0.05)
    local x0 = self.Position - self.Target
    local v0 = self.Velocity
    local w0 = self.Frequency
    local z = self.Damping

    if z < 0.999 then
        local wd = w0 * math.sqrt(1 - z * z)
        local decay = math.exp(-z * w0 * dt)
        local cosTerm = math.cos(wd * dt)
        local sinTerm = math.sin(wd * dt)
        local c1 = x0
        local c2 = (v0 + z * w0 * x0) / wd

        self.Position = self.Target + decay * (c1 * cosTerm + c2 * sinTerm)
        self.Velocity = decay * (v0 * cosTerm - (c1 * wd + (z * w0 / wd) * (v0 + z * w0 * x0)) * sinTerm)
    else
        local decay = math.exp(-w0 * dt)
        local c1 = x0
        local c2 = v0 + w0 * x0
        self.Position = self.Target + decay * (c1 + c2 * dt)
        self.Velocity = decay * (v0 - w0 * c2 * dt)
    end
    return self.Position
end

local LiquidGlass = {}
LiquidGlass.__index = LiquidGlass

-- Default configuration preset (macOS Liquid Glass)
LiquidGlass.DefaultConfig = {
    CornerRadius = 15,
    CornerRefraction = 6.0,
    RimScale = 2.3,
    FrostBlur = 0.25,
    EdgeRefraction = 1.1,
    HighlightBoost = 1.00,
    BlurKernelInset = 32,
    WindowTransparency = 0.60,
    JellyPhysics = false,
    Enabled = true,
}

-- Ensure 9-slice overlay template assets exist in ReplicatedStorage
function LiquidGlass.ensureAssets()
    local lghAsset = ReplicatedStorage:FindFirstChild("LiquidGlassHandler")
    if not lghAsset then
        local loaded = game:GetObjects("rbxassetid://78675735649311")[1]
        loaded.Name = "LiquidGlassHandler"
        loaded.Parent = ReplicatedStorage
        lghAsset = loaded
    end
    return lghAsset.Overlay
end

local function getPlanePos(pixelX, pixelY)
    local ray = Camera:ScreenPointToRay(pixelX, pixelY)
    local camCF = Camera:GetRenderCFrame()
    local dist = DEPTH / ray.Direction:Dot(camCF.LookVector)
    return ray.Origin + ray.Direction * dist
end

-- Attach Liquid Glass effect to any GuiObject (Frame, CanvasGroup, Cascade window body)
function LiquidGlass.attach(guiObject: GuiObject, userConfig)
    assert(typeof(guiObject) == "Instance" and guiObject:IsA("GuiObject"), "LiquidGlass.attach: expected GuiObject")

    local self = setmetatable({}, LiquidGlass)
    self.GuiObject = guiObject
    self.Config = table.clone(LiquidGlass.DefaultConfig)

    if userConfig and type(userConfig) == "table" then
        for k, v in pairs(userConfig) do
            self.Config[k] = v
        end
    end

    local templateContainer = LiquidGlass.ensureAssets()

    -- 1. Isolated DepthOfField effect for local frost blur (zero screen bleed)
    self.Dof = Instance.new("DepthOfFieldEffect")
    self.Dof.Name = "Cascade_LiquidFrostDOF"
    self.Dof.FarIntensity = 0       -- Guaranteed: Screen around window is NEVER blurred
    self.Dof.FocusDistance = 0.15   -- Near camera lens
    self.Dof.InFocusRadius = 0
    self.Dof.NearIntensity = self.Config.FrostBlur
    self.Dof.Parent = Lighting

    -- 2. Camera folder & Model container
    self.Folder = Instance.new("Folder")
    self.Folder.Name = "LiquidGlassObjects_" .. guiObject.Name
    self.Folder.Parent = Camera

    self.RimModel = Instance.new("Model")
    self.RimModel.Name = "LiquidRimModel"
    self.RimModel.Parent = self.Folder

    -- Specular highlight
    self.Highlight = Instance.new("Highlight")
    self.Highlight.Name = "LiquidHighlight"
    self.Highlight.FillColor = Color3.fromRGB(0, 0, 0)
    self.Highlight.FillTransparency = self.Config.HighlightBoost
    self.Highlight.OutlineTransparency = 1
    self.Highlight.Parent = self.RimModel

    -- Center frost carrier plane
    self.CenterFrostPart = Instance.new("Part")
    self.CenterFrostPart.Name = "CenterFrostPlane"
    self.CenterFrostPart.Material = Enum.Material.Glass
    self.CenterFrostPart.Color = Color3.fromRGB(240, 248, 255)
    self.CenterFrostPart.Transparency = 0.98
    self.CenterFrostPart.Reflectance = 0
    self.CenterFrostPart.CastShadow = false
    self.CenterFrostPart.CanCollide = false
    self.CenterFrostPart.CanTouch = false
    self.CenterFrostPart.CanQuery = false
    self.CenterFrostPart.Anchored = true
    self.CenterFrostPart.Parent = self.Folder

    -- Helper to clone template rim parts
    local function makeRimPart(templateName, swapAxes, localRot)
        local p = templateContainer:FindFirstChild(templateName):Clone()
        p.Material = Enum.Material.Glass
        p.Color = Color3.fromRGB(0, 0, 0)
        p.Transparency = self.Config.EdgeRefraction
        p.CastShadow = false
        p.CanCollide = false
        p.CanQuery = false
        p.CanTouch = false
        p.Anchored = true
        p.Parent = self.RimModel
        return {
            Part = p,
            SwapAxes = swapAxes,
            LocalRot = localRot or CFrame.identity,
        }
    end

    self.Edges = {
        Top = makeRimPart("Edge", false, CFrame.Angles(0, 0, 0)),
        Bottom = makeRimPart("Edge", false, CFrame.Angles(0, 0, math.rad(180))),
        Left = makeRimPart("Edge", true, CFrame.Angles(0, 0, math.rad(90))),
        Right = makeRimPart("Edge", true, CFrame.Angles(0, 0, math.rad(-90))),
    }

    self.Corners = {
        TopLeft = makeRimPart("Corner", true, CFrame.Angles(0, 0, math.rad(90))),
        TopRight = makeRimPart("Corner", false, CFrame.Angles(0, 0, 0)),
        BottomLeft = makeRimPart("Corner", false, CFrame.Angles(0, 0, math.rad(180))),
        BottomRight = makeRimPart("Corner", true, CFrame.Angles(0, 0, math.rad(-90))),
    }

    -- Spring physics
    self.TiltSpring = Spring.new(0, 16, 0.68)
    self.PitchSpring = Spring.new(0, 22, 0.72)
    self.RollSpring = Spring.new(0, 22, 0.72)
    self.LastBodyPos = guiObject.AbsolutePosition
    self.SmoothedVelocity = Vector2.zero

    -- 3. Render loop
    self.RenderConn = RunService.RenderStepped:Connect(function(dt)
        self:Update(dt)
    end)

    -- Auto-cleanup on GuiObject destruction
    self.DestroyingConn = guiObject.Destroying:Connect(function()
        self:Destroy()
    end)

    return self
end

function LiquidGlass:Update(dt)
    dt = dt or 0.016
    local gui = self.GuiObject
    if not gui or not gui.Parent then
        self:Hide()
        return
    end

    local size = gui.AbsoluteSize
    local pos = gui.AbsolutePosition

    local isHidden = (not self.Config.Enabled)
        or (not gui.Visible)
        or (size.X < 80 or size.Y < 80)

    if isHidden then
        self:Hide()
        return
    else
        self:Show()
    end

    -- Physics wobble handling
    if self.Config.JellyPhysics then
        local deltaPos = pos - self.LastBodyPos
        self.LastBodyPos = pos

        local instantVel = (dt > 0.0001) and (deltaPos / dt) or Vector2.zero
        self.SmoothedVelocity = self.SmoothedVelocity:Lerp(instantVel, math.clamp(dt * 14, 0, 1))

        local targetTilt = math.clamp(-self.SmoothedVelocity.X * 0.010, -5, 5)
        local targetPitch = math.clamp(self.SmoothedVelocity.Y * 0.012, -4, 4)
        local targetRoll = math.clamp(-self.SmoothedVelocity.X * 0.012, -4, 4)

        self.TiltSpring.Target = targetTilt
        self.PitchSpring.Target = targetPitch
        self.RollSpring.Target = targetRoll

        gui.Rotation = self.TiltSpring:Step(dt)
    else
        gui.Rotation = 0
        self.SmoothedVelocity = Vector2.zero
        self.LastBodyPos = pos
    end

    local rad = math.clamp(self.Config.CornerRadius, 6, math.min(size.X, size.Y) / 2)
    local uiCorner = gui:FindFirstChildOfClass("UICorner")
    if uiCorner and uiCorner.CornerRadius.Offset ~= rad then
        uiCorner.CornerRadius = UDim.new(0, rad)
    end

    local camCF = Camera:GetRenderCFrame()
    local guiRotCF = CFrame.Angles(0, 0, math.rad(-gui.AbsoluteRotation))
    local dynamicTiltCF = CFrame.Angles(
        math.rad(self.PitchSpring.Position),
        math.rad(self.RollSpring.Position),
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

    local rimScale = math.clamp(self.Config.RimScale or 1.0, 1.0, 4.0)
    local cornerPxX = rad
    local cornerPxY = rad
    local relCornerX = cornerPxX / size.X
    local relCornerY = cornerPxY / size.Y

    local edgePxX = math.clamp(rad * rimScale, rad, size.X * 0.40)
    local edgePxY = math.clamp(rad * rimScale, rad, size.Y * 0.40)
    local relEdgeX = edgePxX / size.X
    local relEdgeY = edgePxY / size.Y

    local innerW = math.max(0.0001, (size.X - 2 * edgePxX) / size.X)
    local innerH = math.max(0.0001, (size.Y - 2 * edgePxY) / size.Y)
    local meshDepth = 0.001 + 0.002 * rimScale

    -- Update transparencies
    for _, edge in pairs(self.Edges) do
        edge.Part.Transparency = self.Config.EdgeRefraction
    end
    for _, corner in pairs(self.Corners) do
        corner.Part.Transparency = self.Config.CornerRefraction
    end
    self.Highlight.FillTransparency = self.Config.HighlightBoost

    -- Position edges
    local function positionEdge(item, relX, relY, relSizeX, relSizeY)
        local localOffset = Vector3.new(relX * worldW, -relY * worldH, 0)
        local rotatedOffset = guiRotCF * localOffset
        local worldOffset = (camCF.RightVector * rotatedOffset.X) + (camCF.UpVector * rotatedOffset.Y)

        if item.SwapAxes then
            item.Part.Size = Vector3.new(meshDepth, relSizeX * worldW, relSizeY * worldH)
        else
            item.Part.Size = Vector3.new(meshDepth, relSizeY * worldH, relSizeX * worldW)
        end
        item.Part.CFrame = CFrame.new(centerWorldPos + worldOffset) * camCF.Rotation * guiRotCF * dynamicTiltCF * item.LocalRot * ROTATION_OFFSET
    end

    -- Position corners
    local function positionCorner(item, relX, relY)
        local localOffset = Vector3.new(relX * worldW, -relY * worldH, 0)
        local rotatedOffset = guiRotCF * localOffset
        local worldOffset = (camCF.RightVector * rotatedOffset.X) + (camCF.UpVector * rotatedOffset.Y)

        if item.SwapAxes then
            item.Part.Size = Vector3.new(meshDepth, relCornerX * worldW, relCornerY * worldH)
        else
            item.Part.Size = Vector3.new(meshDepth, relCornerY * worldH, relCornerX * worldW)
        end
        item.Part.CFrame = CFrame.new(centerWorldPos + worldOffset) * camCF.Rotation * guiRotCF * dynamicTiltCF * item.LocalRot * ROTATION_OFFSET
    end

    positionEdge(self.Edges.Top,    0,                     -0.5 + (relEdgeY / 2),  innerW,   relEdgeY)
    positionEdge(self.Edges.Bottom, 0,                      0.5 - (relEdgeY / 2),  innerW,   relEdgeY)
    positionEdge(self.Edges.Left,  -0.5 + (relEdgeX / 2),  0,                     relEdgeX, innerH)
    positionEdge(self.Edges.Right,  0.5 - (relEdgeX / 2),  0,                     relEdgeX, innerH)

    positionCorner(self.Corners.TopLeft,     -0.5 + (relCornerX / 2), -0.5 + (relCornerY / 2))
    positionCorner(self.Corners.TopRight,     0.5 - (relCornerX / 2), -0.5 + (relCornerY / 2))
    positionCorner(self.Corners.BottomLeft,  -0.5 + (relCornerX / 2),  0.5 - (relCornerY / 2))
    positionCorner(self.Corners.BottomRight,  0.5 - (relCornerX / 2),  0.5 - (relCornerY / 2))

    -- Center Frost plane
    local insetPixels = math.max(self.Config.BlurKernelInset, math.max(edgePxX, edgePxY))
    local frostW = math.max(0.001, (size.X - insetPixels) / size.X * worldW)
    local frostH = math.max(0.001, (size.Y - insetPixels) / size.Y * worldH)
    self.CenterFrostPart.Size = Vector3.new(frostW, frostH, 0.001)
    self.CenterFrostPart.CFrame = CFrame.new(centerWorldPos) * camCF.Rotation * guiRotCF * dynamicTiltCF
end

function LiquidGlass:Hide()
    self.RimModel.Parent = nil
    self.CenterFrostPart.Transparency = 1
    self.Dof.NearIntensity = 0
end

function LiquidGlass:Show()
    if self.RimModel.Parent ~= self.Folder then
        self.RimModel.Parent = self.Folder
    end
    self.CenterFrostPart.Transparency = (self.Config.FrostBlur > 0.02) and 0.98 or 1.0
    self.Dof.NearIntensity = self.Config.FrostBlur
end

function LiquidGlass:SetEnabled(enabled: boolean)
    self.Config.Enabled = enabled
    self:Update(0)
end

function LiquidGlass:Destroy()
    if self.RenderConn then
        self.RenderConn:Disconnect()
        self.RenderConn = nil
    end
    if self.DestroyingConn then
        self.DestroyingConn:Disconnect()
        self.DestroyingConn = nil
    end
    if self.Dof then
        self.Dof:Destroy()
        self.Dof = nil
    end
    if self.Folder then
        self.Folder:Destroy()
        self.Folder = nil
    end
end

return LiquidGlass
