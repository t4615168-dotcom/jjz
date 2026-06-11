local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
_G.Rayfield = Rayfield

_G.Settings = {
    AutoFarm = false,
    AutoRaid = false,
    AutoSkillR = false, AutoSkillF = false, AutoSkillC = false,
    AutoSkillX = false, AutoSkillT = false,
    FarmRadius = 200,
    HoverHeight = 10,
    SkillDelay = 0.8,
    WalkSpeed = 60,
    TargetType = "All"
}

local Window = Rayfield:CreateWindow({Name = "JJZ AutoFarm", LoadingTitle = "JJZ AutoFarm", LoadingSubtitle = "by Grok", Theme = "Default"})

local CombatTab = Window:CreateTab("Combat")
local SkillsTab = Window:CreateTab("Skills")

CombatTab:CreateSection("Combat")
CombatTab:CreateToggle({Name = "Auto Farm", CurrentValue = false, Callback = function(v)
    _G.Settings.AutoFarm = v
    if v then _G.Settings.AutoRaid = false end
end})

CombatTab:CreateToggle({Name = "Auto Raid Kill", CurrentValue = false, Callback = function(v)
    _G.Settings.AutoRaid = v
    if v then _G.Settings.AutoFarm = false end
end})

CombatTab:CreateDropdown({
    Name = "Target Type",
    Options = {"All", "Normal", "MiniBoss", "RaidBoss"},
    CurrentOption = {"All"},
    Callback = function(selected) _G.Settings.TargetType = selected[1] end,
})

CombatTab:CreateSection("Settings")
CombatTab:CreateSlider({Name = "Farm Radius", Range = {50, 500}, Increment = 10, CurrentValue = 200, Callback = function(v) _G.Settings.FarmRadius = v end})
CombatTab:CreateSlider({Name = "Hover Height", Range = {5, 25}, Increment = 1, CurrentValue = 10, Callback = function(v) _G.Settings.HoverHeight = v end})
CombatTab:CreateSlider({Name = "Walk Speed", Range = {16, 120}, Increment = 1, CurrentValue = 60, Callback = function(v) _G.Settings.WalkSpeed = v end})

SkillsTab:CreateSection("Auto Skills")
for _, k in ipairs({"R","F","C","X","T"}) do
    SkillsTab:CreateToggle({Name = "Auto Skill "..k, Callback = function(v) _G.Settings["AutoSkill"..k] = v end})
end
SkillsTab:CreateSlider({Name = "Skill Delay", Range = {1, 30}, Increment = 1, Suffix = "x0.1s", CurrentValue = 8, Callback = function(v) _G.Settings.SkillDelay = v * 0.1 end})

print("[JJZ] UI Loaded!")

-- Services
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Settings = _G.Settings

local Character, HRP, Humanoid

local function UpdateChar()
    Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    HRP = Character:WaitForChild("HumanoidRootPart")
    Humanoid = Character:WaitForChild("Humanoid")
    Humanoid.WalkSpeed = Settings.WalkSpeed
end
UpdateChar()
LocalPlayer.CharacterAdded:Connect(UpdateChar)

-- Auto Equip Tool
local function EquipTool()
    local tool = Character:FindFirstChildOfClass("Tool")
    if not tool then
        for _, v in ipairs(Character:GetChildren()) do
            if v:IsA("Tool") then v.Parent = Character; break end
        end
    end
end

-- Enemy Detection (Jujutsu Zero specific)
local function IsValidEnemy(model)
    if not model or not model:FindFirstChild("Humanoid") or not model:FindFirstChild("HumanoidRootPart") then return false end
    if model == Character or Players:GetPlayerFromCharacter(model) then return false end
    if model.Humanoid.Health <= 0 then return false end
    return true
end

local function GetNearestEnemy()
    local nearest, dist = nil, Settings.FarmRadius
    for _, v in ipairs(workspace:GetDescendants()) do
        if not v:IsA("Model") then continue end
        local name = v.Name:lower()
        local valid = false
        local t = Settings.TargetType

        if t == "All" then
            valid = IsValidEnemy(v)
        elseif t == "Normal" then
            valid = IsValidEnemy(v) and not (name:find("boss") or name:find("raid") or name:find("remnant"))
        elseif t == "MiniBoss" then
            valid = IsValidEnemy(v) and (name:find("remnant") or name:find("mini") or name:find("elite"))
        elseif t == "RaidBoss" then
            valid = IsValidEnemy(v) and (name:find("raid") or name:find("jogo") or name:find("toji") or name:find("sukuna") or name:find("hajime"))
        end

        if valid then
            local d = (HRP.Position - v.HumanoidRootPart.Position).Magnitude
            if d < dist then
                dist = d
                nearest = v
            end
        end
    end
    return nearest
end

-- Improved Hover for Delta
local function HoverOnEnemy(enemy)
    if not enemy or not enemy:FindFirstChild("HumanoidRootPart") then return end
    local targetPos = enemy.HumanoidRootPart.Position + Vector3.new(0, Settings.HoverHeight, 0)
    
    HRP.CFrame = CFrame.new(targetPos, enemy.HumanoidRootPart.Position)
    
    -- Extra stability
    local vel = Instance.new("BodyVelocity")
    vel.MaxForce = Vector3.new(1e5, 1e5, 1e5)
    vel.Velocity = Vector3.new(0, 5, 0)
    vel.Parent = HRP
    game:GetService("Debris"):AddItem(vel, 0.2)
end

-- Attack
local function ClickAttack()
    EquipTool()
    local tool = Character:FindFirstChildOfClass("Tool")
    if tool then
        pcall(function() tool:Activate() end)
        
        for _, desc in ipairs(tool:GetDescendants()) do
            if desc:IsA("RemoteEvent") or desc:IsA("RemoteFunction") then
                pcall(function() desc:FireServer() end)
            end
        end
    end

    -- Mouse click simulation (Delta reliable)
    pcall(function()
        local VIM = game:GetService("VirtualInputManager")
        VIM:SendMouseButtonEvent(workspace.CurrentCamera.ViewportSize.X/2, workspace.CurrentCamera.ViewportSize.Y/2, 0, true, game, 1)
        task.wait(0.04)
        VIM:SendMouseButtonEvent(workspace.CurrentCamera.ViewportSize.X/2, workspace.CurrentCamera.ViewportSize.Y/2, 0, false, game, 1)
    end)
end

local function AttackEnemy(enemy)
    if not enemy then return end
    HoverOnEnemy(enemy)
    task.wait(0.1)
    ClickAttack()
end

-- Skills
local function SimulateKey(keyCode)
    pcall(function()
        local VIM = game:GetService("VirtualInputManager")
        VIM:SendKeyEvent(true, keyCode, false, game)
        task.wait(0.06)
        VIM:SendKeyEvent(false, keyCode, false, game)
    end)
end

local SkillKeys = {
    {key = "AutoSkillR", code = Enum.KeyCode.R},
    {key = "AutoSkillF", code = Enum.KeyCode.F},
    {key = "AutoSkillC", code = Enum.KeyCode.C},
    {key = "AutoSkillX", code = Enum.KeyCode.X},
    {key = "AutoSkillT", code = Enum.KeyCode.T},
}

local lastSkillTime = {}
for _, s in ipairs(SkillKeys) do lastSkillTime[s.key] = 0 end

local function FireSkills()
    local now = tick()
    for _, s in ipairs(SkillKeys) do
        if Settings[s.key] and (now - lastSkillTime[s.key]) >= Settings.SkillDelay then
            lastSkillTime[s.key] = now
            SimulateKey(s.code)
        end
    end
end

-- Main Loops
task.spawn(function()
    while true do
        task.wait(0.08)
        if not HRP or Humanoid.Health <= 0 then continue end

        if Settings.AutoFarm or Settings.AutoRaid then
            local enemy = GetNearestEnemy()
            if enemy then
                AttackEnemy(enemy)
            end
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(0.05)
        FireSkills()
    end
end)

print("[JJZ] Logic Loaded for Jujutsu Zero! (Delta Optimized)")
