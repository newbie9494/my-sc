-- [[ SCRIPT DELTA OFFICIAL: AUTO-PICKUP BABI DEWASA FIX UI ]] --
-- Menggunakan Metode Jarak Jauh (Remote Method) & Fix Bug UI Crash

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Status Fitur ON/OFF
local AutoPickupActive = false

-- ====================================================================
-- SYSTEM 1: MEMBUAT TAMPILAN MENU UI (GUI SYSTEM - FIXED)
-- ====================================================================

-- Cari atau Hapus GUI lama agar tidak menumpuk saat di-execute ulang
local GuiLama = LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("DeltaBabiManagerFix")
if GuiLama then GuiLama:Destroy() end

-- Membuat ScreenGui Utama
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "DeltaBabiManagerFix"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- Membuat Frame Utama Menu
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 260, 0, 150) -- FIXED: Menggunakan UDim2 resmi Roblox
MainFrame.Position = UDim2.new(0.5, -130, 0.4, -75)
MainFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true -- UI bisa digeser/diseret di layar HP/PC
MainFrame.Parent = ScreenGui

-- Membuat Sudut Bulat pada Frame
local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0, 10)
Corner.Parent = MainFrame

-- Membuat Judul Menu
local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, 0, 0, 35)
TitleLabel.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
TitleLabel.Text = "  BABI MANAGER V2 (FIX)"
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.Font = Enum.Font.SourceSansBold
TitleLabel.TextSize = 15
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.BorderSizePixel = 0
TitleLabel.Parent = MainFrame

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 10)
TitleCorner.Parent = TitleLabel

-- Membuat Tombol Minimize (X)
local MinimizeBtn = Instance.new("TextButton")
MinimizeBtn.Size = UDim2.new(0, 30, 0, 30)
MinimizeBtn.Position = UDim2.new(1, -35, 0, 2)
MinimizeBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 65)
MinimizeBtn.Text = "X"
MinimizeBtn.TextColor3 = Color3.fromRGB(255, 50, 50)
MinimizeBtn.Font = Enum.Font.SourceSansBold
MinimizeBtn.TextSize = 16
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

-- Membuat Tombol Restore (Floating icon bulat babi)
local RestoreBtn = Instance.new("TextButton")
RestoreBtn.Name = "RestoreBtn"
RestoreBtn.Size = UDim2.new(0, 50, 0, 50)
RestoreBtn.Position = UDim2.new(0, 15, 0.5, -25) -- Standby di pojok kiri layar agar rapi
RestoreBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
RestoreBtn.Text = "🐷"
RestoreBtn.TextSize = 26
RestoreBtn.Visible = false
RestoreBtn.BorderSizePixel = 0
RestoreBtn.Parent = ScreenGui

local RestoreCorner = Instance.new("UICorner")
RestoreCorner.CornerRadius = UDim.new(0, 25) -- Bulat Sempurna
RestoreCorner.Parent = RestoreBtn

-- ====================================================================
-- SYSTEM 2: LOGIKA INTERAKSI UI (OPEN / CLOSE / TOGGLE)
-- ====================================================================

-- Logika Klik Tombol ON/OFF Fitur
ToggleBtn.MouseButton1Click:Connect(function()
    AutoPickupActive = not AutoPickupActive
    if AutoPickupActive then
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 180, 50) -- Hijau (ON)
        ToggleBtn.Text = "AUTO PICKUP: ON"
    else
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50) -- Merah (OFF)
        ToggleBtn.Text = "AUTO PICKUP: OFF"
    end
end)

-- Logika Mengecilkan Menu (Minimize via tombol X)
MinimizeBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
    RestoreBtn.Visible = true
end)

-- Logika Membuka Kembali Menu Utama (Klik Icon Babi 🐷)
RestoreBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = true
    RestoreBtn.Visible = false
end)

-- ====================================================================
-- SYSTEM 3: LOGIKA UTAMA SCANNING & REMOTE PICKUP JALUR SISTEM
-- ====================================================================

-- Fungsi Detektif Teks Kepala: Memisahkan Anakan Dewasa dari Indukan secara Akurat
local function ValidasiBabiDewasa(modelBabi)
    local namaValid = false
    local faseValid = false

    for _, gui in pairs(modelBabi:GetDescendants()) do
        if gui:IsA("BillboardGui") then
            for _, label in pairs(gui:GetDescendants()) do
                if label:IsA("TextLabel") or label:IsA("TextBox") then
                    local teks = label.Text
                    
                    -- Proteksi Mutlak: Jika terdeteksi kata Bayi atau Muda, batalkan instan!
                    if string.find(teks, "Bayi") or string.find(teks, "Muda") then
                        return false
                    end
                    
                    -- Deteksi Nama: Harus merupakan anakan (mengandung tulisan Babi Ngepet)
                    if string.find(teks, "Babi Ngepet") then
                        namaValid = true
                    end
                    
                    -- Deteksi Fase Selesai: Harus berstatus Dewasa
                    if string.find(teks, "Dewasa") then
                        faseValid = true
                    end
                end
            end
        end
    end
    -- Mengembalikan true hanya jika lolos proteksi induk dan berstatus anakan dewasa
    return namaValid and faseValid
end

-- LOOP UTAMA AUTOMATION (Berjalan di latar belakang)
task.spawn(function()
    while true do
        task.wait(0.5) -- Scan berkala setiap 0.5 detik agar efisien dan tidak lag
        
        if AutoPickupActive then
            -- Menyisir Workspace secara dinamis untuk mencari objek babi
            for _, babi in pairs(Workspace:GetChildren()) do
                if babi:IsA("Model") and ValidasiBabiDewasa(babi) then
                    
                    -- Mengekstrak ID Unik Pet (PetID) milik babi dewasa tersebut
                    local petIDValue = babi:FindFirstChild("PetID") or babi:GetAttribute("PetID")
                    local targetID = nil
                    
                    if petIDValue and petIDValue:IsA("StringValue") then
                        targetID = petIDValue.Value
                    elseif type(petIDValue) == "string" then
                        targetID = petIDValue
                    end
                    
                    -- Jika ID Unik ditemukan, tembak perintah pickup jarak jauh lewat ReplicatedStorage
                    if targetID then
                        for _, remote in pairs(ReplicatedStorage:GetDescendants()) do
                            if remote:IsA("RemoteEvent") and (string.find(remote.Name, "Pickup") or string.find(remote.Name, "Angkat") or string.find(remote.Name, "Pet")) then
                                
                                -- Eksekusi bypass jaringan tanpa menggerakkan avatar Anda
                                remote:FireServer(targetID)
                                
                            end
                        end
                    end
                    
                end
            end
        end
    end
end)

print("[Delta Fix]: Seluruh sistem menu UI dan Logika Jaringan berhasil dimuat!")
