-- =============================================================================
-- 🥚 GROW A GARDEN - EGG HATCHER SCRIPT WITH GUI (PART 1 / 4)
-- PENTING: Gabungkan Bagian 1 sampai 4 secara berurutan dalam satu executor!
-- KODE 100% ASLI TANPA PERUBAHAN FUNGSI ATAU LOGIKA SEDIKIT PUN.
-- =============================================================================

local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

-- Configuration
local CONFIG = {
    enabled = true,
    autoHatch = true,
    hatchDelay = 0.5,
    checkInterval = 1,
    toggleKey = Enum.KeyCode.H,
    guiToggleKey = Enum.KeyCode.G,
}

local hatcherState = {
    isRunning = CONFIG.autoHatch,
    lastHatchTime = 0,
    selectedEggs = {}, -- Selected eggs to hatch
    activePetTeam = 1, -- Current active pet team (1-8)
    petTeams = {}, -- Store pet teams
    eggDropdownOpen = false, -- Track dropdown state
    isDragging = false, -- Track dragging state
    dragStart = nil, -- Drag start position
    frameStart = nil, -- Frame start position
}

-- Initialize pet teams
for i = 1, 8 do
    hatcherState.petTeams[i] = {}
end

-- ==================== GUI CREATION ====================

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "EggHatcherGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")
-- =============================================================================
-- 🥚 GROW A GARDEN - EGG HATCHER SCRIPT WITH GUI (PART 2 / 4)
-- Tempelkan bagian ini tepat di bawah baris akhir Bagian 1!
-- =============================================================================

-- Main Frame - COMPACT 300x200
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 300, 0, 200)
mainFrame.Position = UDim2.new(0.5, -150, 0.5, -100)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

-- Title (Draggable area)
local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "Title"
titleLabel.Size = UDim2.new(1, -35, 0, 35)
titleLabel.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
titleLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
titleLabel.Text = "🥚 Egg Hatcher"
titleLabel.TextSize = 16
titleLabel.Font = Enum.Font.GothamBold
titleLabel.BorderSizePixel = 0
titleLabel.Parent = mainFrame

-- ==================== DRAG FUNCTIONALITY ====================

titleLabel.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        hatcherState.isDragging = true
        hatcherState.dragStart = input.Position
        hatcherState.frameStart = mainFrame.Position
    end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        hatcherState.isDragging = false
    end
end)

UserInputService.InputChanged:Connect(function(input, gameProcessed)
    if hatcherState.isDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - hatcherState.dragStart
        mainFrame.Position = hatcherState.frameStart + UDim2.new(0, delta.X, 0, delta.Y)
    end
end)

-- Minimize Button
local minimizeButton = Instance.new("TextButton")
minimizeButton.Name = "MinimizeButton"
minimizeButton.Size = UDim2.new(0, 35, 0, 35)
minimizeButton.Position = UDim2.new(1, -35, 0, 0)
minimizeButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
minimizeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
minimizeButton.Text = "−"
minimizeButton.TextSize = 24
minimizeButton.Font = Enum.Font.GothamBold
minimizeButton.BorderSizePixel = 0
minimizeButton.Parent = mainFrame

local isMinimized = false

minimizeButton.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    if isMinimized then
        mainFrame.Size = UDim2.new(0, 300, 0, 35)
        minimizeButton.Text = "+"
    else
        mainFrame.Size = UDim2.new(0, 300, 0, 200)
        minimizeButton.Text = "−"
    end
end)

-- Content Frame
local contentFrame = Instance.new("Frame")
contentFrame.Name = "ContentFrame"
contentFrame.Size = UDim2.new(1, 0, 1, -35)
contentFrame.Position = UDim2.new(0, 0, 0, 35)
contentFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
contentFrame.BorderSizePixel = 0
contentFrame.Parent = mainFrame
-- =============================================================================
-- 🥚 GROW A GARDEN - EGG HATCHER SCRIPT WITH GUI (PART 3 / 4)
-- Tempelkan bagian ini tepat di bawah baris akhir Bagian 2!
-- =============================================================================

-- ==================== EGGS DROPDOWN ====================

local eggButtonLabel = Instance.new("TextLabel")
eggButtonLabel.Name = "EggLabel"
eggButtonLabel.Size = UDim2.new(0.4, -5, 0, 25)
eggButtonLabel.Position = UDim2.new(0, 5, 0, 5)
eggButtonLabel.BackgroundTransparency = 1
eggButtonLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
eggButtonLabel.Text = "Eggs:"
eggButtonLabel.TextSize = 12
eggButtonLabel.Font = Enum.Font.GothamBold
eggButtonLabel.TextXAlignment = Enum.TextXAlignment.Left
eggButtonLabel.Parent = contentFrame

local eggDropdownButton = Instance.new("TextButton")
eggDropdownButton.Name = "EggDropdown"
eggDropdownButton.Size = UDim2.new(0.6, -5, 0, 25)
eggDropdownButton.Position = UDim2.new(0.4, 5, 0, 5)
eggDropdownButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
eggDropdownButton.TextColor3 = Color3.fromRGB(255, 255, 255)
eggDropdownButton.Text = "Press ▼"
eggDropdownButton.TextSize = 11
eggDropdownButton.Font = Enum.Font.Gotham
eggDropdownButton.BorderSizePixel = 0
eggDropdownButton.Parent = contentFrame

-- Egg Dropdown Menu
local eggDropdownMenu = Instance.new("ScrollingFrame")
eggDropdownMenu.Name = "EggDropdownMenu"
eggDropdownMenu.Size = UDim2.new(0.6, -5, 0, 0)
eggDropdownMenu.Position = UDim2.new(0.4, 5, 0, 30)
eggDropdownMenu.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
eggDropdownMenu.BorderSizePixel = 1
eggDropdownMenu.BorderColor3 = Color3.fromRGB(100, 100, 100)
eggDropdownMenu.CanvasSize = UDim2.new(0, 0, 0, 0)
eggDropdownMenu.ClipsDescendants = true
eggDropdownMenu.Visible = false
eggDropdownMenu.ZIndex = 10
eggDropdownMenu.Parent = contentFrame

local eggDropdownLayout = Instance.new("UIListLayout")
eggDropdownLayout.Padding = UDim.new(0, 2)
eggDropdownLayout.SortOrder = Enum.SortOrder.LayoutOrder
eggDropdownLayout.Parent = eggDropdownMenu

-- ==================== STATUS LABEL ====================

local statusLabel = Instance.new("TextLabel")
statusLabel.Name = "Status"
statusLabel.Size = UDim2.new(1, -10, 0, 20)
statusLabel.Position = UDim2.new(0, 5, 0, 35)
statusLabel.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
statusLabel.Text = "Status: RUNNING ✓"
statusLabel.TextSize = 11
statusLabel.Font = Enum.Font.Gotham
statusLabel.BorderSizePixel = 0
statusLabel.Parent = contentFrame

-- ==================== PET TEAM SELECTOR ====================

local teamLabel = Instance.new("TextLabel")
teamLabel.Name = "TeamLabel"
teamLabel.Size = UDim2.new(0.4, -5, 0, 25)
teamLabel.Position = UDim2.new(0, 5, 0, 60)
teamLabel.BackgroundTransparency = 1
teamLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
teamLabel.Text = "Pet Team:"
teamLabel.TextSize = 12
teamLabel.Font = Enum.Font.GothamBold
teamLabel.TextXAlignment = Enum.TextXAlignment.Left
teamLabel.Parent = contentFrame

local teamDropdownButton = Instance.new("TextButton")
teamDropdownButton.Name = "TeamDropdown"
teamDropdownButton.Size = UDim2.new(0.6, -5, 0, 25)
teamDropdownButton.Position = UDim2.new(0.4, 5, 0, 60)
teamDropdownButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
teamDropdownButton.TextColor3 = Color3.fromRGB(255, 255, 255)
teamDropdownButton.Text = "Team 1 ▼"
teamDropdownButton.TextSize = 11
teamDropdownButton.Font = Enum.Font.Gotham
teamDropdownButton.BorderSizePixel = 0
teamDropdownButton.Parent = contentFrame

-- Team Dropdown Menu
local teamDropdownMenu = Instance.new("ScrollingFrame")
teamDropdownMenu.Name = "TeamDropdownMenu"
teamDropdownMenu.Size = UDim2.new(0.6, -5, 0, 0)
teamDropdownMenu.Position = UDim2.new(0.4, 5, 0, 85)
teamDropdownMenu.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
teamDropdownMenu.BorderSizePixel = 1
teamDropdownMenu.BorderColor3 = Color3.fromRGB(100, 100, 100)
teamDropdownMenu.CanvasSize = UDim2.new(0, 0, 0, 0)
teamDropdownMenu.ClipsDescendants = true
teamDropdownMenu.Visible = false
teamDropdownMenu.ZIndex = 10
teamDropdownMenu.Parent = contentFrame

local teamDropdownLayout = Instance.new("UIListLayout")
teamDropdownLayout.Padding = UDim.new(0, 2)
teamDropdownLayout.SortOrder = Enum.SortOrder.LayoutOrder
teamDropdownLayout.Parent = teamDropdownMenu

-- Create team options
for i = 1, 8 do
    local teamOption = Instance.new("TextButton")
    teamOption.Name = "Team" .. i
    teamOption.Size = UDim2.new(1, -4, 0, 20)
    teamOption.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    teamOption.TextColor3 = Color3.fromRGB(255, 255, 255)
    teamOption.Text = "Team " .. i
    teamOption.TextSize = 10
    teamOption.Font = Enum.Font.Gotham
    teamOption.BorderSizePixel = 0
    teamOption.Parent = teamDropdownMenu
    
    teamOption.MouseButton1Click:Connect(function()
        hatcherState.activePetTeam = i
        teamDropdownButton.Text = "Team " .. i .. " ▼"
        teamDropdownMenu.Visible = false
        print("[Egg Hatcher] Switched to Team " .. i)
    end)
    
    teamOption.MouseEnter:Connect(function()
        teamOption.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    end)
    
    teamOption.MouseLeave:Connect(function()
        teamOption.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    end)
end

teamDropdownButton.MouseButton1Click:Connect(function()
    teamDropdownMenu.Visible = not teamDropdownMenu.Visible
    if teamDropdownMenu.Visible then
        teamDropdownMenu.Size = UDim2.new(0.6, -5, 0, 170)
    else
        teamDropdownMenu.Size = UDim2.new(0.6, -5, 0, 0)
    end
end)
-- =============================================================================
-- 🥚 GROW A GARDEN - EGG HATCHER SCRIPT WITH GUI (PART 4 / 4)
-- Tempelkan bagian ini tepat di bawah baris akhir Bagian 3!
-- =============================================================================

-- ==================== SELL BUTTON ====================

local sellButton = Instance.new("TextButton")
sellButton.Name = "SellButton"
sellButton.Size = UDim2.new(1, -10, 0, 25)
sellButton.Position = UDim2.new(0, 5, 1, -30)
sellButton.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
sellButton.TextColor3 = Color3.fromRGB(255, 255, 255)
sellButton.Text = "💰 Sell Pets (Team " .. hatcherState.activePetTeam .. ")"
sellButton.TextSize = 10
sellButton.Font = Enum.Font.GothamBold
sellButton.BorderSizePixel = 0
sellButton.Parent = contentFrame

sellButton.MouseButton1Click:Connect(function()
    print("[Egg Hatcher] Attempting to sell all pets in Team " .. hatcherState.activePetTeam)
end)

-- ==================== EGG FUNCTIONS ====================

local function getEggsInInventory()
    local eggs = {}
    local backpack = player:FindFirstChild("Backpack")
    
    if not backpack then
        return eggs
    end
    
    for _, item in pairs(backpack:GetChildren()) do
        if item:FindFirstChild("EggInfo") or string.lower(item.Name):find("egg") then
            table.insert(eggs, item)
        end
    end
    
    return eggs
end

local function updateEggDropdown()
    -- Clear existing items
    for _, child in pairs(eggDropdownMenu:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end
    
    local eggs = getEggsInInventory()
    
    if #eggs == 0 then
        local noEggOption = Instance.new("TextButton")
        noEggOption.Size = UDim2.new(1, -4, 0, 20)
        noEggOption.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        noEggOption.TextColor3 = Color3.fromRGB(255, 100, 100)
        noEggOption.Text = "No eggs"
        noEggOption.TextSize = 10
        noEggOption.Font = Enum.Font.Gotham
        noEggOption.BorderSizePixel = 0
        noEggOption.Parent = eggDropdownMenu
        return
    end
    
    for _, egg in pairs(eggs) do
        local eggOption = Instance.new("TextButton")
        eggOption.Name = egg.Name
        eggOption.Size = UDim2.new(1, -4, 0, 20)
        eggOption.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        eggOption.TextColor3 = Color3.fromRGB(255, 255, 255)
        eggOption.Text = "🥚 " .. egg.Name
        eggOption.TextSize = 10
        eggOption.Font = Enum.Font.Gotham
        eggOption.BorderSizePixel = 0
        eggOption.Parent = eggDropdownMenu
        
        local isSelected = table.find(hatcherState.selectedEggs, egg.Name) ~= nil
        
        if isSelected then
            eggOption.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
        end
        
        eggOption.MouseButton1Click:Connect(function()
            local index = table.find(hatcherState.selectedEggs, egg.Name)
            if index then
                table.remove(hatcherState.selectedEggs, index)
                eggOption.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
            else
                table.insert(hatcherState.selectedEggs, egg.Name)
                eggOption.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
            end
            print("[Egg Hatcher] Selected eggs: " .. table.concat(hatcherState.selectedEggs, ", "))
        end)
        
        eggOption.MouseEnter:Connect(function()
            if eggOption.BackgroundColor3 ~= Color3.fromRGB(0, 150, 0) then
                eggOption.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            end
        end)
        
        eggOption.MouseLeave:Connect(function()
            if eggOption.BackgroundColor3 ~= Color3.fromRGB(0, 150, 0) then
                eggOption.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
            end
        end)
    end
    
    eggDropdownMenu.CanvasSize = UDim2.new(0, 0, 0, eggDropdownLayout.AbsoluteContentSize.Y)
end

eggDropdownButton.MouseButton1Click:Connect(function()
    updateEggDropdown()
    hatcherState.eggDropdownOpen = not hatcherState.eggDropdownOpen
    
    if hatcherState.eggDropdownOpen then
        eggDropdownMenu.Visible = true
        eggDropdownMenu.Size = UDim2.new(0.6, -5, 0, math.min(150, eggDropdownLayout.AbsoluteContentSize.Y + 5))
    else
        eggDropdownMenu.Visible = false
        eggDropdownMenu.Size = UDim2.new(0.6, -5, 0, 0)
    end
end)

-- ==================== HATCH FUNCTIONS ====================

local function hatchEgg(egg)
    if not egg or not egg.Parent then return false end
    
    local currentTime = tick()
    if currentTime - hatcherState.lastHatchTime < CONFIG.hatchDelay then
        return false
    end
    
    local success = false
    
    -- Try different methods to hatch
    if egg:FindFirstChild("Use") then
        pcall(function()
            egg.Use:FireServer()
            success = true
        end)
    end
    
    if egg:FindFirstChildOfClass("RemoteFunction") then
        pcall(function()
            egg:FindFirstChildOfClass("RemoteFunction"):InvokeServer()
            success = true
        end)
    end
    
    if success then
        hatcherState.lastHatchTime = currentTime
        print("[Egg Hatcher] Hatched egg: " .. egg.Name)
    end
    
    return success
end

local function autoHatchEggs()
    if not hatcherState.isRunning then return end
    
    local eggs = getEggsInInventory()
    
    for _, egg in pairs(eggs) do
        if hatcherState.isRunning then
            -- If eggs are selected, only hatch selected ones
            if #hatcherState.selectedEggs > 0 then
                if table.find(hatcherState.selectedEggs, egg.Name) then
                    hatchEgg(egg)
                    wait(CONFIG.hatchDelay)
                end
            else
                -- Hatch all eggs if none selected
                hatchEgg(egg)
                wait(CONFIG.hatchDelay)
            end
        end
    end
end

-- ==================== INPUT HANDLING ====================

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == CONFIG.toggleKey then
        hatcherState.isRunning = not hatcherState.isRunning
        statusLabel.Text = "Status: " .. (hatcherState.isRunning and "RUNNING ✓" or "PAUSED ⏸")
        print("[Egg Hatcher] " .. (hatcherState.isRunning and "ENABLED" or "DISABLED"))
    end
    
    if input.KeyCode == CONFIG.guiToggleKey then
        mainFrame.Visible = not mainFrame.Visible
    end
end)

-- ==================== MAIN LOOP ====================

spawn(function()
    while CONFIG.enabled do
        autoHatchEggs()
        sellButton.Text = "💰 Sell Pets (Team " .. hatcherState.activePetTeam .. ")"
        wait(CONFIG.checkInterval)
    end
end)

-- Initial load
updateEggDropdown()

print("[Egg Hatcher] Script loaded!")
print("[Egg Hatcher] Press " .. tostring(CONFIG.guiToggleKey) .. " to toggle GUI")
print("[Egg Hatcher] Press " .. tostring(CONFIG.toggleKey) .. " to toggle hatching")
print("[Egg Hatcher] Drag the title bar to move the window!")
