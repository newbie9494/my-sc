-- [[ SCRIPT DELTA: REMOTED PICKUP BABI DEWASA WITH MENU UI ]] --
-- Menggunakan Metode Tembak ID Jarak Jauh (Anti-Salah Angkat)

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- 1. Mengunci Folder Kandang Sesuai File .rbxm
local FolderKandang = Workspace:FindFirstChild("FolderKandang") or Workspace:FindFirstChild("Kandang")

-- Fitur Status
local AutoPickupActive = false

-- ====================================================================
-- SYSTEM 1: MEMBUAT TAMPILAN MENU UI (GUI SYSTEM)
-- ====================================================================

-- Membuat ScreenGui Utama
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "DeltaBabiManager"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- Membuat Frame Utama Menu
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UUDim2.new(0, 260, 0, 150)
MainFrame.Position = UDim2.new(0.5, -130, 0.4, -75)
MainFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true -- Agar menu bisa digeser-geser di layar
MainFrame.Parent = ScreenGui

-- Membuat Sudut Bulat pada Frame
local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0, 10)
Corner.Parent = MainFrame

-- Membuat Judul Menu
local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, 0, 0, 35)
TitleLabel.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
TitleLabel.Text = "  BABI MANAGER V2"
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.Font = Enum.Font.SourceSansBold
TitleLabel.TextSize = 16
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.BorderSizePixel = 0
TitleLabel.Parent = MainFrame

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 10)
TitleCorner.Parent = TitleLabel

-- Membuat Tombol Minimize (-)
local MinimizeBtn = Instance.new("TextButton")
MinimizeBtn.Size = UDim2.new(0, 30, 0, 30)
MinimizeBtn.Position = UDim2.new(1, -35, 0, 2)
MinimizeBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 65)
MinimizeBtn.Text = "-"
MinimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinimizeBtn.Font = Enum.Font.SourceSansBold
MinimizeBtn.TextSize = 18
MinimizeBtn.BorderSizePixel = 0
MinimizeBtn.Parent = MainFrame

local MinCorner = Instance.new("UICorner")
MinCorner.CornerRadius = UDim.new(0, 5)
MinCorner.Parent = MinimizeBtn

-- Membuat Tombol ON/OFF Fitur
local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(0, 220, 0, 45)
ToggleBtn.Position = UDim2.new(0, 20, 0, 65)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50) -- Default Merah (OFF)
ToggleBtn.Text = "AUTO PICKUP: OFF"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.SourceSansBold
ToggleBtn.TextSize = 16
ToggleBtn.BorderSizePixel = 0
ToggleBtn.Parent = MainFrame

local ToggleCorner = Instance.new("UICorner")
ToggleCorner.CornerRadius = UDim.new(0, 8)
ToggleCorner.Parent = ToggleBtn

-- Membuat Tombol Restore (Muncul saat di-minimize)
local RestoreBtn = Instance.new("TextButton")
RestoreBtn.Name = "RestoreBtn"
RestoreBtn.Size = UDim2.new(0, 50, 0, 50)
RestoreBtn.Position = UDim2.new(0, 10, 0.5, -25) -- Di kiri layar
RestoreBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
RestoreBtn.Text = "🐷"
RestoreBtn.TextSize = 24
RestoreBtn.Visible = false
RestoreBtn.BorderSizePixel = 0
RestoreBtn.Parent = ScreenGui

local RestoreCorner = Instance.new("UICorner")
RestoreCorner.CornerRadius = UDim.new(0, 25) -- Bulat Sempurna
RestoreCorner.Parent = RestoreBtn

-- ====================================================================
-- SYSTEM 2: INTERAKSI MENU UI (OPEN / CLOSE / TOGGLE)
-- ====================================================================

-- Logika Tombol ON/OFF
ToggleBtn.MouseButton1Click:Connect(function()
    AutoPickupActive = not AutoPickupActive
    if AutoPickupActive then
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 180, 50) -- Hijau (ON)
        ToggleBtn.Text = "AUTO PICKUP: ON"
        print("[Delta]: Auto Pickup Diaktifkan.")
    else
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50) -- Merah (OFF)
        ToggleBtn.Text = "AUTO PICKUP: OFF"
        print("[Delta]: Auto Pickup Dimatikan.")
    end
end)

-- Logika Minimize Menu
MinimizeBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
    RestoreBtn.Visible = true
end)

-- Logika Membuka Kembali Menu (Restore)
RestoreBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = true
    RestoreBtn.Visible = false
end)

-- ====================================================================
-- SYSTEM 3: LOGIKA UTAMA REMOTE PICKUP (ANTI-SALAH ANGKAT)
-- ====================================================================

-- Fungsi Detektif: Memastikan Objek adalah Anakan + Dewasa berdasarkan Papan Nama
local function CekApakahAnakanDewasa(modelBabi)
    local namaValid = false
    local faseValid = false

    -- Menyisir teks BillboardGui di atas kepala babi sesuai foto kandang Anda
    for _, gui in pairs(modelBabi:GetDescendants()) do
        if gui:IsA("BillboardGui") then
            for _, label in pairs(gui:GetDescendants()) do
                if label:IsA("TextLabel") or label:IsA("TextBox") then
                    local teks = label.Text
                    
                    -- Proteksi Mutlak: Jika terdeteksi "Bayi" atau "Muda", gagalkan!
                    if string.find(teks, "Bayi") or string.find(teks, "Muda") then
                        return false
                    end
                    
                    -- Proteksi Induk: Harus mengandung string "Babi Ngepet"
                    if string.find(teks, "Babi Ngepet") then
                        namaValid = true
                    end
                    
                    -- Harus berstatus Dewasa
                    if string.find(teks, "Dewasa") then
                        faseValid = true
                    end
                end
            end
        end
    end
    return namaValid and faseValid
end

-- LOOP UTAMA: Menembak Data ID Jarak Jauh ke Server
task.spawn(function()
    while true do
        task.wait(0.5) -- Memindai berkala setiap 0.5 detik
        
        -- Skrip hanya berjalan jika tombol di Menu UI berstatus ON
        if AutoPickupActive and FolderKandang then
            for _, babi in pairs(FolderKandang:GetChildren()) do
                if babi:IsA("Model") then
                    
                    -- Jalankan filter teks berlapis (Induk otomatis diabaikan di sini)
                    if CekApakahAnakanDewasa(babi) then
                        
                        -- Mengambil nilai ID Unik (PetID) milik babi dewasa tersebut
                        local petIDValue = babi:FindFirstChild("PetID") or babi:GetAttribute("PetID")
                        local targetID = nil
                        
                        if petIDValue and petIDValue:IsA("StringValue") then
                            targetID = petIDValue.Value
                        elseif type(petIDValue) == "string" then
                            targetID = petIDValue
                        end
                        
                        -- Cari objek RemoteEvent untuk pengangkatan di dalam sistem game Anda
                        -- (Skrip otomatis mendeteksi RemoteEvent yang melayani fungsi 'Angkat' / 'Pickup')
                        if targetID then
                            for _, remote in pairs(ReplicatedStorage:GetDescendants()) do
                                if remote:IsA("RemoteEvent") and (string.find(remote.Name, "Pickup") or string.find(remote.Name, "Angkat") or string.find(remote.Name, "Pet")) then
                                    
                                    -- MENEMBAK DATA LANGSUNG KE SERVER (Metode Jarak Jauh)
                                    -- Mengirim perintah angkat berdasarkan ID Unik babi dewasa tanpa merubah posisi avatar Anda
                                    remote:FireServer(targetID)
                                    
                                end
                            end
                        end
                        
                    end
                end
            end
        end
    end
end)

print("[Delta Script]: Menu Manager & Sistem Remote Berhasil Dimuat Sempurna!")
