--==============================================================
-- BABI MANAGER
-- FULL VERSION - SERVER DATA + DYNAMIC TARGET
--==============================================================
--
-- STRUKTUR TARGET:
--
-- Workspace
-- └── KandangBabi_<PlayerID>
--     ├── Babi_<ID>
--     │   └── modelinduk
--     │
--     ├── Babi_<ID>
--     │   └── modelbabi
--     │       ├── ProximityPrompt (Bawa)
--     │       └── ProximityPrompt (Gosok)
--     │
--     └── ...
--
-- DATA UMUR:
--
-- ReplicatedStorage
-- └── BabiBandar
--       :InvokeServer("info")
--
-- result.ternak
-- ├── id
-- ├── progres
-- ├── umur
-- ├── dewasa
-- └── ...
--
-- progres = hari
-- menit = progres * 1440
--
--==============================================================


--==============================================================
-- GAME LOADED
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


--==============================================================
-- PLAYER
--==============================================================

local LocalPlayer = Players.LocalPlayer

if not LocalPlayer then
    warn("[BABI MANAGER] LocalPlayer tidak ditemukan")
    return
end

local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")


--==============================================================
-- CONFIG
--==============================================================

local DEFAULT_MIN_AGE = 60

local SCAN_INTERVAL = 1

--==============================================================
-- STATE
--==============================================================

local Running = false

local MinimumAgeMinutes = DEFAULT_MIN_AGE

local CurrentTarget = nil

local CurrentTargetData = nil

local BabiBandar = nil

local Busy = false


--==============================================================
-- HAPUS UI LAMA
--==============================================================

local OldUI = PlayerGui:FindFirstChild("BabiManagerUI")

if OldUI then
    OldUI:Destroy()
end


--==============================================================
-- FIND BABIBANDAR
--==============================================================

local function FindBabiBandar()

    local found = ReplicatedStorage:FindFirstChild(
        "BabiBandar",
        true
    )

    if found and found:IsA("RemoteFunction") then
        return found
    end

    return nil
end


BabiBandar = FindBabiBandar()


--==============================================================
-- UI
--==============================================================

local ScreenGui = Instance.new("ScreenGui")

ScreenGui.Name = "BabiManagerUI"

ScreenGui.ResetOnSpawn = false

ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

ScreenGui.Parent = PlayerGui


--==============================================================
-- MAIN
--==============================================================

local Main = Instance.new("Frame")

Main.Name = "Main"

Main.Size = UDim2.new(0, 340, 0, 360)

Main.Position = UDim2.new(
    0,
    20,
    0.5,
    -180
)

Main.BackgroundColor3 = Color3.fromRGB(
    24,
    24,
    24
)

Main.BorderSizePixel = 0

Main.Parent = ScreenGui


local MainCorner = Instance.new("UICorner")

MainCorner.CornerRadius = UDim.new(
    0,
    10
)

MainCorner.Parent = Main


local MainStroke = Instance.new("UIStroke")

MainStroke.Thickness = 1

MainStroke.Color = Color3.fromRGB(
    80,
    80,
    80
)

MainStroke.Parent = Main


--==============================================================
-- TITLE
--==============================================================

local Title = Instance.new("TextLabel")

Title.Name = "Title"

Title.Size = UDim2.new(
    1,
    -20,
    0,
    40
)

Title.Position = UDim2.new(
    0,
    10,
    0,
    5
)

Title.BackgroundTransparency = 1

Title.Text = "BABI MANAGER"

Title.TextColor3 = Color3.fromRGB(
    255,
    255,
    255
)

Title.TextSize = 22

Title.Font = Enum.Font.GothamBold

Title.Parent = Main


--==============================================================
-- STATUS
--==============================================================

local Status = Instance.new("TextLabel")

Status.Name = "Status"

Status.Size = UDim2.new(
    1,
    -20,
    0,
    38
)

Status.Position = UDim2.new(
    0,
    10,
    0,
    48
)

Status.BackgroundColor3 = Color3.fromRGB(
    35,
    35,
    35
)

Status.BorderSizePixel = 0

Status.Text = "STATUS: STARTING..."

Status.TextColor3 = Color3.fromRGB(
    255,
    220,
    80
)

Status.TextSize = 13

Status.Font = Enum.Font.GothamBold

Status.Parent = Main


local StatusCorner = Instance.new("UICorner")

StatusCorner.CornerRadius = UDim.new(
    0,
    6
)

StatusCorner.Parent = Status


--==============================================================
-- TARGET
--==============================================================

local TargetLabel = Instance.new("TextLabel")

TargetLabel.Name = "Target"

TargetLabel.Size = UDim2.new(
    1,
    -20,
    0,
    58
)

TargetLabel.Position = UDim2.new(
    0,
    10,
    0,
    92
)

TargetLabel.BackgroundTransparency = 1

TargetLabel.Text = "TARGET: NONE"

TargetLabel.TextColor3 = Color3.fromRGB(
    255,
    255,
    255
)

TargetLabel.TextSize = 13

TargetLabel.Font = Enum.Font.Gotham

TargetLabel.TextWrapped = true

TargetLabel.TextXAlignment = Enum.TextXAlignment.Left

TargetLabel.Parent = Main


--==============================================================
-- AGE
--==============================================================

local AgeLabel = Instance.new("TextLabel")

AgeLabel.Name = "Age"

AgeLabel.Size = UDim2.new(
    1,
    -20,
    0,
    30
)

AgeLabel.Position = UDim2.new(
    0,
    10,
    0,
    148
)

AgeLabel.BackgroundTransparency = 1

AgeLabel.Text = "AGE: NONE"

AgeLabel.TextColor3 = Color3.fromRGB(
    190,
    190,
    190
)

AgeLabel.TextSize = 13

AgeLabel.Font = Enum.Font.Gotham

AgeLabel.TextXAlignment = Enum.TextXAlignment.Left

AgeLabel.Parent = Main


--==============================================================
-- SERVER DATA COUNT
--==============================================================

local ServerCountLabel = Instance.new("TextLabel")

ServerCountLabel.Name = "ServerCount"

ServerCountLabel.Size = UDim2.new(
    1,
    -20,
    0,
    25
)

ServerCountLabel.Position = UDim2.new(
    0,
    10,
    0,
    178
)

ServerCountLabel.BackgroundTransparency = 1

ServerCountLabel.Text = "SERVER TERNAK: 0"

ServerCountLabel.TextColor3 = Color3.fromRGB(
    150,
    150,
    150
)

ServerCountLabel.TextSize = 12

ServerCountLabel.Font = Enum.Font.Gotham

ServerCountLabel.TextXAlignment = Enum.TextXAlignment.Left

ServerCountLabel.Parent = Main


--==============================================================
-- WORKSPACE COUNT
--==============================================================

local WorkspaceCountLabel = Instance.new("TextLabel")

WorkspaceCountLabel.Name = "WorkspaceCount"

WorkspaceCountLabel.Size = UDim2.new(
    1,
    -20,
    0,
    25
)

WorkspaceCountLabel.Position = UDim2.new(
    0,
    10,
    0,
    200
)

WorkspaceCountLabel.BackgroundTransparency = 1

WorkspaceCountLabel.Text = "WORKSPACE BABI: 0"

WorkspaceCountLabel.TextColor3 = Color3.fromRGB(
    150,
    150,
    150
)

WorkspaceCountLabel.TextSize = 12

WorkspaceCountLabel.Font = Enum.Font.Gotham

WorkspaceCountLabel.TextXAlignment = Enum.TextXAlignment.Left

WorkspaceCountLabel.Parent = Main


--==============================================================
-- MIN AGE LABEL
--==============================================================

local MinAgeLabel = Instance.new("TextLabel")

MinAgeLabel.Name = "MinAgeLabel"

MinAgeLabel.Size = UDim2.new(
    0,
    100,
    0,
    30
)

MinAgeLabel.Position = UDim2.new(
    0,
    10,
    0,
    225
)

MinAgeLabel.BackgroundTransparency = 1

MinAgeLabel.Text = "MIN AGE:"

MinAgeLabel.TextColor3 = Color3.fromRGB(
    255,
    255,
    255
)

MinAgeLabel.TextSize = 14

MinAgeLabel.Font = Enum.Font.GothamBold

MinAgeLabel.TextXAlignment = Enum.TextXAlignment.Left

MinAgeLabel.Parent = Main


--==============================================================
-- AGE BOX
--==============================================================

local AgeBox = Instance.new("TextBox")

AgeBox.Name = "AgeBox"

AgeBox.Size = UDim2.new(
    0,
    210,
    0,
    32
)

AgeBox.Position = UDim2.new(
    0,
    110,
    0,
    224
)

AgeBox.BackgroundColor3 = Color3.fromRGB(
    42,
    42,
    42
)

AgeBox.BorderSizePixel = 0

AgeBox.Text = tostring(DEFAULT_MIN_AGE)

AgeBox.PlaceholderText = "Minutes"

AgeBox.TextColor3 = Color3.fromRGB(
    255,
    255,
    255
)

AgeBox.TextSize = 14

AgeBox.Font = Enum.Font.Gotham

AgeBox.ClearTextOnFocus = false

AgeBox.Parent = Main


local AgeBoxCorner = Instance.new("UICorner")

AgeBoxCorner.CornerRadius = UDim.new(
    0,
    6
)

AgeBoxCorner.Parent = AgeBox


--==============================================================
-- APPLY BUTTON
--==============================================================

local ApplyButton = Instance.new("TextButton")

ApplyButton.Name = "Apply"

ApplyButton.Size = UDim2.new(
    0,
    320,
    0,
    35
)

ApplyButton.Position = UDim2.new(
    0,
    10,
    0,
    265
)

ApplyButton.BackgroundColor3 = Color3.fromRGB(
    55,
    55,
    55
)

ApplyButton.BorderSizePixel = 0

ApplyButton.Text = "APPLY MIN AGE"

ApplyButton.TextColor3 = Color3.fromRGB(
    255,
    255,
    255
)

ApplyButton.TextSize = 13

ApplyButton.Font = Enum.Font.GothamBold

ApplyButton.Parent = Main


local ApplyCorner = Instance.new("UICorner")

ApplyCorner.CornerRadius = UDim.new(
    0,
    6
)

ApplyCorner.Parent = ApplyButton


--==============================================================
-- AUTO PICKUP BUTTON
--==============================================================

local ToggleButton = Instance.new("TextButton")

ToggleButton.Name = "Toggle"

ToggleButton.Size = UDim2.new(
    0,
    320,
    0,
    35
)

ToggleButton.Position = UDim2.new(
    0,
    10,
    0,
    310
)

ToggleButton.BackgroundColor3 = Color3.fromRGB(
    80,
    50,
    50
)

ToggleButton.BorderSizePixel = 0

ToggleButton.Text = "AUTO PICKUP: OFF"

ToggleButton.TextColor3 = Color3.fromRGB(
    255,
    255,
    255
)

ToggleButton.TextSize = 13

ToggleButton.Font = Enum.Font.GothamBold

ToggleButton.Parent = Main


local ToggleCorner = Instance.new("UICorner")

ToggleCorner.CornerRadius = UDim.new(
    0,
    6
)

ToggleCorner.Parent = ToggleButton


--==============================================================
-- STATUS FUNCTION
--==============================================================

local function SetStatus(text)

    Status.Text = "STATUS: " .. tostring(text)

end


--==============================================================
-- NORMALIZE ID
--==============================================================

local function NormalizeID(value)

    if value == nil then
        return nil
    end

    local result = tostring(value)

    result = result:gsub("^Babi_", "")

    result = string.lower(result)

    return result

end


--==============================================================
-- PROGRESS -> MINUTES
--==============================================================

local function ProgressToMinutes(progress)

    progress = tonumber(progress)

    if not progress then
        return nil
    end

    return progress * 1440

end


--==============================================================
-- GET BABI ID
--==============================================================

local function GetBabiID(object)

    if not object then
        return nil
    end

    local id = string.match(
        object.Name,
        "^Babi_(.+)$"
    )

    if not id then
        return nil
    end

    return NormalizeID(id)

end


--==============================================================
-- GET ALL KANDANG
--==============================================================

local function GetAllKandang()

    local result = {}

    for _, object in ipairs(
        workspace:GetDescendants()
    ) do

        if object:IsA("Folder")
            or object:IsA("Model") then

            if string.match(
                object.Name,
                "^KandangBabi_"
            ) then

                table.insert(
                    result,
                    object
                )

            end
        end
    end

    return result

end


--==============================================================
-- GET ALL BABI
--==============================================================

local function GetAllBabiModels()

    local result = {}

    local kandangList = GetAllKandang()

    for _, kandang in ipairs(kandangList) do

        for _, object in ipairs(
            kandang:GetDescendants()
        ) do

            if object:IsA("Model")
                or object:IsA("Folder") then

                local id = GetBabiID(object)

                if id then

                    table.insert(
                        result,
                        {
                            Object = object,
                            ID = id
                        }
                    )

                end
            end
        end
    end

    return result

end


--==============================================================
-- FIND MODEL BABI
--==============================================================

local function FindModelBabi(babi)

    if not babi then
        return nil
    end


    -- exact
    local exact = babi:FindFirstChild(
        "modelbabi",
        true
    )

    if exact then
        return exact
    end


    -- case insensitive
    for _, object in ipairs(
        babi:GetDescendants()
    ) do

        if string.lower(
            object.Name
        ) == "modelbabi" then

            return object

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

    for _, object in ipairs(
        modelBabi:GetDescendants()
    ) do

        if object:IsA(
            "ProximityPrompt"
        ) then

            local action =
                string.lower(
                    tostring(
                        object.ActionText
                    )
                )

            if action == "bawa" then

                return object

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

        BabiBandar =
            FindBabiBandar()

    end


    if not BabiBandar then

        return nil,
            "BABIBANDAR TIDAK DITEMUKAN"

    end


    local success, result =
        pcall(function()

            return BabiBandar:
                InvokeServer("info")

        end)


    if not success then

        warn(
            "[BABI MANAGER] INFO ERROR:",
            result
        )

        return nil,
            "INVOKE INFO ERROR"

    end


    if type(result) ~= "table" then

        return nil,
            "RESPONSE BUKAN TABLE"

    end


    if type(result.ternak) ~= "table" then

        return nil,
            "TERNak TIDAK DITEMUKAN"

    end


    return result.ternak, nil

end


--==============================================================
-- COUNT SERVER DATA
--==============================================================

local function CountTable(tableData)

    local count = 0

    if type(tableData) ~= "table" then
        return 0
    end

    for _, _ in pairs(tableData) do
        count += 1
    end

    return count

end


--==============================================================
-- FIND SERVER DATA BY ID
--==============================================================

local function FindServerDataByID(
    ternak,
    workspaceID
)

    if type(ternak) ~= "table" then
        return nil
    end


    local wantedID =
        NormalizeID(workspaceID)


    if not wantedID then
        return nil
    end


    for key, data in pairs(ternak) do

        if type(data) == "table" then


            --==================================================
            -- DATA.ID
            --==================================================

            if data.id ~= nil then

                local serverID =
                    NormalizeID(data.id)

                if serverID == wantedID then

                    return data

                end
            end


            --==================================================
            -- KEY TABLE
            --==================================================

            if key ~= nil then

                local keyID =
                    NormalizeID(key)

                if keyID == wantedID then

                    return data

                end
            end

        end
    end


    return nil

end


--==============================================================
-- CLEAR TARGET
--==============================================================

local function ClearTarget(reason)

    CurrentTarget = nil

    CurrentTargetData = nil

    TargetLabel.Text =
        "TARGET: NONE"

    AgeLabel.Text =
        "AGE: NONE"

    if reason then
        SetStatus(reason)
    end

end


--==============================================================
-- DISPLAY TARGET
--==============================================================

local function DisplayTarget(target)

    if not target then

        TargetLabel.Text =
            "TARGET: NONE"

        AgeLabel.Text =
            "AGE: NONE"

        return

    end


    TargetLabel.Text =
        "TARGET: " ..
        tostring(
            target.Babi.Name
        ) ..
        "\nID: " ..
        tostring(
            target.PigId
        )


    local age =
        tonumber(
            target.AgeMinutes
        ) or 0


    local data =
        target.Data


    local umur = "UNKNOWN"


    if data then

        if data.umur ~= nil then

            umur =
                tostring(
                    data.umur
                )

        elseif data.dewasa == true then

            umur = "Dewasa"

        end
    end


    AgeLabel.Text =
        string.format(
            "AGE: %.2f MIN | %s",
            age,
            umur
        )

end


--==============================================================
-- FIND TARGET
--==============================================================

local function FindTarget()

    local ternak, errorMessage =
        GetServerPigData()


    if not ternak then

        return nil,
            errorMessage

    end


    local serverCount =
        CountTable(ternak)


    ServerCountLabel.Text =
        "SERVER TERNAK: " ..
        tostring(serverCount)


    local babiList =
        GetAllBabiModels()


    WorkspaceCountLabel.Text =
        "WORKSPACE BABI: " ..
        tostring(#babiList)


    print(
        "========================================"
    )

    print(
        "[BABI MANAGER] SERVER TERNAK:",
        serverCount
    )

    print(
        "[BABI MANAGER] WORKSPACE BABI:",
        #babiList
    )

    print(
        "========================================"
    )


    --==========================================================
    -- LOOP SEMUA BABI
    --==========================================================

    for _, info in ipairs(babiList) do

        local babi =
            info.Object

        local workspaceID =
            info.ID


        print(
            "[BABI MANAGER] CHECK:",
            babi:GetFullName(),
            "ID:",
            workspaceID
        )


        --======================================================
        -- CARI DATA SERVER
        --======================================================

        local data =
            FindServerDataByID(
                ternak,
                workspaceID
            )


        if not data then

            print(
                "[BABI MANAGER] DATA SERVER TIDAK COCOK:",
                workspaceID
            )

            continue

        end


        --======================================================
        -- PROGRES
        --======================================================

        local progress =
            tonumber(
                data.progres
            )


        if not progress then

            print(
                "[BABI MANAGER] PROGRES INVALID:",
                workspaceID,
                data.progres
            )

            continue

        end


        --======================================================
        -- UMUR
        --======================================================

        local ageMinutes =
            ProgressToMinutes(
                progress
            )


        if not ageMinutes then

            continue

        end


        print(
            "[BABI MANAGER] AGE:",
            workspaceID,
            ageMinutes,
            "MIN"
        )


        --======================================================
        -- CEK MIN AGE
        --======================================================

        if ageMinutes <
            MinimumAgeMinutes then

            print(
                "[BABI MANAGER] TERLALU MUDA:",
                workspaceID,
                ageMinutes,
                "<",
                MinimumAgeMinutes
            )

            continue

        end


        --======================================================
        -- MODEL BABI
        --======================================================

        local modelBabi =
            FindModelBabi(
                babi
            )


        if not modelBabi then

            print(
                "[BABI MANAGER] MODEL BABI TIDAK ADA:",
                babi:GetFullName()
            )

            continue

        end


        --======================================================
        -- PROMPT BAWA
        --======================================================

        local prompt =
            FindBawaPrompt(
                modelBabi
            )


        if not prompt then

            print(
                "[BABI MANAGER] PROMPT BAWA TIDAK ADA:",
                modelBabi:GetFullName()
            )

            continue

        end


        --======================================================
        -- TARGET VALID
        --======================================================

        print(
            "========================================"
        )

        print(
            "[BABI MANAGER] TARGET DITEMUKAN!"
        )

        print(
            "BABI:",
            babi:GetFullName()
        )

        print(
            "ID:",
            workspaceID
        )

        print(
            "AGE:",
            ageMinutes
        )

        print(
            "MODEL:",
            modelBabi:GetFullName()
        )

        print(
            "PROMPT:",
            prompt:GetFullName()
        )

        print(
            "========================================"
        )


        return {

            Babi = babi,

            ModelBabi = modelBabi,

            Prompt = prompt,

            Data = data,

            AgeMinutes = ageMinutes,

            PigId = workspaceID

        }

    end


    return nil,
        "TIDAK ADA TARGET MEMENUHI SYARAT"

end


--==============================================================
-- VALIDATE CURRENT TARGET
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
-- REFRESH CURRENT TARGET
--==============================================================

local function RefreshCurrentTarget()

    if not CurrentTarget then
        return false
    end


    if not ValidateTarget(
        CurrentTarget
    ) then

        return false

    end


    local ternak, errorMessage =
        GetServerPigData()


    if not ternak then

        SetStatus(
            errorMessage or
            "DATA ERROR"
        )

        return true

    end


    local targetID =
        NormalizeID(
            CurrentTarget.PigId
        )


    local data =
        FindServerDataByID(
            ternak,
            targetID
        )


    if not data then

        return false

    end


    local progress =
        tonumber(
            data.progres
        )


    if not progress then

        return false

    end


    local ageMinutes =
        ProgressToMinutes(
            progress
        )


    if not ageMinutes then

        return false

    end


    CurrentTarget.Data =
        data

    CurrentTarget.AgeMinutes =
        ageMinutes

    CurrentTargetData =
        data


    DisplayTarget(
        CurrentTarget
    )


    if ageMinutes >=
        MinimumAgeMinutes then

        SetStatus(
            "TARGET LOCKED"
        )

        return true

    end


    return false

end


--==============================================================
-- ACQUIRE TARGET
--==============================================================

local function AcquireTarget()

    if Busy then
        return
    end


    Busy = true


    local target, errorMessage =
        FindTarget()


    if target then

        CurrentTarget =
            target

        CurrentTargetData =
            target.Data


        DisplayTarget(
            target
        )


        SetStatus(
            "TARGET LOCKED"
        )


    else

        ClearTarget(
            errorMessage or
            "NO TARGET"
        )

    end


    Busy = false

end


--==============================================================
-- APPLY MIN AGE
--==============================================================

local function ApplyMinAge()

    local value =
        tonumber(
            AgeBox.Text
        )


    if not value then

        AgeBox.Text =
            tostring(
                MinimumAgeMinutes
            )

        SetStatus(
            "MIN AGE INVALID"
        )

        return

    end


    value =
        math.floor(
            value
        )


    if value < 1 then
        value = 1
    end


    if value > 100000 then
        value = 100000
    end


    MinimumAgeMinutes =
        value


    AgeBox.Text =
        tostring(
            value
        )


    ClearTarget(
        "MIN AGE: " ..
        tostring(value) ..
        " MIN"
    )

end


--==============================================================
-- APPLY BUTTON
--==============================================================

ApplyButton.MouseButton1Click:Connect(
    function()

        ApplyMinAge()

    end
)


--==============================================================
-- ENTER AGE
--==============================================================

AgeBox.FocusLost:Connect(
    function(enterPressed)

        if enterPressed then

            ApplyMinAge()

        end

    end
)


--==============================================================
-- TOGGLE
--==============================================================

ToggleButton.MouseButton1Click:Connect(
    function()

        Running =
            not Running


        if Running then

            ToggleButton.Text =
                "AUTO PICKUP: ON"

            ToggleButton.BackgroundColor3 =
                Color3.fromRGB(
                    45,
                    125,
                    55
                )


            ClearTarget(
                "SCANNING..."
            )


        else

            ToggleButton.Text =
                "AUTO PICKUP: OFF"

            ToggleButton.BackgroundColor3 =
                Color3.fromRGB(
                    80,
                    50,
                    50
                )


            SetStatus(
                "STOPPED"
            )

        end

    end
)


--==============================================================
-- INITIALIZE
--==============================================================

task.spawn(
    function()

        task.wait(1)


        BabiBandar =
            FindBabiBandar()


        if BabiBandar then

            SetStatus(
                "BABIBANDAR READY"
            )

        else

            SetStatus(
                "BABIBANDAR NOT FOUND"
            )

        end

    end
)


--==============================================================
-- MAIN LOOP
--==============================================================

task.spawn(
    function()

        while ScreenGui.Parent do

            task.wait(
                SCAN_INTERVAL
            )


            if not Running then
                continue
            end


            --==================================================
            -- TARGET SUDAH ADA
            --==================================================

            if CurrentTarget then

                local valid =
                    RefreshCurrentTarget()


                if valid then

                    continue

                end


                ClearTarget(
                    "TARGET INVALID - RESCAN"
                )

            end


            --==================================================
            -- CARI TARGET BARU
            --==================================================

            AcquireTarget()

        end

    end
)


--==============================================================
-- DRAG UI
--==============================================================

local dragging = false

local dragStart = nil

local startPosition = nil


Title.InputBegan:Connect(
    function(input)

        if input.UserInputType ==
            Enum.UserInputType.MouseButton1
            or input.UserInputType ==
            Enum.UserInputType.Touch then


            dragging = true

            dragStart =
                input.Position

            startPosition =
                Main.Position


            input.Changed:Connect(
                function()

                    if input.UserInputState ==
                        Enum.UserInputState.End then

                        dragging = false

                    end

                end
            )

        end

    end
)


Title.InputChanged:Connect(
    function(input)

        if input.UserInputType ==
            Enum.UserInputType.MouseMovement
            or input.UserInputType ==
            Enum.UserInputType.Touch then


            local connection


            connection =
                RunService.RenderStepped:Connect(
                    function()

                        if not dragging then

                            connection:Disconnect()

                            return

                        end


                        local delta =
                            input.Position -
                            dragStart


                        Main.Position =
                            UDim2.new(

                                startPosition.X.Scale,

                                startPosition.X.Offset +
                                delta.X,

                                startPosition.Y.Scale,

                                startPosition.Y.Offset +
                                delta.Y

                            )

                    end
                )

        end

    end
)


--==============================================================
-- FINAL
--==============================================================

print(
    "=============================================="
)

print(
    "[BABI MANAGER] LOADED"
)

print(
    "[BABI MANAGER] MIN AGE:",
    MinimumAgeMinutes,
    "MINUTES"
)

print(
    "[BABI MANAGER] BABIBANDAR:",
    BabiBandar
)

print(
    "=============================================="
)
