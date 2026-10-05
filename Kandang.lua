```lua
--==============================================================
-- BABI MANAGER
-- FULL UPDATED VERSION
--
-- PASANG SEBAGAI:
-- StarterPlayer
--   > StarterPlayerScripts
--      > LocalScript
--
-- SUMBER DATA:
-- ReplicatedStorage
--   > RemoteRegistry
--      > Remotes
--         > BabiBandar
--
-- TARGET:
-- Workspace
--   > KandangBabi_<PlayerID>
--      > Babi_<ID>
--         > modelbabi
--            > ProximityPrompt
--               ActionText = "Bawa"
--
-- UMUR:
-- data.progres * 1440 = menit
--
-- BabiConfig:
-- HariSampaiDewasa = 0.020833333333333336
-- = 30 menit nyata
--==============================================================

if not game:IsLoaded() then
    game.Loaded:Wait()
end

--==============================================================
-- SERVICES
--==============================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

--==============================================================
-- CONFIG
--==============================================================

local DEFAULT_MIN_AGE = 60
local MIN_ALLOWED_AGE = 1
local MAX_ALLOWED_AGE = 100000

local REFRESH_INTERVAL = 2
local TARGET_SCAN_INTERVAL = 0.5
local PICKUP_INTERVAL = 0.35

local PROMPT_ACTION = "Bawa"
local MODEL_TARGET = "modelbabi"

--==============================================================
-- STATE
--==============================================================

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

--==============================================================
-- REMOVE OLD UI
--==============================================================

local oldGui = PlayerGui:FindFirstChild("BabiManager")
if oldGui then
    oldGui:Destroy()
end

--==============================================================
-- FIND BABIBANDAR
--==============================================================

local function FindBabiBandar()

    local remoteRegistry =
        ReplicatedStorage:FindFirstChild("RemoteRegistry")

    if not remoteRegistry then
        return nil
    end

    local remotesFolder = nil

    -- RemoteRegistry biasanya ModuleScript.
    -- Kita coba gunakan API folder("Remotes").
    if remoteRegistry:IsA("ModuleScript") then

        local ok, registry = pcall(function()
            return require(remoteRegistry)
        end)

        if ok and type(registry) == "table" then

            if type(registry.folder) == "function" then
                local okFolder, folder =
                    pcall(function()
                        return registry.folder("Remotes")
                    end)

                if okFolder and folder then
                    remotesFolder = folder
                end
            end
        end
    end

    -- Fallback jika Remotes terlihat sebagai child biasa.
    if not remotesFolder then
        remotesFolder =
            remoteRegistry:FindFirstChild("Remotes")
    end

    if not remotesFolder then
        return nil
    end

    local BabiBandar =
        remotesFolder:FindFirstChild("BabiBandar")

    if BabiBandar then
        return BabiBandar
    end

    -- Fallback descendant search.
    for _, obj in ipairs(remotesFolder:GetDescendants()) do
        if obj.Name == "BabiBandar" then
            return obj
        end
    end

    return nil
end

local BabiBandar = FindBabiBandar()

--==============================================================
-- BABI CONFIG
--==============================================================

local BabiConfig = nil

pcall(function()
    BabiConfig =
        require(
            ReplicatedStorage:WaitForChild("BabiConfig")
        )
end)

--==============================================================
-- AGE FUNCTIONS
--==============================================================

local function GetAgeMinutes(data)

    if type(data) ~= "table" then
        return nil
    end

    local progres =
        tonumber(data.progres)

    if not progres then
        return nil
    end

    -- progres = hari game
    -- 1 hari = 1440 menit

    return progres * 1440
end

local function IsAdult(data)

    if type(data) ~= "table" then
        return false
    end

    if data.dewasa == true then
        return true
    end

    local age = GetAgeMinutes(data)

    if not age then
        return false
    end

    -- BabiConfig:
    -- HariSampaiDewasa = 0.020833333333333336
    -- = 30 menit

    local adultMinutes = 30

    if BabiConfig then

        local threshold =
            tonumber(BabiConfig.HariSampaiDewasa)

        if threshold then
            adultMinutes = threshold * 1440
        end
    end

    return age >= adultMinutes
end

--==============================================================
-- FORMAT AGE
--==============================================================

local function FormatAge(minutes)

    if not minutes then
        return "NONE"
    end

    minutes = math.max(0, minutes)

    if minutes < 1 then
        return string.format("%.1f menit", minutes)
    end

    if minutes < 60 then
        return string.format(
            "%d menit",
            math.floor(minutes + 0.5)
        )
    end

    local hours = math.floor(minutes / 60)
    local mins = math.floor(minutes % 60)

    if mins == 0 then
        return string.format("%d jam", hours)
    end

    return string.format(
        "%d jam %d menit",
        hours,
        mins
    )
end

--==============================================================
-- GET SERVER INFO
--==============================================================

local function GetServerInfo()

    if not BabiBandar then
        BabiBandar = FindBabiBandar()
    end

    if not BabiBandar then
        return nil, "BabiBandar tidak ditemukan"
    end

    if not BabiBandar:IsA("RemoteFunction") then
        return nil,
            "BabiBandar bukan RemoteFunction"
    end

    local success, result =
        pcall(function()
            return BabiBandar:InvokeServer("info")
        end)

    if not success then
        return nil, tostring(result)
    end

    if type(result) ~= "table" then
        return nil, "Result bukan table"
    end

    if result.ok ~= true then
        return nil, "Result.ok = false"
    end

    return result, nil
end

--==============================================================
-- REFRESH SERVER DATA
--==============================================================

local function RefreshServerData()

    local result, errorMessage =
        GetServerInfo()

    if not result then
        return false, errorMessage
    end

    ServerData = result
    LastRefresh = os.clock()

    return true, nil
end

--==============================================================
-- FIND DATA BY ID
--==============================================================

local function FindTernakById(id)

    if not ServerData then
        return nil
    end

    local ternak = ServerData.ternak

    if type(ternak) ~= "table" then
        return nil
    end

    local wantedId =
        string.lower(tostring(id))

    --==========================================================
    -- NORMAL ARRAY
    --==========================================================

    for _, data in ipairs(ternak) do

        if type(data) == "table" then

            local dataId = data.id

            if dataId ~= nil then

                if string.lower(tostring(dataId))
                    == wantedId then

                    return data
                end
            end
        end
    end

    --==========================================================
    -- DICTIONARY FALLBACK
    --==========================================================

    for key, data in pairs(ternak) do

        if type(data) == "table" then

            if string.lower(tostring(key))
                == wantedId then

                return data
            end

            if data.id ~= nil then

                if string.lower(tostring(data.id))
                    == wantedId then

                    return data
                end
            end
        end
    end

    return nil
end

--==============================================================
-- GET PLAYER KANDANG
--==============================================================

local function FindPlayerKandang()

    local wanted =
        "kandangbabi_"
        .. tostring(LocalPlayer.UserId)

    -- First: exact expected name.
    local exact =
        workspace:FindFirstChild(wanted)

    if exact then
        return exact
    end

    -- Fallback case-insensitive.
    local wantedLower =
        string.lower(wanted)

    for _, obj in ipairs(workspace:GetChildren()) do

        if string.lower(obj.Name)
            == wantedLower then

            return obj
        end
    end

    -- Last fallback: descendants.
    for _, obj in ipairs(workspace:GetDescendants()) do

        if string.lower(obj.Name)
            == wantedLower then

            return obj
        end
    end

    return nil
end

--==============================================================
-- EXTRACT BABI ID
--==============================================================

local function GetBabiIdFromObject(obj)

    if not obj then
        return nil
    end

    local id =
        string.match(
            obj.Name,
            "^Babi_(.+)$"
        )

    return id
end

--==============================================================
-- FIND MODELBABI
--==============================================================

local function FindModelBabi(babiObject)

    if not babiObject then
        return nil
    end

    -- Exact expected child.
    local exact =
        babiObject:FindFirstChild(
            MODEL_TARGET
        )

    if exact then
        return exact
    end

    -- Case-insensitive fallback.
    for _, child in ipairs(
        babiObject:GetChildren()
    ) do

        if string.lower(child.Name)
            == MODEL_TARGET then

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

    for _, obj in ipairs(
        modelBabi:GetDescendants()
    ) do

        if obj:IsA("ProximityPrompt") then

            local action =
                string.lower(
                    tostring(obj.ActionText or "")
                )

            if action == string.lower(PROMPT_ACTION) then
                return obj
            end
        end
    end

    return nil
end

--==============================================================
-- FIND ALL BABI IN PLAYER KANDANG
--==============================================================

local function GetAllPlayerBabi()

    local kandang =
        FindPlayerKandang()

    if not kandang then
        return {}
    end

    local result = {}

    for _, obj in ipairs(
        kandang:GetDescendants()
    ) do

        if obj:IsA("Model")
            or obj:IsA("Folder") then

            local id =
                GetBabiIdFromObject(obj)

            if id then

                -- Must contain modelbabi.
                local modelBabi =
                    FindModelBabi(obj)

                if modelBabi then

                    local prompt =
                        FindBawaPrompt(modelBabi)

                    if prompt then

                        table.insert(result, {
                            object = obj,
                            id = id,
                            model = modelBabi,
                            prompt = prompt
                        })

                    end
                end
            end
        end
    end

    return result
end

--==============================================================
-- TARGET VALIDATION
--==============================================================

local function IsTargetStillValid()

    if not CurrentTarget then
        return false
    end

    if not CurrentTarget.Parent then
        return false
    end

    local id =
        GetBabiIdFromObject(CurrentTarget)

    if not id then
        return false
    end

    local model =
        FindModelBabi(CurrentTarget)

    if not model then
        return false
    end

    local prompt =
        FindBawaPrompt(model)

    if not prompt then
        return false
    end

    return true
end

--==============================================================
-- FIND BEST TARGET
--==============================================================

local function FindBestTarget()

    local candidates =
        GetAllPlayerBabi()

    local bestObject = nil
    local bestData = nil
    local bestAge = nil

    for _, candidate in ipairs(candidates) do

        local data =
            FindTernakById(candidate.id)

        if data then

            local age =
                GetAgeMinutes(data)

            if age then

                --==================================================
                -- AGE FILTER
                --==================================================

                if age >= MinAge then

                    -- Jangan pilih babi terkunci.
                    if data.kunci ~= true then

                        -- Jangan pilih babi bunting.
                        if data.bunting ~= true then

                            -- Hanya jenis ternak.
                            if data.jenis == "ternak"
                                or data.jenis == nil then

                                if not bestAge
                                    or age > bestAge then

                                    bestObject =
                                        candidate.object

                                    bestData = data
                                    bestAge = age
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    return bestObject, bestData, bestAge
end

--==============================================================
-- PICK TARGET
--==============================================================

local function UpdateTarget()

    --==========================================================
    -- TARGET LOCK
    --==========================================================

    if TargetLock
        and CurrentTarget
        and IsTargetStillValid() then

        local id =
            GetBabiIdFromObject(CurrentTarget)

        local data =
            FindTernakById(id)

        if data then

            local age =
                GetAgeMinutes(data)

            if age
                and age >= MinAge
                and data.kunci ~= true
                and data.bunting ~= true then

                CurrentTargetData = data
                CurrentTargetAge = age

                return
            end
        end
    end

    --==========================================================
    -- FIND NEW TARGET
    --==========================================================

    local object, data, age =
        FindBestTarget()

    CurrentTarget = object
    CurrentTargetData = data
    CurrentTargetAge = age
end

--==============================================================
-- GET TARGET PROMPT
--==============================================================

local function GetCurrentPrompt()

    if not CurrentTarget then
        return nil
    end

    local model =
        FindModelBabi(CurrentTarget)

    if not model then
        return nil
    end

    return FindBawaPrompt(model)
end

--==============================================================
-- AUTO PICKUP
--==============================================================

local function TryAutoPickup()

    if not AutoPickup then
        return
    end

    if Busy then
        return
    end

    if not CurrentTarget then
        return
    end

    if os.clock() - LastPickup
        < PICKUP_INTERVAL then

        return
    end

    local prompt =
        GetCurrentPrompt()

    if not prompt then
        return
    end

    --==========================================================
    -- CHECK PROMPT
    --==========================================================

    if not prompt.Enabled then
        return
    end

    local character =
        LocalPlayer.Character

    if not character then
        return
    end

    local root =
        character:FindFirstChild(
            "HumanoidRootPart"
        )

    if not root then
        return
    end

    local promptParent =
        prompt.Parent

    if not promptParent then
        return
    end

    local targetPart = nil

    if promptParent:IsA("BasePart") then
        targetPart = promptParent
    else
        targetPart =
            promptParent:FindFirstChildWhichIsA(
                "BasePart",
                true
            )
    end

    if not targetPart then
        return
    end

    local distance =
        (root.Position - targetPart.Position).Magnitude

    --==========================================================
    -- JANGAN MEMAKSA INTERAKSI DARI JARAK JAUH
    --==========================================================

    local maxDistance =
        tonumber(prompt.MaxActivationDistance)
        or 10

    if distance > maxDistance + 1 then
        return
    end

    LastPickup = os.clock()

    Busy = true

    --==========================================================
    -- TRIGGER PROXIMITY PROMPT
    --
    -- Server tetap memvalidasi interaksi.
    -- Jika game menggunakan HoldDuration,
    -- InputHoldBegin/End akan mengikuti mekanisme prompt.
    --==========================================================

    pcall(function()

        if prompt.HoldDuration
            and prompt.HoldDuration > 0 then

            prompt:InputHoldBegin()

            task.wait(
                prompt.HoldDuration + 0.08
            )

            prompt:InputHoldEnd()

        else

            prompt:InputHoldBegin()
            task.wait(0.08)
            prompt:InputHoldEnd()

        end

    end)

    task.delay(0.2, function()
        Busy = false
    end)
end

--==============================================================
-- UI
--==============================================================

local Gui =
    Instance.new("ScreenGui")

Gui.Name = "BabiManager"
Gui.ResetOnSpawn = false
Gui.IgnoreGuiInset = false
Gui.ZIndexBehavior =
    Enum.ZIndexBehavior.Sibling

Gui.Parent = PlayerGui

--==============================================================
-- MAIN FRAME
--==============================================================

local Main =
    Instance.new("Frame")

Main.Name = "Main"
Main.Size =
    UDim2.new(0, 360, 0, 300)

Main.Position =
    UDim2.new(
        0,
        20,
        0.5,
        -150
    )

Main.BackgroundColor3 =
    Color3.fromRGB(
        25,
        25,
        25
    )

Main.BorderSizePixel = 0
Main.Parent = Gui

local MainCorner =
    Instance.new("UICorner")

MainCorner.CornerRadius =
    UDim.new(0, 10)

MainCorner.Parent = Main

--==============================================================
-- TITLE
--==============================================================

local Title =
    Instance.new("TextLabel")

Title.Size =
    UDim2.new(1, -20, 0, 40)

Title.Position =
    UDim2.new(0, 10, 0, 5)

Title.BackgroundTransparency = 1

Title.Text =
    "BABI MANAGER"

Title.TextColor3 =
    Color3.fromRGB(
        255,
        255,
        255
    )

Title.TextSize = 20
Title.Font =
    Enum.Font.GothamBold

Title.TextXAlignment =
    Enum.TextXAlignment.Left

Title.Parent = Main

--==============================================================
-- MIN AGE LABEL
--==============================================================

local AgeLabel =
    Instance.new("TextLabel")

AgeLabel.Size =
    UDim2.new(0, 120, 0, 30)

AgeLabel.Position =
    UDim2.new(0, 15, 0, 52)

AgeLabel.BackgroundTransparency = 1

AgeLabel.Text =
    "MIN AGE"

AgeLabel.TextColor3 =
    Color3.fromRGB(
        220,
        220,
        220
    )

AgeLabel.TextSize = 14
AgeLabel.Font =
    Enum.Font.GothamBold

AgeLabel.TextXAlignment =
    Enum.TextXAlignment.Left

AgeLabel.Parent = Main

--==============================================================
-- AGE BOX
--==============================================================

local AgeBox =
    Instance.new("TextBox")

AgeBox.Size =
    UDim2.new(0, 100, 0, 32)

AgeBox.Position =
    UDim2.new(0, 125, 0, 50)

AgeBox.BackgroundColor3 =
    Color3.fromRGB(
        45,
        45,
        45
    )

AgeBox.BorderSizePixel = 0

AgeBox.Text =
    tostring(DEFAULT_MIN_AGE)

AgeBox.TextColor3 =
    Color3.fromRGB(
        255,
        255,
        255
    )

AgeBox.TextSize = 15
AgeBox.Font =
    Enum.Font.Gotham

AgeBox.ClearTextOnFocus = false

AgeBox.Parent = Main

local AgeCorner =
    Instance.new("UICorner")

AgeCorner.CornerRadius =
    UDim.new(0, 6)

AgeCorner.Parent = AgeBox

--==============================================================
-- MINUTES LABEL
--==============================================================

local MinuteLabel =
    Instance.new("TextLabel")

MinuteLabel.Size =
    UDim2.new(0, 80, 0, 30)

MinuteLabel.Position =
    UDim2.new(0, 235, 0, 52)

MinuteLabel.BackgroundTransparency = 1

MinuteLabel.Text =
    "menit"

MinuteLabel.TextColor3 =
    Color3.fromRGB(
        180,
        180,
        180
    )

MinuteLabel.TextSize = 13
MinuteLabel.Font =
    Enum.Font.Gotham

MinuteLabel.TextXAlignment =
    Enum.TextXAlignment.Left

MinuteLabel.Parent = Main

--==============================================================
-- AGE BOX COMMIT
--==============================================================

local function ApplyAge()

    local value =
        tonumber(
            AgeBox.Text
        )

    if not value then

        AgeBox.Text =
            tostring(MinAge)

        return
    end

    value =
        math.floor(value)

    value =
        math.clamp(
            value,
            MIN_ALLOWED_AGE,
            MAX_ALLOWED_AGE
        )

    MinAge = value

    AgeBox.Text =
        tostring(MinAge)

    -- Kalau setting umur berubah,
    -- target lama harus dievaluasi lagi.

    CurrentTarget = nil
    CurrentTargetData = nil
    CurrentTargetAge = nil

    UpdateTarget()
end

AgeBox.FocusLost:Connect(
    function()
        ApplyAge()
    end
)

AgeBox:GetPropertyChangedSignal(
    "Text"
):Connect(function()

    -- Jangan langsung mengubah MinAge
    -- saat user masih mengetik.

end)

--==============================================================
-- STATUS LABEL
--==============================================================

local Status =
    Instance.new("TextLabel")

Status.Size =
    UDim2.new(1, -30, 0, 28)

Status.Position =
    UDim2.new(0, 15, 0, 95)

Status.BackgroundTransparency = 1

Status.Text =
    "STATUS: MEMUAT..."

Status.TextColor3 =
    Color3.fromRGB(
        180,
        180,
        180
    )

Status.TextSize = 13
Status.Font =
    Enum.Font.Gotham

Status.TextXAlignment =
    Enum.TextXAlignment.Left

Status.Parent = Main

--==============================================================
-- TARGET LABEL
--==============================================================

local TargetLabel =
    Instance.new("TextLabel")

TargetLabel.Size =
    UDim2.new(1, -30, 0, 28)

TargetLabel.Position =
    UDim2.new(0, 15, 0, 125)

TargetLabel.BackgroundTransparency = 1

TargetLabel.Text =
    "TARGET: NONE"

TargetLabel.TextColor3 =
    Color3.fromRGB(
        255,
        255,
        255
    )

TargetLabel.TextSize = 13
TargetLabel.Font =
    Enum.Font.GothamBold

TargetLabel.TextXAlignment =
    Enum.TextXAlignment.Left

TargetLabel.Parent = Main

--==============================================================
-- AGE STATUS
--==============================================================

local TargetAgeLabel =
    Instance.new("TextLabel")

TargetAgeLabel.Size =
    UDim2.new(1, -30, 0, 25)

TargetAgeLabel.Position =
    UDim2.new(0, 15, 0, 153)

TargetAgeLabel.BackgroundTransparency = 1

TargetAgeLabel.Text =
    "UMUR: NONE"

TargetAgeLabel.TextColor3 =
    Color3.fromRGB(
        200,
        200,
        200
    )

TargetAgeLabel.TextSize = 13
TargetAgeLabel.Font =
    Enum.Font.Gotham

TargetAgeLabel.TextXAlignment =
    Enum.TextXAlignment.Left

TargetAgeLabel.Parent = Main

--==============================================================
-- AUTO PICKUP BUTTON
--==============================================================

local AutoButton =
    Instance.new("TextButton")

AutoButton.Size =
    UDim2.new(1, -30, 0, 38)

AutoButton.Position =
    UDim2.new(0, 15, 0, 190)

AutoButton.BackgroundColor3 =
    Color3.fromRGB(
        55,
        55,
        55
    )

AutoButton.BorderSizePixel = 0

AutoButton.TextColor3 =
    Color3.fromRGB(
        255,
        255,
        255
    )

AutoButton.TextSize = 14
AutoButton.Font =
    Enum.Font.GothamBold

AutoButton.Parent = Main

local AutoCorner =
    Instance.new("UICorner")

AutoCorner.CornerRadius =
    UDim.new(0, 7)

AutoCorner.Parent = AutoButton

--==============================================================
-- TARGET LOCK BUTTON
--==============================================================

local LockButton =
    Instance.new("TextButton")

LockButton.Size =
    UDim2.new(1, -30, 0, 38)

LockButton.Position =
    UDim2.new(0, 15, 0, 235)

LockButton.BackgroundColor3 =
    Color3.fromRGB(
        55,
        55,
        55
    )

LockButton.BorderSizePixel = 0

LockButton.TextColor3 =
    Color3.fromRGB(
        255,
        255,
        255
    )

LockButton.TextSize = 14
LockButton.Font =
    Enum.Font.GothamBold

LockButton.Parent = Main

local LockCorner =
    Instance.new("UICorner")

LockCorner.CornerRadius =
    UDim.new(0, 7)

LockCorner.Parent = LockButton

--==============================================================
-- UPDATE BUTTON TEXT
--==============================================================

local function UpdateButtons()

    if AutoPickup then

        AutoButton.Text =
            "AUTO PICKUP : ON"

        AutoButton.BackgroundColor3 =
            Color3.fromRGB(
                55,
                120,
                65
            )

    else

        AutoButton.Text =
            "AUTO PICKUP : OFF"

        AutoButton.BackgroundColor3 =
            Color3.fromRGB(
                55,
                55,
                55
            )

    end

    if TargetLock then

        LockButton.Text =
            "TARGET LOCK : ON"

        LockButton.BackgroundColor3 =
            Color3.fromRGB(
                70,
                90,
                125
            )

    else

        LockButton.Text =
            "TARGET LOCK : OFF"

        LockButton.BackgroundColor3 =
            Color3.fromRGB(
                55,
                55,
                55
            )

    end
end

AutoButton.MouseButton1Click:Connect(
    function()

        AutoPickup =
            not AutoPickup

        UpdateButtons()
    end
)

LockButton.MouseButton1Click:Connect(
    function()

        TargetLock =
            not TargetLock

        if not TargetLock then

            CurrentTarget = nil
            CurrentTargetData = nil
            CurrentTargetAge = nil

        end

        UpdateButtons()
    end
)

UpdateButtons()

--==============================================================
-- UPDATE UI
--==============================================================

local function UpdateUI()

    --==========================================================
    -- SERVER STATUS
    --==========================================================

    if not BabiBandar then

        Status.Text =
            "SERVER: BABIBANDAR TIDAK DITEMUKAN"

        Status.TextColor3 =
            Color3.fromRGB(
                230,
                90,
                90
            )

    elseif not ServerData then

        Status.Text =
            "SERVER: DATA BELUM TERSEDIA"

        Status.TextColor3 =
            Color3.fromRGB(
                230,
                180,
                70
            )

    else

        local count = 0

        if type(ServerData.ternak)
            == "table" then

            for _, data in pairs(
                ServerData.ternak
            ) do

                if type(data) == "table" then
                    count += 1
                end
            end
        end

        Status.Text =
            "SERVER: OK | TERNAK: "
            .. tostring(count)

        Status.TextColor3 =
            Color3.fromRGB(
                100,
                210,
                120
            )
    end

    --==========================================================
    -- TARGET
    --==========================================================

    if CurrentTarget
        and CurrentTarget.Parent then

        local id =
            GetBabiIdFromObject(
                CurrentTarget
            )

        TargetLabel.Text =
            "TARGET: Babi_"
            .. tostring(id or "?")

        if CurrentTargetAge then

            TargetAgeLabel.Text =
                "UMUR: "
                .. FormatAge(
                    CurrentTargetAge
                )

                .. " | MIN: "
                .. tostring(MinAge)
                .. " menit"

        else

            TargetAgeLabel.Text =
                "UMUR: NONE"

        end

    else

        TargetLabel.Text =
            "TARGET: NONE"

        TargetAgeLabel.Text =
            "UMUR: NONE | MIN: "
            .. tostring(MinAge)
            .. " menit"
    end
end

--==============================================================
-- REFRESH LOOP
--==============================================================

task.spawn(function()

    while Gui.Parent do

        local success, errorMessage =
            RefreshServerData()

        if not success then

            -- Jangan spam error.
            -- UI akan menunjukkan status.

        else

            UpdateTarget()
            UpdateUI()

        end

        task.wait(
            REFRESH_INTERVAL
        )
    end
end)

--==============================================================
-- TARGET SCAN LOOP
--==============================================================

task.spawn(function()

    while Gui.Parent do

        if os.clock() - LastTargetScan
            >= TARGET_SCAN_INTERVAL then

            LastTargetScan =
                os.clock()

            -- Jika target hilang,
            -- segera cari pengganti.

            if not IsTargetStillValid() then

                CurrentTarget = nil
                CurrentTargetData = nil
                CurrentTargetAge = nil

                UpdateTarget()

            else

                -- Jika target lock aktif,
                -- perbarui umur datanya.

                if CurrentTarget then

                    local id =
                        GetBabiIdFromObject(
                            CurrentTarget
                        )

                    local data =
                        FindTernakById(id)

                    if data then

                        local age =
                            GetAgeMinutes(data)

                        CurrentTargetData =
                            data

                        CurrentTargetAge =
                            age

                        -- Jika sudah tidak memenuhi
                        -- MIN AGE, cari target baru.

                        if not age
                            or age < MinAge
                            or data.kunci == true
                            or data.bunting == true then

                            CurrentTarget = nil
                            CurrentTargetData = nil
                            CurrentTargetAge = nil

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

--==============================================================
-- AUTO PICKUP LOOP
--==============================================================

task.spawn(function()

    while Gui.Parent do

        if AutoPickup then

            pcall(function()
                TryAutoPickup()
            end)

        end

        task.wait(0.1)
    end
end)

--==============================================================
-- CHARACTER RESPAWN
--==============================================================

LocalPlayer.CharacterAdded:Connect(
    function()

        task.wait(1)

        Busy = false

        -- Target tetap dipertahankan jika
        -- masih valid dan Target Lock ON.

        if not TargetLock then

            CurrentTarget = nil
            CurrentTargetData = nil
            CurrentTargetAge = nil

        end

        UpdateUI()
    end
)

--==============================================================
-- INITIAL LOAD
--==============================================================

task.spawn(function()

    task.wait(1)

    local success =
        RefreshServerData()

    if success then
        UpdateTarget()
    end

    UpdateUI()
end)

--==============================================================
-- DEBUG OUTPUT
--==============================================================

print(
    "[BABI MANAGER] Loaded"
)

print(
    "[BABI MANAGER] BabiBandar:",
    BabiBandar
        and BabiBandar:GetFullName()
        or "NOT FOUND"
)

print(
    "[BABI MANAGER] Min Age:",
    MinAge,
    "minutes"
)

print(
    "[BABI MANAGER] Target Model:",
    MODEL_TARGET
)

print(
    "[BABI MANAGER] Prompt:",
    PROMPT_ACTION
)

--==============================================================
-- END
--==============================================================
```
