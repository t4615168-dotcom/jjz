local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
_G.Rayfield = Rayfield

_G.Settings = {
    AutoFarm = false, AutoRaid = false,
    AutoSkillR = false, AutoSkillF = false, AutoSkillC = false,
    AutoSkillX = false, AutoSkillT = false,
    FarmRadius = 180, HoverHeight = 12, SkillDelay = 0.9, WalkSpeed = 55,
    TargetType = "All"
}

local Window = Rayfield:CreateWindow({Name = "JJZ AutoFarm - Stable", LoadingTitle = "Loading...", Theme = "Default"})

local CombatTab = Window:CreateTab("Combat")
local SkillsTab = Window:CreateTab("Skills")

CombatTab:CreateToggle({Name = "Auto Farm", CurrentValue = false, Callback = function(v) _G.Settings.AutoFarm = v end})
CombatTab:CreateToggle({Name = "Auto Raid Kill", CurrentValue = false, Callback = function(v) _G.Settings.AutoRaid = v end})

CombatTab:CreateDropdown({Name = "Target Type", Options = {"All","Normal","MiniBoss","RaidBoss"}, CurrentOption={"All"}, Callback = function(s) _G.Settings.TargetType = s[1] end})

CombatTab:CreateSection("Settings")
CombatTab:CreateSlider({Name = "Farm Radius", Range={50,400}, CurrentValue=180, Callback=function(v) _G.Settings.FarmRadius=v end})
CombatTab:CreateSlider({Name = "Hover Height", Range={5,25}, CurrentValue=12, Callback=function(v) _G.Settings.HoverHeight=v end})
CombatTab:CreateSlider({Name = "Walk Speed", Range={16,100}, CurrentValue=55, Callback=function(v) _G.Settings.WalkSpeed = v end})

SkillsTab:CreateSection("Auto Skills")
for _,k in {"R","F","C","X","T"} do
    SkillsTab:CreateToggle({Name = "Auto Skill "..k, Callback = function(v) _G.Settings["AutoSkill"..k] = v end})
end
SkillsTab:CreateSlider({Name = "Skill Delay", Range={5,30}, CurrentValue=9, Suffix="x0.1s", Callback=function(v) _G.Settings.SkillDelay = v*0.1 end})

print("[JJZ] UI Loaded!")

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

-- Enemy Finder (Jujutsu Zero)
local function GetNearestEnemy()
    local nearest, dist = nil, Settings.FarmRadius
    for _, model in ipairs(workspace:GetDescendants()) do
        if model:IsA("Model") and model:FindFirstChild("Humanoid") and model:FindFirstChild("HumanoidRootPart") then
            local name = model.Name:lower()
            local t = Settings.TargetType
            local valid = false

            if t == "All" then valid = true
            elseif t == "Normal" and not (name:find("boss") or name:find("raid") or name:find("remnant")) then valid = true
            elseif t == "MiniBoss" and (name:find("remnant") or name:find("mini")) then valid = true
            elseif t == "RaidBoss" and (name:find("raid") or name:find("jogo") or name:find("sukuna") or name:find("toji")) then valid = true
            end

            if valid and model.Humanoid.Health > 0 and model ~= Character then
                local d = (HRP.Position - model.HumanoidRootPart.Position).Magnitude
                if d < dist then dist = d; nearest = model end
            end
        end
    end
    return nearest
end

local function HoverOnEnemy(enemy)
    if not enemy then return end
    local pos = enemy.HumanoidRootPart.Position + Vector3.new(0, Settings.HoverHeight, -2) -- slight offset
    HRP.CFrame = CFrame.new(pos, enemy.HumanoidRootPart.Position)
end

local function ClickAttack()
    local tool = Character:FindFirstChildOfClass("Tool")
    if tool then
        pcall(function() tool:Activate() end)
    end
end

local function SimulateKey(keyCode)
    pcall(function()
        local VIM = game:GetService("VirtualInputManager")
        VIM:SendKeyEvent(true, keyCode, false, game)
        task.wait(0.08)
        VIM:SendKeyEvent(false, keyCode, false, game)
    end)
end

-- Slower, stable loops
task.spawn(function()
    while true do
        task.wait(0.25) -- Much slower to stop spam
        if not HRP or Humanoid.Health <= 0 then continue end

        if Settings.AutoFarm or Settings.AutoRaid then
            local enemy = GetNearestEnemy()
            if enemy then
                HoverOnEnemy(enemy)
                task.wait(0.15)
                ClickAttack()
            end
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(0.1)
        local now = tick()
        for _, s in ipairs({
            {k="AutoSkillR", c=Enum.KeyCode.R},
            {k="AutoSkillF", c=Enum.KeyCode.F},
            {k="AutoSkillC", c=Enum.KeyCode.C},
            {k="AutoSkillX", c=Enum.KeyCode.X},
            {k="AutoSkillT", c=Enum.KeyCode.T}
        }) do
            if Settings[s.k] and (now - (lastSkillTime or 0)) >= Settings.SkillDelay then
                lastSkillTime = now
                SimulateKey(s.c)
            end
        end
    end
end)

local lastSkillTime = 0
print("[JJZ] Stable Version Loaded - Spam Fixed")
