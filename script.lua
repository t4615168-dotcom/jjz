local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
_G.Rayfield = Rayfield

_G.Settings = {
    AutoFarm = false, AutoRaid = false,
    AutoSkillR = false, AutoSkillF = false, AutoSkillC = false,
    AutoSkillX = false, AutoSkillT = false,
    FarmRadius = 300, HoverHeight = 12, SkillDelay = 0.9, WalkSpeed = 55,
    TargetType = "All",
    SelectedEnemy = nil
}

local Window = Rayfield:CreateWindow({Name = "JJZ AutoFarm - Quest Fix", LoadingTitle = "Loading...", Theme = "Default"})

local CombatTab = Window:CreateTab("Combat")
local SkillsTab = Window:CreateTab("Skills")

local EnemyList = {}
local EnemyDropdown

local function IsValidEnemyModel(model)
    if not model or not model:IsA("Model") then return false end
    local name = model.Name:lower()
    
    -- Filter out junk
    if name:find("visual") or name:find("default_client") or name:find("camera") or name:find("effect") then
        return false
    end
    
    local hum = model:FindFirstChild("Humanoid")
    local hrp = model:FindFirstChild("HumanoidRootPart")
    
    return hum and hrp and hum.Health > 0
end

local function RefreshEnemies()
    EnemyList = {}
    local names = {}
    local LocalCharacter = game.Players.LocalPlayer.Character
    local LocalHRP = LocalCharacter and LocalCharacter:FindFirstChild("HumanoidRootPart")
    
    -- Deep scan
    for _, model in ipairs(workspace:GetDescendants()) do
        if IsValidEnemyModel(model) and model ~= LocalCharacter then
            local dist = LocalHRP and math.floor((LocalHRP.Position - model.HumanoidRootPart.Position).Magnitude) or 0
            local display = model.Name .. " (" .. dist .. "m)"
            
            table.insert(EnemyList, {Model = model, Display = display})
            table.insert(names, display)
        end
    end
    
    -- Sort by distance (closer first)
    table.sort(EnemyList, function(a, b)
        return a.Display < b.Display  -- simple sort by name+distance
    end)
    
    if EnemyDropdown then
        EnemyDropdown:Refresh(names, true)
    end
    print("[JJZ] Found " .. #EnemyList .. " valid enemies (including Upper Year Student)")
end

CombatTab:CreateSection("Enemy Selection")
CombatTab:CreateButton({
    Name = "🔄 Refresh Enemies (Quest Fix)",
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

CombatTab:CreateSection("Settings")
CombatTab:CreateSlider({Name = "Farm Radius", Range={50,500}, CurrentValue=300, Callback=function(v) _G.Settings.FarmRadius=v end})
CombatTab:CreateSlider({Name = "Hover Height", Range={5,30}, CurrentValue=12, Callback=function(v) _G.Settings.HoverHeight=v end})
CombatTab:CreateSlider({Name = "Walk Speed", Range={16,100}, CurrentValue=55, Callback=function(v) _G.Settings.WalkSpeed = v end})

SkillsTab:CreateSection("Auto Skills")
for _,k in {"R","F","C","X","T"} do
    SkillsTab:CreateToggle({Name = "Auto Skill "..k, Callback = function(v) _G.Settings["AutoSkill"..k] = v end})
end
SkillsTab:CreateSlider({Name = "Skill Delay", Range={5,30}, CurrentValue=9, Suffix="x0.1s", Callback=function(v) _G.Settings.SkillDelay = v*0.1 end})

print("[JJZ] UI Loaded with Improved Detection!")

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

local function GetTargetEnemy()
    if Settings.SelectedEnemy and Settings.SelectedEnemy.Parent and Settings.SelectedEnemy:FindFirstChild("Humanoid") and Settings.SelectedEnemy.Humanoid.Health > 0 then
        return Settings.SelectedEnemy
    end
    return nil
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
        task.wait(0.1)
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

print("[JJZ] Ready! Accept quest → Refresh Enemies")
