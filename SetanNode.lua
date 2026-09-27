-- [[ ALIT HUB ULTRA - NODE STYLE THEME GABUNGAN ]]
if not game:IsLoaded() then game.Loaded:Wait() end
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")

-- 1. ULTRA ANTI-KICK & METATABLE BYPASS (SISI CLIENT)
pcall(function()
    if game:GetService("ReplicatedStorage"):FindFirstChild("AddStrike") then
        game:GetService("ReplicatedStorage").AddStrike:Destroy()
    end
end)

local mt = getrawmetatable(game)
local old_namecall = mt.__namecall
local old_newindex = mt.__newindex
setreadonly(mt, false)

mt.__namecall = newcclosure(function(self, ...)
    local method = getnamecallmethod()
    if string.lower(method) == "kick" then
        warn("Anticheat mendeteksi upaya KICK. Pemblokiran berhasil!")
        return nil
    end
    if method == "Destroy" or method == "destroy" then
        if self == getcallingscript() then
            return nil
        end
    end
    return old_namecall(self, ...)
end)
setreadonly(mt, true)

-- 2. INISIALISASI VARIABEL ALIT HUB
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

local SelectedTargets, SelectedRestock, SelectedFeed = {}, {}, {}
local BLINK_SPEED, POST_PANEN_DELAY, TELEPORT_DELAY = 120, 0.3, 0.35
local GLOBAL_SAVED_POS = UDim2.new(0.5, -225, 0.3, -150)

-- 3. PEMBUATAN UI TEMA NODE HUB (GELAP + EMAS DENGAN TAB NAVIGASI)
if CoreGui:FindFirstChild("AlitHubUI") then 
    CoreGui.AlitHubUI:Destroy() 
end

local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "AlitHubUI"
ScreenGui.ResetOnSpawn = false

-- Bingkai Utama (Main Frame)
local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Name = "MainFrame"
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 22)
MainFrame.Position = GLOBAL_SAVED_POS
MainFrame.Size = UDim2.new(0, 450, 0, 300)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)

-- Garis Tepi Emas (UIStroke)
local Stroke = Instance.new("UIStroke", MainFrame)
Stroke.Color = Color3.fromRGB(218, 165, 32) -- Warna Gold
Stroke.Thickness = 1.5
Stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

-- Top Bar UI
local TopBar = Instance.new("Frame", MainFrame)
TopBar.Size = UDim2.new(1, 0, 0, 40)
TopBar.BackgroundTransparency = 1

local Title = Instance.new("TextButton", TopBar)
Title.BackgroundTransparency = 1
Title.Position = UDim2.new(0, 15, 0, 0)
Title.Size = UDim2.new(0, 150, 0, 40)
Title.Font = Enum.Font.GothamBold
Title.Text = "⚡ ALIT HUB V2"
Title.TextColor3 = Color3.fromRGB(218, 165, 32)
Title.TextSize = 14
Title.TextXAlignment = Enum.TextXAlignment.Left

-- Tombol Close (X) bergaya premium
local CloseBtn = Instance.new("TextButton", TopBar)
CloseBtn.BackgroundTransparency = 1
CloseBtn.Position = UDim2.new(1, -35, 0, 0)
CloseBtn.Size = UDim2.new(0, 30, 0, 40)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
CloseBtn.TextSize = 14
CloseBtn.Activated:Connect(function() ScreenGui:Destroy() end)

-- Panel Tab Menu Kontainer (Gaya Barisan Horizontal di Atas)
local TabBar = Instance.new("Frame", MainFrame)
TabBar.Position = UDim2.new(0, 15, 0, 40)
TabBar.Size = UDim2.new(1, -30, 0, 30)
TabBar.BackgroundTransparency = 1

local TabListLayout = Instance.new("UIListLayout", TabBar)
TabListLayout.FillDirection = Enum.FillDirection.Horizontal
TabListLayout.SortOrder = Enum.SortOrder.LayoutOrder
TabListLayout.Padding = UDim.new(0, 8)

-- Area Utama Konten (Kontainer Halaman)
local PagesContainer = Instance.new("Frame", MainFrame)
PagesContainer.Position = UDim2.new(0, 15, 0, 80)
PagesContainer.Size = UDim2.new(1, -30, 1, -95)
PagesContainer.BackgroundTransparency = 1

-- List halaman per kategori tab
local Pages = {}
local Tabs = {}

local function CreatePage(name)
    local Page = Instance.new("ScrollingFrame", PagesContainer)
    Page.Size = UDim2.new(1, 0, 1, 0)
    Page.BackgroundTransparency = 1
    Page.BorderSizePixel = 0
    Page.ScrollBarThickness = 4
    Page.Visible = false
    Instance.new("UIListLayout", Page).Padding = UDim.new(0, 4)
    Pages[name] = Page
    return Page
end

local function CreateTab(name, displayName)
    local TabButton = Instance.new("TextButton", TabBar)
    TabButton.Size = UDim2.new(0, 90, 1, 0)
    TabButton.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    TabButton.Font = Enum.Font.GothamSemibold
    TabButton.Text = displayName
    TabButton.TextColor3 = Color3.fromRGB(180, 180, 180)
    TabButton.TextSize = 11
    local corner = Instance.new("UICorner", TabButton)
    corner.CornerRadius = UDim.new(0, 5)
    
    local tabStroke = Instance.new("UIStroke", TabButton)
    tabStroke.Color = Color3.fromRGB(50, 50, 55)
    tabStroke.Thickness = 1
    
    Tabs[name] = {Button = TabButton, Stroke = tabStroke}
    return TabButton
end

-- Membuat 3 Tab Halaman Utama
local pageFarm = CreatePage("Farm")
local pageStock = CreatePage("Stock")
local pagePig = CreatePage("Pig")

local tabFarm = CreateTab("Farm", "Auto Farm")
local tabStock = CreateTab("Stock", "Restock Kios")
local tabPig = CreateTab("Pig", "Pig Farm")

local currentTab = nil

local function SwitchTab(tabName)
    if currentTab == tabName then return end
    currentTab = tabName
    
    -- Sembunyikan semua halaman & reset tombol
    for name, page in pairs(Pages) do
        page.Visible = (name == tabName)
    end
    
    for name, data in pairs(Tabs) do
        if name == tabName then
            data.Button.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
            data.Button.TextColor3 = Color3.fromRGB(255, 200, 0) -- Text Emas Aktif
            data.Stroke.Color = Color3.fromRGB(218, 165, 32)
        else
            data.Button.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
            data.Button.TextColor3 = Color3.fromRGB(180, 180, 180)
            data.Stroke.Color = Color3.fromRGB(50, 50, 55)
        end
    end
end

tabFarm.Activated:Connect(function() SwitchTab("Farm") end)
tabStock.Activated:Connect(function() SwitchTab("Stock") end)
tabPig.Activated:Connect(function() SwitchTab("Pig") end)
SwitchTab("Farm") -- Buka halaman pertama default

-- 4. MEMBUAT TOGGLE UTAMA DI TIAP HALAMAN (Gaya Node Hub Premium)
local function CreateMasterToggle(parentPage, text, globalVar)
    local Frame = Instance.new("Frame", parentPage)
    Frame.Size = UDim2.new(1, 0, 0, 35)
    Frame.BackgroundColor3 = Color3.fromRGB(28, 28, 32)
    Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 4)
    
    local Label = Instance.new("TextLabel", Frame)
    Label.Position = UDim2.new(0, 10, 0, 0)
    Label.Size = UDim2.new(0.6, 0, 1, 0)
    Label.BackgroundTransparency = 1
    Label.Font = Enum.Font.GothamBold
    Label.Text = "STATUS SISTEM: AKTIF"
    Label.TextColor3 = Color3.fromRGB(220, 220, 220)
    Label.TextSize = 11
    Label.TextXAlignment = Enum.TextXAlignment.Left
    
    local ToggleBtn = Instance.new("TextButton", Frame)
    ToggleBtn.Position = UDim2.new(1, -90, 0, 5)
    ToggleBtn.Size = UDim2.new(0, 80, 0, 25)
    ToggleBtn.BackgroundColor3 = Color3.fromRGB(220, 53, 69)
    ToggleBtn.Font = Enum.Font.GothamBold
    ToggleBtn.Text = "OFF"
    ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    ToggleBtn.TextSize = 10
    Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(0, 4)
    
    ToggleBtn.Activated:Connect(function()
        if globalVar == "Farm" then
            _G.AlitHubFarmActive = not _G.AlitHubFarmActive
            ToggleBtn.Text = _G.AlitHubFarmActive and "ON" or "OFF"
            ToggleBtn.BackgroundColor3 = _G.AlitHubFarmActive and Color3.fromRGB(40, 167, 69) or Color3.fromRGB(220, 53, 69)
        elseif globalVar == "Stock" then
            _G.AlitHubRestockActive = not _G.AlitHubRestockActive
            ToggleBtn.Text = _G.AlitHubRestockActive and "ON" or "OFF"
            ToggleBtn.BackgroundColor3 = _G.AlitHubRestockActive and Color3.fromRGB(40, 167, 69) or Color3.fromRGB(220, 53, 69)
        elseif globalVar == "Pig" then
            _G.AlitHubPigActive = not _G.AlitHubPigActive
            ToggleBtn.Text = _G.AlitHubPigActive and "ON" or "OFF"
            ToggleBtn.BackgroundColor3 = _G.AlitHubPigActive and Color3.fromRGB(40, 167, 69) or Color3.fromRGB(220, 53, 69)
        end
    end)
end

CreateMasterToggle(pageFarm, "FARM UTAMA", "Farm")
CreateMasterToggle(pageStock, "RESTOCK UTAMA", "Stock")
CreateMasterToggle(pagePig, "PIG FARM UTAMA", "Pig")

-- Membuat spacer pemisah list
local function CreateDivider(parentPage, text)
    local Frame = Instance.new("Frame", parentPage)
    Frame.Size = UDim2.new(1, 0, 0, 20)
    Frame.BackgroundTransparency = 1
    local Lbl = Instance.new("TextLabel", Frame)
    Lbl.Size = UDim2.new(1, 0, 1, 0)
    Lbl.BackgroundTransparency = 1
    Lbl.Font = Enum.Font.GothamSemibold
    Lbl.Text = "--- PILIHAN TARGET " .. text .. " ---"
    Lbl.TextColor3 = Color3.fromRGB(120, 120, 130)
    Lbl.TextSize = 9
end

CreateDivider(pageFarm, "MATERIAL")
CreateDivider(pageStock, "KIOS ITEMS")
CreateDivider(pagePig, "PAKAN PIG")

-- 5. PENGISIAN DAFTAR OPSI ELEMENT GAYA LIST KUNING PREMIUM PERIS DI GAMBAR
local function AddSelectionRow(parentPage, displayName, valueName, targetTable)
    local Row = Instance.new("Frame", parentPage)
    Row.Size = UDim2.new(1, 0, 0, 30)
    Row.BackgroundColor3 = Color3.fromRGB(25, 25, 28)
    Instance.new("UICorner", Row).CornerRadius = UDim.new(0, 4)
    
    local label = Instance.new("TextLabel", Row)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.Size = UDim2.new(0.7, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.Gotham
    label.Text = "▶  " .. displayName
    label.TextColor3 = Color3.fromRGB(200, 200, 200)
    label.TextSize = 11
    label.TextXAlignment = Enum.TextXAlignment.Left
    
    local btn = Instance.new("TextButton", Row)
    btn.Position = UDim2.new(1, -70, 0, 4)
    btn.Size = UDim2.new(0, 60, 0, 22)
    btn.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
    btn.Font = Enum.Font.GothamBold
    btn.Text = "PILIH"
    btn.TextColor3 = Color3.fromRGB(160, 160, 160)
    btn.TextSize = 9
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
    
    local btnStroke = Instance.new("UIStroke", btn)
    btnStroke.Color = Color3.fromRGB(50, 50, 55)
    btnStroke.Thickness = 1
    
    btn.Activated:Connect(function()
        local idx = table.find(targetTable, valueName)
        if idx then
            table.remove(targetTable, idx)
            btn.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
            btn.TextColor3 = Color3.fromRGB(160, 160, 160)
            btnStroke.Color = Color3.fromRGB(50, 50, 55)
            btn.Text = "PILIH"
        else
            table.insert(targetTable, valueName)
            btn.BackgroundColor3 = Color3.fromRGB(255, 200, 0) -- Kuning Node Hub Emas
            btn.TextColor3 = Color3.fromRGB(20, 20, 20)
            btnStroke.Color = Color3.fromRGB(255, 215, 0)
            btn.Text = "AKTIF"
        end
    end)
end

for name, val in pairs(TARGET_MAPPING) do AddSelectionRow(pageFarm, name, val, SelectedTargets) end
for name, val in pairs(RESTOCK_MAPPING) do AddSelectionRow(pageStock, name, val, SelectedRestock) end
for name, val in pairs(FEED_MAPPING) do AddSelectionRow(pagePig, name, val, SelectedFeed) end

-- 6. FITUR GESER WINDOW MANUAL (DRAGGABLE BYPASS MOBILE)
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

-- 7. SISTEM DRIVER FUNGSIONAL OTOMASI UTAMA GAME (ANTI-STUCK)
local function equipItem(itemName)
    local bp = LocalPlayer:FindFirstChild("Backpack") local char = LocalPlayer.Character
    if bp and char then
        local tool = bp:FindFirstChild(itemName)
        if tool and char:FindFirstChildOfClass("Humanoid") then char.Humanoid:EquipTool(tool); return true end
    end
    return char and char:FindFirstChild(itemName) ~= nil
end

local function firePrompt(prompt)
    if not prompt or not prompt.Enabled then return end
    if fireproximityprompt then fireproximityprompt(prompt) else prompt:InputHoldBegin() task.wait(prompt.HoldDuration + 0.05) prompt:InputHoldEnd() end
end

local function blinkTravelTo(root, humanoid, targetCFrame)
    if root and humanoid then
        humanoid:ChangeState(Enum.HumanoidStateType.Physics); root.Velocity = Vector3.new(0, 0, 0)
        local tw = TweenService:Create(root, TweenInfo.new((root.Position - targetCFrame.Position).Magnitude / BLINK_SPEED, Enum.EasingStyle.Linear), {CFrame = targetCFrame})
        tw:Play() tw.Completed:Wait(); root.Velocity = Vector3.new(0, 0, 0); humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
    end
end

task.spawn(function()
    while true do
        task.wait(0.3)
        local char = LocalPlayer.Character local root = char and char:FindFirstChild("HumanoidRootPart") local hum = char and char:FindFirstChildOfClass("Humanoid")
        
        if _G.AlitHubFarmActive and #SelectedTargets > 0 and root and hum then
            local folder = workspace:FindFirstChild("SpawnBahan")
            if folder then
                for _, obj in pairs(folder:GetChildren()) do
                    if not _G.AlitHubFarmActive then break end
                    if table.find(SelectedTargets, obj.Name) then
                        local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
                        if prompt and prompt.Enabled and prompt.Parent then
                            local part = prompt.Parent:IsA("BasePart") and prompt.Parent or obj:FindFirstChildWhichIsA("BasePart", true)
                            if part then blinkTravelTo(root, hum, part.CFrame); task.wait(TELEPORT_DELAY) if _G.AlitHubFarmActive and prompt.Enabled then firePrompt(prompt) task.wait(POST_PANEN_DELAY) end end
                        end
                    end
                end
            end
        end
        if _G.AlitHubRestockActive and #SelectedRestock > 0 and root and hum then
            local kios = workspace:FindFirstChild("Kios_" .. LocalPlayer.Name)
            if kios then
                for i = 1, 12 do
                    if not _G.AlitHubRestockActive then break end
                    local slot = kios:FindFirstChild("slot" .. i) or kios:FindFirstChild("slot " .. i)
                    if slot then
                        local prompt = slot:FindFirstChildWhichIsA("ProximityPrompt", true)
                        if prompt and prompt.Enabled then
                            for _, toolName in ipairs(SelectedRestock) do
                                if equipItem(toolName) then
                                    local part = slot:IsA("BasePart") and slot or slot:FindFirstChildWhichIsA("BasePart", true)
                                    if part then blinkTravelTo(root, hum, part.CFrame); task.wait(TELEPORT_DELAY) if prompt.Enabled and _G.AlitHubRestockActive then firePrompt(prompt) task.wait(POST_PANEN_DELAY) end end
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
                                        for k = 1, 10 do if not pakanPrompt.Enabled or not _G.AlitHubPigActive or string.find(pakanPrompt.ObjectText, "10/10") or not equipItem(foodName) then break end firePrompt(pakanPrompt) task.wait(0.3) end
                                    end
                                    break
                                end
                            end
                        end
                    end
                end
                for _, babi in pairs(kandang:GetChildren()) do
                    if not _G.AlitHubPigActive then break end
                    if string.find(string.lower(babi.Name), "babi") or babi:FindFirstChild("Fase") then
                        local statusFase = babi:FindFirstChild("Fase") or babi:FindFirstChild("Status")
                        if statusFase and (string.find(string.lower(tostring(statusFase.Value)), "dewasa") or string.find(string.lower(babi.Name), "dewasa")) then
                            local panenPrompt = babi:FindFirstChildWhichIsA("ProximityPrompt", true)
                            if panenPrompt and panenPrompt.Enabled then
                                local babiPart = babi:IsA("BasePart") and babi or babi:FindFirstChildWhichIsA("BasePart", true)
                                if babiPart then blinkTravelTo(root, hum, babiPart.CFrame); task.wait(TELEPORT_DELAY) if panenPrompt.Enabled and _G.AlitHubPigActive then firePrompt(panenPrompt) task.wait(POST_PANEN_DELAY) end end
                            end
                        end
                    end
                end
            end
        end
    end
end)
