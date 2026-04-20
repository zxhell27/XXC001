--//====================================================--
--// WICIDA OPTIMIZED - ANTI-STUCK VERSION
--//====================================================--

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

-- Fungsi pengaman agar script tidak "mogok" (Infinite Yield)
local function GetFolder(name)
    return Workspace:FindFirstChild(name) -- Menggunakan FindFirstChild agar tidak menunggu selamanya
end

--//====================================================--
--// LOAD UI LIBRARY (DENGAN PROTEKSI)
--//====================================================--
local LibraryURL = "https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/Library.lua"
local Library = loadstring(game:HttpGet(LibraryURL))()

local Window = Library:CreateWindow({
    Title = "WiCiDa Pro | Fix Interaction",
    Center = true,
    AutoShow = true
})

-- Variabel kontrol (State)
local Options = {
    AutoFarm = false,
    FarmAll = false,
    SelectedEnemies = {}
}

--//====================================================--
--// TAB SETUP
--//====================================================--
local MainTab = Window:AddTab("Main")
local EnemyBox = MainTab:AddLeftGroupbox("Combat")

-- Fungsi Scan Musuh
local function GetEnemyList()
    local folder = GetFolder("Enemies")
    local list = {}
    if folder then
        for _, v in pairs(folder:GetChildren()) do
            if not table.find(list, v.Name) then table.insert(list, v.Name) end
        end
    end
    return list
end

-- DROPDOWN (Pilih Musuh)
local EnemyDropdown = EnemyBox:AddDropdown("EnemyDropdown", {
    Text = "Pilih Musuh",
    Values = GetEnemyList(),
    Multi = true,
    AllowNull = true
})

EnemyDropdown:OnChanged(function()
    Options.SelectedEnemies = EnemyDropdown.Value
end)

-- TOGGLE AUTO FARM
EnemyBox:AddToggle("AutoFarmToggle", {
    Text = "Aktifkan Auto Farm",
    Default = false,
    Tooltip = "Teleport dan serang musuh otomatis"
}):OnChanged(function()
    Options.AutoFarm = Toggles.AutoFarmToggle.Value
    if Options.AutoFarm then
        Library:Notify("Auto Farm Aktif!")
    end
end)

EnemyBox:AddToggle("FarmAllToggle", {
    Text = "Serang Semua Jenis",
    Default = false
}):OnChanged(function()
    Options.FarmAll = Toggles.FarmAllToggle.Value
end)

-- BUTTON REFRESH (Jika dropdown kosong)
EnemyBox:AddButton({
    Text = "Refresh Daftar Musuh",
    Func = function()
        EnemyDropdown:SetValues(GetEnemyList())
        Library:Notify("Daftar musuh diperbarui!")
    end
})

--//====================================================--
--// LOGIKA FARM (BERJALAN DI BACKGROUND)
--//====================================================--
task.spawn(function()
    while true do
        task.wait(0.1)
        
        if Options.AutoFarm then
            local folder = GetFolder("Enemies")
            if not folder then continue end

            for _, enemy in pairs(folder:GetChildren()) do
                if not Options.AutoFarm then break end
                
                local hum = enemy:FindFirstChildOfClass("Humanoid")
                local hrp = enemy:FindFirstChild("HumanoidRootPart")

                if hum and hum.Health > 0 and hrp then
                    -- Filter Musuh
                    if Options.FarmAll or Options.SelectedEnemies[enemy.Name] then
                        
                        -- Loop Serang satu musuh sampai mati
                        while Options.AutoFarm and hum.Health > 0 and enemy.Parent do
                            pcall(function()
                                -- Teleport ke musuh
                                if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                                    LocalPlayer.Character.HumanoidRootPart.CFrame = hrp.CFrame * CFrame.new(0, 0, 3)
                                end
                                
                                -- Panggil Remote Attack (Sesuaikan dengan game)
                                local Knit = ReplicatedStorage:FindFirstChild("Packages") and ReplicatedStorage.Packages:FindFirstChild("Knit")
                                if Knit then
                                    local Combat = Knit.Services.CombatService.RF.RegisterAttack
                                    Combat:InvokeServer({
                                        AttackStart = tick(),
                                        Combo = 1
                                    })
                                end
                            end)
                            task.wait(0.05) -- Kecepatan pukul
                        end
                    end
                end
            end
        end
    end
end)

Library:Notify("Script Berhasil Dimuat! Silakan tekan tombol.")
