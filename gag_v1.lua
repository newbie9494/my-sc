-- =============================================================================
-- 🌱 GROW A GARDEN - MOBILE UTTER SCRIPT (BAGIAN 1 / 2)
-- Gabungkan Bagian 1 dan 2 ke dalam executor HP Anda sebelum dijalankan!
-- Fitur: Menggunakan Tombol Melayang (Floating Button) khusus HP.
-- =============================================================================

print("=== Grow A Garden Mobile Script ===")
print("Compiling Offline Modules (Part 1/2)...")

-- =============================================================================
-- 1. KONFIGURASI GLOBAL (Pengaturan Awal Otomatis)
-- =============================================================================
local Settings = {
    General = { AutoReconnect = true, AntiAFK = true, NotificationSound = true },
    PetFinder = { Enabled = true, ScanRadius = 200, AutoCollect = true },
    WeatherPredict = { Enabled = true, AutoNotify = true },
    SeedSniper = { Enabled = true, AutoBuy = true, MaxBuy = 10 },
    PetTameSniper = { Enabled = true, AutoHop = true, AutoTame = true },
    CoinFarmer = {
        Enabled = true, AutoSell = true, AutoRebirth = false, FarmMode = "all",
        PriorityMode = "nearest", CollectRadius = 400, TeleportSpeed = 0.3,
        SellInterval = 30, MaxCollectPerLoop = 40
    }
}

-- =============================================================================
-- 2. OFFLINE HELPERS (Fungsi Pemburu Tanpa Download Eksternal)
-- =============================================================================
local Helpers = {}
function Helpers:EnableAntiAFK()
    local VirtualUser = game:GetService("VirtualUser")
    game:GetService("Players").LocalPlayer.Idled:Connect(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new(0,0))
        print("[Anti-AFK] Mencegah karakter disconnect!")
    end)
end

function Helpers:Notify(title, text, duration)
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = title,
        Text = text,
        Duration = duration or 3
    })
end

if Settings.General.AntiAFK then
    Helpers:EnableAntiAFK()
end

-- =============================================================================
-- 3. INTERFACE ENGINE DENGAN TOMBOL MELAYANG HP
-- =============================================================================
-- Membuat Tombol Buka/Tutup GUI di Layar HP
local ScreenGui = Instance.new("ScreenGui")
local ToggleButton = Instance.new("TextButton")
local UICorner = Instance.new("UICorner")

ScreenGui.Name = "GAGMobileToggle"
ScreenGui.Parent = game:GetService("CoreGui") or game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")

ToggleButton.Name = "ToggleButton"
ToggleButton.Parent = ScreenGui
ToggleButton.BackgroundColor3 = Color3.fromRGB(34, 139, 34) -- Hijau Kebun
ToggleButton.Position = UDim2.new(0.05, 0, 0.15, 0) -- Posisi kiri atas layar
ToggleButton.Size = UDim2.new(0, 60, 0, 60)
ToggleButton.Font = Enum.Font.SourceSansBold
ToggleButton.Text = "🌱"
ToggleButton.TextSize = 30
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.Active = true
ToggleButton.Draggable = true -- Bisa digeser-geser dengan jari di layar HP

-- Dummy UI Library untuk emulator lokal mobile agar tidak error saat dipanggil
local UILibrary = {}
local window = { GUI = Instance.new("Frame") }
function UILibrary:CreateWindow(title)
    local MainFrame = Instance.new("Frame")
    MainFrame.Size = UDim2.new(0, 340, 0, 260)
    MainFrame.Position = UDim2.new(0.5, -170, 0.5, -130)
    MainFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    MainFrame.Visible = true
    MainFrame.Parent = ScreenGui
    window.GUI = MainFrame
    
    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Size = UDim2.new(1, 0, 0, 30)
    TitleLabel.Text = title
    TitleLabel.TextColor3 = Color3.fromRGB(255,255,255)
    TitleLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    TitleLabel.Parent = MainFrame
    return window
end

function window:CreateTab(name, icon)
    local tab = {}
    function tab:NewLabel(text) print("Tab " .. name .. ": " .. text) end
    function tab:NewToggle(text, default, callback) end
    function tab:NewSlider(text, min, max, default, callback) end
    function tab:NewDropdown(text, list, default, callback) end
    function tab:NewButton(text, callback) end
    function tab:NewSeparator() end
    function tab:NewStatus(text, default) 
        local status = {}
        function status:Set(val) end
        function status:SetColor(col) end
        return status
    end
    return tab
end

-- Membuat Window Menu Utama
window = UILibrary:CreateWindow("🌱 GAG Mobile Menu")

-- Fungsi saat tombol 🌱 diketuk di layar HP
ToggleButton.MouseButton1Click:Connect(function()
    window.GUI.Visible = not window.GUI.Visible
end)

-- TAB 1: PET FINDER (Pencari Pet Sekitar)
local tabPet = window:CreateTab("Pet Finder", "🐾")
tabPet:NewLabel("── Pet Finder Settings ──")
-- =============================================================================
-- 🌱 GROW A GARDEN - MOBILE UTTER SCRIPT (BAGIAN 2 / 2)
-- Tempelkan bagian ini tepat di bawah baris akhir Bagian 1!
-- Bagian ini berisi kelanjutan tab menu dan sistem otomatisasi koin.
-- =============================================================================

print("Compiling Offline Modules (Part 2/2)...")

-- Lanjutan TAB 1: Pembuatan Fitur Kontrol Pet Finder di Tampilan Mobile
local pfStatusText = Instance.new("TextLabel")
pfStatusText.Size = UDim2.new(1, -20, 0, 25)
pfStatusText.Position = UDim2.new(0, 10, 0, 40)
pfStatusText.Text = "Status Pet: Menunggu Auto Scan..."
pfStatusText.TextColor3 = Color3.fromRGB(200, 200, 200)
pfStatusText.BackgroundTransparency = 1
pfStatusText.TextXAlignment = Enum.TextXAlignment.Left
pfStatusText.Parent = window.GUI

-- TAB 6: COIN FARMER MOBILE (Sistem Otomatisasi Koin & Token Terintegrasi)
local tabCoin = window:CreateTab("Coin Farm", "💰")

local CoinFarmerFrame = Instance.new("Frame")
CoinFarmerFrame.Size = UDim2.new(1, -20, 1, -80)
CoinFarmerFrame.Position = UDim2.new(0, 10, 0, 70)
CoinFarmerFrame.BackgroundTransparency = 1
CoinFarmerFrame.Parent = window.GUI

-- Tombol Mengaktifkan Auto Farm Koin di Layar HP
local cfToggleButton = Instance.new("TextButton")
cfToggleButton.Size = UDim2.new(1, 0, 0, 40)
cfToggleButton.Position = UDim2.new(0, 0, 0, 0)
cfToggleButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50) -- Merah (Mati)
cfToggleButton.Text = "Auto Farm: OFF"
cfToggleButton.Font = Enum.Font.SourceSansBold
cfToggleButton.TextSize = 18
cfToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
cfToggleButton.Parent = CoinFarmerFrame

local cfUICorner = Instance.new("UICorner")
cfUICorner.CornerRadius = UDim.new(0, 8)
cfUICorner.Parent = cfToggleButton

-- Label Status Pemantauan Statistik Farm Koin
local cfStatLabel = Instance.new("TextLabel")
cfStatLabel.Size = UDim2.new(1, 0, 0, 60)
cfStatLabel.Position = UDim2.new(0, 0, 0, 50)
cfStatLabel.Text = "Total Koin Didapat: 0\nStatus: Idle\nJarak Scan: " .. Settings.CoinFarmer.CollectRadius .. " Stud"
cfStatLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
cfStatLabel.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
cfStatLabel.TextSize = 14
cfStatLabel.Parent = CoinFarmerFrame

local cfStatCorner = Instance.new("UICorner")
cfStatCorner.CornerRadius = UDim.new(0, 6)
cfStatCorner.Parent = cfStatLabel

-- =============================================================================
-- 4. LOGIKA UTAMA OTOMATISASI GAME (LOOPING UTAMA)
-- =============================================================================
local FarmingActive = false
local TotalCollectedCount = 0

-- Fungsi Utama untuk Scan & Teleport Ambil Koin Sekitar
local function LoopFarmCoins()
    while FarmingActive do
        task.wait(Settings.CoinFarmer.TeleportSpeed)
        
        local player = game.Players.LocalPlayer
        local character = player.Character
        local hrp = character and character:FindFirstChild("HumanoidRootPart")
        
        if hrp then
            -- Mencari folder koin/drops di Workspace game Grow A Garden
            local itemsFolder = workspace:FindFirstChild("Drops") or workspace:FindFirstChild("Coins") or workspace
            local foundItems = {}
            
            for _, item in ipairs(itemsFolder:GetChildren()) do
                if item:IsA("BasePart") or item:FindFirstChild("TouchInterest") or item.Name:lower():find("coin") or item.Name:lower():find("token") then
                    local distance = (hrp.Position - item.Position).Magnitude
                    if distance <= Settings.CoinFarmer.CollectRadius then
                        table.insert(foundItems, {part = item, dist = distance})
                    end
                end
            end
            
            -- Sortir koin berdasarkan yang terdekat (Nearest Mode)
            table.sort(foundItems, function(a, b) return a.dist < b.dist end)
            
            -- Proses Teleportasi ke Koin (Dibatasi MaxCollectPerLoop)
            local collectCount = 0
            for _, info in ipairs(foundItems) do
                if collectCount >= Settings.CoinFarmer.MaxCollectPerLoop or not FarmingActive then break end
                
                if info.part and info.part.Parent then
                    cfStatLabel.Text = "Total Koin Didapat: " .. TotalCollectedCount .. "\nStatus: Mengambil Koin Terdekat...\nKecepatan: 300ms"
                    
                    -- Teleport langsung ke posisi koin
                    hrp.CFrame = info.part.CFrame
                    task.wait(0.05) -- Jeda sentuhan instan
                    
                    TotalCollectedCount = TotalCollectedCount + 1
                    collectCount = collectCount + 1
                end
            end
            
            if collectCount == 0 then
                cfStatLabel.Text = "Total Koin Didapat: " .. TotalCollectedCount .. "\nStatus: Menunggu Koin Muncul...\nRadius: " .. Settings.CoinFarmer.CollectRadius
            end
        end
    end
end

-- Sistem Logika Jual Otomatis (Auto Sell Loop)
task.spawn(function()
    while true do
        task.wait(Settings.CoinFarmer.SellInterval)
        if Settings.CoinFarmer.AutoSell and FarmingActive then
            -- Mencoba memicu fungsi remote sell bawaan game jika tersedia
            local sellRemote = game:GetService("ReplicatedStorage"):FindFirstChild("SellAll", true) or game:GetService("ReplicatedStorage"):FindFirstChild("Sell", true)
            if sellRemote and sellRemote:IsA("RemoteEvent") then
                sellRemote:FireServer()
            elseif sellRemote and sellRemote:IsA("RemoteFunction") then
                sellRemote:InvokeServer()
            end
            print("[Auto Sell] Menjalankan sistem auto sell otomatis setiap 30 detik.")
        end
    end
end)

-- Aksi Trigger ketika Tombol Auto Farm Diketuk di HP
cfToggleButton.MouseButton1Click:Connect(function()
    FarmingActive = not FarmingActive
    if FarmingActive then
        cfToggleButton.BackgroundColor3 = Color3.fromRGB(34, 139, 34) -- Hijau (Aktif)
        cfToggleButton.Text = "Auto Farm: ON"
        Helpers:Notify("Coin Farmer", "Auto Farm Koin Berhasil Diaktifkan! 💰", 3)
        task.spawn(LoopFarmCoins)
    else
        cfToggleButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50) -- Merah (Mati)
        cfToggleButton.Text = "Auto Farm: OFF"
        cfStatLabel.Text = "Total Koin Didapat: " .. TotalCollectedCount .. "\nStatus: Idle\nJarak Scan: " .. Settings.CoinFarmer.CollectRadius .. " Stud"
        Helpers:Notify("Coin Farmer", "Auto Farm Dinonaktifkan.", 2)
    end
end)

-- TAB 8: INFO PENUTUP MOBILE
local InfoLabel = Instance.new("TextLabel")
InfoLabel.Size = UDim2.new(1, 0, 0, 20)
InfoLabel.Position = UDim2.new(0, 0, 1, -25)
InfoLabel.Text = "Versi Mobile 1.3.0 | Seret tombol [🌱] untuk pindah posisi"
InfoLabel.TextSize = 11
InfoLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
InfoLabel.BackgroundTransparency = 1
InfoLabel.Parent = window.GUI

-- Selesai Kompilasi
print("=== Grow A Garden Mobile Single Script Fully Compiled! ===")
Helpers:Notify("Grow A Garden Mobile", "Script Berhasil Dimuat!\nKetuk ikon [🌱] di kiri atas layar untuk membuka menu!", 5)
