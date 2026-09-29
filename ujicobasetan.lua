-- [[ ALIT HUB V3 - LIVE RESCAN PRIORITIZED EDITION - PART 1 ]]
if not game:IsLoaded() then game.Loaded:Wait() end
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local TweenService = game:GetService("TweenService")
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui", 10)

if PlayerGui:FindFirstChild("AlitHubUI") then 
    PlayerGui.AlitHubUI:Destroy() 
end

_G.AlitHubFarmActive = false
_G.AlitHubRestockActive = false
_G.AlitHubPigActive = false
_G.AlitHubCookActive = false

local TARGET_MAPPING = {
    ["Dupa"] = "Spawn_Dupa", ["Gagak"] = "Spawn_Gagak",
    ["Jamur Kuburan"] = "Spawn_JamurKuburan", ["Kemenyan"] = "Spawn_Kemenyan",
    ["Kepiting Sungai"] = "Spawn_KepitingSungai", ["Melati"] = "Spawn_Melati"
}

local AutoDetectedSlots = {}
local AutoDetectedTools = {}
local SlotSpecificTargets = {} 
local SelectedTargets = {}

local GLOBAL_SAVED_POS = UDim2.new(0.5, -175, 0.3, -110)
local TELEPORT_DELAY = 0.2      
local MASA_TUNGGU = 5.0         

local BG_COLOR = Color3.fromRGB(15, 15, 15)
local ACCENT_GOLD = Color3.fromRGB(255, 185, 0)
local TEXT_DARK = Color3.fromRGB(200, 200, 200)

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AlitHubUI"; ScreenGui.Parent = PlayerGui; ScreenGui.ResetOnSpawn = false

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"; MainFrame.Parent = ScreenGui; MainFrame.BackgroundColor3 = BG_COLOR
MainFrame.Position = GLOBAL_SAVED_POS; MainFrame.Size = UDim2.new(0, 350, 0, 220); MainFrame.BorderSizePixel = 1; MainFrame.BorderColor3 = ACCENT_GOLD
MainFrame.ClipsDescendants = true; MainFrame.Active = true
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)
-- [[ ALIT HUB V3 - LIVE RESCAN PRIORITIZED EDITION - PART 2 ]]
local TopBar = Instance.new("Frame"); TopBar.Name = "TopBar"; TopBar.Parent = MainFrame; TopBar.BackgroundTransparency = 1; TopBar.Size = UDim2.new(1, 0, 0, 35)
local TitleLabel = Instance.new("TextLabel")
TitleLabel.Name = "TitleLabel"; TitleLabel.Parent = TopBar; TitleLabel.BackgroundTransparency = 1; TitleLabel.Position = UDim2.new(0, 12, 0, 0); TitleLabel.Size = UDim2.new(0, 150, 0, 35)
TitleLabel.Font = Enum.Font.GothamBold; TitleLabel.Text = "ALIT HUB V3"; TitleLabel.TextColor3 = ACCENT_GOLD; TitleLabel.TextSize = 12; TitleLabel.TextXAlignment = Enum.TextXAlignment.Left

local MiniButton = Instance.new("TextButton")
MiniButton.Name = "MiniButton"; MiniButton.Parent = TopBar; MiniButton.BackgroundTransparency = 1; MiniButton.Position = UDim2.new(1, -30, 0, 0); MiniButton.Size = UDim2.new(0, 25, 0, 35)
MiniButton.Font = Enum.Font.GothamBold; MiniButton.Text = "-"; MiniButton.TextColor3 = TEXT_DARK; MiniButton.TextSize = 20

local LeftSidebar = Instance.new("Frame")
LeftSidebar.Name = "LeftSidebar"; LeftSidebar.Parent = MainFrame; LeftSidebar.BackgroundColor3 = Color3.fromRGB(10, 10, 10); LeftSidebar.Position = UDim2.new(0, 0, 0, 35); LeftSidebar.Size = UDim2.new(0, 95, 1, -35); LeftSidebar.BorderSizePixel = 0
local SidebarLayout = Instance.new("UIListLayout")
SidebarLayout.Parent = LeftSidebar; SidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder; SidebarLayout.Padding = UDim.new(0, 4)

local SidebarButtons = {"AUTO FARM", "AUTO STOCK", "AUTO PIG", "AUTO COOK"}
local SubFrames = {}

local ContentArea = Instance.new("Frame")
ContentArea.Name = "ContentArea"; ContentArea.Parent = MainFrame; ContentArea.BackgroundTransparency = 1; ContentArea.Position = UDim2.new(0, 100, 0, 35); ContentArea.Size = UDim2.new(1, -105, 1, -40)

local OpenButton = Instance.new("TextButton")
OpenButton.Name = "OpenButton"; OpenButton.Parent = ScreenGui; OpenButton.BackgroundColor3 = BG_COLOR; OpenButton.Position = UDim2.new(0, 10, 0.4, 0); OpenButton.Size = UDim2.new(0, 45, 0, 30); OpenButton.Font = Enum.Font.GothamBold; OpenButton.Text = "ALIT"; OpenButton.TextColor3 = ACCENT_GOLD; OpenButton.TextSize = 10; OpenButton.BorderSizePixel = 1; OpenButton.BorderColor3 = ACCENT_GOLD; OpenButton.Visible = false
Instance.new("UICorner", OpenButton).CornerRadius = UDim.new(0, 5)

MiniButton.Activated:Connect(function() GLOBAL_SAVED_POS = MainFrame.Position; MainFrame.Visible = false; OpenButton.Visible = true end)
OpenButton.Activated:Connect(function() OpenButton.Visible = false; MainFrame.Position = GLOBAL_SAVED_POS; MainFrame.Visible = true end)

for i, tabName in ipairs(SidebarButtons) do
    local sBtn = Instance.new("TextButton")
    sBtn.Name = tabName .. "Btn"; sBtn.Parent = LeftSidebar; sBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 20); sBtn.Size = UDim2.new(1, -8, 0, 30); sBtn.Font = Enum.Font.GothamBold; sBtn.Text = tabName; sBtn.TextColor3 = Color3.fromRGB(200, 200, 200); sBtn.TextSize = 8; Instance.new("UICorner", sBtn).CornerRadius = UDim.new(0, 4)
    local f = Instance.new("Frame"); f.Name = tabName .. "Frame"; f.Parent = ContentArea; f.BackgroundTransparency = 1; f.Size = UDim2.new(1, 0, 1, 0); f.Visible = (i == 1); SubFrames[tabName] = f
    sBtn.Activated:Connect(function()
        for _, frame in pairs(SubFrames) do frame.Visible = false end
        for _, btn in pairs(LeftSidebar:GetChildren()) do if btn:IsA("TextButton") then btn.TextColor3 = Color3.fromRGB(200, 200, 200); btn.BackgroundColor3 = Color3.fromRGB(20, 20, 20) end end
        f.Visible = true; sBtn.TextColor3 = ACCENT_GOLD; sBtn.BackgroundColor3 = Color3.fromRGB(30, 25, 20)
    end)
    if i == 1 then sBtn.TextColor3 = ACCENT_GOLD; sBtn.BackgroundColor3 = Color3.fromRGB(30, 25, 20) end
end
-- [[ ALIT HUB V3 - LIVE RESCAN PRIORITIZED EDITION - PART 3 ]]
local ToggleButton = Instance.new("TextButton"); ToggleButton.Size = UDim2.new(1, 0, 0, 28); ToggleButton.BackgroundColor3 = Color3.fromRGB(30, 15, 15); ToggleButton.Font = Enum.Font.GothamBold; ToggleButton.Text = "FARM SYSTEM: OFF"; ToggleButton.TextColor3 = Color3.fromRGB(220, 53, 69); ToggleButton.TextSize = 9; ToggleButton.Parent = SubFrames["AUTO FARM"]; Instance.new("UICorner", ToggleButton).CornerRadius = UDim.new(0, 4)
local DropdownButton = Instance.new("TextButton"); DropdownButton.Position = UDim2.new(0, 0, 0, 34); DropdownButton.Size = UDim2.new(1, 0, 0, 24); DropdownButton.BackgroundColor3 = Color3.fromRGB(22, 22, 22); DropdownButton.Font = Enum.Font.GothamSemibold; DropdownButton.Text = "SELECT TARGETS ▼"; DropdownButton.TextColor3 = TEXT_DARK; DropdownButton.TextSize = 9; DropdownButton.Parent = SubFrames["AUTO FARM"]; Instance.new("UICorner", DropdownButton).CornerRadius = UDim.new(0, 4)
local ListContainer = Instance.new("ScrollingFrame"); ListContainer.Position = UDim2.new(0, 0, 0, 62); ListContainer.Size = UDim2.new(1, 0, 1, -62); ListContainer.BackgroundColor3 = Color3.fromRGB(12, 12, 12); ListContainer.BorderSizePixel = 0; ListContainer.ScrollBarThickness = 2; ListContainer.Visible = false; ListContainer.Parent = SubFrames["AUTO FARM"]
local UIListLayout = Instance.new("UIListLayout"); UIListLayout.Parent = ListContainer; UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder; UIListLayout.Padding = UDim.new(0, 2)

for disp, ws in pairs(TARGET_MAPPING) do
    local btn = Instance.new("TextButton"); btn.Size = UDim2.new(1, 0, 0, 20); btn.BackgroundColor3 = Color3.fromRGB(20, 20, 20); btn.Text = "  " .. disp; btn.TextColor3 = TEXT_DARK; btn.Font = Enum.Font.GothamSemibold; btn.TextSize = 9; btn.TextXAlignment = Enum.TextXAlignment.Left; btn.Parent = ListContainer; Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
    btn.Activated:Connect(function() local idx = table.find(SelectedTargets, ws) if idx then table.remove(SelectedTargets, idx); btn.TextColor3 = TEXT_DARK; btn.BackgroundColor3 = Color3.fromRGB(20, 20, 20) else table.insert(SelectedTargets, ws); btn.TextColor3 = BG_COLOR; btn.BackgroundColor3 = ACCENT_GOLD end end)
end
ListContainer.CanvasSize = UDim2.new(0, 0, 0, 130)
DropdownButton.Activated:Connect(function() ListContainer.Visible = not ListContainer.Visible; DropdownButton.Text = ListContainer.Visible and "SELECT TARGETS ▲" or "SELECT TARGETS ▼" end)
ToggleButton.Activated:Connect(function() _G.AlitHubFarmActive = not _G.AlitHubFarmActive; ToggleButton.BackgroundColor3 = _G.AlitHubFarmActive and Color3.fromRGB(15, 30, 15) or Color3.fromRGB(30, 15, 15); ToggleButton.TextColor3 = _G.AlitHubFarmActive and ACCENT_GOLD or Color3.fromRGB(220, 53, 69); ToggleButton.Text = _G.AlitHubFarmActive and "FARM SYSTEM: ON" or "FARM SYSTEM: OFF" end)

local RestockButton = Instance.new("TextButton"); RestockButton.Size = UDim2.new(1, 0, 0, 28); RestockButton.BackgroundColor3 = Color3.fromRGB(30, 15, 15); RestockButton.Font = Enum.Font.GothamBold; RestockButton.Text = "RESTOCK KIOS: OFF"; RestockButton.TextColor3 = Color3.fromRGB(220, 53, 69); RestockButton.TextSize = 9; RestockButton.Parent = SubFrames["AUTO STOCK"]; Instance.new("UICorner", RestockButton).CornerRadius = UDim.new(0, 4)
local MasterScroll = Instance.new("ScrollingFrame"); MasterScroll.Name = "MasterScroll"; MasterScroll.Position = UDim2.new(0, 0, 0, 34); MasterScroll.Size = UDim2.new(1, 0, 1, -38); MasterScroll.BackgroundColor3 = Color3.fromRGB(10, 10, 10); MasterScroll.BorderSizePixel = 0; MasterScroll.ScrollBarThickness = 3; MasterScroll.Parent = SubFrames["AUTO STOCK"]
local UIMasterLayout = Instance.new("UIListLayout"); UIMasterLayout.Parent = MasterScroll; UIMasterLayout.Padding = UDim.new(0, 4)

local PigLabel = Instance.new("TextLabel"); PigLabel.Size = UDim2.new(1, 0, 0, 30); PigLabel.BackgroundTransparency = 1; PigLabel.Font = Enum.Font.GothamBold; PigLabel.Text = "PIG CONFIGURATION PLACEHOLDER"; PigLabel.TextColor3 = TEXT_DARK; PigLabel.TextSize = 8; PigLabel.Parent = SubFrames["AUTO PIG"]
local CookLabel = Instance.new("TextLabel"); CookLabel.Size = UDim2.new(1, 0, 0, 30); CookLabel.BackgroundTransparency = 1; CookLabel.Font = Enum.Font.GothamBold; CookLabel.Text = "COOK CONFIGURATION PLACEHOLDER"; CookLabel.TextColor3 = TEXT_DARK; CookLabel.TextSize = 8; CookLabel.Parent = SubFrames["AUTO COOK"]
-- [[ ALIT HUB V3 - LIVE RESCAN PRIORITIZED EDITION - PART 4 ]]
local ALL_PRESET_ITEMS = {"SateGagak", "JamurRebus", "TumisKamboja", "SateKepiting", "PisangRajaRebus", "KopiKemenyan"}

local function BuildMultiRakUI()
    for _, child in pairs(MasterScroll:GetChildren()) do if child:IsA("Frame") then child:Destroy() end end
    table.clear(AutoDetectedSlots)
    
    local kiosAktif = workspace:FindFirstChild("KiosAktif")
    local myKios = kiosAktif and (kiosAktif:FindFirstChild("Kios_" .. LocalPlayer.Name) or kiosAktif:FindFirstChild("Kios_panggil_" .. LocalPlayer.Name))
    if myKios then
        local slotIndices = {}
        for _, obj in pairs(myKios:GetChildren()) do
            if string.find(string.lower(obj.Name), "slot") then
                local num = tonumber(string.match(obj.Name, "%d+")) or 0
                table.insert(slotIndices, {name = obj.Name, index = num})
            end
        end
        table.sort(slotIndices, function(a, b) return a.index < b.index end)
        for _, slotData in ipairs(slotIndices) do
            local sName = slotData.name; table.insert(AutoDetectedSlots, sName)
            if not SlotSpecificTargets[sName] then SlotSpecificTargets[sName] = "" end
            local rowFrame = Instance.new("Frame"); rowFrame.Size = UDim2.new(1, -4, 0, 32); rowFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20); rowFrame.Parent = MasterScroll; Instance.new("UICorner", rowFrame).CornerRadius = UDim.new(0, 4)
            local rLabel = Instance.new("TextLabel"); rLabel.Size = UDim2.new(0, 60, 1, 0); rLabel.Position = UDim2.new(0, 6, 0, 0); rLabel.BackgroundTransparency = 1; rLabel.Font = Enum.Font.GothamBold; rLabel.Text = string.upper(sName); rLabel.TextColor3 = Color3.fromRGB(200, 200, 200); rLabel.TextSize = 8; rLabel.TextXAlignment = Enum.TextXAlignment.Left; rLabel.Parent = rowFrame
            local rDrop = Instance.new("TextButton"); rDrop.Size = UDim2.new(1, -70, 0, 20); rDrop.Position = UDim2.new(0, 64, 0, 6); rDrop.BackgroundColor3 = Color3.fromRGB(30, 30, 30); rDrop.Font = Enum.Font.GothamSemibold; rDrop.Text = SlotSpecificTargets[sName] ~= "" and SlotSpecificTargets[sName] or "NONE ▼"; rDrop.TextColor3 = ACCENT_GOLD; rDrop.TextSize = 7; rDrop.Parent = rowFrame; Instance.new("UICorner", rDrop).CornerRadius = UDim.new(0, 4)
            local subContainer = Instance.new("ScrollingFrame"); subContainer.Size = UDim2.new(1, -10, 0, 50); subContainer.Position = UDim2.new(0, 5, 0, 28); subContainer.BackgroundColor3 = Color3.fromRGB(15, 15, 15); subContainer.ZIndex = 5; subContainer.Visible = false; subContainer.ScrollBarThickness = 2; subContainer.Parent = rowFrame; Instance.new("UIListLayout", subContainer).Padding = UDim.new(0, 2)
            rDrop.Activated:Connect(function() subContainer.Visible = not subContainer.Visible; rowFrame.Size = subContainer.Visible and UDim2.new(1, -4, 0, 85) or UDim2.new(1, -4, 0, 32); MasterScroll.CanvasSize = UDim2.new(0, 0, 0, MasterScroll.UIListLayout.AbsoluteContentSize.Y + 10) end)
            local noneBtn = Instance.new("TextButton"); noneBtn.Size = UDim2.new(1, 0, 0, 14); noneBtn.BackgroundColor3 = Color3.fromRGB(25, 15, 15); noneBtn.Text = "  NONE"; noneBtn.TextColor3 = Color3.fromRGB(220, 53, 69); noneBtn.Font = Enum.Font.GothamSemibold; noneBtn.TextSize = 7; noneBtn.TextXAlignment = Enum.TextXAlignment.Left; noneBtn.ZIndex = 6; noneBtn.Parent = subContainer; Instance.new("UICorner", noneBtn).CornerRadius = UDim.new(0, 4)
            noneBtn.Activated:Connect(function() SlotSpecificTargets[sName] = ""; rDrop.Text = "NONE ▼"; subContainer.Visible = false; rowFrame.Size = UDim2.new(1, -4, 0, 32) end)
            for _, tName in ipairs(ALL_PRESET_ITEMS) do
                local tBtn = Instance.new("TextButton"); tBtn.Size = UDim2.new(1, 0, 0, 14); tBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 25); tBtn.Text = "  " .. tName; tBtn.TextColor3 = Color3.fromRGB(200, 200, 200); tBtn.Font = Enum.Font.GothamSemibold; tBtn.TextSize = 7; tBtn.TextXAlignment = Enum.TextXAlignment.Left; tBtn.ZIndex = 6; tBtn.Parent = subContainer; Instance.new("UICorner", tBtn).CornerRadius = UDim.new(0, 4)
                tBtn.Activated:Connect(function() SlotSpecificTargets[sName] = tName; rDrop.Text = tName .. " ▼"; subContainer.Visible = false; rowFrame.Size = UDim2.new(1, -4, 0, 32) end)
            end
            subContainer.CanvasSize = UDim2.new(0, 0, 0, (#ALL_PRESET_ITEMS + 1) * 16)
        end
    end
    MasterScroll.CanvasSize = UDim2.new(0, 0, 0, #AutoDetectedSlots * 36)
end

task.spawn(function() task.wait(0.5); BuildMultiRakUI() end)
RestockButton.Activated:Connect(function() _G.AlitHubRestockActive = not _G.AlitHubRestockActive; RestockButton.BackgroundColor3 = _G.AlitHubRestockActive and Color3.fromRGB(15, 30, 15) or Color3.fromRGB(30, 15, 15); RestockButton.TextColor3 = _G.AlitHubRestockActive and ACCENT_GOLD or Color3.fromRGB(220, 53, 69); RestockButton.Text = _G.AlitHubRestockActive and "RESTOCK KIOS: ON" or "RESTOCK KIOS: OFF" if not _G.AlitHubRestockActive then BuildMultiRakUI() end end)
-- [[ ALIT HUB V3 - LIVE RESCAN PRIORITIZED EDITION - PART 5 ]]
local function equipItem(itemName)
    local bp = LocalPlayer:FindFirstChild("Backpack")
    local char = LocalPlayer.Character
    if bp and char then
        local tool = bp:FindFirstChild(itemName)
        if tool and char:FindFirstChildOfClass("Humanoid") then char.Humanoid:EquipTool(tool); return true end
    end
    return char and char:FindFirstChild(itemName) ~= nil
end

local function instantTeleportTo(root, targetCFrame)
    if root then root.Velocity = Vector3.new(0,0,0); root.CFrame = targetCFrame; root.Velocity = Vector3.new(0,0,0) end
end

local function executePerfectHarvest(prompt)
    if not prompt or not prompt.Enabled then return end
    task.wait(TELEPORT_DELAY)
    prompt:InputHoldBegin(); task.wait(0.5); prompt:InputHoldEnd()
    if fireproximityprompt then fireproximityprompt(prompt) end
    task.wait(MASA_TUNGGU)
end

local dragToggle, dragInput, dragStart, startPos
MainFrame.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragToggle = true; dragStart = input.Position; startPos = MainFrame.Position; input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragToggle = false end end) end end)
MainFrame.InputChanged:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end end)
game:GetService("UserInputService").InputChanged:Connect(function(input) if input == dragInput and dragToggle then local delta = input.Position - dragStart; MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y) end end)

local floatToggle, floatStart, floatStartPos
OpenButton.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then floatToggle = true; floatStart = input.Position; floatStartPos = OpenButton.Position; input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then floatToggle = false end end) end end)
game:GetService("UserInputService").InputChanged:Connect(function(input) if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement then if floatToggle then local delta = input.Position - floatStart; OpenButton.Position = UDim2.new(floatStartPos.X.Scale, floatStartPos.X.Offset + delta.X, floatStartPos.Y.Scale, floatStartPos.Y.Offset + delta.Y) end end end)

LocalPlayer.Idled:Connect(function() if _G.AlitHubFarmActive or _G.AlitHubRestockActive then local vu = game:GetService("VirtualUser"); vu:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame); task.wait(0.5); vu:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame) end end)
-- [[ ALIT HUB V3 - LIVE RESCAN PRIORITIZED EDITION - PART 6 ]]
-- ENGINE UTAMA: 1 JALUR ANTILAG DENGAN PRIORITAS DAN PEMINDAIAN TAS REAL-TIME (STOCK OVER FARM)
task.spawn(function()
    while true do
        task.wait(0.1) -- Detakan loop mikro super responsif
        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        
        if root and hum then
            local actionExecuted = false
            
            -- [[ PRIORITAS 1: OTOMATISASI KIOS (URUTAN DAN ISI ULANG AKTIF) ]]
            if _G.AlitHubRestockActive and #AutoDetectedSlots > 0 then
                local kiosAktif = workspace:FindFirstChild("KiosAktif")
                local myKios = kiosAktif and (kiosAktif:FindFirstChild("Kios_" .. LocalPlayer.Name) or kiosAktif:FindFirstChild("Kios_panggil_" .. LocalPlayer.Name))
                
                if myKios then
                    -- Pemindaian urutan kronologis slot nampan secara terus-menerus tanpa putus kaku
                    for _, slotName in ipairs(AutoDetectedSlots) do
                        local targetTool = SlotSpecificTargets[slotName] or ""
                        
                        -- CRITICAL: Validasi tas dilakukan langsung secara instan tepat di radar loop
                        if targetTool ~= "" and equipItem(targetTool) then
                            local slot = myKios:FindFirstChild(slotName)
                            local prompt = slot and slot:FindFirstChildWhichIsA("ProximityPrompt", true)
                            
                            -- Deteksi Real-Time: Jika dibeli NPC dan prompt menyala, langsung serang kembali!
                            if prompt and prompt.Enabled then
                                local part = slot:IsA("BasePart") and slot or slot:FindFirstChildWhichIsA("BasePart", true)
                                if part and _G.AlitHubRestockActive then
                                    instantTeleportTo(root, part.CFrame)
                                    task.wait(0.2)
                                    prompt:InputHoldBegin(); task.wait(0.4); prompt:InputHoldEnd()
                                    if fireproximityprompt then fireproximityprompt(prompt) end
                                    task.wait(0.4)
                                    actionExecuted = true 
                                    -- Selesai isi 1 slot, loop langsung di-refresh ke awal agar prioritas ter-scan ulang murni
                                    break 
                                end
                            end
                        end
                    end
                end
            end
            
            -- [[ PRIORITAS 2: LOGIKA FARMING HUTAN (BISA DI-CUT KAPAN PUN OLEH KIOS) ]]
            if not actionExecuted and _G.AlitHubFarmActive and #SelectedTargets > 0 then
                local folder = workspace:FindFirstChild("SpawnBahan")
                if folder then
                    for _, obj in pairs(folder:GetChildren()) do
                        if table.find(SelectedTargets, obj.Name) then
                            local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
                            if prompt and prompt.Enabled and prompt.Parent then
                                local part = prompt.Parent:IsA("BasePart") and prompt.Parent or obj:FindFirstChildWhichIsA("BasePart", true)
                                if part and _G.AlitHubFarmActive then 
                                    instantTeleportTo(root, part.CFrame)
                                    executePerfectHarvest(prompt)
                                    break 
                                end
                            end
                        end
                    end
                end
            end
            
        end
    end
end)
