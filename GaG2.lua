-- GaG2 Complete Hub - Panel + Inventory Slot Labels
-- Executor Script (Synapse X / KRNL / Delta etc.)

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer
local playerGui = player.PlayerGui

local function fmt(n)
    if n >= 1e9 then      return string.format("$%.2fB", n/1e9)
    elseif n >= 1e6 then  return string.format("$%.2fM", n/1e6)
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
    ["Dragon's Breath"] = 429,
}

local MUTATION_MULT = {
    ["Gold"]       = 17.3,  -- verified
    ["Aurora"]     = 34.3,  -- verified
    ["Bloodlit"]   = 94.8,  -- verified
    ["Rainbow"]    = 30,    -- ยังไม่ verified
    ["Electric"]   = 25,    -- ยังไม่ verified
    ["Starstruck"] = 50,    -- ยังไม่ verified
    ["Frozen"]     = 14,    -- ยังไม่ verified
    ["Solarflare"] = 5,     -- ยังไม่ verified
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
    elseif val >= 1e6 then    return Color3.fromRGB(80,  255, 120)
    elseif val >= 100000 then return Color3.fromRGB(255, 140, 0)
    elseif val >= 10000 then  return Color3.fromRGB(255, 215, 0)
    elseif val >= 1000 then   return Color3.fromRGB(100, 180, 255)
    else                      return Color3.fromRGB(180, 180, 180)
    end
end

local function scanCrops()
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
            if item:IsA("Configuration") then tryAdd(item) end
            if item:IsA("Tool") then
                tryAdd(item)
                for _, child in ipairs(item:GetChildren()) do
                    if child:IsA("Configuration") then tryAdd(child) end
                end
            end
        end
    end

    scanFolder(player.Backpack)
    if player.Character then scanFolder(player.Character) end
    table.sort(crops, function(a,b) return a.value > b.value end)
    return crops
end

local function buildWeightLookup()
    local lookup = {}

    local function tryItem(item)
        if item:GetAttribute("HarvestedFruit") ~= true then return end
        local name     = item:GetAttribute("FruitName") or ""
        local weight   = item:GetAttribute("Weight") or 0
        local sizeMult = item:GetAttribute("SizeMultiplier") or 1
        local mutation = item:GetAttribute("Mutation") or ""
        if mutation == "None" then mutation = "" end
        if name == "" then return end
        local value = calcValue(name, weight, sizeMult, mutation)
        if not lookup[name] then lookup[name] = {} end
        table.insert(lookup[name], {weight=weight, value=value, used=false})
    end

    for _, item in ipairs(player.Backpack:GetChildren()) do
        pcall(tryItem, item)
        if item:IsA("Tool") then
            pcall(tryItem, item)
            for _, child in ipairs(item:GetChildren()) do
                pcall(tryItem, child)
            end
        end
    end
    if player.Character then
        for _, item in ipairs(player.Character:GetChildren()) do
            pcall(tryItem, item)
            if item:IsA("Tool") then
                pcall(tryItem, item)
                for _, child in ipairs(item:GetChildren()) do
                    pcall(tryItem, child)
                end
            end
        end
    end
    return lookup
end

local old = playerGui:FindFirstChild("GaG2_UI")
if old then old:Destroy() end

local sg = Instance.new("ScreenGui")
sg.Name = "GaG2_UI"
sg.ResetOnSpawn = false
sg.DisplayOrder = 999
sg.IgnoreGuiInset = true
sg.Parent = playerGui

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

local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 44)
titleBar.BackgroundTransparency = 1
titleBar.BorderSizePixel = 0
titleBar.Parent = panel

local titleLbl = Instance.new("TextLabel")
titleLbl.Size = UDim2.new(1, -50, 1, 0)
titleLbl.Position = UDim2.new(0, 16, 0, 0)
titleLbl.BackgroundTransparency = 1
titleLbl.Text = "Gag Hub"
titleLbl.TextColor3 = Color3.fromRGB(200, 200, 200)
titleLbl.Font = Enum.Font.GothamBold
titleLbl.TextSize = 15
titleLbl.TextXAlignment = Enum.TextXAlignment.Left
titleLbl.Parent = titleBar

local minBtn = Instance.new("TextButton")
minBtn.Size = UDim2.new(0, 28, 0, 28)
minBtn.Position = UDim2.new(1, -38, 0.5, -14)
minBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
minBtn.BorderSizePixel = 0
minBtn.Text = "-"
minBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
minBtn.Font = Enum.Font.GothamBold
minBtn.TextSize = 16
minBtn.Parent = titleBar
Instance.new("UICorner", minBtn).CornerRadius = UDim.new(0, 6)

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

local minimized = false
local fullHeight = 500
minBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    scroll.Visible       = not minimized
    totalBox.Visible     = not minimized
    allFruitsLbl.Visible = not minimized
    minBtn.Text = minimized and "+" or "-"
    panel.Size = UDim2.new(0, 310, 0, minimized and 44 or fullHeight)
end)

local function makeRow(crop, order)
    local tc = tierColor(crop.value)
    local displayMut = crop.mutation ~= "" and (" ["..crop.mutation.."]") or ""
    local mutMult = MUTATION_MULT[crop.mutation]
    local mutColor = MUTATION_COLOR[crop.mutation] or Color3.fromRGB(180,180,180)
    local multTag = mutMult and string.format(" x%.1f", mutMult) or ""

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
    wl.Text = string.format("%.2fkg x%.2f size%s", crop.weight, crop.sizeMult, multTag)
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

local LABEL_NAME = "GaG2_PriceLabel"

local function getGrid()
    local bg = playerGui:FindFirstChild("BackpackGui")
    if not bg then return nil end
    local function findGrid(obj, depth)
        if depth > 6 then return nil end
        if obj.Name == "UIGridFrame" then return obj end
        for _, c in ipairs(obj:GetChildren()) do
            local result = findGrid(c, depth + 1)
            if result then return result end
        end
        return nil
    end
    return findGrid(bg, 0)
end

local function updateSlotLabels()
    local grid = getGrid()
    if not grid then return end

    local lookup = buildWeightLookup()

    for _, slot in ipairs(grid:GetChildren()) do
        if slot:IsA("TextButton") then
            local toolNameLbl = slot:FindFirstChild("ToolName")
            local cropName = toolNameLbl and toolNameLbl.Text or ""

            local oldLabel = slot:FindFirstChild(LABEL_NAME)
            if oldLabel then oldLabel:Destroy() end

            if not PRICE_PER_KG[cropName] then continue end
            if not lookup[cropName] then continue end

            local toolCount = slot:FindFirstChild("ToolCount")
            local slotWeight = nil
            if toolCount and toolCount:IsA("TextLabel") then
                local w = toolCount.Text:match("([%d%.]+)kg")
                if w then slotWeight = tonumber(w) end
            end

            local bestEntry = nil
            local bestDiff = math.huge

            for _, entry in ipairs(lookup[cropName]) do
                if not entry.used then
                    if slotWeight then
                        local diff = math.abs(entry.weight - slotWeight)
                        if diff < bestDiff then
                            bestDiff = diff
                            bestEntry = entry
                        end
                    else
                        if not bestEntry then
                            bestEntry = entry
                        end
                    end
                end
            end

            if not bestEntry then continue end
            bestEntry.used = true
            if bestEntry.value <= 0 then continue end

            local label = Instance.new("TextLabel")
            label.Name = LABEL_NAME
            label.Size = UDim2.new(1, 0, 0, 18)
            label.Position = UDim2.new(0, 0, 0, 0)
            label.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
            label.BackgroundTransparency = 0.3
            label.Text = fmt(bestEntry.value)
            label.TextColor3 = tierColor(bestEntry.value)
            label.Font = Enum.Font.GothamBold
            label.TextSize = 11
            label.TextScaled = false
            label.ZIndex = 10
            label.Parent = slot
            Instance.new("UICorner", label).CornerRadius = UDim.new(0, 3)
        end
    end
end

local function update()
    local crops = scanCrops()

    for _, c in ipairs(scroll:GetChildren()) do
        if c:IsA("Frame") then c:Destroy() end
    end

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

    pcall(updateSlotLabels)
end

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

task.spawn(function()
    while sg and sg.Parent do
        task.wait(1)
        pcall(update)
    end
end)

update()
print("[GaG2] Complete Hub loaded! Panel + Slot Labels active!")
