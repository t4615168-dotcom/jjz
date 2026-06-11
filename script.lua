-- Load Rayfield Library
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

repeat task.wait() until LocalPlayer.Character
local Character = LocalPlayer.Character
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
local Humanoid = Character:WaitForChild("Humanoid")

-- Settings
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

-- Create Window
local Window = Rayfield:CreateWindow({
    Name = "JJZ AutoFarm",
    LoadingTitle = "JJZ AutoFarm",
    LoadingSubtitle = "by script",
    Theme = "Default",
    DisableRayfieldPrompts = false,
    DisableBuildWarnings = false,
})

-- Combat Tab
local CombatTab = Window:CreateTab("Combat", 4483362458)

CombatTab:CreateSection("Auto Combat")

CombatTab:CreateToggle({
    Name = "Auto Farm",
    CurrentValue = false,
    Flag = "AutoFarm",
    Callback = function(value)
        Settings.AutoFarm = value
        if value then Settings.AutoRaid = false end
    end,
})

CombatTab:CreateToggle({
    Name = "Auto Raid Kill",
    CurrentValue = false,
    Flag = "AutoRaid",
    Callback = function(value)
        Settings.AutoRaid = value
        if value then Settings.AutoFarm = false end
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
    Callback = function(value)
        Settings.FarmRadius = value
    end,
})

CombatTab:CreateSlider({
    Name = "Attack Range",
    Range = {5, 50},
    Increment = 1,
    Suffix = "studs",
    CurrentValue = 10,
    Flag = "AttackRange",
    Callback = function(value)
        Settings.AttackRange = value
    end,
})

CombatTab:CreateSlider({
    Name = "Walk Speed",
    Range = {16, 100},
    Increment = 1,
    Suffix = "speed",
    CurrentValue = 50,
    Flag = "WalkSpeed",
    Callback = function(value)
        Settings.WalkSpeed = value
        if Humanoid then
            Humanoid.WalkSpeed = value
        end
    end,
})

-- Skills Tab
local SkillsTab = Window:CreateTab("Skills", 4483362458)

SkillsTab:CreateSection("Auto Skills")

SkillsTab:CreateToggle({
    Name = "Auto Skill [R]",
    CurrentValue = false,
    Flag = "AutoSkillR",
    Callback = function(value)
        Settings.AutoSkillR = value
    end,
})

SkillsTab:CreateToggle({
    Name = "Auto Skill [F]",
    CurrentValue = false,
    Flag = "AutoSkillF",
    Callback = function(value)
        Settings.AutoSkillF = value
    end,
})

SkillsTab:CreateToggle({
    Name = "Auto Skill [C]",
    CurrentValue = false,
    Flag = "AutoSkillC",
    Callback = function(value)
        Settings.AutoSkillC = value
    end,
})

SkillsTab:CreateToggle({
    Name = "Auto Skill [X]",
    CurrentValue = false,
    Flag = "AutoSkillX",
    Callback = function(value)
        Settings.AutoSkillX = value
    end,
})

SkillsTab:CreateToggle({
    Name = "Auto Skill [T]",
    CurrentValue = false,
    Flag = "AutoSkillT",
    Callback = function(value)
        Settings.AutoSkillT = value
    end,
})

SkillsTab:CreateSection("Skill Settings")

SkillsTab:CreateSlider({
    Name = "Skill Delay",
    Range = {0.1, 3},
    Increment = 0.1,
    Suffix = "s",
    CurrentValue = 0.5,
    Flag = "SkillDelay",
    Callback = function(value)
        Settings.SkillDelay = value
    end,
})

-- Info Tab
local InfoTab = Window:CreateTab("Info", 4483362458)

InfoTab:CreateSection("Status")

local StatusParagraph = InfoTab:CreateParagraph({
    Title = "Current Status",
    Content = "Idle"
})

local function SetStatus(msg)
    StatusParagraph:Set({
        Title = "Current Status",
        Content = msg
    })
end

InfoTab:CreateSection("About")
InfoTab:CreateParagraph({
    Title = "JJZ AutoFarm",
    Content = "Auto Farm - Kills nearby enemies\nAuto Raid Kill - Clears all enemies in current raid\nAuto Skills - Auto uses R F C X T skills"
})

-- Utilities
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
        SetStatus("Raid: No enemies found")
        return
    end
    table.sort(enemies, function(a, b)
        return GetDistance(HumanoidRootPart.Position, a.HumanoidRootPart.Position)
             < GetDistance(HumanoidRootPart.Position, b.HumanoidRootPart.Position)
    end)
    SetStatus("Raid: Killing " .. #enemies .. " enemies")
    local target = enemies[1]
    if target and target.Humanoid.Health > 0 then AttackEnemy(target) end
end

-- Auto Skill
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

-- Respawn Handler
LocalPlayer.CharacterAdded:Connect(function(char)
    Character = char
    HumanoidRootPart = char:WaitForChild("HumanoidRootPart")
    Humanoid = char:WaitForChild("Humanoid")
    Humanoid.WalkSpeed = Settings.WalkSpeed
    SetStatus("Respawned")
end)

Humanoid.WalkSpeed = Settings.WalkSpeed

-- Main Loop
RunService.Heartbeat:Connect(function()
    if not Character or not Humanoid then return end
    if Humanoid.Health <= 0 then return end
    if Settings.AutoFarm then
        local enemy = GetNearestEnemy()
        if enemy then
            AttackEnemy(enemy)
            SetStatus("Farming: " .. enemy.Name)
        else
            SetStatus("Farming: Searching...")
        end
    elseif Settings.AutoRaid then
        DoRaidKill()
    else
        SetStatus("Idle")
    end
    FireSkills()
end)

Rayfield:Notify({
    Title = "JJZ AutoFarm",
    Content = "Script loaded successfully!",
    Duration = 5,
})
