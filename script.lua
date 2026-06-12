local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
_G.Rayfield = Rayfield

_G.Settings = {
    AutoFarm = false, AutoRaid = false,
    AutoSkillR = false, AutoSkillF = false, AutoSkillC = false,
    AutoSkillX = false, AutoSkillT = false,
    FarmRadius = 300, HoverHeight = 12, SkillDelay = 0.9, WalkSpeed = 55,
    SelectedEnemy = nil
}

local Window = Rayfield:CreateWindow({Name = "JJZ AutoFarm", LoadingTitle = "Loading...", Theme = "Default"})

local CombatTab = Window:CreateTab("Combat")
local SkillsTab = Window:CreateTab("Skills")

local EnemyList = {}
local EnemyDropdown

local function RefreshEnemies()
    EnemyList = {}
    local names = {}

    local LocalPlayer = game.Players.LocalPlayer
    local LocalCharacter = workspace:FindFirstChild("Characters")
        and workspace.Characters:FindFirstChild("Client")
        and workspace.Characters.Client:FindFirstChild(LocalPlayer.Name .. "_Client")
    local LocalHRP = LocalCharacter and LocalCharacter:FindFirstChild("HumanoidRootPart")

    local npcsFolder = workspace:FindFirstChild("Characters")
        and workspace.Characters:FindFirstChild("Server")
        and workspace.Characters.Server:FindFirstChild("NPCs")

    if not npcsFolder then
        print("[JJZ] ❌ NPCs folder not found!")
        return
    end

    print("[JJZ] Scanning workspace.Characters.Server.NPCs...")

    for _, model in ipairs(npcsFolder:GetChildren()) do
        if not model:IsA("Model") then continue end
        local hum = model:FindFirstChildWhichIsA("Humanoid")
        local hrp = model:FindFirstChild("HumanoidRootPart")
        if not (hum and hrp and hum.Health > 0) then continue end

        local dist = (LocalHRP and hrp) and math.floor((LocalHRP.Position - hrp.Position).Magnitude) or 0

        local displayName = model.Name
        local billboard = model:FindFirstChildWhichIsA("BillboardGui", true)
        if billboard then
            local label = billboard:FindFirstChildWhichIsA("TextLabel", true)
            if label and label.Text ~= "" then
                displayName = label.Text
            end
        end

        local display = displayName .. " (" .. dist .. "m)"
        table.insert(EnemyList, {Model = model, Display = display})
        table.insert(names, display)
        print("[JJZ] ✅ Found: " .. displayName .. " | " .. dist .. "m")
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

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Settings = _G.Settings

local Character, HRP, Humanoid
local function UpdateChar()
    task.wait(1)
    local clientFolder = workspace:FindFirstChild("Characters")
        and workspace.Characters:FindFirstChild("Client")
    if clientFolder then
        Character = clientFolder:FindFirstChild(LocalPlayer.Name .. "_Client")
    end
    if not Character then
        Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    end
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
