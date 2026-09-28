-- [[ SKRIP REMAKE - AUTO COOK SIMULATOR UI REMAKE PART 1 ]]
if not game:IsLoaded() then game.Loaded:Wait() end
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local TweenService = game:GetService("TweenService")
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui", 10)

if PlayerGui:FindFirstChild("AutoCookRemakeUI") then 
    PlayerGui.AutoCookRemakeUI:Destroy() 
end

_G.AutoCookActive = false
_G.SelectedCookMenu = "Sate Gagak"
task.wait(0.1)

-- FIXED: Daftar Pilihan Menu Masakan Baru Sesuai Teks Asli Layar Roblox Anda
local COOK_RECIPES = {
    ["Sate Gagak"] = "Sate Gagak",
    ["Jamur Rebus Kuburan"] = "Jamur Rebus Kuburan",
    ["Tumis Kamboja"] = "Tumis Kamboja",
    ["Sate Kepiting"] = "Sate Kepiting",
    ["Pisang Raja Rebus"] = "Pisang Raja Rebus",
    ["Kopi Kemenyan"] = "Kopi Kemenyan"
}

local INITIAL_TELEPORT_DELAY = 0.2
local SECURE_HOLD_DURATION = 0.5
local REPEAT_LOOP_DELAY = 1.5
local GLOBAL_SAVED_POS = UDim2.new(0.5, -110, 0.3, -100)

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AutoCookRemakeUI"; ScreenGui.Parent = PlayerGui; ScreenGui.ResetOnSpawn = false
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"; MainFrame.Parent = ScreenGui; MainFrame.BackgroundColor3 = Color3.fromRGB(35, 30, 30)
MainFrame.Position = GLOBAL_SAVED_POS; MainFrame.Size = UDim2.new(0, 220, 0, 180); MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true; MainFrame.Active = true
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 12)

local TopBar = Instance.new("Frame"); TopBar.Name = "TopBar"; TopBar.Parent = MainFrame; TopBar.BackgroundTransparency = 1; TopBar.Size = UDim2.new(1, 0, 0, 45)
local TitleButton = Instance.new("TextButton")
TitleButton.Name = "TitleButton"; TitleButton.Parent = TopBar; TitleButton.BackgroundTransparency = 1; TitleButton.Position = UDim2.new(0, 15, 0, 0); TitleButton.Size = UDim2.new(0, 140, 0, 45)
TitleButton.Font = Enum.Font.GothamBold; TitleButton.Text = "COOK SIMULATOR V2"; TitleButton.TextColor3 = Color3.fromRGB(255, 215, 0); TitleButton.TextSize = 11; TitleButton.TextXAlignment = Enum.TextXAlignment.Left

local MiniButton = Instance.new("TextButton")
MiniButton.Name = "MiniButton"; MiniButton.Parent = TopBar; MiniButton.BackgroundTransparency = 1; MiniButton.Position = UDim2.new(1, -35, 0, 0); MiniButton.Size = UDim2.new(0, 30, 0, 45)
MiniButton.Font = Enum.Font.GothamBold; MiniButton.Text = "-"; MiniButton.TextColor3 = Color3.fromRGB(200, 200, 200); MiniButton.TextSize = 20

local ContentFrame = Instance.new("Frame")
ContentFrame.Name = "ContentFrame"; ContentFrame.Parent = MainFrame; ContentFrame.BackgroundTransparency = 1; ContentFrame.Position = UDim2.new(0, 0, 0, 45); ContentFrame.Size = UDim2.new(1, 0, 1, -45)

local CookToggleBtn = Instance.new("TextButton")
CookToggleBtn.Name = "CookToggleBtn"; CookToggleBtn.Parent = ContentFrame; CookToggleBtn.BackgroundColor3 = Color3.fromRGB(220, 53, 69); CookToggleBtn.Position = UDim2.new(0.05, 0, 0.05, 0); CookToggleBtn.Size = UDim2.new(0.9, 0, 0, 35)
CookToggleBtn.Font = Enum.Font.GothamBold; CookToggleBtn.Text = "AUTO COOK: OFF"; CookToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255); CookToggleBtn.TextSize = 11
Instance.new("UICorner", CookToggleBtn).CornerRadius = UDim.new(0, 6)
-- [[ SKRIP REMAKE - AUTO COOK SIMULATOR UI REMAKE PART 2 ]]
local DropdownButton = Instance.new("TextButton")
DropdownButton.Name = "DropdownButton"; DropdownButton.Parent = ContentFrame; DropdownButton.BackgroundColor3 = Color3.fromRGB(50, 45, 45); DropdownButton.Position = UDim2.new(0.05, 0, 0.40, 0); DropdownButton.Size = UDim2.new(0.9, 0, 0, 30)
DropdownButton.Font = Enum.Font.GothamSemibold; DropdownButton.Text = "PILIH MENU: SATE GAGAK ▼"; DropdownButton.TextColor3 = Color3.fromRGB(240, 240, 240); DropdownButton.TextSize = 10
Instance.new("UICorner", DropdownButton).CornerRadius = UDim.new(0, 5)

local ListContainer = Instance.new("ScrollingFrame")
ListContainer.Name = "ListContainer"; ListContainer.Parent = ContentFrame; ListContainer.BackgroundColor3 = Color3.fromRGB(25, 20, 20); ListContainer.Position = UDim2.new(0.05, 0, 0.65, 0); ListContainer.Size = UDim2.new(0.9, 0, 0, 65); ListContainer.BorderSizePixel = 0; ListContainer.ScrollBarThickness = 3; ListContainer.Visible = false
Instance.new("UICorner", ListContainer).CornerRadius = UDim.new(0, 5)
local UIListLayout = Instance.new("UIListLayout"); UIListLayout.Parent = ListContainer; UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder; UIListLayout.Padding = UDim.new(0, 2)

local isMinimized = false
MiniButton.Activated:Connect(function() 
    isMinimized = true; GLOBAL_SAVED_POS = MainFrame.Position; ContentFrame.Visible = false; MiniButton.Visible = false
    MainFrame.Position = UDim2.new(0, 10, 0.4, 0); MainFrame.Size = UDim2.new(0, 110, 0, 45) 
end)
TitleButton.Activated:Connect(function() 
    if isMinimized then 
        isMinimized = false; MainFrame.Position = GLOBAL_SAVED_POS; MainFrame.Size = UDim2.new(0, 220, 0, 180); ContentFrame.Visible = true; MiniButton.Visible = true 
    end 
end)

-- Menghubungkan dropdown visual dengan urutan resep baru Anda
for codeName, dispName in pairs(COOK_RECIPES) do
    local btn = Instance.new("TextButton"); btn.Size = UDim2.new(1, 0, 0, 22); btn.BackgroundColor3 = Color3.fromRGB(40, 35, 35); btn.Text = dispName; btn.TextColor3 = Color3.fromRGB(220, 220, 220); btn.Font = Enum.Font.Gotham; btn.TextSize = 9; btn.Parent = ListContainer; Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
    btn.Activated:Connect(function() 
        _G.SelectedCookMenu = codeName
        DropdownButton.Text = "PILIH MENU: " .. string.upper(dispName) .. " ▼"
        ListContainer.Visible = false
        MainFrame.Size = UDim2.new(0, 220, 0, 180)
    end)
end

ListContainer.CanvasSize = UDim2.new(0, 0, 0, 140) -- Kunci tinggi scroll dropdown agar rapi
DropdownButton.Activated:Connect(function() 
    ListContainer.Visible = not ListContainer.Visible
    MainFrame.Size = ListContainer.Visible and UDim2.new(0, 220, 0, 250) or UDim2.new(0, 220, 0, 180)
end)

CookToggleBtn.Activated:Connect(function() 
    if _G.AutoCookActive == true then 
        _G.AutoCookActive = false
        CookToggleBtn.BackgroundColor3 = Color3.fromRGB(220, 53, 69)
        CookToggleBtn.Text = "AUTO COOK: OFF"
    else 
        _G.AutoCookActive = true
        CookToggleBtn.BackgroundColor3 = Color3.fromRGB(40, 167, 69)
        CookToggleBtn.Text = "AUTO COOK: ON"
    end
end)
-- [[ SKRIP REMAKE - AUTO COOK SIMULATOR UI REMAKE PART 3 ]]
local function instantTeleport(root, targetCFrame)
    if root then
        root.Velocity = Vector3.new(0, 0, 0)
        root.CFrame = targetCFrame
        root.Velocity = Vector3.new(0, 0, 0)
    end
end

local function initializeKitchen()
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return false end
    
    local kiosAktif = workspace:FindFirstChild("KiosAktif")
    local myKios = kiosAktif and (kiosAktif:FindFirstChild("Kios_" .. LocalPlayer.Name) or kiosAktif:FindFirstChild("Kios_panggil_" .. LocalPlayer.Name))
    
    if myKios then
        local pKompor = myKios:FindFirstChild("pKompor") or myKios:FindFirstChildWhichIsA("Attachment", true)
        if pKompor then
            local prompt = pKompor:FindFirstChildOfClass("ProximityPrompt") or myKios:FindFirstChildWhichIsA("ProximityPrompt", true)
            if prompt and prompt.Enabled then
                instantTeleport(root, pKompor.WorldCFrame)
                task.wait(INITIAL_TELEPORT_DELAY)
                prompt:InputHoldBegin()
                task.wait(SECURE_HOLD_DURATION)
                prompt:InputHoldEnd()
                if fireproximityprompt then fireproximityprompt(prompt) end
                return true
            end
        end
    end
    return false
end

-- FIXED: Fungsi Baru Pencarian Berantai untuk Mengetuk Tombol "Masak" yang Berada di Baris Resep yang Tepat
local function clickVirtualCookingButton(gui, targetMenuName)
    if not gui then return false end
    
    -- Mencari semua objek teks (judul resep masakan) yang ada di dalam GUI game
    for _, textObj in pairs(gui:GetDescendants()) do
        if textObj:IsA("TextLabel") and string.find(string.lower(textObj.Text), string.lower(targetMenuName)) then
            -- Begitu baris nama masakan ketemu, skrip mencari tombol hijau "Masak" yang berada dalam satu kotak baris tersebut
            local parentContainer = textObj.Parent
            if parentContainer then
                -- Mencari tombol di dalam kotak kontainer baris resep masakan tersebut
                local actionBtn = parentContainer:FindFirstChild("Masak", true) or parentContainer:FindFirstChildWhichIsA("TextButton", true)
                if actionBtn and actionBtn:IsA("TextButton") and actionBtn.Activated then
                    actionBtn.Activated:Fire() -- Mengetuk tombol virtual "Masak" milik resep pilihan Anda secara akurat
                    return true
                end
            end
        end
    end
    return false
end

-- SYSTEM DRAGGABLE MANUAL UI MURNI LUAU
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

-- BACKEND ENGINE UTUH RE-ALUR MANDIRI ANDA
task.spawn(function()
    while true do
        task.wait(1)
        if _G.AutoCookActive then
            local initSuccess = initializeKitchen()
            if initSuccess then
                while _G.AutoCookActive do
                    task.wait(REPEAT_LOOP_DELAY)
                    local cookingGui = PlayerGui:FindFirstChild("MemasakGui") or PlayerGui:FindFirstChildWhichIsA("ScreenGui", true)
                    if cookingGui and cookingGui.Enabled and _G.AutoCookActive then
                        local fillCount = 0
                        -- Mengisi maksimal 3 antrean berturut-turut pada baris resep masakan Anda
                        for i = 1, 3 do
                            if clickVirtualCookingButton(cookingGui, _G.SelectedCookMenu) then
                                fillCount = fillCount + 1
                                task.wait(0.1) -- Jeda mikro antar pengisian slot
                            end
                        end
                        if fillCount > 0 then
                            -- Skrip mendeteksi tombol penyelesaian otomatis game (otomatis terkunci 10 detik masa tunggu pamatangan)
                            task.wait(10) 
                        end
                    end
                end
            end
        end
    end
end)
