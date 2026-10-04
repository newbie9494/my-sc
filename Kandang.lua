-- [[ BABI MANAGER V8 - TARGET LOCK + CUSTOM MINIMUM AGE ]]
-- TEST HARNESS UNTUK GAME SENDIRI
----------------------------------

-- Minimum Age dapat diubah langsung melalui UI.
-- Nilai umur menggunakan MENIT.
--------------------------------

-- Contoh:
-- 30  = 30 menit
-- 60  = 1 jam
-- 90  = 1 jam 30 menit
-- 120 = 2 jam
--------------

-- Alur:
-- 1. Cari Babi Ngepet
-- 2. Validasi umur sesuai setting UI
-- 3. Lock INSTANCE target
-- 4. Teleport ke target
-- 5. Cari ProximityPrompt "Bawa" MILIK target
-- 6. Siapkan interaksi normal
------------------------------

-- Script tidak menembakkan RemoteEvent arbitrer.

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")

-- ==============================================================
-- CONFIG
-- ==============================================================

local DEFAULT_AGE_MINUTES = 60
local TARGET_FOLDER_NAME = "kandang_babi"
local TARGET_NAME = "Babi Ngepet"
local SCAN_INTERVAL = 0.5
local PROMPT_DISTANCE = 10
local TELEPORT_DISTANCE = 5

-- Umur aktif. Default 60 menit.
local MinimumAgeMinutes = DEFAULT_AGE_MINUTES
local MinimumAgeSeconds = DEFAULT_AGE_MINUTES * 60

local AutoPickupActive = false
local CurrentTarget = nil
local Busy = false

local FolderKandang = Workspace:FindFirstChild(TARGET_FOLDER_NAME)

-- ==============================================================
-- UI
-- ==============================================================

local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local OldGui = PlayerGui:FindFirstChild("DeltaBabiManagerV8")
if OldGui then
OldGui:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "DeltaBabiManagerV8"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = PlayerGui

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 300, 0, 225)
MainFrame.Position = UDim2.new(0.5, -150, 0.4, -112)
MainFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0, 10)
Corner.Parent = MainFrame

-- ==============================================================
-- TITLE
-- ==============================================================

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -40, 0, 35)
TitleLabel.Position = UDim2.new(0, 0, 0, 0)
TitleLabel.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
TitleLabel.Text = "  BABI MANAGER V8"
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.Font = Enum.Font.SourceSansBold
TitleLabel.TextSize = 15
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.BorderSizePixel = 0
TitleLabel.Parent = MainFrame

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 10)
TitleCorner.Parent = TitleLabel

-- ==============================================================
-- CLOSE
-- ==============================================================

local CloseButton = Instance.new("TextButton")
CloseButton.Size = UDim2.new(0, 35, 0, 30)
CloseButton.Position = UDim2.new(1, -38, 0, 3)
CloseButton.BackgroundColor3 = Color3.fromRGB(60, 60, 65)
CloseButton.Text = "X"
CloseButton.TextColor3 = Color3.fromRGB(255, 70, 70)
CloseButton.Font = Enum.Font.SourceSansBold
CloseButton.TextSize = 16
CloseButton.BorderSizePixel = 0
CloseButton.Parent = MainFrame

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 5)
CloseCorner.Parent = CloseButton

-- ==============================================================
-- STATUS
-- ==============================================================

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, -30, 0, 25)
StatusLabel.Position = UDim2.new(0, 15, 0, 40)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "STATUS: OFF"
StatusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
StatusLabel.Font = Enum.Font.SourceSansBold
StatusLabel.TextSize = 13
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.Parent = MainFrame

-- ==============================================================
-- TARGET LABEL
-- ==============================================================

local TargetLabel = Instance.new("TextLabel")
TargetLabel.Size = UDim2.new(1, -30, 0, 25)
TargetLabel.Position = UDim2.new(0, 15, 0, 62)
TargetLabel.BackgroundTransparency = 1
TargetLabel.Text = "TARGET: NONE"
TargetLabel.TextColor3 = Color3.fromRGB(210, 210, 210)
TargetLabel.Font = Enum.Font.SourceSans
TargetLabel.TextSize = 11
TargetLabel.TextXAlignment = Enum.TextXAlignment.Left
TargetLabel.TextTruncate = Enum.TextTruncate.AtEnd
TargetLabel.Parent = MainFrame

-- ==============================================================
-- AGE SETTING
-- ==============================================================

local AgeLabel = Instance.new("TextLabel")
AgeLabel.Size = UDim2.new(0, 105, 0, 30)
AgeLabel.Position = UDim2.new(0, 15, 0, 88)
AgeLabel.BackgroundTransparency = 1
AgeLabel.Text = "MIN AGE (MIN):"
AgeLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
AgeLabel.Font = Enum.Font.SourceSansBold
AgeLabel.TextSize = 12
AgeLabel.TextXAlignment = Enum.TextXAlignment.Left
AgeLabel.Parent = MainFrame

local AgeBox = Instance.new("TextBox")
AgeBox.Name = "AgeBox"
AgeBox.Size = UDim2.new(0, 75, 0, 30)
AgeBox.Position = UDim2.new(0, 125, 0, 88)
AgeBox.BackgroundColor3 = Color3.fromRGB(55, 55, 62)
AgeBox.Text = tostring(DEFAULT_AGE_MINUTES)
AgeBox.PlaceholderText = "Menit"
AgeBox.TextColor3 = Color3.fromRGB(255, 255, 255)
AgeBox.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
AgeBox.Font = Enum.Font.SourceSansBold
AgeBox.TextSize = 14
AgeBox.ClearTextOnFocus = false
AgeBox.BorderSizePixel = 0
AgeBox.Parent = MainFrame

local AgeCorner = Instance.new("UICorner")
AgeCorner.CornerRadius = UDim.new(0, 6)
AgeCorner.Parent = AgeBox

local ApplyAgeButton = Instance.new("TextButton")
ApplyAgeButton.Size = UDim2.new(0, 70, 0, 30)
ApplyAgeButton.Position = UDim2.new(0, 205, 0, 88)
ApplyAgeButton.BackgroundColor3 = Color3.fromRGB(65, 110, 180)
ApplyAgeButton.Text = "SET"
ApplyAgeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ApplyAgeButton.Font = Enum.Font.SourceSansBold
ApplyAgeButton.TextSize = 12
ApplyAgeButton.BorderSizePixel = 0
ApplyAgeButton.Parent = MainFrame

local ApplyCorner = Instance.new("UICorner")
ApplyCorner.CornerRadius = UDim.new(0, 6)
ApplyCorner.Parent = ApplyAgeButton

-- ==============================================================
-- AGE INFO
-- ==============================================================

local AgeInfoLabel = Instance.new("TextLabel")
AgeInfoLabel.Size = UDim2.new(1, -30, 0, 20)
AgeInfoLabel.Position = UDim2.new(0, 15, 0, 119)
AgeInfoLabel.BackgroundTransparency = 1
AgeInfoLabel.Text = "Target minimum: 60 menit"
AgeInfoLabel.TextColor3 = Color3.fromRGB(150, 200, 255)
AgeInfoLabel.Font = Enum.Font.SourceSans
AgeInfoLabel.TextSize = 11
AgeInfoLabel.TextXAlignment = Enum.TextXAlignment.Left
AgeInfoLabel.Parent = MainFrame

-- ==============================================================
-- TOGGLE
-- ==============================================================

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(0, 260, 0, 45)
ToggleBtn.Position = UDim2.new(0, 20, 0, 145)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
ToggleBtn.Text = "AUTO PICKUP: OFF"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.SourceSansBold
ToggleBtn.TextSize = 16
ToggleBtn.BorderSizePixel = 0
ToggleBtn.Parent = MainFrame

local ToggleCorner = Instance.new("UICorner")
ToggleCorner.CornerRadius = UDim.new(0, 8)
ToggleCorner.Parent = ToggleBtn

-- ==============================================================
-- RESTORE BUTTON
-- ==============================================================

local RestoreBtn = Instance.new("TextButton")
RestoreBtn.Size = UDim2.new(0, 50, 0, 50)
RestoreBtn.Position = UDim2.new(0, 15, 0.5, -25)
RestoreBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
RestoreBtn.Text = "🐷"
RestoreBtn.TextSize = 26
RestoreBtn.Visible = false
RestoreBtn.BorderSizePixel = 0
RestoreBtn.Parent = ScreenGui

local RestoreCorner = Instance.new("UICorner")
RestoreCorner.CornerRadius = UDim.new(0, 25)
RestoreCorner.Parent = RestoreBtn

-- ==============================================================
-- STATUS FUNCTION
-- ==============================================================

local function SetStatus(text, color)
StatusLabel.Text = "STATUS: " .. text
StatusLabel.TextColor3 = color
end

local function SetTarget(model)
if model then
TargetLabel.Text = "TARGET: " .. model:GetFullName()
else
TargetLabel.Text = "TARGET: NONE"
end
end

-- ==============================================================
-- APPLY AGE
-- ==============================================================

local function ApplyAgeSetting()
local text = AgeBox.Text
local number = tonumber(text)

```
if not number then
    AgeBox.Text = tostring(MinimumAgeMinutes)
    SetStatus(
        "INVALID AGE",
        Color3.fromRGB(255, 100, 100)
    )
    return
end

number = math.floor(number)

if number < 1 then
    number = 1
end

-- Batas aman input UI.
if number > 100000 then
    number = 100000
end

MinimumAgeMinutes = number
MinimumAgeSeconds = number * 60

AgeBox.Text = tostring(MinimumAgeMinutes)

AgeInfoLabel.Text =
    "Target minimum: "
    .. tostring(MinimumAgeMinutes)
    .. " menit"

SetStatus(
    "AGE SET: " .. tostring(MinimumAgeMinutes) .. " MIN",
    Color3.fromRGB(80, 220, 255)
)

-- Target lama dibatalkan supaya scanner
-- melakukan validasi ulang menggunakan setting baru.
CurrentTarget = nil
SetTarget(nil)
```

end

ApplyAgeButton.MouseButton1Click:Connect(ApplyAgeSetting)

AgeBox.FocusLost:Connect(function(enterPressed)
if enterPressed then
ApplyAgeSetting()
end
end)

-- ==============================================================
-- TOGGLE
-- ==============================================================

ToggleBtn.MouseButton1Click:Connect(function()
AutoPickupActive = not AutoPickupActive

```
if AutoPickupActive then
    ToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 180, 50)
    ToggleBtn.Text = "AUTO PICKUP: ON"

    SetStatus(
        "SCANNING >= " .. tostring(MinimumAgeMinutes) .. " MIN",
        Color3.fromRGB(80, 255, 100)
    )
else
    ToggleBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    ToggleBtn.Text = "AUTO PICKUP: OFF"

    SetStatus(
        "OFF",
        Color3.fromRGB(255, 100, 100)
    )

    CurrentTarget = nil
    SetTarget(nil)
end
```

end)

CloseButton.MouseButton1Click:Connect(function()
MainFrame.Visible = false
RestoreBtn.Visible = true
end)

RestoreBtn.MouseButton1Click:Connect(function()
MainFrame.Visible = true
RestoreBtn.Visible = false
end)

-- ==============================================================
-- CHARACTER
-- ==============================================================

local function GetCharacter()
return LocalPlayer.Character
end

local function GetRoot()
local Character = GetCharacter()

```
if not Character then
    return nil
end

return Character:FindFirstChild("HumanoidRootPart")
```

end

-- ==============================================================
-- TARGET NAME
-- ==============================================================

local function IsTargetPig(model)
if not model or not model:IsA("Model") then
return false
end

```
if model.Name == TARGET_NAME then
    return true
end

for _, obj in ipairs(model:GetDescendants()) do
    if obj:IsA("TextLabel") or obj:IsA("TextBox") then
        if string.find(
            obj.Text,
            TARGET_NAME,
            1,
            true
        ) then
            return true
        end
    end
end

return false
```

end

-- ==============================================================
-- READ NUMBER
-- ==============================================================

local function ReadNumber(value)
if typeof(value) == "number" then
return value
end

```
if typeof(value) == "string" then
    return tonumber(value)
end

return nil
```

end

-- ==============================================================
-- AGE READER
-- ==============================================================

local function ReadAgeSeconds(pig)

```
local attributes = {
    "AgeSeconds",
    "Age",
    "age",
    "UmurSeconds",
    "Umur",
    "umur",
    "TimeAlive",
    "timeAlive",
    "ElapsedTime",
    "elapsedTime"
}

for _, attributeName in ipairs(attributes) do

    local value = pig:GetAttribute(attributeName)
    local number = ReadNumber(value)

    if number then
        return number
    end
end

for _, obj in ipairs(pig:GetDescendants()) do

    if obj:IsA("NumberValue")
        or obj:IsA("IntValue")
    then

        local lowerName =
            string.lower(obj.Name)

        if string.find(
            lowerName,
            "age",
            1,
            true
        )
        or string.find(
            lowerName,
            "umur",
            1,
            true
        )
        or string.find(
            lowerName,
            "timealive",
            1,
            true
        )
        then

            return obj.Value
        end
    end
end

return nil
```

end

-- ==============================================================
-- ADULT CHECK
-- ==============================================================

local function IsAdult(pig)

```
for _, gui in ipairs(
    pig:GetDescendants()
) do

    if gui:IsA("BillboardGui") then

        for _, label in ipairs(
            gui:GetDescendants()
        ) do

            if label:IsA("TextLabel")
                or label:IsA("TextBox")
            then

                local text = label.Text

                if string.find(
                    text,
                    "Bayi",
                    1,
                    true
                )
                or string.find(
                    text,
                    "Muda",
                    1,
                    true
                )
                then
                    return false
                end

                if string.find(
                    text,
                    "Dewasa",
                    1,
                    true
                ) then
                    return true
                end
            end
        end
    end
end

return false
```

end

-- ==============================================================
-- AGE VALIDATION
-- ==============================================================

local function IsOldEnough(pig)

```
local ageSeconds =
    ReadAgeSeconds(pig)

if not ageSeconds then
    return false
end

return ageSeconds >= MinimumAgeSeconds
```

end

-- ==============================================================
-- POSITION
-- ==============================================================

local function GetPigPosition(pig)

```
if pig.PrimaryPart then
    return pig.PrimaryPart.Position
end

local root =
    pig:FindFirstChild("HumanoidRootPart")
    or pig:FindFirstChild("RootPart")
    or pig:FindFirstChildWhichIsA(
        "BasePart",
        true
    )

if root then
    return root.Position
end

return nil
```

end

-- ==============================================================
-- TARGET SEARCH
-- ==============================================================

local function FindBestTarget()

```
if not FolderKandang then
    FolderKandang =
        Workspace:FindFirstChild(
            TARGET_FOLDER_NAME
        )
end

if not FolderKandang then
    return nil
end

local root = GetRoot()

if not root then
    return nil
end

local bestPig = nil
local bestDistance = math.huge

for _, pig in ipairs(
    FolderKandang:GetChildren()
) do

    if pig:IsA("Model")
        and IsTargetPig(pig)
        and IsOldEnough(pig)
        and IsAdult(pig)
    then

        local position =
            GetPigPosition(pig)

        if position then

            local distance =
                (root.Position - position).Magnitude

            if distance < bestDistance then

                bestDistance = distance
                bestPig = pig

            end
        end
    end
end

return bestPig
```

end

-- ==============================================================
-- TARGET LOCK
-- ==============================================================

local function IsTargetStillValid(target)

```
if not target then
    return false
end

if not target.Parent then
    return false
end

if not IsTargetPig(target) then
    return false
end

if not IsOldEnough(target) then
    return false
end

if not IsAdult(target) then
    return false
end

return true
```

end

-- ==============================================================
-- FIND BAwa PROMPT
-- ==============================================================

local function FindBawaPrompt(target)

```
if not target then
    return nil
end

for _, obj in ipairs(
    target:GetDescendants()
) do

    if obj:IsA("ProximityPrompt") then

        local actionText =
            string.lower(
                obj.ActionText or ""
            )

        local objectText =
            string.lower(
                obj.ObjectText or ""
            )

        if string.find(
            actionText,
            "bawa",
            1,
            true
        )
        or string.find(
            objectText,
            "bawa",
            1,
            true
        )
        then

            return obj
        end
    end
end

return nil
```

end

-- ==============================================================
-- TELEPORT
-- ==============================================================

local function TeleportNearTarget(target)

```
local root = GetRoot()
local position =
    GetPigPosition(target)

if not root or not position then
    return false
end

root.CFrame =
    CFrame.new(
        position
            + Vector3.new(
                0,
                0,
                TELEPORT_DISTANCE
            ),
        position
    )

task.wait(0.2)

local newRoot = GetRoot()

if not newRoot then
    return false
end

return (
    newRoot.Position - position
).Magnitude <= PROMPT_DISTANCE
```

end

-- ==============================================================
-- PROCESS TARGET
-- ==============================================================

local function ProcessTarget(target)

```
if Busy then
    return
end

Busy = true

CurrentTarget = target
SetTarget(target)

if not IsTargetStillValid(target) then

    SetStatus(
        "TARGET INVALID",
        Color3.fromRGB(255, 100, 100)
    )

    CurrentTarget = nil
    SetTarget(nil)

    Busy = false
    return
end

SetStatus(
    "TARGET LOCKED",
    Color3.fromRGB(255, 220, 80)
)

if not TeleportNearTarget(target) then

    SetStatus(
        "TELEPORT FAILED",
        Color3.fromRGB(255, 100, 100)
    )

    CurrentTarget = nil
    SetTarget(nil)

    Busy = false
    return
end

-- Jangan pernah menerima target lain
-- setelah target dikunci.
if CurrentTarget ~= target then
    Busy = false
    return
end

if not IsTargetStillValid(target) then

    SetStatus(
        "TARGET CHANGED",
        Color3.fromRGB(255, 100, 100)
    )

    CurrentTarget = nil
    SetTarget(nil)

    Busy = false
    return
end

local prompt =
    FindBawaPrompt(target)

if not prompt then

    SetStatus(
        "BAWA PROMPT NOT FOUND",
        Color3.fromRGB(255, 170, 70)
    )

    CurrentTarget = nil
    SetTarget(nil)

    Busy = false
    return
end

-- Proteksi anti salah target.
if not prompt:IsDescendantOf(target) then

    SetStatus(
        "WRONG PROMPT BLOCKED",
        Color3.fromRGB(255, 80, 80)
    )

    CurrentTarget = nil
    SetTarget(nil)

    Busy = false
    return
end

if not prompt.Enabled then

    SetStatus(
        "BAWA DISABLED",
        Color3.fromRGB(255, 170, 70)
    )

    CurrentTarget = nil
    SetTarget(nil)

    Busy = false
    return
end

SetStatus(
    "READY - HOLD E "
    .. string.format(
        "%.2f",
        prompt.HoldDuration
    )
    .. "s",
    Color3.fromRGB(80, 220, 255)
)

print(
    "[Babi Manager V8] Target:",
    target:GetFullName()
)

print(
    "[Babi Manager V8] Minimum age:",
    MinimumAgeMinutes,
    "minutes"
)

print(
    "[Babi Manager V8] Prompt:",
    prompt:GetFullName()
)

print(
    "[Babi Manager V8] HoldDuration:",
    prompt.HoldDuration
)

SetStatus(
    "BAWA PROMPT READY",
    Color3.fromRGB(80, 255, 100)
)

Busy = false
```

end

-- ==============================================================
-- MAIN LOOP
-- ==============================================================

task.spawn(function()

```
while ScreenGui.Parent do

    task.wait(SCAN_INTERVAL)

    if not AutoPickupActive then
        continue
    end

    if Busy then
        continue
    end

    if CurrentTarget then

        if IsTargetStillValid(
            CurrentTarget
        ) then
            continue
        end

        CurrentTarget = nil
        SetTarget(nil)
    end

    local target =
        FindBestTarget()

    if target then

        task.spawn(function()
            ProcessTarget(target)
        end)

    else

        SetStatus(
            "NO BABI >= "
            .. tostring(
                MinimumAgeMinutes
            )
            .. " MIN",
            Color3.fromRGB(
                180,
                180,
                180
            )
        )
    end
end
```

end)

-- ==============================================================
-- INITIAL STATE
-- ==============================================================

AgeInfoLabel.Text =
"Target minimum: "
.. tostring(MinimumAgeMinutes)
.. " menit"

print("[Babi Manager V8] Loaded.")
print(
"[Babi Manager V8] Minimum age:",
MinimumAgeMinutes,
"minutes"
)
print(
"[Babi Manager V8] Target:",
TARGET_NAME
)
print(
"[Babi Manager V8] Target lock: ENABLED"
)
print(
"[Babi Manager V8] Custom age setting: ENABLED"
)
print(
"[Babi Manager V8] Wrong-prompt protection: ENABLED"
)
