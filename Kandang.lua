--==============================================================
-- BABI MANAGER - PART 1
-- FULL EXECUTOR COMPATIBLE
--==============================================================

if not game:IsLoaded() then
    game.Loaded:Wait()
end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local DEFAULT_MIN_AGE = 60
local MIN_ALLOWED_AGE = 1
local MAX_ALLOWED_AGE = 100000

local REFRESH_INTERVAL = 2
local TARGET_SCAN_INTERVAL = 0.5
local PICKUP_INTERVAL = 0.35

local PROMPT_ACTION = "Bawa"
local MODEL_TARGET = "modelbabi"

local MinAge = DEFAULT_MIN_AGE
local AutoPickup = false
local TargetLock = true

local CurrentTarget = nil
local CurrentTargetData = nil
local CurrentTargetAge = nil

local ServerData = nil
local LastRefresh = 0
local LastTargetScan = 0
local LastPickup = 0
local Busy = false

local oldGui = PlayerGui:FindFirstChild("BabiManager")
if oldGui then oldGui:Destroy() end

local function FindBabiBandar()
    local remoteRegistry = ReplicatedStorage:FindFirstChild("RemoteRegistry")
    if not remoteRegistry then return nil end
    local remotesFolder = nil
    if remoteRegistry:IsA("ModuleScript") then
        local ok, registry = pcall(function() return require(remoteRegistry) end)
        if ok and type(registry) == "table" then
            if type(registry.folder) == "function" then
                local okFolder, folder = pcall(function() return registry.folder("Remotes") end)
                if okFolder and folder then remotesFolder = folder end
            end
        end
    end
    if not remotesFolder then remotesFolder = remoteRegistry:FindFirstChild("Remotes") end
    if not remotesFolder then return nil end
    local BabiBandar = remotesFolder:FindFirstChild("BabiBandar")
    if BabiBandar then return BabiBandar end
    for _, obj in ipairs(remotesFolder:GetDescendants()) do
        if obj.Name == "BabiBandar" then return obj end
    end
    return nil
end

local BabiBandar = FindBabiBandar()
local BabiConfig = nil
pcall(function() BabiConfig = require(ReplicatedStorage:WaitForChild("BabiConfig")) end)

local function GetAgeMinutes(data)
    if type(data) ~= "table" then return nil end
    local progres = tonumber(data.progres)
    if not progres then return nil end
    return progres * 1440
end

local function IsAdult(data)
    if type(data) ~= "table" then return false end
    if data.dewasa == true then return true end
    local age = GetAgeMinutes(data)
    if not age then return false end
    local adultMinutes = 30
    if BabiConfig then
        local threshold = tonumber(BabiConfig.HariSampaiDewasa)
        if threshold then adultMinutes = threshold * 1440 end
    end
    return age >= adultMinutes
end

local function FormatAge(minutes)
    if not minutes then return "NONE" end
    minutes = math.max(0, minutes)
    if minutes < 1 then return string.format("%.1f menit", minutes) end
    if minutes < 60 then return string.format("%d menit", math.floor(minutes + 0.5)) end
    local hours = math.floor(minutes / 60)
    local mins = math.floor(minutes % 60)
    if mins == 0 then return string.format("%d jam", hours) end
    return string.format("%d jam %d menit", hours, mins)
end

local function GetServerInfo()
    if not BabiBandar then BabiBandar = FindBabiBandar() end
    if not BabiBandar then return nil, "BabiBandar tidak ditemukan" end
    if not BabiBandar:IsA("RemoteFunction") then return nil, "BabiBandar bukan RemoteFunction" end
    local success, result = pcall(function() return BabiBandar:InvokeServer("info") end)
    if not success then return nil, tostring(result) end
    if type(result) ~= "table" then return nil, "Result bukan table" end
    if result.ok ~= true then return nil, "Result.ok = false" end
    return result, nil
end

local function RefreshServerData()
    local result, errorMessage = GetServerInfo()
    if not result then return false, errorMessage end
    ServerData = result
    LastRefresh = os.clock()
    return true, nil
end

local function FindTernakById(id)
    if not ServerData then return nil end
    local ternak = ServerData.ternak
    if type(ternak) ~= "table" then return nil end
    local wantedId = string.lower(tostring(id))
    for _, data in ipairs(ternak) do
        if type(data) == "table" and data.id ~= nil then
            if string.lower(tostring(data.id)) == wantedId then return data end
        end
    end
    for key, data in pairs(ternak) do
        if type(data) == "table" then
            if string.lower(tostring(key)) == wantedId then return data end
            if data.id ~= nil and string.lower(tostring(data.id)) == wantedId then return data end
        end
    end
    return nil
end
--==============================================================
-- BABI MANAGER - PART 2
--==============================================================

local function FindPlayerKandang()
    local wanted = "kandangbabi_" .. tostring(LocalPlayer.UserId)
    local exact = workspace:FindFirstChild(wanted)
    if exact then return exact end
    local wantedLower = string.lower(wanted)
    for _, obj in ipairs(workspace:GetChildren()) do
        if string.lower(obj.Name) == wantedLower then return obj end
    end
    for _, obj in ipairs(workspace:GetDescendants()) do
        if string.lower(obj.Name) == wantedLower then return obj end
    end
    return nil
end

local function GetBabiIdFromObject(obj)
    if not obj then return nil end
    return string.match(obj.Name, "^Babi_(.+)$")
end

local function FindModelBabi(babiObject)
    if not babiObject then return nil end
    local exact = babiObject:FindFirstChild(MODEL_TARGET)
    if exact then return exact end
    for _, child in ipairs(babiObject:GetChildren()) do
        if string.lower(child.Name) == MODEL_TARGET then return child end
    end
    return nil
end

local function FindBawaPrompt(modelBabi)
    if not modelBabi then return nil end
    for _, obj in ipairs(modelBabi:GetDescendants()) do
        if obj:IsA("ProximityPrompt") then
            local action = string.lower(tostring(obj.ActionText or ""))
            if action == string.lower(PROMPT_ACTION) then return obj end
        end
    end
    return nil
end

local function GetAllPlayerBabi()
    local kandang = FindPlayerKandang()
    if not kandang then return {} end
    local result = {}
    for _, obj in ipairs(kandang:GetDescendants()) do
        if obj:IsA("Model") or obj:IsA("Folder") then
            local id = GetBabiIdFromObject(obj)
            if id then
                local modelBabi = FindModelBabi(obj)
                if modelBabi then
                    local prompt = FindBawaPrompt(modelBabi)
                    if prompt then
                        table.insert(result, {object = obj, id = id, model = modelBabi, prompt = prompt})
                    end
                end
            end
        end
    end
    return result
end

local function IsTargetStillValid()
    if not CurrentTarget or not CurrentTarget.Parent then return false end
    if not GetBabiIdFromObject(CurrentTarget) then return false end
    local model = FindModelBabi(CurrentTarget)
    if not model or not FindBawaPrompt(model) then return false end
    return true
end

local function FindBestTarget()
    local candidates = GetAllPlayerBabi()
    local bestObject, bestData, bestAge = nil, nil, nil
    for _, candidate in ipairs(candidates) do
        local data = FindTernakById(candidate.id)
        if data then
            local age = GetAgeMinutes(data)
            if age and age >= MinAge and data.kunci ~= true and data.bunting ~= true then
                if data.jenis == "ternak" or data.jenis == nil then
                    if not bestAge or age > bestAge then
                        bestObject = candidate.object
                        bestData = data
                        bestAge = age
                    end
                end
            end
        end
    end
    return bestObject, bestData, bestAge
end

local function UpdateTarget()
    if TargetLock and CurrentTarget and IsTargetStillValid() then
        local id = GetBabiIdFromObject(CurrentTarget)
        local data = FindTernakById(id)
        if data then
            local age = GetAgeMinutes(data)
            if age and age >= MinAge and data.kunci ~= true and data.bunting ~= true then
                CurrentTargetData = data
                CurrentTargetAge = age
                return
            end
        end
    end
    local object, data, age = FindBestTarget()
    CurrentTarget = object
    CurrentTargetData = data
    CurrentTargetAge = age
end

local function GetCurrentPrompt()
    if not CurrentTarget then return nil end
    local model = FindModelBabi(CurrentTarget)
    if not model then return nil end
    return FindBawaPrompt(model)
end

local function TryAutoPickup()
    if not AutoPickup or Busy or not CurrentTarget then return end
    if os.clock() - LastPickup < PICKUP_INTERVAL then return end
    local prompt = GetCurrentPrompt()
    if not prompt or not prompt.Enabled then return end
    local character = LocalPlayer.Character
    if not character then return end
    local root = character:FindFirstChild("HumanoidRootPart")
    if not root or not prompt.Parent then return end
    local targetPart = prompt.Parent:IsA("BasePart") and prompt.Parent or prompt.Parent:FindFirstChildWhichIsA("BasePart", true)
    if not targetPart then return end
    local distance = (root.Position - targetPart.Position).Magnitude
    local maxDistance = tonumber(prompt.MaxActivationDistance) or 10
    if distance > maxDistance + 1 then return end
    LastPickup = os.clock()
    Busy = true
    pcall(function()
        if prompt.HoldDuration and prompt.HoldDuration > 0 then
            prompt:InputHoldBegin()
            task.wait(prompt.HoldDuration + 0.08)
            prompt:InputHoldEnd()
        else
            prompt:InputHoldBegin()
            task.wait(0.08)
            prompt:InputHoldEnd()
        end
    end)
    task.delay(0.2, function() Busy = false end)
end
--==============================================================
-- BABI MANAGER - PART 3
--==============================================================

local Gui = Instance.new("ScreenGui")
Gui.Name = "BabiManager"
Gui.ResetOnSpawn = false
Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Gui.Parent = PlayerGui

local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.new(0, 360, 0, 300)
Main.Position = UDim2.new(0, 20, 0.5, -150)
Main.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
Main.BorderSizePixel = 0
Main.Parent = Gui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 10)
MainCorner.Parent = Main

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -20, 0, 40)
Title.Position = UDim2.new(0, 10, 0, 5)
Title.BackgroundTransparency = 1
Title.Text = "BABI MANAGER"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 20
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Main

local AgeLabel = Instance.new("TextLabel")
AgeLabel.Size = UDim2.new(0, 120, 0, 30)
AgeLabel.Position = UDim2.new(0, 15, 0, 52)
AgeLabel.BackgroundTransparency = 1
AgeLabel.Text = "MIN AGE"
AgeLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
AgeLabel.TextSize = 14
AgeLabel.Font = Enum.Font.GothamBold
AgeLabel.TextXAlignment = Enum.TextXAlignment.Left
AgeLabel.Parent = Main

local AgeBox = Instance.new("TextBox")
AgeBox.Size = UDim2.new(0, 100, 0, 32)
AgeBox.Position = UDim2.new(0, 125, 0, 50)
AgeBox.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
AgeBox.BorderSizePixel = 0
AgeBox.Text = tostring(DEFAULT_MIN_AGE)
AgeBox.TextColor3 = Color3.fromRGB(255, 255, 255)
AgeBox.TextSize = 15
AgeBox.Font = Enum.Font.Gotham
AgeBox.ClearTextOnFocus = false
AgeBox.Parent = Main

local AgeCorner = Instance.new("UICorner")
AgeCorner.CornerRadius = UDim.new(0, 6)
AgeCorner.Parent = AgeBox

local MinuteLabel = Instance.new("TextLabel")
MinuteLabel.Size = UDim2.new(0, 80, 0, 30)
MinuteLabel.Position = UDim2.new(0, 235, 0, 52)
MinuteLabel.BackgroundTransparency = 1
MinuteLabel.Text = "menit"
MinuteLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
MinuteLabel.TextSize = 13
MinuteLabel.Font = Enum.Font.Gotham
MinuteLabel.TextXAlignment = Enum.TextXAlignment.Left
MinuteLabel.Parent = Main

local function ApplyAge()
    local value = tonumber(AgeBox.Text)
    if not value then AgeBox.Text = tostring(MinAge) return end
    value = math.clamp(math.floor(value), MIN_ALLOWED_AGE, MAX_ALLOWED_AGE)
    MinAge = value
    AgeBox.Text = tostring(MinAge)
    CurrentTarget, CurrentTargetData, CurrentTargetAge = nil, nil, nil
    UpdateTarget()
end
AgeBox.FocusLost:Connect(ApplyAge)

local Status = Instance.new("TextLabel")
Status.Size = UDim2.new(1, -30, 0, 28)
Status.Position = UDim2.new(0, 15, 0, 95)
Status.BackgroundTransparency = 1
Status.Text = "STATUS: MEMUAT..."
Status.TextColor3 = Color3.fromRGB(180, 180, 180)
Status.TextSize = 13
Status.Font = Enum.Font.Gotham
Status.TextXAlignment = Enum.TextXAlignment.Left
Status.Parent = Main

local TargetLabel = Instance.new("TextLabel")
TargetLabel.Size = UDim2.new(1, -30, 0, 28)
TargetLabel.Position = UDim2.new(0, 15, 0, 125)
TargetLabel.BackgroundTransparency = 1
TargetLabel.Text = "TARGET: NONE"
TargetLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TargetLabel.TextSize = 13
TargetLabel.Font = Enum.Font.GothamBold
TargetLabel.TextXAlignment = Enum.TextXAlignment.Left
TargetLabel.Parent = Main

local TargetAgeLabel = Instance.new("TextLabel")
TargetAgeLabel.Size = UDim2.new(1, -30, 0, 25)
TargetAgeLabel.Position = UDim2.new(0, 15, 0, 153)
TargetAgeLabel.BackgroundTransparency = 1
TargetAgeLabel.Text = "UMUR: NONE"
TargetAgeLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
TargetAgeLabel.TextSize = 13
TargetAgeLabel.Font = Enum.Font.Gotham
TargetAgeLabel.TextXAlignment = Enum.TextXAlignment.Left
TargetAgeLabel.Parent = Main

local AutoButton = Instance.new("TextButton")
AutoButton.Size = UDim2.new(1, -30, 0, 38)
AutoButton.Position = UDim2.new(0, 15, 0, 190)
AutoButton.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
AutoButton.BorderSizePixel = 0
AutoButton.TextColor3 = Color3.fromRGB(255, 255, 255)
AutoButton.TextSize = 14
AutoButton.Font = Enum.Font.GothamBold
AutoButton.Parent = Main
Instance.new("UICorner").CornerRadius = UDim.new(0, 7)
AutoButton.UICorner.Parent = AutoButton

local LockButton = Instance.new("TextButton")
LockButton.Size = UDim2.new(1, -30, 0, 38)
LockButton.Position = UDim2.new(0, 15, 0, 235)
LockButton.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
LockButton.BorderSizePixel = 0
LockButton.TextColor3 = Color3.fromRGB(255, 255, 255)
LockButton.TextSize = 14
LockButton.Font = Enum.Font.GothamBold
LockButton.Parent = Main
Instance.new("UICorner").CornerRadius = UDim.new(0, 7)
LockButton.UICorner.Parent = LockButton

local function UpdateButtons()
    if AutoPickup then
        AutoButton.Text = "AUTO PICKUP : ON"
        AutoButton.BackgroundColor3 = Color3.fromRGB(55, 120, 65)
    else
        AutoButton.Text = "AUTO PICKUP : OFF"
        AutoButton.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
    end
    if TargetLock then
        LockButton.Text = "TARGET LOCK : ON"
        LockButton.BackgroundColor3 = Color3.fromRGB(70, 90, 125)
    else
        LockButton.Text = "TARGET LOCK : OFF"
        LockButton.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
    end
end

AutoButton.MouseButton1Click:Connect(function() AutoPickup = not AutoPickup UpdateButtons() end)
LockButton.MouseButton1Click:Connect(function() TargetLock = not TargetLock if not TargetLock then CurrentTarget, CurrentTargetData, CurrentTargetAge = nil, nil, nil end UpdateButtons() end)
UpdateButtons()

local function UpdateUI()
    if not BabiBandar then
        Status.Text = "SERVER: BABIBANDAR TIDAK DITEMUKAN"
        Status.TextColor3 = Color3.fromRGB(230, 90, 90)
    elseif not ServerData then
        Status.Text = "SERVER: DATA BELUM TERSEDIA"
        Status.TextColor3 = Color3.fromRGB(230, 180, 70)
    else
        local count = 0
        if type(ServerData.ternak) == "table" then
            for _, data in pairs(ServerData.ternak) do if type(data) == "table" then count += 1 end end
        end
        Status.Text = "SERVER: OK | TERNAK: " .. tostring(count)
        Status.TextColor3 = Color3.fromRGB(100, 210, 120)
    end
    if CurrentTarget and CurrentTarget.Parent then
        local id = GetBabiIdFromObject(CurrentTarget)
        TargetLabel.Text = "TARGET: Babi_" .. tostring(id or "?")
        if CurrentTargetAge then
            TargetAgeLabel.Text = "UMUR: " .. FormatAge(CurrentTargetAge) .. " | MIN: " .. tostring(MinAge) .. " menit"
        else
            TargetAgeLabel.Text = "UMUR: NONE"
        end
    else
        TargetLabel.Text = "TARGET: NONE"
        TargetAgeLabel.Text = "UMUR: NONE | MIN: " .. tostring(MinAge) .. " menit"
    end
end

task.spawn(function()
    while true do
        local success, errorMessage = RefreshServerData()
        if success then UpdateTarget() UpdateUI() end
        task.wait(REFRESH_INTERVAL)
    end
end)

task.spawn(function()
    while true do
        if os.clock() - LastTargetScan >= TARGET_SCAN_INTERVAL then
            LastTargetScan = os.clock()
            if not IsTargetStillValid() then
                CurrentTarget, CurrentTargetData, CurrentTargetAge = nil, nil, nil
                UpdateTarget()
            else
                if CurrentTarget then
                    local id = GetBabiIdFromObject(CurrentTarget)
                    local data = FindTernakById(id)
                    if data then
                        local age = GetAgeMinutes(data)
                        CurrentTargetData, CurrentTargetAge = data, age
                        if not age or age < MinAge or data.kunci == true or data.bunting == true then
                            CurrentTarget, CurrentTargetData, CurrentTargetAge = nil, nil, nil
                            UpdateTarget()
                        end
                    end
                end
            end
            UpdateUI()
        end
        task.wait(0.1)
    end
end)

task.spawn(function()
    while true do
        if AutoPickup then pcall(TryAutoPickup) end
        task.wait(0.1)
    end
end)

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    Busy = false
    if not TargetLock then CurrentTarget, CurrentTargetData, CurrentTargetAge = nil, nil, nil end
    UpdateUI()
end)

task.spawn(function()
    task.wait(1)
    if RefreshServerData() then UpdateTarget() end
    UpdateUI()
end)

print("[BABI MANAGER] Loaded")
