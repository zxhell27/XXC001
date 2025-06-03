--]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui") -- Untuk contoh manipulasi UI

local localPlayer = Players.LocalPlayer
local character = localPlayer.Character or localPlayer.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

local VulnerabilityTester = {}

-- =============================================
-- I. ALAT REMOTE EVENT / FUNCTION
-- =============================================
-- Tujuan: Menguji apakah server memvalidasi input dari RemoteEvents/RemoteFunctions dengan benar.
-- Potensi Kerentanan: Kurangnya validasi sisi server dapat memungkinkan eksploitasi seperti
-- pemberian item secara ilegal, perubahan statistik pemain, atau eksekusi tindakan tidak sah lainnya.

VulnerabilityTester.RemoteTools = {}

--- Mendaftar semua RemoteEvent dan RemoteFunction yang ditemukan dalam sebuah kontainer (misalnya, ReplicatedStorage).
-- @param container Instance: Kontainer tempat mencari (contoh: game.ReplicatedStorage).
function VulnerabilityTester.RemoteTools.ListRemotes(container)
    if not container then
        warn("ListRemotes: Kontainer tidak valid.")
        return
    end
    print("--- Mendaftar RemoteEvents & RemoteFunctions di: ".. container:GetFullName().. " ---")
    local remotesFound = 0
    for _, child in ipairs(container:GetDescendants()) do
        if child:IsA("RemoteEvent") then
            print(string.format(": %s", child:GetFullName()))
            remotesFound = remotesFound + 1
        elseif child:IsA("RemoteFunction") then
            print(string.format(": %s", child:GetFullName()))
            remotesFound = remotesFound + 1
        end
    end
    if remotesFound == 0 then
        print("Tidak ada RemoteEvents atau RemoteFunctions yang ditemukan di ".. container:GetFullName())
    end
    print("----------------------------------------------------")
end

--- Mencoba memanggil (fire) RemoteEvent dengan argumen yang diberikan.
-- PERINGATAN: Memanggil remote secara sembarangan dapat merusak state game atau memicu anti-cheat. Gunakan dengan hati-hati.
-- @param remotePath string: Path lengkap ke RemoteEvent (contoh: "game.ReplicatedStorage.NamaEventSaya").
-- @param... variadic: Argumen yang akan dikirim ke server.
function VulnerabilityTester.RemoteTools.FireRemoteEvent(remotePath,...)
    local remote = VulnerabilityTester.Utils.FindInstanceByPath(remotePath)
    if remote and remote:IsA("RemoteEvent") then
        print(string.format("Mencoba memanggil RemoteEvent: %s dengan argumen:", remote:GetFullName()),...)
        local success, err = pcall(function()
            remote:FireServer(...)
        end)
        if success then
            print("Panggilan ke RemoteEvent selesai.")
        else
            warn(string.format("Gagal memanggil RemoteEvent %s: %s", remotePath, tostring(err)))
        end
    else
        warn("RemoteEvent tidak ditemukan atau path salah: ".. remotePath)
    end
end

--- Mencoba memanggil (invoke) RemoteFunction dengan argumen yang diberikan.
-- PERINGATAN: Sama seperti RemoteEvent. Gunakan dengan hati-hati.
-- @param remotePath string: Path lengkap ke RemoteFunction.
-- @param... variadic: Argumen yang akan dikirim ke server.
function VulnerabilityTester.RemoteTools.InvokeRemoteFunction(remotePath,...)
    local remoteFunc = VulnerabilityTester.Utils.FindInstanceByPath(remotePath)
    if remoteFunc and remoteFunc:IsA("RemoteFunction") then
        print(string.format("Mencoba memanggil RemoteFunction: %s dengan argumen:", remoteFunc:GetFullName()),...)
        local success, result = pcall(function()
            return remoteFunc:InvokeServer(...)
        end)
        if success then
            print("RemoteFunction mengembalikan:", result)
        else
            warn(string.format("Error saat memanggil RemoteFunction %s: %s", remotePath, tostring(result)))
        end
    else
        warn("RemoteFunction tidak ditemukan atau path salah: ".. remotePath)
    end
end

-- =============================================
-- II. MODIFIKASI PROPERTI PEMAIN LOKAL
-- =============================================
-- Tujuan: Menguji apakah game bergantung pada properti sisi klien untuk logika penting.
-- Potensi Kerentanan: Jika server tidak memiliki otoritas atas statistik pemain (misalnya, kecepatan berjalan,
-- kekuatan lompat, kesehatan), pemain dapat memodifikasinya di klien untuk mendapatkan keuntungan yang tidak adil.

VulnerabilityTester.PlayerModifiers = {}

--- Mengatur properti tertentu pada Humanoid pemain lokal.
-- @param propertyName string: Nama properti Humanoid yang akan diubah (contoh: "WalkSpeed", "JumpHeight").
-- @param value any: Nilai baru untuk properti tersebut.
function VulnerabilityTester.PlayerModifiers.SetHumanoidProperty(propertyName, value)
    if not humanoid then
        warn("SetHumanoidProperty: Humanoid tidak ditemukan.")
        return
    end

    print(string.format("Mencoba mengubah Humanoid.%s menjadi: %s", propertyName, tostring(value)))
    local success, err = pcall(function()
        humanoid[propertyName] = value
    end)

    if success then
        print(string.format("Humanoid.%s sekarang: %s", propertyName, tostring(humanoid[propertyName])))
    else
        warn(string.format("Gagal mengatur Humanoid.%s: %s", propertyName, tostring(err)))
    end
end

-- =============================================
-- III. ALAT NOCLIP DASAR
-- =============================================
-- Tujuan: Menguji apakah server secara otoritatif mengontrol posisi pemain dan deteksi tabrakan.
-- Potensi Kerentanan: Jika tabrakan hanya ditangani di klien (CanCollide), pemain dapat menonaktifkannya
-- untuk berjalan menembus dinding atau objek lain.

VulnerabilityTester.MovementHacks = {}
VulnerabilityTester.MovementHacks.NoclipEnabled = false
VulnerabilityTester.MovementHacks.OriginalCollisions = {} -- Untuk menyimpan status tabrakan asli

--- Mengaktifkan atau menonaktifkan Noclip dasar untuk karakter pemain lokal.
function VulnerabilityTester.MovementHacks.ToggleNoclip()
    if not character then
        warn("ToggleNoclip: Karakter tidak ditemukan.")
        return
    end

    VulnerabilityTester.MovementHacks.NoclipEnabled = not VulnerabilityTester.MovementHacks.NoclipEnabled
    print("Noclip ".. (VulnerabilityTester.MovementHacks.NoclipEnabled and "diaktifkan" or "dinonaktifkan"))

    if VulnerabilityTester.MovementHacks.NoclipEnabled then
        VulnerabilityTester.MovementHacks.OriginalCollisions = {} -- Reset
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                VulnerabilityTester.MovementHacks.OriginalCollisions[part] = part.CanCollide
                pcall(function() part.CanCollide = false end)
            end
        end
    else -- Mengembalikan tabrakan ke status asli
        for part, canCollideStatus in pairs(VulnerabilityTester.MovementHacks.OriginalCollisions) do
            if part and part.Parent then -- Pastikan part masih ada
                pcall(function() part.CanCollide = canCollideStatus end)
            end
        end
        VulnerabilityTester.MovementHacks.OriginalCollisions = {} -- Kosongkan setelah selesai
    end
end

-- =============================================
-- IV. INSPEKTOR LINGKUNGAN SISI KLIEN
-- =============================================
-- Tujuan: Mengidentifikasi informasi atau modul sensitif yang mungkin terekspos di klien.
-- Potensi Kerentanan: Skrip dapat secara tidak sengaja mengekspos data konfigurasi,
-- atau logika game internal yang dapat dimanfaatkan jika diketahui.

VulnerabilityTester.EnvironmentInspector = {}

--- Mendaftar properti dan metode yang dapat diakses dari sebuah service.
-- (Catatan: Ini hanya akan menampilkan apa yang bisa diakses dari Lua, bukan semua detail internal service).
-- @param serviceName string: Nama service (contoh: "ReplicatedStorage", "UserInputService").
function VulnerabilityTester.EnvironmentInspector.ListServiceDetails(serviceName)
    local success, service = pcall(function() return game:GetService(serviceName) end)
    if success and service then
        print(string.format("--- Detail untuk Service: %s ---", serviceName))
        for property, value in pairs(service) do
            print(string.format("  %s: %s", tostring(property), type(value)))
        end
        print("----------------------------------------------------")
    else
        warn("Service tidak ditemukan: ".. serviceName)
    end
end

--- Mendaftar semua child langsung dari sebuah instance.
-- @param instancePath string: Path lengkap ke instance (contoh: "game.Workspace", "game.Players.LocalPlayer.PlayerGui").
function VulnerabilityTester.EnvironmentInspector.InspectInstanceChildren(instancePath)
    local instance = VulnerabilityTester.Utils.FindInstanceByPath(instancePath)
    if instance then
        print(string.format("--- Children dari: %s ---", instance:GetFullName()))
        for _, child in ipairs(instance:GetChildren()) do
            print(string.format("  %s (%s)", child.Name, child.ClassName))
        end
        print("----------------------------------------------------")
    else
        warn("Instance tidak ditemukan: ".. instancePath)
    end
end

-- =============================================
-- V. ALAT MODULESCRIPT
-- =============================================
-- Tujuan: Menguji apakah ModuleScripts yang dapat diakses klien mengembalikan fungsi atau data sensitif.
-- Potensi Kerentanan: ModuleScripts di ReplicatedStorage atau lokasi lain yang dapat diakses klien dapat
-- secara tidak sengaja mengekspos fungsi administratif, data game internal, atau logika yang
-- dapat disalahgunakan jika dipanggil dengan argumen yang tidak terduga atau jika isinya dapat dimodifikasi.

VulnerabilityTester.ModuleInspector = {}

--- Mencoba me-require sebuah ModuleScript dan menampilkan tipe data yang dikembalikan.
-- @param modulePath string: Path lengkap ke ModuleScript.
function VulnerabilityTester.ModuleInspector.AttemptRequireModule(modulePath)
    local moduleScript = VulnerabilityTester.Utils.FindInstanceByPath(modulePath)
    if moduleScript and moduleScript:IsA("ModuleScript") then
        print(string.format("Mencoba me-require ModuleScript: %s", moduleScript:GetFullName()))
        local success, result = pcall(require, moduleScript)
        if success then
            print(string.format("ModuleScript berhasil di-require. Hasilnya adalah tipe: %s", type(result)))
            if type(result) == "table" then
                print("Isi tabel yang dikembalikan (tingkat pertama):")
                for k, v in pairs(result) do
                    print(string.format("  %s: %s", tostring(k), type(v)))
                end
            elseif type(result) == "function" then
                print("ModuleScript mengembalikan sebuah fungsi.")
            else
                print("ModuleScript mengembalikan:", result)
            end
        else
            warn(string.format("Gagal me-require ModuleScript %s: %s", modulePath, tostring(result)))
        end
    else
        warn("ModuleScript tidak ditemukan atau path salah: ".. modulePath)
    end
end

-- =============================================
-- VI. MANIPULASI UI SISI KLIEN
-- =============================================
-- Tujuan: Menguji bagaimana game menangani modifikasi UI dari sisi klien.
-- Potensi Kerentanan: Jika logika game penting (misalnya, menampilkan tombol pembelian, jumlah mata uang)
-- hanya dikontrol oleh properti UI di klien tanpa pemeriksaan server, pemain dapat memanipulasinya
-- untuk keuntungan atau untuk mengganggu permainan.

VulnerabilityTester.UiManipulator = {}

--- Mengatur properti tertentu dari sebuah elemen UI.
-- @param uiElementPath string: Path lengkap ke elemen UI.
-- @param propertyName string: Nama properti yang akan diubah (contoh: "Visible", "Text", "BackgroundColor3").
-- @param value any: Nilai baru untuk properti tersebut.
function VulnerabilityTester.UiManipulator.SetUiProperty(uiElementPath, propertyName, value)
    local uiElement = VulnerabilityTester.Utils.FindInstanceByPath(uiElementPath)
    if uiElement and (uiElement:IsA("GuiObject") or uiElement:IsA("GuiBase2d")) then
        print(string.format("Mengubah %s dari %s menjadi:", propertyName, uiElement:GetFullName()), value)
        local success, err = pcall(function()
            uiElement[propertyName] = value
        end)
        if success then
            print(string.format("%s sekarang:", propertyName), uiElement[propertyName])
        else
            warn(string.format("Gagal mengatur properti UI %s: %s", propertyName, tostring(err)))
        end
    else
        warn("Elemen UI tidak ditemukan atau path salah: ".. uiElementPath)
    end
end

-- =============================================
-- UTILITAS
-- =============================================
VulnerabilityTester.Utils = {}

--- Mencari sebuah instance berdasarkan path string (contoh: "game.Workspace.BagianSaya").
-- @param pathString string: Path ke instance.
-- @return Instance? : Instance yang ditemukan, atau nil jika tidak ditemukan.
function VulnerabilityTester.Utils.FindInstanceByPath(pathString)
    local segments = {}
    for segment in string.gmatch(pathString, "[^%.]+") do
        table.insert(segments, segment)
    end

    local currentInstance = game
    if segments[1] ~= "game" then -- Jika path tidak dimulai dengan "game", coba dari nil
        -- Ini memungkinkan path relatif seperti "Workspace.MyPart" jika _G menunjuk ke game
        -- Namun, untuk kejelasan, lebih baik gunakan path absolut dari 'game'
        -- Untuk skrip ini, kita asumsikan path dimulai dari 'game' atau merupakan child langsung dari 'game'
        -- Jika tidak, pengguna harus menyesuaikan.
        -- Untuk kesederhanaan, kita akan selalu mulai dari 'game' dan menghapus 'game' jika ada di awal path.
        if segments[1] == "game" then
            table.remove(segments, 1)
        end
    else
         table.remove(segments, 1) -- Hapus "game" dari path
    end


    for _, segmentName in ipairs(segments) do
        if currentInstance then
            currentInstance = currentInstance:FindFirstChild(segmentName)
            if not currentInstance then
                -- warn("FindInstanceByPath: Segmen tidak ditemukan: ".. segmentName.. " dalam path ".. pathString)
                return nil
            end
        else
            return nil -- Path tidak valid di segmen sebelumnya
        end
    end
    return currentInstance
end


-- =============================================
-- CONTOH PENGGUNAAN ALAT (AKTIFKAN DAN MODIFIKASI SESUAI KEBUTUHAN)
-- =============================================

-- Untuk menjalankan tes, Anda bisa memanggil fungsi-fungsi ini dari sini,
-- atau mengikatnya ke input pengguna atau tombol UI jika Anda membangun UI untuk alat ini.

-- Contoh: Mendaftar semua remote di ReplicatedStorage saat skrip dimulai
-- print("Memulai daftar remote otomatis...")
-- VulnerabilityTester.RemoteTools.ListRemotes(ReplicatedStorage)
-- VulnerabilityTester.RemoteTools.ListRemotes(workspace) -- Bisa juga mencari di workspace

-- Contoh: Mengubah WalkSpeed saat tombol 'P' ditekan
-- UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
--     if input.KeyCode == Enum.KeyCode.P and not gameProcessedEvent then
--         VulnerabilityTester.PlayerModifiers.SetHumanoidProperty("WalkSpeed", 100)
--     end
-- end)

-- Contoh: Toggle Noclip saat tombol 'L' ditekan
-- UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
--     if input.KeyCode == Enum.KeyCode.L and not gameProcessedEvent then
--         VulnerabilityTester.MovementHacks.ToggleNoclip()
--     end
-- end)

-- Contoh: Mencoba memanggil RemoteEvent (gunakan dengan SANGAT hati-hati!)
-- Ganti "game.ReplicatedStorage.NamaRemoteEventAnda" dengan path yang benar.
-- Ganti "arg1", 123 dengan argumen yang ingin Anda uji.
-- VulnerabilityTester.RemoteTools.FireRemoteEvent("game.ReplicatedStorage.NamaRemoteEventAnda", "arg1", 123)

-- Contoh: Mencoba me-require ModuleScript
-- VulnerabilityTester.ModuleInspector.AttemptRequireModule("game.ReplicatedStorage.NamaModuleAnda")

-- Contoh: Mengubah teks label UI
-- VulnerabilityTester.UiManipulator.SetUiProperty("game.Players.LocalPlayer.PlayerGui.NamaScreenGuiAnda.NamaFrame.NamaTextLabel", "Text", "Teks Diubah!")


print("Client-Side Vulnerability Assessment Toolkit telah dimuat.")
print("Anda dapat mengakses alat ini melalui variabel 'VulnerabilityTester' dalam skrip ini.")

-- Untuk kemudahan pengujian dari Command Bar di Studio, Anda dapat mengeksposnya ke _G:
_G.VT = VulnerabilityTester
print("Ketik '_G.VT' di Command Bar Studio untuk mengakses fungsi-fungsi toolkit ini.")
print("Contoh: _G.VT.RemoteTools.ListRemotes(game.ReplicatedStorage)")
print("Contoh: _G.VT.PlayerModifiers.SetHumanoidProperty('WalkSpeed', 200)")

-- Akhir dari skrip
