--==============================================================
-- BABI MANAGER - GAME DATA VERSION
--==============================================================
-- Pasang sebagai LocalScript:
-- StarterPlayer > StarterPlayerScripts
--
-- SISTEM:
--   BabiBandar:InvokeServer("info")
--       -> result.ternak
--       -> ternak[].id
--       -> ternak[].progres
--
-- UMUR:
--   progres = hari
--   1 hari = 1440 menit
--
-- TARGET:
--   Workspace
--   └─ KandangBabi_*
--      └─ Babi_<ID>
--         └─ modelbabi
--            └─ ProximityPrompt "Bawa"
--
-- modelinduk DAN prompt "Gosok" DIABAIKAN.
--==============================================================

if not game:IsLoaded() then
    game.Loaded:Wait()
end

--==============================================================
-- SERVICES
--==============================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

if not LocalPlayer then
    return
end

local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

--==============================================================
-- CONFIG
--==============================================================

local DEFAULT_MIN_AGE = 60
local SCAN_INTERVAL = 1
local TARGET_LOCK_TIME = 0.5

--==============================================================
-- STATE
--==============================================================

local Running = false
local CurrentTarget = nil
local CurrentTargetData = nil
local LastScan = 0
local Busy = false

local MinimumAgeMinutes = DEFAULT_MIN_AGE

--==============================================================
-- CLEAN OLD UI
--==============================================================

local OldUI = PlayerGui:FindFirstChild("BabiManagerUI")

if OldUI then
    OldUI:Destroy()
end

--==============================================================
-- FIND BABIBANDAR
--==============================================================

local function FindBabiBandar()

    local obj = ReplicatedStorage:FindFirstChild("BabiBandar", true)

    if obj and obj:IsA("RemoteFunction") then
        return obj
    end

    return nil
end

local BabiBandar = FindBabiBandar()

--==============================================================
-- UI
--==============================================================

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "BabiManagerUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = PlayerGui

local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.new(0, 320, 0, 310)
Main.Position = UDim2.new(0, 20, 0.5, -155)
Main.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
Main.BorderSizePixel = 0
Main.Parent = ScreenGui

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0, 10)
Corner.Parent = Main

local Stroke = Instance.new("UIStroke")
Stroke.Thickness = 1
Stroke.Color = Color3.fromRGB(80, 80, 80)
Stroke.Parent = Main

--==============================================================
-- TITLE
--==============================================================

local Title = Instance.new("TextLabel")
Title.Name = "Title"
Title.Size = UDim2.new(1, -20, 0, 40)
Title.Position = UDim2.new(0, 10, 0, 5)
Title.BackgroundTransparency = 1
Title.Text = "BABI MANAGER"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 22
Title.Font = Enum.Font.GothamBold
Title.Parent = Main

--==============================================================
-- STATUS
--==============================================================

local Status = Instance.new("TextLabel")
Status.Name = "Status"
Status.Size = UDim2.new(1, -20, 0, 35)
Status.Position = UDim2.new(0, 10, 0, 48)
Status.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
Status.Text = "STATUS: STARTING..."
Status.TextColor3 = Color3.fromRGB(255, 220, 80)
Status.TextSize = 14
Status.Font = Enum.Font.GothamBold
Status.Parent = Main

local StatusCorner = Instance.new("UICorner")
StatusCorner.CornerRadius = UDim.new(0, 6)
StatusCorner.Parent = Status

--==============================================================
-- TARGET
--==============================================================

local TargetLabel = Instance.new("TextLabel")
TargetLabel.Name = "Target"
TargetLabel.Size = UDim2.new(1, -20, 0, 45)
TargetLabel.Position = UDim2.new(0, 10, 0, 90)
TargetLabel.BackgroundTransparency = 1
TargetLabel.Text = "TARGET: NONE"
TargetLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TargetLabel.TextSize = 13
TargetLabel.Font = Enum.Font.Gotham
TargetLabel.TextWrapped = true
TargetLabel.Parent = Main

--==============================================================
-- AGE
--==============================================================

local AgeLabel = Instance.new("TextLabel")
AgeLabel.Name = "Age"
AgeLabel.Size = UDim2.new(1, -20, 0, 30)
AgeLabel.Position = UDim2.new(0, 10, 0, 138)
AgeLabel.BackgroundTransparency = 1
AgeLabel.Text = "AGE: NONE"
AgeLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
AgeLabel.TextSize = 13
AgeLabel.Font = Enum.Font.Gotham
AgeLabel.Parent = Main

--==============================================================
-- MIN AGE LABEL
--==============================================================

local MinAgeLabel = Instance.new("TextLabel")
MinAgeLabel.Name = "MinAgeLabel"
MinAgeLabel.Size = UDim2.new(0, 100, 0, 30)
MinAgeLabel.Position = UDim2.new(0, 10, 0, 178)
MinAgeLabel.BackgroundTransparency = 1
MinAgeLabel.Text = "MIN AGE:"
MinAgeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
MinAgeLabel.TextSize = 14
MinAgeLabel.Font = Enum.Font.GothamBold
MinAgeLabel.TextXAlignment = Enum.TextXAlignment.Left
MinAgeLabel.Parent = Main

--==============================================================
-- AGE BOX
--==============================================================

local AgeBox = Instance.new("TextBox")
AgeBox.Name = "AgeBox"
AgeBox.Size = UDim2.new(0, 190, 0, 32)
AgeBox.Position = UDim2.new(0, 110, 0, 177)
AgeBox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
AgeBox.BorderSizePixel = 0
AgeBox.Text = tostring(DEFAULT_MIN_AGE)
AgeBox.PlaceholderText = "Minutes"
AgeBox.TextColor3 = Color3.fromRGB(255, 255, 255)
AgeBox.TextSize = 14
AgeBox.Font = Enum.Font.Gotham
AgeBox.ClearTextOnFocus = false
AgeBox.Parent = Main

local AgeCorner = Instance.new("UICorner")
AgeCorner.CornerRadius = UDim.new(0, 6)
AgeCorner.Parent = AgeBox

--==============================================================
-- APPLY AGE
--==============================================================

local ApplyButton = Instance.new("TextButton")
ApplyButton.Name = "Apply"
ApplyButton.Size = UDim2.new(0, 290, 0, 35)
ApplyButton.Position = UDim2.new(0, 15, 0, 217)
ApplyButton.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
ApplyButton.BorderSizePixel = 0
ApplyButton.Text = "APPLY MIN AGE"
ApplyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ApplyButton.TextSize = 13
ApplyButton.Font = Enum.Font.GothamBold
ApplyButton.Parent = Main

local ApplyCorner = Instance.new("UICorner")
ApplyCorner.CornerRadius = UDim.new(0, 6)
ApplyCorner.Parent = ApplyButton

--==============================================================
-- START / STOP
--==============================================================

local ToggleButton = Instance.new("TextButton")
ToggleButton.Name = "Toggle"
ToggleButton.Size = UDim2.new(0, 290, 0, 35)
ToggleButton.Position = UDim2.new(0, 15, 0, 260)
ToggleButton.BackgroundColor3 = Color3.fromRGB(45, 100, 45)
ToggleButton.BorderSizePixel = 0
ToggleButton.Text = "AUTO PICKUP: OFF"
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.TextSize = 13
ToggleButton.Font = Enum.Font.GothamBold
ToggleButton.Parent = Main

local ToggleCorner = Instance.new("UICorner")
ToggleCorner.CornerRadius = UDim.new(0, 6)
ToggleCorner.Parent = ToggleButton

--==============================================================
-- STATUS FUNCTION
--==============================================================

local function SetStatus(text)
    Status.Text = "STATUS: " .. tostring(text)
end

--==============================================================
-- FORMAT AGE
--==============================================================

local function ProgressToMinutes(progress)

    progress = tonumber(progress)

    if not progress then
        return nil
    end

    return progress * 1440
end

--==============================================================
-- GET PIG ID FROM WORKSPACE
--==============================================================

local function GetPigIdFromModel(model)

    if not model then
        return nil
    end

    local id = string.match(model.Name, "^Babi_(.+)$")

    return id
end

--==============================================================
-- FIND BABI WORKSPACE MODEL
--==============================================================

local function FindWorkspacePigById(id)

    if not id then
        return nil
    end

    local kandangFolderList = {}

    for _, obj in ipairs(workspace:GetChildren()) do

        if obj:IsA("Folder") or obj:IsA("Model") then

            if string.match(obj.Name, "^KandangBabi_") then
                table.insert(kandangFolderList, obj)
            end

        end
    end

    for _, kandang in ipairs(kandangFolderList) do

        for _, babi in ipairs(kandang:GetChildren()) do

            if babi:IsA("Model") or babi:IsA("Folder") then

                local babiId = GetPigIdFromModel(babi)

                if babiId and tostring(babiId) == tostring(id) then

                    return babi

                end

            end

        end
    end

    return nil
end

--==============================================================
-- FIND MODEL BABI
--==============================================================

local function FindModelBabi(babi)

    if not babi then
        return nil
    end

    -- Nama yang benar adalah lowercase: modelbabi
    local exact = babi:FindFirstChild("modelbabi")

    if exact then
        return exact
    end

    -- Fallback case-insensitive
    for _, child in ipairs(babi:GetChildren()) do

        if string.lower(child.Name) == "modelbabi" then
            return child
        end

    end

    return nil
end

--==============================================================
-- FIND BAWA PROMPT
--==============================================================

local function FindBawaPrompt(modelBabi)

    if not modelBabi then
        return nil
    end

    for _, obj in ipairs(modelBabi:GetDescendants()) do

        if obj:IsA("ProximityPrompt") then

            if obj.ActionText == "Bawa" then
                return obj
            end

        end

    end

    return nil
end

--==============================================================
-- GET SERVER DATA
--==============================================================

local function GetServerPigData()

    if not BabiBandar then

        BabiBandar = FindBabiBandar()

        if not BabiBandar then
            return nil, "BABIBANDAR NOT FOUND"
        end

    end

    local success, result = pcall(function()

        return BabiBandar:InvokeServer("info")

    end)

    if not success then
        return nil, "INFO REQUEST FAILED"
    end

    if type(result) ~= "table" then
        return nil, "INVALID INFO RESPONSE"
    end

    if result.ok ~= true then
        return nil, "INFO RESPONSE NOT OK"
    end

    if type(result.ternak) ~= "table" then
        return nil, "TERNak DATA NOT FOUND"
    end

    return result.ternak, nil
end

--==============================================================
-- FIND BEST TARGET
--==============================================================

local function FindTarget()

    local ternak, errorMessage = GetServerPigData()

    if not ternak then
        return nil, nil, errorMessage
    end

    local eligibleCount = 0

    for _, data in pairs(ternak) do

        if type(data) == "table" then

            local pigId = data.id

            if pigId ~= nil then

                local progress = tonumber(data.progres)

                if progress then

                    local ageMinutes = ProgressToMinutes(progress)

                    if ageMinutes and ageMinutes >= MinimumAgeMinutes then

                        eligibleCount += 1

                        local babi = FindWorkspacePigById(pigId)

                        if babi then

                            local modelBabi = FindModelBabi(babi)

                            if modelBabi then

                                local prompt = FindBawaPrompt(modelBabi)

                                if prompt then

                                    return {
                                        Babi = babi,
                                        ModelBabi = modelBabi,
                                        Prompt = prompt,
                                        Data = data,
                                        AgeMinutes = ageMinutes,
                                        PigId = tostring(pigId)
                                    }, nil, nil

                                end
                            end
                        end
                    end
                end
            end
        end
    end

    if eligibleCount > 0 then
        return nil, nil, "ELIGIBLE BUT MODEL/PROMPT NOT FOUND"
    end

    return nil, nil, "NO BABI MEETS MIN AGE"
end

--==============================================================
-- TARGET VALIDATION
--==============================================================

local function ValidateTarget(target)

    if not target then
        return false
    end

    if not target.Babi then
        return false
    end

    if not target.Babi.Parent then
        return false
    end

    if not target.ModelBabi then
        return false
    end

    if not target.ModelBabi.Parent then
        return false
    end

    if not target.Prompt then
        return false
    end

    if not target.Prompt.Parent then
        return false
    end

    return true
end

--==============================================================
-- DISPLAY TARGET
--==============================================================

local function DisplayTarget(target)

    if not target then

        TargetLabel.Text = "TARGET: NONE"
        AgeLabel.Text = "AGE: NONE"

        return
    end

    local data = target.Data

    local umurText = "UNKNOWN"

    if data and data.umur then
        umurText = tostring(data.umur)
    elseif data and data.dewasa == true then
        umurText = "Dewasa"
    end

    TargetLabel.Text =
        "TARGET: " ..
        tostring(target.Babi.Name) ..
        "\nID: " ..
        tostring(target.PigId)

    AgeLabel.Text =
        string.format(
            "AGE: %.1f MIN | %s",
            target.AgeMinutes or 0,
            umurText
        )
end

--==============================================================
-- CLEAR TARGET
--==============================================================

local function ClearTarget(reason)

    CurrentTarget = nil
    CurrentTargetData = nil

    TargetLabel.Text = "TARGET: NONE"
    AgeLabel.Text = "AGE: NONE"

    if reason then
        SetStatus(reason)
    end
end

--==============================================================
-- FIND NEW TARGET
--==============================================================

local function AcquireTarget()

    if Busy then
        return
    end

    Busy = true

    local target, _, errorMessage = FindTarget()

    if target then

        CurrentTarget = target
        CurrentTargetData = target.Data

        DisplayTarget(target)

        SetStatus("TARGET LOCKED")

    else

        ClearTarget(errorMessage or "NO TARGET")

    end

    Busy = false
end

--==============================================================
-- CHECK TARGET AGE AGAINST SERVER DATA
--==============================================================

local function RefreshLockedTarget()

    if not CurrentTarget then
        return false
    end

    if not ValidateTarget(CurrentTarget) then
        return false
    end

    local ternak, errorMessage = GetServerPigData()

    if not ternak then
        SetStatus(errorMessage or "DATA ERROR")
        return true
    end

    local targetId = tostring(CurrentTarget.PigId)

    for _, data in pairs(ternak) do

        if type(data) == "table" then

            if data.id ~= nil and tostring(data.id) == targetId then

                local progress = tonumber(data.progres)

                if not progress then
                    return false
                end

                local ageMinutes = ProgressToMinutes(progress)

                if not ageMinutes then
                    return false
                end

                CurrentTarget.Data = data
                CurrentTarget.AgeMinutes = ageMinutes
                CurrentTargetData = data

                DisplayTarget(CurrentTarget)

                if ageMinutes >= MinimumAgeMinutes then

                    SetStatus("TARGET LOCKED")

                    return true

                else

                    return false

                end
            end
        end
    end

    return false
end

--==============================================================
-- APPLY MIN AGE
--==============================================================

ApplyButton.MouseButton1Click:Connect(function()

    local value = tonumber(AgeBox.Text)

    if not value then

        AgeBox.Text = tostring(MinimumAgeMinutes)
        SetStatus("INVALID MIN AGE")

        return
    end

    value = math.floor(value)

    if value < 1 then
        value = 1
    end

    if value > 100000 then
        value = 100000
    end

    MinimumAgeMinutes = value
    AgeBox.Text = tostring(value)

    ClearTarget("MIN AGE SET: " .. tostring(value) .. " MIN")

end)

--==============================================================
-- ENTER KEY FOR AGE
--==============================================================

AgeBox.FocusLost:Connect(function(enterPressed)

    if enterPressed then

        local value = tonumber(AgeBox.Text)

        if value then

            value = math.floor(value)

            if value < 1 then
                value = 1
            end

            if value > 100000 then
                value = 100000
            end

            MinimumAgeMinutes = value
            AgeBox.Text = tostring(value)

            ClearTarget("MIN AGE SET: " .. tostring(value) .. " MIN")

        else

            AgeBox.Text = tostring(MinimumAgeMinutes)

        end

    end
end)

--==============================================================
-- TOGGLE
--==============================================================

ToggleButton.MouseButton1Click:Connect(function()

    Running = not Running

    if Running then

        ToggleButton.Text = "AUTO PICKUP: ON"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(45, 130, 55)

        SetStatus("SCANNING...")

        ClearTarget()

    else

        ToggleButton.Text = "AUTO PICKUP: OFF"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(45, 100, 45)

        SetStatus("STOPPED")

    end

end)

--==============================================================
-- INITIAL STATUS
--==============================================================

task.spawn(function()

    task.wait(1)

    BabiBandar = FindBabiBandar()

    if BabiBandar then
        SetStatus("BABIBANDAR READY")
    else
        SetStatus("BABIBANDAR NOT FOUND")
    end

end)

--==============================================================
-- MAIN LOOP
--==============================================================

task.spawn(function()

    while ScreenGui.Parent do

        task.wait(SCAN_INTERVAL)

        if not Running then
            continue
        end

        --======================================================
        -- KEEP EXISTING TARGET LOCKED
        --======================================================

        if CurrentTarget then

            local valid = RefreshLockedTarget()

            if valid then
                continue
            end

            ClearTarget("TARGET INVALID - RESCAN")

        end

        --======================================================
        -- FIND NEW TARGET
        --======================================================

        AcquireTarget()

    end

end)

--==============================================================
-- DRAG UI
--==============================================================

local dragging = false
local dragStart
local startPosition

Title.InputBegan:Connect(function(input)

    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then

        dragging = true
        dragStart = input.Position
        startPosition = Main.Position

        input.Changed:Connect(function()

            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end

        end)

    end

end)

Title.InputChanged:Connect(function(input)

    if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then

        local connection

        connection = RunService.RenderStepped:Connect(function()

            if not dragging then

                connection:Disconnect()
                return

            end

            local delta = input.Position - dragStart

            Main.Position = UDim2.new(
                startPosition.X.Scale,
                startPosition.X.Offset + delta.X,
                startPosition.Y.Scale,
                startPosition.Y.Offset + delta.Y
            )

        end)

    end

end)

--==============================================================
-- DONE
--==============================================================

print("==============================================")
print("BABI MANAGER LOADED")
print("Minimum Age:", MinimumAgeMinutes, "minutes")
print("BabiBandar:", BabiBandar)
print("==============================================")
