-- [[ ALIT HUB - ISOLATED AUTO RESTOCK INDEPENDENT MULTI-RAK - PART 1 ]]
if not game:IsLoaded() then game.Loaded:Wait() end
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui", 10)

if PlayerGui:FindFirstChild("AlitIndependentMultiStockUI") then 
    PlayerGui.AlitIndependentMultiStockUI:Destroy() 
end

_G.DynamicRestockActive = false
local AutoDetectedSlots = {}
local AutoDetectedTools = {}
local SlotSpecificTargets = {} -- Menyimpan kuncian target makanan untuk setiap slot nampan secara mandiri

-- PREMIUM UI HITAM PEKAT + EMAS GLOW (NODE HUB ESTETIKA PREMIUM)
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AlitIndependentMultiStockUI"; ScreenGui.Parent = PlayerGui; ScreenGui.ResetOnSpawn = false

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"; MainFrame.Parent = ScreenGui; MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
MainFrame.Position = UDim2.new(0, 10, 0.4, -90); MainFrame.Size = UDim2.new(0, 200, 0, 190); MainFrame.BorderSizePixel = 1; MainFrame.BorderColor3 = Color3.fromRGB(255, 185, 0)
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)

local TopBar = Instance.new("Frame"); TopBar.Size = UDim2.new(1, 0, 0, 30); TopBar.BackgroundTransparency = 1; TopBar.Parent = MainFrame
local Title = Instance.new("TextLabel"); Title.Size = UDim2.new(0, 140, 1, 0); Title.Position = UDim2.new(0, 10, 0, 0); Title.BackgroundTransparency = 1; Title.Font = Enum.Font.GothamBold; Title.Text = "MULTI-RAK MANAGER"; Title.TextColor3 = Color3.fromRGB(255, 185, 0); Title.TextSize = 10; Title.TextXAlignment = Enum.TextXAlignment.Left; Title.Parent = TopBar
local MiniBtn = Instance.new("TextButton"); MiniBtn.Size = UDim2.new(0, 25, 1, 0); MiniBtn.Position = UDim2.new(1, -25, 0, 0); MiniBtn.BackgroundTransparency = 1; MiniBtn.Font = Enum.Font.GothamBold; MiniBtn.Text = "-"; MiniBtn.TextColor3 = Color3.fromRGB(200, 200, 200); MiniBtn.TextSize = 16; MiniBtn.Parent = TopBar

local RestockButton = Instance.new("TextButton"); RestockButton.Position = UDim2.new(0, 10, 0, 35); RestockButton.Size = UDim2.new(1, -20, 0, 26); RestockButton.BackgroundColor3 = Color3.fromRGB(30, 15, 15); RestockButton.Font = Enum.Font.GothamBold; RestockButton.Text = "RESTOCK: OFF"; RestockButton.TextColor3 = Color3.fromRGB(220, 53, 69); RestockButton.TextSize = 9; RestockButton.Parent = MainFrame; Instance.new("UICorner", RestockButton).CornerRadius = UDim.new(0, 4)
-- [[ ALIT HUB - ISOLATED AUTO RESTOCK INDEPENDENT MULTI-RAK - PART 2 ]]
local MasterScroll = Instance.new("ScrollingFrame")
MasterScroll.Name = "MasterScroll"; MasterScroll.Position = UDim2.new(0, 10, 0, 68); MasterScroll.Size = UDim2.new(1, -20, 1, -78); MasterScroll.BackgroundColor3 = Color3.fromRGB(10, 10, 10); MasterScroll.BorderSizePixel = 0; MasterScroll.ScrollBarThickness = 3; MasterScroll.Parent = MainFrame
local UIMasterLayout = Instance.new("UIListLayout"); UIMasterLayout.Parent = MasterScroll; UIMasterLayout.Padding = UDim.new(0, 4)

local OpenButton = Instance.new("TextButton")
OpenButton.Name = "OpenButton"; OpenButton.Parent = ScreenGui; OpenButton.BackgroundColor3 = Color3.fromRGB(15, 15, 15); OpenButton.Position = UDim2.new(0, 10, 0.4, 0); OpenButton.Size = UDim2.new(0, 55, 0, 26); OpenButton.Font = Enum.Font.GothamBold; OpenButton.Text = "STOCK"; OpenButton.TextColor3 = Color3.fromRGB(255, 185, 0); OpenButton.TextSize = 9; OpenButton.BorderSizePixel = 1; OpenButton.BorderColor3 = Color3.fromRGB(255, 185, 0); OpenButton.Visible = false; Instance.new("UICorner", OpenButton).CornerRadius = UDim.new(0, 4)

MiniBtn.Activated:Connect(function() MainFrame.Visible = false; OpenButton.Visible = true end)
OpenButton.Activated:Connect(function() OpenButton.Visible = false; MainFrame.Visible = true end)

local function ScanCurrentInventory()
    table.clear(AutoDetectedTools)
    local bp = LocalPlayer:FindFirstChild("Backpack")
    local char = LocalPlayer.Character
    local foundItems = {}
    local function check(tool)
        if tool:IsA("Tool") and not foundItems[tool.Name] then
            local nameLower = string.lower(tool.Name)
            if not (string.find(nameLower, "penyiram") or string.find(nameLower, "bibit") or string.find(nameLower, "lantern") or string.find(nameLower, "gerobak") or string.find(nameLower, "payung") or string.find(nameLower, "arwah") or string.find(nameLower, "pusaka") or string.find(nameLower, "tas")) then
                foundItems[tool.Name] = true
                table.insert(AutoDetectedTools, tool.Name)
            end
        end
    end
    if bp then for _, t in pairs(bp:GetChildren()) do check(t) end end
    if char then for _, t in pairs(char:GetChildren()) do check(t) end end
end
-- [[ ALIT HUB - ISOLATED AUTO RESTOCK INDEPENDENT MULTI-RAK - PART 3 ]]
-- RENDER REAL-TIME LIST RAK DINAMIS MENGIKUTI STRUKTUR LEVEL TOKO ANDA
local function BuildMultiRakUI()
    for _, child in pairs(MasterScroll:GetChildren()) do if child:IsA("Frame") then child:Destroy() end end
    table.clear(AutoDetectedSlots)
    ScanCurrentInventory()
    
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
            local sName = slotData.name
            table.insert(AutoDetectedSlots, sName)
            if not SlotSpecificTargets[sName] then SlotSpecificTargets[sName] = "" end
            
            local rowFrame = Instance.new("Frame"); rowFrame.Size = UDim2.new(1, -4, 0, 38); rowFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20); rowFrame.BorderSizePixel = 0; rowFrame.Parent = MasterScroll; Instance.new("UICorner", rowFrame).CornerRadius = UDim.new(0, 4)
            local rLabel = Instance.new("TextLabel"); rLabel.Size = UDim2.new(0, 70, 1, 0); rLabel.Position = UDim2.new(0, 6, 0, 0); rLabel.BackgroundTransparency = 1; rLabel.Font = Enum.Font.GothamBold; rLabel.Text = string.upper(sName); rLabel.TextColor3 = Color3.fromRGB(200, 200, 200); rLabel.TextSize = 8; rLabel.TextXAlignment = Enum.TextXAlignment.Left; rLabel.Parent = rowFrame
            local rDrop = Instance.new("TextButton"); rDrop.Size = UDim2.new(1, -80, 0, 22); rDrop.Position = UDim2.new(0, 74, 0, 8); rDrop.BackgroundColor3 = Color3.fromRGB(30, 30, 30); rDrop.Font = Enum.Font.GothamSemibold; rDrop.Text = SlotSpecificTargets[sName] ~= "" and SlotSpecificTargets[sName] or "NONE ▼"; rDrop.TextColor3 = Color3.fromRGB(255, 185, 0); rDrop.TextSize = 7; rDrop.Parent = rowFrame; Instance.new("UICorner", rDrop).CornerRadius = UDim.new(0, 4)
            
            local subContainer = Instance.new("ScrollingFrame"); subContainer.Size = UDim2.new(1, -10, 0, 60); subContainer.Position = UDim2.new(0, 5, 0, 32); subContainer.BackgroundColor3 = Color3.fromRGB(15, 15, 15); subContainer.ZIndex = 5; subContainer.Visible = false; subContainer.ScrollBarThickness = 2; subContainer.Parent = rowFrame; local rList = Instance.new("UIListLayout"); rList.Parent = subContainer; rList.Padding = UDim.new(0, 2)
            
            rDrop.Activated:Connect(function() subContainer.Visible = not subContainer.Visible; rowFrame.Size = subContainer.Visible and UDim2.new(1, -4, 0, 96) or UDim2.new(1, -4, 0, 38); MasterScroll.CanvasSize = UDim2.new(0, 0, 0, MasterScroll.UIListLayout.AbsoluteContentSize.Y + 10) end)
            
            local noneBtn = Instance.new("TextButton"); noneBtn.Size = UDim2.new(1, 0, 0, 16); noneBtn.BackgroundColor3 = Color3.fromRGB(25, 15, 15); noneBtn.Text = "  NONE (KOSONGKAN)"; noneBtn.TextColor3 = Color3.fromRGB(220, 53, 69); noneBtn.Font = Enum.Font.GothamSemibold; noneBtn.TextSize = 7; noneBtn.TextXAlignment = Enum.TextXAlignment.Left; noneBtn.ZIndex = 6; noneBtn.Parent = subContainer; Instance.new("UICorner", noneBtn).CornerRadius = UDim.new(0, 4)
            noneBtn.Activated:Connect(function() SlotSpecificTargets[sName] = ""; rDrop.Text = "NONE ▼"; subContainer.Visible = false; rowFrame.Size = UDim2.new(1, -4, 0, 38) end)
            
            for _, tName in ipairs(AutoDetectedTools) do
                local tBtn = Instance.new("TextButton"); tBtn.Size = UDim2.new(1, 0, 0, 16); tBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 25); tBtn.Text = "  " .. tName; tBtn.TextColor3 = Color3.fromRGB(200, 200, 200); tBtn.Font = Enum.Font.GothamSemibold; tBtn.TextSize = 7; tBtn.TextXAlignment = Enum.TextXAlignment.Left; tBtn.ZIndex = 6; tBtn.Parent = subContainer; Instance.new("UICorner", tBtn).CornerRadius = UDim.new(0, 4)
                tBtn.Activated:Connect(function() SlotSpecificTargets[sName] = tName; rDrop.Text = tName .. " ▼"; subContainer.Visible = false; rowFrame.Size = UDim2.new(1, -4, 0, 38) end)
            end
            subContainer.CanvasSize = UDim2.new(0, 0, 0, (#AutoDetectedTools + 1) * 18)
        end
    end
    MasterScroll.CanvasSize = UDim2.new(0, 0, 0, #AutoDetectedSlots * 42)
end

task.spawn(function() task.wait(0.5); BuildMultiRakUI() end)
RestockButton.Activated:Connect(function() _G.DynamicRestockActive = not _G.DynamicRestockActive; RestockButton.BackgroundColor3 = _G.DynamicRestockActive and Color3.fromRGB(15, 30, 15) or Color3.fromRGB(30, 15, 15); RestockButton.TextColor3 = _G.DynamicRestockActive and Color3.fromRGB(255, 185, 0) or Color3.fromRGB(220, 53, 69); RestockButton.Text = _G.DynamicRestockActive and "RESTOCK: ON" or "RESTOCK: OFF" if not _G.DynamicRestockActive then BuildMultiRakUI() end end)
-- [[ ALIT HUB - ISOLATED AUTO RESTOCK INDEPENDENT MULTI-RAK - PART 4 ]]
-- FIXED AUTOMATION QUEUE CHRONOLOGICAL: Mengisi berurutan dari Rak 1 ke Rak berikutnya secara rapi tanpa berebutan koordinat
local dragToggle, dragInput, dragStart, startPos
MainFrame.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragToggle = true; dragStart = input.Position; startPos = MainFrame.Position; input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragToggle = false end end) end end)
MainFrame.InputChanged:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end end)
game:GetService("UserInputService").InputChanged:Connect(function(input) if input == dragInput and dragToggle then local delta = input.Position - dragStart; MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y) end end)

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

task.spawn(function()
    while task.wait(0.1) do
        if _G.DynamicRestockActive and #AutoDetectedSlots > 0 then
            local char = LocalPlayer.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if root then
                local kiosAktif = workspace:FindFirstChild("KiosAktif")
                local myKios = kiosAktif and (kiosAktif:FindFirstChild("Kios_" .. LocalPlayer.Name) or kiosAktif:FindFirstChild("Kios_panggil_" .. LocalPlayer.Name))
                if myKios then
                    -- PROSES URUTAN KRONOLOGIS: Membaca slot nampan secara rapi berurutan (slot1, slot2, slot3...)
                    for _, slotName in ipairs(AutoDetectedSlots) do
                        if not _G.DynamicRestockActive then break end
                        local targetTool = SlotSpecificTargets[slotName] or ""
                        
                        -- Jalankan pengisian jika rak dikunci dengan target jualan dan itemnya ada di dalam tas
                        if targetTool ~= "" and equipItem(targetTool) then
                            local slot = myKios:FindFirstChild(slotName)
                            if slot then
                                local prompt = slot:FindFirstChildWhichIsA("ProximityPrompt", true)
                                -- Mengisi jika dan hanya jika nampan tersebut berstatus KOSONG (Prompt Enabled)
                                if prompt and prompt.Enabled then
                                    local part = slot:IsA("BasePart") and slot or slot:FindFirstChildWhichIsA("BasePart", true)
                                    if part then
                                        instantTeleportTo(root, part.CFrame)
                                        task.wait(0.2)
                                        prompt:InputHoldBegin(); task.wait(0.4); prompt:InputHoldEnd()
                                        if fireproximityprompt then fireproximityprompt(prompt) end
                                        task.wait(0.3)
                                        -- Mengunci antrean agar fokus menyelesaikan slot ini sebelum lanjut ke slot berikutnya
                                        break
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end)
