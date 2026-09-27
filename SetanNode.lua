-- [[ ALIT HUB - CONFIGURATION PASAR HUTAN ]]
local TARGET_MAPPING = {
    ["Dupa"] = "Spawn_Dupa",
    ["Gagak"] = "Spawn_Gagak",
    ["Jamur Kuburan"] = "Spawn_JamurKuburan",
    ["Kemenyan"] = "Spawn_Kemenyan",
    ["Kepiting Sungai"] = "Spawn_KepitingSungai",
    ["Melati"] = "Spawn_Melati"
}

local SelectedTargets = {}
local TELEPORT_DELAY = 0.35 
local POST_PANEN_DELAY = 0.3 

-- Posisi default saat UI terbuka penuh di tengah layar
local SAVED_POSITION = UDim2.new(0.5, -110, 0.3, -100) 

-- [[ SERVICES ROBLOX ]]
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local TweenService = game:GetService("TweenService")

local PlayerGui = LocalPlayer:WaitForChild("PlayerGui", 10)

if PlayerGui:FindFirstChild("AlitHubUI") then
    PlayerGui.AlitHubUI:Destroy()
end

_G.AlitHubFarmActive = false
task.wait(0.1)

-- [[ MEMBUAT INTERFACES UI ALIT HUB ]]
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AlitHubUI"
ScreenGui.Parent = PlayerGui
ScreenGui.ResetOnSpawn = false

-- Panel Utama
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
MainFrame.Position = SAVED_POSITION
MainFrame.Size = UDim2.new(0, 220, 0, 260) 
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true 
MainFrame.Draggable = true
MainFrame.Selectable = true
MainFrame.Active = true

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 12)
MainCorner.Parent = MainFrame

-- Top Bar Frame (Menampung Judul dan Tombol Minimize Mini)
local TopBar = Instance.new("Frame")
TopBar.Name = "TopBar"
TopBar.Parent = MainFrame
TopBar.BackgroundTransparency = 1
TopBar.Size = UDim2.new(1, 0, 0, 45)

-- Judul Utama (Klik tulisan ini saat minimize untuk membuka kembali)
local TitleButton = Instance.new("TextButton")
TitleButton.Name = "TitleButton"
TitleButton.Parent = TopBar
TitleButton.BackgroundTransparency = 1
TitleButton.Position = UDim2.new(0, 15, 0, 0)
TitleButton.Size = UDim2.new(0, 140, 0, 45) 
TitleButton.Font = Enum.Font.GothamBold
TitleButton.Text = "ALIT HUB"
TitleButton.TextColor3 = Color3.fromRGB(255, 215, 0)
TitleButton.TextSize = 14
TitleButton.TextXAlignment = Enum.TextXAlignment.Left

-- Tombol Simbol Minus (-) di Pojok Kanan Atas Panel Utama
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

-- Container Konten Fitur 
local ContentFrame = Instance.new("Frame")
ContentFrame.Name = "ContentFrame"
ContentFrame.Parent = MainFrame
ContentFrame.BackgroundTransparency = 1
ContentFrame.Position = UDim2.new(0, 0, 0, 45)
ContentFrame.Size = UDim2.new(1, 0, 1, -45)

-- Tombol Utama Auto Farm (ON/OFF)
local ToggleButton = Instance.new("TextButton")
ToggleButton.Name = "ToggleButton"
ToggleButton.Parent = ContentFrame
ToggleButton.BackgroundColor3 = Color3.fromRGB(220, 53, 69)
ToggleButton.Position = UDim2.new(0.08, 0, 0.05, 0)
ToggleButton.Size = UDim2.new(0.84, 0, 0, 35)
ToggleButton.Font = Enum.Font.GothamBold
ToggleButton.Text = "AUTO FARM: OFF"
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.TextSize = 12

local ToggleCorner = Instance.new("UICorner")
ToggleCorner.CornerRadius = UDim.new(0, 6)
ToggleCorner.Parent = ToggleButton

-- Kolom Tombol Dropdown Target
local DropdownButton = Instance.new("TextButton")
DropdownButton.Name = "DropdownButton"
DropdownButton.Parent = ContentFrame
DropdownButton.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
DropdownButton.Position = UDim2.new(0.08, 0, 0.28, 0)
DropdownButton.Size = UDim2.new(0.84, 0, 0, 35)
DropdownButton.Font = Enum.Font.GothamSemibold
DropdownButton.Text = "PILIH TARGET ▼"
DropdownButton.TextColor3 = Color3.fromRGB(240, 240, 240)
DropdownButton.TextSize = 12

local DropdownCorner = Instance.new("UICorner")
DropdownCorner.CornerRadius = UDim.new(0, 6)
DropdownCorner.Parent = DropdownButton

-- Container untuk Daftar List Target (Scrolling)
local ListContainer = Instance.new("ScrollingFrame")
ListContainer.Name = "ListContainer"
ListContainer.Parent = ContentFrame
ListContainer.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
ListContainer.Position = UDim2.new(0.08, 0, 0.48, 0)
ListContainer.Size = UDim2.new(0.84, 0, 0, 100)
ListContainer.BorderSizePixel = 0
ListContainer.ScrollBarThickness = 4
ListContainer.Visible = false

local ListCorner = Instance.new("UICorner")
ListCorner.CornerRadius = UDim.new(0, 6)
ListCorner.Parent = ListContainer

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Parent = ListContainer
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 4)

-- [[ LOGIKA BUKA / TUTUP MINIMIZE & PERPINDAHAN KE KIRI LAYAR ]]
MiniButton.Activated:Connect(function()
    -- Simpan posisi terakhir panel sebelum di-minimize jika pernah digeser user
    SAVED_POSITION = MainFrame.Position 
    
    ContentFrame.Visible = false
    MiniButton.Visible = false
    
    -- Teleportasikan bilah menu ke samping kiri layar secara instan
    MainFrame.Position = UDim2.new(0, 10, 0.4, 0)
    MainFrame.Size = UDim2.new(0, 100, 0, 45) -- Mengecil menjadi box tulisan ramping
end)

TitleButton.Activated:Connect(function()
    if not ContentFrame.Visible then
        -- Kembalikan ke posisi tengah (atau posisi sebelum di-minimize)
        MainFrame.Position = SAVED_POSITION
        MainFrame.Size = UDim2.new(0, 220, 0, 260) 
        
        ContentFrame.Visible = true
        MiniButton.Visible = true
    end
end)

-- [[ DAFTAR ITEM TARGET ]]
for displayName, workspaceName in pairs(TARGET_MAPPING) do
    local ItemButton = Instance.new("TextButton")
    ItemButton.Name = displayName
    ItemButton.Parent = ListContainer
    ItemButton.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
    ItemButton.Size = UDim2.new(1, 0, 0, 28)
    ItemButton.Font = Enum.Font.Gotham
    ItemButton.Text = displayName
    ItemButton.TextColor3 = Color3.fromRGB(200, 200, 200)
    ItemButton.TextSize = 11

    local ItemCorner = Instance.new("UICorner")
    ItemCorner.CornerRadius = UDim.new(0, 4)
    ItemCorner.Parent = ItemButton

    ItemButton.Activated:Connect(function()
        if table.find(SelectedTargets, workspaceName) then
            for i, name in ipairs(SelectedTargets) do
                if name == workspaceName then table.remove(SelectedTargets, i) break end
            end
            TweenService:Create(ItemButton, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(35, 35, 40), TextColor3 = Color3.fromRGB(200, 200, 200)}):Play()
        else
            table.insert(SelectedTargets, workspaceName)
            TweenService:Create(ItemButton, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(40, 167, 69), TextColor3 = Color3.fromRGB(255, 255, 255)}):Play()
        end
    end)
end

ListContainer.CanvasSize = UDim2.new(0, 0, 0, UIListLayout.AbsoluteContentSize.Y + 10)

DropdownButton.Activated:Connect(function()
    ListContainer.Visible = not ListContainer.Visible
    DropdownButton.Text = ListContainer.Visible and "PILIH TARGET ▲" or "PILIH TARGET ▼"
end)

-- [[ LOGIKA TELEPORTASI ]]
local function teleportTo(targetCFrame)
    local character = LocalPlayer.Character
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
    if rootPart then
        rootPart.CFrame = targetCFrame
    end
end

-- [[ LOGIKA UTAMA AUTO FARM PASAR HUTAN ]]
task.spawn(function()
    while true do
        task.wait(0.05)
        if _G.AlitHubFarmActive and #SelectedTargets > 0 then
            local targetPart = nil
            local prompt = nil

            local spawnBahanFolder = game.Workspace:FindFirstChild("SpawnBahan")
            if spawnBahanFolder then
                for _, obj in pairs(spawnBahanFolder:GetChildren()) do
                    if table.find(SelectedTargets, obj.Name) then
                        local foundPrompt = obj:FindFirstChild("AmbilPrompt", true)
                        
                        if foundPrompt and foundPrompt.Enabled and foundPrompt.Parent then
                            targetPart = foundPrompt.Parent:IsA("BasePart") and foundPrompt.Parent or obj:FindFirstChildWhichIsA("BasePart", true)
                            prompt = foundPrompt
                            break 
                        end
                    end
                end
            end

            if targetPart and prompt and _G.AlitHubFarmActive then
                teleportTo(targetPart.CFrame)
                task.wait(TELEPORT_DELAY) 
                
                if _G.AlitHubFarmActive and prompt.Enabled then
                    if fireproximityprompt then
                        fireproximityprompt(prompt)
                    end
                    
                    prompt:InputHoldBegin()
                    task.wait(prompt.HoldDuration + 0.05) 
                    prompt:InputHoldEnd()
                    
                    task.wait(POST_PANEN_DELAY)
                end
            end
        end
    end
end)

-- TOGGLE BUTTON
ToggleButton.Activated:Connect(function()
    _G.AlitHubFarmActive = not _G.AlitHubFarmActive
    if _G.AlitHubFarmActive then
        TweenService:Create(ToggleButton, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(40, 167, 69)}):Play()
        ToggleButton.Text = "AUTO FARM: ON"
    else
        TweenService:Create(ToggleButton, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(220, 53, 69)}):Play()
        ToggleButton.Text = "AUTO FARM: OFF"
    end
end)
