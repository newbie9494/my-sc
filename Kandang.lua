-- [[ SCRIPT DELTA OFFICIAL: BABI MANAGER V7 (MURNI METODE REMOTE) ]] --
-- Avatar diam di tempat. Pengangkatan murni via Tembak Data ID Jarak Jauh.

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Status Fitur ON/OFF via Menu UI
local AutoPickupActive = false

-- Mengunci Folder Kandang Sesuai File Berkas Anda
local FolderKandang = Workspace:FindFirstChild("kandang_babi")

-- ====================================================================
-- SYSTEM 1: MEMBUAT TAMPILAN PANEL MENU UI
-- ====================================================================

local GuiLama = LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("DeltaBabiManagerRemote")
if GuiLama then GuiLama:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "DeltaBabiManagerRemote"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 260, 0, 150)
MainFrame.Position = UDim2.new(0.5, -130, 0.4, -75)
MainFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0, 10)
Corner.Parent = MainFrame

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, 0, 0, 35)
TitleLabel.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
TitleLabel.Text = "  BABI MANAGER V7 (REMOTE)"
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.Font = Enum.Font.SourceSansBold
TitleLabel.TextSize = 14
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.BorderSizePixel = 0
TitleLabel.Parent = MainFrame

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 10)
TitleCorner.Parent = TitleLabel

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

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(0, 220, 0, 45)
ToggleBtn.Position = UDim2.new(0, 20, 0, 65)
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

local RestoreBtn = Instance.new("TextButton")
RestoreBtn.Name = "RestoreBtn"
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

-- ====================================================================
-- SYSTEM 2: INTERAKSI MENU UI (OPEN / CLOSE / TOGGLE)
-- ====================================================================

ToggleBtn.MouseButton1Click:Connect(function()
    AutoPickupActive = not AutoPickupActive
    if AutoPickupActive then
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 180, 50)
        ToggleBtn.Text = "AUTO PICKUP: ON"
    else
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        ToggleBtn.Text = "AUTO PICKUP: OFF"
    end
end)

MinimizeBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
    RestoreBtn.Visible = true
end)

RestoreBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = true
    RestoreBtn.Visible = false
end)

-- ====================================================================
-- SYSTEM 3: MONITORING TEXT FASE & PENEMBAKAN DATA REMOTE JALUR SISTEM
-- ====================================================================

-- Pengecekan teks BillboardGui di atas kepala babi peliharaan Anda
local function CekApakahAnakanDewasa(modelPet)
    local namaValid = false
    local faseValid = false

    for _, gui in pairs(modelPet:GetDescendants()) do
        if gui:IsA("BillboardGui") then
            for _, label in pairs(gui:GetDescendants()) do
                if label:IsA("TextLabel") or label:IsA("TextBox") then
                    local teks = label.Text
                    
                    -- Proteksi Bayi & Muda: Jika terdeteksi, batalkan instan!
                    if string.find(teks, "Bayi") or string.find(teks, "Muda") then
                        return false
                    end
                    
                    -- Konfirmasi Identitas Anakan
                    if string.find(teks, "Babi Ngepet") then
                        namaValid = true
                    end
                    
                    -- Pemicu Target: Fase terbaca Dewasa
                    if string.find(teks, "Dewasa") then
                        faseValid = true
                    end
                end
            end
        end
    end
    return namaValid and faseValid
end

-- LOOP UTAMA AUTOMATION (Tembak Data ID Jarak Jauh)
task.spawn(function()
    while true do
        task.wait(0.3) -- Jeda scan konstan 0.3 detik di latar belakang
        
        -- Berjalan murni di dalam folder kandang_babi saja sesuai berkas Anda
        if AutoPickupActive and FolderKandang then
            for _, babi in pairs(FolderKandang:GetChildren()) do
                if babi:IsA("Model") and CekApakahAnakanDewasa(babi) then
                    
                    -- Mengekstrak ID Unik Pet (PetID) milik babi dewasa target
                    local petIDValue = babi:FindFirstChild("PetID") or babi:GetAttribute("PetID")
                    local targetID = nil
                    
                    if petIDValue and petIDValue:IsA("StringValue") then
                        targetID = petIDValue.Value
                    elseif type(petIDValue) == "string" then
                        targetID = petIDValue
                    end
                    
                    -- Jika ID unik babi dewasa berhasil dikunci, langsung tembak lewat jaringan data game
                    if targetID then
                        for _, remote in pairs(ReplicatedStorage:GetDescendants()) do
                            if remote:IsA("RemoteEvent") and (string.find(remote.Name, "Pickup") or string.find(remote.Name, "Angkat") or string.find(remote.Name, "Pet")) then
                                
                                -- PERINTAH MURNI REMOTE JAUH: Kirim ID babi tanpa memindahkan avatar Anda sama sekali
                                remote:FireServer(targetID)
                                
                            end
                        end
                    end
                    
                end
            end
        end
    end
end)

print("[Delta V7]: Sukses! Skrip Murni Menggunakan Metode Tembak Jaringan Data Remote.")
