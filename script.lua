local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
_G.Rayfield = Rayfield

_G.Settings = {
    AutoFarm = false, AutoRaid = false,
    AutoSkillR = false, AutoSkillF = false, AutoSkillC = false,
    AutoSkillX = false, AutoSkillT = false,
    FarmRadius = 300, HoverHeight = 12, SkillDelay = 0.9, WalkSpeed = 55,
    SelectedEnemy = nil
}

local Window = Rayfield:CreateWindow({Name = "JJZ AutoFarm - Strict Enemy", LoadingTitle = "Loading...", Theme = "Default"})

local CombatTab = Window:CreateTab("Combat")
local SkillsTab = Window:CreateTab("Skills")

local EnemyList = {}
local EnemyDropdown

local function IsRealEnemy(model)
    if not model or not model:IsA("Model") then return false end
    local nameLower = model.Name:lower()

    -- Skip known junk/friendly/system objects
    local badKeywords = {
        "visual", "camera", "effect", "particle", "map",
        "shop", "vendor", "trainer", "civilian", "server",
        "default_client", "baseplate", "spawn"
    }
    for _, kw in ipairs(badKeywords) do
        if nameLower:find(kw) then return false end
    end

    -- Must have Humanoid + HRP with health > 0
    local hum = model:FindFirstChildWhichIsA("Humanoid")
    local hrp = model:FindFirstChild("HumanoidRootPart")
    if not (hum and hrp and hum.Health > 0) then return false end

    -- Skip actual players
    if game.Players:GetPlayerFromCharacter(model) then return false end

    -- Skip local player's own character
    if model == game.Players.LocalPlayer.Character then return false end

    return true
end

local function RefreshEnemies()
    EnemyList = {}
    local names = {}
    local LocalCharacter = game.Players.LocalPlayer.Character
    local LocalHRP = LocalCharacter and LocalCharacter:FindFirstChild("HumanoidRootPart")

    print("[JJZ] Scanning by Humanoid...")

    for _, hum in ipairs(workspace:GetDescendants()) do
        if hum:IsA("Humanoid") and hum.Health > 0 then
            local model = hum.Parent
            if not model then continue end

            -- Skip players
            if game.Players:GetPlayerFromCharacter(model) then continue end
            if model == LocalCharacter then continue end

            local hrp = model:FindFirstChild("HumanoidRootPart")
            if not hrp then continue end

            -- Skip junk
            local nameLower = model.Name:lower()
            local badKeywords = {"visual", "camera", "effect", "particle", "baseplate", "spawn", "vendor", "shop"}
            local skip = false
            for _, kw in ipairs(badKeywords) do
                if nameLower:find(kw) then skip = true break end
            end
            if skip then continue end

            local dist = LocalHRP and math.floor((LocalHRP.Position - hrp.Position).Magnitude) or 0
            local display = model.Name .. " (" .. dist .. "m)"

            -- Avoid duplicates
            local duplicate = false
            for _, e in ipairs(EnemyList) do
                if e.Model == model then duplicate = true break end
            end
            if duplicate then continue end

            table.insert(EnemyList, {Model = model, Display = display})
            table.insert(names, display)
            print("[JJZ] ✅ Found: " .. model.Name .. " | " .. dist .. "m")
        end
    end

    table.sort(names)
    if EnemyDropdown then
        EnemyDropdown:Refresh(names, true)
    end
    print("[JJZ] Done | Enemies found: " .. #EnemyList)
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
            local sel = selected[1]
            for _, e in ipairs(EnemyList) do
                if e.Display == sel then
                    _G.Settings.SelectedEnemy = e.Model
                    print("[JJZ] ✅ Selected Enemy: " .. sel)
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
for _, k in ipairs({"R","F","C","X","T"}) do
    SkillsTab:CreateToggle({Name = "Auto Skill "..k, Callback = function(v) _G.Settings["AutoSkill"..k] = v end})
end
SkillsTab:CreateSlider({Name = "Skill Delay", Range={5,30}, CurrentValue=9, Suffix="x0.1s", Callback=function(v) _G.Settings.SkillDelay = v*0.1 end})

print("[JJZ] UI Loaded!")

-- Services & character setup
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
    if Settings.SelectedEnemy and Settings.SelectedEnemy.Parent
        and Settings.SelectedEnemy:FindFirstChild("Humanoid")
        and Settings.SelectedEnemy.Humanoid.Health > 0 then
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

-- Auto Farm loop
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

-- Auto Skills loop
task.spawn(function()
    while true do
        task.wait(0.1)
        for _, s in ipairs({
            {k="AutoSkillR", c=Enum.KeyCode.R},
            {k="AutoSkillF", c=Enum.KeyCode.F},
            {k="AutoSkillC", c=Enum.KeyCode.C},
            {k="AutoSkillX", c=Enum.KeyCode.X},
            {k="AutoSkillT", c=Enum.KeyCode.T}
        }) do
            if Settings[s.k] then
                SimulateKey(s.c)
                task.wait(Settings.SkillDelay)
            end
        end
    end
end)

print("[JJZ] Accept quest → Refresh → Select enemy → Enable AutoFarm!")
