local ok, err = pcall(function()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

repeat task.wait() until LocalPlayer.Character
local Character = LocalPlayer.Character
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
local Humanoid = Character:WaitForChild("Humanoid")

local Settings = {
    AutoFarm    = false,
    AutoRaid    = false,
    AutoSkillR  = false,
    AutoSkillF  = false,
    AutoSkillC  = false,
    AutoSkillX  = false,
    AutoSkillT  = false,
    FarmRadius  = 150,
    AttackRange = 10,
    WalkSpeed   = 50,
    SkillDelay  = 0.5,
}

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "JJZAutoFarm"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = game:GetService("CoreGui")
print("[JJZ] ScreenGui created")

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 230, 0, 410)
MainFrame.Position = UDim2.new(0.5, -115, 0.5, -205)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)
print("[JJZ] MainFrame created")

local Stroke = Instance.new("UIStroke")
Stroke.Color = Color3.fromRGB(80, 0, 180)
Stroke.Thickness = 1.5
Stroke.Parent = MainFrame

local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 36)
TitleBar.BackgroundColor3 = Color3.fromRGB(80, 0, 180)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame
Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 10)

local TitleFix = Instance.new("Frame")
TitleFix.Size = UDim2.new(1, 0, 0.5, 0)
TitleFix.Position = UDim2.new(0, 0, 0.5, 0)
TitleFix.BackgroundColor3 = Color3.fromRGB(80, 0, 180)
TitleFix.BorderSizePixel = 0
TitleFix.Parent = TitleBar

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Text = "⚡ JJZ AutoFarm"
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextSize = 15
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.Size = UDim2.new(1, 0, 1, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Parent = TitleBar
print("[JJZ] TitleBar created")

local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 28, 0, 28)
MinBtn.Position = UDim2.new(1, -32, 0, 4)
MinBtn.BackgroundColor3 = Color3.fromRGB(60, 0, 140)
MinBtn.BorderSizePixel = 0
MinBtn.Text = "-"
MinBtn.Font = Enum.Font.GothamBold
MinBtn.TextSize = 16
MinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinBtn.Parent = TitleBar
Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 6)

local ContentFrame = Instance.new("Frame")
ContentFrame.Size = UDim2.new(1, 0, 1, -36)
ContentFrame.Position = UDim2.new(0, 0, 0, 36)
ContentFrame.BackgroundTransparency = 1
ContentFrame.Parent = MainFrame

local minimized = false
MinBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    ContentFrame.Visible = not minimized
    MainFrame.Size = minimized and UDim2.new(0, 230, 0, 36) or UDim2.new(0, 230, 0, 410)
    MinBtn.Text = minimized and "+" or "-"
end)

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Text = "● Idle"
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.TextSize = 10
StatusLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
StatusLabel.Size = UDim2.new(1, 0, 0, 20)
StatusLabel.Position = UDim2.new(0, 0, 1, -22)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Parent = ContentFrame

local function SetStatus(msg, color)
    StatusLabel.Text = "● " .. msg
    StatusLabel.TextColor3 = color or Color3.fromRGB(150, 150, 150)
end

local function CreateSection(parent, text, yPos)
    local lbl = Instance.new("TextLabel")
    lbl.Text = text
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 10
    lbl.TextColor3 = Color3.fromRGB(130, 80, 220)
    lbl.Size = UDim2.new(0.88, 0, 0, 16)
    lbl.Position = UDim2.new(0.06, 0, 0, yPos)
    lbl.BackgroundTransparency = 1
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = parent
end

local function CreateToggle(parent, label, yPos, settingKey)
    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(0.88, 0, 0, 34)
    Btn.Position = UDim2.new(0.06, 0, 0, yPos)
    Btn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    Btn.BorderSizePixel = 0
    Btn.Font = Enum.Font.GothamSemibold
    Btn.TextSize = 12
    Btn.TextColor3 = Color3.fromRGB(200, 200, 200)
    Btn.Text = "[OFF] " .. label
    Btn.TextXAlignment = Enum.TextXAlignment.Left
    Btn.AutoButtonColor = false
    Btn.Parent = parent
    Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 6)

    local BtnStroke = Instance.new("UIStroke")
    BtnStroke.Color = Color3.fromRGB(60, 60, 80)
    BtnStroke.Thickness = 1
    BtnStroke.Parent = Btn

    local Pad = Instance.new("UIPadding")
    Pad.PaddingLeft = UDim.new(0, 10)
    Pad.Parent = Btn

    Btn.MouseButton1Click:Connect(function()
        Settings[settingKey] = not Settings[settingKey]
        if Settings[settingKey] then
            Btn.Text = "[ON]  " .. label
            Btn.BackgroundColor3 = Color3.fromRGB(25, 40, 25)
            BtnStroke.Color = Color3.fromRGB(0, 200, 80)
        else
            Btn.Text = "[OFF] " .. label
            Btn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
            BtnStroke.Color = Color3.fromRGB(60, 60, 80)
        end
    end)
end

print("[JJZ] Building buttons...")
CreateSection(ContentFrame, "-- COMBAT --", 6)
CreateToggle(ContentFrame, "Auto Farm",      26,  "AutoFarm")
CreateToggle(ContentFrame, "Auto Raid Kill", 66,  "AutoRaid")
CreateSection(ContentFrame, "-- SKILLS --", 110)
CreateToggle(ContentFrame, "Auto Skill R",  130, "AutoSkillR")
CreateToggle(ContentFrame, "Auto Skill F",  170, "AutoSkillF")
CreateToggle(ContentFrame, "Auto Skill C",  210, "AutoSkillC")
CreateToggle(ContentFrame, "Auto Skill X",  250, "AutoSkillX")
CreateToggle(ContentFrame, "Auto Skill T",  290, "AutoSkillT")
print("[JJZ] GUI fully built!")

local function GetDistance(p1, p2)
    return (p1 - p2).Magnitude
end

local function IsEnemy(model)
    if not model:FindFirstChild("Humanoid") then return false end
    if not model:FindFirstChild("HumanoidRootPart") then return false end
    if model == Character then return false end
    if Players:GetPlayerFromCharacter(model) then return false end
    if model.Humanoid.Health <= 0 then return false end
    return true
end

local function GetNearestEnemy()
    local nearest, shortest = nil, Settings.FarmRadius
    for _, model in ipairs(workspace:GetDescendants()) do
        if model:IsA("Model") and IsEnemy(model) then
            local d = GetDistance(HumanoidRootPart.Position, model.HumanoidRootPart.Position)
            if d < shortest then shortest = d; nearest = model end
        end
    end
    return nearest
end

local function AttackEnemy(enemy)
    if not enemy or not enemy.Parent then return end
    if not enemy:FindFirstChild("HumanoidRootPart") then return end
    if enemy.Humanoid.Health <= 0 then return end
    local dist = GetDistance(HumanoidRootPart.Position, enemy.HumanoidRootPart.Position)
    if dist > Settings.AttackRange then
        Humanoid:MoveTo(enemy.HumanoidRootPart.Position)
    else
        local RS = game:GetService("ReplicatedStorage")
        local remote = RS:FindFirstChild("AttackRemote")
            or RS:FindFirstChild("Attack")
            or RS:FindFirstChild("Hit")
            or RS:FindFirstChild("DealDamage")
        if remote then pcall(function() remote:FireServer(enemy) end) end
        local tool = Character:FindFirstChildOfClass("Tool")
        if tool then pcall(function() tool:Activate() end) end
    end
end

local function DoRaidKill()
    local enemies = {}
    for _, model in ipairs(workspace:GetDescendants()) do
        if model:IsA("Model") and IsEnemy(model) then
            table.insert(enemies, model)
        end
    end
    if #enemies == 0 then
        SetStatus("Raid: No enemies found", Color3.fromRGB(255, 200, 0))
        return
    end
    table.sort(enemies, function(a, b)
        return GetDistance(HumanoidRootPart.Position, a.HumanoidRootPart.Position)
             < GetDistance(HumanoidRootPart.Position, b.HumanoidRootPart.Position)
    end)
    SetStatus("Raid: Killing " .. #enemies .. " enemies", Color3.fromRGB(255, 80, 80))
    local target = enemies[1]
    if target and target.Humanoid.Health > 0 then AttackEnemy(target) end
end

local VIM = game:GetService("VirtualInputManager")
local SkillKeys = {
    { key = "AutoSkillR", code = Enum.KeyCode.R },
    { key = "AutoSkillF", code = Enum.KeyCode.F },
    { key = "AutoSkillC", code = Enum.KeyCode.C },
    { key = "AutoSkillX", code = Enum.KeyCode.X },
    { key = "AutoSkillT", code = Enum.KeyCode.T },
}
local lastSkillTime = {}
for _, s in ipairs(SkillKeys) do lastSkillTime[s.key] = 0 end

local function FireSkills()
    local now = tick()
    for _, s in ipairs(SkillKeys) do
        if Settings[s.key] and (now - lastSkillTime[s.key]) >= Settings.SkillDelay then
            lastSkillTime[s.key] = now
            pcall(function()
                VIM:SendKeyEvent(true,  s.code, false, game)
                task.wait(0.05)
                VIM:SendKeyEvent(false, s.code, false, game)
            end)
        end
    end
end

LocalPlayer.CharacterAdded:Connect(function(char)
    Character = char
    HumanoidRootPart = char:WaitForChild("HumanoidRootPart")
    Humanoid = char:WaitForChild("Humanoid")
    Humanoid.WalkSpeed = Settings.WalkSpeed
    SetStatus("Respawned", Color3.fromRGB(100, 200, 255))
end)

Humanoid.WalkSpeed = Settings.WalkSpeed

RunService.Heartbeat:Connect(function()
    if not Character or not Humanoid then return end
    if Humanoid.Health <= 0 then return end
    if Settings.AutoFarm then
        local enemy = GetNearestEnemy()
        if enemy then
            AttackEnemy(enemy)
            SetStatus("Farming: " .. enemy.Name, Color3.fromRGB(0, 220, 100))
        else
            SetStatus("Farming: Searching...", Color3.fromRGB(200, 200, 0))
        end
    elseif Settings.AutoRaid then
        DoRaidKill()
    else
        SetStatus("Idle", Color3.fromRGB(150, 150, 150))
    end
    FireSkills()
end)

end)

-- Show error if something went wrong
if not ok then
    warn("[JJZ ERROR]: " .. tostring(err))
    print("[JJZ ERROR]: " .. tostring(err))
end
