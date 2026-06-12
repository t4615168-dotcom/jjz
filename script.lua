local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
_G.Rayfield = Rayfield

_G.Settings = {
    AutoFarm = false, AutoRaid = false,
    AutoSkillR = false, AutoSkillF = false, AutoSkillC = false,
    AutoSkillX = false, AutoSkillT = false,
    FarmRadius = 300, HoverHeight = 12, SkillDelay = 0.9, WalkSpeed = 55,
    SelectedEnemy = nil
}

local Window = Rayfield:CreateWindow({Name = "JJZ AutoFarm - Upper Year Fix", LoadingTitle = "Loading...", Theme = "Default"})

local CombatTab = Window:CreateTab("Combat")
local SkillsTab = Window:CreateTab("Skills")

local EnemyList = {}
local EnemyDropdown

local function IsValidEnemy(model)
    if not model or not model:IsA("Model") then return false end
    
    local nameLower = model.Name:lower()
    -- Keep only likely enemies
    if nameLower:find("visual") or nameLower:find("default_client") or nameLower:find("camera") or 
       nameLower:find("effect") or nameLower:find("particle") or nameLower:find("map") then
        return false
    end
    
    local hum = model:FindFirstChild("Humanoid")
    local hrp = model:FindFirstChild("HumanoidRootPart")
    
    if hum and hrp and hum.Health > 0 then
        -- Extra check for quest enemies like Upper Year Student
        return true
    end
    return false
end

local function RefreshEnemies()
    EnemyList = {}
    local names = {}
    local LocalCharacter = game.Players.LocalPlayer.Character
    local LocalHRP = LocalCharacter and LocalCharacter:FindFirstChild("HumanoidRootPart")
    
    print("[JJZ] Starting deep scan for Upper Year Student...")

    for _, model in ipairs(workspace:GetDescendants()) do
        if IsValidEnemy(model) and model ~= LocalCharacter then
            local dist = LocalHRP and math.floor((LocalHRP.Position - model.HumanoidRootPart.Position).Magnitude) or 0
            local display = model.Name .. " (" .. dist .. "m)"
            
            table.insert(EnemyList, {Model = model, Display = display})
            table.insert(names, display)
            
            if model.Name:lower():find("upper") or model.Name:lower():find("student") then
                print("[JJZ] FOUND QUEST ENEMY: " .. model.Name)
            end
        end
    end
    
    table.sort(names)  -- Sort alphabetically
    
    if EnemyDropdown then
        EnemyDropdown:Refresh(names, true)
    end
    
    print("[JJZ] Total valid targets found: " .. #EnemyList)
end

CombatTab:CreateSection("Enemy Selection")
CombatTab:CreateButton({
    Name = "🔄 Refresh Enemies (Upper Year Student Fix)",
    Callback = RefreshEnemies
})

EnemyDropdown = CombatTab:CreateDropdown({
    Name = "Select Target Enemy",
    Options = {},
    CurrentOption = {},
    MultipleOptions = false,
    Callback = function(selected)
        if #selected > 0 then
            local sel = selected[1]
            for _, e in ipairs(EnemyList) do
                if e.Display == sel then
                    _G.Settings.SelectedEnemy = e.Model
                    print("[JJZ] ✅ Selected: " .. sel)
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

print("[JJZ] UI Loaded - Upper Year Student Detection Active!")

-- Services & Character
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
        task.wait(0.25)
        if not HRP or Humanoid.Health <= 0 then continue end

        if Settings.AutoFarm or Settings.AutoRaid then
            local enemy = GetTargetEnemy()
            if enemy then
                HoverOnEnemy(enemy)
                task.wait(0.15)
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

print("[JJZ] Test: Accept quest → Refresh Enemies")
