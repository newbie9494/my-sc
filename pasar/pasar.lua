-- [[ ALIT HUB PART 1 - BASE & TOPBAR ]]
if not game:IsLoaded() then game.Loaded:Wait() end
local P = game:GetService("Players").LocalPlayer
local TS = game:GetService("TweenService")
local CG = game:GetService("CoreGui")
if CG:FindFirstChild("AlitHubUI") then CG.AlitHubUI:Destroy() end
_G.AlitHubFarmActive, _G.AlitHubRestockActive, _G.AlitHubPigActive = false, false, false
_G.TM = {["Dupa"]="Spawn_Dupa", ["Gagak"]="Spawn_Gagak", ["Jamur Kuburan"]="Spawn_JamurKuburan", ["Kemenyan"]="Spawn_Kemenyan", ["Kepiting Sungai"]="Spawn_KepitingSungai", ["Melati"]="Spawn_Melati"}
_G.RM = {["Kepiting"]="Kepiting", ["Sate Kepiting"]="Sate Kepiting"}
_G.FM = {["Jamur Rebus"]="JamurRebus", ["Pisang Raja Rebus"]="PisangRajaRebus"}
_G.ST, _G.SR, _G.SF = {}, {}, {}
_G.SPD, _G.PPD, _G.TD = 350, 0.3, 0.35
_G.SG = Instance.new("ScreenGui", CG)
_G.SG.Name = "AlitHubUI"; _G.SG.ResetOnSpawn = false
_G.MF = Instance.new("Frame", _G.SG)
_G.MF.Name = "MainFrame"; _G.MF.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
_G.MF.Position = UDim2.new(0.5, -110, 0.3, -100); _G.MF.Size = UDim2.new(0, 220, 0, 420); _G.MF.BorderSizePixel = 0; _G.MF.Active = true
Instance.new("UICorner", _G.MF).CornerRadius = UDim.new(0, 12)
local TB = Instance.new("Frame", _G.MF); TB.Size = UDim2.new(1, 0, 0, 45); TB.BackgroundTransparency = 1
local Title = Instance.new("TextButton", TB); Title.BackgroundTransparency = 1; Title.Position = UDim2.new(0, 15, 0, 0); Title.Size = UDim2.new(0, 120, 0, 45); Title.Font = Enum.Font.GothamBold; Title.Text = "ALIT HUB"; Title.TextColor3 = Color3.fromRGB(255, 215, 0); Title.TextSize = 14
local MB = Instance.new("TextButton", TB); MB.BackgroundTransparency = 1; MB.Position = UDim2.new(1, -35, 0, 0); MB.Size = UDim2.new(0, 30, 0, 45); MB.Text = "-"; MB.TextColor3 = Color3.fromRGB(200, 200, 200); MB.TextSize = 20
_G.CF = Instance.new("Frame", _G.MF); _G.CF.Name = "ContentFrame"; _G.CF.BackgroundTransparency = 1; _G.CF.Position = UDim2.new(0, 0, 0, 45); _G.CF.Size = UDim2.new(1, 0, 1, -45)
MB.Activated:Connect(function() _G.CF.Visible = false MB.Visible = false _G.MF.Position = UDim2.new(0, 10, 0.4, 0) _G.MF.Size = UDim2.new(0, 100, 0, 45) end)
Title.Activated:Connect(function() if not _G.CF.Visible then _G.MF.Position = UDim2.new(0.5, -110, 0.3, -100) _G.MF.Size = UDim2.new(0, 220, 0, 420) _G.CF.Visible = true MB.Visible = true end end)
-- [[ ALIT HUB PART 2 - BUTTONS & DROPDOWNS ]]
local function btn(n, p, c)
    local b = Instance.new("TextButton", _G.CF); b.Size = UDim2.new(0, 64, 0, 32); b.Position = p; b.BackgroundColor3 = Color3.fromRGB(220, 53, 69); b.Font = Enum.Font.GothamBold; b.Text = n; b.TextColor3 = Color3.fromRGB(255, 255, 255); b.TextSize = 10
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 5)
    b.Activated:Connect(function() c(b) end)
end
btn("FARM", UDim2.new(0.04, 0, 0.02, 0), function(b) _G.AlitHubFarmActive = not _G.AlitHubFarmActive b.BackgroundColor3 = _G.AlitHubFarmActive and Color3.fromRGB(40, 167, 69) or Color3.fromRGB(220, 53, 69) b.Text = _G.AlitHubFarmActive and "FARM: ON" or "FARM: OFF" end)
btn("STOCK", UDim2.new(0.36, 0, 0.02, 0), function(b) _G.AlitHubRestockActive = not _G.AlitHubRestockActive b.BackgroundColor3 = _G.AlitHubRestockActive and Color3.fromRGB(40, 167, 69) or Color3.fromRGB(220, 53, 69) b.Text = _G.AlitHubRestockActive and "STOCK: ON" or "STOCK: OFF" end)
btn("PIG", UDim2.new(0.68, 0, 0.02, 0), function(b) _G.AlitHubPigActive = not _G.AlitHubPigActive b.BackgroundColor3 = _G.AlitHubPigActive and Color3.fromRGB(40, 167, 69) or Color3.fromRGB(220, 53, 69) b.Text = _G.AlitHubPigActive and "PIG: ON" or "PIG: OFF" end)
local function drop(n, p, h, m, t)
    local db = Instance.new("TextButton", _G.CF); db.Size = UDim2.new(0.9, 0, 0, 28); db.Position = p; db.BackgroundColor3 = Color3.fromRGB(45, 45, 50); db.Font = Enum.Font.GothamSemibold; db.Text = n .. " ▼"; db.TextColor3 = Color3.fromRGB(240, 240, 240); db.TextSize = 10
    Instance.new("UICorner", db).CornerRadius = UDim.new(0, 5)
    local lc = Instance.new("ScrollingFrame", _G.CF); lc.Size = UDim2.new(0.9, 0, 0, h); lc.Position = UDim2.new(p.X.Scale, p.X.Offset, p.Y.Scale + 0.08, p.Y.Offset); lc.BackgroundColor3 = Color3.fromRGB(20, 20, 25); lc.BorderSizePixel = 0; lc.ScrollBarThickness = 3; lc.Visible = false
    Instance.new("UICorner", lc).CornerRadius = UDim.new(0, 5)
    Instance.new("UIListLayout", lc).Padding = UDim.new(0, 2)
    db.Activated:Connect(function() lc.Visible = not lc.Visible db.Text = lc.Visible and n .. " ▲" or n .. " ▼" end)
    for disp, ws in pairs(m) do
        local b2 = Instance.new("TextButton", lc); b2.Size = UDim2.new(1, 0, 0, 22); b2.BackgroundColor3 = Color3.fromRGB(35, 35, 40); b2.Text = disp; b2.TextColor3 = Color3.fromRGB(200, 200, 200); b2.TextSize = 9
        Instance.new("UICorner", b2).CornerRadius = UDim.new(0, 4)
        b2.Activated:Connect(function() local idx = table.find(t, ws) if idx then table.remove(t, idx) b2.BackgroundColor3 = Color3.fromRGB(35, 35, 40) else table.insert(t, ws) b2.BackgroundColor3 = Color3.fromRGB(40, 167, 69) end end)
    end
end
drop("TARGET FARM", UDim2.new(0.05, 0, 0.12, 0), 60, _G.TM, _G.ST)
drop("TARGET RESTOCK", UDim2.new(0.05, 0, 0.40, 0), 45, _G.RM, _G.SR)
drop("TARGET PAKAN PIG", UDim2.new(0.05, 0, 0.68, 0), 45, _G.FM, _G.SF)
local dT, dI, dS, sP
_G.MF.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dT = true dS = i.Position sP = _G.MF.Position i.Changed:Connect(function() if i.UserInputState == Enum.UserInputState.End then dT = false end end) end end)
_G.MF.InputChanged:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch then dI = i end end)
game:GetService("UserInputService").InputChanged:Connect(function(i) if i == dI and dT then local d = i.Position - dS _G.MF.Position = UDim2.new(sP.X.Scale, sP.X.Offset + d.X, sP.Y.Scale, sP.Y.Offset + d.Y) end end)
game:GetService("Players").LocalPlayer.Idled:Connect(function() if _G.AlitHubFarmActive or _G.AlitHubRestockActive or _G.AlitHubPigActive then game:GetService("VirtualUser"):Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame) task.wait(0.5) game:GetService("VirtualUser"):Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame) end end)
-- [[ ALIT HUB PART 3 - TP LOGIC & LOOP ]]
local P = game:GetService("Players").LocalPlayer
local TS = game:GetService("TweenService")
local function eq(n)
    local bp = P:FindFirstChild("Backpack") local ch = P.Character
    if bp and ch then
        local t = bp:FindFirstChild(n)
        if t and ch:FindFirstChildOfClass("Humanoid") then ch.Humanoid:EquipTool(t) return true end
    end
    return ch and ch:FindFirstChild(n) ~= nil
end
local function fp(p)
    if not p or not p.Enabled then return end
    if fireproximityprompt then fireproximityprompt(p) else p:InputHoldBegin() task.wait(p.HoldDuration + 0.05) p:InputHoldEnd() end
end
local function tv(r, h, t)
    if r and h then
        h:ChangeState(Enum.HumanoidStateType.Physics); r.Velocity = Vector3.new(0, 0, 0)
        local tw = TS:Create(r, TweenInfo.new((r.Position - t.Position).Magnitude / _G.SPD, Enum.EasingStyle.Linear), {CFrame = t})
        tw:Play() tw.Completed:Wait(); r.Velocity = Vector3.new(0, 0, 0); h:ChangeState(Enum.HumanoidStateType.Freefall)
    end
end
task.spawn(function()
    while true do
        task.wait(0.3)
        local ch = P.Character local r = ch and ch:FindFirstChild("HumanoidRootPart") local h = ch and ch:FindFirstChildOfClass("Humanoid")
        if _G.AlitHubFarmActive and #_G.ST > 0 and r and h then
            local f = workspace:FindFirstChild("SpawnBahan")
            if f then
                for _, o in pairs(f:GetChildren()) do
                    if not _G.AlitHubFarmActive then break end
                    if table.find(_G.ST, o.Name) then
                        local p = o:FindFirstChildWhichIsA("ProximityPrompt", true)
                        if p and p.Enabled and p.Parent then
                            local pt = p.Parent:IsA("BasePart") and p.Parent or o:FindFirstChildWhichIsA("BasePart", true)
                            if pt then tv(r, h, pt.CFrame) task.wait(_G.TD) if _G.AlitHubFarmActive and p.Enabled then fp(p) task.wait(_G.PPD) end end
                        end
                    end
                end
            end
        end
        if _G.AlitHubRestockActive and #_G.SR > 0 and r and h then
            local k = workspace:FindFirstChild("Kios_" .. P.Name)
            if k then
                for i = 1, 12 do
                    if not _G.AlitHubRestockActive then break end
                    local s = k:FindFirstChild("slot" .. i) or k:FindFirstChild("slot " .. i)
                    if s then
                        local p = s:FindFirstChildWhichIsA("ProximityPrompt", true)
                        if p and p.Enabled then
                            for _, tN in ipairs(_G.SR) do
                                if eq(tN) then
                                    local pt = s:IsA("BasePart") and s or s:FindFirstChildWhichIsA("BasePart", true)
                                    if pt then tv(r, h, pt.CFrame) task.wait(_G.TD) if p.Enabled and _G.AlitHubRestockActive then fp(p) task.wait(_G.PPD) end end
                                    break
                                end
                            end
                        end
                    end
                end
            end
        end
        if _G.AlitHubPigActive and r and h then
            local kd = workspace:FindFirstChild("KandangBabi_" .. P.UserId) or workspace:FindFirstChild("KandangBabi_" .. P.Name)
            if kd then
                local tm = kd:FindFirstChild("TempatMakan") or kd:FindFirstChild("Tempat Makan")
                if tm and #_G.SF > 0 then
                    local p = tm:FindFirstChildWhichIsA("ProximityPrompt", true)
                    if p then
                        local ts = p.ObjectText or ""
                        if string.find(ts, "0/10") or ts == "" then
                            for _, fN in ipairs(_G.SF) do
                                if eq(fN) then
                                    local pt = tm:IsA("BasePart") and tm or tm:FindFirstChildWhichIsA("BasePart", true)
                                    if pt then
                                        tv(r, h, pt.CFrame) task.wait(_G.TD)
                                        for c = 1, 10 do if not p.Enabled or not _G.AlitHubPigActive or string.find(p.ObjectText, "10/10") or not eq(fN) then break end fp(p) task.wait(0.3) end
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
                                if pt then tv(r, h, pt.CFrame) task.wait(_G.TD) if p.Enabled and _G.AlitHubPigActive then fp(p) task.wait(_G.PPD) end end
                            end
                        end
                    end
                end
            end
        end
    end
end)
