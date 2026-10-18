--[[
    Cascade UI + Настоящее жидкое стекло macOS (Русская версия)
    ===========================================================
    Пример подключения и использования библиотеки LiquidGlass напрямую
    из официального репозитория на GitHub:
    https://raw.githubusercontent.com/Quad-z/Cascade-Liquid-Glass/refs/heads/main/src/LiquidGlass.luau

    Возможности:
    - Модульность: Загрузка LiquidGlass напрямую из исходников GitHub
    - Аутентичная темная тема macOS Vibrancy (полупрозрачное обсидиановое стекло)
    - Увеличенная рамка преломления (RimScale)
    - Бесшовное 9-slice выравнивание по углам и граням
    - Локальный матовый блюр (DepthOfField изолирован строго под окном)
    - Плавные анимации переключения вкладок
    - Устойчивость к респавну персонажа
    
    MIT License | GitHub Ready
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- 1. ОЧИСТКА ПРЕДЫДУЩИХ ЭКЗЕМПЛЯРОВ
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

-- 2. ПОДКЛЮЧЕНИЕ БИБЛИОТЕКИ LIQUID GLASS ИЗ ИСХОДНИКОВ GITHUB
local LIB_URL = "https://raw.githubusercontent.com/Quad-z/Cascade-Liquid-Glass/refs/heads/main/src/LiquidGlass.luau"
local LiquidGlass = loadstring(game:HttpGet(LIB_URL))()

-- 3. ИНИЦИАЛИЗАЦИЯ CASCADE UI
local cascade = loadstring(game:HttpGet("https://github.com/cascadeui/Cascade/releases/download/v1.4.0/dist.luau"))()

local app = cascade.New({
    WindowPill = true,
    Theme = cascade.Themes.Dark,
    Accent = cascade.Accents.Blue,
})

local window = app:Window({
    Title = "Cascade",
    Subtitle = "Жидкое стекло • macOS Edition",
    Size = UDim2.fromOffset(780, 490),
    UIBlur = false,
})

local rawBody = window.Structures.Body
local body = rawBody.__instance or rawBody

-- Защита от сброса при смерти персонажа
local screenGui = body:FindFirstAncestorOfClass("ScreenGui")
if screenGui then
    screenGui.ResetOnSpawn = false
end

-- Тонкий спекулярный кант macOS
local borderStroke = body:FindFirstChild("LiquidGlassStroke") or Instance.new("UIStroke")
borderStroke.Name = "LiquidGlassStroke"
borderStroke.Color = Color3.fromRGB(255, 255, 255)
borderStroke.Transparency = 0.82
borderStroke.Thickness = 1.2
borderStroke.Parent = body

-- Стилизация обсидианового полупрозрачного стекла
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

-- 4. НАКЛАДЫВАЕМ ЭФФЕКТ СТЕКЛА ЧЕРЕЗ БИБЛИОТЕКУ LIQUID GLASS
local glass = LiquidGlass.attach(body, {
    CornerRadius        = 15,    -- Радиус скругления углов (px)
    CornerRefraction    = 6.0,   -- Сила оптического искажения по углам
    RimScale            = 2.3,   -- Масштаб толщины фаски преломления
    FrostBlur           = 0.25,  -- Локальный матовый блюр под окном
    EdgeRefraction      = 1.1,   -- Преломление вдоль граней окна
    BlurKernelInset     = 32,    -- Защита от ореола блюра вокруг окна
    WindowTransparency  = windowTransparency,
    HighlightBoost      = 1.00,  -- Яркость спекулярного канта
    JellyPhysics        = false, -- Инерционное покачивание окна при перетаскивании
    Enabled             = true,
})

-- 5. ПЛАВНЫЕ ПЕРЕХОДЫ ВКЛАДОК
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

-- 6. СОЗДАНИЕ ВКЛАДОК И СТЕППЕРОВ
local section = window:Section({
    Title = "Жидкое стекло",
    Disclosure = false,
})

local tabRefraction = section:Tab({
    Selected = true,
    Title = "Преломление",
    Icon = cascade.Symbols.sliderHorizontal3,
})

local tabParameters = section:Tab({
    Selected = false,
    Title = "Параметры",
    Icon = cascade.Symbols.gear,
})

local tabAbout = section:Tab({
    Selected = false,
    Title = "О модуле",
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

-- ВКЛАДКА 1: Преломление
do
    local form = tabRefraction:Form()

    local rowCorner = titledRow(form, "Преломление углов", "Сила оптического искажения линз на скруглениях [ - / + ]")
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

    local rowRadius = titledRow(form, "Радиус углов", "Скругление углов окна и базовый радиус линзы (px) [ - / + ]")
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

    local rowRim = titledRow(form, "Ширина фаски / Rim", "Толщина оптической каймы преломления [ - / + ]")
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

    local rowFrost = titledRow(form, "Матовый блюр (Frost)", "Локальное размытие под окном без замыливания экрана [ - / + ]")
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

    local rowEdge = titledRow(form, "Преломление граней", "Коэффициент преломления вдоль прямых сторон окна")
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

    local rowToggle = titledRow(form, "Эффект жидкого стекла", "Включить / отключить 3D-меши преломления и матовый блюр")
    rowToggle:Right():Toggle({
        Value = glass.Config.Enabled,
        ValueChanged = function(self, val)
            glass:SetEnabled(val)
        end,
    })
end

-- ВКЛАДКА 2: Параметры
do
    local form = tabParameters:Form()

    local rowInset = titledRow(form, "Отступ блюра (Kernel Inset)", "Защитный внутренний отступ для предотвращения ореола размытия")
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

    local rowOpacity = titledRow(form, "Прозрачность окна", "Базовая прозрачность обсидианового тела окна")
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

    local rowHighlight = titledRow(form, "Яркость канта (Highlight)", "Прозрачность светоотражающей каймы (по умолчанию: 1.00)")
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

    local rowPhysics = titledRow(form, "Физика желе (Jelly Drag)", "Органическое покачивание окна при перетаскивании курсором")
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

-- ВКЛАДКА 3: О модуле
do
    local form = tabAbout:Form()

    local rowStatus = titledRow(form, "Статус подключения", "Библиотека LiquidGlass успешно загружена из репозитория GitHub")
    rowStatus:Right():Button({
        Label = "Проверено",
        Pushed = function()
            print("[Cascade] LiquidGlass.luau успешно подключен из сурсов GitHub!")
        end,
    })
end

task.delay(0.1, applyTranslucency)
task.delay(0.5, applyTranslucency)

print("[Cascade] Аутентичное жидкое стекло macOS подключено через сурсы GitHub!")
