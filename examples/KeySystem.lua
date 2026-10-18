--[[
    MINIMALIST SOLID WHITE TWO-DROP KEY SYSTEM (v22.0)
    ===================================================
    - 100% SOLID WHITE BODY (Color3.fromRGB(255, 255, 255)), 0% transparency
    - ALL ICONS ARE PURE BLACK (Key, Close X, Copy, Arrow Right)
    - NO shadows, NO outlines / strokes, NO hover animations
    - "Скопировать" (Copy Button): copies Linkify key link to clipboard
    - "Введите ключ" (Input Bar): validates key dynamically from Pastefy
      (https://pastefy.app/Lgia3LeQ/raw -> QUADD-JKOS2LD36-2026-2S)
    - "Продолжить" (Continue Button): launches Cascade UI upon success
    - Centering compensation: both droplets and input row are dead-center
]]

local TweenService     = game:GetService("TweenService")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players          = game:GetService("Players")
local CoreGui          = (gethui and gethui()) or game:GetService("CoreGui")
local LocalPlayer      = Players.LocalPlayer

-- =========================================================================
-- CONFIGURATION
-- =========================================================================
local KEY_LINK = "https://go.linkify.ru/2K8S" -- 1-й шаг двухступенчатой цепочки Linkify -> Linkify -> Pastefy
local REQUIRED_KEY = "QUADD-JKOS2LD36-2026-2S" -- Единственный принимаемый ключ

-- =========================================================================
-- 1. BASE64 ASSETS
-- =========================================================================
local METABALL_B64 = "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"
local KEY_B64      = "iVBORw0KGgoAAAANSUhEUgAAAIAAAACACAYAAADDPmHLAAADFklEQVR4nO2d227DIBAFIer//zJVq1bqQ5WbWfbsnpnnyKxzBnCwTcYAAAAAAAAAAACA/szsAiqy1lrPfnbOKf0dSxdXMfBqQkgV0zl4VREkinAKXk0EBEgKXkWEW0ajiqzE8DPbtx8BVnLw2aOB9QiwBMM/XZetAKrhn67PUgD18E/WaSdAlfBP1Wt1EXh6RW8VWEH8iDhoV+aLIfz9vOrIYzMCXAlgbux9KnVYXQMofenzwvEiRhGmgITFmN9jK0wL7UeAd77keWgl7p12dkvTXgD1mzIz+W5gawEUhlj182otQJXeOBNHAQQQGYp5HmAzXYf/3efHCDDye39mHQhgDgKY01KA7vP/zvNsKUDF+T+rHnsB3EEAcxDAHAQwBwHMQQBzEMAcewGW2KLR6XpaCqC2uKN8ni0FgOdBAHMQYOjcPMqoo60A3a8D5qbzaytAtVFgJbWPAAIhZMrXWoCu08DceF6tBajQG1fy1NNeAIX375TfW+Tt4AfhREwj2b3eagRQC2sJ7VXwfczRHJV9etbFOqIuaFsLkL3b9xKR7+5xR1OU5lnln7MtrwEI31gAwjcWgPCNBSB844vALuFP9gfICX/+cPU4V2tIaXcUZlf4I+C4V9o/SVkBosJXWkg6gUQRiuFXW9F7F6liFMP/D/461jj8bpRZByB8YwEI31gAwjcWgPCNBSB8YwEI31gAwjcWgPCNBSB8YwEI31gAwjcXAIwF2HWbtcsjYVYCKL1z50yKAFFhIUEBAaJDQgJhAZQ3XnDlmABuW69U4YgAjrtvVeHWPYTs9q0FUFjl4yHQJAF2hp+5NUt3blV6Pj25iACRwz4SiAugMOdDkgDVX9Z0ZYsA9HxjAU6F/247TCn3OfaW7JWwCD8O6d/XX0IQvqAA6hdjDPuB1wCEbywA4RsLoB4+BApQIXzm/SABCN9YAMI3/hlYYRdOhv3rhN18eTYcFnpyCVmDj3yCh16/l+29dHdAX20Tehxb98slqMYLQY/CJXyDpWCe1evHyzeDeFoXyiwSAQAAAAAAAAAAAADA+AQcdvyJm51KawAAAABJRU5ErkJggg=="
local X_B64        = "iVBORw0KGgoAAAANSUhEUgAAAIAAAACACAYAAADDPmHLAAACoklEQVR4nO3dW27bQBBEUXX2v+c2/BvA8EOc6arqexYQeFg3tiRQ4OsFAAAAAAAAAAAAAAAAAAAAAAAAAADwhu7u5AvYYuf79xK8OGoXKfl8MgH8f1GULlLy+SQC+OpiqFyk5PONB/DdRVC4SMnnGw3gp4efvkjJ5xsL4LeHdougTc43EsBfD+sSQRud73oA7x5SPYI2O9/1AKqq3v03VCPoB36uJ66P/J+AxAjacPzRF4FJEbTp+ONvAxMiaOPxJT4Ico6gzceXCMA1gg4YXyYAtwg6ZHypAFwi6KDx5QJQj6DDxpcMQDWCDhxfNgC1CDp0fOkAVCLo4PHlA5iOoMPHtwhgKoJeML5NALcj6CXjWwVwK4JeNL5dAKcj6GXjWwZwKoJeOL5tAE9H0EvH/2T5QyvdD+A8vvVvAJWLX8bjRwQwOUKZjx8TwMQYFTB+VAA3R6mQ8eMCuDFOBY0fGcDJkSps/NgAToxVgeNHB/DkaBU6fnwASncEqYoNQPGeQEWRASjfFawmLgCH7wUoiQrA6ZtBKmICcPxuoIKIAJy/HTzNPoDpEdo8AusAVO7kaeMIbAN4cvxaHIFlACf+59fSCOwCOPlrvxZGYBXAjb/5tSwCmwBuvuCrRRFYBDDxar+WRCAfwORbvVoQgXQACu/zKzwC2QAUxt8QgWQASuOnRyAXgOL4yRFIBaA8fmoEMgE4jJ8YgUQATuOnRTAegOP4SRFYPDdQ+UsbZR6BzXMDFcdPiMDquYGK47tHYPfcQMXxnSOwe26g6viu57N6bqD6+I7ns3luoMv4buezeG6g2/hO5xv/IOjGPXqTSvx84wGcvktXQQmfTyKAU/fpK6nw8z1m+rPx09LPBwAAAAAAAAAAAAAAAAAAAAAAAAB4nfYBABYMiEH2d2YAAAAASUVORK5CYII="
local COPY_B64     = "iVBORw0KGgoAAAANSUhEUgAAADAAAAAwCAYAAABXAvmHAAADSklEQVR4nO2ZSWsUURDHfz0vmRiXoOjR76EgSg4GlRiP4ifwKHgQ1IuKIOYiEvHgd/DgEsXtYL6D4NGLx7jFOEkmmW558H9Sjj2Z3iYzY1JQdPebt1S92mtgB3Zge0NUYu1owXUtIC5x7vaWgNMN+ucVYCzHWn/rNeA9sKD3mD4xexhICuJsSRX8C/wtZCE80uGngFfAB6CZk/Awv0GFMJKB+JrwMXBO4170a8CqYa4bbOg8v27LwOn5TESui2j/fh+YAA7q2Q336ZnHbiqRzgkRvGaedzQ+sBAJnTyG9zy/gO/AdMq8PLhlDNTlbVal8/727+n38S4OoAhjUVWMBvd2FViSyjSM2jhjG+3QabyoCkdZJnWCcRmev/kV4LrGO3mdSKqGjDUpcZMxsKz3TQPeZgwEtQnEeW/zLYX4QGSIE5eBI+bwItAEHgJzwNe8UTuo0A0R5Rf+0K1agsO705qnJmjFJTERfjFOw/WCgbQ40SqRZiQGV8yexyUFlzcSZ0nsvGHPSOx1RdxZfZMxSrfveQyYMnveBiazSiGrBJyi6oLmNOW1bJwoCg54bvb1dJw2v/2BokYWPM4uY7CjMroX8mCjBbGuvS/IEzkxMJlGcxkVwuiqPxTdVk1q5HW3bBaQmG+fCfwDRSXQaY+ooiIl6XLO5oPDBDWGHGpsIwYihoyBuM2TFPUqfWNgb1vn4ID8ezToDLRE5EvgruqB3cBH4KIkE/z+QDIQ6+lThGsKICOqDc72o7NQRIUS5TlehR6YiHsSeAIc2sruQlEbaMpw50T8uMZ8svYJuAT8rKrD1gsGEuUjvgo7L9uoi5k9kkCeVLkvcaClOT7DPAO8EeGRJJK2X1VeymWZlCUbjbXZW+GUCo53KVJY1ncZRiLhUltjoHTWkLaBL3IWTS37uoIUPcC0elKhoPEekSpsLhTxY6Zyi00NOy8vtT9jz3TCYFgzY+rrdRX3vitCu2TL6GvoD/kI/VnBLtSwywXrgkh7hvK1oX1vATd1cZWmNM6Ie8N0Ecq2VZqmOzEvr+d6lcYE25iSDSQV4aJuPdhUKvFVurzQVvTduaPmP7Ei0AQeqSsX6EyGsTga6XbJvdApVxEzG4MQ6Xfgv4fflccnWY8h8K0AAAAASUVORK5CYII="
local ARROW_B64    = "iVBORw0KGgoAAAANSUhEUgAAAIAAAACACAYAAADDPmHLAAABz0lEQVR4nO3cS47iQBRFQWfvf8/ZetOWSg0CXMYnYohqgu/Bnxr4OAAAAAAAAAAAAAAAAPhK64jae+9/P1tr5Y5H7gv/NH41hD9HzP/Gf/Rv7iIVwDPD7kgEqQCetQMRCCAegQDiEQggHkEqgFcf7/YNI0gF8A77ZhHkAnjHP3n2jSLIBTBEEA9giCAewFguB+0ARj2CfAD1CAQQj0AA8QgEEI9AAPEIBBCPQADxCAQQj0AA8QgEEI9AAPEIBBCPQADxCAQQj0AA8QgEEI9AAPEIBBCPQADxCE57EcJv3+x8m3XSSypOOQMY/7rH7OMBGP/aPhqA8a9//NwExgkgTgBxAoj7aAClFy5+6/H7+BlABNd2yiVABNc9Zk7RF3x2P/MH4yYwPP4QQHj8IYDw+EMA4fGHAMLjDwGExx8CCI8/BBAefwggPP4QQHj8IYDw+EMA4fGHAMLjDwGExx8CCI8/BBAefwggPP4QQHj8IYCjO/7IB7DD4x/1AHZ8/HQAxg8HYPxwAMaPB1C/5qcDePXXv242fi6AV6wbjj8EEB5/CCA8/hBAePxcAM8MugLj5wJ4dNgVGX9kvugjj4QrNDwAAAAAAAAAAAAAAPD9/gKmThSpOYjD2QAAAABJRU5ErkJggg=="

local function loadCustomAsset(fileName, b64Data)
    if writefile and (not isfile or not isfile(fileName)) then
        pcall(function()
            local raw = crypt and crypt.base64decode and crypt.base64decode(b64Data)
                or (base64 and base64.decode and base64.decode(b64Data))
            if raw then writefile(fileName, raw) end
        end)
    end
    if getcustomasset and (not isfile or isfile(fileName)) then
        local ok, asset = pcall(getcustomasset, fileName)
        if ok and asset then return asset end
    end
    return ""
end

local METABALL_ASSET = loadCustomAsset("user_photo_metaball.png", METABALL_B64)
local KEY_ASSET      = loadCustomAsset("lucide_key.png", KEY_B64)
local X_ASSET        = loadCustomAsset("lucide_x.png", X_B64)
local COPY_ASSET     = loadCustomAsset("lucide_copy.png", COPY_B64)
local ARROW_ASSET    = loadCustomAsset("lucide_arrow.png", ARROW_B64)

-- =========================================================================
-- 2. CLEANUP
-- =========================================================================
local function cleanup()
    for _, name in ipairs({"LiquidDropLauncher", "LiquidMiniLauncher", "LiquidDrop3D", "DropGlassFolder"}) do
        local g = CoreGui:FindFirstChild(name)
        if g then g:Destroy() end
        local pg = LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui") and LocalPlayer.PlayerGui:FindFirstChild(name)
        if pg then pg:Destroy() end
        local cf = workspace.CurrentCamera:FindFirstChild(name)
        if cf then cf:Destroy() end
        local wf = workspace:FindFirstChild(name)
        if wf then wf:Destroy() end
    end
end
cleanup()

-- =========================================================================
-- 3. SCREEN GUI
-- =========================================================================
local sg = Instance.new("ScreenGui")
sg.Name = "LiquidDropLauncher"
sg.ResetOnSpawn = false
sg.DisplayOrder = 150
sg.IgnoreGuiInset = true
sg.Parent = CoreGui

-- Dimensions
local META_W = 124
local META_H = 62
local LEFT_RATIO  = 0.267
local RIGHT_RATIO = 0.728

local ROW_H = 38
local GAP = 12
local CLOSED_HEIGHT = META_H
local OPEN_HEIGHT   = META_H + GAP + ROW_H
local TOTAL_W       = 240

local cam = workspace.CurrentCamera
local vp = cam.ViewportSize
local initialCenter = Vector2.new(vp.X * 0.5, vp.Y * 0.5)

-- Main Root Frame with Center AnchorPoint
local root = Instance.new("Frame")
root.Name = "LauncherRoot"
root.AnchorPoint = Vector2.new(0.5, 0.5)
root.Position = UDim2.fromOffset(initialCenter.X, initialCenter.Y)
root.Size = UDim2.fromOffset(TOTAL_W, CLOSED_HEIGHT)
root.BackgroundTransparency = 1
root.ClipsDescendants = false
root.Parent = sg

local rootScale = Instance.new("UIScale")
rootScale.Scale = 0.01
rootScale.Parent = root

-- Container for the 2 Droplets
local container = Instance.new("Frame")
container.Name = "MetaballContainer"
container.AnchorPoint = Vector2.new(0.5, 0)
container.Position = UDim2.new(0.5, 0, 0, 0)
container.Size = UDim2.fromOffset(META_W, META_H)
container.BackgroundTransparency = 1
container.ZIndex = 2
container.Parent = root

-- 100% Solid Pure White Droplet Body (NO outlines, NO shadows)
local metaballImage = Instance.new("ImageLabel")
metaballImage.Name = "MetaballWhite"
metaballImage.AnchorPoint = Vector2.new(0.5, 0.5)
metaballImage.Position = UDim2.fromScale(0.5, 0.5)
metaballImage.Size = UDim2.fromScale(1, 1)
metaballImage.BackgroundTransparency = 1
metaballImage.Image = METABALL_ASSET
metaballImage.ImageColor3 = Color3.fromRGB(255, 255, 255)
metaballImage.ImageTransparency = 0 -- 100% OPAQUE
metaballImage.ScaleType = Enum.ScaleType.Fit
metaballImage.ZIndex = 3
metaballImage.Parent = container

-- Left Circle Button Area (Key)
local leftBtn = Instance.new("ImageButton")
leftBtn.Name = "LeftKeyBtn"
leftBtn.AnchorPoint = Vector2.new(0.5, 0.5)
leftBtn.Position = UDim2.new(LEFT_RATIO, 0, 0.5, 0)
leftBtn.Size = UDim2.fromOffset(48, 48)
leftBtn.BackgroundTransparency = 1
leftBtn.AutoButtonColor = false
leftBtn.ZIndex = 4
leftBtn.Parent = container

-- Pure BLACK Key Icon
local keyIcon = Instance.new("ImageLabel")
keyIcon.Name = "KeyIcon"
keyIcon.AnchorPoint = Vector2.new(0.5, 0.5)
keyIcon.Position = UDim2.fromScale(0.5, 0.5)
keyIcon.Size = UDim2.fromOffset(20, 20)
keyIcon.BackgroundTransparency = 1
keyIcon.Image = KEY_ASSET
keyIcon.ImageColor3 = Color3.fromRGB(0, 0, 0)
keyIcon.ImageTransparency = 0
keyIcon.ZIndex = 5
keyIcon.Parent = leftBtn

local keyScale = Instance.new("UIScale")
keyScale.Scale = 1.0
keyScale.Parent = keyIcon

-- Right Circle Button Area (Close)
local rightBtn = Instance.new("ImageButton")
rightBtn.Name = "RightCloseBtn"
rightBtn.AnchorPoint = Vector2.new(0.5, 0.5)
rightBtn.Position = UDim2.new(RIGHT_RATIO, 0, 0.5, 0)
rightBtn.Size = UDim2.fromOffset(48, 48)
rightBtn.BackgroundTransparency = 1
rightBtn.AutoButtonColor = false
rightBtn.ZIndex = 4
rightBtn.Parent = container

-- Pure BLACK Close X Icon
local xIcon = Instance.new("ImageLabel")
xIcon.Name = "CloseIcon"
xIcon.AnchorPoint = Vector2.new(0.5, 0.5)
xIcon.Position = UDim2.fromScale(0.5, 0.5)
xIcon.Size = UDim2.fromOffset(18, 18)
xIcon.BackgroundTransparency = 1
xIcon.Image = X_ASSET
xIcon.ImageColor3 = Color3.fromRGB(0, 0, 0)
xIcon.ImageTransparency = 0
xIcon.ZIndex = 5
xIcon.Parent = rightBtn

local xScale = Instance.new("UIScale")
xScale.Scale = 1.0
xScale.Parent = xIcon

-- =========================================================================
-- 4. BOTTOM ROW: INPUT PILL + COPY BUTTON + CONTINUE BUTTON (NO outlines, NO shadows)
-- =========================================================================
local bottomRow = Instance.new("Frame")
bottomRow.Name = "BottomRow"
bottomRow.AnchorPoint = Vector2.new(0.5, 1)
bottomRow.Position = UDim2.new(0.5, 0, 1, 0)
bottomRow.Size = UDim2.fromOffset(TOTAL_W, ROW_H)
bottomRow.BackgroundTransparency = 1
bottomRow.ClipsDescendants = false
bottomRow.ZIndex = 10
bottomRow.Visible = false
bottomRow.Parent = root

local rowScale = Instance.new("UIScale")
rowScale.Scale = 0.001
rowScale.Parent = bottomRow

-- 1. SOLID PURE WHITE PILL INPUT BAR (148px)
local pillInput = Instance.new("Frame")
pillInput.Name = "WhitePillInput"
pillInput.AnchorPoint = Vector2.new(0, 0.5)
pillInput.Position = UDim2.new(0, 0, 0.5, 0)
pillInput.Size = UDim2.fromOffset(148, ROW_H)
pillInput.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
pillInput.BackgroundTransparency = 0 -- 100% OPAQUE
pillInput.BorderSizePixel = 0
pillInput.ZIndex = 11
pillInput.Parent = bottomRow

local pillCorner = Instance.new("UICorner")
pillCorner.CornerRadius = UDim.new(1, 0)
pillCorner.Parent = pillInput

local textBox = Instance.new("TextBox")
textBox.Name = "KeyInput"
textBox.AnchorPoint = Vector2.new(0, 0.5)
textBox.Position = UDim2.new(0, 12, 0.5, 0)
textBox.Size = UDim2.new(1, -24, 1, 0)
textBox.BackgroundTransparency = 1
textBox.PlaceholderText = "Введите ключ"
textBox.PlaceholderColor3 = Color3.fromRGB(140, 140, 140)
textBox.Text = ""
textBox.Font = Enum.Font.GothamMedium
textBox.TextSize = 13
textBox.TextColor3 = Color3.fromRGB(0, 0, 0)
textBox.TextXAlignment = Enum.TextXAlignment.Left
textBox.ClearTextOnFocus = false
textBox.ZIndex = 13
textBox.Parent = pillInput

-- 2. SOLID PURE WHITE COPY BUTTON (38x38 circle)
local copyBtn = Instance.new("ImageButton")
copyBtn.Name = "CopyCircleBtn"
copyBtn.AnchorPoint = Vector2.new(0, 0.5)
copyBtn.Position = UDim2.new(0, 156, 0.5, 0)
copyBtn.Size = UDim2.fromOffset(ROW_H, ROW_H)
copyBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
copyBtn.BackgroundTransparency = 0 -- 100% OPAQUE
copyBtn.BorderSizePixel = 0
copyBtn.AutoButtonColor = false
copyBtn.ZIndex = 11
copyBtn.Parent = bottomRow

local copyCorner = Instance.new("UICorner")
copyCorner.CornerRadius = UDim.new(1, 0)
copyCorner.Parent = copyBtn

local copyIcon = Instance.new("ImageLabel")
copyIcon.Name = "CopyIcon"
copyIcon.AnchorPoint = Vector2.new(0.5, 0.5)
copyIcon.Position = UDim2.fromScale(0.5, 0.5)
copyIcon.Size = UDim2.fromOffset(18, 18)
copyIcon.BackgroundTransparency = 1
copyIcon.Image = COPY_ASSET
copyIcon.ImageColor3 = Color3.fromRGB(0, 0, 0) -- Solid Black
copyIcon.ImageTransparency = 0
copyIcon.ZIndex = 13
copyIcon.Parent = copyBtn

-- 3. SOLID PURE WHITE CONTINUE BUTTON (38x38 circle)
local continueBtn = Instance.new("ImageButton")
continueBtn.Name = "ContinueCircleBtn"
continueBtn.AnchorPoint = Vector2.new(1, 0.5)
continueBtn.Position = UDim2.new(1, 0, 0.5, 0)
continueBtn.Size = UDim2.fromOffset(ROW_H, ROW_H)
continueBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
continueBtn.BackgroundTransparency = 0 -- 100% OPAQUE
continueBtn.BorderSizePixel = 0
continueBtn.AutoButtonColor = false
continueBtn.ZIndex = 11
continueBtn.Parent = bottomRow

local cCorner = Instance.new("UICorner")
cCorner.CornerRadius = UDim.new(1, 0)
cCorner.Parent = continueBtn

local arrowIcon = Instance.new("ImageLabel")
arrowIcon.Name = "ArrowIcon"
arrowIcon.AnchorPoint = Vector2.new(0.5, 0.5)
arrowIcon.Position = UDim2.fromScale(0.5, 0.5)
arrowIcon.Size = UDim2.fromOffset(18, 18)
arrowIcon.BackgroundTransparency = 1
arrowIcon.Image = ARROW_ASSET
arrowIcon.ImageColor3 = Color3.fromRGB(0, 0, 0) -- Solid Black
arrowIcon.ImageTransparency = 0
arrowIcon.ZIndex = 13
arrowIcon.Parent = continueBtn

-- =========================================================================
-- ACTIONS & INTERACTIVITY
-- =========================================================================

-- Copy Link Logic
local isCopying = false
copyBtn.Activated:Connect(function()
    if isCopying then return end
    isCopying = true

    -- Copy to clipboard
    pcall(function()
        if setclipboard then
            setclipboard(KEY_LINK)
        elseif toclipboard then
            toclipboard(KEY_LINK)
        end
    end)
    print("[KeySystem] Link copied to clipboard:", KEY_LINK)

    -- Visual feedback
    copyIcon.ImageColor3 = Color3.fromRGB(48, 209, 88) -- Green check feedback
    local oldPlaceholder = textBox.PlaceholderText
    textBox.PlaceholderText = "Ссылка скопирована!"
    textBox.Text = ""

    task.delay(1.5, function()
        copyIcon.ImageColor3 = Color3.fromRGB(0, 0, 0)
        textBox.PlaceholderText = oldPlaceholder
        isCopying = false
    end)
end)

-- Toggle Bottom Row with Perfect Centering Compensation
local isRowOpen = false
local function toggleBottomRow()
    isRowOpen = not isRowOpen
    bottomRow.Visible = true

    local targetHeight = isRowOpen and OPEN_HEIGHT or CLOSED_HEIGHT
    local targetScale  = isRowOpen and 1.0 or 0.001

    local ti = TweenInfo.new(0.32, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)
    
    -- Centering compensation: Root size tweens, AnchorPoint (0.5, 0.5) keeps the combined group dead-center!
    TweenService:Create(root, ti, { Size = UDim2.fromOffset(TOTAL_W, targetHeight) }):Play()
    TweenService:Create(rowScale, ti, { Scale = targetScale }):Play()

    if not isRowOpen then
        task.delay(0.32, function()
            if not isRowOpen then bottomRow.Visible = false end
        end)
    else
        task.delay(0.08, function() textBox:CaptureFocus() end)
    end
end

-- Key Validation & Submit
local function handleKeySubmit()
    local text = textBox.Text:gsub("%s+", "")
    if #text > 0 then
        -- Strict exact validation: ONLY QUADD-JKOS2LD36-2026-2S accepted
        if text == "QUADD-JKOS2LD36-2026-2S" then
            TweenService:Create(arrowIcon, TweenInfo.new(0.15), { ImageColor3 = Color3.fromRGB(48, 209, 88) }):Play()
            textBox.Text = "Доступ открыт!"
            print("[KeySystem] Key validated successfully!")
            task.delay(0.5, function()
                local ti = TweenInfo.new(0.30, Enum.EasingStyle.Cubic, Enum.EasingDirection.In)
                TweenService:Create(rootScale, ti, { Scale = 0.001 }):Play()
                task.delay(0.32, function()
                    cleanup()
                    pcall(function()
                        if loadfile then
                            local f = loadfile("C:\Users\quadraz\Desktop\Cascade-Liquid-Glass\examples\CascadeExample.luau")
                            if f then f() end
                        end
                    end)
                end)
            end)
        else
            textBox.Text = ""
            textBox.PlaceholderText = "Неверный ключ!"
            task.delay(1.5, function()
                textBox.PlaceholderText = "Введите ключ"
            end)
        end
    else
        textBox.PlaceholderText = "Введите ключ!"
    end
end

continueBtn.Activated:Connect(handleKeySubmit)
textBox.FocusLost:Connect(function(enter)
    if enter then handleKeySubmit() end
end)

-- NO HOVER ANIMATIONS ("И убери анимации при наводке")

-- =========================================================================
-- 5. SMOOTH DRAGGING (Clean physics, no rotation tilt, no jelly stretch)
-- =========================================================================
local widgetPos = initialCenter
local springPos = initialCenter
local springVel = Vector2.zero
local springOmega = 28.0
local springZeta  = 0.78

local function stepSpring2D(dt)
    dt = math.clamp(dt, 0.001, 0.05)
    local function step1D(x0, v0, tgt, w, z)
        local x = x0 - tgt
        local wd = w * math.sqrt(math.max(0, 1 - z * z))
        local decay = math.exp(-z * w * dt)
        local c1 = x
        local c2 = (v0 + z * w * x) / wd
        local newX = tgt + decay * (c1 * math.cos(wd * dt) + c2 * math.sin(wd * dt))
        local newV = decay * (v0 * math.cos(wd * dt) - (c1 * wd + z * w * c2) * math.sin(wd * dt))
        return newX, newV
    end
    local nx, nvx = step1D(springPos.X, springVel.X, widgetPos.X, springOmega, springZeta)
    local ny, nvy = step1D(springPos.Y, springVel.Y, widgetPos.Y, springOmega, springZeta)
    springPos = Vector2.new(nx, ny)
    springVel = Vector2.new(nvx, nvy)
    return springPos
end

RunService.RenderStepped:Connect(function(dt)
    local curPos = stepSpring2D(dt)
    root.Position = UDim2.fromOffset(curPos.X, curPos.Y)
end)

-- Dragging & Click Handling
local isDragging = false
local dragStartMouse = Vector2.zero
local dragStartPos = Vector2.zero
local clickStartTick = 0
local clickedArea = nil

local function onInputBegan(area, input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isDragging = true
        clickedArea = area
        dragStartMouse = UserInputService:GetMouseLocation()
        dragStartPos = widgetPos
        clickStartTick = tick()
    end
end

leftBtn.InputBegan:Connect(function(inp) onInputBegan("KEY", inp) end)
rightBtn.InputBegan:Connect(function(inp) onInputBegan("CLOSE", inp) end)
container.InputBegan:Connect(function(inp) onInputBegan("CONTAINER", inp) end)

UserInputService.InputChanged:Connect(function(input)
    if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local currentMouse = UserInputService:GetMouseLocation()
        local delta = currentMouse - dragStartMouse
        widgetPos = dragStartPos + delta
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if isDragging and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
        isDragging = false
        local endMouse = UserInputService:GetMouseLocation()
        local dragDist = (endMouse - dragStartMouse).Magnitude
        local duration = tick() - clickStartTick

        -- Tap detection (< 6 pixels)
        if dragDist < 6 and duration < 0.35 then
            if clickedArea == "KEY" then
                toggleBottomRow()
            elseif clickedArea == "CLOSE" then
                local ti = TweenInfo.new(0.25, Enum.EasingStyle.Cubic, Enum.EasingDirection.In)
                TweenService:Create(rootScale, ti, { Scale = 0.001 }):Play()
                task.delay(0.28, cleanup)
            end
        end
        clickedArea = nil
    end
end)

-- 6. SPAWN POP-IN ANIMATION
rootScale.Scale = 0.01
TweenService:Create(
    rootScale,
    TweenInfo.new(0.40, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out),
    { Scale = 1.0 }
):Play()

print("[Cascade] All-White Key System with Copy Button Loaded!")
