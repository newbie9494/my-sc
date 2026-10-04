--==============================================================
-- BABI MANAGER V9
-- TARGET: KandangBabi_* -> Babi_* -> ModelBabi
-- ModelInduk DIABAIKAN
--
-- Gunakan sebagai LocalScript:
-- StarterPlayer > StarterPlayerScripts
--==============================================================

if not game:IsLoaded() then
    game.Loaded:Wait()
end

--==============================================================
-- SERVICES
--==============================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer

--==============================================================
-- CONFIG
--==============================================================

local DEFAULT_AGE_MINUTES = 60

local SCAN_INTERVAL = 0.5
local TARGET_CHECK_INTERVAL = 0.5
local TELEPORT_DISTANCE = 5

--==============================================================
-- STATE
--==============================================================

local MinimumAgeMinutes = DEFAULT_AGE_MINUTES
local MinimumAgeSeconds = DEFAULT_AGE_MINUTES * 60

local AutoPickup = false
local Running = true

local CurrentTarget = nil
local CurrentBabiContainer = nil
local CurrentKandang = nil
local CurrentPrompt = nil

local LastScan = 0
local LastTargetCheck = 0

--==============================================================
-- HELPERS
--==============================================================

local function SafeFind(parent, name)
    if not parent then
        return nil
    end

    local ok, result = pcall(function()
        return parent:FindFirstChild(name)
    end)

    if ok then
        return result
    end

    return nil
end

local function IsKandang(object)
    if not object then
        return false
    end

    return string.match(object.Name, "^KandangBabi_") ~= nil
end

local function IsBabiContainer(object)
    if not object then
        return false
    end

    return string.match(object.Name, "^Babi_") ~= nil
end

--==============================================================
-- AGE READER
--==============================================================

local AGE_NAMES = {
    "AgeSeconds",
    "AgeSecond",
    "Age",
    "Umur",
    "AgeTime",
    "TimeAlive",
    "TimeAge",
    "AgeValue",
    "UmurSeconds",
    "UmurSecond",
    "Lifetime",
    "ElapsedTime",
}

local function ReadNumberObject(object)
    if not object then
        return nil
    end

    if object:IsA("NumberValue") or object:IsA("IntValue") then
        local ok, value = pcall(function()
            return object.Value
        end)

        if ok and type(value) == "number" then
            return value
        end
    end

    return nil
end

local function ReadAttribute(object, attributeName)
    if not object then
        return nil
    end

    local ok, value = pcall(function()
        return object:GetAttribute(attributeName)
    end)

    if not ok then
        return nil
    end

    if type(value) == "number" then
        return value
    end

    return nil
end

local function SearchAgeInObject(object)
    if not object then
        return nil
    end

    --==========================================================
    -- 1. ATTRIBUTES
    --==========================================================

    for _, name in ipairs(AGE_NAMES) do
        local value = ReadAttribute(object, name)

        if value ~= nil then
            return value, name
        end
    end

    --==========================================================
    -- 2. DIRECT VALUE OBJECTS
    --==========================================================

    for _, name in ipairs(AGE_NAMES) do
        local child = SafeFind(object, name)

        if child then
            local value = ReadNumberObject(child)

            if value ~= nil then
                return value, name
            end
        end
    end

    --==========================================================
    -- 3. DESCENDANTS
    --==========================================================

    local descendants = {}

    local ok = pcall(function()
        descendants = object:GetDescendants()
    end)

    if not ok then
        return nil
    end

    for _, descendant in ipairs(descendants) do
        local lowerName = string.lower(descendant.Name)

        for _, name in ipairs(AGE_NAMES) do
            if lowerName == string.lower(name) then
                local value = ReadNumberObject(descendant)

                if value ~= nil then
                    return value, descendant.Name
                end
            end
        end
    end

    return nil
end

local function ReadAgeSeconds(modelBabi, babiContainer)
    -- Prioritas ModelBabi
    local value, source = SearchAgeInObject(modelBabi)

    if value ~= nil then
        return value, source
    end

    -- Jika tidak ada, cek parent Babi_*
    value, source = SearchAgeInObject(babiContainer)

    if value ~= nil then
        return value, source
    end

    return nil, nil
end

--==============================================================
-- MODEL VALIDATION
--==============================================================

local function IsValidModelBabi(modelBabi)
    if not modelBabi then
        return false
    end

    if not modelBabi.Parent then
        return false
    end

    if modelBabi.Name ~= "ModelBabi" then
        return false
    end

    return true
end

--==============================================================
-- FIND BAwa PROMPT
--==============================================================

local function FindBawaPrompt(modelBabi)
    if not modelBabi then
        return nil
    end

    local directPrompt = SafeFind(modelBabi, "Bawa")

    if directPrompt and directPrompt:IsA("ProximityPrompt") then
        return directPrompt
    end

    local ok, descendants = pcall(function()
        return modelBabi:GetDescendants()
    end)

    if not ok then
        return nil
    end

    for _, object in ipairs(descendants) do
        if object:IsA("ProximityPrompt") then
            if object.Name == "Bawa" then
                return object
            end

            local okAction, actionText = pcall(function()
                return object.ActionText
            end)

            if okAction and actionText == "Bawa" then
                return object
            end
        end
    end

    return nil
end

--==============================================================
-- FIND ROOT PART
--==============================================================

local function FindRootPart(model)
    if not model then
        return nil
    end

    if model:IsA("BasePart") then
        return model
    end

    local ok, result = pcall(function()
        return model.PrimaryPart
    end)

    if ok and result then
        return result
    end

    local humanoidRoot = SafeFind(model, "HumanoidRootPart")

    if humanoidRoot and humanoidRoot:IsA("BasePart") then
        return humanoidRoot
    end

    local okDesc, descendants = pcall(function()
        return model:GetDescendants()
    end)

    if okDesc then
        for _, object in ipairs(descendants) do
            if object:IsA("BasePart") then
                return object
            end
        end
    end

    return nil
end

--==============================================================
-- CHARACTER ROOT
--==============================================================

local function GetCharacterRoot()
    local character = LocalPlayer.Character

    if not character then
        return nil
    end

    return character:FindFirstChild("HumanoidRootPart")
end

--==============================================================
-- FIND ALL TARGETS
--==============================================================

local function GetAllTargets()
    local targets = {}

    local ok, children = pcall(function()
        return workspace:GetChildren()
    end)

    if not ok then
        return targets
    end

    for _, kandang in ipairs(children) do

        --======================================================
        -- ONLY KandangBabi_<PlayerID>
        --======================================================

        if IsKandang(kandang) then

            local okBabi, babiChildren = pcall(function()
                return kandang:GetChildren()
            end)

            if okBabi then

                for _, babiContainer in ipairs(babiChildren) do

                    --==================================================
                    -- ONLY Babi_<ID unik>
                    --==================================================

                    if IsBabiContainer(babiContainer) then

                        --================================================
                        -- CRITICAL:
                        -- ModelInduk tidak pernah dipakai.
                        -- Hanya ModelBabi.
                        --================================================

                        local modelBabi = SafeFind(
                            babiContainer,
                            "ModelBabi"
                        )

                        if modelBabi and IsValidModelBabi(modelBabi) then

                            table.insert(targets, {
                                Kandang = kandang,
                                BabiContainer = babiContainer,
                                ModelBabi = modelBabi,
                            })

                        end
                    end
                end
            end
        end
    end

    return targets
end

--==============================================================
-- CHECK AGE
--==============================================================

local function TargetPassesAge(targetData)
    if not targetData then
        return false, nil
    end

    local ageSeconds, source = ReadAgeSeconds(
        targetData.ModelBabi,
        targetData.BabiContainer
    )

    if ageSeconds == nil then
        return false, nil
    end

    --==========================================================
    -- Normalisasi:
    --
    -- Jika sistem game menyimpan Age dalam menit, nilainya
    -- kemungkinan kecil. Untuk menghindari salah tafsir kita
    -- gunakan field yang bernama jelas terlebih dahulu.
    --==========================================================

    local lowerSource = source and string.lower(source) or ""

    if string.find(lowerSource, "minute")
        or string.find(lowerSource, "menit") then

        ageSeconds = ageSeconds * 60
    end

    return ageSeconds >= MinimumAgeSeconds, ageSeconds
end

--==============================================================
-- FIND TARGET
--==============================================================

local function FindBestTarget()
    local targets = GetAllTargets()

    local oldestTarget = nil
    local oldestAge = -math.huge

    for _, targetData in ipairs(targets) do

        local validAge, ageSeconds = TargetPassesAge(targetData)

        if validAge and ageSeconds then

            if ageSeconds > oldestAge then
                oldestAge = ageSeconds
                oldestTarget = targetData
            end

        end
    end

    return oldestTarget, oldestAge
end

--==============================================================
-- TARGET VALIDATION
--==============================================================

local function IsCurrentTargetValid()
    if not CurrentTarget then
        return false
    end

    if not IsValidModelBabi(CurrentTarget) then
        return false
    end

    if not CurrentBabiContainer then
        return false
    end

    if not CurrentBabiContainer.Parent then
        return false
    end

    if CurrentBabiContainer:FindFirstChild("ModelBabi") ~= CurrentTarget then
        return false
    end

    local targetData = {
        ModelBabi = CurrentTarget,
        BabiContainer = CurrentBabiContainer,
        Kandang = CurrentKandang,
    }

    local validAge = TargetPassesAge(targetData)

    if not validAge then
        return false
    end

    return true
end

--==============================================================
-- SET TARGET
--==============================================================

local function SetTarget(targetData)
    if not targetData then
        CurrentTarget = nil
        CurrentBabiContainer = nil
        CurrentKandang = nil
        CurrentPrompt = nil
        return
    end

    CurrentTarget = targetData.ModelBabi
    CurrentBabiContainer = targetData.BabiContainer
    CurrentKandang = targetData.Kandang
    CurrentPrompt = FindBawaPrompt(CurrentTarget)
end

--==============================================================
-- TELEPORT NEAR TARGET
--==============================================================

local function MoveNearTarget()
    if not CurrentTarget then
        return false
    end

    local characterRoot = GetCharacterRoot()

    if not characterRoot then
        return false
    end

    local targetRoot = FindRootPart(CurrentTarget)

    if not targetRoot then
        return false
    end

    local targetCFrame = targetRoot.CFrame

    local ok = pcall(function()
        characterRoot.CFrame =
            targetCFrame
            * CFrame.new(0, 0, TELEPORT_DISTANCE)
    end)

    return ok
end

--==============================================================
-- UI
--==============================================================

local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local Existing = PlayerGui:FindFirstChild("BabiManagerV9")

if Existing then
    Existing:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "BabiManagerV9"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = PlayerGui

--==============================================================
-- MAIN FRAME
--==============================================================

local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.new(0, 320, 0, 300)
Main.Position = UDim2.new(0.5, -160, 0.5, -150)
Main.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
Main.BorderSizePixel = 0
Main.Parent = ScreenGui

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0, 10)
Corner.Parent = Main

local Stroke = Instance.new("UIStroke")
Stroke.Thickness = 1
Stroke.Color = Color3.fromRGB(70, 70, 80)
Stroke.Parent = Main

--==============================================================
-- TITLE
--==============================================================

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -20, 0, 35)
Title.Position = UDim2.new(0, 10, 0, 8)
Title.BackgroundTransparency = 1
Title.Text = "BABI MANAGER V9"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 18
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Main

--==============================================================
-- AGE LABEL
--==============================================================

local AgeLabel = Instance.new("TextLabel")
AgeLabel.Size = UDim2.new(1, -20, 0, 25)
AgeLabel.Position = UDim2.new(0, 10, 0, 48)
AgeLabel.BackgroundTransparency = 1
AgeLabel.Text = "MINIMUM AGE (MENIT)"
AgeLabel.TextColor3 = Color3.fromRGB(190, 190, 200)
AgeLabel.TextSize = 12
AgeLabel.Font = Enum.Font.Gotham
AgeLabel.TextXAlignment = Enum.TextXAlignment.Left
AgeLabel.Parent = Main

--==============================================================
-- AGE BOX
--==============================================================

local AgeBox = Instance.new("TextBox")
AgeBox.Size = UDim2.new(0, 190, 0, 38)
AgeBox.Position = UDim2.new(0, 10, 0, 75)
AgeBox.BackgroundColor3 = Color3.fromRGB(30, 30, 36)
AgeBox.BorderSizePixel = 0
AgeBox.Text = tostring(MinimumAgeMinutes)
AgeBox.TextColor3 = Color3.fromRGB(255, 255, 255)
AgeBox.PlaceholderText = "Contoh: 60"
AgeBox.PlaceholderColor3 = Color3.fromRGB(100, 100, 110)
AgeBox.TextSize = 14
AgeBox.Font = Enum.Font.Gotham
AgeBox.ClearTextOnFocus = false
AgeBox.Parent = Main

local AgeCorner = Instance.new("UICorner")
AgeCorner.CornerRadius = UDim.new(0, 7)
AgeCorner.Parent = AgeBox

--==============================================================
-- SET BUTTON
--==============================================================

local SetButton = Instance.new("TextButton")
SetButton.Size = UDim2.new(0, 90, 0, 38)
SetButton.Position = UDim2.new(0, 215, 0, 75)
SetButton.BackgroundColor3 = Color3.fromRGB(50, 120, 220)
SetButton.BorderSizePixel = 0
SetButton.Text = "SET"
SetButton.TextColor3 = Color3.fromRGB(255, 255, 255)
SetButton.TextSize = 14
SetButton.Font = Enum.Font.GothamBold
SetButton.Parent = Main

local SetCorner = Instance.new("UICorner")
SetCorner.CornerRadius = UDim.new(0, 7)
SetCorner.Parent = SetButton

--==============================================================
-- STATUS
--==============================================================

local Status = Instance.new("TextLabel")
Status.Size = UDim2.new(1, -20, 0, 28)
Status.Position = UDim2.new(0, 10, 0, 125)
Status.BackgroundTransparency = 1
Status.Text = "STATUS: SCANNING..."
Status.TextColor3 = Color3.fromRGB(255, 220, 100)
Status.TextSize = 13
Status.Font = Enum.Font.GothamBold
Status.TextXAlignment = Enum.TextXAlignment.Left
Status.Parent = Main

--==============================================================
-- TARGET
--==============================================================

local TargetLabel = Instance.new("TextLabel")
TargetLabel.Size = UDim2.new(1, -20, 0, 45)
TargetLabel.Position = UDim2.new(0, 10, 0, 153)
TargetLabel.BackgroundTransparency = 1
TargetLabel.Text = "TARGET: NONE"
TargetLabel.TextColor3 = Color3.fromRGB(200, 200, 210)
TargetLabel.TextSize = 12
TargetLabel.Font = Enum.Font.Gotham
TargetLabel.TextWrapped = true
TargetLabel.TextXAlignment = Enum.TextXAlignment.Left
TargetLabel.Parent = Main

--==============================================================
-- PROMPT STATUS
--==============================================================

local PromptLabel = Instance.new("TextLabel")
PromptLabel.Size = UDim2.new(1, -20, 0, 25)
PromptLabel.Position = UDim2.new(0, 10, 0, 198)
PromptLabel.BackgroundTransparency = 1
PromptLabel.Text = "BAWA: SEARCHING"
PromptLabel.TextColor3 = Color3.fromRGB(170, 170, 180)
PromptLabel.TextSize = 12
PromptLabel.Font = Enum.Font.Gotham
PromptLabel.TextXAlignment = Enum.TextXAlignment.Left
PromptLabel.Parent = Main

--==============================================================
-- AUTO PICKUP BUTTON
--==============================================================

local AutoButton = Instance.new("TextButton")
AutoButton.Size = UDim2.new(1, -20, 0, 35)
AutoButton.Position = UDim2.new(0, 10, 0, 225)
AutoButton.BackgroundColor3 = Color3.fromRGB(45, 45, 52)
AutoButton.BorderSizePixel = 0
AutoButton.Text = "AUTO PICKUP: OFF"
AutoButton.TextColor3 = Color3.fromRGB(230, 230, 235)
AutoButton.TextSize = 13
AutoButton.Font = Enum.Font.GothamBold
AutoButton.Parent = Main

local AutoCorner = Instance.new("UICorner")
AutoCorner.CornerRadius = UDim.new(0, 7)
AutoCorner.Parent = AutoButton

--==============================================================
-- DRAG SYSTEM
--==============================================================

local Dragging = false
local DragStart = nil
local StartPosition = nil

Title.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then

        Dragging = true
        DragStart = input.Position
        StartPosition = Main.Position

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                Dragging = false
            end
        end)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if not Dragging then
        return
    end

    if input.UserInputType ~= Enum.UserInputType.MouseMovement
        and input.UserInputType ~= Enum.UserInputType.Touch then
        return
    end

    local Delta = input.Position - DragStart

    Main.Position = UDim2.new(
        StartPosition.X.Scale,
        StartPosition.X.Offset + Delta.X,
        StartPosition.Y.Scale,
        StartPosition.Y.Offset + Delta.Y
    )
end)

--==============================================================
-- SET AGE
--==============================================================

local function ApplyAge()
    local number = tonumber(AgeBox.Text)

    if not number then
        AgeBox.Text = tostring(MinimumAgeMinutes)
        return
    end

    number = math.floor(number)

    if number < 0 then
        number = 0
    end

    if number > 100000 then
        number = 100000
    end

    MinimumAgeMinutes = number
    MinimumAgeSeconds = number * 60

    -- Reset target agar scanner mencari ulang
    CurrentTarget = nil
    CurrentBabiContainer = nil
    CurrentKandang = nil
    CurrentPrompt = nil

    Status.Text =
        "STATUS: AGE SET " ..
        tostring(MinimumAgeMinutes) ..
        " MIN"

    TargetLabel.Text = "TARGET: NONE"
    PromptLabel.Text = "BAWA: SEARCHING"
end

SetButton.MouseButton1Click:Connect(ApplyAge)

AgeBox.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        ApplyAge()
    end
end)

--==============================================================
-- AUTO BUTTON
--==============================================================

AutoButton.MouseButton1Click:Connect(function()
    AutoPickup = not AutoPickup

    if AutoPickup then
        AutoButton.Text = "AUTO PICKUP: ON"
    else
        AutoButton.Text = "AUTO PICKUP: OFF"
    end
end)

--==============================================================
-- UPDATE UI TARGET
--==============================================================

local function UpdateTargetUI(ageSeconds)
    if not CurrentTarget then
        TargetLabel.Text = "TARGET: NONE"
        PromptLabel.Text = "BAWA: SEARCHING"
        return
    end

    local ageText = "UNKNOWN"

    if ageSeconds then
        ageText = string.format(
            "%.1f menit",
            ageSeconds / 60
        )
    end

    TargetLabel.Text =
        "TARGET: " ..
        CurrentTarget.Name ..
        "\nAGE: " ..
        ageText

    if CurrentPrompt then
        PromptLabel.Text = "BAWA: FOUND"
    else
        PromptLabel.Text = "BAWA: NOT FOUND"
    end
end

--==============================================================
-- MAIN SCANNER
--==============================================================

task.spawn(function()

    while Running do

        task.wait(SCAN_INTERVAL)

        if not ScreenGui.Parent then
            break
        end

        --======================================================
        -- CURRENT TARGET
        --======================================================

        if CurrentTarget then

            if not IsCurrentTargetValid() then

                CurrentTarget = nil
                CurrentBabiContainer = nil
                CurrentKandang = nil
                CurrentPrompt = nil

                Status.Text = "STATUS: TARGET LOST"

            else

                CurrentPrompt = FindBawaPrompt(CurrentTarget)

                local data = {
                    ModelBabi = CurrentTarget,
                    BabiContainer = CurrentBabiContainer,
                    Kandang = CurrentKandang,
                }

                local validAge, ageSeconds =
                    TargetPassesAge(data)

                if validAge then

                    Status.Text = "STATUS: TARGET LOCKED"

                    UpdateTargetUI(ageSeconds)

                    if AutoPickup then
                        MoveNearTarget()
                    end

                else

                    CurrentTarget = nil
                    CurrentBabiContainer = nil
                    CurrentKandang = nil
                    CurrentPrompt = nil

                    Status.Text = "STATUS: AGE NO LONGER VALID"
                    TargetLabel.Text = "TARGET: NONE"
                    PromptLabel.Text = "BAWA: SEARCHING"
                end
            end

        else

            --==================================================
            -- FIND NEW TARGET
            --==================================================

            local targetData, ageSeconds = FindBestTarget()

            if targetData then

                SetTarget(targetData)

                Status.Text = "STATUS: TARGET LOCKED"

                UpdateTargetUI(ageSeconds)

                if AutoPickup then
                    MoveNearTarget()
                end

            else

                Status.Text =
                    "STATUS: NO BABI >= " ..
                    tostring(MinimumAgeMinutes) ..
                    " MIN"

                TargetLabel.Text = "TARGET: NONE"
                PromptLabel.Text = "BAWA: SEARCHING"
            end
        end
    end
end)

--==============================================================
-- DEBUG INFORMATION
--==============================================================

print("==================================================")
print(" BABI MANAGER V9 STARTED")
print("==================================================")
print("Target structure:")
print("Workspace")
print("  -> KandangBabi_*")
print("      -> Babi_*")
print("          -> ModelBabi")
print("==================================================")
print("ModelInduk will be ignored.")
print("Minimum Age:", MinimumAgeMinutes, "minutes")
print("==================================================")
