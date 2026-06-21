-- GaG2 Crop Value Display - Final + Hotbar Fix
-- Executor Script (Synapse X / KRNL / Delta etc.)

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer
local playerGui = player.PlayerGui

local function fmt(n)
    if n >= 1e9 then      return string.format("$%.2fB", n/1e9)
    elseif n >= 1e6 then  return string.format("$%.3fM", n/1e6)
    elseif n >= 1000 then return string.format("$%.1fK", n/1000)
    else                   return "$"..tostring(math.floor(n))
    end
end

local PRICE_PER_KG = {
    ["Carrot"]          = 9,
    ["Strawberry"]      = 3,
    ["Blueberry"]       = 5,
    ["Tulip"]           = 346,
    ["Tomato"]          = 11,
    ["Apple"]           = 11,
    ["Bamboo"]          = 722,
    ["Corn"]            = 31,
    ["Cactus"]          = 36,
    ["Pineapple"]       = 27,
    ["Baby Cactus"]     = 63,
    ["Horned Melon"]    = 1650,
    ["Mushroom"]        = 11700,
    ["Green Bean"]      = 70,
    ["Banana"]          = 32,
    ["Grape"]           = 41,
    ["Coconut"]         = 54,
    ["Mango"]           = 81,
    ["Glow Mushroom"]   = 632,
    ["Dragon Fruit"]    = 135,
    ["Acorn"]           = 180,
    ["Cherry"]          = 316,
    ["Sunflower"]       = 1580,
    ["Poison Ivy"]      = 1530,
    ["Venus Fly Trap"]  = 2710,
    ["Pomegranate"]     = 812,
    ["Poison Apple"]    = 812,
    ["Ghost Pepper"]    = 2260,
    ["Moon Bloom"]      = 8120,
    ["Dragon's Breath"] = 3070,
}

local MUTATION_MULT = {
    ["Electric"]   = 5.10,
    ["Aurora"]     = 9.69,
    ["Frozen"]     = 4.41,
    ["Gold"]       = 10,
    ["Bloodlit"]   = 10,
    ["Rainbow"]    = 30,
    ["Starstruck"] = 50,
    ["Solarflare"] = 5,
}

local MUTATION_COLOR = {
    ["Electric"]   = Color3.fromRGB(100, 180, 255),
    ["Aurora"]     = Color3.fromRGB(160, 80,  255),
    ["Frozen"]     = Color3.fromRGB(80,  210, 255),
    ["Gold"]       = Color3.fromRGB(255, 200, 0),
    ["Bloodlit"]   = Color3.fromRGB(200, 30,  30),
    ["Rainbow"]    = Color3.fromRGB(255, 120, 200),
    ["Starstruck"] = Color3.fromRGB(255, 240, 100),
    ["Solarflare"] = Color3.fromRGB(255, 140, 0),
}

local function calcValue(name, weight, sizeMult, mutation)
    local base    = PRICE_PER_KG[name] or 0
    local mutMult = (mutation and mutation ~= "" and MUTATION_MULT[mutation]) or 1
    return math.floor(base * weight * sizeMult * mutMult)
end

local function tierColor(val)
    if val >= 10e6 then       return Color3.fromRGB(220, 80,  255)
    elseif val >= 1e6 then    return Color3.fromRGB(255, 60,  60)
    elseif val >= 100000 then return Color3.fromRGB(255, 140, 0)
    elseif val >= 10000 then  return Color3.fromRGB(255, 215, 0)
    elseif val >= 1000 then   return Color3.fromRGB(100, 180, 255)
    else                      return Color3.fromRGB(180, 180, 180)
    end
end

-- ===== getCrops: สแกน Backpack + Character + Tool (hotbar) =====
local function getCrops()
    local crops = {}
    local seen = {}

    local function tryAdd(item)
        if seen[item] then return end
        seen[item] = true

        local harvested = item:GetAttribute("HarvestedFruit")
        local name      = item:GetAttribute("FruitName") or ""
        local weight    = item:GetAttribute("Weight") or 0
        local sizeMult  = item:GetAttribute("SizeMultiplier") or 1
        local mutation  = item:GetAttribute("Mutation") or ""
        if mutation == "None" then mutation = "" end

        if harvested == true and name ~= "" then
            local value = calcValue(name, weight, sizeMult, mutation)
            table.insert(crops, {
                name=name, weight=weight,
                sizeMult=sizeMult, mutation=mutation, value=value,
            })
        end
    end

    local function scanFolder(folder)
        if not folder then return end
        for _, item in ipairs(folder:GetChildren()) do
            if item:IsA("Configuration") then
                tryAdd(item)
            end
            if item:IsA("Tool") then
                tryAdd(item) -- attribute ติดกับ Tool โดยตรงตอนอยู่ hotbar
                for _, child in ipairs(item:GetChildren()) do
                    if child:IsA("Configuration") then
                        tryAdd(child)
                    end
                end
            end
        end
    end

    scanFolder(player.Backpack)
    if player.Character then
        scanFolder(player.Character)
    end

    table.sort(crops, function(a,b) return a.value > b.value end)
    return crops
end

-- ===== ลบ GUI เก่า =====
local old = playerGui:FindFirstChild("GaG2_UI")
if old then old:Destroy() end

local sg = Instance.new("ScreenGui")
sg.Name = "GaG2_UI"
sg.ResetOnSpawn = false
sg.DisplayOrder = 999
sg.IgnoreGuiInset = true
sg.Parent = playerGui

-- Panel
local panel = Instance.new("Frame")
panel.Size = UDim2.new(0, 310, 0, 500)
panel.Position = UDim2.new(0, 12, 0.5, -250)
panel.BackgroundColor3 = Color3.fromRGB(10, 10, 14)
panel.BackgroundTransparency = 0.08
panel.BorderSizePixel = 0
panel.Parent = sg
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 16)

local panelStroke = Instance.new("UIStroke")
panelStroke.Color = Color3.fromRGB(50, 50, 60)
panelStroke.Thickness = 1.5
panelStroke.Parent = panel

-- Title bar
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 44)
titleBar.BackgroundTransparency = 1
titleBar.BorderSizePixel = 0
titleBar.Parent = panel

local playerNameLbl = Instance.new("TextLabel")
playerNameLbl.Size = UDim2.new(1, -50, 1, 0)
playerNameLbl.Position = UDim2.new(0, 16, 0, 0)
playerNameLbl.BackgroundTransparency = 1
playerNameLbl.Text = player.Name
playerNameLbl.TextColor3 = Color3.fromRGB(200, 200, 200)
playerNameLbl.Font = Enum.Font.GothamBold
playerNameLbl.TextSize = 15
playerNameLbl.TextXAlignment = Enum.TextXAlignment.Left
playerNameLbl.Parent = titleBar

local minBtn = Instance.new("TextButton")
minBtn.Size = UDim2.new(0, 28, 0, 28)
minBtn.Position = UDim2.new(1, -38, 0.5, -14)
minBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
minBtn.BorderSizePixel = 0
minBtn.Text = "−"
minBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
minBtn.Font = Enum.Font.GothamBold
minBtn.TextSize = 16
minBtn.Parent = titleBar
Instance.new("UICorner", minBtn).CornerRadius = UDim.new(0, 6)

-- Total box
local totalBox = Instance.new("Frame")
totalBox.Size = UDim2.new(1, -20, 0, 56)
totalBox.Position = UDim2.new(0, 10, 0, 48)
totalBox.BackgroundColor3 = Color3.fromRGB(20, 10, 10)
totalBox.BorderSizePixel = 0
totalBox.Parent = panel
Instance.new("UICorner", totalBox).CornerRadius = UDim.new(0, 10)

local totalValLbl = Instance.new("TextLabel")
totalValLbl.Size = UDim2.new(1, 0, 1, 0)
totalValLbl.BackgroundTransparency = 1
totalValLbl.Text = "all $0"
totalValLbl.TextColor3 = Color3.fromRGB(255, 80, 80)
totalValLbl.Font = Enum.Font.GothamBold
totalValLbl.TextSize = 26
totalValLbl.Parent = totalBox

local allFruitsLbl = Instance.new("TextLabel")
allFruitsLbl.Size = UDim2.new(1, 0, 0, 24)
allFruitsLbl.Position = UDim2.new(0, 0, 0, 108)
allFruitsLbl.BackgroundTransparency = 1
allFruitsLbl.Text = "ALL FRUITS"
allFruitsLbl.TextColor3 = Color3.fromRGB(100, 100, 120)
allFruitsLbl.Font = Enum.Font.GothamBold
allFruitsLbl.TextSize = 11
allFruitsLbl.Parent = panel

-- Scroll
local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -16, 1, -148)
scroll.Position = UDim2.new(0, 8, 0, 134)
scroll.BackgroundTransparency = 1
scroll.ScrollBarThickness = 3
scroll.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 100)
scroll.BorderSizePixel = 0
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.Parent = panel

local ll = Instance.new("UIListLayout")
ll.SortOrder = Enum.SortOrder.LayoutOrder
ll.Padding = UDim.new(0, 6)
ll.Parent = scroll

local lpad = Instance.new("UIPadding")
lpad.PaddingLeft = UDim.new(0, 2)
lpad.PaddingRight = UDim.new(0, 2)
lpad.PaddingTop = UDim.new(0, 2)
lpad.Parent = scroll

-- ===== Drag =====
local dragging, dragStart, startPos = false, nil, nil
titleBar.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1
    or inp.UserInputType == Enum.UserInputType.Touch then
        dragging=true; dragStart=inp.Position; startPos=panel.Position
    end
end)
titleBar.InputEnded:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1
    or inp.UserInputType == Enum.UserInputType.Touch then
        dragging=false
    end
end)
UserInputService.InputChanged:Connect(function(inp)
    if dragging and (inp.UserInputType == Enum.UserInputType.MouseMovement
    or inp.UserInputType == Enum.UserInputType.Touch) then
        local d = inp.Position - dragStart
        panel.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + d.X,
            startPos.Y.Scale, startPos.Y.Offset + d.Y)
    end
end)

-- ===== Minimize =====
local minimized = false
local fullHeight = 500
minBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    scroll.Visible       = not minimized
    totalBox.Visible     = not minimized
    allFruitsLbl.Visible = not minimized
    minBtn.Text = minimized and "+" or "−"
    panel.Size = UDim2.new(0, 310, 0, minimized and 44 or fullHeight)
end)

-- ===== Row =====
local function makeRow(crop, order)
    local tc = tierColor(crop.value)
    local displayMut = crop.mutation ~= "" and (" ["..crop.mutation.."]") or ""
    local mutMult = MUTATION_MULT[crop.mutation]
    local mutColor = MUTATION_COLOR[crop.mutation] or Color3.fromRGB(180,180,180)
    local multTag = mutMult and string.format(" ×%.2fx", mutMult) or ""

    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 54)
    row.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
    row.BackgroundTransparency = 0
    row.BorderSizePixel = 0
    row.LayoutOrder = order
    row.Parent = scroll
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 10)

    if crop.mutation ~= "" then
        local badge = Instance.new("Frame")
        badge.Size = UDim2.new(0, 4, 1, -8)
        badge.Position = UDim2.new(0, 4, 0, 4)
        badge.BackgroundColor3 = mutColor
        badge.BorderSizePixel = 0
        badge.Parent = row
        Instance.new("UICorner", badge).CornerRadius = UDim.new(0, 3)
    end

    local nl = Instance.new("TextLabel")
    nl.Size = UDim2.new(0.58, 0, 0.5, 0)
    nl.Position = UDim2.new(0, 14, 0, 5)
    nl.BackgroundTransparency = 1
    nl.Text = crop.name .. displayMut
    nl.TextColor3 = crop.mutation ~= "" and mutColor or Color3.fromRGB(240,240,240)
    nl.Font = Enum.Font.GothamBold
    nl.TextSize = 13
    nl.TextXAlignment = Enum.TextXAlignment.Left
    nl.TextTruncate = Enum.TextTruncate.AtEnd
    nl.Parent = row

    local wl = Instance.new("TextLabel")
    wl.Size = UDim2.new(0.58, 0, 0.4, 0)
    wl.Position = UDim2.new(0, 14, 0.54, 0)
    wl.BackgroundTransparency = 1
    wl.Text = string.format("%.2fkg  ×%.2f size%s", crop.weight, crop.sizeMult, multTag)
    wl.TextColor3 = Color3.fromRGB(110, 110, 130)
    wl.Font = Enum.Font.Gotham
    wl.TextSize = 10
    wl.TextXAlignment = Enum.TextXAlignment.Left
    wl.Parent = row

    local vl = Instance.new("TextLabel")
    vl.Size = UDim2.new(0.4, -10, 1, 0)
    vl.Position = UDim2.new(0.6, 0, 0, 0)
    vl.BackgroundTransparency = 1
    vl.Text = fmt(crop.value)
    vl.TextColor3 = tc
    vl.Font = Enum.Font.GothamBold
    vl.TextSize = 17
    vl.TextXAlignment = Enum.TextXAlignment.Right
    vl.Parent = row
end

-- ===== Update =====
local function update()
    for _, c in ipairs(scroll:GetChildren()) do
        if c:IsA("Frame") then c:Destroy() end
    end

    local crops = getCrops()
    local grand = 0
    for i, crop in ipairs(crops) do
        makeRow(crop, i)
        grand = grand + crop.value
    end

    if #crops == 0 then
        local empty = Instance.new("TextLabel")
        empty.Size = UDim2.new(1, 0, 0, 50)
        empty.BackgroundTransparency = 1
        empty.Text = "No harvested crops found"
        empty.TextColor3 = Color3.fromRGB(130, 130, 150)
        empty.Font = Enum.Font.Gotham
        empty.TextSize = 12
        empty.Parent = scroll
    end

    scroll.CanvasSize = UDim2.new(0, 0, 0, #crops * 60 + 10)
    totalValLbl.Text = "all " .. fmt(grand)

    if not minimized then
        fullHeight = math.max(200, math.min(550, 148 + #crops * 60 + 20))
        panel.Size = UDim2.new(0, 310, 0, fullHeight)
    end
end

-- ===== Realtime Connections =====
local function connectCharacter(char)
    if not char then return end
    char.ChildAdded:Connect(function(child)
        task.wait(0.1)
        pcall(update)
        if child:IsA("Tool") then
            child.ChildAdded:Connect(function() pcall(update) end)
            child.ChildRemoved:Connect(function() pcall(update) end)
        end
    end)
    char.ChildRemoved:Connect(function()
        task.wait(0.1)
        pcall(update)
    end)
end

player.Backpack.ChildAdded:Connect(function()
    task.wait(0.1)
    pcall(update)
end)
player.Backpack.ChildRemoved:Connect(function()
    task.wait(0.1)
    pcall(update)
end)

connectCharacter(player.Character)

player.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    connectCharacter(char)
    pcall(update)
end)

-- Safety net ทุก 1 วิ
task.spawn(function()
    while sg and sg.Parent do
        task.wait(1)
        pcall(update)
    end
end)

update()
print("[GaG2] ✅ Hotbar Fix! Scans Configuration + Tool attributes")
