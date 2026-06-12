local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
_G.Rayfield = Rayfield

_G.Settings = {
    AutoFarm = false, AutoRaid = false,
    AutoSkillR = false, AutoSkillF = false, AutoSkillC = false,
    AutoSkillX = false, AutoSkillT = false,
    FarmRadius = 250, HoverHeight = 12, SkillDelay = 0.9, WalkSpeed = 55,
    TargetType = "All",
    SelectedEnemy = nil
}

local Window = Rayfield:CreateWindow({Name = "JJZ AutoFarm - Enemy Selector", LoadingTitle = "Loading...", Theme = "Default"})

local CombatTab = Window:CreateTab("Combat")
local SkillsTab = Window:CreateTab("Skills")

-- Enemy List
local EnemyList = {}
local EnemyDropdown

local function RefreshEnemies()
    EnemyList = {}
    local names = {}
    local LocalHRP = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    
    for _, model in ipairs(workspace:GetDescendants()) do
        if model:IsA("Model") and model:FindFirstChild("Humanoid") and model:FindFirstChild("HumanoidRootPart") then
            local name = model.Name
            local lower = name:lower()
            if model.Humanoid.Health > 0 and model ~= game.Players.LocalPlayer.Character then
                local dist = LocalHRP and math.floor((LocalHRP.Position - model.HumanoidRootPart.Position).Magnitude) or 0
                local display = name .. " (" .. dist .. "m)"
                table.insert(EnemyList, {Model = model, Display = display})
                table.insert(names, display)
            end
        end
    end
    
    if EnemyDropdown then
        EnemyDropdown:Refresh(names, true)  -- true = clear previous
    end
    print("[JJZ] Refreshed " .. #EnemyList .. " enemies")
end

CombatTab:CreateSection("Enemy Selection")
CombatTab:CreateButton({
    Name = "🔄 Refresh Enemies",
    Callback = RefreshEnemies
})

EnemyDropdown = CombatTab:CreateDropdown({
    Name = "Select Target Enemy",
    Options = {},
    CurrentOption = {},
    MultipleOptions = false,
    Callback = function(selected)
        if #selected > 0 then
            local selectedText = selected[1]
            for _, e in ipairs(EnemyList) do
                if e.Display == selectedText then
                    _G.Settings.SelectedEnemy = e.Model
                    print("[JJZ] Selected: " .. e.Display)
                    return
                end
            end
        end
    end
})

CombatTab:CreateToggle({Name = "Auto Farm (Use Selected)", CurrentValue = false, Callback = function(v)
    _G.Settings.AutoFarm = v
    if v then _G.Settings.AutoRaid = false end
end})

CombatTab:CreateToggle({Name = "Auto Raid Kill (Use Selected)", CurrentValue = false, Callback = function(v)
    _G.Settings.AutoRaid = v
    if v then _G.Settings.AutoFarm = false end
end})

CombatTab:CreateDropdown({
    Name = "Target Type (Fallback)",
    Options = {"All","Normal","MiniBoss","RaidBoss"},
    CurrentOption = {"All"},
    Callback = function(s) _G.Settings.TargetType = s[1] end,
})

CombatTab:CreateSection("Settings")
CombatTab:CreateSlider({Name = "Farm Radius", Range={50,400}, CurrentValue=250, Callback=function(v) _G.Settings.FarmRadius=v end})
CombatTab:CreateSlider({Name = "Hover Height", Range={5,30}, CurrentValue=12, Callback=function(v) _G.Settings.HoverHeight=v end})
CombatTab:CreateSlider({Name = "Walk Speed", Range={16,100}, CurrentValue=55, Callback=function(v) _G.Settings.WalkSpeed = v end})

SkillsTab:CreateSection("Auto Skills")
for _,k in {"R","F","C","X","T"} do
    SkillsTab:CreateToggle({Name = "Auto Skill "..k, Callback = function(v) _G.Settings["AutoSkill"..k] = v end})
end
SkillsTab:CreateSlider({Name = "Skill Delay", Range={5,30}, CurrentValue=9, Suffix="x0.1s", Callback=function(v) _G.Settings.SkillDelay = v*0.1 end})

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

-- Get Target
local function GetTargetEnemy()
    if Settings.SelectedEnemy and Settings.SelectedEnemy.Parent and Settings.SelectedEnemy:FindFirstChild("Humanoid") and Settings.SelectedEnemy.Humanoid.Health > 0 then
        return Settings.SelectedEnemy
    end
    -- Fallback nearest
    local nearest, dist = nil, Settings.FarmRadius
    for _, model in ipairs(workspace:GetDescendants()) do
        if model:IsA("Model") and model:FindFirstChild("Humanoid") and model:FindFirstChild("HumanoidRootPart") then
            local name = model.Name:lower()
            local valid = false
            local t = Settings.TargetType
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
    if not enemy or not enemy:FindFirstChild("HumanoidRootPart") then return end
    local pos = enemy.HumanoidRootPart.Position + Vector3.new(0, Settings.HoverHeight, -3)
    HRP.CFrame = CFrame.new(pos, enemy.HumanoidRootPart.Position)
end

local function ClickAttack()
    local tool = Character:FindFirstChildOfClass("Tool")
    if tool then pcall(function() tool:Activate() end) end
end

local function SimulateKey(keyCode)
    pcall(function()
        local VIM = game:GetService("VirtualInputManager")
        VIM:SendKeyEvent(true, keyCode, false, game)
        task.wait(0.08)
        VIM:SendKeyEvent(false, keyCode, false, game)
    end)
end

-- Main Loop
task.spawn(function()
    while true do
        task.wait(0.22)
        if not HRP or Humanoid.Health <= 0 then continue end

        if Settings.AutoFarm or Settings.AutoRaid then
            local enemy = GetTargetEnemy()
            if enemy then
                HoverOnEnemy(enemy)
                task.wait(0.12)
                ClickAttack()
            end
        end
    end
end)

-- Skills Loop
task.spawn(function()
    while true do
        task.wait(0.08)
        local now = tick()
        for _, s in ipairs({
            {k="AutoSkillR", c=Enum.KeyCode.R}, {k="AutoSkillF", c=Enum.KeyCode.F},
            {k="AutoSkillC", c=Enum.KeyCode.C}, {k="AutoSkillX", c=Enum.KeyCode.X},
            {k="AutoSkillT", c=Enum.KeyCode.T}
        }) do
            if Settings[s.k] then
                SimulateKey(s.c)
                task.wait(Settings.SkillDelay)
            end
        end
    end
end)

print("[JJZ] Enemy Selector Fixed! Click Refresh after spawning near enemies.")
