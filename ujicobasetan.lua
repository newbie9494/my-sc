-- [[ ALIT HUB V3 FIXED - EXACT REPAIR EDITION - PART 1 ]]
if not game:IsLoaded() then
    game.Loaded:Wait()
end

--==============================================================
-- SERVICES
--==============================================================

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui", 10)

if not PlayerGui then
    warn("[ALIT HUB] PlayerGui tidak ditemukan.")
    return
end

--==============================================================
-- CLEAN OLD UI
--==============================================================

local oldUI = PlayerGui:FindFirstChild("AlitHubUI")
if oldUI then
    oldUI:Destroy()
end

--==============================================================
-- GLOBAL STATE
--==============================================================

_G.AlitHubFarmActive = false
_G.AlitHubRestockActive = false
_G.AlitHubPigActive = false
_G.AlitHubCookActive = false

--==============================================================
-- CONFIGURATION
--==============================================================

local TARGET_MAPPING = {
    ["Dupa"] = "Spawn_Dupa",
    ["Gagak"] = "Spawn_Gagak",
    ["Jamur Kuburan"] = "Spawn_JamurKuburan",
    ["Kemenyan"] = "Spawn_Kemenyan",
    ["Kepiting Sungai"] = "Spawn_KepitingSungai",
    ["Melati"] = "Spawn_Melati",
}

local TARGET_ORDER = {
    "Dupa",
    "Gagak",
    "Jamur Kuburan",
    "Kemenyan",
    "Kepiting Sungai",
    "Melati",
}

--==============================================================
-- FIXED SLOTS
--==============================================================

local FIXED_RBXL_SLOTS = {
    "slot1", "slot2", "slot3", "slot4", "slot5", "slot6",
    "slot7", "slot8", "slot9", "slot10", "slot11", "slot12"
}

--==============================================================
-- DELAY CONFIG
--==============================================================

local RESTOCK_TELEPORT_DELAY = 0.3
local RESTOCK_HOLD_DURATION = 0.5
local RESTOCK_HOLD_DELAY = 0.4
local RESTOCK_COOLDOWN = 2.0

local RESTOCK_MAX_ATTEMPTS = 3
local RESTOCK_CHECK_DELAY = 0.1
local RESTOCK_VERIFY_TIMEOUT = 4.0

local FARM_TELEPORT_DELAY = 0.2
local FARM_COOLDOWN = 2.5

local MAIN_LOOP_DELAY = 0.15
local UI_REFRESH_DELAY = 1.0

--==============================================================
-- COLORS
--==============================================================

local BG_COLOR = Color3.fromRGB(15, 15, 15)
local SIDEBAR_COLOR = Color3.fromRGB(10, 10, 10)
local PANEL_COLOR = Color3.fromRGB(20, 20, 20)
local ACCENT_GOLD = Color3.fromRGB(255, 185, 0)
local TEXT_LIGHT = Color3.fromRGB(220, 220, 220)
local TEXT_DARK = Color3.fromRGB(150, 150, 150)
local OFF_RED = Color3.fromRGB(220, 53, 69)
local ON_GREEN = Color3.fromRGB(35, 180, 80)

--==============================================================
-- STATE TABLES
--==============================================================

local AutoDetectedTools = {}
local SlotSpecificTargets = {}
local SelectedTargets = {}
local GLOBAL_SAVED_POS = UDim2.new(0.5, -175, 0.3, -110)
local CurrentKios = nil

--==============================================================
-- UTILITY & SCANNERS
--==============================================================

local function getCharacter()
    return LocalPlayer.Character
end

local function getRoot()
    local character = getCharacter()
    return character and character:FindFirstChild("HumanoidRootPart")
end

local function getHumanoid()
    local character = getCharacter()
    return character and character:FindFirstChildOfClass("Humanoid")
end

local function getMyKios()
    local kiosAktif = workspace:FindFirstChild("KiosAktif")
    if not kiosAktif then return nil end

    return kiosAktif:FindFirstChild("Kios_" .. LocalPlayer.Name)
        or kiosAktif:FindFirstChild("Kios_panggil_" .. LocalPlayer.Name)
end

local function getSlot(kios, slotName)
    if not kios then return nil end

    local slot = kios:FindFirstChild(slotName)
    if slot then return slot end

    local number = string.match(slotName, "%d+")
    if number then
        return kios:FindFirstChild("slot " .. number)
    end

    return nil
end

local function cleanToolName(name)
    if not name then return "" end

    local cleaned = string.gsub(name, "%s+x%d+", "")
    cleaned = string.gsub(cleaned, "%s+$", "")

    return cleaned
end

local function ScanCurrentInventory()
    table.clear(AutoDetectedTools)

    local foundItems = {}

    local backpack = LocalPlayer:FindFirstChild("Backpack")
    local character = LocalPlayer.Character

    local function inspect(container)
        if not container then return end

        for _, object in ipairs(container:GetChildren()) do
            if object:IsA("Tool") then

                local lowerName = string.lower(object.Name)

                local excluded =
                    string.find(lowerName, "penyiram")
                    or string.find(lowerName, "bibit")
                    or string.find(lowerName, "lantern")
                    or string.find(lowerName, "gerobak")
                    or string.find(lowerName, "payung")
                    or string.find(lowerName, "arwah")
                    or string.find(lowerName, "pusaka")
                    or string.find(lowerName, "tas")

                if not excluded then
                    local cleanName = cleanToolName(object.Name)

                    if cleanName ~= "" and not foundItems[cleanName] then
                        foundItems[cleanName] = true
                        table.insert(AutoDetectedTools, cleanName)
                    end
                end
            end
        end
    end

    inspect(backpack)
    inspect(character)

    table.sort(AutoDetectedTools)
end

--==============================================================
-- INTERACTION & DETECTORS
--==============================================================

local function checkItemInBackpackClean(cleanName)
    if not cleanName or cleanName == "" then
        return false
    end

    local backpack = LocalPlayer:FindFirstChild("Backpack")
    local character = LocalPlayer.Character

    local function search(container)
        if not container then return false end

        for _, object in ipairs(container:GetChildren()) do
            if object:IsA("Tool")
                and cleanToolName(object.Name) == cleanName then
                return true
            end
        end

        return false
    end

    return search(backpack) or search(character)
end

--==============================================================
-- EQUIP ITEM
--==============================================================

local function equipItemClean(cleanName)
    if not cleanName or cleanName == "" then
        return false
    end

    local backpack = LocalPlayer:FindFirstChild("Backpack")
    local humanoid = getHumanoid()

    if not backpack or not humanoid then
        return false
    end

    local character = getCharacter()

    if character then
        for _, object in ipairs(character:GetChildren()) do
            if object:IsA("Tool")
                and cleanToolName(object.Name) == cleanName then
                return true
            end
        end
    end

    for _, object in ipairs(backpack:GetChildren()) do
        if object:IsA("Tool")
            and cleanToolName(object.Name) == cleanName then

            humanoid:EquipTool(object)

            local verifyTimeout = tick() + 1.0

            while tick() < verifyTimeout do
                task.wait(0.05)

                character = getCharacter()

                if character then
                    for _, equippedTool in ipairs(character:GetChildren()) do
                        if equippedTool:IsA("Tool")
                            and cleanToolName(equippedTool.Name) == cleanName then
                            return true
                        end
                    end
                end
            end

            return false
        end
    end

    return false
end

--==============================================================
-- TELEPORT
--==============================================================

local function teleportToPart(part)
    if not part then
        return false
    end

    local root = getRoot()

    if not root or not part:IsA("BasePart") then
        return false
    end

    root.CFrame = part.CFrame + Vector3.new(0, 3, 0)

    root.AssemblyLinearVelocity = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero

    return true
end

--==============================================================
-- MAIN PART
--==============================================================

local function getMainPart(object)
    if not object then
        return nil
    end

    if object:IsA("BasePart") then
        return object
    end

    return object:FindFirstChildWhichIsA("BasePart", true)
end

--==============================================================
-- SLOT STOCK CHECK
--==============================================================

local function IsTrayEmptyIndependent(slotObj)
    if not slotObj then
        return true
    end

    local stokFolder = slotObj:FindFirstChild("Stok")

    if not stokFolder then
        return true
    end

    for _, item in ipairs(stokFolder:GetChildren()) do
        if item:IsA("IntValue") and item.Value > 0 then
            return false
        end
    end

    return true
end

--==============================================================
-- GET PROMPT
--==============================================================

local function getPrompt(object)
    if not object then
        return nil
    end

    return object:FindFirstChildWhichIsA("ProximityPrompt", true)
end

--==============================================================
-- RESTOCK
--==============================================================

local function performRestock(slotObj, itemName)
    if not slotObj then
        return false
    end

    local prompt = getPrompt(slotObj)

    if not prompt then
        warn(
            "[ALIT RESTOCK] PROMPT TIDAK DITEMUKAN:",
            slotObj.Name
        )
        return false
    end

    if not prompt.Enabled then
        warn(
            "[ALIT RESTOCK] PROMPT DISABLED:",
            slotObj.Name,
            prompt.Name
        )
        return false
    end

    print(
        "[ALIT RESTOCK] MENEKAN E:",
        slotObj.Name,
        "| Prompt:",
        prompt.Name,
        "| Action:",
        prompt.ActionText,
        "| Object:",
        prompt.ObjectText,
        "| Hold:",
        prompt.HoldDuration
    )

    prompt:InputHoldBegin()

    task.wait(RESTOCK_HOLD_DURATION)

    prompt:InputHoldEnd()

    print(
        "[ALIT RESTOCK] E RELEASE:",
        slotObj.Name
    )

    return true
end

--==============================================================
-- HARVEST
--==============================================================

local function performHarvest(targetObject)
    if not targetObject then
        return false
    end

    local prompt = getPrompt(targetObject)

    if not prompt or not prompt.Enabled then
        return false
    end

    if fireproximityprompt then
        fireproximityprompt(prompt)
        return true
    else
        prompt:InputHoldBegin()
        task.wait(0.6)
        prompt:InputHoldEnd()

        return true
    end
end

--==============================================================
-- UI FRAMEWORK
--==============================================================

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AlitHubUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = PlayerGui

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = BG_COLOR
MainFrame.Position = GLOBAL_SAVED_POS
MainFrame.Size = UDim2.new(0, 350, 0, 220)
MainFrame.BorderSizePixel = 1
MainFrame.BorderColor3 = ACCENT_GOLD
MainFrame.ClipsDescendants = true
MainFrame.Active = true

Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)

local TopBar = Instance.new("Frame")
TopBar.Name = "TopBar"
TopBar.Parent = MainFrame
TopBar.BackgroundTransparency = 1
TopBar.Size = UDim2.new(1, 0, 0, 35)

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Name = "TitleLabel"
TitleLabel.Parent = TopBar
TitleLabel.BackgroundTransparency = 1
TitleLabel.Position = UDim2.new(0, 12, 0, 0)
TitleLabel.Size = UDim2.new(0, 150, 0, 35)
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.Text = "ALIT HUB V3"
TitleLabel.TextColor3 = ACCENT_GOLD
TitleLabel.TextSize = 12
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left

local MiniButton = Instance.new("TextButton")
MiniButton.Name = "MiniButton"
MiniButton.Parent = TopBar
MiniButton.BackgroundTransparency = 1
MiniButton.Position = UDim2.new(1, -30, 0, 0)
MiniButton.Size = UDim2.new(0, 25, 0, 35)
MiniButton.Font = Enum.Font.GothamBold
MiniButton.Text = "-"
MiniButton.TextColor3 = TEXT_LIGHT
MiniButton.TextSize = 20

local LeftSidebar = Instance.new("Frame")
LeftSidebar.Name = "LeftSidebar"
LeftSidebar.Parent = MainFrame
LeftSidebar.BackgroundColor3 = SIDEBAR_COLOR
LeftSidebar.Position = UDim2.new(0, 0, 0, 35)
LeftSidebar.Size = UDim2.new(0, 95, 1, -35)
LeftSidebar.BorderSizePixel = 0

local SidebarLayout = Instance.new("UIListLayout")
SidebarLayout.Parent = LeftSidebar
SidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder
SidebarLayout.Padding = UDim.new(0, 4)

local ContentArea = Instance.new("Frame")
ContentArea.Name = "ContentArea"
ContentArea.Parent = MainFrame
ContentArea.BackgroundTransparency = 1
ContentArea.Position = UDim2.new(0, 100, 0, 35)
ContentArea.Size = UDim2.new(1, -105, 1, -40)

local OpenButton = Instance.new("TextButton")
OpenButton.Name = "OpenButton"
OpenButton.Parent = ScreenGui
OpenButton.BackgroundColor3 = BG_COLOR
OpenButton.Position = UDim2.new(0, 10, 0.4, 0)
OpenButton.Size = UDim2.new(0, 45, 0, 30)
OpenButton.Font = Enum.Font.GothamBold
OpenButton.Text = "ALIT"
OpenButton.TextColor3 = ACCENT_GOLD
OpenButton.TextSize = 10
OpenButton.BorderSizePixel = 1
OpenButton.BorderColor3 = ACCENT_GOLD
OpenButton.Visible = false

Instance.new("UICorner", OpenButton).CornerRadius = UDim.new(0, 5)

MiniButton.Activated:Connect(function()
    GLOBAL_SAVED_POS = MainFrame.Position
    MainFrame.Visible = false
    OpenButton.Visible = true
end)

OpenButton.Activated:Connect(function()
    OpenButton.Visible = false
    MainFrame.Position = GLOBAL_SAVED_POS
    MainFrame.Visible = true
end)

local SidebarButtons = {
    "AUTO FARM",
    "AUTO STOCK",
    "AUTO PIG",
    "AUTO COOK"
}

local SubFrames = {}

for index, tabName in ipairs(SidebarButtons) do

    local button = Instance.new("TextButton")
    button.Name = tabName .. "Btn"
    button.Parent = LeftSidebar
    button.BackgroundColor3 = PANEL_COLOR
    button.Size = UDim2.new(1, -8, 0, 30)
    button.Font = Enum.Font.GothamBold
    button.Text = tabName
    button.TextColor3 = TEXT_LIGHT
    button.TextSize = 8

    Instance.new("UICorner", button).CornerRadius = UDim.new(0, 4)

    local frame = Instance.new("Frame")
    frame.Name = tabName .. "Frame"
    frame.Parent = ContentArea
    frame.BackgroundTransparency = 1
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.Visible = (index == 1)

    SubFrames[tabName] = frame

    button.Activated:Connect(function()

        for _, otherFrame in pairs(SubFrames) do
            otherFrame.Visible = false
        end

        for _, child in ipairs(LeftSidebar:GetChildren()) do
            if child:IsA("TextButton") then
                child.TextColor3 = TEXT_LIGHT
                child.BackgroundColor3 = PANEL_COLOR
            end
        end

        frame.Visible = true
        button.TextColor3 = ACCENT_GOLD
        button.BackgroundColor3 = Color3.fromRGB(30, 25, 20)
    end)

    if index == 1 then
        button.TextColor3 = ACCENT_GOLD
        button.BackgroundColor3 = Color3.fromRGB(30, 25, 20)
    end
end

--==============================================================
-- AUTO FARM UI
--==============================================================

local ToggleButton = Instance.new("TextButton")
ToggleButton.Size = UDim2.new(1, 0, 0, 28)
ToggleButton.BackgroundColor3 = Color3.fromRGB(30, 15, 15)
ToggleButton.Font = Enum.Font.GothamBold
ToggleButton.Text = "FARM SYSTEM: OFF"
ToggleButton.TextColor3 = OFF_RED
ToggleButton.TextSize = 9
ToggleButton.Parent = SubFrames["AUTO FARM"]

Instance.new("UICorner", ToggleButton).CornerRadius = UDim.new(0, 4)

local DropdownButton = Instance.new("TextButton")
DropdownButton.Position = UDim2.new(0, 0, 0, 34)
DropdownButton.Size = UDim2.new(1, 0, 0, 24)
DropdownButton.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
DropdownButton.Font = Enum.Font.GothamSemibold
DropdownButton.Text = "SELECT TARGETS ▼"
DropdownButton.TextColor3 = TEXT_LIGHT
DropdownButton.TextSize = 9
DropdownButton.Parent = SubFrames["AUTO FARM"]

Instance.new("UICorner", DropdownButton).CornerRadius = UDim.new(0, 4)

local ListContainer = Instance.new("ScrollingFrame")
ListContainer.Position = UDim2.new(0, 0, 0, 62)
ListContainer.Size = UDim2.new(1, 0, 1, -62)
ListContainer.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
ListContainer.BorderSizePixel = 0
ListContainer.ScrollBarThickness = 2
ListContainer.Visible = false
ListContainer.Parent = SubFrames["AUTO FARM"]

Instance.new("UIListLayout", ListContainer).Padding = UDim.new(0, 2)

--==============================================================
-- AUTO FARM TARGET LIST
-- PENTING:
-- SelectedTargets menyimpan NILAI MAPPING:
-- Spawn_Dupa, Spawn_Gagak, dst.
-- BUKAN nama tampilan Dupa, Gagak, dst.
--==============================================================

local function RefreshTargetList()

    for _, child in ipairs(ListContainer:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end

    for _, targetName in ipairs(TARGET_ORDER) do

        local targetObjectName = TARGET_MAPPING[targetName]

        local button = Instance.new("TextButton")
        button.Name = targetObjectName .. "Button"
        button.Size = UDim2.new(1, -4, 0, 22)
        button.BackgroundColor3 =
            table.find(SelectedTargets, targetObjectName)
            and Color3.fromRGB(30, 25, 20)
            or Color3.fromRGB(25, 25, 25)

        button.Font = Enum.Font.GothamSemibold
        button.Text = targetName
        button.TextColor3 =
            table.find(SelectedTargets, targetObjectName)
            and ACCENT_GOLD
            or TEXT_LIGHT

        button.TextSize = 8
        button.Parent = ListContainer

        Instance.new("UICorner", button).CornerRadius =
            UDim.new(0, 3)

        button.Activated:Connect(function()

            local index =
                table.find(
                    SelectedTargets,
                    targetObjectName
                )

            if index then

                table.remove(
                    SelectedTargets,
                    index
                )

                button.BackgroundColor3 =
                    Color3.fromRGB(25, 25, 25)

                button.TextColor3 =
                    TEXT_LIGHT

            else

                table.insert(
                    SelectedTargets,
                    targetObjectName
                )

                button.BackgroundColor3 =
                    Color3.fromRGB(30, 25, 20)

                button.TextColor3 =
                    ACCENT_GOLD
            end

            if #SelectedTargets > 0 then

                local displayNames = {}

                for _, selectedObjectName in ipairs(SelectedTargets) do

                    for displayName, mappedName in pairs(TARGET_MAPPING) do

                        if mappedName == selectedObjectName then
                            table.insert(
                                displayNames,
                                displayName
                            )
                            break
                        end

                    end
                end

                DropdownButton.Text =
                    "TARGET: "
                    .. table.concat(displayNames, ", ")
                    .. " ▼"

            else

                DropdownButton.Text =
                    "SELECT TARGETS ▼"
            end
        end)
    end

    ListContainer.CanvasSize =
        UDim2.new(
            0,
            0,
            0,
            (#TARGET_ORDER * 24) + 4
        )
end

DropdownButton.Activated:Connect(function()

    ListContainer.Visible =
        not ListContainer.Visible

    if ListContainer.Visible then
        RefreshTargetList()
        DropdownButton.Text =
            "SELECT TARGETS ▲"
    else

        if #SelectedTargets > 0 then

            local displayNames = {}

            for _, selectedObjectName in ipairs(SelectedTargets) do

                for displayName, mappedName in pairs(TARGET_MAPPING) do

                    if mappedName == selectedObjectName then
                        table.insert(
                            displayNames,
                            displayName
                        )
                        break
                    end

                end
            end

            DropdownButton.Text =
                "TARGET: "
                .. table.concat(displayNames, ", ")
                .. " ▼"

        else

            DropdownButton.Text =
                "SELECT TARGETS ▼"
        end
    end
end)

RefreshTargetList()

--==============================================================
-- AUTO STOCK UI
--==============================================================

local RestockButton = Instance.new("TextButton")
RestockButton.Size = UDim2.new(1, 0, 0, 28)
RestockButton.BackgroundColor3 = Color3.fromRGB(30, 15, 15)
RestockButton.Font = Enum.Font.GothamBold
RestockButton.Text = "RESTOCK KIOS: OFF"
RestockButton.TextColor3 = OFF_RED
RestockButton.TextSize = 9
RestockButton.Parent = SubFrames["AUTO STOCK"]

Instance.new("UICorner", RestockButton).CornerRadius = UDim.new(0, 4)

local MasterScroll = Instance.new("ScrollingFrame")
MasterScroll.Name = "MasterScroll"
MasterScroll.Position = UDim2.new(0, 0, 0, 34)
MasterScroll.Size = UDim2.new(1, 0, 1, -38)
MasterScroll.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
MasterScroll.BorderSizePixel = 0
MasterScroll.ScrollBarThickness = 3
MasterScroll.Parent = SubFrames["AUTO STOCK"]

local UIMasterLayout = Instance.new("UIListLayout")
UIMasterLayout.Parent = MasterScroll
UIMasterLayout.Padding = UDim.new(0, 4)

local PigLabel = Instance.new("TextLabel")
PigLabel.Size = UDim2.new(1, 0, 0, 30)
PigLabel.BackgroundTransparency = 1
PigLabel.Font = Enum.Font.GothamBold
PigLabel.Text = "PIG CONFIGURATION"
PigLabel.TextColor3 = TEXT_DARK
PigLabel.TextSize = 8
PigLabel.Parent = SubFrames["AUTO PIG"]

local CookLabel = Instance.new("TextLabel")
CookLabel.Size = UDim2.new(1, 0, 0, 30)
CookLabel.BackgroundTransparency = 1
CookLabel.Font = Enum.Font.GothamBold
CookLabel.Text = "COOK CONFIGURATION"
CookLabel.TextColor3 = TEXT_DARK
CookLabel.TextSize = 8
CookLabel.Parent = SubFrames["AUTO COOK"]

--==============================================================
-- AUTO STOCK CONFIG UI
--==============================================================

local function BuildMultiRakUI()

    for _, child in ipairs(MasterScroll:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end

    CurrentKios = getMyKios()

    ScanCurrentInventory()

    if not CurrentKios then

        local msg = Instance.new("TextLabel")
        msg.Size = UDim2.new(1, -10, 0, 30)
        msg.BackgroundTransparency = 1
        msg.Text = "KIOS BELUM DITEMUKAN"
        msg.TextColor3 = OFF_RED
        msg.Font = Enum.Font.GothamBold
        msg.TextSize = 8
        msg.Parent = MasterScroll

        return
    end

    for slotIndex, slotName in ipairs(FIXED_RBXL_SLOTS) do

        local slotObj = getSlot(CurrentKios, slotName)

        if slotObj then

            if SlotSpecificTargets[slotName] == nil then
                SlotSpecificTargets[slotName] = ""
            end

            local row = Instance.new("Frame")
            row.Name = slotName .. "Row"
            row.LayoutOrder = slotIndex
            row.Size = UDim2.new(1, -4, 0, 32)
            row.BackgroundColor3 = PANEL_COLOR
            row.Parent = MasterScroll

            Instance.new("UICorner", row).CornerRadius = UDim.new(0, 4)

            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(0, 60, 1, 0)
            lbl.Position = UDim2.new(0, 6, 0, 0)
            lbl.BackgroundTransparency = 1
            lbl.Font = Enum.Font.GothamBold
            lbl.Text = string.upper(slotName)
            lbl.TextColor3 = TEXT_LIGHT
            lbl.TextSize = 8
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.Parent = row

            local dwn = Instance.new("TextButton")
            dwn.Size = UDim2.new(1, -70, 0, 20)
            dwn.Position = UDim2.new(0, 64, 0, 6)
            dwn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)

            dwn.Text =
                SlotSpecificTargets[slotName] ~= ""
                and SlotSpecificTargets[slotName] .. " ▼"
                or "NONE ▼"

            dwn.TextColor3 = ACCENT_GOLD
            dwn.TextSize = 7
            dwn.Parent = row

            Instance.new("UICorner", dwn).CornerRadius = UDim.new(0, 4)

            local opt = Instance.new("ScrollingFrame")
            opt.Size = UDim2.new(1, -10, 0, 70)
            opt.Position = UDim2.new(0, 5, 0, 34)
            opt.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
            opt.BorderSizePixel = 0
            opt.ScrollBarThickness = 2
            opt.Visible = false
            opt.ZIndex = 10
            opt.Parent = row

            Instance.new("UIListLayout", opt).Padding = UDim.new(0, 2)

            local function closeOptions()
                opt.Visible = false
                row.Size = UDim2.new(1, -4, 0, 32)
            end

            local function makeOption(text, callback)

                local btnOpt = Instance.new("TextButton")
                btnOpt.Size = UDim2.new(1, 0, 0, 18)
                btnOpt.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
                btnOpt.Text = "  " .. text
                btnOpt.TextColor3 = TEXT_LIGHT
                btnOpt.Font = Enum.Font.GothamSemibold
                btnOpt.TextSize = 7
                btnOpt.TextXAlignment = Enum.TextXAlignment.Left
                btnOpt.ZIndex = 11
                btnOpt.Parent = opt

                Instance.new("UICorner", btnOpt).CornerRadius = UDim.new(0, 3)

                btnOpt.Activated:Connect(callback)
            end

            dwn.Activated:Connect(function()

                if opt.Visible then
                    closeOptions()
                    return
                end

                for _, child in ipairs(opt:GetChildren()) do
                    if child:IsA("TextButton") then
                        child:Destroy()
                    end
                end

                ScanCurrentInventory()

                makeOption("NONE", function()
                    SlotSpecificTargets[slotName] = ""
                    dwn.Text = "NONE ▼"
                    closeOptions()
                end)

                for _, itemName in ipairs(AutoDetectedTools) do

                    local capturedName = itemName

                    makeOption(capturedName, function()
                        SlotSpecificTargets[slotName] = capturedName
                        dwn.Text = capturedName .. " ▼"
                        closeOptions()
                    end)
                end

                opt.CanvasSize =
                    UDim2.new(
                        0,
                        0,
                        0,
                        (#AutoDetectedTools + 1) * 20
                    )

                opt.Visible = true
                row.Size = UDim2.new(1, -4, 0, 108)
            end)
        end
    end

    MasterScroll.CanvasSize =
        UDim2.new(
            0,
            0,
            0,
            UIMasterLayout.AbsoluteContentSize.Y + 10
        )
end

--==============================================================
-- DRAGS
--==============================================================

local dragToggle = false
local dragStart = nil
local startPos = nil

MainFrame.InputBegan:Connect(function(input)

    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then

        dragToggle = true
        dragStart = input.Position
        startPos = MainFrame.Position

        input.Changed:Connect(function()

            if input.UserInputState == Enum.UserInputState.End then
                dragToggle = false
            end

        end)
    end
end)

UserInputService.InputChanged:Connect(function(input)

    if dragToggle
        and (
            input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch
        ) then

        local delta = input.Position - dragStart

        MainFrame.Position =
            UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
    end
end)

local openDrag = false
local openStart = nil
local openStartPos = nil

OpenButton.InputBegan:Connect(function(input)

    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then

        openDrag = true
        openStart = input.Position
        openStartPos = OpenButton.Position

        input.Changed:Connect(function()

            if input.UserInputState == Enum.UserInputState.End then
                openDrag = false
            end

        end)
    end
end)

UserInputService.InputChanged:Connect(function(input)

    if openDrag
        and (
            input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch
        ) then

        local delta = input.Position - openStart

        OpenButton.Position =
            UDim2.new(
                openStartPos.X.Scale,
                openStartPos.X.Offset + delta.X,
                openStartPos.Y.Scale,
                openStartPos.Y.Offset + delta.Y
            )
    end
end)

--==============================================================
-- TOGGLES
--==============================================================

ToggleButton.Activated:Connect(function()

    _G.AlitHubFarmActive = not _G.AlitHubFarmActive

    ToggleButton.BackgroundColor3 =
        _G.AlitHubFarmActive
        and Color3.fromRGB(15, 30, 15)
        or Color3.fromRGB(30, 15, 15)

    ToggleButton.TextColor3 =
        _G.AlitHubFarmActive
        and ON_GREEN
        or OFF_RED

    ToggleButton.Text =
        _G.AlitHubFarmActive
        and "FARM SYSTEM: ON"
        or "FARM SYSTEM: OFF"
end)

RestockButton.Activated:Connect(function()

    _G.AlitHubRestockActive = not _G.AlitHubRestockActive

    RestockButton.BackgroundColor3 =
        _G.AlitHubRestockActive
        and Color3.fromRGB(15, 30, 15)
        or Color3.fromRGB(30, 15, 15)

    RestockButton.TextColor3 =
        _G.AlitHubRestockActive
        and ON_GREEN
        or OFF_RED

    RestockButton.Text =
        _G.AlitHubRestockActive
        and "RESTOCK KIOS: ON"
        or "RESTOCK KIOS: OFF"

    if not _G.AlitHubRestockActive then
        BuildMultiRakUI()
    end
end)

LocalPlayer.CharacterAdded:Connect(function()

    task.wait(1)

    if _G.AlitHubRestockActive
        or _G.AlitHubFarmActive then

        CurrentKios = getMyKios()
    end
end)

--==============================================================
-- BUILD RESTOCK QUEUE
--==============================================================

local function buildRestockQueue()

    local queue = {}

    local kios = getMyKios()

    if not kios then
        return queue
    end

    for _, slotName in ipairs(FIXED_RBXL_SLOTS) do

        local slot = getSlot(kios, slotName)

        if slot and IsTrayEmptyIndependent(slot) then

            local itemName = SlotSpecificTargets[slotName]

            if itemName
                and itemName ~= ""
                and checkItemInBackpackClean(itemName) then

                table.insert(
                    queue,
                    {
                        slotObj = slot,
                        slotName = slotName,
                        itemName = itemName
                    }
                )
            end
        end
    end

    return queue
end

--==============================================================
-- RESTOCK PROCESS
--==============================================================

local restockBusy = false

local function processRestock()

    if restockBusy
        or not _G.AlitHubRestockActive then

        return
    end

    local queue = buildRestockQueue()
    local job = queue[1]

    if not job then
        return
    end

    local part = getMainPart(job.slotObj)

    if not part then
        return
    end

    restockBusy = true

    local teleported = teleportToPart(part)

    if teleported then

        task.wait(RESTOCK_TELEPORT_DELAY)

        if _G.AlitHubRestockActive then

            local equipped = equipItemClean(job.itemName)

            if equipped then

                local filled = false

                for attempt = 1, RESTOCK_MAX_ATTEMPTS do

                    if not _G.AlitHubRestockActive then
                        break
                    end

                    if not IsTrayEmptyIndependent(job.slotObj) then
                        filled = true
                        break
                    end

                    print(
                        "[ALIT RESTOCK] ATTEMPT:",
                        attempt,
                        "/",
                        RESTOCK_MAX_ATTEMPTS,
                        "| SLOT:",
                        job.slotName
                    )

                    local restockPressed =
                        performRestock(
                            job.slotObj,
                            job.itemName
                        )

                    if restockPressed then

                        task.wait(RESTOCK_HOLD_DELAY)

                        local verifyEnd =
                            tick() + RESTOCK_VERIFY_TIMEOUT

                        while
                            IsTrayEmptyIndependent(job.slotObj)
                            and tick() < verifyEnd
                            and _G.AlitHubRestockActive
                        do
                            task.wait(RESTOCK_CHECK_DELAY)
                        end

                        if not IsTrayEmptyIndependent(job.slotObj) then

                            filled = true

                            print(
                                "[ALIT RESTOCK] BERHASIL:",
                                job.slotName
                            )

                            break
                        end

                        warn(
                            "[ALIT RESTOCK] BELUM TERISI:",
                            job.slotName,
                            "| Attempt:",
                            attempt
                        )

                    else

                        warn(
                            "[ALIT RESTOCK] GAGAL MENEKAN PROMPT:",
                            job.slotName
                        )
                    end

                    if attempt < RESTOCK_MAX_ATTEMPTS then
                        task.wait(0.3)
                    end
                end

                if filled then
                    task.wait(RESTOCK_COOLDOWN)
                else

                    warn(
                        "[ALIT RESTOCK] SLOT GAGAL SETELAH",
                        RESTOCK_MAX_ATTEMPTS,
                        "PERCOBAAN:",
                        job.slotName
                    )

                    task.wait(1.0)
                end

            else

                warn(
                    "[ALIT RESTOCK] ITEM GAGAL DI-EQUIP:",
                    job.itemName
                )

                task.wait(0.5)
            end
        end
    end

    restockBusy = false
end

--==============================================================
-- FARM PROCESS
--==============================================================

local farmBusy = false

local function processFarm()

    if farmBusy
        or not _G.AlitHubFarmActive
        or #SelectedTargets == 0 then

        return
    end

    local queue = buildRestockQueue()

    if #queue > 0 then
        return
    end

    farmBusy = true

    local spawnFolder =
        workspace:FindFirstChild("SpawnBahan")

    if spawnFolder then

        for _, object in ipairs(spawnFolder:GetChildren()) do

            if not _G.AlitHubFarmActive
                or #buildRestockQueue() > 0 then

                break
            end

            -- SelectedTargets sekarang berisi:
            -- Spawn_Dupa
            -- Spawn_Gagak
            -- Spawn_JamurKuburan
            -- dst.

            if table.find(
                SelectedTargets,
                object.Name
            ) then

                local prompt = getPrompt(object)

                if prompt and prompt.Enabled then

                    local part = getMainPart(object)

                    if part and teleportToPart(part) then

                        task.wait(FARM_TELEPORT_DELAY)

                        if _G.AlitHubFarmActive then

                            performHarvest(object)

                            task.wait(FARM_COOLDOWN)
                        end

                        break
                    end
                end
            end
        end
    end

    farmBusy = false
end

--==============================================================
-- CENTRAL ENGINE
-- PRIORITAS:
-- 1. RESTOCK
-- 2. FARM
--==============================================================

task.spawn(function()

    while ScreenGui.Parent do

        if _G.AlitHubRestockActive
            and not restockBusy then

            local restockQueue =
                buildRestockQueue()

            if #restockQueue > 0 then

                processRestock()

            elseif _G.AlitHubFarmActive
                and not farmBusy then

                processFarm()
            end

        elseif _G.AlitHubFarmActive
            and not farmBusy
            and not restockBusy then

            processFarm()
        end

        task.wait(MAIN_LOOP_DELAY)
    end
end)

--==============================================================
-- UI REFRESH
--==============================================================

task.spawn(function()

    while ScreenGui.Parent do

        if not _G.AlitHubRestockActive then

            local kios = getMyKios()

            if kios ~= CurrentKios then
                CurrentKios = kios
                BuildMultiRakUI()
            end
        end

        task.wait(UI_REFRESH_DELAY)
    end
end)

--==============================================================
-- INITIAL BUILD
--==============================================================

task.spawn(function()

    task.wait(0.5)

    BuildMultiRakUI()
end)

print(
    "[ALIT HUB V3] Exact Repair Edition loaded."
)

print(
    "[ALIT HUB] Restock E Hold = 0.5 seconds."
)

print(
    "[ALIT HUB] Restock retry = 3 attempts without repeated teleport."
)

print(
    "[ALIT HUB] Farm target mapping repaired."
)
