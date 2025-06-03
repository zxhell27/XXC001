-- ZXHELL Security Tools: Alat pengujian kerentanan untuk game Roblox
-- Versi: 2.0
-- Tujuan: Menguji kerentanan sisi klien seperti bypass cooldown, spam remote, dan manipulasi data
-- Fitur: UI cyberpunk, mobile-friendly, drag/minimize, logging detail, timer per remote
-- Dibuat untuk pengguna awam dengan desain intuitif dan responsif
-- Inspirasi: Roblox UI Guide (create.roblox.com/docs/ui), Justinmind UI Principles
-- Catatan: Hanya untuk game Anda sendiri, bukan game publik

-- Layanan Roblox
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TextService = game:GetService("TextService")

-- Variabel global
local testingActive = false -- Status pengujian
local exploitLog = {} -- Log kerentanan
local remoteTimer = {} -- Timer per remote
local remoteList = {} -- Daftar RemoteEvents/Functions
local selectedRemote = nil -- Remote terpilih
local customArgs = nil -- Argumen kustom
local hackMethod = "AutoSpam" -- Metode peretasan default
local uiStates = {} -- Status minimize/maximize frame
local draggingFrame = nil -- Frame yang sedang di-drag
local scaleFactor = 1 -- Skala untuk layar mobile
local lastLogUpdate = 0 -- Waktu update log terakhir
local logUpdateInterval = 0.1 -- Interval update log (detik)
local testDelay = 0.01 -- Delay default pengujian (detik)

-- Fungsi utilitas: Logging kerentanan
-- Tujuan: Mencatat setiap tindakan pengujian dengan timestamp
-- Parameter: action (string), status (string), details (string)
-- Mengembalikan: String log untuk ditampilkan di UI
local function logExploit(action, status, details)
    local logEntry = {
        timestamp = os.time(),
        action = action,
        status = status,
        details = details
    }
    table.insert(exploitLog, logEntry)
    local logText = string.format("[%s] %s: %s (%s)", os.date("%X", logEntry.timestamp), action, status, details)
    print(logText)
    return logText
end

-- Fungsi utilitas: Mendeteksi RemoteEvents/Functions
-- Tujuan: Menemukan semua remote di ReplicatedStorage
-- Mengembalikan: Boolean (true jika ditemukan remote)
local function detectRemotes()
    remoteList = {}
    local success, err = pcall(function()
        for _, obj in pairs(ReplicatedStorage:GetDescendants()) do
            if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
                table.insert(remoteList, obj)
                remoteTimer[obj] = { lastCall = 0, cooldown = 0 }
                logExploit("Deteksi Remote", "Berhasil", "Ditemukan: " .. obj:GetFullName())
            end
        end
    end)
    if not success then
        logExploit("Deteksi Remote", "Gagal", "Error: " .. tostring(err))
    end
    return #remoteList > 0
end

-- Argumen uji untuk pengujian kerentanan
-- Tujuan: Menyediakan berbagai argumen untuk menguji respons server
local testArgs = {
    nil, -- Tanpa argumen
    "instant", -- String bypass
    true, -- Boolean
    -1, -- Nilai negatif
    999999, -- Nilai besar
    string.rep("x", 1000), -- String besar
    { exploit = "malicious", nested = { depth = 100 } }, -- Tabel berbahaya
    { math.huge, -math.huge, 0/0 }, -- Nilai numerik tidak valid
    "function() end", -- String menyerupai kode
    { userId = -999, action = "bypass" }, -- Tabel dengan ID tidak valid
    "", -- String kosong
    0, -- Nol
    { table.unpack({1, 2, 3}) }, -- Tabel dengan unpack
    { nil, nil, nil }, -- Tabel dengan nilai nil
    { key = math.random(1, 1000000) } -- Tabel dengan kunci acak
}

-- Fungsi utilitas: Menguji remote dengan argumen
-- Parameter: remote (Instance), args (any), method (string)
-- Mengembalikan: success (boolean), status (string), details (string)
local function testRemote(remote, args, method)
    if not remote or remoteTimer[remote].cooldown > 0 then
        return false, "Lewati", "Remote tidak tersedia atau dalam cooldown"
    end
    local success, result
    if method == "PropertyManip" then
        success, result = pcall(function()
            local leaderstats = Players.LocalPlayer:FindFirstChild("leaderstats")
            if leaderstats then
                leaderstats[remote.Name] = 999999
                return "Mencoba manipulasi properti"
            end
            return "Leaderstats tidak ditemukan"
        end)
    else
        success, result = pcall(function()
            if remote:IsA("RemoteEvent") then
                remote:FireServer(args)
                return "Dipanggil"
            elseif remote:IsA("RemoteFunction") then
                return remote:InvokeServer(args)
            end
        end)
    end
    remoteTimer[remote].lastCall = tick()
    remoteTimer[remote].cooldown = 0
    local status = success and "Berhasil" or "Gagal"
    local details = remote:GetFullName() .. " dengan argumen: " .. tostring(args) .. ", Metode: " .. method .. ", Hasil: " .. tostring(result)
    logExploit("Uji Remote", status, details)
    return success, status, details
end

-- Fungsi utilitas: Parsing argumen kustom
-- Parameter: input (string)
-- Mengembalikan: success (boolean), message (string)
local function parseCustomArgs(input)
    local success, result = pcall(function()
        return loadstring("return " .. input)()
    end)
    if success then
        customArgs = { result }
        return true, "Berhasil parse: " .. tostring(result)
    else
        customArgs = nil
        return false, "Gagal parse: " .. tostring(result)
    end
end

-- Fungsi utilitas: Animasi tombol
-- Parameter: button (TextButton), hover (boolean)
local function animateButton(button, hover)
    spawn(function()
        local originalColor = button.BackgroundColor3
        local targetColor = hover and Color3.fromRGB(0, 100, 200) or Color3.fromRGB(0, 80, 150)
        for t = 0, 1, 0.1 do
            button.BackgroundColor3 = originalColor:Lerp(targetColor, t)
            task.wait(0.02)
        end
    end)
end

-- Fungsi utilitas: Membuat frame UI
-- Parameter: name (string), size (UDim2), position (UDim2)
-- Mengembalikan: Frame
local function createFrame(name, size, position)
    local frame = Instance.new("Frame")
    frame.Name = name
    frame.Size = UDim2.new(size.X.Scale * scaleFactor, size.X.Offset * scaleFactor, size.Y.Scale * scaleFactor, size.Y.Offset * scaleFactor)
    frame.Position = UDim2.new(position.X.Scale, position.X.Offset * scaleFactor, position.Y.Scale, position.Y.Offset * scaleFactor)
    frame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    frame.BorderSizePixel = 0
    frame.ClipsDescendants = true
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame
    local border = Instance.new("UIStroke")
    border.Thickness = 2
    border.Color = Color3.fromRGB(0, 255, 255)
    border.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    border.Transparency = 0.3
    local glow = Instance.new("UIGradient")
    glow.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 255, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 255))
    })
    glow.Rotation = 45
    glow.Transparency = NumberSequence.new(0.7)
    glow.Parent = border
    border.Parent = frame
    return frame
end

-- Fungsi utilitas: Membuat tombol
-- Parameter: parent (Instance), name (string), text (string), size (UDim2), position (UDim2)
-- Mengembalikan: TextButton
local function createButton(parent, name, text, size, position)
    local button = Instance.new("TextButton")
    button.Name = name
    button.Size = UDim2.new(size.X.Scale * scaleFactor, size.X.Offset * scaleFactor, size.Y.Scale * scaleFactor, size.Y.Offset * scaleFactor)
    button.Position = UDim2.new(position.X.Scale, position.X.Offset * scaleFactor, position.Y.Scale, position.Y.Offset * scaleFactor)
    button.BackgroundColor3 = Color3.fromRGB(0, 80, 150)
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.Text = text
    button.Font = Enum.Font.SourceSansBold
    button.TextSize = 16 * scaleFactor
    button.Parent = parent
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = button
    button.MouseEnter:Connect(function() animateButton(button, true) end)
    button.MouseLeave:Connect(function() animateButton(button, false) end)
    return button
end

-- Fungsi utilitas: Membuat label
-- Parameter: parent (Instance), name (string), text (string), size (UDim2), position (UDim2)
-- Mengembalikan: TextLabel
local function createLabel(parent, name, text, size, position)
    local label = Instance.new("TextLabel")
    label.Name = name
    label.Size = UDim2.new(size.X.Scale * scaleFactor, size.X.Offset * scaleFactor, size.Y.Scale * scaleFactor, size.Y.Offset * scaleFactor)
    label.Position = UDim2.new(position.X.Scale, position.X.Offset * scaleFactor, position.Y.Scale, position.Y.Offset * scaleFactor)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(200, 200, 200)
    label.Text = text
    label.Font = Enum.Font.SourceSans
    label.TextSize = 14 * scaleFactor
    label.TextWrapped = true
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = parent
    return label
end

-- Fungsi utilitas: Membuat scrolling frame
-- Parameter: parent (Instance), name (string), size (UDim2), position (UDim2)
-- Mengembalikan: ScrollingFrame
local function createScrollingFrame(parent, name, size, position)
    local scrolling = Instance.new("ScrollingFrame")
    scrolling.Name = name
    scrolling.Size = UDim2.new(size.X.Scale * scaleFactor, size.X.Offset * scaleFactor, size.Y.Scale * scaleFactor, size.Y.Offset * scaleFactor)
    scrolling.Position = UDim2.new(position.X.Scale, position.X.Offset * scaleFactor, position.Y.Scale, position.Y.Offset * scaleFactor)
    scrolling.BackgroundTransparency = 1
    scrolling.ScrollBarThickness = 4
    scrolling.CanvasSize = UDim2.new(0, 0, 0, 0)
    scrolling.Parent = parent
    return scrolling
end

-- Fungsi utilitas: Toggle frame minimize/maximize
-- Parameter: frame (Frame), titleBar (TextLabel)
local function toggleFrame(frame, titleBar)
    local isMinimized = uiStates[frame] or false
    frame.Size = isMinimized and UDim2.new(0, 200 * scaleFactor, 0, 250 * scaleFactor) or UDim2.new(0, 200 * scaleFactor, 0, 30 * scaleFactor)
    for _, child in ipairs(frame:GetChildren()) do
        if child ~= titleBar then
            child.Visible = isMinimized
        end
    end
    uiStates[frame] = not isMinimized
end

-- Fungsi utilitas: Setup drag untuk frame
-- Parameter: frame (Frame), titleBar (TextLabel)
local function setupDrag(frame, titleBar)
    local dragStartPos, dragStartFramePos
    titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            draggingFrame = frame
            dragStartPos = input.Position
            dragStartFramePos = frame.Position
            frame.dragStartPos = dragStartPos
            frame.dragStartFramePos = dragStartFramePos
        end
    end)
    titleBar.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            draggingFrame = nil
        end
    end)
end

-- Fungsi utama: Loop pengujian
-- Tujuan: Menjalankan pengujian kerentanan sesuai metode
local function runExploitLoop()
    if not testingActive then return end
    local argsToUse = customArgs or testArgs
    local delay = tonumber(testDelay) or 0.01
    for _, remote in ipairs(remoteList) do
        if selectedRemote == nil or remote == selectedRemote then
            if hackMethod == "AutoSpam" then
                for _, arg in ipairs(argsToUse) do
                    if not testingActive then return end
                    testRemote(remote, arg, hackMethod)
                    task.wait(delay)
                end
            elseif hackMethod == "FloodTest" then
                for i = 1, 100 do
                    if not testingActive then return end
                    testRemote(remote, argsToUse[math.random(1, #argsToUse)], hackMethod)
                    task.wait(delay / 10)
                end
            else
                testRemote(remote, argsToUse[1], hackMethod)
                task.wait(delay)
            end
        end
    end
end

-- Fungsi utama: Membuat UI
-- Tujuan: Membuat UI cyberpunk yang responsif dan intuitif
local function createUI()
    -- Skala untuk layar mobile
    scaleFactor = math.min(1, math.min(workspace.CurrentCamera.ViewportSize.X / 800, workspace.CurrentCamera.ViewportSize.Y / 600))

    -- ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "ZXHELLSecurityTools"
    screenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui", 10)
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.DisplayOrder = 1000

    -- Frame Start
    local startFrame = createFrame("StartFrame", UDim2.new(0, 200, 0, 100), UDim2.new(0.05, 10, 0.05, 10))
    startFrame.Parent = screenGui
    local startTitle = createLabel(startFrame, "StartTitle", "ZXHELL Start", UDim2.new(1, -30, 0, 30), UDim2.new(0, 0, 0, 0))
    startTitle.TextColor3 = Color3.fromRGB(0, 255, 255)
    startTitle.Font = Enum.Font.SourceSansBold
    startTitle.TextSize = 18 * scaleFactor
    setupDrag(startFrame, startTitle)
    startTitle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            toggleFrame(startFrame, startTitle)
        end
    end)
    local startButton = createButton(startFrame, "StartButton", "MULAI PENGUJIAN", UDim2.new(1, -10, 0, 40), UDim2.new(0, 5, 0, 40))
    startButton.MouseButton1Click:Connect(function()
        testingActive = not testingActive
        startButton.Text = testingActive and "HENTIKAN PENGUJIAN" or "MULAI PENGUJIAN"
        startButton.BackgroundColor3 = testingActive and Color3.fromRGB(150, 0, 0) or Color3.fromRGB(0, 80, 150)
        logExploit("Pengujian", testingActive and "Dimulai" or "Dihentikan", "Pengujian keamanan " .. (testingActive and "diaktifkan" or "dinonaktifkan"))
        if testingActive then
            spawn(runExploitLoop)
        end
    end)

    -- Frame Proses
    local processFrame = createFrame("ProcessFrame", UDim2.new(0, 200, 0, 250), UDim2.new(0.3, 10, 0.05, 10))
    processFrame.Parent = screenGui
    local processTitle = createLabel(processFrame, "ProcessTitle", "Proses", UDim2.new(1, -30, 0, 30), UDim2.new(0, 0, 0, 0))
    processTitle.TextColor3 = Color3.fromRGB(255, 0, 255)
    processTitle.Font = Enum.Font.SourceSansBold
    processTitle.TextSize = 18 * scaleFactor
    setupDrag(processFrame, processTitle)
    processTitle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            toggleFrame(processFrame, processTitle)
        end
    end)
    local processLog = createScrollingFrame(processFrame, "ProcessLog", UDim2.new(1, -10, 1, -40), UDim2.new(0, 5, 0, 35))
    local processLogBox = createLabel(processLog, "ProcessLogBox", "Menunggu aktivitas...", UDim2.new(1, -10, 0, 0), UDim2.new(0, 0, 0, 0))
    local function updateProcessLog(text)
        processLogBox.Text = processLogBox.Text .. "\n" .. text
        local textSize = TextService:GetTextSize(processLogBox.Text, processLogBox.TextSize, processLogBox.Font, Vector2.new(processLog.Size.X.Offset - 10, math.huge))
        processLogBox.Size = UDim2.new(1, -10, 0, textSize.Y)
        processLog.CanvasSize = UDim2.new(0, 0, 0, textSize.Y)
        processLog.CanvasPosition = Vector2.new(0, textSize.Y)
    end

    -- Frame Opsi
    local optionsFrame = createFrame("OptionsFrame", UDim2.new(0, 200, 0, 250), UDim2.new(0.55, 10, 0.05, 10))
    optionsFrame.Parent = screenGui
    local optionsTitle = createLabel(optionsFrame, "OptionsTitle", "Opsi", UDim2.new(1, -30, 0, 30), UDim2.new(0, 0, 0, 0))
    optionsTitle.TextColor3 = Color3.fromRGB(0, 255, 255)
    optionsTitle.Font = Enum.Font.SourceSansBold
    optionsTitle.TextSize = 18 * scaleFactor
    setupDrag(optionsFrame, optionsTitle)
    optionsTitle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            toggleFrame(optionsFrame, optionsTitle)
        end
    end)
    local argsInput = Instance.new("TextBox")
    argsInput.Name = "ArgsInput"
    argsInput.Size = UDim2.new(1, -10, 0, 30)
    argsInput.Position = UDim2.new(0, 5, 0, 40)
    argsInput.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    argsInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    argsInput.PlaceholderText = "Argumen kustom (misal: {test=123})"
    argsInput.Font = Enum.Font.SourceSans
    argsInput.TextSize = 14 * scaleFactor
    argsInput.Parent = optionsFrame
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = argsInput
    argsInput.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            local success, msg = parseCustomArgs(argsInput.Text)
            updateProcessLog(success and "Argumen kustom: " .. msg or "Gagal parse: " .. msg)
        end
    end)
    local delayInput = Instance.new("TextBox")
    delayInput.Name = "DelayInput"
    delayInput.Size = UDim2.new(1, -10, 0, 30)
    delayInput.Position = UDim2.new(0, 5, 0, 80)
    delayInput.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    delayInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    delayInput.PlaceholderText = "Delay (detik, misal: 0.01)"
    delayInput.Text = "0.01"
    delayInput.Font = Enum.Font.SourceSans
    delayInput.TextSize = 14 * scaleFactor
    delayInput.Parent = optionsFrame
    local cornerDelay = Instance.new("UICorner")
    cornerDelay.CornerRadius = UDim.new(0, 4)
    cornerDelay.Parent = delayInput
    delayInput.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            local newDelay = tonumber(delayInput.Text)
            if newDelay and newDelay > 0 then
                testDelay = newDelay
                updateProcessLog("Delay diatur ke: " .. newDelay .. " detik")
            else
                updateProcessLog("Delay tidak valid, menggunakan default 0.01")
            end
        end
    end)

    -- Frame Status
    local statusFrame = createFrame("StatusFrame", UDim2.new(0, 200, 0, 250), UDim2.new(0.8, 10, 0.05, 10))
    statusFrame.Parent = screenGui
    local statusTitle = createLabel(statusFrame, "StatusTitle", "Status", UDim2.new(1, -30, 0, 30), UDim2.new(0, 0, 0, 0))
    statusTitle.TextColor3 = Color3.fromRGB(255, 0, 255)
    statusTitle.Font = Enum.Font.SourceSansBold
    statusTitle.TextSize = 18 * scaleFactor
    setupDrag(statusFrame, statusTitle)
    statusTitle.InputBegan:Connect(function(input)
if input.UserInputType == Enum.UserInputType.MouseButton1 then
toggleFrame(statusFrame, statusTitle)
end
end)
local statusLog = createScrollingFrame(statusFrame, "StatusLog", UDim2.new(1, -10, 1, -40), UDim2.new(0, 5, 0, 35))
local statusLogBox = createLabel(statusLog, "StatusLogBox", "Kerentanan akan ditampilkan di sini...", UDim2.new(1, -10, 0, 0), UDim2.new(0, 0, 0, 0))
local function updateStatusLog(text)
if text:find("Berhasil") then
local remoteName = text:match("Uji Remote: Berhasil%((.-) dengan argumen") or "Tidak Diketahui"
local arg = text:match("argumen: (.-), Metode") or "Tidak Diketahui"
local vulnText = string.format("Kerentanan: %s rentan terhadap argumen %s", remoteName, arg)
statusLogBox.Text = statusLogBox.Text .. "\n" .. vulnText
local textSize = TextService:GetTextSize(statusLogBox.Text, statusLogBox.TextSize, statusLogBox.Font, Vector2.new(statusLog.Size.X.Offset - 10, math.huge))
statusLogBox.Size = UDim2.new(1, -10, 0, textSize.Y)
statusLog.CanvasSize = UDim2.new(0, 0, 0, textSize.Y)
statusLog.CanvasPosition = Vector2.new(0, textSize.Y)
end
end

-- Frame Metode Peretasan
local methodFrame = createFrame("MethodFrame", UDim2.new(0, 200, 0, 250), UDim2.new(0.05, 10, 0.4, 10))
methodFrame.Parent = screenGui
local methodTitle = createLabel(methodFrame, "MethodTitle", "Metode Peretasan", UDim2.new(1, -30, 0, 30), UDim2.new(0, 0, 0, 0))
methodTitle.TextColor3 = Color3.fromRGB(0, 255, 255)
methodTitle.Font = Enum.Font.SourceSansBold
methodTitle.TextSize = 18 * scaleFactor
setupDrag(methodFrame, methodTitle)
methodTitle.InputBegan:Connect(function(input)
if input.UserInputType == Enum.UserInputType.MouseButton1 then
toggleFrame(methodFrame, methodTitle)
end
end)
local methodDropdown = createButton(methodFrame, "MethodDropdown", "Pilih Metode: Auto Spam", UDim2.new(1, -10, 0, 30), UDim2.new(0, 5, 0, 40))
local methodList = Instance.new("Frame")
methodList.Name = "MethodList"
methodList.Size = UDim2.new(1, 0, 0, 100 * scaleFactor)
methodList.Position = UDim2.new(0, 0, 1, 0)
methodList.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
methodList.Visible = false
methodList.Parent = methodDropdown
local cornerMethodList = Instance.new("UICorner")
cornerMethodList.CornerRadius = UDim.new(0, 4)
cornerMethodList.Parent = methodList
local methodScrolling = createScrollingFrame(methodList, "MethodScrolling", UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0))
local methods = {
{ name = "Auto Spam", desc = "Spam semua argumen secara otomatis" },
{ name = "Single Shot", desc = "Uji satu argumen per klik" },
{ name = "Custom Args", desc = "Gunakan argumen kustom dari Opsi" },
{ name = "Flood Test", desc = "Spam cepat untuk uji beban server" },
{ name = "Property Manip", desc = "Coba ubah properti seperti leaderstats" },
}
local yOffset = 0
for , method in ipairs(methods) do
local button = createButton(methodScrolling, "Method" .. method.name, method.name, UDim2.new(1, 0, 0, 25), UDim2.new(0, 0, 0, yOffset))
button.TextSize = 14 * scaleFactor
button.MouseButton1Click:Connect(function()
hackMethod = method.name:gsub(" ", "")
methodDropdown.Text = "Pilih Metode: " .. method.name
methodList.Visible = false
updateProcessLog("Metode diubah: " .. method.name)
end)
local tooltip = createLabel(button, "Tooltip", method.desc, UDim2.new(0, 150 * scaleFactor, 0, 40 * scaleFactor), UDim2.new(1, 5, 0, 0))
tooltip.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
tooltip.TextColor3 = Color3.fromRGB(200, 200, 200)
tooltip.Visible = false
local cornerTooltip = Instance.new("UICorner")
cornerTooltip.CornerRadius = UDim.new(0, 4)
cornerTooltip.Parent = tooltip
button.MouseEnter:Connect(function() tooltip.Visible = true end)
button.MouseLeave:Connect(function() tooltip.Visible = false end)
yOffset = yOffset + 25
end
methodScrolling.CanvasSize = UDim2.new(0, 0, 0, yOffset * scaleFactor)
methodDropdown.MouseButton1Click:Connect(function()
methodList.Visible = not methodList.Visible
end)

-- Frame Pilih Remote
local remoteFrame = createFrame("RemoteFrame", UDim2.new(0, 200, 0, 250), UDim2.new(0.3, 10, 0.4, 10))
remoteFrame.Parent = screenGui
local remoteTitle = createLabel(remoteFrame, "RemoteTitle", "Pilih Remote", UDim2.new(1, -30, 0, 30), UDim2.new(0, 0, 0, 0))
remoteTitle.TextColor3 = Color3.fromRGB(255, 0, 255)
remoteTitle.Font = Enum.Font.SourceSansBold
remoteTitle.TextSize = 18 * scaleFactor
setupDrag(remoteFrame, remoteTitle)
remoteTitle.InputBegan:Connect(function(input)
if input.UserInputType == Enum.UserInputType.MouseButton1 then
toggleFrame(remoteFrame, remoteTitle)
end
end)
local remoteDropdown = createButton(remoteFrame, "RemoteDropdown", "Pilih Remote: Semua", UDim2.new(1, -10, 0, 30), UDim2.new(0, 5, 0, 40))
local remoteListFrame = Instance.new("Frame")
remoteListFrame.Name = "RemoteListFrame"
remoteListFrame.Size = UDim2.new(1, 0, 0, 100 * scaleFactor)
remoteListFrame.Position = UDim2.new(0, 0, 1, 0)
remoteListFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
remoteListFrame.Visible = false
remoteListFrame.Parent = remoteDropdown
local cornerRemoteList = Instance.new("UICorner")
cornerRemoteList.CornerRadius = UDim.new(0, 4)
cornerRemoteList.Parent = remoteListFrame
local remoteScrolling = createScrollingFrame(remoteListFrame, "RemoteScrolling", UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0))
local function populateRemotes()
for _, child in ipairs(remoteScrolling:GetChildren()) do
if child:IsA("TextButton") then
child:Destroy()
end
end
local yOffset = 0
local allButton = createButton(remoteScrolling, "AllRemotes", "Semua Remote", UDim2.new(1, 0, 0, 25), UDim2.new(0, 0, 0, yOffset))
allButton.TextSize = 14 * scaleFactor
allButton.MouseButton1Click:Connect(function()
selectedRemote = nil
remoteDropdown.Text = "Pilih Remote: Semua"
remoteListFrame.Visible = false
end)
yOffset = yOffset + 25
for , remote in ipairs(remoteList) do
local button = createButton(remoteScrolling, "Remote" .. remote.Name, remote.Name, UDim2.new(1, 0, 0, 25), UDim2.new(0, 0, 0, yOffset))
button.TextSize = 14 * scaleFactor
button.MouseButton1Click:Connect(function()
selectedRemote = remote
remoteDropdown.Text = "Pilih Remote: " .. remote.Name
remoteListFrame.Visible = false
end)
yOffset = yOffset + 25
end
remoteScrolling.CanvasSize = UDim2.new(0, 0, 0, yOffset * scaleFactor)
end

-- Frame Tambahan: Pengaturan Lanjutan
local settingsFrame = createFrame("SettingsFrame", UDim2.new(0, 200, 0, 250), UDim2.new(0.55, 10, 0.4, 10))
settingsFrame.Parent = screenGui
local settingsTitle = createLabel(settingsFrame, "SettingsTitle", "Pengaturan Lanjutan", UDim2.new(1, -30, 0, 30), UDim2.new(0, 0, 0, 0))
settingsTitle.TextColor3 = Color3.fromRGB(0, 255, 255)
settingsTitle.Font = Enum.Font.SourceSansBold
settingsTitle.TextSize = 18 * scaleFactor
setupDrag(settingsFrame, settingsTitle)
settingsTitle.InputBegan:Connect(function(input)
if input.UserInputType == Enum.UserInputType.MouseButton1 then
toggleFrame(settingsFrame, settingsTitle)
end
end)
local autoScrollToggle = createButton(settingsFrame, "AutoScrollToggle", "Auto Scroll: ON", UDim2.new(1, -10, 0, 30), UDim2.new(0, 5, 0, 40))
local autoScroll = true
autoScrollToggle.MouseButton1Click:Connect(function()
autoScroll = not autoScroll
autoScrollToggle.Text = "Auto Scroll: " .. (autoScroll and "ON" or "OFF")
updateProcessLog("Auto Scroll diatur ke: " .. (autoScroll and "ON" or "OFF"))
end)
local clearLogButton = createButton(settingsFrame, "ClearLogButton", "Hapus Log", UDim2.new(1, -10, 0, 30), UDim2.new(0, 5, 0, 80))
clearLogButton.MouseButton1Click:Connect(function()
processLogBox.Text = "Log dihapus"
statusLogBox.Text = "Kerentanan akan ditampilkan di sini..."
exploitLog = {}
updateProcessLog("Log dihapus")
end)

-- Handler Drag
UserInputService.InputChanged:Connect(function(input)
if draggingFrame and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
local delta = input.Position - draggingFrame.dragStartPos
draggingFrame.Position = UDim2.new(
draggingFrame.dragStartFramePos.X.Scale,
draggingFrame.dragStartFramePos.X.Offset + delta.X,
draggingFrame.dragStartFramePos.Y.Scale,
draggingFrame.dragStartFramePos.Y.Offset + delta.Y
)
end
end)

-- Handler Tutup Dropdown
UserInputService.InputBegan:Connect(function(input)
if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
if methodList.Visible and not methodDropdown:IsAncestorOf(input.Target) then
methodList.Visible = false
end
if remoteListFrame.Visible and not remoteDropdown:IsAncestorOf(input.Target) then
remoteListFrame.Visible = false
end
end
end)

-- Update Timer
local function updateTimerUI()
for _, timer in pairs(remoteTimer) do
if timer.cooldown > 0 then
timer.cooldown = timer.cooldown - RunService.Heartbeat:Wait()
end
end
end

-- Update Log
local function updateLogs(text)
if autoScroll then
updateProcessLog(text)
updateStatusLog(text)
else
processLogBox.Text = processLogBox.Text .. "\n" .. text
if text:find("Berhasil") then
local remoteName = text:match("Uji Remote: Berhasil%((.-) dengan argumen") or "Tidak Diketahui"
local arg = text:match("argumen: (.-), Metode") or "Tidak Diketahui"
local vulnText = string.format("Kerentanan: %s rentan terhadap argumen %s", remoteName, arg)
statusLogBox.Text = statusLogBox.Text .. "\n" .. vulnText
end
end
end

-- Inisialisasi
if detectRemotes() then
updateLogs("Terdeteksi " .. #remoteList .. " remote")
populateRemotes()
else
updateLogs("Tidak ada remote ditemukan di ReplicatedStorage")
end

-- Timer Update
RunService.Heartbeat:Connect(updateTimerUI)

-- Log Awal
updateLogs("ZXHELL Security Tools siap! Klik MULAI PENGUJIAN untuk mulai.")

return screenGui
end

-- Inisialisasi UI
local success, errorMsg = pcall(createUI)
if not success then
logExploit("Inisialisasi UI", "Gagal", "Error: " .. tostring(errorMsg))
end

-- Simpan Log Saat Keluar
game:BindToClose(function()
local logJson = HttpService:JSONEncode(exploitLog)
print("Log Akhir ZXHELL:", logJson)
end)

-- Fungsi Tambahan: Rekomendasi Keamanan
-- Tujuan: Memberikan saran perbaikan berdasarkan log
local function generateSecurityRecommendations()
local recommendations = {}
for _, log in ipairs(exploitLog) do
if log.status == "Berhasil" and log.action == "Uji Remote" then
local remoteName = log.details:match("(.-) dengan argumen") or "Tidak Diketahui"
local arg = log.details:match("argumen: (.-), Metode") or "Tidak Diketahui"
table.insert(recommendations, string.format("Remote %s rentan terhadap %s. Tambahkan validasi server-side.", remoteName, arg))
end
end
return recommendations
end

-- Fungsi Tambahan: Ekspor Log ke JSON
-- Tujuan: Memungkinkan pengguna menyimpan log
local function exportLog()
local logJson = HttpService:JSONEncode(exploitLog)
logExploit("Ekspor Log", "Berhasil", "Log disimpan sebagai JSON")
return logJson
end

-- Fungsi Tambahan: Periksa Performa
-- Tujuan: Memantau performa pengujian
local function checkPerformance()
local startTime = tick()
local testCount = 0
for _, remote in ipairs(remoteList) do
testRemote(remote, testArgs[1], "AutoSpam")
testCount = testCount + 1
end
local endTime = tick()
local duration = endTime - startTime
logExploit("Performa", "Berhasil", string.format("Uji %d remote selesai dalam %.2f detik", testCount, duration))
end

-- Fungsi Tambahan: Notifikasi Visual
-- Tujuan: Menampilkan notifikasi sementara di layar
local function showNotification(message, color)
local notification = Instance.new("Frame")
notification.Size = UDim2.new(0, 200 * scaleFactor, 0, 50 * scaleFactor)
notification.Position = UDim2.new(0.5, -100 * scaleFactor, 0.1, 0)
notification.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
notification.BorderSizePixel = 0
notification.Parent = Players.LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("ZXHELLSecurityTools")
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = notification
local border = Instance.new("UIStroke")
border.Thickness = 2
border.Color = color or Color3.fromRGB(0, 255, 255)
border.Parent = notification
local label = createLabel(notification, "NotificationLabel", message, UDim2.new(1, -10, 1, -10), UDim2.new(0, 5, 0, 5))
label.TextColor3 = Color3.fromRGB(255, 255, 255)
spawn(function()
wait(3)
for i = 1, 0, -0.1 do
notification.BackgroundTransparency = 1 - i
label.TextTransparency = 1 - i
border.Transparency = 1 - i
task.wait(0.05)
end
notification:Destroy()
end)
end

-- Handler Error Global
local function handleError(err)
logExploit("Error Sistem", "Gagal", tostring(err))
showNotification("Error: " .. tostring(err), Color3.fromRGB(255, 0, 0))
end

-- Contoh Pengujian Tambahan: Simulasi Serangan
local function simulateAttack()
local attackArgs = { string.rep("attack", 1000) }
for _, remote in ipairs(remoteList) do
testRemote(remote, attackArgs, "FloodTest")
end
logExploit("Simulasi Serangan", "Berhasil", "Menguji dengan argumen serangan besar")
end

-- Inisialisasi Tambahan
local function initialize()
logExploit("Inisialisasi", "Berhasil", "ZXHELL Security Tools dimulai")
showNotification("ZXHELL Security Tools Siap!", Color3.fromRGB(0, 255, 255))
checkPerformance()
end

initialize()

-- Catatan Pengembang
-- - Kode ini dioptimalkan untuk eksekutor seperti Synapse X atau Krnl
-- - UI mengikuti prinsip desain dari Roblox UI Guide dan Justinmind
-- - Untuk menambah fitur, tambahkan frame baru atau metode pengujian di methods
-- - Pastikan game memiliki RemoteEvents/Functions di ReplicatedStorage
-- - Gunakan hanya di game Anda sendiri untuk pengujian etis

-- Selesai
return "ZXHELL Security Tools v2.0 Loaded"
