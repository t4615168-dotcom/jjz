local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
_G.Rayfield = Rayfield

_G.Settings = {
    AutoFarm = false, AutoRaid = false,
    AutoSkillR = false, AutoSkillF = false, AutoSkillC = false,
    AutoSkillX = false, AutoSkillT = false,
    FarmRadius = 250, HoverHeight = 12, SkillDelay = 0.7, WalkSpeed = 60,
    TargetType = "All"
}

local Window = Rayfield:CreateWindow({Name = "JJZ AutoFarm - Debug", LoadingTitle = "Loading...", Theme = "Default"})

local CombatTab = Window:CreateTab("Combat")
local SkillsTab = Window:CreateTab("Skills")

CombatTab:CreateToggle({Name = "Auto Farm", Callback = function(v) _G.Settings.AutoFarm = v end})
CombatTab:CreateToggle({Name = "Auto Raid Kill", Callback = function(v) _G.Settings.AutoRaid = v end})

CombatTab:CreateDropdown({Name = "Target Type", Options = {"All","Normal","MiniBoss","RaidBoss"}, CurrentOption={"All"}, Callback = function(s) _G.Settings.TargetType = s[1] end})

CombatTab:CreateSlider({Name = "Farm Radius", Range={50,500}, CurrentValue=250, Callback=function(v) _G.Settings.FarmRadius=v end})
CombatTab:CreateSlider({Name = "Hover Height", Range={5,30}, CurrentValue=12, Callback=function(v) _G.Settings.HoverHeight=v end})

SkillsTab:CreateSection("Auto Skills")
for _,k in {"R","F","C","X","T"} do
    SkillsTab:CreateToggle({Name="Auto Skill "..k, Callback=function(v) _G.Settings["AutoSkill"..k]=v end})
end
SkillsTab:CreateSlider({Name="Skill Delay", Range={1,30}, CurrentValue=7, Callback=function(v) _G.Settings.SkillDelay = v*0.1 end})

print("[JJZ] UI Loaded - Debug Mode")

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Settings = _G.Settings
local Character, HRP, Humanoid

local function UpdateChar()
    Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    HRP = Character:WaitForChild("HumanoidRootPart")
    Humanoid = Character:WaitForChild("Humanoid")
    print("[JJZ] Character Loaded")
end
UpdateChar()
LocalPlayer.CharacterAdded:Connect(UpdateChar)

-- Jujutsu Zero Enemy Finder (more aggressive)
local function GetNearestEnemy()
    local nearest, dist = nil, Settings.FarmRadius
    for _, folder in ipairs(workspace:GetChildren()) do
        for _, model in ipairs(folder:GetDescendants()) do
            if model:IsA("Model") and model:FindFirstChild("Humanoid") and model:FindFirstChild("HumanoidRootPart") then
                local name = model.Name:lower()
                local valid = false
                local t = Settings.TargetType

                if t == "All" or (t == "Normal" and not (name:find("boss") or name:find("raid") or name:find("remnant"))) then
                    valid = true
                elseif t == "MiniBoss" and (name:find("remnant") or name:find("mini")) then
                    valid = true
                elseif t == "RaidBoss" and (name:find("raid") or name:find("jogo") or name:find("sukuna") or name:find("toji")) then
                    valid = true
                end

                if valid and model.Humanoid.Health > 0 and model ~= Character then
                    local d = (HRP.Position - model.HumanoidRootPart.Position).Magnitude
                    if d < dist then
                        dist = d
                        nearest = model
                    end
                end
            end
        end
    end
    if nearest then
        print("[JJZ] Found enemy: " .. nearest.Name .. " | Distance: " .. math.floor(dist))
    end
    return nearest
end

local function HoverOnEnemy(enemy)
    if not enemy then return end
    local pos = enemy.HumanoidRootPart.Position + Vector3.new(0, Settings.HoverHeight, 0)
    HRP.CFrame = CFrame.new(pos)
    print("[JJZ] Hovering on: " .. enemy.Name)
end

local function ClickAttack()
    local tool = Character:FindFirstChildOfClass("Tool")
    if tool then
        tool:Activate()
        print("[JJZ] Tool Activated: " .. tool.Name)
    else
        print("[JJZ] No tool equipped")
    end
end

local function SimulateKey(key)
    local VIM = game:GetService("VirtualInputManager")
    VIM:SendKeyEvent(true, key, false, game)
    task.wait(0.07)
    VIM:SendKeyEvent(false, key, false, game)
    print("[JJZ] Simulated key: " .. tostring(key))
end

-- Main Farm Loop
task.spawn(function()
    while true do
        task.wait(0.12)
        if not HRP or Humanoid.Health <= 0 then continue end

        if Settings.AutoFarm or Settings.AutoRaid then
            local enemy = GetNearestEnemy()
            if enemy then
                HoverOnEnemy(enemy)
                task.wait(0.1)
                ClickAttack()
            else
                print("[JJZ] No enemy found in radius")
            end
        end
    end
end)

-- Skill Loop
task.spawn(function()
    while true do
        task.wait(0.06)
        local now = tick()
        for _, skill in ipairs({{k="AutoSkillR",c=Enum.KeyCode.R},{k="AutoSkillF",c=Enum.KeyCode.F},{k="AutoSkillC",c=Enum.KeyCode.C},{k="AutoSkillX",c=Enum.KeyCode.X},{k="AutoSkillT",c=Enum.KeyCode.T}}) do
            if Settings[skill.k] then
                SimulateKey(skill.c)
                task.wait(Settings.SkillDelay)
            end
        end
    end
end)

print("[JJZ] Debug Script Loaded - Check F9 for logs!")
