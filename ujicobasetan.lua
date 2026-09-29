-- [[ ALIT HUB V3 - INDEPENDENT THREAD ISOLATION EDITION - PART 1 ]]
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
task.wait(0.1)

local TARGET_MAPPING = {
    ["Dupa"] = "Spawn_Dupa", ["Gagak"] = "Spawn_Gagak",
    ["Jamur Kuburan"] = "Spawn_JamurKuburan", ["Kemenyan"] = "Spawn_Kemenyan",
    ["Kepiting Sungai"] = "Spawn_KepitingSungai", ["Melati"] = "Spawn_Melati"
}
local RESTOCK_MAPPING = {
    ["Sate Gagak"] = "Sate Gagak", ["Jamur Rebus Kuburan"] = "Jamur Rebus Kuburan",
    ["Tumis Kamboja"] = "Tumis Kamboja", ["Sate Kepiting"] = "Sate Kepiting",
    ["Pisang Raja Rebus"] = "Pisang Raja Rebus", ["Kopi Kemenyan"] = "Kopi Kemenyan"
}
local COOK_MAPPING = {
    ["Sate Gagak"] = "SateGagak", ["Jamur Rebus Kuburan"] = "JamurRebus",
    ["Tumis Kamboja"] = "TumisKamboja", ["Sate Kepiting"] = "SateKepiting",
    ["Pisang Raja Rebus"] = "PisangRajaRebus", ["Kopi Kemenyan"] = "KopiKemenyan"
}
local FEED_MAPPING = { ["Jamur Rebus"] = "JamurRebus", ["Pisang Raja Rebus"] = "PisangRajaRebus" }

local SelectedTargets, SelectedRestock, SelectedFeed = {}, {}, {}
local GLOBAL_SAVED_POS = UDim2.new(0.5, -175, 0.3, -110)
_G.SelectedCookMenu = "Sate Gagak"

local TELEPORT_DELAY = 0.2      
local MASA_TUNGGU = 5.0         
local REPEAT_COOK_DELAY = 1.5   
-- [[ ALIT HUB V3 - INDEPENDENT THREAD ISOLATION EDITION - PART 2 ]]
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
-- [[ ALIT HUB V3 - INDEPENDENT THREAD ISOLATION EDITION - PART 3 ]]
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

local ToggleButton = Instance.new("TextButton"); ToggleButton.Size = UDim2.new(1, 0, 0, 28); ToggleButton.BackgroundColor3 = Color3.fromRGB(30, 15, 15); ToggleButton.Font = Enum.Font.GothamBold; ToggleButton.Text = "FARM SYSTEM: OFF"; ToggleButton.TextColor3 = Color3.fromRGB(220, 53, 69); ToggleButton.TextSize = 9; ToggleButton.Parent = SubFrames["AUTO FARM"]; Instance.new("UICorner", ToggleButton).CornerRadius = UDim.new(0, 4)
local DropdownButton = Instance.new("TextButton"); DropdownButton.Position = UDim2.new(0, 0, 0, 34); DropdownButton.Size = UDim2.new(1, 0, 0, 24); DropdownButton.BackgroundColor3 = Color3.fromRGB(22, 22, 22); DropdownButton.Font = Enum.Font.GothamSemibold; DropdownButton.Text = "SELECT TARGETS ▼"; DropdownButton.TextColor3 = TEXT_DARK; DropdownButton.TextSize = 9; DropdownButton.Parent = SubFrames["AUTO FARM"]; Instance.new("UICorner", DropdownButton).CornerRadius = UDim.new(0, 4)
local ListContainer = Instance.new("ScrollingFrame"); ListContainer.Position = UDim2.new(0, 0, 0, 62); ListContainer.Size = UDim2.new(1, 0, 1, -62); ListContainer.BackgroundColor3 = Color3.fromRGB(12, 12, 12); ListContainer.BorderSizePixel = 0; ListContainer.ScrollBarThickness = 2; ListContainer.Visible = false; ListContainer.Parent = SubFrames["AUTO FARM"]
local UIListLayout = Instance.new("UIListLayout"); UIListLayout.Parent = ListContainer; UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder; UIListLayout.Padding = UDim.new(0, 2)
-- [[ ALIT HUB V3 - INDEPENDENT THREAD ISOLATION EDITION - PART 4 ]]
local RestockButton = Instance.new("TextButton"); RestockButton.Size = UDim2.new(1, 0, 0, 28); RestockButton.BackgroundColor3 = Color3.fromRGB(30, 15, 15); RestockButton.Font = Enum.Font.GothamBold; RestockButton.Text = "RESTOCK KIOS: OFF"; RestockButton.TextColor3 = Color3.fromRGB(220, 53, 69); RestockButton.TextSize = 9; RestockButton.Parent = SubFrames["AUTO STOCK"]; Instance.new("UICorner", RestockButton).CornerRadius = UDim.new(0, 4)
local DropdownButton2 = Instance.new("TextButton"); DropdownButton2.Position = UDim2.new(0, 0, 0, 34); DropdownButton2.Size = UDim2.new(1, 0, 0, 24); DropdownButton2.BackgroundColor3 = Color3.fromRGB(22, 22, 22); DropdownButton2.Font = Enum.Font.GothamSemibold; DropdownButton2.Text = "SELECT ITEMS ▼"; DropdownButton2.TextColor3 = TEXT_DARK; DropdownButton2.TextSize = 9; DropdownButton2.Parent = SubFrames["AUTO STOCK"]; Instance.new("UICorner", DropdownButton2).CornerRadius = UDim.new(0, 4)
local ListContainer2 = Instance.new("ScrollingFrame"); ListContainer2.Position = UDim2.new(0, 0, 0, 62); ListContainer2.Size = UDim2.new(1, 0, 1, -62); ListContainer2.BackgroundColor3 = Color3.fromRGB(12, 12, 12); ListContainer2.BorderSizePixel = 0; ListContainer2.ScrollBarThickness = 2; ListContainer2.Visible = false; ListContainer2.Parent = SubFrames["AUTO STOCK"]
local UIListLayout2 = Instance.new("UIListLayout"); UIListLayout2.Parent = ListContainer2; UIListLayout2.SortOrder = Enum.SortOrder.LayoutOrder; UIListLayout2.Padding = UDim.new(0, 2)

local PigButton = Instance.new("TextButton"); PigButton.Size = UDim2.new(1, 0, 0, 28); PigButton.BackgroundColor3 = Color3.fromRGB(30, 15, 15); PigButton.Font = Enum.Font.GothamBold; PigButton.Text = "PIG REAR SYSTEM: OFF"; PigButton.TextColor3 = Color3.fromRGB(220, 53, 69); PigButton.TextSize = 9; PigButton.Parent = SubFrames["AUTO PIG"]; Instance.new("UICorner", PigButton).CornerRadius = UDim.new(0, 4)
local FeedLabel = Instance.new("TextLabel"); FeedLabel.Position = UDim2.new(0, 5, 0, 34); FeedLabel.Size = UDim2.new(1, -10, 0, 20); FeedLabel.BackgroundTransparency = 1; FeedLabel.Font = Enum.Font.GothamBold; FeedLabel.Text = "SELECT FEED METHOD:"; FeedLabel.TextColor3 = ACCENT_GOLD; FeedLabel.TextSize = 9; FeedLabel.TextXAlignment = Enum.TextXAlignment.Left; FeedLabel.Parent = SubFrames["AUTO PIG"]
local ListContainerFeed = Instance.new("Frame"); ListContainerFeed.Position = UDim2.new(0, 0, 0, 58); ListContainerFeed.Size = UDim2.new(1, 0, 1, -58); ListContainerFeed.BackgroundTransparency = 1; ListContainerFeed.Parent = SubFrames["AUTO PIG"]
local UIListLayoutFeed = Instance.new("UIListLayout"); UIListLayoutFeed.Parent = ListContainerFeed; UIListLayoutFeed.SortOrder = Enum.SortOrder.LayoutOrder; UIListLayoutFeed.Padding = UDim.new(0, 2)

local CookButton = Instance.new("TextButton"); CookButton.Size = UDim2.new(1, 0, 0, 28); CookButton.BackgroundColor3 = Color3.fromRGB(30, 15, 15); CookButton.Font = Enum.Font.GothamBold; CookButton.Text = "COOK SYSTEM: OFF"; CookButton.TextColor3 = Color3.fromRGB(220, 53, 69); CookButton.TextSize = 9; CookButton.Parent = SubFrames["AUTO COOK"]; Instance.new("UICorner", CookButton).CornerRadius = UDim.new(0, 4)
local DropdownButton3 = Instance.new("TextButton"); DropdownButton3.Position = UDim2.new(0, 0, 0, 34); DropdownButton3.Size = UDim2.new(1, 0, 0, 24); DropdownButton3.BackgroundColor3 = Color3.fromRGB(22, 22, 22); DropdownButton3.Font = Enum.Font.GothamSemibold; DropdownButton3.Text = "RECIPE: SATE GAGAK ▼"; DropdownButton3.TextColor3 = TEXT_DARK; DropdownButton3.TextSize = 9; DropdownButton3.Parent = SubFrames["AUTO COOK"]; Instance.new("UICorner", DropdownButton3).CornerRadius = UDim.new(0, 4)
local ListContainer3 = Instance.new("ScrollingFrame"); ListContainer3.Position = UDim2.new(0, 0, 0, 62); ListContainer3.Size = UDim2.new(1, 0, 1, -62); ListContainer3.BackgroundColor3 = Color3.fromRGB(12, 12, 12); ListContainer3.BorderSizePixel = 0; ListContainer3.ScrollBarThickness = 2; ListContainer3.Visible = false; ListContainer3.Parent = SubFrames["AUTO COOK"]
local UIListLayout3 = Instance.new("UIListLayout"); UIListLayout3.Parent = ListContainer3; UIListLayout3.SortOrder = Enum.SortOrder.LayoutOrder; UIListLayout3.Padding = UDim.new(0, 2)
-- [[ ALIT HUB V3 - INDEPENDENT THREAD ISOLATION EDITION - PART 5 ]]
for disp, ws in pairs(TARGET_MAPPING) do
    local btn = Instance.new("TextButton"); btn.Size = UDim2.new(1, 0, 0, 20); btn.BackgroundColor3 = Color3.fromRGB(20, 20, 20); btn.Text = "  " .. disp; btn.TextColor3 = TEXT_DARK; btn.Font = Enum.Font.GothamSemibold; btn.TextSize = 9; btn.TextXAlignment = Enum.TextXAlignment.Left; btn.Parent = ListContainer; Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
    btn.Activated:Connect(function() local idx = table.find(SelectedTargets, ws) if idx then table.remove(SelectedTargets, idx); btn.TextColor3 = TEXT_DARK; btn.BackgroundColor3 = Color3.fromRGB(20, 20, 20) else table.insert(SelectedTargets, ws); btn.TextColor3 = BG_COLOR; btn.BackgroundColor3 = ACCENT_GOLD end end)
end
for disp, tool in pairs(RESTOCK_MAPPING) do
    local btn = Instance.new("TextButton"); btn.Size = UDim2.new(1, 0, 0, 20); btn.BackgroundColor3 = Color3.fromRGB(20, 20, 20); btn.Text = "  " .. disp; btn.TextColor3 = TEXT_DARK; btn.Font = Enum.Font.GothamSemibold; btn.TextSize = 9; btn.TextXAlignment = Enum.TextXAlignment.Left; btn.Parent = ListContainer2; Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
    btn.Activated:Connect(function() local idx = table.find(SelectedRestock, tool) if idx then table.remove(SelectedRestock, idx); btn.TextColor3 = TEXT_DARK; btn.BackgroundColor3 = Color3.fromRGB(20, 20, 20) else table.insert(SelectedRestock, tool); btn.TextColor3 = BG_COLOR; btn.BackgroundColor3 = ACCENT_GOLD end end)
end
for disp, code in pairs(RESTOCK_MAPPING) do
    local btn = Instance.new("TextButton"); btn.Size = UDim2.new(1, 0, 0, 20); btn.BackgroundColor3 = Color3.fromRGB(20, 20, 20); btn.Text = "  " .. disp; btn.TextColor3 = TEXT_DARK; btn.Font = Enum.Font.GothamSemibold; btn.TextSize = 9; btn.TextXAlignment = Enum.TextXAlignment.Left; btn.Parent = ListContainer3; Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
    btn.Activated:Connect(function() _G.SelectedCookMenu = disp; DropdownButton3.Text = "RECIPE: " .. string.upper(disp) .. " ▼"; ListContainer3.Visible = false end)
end
for disp, tool in pairs(FEED_MAPPING) do
    local btn = Instance.new("TextButton"); btn.Size = UDim2.new(1, 0, 0, 20); btn.BackgroundColor3 = Color3.fromRGB(20, 20, 20); btn.Text = "  " .. disp; btn.TextColor3 = TEXT_DARK; btn.Font = Enum.Font.GothamSemibold; btn.TextSize = 9; btn.TextXAlignment = Enum.TextXAlignment.Left; btn.Parent = ListContainerFeed; Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
    btn.Activated:Connect(function() local idx = table.find(SelectedFeed, tool) if idx then table.remove(SelectedFeed, idx); btn.TextColor3 = TEXT_DARK; btn.BackgroundColor3 = Color3.fromRGB(20, 20, 20) else table.insert(SelectedFeed, tool); btn.TextColor3 = BG_COLOR; btn.BackgroundColor3 = ACCENT_GOLD end end)
end

ListContainer.CanvasSize = UDim2.new(0, 0, 0, 130); ListContainer2.CanvasSize = UDim2.new(0, 0, 0, 130); ListContainer3.CanvasSize = UDim2.new(0, 0, 0, 130)
DropdownButton.Activated:Connect(function() ListContainer.Visible = not ListContainer.Visible; DropdownButton.Text = ListContainer.Visible and "SELECT TARGETS ▲" or "SELECT TARGETS ▼" end)
DropdownButton2.Activated:Connect(function() ListContainer2.Visible = not ListContainer2.Visible; DropdownButton2.Text = ListContainer2.Visible and "SELECT ITEMS ▲" or "SELECT ITEMS ▼" end)
DropdownButton3.Activated:Connect(function() ListContainer3.Visible = not ListContainer3.Visible; DropdownButton3.Text = ListContainer3.Visible and "SELECT RECIPE ▲" or "SELECT RECIPE ▼" end)

ToggleButton.Activated:Connect(function() _G.AlitHubFarmActive = not _G.AlitHubFarmActive; ToggleButton.BackgroundColor3 = _G.AlitHubFarmActive and Color3.fromRGB(15, 30, 15) or Color3.fromRGB(30, 15, 15); ToggleButton.TextColor3 = _G.AlitHubFarmActive and ACCENT_GOLD or Color3.fromRGB(220, 53, 69); ToggleButton.Text = _G.AlitHubFarmActive and "FARM SYSTEM: ON" or "FARM SYSTEM: OFF" end)
RestockButton.Activated:Connect(function() _G.AlitHubRestockActive = not _G.AlitHubRestockActive; RestockButton.BackgroundColor3 = _G.AlitHubRestockActive and Color3.fromRGB(15, 30, 15) or Color3.fromRGB(30, 15, 15); RestockButton.TextColor3 = _G.AlitHubRestockActive and ACCENT_GOLD or Color3.fromRGB(220, 53, 69); RestockButton.Text = _G.AlitHubRestockActive and "RESTOCK KIOS: ON" or "RESTOCK KIOS: OFF" end)
PigButton.Activated:Connect(function() _G.AlitHubPigActive = not _G.AlitHubPigActive; PigButton.BackgroundColor3 = _G.AlitHubPigActive and Color3.fromRGB(15, 30, 15) or Color3.fromRGB(30, 15, 15); PigButton.TextColor3 = _G.AlitHubPigActive and ACCENT_GOLD or Color3.fromRGB(220, 53, 69); PigButton.Text = _G.AlitHubPigActive and "PIG REAR SYSTEM: ON" or "PIG REAR SYSTEM: OFF" end)
CookButton.Activated:Connect(function() _G.AlitHubCookActive = not _G.AlitHubCookActive; CookButton.BackgroundColor3 = _G.AlitHubCookActive and Color3.fromRGB(15, 30, 15) or Color3.fromRGB(30, 15, 15); CookButton.TextColor3 = _G.AlitHubCookActive and ACCENT_GOLD or Color3.fromRGB(220, 53, 69); CookButton.Text = _G.AlitHubCookActive and "COOK SYSTEM: ON" or "COOK SYSTEM: OFF" end)
-- [[ ALIT HUB V3 - INDEPENDENT THREAD ISOLATION EDITION - PART 6 ]]
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
    if root then root.Velocity = Vector3.new(0, 0, 0); root.CFrame = targetCFrame; root.Velocity = Vector3.new(0, 0, 0) end
end

local function executePerfectHarvest(prompt)
    if not prompt or not prompt.Enabled then return end
    task.wait(TELEPORT_DELAY)
    prompt:InputHoldBegin(); task.wait(0.5); prompt:InputHoldEnd()
    if fireproximityprompt then fireproximityprompt(prompt) end
    task.wait(MASA_TUNGGU)
end

local function clickVirtualCookRowButton(gui, targetMenuString)
    if not gui then return false end
    for _, textObj in pairs(gui:GetDescendants()) do
        if textObj:IsA("TextLabel") and string.find(string.lower(textObj.Text), string.lower(targetMenuString)) then
            local p = textObj.Parent
            if p then
                local actBtn = p:FindFirstChild("MasakButton") or p:FindFirstChild("CookBtn") or p:FindFirstChildWhichIsA("TextButton", true)
                if actBtn and actBtn.Activated then actBtn.Activated:Fire(); return true end
            end
        end
    end
    return false
end

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

local floatToggle, floatStart, floatStartPos
OpenButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        floatToggle = true; floatStart = input.Position; floatStartPos = OpenButton.Position
        input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then floatToggle = false end end)
    end
end)
game:GetService("UserInputService").InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement then
        if floatToggle then
            local delta = input.Position - floatStart
            OpenButton.Position = UDim2.new(floatStartPos.X.Scale, floatStartPos.X.Offset + delta.X, floatStartPos.Y.Scale, floatStartPos.Y.Offset + delta.Y)
        end
    end
end)

LocalPlayer.Idled:Connect(function()
    if _G.AlitHubFarmActive or _G.AlitHubRestockActive or _G.AlitHubPigActive or _G.AlitHubCookActive then
        local vu = game:GetService("VirtualUser")
        vu:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame); task.wait(0.5); vu:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
    end
end)
-- [[ ALIT HUB V3 - INDEPENDENT THREAD ISOLATION EDITION - PART 7 ]]
-- THREAD MANDIRI 1: KHUSUS KONTROL AUTO FARMING (TERISOLASI PENUH)
task.spawn(function()
    while true do
        task.wait(0.1)
        if _G.AlitHubFarmActive then
            local char = LocalPlayer.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if root and hum and #SelectedTargets > 0 then
                local folder = workspace:FindFirstChild("SpawnBahan")
                if folder then
                    for _, obj in pairs(folder:GetChildren()) do
                        if table.find(SelectedTargets, obj.Name) then
                            local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
                            if prompt and prompt.Enabled and prompt.Parent then
                                local part = prompt.Parent:IsA("BasePart") and prompt.Parent or obj:FindFirstChildWhichIsA("BasePart", true)
                                if part and _G.AlitHubFarmActive then 
                                    instantTeleportTo(root, part.CFrame); executePerfectHarvest(prompt); break 
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end)

-- THREAD MANDIRI 2: KHUSUS KONTROL AUTO RESTOCK (TERISOLASI PENUH)
task.spawn(function()
    while true do
        task.wait(0.1)
        if _G.AlitHubRestockActive then
            local char = LocalPlayer.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if root and hum and #SelectedRestock > 0 then
                local kiosAktif = workspace:FindFirstChild("KiosAktif")
                local myKios = kiosAktif and (kiosAktif:FindFirstChild("Kios_" .. LocalPlayer.Name) or kiosAktif:FindFirstChild("Kios_panggil_" .. LocalPlayer.Name))
                if myKios then
                    for i = 1, 12 do
                        local slot = myKios:FindFirstChild("slot" .. i) or myKios:FindFirstChild("slot " .. i)
                        if slot then
                            local prompt = slot:FindFirstChildWhichIsA("ProximityPrompt", true)
                            if prompt and prompt.Enabled then
                                local breakRestock = false
                                for _, toolName in ipairs(SelectedRestock) do
                                    if equipItem(toolName) then
                                        local targetPart = slot:IsA("BasePart") and slot or slot:FindFirstChildWhichIsA("BasePart", true)
                                        if targetPart and _G.AlitHubRestockActive then
                                            instantTeleportTo(root, targetPart.CFrame); executePerfectHarvest(prompt); breakRestock = true; break
                                        end
                                    end
                                end
                                if breakRestock then break end
                            end
                        end
                    end
                end
            end
        end
    end
end)

-- THREAD MANDIRI 3: KHUSUS KONTROL AUTO COOK (TERISOLASI PENUH)
task.spawn(function()
    while true do
        task.wait(0.1)
        if _G.AlitHubCookActive then
            local char = LocalPlayer.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if root and hum then
                local kiosAktif = workspace:FindFirstChild("KiosAktif")
                local myKios = kiosAktif and (kiosAktif:FindFirstChild("Kios_" .. LocalPlayer.Name) or kiosAktif:FindFirstChild("Kios_panggil_" .. LocalPlayer.Name))
                if myKios then
                    local pKompor = myKios:FindFirstChild("pKompor") or myKios:FindFirstChildWhichIsA("Attachment", true)
                    if pKompor then
                        local prompt = pKompor:FindFirstChildOfClass("ProximityPrompt") or myKios:FindFirstChildWhichIsA("ProximityPrompt", true)
                        if prompt and prompt.Enabled then
                            instantTeleportTo(root, pKompor.WorldCFrame); task.wait(TELEPORT_DELAY)
                            prompt:InputHoldBegin(); task.wait(0.5); prompt:InputHoldEnd()
                            if fireproximityprompt then fireproximityprompt(prompt) end
                            task.wait(0.3)
                            
                            local cookingGui = PlayerGui:FindFirstChild("MemasakGui") or PlayerGui:FindFirstChildWhichIsA("ScreenGui", true)
                            if cookingGui and cookingGui.Enabled then
                                local count = 0
                                for i = 1, 3 do
                                    if _G.AlitHubCookActive and clickVirtualCookRowButton(cookingGui, _G.SelectedCookMenu) then count = count + 1; task.wait(0.1) end
                                end
                                if count > 0 then task.wait(10) end
                            end
                        end
                    end
                end
            end
        end
    end
end)

-- THREAD MANDIRI 4: KHUSUS KONTROL AUTO FEED & PANEN BABI (TERISOLASI PENUH)
task.spawn(function()
    while true do
        task.wait(0.1)
        if _G.AlitHubPigActive then
            local char = LocalPlayer.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if root and hum then
                local folderKandang = workspace:FindFirstChild("KandangBabi") or workspace
                for _, kandang in pairs(folderKandang:GetChildren()) do
                    if string.find(kandang.Name, LocalPlayer.UserId) or string.find(kandang.Name, LocalPlayer.Name) then
                        local tempatMakan = kandang:FindFirstChild("TempatMakan") or kandang:FindFirstChild("Tempat Makan")
                        local pakanPrompt = tempatMakan and tempatMakan:FindFirstChildWhichIsA("ProximityPrompt", true)
                        if pakanPrompt and pakanPrompt.Enabled then
                            local textStatus = pakanPrompt.ObjectText or ""
                            if string.find(textStatus, "0/10") or textStatus == "" then
                                for _, foodName in ipairs(SelectedFeed) do
                                    if equipItem(foodName) then
                                        local pmPart = tempatMakan:IsA("BasePart") and tempatMakan or tempatMakan:FindFirstChildWhichIsA("BasePart", true)
                                        if pmPart and _G.AlitHubPigActive then
                                            instantTeleportTo(root, pmPart.CFrame)
                                            while pakanPrompt.Enabled and _G.AlitHubPigActive and not string.find(pakanPrompt.ObjectText, "10/10") do
                                                pakanPrompt:InputHoldBegin(); task.wait(0.5); pakanPrompt:InputHoldEnd()
                                                if fireproximityprompt then fireproximityprompt(pakanPrompt) end; task.wait(0.1)
                                                if not equipItem(foodName) then break end
                                            end
                                        end
                                        break
                                    end
                                end
                            end
                        end
                        for _, babi in pairs(kandang:GetChildren()) do
                            if string.find(string.lower(babi.Name), "babi") or babi:FindFirstChild("Fase") then
                                local statusFase = babi:FindFirstChild("Fase") or babi:FindFirstChild("Status")
                                if statusFase and string.find(string.lower(tostring(statusFase.Value)), "dewasa") then
                                    local panenPrompt = babi:FindFirstChildWhichIsA("ProximityPrompt", true)
                                    if panenPrompt and panenPrompt.Enabled then
                                        local babiPart = babi:IsA("BasePart") and babi or babi:FindFirstChildWhichIsA("BasePart", true)
                                        if babiPart and _G.AlitHubPigActive then 
                                            instantTeleportTo(root, babiPart.CFrame); executePerfectHarvest(panenPrompt); break 
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
