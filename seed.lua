--!strict
--[[
    ZXHELL Security Tools - Enhanced Version for Roblox Script Executor (Lua)

    This script provides a user interface (UI) for detecting and testing RemoteEvents
    and RemoteFunctions within a Roblox game. It aims to simulate various exploit
    methods and log potential vulnerabilities.

    Key Features:
    - Dynamic UI creation using Instance.new()
    - Draggable UI frames
    - Minimize/Maximize functionality for UI frames
    - Real-time logging of processes and potential vulnerabilities
    - Customizable test arguments and delay
    - Multiple hacking methods (Auto Spam, Single Shot, Flood Test, Property Manipulation)
    - Dynamic detection and selection of RemoteEvents/Functions
    - Responsive UI scaling (basic)

    Original issues addressed:
    - Options not appearing / functions not working: Entirely re-implemented UI and logic flow.
    - UI not responding: Ensured non-blocking operations and proper event handling.
    - UI design: Re-imagined with modern aesthetics suitable for Roblox UI.
    - "Stop Test" not working: Fixed the logic to correctly halt the testing loop.

    Disclaimer: This tool is for educational and ethical security testing purposes only.
    Unauthorized use to exploit games without permission is against Roblox Terms of Service.
]]

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService") -- Ditambahkan untuk animasi UI
local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait() -- Memastikan LocalPlayer tersedia

-- Global Variables for Application State
local testingActive: boolean = false -- Mengontrol apakah loop pengujian keamanan berjalan
local exploitLog: { [number]: { timestamp: number, action: string, status: string, details: string, vulnerabilityType: string? } } = {} -- Menyimpan log detail dari upaya eksploitasi, ditambahkan vulnerabilityType
local remoteTimer: { [RemoteEvent | RemoteFunction]: { lastCall: number, cooldown: number } } = {} -- Pelacakan cooldown untuk setiap remote
local remoteList: { [number]: RemoteEvent | RemoteFunction } = {} -- Daftar RemoteEvents/RemoteFunctions yang terdeteksi
local selectedRemote: RemoteEvent | RemoteFunction | nil = nil -- Remote yang saat ini dipilih untuk pengujian spesifik
local customArgs: { any } | nil = nil -- Argumen kustom yang dimasukkan oleh pengguna
local hackMethod: string = "AutoSpam" -- Metode serangan saat ini (misalnya, "AutoSpam", "FloodTest")
local uiStates: { [string]: boolean } = {} -- Menyimpan status minimize/maximize untuk setiap frame UI (true jika diminimize)
local autoScrollLogs: { [string]: boolean } = { ProcessLog = true, StatusLog = true, DetailedLog = true } -- Mengontrol auto-scrolling untuk frame log

-- UI Dragging Variables
local draggingFrame: Frame | nil = nil -- Frame UI yang saat ini sedang di-drag

-- UI Element References (akan diisi selama pembuatan UI)
local uiElements: { [string]: GuiObject } = {} -- Tabel terpusat untuk menyimpan referensi ke elemen UI kunci

-- Constants for UI Styling (nilai RGB untuk Color3.fromRGB)
local FRAME_BACKGROUND_COLOR = Color3.fromRGB(20, 20, 30)
local TITLE_TEXT_COLOR_PRIMARY = Color3.fromRGB(0, 255, 255) -- Cyan
local TITLE_TEXT_COLOR_SECONDARY = Color3.fromRGB(255, 0, 255) -- Magenta
local BUTTON_BACKGROUND_COLOR = Color3.fromRGB(0, 80, 150)
local BUTTON_HOVER_COLOR = Color3.fromRGB(0, 100, 200)
local BUTTON_ACTIVE_COLOR = Color3.fromRGB(150, 0, 0) -- Merah untuk tombol stop
local TEXT_COLOR_LIGHT = Color3.fromRGB(255, 255, 255)
local LOG_TEXT_COLOR = Color3.fromRGB(200, 200, 200)
local INPUT_BACKGROUND_COLOR = Color3.fromRGB(30, 30, 40)
local BORDER_COLOR = Color3.fromRGB(0, 255, 255)
local CORNER_RADIUS = UDim.new(0, 8) -- 8 piksel untuk sudut membulat
local BUTTON_CORNER_RADIUS = UDim.new(0, 4) -- 4 piksel untuk sudut tombol
local SCROLLBAR_THICKNESS = 4 -- Piksel untuk ketebalan scrollbar

-- Test Arguments for Remote Calls (Diperluas sesuai dokumen)
-- Ini adalah argumen generik yang mungkin mengungkapkan kerentanan jika remote tidak divalidasi dengan benar.
local testArgs: { any } = {
    nil, -- Uji dengan argumen kosong
    "instant", -- Argumen string umum
    true, -- Argumen boolean
    -1, -- Angka negatif
    999999, -- Angka besar
    string.rep("x", 1000), -- String panjang (potensi buffer overflow/DoS)
    {}, -- Tabel kosong
    { exploit = "malicious", nested = { depth = 100, circular = {} } }, -- Tabel bersarang (struktur data kompleks), ditambahkan placeholder referensi melingkar
    { math.huge, -math.huge, 0/0 }, -- Angka kasus ekstrem (Infinity, NaN)
    "function() end", -- String yang merepresentasikan fungsi (jika diinterpretasikan sebagai kode)
    LocalPlayer, -- Melewatkan objek LocalPlayer itu sendiri
    workspace, -- Melewatkan sebuah service
    ReplicatedStorage, -- Melewatkan ReplicatedStorage
    Vector3.new(0,0,0), -- Vector3
    CFrame.new(0,0,0), -- CFrame
    Color3.new(1,0,0), -- Color3
    UDim2.new(0.5,0,0.5,0), -- UDim2
    "", -- String kosong
    "\0", -- Null byte dalam string
    "\n", -- Baris baru dalam string
    "local function test() print('hello') end", -- Cuplikan kode Lua sebagai string
    Instance.new("Part"), -- Sebuah instance baru, tanpa parent
    Instance.new("Folder", nil), -- Sebuah instance dengan parent nil
    Enum.KeyCode.A, -- Sebuah item Enum
    12345678901234567, -- Integer yang sangat besar (untuk potensi overflow)
    -12345678901234567, -- Integer yang sangat kecil
}
-- Untuk referensi melingkar:
testArgs[7].circular = testArgs[7] -- Membuatnya melingkar untuk menguji masalah serialisasi

-- Hacking Methods Available
-- Setiap metode memiliki nama, nilai (untuk logika internal), dan deskripsi.
local methods: { { name: string, value: string, desc: string } } = {
    { name = "Auto Spam", value = "AutoSpam", desc = "Spam semua argumen secara otomatis ke remote yang dipilih." },
    { name = "Single Shot", value = "SingleShot", desc = "Uji satu argumen per klik tombol secara manual." },
    { name = "Custom Args", value = "CustomArgs", desc = "Gunakan argumen kustom yang dimasukkan pengguna." },
    { name = "Flood Test", value = "FloodTest", desc = "Spam cepat untuk uji beban dan deteksi batasan rate-limit." },
    { name = "Property Manip", value = "PropertyManip", desc = "Coba ubah properti pemain (misalnya, leaderstats) jika remote mengizinkan." },
    -- Fitur Masa Depan (tidak diimplementasikan dalam versi ini):
    -- { name = "Mutation Fuzz", value = "MutationFuzz", desc = "Secara otomatis memutasi argumen untuk menemukan kasus ekstrem." },
    -- { name = "Sequence Test", value = "SequenceTest", desc = "Eksekusi urutan panggilan remote yang telah ditentukan." },
    -- { name = "Replay Attack", value = "ReplayAttack", desc = "Rekam dan putar ulang panggilan remote yang sah dengan modifikasi." },
}

-- Logging Functions
-- Fungsi-fungsi ini memperbarui log UI dan log eksploitasi internal.

--- Mencatat upaya eksploitasi dan memperbarui status log eksploitasi.
-- @param action string - Aksi yang dilakukan (misalnya, "Remote Detection", "Test Remote").
-- @param status string - Status aksi (misalnya, "Success", "Failed").
-- @param details string - Informasi detail tentang aksi.
-- @param vulnerabilityType string? - Opsional: Jenis kerentanan spesifik jika teridentifikasi.
-- @return string - Teks log yang diformat.
local function logExploit(action: string, status: string, details: string, vulnerabilityType: string?): string
    local logEntry = {
        timestamp = os.time(), -- Timestamp saat ini dalam detik sejak epoch
        action = action,
        status = status,
        details = details,
        vulnerabilityType = vulnerabilityType
    }
    table.insert(exploitLog, logEntry) -- Tambahkan ke riwayat log internal
    local logText = string.format("[%s] %s: %s (%s)", os.date("%X", logEntry.timestamp), action, status, details)
    print(logText) -- Juga cetak ke output Roblox untuk debugging
    return logText
end

--- Memperbarui TextLabel log UI generik dan ScrollingFrame-nya.
-- @param logBox TextLabel - TextLabel yang akan diperbarui.
-- @param scrollingFrame ScrollingFrame - ScrollingFrame induk.
-- @param text string - Teks yang akan ditambahkan.
-- @param logType string - "ProcessLog", "StatusLog", atau "DetailedLog" untuk kontrol auto-scroll.
local function updateLogUI(logBox: TextLabel, scrollingFrame: ScrollingFrame, text: string, logType: string)
    if logBox and scrollingFrame then
        logBox.Text = logBox.Text .. "\n" .. text -- Tambahkan teks baru
        -- Sesuaikan ukuran TextLabel agar sesuai dengan konten
        logBox.Size = UDim2.new(1, -10, 0, logBox.TextBounds.Y)
        -- Sesuaikan CanvasSize ScrollingFrame agar sesuai dengan tinggi TextLabel
        scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, logBox.TextBounds.Y)

        -- Auto-scroll ke bawah hanya jika auto-scroll diaktifkan untuk jenis log ini
        if autoScrollLogs[logType] then
            scrollingFrame.CanvasPosition = Vector2.new(0, logBox.TextBounds.Y)
        end
    end
end

--- Memperbarui TextLabel log proses UI.
-- @param text string - Teks yang akan ditambahkan ke log proses.
local function updateProcessLog(text: string)
    updateLogUI(uiElements.ProcessLogBox as TextLabel, uiElements.ProcessLogScrollingFrame as ScrollingFrame, text, "ProcessLog")
end

--- Memperbarui TextLabel log status UI, secara khusus mencari kerentanan.
-- @param text string - Teks yang akan ditambahkan ke log status.
-- @param vulnerabilityType string? - Opsional: Jenis kerentanan spesifik.
local function updateStatusLog(text: string, vulnerabilityType: string?)
    local statusLogBox = uiElements.StatusLogBox as TextLabel
    local statusLogScrollingFrame = uiElements.StatusLogScrollingFrame as ScrollingFrame

    if statusLogBox and statusLogScrollingFrame then
        if text:find("Success") then -- Hanya catat upaya eksploitasi yang berhasil sebagai kerentanan
            local remoteName = text:match("Test Remote: Success%((.-) with args:") or "Unknown"
            local arg = text:match("args: (.-), Method:") or "Unknown"
            local vulnText = string.format("Kerentanan: %s rentan terhadap argumen %s", remoteName, arg)
            -- Tambahkan warna berdasarkan jenis kerentanan (konseptual)
            if vulnerabilityType == "Critical: Infinite Value/Resource" or vulnerabilityType == "Critical: Unauthorized Object Removal" then
                vulnText = string.format("<font color=\"rgb(255,0,0)\">%s</font>", vulnText) -- Merah
            elseif vulnerabilityType == "High: Property Manipulation" or vulnerabilityType == "High: Unauthorized Action Granted" or vulnerabilityType == "High: Unauthorized Teleport/Movement" then
                vulnText = string.format("<font color=\"rgb(255,165,0)\">%s</font>", vulnText) -- Oranye
            elseif vulnerabilityType == "Medium: Server Error/Bad Response" or vulnerabilityType == "Medium: Server Yield/Timeout" then
                vulnText = string.format("<font color=\"rgb(255,255,0)\">%s</font>", vulnText) -- Kuning
            else
                vulnText = string.format("<font color=\"rgb(0,255,0)\">%s</font>", vulnText) -- Hijau untuk sukses umum
            end
            statusLogBox.RichText = true -- Aktifkan RichText untuk teks berwarna
            updateLogUI(statusLogBox, statusLogScrollingFrame, vulnText, "StatusLog")
        end
    end
end

-- Core Logic Functions

--- Mendeteksi RemoteEvents dan RemoteFunctions di layanan yang ditentukan.
-- Mengisi variabel global `remoteList`.
-- @param servicesToScan {Instance} - Daftar layanan/kontainer yang akan dipindai.
-- @return boolean - True jika ada remote yang ditemukan, false jika tidak.
local function detectRemotes(servicesToScan: { Instance }): boolean
    local initialCount = #remoteList
    local newRemotesFound = 0

    for _, service in ipairs(servicesToScan) do
        for _, obj in pairs(service:GetDescendants()) do
            if (obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction")) and not table.find(remoteList, obj) then
                table.insert(remoteList, obj)
                remoteTimer[obj] = { lastCall = tick(), cooldown = 0 } -- Inisialisasi cooldown untuk setiap remote
                logExploit("Remote Detection", "Success", "Ditemukan: " .. obj:GetFullName())
                newRemotesFound = newRemotesFound + 1
            end
        end
    end
    return newRemotesFound > 0 or initialCount > 0
end

--- Menyiapkan listener deteksi remote dinamis.
-- Memindai dan mendengarkan remote baru di lokasi umum.
local function setupDynamicRemoteDetection()
    local servicesToMonitor = {
        ReplicatedStorage,
        workspace,
        LocalPlayer.PlayerGui,
        game:GetService("Lighting"), -- Terkadang remote ditempatkan di sini
        game:GetService("StarterGui"), -- Terkadang remote ditempatkan di sini
        -- ServerStorage dan ServerScriptService tidak akan direplikasi ke klien secara normal,
        -- tetapi disertakan untuk kasus replikasi yang salah atau debugging.
        game:GetService("ServerStorage"),
        game:GetService("ServerScriptService"),
    }

    -- Pemindaian awal
    detectRemotes(servicesToMonitor)
    populateRemotes() -- Perbarui UI dengan remote yang awalnya ditemukan

    -- Siapkan listener ChildAdded/DescendantAdded untuk deteksi dinamis
    for _, service in ipairs(servicesToMonitor) do
        service.DescendantAdded:Connect(function(newDescendant)
            if newDescendant:IsA("RemoteEvent") or newDescendant:IsA("RemoteFunction") then
                if not table.find(remoteList, newDescendant) then
                    table.insert(remoteList, newDescendant)
                    remoteTimer[newDescendant] = { lastCall = tick(), cooldown = 0 }
                    logExploit("Remote Detection", "Success", "Ditemukan Secara Dinamis: " .. newDescendant:GetFullName())
                    populateRemotes() -- Perbarui UI dengan remote baru
                end
            end
        end)
    end
end


--- Mensimulasikan pengujian remote dengan argumen dan metode yang diberikan.
-- Dalam lingkungan Roblox yang sebenarnya, ini akan melibatkan FireServer atau InvokeServer.
-- @param remote RemoteEvent | RemoteFunction - Objek remote yang akan diuji.
-- @param args any - Argumen yang akan dilewatkan ke remote.
-- @param method string - Metode peretasan yang digunakan.
-- @return boolean - True jika pengujian "berhasil", false jika tidak.
local function testRemote(remote: RemoteEvent | RemoteFunction, args: any, method: string): boolean
    local currentTick = tick()
    -- Mengimplementasikan cooldown dasar untuk mencegah spam berlebihan dalam simulasi
    if remoteTimer[remote].cooldown > (currentTick - remoteTimer[remote].lastCall) then
        return false -- Masih dalam cooldown
    end

    local success: boolean = false
    local result: any = nil
    local vulnerabilityType: string? = nil

    if method == "PropertyManip" then
        -- Mensimulasikan upaya manipulasi properti
        local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
        if leaderstats and leaderstats:FindFirstChild(remote.Name) and leaderstats[remote.Name]:IsA("IntValue") then
            local pcallSuccess, pcallResult = pcall(function()
                -- Mensimulasikan perubahan nilai leaderstat
                leaderstats[remote.Name].Value = 999999999 -- Mencoba mengatur nilai yang sangat tinggi
                return "Attempted property manipulation"
            end)
            success = pcallSuccess
            result = pcallResult
            if success then
                vulnerabilityType = "High: Property Manipulation"
            end
        else
            result = "Property manipulation not applicable or leaderstat not found/not IntValue."
        end
    else
        -- Mensimulasikan firing/invoking remote
        local pcallSuccess, pcallResult = pcall(function()
            if remote:IsA("RemoteEvent") then
                remote:FireServer(args) -- Fire event
                return "Fired"
            elseif remote:IsA("RemoteFunction") then
                return remote:InvokeServer(args) -- Invoke fungsi dan dapatkan hasilnya
            end
        end)
        success = pcallSuccess
        result = pcallResult

        -- Pencatatan Status Granular berdasarkan hasil simulasi
        if success then
            local resultString = tostring(result)
            if resultString:find("Error") or resultString:find("Fail") then
                vulnerabilityType = "Medium: Server Error/Bad Response"
            elseif resultString:find("true") or resultString:find("granted") or resultString:find("success") then
                vulnerabilityType = "High: Unauthorized Action Granted"
            elseif resultString:find("999999999") or resultString:find("inf") or resultString:find("huge") then
                vulnerabilityType = "Critical: Infinite Value/Resource"
            elseif resultString:find("teleported") or resultString:find("moved") or resultString:find("position") then
                vulnerabilityType = "High: Unauthorized Teleport/Movement"
            elseif resultString:find("removed") or resultString:find("destroyed") or resultString:find("deleted") then
                vulnerabilityType = "Critical: Unauthorized Object Removal"
            else
                vulnerabilityType = "Low: Unexpected Success"
            end
        else
            local pcallResultString = tostring(pcallResult)
            if pcallResultString:find("timeout") or pcallResultString:find("yield") then
                vulnerabilityType = "Medium: Server Yield/Timeout"
            elseif pcallResultString:find("argument") or pcallResultString:find("type") then
                vulnerabilityType = "Low: Argument Type Mismatch"
            end
        end
    end

    -- Perbarui cooldown untuk remote
    remoteTimer[remote].lastCall = currentTick
    -- Cooldown dari delay UI, atau nilai default jika tidak berlaku
    local delayFromUI = tonumber(uiElements.DelayInput.Text) or 0.01
    remoteTimer[remote].cooldown = delayFromUI > 0 and delayFromUI or 0.01 -- Memastikan cooldown minimum

    local status = success and "Success" or "Failed"
    local details = string.format("%s dengan argumen: %s, Metode: %s, Hasil: %s",
        remote:GetFullName(), tostring(args), method, tostring(result))
    local logText = logExploit("Test Remote", status, details, vulnerabilityType)
    updateProcessLog(logText)
    -- Hanya perbarui log status jika berhasil atau jenis kegagalan spesifik
    if success or vulnerabilityType then
        updateStatusLog(logText, vulnerabilityType)
    end
    return success
end

--- Loop pengujian eksploitasi utama. Berjalan selama `testingActive` adalah true.
local function runExploitLoop()
    local argsToUse = customArgs or testArgs -- Gunakan argumen kustom jika tersedia, jika tidak gunakan default
    local delayTime = tonumber(uiElements.DelayInput.Text) or 0.01 -- Dapatkan delay dari UI

    while testingActive do
        for _, remote in ipairs(remoteList) do
            if not testingActive then return end -- Berhenti jika pengujian dinonaktifkan di tengah loop
            if selectedRemote == nil or remote == selectedRemote then -- Uji semua remote atau hanya yang dipilih
                if hackMethod == "AutoSpam" then
                    for _, arg in ipairs(argsToUse) do
                        if not testingActive then return end
                        testRemote(remote, arg, hackMethod)
                        task.wait(delayTime) -- Gunakan delay yang dapat dikonfigurasi
                    end
                elseif hackMethod == "FloodTest" then
                    for i = 1, 100 do -- Banjiri 100 kali per remote
                        if not testingActive then return end
                        testRemote(remote, argsToUse[math.random(1, #argsToUse)], hackMethod)
                        task.wait(delayTime / 10) -- Lebih cepat untuk banjir, tetapi masih menggunakan basis yang dapat dikonfigurasi
                    end
                elseif hackMethod == "SingleShot" then
                    -- SingleShot dipicu secara manual, jadi loop ini tidak akan berjalan untuknya
                    -- Loop akan secara efektif berhenti sampai testingActive false atau metode berubah
                    task.wait(0.1) -- Mencegah loop ketat jika SingleShot dipilih dan loop berjalan
                elseif hackMethod == "CustomArgs" then
                    if customArgs then
                        testRemote(remote, customArgs[1], hackMethod) -- Gunakan argumen kustom pertama
                        task.wait(delayTime)
                    else
                        updateProcessLog("Error: Argumen kustom tidak valid atau kosong.")
                    end
                elseif hackMethod == "PropertyManip" then
                    testRemote(remote, nil, hackMethod) -- Argumen mungkin tidak relevan untuk manipulasi properti
                    task.wait(delayTime)
                end
            end
        end
        task.wait(0.1) -- Delay kecil di antara iterasi penuh pada daftar remote
    end
end

--- Mengurai argumen kustom dari input string menggunakan JSONDecode.
-- Ini adalah alternatif yang lebih aman untuk `loadstring`.
-- @param input string - Input string dari pengguna (diharapkan format JSON).
-- @return boolean - True jika penguraian berhasil, false jika tidak.
-- @return string - Pesan yang menunjukkan keberhasilan atau kegagalan.
local function parseCustomArgs(input: string): (boolean, string)
    local success, result = pcall(function()
        -- Mencoba mengurai sebagai JSON.
        return HttpService:JSONDecode(input)
    end)

    if success then
        -- JSONDecode mengembalikan satu nilai (tabel, string, angka, boolean, nil)
        -- Bungkus dalam tabel agar konsisten dengan struktur `testArgs` yang merupakan array argumen
        customArgs = { result }
        return true, "Berhasil diurai: " .. HttpService:JSONEncode(result) -- Encode ulang untuk tampilan
    else
        customArgs = nil
        return false, "Gagal mengurai: " .. tostring(result) .. ". Pastikan format JSON valid (misal: {\"test\":123} atau \"string\")."
    end
end

-- UI Creation and Management Functions

--- Membuat frame UI generik dengan styling umum.
-- @param name string - Nama frame.
-- @param size UDim2 - Ukuran awal frame.
-- @param position UDim2 - Posisi awal frame.
-- @param parent Instance - Parent dari frame.
-- @return Frame - Frame yang dibuat.
local function createFrame(name: string, size: UDim2, position: UDim2, parent: Instance): Frame
    local frame = Instance.new("Frame")
    frame.Name = name
    frame.Size = size
    frame.Position = position
    frame.BackgroundColor3 = FRAME_BACKGROUND_COLOR
    frame.BorderSizePixel = 0
    frame.ClipsDescendants = true
    frame.Parent = parent

    -- Tambahkan UICorner untuk sudut membulat
    local uiCorner = Instance.new("UICorner")
    uiCorner.CornerRadius = CORNER_RADIUS
    uiCorner.Parent = frame

    -- Tambahkan UIStroke untuk efek border glow
    local uiStroke = Instance.new("UIStroke")
    uiStroke.Thickness = 2
    uiStroke.Color = BORDER_COLOR
    uiStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    uiStroke.Transparency = 0.3
    uiStroke.Parent = frame

    -- UIGradient opsional untuk glow halus di dalam border
    local uiGradient = Instance.new("UIGradient")
    uiGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 255, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 255))
    })
    uiGradient.Rotation = 45
    uiGradient.Transparency = NumberSequence.new(0.7)
    uiGradient.Parent = uiStroke -- Terapkan gradient ke stroke

    return frame
end

--- Membuat TextLabel untuk judul frame dengan tombol toggle.
-- @param parent GuiObject - Parent dari title bar.
-- @param text string - Konten teks judul.
-- @param textColor Color3 - Warna teks judul.
-- @return TextLabel - Label judul yang dibuat.
local function createTitleBar(parent: GuiObject, text: string, textColor: Color3): TextLabel
    local titleBar = Instance.new("TextLabel")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 30) -- Lebar penuh, tinggi 30px
    titleBar.BackgroundTransparency = 1
    titleBar.TextColor3 = textColor
    titleBar.Text = text
    titleBar.Font = Enum.Font.SourceSansBold
    titleBar.TextSize = 18
    titleBar.TextScaled = true -- Skalakan teks agar pas
    titleBar.TextWrapped = true
    titleBar.TextXAlignment = Enum.TextXAlignment.Center
    titleBar.Parent = parent
    titleBar.ZIndex = 2 -- Memastikan judul di atas konten
    titleBar.LayoutOrder = 1 -- Untuk UIListLayout

    -- Tambahkan tombol minimize/maximize kecil atau indikator
    local toggleButton = Instance.new("TextButton") -- Diubah menjadi TextButton agar bisa diklik
    toggleButton.Name = "ToggleButton"
    toggleButton.Size = UDim2.new(0, 20, 1, 0)
    toggleButton.Position = UDim2.new(1, -25, 0, 0) -- Posisi di kanan atas
    toggleButton.BackgroundTransparency = 1
    toggleButton.TextColor3 = textColor
    toggleButton.Text = "[-]"
    toggleButton.Font = Enum.Font.SourceSansBold
    toggleButton.TextSize = 16
    toggleButton.TextXAlignment = Enum.TextXAlignment.Center
    toggleButton.TextYAlignment = Enum.TextYAlignment.Center
    toggleButton.Parent = titleBar
    toggleButton.ZIndex = 3
    toggleButton.Cursor = Enum.Cursor.PointingHand

    -- Event listener untuk tombol toggle
    toggleButton.MouseButton1Click:Connect(function()
        local frameName = parent.Name
        uiStates[frameName] = not (uiStates[frameName] or false) -- Toggle status
        local isMinimized = uiStates[frameName]
        toggleButton.Text = isMinimized and "[+]" or "[-]"

        -- Animasi perubahan ukuran frame
        local targetHeight = isMinimized and 30 or 250 -- Tinggi penuh default
        if frameName == "StartFrame" then
            targetHeight = isMinimized and 30 or 100
        end

        local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        TweenService:Create(parent, tweenInfo, { Size = UDim2.new(parent.Size.X.Scale, parent.Size.X.Offset, 0, targetHeight) }):Play()

        -- Toggle visibilitas anak-anak (kecuali title bar itu sendiri dan tombol togglenya)
        for _, child in pairs(parent:GetChildren()) do
            if child ~= titleBar and child ~= toggleButton then
                child.Visible = not isMinimized
            end
        end
    end)

    return titleBar
end

--- Menyiapkan fungsionalitas drag untuk frame UI.
-- @param frame Frame - Frame yang akan dibuat draggable.
-- @param titleBar TextLabel - Title bar yang berfungsi sebagai handle drag.
local function setupDrag(frame: Frame, titleBar: TextLabel)
    titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            draggingFrame = frame
            -- Simpan posisi awal drag langsung pada instance frame
            frame.DragStartPos = input.Position
            frame.DragStartFramePos = frame.Position
            titleBar.Cursor = Enum.Cursor.Grabbing -- Ubah kursor saat dragging
        end
    end)

    titleBar.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if draggingFrame == frame then -- Pastikan itu adalah frame yang kita mulai drag
                draggingFrame = nil
                titleBar.Cursor = Enum.Cursor.Grab -- Reset kursor
            end
        end
    end)
end

-- Global InputChanged handler untuk dragging
UserInputService.InputChanged:Connect(function(input)
    if draggingFrame and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        -- Akses posisi awal drag dari instance draggingFrame
        local delta = input.Position - draggingFrame.DragStartPos
        draggingFrame.Position = UDim2.new(
            draggingFrame.DragStartFramePos.X.Scale,
            draggingFrame.DragStartFramePos.X.Offset + delta.X,
            draggingFrame.DragStartFramePos.Y.Scale,
            draggingFrame.DragStartFramePos.Y.Offset + delta.Y
        )
    end
end)

-- Global InputBegan handler untuk menutup dropdown saat mengklik di luar
UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        local target = input.Target

        -- Periksa Dropdown Metode
        local methodListFrame = uiElements.MethodListFrame as Frame
        local methodDropdownButton = uiElements.MethodDropdownButton as TextButton
        if methodListFrame and methodDropdownButton and methodListFrame.Visible then
            -- Tutup jika target bukan bagian dari tombol dropdown atau frame daftar dropdown
            if not target:IsDescendantOf(methodDropdownButton) and not target:IsDescendantOf(methodListFrame) then
                methodListFrame.Visible = false
            end
        end

        -- Periksa Dropdown Remote
        local remoteListFrame = uiElements.RemoteListFrame as Frame
        local remoteDropdownButton = uiElements.RemoteDropdownButton as TextButton
        if remoteListFrame and remoteDropdownButton and remoteListFrame.Visible then
            -- Tutup jika target bukan bagian dari tombol dropdown atau frame daftar dropdown
            if not target:IsDescendantOf(remoteDropdownButton) and not target:IsDescendantOf(remoteListFrame) then
                remoteListFrame.Visible = false
            end
        end
    end
end)

--- Membuat TextButton yang distyling.
-- @param parent GuiObject - Parent dari tombol.
-- @param text string - Konten teks tombol.
-- @param position UDim2 - Posisi tombol.
-- @param size UDim2 - Ukuran tombol.
-- @param bgColor Color3 - Warna latar belakang tombol.
-- @param textColor Color3 - Warna teks tombol.
-- @return TextButton - Tombol yang dibuat.
local function createStyledButton(parent: GuiObject, text: string, position: UDim2, size: UDim2, bgColor: Color3, textColor: Color3): TextButton
    local button = Instance.new("TextButton")
    button.Size = size
    button.Position = position
    button.BackgroundColor3 = bgColor
    button.TextColor3 = textColor
    button.Text = text
    button.Font = Enum.Font.SourceSansBold
    button.TextSize = 16
    button.TextScaled = true
    button.TextWrapped = true
    button.Parent = parent
    button.ZIndex = 2

    local uiCorner = Instance.new("UICorner")
    uiCorner.CornerRadius = BUTTON_CORNER_RADIUS
    uiCorner.Parent = button

    -- Animasi hover tombol
    button.MouseEnter:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.1), { BackgroundColor3 = BUTTON_HOVER_COLOR }):Play()
    end)
    button.MouseLeave:Connect(function()
        if button.BackgroundColor3 ~= BUTTON_ACTIVE_COLOR then -- Jangan berubah jika itu adalah warna aktif (STOP)
            TweenService:Create(button, TweenInfo.new(0.1), { BackgroundColor3 = bgColor }):Play()
        end
    end)

    return button
end

--- Membuat TextBox yang distyling.
-- @param parent GuiObject - Parent dari textbox.
-- @param placeholder string - Teks placeholder.
-- @param position UDim2 - Posisi textbox.
-- @param size UDim2 - Ukuran textbox.
-- @return TextBox - Textbox yang dibuat.
local function createStyledTextBox(parent: GuiObject, placeholder: string, position: UDim2, size: UDim2): TextBox
    local textBox = Instance.new("TextBox")
    textBox.Size = size
    textBox.Position = position
    textBox.BackgroundColor3 = INPUT_BACKGROUND_COLOR
    textBox.TextColor3 = TEXT_COLOR_LIGHT
    textBox.PlaceholderText = placeholder
    textBox.Font = Enum.Font.SourceSans
    textBox.TextSize = 14
    textBox.TextScaled = true
    textBox.TextWrapped = true
    textBox.Parent = parent
    textBox.ZIndex = 2

    local uiCorner = Instance.new("UICorner")
    uiCorner.CornerRadius = BUTTON_CORNER_RADIUS
    uiCorner.Parent = textBox

    return textBox
end

--- Membuat tombol toggle untuk auto-scrolling log.
-- @param parent GuiObject - Parent dari tombol.
-- @param logType string - "ProcessLog", "StatusLog", atau "DetailedLog".
-- @param initialPosition UDim2 - Posisi tombol.
-- @return TextButton - Tombol toggle yang dibuat.
local function createAutoScrollToggleButton(parent: GuiObject, logType: string, initialPosition: UDim2): TextButton
    local button = Instance.new("TextButton")
    button.Name = "AutoScrollToggle"
    button.Size = UDim2.new(0, 100, 0, 20)
    button.Position = initialPosition
    button.BackgroundColor3 = INPUT_BACKGROUND_COLOR
    button.TextColor3 = TEXT_COLOR_LIGHT
    button.Text = "Auto-Gulir: ON"
    button.Font = Enum.Font.SourceSans
    button.TextSize = 12
    button.Parent = parent
    button.ZIndex = 2

    local uiCorner = Instance.new("UICorner")
    uiCorner.CornerRadius = BUTTON_CORNER_RADIUS
    uiCorner.Parent = button

    button.MouseButton1Click:Connect(function()
        autoScrollLogs[logType] = not autoScrollLogs[logType]
        button.Text = "Auto-Gulir: " .. (autoScrollLogs[logType] and "ON" or "OFF")
        updateProcessLog(string.format("Auto-gulir %s: %s", logType, (autoScrollLogs[logType] and "ON" or "OFF")))
    end)

    -- Status awal
    button.Text = "Auto-Gulir: " .. (autoScrollLogs[logType] and "ON" or "OFF")
    return button
end

--- Mengisi dropdown pemilihan remote dengan remote yang terdeteksi.
local function populateRemotes()
    local remoteScrollingFrame = uiElements.RemoteScrollingFrame as ScrollingFrame
    local remoteDropdownButton = uiElements.RemoteDropdownButton as TextButton
    local remoteListLayout = uiElements.RemoteListLayout as UIListLayout

    -- Hapus tombol yang ada
    for _, child in pairs(remoteScrollingFrame:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end

    -- Tambahkan opsi "Semua Remote"
    local allButton = createStyledButton(remoteScrollingFrame, "Semua Remote", UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0, 25), INPUT_BACKGROUND_COLOR, TEXT_COLOR_LIGHT)
    allButton.TextXAlignment = Enum.TextXAlignment.Left
    allButton.MouseButton1Click:Connect(function()
        selectedRemote = nil
        remoteDropdownButton.Text = "Pilih Remote: Semua ▼"
        uiElements.RemoteListFrame.Visible = false
        updateProcessLog("Remote yang dipilih: Semua Remote.")
    end)

    -- Tambahkan tombol untuk setiap remote yang terdeteksi
    for _, remote in ipairs(remoteList) do
        local button = createStyledButton(remoteScrollingFrame, remote.Name, UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0, 25), INPUT_BACKGROUND_COLOR, TEXT_COLOR_LIGHT)
        button.TextXAlignment = Enum.TextXAlignment.Left
        button.MouseButton1Click:Connect(function()
            selectedRemote = remote
            remoteDropdownButton.Text = "Pilih Remote: " .. remote.Name .. " ▼"
            uiElements.RemoteListFrame.Visible = false
            updateProcessLog("Remote yang dipilih: " .. remote.Name)
        end)
    end

    -- UIListLayout akan secara otomatis menyesuaikan CanvasSize
end

--- Fungsi utama untuk membuat seluruh UI.
-- @return ScreenGui - Instance ScreenGui yang dibuat.
local function createUI(): ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "ZXHELLSecurityTools"
    screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.DisplayOrder = 1000 -- Memastikan di atas sebagian besar UI

    -- Definisikan posisi dan ukuran awal untuk frame
    -- Menggunakan skala untuk responsivitas dasar
    local frameWidth = UDim2.new(0, 250)
    local frameHeight = UDim2.new(0, 250)
    local startFrameHeight = UDim2.new(0, 100) -- Lebih kecil untuk frame awal

    -- Frame: Start
    local startFrame = createFrame("StartFrame", frameWidth, UDim2.new(0.02, 0, 0.05, 0), screenGui)
    startFrame.Size = startFrameHeight -- Mengesampingkan tinggi default untuk frame awal
    local startTitle = createTitleBar(startFrame, "ZXHELL Start", TITLE_TEXT_COLOR_PRIMARY)
    setupDrag(startFrame, startTitle)
    uiElements.StartFrame = startFrame

    local startButton = createStyledButton(startFrame, "START TEST", UDim2.new(0.5, -95, 0, 40), UDim2.new(0, 190, 0, 40), BUTTON_BACKGROUND_COLOR, TEXT_COLOR_LIGHT)
    startButton.MouseButton1Click:Connect(function()
        testingActive = not testingActive
        if testingActive then
            startButton.Text = "STOP TEST"
            -- Tween warna ke status aktif
            TweenService:Create(startButton, TweenInfo.new(0.1), { BackgroundColor3 = BUTTON_ACTIVE_COLOR }):Play()
            task.spawn(runExploitLoop) -- Mulai loop di thread baru
            logExploit("Testing", "Started", "Pengujian keamanan diaktifkan")
        else
            startButton.Text = "START TEST"
            -- Tween warna kembali ke default
            TweenService:Create(startButton, TweenInfo.new(0.1), { BackgroundColor3 = BUTTON_BACKGROUND_COLOR }):Play()
            logExploit("Testing", "Stopped", "Pengujian keamanan dinonaktifkan")
        end
    end)
    uiElements.StartButton = startButton

    -- Frame: Proses (Process Log)
    local processFrame = createFrame("ProcessFrame", frameWidth, UDim2.new(0.02, 260, 0.05, 0), screenGui)
    local processTitle = createTitleBar(processFrame, "Proses", TITLE_TEXT_COLOR_SECONDARY)
    setupDrag(processFrame, processTitle)
    uiElements.ProcessFrame = processFrame

    local processLogScrollingFrame = Instance.new("ScrollingFrame")
    processLogScrollingFrame.Name = "ProcessLogScrollingFrame"
    processLogScrollingFrame.Size = UDim2.new(1, -10, 1, -65) -- Disesuaikan untuk tombol auto-scroll
    processLogScrollingFrame.Position = UDim2.new(0, 5, 0, 35)
    processLogScrollingFrame.BackgroundTransparency = 1
    processLogScrollingFrame.ScrollBarThickness = SCROLLBAR_THICKNESS
    processLogScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0) -- Akan disesuaikan secara dinamis
    processLogScrollingFrame.Parent = processFrame
    uiElements.ProcessLogScrollingFrame = processLogScrollingFrame

    local processLogBox = Instance.new("TextLabel")
    processLogBox.Name = "ProcessLogBox"
    processLogBox.Size = UDim2.new(1, -10, 0, 0) -- Tinggi akan disesuaikan secara dinamis
    processLogBox.BackgroundTransparency = 1
    processLogBox.TextColor3 = LOG_TEXT_COLOR
    processLogBox.TextWrapped = true
    processLogBox.TextYAlignment = Enum.TextYAlignment.Top
    processLogBox.TextXAlignment = Enum.TextXAlignment.Left
    processLogBox.Text = "Menunggu aktivitas..."
    processLogBox.Font = Enum.Font.SourceSans
    processLogBox.TextSize = 14
    processLogBox.Parent = processLogScrollingFrame
    uiElements.ProcessLogBox = processLogBox

    local processAutoScrollButton = createAutoScrollToggleButton(processFrame, "ProcessLog", UDim2.new(0.5, -50, 1, -25))
    uiElements.ProcessAutoScrollButton = processAutoScrollButton

    -- Frame: Opsi (Options)
    local optionsFrame = createFrame("OptionsFrame", frameWidth, UDim2.new(0.02, 520, 0.05, 0), screenGui)
    local optionsTitle = createTitleBar(optionsFrame, "Opsi", TITLE_TEXT_COLOR_PRIMARY)
    setupDrag(optionsFrame, optionsTitle)
    uiElements.OptionsFrame = optionsFrame

    local argsInputLabel = Instance.new("TextLabel")
    argsInputLabel.Size = UDim2.new(1, -10, 0, 20)
    argsInputLabel.Position = UDim2.new(0, 5, 0, 35)
    argsInputLabel.BackgroundTransparency = 1
    argsInputLabel.TextColor3 = TEXT_COLOR_LIGHT
    argsInputLabel.Text = "Argumen Kustom (JSON):"
    argsInputLabel.Font = Enum.Font.SourceSansBold
    argsInputLabel.TextSize = 12
    argsInputLabel.TextXAlignment = Enum.TextXAlignment.Left
    argsInputLabel.Parent = optionsFrame

    local argsInput = createStyledTextBox(optionsFrame, "Contoh: {\"test\":123} atau \"string\"", UDim2.new(0, 5, 0, 55), UDim2.new(1, -10, 0, 30))
    argsInput.Text = "" -- Memastikan dimulai kosong
    argsInput.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            local success, msg = parseCustomArgs(argsInput.Text)
            updateProcessLog(success and "Argumen kustom: " .. msg or "Gagal parse: " .. msg)
        end
    end)
    uiElements.ArgsInput = argsInput

    local delayInputLabel = Instance.new("TextLabel")
    delayInputLabel.Size = UDim2.new(1, -10, 0, 20)
    delayInputLabel.Position = UDim2.new(0, 5, 0, 95)
    delayInputLabel.BackgroundTransparency = 1
    delayInputLabel.TextColor3 = TEXT_COLOR_LIGHT
    delayInputLabel.Text = "Delay (detik, misal: 0.01):"
    delayInputLabel.Font = Enum.Font.SourceSansBold
    delayInputLabel.TextSize = 12
    delayInputLabel.TextXAlignment = Enum.TextXAlignment.Left
    delayInputLabel.Parent = optionsFrame

    local delayInput = createStyledTextBox(optionsFrame, "0.01", UDim2.new(0, 5, 0, 115), UDim2.new(1, -10, 0, 30))
    delayInput.Text = "0.01" -- Nilai default
    uiElements.DelayInput = delayInput

    -- Frame: Status (Vulnerability Log)
    local statusFrame = createFrame("StatusFrame", frameWidth, UDim2.new(0.02, 780, 0.05, 0), screenGui)
    local statusTitle = createTitleBar(statusFrame, "Status", TITLE_TEXT_COLOR_SECONDARY)
    setupDrag(statusFrame, statusTitle)
    uiElements.StatusFrame = statusFrame

    local statusLogScrollingFrame = Instance.new("ScrollingFrame")
    statusLogScrollingFrame.Name = "StatusLogScrollingFrame"
    statusLogScrollingFrame.Size = UDim2.new(1, -10, 1, -65) -- Disesuaikan untuk tombol auto-scroll
    statusLogScrollingFrame.Position = UDim2.new(0, 5, 0, 35)
    statusLogScrollingFrame.BackgroundTransparency = 1
    statusLogScrollingFrame.ScrollBarThickness = SCROLLBAR_THICKNESS
    statusLogScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    statusLogScrollingFrame.Parent = statusFrame
    uiElements.StatusLogScrollingFrame = statusLogScrollingFrame

    local statusLogBox = Instance.new("TextLabel")
    statusLogBox.Name = "StatusLogBox"
    statusLogBox.Size = UDim2.new(1, -10, 0, 0)
    statusLogBox.BackgroundTransparency = 1
    statusLogBox.TextColor3 = LOG_TEXT_COLOR
    statusLogBox.TextWrapped = true
    statusLogBox.TextYAlignment = Enum.TextYAlignment.Top
    statusLogBox.TextXAlignment = Enum.TextXAlignment.Left
    statusLogBox.Text = "Kerentanan akan ditampilkan di sini..."
    statusLogBox.Font = Enum.Font.SourceSans
    statusLogBox.TextSize = 14
    statusLogBox.Parent = statusLogScrollingFrame
    uiElements.StatusLogBox = statusLogBox

    local statusAutoScrollButton = createAutoScrollToggleButton(statusFrame, "StatusLog", UDim2.new(0.5, -50, 1, -25))
    uiElements.StatusAutoScrollButton = statusAutoScrollButton

    -- Frame: Metode Peretasan (Hacking Methods)
    local methodFrame = createFrame("MethodFrame", frameWidth, UDim2.new(0.02, 0, 0.5, 0), screenGui)
    local methodTitle = createTitleBar(methodFrame, "Metode Peretasan", TITLE_TEXT_COLOR_PRIMARY)
    setupDrag(methodFrame, methodTitle)
    uiElements.MethodFrame = methodFrame

    local methodDropdownButton = createStyledButton(methodFrame, "Pilih Metode: Auto Spam", UDim2.new(0, 5, 0, 40), UDim2.new(1, -10, 0, 30), INPUT_BACKGROUND_COLOR, TEXT_COLOR_LIGHT)
    methodDropdownButton.TextXAlignment = Enum.TextXAlignment.Left
    methodDropdownButton.Text = methodDropdownButton.Text .. " ▼" -- Tambahkan panah dropdown
    methodDropdownButton.MouseButton1Click:Connect(function()
        uiElements.MethodListFrame.Visible = not uiElements.MethodListFrame.Visible
    end)
    uiElements.MethodDropdownButton = methodDropdownButton

    local methodListFrame = createFrame("MethodListFrame", UDim2.new(1, 0, 0, 150), UDim2.new(0, 0, 1, 0), methodDropdownButton)
    methodListFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    methodListFrame.Visible = false
    methodListFrame.ZIndex = 3 -- Memastikan dropdown di atas konten lain
    uiElements.MethodListFrame = methodListFrame

    local methodScrollingFrame = Instance.new("ScrollingFrame")
    methodScrollingFrame.Name = "MethodScrollingFrame"
    methodScrollingFrame.Size = UDim2.new(1, 0, 1, 0)
    methodScrollingFrame.BackgroundTransparency = 1
    methodScrollingFrame.ScrollBarThickness = SCROLLBAR_THICKNESS
    methodScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    methodScrollingFrame.Parent = methodListFrame
    uiElements.MethodScrollingFrame = methodScrollingFrame

    local methodListLayout = Instance.new("UIListLayout") -- Gunakan UIListLayout untuk pengaturan otomatis
    methodListLayout.FillDirection = Enum.FillDirection.Vertical
    methodListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    methodListLayout.Padding = UDim.new(0, 2)
    methodListLayout.Parent = methodScrollingFrame

    for _, method in ipairs(methods) do
        local button = createStyledButton(methodScrollingFrame, method.name, UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0, 25), INPUT_BACKGROUND_COLOR, TEXT_COLOR_LIGHT)
        button.TextXAlignment = Enum.TextXAlignment.Left
        button.MouseButton1Click:Connect(function()
            hackMethod = method.value
            methodDropdownButton.Text = "Pilih Metode: " .. method.name .. " ▼"
            methodListFrame.Visible = false
            updateProcessLog("Metode diubah: " .. method.name)
            -- Perbarui visibilitas SingleShotButton segera
            if uiElements.SingleShotButton then
                uiElements.SingleShotButton.Visible = (hackMethod == "SingleShot")
            end
        end)

        -- Tooltip untuk deskripsi metode
        local tooltip = Instance.new("TextLabel")
        tooltip.Name = "Tooltip"
        tooltip.Size = UDim2.new(0, 180, 0, 40)
        tooltip.Position = UDim2.new(1, 5, 0, 0)
        tooltip.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
        tooltip.TextColor3 = Color3.fromRGB(200, 200, 200)
        tooltip.Text = method.desc
        tooltip.TextWrapped = true
        tooltip.Visible = false
        tooltip.Font = Enum.Font.SourceSans
        tooltip.TextSize = 12
        tooltip.TextXAlignment = Enum.TextXAlignment.Left
        tooltip.TextYAlignment = Enum.TextYAlignment.Top
        tooltip.Parent = button
        local tooltipCorner = Instance.new("UICorner")
        tooltipCorner.CornerRadius = BUTTON_CORNER_RADIUS
        tooltipCorner.Parent = tooltip
        tooltip.ZIndex = 4 -- Memastikan tooltip di atas

        button.MouseEnter:Connect(function() tooltip.Visible = true end)
        button.MouseLeave:Connect(function() tooltip.Visible = false end)
    end

    -- Tombol Single Shot (hanya terlihat jika hackMethod adalah SingleShot)
    local singleShotButton = createStyledButton(methodFrame, "JALANKAN SINGLE SHOT", UDim2.new(0.5, -95, 0, 180), UDim2.new(0, 190, 0, 40), BUTTON_BACKGROUND_COLOR, TEXT_COLOR_LIGHT)
    singleShotButton.Visible = (hackMethod == "SingleShot") -- Visibilitas awal
    singleShotButton.MouseButton1Click:Connect(function()
        if selectedRemote then
            local argsToUse = customArgs or testArgs
            testRemote(selectedRemote, argsToUse[1] or nil, hackMethod) -- Uji dengan argumen pertama, atau nil jika tidak ada
            updateProcessLog(string.format("Single Shot ke %s selesai.", selectedRemote.Name))
        else
            updateProcessLog("Pilih remote terlebih dahulu untuk Single Shot.")
        end
    end)
    uiElements.SingleShotButton = singleShotButton

    -- Frame: Pilih Remote (Select Remote)
    local remoteFrame = createFrame("RemoteFrame", frameWidth, UDim2.new(0.02, 260, 0.5, 0), screenGui)
    local remoteTitle = createTitleBar(remoteFrame, "Pilih Remote", TITLE_TEXT_COLOR_SECONDARY)
    setupDrag(remoteFrame, remoteTitle)
    uiElements.RemoteFrame = remoteFrame

    local remoteDropdownButton = createStyledButton(remoteFrame, "Pilih Remote: Semua", UDim2.new(0, 5, 0, 40), UDim2.new(1, -10, 0, 30), INPUT_BACKGROUND_COLOR, TEXT_COLOR_LIGHT)
    remoteDropdownButton.TextXAlignment = Enum.TextXAlignment.Left
    remoteDropdownButton.Text = remoteDropdownButton.Text .. " ▼" -- Tambahkan panah dropdown
    remoteDropdownButton.MouseButton1Click:Connect(function()
        uiElements.RemoteListFrame.Visible = not uiElements.RemoteListFrame.Visible
        populateRemotes() -- Isi ulang jika ada remote baru yang terdeteksi
    end)
    uiElements.RemoteDropdownButton = remoteDropdownButton

    local remoteListFrame = createFrame("RemoteListFrame", UDim2.new(1, 0, 0, 150), UDim2.new(0, 0, 1, 0), remoteDropdownButton)
    remoteListFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    remoteListFrame.Visible = false
    remoteListFrame.ZIndex = 3
    uiElements.RemoteListFrame = remoteListFrame

    local remoteScrollingFrame = Instance.new("ScrollingFrame")
    remoteScrollingFrame.Name = "RemoteScrollingFrame"
    remoteScrollingFrame.Size = UDim2.new(1, 0, 1, 0)
    remoteScrollingFrame.BackgroundTransparency = 1
    remoteScrollingFrame.ScrollBarThickness = SCROLLBAR_THICKNESS
    remoteScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    remoteScrollingFrame.Parent = remoteListFrame
    uiElements.RemoteScrollingFrame = remoteScrollingFrame

    local remoteListLayout = Instance.new("UIListLayout") -- Gunakan UIListLayout untuk pengaturan otomatis
    remoteListLayout.FillDirection = Enum.FillDirection.Vertical
    remoteListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    remoteListLayout.Padding = UDim.new(0, 2)
    remoteListLayout.Parent = remoteScrollingFrame
    uiElements.RemoteListLayout = remoteListLayout -- Simpan referensi untuk populateRemotes

    -- Frame Log Eksploitasi Rinci (Penambahan baru)
    local detailedLogFrame = createFrame("DetailedLogFrame", UDim2.new(0, 510, 0, 250), UDim2.new(0.02, 520, 0.5, 0), screenGui)
    local detailedLogTitle = createTitleBar(detailedLogFrame, "Log Eksploitasi Rinci", TITLE_TEXT_COLOR_PRIMARY)
    setupDrag(detailedLogFrame, detailedLogTitle)
    uiElements.DetailedLogFrame = detailedLogFrame

    local detailedLogScrollingFrame = Instance.new("ScrollingFrame")
    detailedLogScrollingFrame.Name = "DetailedLogScrollingFrame"
    detailedLogScrollingFrame.Size = UDim2.new(1, -10, 1, -65) -- Disesuaikan untuk tombol auto-scroll
    detailedLogScrollingFrame.Position = UDim2.new(0, 5, 0, 35)
    detailedLogScrollingFrame.BackgroundTransparency = 1
    detailedLogScrollingFrame.ScrollBarThickness = SCROLLBAR_THICKNESS
    detailedLogScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    detailedLogScrollingFrame.Parent = detailedLogFrame
    uiElements.DetailedLogScrollingFrame = detailedLogScrollingFrame

    local detailedLogBox = Instance.new("TextLabel")
    detailedLogBox.Name = "DetailedLogBox"
    detailedLogBox.Size = UDim2.new(1, -10, 0, 0)
    detailedLogBox.BackgroundTransparency = 1
    detailedLogBox.TextColor3 = LOG_TEXT_COLOR
    detailedLogBox.TextWrapped = true
    detailedLogBox.TextYAlignment = Enum.TextYAlignment.Top
    detailedLogBox.TextXAlignment = Enum.TextXAlignment.Left
    detailedLogBox.Text = "Log detail akan ditampilkan di sini..."
    detailedLogBox.Font = Enum.Font.SourceSans
    detailedLogBox.TextSize = 12
    detailedLogBox.Parent = detailedLogScrollingFrame
    uiElements.DetailedLogBox = detailedLogBox

    local detailedAutoScrollButton = createAutoScrollToggleButton(detailedLogFrame, "DetailedLog", UDim2.new(0.5, -50, 1, -25))
    uiElements.DetailedAutoScrollButton = detailedAutoScrollButton

    -- Tombol Ekspor Log (Konseptual, membutuhkan akses sistem file yang terbatas di klien Roblox)
    local exportLogButton = createStyledButton(detailedLogFrame, "Ekspor Log (Konsol)", UDim2.new(0.5, -95, 1, -25), UDim2.new(0, 190, 0, 25), BUTTON_BACKGROUND_COLOR, TEXT_COLOR_LIGHT)
    exportLogButton.MouseButton1Click:Connect(function()
        local jsonLog = HttpService:JSONEncode(exploitLog)
        print("--- EXPORTED EXPLOIT LOG ---")
        print(jsonLog)
        print("--- END EXPORTED LOG ---")
        updateProcessLog("Log eksploitasi diekspor ke konsol.")
    end)
    uiElements.ExportLogButton = exportLogButton

    return screenGui
end

-- Initialization Sequence

-- Buat UI
local mainScreenGui = createUI()

-- Deteksi remote awal dan pengisian UI
setupDynamicRemoteDetection() -- Sekarang menangani pemindaian awal dan listener

-- Pesan log awal
updateProcessLog("ZXHELL Security Tools siap! Klik START TEST untuk mulai.")

-- Bind ke penutupan game untuk output log akhir (berguna untuk debugging di Studio)
game:BindToClose(function()
    local logJson = HttpService:JSONEncode(exploitLog)
    print("--- FINAL EXPLOIT LOG ON CLOSE ---")
    print(logJson)
    print("--- END FINAL EXPLOIT LOG ---")
end)

-- Perbarui UI log detail secara berkala
local function updateDetailedLogUI()
    local detailedLogBox = uiElements.DetailedLogBox as TextLabel
    local detailedLogScrollingFrame = uiElements.DetailedLogScrollingFrame as ScrollingFrame

    if detailedLogBox and detailedLogScrollingFrame then
        local logText = ""
        for i, entry in ipairs(exploitLog) do
            local timestamp = os.date("%X", entry.timestamp)
            local statusColor = "rgb(200,200,200)" -- Default
            if entry.status == "Success" then
                statusColor = "rgb(0,255,0)" -- Hijau untuk sukses
                if entry.vulnerabilityType then
                    if entry.vulnerabilityType:find("Critical") then statusColor = "rgb(255,0,0)" end -- Merah
                    if entry.vulnerabilityType:find("High") then statusColor = "rgb(255,165,0)" end -- Oranye
                    if entry.vulnerabilityType:find("Medium") then statusColor = "rgb(255,255,0)" end -- Kuning
                end
            elseif entry.status == "Failed" then
                statusColor = "rgb(255,0,0)" -- Merah untuk kegagalan
            end

            local entryString = string.format("[%s] <font color=\"%s\">%s</font>: %s (%s)",
                timestamp, statusColor, entry.action, entry.status, entry.details)
            if entry.vulnerabilityType then
                entryString = entryString .. string.format(" - Tipe Kerentanan: %s", entry.vulnerabilityType)
            end
            logText = logText .. entryString .. "\n"
        end

        detailedLogBox.RichText = true -- Aktifkan RichText untuk teks berwarna
        detailedLogBox.Text = logText
        detailedLogBox.Size = UDim2.new(1, -10, 0, detailedLogBox.TextBounds.Y)
        detailedLogScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, detailedLogBox.TextBounds.Y)
        if autoScrollLogs.DetailedLog then
            detailedLogScrollingFrame.CanvasPosition = Vector2.new(0, detailedLogBox.TextBounds.Y)
        end
    end
end

-- Perbarui UI log detail setiap detik (atau lebih jarang jika ada masalah kinerja)
RunService.Heartbeat:Connect(function()
    -- Hanya perbarui jika frame log detail terlihat dan tidak diminimize
    if uiElements.DetailedLogFrame and not uiStates.DetailedLogFrame then
        updateDetailedLogUI()
    end
end)

