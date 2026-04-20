--//====================================================--
--// FIX & OPTIMIZED VERSION
--//====================================================--

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

-- Fix: Gunakan pcall untuk memuat library agar tidak crash jika link mati
local function GetLibrary(url)
    local success, result = pcall(function()
        return game:HttpGet(url)
    end)
    if success and not result:find("<!DOCTYPE html>") then
        return loadstring(result)()
    else
        warn("Gagal memuat library dari: " .. url)
        return nil
    end
end

local Library = GetLibrary("https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/Library.lua")
if not Library then return end -- Berhenti jika library gagal dimuat

--//====================================================--
--// DYNAMIC SCANNING (Mencegah Infinite Yield)
--//====================================================--

-- Fix: Jangan pakai WaitForChild tanpa timeout kalau tidak yakin foldernya ada
local MapStuff = Workspace:FindFirstChild("MapStuff") or Workspace:FindFirstChild("Resources") or Workspace

local function GetEnemyNames()
    local folder = Workspace:FindFirstChild("Enemies")
    if not folder then return {} end
    local names = {}
    for _, enemy in pairs(folder:GetChildren()) do
        if not table.find(names, enemy.Name) then
            table.insert(names, enemy.Name)
        end
    end
    return names
end

--//====================================================--
--// UI SETUP
--//====================================================--

local Window = Library:CreateWindow({ Title = "WiCiDa Optimizer | Fix Version", Center = true, AutoShow = true })
local FarmTab = Window:AddTab("Farm")

local EnemyBox = FarmTab:AddLeftGroupbox("Auto Scan & Farm")

-- Fitur Scan Otomatis Musuh
local EnemyDropdown = EnemyBox:AddDropdown("EnemyDropdown", {
    Text = "Select Enemies",
    Values = GetEnemyNames(),
    Multi = true,
})

EnemyBox:AddToggle("AutoFarm", { Text = "Aktifkan Auto Farm" }):OnChanged(function(v)
    _G.AutoFarm = v
end)

--//====================================================--
--// IMPROVED ATTACK LOOP
--////====================================================--

task.spawn(function()
    while task.wait(0.1) do
        if not _G.AutoFarm then continue end
        
        local enemiesFolder = Workspace:FindFirstChild("Enemies")
        if not enemiesFolder then continue end

        for _, enemy in ipairs(enemiesFolder:GetChildren()) do
            if not _G.AutoFarm then break end
            
            local hum = enemy:FindFirstChildOfClass("Humanoid")
            local hrp = enemy:FindFirstChild("HumanoidRootPart")

            if hum and hum.Health > 0 and hrp then
                -- Teleport & Attack (Gunakan pcall pada remote)
                pcall(function()
                    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                        LocalPlayer.Character.HumanoidRootPart.CFrame = hrp.CFrame * CFrame.new(0, 0, 3)
                        
                        -- Panggil remote combat di sini (pastikan path benar)
                        local Knit = ReplicatedStorage:FindFirstChild("Packages") and ReplicatedStorage.Packages:FindFirstChild("Knit")
                        if Knit then
                            local Combat = Knit.Services.CombatService.RF.RegisterAttack
                            Combat:InvokeServer({
                                AttackStart = tick(),
                                Combo = 1
                            })
                        end
                    end
                end)
            end
        end
    end
end)

-- Auto Refresh List tiap 5 detik agar musuh baru muncul di daftar
task.spawn(function()
    while task.wait(5) do
        if EnemyDropdown then
            EnemyDropdown:SetValues(GetEnemyNames())
        end
    end
end)

Library:Notify("Fix Loaded: MapStuff error bypassed.")
