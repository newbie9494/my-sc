```lua
--[[
    ALIT HUB V3 FIXED
    ------------------------------------------------------------
    Studio-safe LocalScript foundation
    FIFO RESTOCK: slot1 -> slot12
    AUTO FARM target selection
    AUTO STOCK configuration
    ------------------------------------------------------------

    IMPORTANT:
    Interaksi game/server sebaiknya dilakukan melalui RemoteEvent
    milik game sendiri. Executor-specific API sengaja tidak digunakan.
]]

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

-- Jangan gunakan pairs() untuk urutan yang harus tetap.
local TARGET_ORDER = {
    "Dupa",
    "Gagak",
    "Jamur Kuburan",
    "Kemenyan",
    "Kepiting Sungai",
    "Melati",
}

local FIXED_RBXL_SLOTS = {
    "slot1",
    "slot2",
    "slot3",
    "slot4",
    "slot5",
    "slot6",
    "slot7",
    "slot8",
    "slot9",
    "slot10",
    "slot11",
    "slot12",
}

--==============================================================
-- DELAY CONFIG
--==============================================================

local RESTOCK_TELEPORT_DELAY = 0.3
local RESTOCK_HOLD_DELAY = 0.4
local RESTOCK_COOLDOWN = 0.6

local FARM_TELEPORT_DELAY = 0.2
local FARM_COOLDOWN = 1.0

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

local GLOBAL_SAVED_POS =
    UDim2.new(0.5, -175, 0.3, -110)

local CurrentKios = nil

--==============================================================
-- UTILITY
--==============================================================

local function getCharacter()
    local character = LocalPlayer.Character

    if not character then
        return nil
    end

    return character
end

local function getRoot()
    local character = getCharacter()

    if not character then
        return nil
    end

    return character:FindFirstChild("HumanoidRootPart")
end

local function getHumanoid()
    local character = getCharacter()

    if not character then
        return nil
    end

    return character:FindFirstChildOfClass("Humanoid")
end

--==============================================================
-- KIOS FINDER
--==============================================================

local function getMyKios()
    local kiosAktif = workspace:FindFirstChild("KiosAktif")

    if not kiosAktif then
        return nil
    end

    local kios =
        kiosAktif:FindFirstChild("Kios_" .. LocalPlayer.Name)
        or kiosAktif:FindFirstChild("Kios_panggil_" .. LocalPlayer.Name)

    return kios
end

--==============================================================
-- SLOT FINDER
--==============================================================

local function getSlot(kios, slotName)
    if not kios then
        return nil
    end

    local slot = kios:FindFirstChild(slotName)

    if slot then
        return slot
    end

    local number =
        string.match(slotName, "%d+")

    if number then
        return kios:FindFirstChild("slot " .. number)
    end

    return nil
end

--==============================================================
-- INVENTORY NAME CLEANER
--==============================================================

local function cleanToolName(name)
    if not name then
        return ""
    end

    local cleaned =
        string.gsub(name, "%s+x%d+", "")

    cleaned =
        string.gsub(cleaned, "%s+$", "")

    return cleaned
end

--==============================================================
-- INVENTORY SCAN
--==============================================================

local function ScanCurrentInventory()
    table.clear(AutoDetectedTools)

    local foundItems = {}

    local backpack =
        LocalPlayer:FindFirstChild("Backpack")

    local character =
        LocalPlayer.Character

    local function inspect(container)
        if not container then
            return
        end

        for _, object in ipairs(container:GetChildren()) do
            if object:IsA("Tool") then

                local lowerName =
                    string.lower(object.Name)

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

                    local cleanName =
                        cleanToolName(object.Name)

                    if cleanName ~= ""
                        and not foundItems[cleanName] then

                        foundItems[cleanName] = true

                        table.insert(
                            AutoDetectedTools,
                            cleanName
                        )
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
-- CHECK INVENTORY
--==============================================================

local function checkItemInBackpackClean(cleanName)

    if not cleanName or cleanName == "" then
        return false
    end

    local backpack =
        LocalPlayer:FindFirstChild("Backpack")

    local character =
        LocalPlayer.Character

    local function search(container)
        if not container then
            return false
        end

        for _, object in ipairs(container:GetChildren()) do

            if object:IsA("Tool") then

                if cleanToolName(object.Name)
                    == cleanName then

                    return true
                end
            end
        end

        return false
    end

    return search(backpack)
        or search(character)
end

--==============================================================
-- EQUIP TOOL
--==============================================================

local function equipItemClean(cleanName)

    if not cleanName or cleanName == "" then
        return false
    end

    local backpack =
        LocalPlayer:FindFirstChild("Backpack")

    local humanoid =
        getHumanoid()

    if not backpack or not humanoid then
        return false
    end

    for _, object in ipairs(backpack:GetChildren()) do

        if object:IsA("Tool")
            and cleanToolName(object.Name)
                == cleanName then

            humanoid:EquipTool(object)

            return true
        end
    end

    return false
end

--==============================================================
-- SAFE TELEPORT
--==============================================================

local function teleportToPart(part)

    if not part then
        return false
    end

    local root = getRoot()

    if not root then
        return false
    end

    if not part:IsA("BasePart") then
        return false
    end

    root.CFrame =
        part.CFrame + Vector3.new(0, 3, 0)

    root.AssemblyLinearVelocity =
        Vector3.zero

    root.AssemblyAngularVelocity =
        Vector3.zero

    return true
end

--==============================================================
-- FIND BASEPART
--==============================================================

local function getMainPart(object)

    if not object then
        return nil
    end

    if object:IsA("BasePart") then
        return object
    end

    return object:FindFirstChildWhichIsA(
        "BasePart",
        true
    )
end

--==============================================================
-- CHECK TRAY
--==============================================================

local function IsTrayEmptyIndependent(slotObj)

    if not slotObj then
        return true
    end

    local stokFolder =
        slotObj:FindFirstChild("Stok")

    if not stokFolder then
        return true
    end

    for _, item in ipairs(stokFolder:GetChildren()) do

        if item:IsA("IntValue")
            and item.Value > 0 then

            return false
        end
    end

    return true
end

--==============================================================
-- FIND PROMPT
--==============================================================

local function getPrompt(object)

    if not object then
        return nil
    end

    return object:FindFirstChildWhichIsA(
        "ProximityPrompt",
        true
    )
end

--==============================================================
-- SERVER INTERACTION PLACEHOLDER
--==============================================================
-- Untuk game milik sendiri, hubungkan fungsi ini ke sistem
-- server melalui RemoteEvent milik game.
--
-- Contoh:
--
-- ReplicatedStorage
--     Remotes
--         RestockRequest
--
-- ServerScript:
--     RestockRequest.OnServerEvent:Connect(...)
--
-- Client:
--     RestockRequest:FireServer(slot, item)
--
-- Jangan mengandalkan fireproximityprompt/executor API.

local function performRestock(slotObj, itemName)

    if not slotObj then
        return false
    end

    if not itemName or itemName == "" then
        return false
    end

    local prompt =
        getPrompt(slotObj)

    if not prompt then
        warn(
            "[ALIT HUB] Prompt tidak ditemukan:",
            slotObj:GetFullName()
        )

        return false
    end

    if not prompt.Enabled then
        return false
    end

    --==========================================================
    -- HUBUNGKAN DENGAN REMOTEEVENT SERVER GAME-MU DI SINI
    --==========================================================

    -- Contoh struktur:
    --
    -- local ReplicatedStorage = game:GetService("ReplicatedStorage")
    -- local Remotes = ReplicatedStorage:FindFirstChild("Remotes")
    -- local RestockRequest = Remotes and Remotes:FindFirstChild("RestockRequest")
    --
    -- if RestockRequest then
    --     RestockRequest:FireServer(slotObj, itemName)
    --     return true
    -- end

    warn(
        "[ALIT HUB] performRestock belum terhubung ke server:",
        itemName
    )

    return false
end

--==============================================================
-- FARM INTERACTION PLACEHOLDER
--==============================================================

local function performHarvest(targetObject)

    if not targetObject then
        return false
    end

    local prompt =
        getPrompt(targetObject)

    if not prompt then
        return false
    end

    if not prompt.Enabled then
        return false
    end

    -- Hubungkan ke sistem server game sendiri.
    --
    -- Contoh:
    -- HarvestRequest:FireServer(targetObject)

    warn(
        "[ALIT HUB] performHarvest belum terhubung ke server:",
        targetObject.Name
    )

    return false
end

--==============================================================
-- SCREEN GUI
--==============================================================

local ScreenGui =
    Instance.new("ScreenGui")

ScreenGui.Name =
    "AlitHubUI"

ScreenGui.ResetOnSpawn =
    false

ScreenGui.Parent =
    PlayerGui

--==============================================================
-- MAIN FRAME
--==============================================================

local MainFrame =
    Instance.new("Frame")

MainFrame.Name =
    "MainFrame"

MainFrame.Parent =
    ScreenGui

MainFrame.BackgroundColor3 =
    BG_COLOR

MainFrame.Position =
    GLOBAL_SAVED_POS

MainFrame.Size =
    UDim2.new(0, 350, 0, 220)

MainFrame.BorderSizePixel =
    1

MainFrame.BorderColor3 =
    ACCENT_GOLD

MainFrame.ClipsDescendants =
    true

MainFrame.Active =
    true

local mainCorner =
    Instance.new("UICorner")

mainCorner.CornerRadius =
    UDim.new(0, 8)

mainCorner.Parent =
    MainFrame

--==============================================================
-- TOP BAR
--==============================================================

local TopBar =
    Instance.new("Frame")

TopBar.Name =
    "TopBar"

TopBar.Parent =
    MainFrame

TopBar.BackgroundTransparency =
    1

TopBar.Size =
    UDim2.new(1, 0, 0, 35)

local TitleLabel =
    Instance.new("TextLabel")

TitleLabel.Name =
    "TitleLabel"

TitleLabel.Parent =
    TopBar

TitleLabel.BackgroundTransparency =
    1

TitleLabel.Position =
    UDim2.new(0, 12, 0, 0)

TitleLabel.Size =
    UDim2.new(0, 150, 0, 35)

TitleLabel.Font =
    Enum.Font.GothamBold

TitleLabel.Text =
    "ALIT HUB V3"

TitleLabel.TextColor3 =
    ACCENT_GOLD

TitleLabel.TextSize =
    12

TitleLabel.TextXAlignment =
    Enum.TextXAlignment.Left

--==============================================================
-- MINIMIZE
--==============================================================

local MiniButton =
    Instance.new("TextButton")

MiniButton.Name =
    "MiniButton"

MiniButton.Parent =
    TopBar

MiniButton.BackgroundTransparency =
    1

MiniButton.Position =
    UDim2.new(1, -30, 0, 0)

MiniButton.Size =
    UDim2.new(0, 25, 0, 35)

MiniButton.Font =
    Enum.Font.GothamBold

MiniButton.Text =
    "-"

MiniButton.TextColor3 =
    TEXT_LIGHT

MiniButton.TextSize =
    20

--==============================================================
-- SIDEBAR
--==============================================================

local LeftSidebar =
    Instance.new("Frame")

LeftSidebar.Name =
    "LeftSidebar"

LeftSidebar.Parent =
    MainFrame

LeftSidebar.BackgroundColor3 =
    SIDEBAR_COLOR

LeftSidebar.Position =
    UDim2.new(0, 0, 0, 35)

LeftSidebar.Size =
    UDim2.new(0, 95, 1, -35)

LeftSidebar.BorderSizePixel =
    0

local SidebarLayout =
    Instance.new("UIListLayout")

SidebarLayout.Parent =
    LeftSidebar

SidebarLayout.SortOrder =
    Enum.SortOrder.LayoutOrder

SidebarLayout.Padding =
    UDim.new(0, 4)

--==============================================================
-- CONTENT
--==============================================================

local ContentArea =
    Instance.new("Frame")

ContentArea.Name =
    "ContentArea"

ContentArea.Parent =
    MainFrame

ContentArea.BackgroundTransparency =
    1

ContentArea.Position =
    UDim2.new(0, 100, 0, 35)

ContentArea.Size =
    UDim2.new(1, -105, 1, -40)

--==============================================================
-- OPEN BUTTON
--==============================================================

local OpenButton =
    Instance.new("TextButton")

OpenButton.Name =
    "OpenButton"

OpenButton.Parent =
    ScreenGui

OpenButton.BackgroundColor3 =
    BG_COLOR

OpenButton.Position =
    UDim2.new(0, 10, 0.4, 0)

OpenButton.Size =
    UDim2.new(0, 45, 0, 30)

OpenButton.Font =
    Enum.Font.GothamBold

OpenButton.Text =
    "ALIT"

OpenButton.TextColor3 =
    ACCENT_GOLD

OpenButton.TextSize =
    10

OpenButton.BorderSizePixel =
    1

OpenButton.BorderColor3 =
    ACCENT_GOLD

OpenButton.Visible =
    false

local openCorner =
    Instance.new("UICorner")

openCorner.CornerRadius =
    UDim.new(0, 5)

openCorner.Parent =
    OpenButton

--==============================================================
-- MINIMIZE EVENTS
--==============================================================

MiniButton.Activated:Connect(function()

    GLOBAL_SAVED_POS =
        MainFrame.Position

    MainFrame.Visible =
        false

    OpenButton.Visible =
        true
end)

OpenButton.Activated:Connect(function()

    OpenButton.Visible =
        false

    MainFrame.Position =
        GLOBAL_SAVED_POS

    MainFrame.Visible =
        true
end)

--==============================================================
-- TABS
--==============================================================

local SidebarButtons = {
    "AUTO FARM",
    "AUTO STOCK",
    "AUTO PIG",
    "AUTO COOK",
}

local SubFrames = {}

for index, tabName in ipairs(SidebarButtons) do

    local button =
        Instance.new("TextButton")

    button.Name =
        tabName .. "Btn"

    button.Parent =
        LeftSidebar

    button.BackgroundColor3 =
        PANEL_COLOR

    button.Size =
        UDim2.new(1, -8, 0, 30)

    button.Font =
        Enum.Font.GothamBold

    button.Text =
        tabName

    button.TextColor3 =
        TEXT_LIGHT

    button.TextSize =
        8

    local corner =
        Instance.new("UICorner")

    corner.CornerRadius =
        UDim.new(0, 4)

    corner.Parent =
        button

    local frame =
        Instance.new("Frame")

    frame.Name =
        tabName .. "Frame"

    frame.Parent =
        ContentArea

    frame.BackgroundTransparency =
        1

    frame.Size =
        UDim2.new(1, 0, 1, 0)

    frame.Visible =
        index == 1

    SubFrames[tabName] =
        frame

    button.Activated:Connect(function()

        for _, otherFrame in pairs(SubFrames) do
            otherFrame.Visible = false
        end

        for _, child in ipairs(LeftSidebar:GetChildren()) do

            if child:IsA("TextButton") then
                child.TextColor3 =
                    TEXT_LIGHT

                child.BackgroundColor3 =
                    PANEL_COLOR
            end
        end

        frame.Visible =
            true

        button.TextColor3 =
            ACCENT_GOLD

        button.BackgroundColor3 =
            Color3.fromRGB(30, 25, 20)
    end)

    if index == 1 then
        button.TextColor3 =
            ACCENT_GOLD

        button.BackgroundColor3 =
            Color3.fromRGB(30, 25, 20)
    end
end

--==============================================================
-- AUTO FARM UI
--==============================================================

local ToggleButton =
    Instance.new("TextButton")

ToggleButton.Size =
    UDim2.new(1, 0, 0, 28)

ToggleButton.BackgroundColor3 =
    Color3.fromRGB(30, 15, 15)

ToggleButton.Font =
    Enum.Font.GothamBold

ToggleButton.Text =
    "FARM SYSTEM: OFF"

ToggleButton.TextColor3 =
    OFF_RED

ToggleButton.TextSize =
    9

ToggleButton.Parent =
    SubFrames["AUTO FARM"]

local toggleCorner =
    Instance.new("UICorner")

toggleCorner.CornerRadius =
    UDim.new(0, 4)

toggleCorner.Parent =
    ToggleButton

--==============================================================
-- TARGET DROPDOWN
--==============================================================

local DropdownButton =
    Instance.new("TextButton")

DropdownButton.Position =
    UDim2.new(0, 0, 0, 34)

DropdownButton.Size =
    UDim2.new(1, 0, 0, 24)

DropdownButton.BackgroundColor3 =
    Color3.fromRGB(22, 22, 22)

DropdownButton.Font =
    Enum.Font.GothamSemibold

DropdownButton.Text =
    "SELECT TARGETS ▼"

DropdownButton.TextColor3 =
    TEXT_LIGHT

DropdownButton.TextSize =
    9

DropdownButton.Parent =
    SubFrames["AUTO FARM"]

local dropdownCorner =
    Instance.new("UICorner")

dropdownCorner.CornerRadius =
    UDim.new(0, 4)

dropdownCorner.Parent =
    DropdownButton

local ListContainer =
    Instance.new("ScrollingFrame")

ListContainer.Position =
    UDim2.new(0, 0, 0, 62)

ListContainer.Size =
    UDim2.new(1, 0, 1, -62)

ListContainer.BackgroundColor3 =
    Color3.fromRGB(12, 12, 12)

ListContainer.BorderSizePixel =
    0

ListContainer.ScrollBarThickness =
    2

ListContainer.Visible =
    false

ListContainer.Parent =
    SubFrames["AUTO FARM"]

local UIListLayout =
    Instance.new("UIListLayout")

UIListLayout.Parent =
    ListContainer

UIListLayout.SortOrder =
    Enum.SortOrder.LayoutOrder

UIListLayout.Padding =
    UDim.new(0, 2)

--==============================================================
-- TARGET BUTTONS
--==============================================================

for index, displayName in ipairs(TARGET_ORDER) do

    local workspaceName =
        TARGET_MAPPING[displayName]

    local button =
        Instance.new("TextButton")

    button.LayoutOrder =
        index

    button.Size =
        UDim2.new(1, 0, 0, 20)

    button.BackgroundColor3 =
        PANEL_COLOR

    button.Text =
        "  " .. displayName

    button.TextColor3 =
        TEXT_LIGHT

    button.Font =
        Enum.Font.GothamSemibold

    button.TextSize =
        9

    button.TextXAlignment =
        Enum.TextXAlignment.Left

    button.Parent =
        ListContainer

    local corner =
        Instance.new("UICorner")

    corner.CornerRadius =
        UDim.new(0, 4)

    corner.Parent =
        button

    button.Activated:Connect(function()

        local existing =
            table.find(
                SelectedTargets,
                workspaceName
            )

        if existing then

            table.remove(
                SelectedTargets,
                existing
            )

            button.TextColor3 =
                TEXT_LIGHT

            button.BackgroundColor3 =
                PANEL_COLOR

        else

            table.insert(
                SelectedTargets,
                workspaceName
            )

            button.TextColor3 =
                BG_COLOR

            button.BackgroundColor3 =
                ACCENT_GOLD
        end
    end)
end

ListContainer.CanvasSize =
    UDim2.new(0, 0, 0, #TARGET_ORDER * 22)

DropdownButton.Activated:Connect(function()

    ListContainer.Visible =
        not ListContainer.Visible

    DropdownButton.Text =
        ListContainer.Visible
        and "SELECT TARGETS ▲"
        or "SELECT TARGETS ▼"
end)

--==============================================================
-- AUTO STOCK UI
--==============================================================

local RestockButton =
    Instance.new("TextButton")

RestockButton.Size =
    UDim2.new(1, 0, 0, 28)

RestockButton.BackgroundColor3 =
    Color3.fromRGB(30, 15, 15)

RestockButton.Font =
    Enum.Font.GothamBold

RestockButton.Text =
    "RESTOCK KIOS: OFF"

RestockButton.TextColor3 =
    OFF_RED

RestockButton.TextSize =
    9

RestockButton.Parent =
    SubFrames["AUTO STOCK"]

local restockCorner =
    Instance.new("UICorner")

restockCorner.CornerRadius =
    UDim.new(0, 4)

restockCorner.Parent =
    RestockButton

--==============================================================
-- MASTER SCROLL
--==============================================================

local MasterScroll =
    Instance.new("ScrollingFrame")

MasterScroll.Name =
    "MasterScroll"

MasterScroll.Position =
    UDim2.new(0, 0, 0, 34)

MasterScroll.Size =
    UDim2.new(1, 0, 1, -38)

MasterScroll.BackgroundColor3 =
    Color3.fromRGB(10, 10, 10)

MasterScroll.BorderSizePixel =
    0

MasterScroll.ScrollBarThickness =
    3

MasterScroll.Parent =
    SubFrames["AUTO STOCK"]

local UIMasterLayout =
    Instance.new("UIListLayout")

UIMasterLayout.Parent =
    MasterScroll

UIMasterLayout.Padding =
    UDim.new(0, 4)

--==============================================================
-- PLACEHOLDER TABS
--==============================================================

local PigLabel =
    Instance.new("TextLabel")

PigLabel.Size =
    UDim2.new(1, 0, 0, 30)

PigLabel.BackgroundTransparency =
    1

PigLabel.Font =
    Enum.Font.GothamBold

PigLabel.Text =
    "PIG CONFIGURATION"

PigLabel.TextColor3 =
    TEXT_DARK

PigLabel.TextSize =
    8

PigLabel.Parent =
    SubFrames["AUTO PIG"]

local CookLabel =
    Instance.new("TextLabel")

CookLabel.Size =
    UDim2.new(1, 0, 0, 30)

CookLabel.BackgroundTransparency =
    1

CookLabel.Font =
    Enum.Font.GothamBold

CookLabel.Text =
    "COOK CONFIGURATION"

CookLabel.TextColor3 =
    TEXT_DARK

CookLabel.TextSize =
    8

CookLabel.Parent =
    SubFrames["AUTO COOK"]

--==============================================================
-- BUILD STOCK UI
--==============================================================

local function BuildMultiRakUI()

    for _, child in ipairs(MasterScroll:GetChildren()) do

        if child:IsA("Frame") then
            child:Destroy()
        end
    end

    CurrentKios =
        getMyKios()

    ScanCurrentInventory()

    if not CurrentKios then

        local message =
            Instance.new("TextLabel")

        message.Size =
            UDim2.new(1, -10, 0, 30)

        message.BackgroundTransparency =
            1

        message.Text =
            "KIOS BELUM DITEMUKAN"

        message.TextColor3 =
            OFF_RED

        message.Font =
            Enum.Font.GothamBold

        message.TextSize =
            8

        message.Parent =
            MasterScroll

        return
    end

    for slotIndex, slotName in ipairs(FIXED_RBXL_SLOTS) do

        local slotObj =
            getSlot(CurrentKios, slotName)

        if slotObj then

            if SlotSpecificTargets[slotName] == nil then
                SlotSpecificTargets[slotName] = ""
            end

            local row =
                Instance.new("Frame")

            row.Name =
                slotName .. "Row"

            row.LayoutOrder =
                slotIndex

            row.Size =
                UDim2.new(1, -4, 0, 32)

            row.BackgroundColor3 =
                PANEL_COLOR

            row.Parent =
                MasterScroll

            local rowCorner =
                Instance.new("UICorner")

            rowCorner.CornerRadius =
                UDim.new(0, 4)

            rowCorner.Parent =
                row

            local label =
                Instance.new("TextLabel")

            label.Size =
                UDim2.new(0, 60, 1, 0)

            label.Position =
                UDim2.new(0, 6, 0, 0)

            label.BackgroundTransparency =
                1

            label.Font =
                Enum.Font.GothamBold

            label.Text =
                string.upper(slotName)

            label.TextColor3 =
                TEXT_LIGHT

            label.TextSize =
                8

            label.TextXAlignment =
                Enum.TextXAlignment.Left

            label.Parent =
                row

            local dropdown =
                Instance.new("TextButton")

            dropdown.Size =
                UDim2.new(1, -70, 0, 20)

            dropdown.Position =
                UDim2.new(0, 64, 0, 6)

            dropdown.BackgroundColor3 =
                Color3.fromRGB(30, 30, 30)

            dropdown.Font =
                Enum.Font.GothamSemibold

            dropdown.Text =
                SlotSpecificTargets[slotName] ~= ""
                and SlotSpecificTargets[slotName] .. " ▼"
                or "NONE ▼"

            dropdown.TextColor3 =
                ACCENT_GOLD

            dropdown.TextSize =
                7

            dropdown.Parent =
                row

            local dropdownCorner =
                Instance.new("UICorner")

            dropdownCorner.CornerRadius =
                UDim.new(0, 4)

            dropdownCorner.Parent =
                dropdown

            local optionContainer =
                Instance.new("ScrollingFrame")

            optionContainer.Size =
                UDim2.new(1, -10, 0, 70)

            optionContainer.Position =
                UDim2.new(0, 5, 0, 34)

            optionContainer.BackgroundColor3 =
                Color3.fromRGB(15, 15, 15)

            optionContainer.BorderSizePixel =
                0

            optionContainer.ScrollBarThickness =
                2

            optionContainer.Visible =
                false

            optionContainer.ZIndex =
                10

            optionContainer.Parent =
                row

            local optionLayout =
                Instance.new("UIListLayout")

            optionLayout.Parent =
                optionContainer

            optionLayout.Padding =
                UDim.new(0, 2)

            local function closeOptions()

                optionContainer.Visible =
                    false

                row.Size =
                    UDim2.new(1, -4, 0, 32)
            end

            local function makeOption(
                text,
                callback
            )

                local option =
                    Instance.new("TextButton")

                option.Size =
                    UDim2.new(1, 0, 0, 18)

                option.BackgroundColor3 =
                    Color3.fromRGB(25, 25, 25)

                option.Text =
                    "  " .. text

                option.TextColor3 =
                    TEXT_LIGHT

                option.Font =
                    Enum.Font.GothamSemibold

                option.TextSize =
                    7

                option.TextXAlignment =
                    Enum.TextXAlignment.Left

                option.ZIndex =
                    11

                option.Parent =
                    optionContainer

                local corner =
                    Instance.new("UICorner")

                corner.CornerRadius =
                    UDim.new(0, 3)

                corner.Parent =
                    option

                option.Activated:Connect(
                    callback
                )
            end

            dropdown.Activated:Connect(function()

                if optionContainer.Visible then
                    closeOptions()
                    return
                end

                for _, child in ipairs(
                    optionContainer:GetChildren()
                ) do

                    if child:IsA("TextButton") then
                        child:Destroy()
                    end
                end

                ScanCurrentInventory()

                makeOption(
                    "NONE",
                    function()

                        SlotSpecificTargets[slotName] =
                            ""

                        dropdown.Text =
                            "NONE ▼"

                        closeOptions()
                    end
                )

                for _, itemName in ipairs(
                    AutoDetectedTools
                ) do

                    local capturedName =
                        itemName

                    makeOption(
                        capturedName,
                        function()

                            SlotSpecificTargets[slotName] =
                                capturedName

                            dropdown.Text =
                                capturedName .. " ▼"

                            closeOptions()
                        end
                    )
                end

                local itemCount =
                    #AutoDetectedTools + 1

                optionContainer.CanvasSize =
                    UDim2.new(
                        0,
                        0,
                        0,
                        itemCount * 20
                    )

                optionContainer.Visible =
                    true

                row.Size =
                    UDim2.new(1, -4, 0, 108)
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
-- INITIAL UI BUILD
--==============================================================

task.spawn(function()

    task.wait(0.5)

    BuildMultiRakUI()

end)

--==============================================================
-- DRAG MAIN WINDOW
--==============================================================

local dragToggle = false
local dragStart = nil
local startPos = nil

MainFrame.InputBegan:Connect(function(input)

    if input.UserInputType
        ~= Enum.UserInputType.MouseButton1
        and input.UserInputType
        ~= Enum.UserInputType.Touch then

        return
    end

    dragToggle =
        true

    dragStart =
        input.Position

    startPos =
        MainFrame.Position

    input.Changed:Connect(function()

        if input.UserInputState
            == Enum.UserInputState.End then

            dragToggle =
                false
        end
    end)
end)

UserInputService.InputChanged:Connect(function(input)

    if not dragToggle then
        return
    end

    if input.UserInputType
        ~= Enum.UserInputType.MouseMovement
        and input.UserInputType
        ~= Enum.UserInputType.Touch then

        return
    end

    local delta =
        input.Position - dragStart

    MainFrame.Position =
        UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
end)

--==============================================================
-- DRAG OPEN BUTTON
--==============================================================

local openDrag = false
local openStart = nil
local openStartPos = nil

OpenButton.InputBegan:Connect(function(input)

    if input.UserInputType
        ~= Enum.UserInputType.MouseButton1
        and input.UserInputType
        ~= Enum.UserInputType.Touch then

        return
    end

    openDrag =
        true

    openStart =
        input.Position

    openStartPos =
        OpenButton.Position

    input.Changed:Connect(function()

        if input.UserInputState
            == Enum.UserInputState.End then

            openDrag =
                false
        end
    end)
end)

UserInputService.InputChanged:Connect(function(input)

    if not openDrag then
        return
    end

    if input.UserInputType
        ~= Enum.UserInputType.MouseMovement
        and input.UserInputType
        ~= Enum.UserInputType.Touch then

        return
    end

    local delta =
        input.Position - openStart

    OpenButton.Position =
        UDim2.new(
            openStartPos.X.Scale,
            openStartPos.X.Offset + delta.X,
            openStartPos.Y.Scale,
            openStartPos.Y.Offset + delta.Y
        )
end)

--==============================================================
-- FARM TOGGLE
--==============================================================

ToggleButton.Activated:Connect(function()

    _G.AlitHubFarmActive =
        not _G.AlitHubFarmActive

    if _G.AlitHubFarmActive then

        ToggleButton.BackgroundColor3 =
            Color3.fromRGB(15, 30, 15)

        ToggleButton.TextColor3 =
            ON_GREEN

        ToggleButton.Text =
            "FARM SYSTEM: ON"

    else

        ToggleButton.BackgroundColor3 =
            Color3.fromRGB(30, 15, 15)

        ToggleButton.TextColor3 =
            OFF_RED

        ToggleButton.Text =
            "FARM SYSTEM: OFF"
    end
end)

--==============================================================
-- RESTOCK TOGGLE
--==============================================================

RestockButton.Activated:Connect(function()

    _G.AlitHubRestockActive =
        not _G.AlitHubRestockActive

    if _G.AlitHubRestockActive then

        RestockButton.BackgroundColor3 =
            Color3.fromRGB(15, 30, 15)

        RestockButton.TextColor3 =
            ON_GREEN

        RestockButton.Text =
            "RESTOCK KIOS: ON"

    else

        RestockButton.BackgroundColor3 =
            Color3.fromRGB(30, 15, 15)

        RestockButton.TextColor3 =
            OFF_RED

        RestockButton.Text =
            "RESTOCK KIOS: OFF"

        BuildMultiRakUI()
    end
end)

--==============================================================
-- CHARACTER RESPAWN
--==============================================================

LocalPlayer.CharacterAdded:Connect(function()

    -- Pastikan sistem tidak menggunakan character lama.
    task.wait(1)

    if _G.AlitHubRestockActive
        or _G.AlitHubFarmActive then

        CurrentKios =
            getMyKios()
    end
end)

--==============================================================
-- FIFO RESTOCK
--==============================================================

local function buildRestockQueue()

    local queue = {}

    local kios =
        getMyKios()

    if not kios then
        return queue
    end

    --==========================================================
    -- PENTING:
    -- ipairs(FIXED_RBXL_SLOTS) menjamin:
    --
    -- slot1
    -- slot2
    -- slot3
    -- ...
    -- slot12
    --
    -- Tidak menggunakan pairs().
    --==========================================================

    for _, slotName in ipairs(
        FIXED_RBXL_SLOTS
    ) do

        local slot =
            getSlot(kios, slotName)

        if slot then

            if IsTrayEmptyIndependent(slot) then

                local itemName =
                    SlotSpecificTargets[slotName]

                if itemName
                    and itemName ~= ""
                    and checkItemInBackpackClean(
                        itemName
                    ) then

                    table.insert(
                        queue,
                        {
                            slotObj = slot,
                            slotName = slotName,
                            itemName = itemName,
                        }
                    )
                end
            end
        end
    end

    return queue
end

--==============================================================
-- RESTOCK LOOP
--==============================================================

local restockBusy = false

local function processRestock()

    if restockBusy then
        return
    end

    if not _G.AlitHubRestockActive then
        return
    end

    restockBusy =
        true

    local queue =
        buildRestockQueue()

    -- Hanya slot pertama yang diproses.
    local job =
        queue[1]

    if job then

        local part =
            getMainPart(job.slotObj)

        if part then

            local teleported =
                teleportToPart(part)

            if teleported then

                task.wait(
                    RESTOCK_TELEPORT_DELAY
                )

                if _G.AlitHubRestockActive then

                    if equipItemClean(
                        job.itemName
                    ) then

                        -- Interaksi server game sendiri.
                        performRestock(
                            job.slotObj,
                            job.itemName
                        )

                        task.wait(
                            RESTOCK_HOLD_DELAY
                        )

                        task.wait(
                            RESTOCK_COOLDOWN
                        )
                    end
                end
            end
        end
    end

    restockBusy =
        false
end

--==============================================================
-- FARM LOOP
--==============================================================

local farmBusy = false

local function processFarm()

    if farmBusy then
        return
    end

    if not _G.AlitHubFarmActive then
        return
    end

    if #SelectedTargets == 0 then
        return
    end

    -- Restock selalu diprioritaskan.
    local queue =
        buildRestockQueue()

    if #queue > 0 then
        return
    end

    farmBusy =
        true

    local spawnFolder =
        workspace:FindFirstChild(
            "SpawnBahan"
        )

    if spawnFolder then

        for _, object in ipairs(
            spawnFolder:GetChildren()
        ) do

            if not _G.AlitHubFarmActive then
                break
            end

            -- Jika ada stok kios kosong,
            -- farm berhenti sementara.
            local currentQueue =
                buildRestockQueue()

            if #currentQueue > 0 then
                break
            end

            if table.find(
                SelectedTargets,
                object.Name
            ) then

                local prompt =
                    getPrompt(object)

                if prompt
                    and prompt.Enabled then

                    local part =
                        getMainPart(object)

                    if part then

                        if teleportToPart(
                            part
                        ) then

                            task.wait(
                                FARM_TELEPORT_DELAY
                            )

                            if _G.AlitHubFarmActive then

                                performHarvest(
                                    object
                                )

                                task.wait(
                                    FARM_COOLDOWN
                                )

                            end

                            break
                        end
                    end
                end
            end
        end
    end

    farmBusy =
        false
end

--==============================================================
-- MAIN ENGINE
--==============================================================

task.spawn(function()

    while ScreenGui.Parent do

        if _G.AlitHubRestockActive then

            processRestock()

        elseif _G.AlitHubFarmActive then

            processFarm()
        end

        task.wait(
            MAIN_LOOP_DELAY
        )
    end
end)

--==============================================================
-- PERIODIC KIOS/UI REFRESH
--==============================================================

task.spawn(function()

    while ScreenGui.Parent do

        if not _G.AlitHubRestockActive then

            local kios =
                getMyKios()

            if kios ~= CurrentKios then

                CurrentKios =
                    kios

                BuildMultiRakUI()
            end
        end

        task.wait(
            UI_REFRESH_DELAY
        )
    end
end)

--==============================================================
-- FINAL STATUS
--==============================================================

print(
    "[ALIT HUB V3 FIXED] Loaded successfully."
)

print(
    "[ALIT HUB] FIFO order: slot1 -> slot12"
)

print(
    "[ALIT HUB] Standard Roblox API mode."
)
```
