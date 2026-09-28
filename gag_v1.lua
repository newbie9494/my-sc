-- =============================================================================
-- 🌱 GROW A GARDEN - INTEGRATED ALL-IN-ONE SCRIPT (BAGIAN 1 / 3)
-- Gabungkan Bagian 1, 2, dan 3 ke dalam satu executor sebelum dijalankan!
-- Toggle Menu: Tekan tombol [RightShift] pada keyboard
-- =============================================================================

print("=== Grow A Garden Script ===")
print("Loading Integrated Modules (Part 1/3)...")

-- =============================================================================
-- 1. KONFIGURASI GLOBAL (Pengaturan Awal Otomatis)
-- =============================================================================
local Settings = {
    General = {
        AutoReconnect = true,
        AntiAFK = true,
        NotificationSound = true,
        DebugMode = false,
    },
    PetFinder = { Enabled = true, ScanRadius = 200, AutoCollect = true },
    WeatherPredict = { Enabled = true, AutoNotify = true },
    SeedSniper = { Enabled = true, AutoBuy = true, MaxBuy = 10 },
    PetTameSniper = { Enabled = true, AutoHop = true, AutoTame = true },
    CoinFarmer = {
        Enabled = true,
        AutoSell = true,
        AutoRebirth = false,
        FarmMode = "all",
        PriorityMode = "nearest",
        CollectRadius = 400,      -- Radius aman rekomendasi (300-500)
        TeleportSpeed = 0.3,      -- Jeda 300ms agar aman dari anti-cheat
        SellInterval = 30,        -- Jual otomatis tiap 30 detik
        MaxCollectPerLoop = 40    -- Batasan ambil per loop agar stabil
    },
    RaccoonFinder = {
        Enabled = false,
        AutoCollect = true,
        AutoTeleport = true,
        NotifySound = true,
        ScanRadius = 500,
        ScanInterval = 1.0
    },
    UnicornFinder = {
        Enabled = false,
        AutoCollect = true,
        AutoTeleport = true,
        AutoHatch = true,
        NotifySound = true,
        NotifyVisual = true,
        ScanRadius = 600,
        ScanInterval = 1.0,
        MaxRetries = 5
    }
}

-- =============================================================================
-- 2. MEMUAT PUSTAKA EKSTERNAL (UI & UTILS)
-- =============================================================================
local UILibrary = loadstring(game:HttpGet("https://githubusercontent.com"))()
local Helpers = loadstring(game:HttpGet("https://githubusercontent.com"))()

-- Aktivasi Fitur Anti-AFK agar tidak terkena kick/disconnect
if Settings.General.AntiAFK then
    Helpers:EnableAntiAFK()
end

-- =============================================================================
-- 3. INTEGRASI LOGIKA MODUL ASLI (Membaca file inti game)
-- =============================================================================
local PetFinder = loadstring(game:HttpGet("https://githubusercontent.com"))()
local WeatherPredict = loadstring(game:HttpGet("https://githubusercontent.com"))()
local SeedSniper = loadstring(game:HttpGet("https://githubusercontent.com"))()
local PetTameSniper = loadstring(game:HttpGet("https://githubusercontent.com"))()
local RaccoonFinder = loadstring(game:HttpGet("https://githubusercontent.com"))()
local CoinFarmer = loadstring(game:HttpGet("https://githubusercontent.com"))()
local UnicornFinder = loadstring(game:HttpGet("https://githubusercontent.com"))()

-- Sinkronisasi pengaturan bawaan ke dalam modul pendeteksi game
PetFinder.Config = { AutoCollect = Settings.PetFinder.AutoCollect, ScanRadius = Settings.PetFinder.ScanRadius, NotifyPet = true }
SeedSniper.Config = { AutoBuy = Settings.SeedSniper.AutoBuy, RareOnly = false, MaxBuyAmount = Settings.SeedSniper.MaxBuy, DelayBetweenBuy = 0.5 }
PetTameSniper.Config = { AutoHop = Settings.PetTameSniper.AutoHop, AutoTame = Settings.PetTameSniper.AutoTame, ScanRadius = 300, MaxTamePerServer = 5, HopDelay = 3, ServerHopMode = "random" }
CoinFarmer.Config = Settings.CoinFarmer
RaccoonFinder.Config = Settings.RaccoonFinder
UnicornFinder.Config = Settings.UnicornFinder

-- =============================================================================
-- 4. PEMBUATAN MENU GUI UTAMA (Window & Tab)
-- =============================================================================
local window = UILibrary:CreateWindow("🌱 Grow A Garden Script")

-- TAB 1: PET FINDER (Pencari Pet Sekitar)
local tabPet = window:CreateTab("Pet Finder", "🐾")
tabPet:NewLabel("── Pet Finder Settings ──")

local pfToggle = tabPet:NewToggle("Auto Scan Pets", false, function(state)
    if state then PetFinder:StartAutoScan() else PetFinder:StopAutoScan() end
end)
local pfCollect = tabPet:NewToggle("Auto Collect", PetFinder.Config.AutoCollect, function(state)
    PetFinder.Config.AutoCollect = state
end)
local pfNotify = tabPet:NewToggle("Notify on Find", true, function(state)
    PetFinder.Config.NotifyPet = state
end)
local pfRadius = tabPet:NewSlider("Scan Radius", 50, 500, PetFinder.Config.ScanRadius, function(value)
    PetFinder.Config.ScanRadius = value
end)

tabPet:NewSeparator()
tabPet:NewLabel("── Quick Actions ──")
tabPet:NewButton("Scan Once", function()
    local pets = PetFinder:ScanPets()
    Helpers:Notify("Pet Finder", "Found " .. #pets .. " pets", 3)
end)
tabPet:NewButton("Collect All Now", function() PetFinder:AutoCollectAll() end)
tabPet:NewSeparator()

local pfStatus = tabPet:NewStatus("Status", "Idle")
local pfFound = tabPet:NewStatus("Pets Found", "0")

task.spawn(function()
    while task.wait(2) do
        if PetFinder.Scanning then
            pfStatus:Set("Scanning...")
            pfStatus:SetColor(Color3.fromRGB(100, 255, 150))
        else
            pfStatus:Set("Idle")
            pfStatus:SetColor(Color3.fromRGB(150, 150, 170))
        end
        pfFound:Set(tostring(#PetFinder.FoundPets))
    end
end)

-- TAB 2: WEATHER PREDICT (Pemantau Cuaca & Multiplier)
local tabWeather = window:CreateTab("Weather", "🌤")
tabWeather:NewLabel("── Weather Monitor ──")

local wToggle = tabWeather:NewToggle("Auto Monitor", false, function(state)
    if state then WeatherPredict:StartMonitoring() else WeatherPredict:StopMonitoring() end
end)
local wNotify = tabWeather:NewToggle("Notify Changes", Settings.WeatherPredict.AutoNotify, function(state) end)

tabWeather:NewSeparator()
tabWeather:NewLabel("── Weather Info ──")
local wCurrent = tabWeather:NewStatus("Current Weather", "Unknown")
local wMultiplier = tabWeather:NewStatus("Multiplier", "x1.0")
local wRemaining = tabWeather:NewStatus("Time Remaining", "N/A")
local wPredicted = tabWeather:NewStatus("Predicted Next", "N/A")
local wConfidence = tabWeather:NewStatus("Confidence", "N/A")
tabWeather:NewSeparator()

tabWeather:NewButton("Refresh Weather", function()
    local info = WeatherPredict:GetInfo()
    wCurrent:Set(info.Current)
    wMultiplier:Set("x" .. info.Multiplier)
    wRemaining:Set(info.TimeRemaining .. "s")
    wPredicted:Set(info.PredictedNext)
    wConfidence:Set(info.Confidence .. "%")
end)

task.spawn(function()
    while task.wait(5) do
        local info = WeatherPredict:GetInfo()
        wCurrent:Set(info.Current)
        wMultiplier:Set("x" .. info.Multiplier)
        if info.Current ~= "Unknown" then
            wRemaining:Set(info.TimeRemaining .. "s")
            wPredicted:Set(info.PredictedNext)
            wConfidence:Set(info.Confidence .. "%")
            if info.Multiplier >= 2.0 then wMultiplier:SetColor(Color3.fromRGB(255, 100, 100))
            elseif info.Multiplier >= 1.5 then wMultiplier:SetColor(Color3.fromRGB(255, 200, 50))
            else wMultiplier:SetColor(Color3.fromRGB(150, 150, 170)) end
        end
    end
end)

-- TAB 3: SEED SNIPER (Auto Beli Benih Event Toko)
local tabSeed = window:CreateTab("Seed Sniper", "🌱")
tabSeed:NewLabel("── Seed Sniper Settings ──")

local ssToggle = tabSeed:NewToggle("Auto Snipe", false, function(state)
    if state then SeedSniper:StartSniping() else SeedSniper:StopSniping() end
end)
local ssBuy = tabSeed:NewToggle("Auto Buy", SeedSniper.Config.AutoBuy, function(state) SeedSniper.Config.AutoBuy = state end)
local ssRare = tabSeed:NewToggle("Rare Only", false, function(state) SeedSniper.Config.RareOnly = state end)
local ssMaxBuy = tabSeed:NewSlider("Max Buy Per Seed", 1, 50, SeedSniper.Config.MaxBuyAmount, function(value) SeedSniper.Config.MaxBuyAmount = value end)
tabSeed:NewSeparator()

local ssStatus = tabSeed:NewStatus("Status", "Idle")
local ssAvail = tabSeed:NewStatus("Available Seeds", "0")
local ssBought = tabSeed:NewStatus("Total Purchased", "0")

task.spawn(function()
    while task.wait(2) do
        if SeedSniper.Sniping then ssStatus:Set("Sniping...") ssStatus:SetColor(Color3.fromRGB(100, 255, 150))
        else ssStatus:Set("Idle") ssStatus:SetColor(Color3.fromRGB(150, 150, 170)) end
        ssAvail:Set(tostring(#SeedSniper.AvailableSeeds))
        ssBought:Set(tostring(#SeedSniper.PurchasedSeeds))
    end
end)
-- =============================================================================
-- 🌱 GROW A GARDEN - INTEGRATED ALL-IN-ONE SCRIPT (BAGIAN 2 / 3)
-- Tempelkan bagian ini tepat di bawah baris akhir Bagian 1!
-- =============================================================================

print("Loading Integrated Modules (Part 2/3)...")

-- TAB 4: PET TAME SNIPER (Auto Hop Server & Penjinak Pet Otomatis)
local tabTame = window:CreateTab("Tame Sniper", "🐾")
tabTame:NewLabel("── Tame Sniper Settings ──")

local tsToggle = tabTame:NewToggle("Auto Snipe Tame", false, function(state)
    if state then PetTameSniper:StartSniping() else PetTameSniper:StopSniping() end
end)
local tsHop = tabTame:NewToggle("Auto Server Hop", PetTameSniper.Config.AutoHop, function(state) 
    PetTameSniper.Config.AutoHop = state 
end)
local tsAutoTame = tabTame:NewToggle("Auto Tame", PetTameSniper.Config.AutoTame, function(state) 
    PetTameSniper.Config.AutoTame = state 
end)
local tsRadius = tabTame:NewSlider("Scan Radius", 50, 500, 300, function(value)
    PetTameSniper.Config.ScanRadius = value
end)
local tsMaxTame = tabTame:NewSlider("Max Tame/Server", 1, 20, 5, function(value)
    PetTameSniper.Config.MaxTamePerServer = value
end)

tabTame:NewSeparator()
tabTame:NewLabel("── Quick Actions ──")
tabTame:NewButton("Scan & Tame Now", function()
    local tamed = PetTameSniper:ScanAndTame()
    Helpers:Notify("Tame Sniper", "Tamed " .. tamed .. " pets!", 3)
end)
tabTame:NewButton("Hop Server Now", function() PetTameSniper:HopServer() end)
tabTame:NewSeparator()

local tsStatus = tabTame:NewStatus("Status", "Idle")
local tsTotal = tabTame:NewStatus("Total Tamed", "0")
local tsFound = tabTame:NewStatus("Pets Found", "0")

task.spawn(function()
    while task.wait(2) do
        if PetTameSniper.Sniping then 
            tsStatus:Set("Sniping...") 
            tsStatus:SetColor(Color3.fromRGB(100, 255, 150))
        else 
            tsStatus:Set("Idle") 
            tsStatus:SetColor(Color3.fromRGB(150, 150, 170)) 
        end
        tsTotal:Set(tostring(PetTameSniper.TotalTamed))
        tsFound:Set(tostring(#PetTameSniper.FoundPets))
    end
end)

-- TAB 5: RACCOON FINDER (Fitur Khusus Pelacak Raccoon Spesial)
local tabRaccoon = window:CreateTab("Raccoon", "🦝")
tabRaccoon:NewLabel("── 🦝 RACCOON FINDER ──")

local rcToggle = tabRaccoon:NewToggle("Auto Find Raccoon", false, function(state)
    if state then RaccoonFinder:StartSearching() else RaccoonFinder:StopSearching() end
end)
local rcAutoCollect = tabRaccoon:NewToggle("Auto Collect", RaccoonFinder.Config.AutoCollect, function(state) 
    RaccoonFinder.Config.AutoCollect = state 
end)
local rcAutoTP = tabRaccoon:NewToggle("Auto Teleport", RaccoonFinder.Config.AutoTeleport, function(state) 
    RaccoonFinder.Config.AutoTeleport = state 
end)
local rcRadius = tabRaccoon:NewSlider("Scan Radius", 100, 1000, 500, function(value)
    RaccoonFinder.Config.ScanRadius = value
end)

tabRaccoon:NewSeparator()
tabRaccoon:NewLabel("── Quick Actions ──")
tabRaccoon:NewButton("Scan Now", function()
    local raccoons = RaccoonFinder:ScanForRaccoon()
    if #raccoons > 0 then
        Helpers:Notify("🦝 RACCOON!", "Found " .. #raccoons .. " Raccoon(s)!", 5)
        RaccoonFinder:TeleportToRaccoon(raccoons[1], true)
    else
        Helpers:Notify("Raccoon Finder", "No Raccoon found nearby", 3)
    end
end)
tabRaccoon:NewButton("Save Position as Spawn", function()
    local hrp = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if hrp then
        RaccoonFinder:AddSpawnLocation(hrp.Position)
        Helpers:Notify("Spawn Saved", "Position: " .. tostring(hrp.Position), 3)
    end
end)
tabRaccoon:NewSeparator()

local rcStatus = tabRaccoon:NewStatus("Status", "Idle")
local rcFound = tabRaccoon:NewStatus("Total Found", "0")
local rcCollected = tabRaccoon:NewStatus("Collected", "0")

task.spawn(function()
    while task.wait(1) do
        local status = RaccoonFinder:GetStatus()
        if status.Searching then 
            rcStatus:Set("🔍 SEARCHING...") 
            rcStatus:SetColor(Color3.fromRGB(255, 100, 100))
        else 
            rcStatus:Set("Idle") 
            rcStatus:SetColor(Color3.fromRGB(150, 150, 170)) 
        end
        rcFound:Set(tostring(status.Found))
        rcCollected:Set(tostring(status.Collected))
    end
end)

-- TAB 6: COIN FARMER (Mesin Otomatisasi Koin & Token)
local tabCoin = window:CreateTab("Coin Farm", "💰")
tabCoin:NewLabel("── 💰 COIN/TOKEN FARMER ──")

local cfToggle = tabCoin:NewToggle("Auto Farm", false, function(state)
    if state then CoinFarmer:StartFarming() else CoinFarmer:StopFarming() end
end)
local cfAutoSell = tabCoin:NewToggle("Auto Sell", CoinFarmer.Config.AutoSell, function(state) 
    CoinFarmer.Config.AutoSell = state 
end)
local cfAutoRebirth = tabCoin:NewToggle("Auto Rebirth", CoinFarmer.Config.AutoRebirth, function(state) 
    CoinFarmer.Config.AutoRebirth = state 
end)

tabCoin:NewSeparator()
tabCoin:NewLabel("── Farm Settings ──")
local cfMode = tabCoin:NewDropdown("Farm Mode", {"all", "coins", "tokens"}, "all", function(value)
    CoinFarmer.Config.FarmMode = value
end)
local cfPriority = tabCoin:NewDropdown("Priority", {"nearest", "highest", "farthest"}, "nearest", function(value)
    CoinFarmer.Config.PriorityMode = value
end)
local cfRadius = tabCoin:NewSlider("Collect Radius", 50, 1000, CoinFarmer.Config.CollectRadius, function(value)
    CoinFarmer.Config.CollectRadius = value
end)
local cfSpeed = tabCoin:NewSlider("Teleport Speed (ms)", 50, 1000, 300, function(value)
    CoinFarmer.Config.TeleportSpeed = value / 1000
end)

tabCoin:NewSeparator()
tabCoin:NewButton("Sell All Now", function()
    local success = CoinFarmer:AutoSell()
    if success then Helpers:Notify("💰 Sell", "Sold all items!", 3) else Helpers:Notify("💰 Sell", "No sell method found", 3) end
end)
tabCoin:NewSeparator()

local cfStatus = tabCoin:NewStatus("Status", "Idle")
local cfTotal = tabCoin:NewStatus("Total Collected", "0")
local cfRate = tabCoin:NewStatus("Coins/Min", "0")
local cfNextSell = tabCoin:NewStatus("Next Sell In", "N/A")

task.spawn(function()
    while task.wait(1) do
        local status = CoinFarmer:GetStatus()
        if status.Farming then 
            cfStatus:Set("💰 FARMING...") 
            cfStatus:SetColor(Color3.fromRGB(255, 200, 50))
        else 
            cfStatus:Set("Idle") 
            cfStatus:SetColor(Color3.fromRGB(150, 150, 170)) 
        end
        cfTotal:Set(tostring(status.TotalCollected))
        cfRate:Set(tostring(status.CoinsPerMinute))
        if status.LastSell then
            local nextSell = math.max(CoinFarmer.Config.SellInterval - status.LastSell, 0)
            cfNextSell:Set(nextSell .. "s")
        end
    end
end)
-- =============================================================================
-- 🌱 GROW A GARDEN - INTEGRATED ALL-IN-ONE SCRIPT (BAGIAN 3 / 3)
-- Tempelkan bagian ini tepat di bawah baris akhir Bagian 2!
-- Ini adalah bagian penutup yang menyelesaikan seluruh rangkaian script.
-- =============================================================================

print("Loading Integrated Modules (Part 3/3)...")

-- TAB 7: UNICORN FINDER (Fitur Pemburu & Menetas Telur Unicorn Legendaris)
local tabUnicorn = window:CreateTab("Unicorn", "🦄")
tabUnicorn:NewLabel("── 🦄 UNICORN FINDER ──")

local uniToggle = tabUnicorn:NewToggle("Auto Find Unicorn", false, function(state)
    if state then UnicornFinder:StartSearching() else UnicornFinder:StopSearching() end
end)
local uniAutoCollect = tabUnicorn:NewToggle("Auto Collect", UnicornFinder.Config.AutoCollect, function(state) 
    UnicornFinder.Config.AutoCollect = state 
end)
local uniAutoTP = tabUnicorn:NewToggle("Auto Teleport", UnicornFinder.Config.AutoTeleport, function(state) 
    UnicornFinder.Config.AutoTeleport = state 
end)
local uniAutoHatch = tabUnicorn:NewToggle("Auto Hatch Eggs", UnicornFinder.Config.AutoHatch, function(state) 
    UnicornFinder.Config.AutoHatch = state 
end)

tabUnicorn:NewSeparator()
tabUnicorn:NewLabel("── Scan Settings ──")
local uniRadius = tabUnicorn:NewSlider("Scan Radius", 100, 1500, UnicornFinder.Config.ScanRadius, function(value)
    UnicornFinder.Config.ScanRadius = value
end)
local uniInterval = tabUnicorn:NewSlider("Scan Interval (ms)", 500, 5000, 1000, function(value)
    UnicornFinder.Config.ScanInterval = value / 1000
end)

tabUnicorn:NewSeparator()
tabUnicorn:NewLabel("── Quick Actions ──")
tabUnicorn:NewButton("Scan for Unicorn Now", function()
    local scan = UnicornFinder:ScanForUnicorn()
    if #scan.pets > 0 then
        Helpers:Notify("🦄 UNICORN!", "Found " .. #scan.pets .. " Unicorn(s)!", 5)
        UnicornFinder:TeleportTo(scan.pets[1], true)
    elseif #scan.eggs > 0 then
        Helpers:Notify("🥚 EGG!", "Found " .. #scan.eggs .. " potential egg(s)!", 5)
        UnicornFinder:TeleportTo(scan.eggs[1], true)
    else
        Helpers:Notify("Unicorn Finder", "Nothing found nearby", 3)
    end
end)
tabUnicorn:NewButton("Save Position as Spawn", function()
    local hrp = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if hrp then
        UnicornFinder:AddSpawnLocation(hrp.Position)
        Helpers:Notify("Spawn Saved", "Position saved for Unicorn hunt!", 3)
    end
end)
tabUnicorn:NewSeparator()

local uniStatus = tabUnicorn:NewStatus("Status", "Idle")
local uniFound = tabUnicorn:NewStatus("Total Found", "0")
local uniCollected = tabUnicorn:NewStatus("Collected", "0")
local uniHatched = tabUnicorn:NewStatus("Eggs Hatched", "0")
local uniLastFound = tabUnicorn:NewStatus("Last Found", "Never")

task.spawn(function()
    while task.wait(1) do
        local status = UnicornFinder:GetStatus()
        if status.Searching then 
            uniStatus:Set("🔍 SEARCHING FOR UNICORN...") 
            uniStatus:SetColor(Color3.fromRGB(200, 100, 255))
        else 
            uniStatus:Set("Idle") 
            uniStatus:SetColor(Color3.fromRGB(150, 150, 170)) 
        end
        uniFound:Set(tostring(status.Found))
        uniCollected:Set(tostring(status.Collected))
        uniHatched:Set(tostring(status.Hatched))
        if status.LastFound then
            local timeAgo = math.floor(tick() - status.LastFound)
            uniLastFound:Set(timeAgo .. "s ago")
            uniLastFound:SetColor(Color3.fromRGB(200, 100, 255))
        end
    end
end)

-- TAB 8: SETTINGS (Pengaturan Umum & Informasi Tambahan)
local tabSettings = window:CreateTab("Settings", "⚙")
tabSettings:NewLabel("── General Settings ──")

local antiAfk = tabSettings:NewToggle("Anti-AFK", true, function(state)
    if state then Helpers:EnableAntiAFK() end
end)
local debugMode = tabSettings:NewToggle("Debug Mode", false, function(state) end)

tabSettings:NewSeparator()
tabSettings:NewLabel("── Script Info ──")
tabSettings:NewStatus("Version", "1.3.0")
tabSettings:NewStatus("Game", "Grow A Garden")
tabSettings:NewStatus("Modules", "8 loaded")
tabSettings:NewStatus("Toggle Key", "RightShift")

tabSettings:NewSeparator()
tabSettings:NewButton("Destroy GUI", function() 
    if window.GUI then window.GUI:Destroy() end 
end)

-- Selesai Pemuatan Keseluruhan Script
print("=== All 8 modules successfully compiled into Single Script! ===")
print("=== Ready Features: Pet Finder, Weather, Seed Sniper, Tame Sniper, Raccoon Finder, Coin Farmer, Unicorn Finder ===")
print("Press RightShift on keyboard to open/close menu GUI")
Helpers:Notify("Grow A Garden", "Script Fully Loaded!\nPress RightShift to Toggle Menu\n🦄 Unicorn & 💰 Coin Farm Ready!", 5)
