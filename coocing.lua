-- [[ SKRIP MANDIRI - AUTO COOK SIMULATOR UI PART 1 ]]
if not game:IsLoaded() then game.Loaded:Wait() end
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local TweenService = game:GetService("TweenService")
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui", 10)

if PlayerGui:FindFirstChild("AutoCookUI") then 
    PlayerGui.AutoCookUI:Destroy() 
end

_G.AutoCookActive = false
_G.SelectedCookMenu = "SateGagak"
task.wait(0.1)

local COOK_RECIPES = {
    ["JamurRebus"] = "Jamur Rebus",
    ["SateGagak"] = "Sate Gagak",
    ["PisangRajaRebus"] = "Pisang Raja Rebus",
    ["TumisKamboja"] = "Tumis Kamboja",
    ["SateKepiting"] = "Sate Kepiting",
    ["BabiGuling"] = "Babi Guling",
    ["Kopi"] = "Kopi",
    ["KopiKemenyan"] = "Kopi Kemenyan"
}

local INITIAL_TELEPORT_DELAY = 0.2
local SECURE_HOLD_DURATION = 0.5
local REPEAT_LOOP_DELAY = 1.5
local GLOBAL_SAVED_POS = UDim2.new(0.5, -110, 0.3, -100)

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AutoCookUI"; ScreenGui.Parent = PlayerGui; ScreenGui.ResetOnSpawn = false
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"; MainFrame.Parent = ScreenGui; MainFrame.BackgroundColor3 = Color3.fromRGB(35, 30, 30)
MainFrame.Position = GLOBAL_SAVED_POS; MainFrame.Size = UDim2.new(0, 220, 0, 180); MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true; MainFrame.Active = true
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 12)

local TopBar = Instance.new("Frame"); TopBar.Name = "TopBar"; TopBar.Parent = MainFrame; TopBar.BackgroundTransparency = 1; TopBar.Size = UDim2.new(1, 0, 0, 45)
local TitleButton = Instance.new("TextButton")
TitleButton.Name = "TitleButton"; TitleButton.Parent = TopBar; TitleButton.BackgroundTransparency = 1; TitleButton.Position = UDim2.new(0, 15, 0, 0); TitleButton.Size = UDim2.new(0, 140, 0, 45)
TitleButton.Font = Enum.Font.GothamBold; TitleButton.Text = "COOK SIMULATOR"; TitleButton.TextColor3 = Color3.fromRGB(255, 215, 0); TitleButton.TextSize = 12; TitleButton.TextXAlignment = Enum.TextXAlignment.Left

local MiniButton = Instance.new("TextButton")
MiniButton.Name = "MiniButton"; MiniButton.Parent = TopBar; MiniButton.BackgroundTransparency = 1; MiniButton.Position = UDim2.new(1, -35, 0, 0); MiniButton.Size = UDim2.new(0, 30, 0, 45)
MiniButton.Font = Enum.Font.GothamBold; MiniButton.Text = "-"; MiniButton.TextColor3 = Color3.fromRGB(200, 200, 200); MiniButton.TextSize = 20

local ContentFrame = Instance.new("Frame")
ContentFrame.Name = "ContentFrame"; ContentFrame.Parent = MainFrame; ContentFrame.BackgroundTransparency = 1; ContentFrame.Position = UDim2.new(0, 0, 0, 45); ContentFrame.Size = UDim2.new(1, 0, 1, -45)

local CookToggleBtn = Instance.new("TextButton")
CookToggleBtn.Name = "CookToggleBtn"; CookToggleBtn.Parent = ContentFrame; CookToggleBtn.BackgroundColor3 = Color3.fromRGB(220, 53, 69); CookToggleBtn.Position = UDim2.new(0.05, 0, 0.05, 0); CookToggleBtn.Size = UDim2.new(0.9, 0, 0, 35)
CookToggleBtn.Font = Enum.Font.GothamBold; CookToggleBtn.Text = "AUTO COOK: OFF"; CookToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255); CookToggleBtn.TextSize = 11
Instance.new("UICorner", CookToggleBtn).CornerRadius = UDim.new(0, 6)
-- [[ SKRIP MANDIRI - AUTO COOK SIMULATOR UI PART 3 ]]
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

local function clickVirtualCookingButton(gui, targetMenu)
    if not gui then return false end
    local targetBtn = gui:FindFirstChild(targetMenu, true) or gui:FindFirstChild(COOK_RECIPES[targetMenu], true)
    if targetBtn and targetBtn:IsA("TextButton") and targetBtn.Activated then
        targetBtn.Activated:Fire()
        return true
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

-- SISTEM BACKEND DETEKSI PENGULANGAN OTOMATIS (MENIRU GAMEPASS)
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
                        for i = 1, 3 do
                            if clickVirtualCookingButton(cookingGui, _G.SelectedCookMenu) then
                                fillCount = fillCount + 1
                                task.wait(0.05)
                            end
                        end
                        if fillCount > 0 then
                            local startBtn = cookingGui:FindFirstChild("Mulai Masak", true) or cookingGui:FindFirstChild("Mulai", true)
                            if startBtn and startBtn:IsA("TextButton") and startBtn.Activated then
                                startBtn.Activated:Fire()
                                task.wait(10) -- Masa tunggu antrean matang otomatis
                            end
                        end
                    end
                end
            end
        end
    end
end)
