-- [[ ALIT HUB - ISOLATED AUTO RESTOCK (DYNAMIC INVENTORY DETECT) ]]
if not game:IsLoaded() then game.Loaded:Wait() end
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui", 10)

if PlayerGui:FindFirstChild("AlitDynamicStockUI") then 
    PlayerGui.AlitDynamicStockUI:Destroy() 
end

_G.DynamicRestockActive = false
local AutoDetectedTools = {}

-- CREATING PREMIUM UI (HITAM PEKAT + EMAS GLOW)
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AlitDynamicStockUI"; ScreenGui.Parent = PlayerGui; ScreenGui.ResetOnSpawn = false

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"; MainFrame.Parent = ScreenGui; MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
MainFrame.Position = UDim2.new(0.5, -90, 0.3, -75); MainFrame.Size = UDim2.new(0, 180, 0, 160); MainFrame.BorderSizePixel = 1; MainFrame.BorderColor3 = Color3.fromRGB(255, 185, 0)
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)

local TopBar = Instance.new("Frame"); TopBar.Size = UDim2.new(1, 0, 0, 30); TopBar.BackgroundTransparency = 1; TopBar.Parent = MainFrame
local Title = Instance.new("TextLabel"); Title.Size = UDim2.new(0, 120, 1, 0); Title.Position = UDim2.new(0, 10, 0, 0); Title.BackgroundTransparency = 1; Title.Font = Enum.Font.GothamBold; Title.Text = "DYNAMIC STOCK"; Title.TextColor3 = Color3.fromRGB(255, 185, 0); Title.TextSize = 10; Title.TextXAlignment = Enum.TextXAlignment.Left; Title.Parent = TopBar
local MiniBtn = Instance.new("TextButton"); MiniBtn.Size = UDim2.new(0, 25, 1, 0); MiniBtn.Position = UDim2.new(1, -25, 0, 0); MiniBtn.BackgroundTransparency = 1; MiniBtn.Font = Enum.Font.GothamBold; MiniBtn.Text = "-"; MiniBtn.TextColor3 = Color3.fromRGB(200, 200, 200); MiniBtn.TextSize = 16; MiniBtn.Parent = TopBar

local RestockButton = Instance.new("TextButton"); RestockButton.Position = UDim2.new(0, 10, 0, 35); RestockButton.Size = UDim2.new(1, -20, 0, 26); RestockButton.BackgroundColor3 = Color3.fromRGB(30, 15, 15); RestockButton.Font = Enum.Font.GothamBold; RestockButton.Text = "RESTOCK: OFF"; RestockButton.TextColor3 = Color3.fromRGB(220, 53, 69); RestockButton.TextSize = 9; RestockButton.Parent = MainFrame; Instance.new("UICorner", RestockButton).CornerRadius = UDim.new(0, 4)
local DropBtn = Instance.new("TextButton"); DropBtn.Position = UDim2.new(0, 10, 0, 66); DropBtn.Size = UDim2.new(1, -20, 0, 22); DropBtn.BackgroundColor3 = Color3.fromRGB(22, 22, 22); DropBtn.Font = Enum.Font.GothamSemibold; DropBtn.Text = "SCAN INVENTORY ↻"; DropBtn.TextColor3 = Color3.fromRGB(255, 185, 0); DropBtn.TextSize = 8; DropBtn.Parent = MainFrame; Instance.new("UICorner", DropBtn).CornerRadius = UDim.new(0, 4)
local ListContainer = Instance.new("ScrollingFrame"); ListContainer.Position = UDim2.new(0, 10, 0, 92); ListContainer.Size = UDim2.new(1, -20, 0, 60); ListContainer.BackgroundColor3 = Color3.fromRGB(12, 12, 12); ListContainer.BorderSizePixel = 0; ListContainer.ScrollBarThickness = 2; ListContainer.Visible = false; ListContainer.Parent = MainFrame
local UIListLayout = Instance.new("UIListLayout"); UIListLayout.Parent = ListContainer; UIListLayout.Padding = UDim.new(0, 2)

local OpenButton = Instance.new("TextButton")
OpenButton.Name = "OpenButton"; OpenButton.Parent = ScreenGui; OpenButton.BackgroundColor3 = Color3.fromRGB(15, 15, 15); OpenButton.Position = UDim2.new(0, 10, 0.4, 0); OpenButton.Size = UDim2.new(0, 55, 0, 26); OpenButton.Font = Enum.Font.GothamBold; OpenButton.Text = "D-STOCK"; OpenButton.TextColor3 = Color3.fromRGB(255, 185, 0); OpenButton.TextSize = 9; OpenButton.BorderSizePixel = 1; OpenButton.BorderColor3 = Color3.fromRGB(255, 185, 0); OpenButton.Visible = false; Instance.new("UICorner", OpenButton).CornerRadius = UDim.new(0, 4)

MiniBtn.Activated:Connect(function() MainFrame.Visible = false; OpenButton.Visible = true end)
OpenButton.Activated:Connect(function() OpenButton.Visible = false; MainFrame.Visible = true end)

-- FUNGSI SCANNING INVENTORY OTOMATIS (MURNI MENGIKUTI APA YANG ADA DI TAS)
local function RefreshInventoryList()
    for _, child in pairs(ListContainer:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end
    table.clear(AutoDetectedTools)
    
    local bp = LocalPlayer:FindFirstChild("Backpack")
    local char = LocalPlayer.Character
    local foundItems = {}
    
    local function checkAndAdd(tool)
        if tool:IsA("Tool") and not foundItems[tool.Name] then
            foundItems[tool.Name] = true
            table.insert(AutoDetectedTools, tool.Name)
            
            local btn = Instance.new("TextButton"); btn.Size = UDim2.new(1, 0, 0, 18); btn.BackgroundColor3 = Color3.fromRGB(255, 185, 0); btn.Text = "  " .. tool.Name; btn.TextColor3 = Color3.fromRGB(15, 15, 15); btn.Font = Enum.Font.GothamSemibold; btn.TextSize = 8; btn.TextXAlignment = Enum.TextXAlignment.Left; btn.Parent = ListContainer; Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
        end
    end
    
    if bp then for _, t in pairs(bp:GetChildren()) do checkAndAdd(t) end end
    if char then for _, t in pairs(char:GetChildren()) do checkAndAdd(t) end end
    ListContainer.CanvasSize = UDim2.new(0, 0, 0, #AutoDetectedTools * 20)
end

DropBtn.Activated:Connect(function() 
    RefreshInventoryList()
    ListContainer.Visible = not ListContainer.Visible
    DropBtn.Text = ListContainer.Visible and "CLOSE LIST ▲" or "SCAN INVENTORY ↻"
end)

RestockButton.Activated:Connect(function()
    _G.DynamicRestockActive = not _G.DynamicRestockActive
    RestockButton.BackgroundColor3 = _G.DynamicRestockActive and Color3.fromRGB(15, 30, 15) or Color3.fromRGB(30, 15, 15)
    RestockButton.TextColor3 = _G.DynamicRestockActive and Color3.fromRGB(255, 185, 0) or Color3.fromRGB(220, 53, 69)
    RestockButton.Text = _G.DynamicRestockActive and "RESTOCK: ON" or "RESTOCK: OFF"
end)

-- SYSTEM DRAGGABLE UI MOBILE
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

-- MAIN BACKGROUND AUTOMATION LOOP (100% TERISOLASI)
task.spawn(function()
    while task.wait(0.1) do
        if _G.DynamicRestockActive and #AutoDetectedTools > 0 then
            local char = LocalPlayer.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if root then
                local kiosAktif = workspace:FindFirstChild("KiosAktif")
                local myKios = kiosAktif and (kiosAktif:FindFirstChild("Kios_" .. LocalPlayer.Name) or kiosAktif:FindFirstChild("Kios_panggil_" .. LocalPlayer.Name))
                if myKios then
                    for i = 1, 12 do
                        local slot = myKios:FindFirstChild("slot" .. i) or myKios:FindFirstChild("slot " .. i)
                        if slot then
                            local prompt = slot:FindFirstChildWhichIsA("ProximityPrompt", true)
                            if prompt and prompt.Enabled then
                                local done = false
                                for _, toolName in ipairs(AutoDetectedTools) do
                                    if equipItem(toolName) then
                                        local part = slot:IsA("BasePart") and slot or slot:FindFirstChildWhichIsA("BasePart", true)
                                        if part and _G.DynamicRestockActive then
                                            root.Velocity = Vector3.new(0,0,0); root.CFrame = part.CFrame; task.wait(0.2)
                                            prompt:InputHoldBegin(); task.wait(0.4); prompt:InputHoldEnd()
                                            if fireproximityprompt then fireproximityprompt(prompt) end
                                            task.wait(0.3); done = true; break
                                        end
                                    end
                                end
                                if done then break end
                            end
                        end
                    end
                end
            end
        end
    end
end)
