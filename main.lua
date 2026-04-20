--[[
	WARNING: Heads up! This script has not been verified by ScriptBlox. Use at your own risk!
]]
--//====================================================--
--// SERVICES
--//====================================================--

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

--//====================================================--
--// CHARACTER
--//====================================================--

local Character, HRP

local function SetupCharacter(char)
    Character = char
    HRP = char:WaitForChild("HumanoidRootPart")
end

SetupCharacter(LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait())

LocalPlayer.CharacterAdded:Connect(SetupCharacter)

--//====================================================--
--// REMOTES
--//====================================================--

local KnitServices = ReplicatedStorage:WaitForChild("Packages")
    :WaitForChild("Knit")
    :WaitForChild("Services")

local CombatService = KnitServices:WaitForChild("CombatService"):WaitForChild("RF")

local RegisterAttack = CombatService:WaitForChild("RegisterAttack")
local ReplicateEffect = CombatService:WaitForChild("ReplicateEffect")
local WeaponDamage = CombatService:WaitForChild("WeaponDamage")

local EquipmentRF = KnitServices
    :WaitForChild("EquipmentService")
    :WaitForChild("RF")
    :WaitForChild("UseConsumable")

--//====================================================--
--// UI LIBRARY
--//====================================================--

local Library = loadstring(game:HttpGet(
"https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/Library.lua"))()

local ThemeManager = loadstring(game:HttpGet(
"https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/addons/ThemeManager.lua"))()

local SaveManager = loadstring(game:HttpGet(
"https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/addons/SaveManager.lua"))()

--//====================================================--
--// UI SETUP
--//====================================================--

local Window = Library:CreateWindow({
    Title = "Enemy & Resource Autofarm",
    Center = true,
    AutoShow = true
})

local FarmTab = Window:AddTab("Farm")
local ResourceTab = Window:AddTab("Resources")
local UITab = Window:AddTab("UI Settings")

local EnemyBox = FarmTab:AddLeftGroupbox("Enemy Farm")
local ChestBox = FarmTab:AddRightGroupbox("Chest Farm")
local ResourceBox = ResourceTab:AddLeftGroupbox("Resource Farm")


--//====================================================--
--// SETTINGS
--//====================================================--

-- Enemy
local selectedEnemies = {}
local farmAllEnemies = false
local autoFarm = false

-- Chests
local selectedChests = {}
local autoOpenChests = false
local openAllChests = false

-- Resources
local selectedResources = {}
local farmSelectedResource = false
local farmAllResources = false
local instantFarm = false

-- Combat
local combo = 1
local maxCombo = 4

-- Boss TP
local bossTPEnabled = {
    ["Lv 20"] = false,
    ["Lv 35"] = false,
    ["Lv 60"] = false,
    ["Lv 85"] = false
}

local bossLocations = {
    ["Lv 20"] = CFrame.new(2818.88647, 19.2597618, 2742.96411),
    ["Lv 35"] = CFrame.new(5402.73047, -25.7606373, 3036.83862),
	["Lv 60"] = CFrame.new(4557.32324, 255.051208, 6683.14502),
	["Lv 85"] = CFrame.new(7783.93652, 263.303284, 9249.94824)
}

-- Resource
local mapStuff = Workspace:WaitForChild("MapStuff")
local extraMapStuff = Workspace:FindFirstChild("some w4 consumables that were misplaced")
local resourceOffset = Vector3.new(0,2.5,0)

-- Misc
local autoSkills = false
local autoParty = false
local pullMobs = false

local pullDistance = 75
local pullOffset = Vector3.new(0,0,7)



--//====================================================--
--// HELPER FUNCTIONS
--//====================================================--

local function Teleport(cf)
    if HRP then
        HRP.CFrame = cf
    end
end

local function TeleportToEnemy(enemy)
    local root = enemy:FindFirstChild("HumanoidRootPart")
    if root then
        Teleport(root.CFrame * CFrame.new(0,2,2))
    end
end

local function Attack(enemy)

    local humanoid = enemy:FindFirstChildOfClass("Humanoid")
    local root = enemy:FindFirstChild("HumanoidRootPart")

    if not humanoid or humanoid.Health <= 0 or not root then return end

    RegisterAttack:InvokeServer({
        AttackStart = tick(),
        AttackLength = 0.6,
        AttackStartKeyframeTime = 0.3,
        Combo = combo,
        AttackEndKeyframeTime = 0.46
    })

    ReplicateEffect:InvokeServer("GreatswordSlash"..combo, root)
    WeaponDamage:InvokeServer(humanoid)

    combo = combo + 1
    if combo > maxCombo then
        combo = 1
    end
end

--//====================================================--
--// LIST FUNCTIONS
--//====================================================--

local function GetEnemyNames()

    local folder = Workspace:FindFirstChild("Enemies")
    if not folder then return {} end

    local names, seen = {}, {}

    for _,enemy in pairs(folder:GetChildren()) do
        if not seen[enemy.Name] then
            seen[enemy.Name] = true
            table.insert(names, enemy.Name)
        end
    end

    return names
end

local function IterateResourceDescendants(callback)
    for _,obj in ipairs(mapStuff:GetDescendants()) do
        callback(obj)
    end

    if extraMapStuff then
        for _,obj in ipairs(extraMapStuff:GetDescendants()) do
            callback(obj)
        end
    end
end

local function GetResourceNames()

    local names, seen = {}, {}

    IterateResourceDescendants(function(prompt)
        if prompt:IsA("ProximityPrompt") and prompt.Parent then

            local name = prompt.Parent.Name

            if not seen[name] then
                seen[name] = true
                table.insert(names,name)
            end
        end
    end)

    return names
end

local function GetChestNames()

    local chestContainer = LocalPlayer.PlayerGui
        :WaitForChild("MainGui")
        :WaitForChild("Default")
        :WaitForChild("RightSideFrame")
        :WaitForChild("Chests")
        :WaitForChild("Container")
        :WaitForChild("List")

    local names = {}

    for _,frame in pairs(chestContainer:GetChildren()) do
        if frame:IsA("Frame") then
            table.insert(names, frame.Name)
        end
    end

    return names
end

--//====================================================--
--// UI CONTROLS
--//====================================================--

local EnemyDropdown = EnemyBox:AddDropdown("EnemyDropdown",{
    Text = "Enemies",
    Values = GetEnemyNames(),
    Multi = true,
    AllowNull = true
})

EnemyDropdown:OnChanged(function(v)
    selectedEnemies = v
end)

EnemyBox:AddToggle("FarmAllEnemies",{Text="Farm All Enemies"})
:OnChanged(function(v) farmAllEnemies = v end)

EnemyBox:AddToggle("AutoFarm",{Text="Auto Farm"})
:OnChanged(function(v) autoFarm = v end)

EnemyBox:AddButton({
    Text = "Refresh Enemy List",
    Func = function()
        EnemyDropdown:SetValues(GetEnemyNames())
    end
})

-- // BOSS TP
local BossBox = FarmTab:AddLeftGroupbox("Boss TP")

BossBox:AddToggle("TPBoss20", {Text = "Lv 20 Boss"}):OnChanged(function(v)
    bossTPEnabled["Lv 20"] = v
end)

BossBox:AddToggle("TPBoss35", {Text = "Lv 35 Boss"}):OnChanged(function(v)
    bossTPEnabled["Lv 35"] = v
end)

BossBox:AddToggle("TPBoss60", {Text = "Lv 60 Boss"}):OnChanged(function(v)
    bossTPEnabled["Lv 60"] = v
end)

BossBox:AddToggle("TPBoss85", {Text = "Lv 85 Boss"}):OnChanged(function(v)
    bossTPEnabled["Lv 85"] = v
end)

--// CHESTS

local ChestDropdown = ChestBox:AddDropdown("ChestDropdown",{
    Text = "Chests",
    Values = {},
    Multi = true,
    AllowNull = true
})

ChestDropdown:OnChanged(function(v)
    selectedChests = v
end)

ChestBox:AddToggle("AutoOpenChests",{Text="Auto Open Selected Chests"})
:OnChanged(function(v) autoOpenChests = v end)

ChestBox:AddToggle("OpenAllChests",{Text="Open All Chests"})
:OnChanged(function(v)
    openAllChests = v
end)

ChestBox:AddButton({
    Text = "Refresh Chest List",
    Func = function()
        ChestDropdown:SetValues(GetChestNames())
    end
})

ChestBox:AddButton({
    Text = "Dismantle TP",
    Func = function()
        Teleport(CFrame.new(
            3179.21289,-26.7675457,2418.42139,
            -0.98663336,-1.66881922e-08,0.162956014,
            -1.91349621e-08,1,-1.34453515e-08,
            -0.162956014,-1.63837885e-08,-0.98663336
        ))
			game:GetService("ReplicatedStorage"):WaitForChild("Packages"):WaitForChild("Knit"):WaitForChild("Services"):WaitForChild("EquipmentService"):WaitForChild("RF"):WaitForChild("ClaimPendingDismantleRewards"):InvokeServer()

    end
})

--// MISC
--// MISC
local MiscBox = FarmTab:AddRightGroupbox("Misc")

MiscBox:AddToggle("AutoSkills", {Text = "Auto Skills"})
:OnChanged(function(v)
    autoSkills = v
end)

MiscBox:AddToggle("AutoParty", {Text = "Auto Party"})
:OnChanged(function(v)
    autoParty = v
end)

MiscBox:AddToggle("PullMobs", {Text = "Pull Nearby Mobs"})
:OnChanged(function(v)
    pullMobs = v
end)

--// RESOURCES

local ResourceDropdown = ResourceBox:AddDropdown("ResourceDropdown",{
    Text = "Resources",
    Values = GetResourceNames(),
    Multi = true,
    AllowNull = true
})

ResourceDropdown:OnChanged(function(v)
    selectedResources = v
end)

ResourceBox:AddToggle("FarmResource",{Text="Farm Selected"})
:OnChanged(function(v)
    farmSelectedResource = v
end)

ResourceBox:AddToggle("FarmAll",{Text="Farm All"})
:OnChanged(function(v)
    farmAllResources = v
end)

ResourceBox:AddToggle("InstantFarm",{Text="Instant Mode"})
:OnChanged(function(v)
    instantFarm = v
end)

ResourceBox:AddButton({
    Text = "Refresh Resource List",
    Func = function()
        ResourceDropdown:SetValues(GetResourceNames())
    end
})

--//====================================================--
--// FARM LOOPS
--//====================================================--

local EnemiesFolder = Workspace:WaitForChild("Enemies")
local enemyOffset = CFrame.new(0,2,2)

task.spawn(function()

    while task.wait(0.05) do
        if not autoFarm then continue end

        for _, enemy in ipairs(EnemiesFolder:GetChildren()) do
            if not enemy:IsA("Model") then continue end

            local humanoid = enemy:FindFirstChildOfClass("Humanoid")
            local root = enemy:FindFirstChild("HumanoidRootPart")

            if not humanoid or humanoid.Health <= 0 or not root then
                continue
            end

            -- enemy filtering
            if not farmAllEnemies and not selectedEnemies[enemy.Name] then
                continue
            end

            -- attack loop
            while autoFarm and enemy.Parent and humanoid.Health > 0 do

                Teleport(root.CFrame * enemyOffset)

                for i = 1,5 do
                    task.spawn(Attack, enemy)
                end

                task.wait(0.08)

            end
        end
    end

end)

--// CHESTS
task.spawn(function()

    while task.wait(1) do

        if not (autoOpenChests or openAllChests) then
            continue
        end

        local chestsToOpen = {}

        if openAllChests then
            chestsToOpen = GetChestNames()
        else
            for chestName in pairs(selectedChests) do
                table.insert(chestsToOpen, chestName)
            end
        end

        for _,chestName in ipairs(chestsToOpen) do

            pcall(function()
                EquipmentRF:InvokeServer(
                    chestName,
                    nil,
                    {BuyMethod="Gold"}
                )
            end)

            task.wait(0.3)

        end

    end

end)

--// RESOURCES
task.spawn(function()
    local queue = {}
    local lastTime = tick()

    while task.wait(0.1) do
        if not (farmAllResources or farmSelectedResource) then continue end

        -- Gather new prompts into queue
        IterateResourceDescendants(function(prompt)
            if not prompt:IsA("ProximityPrompt") then return end
            local part = prompt.Parent
            if not part or not part:IsA("BasePart") then return end
            if farmSelectedResource and not selectedResources[part.Name] then return end

            if not queue[prompt] then
                queue[prompt] = {
                    prompt = prompt,
                    part = part,
                    initialized = false
                }
            end
        end)

        -- Calculate dynamic batch based on FPS
        local now = tick()
        local delta = math.clamp(now - lastTime, 0.01, 0.2) -- avoid extremes
        local fps = 1 / delta
        local batchCount = math.clamp(math.floor(fps / 20), 1, 10) -- 1-10 prompts per frame
        lastTime = now

        local processed = 0
        for promptObj, data in pairs(queue) do
            if processed >= batchCount then break end

            local prompt, part = data.prompt, data.part

            if instantFarm then
                if not data.initialized then
                    prompt.MaxActivationDistance = math.huge
                    prompt.RequiresLineOfSight = false
                    prompt.HoldDuration = 0
                    data.initialized = true
                end
                fireproximityprompt(prompt)
            else
                if HRP then
                    local targetCFrame = part.CFrame * CFrame.new(resourceOffset)
                    if (HRP.Position - targetCFrame.Position).Magnitude > 0.5 then
                        HRP.CFrame = targetCFrame
                    end
                end
                fireproximityprompt(prompt)
            end

            queue[promptObj] = nil
            processed = processed + 1
            task.wait(0.03) -- tiny delay for smoothness
        end
    end
end)

-- // BOSS TP
task.spawn(function()
    while task.wait(10) do
        if bossTPEnabled["Lv 20"] then
            Teleport(bossLocations["Lv 20"])
        end
        if bossTPEnabled["Lv 35"] then
            Teleport(bossLocations["Lv 35"])
        end
        if bossTPEnabled["Lv 60"] then
            Teleport(bossLocations["Lv 60"])
        end
        if bossTPEnabled["Lv 85"] then
            Teleport(bossLocations["Lv 85"])
        end
    end
end)

-- // Auto Skills
task.spawn(function()

    local vim = game:GetService("VirtualInputManager")

    local function pressKey(key)
        vim:SendKeyEvent(true, key, false, game)
        task.wait(0.05)
        vim:SendKeyEvent(false, key, false, game)
    end

    while task.wait(0.5) do

        if not autoSkills then
            continue
        end

        pressKey(Enum.KeyCode.One)
        pressKey(Enum.KeyCode.Two)
        pressKey(Enum.KeyCode.Three)

    end
end)

--// Auto Party
task.spawn(function()

    local PartyService = ReplicatedStorage
        :WaitForChild("Packages")
        :WaitForChild("Knit")
        :WaitForChild("Services")
        :WaitForChild("PartyService")
        :WaitForChild("RF")
        :WaitForChild("SendInvite")

    while task.wait(5) do

        if not autoParty then
            continue
        end

        for _,player in pairs(Players:GetPlayers()) do

            if player ~= LocalPlayer then
                pcall(function()
                    PartyService:InvokeServer(player.Name)
                end)
            end

        end

    end
end)

--// Pull Mobs
task.spawn(function()

    local RunService = game:GetService("RunService")

    RunService.Heartbeat:Connect(function()

        if not pullMobs then
            return
        end

        local enemiesFolder = Workspace:FindFirstChild("Enemies")
        if not enemiesFolder or not HRP then return end

        for _,enemy in ipairs(enemiesFolder:GetChildren()) do

            if enemy:IsA("Model") and enemy:FindFirstChild("HumanoidRootPart") then

                local enemyHRP = enemy.HumanoidRootPart
                local distance = (enemyHRP.Position - HRP.Position).Magnitude

                if distance <= pullDistance then
                    enemyHRP.CFrame = HRP.CFrame + HRP.CFrame.LookVector * pullOffset.Z
                end

            end
        end

    end)

end)


--//====================================================--
--// AUTO REFRESH
--//====================================================--

task.spawn(function()

    while task.wait(5) do

        EnemyDropdown:SetValues(GetEnemyNames())
        ResourceDropdown:SetValues(GetResourceNames())
        ChestDropdown:SetValues(GetChestNames())

    end

end)

--//====================================================--
--// UI SETTINGS
--//====================================================--

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)

SaveManager:IgnoreThemeSettings()
SaveManager:SetFolder("EnemyResourceAutofarm")

ThemeManager:ApplyToTab(UITab)
SaveManager:BuildConfigSection(UITab)

Library:Notify("Enemy & Resource Autofarm Loaded")
