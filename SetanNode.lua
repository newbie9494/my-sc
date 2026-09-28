-- [[ ALIT HUB - TELEPORT INSTAN + RESTOCK & PIG FARM PART 1 ]]
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
task.wait(0.1)

local TARGET_MAPPING = {
    ["Dupa"] = "Spawn_Dupa", ["Gagak"] = "Spawn_Gagak",
    ["Jamur Kuburan"] = "Spawn_JamurKuburan", ["Kemenyan"] = "Spawn_Kemenyan",
    ["Kepiting Sungai"] = "Spawn_KepitingSungai", ["Melati"] = "Spawn_Melati"
}
local RESTOCK_MAPPING = { ["Kepiting"] = "Kepiting", ["Sate Kepiting"] = "Sate Kepiting" }
local FEED_MAPPING = { ["Jamur Rebus"] = "JamurRebus", ["Pisang Raja Rebus"] = "PisangRajaRebus" }

-- FIXED: Inisialisasi tabel tunggal terpadu untuk mencegah putus referensi data
local SelectedTargets, SelectedRestock, SelectedFeed = {}, {}, {}
local GLOBAL_SAVED_POS = UDim2.new(0.5, -110, 0.3, -100)

-- KONFIGURASI DELAY AMAN DARI USER
local BLINK_SPEED = 250
local POST_PANEN_DELAY = 0.7
local TELEPORT_DELAY = 0.6

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AlitHubUI"
ScreenGui.Parent = PlayerGui
ScreenGui.ResetOnSpawn = false

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
MainFrame.Position = GLOBAL_SAVED_POS
MainFrame.Size = UDim2.new(0, 220, 0, 420)
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
MainFrame.Active = true
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 12)

local TopBar = Instance.new("Frame")
TopBar.Name = "TopBar"
TopBar.Parent = MainFrame
TopBar.BackgroundTransparency = 1
TopBar.Size = UDim2.new(1, 0, 0, 45)

local TitleButton = Instance.new("TextButton")
TitleButton.Name = "TitleButton"
TitleButton.Parent = TopBar
TitleButton.BackgroundTransparency = 1
TitleButton.Position = UDim2.new(0, 15, 0, 0)
TitleButton.Size = UDim2.new(0, 120, 0, 45)
TitleButton.Font = Enum.Font.GothamBold
TitleButton.Text = "ALIT HUB"
TitleButton.TextColor3 = Color3.fromRGB(255, 215, 0)
TitleButton.TextSize = 14
TitleButton.TextXAlignment = Enum.TextXAlignment.Left

local MiniButton = Instance.new("TextButton")
MiniButton.Name = "MiniButton"
MiniButton.Parent = TopBar
MiniButton.BackgroundTransparency = 1
MiniButton.Position = UDim2.new(1, -35, 0, 0)
MiniButton.Size = UDim2.new(0, 30, 0, 45)
MiniButton.Font = Enum.Font.GothamBold
MiniButton.Text = "-"
MiniButton.TextColor3 = Color3.fromRGB(200, 200, 200)
MiniButton.TextSize = 20

local ContentFrame = Instance.new("Frame")
ContentFrame.Name = "ContentFrame"
ContentFrame.Parent = MainFrame
ContentFrame.BackgroundTransparency = 1
ContentFrame.Position = UDim2.new(0, 0, 0, 45)
ContentFrame.Size = UDim2.new(1, 0, 1, -45)

local ToggleButton = Instance.new("TextButton")
ToggleButton.Name = "ToggleButton"
ToggleButton.Parent = ContentFrame
ToggleButton.BackgroundColor3 = Color3.fromRGB(220, 53, 69)
ToggleButton.Position = UDim2.new(0.04, 0, 0.02, 0)
ToggleButton.Size = UDim2.new(0.29, 0, 0, 32)
ToggleButton.Font = Enum.Font.GothamBold
ToggleButton.Text = "FARM: OFF"
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.TextSize = 9
Instance.new("UICorner", ToggleButton).CornerRadius = UDim.new(0, 5)

local RestockButton = Instance.new("TextButton")
RestockButton.Name = "RestockButton"
RestockButton.Parent = ContentFrame
RestockButton.BackgroundColor3 = Color3.fromRGB(220, 53, 69)
RestockButton.Position = UDim2.new(0.36, 0, 0.02, 0)
RestockButton.Size = UDim2.new(0.29, 0, 0, 32)
RestockButton.Font = Enum.Font.GothamBold
RestockButton.Text = "STOCK: OFF"
RestockButton.TextColor3 = Color3.fromRGB(255, 255, 255)
RestockButton.TextSize = 9
Instance.new("UICorner", RestockButton).CornerRadius = UDim.new(0, 5)

local PigButton = Instance.new("TextButton")
PigButton.Name = "PigButton"
PigButton.Parent = ContentFrame
PigButton.BackgroundColor3 = Color3.fromRGB(220, 53, 69)
PigButton.Position = UDim2.new(0.68, 0, 0.02, 0)
PigButton.Size = UDim2.new(0.29, 0, 0, 32)
PigButton.Font = Enum.Font.GothamBold
PigButton.Text = "PIG: OFF"
PigButton.TextColor3 = Color3.fromRGB(255, 255, 255)
PigButton.TextSize = 9
Instance.new("UICorner", PigButton).CornerRadius = UDim.new(0, 5)
-- [[ ALIT HUB - TELEPORT INSTAN + RESTOCK & PIG FARM PART 2 ]]
local DropdownButton = Instance.new("TextButton")
DropdownButton.Name = "DropdownButton"
DropdownButton.Parent = ContentFrame
DropdownButton.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
DropdownButton.Position = UDim2.new(0.05, 0, 0.12, 0)
DropdownButton.Size = UDim2.new(0.9, 0, 0, 28)
DropdownButton.Font = Enum.Font.GothamSemibold
DropdownButton.Text = "TARGET FARM ▼"
DropdownButton.TextColor3 = Color3.fromRGB(240, 240, 240)
DropdownButton.TextSize = 10
Instance.new("UICorner", DropdownButton).CornerRadius = UDim.new(0, 5)

local ListContainer = Instance.new("ScrollingFrame")
ListContainer.Name = "ListContainer"
ListContainer.Parent = ContentFrame
ListContainer.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
ListContainer.Position = UDim2.new(0.05, 0, 0.20, 0)
ListContainer.Size = UDim2.new(0.9, 0, 0, 60)
ListContainer.BorderSizePixel = 0
ListContainer.ScrollBarThickness = 3
ListContainer.Visible = false
Instance.new("UICorner", ListContainer).CornerRadius = UDim.new(0, 5)
local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Parent = ListContainer
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 2)

local DropdownButton2 = Instance.new("TextButton")
DropdownButton2.Name = "DropdownButton2"
DropdownButton2.Parent = ContentFrame
DropdownButton2.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
DropdownButton2.Position = UDim2.new(0.05, 0, 0.40, 0)
DropdownButton2.Size = UDim2.new(0.9, 0, 0, 28)
DropdownButton2.Font = Enum.Font.GothamSemibold
DropdownButton2.Text = "TARGET RESTOCK ▼"
DropdownButton2.TextColor3 = Color3.fromRGB(240, 240, 240)
DropdownButton2.TextSize = 10
Instance.new("UICorner", DropdownButton2).CornerRadius = UDim.new(0, 5)

local ListContainer2 = Instance.new("ScrollingFrame")
ListContainer2.Name = "ListContainer2"
ListContainer2.Parent = ContentFrame
ListContainer2.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
ListContainer2.Position = UDim2.new(0.05, 0, 0.48, 0)
ListContainer2.Size = UDim2.new(0.9, 0, 0, 45)
ListContainer2.BorderSizePixel = 0
ListContainer2.ScrollBarThickness = 3
ListContainer2.Visible = false
Instance.new("UICorner", ListContainer2).CornerRadius = UDim.new(0, 5)
local UIListLayout2 = Instance.new("UIListLayout")
UIListLayout2.Parent = ListContainer2
UIListLayout2.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout2.Padding = UDim.new(0, 2)

local DropdownButton3 = Instance.new("TextButton")
DropdownButton3.Name = "DropdownButton3"
DropdownButton3.Parent = ContentFrame
DropdownButton3.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
DropdownButton3.Position = UDim2.new(0.05, 0, 0.68, 0)
DropdownButton3.Size = UDim2.new(0.9, 0, 0, 28)
DropdownButton3.Font = Enum.Font.GothamSemibold
DropdownButton3.Text = "TARGET PAKAN PIG ▼"
DropdownButton3.TextColor3 = Color3.fromRGB(240, 240, 240)
DropdownButton3.TextSize = 10
Instance.new("UICorner", DropdownButton3).CornerRadius = UDim.new(0, 5)

local ListContainer3 = Instance.new("ScrollingFrame")
ListContainer3.Name = "ListContainer3"
ListContainer3.Parent = ContentFrame
ListContainer3.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
ListContainer3.Position = UDim2.new(0.05, 0, 0.76, 0)
ListContainer3.Size = UDim2.new(0.9, 0, 0, 45)
ListContainer3.BorderSizePixel = 0
ListContainer3.ScrollBarThickness = 3
ListContainer3.Visible = false
Instance.new("UICorner", ListContainer3).CornerRadius = UDim.new(0, 5)
local UIListLayout3 = Instance.new("UIListLayout")
UIListLayout3.Parent = ListContainer3
UIListLayout3.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout3.Padding = UDim.new(0, 2)

MiniButton.Activated:Connect(function() 
    ContentFrame.Visible = false 
    MiniButton.Visible = false 
    MainFrame.Position = UDim2.new(0, 10, 0.4, 0) 
    MainFrame.Size = UDim2.new(0, 100, 0, 45) 
end)

TitleButton.Activated:Connect(function() 
    if not ContentFrame.Visible then 
        MainFrame.Position = GLOBAL_SAVED_POS 
        MainFrame.Size = UDim2.new(0, 220, 0, 420) 
        ContentFrame.Visible = true 
        MiniButton.Visible = true 
    end 
end)

for disp, ws in pairs(TARGET_MAPPING) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 22); btn.BackgroundColor3 = Color3.fromRGB(35, 35, 40); btn.Text = disp; btn.TextColor3 = Color3.fromRGB(200, 200, 200); btn.Font = Enum.Font.Gotham; btn.TextSize = 9; btn.Parent = ListContainer; Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
    btn.Activated:Connect(function() 
        local idx = table.find(SelectedTargets, ws) 
        if idx then 
            table.remove(SelectedTargets, idx); btn.BackgroundColor3 = Color3.fromRGB(35, 35, 40) 
        else 
            table.insert(SelectedTargets, ws); btn.BackgroundColor3 = Color3.fromRGB(40, 167, 69) 
        end 
    end)
end

for disp, tool in pairs(RESTOCK_MAPPING) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 22); btn.BackgroundColor3 = Color3.fromRGB(35, 35, 40); btn.Text = disp; btn.TextColor3 = Color3.fromRGB(200, 200, 200); btn.Font = Enum.Font.Gotham; btn.TextSize = 9; btn.Parent = ListContainer2; Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
    btn.Activated:Connect(function() 
        local idx = table.find(SelectedRestock, tool) 
        if idx then 
            table.remove(SelectedRestock, idx); btn.BackgroundColor3 = Color3.fromRGB(35, 35, 40) 
        else 
            table.insert(SelectedRestock, tool); btn.BackgroundColor3 = Color3.fromRGB(40, 167, 69) 
        end 
    end)
end

for disp, tool in pairs(FEED_MAPPING) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 22); btn.BackgroundColor3 = Color3.fromRGB(35, 35, 40); btn.Text = disp; btn.TextColor3 = Color3.fromRGB(200, 200, 200); btn.Font = Enum.Font.Gotham; btn.TextSize = 9; btn.Parent = ListContainer3; Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
    btn.Activated:Connect(function() 
        local idx = table.find(SelectedFeed, tool) 
        if idx then 
            table.remove(SelectedFeed, idx); btn.BackgroundColor3 = Color3.fromRGB(35, 35, 40) 
        else 
            table.insert(SelectedFeed, tool); btn.BackgroundColor3 = Color3.fromRGB(40, 167, 69) 
        end 
    end)
end

ListContainer.CanvasSize = UDim2.new(0, 0, 0, 160)
ListContainer2.CanvasSize = UDim2.new(0, 0, 0, 60)
ListContainer3.CanvasSize = UDim2.new(0, 0, 0, 60)

DropdownButton.Activated:Connect(function() ListContainer.Visible = not ListContainer.Visible; DropdownButton.Text = ListContainer.Visible and "TARGET FARM ▲" or "TARGET FARM ▼" end)
DropdownButton2.Activated:Connect(function() ListContainer2.Visible = not ListContainer2.Visible; DropdownButton2.Text = ListContainer2.Visible and "TARGET RESTOCK ▲" or "TARGET RESTOCK ▼" end)
DropdownButton3.Activated:Connect(function() ListContainer3.Visible = not ListContainer3.Visible; DropdownButton3.Text = ListContainer3.Visible and "TARGET PAKAN PIG ▲" or "TARGET PAKAN PIG ▼" end)

ToggleButton.Activated:Connect(function() 
    if _G.AlitHubFarmActive == true then
        _G.AlitHubFarmActive = false
        ToggleButton.BackgroundColor3 = Color3.fromRGB(220, 53, 69)
        ToggleButton.Text = "FARM: OFF"
    else
        _G.AlitHubFarmActive = true
        ToggleButton.BackgroundColor3 = Color3.fromRGB(40, 167, 69)
        ToggleButton.Text = "FARM: ON"
    end
end)

RestockButton.Activated:Connect(function() 
    if _G.AlitHubRestockActive == true then
        _G.AlitHubRestockActive = false
        RestockButton.BackgroundColor3 = Color3.fromRGB(220, 53, 69)
        RestockButton.Text = "STOCK: OFF"
    else
        _G.AlitHubRestockActive = true
        RestockButton.BackgroundColor3 = Color3.fromRGB(40, 167, 69)
        RestockButton.Text = "STOCK: ON"
    end
end)

PigButton.Activated:Connect(function() 
    if _G.AlitHubPigActive == true then
        _G.AlitHubPigActive = false
        PigButton.BackgroundColor3 = Color3.fromRGB(220, 53, 69)
        PigButton.Text = "PIG: OFF"
    else
        _G.AlitHubPigActive = true
        PigButton.BackgroundColor3 = Color3.fromRGB(40, 167, 69)
        PigButton.Text = "PIG: ON"
    end
end)
-- [[ ALIT HUB - TELEPORT INSTAN + RESTOCK & PIG FARM PART 3 ]]
local function equipItem(itemName)
    local bp = LocalPlayer:FindFirstChild("Backpack")
    local char = LocalPlayer.Character
    if bp and char then
        local tool = bp:FindFirstChild(itemName)
        if tool and char:FindFirstChildOfClass("Humanoid") then char.Humanoid:EquipTool(tool); return true end
    end
    return char and char:FindFirstChild(itemName) ~= nil
end

local function blinkTravelTo(root, humanoid, targetCFrame)
    if root and humanoid then
        local distance = (root.Position - targetCFrame.Position).Magnitude
        local duration = distance / BLINK_SPEED
        humanoid:ChangeState(Enum.HumanoidStateType.Physics)
        root.Velocity = Vector3.new(0, 0, 0)
        local tween = TweenService:Create(root, TweenInfo.new(duration, Enum.EasingStyle.Linear), {CFrame = targetCFrame})
        tween:Play(); tween.Completed:Wait()
        root.Velocity = Vector3.new(0, 0, 0)
        humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
    end
end

local function secureHoldPrompt(prompt)
    if not prompt or not prompt.Enabled then return end
    if fireproximityprompt then fireproximityprompt(prompt) end
    task.wait(0.02)
    prompt:InputHoldBegin()
    task.wait(0.6) 
    prompt:InputHoldEnd()
end

-- SYSTEM DRAGGABLE MANUAL (BYPASS EROR MOBILE)
local dragToggle, dragInput, dragStart, startPos
MainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragToggle = true; dragStart = input.Position; startPos = MainFrame.Position
        input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragToggle = false end end)
    end
end)
MainFrame.InputChanged:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end end)
game:GetService("UserInputService").InputChanged:Connect(function(input)
    if input == dragInput and dragToggle then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- BYPASS AFK KICK PROTECTOR
LocalPlayer.Idled:Connect(function()
    if _G.AlitHubFarmActive or _G.AlitHubRestockActive or _G.AlitHubPigActive then
        local vu = game:GetService("VirtualUser")
        vu:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame); task.wait(0.5); vu:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
    end
end)

task.spawn(function()
    while true do
        task.wait(0.3)
        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        
        if _G.AlitHubFarmActive and #SelectedTargets > 0 and root and hum then
            local folder = workspace:FindFirstChild("SpawnBahan")
            if folder then
                for _, obj in pairs(folder:GetChildren()) do
                    if table.find(SelectedTargets, obj.Name) then
                        local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
                        if prompt and prompt.Enabled and prompt.Parent then
                            local part = prompt.Parent:IsA("BasePart") and prompt.Parent or obj:FindFirstChildWhichIsA("BasePart", true)
                            if part then
                                blinkTravelTo(root, hum, part.CFrame); task.wait(TELEPORT_DELAY)
                                if _G.AlitHubFarmActive and prompt.Enabled then
                                    secureHoldPrompt(prompt)
                                    task.wait(POST_PANEN_DELAY)
                                end
                            end
                        end
                    end
                end
            end
        end
        
        if _G.AlitHubRestockActive and #SelectedRestock > 0 and root and hum then
            local kios = workspace:FindFirstChild("Kios_" .. LocalPlayer.Name)
            if kios then
                for i = 1, 12 do
                    local slot = kios:FindFirstChild("slot" .. i) or kios:FindFirstChild("slot " .. i)
                    if slot then
                        local prompt = slot:FindFirstChildWhichIsA("ProximityPrompt", true)
                        if prompt and prompt.Enabled then
                            for _, toolName in ipairs(SelectedRestock) do
                                if equipItem(toolName) then
                                    local targetPart = slot:IsA("BasePart") and slot or slot:FindFirstChildWhichIsA("BasePart", true)
                                    if targetPart then
                                        blinkTravelTo(root, hum, targetPart.CFrame); task.wait(TELEPORT_DELAY)
                                        if prompt.Enabled and _G.AlitHubRestockActive then
                                            secureHoldPrompt(prompt)
                                            task.wait(POST_PANEN_DELAY)
                                        end
                                    end
                                    break
                                end
                            end
                        end
                    end
                end
            end
        end

        if _G.AlitHubPigActive and root and hum then
            local kandang = workspace:FindFirstChild("KandangBabi_" .. LocalPlayer.UserId) or workspace:FindFirstChild("KandangBabi_" .. LocalPlayer.Name)
            if kandang then
                local tempatMakan = kandang:FindFirstChild("TempatMakan") or kandang:FindFirstChild("Tempat Makan")
                if tempatMakan and #SelectedFeed > 0 then
                    local pakanPrompt = tempatMakan:FindFirstChildWhichIsA("ProximityPrompt", true)
                    if pakanPrompt then
                        local textStatus = pakanPrompt.ObjectText or ""
                        if string.find(textStatus, "0/10") or textStatus == "" then
                            for _, foodName in ipairs(SelectedFeed) do
                                if equipItem(foodName) then
                                    local pmPart = tempatMakan:IsA("BasePart") and tempatMakan or tempatMakan:FindFirstChildWhichIsA("BasePart", true)
                                    if pmPart then
                                        blinkTravelTo(root, hum, pmPart.CFrame); task.wait(TELEPORT_DELAY)
                                        while pakanPrompt.Enabled and _G.AlitHubPigActive and not string.find(pakanPrompt.ObjectText, "10/10") do
                                            secureHoldPrompt(pakanPrompt)
                                            task.wait(0.2)
                                            if not equipItem(foodName) then break end
                                        end
                                    end
                                    break
                                end
                            end
                        end
                    end
                end
                for _, babi in pairs(kandang:GetChildren()) do
                    if string.find(string.lower(babi.Name), "babi") or babi:FindFirstChild("Fase") then
                        local statusFase = babi:FindFirstChild("Fase") or babi:FindFirstChild("Status")
                        if statusFase then
                            local faseValue = tostring(statusFase.Value)
                            if string.find(string.lower(faseValue), "dewasa") or string.find(string.lower(babi.Name), "dewasa") then
                                local panenPrompt = babi:FindFirstChildWhichIsA("ProximityPrompt", true)
                                if panenPrompt and panenPrompt.Enabled then
                                    local babiPart = babi:IsA("BasePart") and babi or babi:FindFirstChildWhichIsA("BasePart", true)
                                    if babiPart then
                                        blinkTravelTo(root, hum, babiPart.CFrame); task.wait(TELEPORT_DELAY)
                                        if panenPrompt.Enabled and _G.AlitHubPigActive then
                                            secureHoldPrompt(panenPrompt)
                                            task.wait(POST_PANEN_DELAY)
                                        end
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
