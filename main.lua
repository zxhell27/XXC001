--[[
    Optimized Script: Auto-Scan & Enhanced Farm
    Note: Pastikan remote path (Knit) sesuai dengan game target.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local Character, HRP, Humanoid

--//====================================================--
--// CORE SETUP
--//====================================================--

local function SetupCharacter(char)
    Character = char
    HRP = char:WaitForChild("HumanoidRootPart")
    Humanoid = char:WaitForChild("Humanoid")
end

if LocalPlayer.Character then SetupCharacter(LocalPlayer.Character) end
LocalPlayer.CharacterAdded:Connect(SetupCharacter)

--// REMOTES (DIBUNGKUS PCALL AGAR TIDAK ERROR JIKA GAME UPDATE)
local KnitServices, CombatService, EquipmentRF
pcall(function()
    KnitServices = ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Knit"):WaitForChild("Services")
    CombatService = KnitServices:WaitForChild("CombatService"):WaitForChild("RF")
    EquipmentRF = KnitServices:WaitForChild("EquipmentService"):WaitForChild("RF"):WaitForChild("UseConsumable")
end)

--//====================================================--
--// UI LIBRARY (LINORIA)
--//====================================================--

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/Library.lua"))()
local ThemeManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/addons/ThemeManager.lua"))()

local Window = Library:CreateWindow({ Title = "WiCiDa | Multi-Farm Pro", Center = true, AutoShow = true })

local FarmTab = Window:AddTab("Main Farm")
local ResourceTab = Window:AddTab("Resources")
local MiscTab = Window:AddTab("Misc & Settings")

local EnemyBox = FarmTab:AddLeftGroupbox("Enemy Farm")
local ResourceBox = ResourceTab:AddLeftGroupbox("Resource Farm")

--//====================================================--
--// VARIABLES & STATES
--//====================================================--

local Toggles = {
    AutoFarm = false,
    FarmAllEnemies = false,
    FarmResources = false,
    InstantFarm = false,
    Noclip = false,
    AutoSkills = false
}

local selectedEnemies = {}
local selectedResources = {}
local combo = 1

--//====================================================--
--// UTILITY FUNCTIONS
--//====================================================--

-- Fitur Noclip agar TP lancar
RunService.Stepped:Connect(function()
    if Toggles.Noclip and Character then
        for _, part in pairs(Character:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
    end
end)

local function SafeTeleport(cf)
    if HRP then HRP.CFrame = cf end
end

local function GetNames(folderName)
    local folder = Workspace:FindFirstChild(folderName)
    if not folder then return {} end
    local names, seen = {}, {}
    for _, obj in pairs(folder:GetChildren()) do
        if not seen[obj.Name] then
            seen[obj.Name] = true
            table.insert(names, obj.Name)
        end
    end
    return names
end

--//====================================================--
--// COMBAT LOGIC
--//====================================================--

local function DoAttack(enemy)
    local enemyHum = enemy:FindFirstChildOfClass("Humanoid")
    local enemyRoot = enemy:FindFirstChild("HumanoidRootPart")

    if enemyHum and enemyHum.Health > 0 and enemyRoot then
        pcall(function()
            CombatService.RegisterAttack:InvokeServer({
                AttackStart = tick(),
                AttackLength = 0.6,
                Combo = combo
            })
            CombatService.WeaponDamage:InvokeServer(enemyHum)
        end)
        
        combo = (combo % 4) + 1
    end
end

--//====================================================--
--// UI CONTROLS
--//====================================================--

local EnemyDropdown = EnemyBox:AddDropdown("EnemyDropdown", { Text = "Select Enemies", Values = GetNames("Enemies"), Multi = true })
EnemyDropdown:OnChanged(function(v) selectedEnemies = v end)

EnemyBox:AddToggle("TglAutoFarm", { Text = "Auto Farm (TP)" }):OnChanged(function(v) Toggles.AutoFarm = v Toggles.Noclip = v end)
EnemyBox:AddToggle("TglAllEnemies", { Text = "Farm All Types" }):OnChanged(function(v) Toggles.FarmAllEnemies = v end)

local ResDropdown = ResourceBox:AddDropdown("ResDropdown", { Text = "Select Resources", Values = GetNames("MapStuff"), Multi = true })
ResDropdown:OnChanged(function(v) selectedResources = v end)

ResourceBox:AddToggle("TglRes", { Text = "Auto Farm Resources" }):OnChanged(function(v) Toggles.FarmResources = v end)
ResourceBox:AddToggle("TglInstant", { Text = "Instant Mode (No TP)" }):OnChanged(function(v) Toggles.InstantFarm = v end)

--//====================================================--
--// LOOPS (SISTEM SCAN OTOMATIS)
--//====================================================--

-- Loop Utama Enemy
task.spawn(function()
    while task.wait(0.1) do
        if not Toggles.AutoFarm then continue end
        
        local enemies = Workspace:FindFirstChild("Enemies")
        if not enemies then continue end

        for _, enemy in ipairs(enemies:GetChildren()) do
            if not Toggles.AutoFarm then break end
            
            local hum = enemy:FindFirstChildOfClass("Humanoid")
            local root = enemy:FindFirstChild("HumanoidRootPart")

            if hum and hum.Health > 0 and root then
                -- Cek apakah musuh ini dipilih atau mode "Farm All" aktif
                if Toggles.FarmAllEnemies or selectedEnemies[enemy.Name] then
                    while Toggles.AutoFarm and hum.Health > 0 and enemy.Parent do
                        SafeTeleport(root.CFrame * CFrame.new(0, 0, 3)) -- TP di depan musuh
                        DoAttack(enemy)
                        task.wait(0.05)
                    end
                end
            end
        end
    end
end)

-- Loop Resource
task.spawn(function()
    while task.wait(0.5) do
        if not Toggles.FarmResources then continue end
        
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("ProximityPrompt") and obj.Parent then
                local name = obj.Parent.Name
                if selectedResources[name] or Toggles.FarmResources then
                    if Toggles.InstantFarm then
                        obj.HoldDuration = 0
                        fireproximityprompt(obj)
                    else
                        SafeTeleport(obj.Parent.CFrame)
                        task.wait(0.2)
                        fireproximityprompt(obj)
                    end
                end
            end
        end
    end
end)

-- Auto Refresh List (Scanning Otomatis setiap 10 detik)
task.spawn(function()
    while task.wait(10) do
        EnemyDropdown:SetValues(GetNames("Enemies"))
        ResDropdown:SetValues(GetNames("MapStuff"))
    end
end)

Library:Notify("WiCiDa Optimizer Loaded Successfully!")
