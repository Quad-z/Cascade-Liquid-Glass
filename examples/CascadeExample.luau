--[[
    Cascade UI + Authentic macOS Liquid Glass
    =========================================
    Demonstrates how to use the LiquidGlass library by connecting
    directly to the library sources from the official GitHub repository:
    https://raw.githubusercontent.com/Quad-z/Cascade-Liquid-Glass/refs/heads/main/src/LiquidGlass.luau

    Features:
    - Modular: Loads LiquidGlass directly from GitHub sources
    - Authentic macOS Dark Mode Vibrancy (Translucent obsidian glass)
    - Enlarged Liquid Refraction Rim (Expanded bezel capturing deep background refraction)
    - Zero-Bleed 9-Slice Planar Alignment (Grows inward, never protruding)
    - Screen-Safe Local Frosted Glass (DepthOfField isolated under window)
    - Smooth macOS Tab Slide Transitions
    - Clean Window Minimization & Respawn Persistence
    
    MIT License | GitHub Ready
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- 1. CLEANUP PREVIOUS INSTANCES
local function cleanup()
    local hui = (gethui and gethui()) or game:GetService("CoreGui")
    for _, name in ipairs({"Cascade", "IdealLiquidStudio", "CascadeTest", "FrostGUI"}) do
        local g = hui:FindFirstChild(name)
        if g then g:Destroy() end
        local pg = LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui") and LocalPlayer.PlayerGui:FindFirstChild(name)
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

-- 2. IMPORT LIQUID GLASS LIBRARY DIRECTLY FROM GITHUB SOURCES
local LIB_URL = "https://raw.githubusercontent.com/Quad-z/Cascade-Liquid-Glass/refs/heads/main/src/LiquidGlass.luau"
local LiquidGlass = loadstring(game:HttpGet(LIB_URL))()

-- 3. INITIALIZE CASCADE UI
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

-- Subtle macOS specular border stroke
local borderStroke = body:FindFirstChild("LiquidGlassStroke") or Instance.new("UIStroke")
borderStroke.Name = "LiquidGlassStroke"
borderStroke.Color = Color3.fromRGB(255, 255, 255)
borderStroke.Transparency = 0.82
borderStroke.Thickness = 1.2
borderStroke.Parent = body

-- 100% Unified Translucent Obsidian Glass Styling
local UNIFIED_COLOR = Color3.fromRGB(14, 17, 24)
local windowTransparency = 0.60

local function applyTranslucency()
    body.BackgroundColor3 = UNIFIED_COLOR
    body.BackgroundTransparency = windowTransparency

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
            end
        end
    end)
end)

-- 4. ATTACH LIQUID GLASS LIBRARY TO THE WINDOW BODY
local glass = LiquidGlass.attach(body, {
    CornerRadius        = 15,    -- Window corner curvature in px
    CornerRefraction    = 6.0,   -- Optical lens distortion on corners
    RimScale            = 2.3,   -- Refraction rim thickness scale
    FrostBlur           = 0.25,  -- Local DepthOfField frosted glass blur
    EdgeRefraction      = 1.1,   -- Refraction along linear edges
    BlurKernelInset     = 32,    -- Inset in px to eliminate blur convolution bleed
    WindowTransparency  = windowTransparency,
    HighlightBoost      = 1.00,  -- Rim highlight factor
    JellyPhysics        = false, -- Window drag inertia wobble
    Enabled             = true,
})

-- 5. macOS-STYLE SMOOTH TAB TRANSITIONS
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

-- 6. BUILD CASCADE TABS & NATIVE STEPPERS
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

-- TAB 1: Refraction Controls
do
    local form = tabRefraction:Form()

    local rowCorner = titledRow(form, "Corner Refraction", "Optical lens distortion intensity on rounded corners [ - / + ]")
    rowCorner:Right():Stepper({
        Minimum = 0.5,
        Maximum = 6.0,
        Step = 0.1,
        Fielded = true,
        Value = glass.Config.CornerRefraction,
        ValueChanged = function(self, val)
            glass.Config.CornerRefraction = tonumber(string.format("%.2f", val))
            glass:Update(0)
        end,
    })

    local rowRadius = titledRow(form, "Corner Radius", "Window corner curvature and base lens mask radius (px) [ - / + ]")
    rowRadius:Right():Stepper({
        Minimum = 12,
        Maximum = 50,
        Step = 1,
        Fielded = true,
        Value = glass.Config.CornerRadius,
        ValueChanged = function(self, val)
            glass.Config.CornerRadius = math.floor(val)
            glass:Update(0)
        end,
    })

    local rowRim = titledRow(form, "Rim Size / Scale", "Refraction border thickness and optical bezel prominence [ - / + ]")
    rowRim:Right():Stepper({
        Minimum = 1.0,
        Maximum = 4.0,
        Step = 0.1,
        Fielded = true,
        Value = glass.Config.RimScale,
        ValueChanged = function(self, val)
            glass.Config.RimScale = tonumber(string.format("%.2f", val))
            glass:Update(0)
        end,
    })

    local rowFrost = titledRow(form, "Frost Blur", "Isolated DepthOfField under window only (Zero screen blur) [ - / + ]")
    rowFrost:Right():Stepper({
        Minimum = 0.0,
        Maximum = 1.0,
        Step = 0.05,
        Fielded = true,
        Value = glass.Config.FrostBlur,
        ValueChanged = function(self, val)
            glass.Config.FrostBlur = tonumber(string.format("%.2f", val))
            glass:Update(0)
        end,
    })

    local rowEdge = titledRow(form, "Edge Refraction", "Refraction power along linear top, bottom, and side edges")
    rowEdge:Right():Stepper({
        Minimum = 0.5,
        Maximum = 5.0,
        Step = 0.1,
        Fielded = true,
        Value = glass.Config.EdgeRefraction,
        ValueChanged = function(self, val)
            glass.Config.EdgeRefraction = tonumber(string.format("%.2f", val))
            glass:Update(0)
        end,
    })

    local rowToggle = titledRow(form, "Liquid Glass Effect", "Toggle 3D physical refraction meshes and frosted glass blur")
    rowToggle:Right():Toggle({
        Value = glass.Config.Enabled,
        ValueChanged = function(self, val)
            glass:SetEnabled(val)
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
        Value = glass.Config.BlurKernelInset,
        ValueChanged = function(self, val)
            glass.Config.BlurKernelInset = math.floor(val)
            glass:Update(0)
        end,
    })

    local rowOpacity = titledRow(form, "Window Transparency", "Overall opacity of the unified obsidian frosted glass body")
    rowOpacity:Right():Stepper({
        Minimum = 0.1,
        Maximum = 0.95,
        Step = 0.05,
        Fielded = true,
        Value = windowTransparency,
        ValueChanged = function(self, val)
            windowTransparency = tonumber(string.format("%.2f", val))
            applyTranslucency()
        end,
    })

    local rowHighlight = titledRow(form, "Highlight Boost", "Rim highlight transparency factor (default: 1.00)")
    rowHighlight:Right():Stepper({
        Minimum = 0.8,
        Maximum = 1.0,
        Step = 0.01,
        Fielded = true,
        Value = glass.Config.HighlightBoost,
        ValueChanged = function(self, val)
            glass.Config.HighlightBoost = tonumber(string.format("%.2f", val))
            glass:Update(0)
        end,
    })

    local rowPhysics = titledRow(form, "Jelly Spring Physics", "Enable organic window drag inertia wobble & fluid tilt response")
    rowPhysics:Right():Toggle({
        Value = glass.Config.JellyPhysics,
        ValueChanged = function(self, val)
            glass.Config.JellyPhysics = val
            if not val then
                body.Rotation = 0
            end
        end,
    })
end

-- TAB 3: About
do
    local form = tabAbout:Form()

    local rowStatus = titledRow(form, "Source Connection", "Connected to LiquidGlass.luau from GitHub repository")
    rowStatus:Right():Button({
        Label = "Verified",
        Pushed = function()
            print("[Cascade] LiquidGlass.luau is successfully loaded from GitHub sources!")
        end,
    })
end

task.delay(0.1, applyTranslucency)
task.delay(0.5, applyTranslucency)

print("[Cascade] Authentic macOS Liquid Glass Loaded via GitHub Source Library!")
