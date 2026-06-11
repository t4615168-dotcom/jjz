local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

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

local Window = Rayfield:CreateWindow({
    Name = "JJZ AutoFarm",
    LoadingTitle = "JJZ AutoFarm",
    LoadingSubtitle = "Loading...",
    Theme = "Default",
    DisableRayfieldPrompts = false,
    DisableBuildWarnings = false,
})

local CombatTab = Window:CreateTab("Combat")
local SkillsTab = Window:CreateTab("Skills")

CombatTab:CreateSection("Combat")

CombatTab:CreateToggle({
    Name = "Auto Farm",
    CurrentValue = false,
    Flag = "AutoFarm",
    Callback = function(v)
        Settings.AutoFarm = v
        if v then Settings.AutoRaid = false end
    end,
})

CombatTab:CreateToggle({
    Name = "Auto Raid Kill",
    CurrentValue = false,
    Flag = "AutoRaid",
    Callback = function(v)
        Settings.AutoRaid = v
        if v then Settings.AutoFarm = false end
    end,
})

CombatTab:CreateSection("Settings")

CombatTab:CreateSlider({
    Name = "Farm Radius",
    Range = {50, 500},
    Increment = 10,
    Suffix = "studs",
    CurrentValue = 150,
    Flag = "FarmRadius",
    Callback = function(v)
        Settings.FarmRadius = v
    end,
})

CombatTab:CreateSlider({
    Name = "Attack Range",
    Range = {5, 50},
    Increment = 1,
    Suffix = "studs",
    CurrentValue = 10,
    Flag = "AttackRange",
    Callback = function(v)
        Settings.AttackRange = v
    end,
})

CombatTab:CreateSlider({
    Name = "Walk Speed",
    Range = {16, 100},
    Increment = 1,
    Suffix = "speed",
    CurrentValue = 50,
    Flag = "WalkSpeed",
    Callback = function(v)
        Settings.WalkSpeed = v
        if Humanoid then Humanoid.WalkSpeed = v end
    end,
})

SkillsTab:CreateSection("Auto Skills")

SkillsTab:CreateToggle({
    Name = "Auto Skill R",
    CurrentValue = false,
    Flag = "AutoSkillR",
    Callback = function(v) Settings.AutoSkillR = v end,
})

SkillsTab:CreateToggle({
    Name = "Auto Skill F",
    CurrentValue = false,
    Flag = "AutoSkillF",
    Callback = function(v) Settings.AutoSkillF = v end,
})

SkillsTab:CreateToggle({
    Name = "Auto Skill C",
    CurrentValue = false,
    Flag = "AutoSkillC",
    Callback = function(v) Settings.AutoSkillC = v end,
})

SkillsTab:CreateToggle({
    Name = "Auto Skill X",
    CurrentValue = false,
    Flag = "AutoSkillX",
    Callback = function(v) Settings.AutoSkillX = v end,
})

SkillsTab:CreateToggle({
    Name = "Auto Skill T",
    CurrentValue = false,
    Flag = "AutoSkillT",
    Callback = function(v) Settings.AutoSkillT = v end,
})

SkillsTab:CreateSlider({
    Name = "Skill Delay",
    Range = {1, 30},
    Increment = 1,
    Suffix = "x10ms",
    CurrentValue = 5,
    Flag = "SkillDelay",
    Callback = function(v)
        Settings.SkillDelay = v / 10
    end,
})

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
    if #enemies == 0 then return end
    table.sort(enemies, function(a, b)
        return GetDistance(HumanoidRootPart.Position, a.HumanoidRootPart.Position)
             < GetDistance(HumanoidRootPart.Position, b.HumanoidRootPart.Position)
    end)
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
                VIM:SendKeyEvent(true, s.code, false, game)
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
end)

Humanoid.WalkSpeed = Settings.WalkSpeed

RunService.Heartbeat:Connect(function()
    if not Character or not Humanoid then return end
    if Humanoid.Health <= 0 then return end
    if Settings.AutoFarm then
        local enemy = GetNearestEnemy()
        if enemy then AttackEnemy(enemy) end
    elseif Settings.AutoRaid then
        DoRaidKill()
    end
    FireSkills()
end)

Rayfield:Notify({
    Title = "JJZ AutoFarm",
    Content = "Loaded successfully!",
    Duration = 5,
})
