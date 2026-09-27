-- [[ ALIT HUB PART 1 - ANTI KICK & CORE MENU NODE HUB STYLE ]]
if not game:IsLoaded() then game.Loaded:Wait() end
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")

pcall(function()
    if game:GetService("ReplicatedStorage"):FindFirstChild("AddStrike") then
        game:GetService("ReplicatedStorage").AddStrike:Destroy()
    end
end)

local mt = getrawmetatable(game)
local old_namecall = mt.__namecall
setreadonly(mt, false)
mt.__namecall = newcclosure(function(self, ...)
    local method = getnamecallmethod()
    if string.lower(method) == "kick" then return nil end
    if method == "Destroy" or method == "destroy" then
        if self == getcallingscript() then return nil end
    end
    return old_namecall(self, ...)
end)
setreadonly(mt, true)

_G.AlitHubFarmActive, _G.AlitHubRestockActive, _G.AlitHubPigActive = false, false, false
task.wait(0.1)

local TM = {["Dupa"]="Spawn_Dupa", ["Gagak"]="Spawn_Gagak", ["Jamur Kuburan"]="Spawn_JamurKuburan", ["Kemenyan"]="Spawn_Kemenyan", ["Kepiting Sungai"]="Spawn_KepitingSungai", ["Melati"]="Spawn_Melati"}
local RM = {["Kepiting"]="Kepiting", ["Sate Kepiting"]="Sate Kepiting"}
local FM = {["Jamur Rebus"]="JamurRebus", ["Pisang Raja Rebus"]="PisangRajaRebus"}
local ST, SR, SF = {}, {}, {}
local SPD, PPD, TD = 110, 0.45, 0.65
local GLOBAL_SAVED_POS = UDim2.new(0.5, -110, 0.3, -100)

if CoreGui:FindFirstChild("AlitHubUI") then CoreGui.AlitHubUI:Destroy() end
local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "AlitHubUI"; ScreenGui.ResetOnSpawn = false

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Name = "MainFrame"; MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
MainFrame.Position = GLOBAL_SAVED_POS; MainFrame.Size = UDim2.new(0, 240, 0, 420); MainFrame.BorderSizePixel = 0; MainFrame.Active = true; MainFrame.ClipsDescendants = true
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)
Instance.new("UIStroke", MainFrame).Color = Color3.fromRGB(255, 200, 0)

local TopBar = Instance.new("Frame", MainFrame); TopBar.Size = UDim2.new(1, 0, 0, 40); TopBar.BackgroundTransparency = 1
local Title = Instance.new("TextLabel", TopBar); Title.BackgroundTransparency = 1; Title.Position = UDim2.new(0, 12, 0, 0); Title.Size = UDim2.new(0, 120, 1, 0); Title.Font = Enum.Font.GothamBold; Title.Text = "ALIT HUB"; Title.TextColor3 = Color3.fromRGB(255, 200, 0); Title.TextSize = 13; Title.TextXAlignment = Enum.TextXAlignment.Left

local MiniButton = Instance.new("TextButton", TopBar); MiniButton.BackgroundTransparency = 1; MiniButton.Position = UDim2.new(1, -35, 0, 0); MiniButton.Size = UDim2.new(0, 30, 1, 0); MiniButton.Font = Enum.Font.GothamBold; MiniButton.Text = "-"; MiniButton.TextColor3 = Color3.fromRGB(200, 200, 200); MiniButton.TextSize = 18

local OpenButton = Instance.new("TextButton", ScreenGui)
OpenButton.Name = "OpenButton"; OpenButton.BackgroundColor3 = Color3.fromRGB(15, 15, 18); OpenButton.Position = UDim2.new(0, 10, 0.4, 0); OpenButton.Size = UDim2.new(0, 85, 0, 35); OpenButton.Font = Enum.Font.GothamBold; OpenButton.Text = "ALIT HUB"; OpenButton.TextColor3 = Color3.fromRGB(255, 200, 0); OpenButton.TextSize = 11; OpenButton.Visible = false
Instance.new("UICorner", OpenButton).CornerRadius = UDim.new(0, 6)
Instance.new("UIStroke", OpenButton).Color = Color3.fromRGB(255, 200, 0)

MiniButton.Activated:Connect(function() MainFrame.Visible = false OpenButton.Visible = true end)
OpenButton.Activated:Connect(function() OpenButton.Visible = false MainFrame.Visible = true end)

local TabBar = Instance.new("Frame", MainFrame); TabBar.Position = UDim2.new(0, 10, 0, 45); TabBar.Size = UDim2.new(1, -20, 0, 30); TabBar.BackgroundTransparency = 1
Instance.new("UIListLayout", TabBar).FillDirection = Enum.FillDirection.Horizontal
local ContainerFrame = Instance.new("Frame", MainFrame); ContainerFrame.Position = UDim2.new(0, 10, 0, 85); ContainerFrame.Size = UDim2.new(1, -20, 1, -95); ContainerFrame.BackgroundTransparency = 1

local Tabs = {}
local function CreateTab(tabName)
    local Page = Instance.new("ScrollingFrame", ContainerFrame); Page.Size = UDim2.new(1, 0, 1, 0); Page.BackgroundTransparency = 1; Page.Visible = false; Page.BorderSizePixel = 0; Page.ScrollBarThickness = 2; Page.CanvasSize = UDim2.new(0,0,0,320)
    Instance.new("UIListLayout", Page).Padding = UDim.new(0, 6)
    local TabBtn = Instance.new("TextButton", TabBar); TabBtn.Size = UDim2.new(0, 68, 1, 0); TabBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 30); TabBtn.Font = Enum.Font.GothamBold; TabBtn.Text = tabName; TabBtn.TextColor3 = Color3.fromRGB(180, 180, 180); TabBtn.TextSize = 9
    Instance.new("UICorner", TabBtn).CornerRadius = UDim.new(0, 4)
    local tStroke = Instance.new("UIStroke", TabBtn); tStroke.Color = Color3.fromRGB(45, 45, 50)
    TabBtn.Activated:Connect(function()
        for _, t in pairs(Tabs) do t.Page.Visible = false t.Btn.TextColor3 = Color3.fromRGB(180, 180, 180) t.Stroke.Color = Color3.fromRGB(45, 45, 50) end
        Page.Visible = true TabBtn.TextColor3 = Color3.fromRGB(255, 200, 0) tStroke.Color = Color3.fromRGB(255, 200, 0)
    end)
    Tabs[tabName] = {Page = Page, Btn = TabBtn, Stroke = tStroke}
    return Page
end

local PageFarm = CreateTab("Main Farm")
local PageStock = CreateTab("Restock Kios")
local PagePig = CreateTab("Pig Farm")
Tabs["Main Farm"].Page.Visible = true
Tabs["Main Farm"].Btn.TextColor3 = Color3.fromRGB(255, 200, 0)
Tabs["Main Farm"].Stroke.Color = Color3.fromRGB(255, 200, 0)
-- [[ ALIT HUB PART 2 - BUTTON LOGIC & TELEPORT LOOP ]]
local function AddToggle(parent, text, callback)
    local tFrame = Instance.new("Frame", parent); tFrame.Size = UDim2.new(1, 0, 0, 35); tFrame.BackgroundColor3 = Color3.fromRGB(22, 22, 26)
    Instance.new("UICorner", tFrame).CornerRadius = UDim.new(0, 5)
    local lbl = Instance.new("TextLabel", tFrame); lbl.BackgroundTransparency = 1; lbl.Position = UDim2.new(0, 10, 0, 0); lbl.Size = UDim2.new(0.6, 0, 1, 0); lbl.Font = Enum.Font.GothamSemibold; lbl.Text = text; lbl.TextColor3 = Color3.fromRGB(220, 220, 220); lbl.TextSize = 10; lbl.TextXAlignment = Enum.TextXAlignment.Left
    local btn = Instance.new("TextButton", tFrame); btn.Position = UDim2.new(1, -65, 0, 6); btn.Size = UDim2.new(0, 55, 0, 22); btn.BackgroundColor3 = Color3.fromRGB(220, 53, 69); btn.Font = Enum.Font.GothamBold; btn.Text = "OFF"; btn.TextColor3 = Color3.fromRGB(255, 255, 255); btn.TextSize = 9
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
    btn.Activated:Connect(function() local status = callback() btn.BackgroundColor3 = status and Color3.fromRGB(40, 167, 69) or Color3.fromRGB(220, 53, 69) btn.Text = status and "ON" or "OFF" end)
end

local function AddDropdownList(parent, title, mapping, targetTable)
    for disp, ws in pairs(mapping) do
        local b = Instance.new("TextButton", parent); b.Size = UDim2.new(1, 0, 0, 26); b.BackgroundColor3 = Color3.fromRGB(22, 22, 26); b.Font = Enum.Font.Gotham; b.Text = "  " .. disp; b.TextColor3 = Color3.fromRGB(180, 180, 180); b.TextSize = 10; b.TextXAlignment = Enum.TextXAlignment.Left
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 4)
        local bStr = Instance.new("UIStroke", b); bStr.Color = Color3.fromRGB(35, 35, 40)
        b.Activated:Connect(function()
            local idx = table.find(targetTable, ws)
            if idx then table.remove(targetTable, idx) bStr.Color = Color3.fromRGB(35, 35, 40) b.TextColor3 = Color3.fromRGB(180, 180, 180)
            else table.insert(targetTable, ws) bStr.Color = Color3.fromRGB(255, 200, 0) b.TextColor3 = Color3.fromRGB(255, 200, 0) end
        end)
    end
end

AddToggle(PageFarm, "Automation Farm", function() _G.AlitHubFarmActive = not _G.AlitHubFarmActive return _G.AlitHubFarmActive end)
AddDropdownList(PageFarm, "Bahan", TM, ST)
AddToggle(PageStock, "Automation Restock", function() _G.AlitHubRestockActive = not _G.AlitHubRestockActive return _G.AlitHubRestockActive end)
AddDropdownList(PageStock, "Kios", RM, SR)
AddToggle(PagePig, "Automation Pig", function() _G.AlitHubPigActive = not _G.AlitHubPigActive return _G.AlitHubPigActive end)
AddDropdownList(PagePig, "Pakan", FM, SF)

local dragToggle, dragInput, dragStart, startPos
MainFrame.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragToggle = true dragStart = input.Position startPos = MainFrame.Position input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragToggle = false end end) end end)
MainFrame.InputChanged:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end end)
game:GetService("UserInputService").InputChanged:Connect(function(input) if input == dragInput and dragToggle then local delta = input.Position - dragStart MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y) end end)
LocalPlayer.Idled:Connect(function() if _G.AlitHubFarmActive or _G.AlitHubRestockActive or _G.AlitHubPigActive then game:GetService("VirtualUser"):Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame) task.wait(0.5) game:GetService("VirtualUser"):Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame) end end)

local function eq(n)
    local bp = LocalPlayer:FindFirstChild("Backpack") local char = LocalPlayer.Character
    if bp and char then local tool = bp:FindFirstChild(n) if tool and char:FindFirstChildOfClass("Humanoid") then char.Humanoid:EquipTool(tool) return true end end
    return char and char:FindFirstChild(n) ~= nil
end

local function fp(p)
    if not p or not p.Enabled then return end
    if fireproximityprompt then fireproximityprompt(p) else p:InputHoldBegin() task.wait(p.HoldDuration + 0.05) p:InputHoldEnd() end
end

local function tv(r, h, t)
    if r and h then
        h:ChangeState(Enum.HumanoidStateType.Physics); r.Velocity = Vector3.new(0, 0, 0)
        local tw = TweenService:Create(r, TweenInfo.new((r.Position - t.Position).Magnitude / SPD, Enum.EasingStyle.Linear), {CFrame = t})
        tw:Play() tw.Completed:Wait(); r.Velocity = Vector3.new(0, 0, 0); h:ChangeState(Enum.HumanoidStateType.Freefall)
    end
end

task.spawn(function()
    while true do
        task.wait(0.4)
        local char = LocalPlayer.Character local r = char and char:FindFirstChild("HumanoidRootPart") local hum = char and char:FindFirstChildOfClass("Humanoid")
        if _G.AlitHubFarmActive and #ST > 0 and r and hum then
            local f = workspace:FindFirstChild("SpawnBahan")
            if f then
                for _, o in pairs(f:GetChildren()) do
                    if not _G.AlitHubFarmActive then break end
                    if table.find(ST, o.Name) then
                        local p = o:FindFirstChildWhichIsA("ProximityPrompt", true)
                        if p and p.Enabled and p.Parent then
                            local pt = p.Parent:IsA("BasePart") and p.Parent or o:FindFirstChildWhichIsA("BasePart", true)
                            if pt then tv(r, hum, pt.CFrame) task.wait(TD) if _G.AlitHubFarmActive and p.Enabled then fp(p) task.wait(PPD) end end
                        end
                    end
                end
            end
        end
        if _G.AlitHubRestockActive and #SR > 0 and r and hum then
            local k = workspace:FindFirstChild("Kios_" .. LocalPlayer.Name)
            if k then
                for i = 1, 12 do
                    if not _G.AlitHubRestockActive then break end
                    local s = k:FindFirstChild("slot" .. i) or k:FindFirstChild("slot " .. i)
                    if s then
                        local p = s:FindFirstChildWhichIsA("ProximityPrompt", true)
                        if p and p.Enabled then
                            for _, tN in ipairs(SR) do
                                if eq(tN) then
                                    local pt = s:IsA("BasePart") and s or s:FindFirstChildWhichIsA("BasePart", true)
                                    if pt then tv(r, hum, pt.CFrame) task.wait(TD) if p.Enabled and _G.AlitHubRestockActive then fp(p) task.wait(PPD) end end
                                    break
                                end
                            end
                        end
                    end
                end
            end
        end
        if _G.AlitHubPigActive and r and hum then
            local kd = workspace:FindFirstChild("KandangBabi_" .. LocalPlayer.UserId) or workspace:FindFirstChild("KandangBabi_" .. LocalPlayer.Name)
            if kd then
                local tm = kd:FindFirstChild("TempatMakan") or kd:FindFirstChild("Tempat Makan")
                if tm and #SF > 0 then
                    local p = tm:FindFirstChildWhichIsA("ProximityPrompt", true)
                    if p then
                        local ts = p.ObjectText or ""
                        if string.find(ts, "0/10") or ts == "" then
                            for _, fN in ipairs(SF) do
                                if eq(fN) then
                                    local pt = tm:IsA("BasePart") and tm or tm:FindFirstChildWhichIsA("BasePart", true)
                                    if pt then
                                        tv(r, hum, pt.CFrame) task.wait(TD)
                                        for c = 1, 10 do if not p.Enabled or not _G.AlitHubPigActive or string.find(p.ObjectText, "10/10") or not eq(fN) then break end fp(p) task.wait(0.35) end
                                    end
                                    break
                                end
                            end
                        end
                    end
                end
                for _, b in pairs(kd:GetChildren()) do
                    if not _G.AlitHubPigActive then break end
                    if string.find(string.lower(b.Name), "babi") or b:FindFirstChild("Fase") then
                        local sf = b:FindFirstChild("Fase") or b:FindFirstChild("Status")
                        if sf and (string.find(string.lower(tostring(sf.Value)), "dewasa") or string.find(string.lower(b.Name), "dewasa")) then
                            local p = b:FindFirstChildWhichIsA("ProximityPrompt", true)
                            if p and p.Enabled then
                                local pt = b:IsA("BasePart") and b or b:FindFirstChildWhichIsA("BasePart", true)
                                if pt then tv(r, hum, pt.CFrame) task.wait(TD) if p.Enabled and _G.AlitHubPigActive then fp(p) task.wait(PPD) end end
                            end
                        end
                    end
                end
            end
        end
    end
end)
