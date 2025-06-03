-- TurtleSpy V1.5.3 (Enhanced by Gemini)
-- Credits to Intrer#0421 for the original script

local colorSettings =
{
    ["Main"] = {
        ["HeaderColor"] = Color3.fromRGB(0, 168, 255),
        ["HeaderShadingColor"] = Color3.fromRGB(0, 151, 230),
        ["HeaderTextColor"] = Color3.fromRGB(47, 54, 64),
        ["MainBackgroundColor"] = Color3.fromRGB(47, 54, 64),
        ["InfoScrollingFrameBgColor"] = Color3.fromRGB(47, 54, 64),
        ["ScrollBarImageColor"] = Color3.fromRGB(127, 143, 166),
        ["InputBackgroundColor"] = Color3.fromRGB(53, 59, 72), -- Warna baru untuk input
        ["InputBorderColor"] = Color3.fromRGB(113, 128, 147), -- Warna baru untuk border input
        ["InputTextColor"] = Color3.fromRGB(220, 221, 225) -- Warna baru untuk teks input
    },
    ["RemoteButtons"] = {
        ["BorderColor"] = Color3.fromRGB(113, 128, 147),
        ["BackgroundColor"] = Color3.fromRGB(53, 59, 72),
        ["TextColor"] = Color3.fromRGB(220, 221, 225),
        ["NumberTextColor"] = Color3.fromRGB(203, 204, 207)
    },
    ["MainButtons"] = { 
        ["BorderColor"] = Color3.fromRGB(113, 128, 147),
        ["BackgroundColor"] = Color3.fromRGB(53, 59, 72),
        ["TextColor"] = Color3.fromRGB(220, 221, 225)
    },
    ['Code'] = {
        ['BackgroundColor'] = Color3.fromRGB(35, 40, 48),
        ['TextColor'] = Color3.fromRGB(220, 221, 225),
        ['CreditsColor'] = Color3.fromRGB(108, 108, 108)
    },
}

local settings = {
    ["Keybind"] = "P",
    ["AutoScroll"] = true, -- Pengaturan baru: Auto scroll ke remote terbaru
    ["MaxDisplayedRemotes"] = 200 -- Pengaturan baru: Batas remote yang ditampilkan untuk performa
}

-- Layanan Roblox
local HttpService = game:GetService("HttpService")
local TextService = game:GetService("TextService")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService") -- Digunakan untuk keybinds yang lebih baik
local RunService = game:GetService("RunService") -- Untuk beberapa loop

-- Variabel Global
local client = Players.LocalPlayer
local mouse = client:GetMouse()
local executorName = "Unknown"
local isSynapseLoaded = false
local isProtoSmasherLoaded = false
local getThreadContextFunc = nil
local setThreadContextFunc = nil
local getNamecallMethodFunc = nil
local getCallingScriptFunc = nil
local decompileFunc = nil

-- Deteksi Executor dan Fungsi Spesifik
if syn and syn.protect_gui then -- Synapse X
    isSynapseLoaded = true
    executorName = "Synapse X"
    getThreadContextFunc = syn.get_thread_identity
    setThreadContextFunc = syn.set_thread_identity
    getNamecallMethodFunc = getnamecallmethod
    getCallingScriptFunc = getcallingscript
    decompileFunc = decompile
    ifisfile =isfile -- Synapse X sudah punya isfile global
    readfile = readfile
    writefile = writefile
elseif PROTOSMASHER_LOADED then -- ProtoSmasher
    isProtoSmasherLoaded = true
    executorName = "ProtoSmasher"
    -- ProtoSmasher mungkin memiliki nama fungsi yang berbeda atau tidak ada sama sekali
    -- Ini adalah placeholder, sesuaikan jika nama fungsinya diketahui
    getThreadContextFunc = get_thread_context 
    setThreadContextFunc = set_thread_context
    getNamecallMethodFunc = get_namecall_method
    getCallingScriptFunc = function() return getfenv(0).script end -- Perkiraan
    decompileFunc = function() return "-- Decompilation not supported on ProtoSmasher" end
    
    -- Fungsi file untuk ProtoSmasher
    getgenv().isfile = newcclosure(function(File)
        local Suc, Er = pcall(readfile, File)
        return Suc
    end)
    -- readfile dan writefile seharusnya sudah ada di global ProtoSmasher
else -- Executor lain atau tidak ada
    -- Fallback dasar jika fungsi spesifik executor tidak ditemukan
    warn("TurtleSpy: Executor tidak dikenal atau fungsi penting tidak ditemukan. Beberapa fitur mungkin tidak berfungsi.")
    getThreadContextFunc = function() return 7 end -- Default context
    setThreadContextFunc = function() end
    getNamecallMethodFunc = function() return "" end
    getCallingScriptFunc = function() return nil end
    decompileFunc = function() return "-- Decompilation not available" end
    
    -- Implementasi file I/O dasar jika tidak ada (mungkin tidak berfungsi di semua executor)
    if not isfile then
        getgenv().isfile = function(path)
            local success, _ = pcall(function() local f = io.open(path, "r") if f then f:close() return true else return false end end)
            return success
        end
    end
    if not readfile then
        getgenv().readfile = function(path)
            local success, result = pcall(function()
                local file = io.open(path, "r")
                if not file then return nil end
                local content = file:read("*a")
                file:close()
                return content
            end)
            return success and result or nil
        end
    end
    if not writefile then
        getgenv().writefile = function(path, content)
            local success, _ = pcall(function()
                local file = io.open(path, "w")
                if not file then return end
                file:write(content)
                file:close()
            end)
            return success
        end
    end
end


-- Muat atau buat file pengaturan
local settingsFileName = "TurtleSpySettings_v2.json"
if not isfile(settingsFileName) then
    local success, err = pcall(writefile, settingsFileName, HttpService:JSONEncode(settings))
    if not success then warn("TurtleSpy: Gagal menyimpan pengaturan awal:", err) end
else
    local success, currentSettingsJson = pcall(readfile, settingsFileName)
    if success and currentSettingsJson then
        local decodedSuccess, decodedSettings = pcall(HttpService.JSONDecode, HttpService, currentSettingsJson)
        if decodedSuccess then
            -- Gabungkan pengaturan yang ada dengan default untuk menambahkan kunci baru
            for k, v in pairs(settings) do
                if decodedSettings[k] == nil then
                    decodedSettings[k] = v
                end
            end
            settings = decodedSettings
            -- Simpan kembali jika ada kunci baru yang ditambahkan
            local resaveSuccess, resaveErr = pcall(writefile, settingsFileName, HttpService:JSONEncode(settings))
            if not resaveSuccess then warn("TurtleSpy: Gagal menyimpan ulang pengaturan:", resaveErr) end
        else
            warn("TurtleSpy: Gagal mendekode pengaturan, menggunakan default:", decodedSettings)
            local backupSuccess, backupErr = pcall(writefile, settingsFileName .. ".backup", currentSettingsJson)
            if not backupSuccess then warn("TurtleSpy: Gagal membuat backup pengaturan rusak:", backupErr) end
            local rewriteSuccess, rewriteErr = pcall(writefile, settingsFileName, HttpService:JSONEncode(settings))
            if not rewriteSuccess then warn("TurtleSpy: Gagal menulis ulang pengaturan dengan default:", rewriteErr) end
        end
    else
        warn("TurtleSpy: Gagal membaca file pengaturan, menggunakan default:", currentSettingsJson)
        local rewriteSuccess, rewriteErr = pcall(writefile, settingsFileName, HttpService:JSONEncode(settings))
        if not rewriteSuccess then warn("TurtleSpy: Gagal menulis ulang pengaturan dengan default:", rewriteErr) end
    end
end

-- Fungsi Utilitas
local function toUnicode(str)
    if not str then return "utf8.char()" end
    local codepoints = "utf8.char("
    local success, codes = pcall(utf8.codes, str)
    if not success or not codes then return "utf8.char()" end
    
    for _i, v in ipairs(codes) do
        codepoints = codepoints .. v .. ', '
    end
    
    return codepoints:sub(1, -3) .. ')'
end

local function GetFullPathOfAnInstance(instance)
    if not instance or not instance.Parent then
        if instance == game then return "game" end
        if instance == workspace then return "workspace" end
        if instance == CoreGui then return "game:GetService('CoreGui')" end
        if instance == Players then return "game:GetService('Players')" end
        if instance == client and client == Players.LocalPlayer then return "game:GetService('Players').LocalPlayer" end
        return (instance and instance.Name or "nil") .. " --[[ PARENTED TO NIL OR DESTROYED ]]"
    end

    local path = instance.Name
    local current = instance
    while current.Parent do
        if current.Parent == game then
            path = "game." .. path
            break
        elseif current.Parent == workspace then
            path = "workspace." .. path
            break
        else
            local parentName = current.Parent.Name
            local isServiceName = false
            local successGetService, service = pcall(game.GetService, game, current.Parent.ClassName)
            if successGetService and service == current.Parent then
                 parentName = 'GetService("' .. current.Parent.ClassName .. '")'
                 isServiceName = true
            else
                if string.match(parentName, "^[%w_]+$") then -- Hanya alphanumeric dan underscore
                    -- aman
                else
                    parentName = '["' .. parentName:gsub('"', '\\"'):gsub('\\', '\\\\') .. '"]'
                end
            end
            path = parentName .. (isServiceName and "" or ".") .. path
        end
        current = current.Parent
    end
    return path
end


-- Hapus instance TurtleSpyGUI sebelumnya
pcall(function()
    if CoreGui:FindFirstChild("TurtleSpyGUI_V2") then
        CoreGui.TurtleSpyGUI_V2:Destroy()
    end
end)

-- Variabel dan Tabel Penting GUI
local buttonOffset = -25
local scrollSizeOffset = 287 -- Ukuran default canvas scroll
local functionImage = "http://www.roblox.com/asset/?id=413369623"
local eventImage = "http://www.roblox.com/asset/?id=413369506"
local remotes = {} -- Menyimpan instance remote asli
local remoteData = {} -- Menyimpan data terkait remote (args, script, count, button, dll)
local remoteButtons = {} -- Menyimpan referensi ke tombol GUI untuk setiap remote unik
local IgnoreList = {} -- Daftar remote yang diabaikan
local BlockList = {} -- Daftar remote yang diblokir
local unstackedRemotes = {} -- Daftar remote yang tidak di-stack
local activeConnections = {} -- Menyimpan koneksi event GUI untuk pembersihan

-- GUI Elements (Sebagian besar dihasilkan, dengan tambahan baru)
local TurtleSpyGUI = Instance.new("ScreenGui")
local mainFrame = Instance.new("Frame")
local Header = Instance.new("Frame")
local HeaderShading = Instance.new("Frame")
local HeaderTextLabel = Instance.new("TextLabel")
local RemoteScrollFrame = Instance.new("ScrollingFrame")
local RemoteButtonTemplate = Instance.new("TextButton") -- Template, jangan diparent
local NumberLabelTemplate = Instance.new("TextLabel")
local RemoteNameLabelTemplate = Instance.new("TextLabel")
local RemoteIconTemplate = Instance.new("ImageLabel")

local InfoFrame = Instance.new("Frame")
local InfoFrameHeader = Instance.new("Frame")
local InfoTitleShading = Instance.new("Frame")
local InfoHeaderText = Instance.new("TextLabel")
local CloseInfoFrameButton = Instance.new("TextButton")

local CodeFrame = Instance.new("ScrollingFrame")
local CodeTextLabel = Instance.new("TextLabel")
local CodeCommentTextLabel = Instance.new("TextLabel")

local ArgumentEditorFrame = Instance.new("Frame") -- Frame untuk editor argumen
local ArgumentEditorLabel = Instance.new("TextLabel")
local ArgumentEditorTextBox = Instance.new("TextBox") -- TextBox untuk mengedit argumen
local ApplyArgumentsButton = Instance.new("TextButton") -- Tombol untuk menerapkan argumen yang diedit

local InfoButtonsScroll = Instance.new("ScrollingFrame")
local CopyCodeButton = Instance.new("TextButton")
local RunCodeButton = Instance.new("TextButton")
local CopyScriptPathButton = Instance.new("TextButton")
local CopyDecompiledButton = Instance.new("TextButton")
local IgnoreRemoteButton = Instance.new("TextButton")
local BlockRemoteButton = Instance.new("TextButton")
local WhileLoopButton = Instance.new("TextButton")
local CopyReturnValueButton = Instance.new("TextButton")
local ClearLogsButton = Instance.new("TextButton")
local UnstackRemoteButton = Instance.new("TextButton")
local CopyFullPathButton = Instance.new("TextButton") -- Tombol baru

local OpenInfoFrameButton = Instance.new("TextButton")
local MinimizeButton = Instance.new("TextButton")
local FrameDivider = Instance.new("Frame")

-- Fitur Tambahan GUI
local FilterTextBox = Instance.new("TextBox") -- Kotak filter
local SaveSessionButton = Instance.new("TextButton")
local LoadSessionButton = Instance.new("TextButton")
local UnstackAllButton = Instance.new("TextButton") -- Tombol baru

-- Pengaturan Hook GUI
local HookSettingsFrame = Instance.new("Frame")
local ToggleFireServerHookButton = Instance.new("TextButton")
local ToggleInvokeServerHookButton = Instance.new("TextButton")
local ToggleNamecallHookButton = Instance.new("TextButton")

-- Remote browser (seperti aslinya, dengan sedikit perbaikan)
local BrowserHeader = Instance.new("Frame")
local BrowserHeaderFrame = Instance.new("Frame")
local BrowserHeaderText = Instance.new("TextLabel")
local CloseBrowserButton = Instance.new("TextButton")
local RemoteBrowserFrame = Instance.new("ScrollingFrame")
local RemoteButtonBrowserTemplate = Instance.new("TextButton")
local RemoteNameBrowserTemplate = Instance.new("TextLabel")
local RemoteIconBrowserTemplate = Instance.new("ImageLabel")
local OpenBrowserButton = Instance.new("ImageButton") -- Tombol untuk membuka browser

-- Fungsi Parent GUI yang Ditingkatkan
local function ParentGUI(guiInstance)
    if isSynapseLoaded and syn.protect_gui then
        syn.protect_gui(guiInstance)
        guiInstance.Parent = CoreGui
    elseif isProtoSmasherLoaded and get_hidden_gui then
        guiInstance.Parent = get_hidden_gui()
    else
        guiInstance.Parent = CoreGui -- Fallback ke CoreGui
    end
end

-- Inisialisasi GUI Utama
TurtleSpyGUI.Name = "TurtleSpyGUI_V2"
TurtleSpyGUI.ResetPlayerGuiOnSpawn = false
TurtleSpyGUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling -- Untuk konsistensi ZIndex
ParentGUI(TurtleSpyGUI)

-- Fungsi untuk membuat UI (untuk menjaga kerapian)
local function CreateUI()
    mainFrame.Name = "mainFrame"
    mainFrame.Parent = TurtleSpyGUI
    mainFrame.BackgroundColor3 = colorSettings["Main"]["MainBackgroundColor"]
    mainFrame.BorderColor3 = colorSettings["Main"]["HeaderShadingColor"] -- Sedikit border
    mainFrame.BorderSizePixel = 1
    mainFrame.Position = UDim2.new(0.1, 0, 0.15, 0) -- Posisi awal yang lebih baik
    mainFrame.Size = UDim2.new(0, 220, 0, 35) -- Sedikit lebih lebar
    mainFrame.ZIndex = 1000
    mainFrame.Active = true
    mainFrame.Draggable = true

    Header.Name = "Header"
    Header.Parent = mainFrame
    Header.BackgroundColor3 = colorSettings["Main"]["HeaderColor"]
    Header.BorderSizePixel = 0
    Header.Size = UDim2.new(1, 0, 0, 26)
    Header.ZIndex = 1001

    HeaderShading.Name = "HeaderShading" -- Ini sebenarnya background untuk teks header
    HeaderShading.Parent = Header
    HeaderShading.BackgroundColor3 = colorSettings["Main"]["HeaderShadingColor"]
    HeaderShading.BorderSizePixel = 0
    HeaderShading.Position = UDim2.new(0, 0, 1, -1) -- Bayangan tipis di bawah header
    HeaderShading.Size = UDim2.new(1, 0, 0, 1)
    HeaderShading.ZIndex = 1000 -- Di bawah teks header

    HeaderTextLabel.Name = "HeaderTextLabel"
    HeaderTextLabel.Parent = Header
    HeaderTextLabel.BackgroundTransparency = 1.000
    HeaderTextLabel.Size = UDim2.new(1, -80, 1, 0) -- Sisakan ruang untuk tombol
    HeaderTextLabel.Position = UDim2.new(0, 5, 0, 0)
    HeaderTextLabel.ZIndex = 1002
    HeaderTextLabel.Font = Enum.Font.SourceSansSemibold
    HeaderTextLabel.Text = "TurtleSpy V2"
    HeaderTextLabel.TextColor3 = colorSettings["Main"]["HeaderTextColor"]
    HeaderTextLabel.TextSize = 16.000
    HeaderTextLabel.TextXAlignment = Enum.TextXAlignment.Left

    -- Tombol Minimize, OpenInfo, OpenBrowser di Header
    MinimizeButton.Name = "MinimizeButton"
    MinimizeButton.Parent = Header
    MinimizeButton.BackgroundColor3 = colorSettings["Main"]["HeaderColor"]
    MinimizeButton.BorderSizePixel = 0
    MinimizeButton.Position = UDim2.new(1, -75, 0, 2)
    MinimizeButton.Size = UDim2.new(0, 22, 0, 22)
    MinimizeButton.ZIndex = 1003
    MinimizeButton.Font = Enum.Font.SourceSansLight
    MinimizeButton.Text = "_"
    MinimizeButton.TextColor3 = colorSettings["Main"]["HeaderTextColor"]
    MinimizeButton.TextSize = 20.000

    OpenInfoFrameButton.Name = "OpenInfoFrameButton"
    OpenInfoFrameButton.Parent = Header
    OpenInfoFrameButton.BackgroundColor3 = colorSettings["Main"]["HeaderColor"]
    OpenInfoFrameButton.BorderSizePixel = 0
    OpenInfoFrameButton.Position = UDim2.new(1, -50, 0, 2)
    OpenInfoFrameButton.Size = UDim2.new(0, 22, 0, 22)
    OpenInfoFrameButton.ZIndex = 1003
    OpenInfoFrameButton.Font = Enum.Font.SourceSans
    OpenInfoFrameButton.Text = ">"
    OpenInfoFrameButton.TextColor3 = colorSettings["Main"]["HeaderTextColor"]
    OpenInfoFrameButton.TextSize = 18.000
    
    OpenBrowserButton.Name = "OpenBrowserButton"
    OpenBrowserButton.Parent = Header
    OpenBrowserButton.BackgroundColor3 = colorSettings["Main"]["HeaderColor"]
    OpenBrowserButton.BackgroundTransparency = 0.5
    OpenBrowserButton.BorderSizePixel = 0
    OpenBrowserButton.Position = UDim2.new(1, -25, 0, 2)
    OpenBrowserButton.Size = UDim2.new(0, 22, 0, 22)
    OpenBrowserButton.ZIndex = 1003
    OpenBrowserButton.Image = "rbxassetid://169476802" -- Icon kaca pembesar
    OpenBrowserButton.ImageColor3 = colorSettings["Main"]["HeaderTextColor"]
    OpenBrowserButton.ScaleType = Enum.ScaleType.Fit

    -- Filter TextBox
    FilterTextBox.Name = "FilterTextBox"
    FilterTextBox.Parent = mainFrame
    FilterTextBox.BackgroundColor3 = colorSettings["Main"]["InputBackgroundColor"]
    FilterTextBox.BorderColor3 = colorSettings["Main"]["InputBorderColor"]
    FilterTextBox.Position = UDim2.new(0.05, 0, 1, 5) -- Di bawah header
    FilterTextBox.Size = UDim2.new(0.9, 0, 0, 25)
    FilterTextBox.ZIndex = 1001
    FilterTextBox.Font = Enum.Font.SourceSans
    FilterTextBox.PlaceholderText = "Filter berdasarkan nama..."
    FilterTextBox.TextColor3 = colorSettings["Main"]["InputTextColor"]
    FilterTextBox.TextSize = 14.000
    FilterTextBox.ClearTextOnFocus = false

    RemoteScrollFrame.Name = "RemoteScrollFrame"
    RemoteScrollFrame.Parent = mainFrame
    RemoteScrollFrame.Active = true
    RemoteScrollFrame.BackgroundColor3 = colorSettings["Main"]["MainBackgroundColor"]
    RemoteScrollFrame.BorderColor3 = colorSettings["Main"]["HeaderShadingColor"]
    RemoteScrollFrame.BorderSizePixel = 1
    RemoteScrollFrame.Position = UDim2.new(0, 0, 1, 35) -- Di bawah filter box
    RemoteScrollFrame.Size = UDim2.new(1, 0, 0, 286) -- Ukuran default
    RemoteScrollFrame.CanvasSize = UDim2.new(0, 0, 0, scrollSizeOffset)
    RemoteScrollFrame.ScrollBarThickness = 8
    RemoteScrollFrame.VerticalScrollBarPosition = Enum.VerticalScrollBarPosition.Left
    RemoteScrollFrame.ScrollBarImageColor3 = colorSettings["Main"]["ScrollBarImageColor"]
    RemoteScrollFrame.ZIndex = 1000

    -- Template untuk Tombol Remote (tidak diparent, hanya untuk clone)
    RemoteButtonTemplate.Name = "RemoteButtonTemplate"
    RemoteButtonTemplate.BackgroundColor3 = colorSettings["RemoteButtons"]["BackgroundColor"]
    RemoteButtonTemplate.BorderColor3 = colorSettings["RemoteButtons"]["BorderColor"]
    RemoteButtonTemplate.Size = UDim2.new(1, -10, 0, 28) -- Lebih tinggi sedikit
    RemoteButtonTemplate.Font = Enum.Font.SourceSans
    RemoteButtonTemplate.Text = ""
    RemoteButtonTemplate.TextColor3 = colorSettings["RemoteButtons"]["TextColor"]
    RemoteButtonTemplate.TextSize = 1.000 -- Teks utama tidak terlihat, info di label anak
    RemoteButtonTemplate.TextWrapped = true
    RemoteButtonTemplate.TextXAlignment = Enum.TextXAlignment.Left
    RemoteButtonTemplate.ZIndex = 1001

    NumberLabelTemplate.Name = "NumberLabel"
    NumberLabelTemplate.Parent = RemoteButtonTemplate
    NumberLabelTemplate.BackgroundTransparency = 1.000
    NumberLabelTemplate.Position = UDim2.new(0, 5, 0, 0)
    NumberLabelTemplate.Size = UDim2.new(0, 30, 1, 0) -- Lebar dinamis nanti
    NumberLabelTemplate.ZIndex = 1002
    NumberLabelTemplate.Font = Enum.Font.SourceSans
    NumberLabelTemplate.Text = "1"
    NumberLabelTemplate.TextColor3 = colorSettings["RemoteButtons"]["NumberTextColor"]
    NumberLabelTemplate.TextSize = 15.000
    NumberLabelTemplate.TextXAlignment = Enum.TextXAlignment.Left

    RemoteNameLabelTemplate.Name = "RemoteNameLabel"
    RemoteNameLabelTemplate.Parent = RemoteButtonTemplate
    RemoteNameLabelTemplate.BackgroundTransparency = 1.000
    RemoteNameLabelTemplate.Position = UDim2.new(0, 30, 0, 0) -- Disesuaikan berdasarkan NumberLabel
    RemoteNameLabelTemplate.Size = UDim2.new(1, -60, 1, 0) -- Sisa ruang dikurangi ikon
    RemoteNameLabelTemplate.Font = Enum.Font.SourceSansSemibold
    RemoteNameLabelTemplate.Text = "RemoteEventName"
    RemoteNameLabelTemplate.TextColor3 = colorSettings["RemoteButtons"]["TextColor"]
    RemoteNameLabelTemplate.TextSize = 15.000
    RemoteNameLabelTemplate.TextXAlignment = Enum.TextXAlignment.Left
    RemoteNameLabelTemplate.TextTruncate = Enum.TextTruncate.AtEnd

    RemoteIconTemplate.Name = "RemoteIcon"
    RemoteIconTemplate.Parent = RemoteButtonTemplate
    RemoteIconTemplate.BackgroundTransparency = 1.000
    RemoteIconTemplate.Position = UDim2.new(1, -28, 0.5, -12) -- Kanan tengah
    RemoteIconTemplate.Size = UDim2.new(0, 24, 0, 24)
    RemoteIconTemplate.ZIndex = 1002
    RemoteIconTemplate.Image = eventImage -- Default event

    -- Info Frame
    InfoFrame.Name = "InfoFrame"
    InfoFrame.Parent = mainFrame
    InfoFrame.BackgroundColor3 = colorSettings["Main"]["InfoScrollingFrameBgColor"]
    InfoFrame.BorderColor3 = colorSettings["Main"]["HeaderShadingColor"]
    InfoFrame.BorderSizePixel = 1
    InfoFrame.Position = UDim2.new(1, 5, 0, 0) -- Di kanan mainFrame
    InfoFrame.Size = UDim2.new(0, 380, 1, 0) -- Ukuran lebih besar untuk info
    InfoFrame.Visible = false
    InfoFrame.ZIndex = 999 -- Di bawah mainFrame jika tidak aktif, di atas jika aktif
    InfoFrame.ClipsDescendants = true

    InfoFrameHeader.Name = "InfoFrameHeader"
    InfoFrameHeader.Parent = InfoFrame
    InfoFrameHeader.BackgroundColor3 = colorSettings["Main"]["HeaderColor"]
    InfoFrameHeader.BorderSizePixel = 0
    InfoFrameHeader.Size = UDim2.new(1, 0, 0, 26)
    InfoFrameHeader.ZIndex = 1011

    InfoTitleShading.Name = "InfoTitleShading" -- Background untuk teks header info
    InfoTitleShading.Parent = InfoFrameHeader
    InfoTitleShading.BackgroundColor3 = colorSettings["Main"]["HeaderShadingColor"]
    InfoTitleShading.BorderSizePixel = 0
    InfoTitleShading.Position = UDim2.new(0,0,1,-1)
    InfoTitleShading.Size = UDim2.new(1, 0, 0, 1)
    InfoTitleShading.ZIndex = 1010

    InfoHeaderText.Name = "InfoHeaderText"
    InfoHeaderText.Parent = InfoFrameHeader
    InfoHeaderText.BackgroundTransparency = 1.000
    InfoHeaderText.Size = UDim2.new(1, -30, 1, 0)
    InfoHeaderText.Position = UDim2.new(0,5,0,0)
    InfoHeaderText.ZIndex = 1012
    InfoHeaderText.Font = Enum.Font.SourceSansSemibold
    InfoHeaderText.Text = "Info: RemoteName"
    InfoHeaderText.TextColor3 = colorSettings["Main"]["HeaderTextColor"]
    InfoHeaderText.TextSize = 16.000
    InfoHeaderText.TextXAlignment = Enum.TextXAlignment.Left

    CloseInfoFrameButton.Name = "CloseInfoFrameButton"
    CloseInfoFrameButton.Parent = InfoFrameHeader
    CloseInfoFrameButton.BackgroundColor3 = colorSettings["Main"]["HeaderColor"]
    CloseInfoFrameButton.BorderSizePixel = 0
    CloseInfoFrameButton.Position = UDim2.new(1, -25, 0, 2)
    CloseInfoFrameButton.Size = UDim2.new(0, 22, 0, 22)
    CloseInfoFrameButton.ZIndex = 1013
    CloseInfoFrameButton.Font = Enum.Font.SourceSansLight
    CloseInfoFrameButton.Text = "X"
    CloseInfoFrameButton.TextColor3 = colorSettings["Main"]["HeaderTextColor"]
    CloseInfoFrameButton.TextSize = 20.000

    CodeFrame.Name = "CodeFrame"
    CodeFrame.Parent = InfoFrame
    CodeFrame.Active = true
    CodeFrame.BackgroundColor3 = colorSettings["Code"]["BackgroundColor"]
    CodeFrame.BorderColor3 = colorSettings["Main"]["HeaderShadingColor"]
    CodeFrame.BorderSizePixel = 1
    CodeFrame.Position = UDim2.new(0.025, 0, 0, 30)
    CodeFrame.Size = UDim2.new(0.95, 0, 0, 65)
    CodeFrame.ZIndex = 1010
    CodeFrame.CanvasSize = UDim2.new(2, 0, 1, 0) -- Horizontal scroll
    CodeFrame.ScrollBarThickness = 6
    CodeFrame.ScrollingDirection = Enum.ScrollingDirection.X
    CodeFrame.ScrollBarImageColor3 = colorSettings["Main"]["ScrollBarImageColor"]

    CodeCommentTextLabel.Name = "CodeCommentTextLabel"
    CodeCommentTextLabel.Parent = CodeFrame
    CodeCommentTextLabel.BackgroundTransparency = 1.000
    CodeCommentTextLabel.Position = UDim2.new(0, 5, 0, 2)
    CodeCommentTextLabel.Size = UDim2.new(0, 10000, 0, 18) -- Sangat lebar untuk teks panjang
    CodeCommentTextLabel.ZIndex = 1011
    CodeCommentTextLabel.Font = Enum.Font.Code -- Font Monospace
    CodeCommentTextLabel.Text = "-- Script generated by TurtleSpy V2, enhanced by Gemini. Original by Intrer#0421"
    CodeCommentTextLabel.TextColor3 = colorSettings["Code"]["CreditsColor"]
    CodeCommentTextLabel.TextSize = 13.000
    CodeCommentTextLabel.TextXAlignment = Enum.TextXAlignment.Left

    CodeTextLabel.Name = "CodeTextLabel"
    CodeTextLabel.Parent = CodeFrame
    CodeTextLabel.BackgroundTransparency = 1.000
    CodeTextLabel.Position = UDim2.new(0, 5, 0, 20)
    CodeTextLabel.Size = UDim2.new(0, 10000, 0, 40) -- Tinggi disesuaikan
    CodeTextLabel.ZIndex = 1011
    CodeTextLabel.Font = Enum.Font.Code
    CodeTextLabel.Text = "game:GetService('ReplicatedStorage').RemoteEvent:FireServer(...)"
    CodeTextLabel.TextColor3 = colorSettings["Code"]["TextColor"]
    CodeTextLabel.TextSize = 14.000
    CodeTextLabel.TextWrapped = false -- Biarkan horizontal scroll menangani
    CodeTextLabel.TextXAlignment = Enum.TextXAlignment.Left
    CodeTextLabel.ClipsDescendants = false

    -- Argument Editor Frame
    ArgumentEditorFrame.Name = "ArgumentEditorFrame"
    ArgumentEditorFrame.Parent = InfoFrame
    ArgumentEditorFrame.BackgroundColor3 = colorSettings["Code"]["BackgroundColor"]
    ArgumentEditorFrame.BorderColor3 = colorSettings["Main"]["HeaderShadingColor"]
    ArgumentEditorFrame.BorderSizePixel = 1
    ArgumentEditorFrame.Position = UDim2.new(0.025, 0, 0, 100) -- Di bawah CodeFrame
    ArgumentEditorFrame.Size = UDim2.new(0.95, 0, 0, 100) -- Ukuran untuk editor
    ArgumentEditorFrame.ZIndex = 1010
    ArgumentEditorFrame.Visible = true -- Selalu terlihat jika InfoFrame visible

    ArgumentEditorLabel.Name = "ArgumentEditorLabel"
    ArgumentEditorLabel.Parent = ArgumentEditorFrame
    ArgumentEditorLabel.BackgroundTransparency = 1.0
    ArgumentEditorLabel.Size = UDim2.new(1, -10, 0, 20)
    ArgumentEditorLabel.Position = UDim2.new(0, 5, 0, 0)
    ArgumentEditorLabel.Font = Enum.Font.SourceSansSemibold
    ArgumentEditorLabel.Text = "Edit Argumen (format Lua table):"
    ArgumentEditorLabel.TextColor3 = colorSettings["Code"]["TextColor"]
    ArgumentEditorLabel.TextSize = 14.000
    ArgumentEditorLabel.TextXAlignment = Enum.TextXAlignment.Left
    ArgumentEditorLabel.ZIndex = 1011

    ArgumentEditorTextBox.Name = "ArgumentEditorTextBox"
    ArgumentEditorTextBox.Parent = ArgumentEditorFrame
    ArgumentEditorTextBox.BackgroundColor3 = colorSettings["Main"]["InputBackgroundColor"]
    ArgumentEditorTextBox.BorderColor3 = colorSettings["Main"]["InputBorderColor"]
    ArgumentEditorTextBox.Position = UDim2.new(0.025, 0, 0, 20)
    ArgumentEditorTextBox.Size = UDim2.new(0.95, 0, 1, -50) -- Sisa ruang dikurangi tombol
    ArgumentEditorTextBox.ZIndex = 1011
    ArgumentEditorTextBox.Font = Enum.Font.Code
    ArgumentEditorTextBox.Text = "{}"
    ArgumentEditorTextBox.TextColor3 = colorSettings["Main"]["InputTextColor"]
    ArgumentEditorTextBox.TextSize = 13.000
    ArgumentEditorTextBox.TextWrapped = true
    ArgumentEditorTextBox.TextXAlignment = Enum.TextXAlignment.Left
    ArgumentEditorTextBox.TextYAlignment = Enum.TextYAlignment.Top
    ArgumentEditorTextBox.MultiLine = true
    ArgumentEditorTextBox.ClearTextOnFocus = false

    ApplyArgumentsButton.Name = "ApplyArgumentsButton"
    ApplyArgumentsButton.Parent = ArgumentEditorFrame
    ApplyArgumentsButton.BackgroundColor3 = colorSettings["MainButtons"]["BackgroundColor"]
    ApplyArgumentsButton.BorderColor3 = colorSettings["MainButtons"]["BorderColor"]
    ApplyArgumentsButton.Position = UDim2.new(0.5, -50, 1, -28) -- Di bawah TextBox
    ApplyArgumentsButton.Size = UDim2.new(0, 100, 0, 22)
    ApplyArgumentsButton.ZIndex = 1012
    ApplyArgumentsButton.Font = Enum.Font.SourceSans
    ApplyArgumentsButton.Text = "Terapkan & Jalankan"
    ApplyArgumentsButton.TextColor3 = colorSettings["MainButtons"]["TextColor"]
    ApplyArgumentsButton.TextSize = 13.000

    -- Info Buttons Scroll
    InfoButtonsScroll.Name = "InfoButtonsScroll"
    InfoButtonsScroll.Parent = InfoFrame
    InfoButtonsScroll.Active = true
    InfoButtonsScroll.BackgroundColor3 = colorSettings["Main"]["InfoScrollingFrameBgColor"]
    InfoButtonsScroll.BorderSizePixel = 0
    InfoButtonsScroll.Position = UDim2.new(0.025, 0, 0, 205) -- Di bawah ArgumentEditorFrame
    InfoButtonsScroll.Size = UDim2.new(0.95, 0, 1, -210) -- Sisa ruang
    InfoButtonsScroll.ZIndex = 1009
    InfoButtonsScroll.CanvasSize = UDim2.new(0, 0, 2, 0) -- Dibuat lebih panjang untuk banyak tombol
    InfoButtonsScroll.ScrollBarThickness = 8
    InfoButtonsScroll.VerticalScrollBarPosition = Enum.VerticalScrollBarPosition.Left
    InfoButtonsScroll.ScrollBarImageColor3 = colorSettings["Main"]["ScrollBarImageColor"]

    local buttonYOffset = 10
    local buttonHeight = 28
    local buttonSpacing = 8

    local function createInfoButton(name, text, yPos)
        local button = Instance.new("TextButton")
        button.Name = name
        button.Parent = InfoButtonsScroll
        button.BackgroundColor3 = colorSettings["MainButtons"]["BackgroundColor"]
        button.BorderColor3 = colorSettings["MainButtons"]["BorderColor"]
        button.Position = UDim2.new(0.05, 0, 0, yPos)
        button.Size = UDim2.new(0.9, 0, 0, buttonHeight)
        button.ZIndex = 1010
        button.Font = Enum.Font.SourceSans
        button.Text = text
        button.TextColor3 = colorSettings["MainButtons"]["TextColor"]
        button.TextSize = 14.000
        return button
    end

    CopyCodeButton = createInfoButton("CopyCodeButton", "Salin Kode", buttonYOffset)
    buttonYOffset = buttonYOffset + buttonHeight + buttonSpacing
    RunCodeButton = createInfoButton("RunCodeButton", "Jalankan Kode Asli", buttonYOffset) -- Diubah teksnya
    buttonYOffset = buttonYOffset + buttonHeight + buttonSpacing
    CopyScriptPathButton = createInfoButton("CopyScriptPathButton", "Salin Path Script Pemanggil", buttonYOffset)
    buttonYOffset = buttonYOffset + buttonHeight + buttonSpacing
    CopyDecompiledButton = createInfoButton("CopyDecompiledButton", "Salin Script Decompiled", buttonYOffset)
    buttonYOffset = buttonYOffset + buttonHeight + buttonSpacing
    CopyFullPathButton = createInfoButton("CopyFullPathButton", "Salin Path Instance Remote", buttonYOffset)
    buttonYOffset = buttonYOffset + buttonHeight + buttonSpacing
    IgnoreRemoteButton = createInfoButton("IgnoreRemoteButton", "Abaikan Remote Ini", buttonYOffset)
    buttonYOffset = buttonYOffset + buttonHeight + buttonSpacing
    BlockRemoteButton = createInfoButton("BlockRemoteButton", "Blokir Remote Ini", buttonYOffset)
    buttonYOffset = buttonYOffset + buttonHeight + buttonSpacing
    UnstackRemoteButton = createInfoButton("UnstackRemoteButton", "Unstack Remote (Argumen Baru)", buttonYOffset)
    buttonYOffset = buttonYOffset + buttonHeight + buttonSpacing
    WhileLoopButton = createInfoButton("WhileLoopButton", "Buat Skrip While Loop", buttonYOffset)
    buttonYOffset = buttonYOffset + buttonHeight + buttonSpacing
    CopyReturnValueButton = createInfoButton("CopyReturnValueButton", "Jalankan & Salin Return (Fungsi)", buttonYOffset)
    CopyReturnValueButton.Visible = false -- Hanya untuk RemoteFunction
    
    -- Tombol global di bawah RemoteScrollFrame
    local globalButtonY = 5
    ClearLogsButton.Name = "ClearLogsButton"
    ClearLogsButton.Parent = mainFrame
    ClearLogsButton.BackgroundColor3 = colorSettings["MainButtons"]["BackgroundColor"]
    ClearLogsButton.BorderColor3 = colorSettings["MainButtons"]["BorderColor"]
    ClearLogsButton.Position = UDim2.new(0.05, 0, 1, RemoteScrollFrame.Size.Y.Offset + FilterTextBox.Size.Y.Offset + globalButtonY + 40)
    ClearLogsButton.Size = UDim2.new(0.425, -5, 0, 25)
    ClearLogsButton.ZIndex = 1001
    ClearLogsButton.Font = Enum.Font.SourceSans
    ClearLogsButton.Text = "Bersihkan Log"
    ClearLogsButton.TextColor3 = colorSettings["MainButtons"]["TextColor"]
    ClearLogsButton.TextSize = 13.000

    UnstackAllButton.Name = "UnstackAllButton"
    UnstackAllButton.Parent = mainFrame
    UnstackAllButton.BackgroundColor3 = colorSettings["MainButtons"]["BackgroundColor"]
    UnstackAllButton.BorderColor3 = colorSettings["MainButtons"]["BorderColor"]
    UnstackAllButton.Position = UDim2.new(0.525, 0, 1, RemoteScrollFrame.Size.Y.Offset + FilterTextBox.Size.Y.Offset + globalButtonY + 40)
    UnstackAllButton.Size = UDim2.new(0.425, -5, 0, 25)
    UnstackAllButton.ZIndex = 1001
    UnstackAllButton.Font = Enum.Font.SourceSans
    UnstackAllButton.Text = "Unstack Semua"
    UnstackAllButton.TextColor3 = colorSettings["MainButtons"]["TextColor"]
    UnstackAllButton.TextSize = 13.000
    
    globalButtonY = globalButtonY + 25 + 5

    SaveSessionButton.Name = "SaveSessionButton"
    SaveSessionButton.Parent = mainFrame
    SaveSessionButton.BackgroundColor3 = colorSettings["MainButtons"]["BackgroundColor"]
    SaveSessionButton.BorderColor3 = colorSettings["MainButtons"]["BorderColor"]
    SaveSessionButton.Position = UDim2.new(0.05, 0, 1, RemoteScrollFrame.Size.Y.Offset + FilterTextBox.Size.Y.Offset + globalButtonY + 40)
    SaveSessionButton.Size = UDim2.new(0.425, -5, 0, 25)
    SaveSessionButton.ZIndex = 1001
    SaveSessionButton.Font = Enum.Font.SourceSans
    SaveSessionButton.Text = "Simpan Sesi"
    SaveSessionButton.TextColor3 = colorSettings["MainButtons"]["TextColor"]
    SaveSessionButton.TextSize = 13.000

    LoadSessionButton.Name = "LoadSessionButton"
    LoadSessionButton.Parent = mainFrame
    LoadSessionButton.BackgroundColor3 = colorSettings["MainButtons"]["BackgroundColor"]
    LoadSessionButton.BorderColor3 = colorSettings["MainButtons"]["BorderColor"]
    LoadSessionButton.Position = UDim2.new(0.525, 0, 1, RemoteScrollFrame.Size.Y.Offset + FilterTextBox.Size.Y.Offset + globalButtonY + 40)
    LoadSessionButton.Size = UDim2.new(0.425, -5, 0, 25)
    LoadSessionButton.ZIndex = 1001
    LoadSessionButton.Font = Enum.Font.SourceSans
    LoadSessionButton.Text = "Muat Sesi"
    LoadSessionButton.TextColor3 = colorSettings["MainButtons"]["TextColor"]
    LoadSessionButton.TextSize = 13.000

    globalButtonY = globalButtonY + 25 + 10 -- Spasi untuk Hook Settings

    -- Hook Settings Frame (di bawah tombol global)
    HookSettingsFrame.Name = "HookSettingsFrame"
    HookSettingsFrame.Parent = mainFrame
    HookSettingsFrame.BackgroundTransparency = 1.0
    HookSettingsFrame.Position = UDim2.new(0.05, 0, 1, RemoteScrollFrame.Size.Y.Offset + FilterTextBox.Size.Y.Offset + globalButtonY + 40)
    HookSettingsFrame.Size = UDim2.new(0.9, 0, 0, 30)
    HookSettingsFrame.ZIndex = 1001
    HookSettingsFrame.Layout = Enum.FillDirection.Horizontal
    HookSettingsFrame.LayoutOrder = 1
    local ListLayout = Instance.new("UIListLayout", HookSettingsFrame)
    ListLayout.FillDirection = Enum.FillDirection.Horizontal
    ListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    ListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    ListLayout.Padding = UDim.new(0, 5)


    local function createHookToggleButton(name, text, initialActive)
        local button = Instance.new("TextButton")
        button.Name = name
        button.Parent = HookSettingsFrame
        button.BackgroundColor3 = initialActive and Color3.fromRGB(76, 209, 55) or colorSettings["MainButtons"]["BackgroundColor"]
        button.BorderColor3 = colorSettings["MainButtons"]["BorderColor"]
        button.Size = UDim2.new(0.31, 0, 1, 0) -- Bagi rata
        button.Font = Enum.Font.SourceSans
        button.Text = text .. (initialActive and " (Aktif)" or " (Nonaktif)")
        button.TextColor3 = colorSettings["MainButtons"]["TextColor"]
        button.TextSize = 11.000
        button.ZIndex = 1002
        button._isActive = initialActive -- Properti custom
        return button
    end

    ToggleFireServerHookButton = createHookToggleButton("ToggleFireServerHook", "FireServer", true)
    ToggleInvokeServerHookButton = createHookToggleButton("ToggleInvokeServerHook", "InvokeServer", true)
    ToggleNamecallHookButton = createHookToggleButton("ToggleNamecallHook", "Namecall", true)
    
    -- Sesuaikan tinggi mainFrame untuk mengakomodasi tombol baru
    local totalBottomUIHeight = FilterTextBox.Size.Y.Offset + 5 + RemoteScrollFrame.Size.Y.Offset + 5 + ClearLogsButton.Size.Y.Offset + 5 + SaveSessionButton.Size.Y.Offset + 5 + HookSettingsFrame.Size.Y.Offset + 10
    mainFrame.Size = UDim2.new(0, 220, 0, 35 + totalBottomUIHeight) -- Header + Konten Bawah
    RemoteScrollFrame.Size = UDim2.new(1,0,0, mainFrame.Size.Y.Offset - (35 + FilterTextBox.Size.Y.Offset + 5 + ClearLogsButton.Size.Y.Offset + 5 + SaveSessionButton.Size.Y.Offset + 5 + HookSettingsFrame.Size.Y.Offset + 10))

    -- Browser Remote
    BrowserHeader.Name = "BrowserHeader"
    BrowserHeader.Parent = TurtleSpyGUI
    BrowserHeader.BackgroundColor3 = colorSettings["Main"]["HeaderShadingColor"]
    BrowserHeader.BorderColor3 = colorSettings["Main"]["HeaderShadingColor"]
    BrowserHeader.Position = UDim2.new(0.5, -103, 0.1, 0) -- Tengah, sedikit ke atas
    BrowserHeader.Size = UDim2.new(0, 207, 0, 33)
    BrowserHeader.ZIndex = 1999
    BrowserHeader.Active = true
    BrowserHeader.Draggable = true
    BrowserHeader.Visible = false -- Sembunyikan secara default

    BrowserHeaderFrame.Name = "BrowserHeaderFrame"
    BrowserHeaderFrame.Parent = BrowserHeader
    BrowserHeaderFrame.BackgroundColor3 = colorSettings["Main"]["HeaderColor"]
    BrowserHeaderFrame.BorderSizePixel = 0
    BrowserHeaderFrame.Size = UDim2.new(1, 0, 0, 26)
    BrowserHeaderFrame.ZIndex = 2000

    BrowserHeaderText.Name = "BrowserHeaderText"
    BrowserHeaderText.Parent = BrowserHeaderFrame
    BrowserHeaderText.BackgroundTransparency = 1.000
    BrowserHeaderText.Size = UDim2.new(1, -30, 1, 0)
    BrowserHeaderText.Position = UDim2.new(0,5,0,0)
    BrowserHeaderText.ZIndex = 2001
    BrowserHeaderText.Font = Enum.Font.SourceSansSemibold
    BrowserHeaderText.Text = "Remote Browser"
    BrowserHeaderText.TextColor3 = colorSettings["Main"]["HeaderTextColor"]
    BrowserHeaderText.TextSize = 16.000
    BrowserHeaderText.TextXAlignment = Enum.TextXAlignment.Left

    CloseBrowserButton.Name = "CloseBrowserButton"
    CloseBrowserButton.Parent = BrowserHeaderFrame
    CloseBrowserButton.BackgroundColor3 = colorSettings["Main"]["HeaderColor"]
    CloseBrowserButton.BorderSizePixel = 0
    CloseBrowserButton.Position = UDim2.new(1, -25, 0, 2)
    CloseBrowserButton.Size = UDim2.new(0, 22, 0, 22)
    CloseBrowserButton.ZIndex = 2002
    CloseBrowserButton.Font = Enum.Font.SourceSansLight
    CloseBrowserButton.Text = "X"
    CloseBrowserButton.TextColor3 = colorSettings["Main"]["HeaderTextColor"]
    CloseBrowserButton.TextSize = 20.000

    RemoteBrowserFrame.Name = "RemoteBrowserFrame"
    RemoteBrowserFrame.Parent = BrowserHeader
    RemoteBrowserFrame.Active = true
    RemoteBrowserFrame.BackgroundColor3 = colorSettings["Main"]["MainBackgroundColor"]
    RemoteBrowserFrame.BorderColor3 = colorSettings["Main"]["HeaderShadingColor"]
    RemoteBrowserFrame.BorderSizePixel = 1
    RemoteBrowserFrame.Position = UDim2.new(0, 0, 1, 0)
    RemoteBrowserFrame.Size = UDim2.new(1, 0, 0, 286)
    RemoteBrowserFrame.ZIndex = 1998
    RemoteBrowserFrame.CanvasSize = UDim2.new(0, 0, 0, 287)
    RemoteBrowserFrame.ScrollBarThickness = 8
    RemoteBrowserFrame.VerticalScrollBarPosition = Enum.VerticalScrollBarPosition.Left
    RemoteBrowserFrame.ScrollBarImageColor3 = colorSettings["Main"]["ScrollBarImageColor"]

    -- Template untuk tombol di browser (jangan diparent)
    RemoteButtonBrowserTemplate.Name = "RemoteButtonBrowserTemplate"
    RemoteButtonBrowserTemplate.BackgroundColor3 = colorSettings["RemoteButtons"]["BackgroundColor"]
    RemoteButtonBrowserTemplate.BorderColor3 = colorSettings["RemoteButtons"]["BorderColor"]
    RemoteButtonBrowserTemplate.Size = UDim2.new(1, -10, 0, 28)
    RemoteButtonBrowserTemplate.Font = Enum.Font.SourceSans
    RemoteButtonBrowserTemplate.Text = ""
    RemoteButtonBrowserTemplate.ZIndex = 2000

    RemoteNameBrowserTemplate.Name = "RemoteNameBrowserLabel"
    RemoteNameBrowserTemplate.Parent = RemoteButtonBrowserTemplate
    RemoteNameBrowserTemplate.BackgroundTransparency = 1.000
    RemoteNameBrowserTemplate.Position = UDim2.new(0, 5, 0, 0)
    RemoteNameBrowserTemplate.Size = UDim2.new(1, -35, 1, 0)
    RemoteNameBrowserTemplate.ZIndex = 2001
    RemoteNameBrowserTemplate.Font = Enum.Font.SourceSans
    RemoteNameBrowserTemplate.Text = "RemoteEventName"
    RemoteNameBrowserTemplate.TextColor3 = colorSettings["RemoteButtons"]["TextColor"]
    RemoteNameBrowserTemplate.TextSize = 15.000
    RemoteNameBrowserTemplate.TextXAlignment = Enum.TextXAlignment.Left
    RemoteNameBrowserTemplate.TextTruncate = Enum.TextTruncate.AtEnd

    RemoteIconBrowserTemplate.Name = "RemoteIconBrowser"
    RemoteIconBrowserTemplate.Parent = RemoteButtonBrowserTemplate
    RemoteIconBrowserTemplate.BackgroundTransparency = 1.000
    RemoteIconBrowserTemplate.Position = UDim2.new(1, -28, 0.5, -12)
    RemoteIconBrowserTemplate.Size = UDim2.new(0, 24, 0, 24)
    RemoteIconBrowserTemplate.ZIndex = 2001
    RemoteIconBrowserTemplate.Image = eventImage
end
CreateUI() -- Panggil fungsi untuk membuat UI

-- Variabel Status GUI
local isInfoFrameOpen = false
local isMainFrameMinimized = false
local currentRemoteLookingAt = nil -- Instance remote yang sedang dilihat di InfoFrame
local currentRemoteDataKey = nil -- Kunci untuk remoteData yang sedang dilihat

-- Fungsi Utilitas GUI
local function ButtonEffect(button, text, success)
    if not IsValid(button) then return end
    local originalText = button.Text
    local originalColor = button.TextColor3
    local originalBgColor = button.BackgroundColor3

    button.Text = text or "Berhasil!"
    if success == true then
        button.TextColor3 = Color3.fromRGB(255, 255, 255)
        button.BackgroundColor3 = Color3.fromRGB(76, 209, 55) -- Hijau untuk sukses
    elseif success == false then
        button.TextColor3 = Color3.fromRGB(255, 255, 255)
        button.BackgroundColor3 = Color3.fromRGB(232, 65, 24) -- Merah untuk gagal
    else -- Netral/default
        button.TextColor3 = Color3.fromRGB(76, 209, 55) -- Tetap hijau untuk "Copied!"
    end
    
    delay(1.2, function()
        if IsValid(button) then
            button.Text = originalText
            button.TextColor3 = originalColor
            button.BackgroundColor3 = originalBgColor
        end
    end)
end

local function UpdateInfoFrame(remoteInstance, dataKey)
    if not remoteInstance or not IsValid(remoteInstance) or not remoteData[dataKey] then
        InfoFrame.Visible = false
        isInfoFrameOpen = false
        OpenInfoFrameButton.Text = ">"
        mainFrame.Size = UDim2.new(0, mainFrame.Size.X.Offset, 0, mainFrame.Size.Y.Offset) -- Pertahankan lebar
        currentRemoteLookingAt = nil
        currentRemoteDataKey = nil
        return
    end

    currentRemoteLookingAt = remoteInstance
    currentRemoteDataKey = dataKey
    local data = remoteData[dataKey]

    InfoHeaderText.Text = "Info: " .. remoteInstance.Name
    local isFunc = remoteInstance:IsA("RemoteFunction")
    CopyReturnValueButton.Visible = isFunc
    
    local fireMethod = isFunc and ":InvokeServer(" or ":FireServer("
    local currentArgs = data.argsHistory[#data.argsHistory] -- Ambil argumen terbaru
    
    local success, codeStr = pcall(convertTableToString, currentArgs, true)
    if not success then codeStr = "{ --[[ Error converting args ]] }" end

    CodeTextLabel.Text = GetFullPathOfAnInstance(remoteInstance) .. fireMethod .. codeStr .. ")"
    
    local successArgsEdit, argsEditStr = pcall(convertTableToString, currentArgs, true, 2) -- Indentasi 2 untuk editor
    if not successArgsEdit then argsEditStr = "{ --[[ Error converting args ]] }" end
    ArgumentEditorTextBox.Text = argsEditStr

    -- Update ukuran CodeTextLabel dan CodeFrame Canvas
    local textSize = TextService:GetTextSize(CodeTextLabel.Text, CodeTextLabel.TextSize, CodeTextLabel.Font, Vector2.new(math.huge, CodeTextLabel.AbsoluteSize.Y))
    CodeTextLabel.Size = UDim2.new(0, textSize.X + 20, 0, CodeTextLabel.Size.Y.Offset) -- Tambahkan padding
    CodeFrame.CanvasSize = UDim2.new(0, textSize.X + 30, 0, CodeFrame.CanvasSize.Y.Scale > 0 and CodeFrame.CanvasSize.Y.Scale or 1) -- Jaga Y scale jika ada

    -- Update tombol Ignore/Block/Unstack
    IgnoreRemoteButton.Text = table.find(IgnoreList, remoteInstance) and "Berhenti Mengabaikan" or "Abaikan Remote Ini"
    IgnoreRemoteButton.TextColor3 = table.find(IgnoreList, remoteInstance) and Color3.fromRGB(251, 197, 49) or colorSettings["MainButtons"]["TextColor"]

    BlockRemoteButton.Text = table.find(BlockList, remoteInstance) and "Buka Blokir Remote" or "Blokir Remote Ini"
    BlockRemoteButton.TextColor3 = table.find(BlockList, remoteInstance) and Color3.fromRGB(251, 197, 49) or colorSettings["MainButtons"]["TextColor"]

    UnstackRemoteButton.Text = table.find(unstackedRemotes, remoteInstance) and "Stack Remote Ini" or "Unstack Remote (Argumen Baru)"
    UnstackRemoteButton.TextColor3 = table.find(unstackedRemotes, remoteInstance) and Color3.fromRGB(251, 197, 49) or colorSettings["MainButtons"]["TextColor"]

    if not isInfoFrameOpen then
        InfoFrame.Visible = true
        isInfoFrameOpen = true
        OpenInfoFrameButton.Text = "<"
        mainFrame.Size = UDim2.new(0, mainFrame.Size.X.Offset + InfoFrame.Size.X.Offset + 5, 0, mainFrame.Size.Y.Offset)
        InfoFrame.ZIndex = 1000 -- Bawa ke depan
    end
end

-- Fungsi untuk mengonversi tabel ke string Lua yang dapat dibaca (ditingkatkan)
function convertTableToString(tbl, prettyPrint, indentLevel, visited)
    if type(tbl) ~= "table" then
        if type(tbl) == "string" then
            return '"' .. tbl:gsub("\\", "\\\\"):gsub('"', '\\"'):gsub("\n", "\\n") .. '"'
        elseif type(tbl) == "Instance" and IsValid(tbl) then
            return GetFullPathOfAnInstance(tbl)
        elseif type(tbl) == "Instance" and not IsValid(tbl) then
            return "nil --[[ Instance dihancurkan ]]"
        elseif type(tbl) == "EnumItem" then
            return "Enum." .. tbl.EnumType.Name .. "." .. tbl.Name
        elseif type(tbl) == "nil" then
            return "nil"
        else
            return tostring(tbl)
        end
    end

    visited = visited or {}
    if visited[tbl] then
        return "{ --[[ Referensi siklik ]] }"
    end
    visited[tbl] = true

    indentLevel = indentLevel or 0
    local str = "{"
    local first = true
    local indentStr = prettyPrint and string.rep("  ", indentLevel + 1) or ""
    local newLine = prettyPrint and "\n" or ""
    local space = prettyPrint and " " or ""

    -- Cek apakah tabel adalah array-like
    local isArrayLike = true
    local maxNumericIndex = 0
    for k, _ in pairs(tbl) do
        if type(k) == "number" and k >= 1 and math.floor(k) == k then
            maxNumericIndex = math.max(maxNumericIndex, k)
        else
            isArrayLike = false
            break
        end
    end
    if maxNumericIndex ~= #tbl then isArrayLike = false end


    if isArrayLike then
        for i = 1, #tbl do
            if not first then str = str .. "," .. space end
            str = str .. newLine .. indentStr .. convertTableToString(tbl[i], prettyPrint, indentLevel + 1, visited)
            first = false
        end
    else -- Mixed or dictionary-like table
        for k, v in pairs(tbl) do
            if not first then str = str .. "," .. space end
            local keyStr
            if type(k) == "string" and k:match("^[%a_][%w_]*$") then -- Valid identifier
                keyStr = k
            else
                keyStr = "[" .. convertTableToString(k, false, 0, {}) .. "]" -- Jangan pretty print kunci, jangan teruskan visited untuk kunci
            end
            str = str .. newLine .. indentStr .. keyStr .. space .. "=" .. space .. convertTableToString(v, prettyPrint, indentLevel + 1, visited)
            first = false
        end
    end
    
    visited[tbl] = nil -- Hapus dari visited setelah selesai dengan tabel ini

    str = str .. newLine .. (prettyPrint and #str > 1 and string.rep("  ", indentLevel) or "") .. "}"
    return str
end

-- Fungsi untuk mengonversi string argumen kembali ke tabel Lua
local function parseArgumentsString(argsString)
    local success, func = pcall(loadstring, "return " .. argsString)
    if not success or not func then
        warn("TurtleSpy: Gagal mem-parse string argumen:", func) -- func akan berisi pesan error dari loadstring
        return nil, "Error parsing: " .. (func or "unknown error")
    end
    
    local setEnvSuccess, _ = pcall(setfenv, func, getfenv(0)) -- Berikan environment saat ini
    if not setEnvSuccess then
        warn("TurtleSpy: Gagal mengatur environment untuk parser argumen.")
        -- Lanjutkan saja, mungkin masih berfungsi untuk argumen sederhana
    end

    local execSuccess, result = pcall(func)
    if not execSuccess then
        warn("TurtleSpy: Gagal mengeksekusi string argumen yang diparsing:", result)
        return nil, "Error executing: " .. (result or "unknown error")
    end
    
    if type(result) ~= "table" then -- Harusnya array argumen
        if result == nil and argsString:match("^%s*nil%s*$") then return {}, nil end -- "nil" menjadi {}
        if result == nil and argsString:match("^%s*%{%s*%}%s*$") then return {}, nil end -- "{}" menjadi {}
        if type(result) ~= "nil" then -- Jika bukan nil, bungkus dalam tabel
             return {result}, nil
        end
        return nil, "Hasil parsing bukan tabel dan bukan nil."
    end

    return result, nil
end


-- Event Handlers untuk Tombol GUI
MinimizeButton.MouseButton1Click:Connect(function()
    isMainFrameMinimized = not isMainFrameMinimized
    if isMainFrameMinimized then
        RemoteScrollFrame.Visible = false
        FilterTextBox.Visible = false
        ClearLogsButton.Visible = false
        UnstackAllButton.Visible = false
        SaveSessionButton.Visible = false
        LoadSessionButton.Visible = false
        HookSettingsFrame.Visible = false
        
        local headerHeight = Header.AbsoluteSize.Y
        mainFrame.Size = UDim2.new(0, mainFrame.Size.X.Offset, 0, headerHeight)
        MinimizeButton.Text = "O" -- Tanda untuk membuka
        if isInfoFrameOpen then -- Jika info frame terbuka, sembunyikan juga
            InfoFrame.Visible = false
        end
    else
        RemoteScrollFrame.Visible = true
        FilterTextBox.Visible = true
        ClearLogsButton.Visible = true
        UnstackAllButton.Visible = true
        SaveSessionButton.Visible = true
        LoadSessionButton.Visible = true
        HookSettingsFrame.Visible = true

        local totalBottomUIHeight = FilterTextBox.Size.Y.Offset + 5 + RemoteScrollFrame.Size.Y.Offset + 5 + ClearLogsButton.Size.Y.Offset + 5 + SaveSessionButton.Size.Y.Offset + 5 + HookSettingsFrame.Size.Y.Offset + 10
        local fullHeight = Header.AbsoluteSize.Y + totalBottomUIHeight
        mainFrame.Size = UDim2.new(0, mainFrame.Size.X.Offset, 0, fullHeight)
        RemoteScrollFrame.Size = UDim2.new(1,0,0, mainFrame.Size.Y.Offset - (Header.AbsoluteSize.Y + FilterTextBox.Size.Y.Offset + 5 + ClearLogsButton.Size.Y.Offset + 5 + SaveSessionButton.Size.Y.Offset + 5 + HookSettingsFrame.Size.Y.Offset + 10))

        MinimizeButton.Text = "_"
        if isInfoFrameOpen then -- Jika info frame tadinya terbuka, tampilkan kembali
            InfoFrame.Visible = true
        end
    end
end)

OpenInfoFrameButton.MouseButton1Click:Connect(function()
    if isMainFrameMinimized then return end -- Jangan lakukan apa-apa jika diminimize

    isInfoFrameOpen = not isInfoFrameOpen
    InfoFrame.Visible = isInfoFrameOpen
    if isInfoFrameOpen then
        OpenInfoFrameButton.Text = "<"
        mainFrame.Size = UDim2.new(0, mainFrame.Size.X.Offset + InfoFrame.Size.X.Offset + 5, 0, mainFrame.Size.Y.Offset)
        InfoFrame.ZIndex = 1000 -- Bawa ke depan
        -- Jika tidak ada remote yang dipilih, tampilkan pesan default atau kosongkan
        if not currentRemoteLookingAt then
            InfoHeaderText.Text = "Info: Tidak ada remote dipilih"
            CodeTextLabel.Text = "-- Pilih remote dari daftar untuk melihat detail --"
            ArgumentEditorTextBox.Text = "{}"
        end
    else
        OpenInfoFrameButton.Text = ">"
        mainFrame.Size = UDim2.new(0, mainFrame.Size.X.Offset - InfoFrame.Size.X.Offset - 5, 0, mainFrame.Size.Y.Offset)
        InfoFrame.ZIndex = 999
    end
end)

CloseInfoFrameButton.MouseButton1Click:Connect(function()
    if isInfoFrameOpen then
        isInfoFrameOpen = false
        InfoFrame.Visible = false
        OpenInfoFrameButton.Text = ">"
        mainFrame.Size = UDim2.new(0, mainFrame.Size.X.Offset - InfoFrame.Size.X.Offset - 5, 0, mainFrame.Size.Y.Offset)
        InfoFrame.ZIndex = 999
        currentRemoteLookingAt = nil
        currentRemoteDataKey = nil
    end
end)

CopyCodeButton.MouseButton1Click:Connect(function()
    if currentRemoteLookingAt and CodeTextLabel.Text ~= "" then
        local success, err = pcall(setclipboard, CodeCommentTextLabel.Text .. "\n\n" .. CodeTextLabel.Text)
        ButtonEffect(CopyCodeButton, success and "Kode Disalin!" or "Gagal Menyalin", success)
    else
        ButtonEffect(CopyCodeButton, "Tidak Ada Kode", false)
    end
end)

-- Fungsi untuk menjalankan remote dengan argumen tertentu
local function ExecuteRemote(remote, argsToExecute)
    if not remote or not IsValid(remote) then
        warn("TurtleSpy: Remote tidak valid untuk dieksekusi.")
        return nil, "Remote tidak valid"
    end

    local result = {}
    local successCall = false
    local callError = "Unknown error"

    if remote:IsA("RemoteFunction") then
        successCall, result = pcall(remote.InvokeServer, remote, unpack(argsToExecute))
        if not successCall then callError = result end -- result berisi pesan error
    elseif remote:IsA("RemoteEvent") then
        successCall, result = pcall(remote.FireServer, remote, unpack(argsToExecute))
        if not successCall then callError = result end
    else
        return nil, "Tipe remote tidak didukung"
    end

    if successCall then
        return result, nil -- result bisa jadi tabel hasil dari InvokeServer atau nil dari FireServer
    else
        return nil, callError
    end
end

RunCodeButton.MouseButton1Click:Connect(function()
    if currentRemoteLookingAt and currentRemoteDataKey and remoteData[currentRemoteDataKey] then
        local data = remoteData[currentRemoteDataKey]
        local originalArgs = data.argsHistory[#data.argsHistory] -- Ambil argumen terbaru/asli
        
        local _, err = ExecuteRemote(currentRemoteLookingAt, originalArgs)
        
        if err then
            ButtonEffect(RunCodeButton, "Gagal Eksekusi!", false)
            warn("TurtleSpy: Gagal menjalankan kode asli:", err)
        else
            ButtonEffect(RunCodeButton, "Kode Asli Dijalankan!", true)
        end
    else
        ButtonEffect(RunCodeButton, "Pilih Remote Dulu", false)
    end
end)

ApplyArgumentsButton.MouseButton1Click:Connect(function()
    if currentRemoteLookingAt then
        local argsStr = ArgumentEditorTextBox.Text
        local parsedArgs, parseErr = parseArgumentsString(argsStr)

        if parseErr then
            ButtonEffect(ApplyArgumentsButton, "Error Argumen!", false)
            warn("TurtleSpy: Gagal mem-parse argumen yang diedit:", parseErr)
            -- Mungkin tampilkan error di UI kecil dekat situ
            return
        end
        
        local _, execErr = ExecuteRemote(currentRemoteLookingAt, parsedArgs or {})
        
        if execErr then
            ButtonEffect(ApplyArgumentsButton, "Gagal Eksekusi!", false)
            warn("TurtleSpy: Gagal menjalankan dengan argumen yang diedit:", execErr)
        else
            ButtonEffect(ApplyArgumentsButton, "Dijalankan dg Arg Editan!", true)
            -- Log bahwa ini dijalankan dengan argumen yang diedit
            -- Mungkin tambahkan ke history argumen remoteData jika diinginkan
        end
    else
        ButtonEffect(ApplyArgumentsButton, "Pilih Remote Dulu", false)
    end
end)


CopyScriptPathButton.MouseButton1Click:Connect(function()
    if currentRemoteLookingAt and currentRemoteDataKey and remoteData[currentRemoteDataKey] then
        local data = remoteData[currentRemoteDataKey]
        if data.callingScript and IsValid(data.callingScript) then
            local path = GetFullPathOfAnInstance(data.callingScript)
            local success, err = pcall(setclipboard, path)
            ButtonEffect(CopyScriptPathButton, success and "Path Script Disalin!" or "Gagal Menyalin", success)
        else
            ButtonEffect(CopyScriptPathButton, "Script Tidak Ditemukan", false)
        end
    else
        ButtonEffect(CopyScriptPathButton, "Pilih Remote Dulu", false)
    end
end)

CopyDecompiledButton.MouseButton1Click:Connect(function()
    if not decompileFunc then
        ButtonEffect(CopyDecompiledButton, "Decompile Tdk Tersedia", false)
        return
    end
    if currentRemoteLookingAt and currentRemoteDataKey and remoteData[currentRemoteDataKey] then
        local data = remoteData[currentRemoteDataKey]
        if data.callingScript and IsValid(data.callingScript) then
            CopyDecompiledButton.Text = "Mendekompilasi..."
            local success, result = pcall(decompileFunc, data.callingScript)
            if success then
                local cbSuccess, _ = pcall(setclipboard, result)
                ButtonEffect(CopyDecompiledButton, cbSuccess and "Dekompilasi Disalin!" or "Gagal Menyalin Hasil", cbSuccess)
            else
                ButtonEffect(CopyDecompiledButton, "Gagal Dekompilasi", false)
                warn("TurtleSpy: Decompilation error:", result)
            end
            -- Kembalikan teks tombol setelah efek
            delay(1.5, function() if IsValid(CopyDecompiledButton) then CopyDecompiledButton.Text = "Salin Script Decompiled" end end)
        else
            ButtonEffect(CopyDecompiledButton, "Script Tidak Ditemukan", false)
        end
    else
        ButtonEffect(CopyDecompiledButton, "Pilih Remote Dulu", false)
    end
end)

CopyFullPathButton.MouseButton1Click:Connect(function()
    if currentRemoteLookingAt and IsValid(currentRemoteLookingAt) then
        local path = GetFullPathOfAnInstance(currentRemoteLookingAt)
        local success, err = pcall(setclipboard, path)
        ButtonEffect(CopyFullPathButton, success and "Path Instance Disalin!" or "Gagal Menyalin", success)
    else
        ButtonEffect(CopyFullPathButton, "Pilih Remote Dulu", false)
    end
end)


IgnoreRemoteButton.MouseButton1Click:Connect(function()
    if currentRemoteLookingAt then
        local index = table.find(IgnoreList, currentRemoteLookingAt)
        if index then
            table.remove(IgnoreList, index)
            IgnoreRemoteButton.Text = "Abaikan Remote Ini"
            IgnoreRemoteButton.TextColor3 = colorSettings["MainButtons"]["TextColor"]
            ButtonEffect(IgnoreRemoteButton, "Berhenti Mengabaikan", true)
            if remoteData[currentRemoteDataKey] and IsValid(remoteData[currentRemoteDataKey].button) then
                 remoteData[currentRemoteDataKey].button.RemoteNameLabel.TextColor3 = colorSettings["RemoteButtons"]["TextColor"]
            end
        else
            table.insert(IgnoreList, currentRemoteLookingAt)
            IgnoreRemoteButton.Text = "Berhenti Mengabaikan"
            IgnoreRemoteButton.TextColor3 = Color3.fromRGB(251, 197, 49)
            ButtonEffect(IgnoreRemoteButton, "Remote Diabaikan", true)
            if remoteData[currentRemoteDataKey] and IsValid(remoteData[currentRemoteDataKey].button) then
                 remoteData[currentRemoteDataKey].button.RemoteNameLabel.TextColor3 = Color3.fromRGB(127, 143, 166) -- Warna abu-abu
            end
        end
    else
        ButtonEffect(IgnoreRemoteButton, "Pilih Remote Dulu", false)
    end
end)

BlockRemoteButton.MouseButton1Click:Connect(function()
    if currentRemoteLookingAt then
        local index = table.find(BlockList, currentRemoteLookingAt)
        if index then
            table.remove(BlockList, index)
            BlockRemoteButton.Text = "Blokir Remote Ini"
            BlockRemoteButton.TextColor3 = colorSettings["MainButtons"]["TextColor"]
            ButtonEffect(BlockRemoteButton, "Blokir Dilepas", true)
            if remoteData[currentRemoteDataKey] and IsValid(remoteData[currentRemoteDataKey].button) then
                 remoteData[currentRemoteDataKey].button.RemoteNameLabel.TextColor3 = colorSettings["RemoteButtons"]["TextColor"]
            end
        else
            table.insert(BlockList, currentRemoteLookingAt)
            BlockRemoteButton.Text = "Buka Blokir Remote"
            BlockRemoteButton.TextColor3 = Color3.fromRGB(251, 197, 49)
            ButtonEffect(BlockRemoteButton, "Remote Diblokir", true)
            if remoteData[currentRemoteDataKey] and IsValid(remoteData[currentRemoteDataKey].button) then
                 remoteData[currentRemoteDataKey].button.RemoteNameLabel.TextColor3 = Color3.fromRGB(225, 177, 44) -- Warna kuning/oranye
            end
        end
    else
        ButtonEffect(BlockRemoteButton, "Pilih Remote Dulu", false)
    end
end)

UnstackRemoteButton.MouseButton1Click:Connect(function()
    if currentRemoteLookingAt then
        local index = table.find(unstackedRemotes, currentRemoteLookingAt)
        if index then
            table.remove(unstackedRemotes, index)
            UnstackRemoteButton.Text = "Unstack Remote (Argumen Baru)"
            UnstackRemoteButton.TextColor3 = colorSettings["MainButtons"]["TextColor"]
            ButtonEffect(UnstackRemoteButton, "Remote Akan Di-stack", true)
        else
            table.insert(unstackedRemotes, currentRemoteLookingAt)
            UnstackRemoteButton.Text = "Stack Remote Ini"
            UnstackRemoteButton.TextColor3 = Color3.fromRGB(251, 197, 49)
            ButtonEffect(UnstackRemoteButton, "Remote Akan Di-unstack", true)
        end
    else
        ButtonEffect(UnstackRemoteButton, "Pilih Remote Dulu", false)
    end
end)

WhileLoopButton.MouseButton1Click:Connect(function()
    if currentRemoteLookingAt and CodeTextLabel.Text ~= "" then
        local loopScript = string.format("while task.wait() do\n    %s\nend", CodeTextLabel.Text)
        local success, err = pcall(setclipboard, loopScript)
        ButtonEffect(WhileLoopButton, success and "Skrip Loop Disalin!" or "Gagal Menyalin", success)
    else
        ButtonEffect(WhileLoopButton, "Tidak Ada Kode", false)
    end
end)

CopyReturnValueButton.MouseButton1Click:Connect(function()
    if currentRemoteLookingAt and currentRemoteLookingAt:IsA("RemoteFunction") and currentRemoteDataKey and remoteData[currentRemoteDataKey] then
        local data = remoteData[currentRemoteDataKey]
        local originalArgs = data.argsHistory[#data.argsHistory]

        local result, execErr = ExecuteRemote(currentRemoteLookingAt, originalArgs)
        
        if execErr then
            ButtonEffect(CopyReturnValueButton, "Gagal Eksekusi!", false)
            warn("TurtleSpy: Gagal mengeksekusi RemoteFunction untuk menyalin return:", execErr)
            return
        end

        local success, returnStr = pcall(convertTableToString, result, true)
        if not success then returnStr = "--[[ Error converting return value ]]--" end
        
        local cbSuccess, _ = pcall(setclipboard, returnStr)
        ButtonEffect(CopyReturnValueButton, cbSuccess and "Return Disalin!" or "Gagal Menyalin Return", cbSuccess)

    elseif not (currentRemoteLookingAt and currentRemoteLookingAt:IsA("RemoteFunction")) then
        ButtonEffect(CopyReturnValueButton, "Ini Bukan Fungsi", false)
    else
        ButtonEffect(CopyReturnValueButton, "Pilih Remote Dulu", false)
    end
end)

ClearLogsButton.MouseButton1Click:Connect(function()
    for _, child in ipairs(RemoteScrollFrame:GetChildren()) do
        if child:IsA("TextButton") and child.Name ~= "RemoteButtonTemplate" then -- Jangan hapus template
            child:Destroy()
        end
    end
    for _, conn in ipairs(activeConnections) do
        if conn and conn.Connected then conn:Disconnect() end
    end
    activeConnections = {}
    remotes = {}
    remoteData = {}
    remoteButtons = {} -- Ini sekarang merujuk ke remoteData[key].button
    -- Jangan reset IgnoreList, BlockList, unstackedRemotes kecuali diminta
    
    buttonOffset = 5 -- Reset offset, mulai dari atas
    RemoteScrollFrame.CanvasSize = UDim2.new(0, 0, 0, scrollSizeOffset) -- Reset ukuran canvas
    currentRemoteLookingAt = nil
    currentRemoteDataKey = nil
    if isInfoFrameOpen then -- Tutup info frame jika terbuka
        CloseInfoFrameButton:MouseButton1Click()
    end
    ButtonEffect(ClearLogsButton, "Log Dibersihkan!", true)
end)

UnstackAllButton.MouseButton1Click:Connect(function()
    local currentUnstackedCount = #unstackedRemotes
    local allKnownRemotes = {}
    for key, dataItem in pairs(remoteData) do
        if dataItem.instance and IsValid(dataItem.instance) then
            table.insert(allKnownRemotes, dataItem.instance)
        end
    end

    if currentUnstackedCount > 0 and currentUnstackedCount == #allKnownRemotes then -- Jika semua sudah di-unstack, stack semua
        unstackedRemotes = {}
        UnstackAllButton.Text = "Unstack Semua"
        ButtonEffect(UnstackAllButton, "Semua Di-stack Ulang", true)
    else -- Unstack semua yang belum
        unstackedRemotes = {} -- Kosongkan dulu
        for _, remoteInst in ipairs(allKnownRemotes) do
            if not table.find(unstackedRemotes, remoteInst) then
                 table.insert(unstackedRemotes, remoteInst)
            end
        end
        UnstackAllButton.Text = "Stack Semua"
        ButtonEffect(UnstackAllButton, "Semua Di-unstack", true)
    end
    -- Update tampilan tombol unstack individual jika info frame terbuka
    if currentRemoteLookingAt and isInfoFrameOpen then
        UnstackRemoteButton.Text = table.find(unstackedRemotes, currentRemoteLookingAt) and "Stack Remote Ini" or "Unstack Remote (Argumen Baru)"
        UnstackRemoteButton.TextColor3 = table.find(unstackedRemotes, currentRemoteLookingAt) and Color3.fromRGB(251, 197, 49) or colorSettings["MainButtons"]["TextColor"]
    end
end)


-- Fungsi untuk menyimpan sesi
SaveSessionButton.MouseButton1Click:Connect(function()
    local sessionData = {
        remotes = {},
        ignoreList = {},
        blockList = {},
        unstackedRemotes = {}
    }
    for key, dataItem in pairs(remoteData) do
        if dataItem.instance and IsValid(dataItem.instance) then
            local remoteInfo = {
                path = GetFullPathOfAnInstance(dataItem.instance),
                name = dataItem.instance.Name,
                className = dataItem.instance.ClassName,
                argsHistory = {}, -- Hanya simpan argumen terakhir untuk kesederhanaan, atau semua jika perlu
                count = dataItem.count,
                -- Tidak menyimpan callingScript karena mungkin tidak valid saat dimuat ulang
            }
            -- Hanya simpan argumen terakhir sebagai string
            if #dataItem.argsHistory > 0 then
                 local success, argStr = pcall(convertTableToString, dataItem.argsHistory[#dataItem.argsHistory], false)
                 if success then remoteInfo.lastArgsString = argStr else remoteInfo.lastArgsString = "{}" end
            end
            table.insert(sessionData.remotes, remoteInfo)
        end
    end
    for _, remoteInst in ipairs(IgnoreList) do if IsValid(remoteInst) then table.insert(sessionData.ignoreList, GetFullPathOfAnInstance(remoteInst)) end end
    for _, remoteInst in ipairs(BlockList) do if IsValid(remoteInst) then table.insert(sessionData.blockList, GetFullPathOfAnInstance(remoteInst)) end end
    for _, remoteInst in ipairs(unstackedRemotes) do if IsValid(remoteInst) then table.insert(sessionData.unstackedRemotes, GetFullPathOfAnInstance(remoteInst)) end end

    local success, encodedData = pcall(HttpService.JSONEncode, HttpService, sessionData)
    if success then
        local writeSuccess, err = pcall(writefile, "TurtleSpySession.json", encodedData)
        ButtonEffect(SaveSessionButton, writeSuccess and "Sesi Disimpan!" or "Gagal Menyimpan", writeSuccess)
        if not writeSuccess then warn("TurtleSpy: Gagal menulis file sesi:", err) end
    else
        ButtonEffect(SaveSessionButton, "Gagal Encode Sesi", false)
        warn("TurtleSpy: Gagal JSONEncode sesi:", encodedData)
    end
end)

-- Fungsi untuk memuat sesi
LoadSessionButton.MouseButton1Click:Connect(function()
    local success, jsonData = pcall(readfile, "TurtleSpySession.json")
    if not success or not jsonData then
        ButtonEffect(LoadSessionButton, "File Sesi Tidak Ada", false)
        warn("TurtleSpy: Gagal membaca file sesi:", jsonData)
        return
    end

    local decodeSuccess, sessionData = pcall(HttpService.JSONDecode, HttpService, jsonData)
    if not decodeSuccess then
        ButtonEffect(LoadSessionButton, "Gagal Decode Sesi", false)
        warn("TurtleSpy: Gagal JSONDecode sesi:", sessionData)
        return
    end

    ClearLogsButton:MouseButton1Click() -- Bersihkan log saat ini

    local function findInstanceByPath(path)
        local success, instance = pcall(function()
            local current = game
            for part in string.gmatch(path, "[^%.%/:]+") do -- Split by ., /, : (GetService)
                if part:match('GetService%("(.+)"%)') then
                    local serviceName = part:match('GetService%("(.+)"%)')
                    current = current:GetService(serviceName)
                elseif part:match('%["(.+)"%]') then
                    local rawName = part:match('%["(.+)"%]')
                    current = current[rawName] -- Akses langsung jika dalam kurung siku
                else
                    current = current[part]
                end
                if not current then return nil end
            end
            return current
        end)
        return success and instance or nil
    end

    for _, remoteInfo in ipairs(sessionData.remotes or {}) do
        local instance = findInstanceByPath(remoteInfo.path)
        if instance and IsValid(instance) and instance:IsA(remoteInfo.className) then
            local args = {}
            if remoteInfo.lastArgsString then
                local parsed, _ = parseArgumentsString(remoteInfo.lastArgsString)
                args = parsed or {}
            end
            -- Panggil addToListInternal untuk menambahkan remote yang dimuat
            -- Perlu script dummy karena getCallingScript tidak akan berfungsi
            local dummyScript = Instance.new("LocalScript")
            dummyScript.Name = "LoadedFromSession"
            addToListInternal(instance:IsA("RemoteEvent"), instance, dummyScript, unpack(args))
            dummyScript:Destroy()
            
            -- Update count jika ada
            local dataKey =GetKeyForRemote(instance, args, table.find(unstackedRemotes, instance) ~= nil)
            if remoteData[dataKey] and remoteInfo.count and remoteInfo.count > 1 then
                remoteData[dataKey].count = remoteInfo.count
                if IsValid(remoteData[dataKey].button) then
                    remoteData[dataKey].button.NumberLabel.Text = tostring(remoteInfo.count)
                    -- Update posisi nama remote berdasarkan panjang angka
                    local numSize = TextService:GetTextSize(remoteData[dataKey].button.NumberLabel.Text, remoteData[dataKey].button.NumberLabel.TextSize, remoteData[dataKey].button.NumberLabel.Font, Vector2.new())
                    remoteData[dataKey].button.RemoteNameLabel.Position = UDim2.new(0, numSize.X + 10, 0, 0)
                end
            end
        else
            warn("TurtleSpy: Gagal menemukan instance saat memuat sesi:", remoteInfo.path)
        end
    end

    IgnoreList = {}
    for _, path in ipairs(sessionData.ignoreList or {}) do local inst = findInstanceByPath(path) if inst then table.insert(IgnoreList, inst) end end
    BlockList = {}
    for _, path in ipairs(sessionData.blockList or {}) do local inst = findInstanceByPath(path) if inst then table.insert(BlockList, inst) end end
    unstackedRemotes = {}
    for _, path in ipairs(sessionData.unstackedRemotes or {}) do local inst = findInstanceByPath(path) if inst then table.insert(unstackedRemotes, inst) end end
    
    ButtonEffect(LoadSessionButton, "Sesi Dimuat!", true)
    FilterTextBox.Text = "" -- Reset filter
    FilterRemotes("") -- Terapkan filter kosong untuk menampilkan semua
end)


-- Pengaturan Hook
local fireServerHookActive = true
local invokeServerHookActive = true
local namecallHookActive = true

local function updateHookButton(button, textPrefix, isActive)
    button._isActive = isActive
    button.Text = textPrefix .. (isActive and " (Aktif)" or " (Nonaktif)")
    button.BackgroundColor3 = isActive and Color3.fromRGB(76, 209, 55) or colorSettings["MainButtons"]["BackgroundColor"]
end

ToggleFireServerHookButton.MouseButton1Click:Connect(function()
    fireServerHookActive = not fireServerHookActive
    updateHookButton(ToggleFireServerHookButton, "FireServer", fireServerHookActive)
    ButtonEffect(ToggleFireServerHookButton, fireServerHookActive and "Hook FireServer Aktif" or "Hook FireServer Nonaktif", fireServerHookActive)
end)
ToggleInvokeServerHookButton.MouseButton1Click:Connect(function()
    invokeServerHookActive = not invokeServerHookActive
    updateHookButton(ToggleInvokeServerHookButton, "InvokeServer", invokeServerHookActive)
    ButtonEffect(ToggleInvokeServerHookButton, invokeServerHookActive and "Hook InvokeServer Aktif" or "Hook InvokeServer Nonaktif", invokeServerHookActive)
end)
ToggleNamecallHookButton.MouseButton1Click:Connect(function()
    namecallHookActive = not namecallHookActive
    updateHookButton(ToggleNamecallHookButton, "Namecall", namecallHookActive)
    ButtonEffect(ToggleNamecallHookButton, namecallHookActive and "Hook Namecall Aktif" or "Hook Namecall Nonaktif", namecallHookActive)
end)

-- Fungsi Filter
local function FilterRemotes(filterText)
    filterText = filterText:lower()
    local newButtonOffset = 5 -- Mulai dari atas lagi
    local visibleCount = 0
    
    -- Iterasi melalui remoteData karena itu yang menyimpan info lengkap
    for key, dataItem in pairs(remoteData) do
        if dataItem.button and IsValid(dataItem.button) then
            local remoteName = dataItem.instance and dataItem.instance.Name:lower() or ""
            if filterText == "" or remoteName:find(filterText, 1, true) then
                dataItem.button.Visible = true
                dataItem.button.Position = UDim2.new(0.05, 0, 0, newButtonOffset)
                newButtonOffset = newButtonOffset + dataItem.button.AbsoluteSize.Y + 5
                visibleCount = visibleCount + 1
            else
                dataItem.button.Visible = false
            end
        end
    end
    RemoteScrollFrame.CanvasSize = UDim2.new(0, 0, 0, math.max(scrollSizeOffset, newButtonOffset))
end

FilterTextBox.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        FilterRemotes(FilterTextBox.Text)
    end
end)
FilterTextBox:GetPropertyChangedSignal("Text"):Connect(function()
    FilterRemotes(FilterTextBox.Text) -- Filter secara real-time
end)

-- Keybind Handler
UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
    if gameProcessedEvent then return end -- Jangan proses jika game sudah memprosesnya (mis. chat)
    if input.KeyCode == Enum.KeyCode[settings["Keybind"]:upper()] then
        TurtleSpyGUI.Enabled = not TurtleSpyGUI.Enabled
    end
end)


-- Browser Remote Logic
local browsedRemotesCache = {} -- Cache untuk remote yang sudah di-browse
local browsedConnections = {}
local browserButtonOffsetY = 10
local browserCanvasCurrentSizeY = 286

OpenBrowserButton.MouseButton1Click:Connect(function()
    BrowserHeader.Visible = not BrowserHeader.Visible
    if BrowserHeader.Visible then
        -- Bersihkan item lama sebelum mengisi ulang
        for _, child in ipairs(RemoteBrowserFrame:GetChildren()) do
            if child:IsA("TextButton") and child.Name ~= "RemoteButtonBrowserTemplate" then
                child:Destroy()
            end
        end
        for _, conn in ipairs(browsedConnections) do if conn.Connected then conn:Disconnect() end end
        browsedConnections = {}
        browsedRemotesCache = {} -- Reset cache
        browserButtonOffsetY = 10
        browserCanvasCurrentSizeY = 286
        RemoteBrowserFrame.CanvasSize = UDim2.new(0,0,0, browserCanvasCurrentSizeY)

        -- Cari semua remote di game
        for _, v in ipairs(game:GetDescendants()) do
            if (v:IsA("RemoteEvent") or v:IsA("RemoteFunction")) and not table.find(browsedRemotesCache, v) then
                table.insert(browsedRemotesCache, v)
                local bButton = RemoteButtonBrowserTemplate:Clone()
                bButton.Parent = RemoteBrowserFrame
                bButton.Visible = true
                bButton.Position = UDim2.new(0.05, 0, 0, browserButtonOffsetY)
                
                local nameLabel = bButton:FindFirstChild("RemoteNameBrowserLabel") or RemoteNameBrowserTemplate:Clone()
                nameLabel.Parent = bButton
                nameLabel.Text = v.Name
                
                local iconLabel = bButton:FindFirstChild("RemoteIconBrowser") or RemoteIconBrowserTemplate:Clone()
                iconLabel.Parent = bButton
                iconLabel.Image = v:IsA("RemoteEvent") and eventImage or functionImage

                local fireMethod = v:IsA("RemoteEvent") and ":FireServer()" or ":InvokeServer()"
                
                local conn = bButton.MouseButton1Click:Connect(function()
                    local success, err = pcall(setclipboard, GetFullPathOfAnInstance(v) .. fireMethod)
                    ButtonEffect(bButton, success and "Path Disalin!" or "Gagal", success)
                end)
                table.insert(browsedConnections, conn)
                
                browserButtonOffsetY = browserButtonOffsetY + bButton.AbsoluteSize.Y + 5
                if browserButtonOffsetY > browserCanvasCurrentSizeY - 30 then -- -30 untuk buffer
                    browserCanvasCurrentSizeY = browserCanvasCurrentSizeY + bButton.AbsoluteSize.Y + 5
                    RemoteBrowserFrame.CanvasSize = UDim2.new(0, 0, 0, browserCanvasCurrentSizeY)
                end
            end
        end
    end
end)

CloseBrowserButton.MouseButton1Click:Connect(function()
    BrowserHeader.Visible = false
end)


-- Fungsi Inti: addToList dan Hook
local function GetKeyForRemote(remote, args, isUnstacked)
    local key = GetFullPathOfAnInstance(remote) 
    if not isUnstacked then
        -- Untuk remote yang di-stack, argumen juga bagian dari kunci
        -- Ini bisa menjadi kompleks jika argumen adalah tabel besar atau instance
        -- Untuk kesederhanaan, kita bisa serialize argumen atau menggunakan referensi tabel jika memungkinkan
        -- Namun, serializing bisa mahal. Coba gunakan kombinasi path dan hash argumen sederhana.
        local success, argStr = pcall(HttpService.JSONEncode, HttpService, args)
        if success then
            key = key .. "|" .. argStr -- Hati-hati dengan panjang kunci dan performa
        else
            -- Fallback jika JSONEncode gagal (misalnya, ada userdata)
            -- Gunakan tostring sederhana, mungkin tidak unik untuk tabel kompleks
            local simpleArgStr = ""
            for _, argVal in ipairs(args) do simpleArgStr = simpleArgStr .. tostring(argVal) end
            key = key .. "|SIMPLE|" .. simpleArgStr
        end
    end
    return key
end

local function addToListInternal(isEvent, remote, callingScript, ...)
    if not remote or not IsValid(remote) then return end
    if table.find(IgnoreList, remote) then return end -- Jangan proses jika diabaikan

    local currentId = getThreadContextFunc()
    setThreadContextFunc(7) -- Set ke context yang aman

    local args = {...}
    local isUnstacked = table.find(unstackedRemotes, remote) ~= nil
    local dataKey = GetKeyForRemote(remote, args, isUnstacked)

    if not remoteData[dataKey] then
        if #RemoteScrollFrame:GetChildren() > settings.MaxDisplayedRemotes then
            -- Hapus remote tertua jika melebihi batas
            local oldestKey, oldestTimestamp = nil, math.huge
            for k, dataItem in pairs(remoteData) do
                if dataItem.firstSeen < oldestTimestamp then
                    oldestTimestamp = dataItem.firstSeen
                    oldestKey = k
                end
            end
            if oldestKey and remoteData[oldestKey] and IsValid(remoteData[oldestKey].button) then
                remoteData[oldestKey].button:Destroy()
                remoteData[oldestKey] = nil
            end
        end

        local rButton = RemoteButtonTemplate:Clone()
        rButton.Name = remote.Name .. "_Button"
        rButton.Parent = RemoteScrollFrame
        rButton.Visible = true -- Akan diatur oleh filter nanti
        
        local numberLabel = rButton:FindFirstChild("NumberLabel") or NumberLabelTemplate:Clone()
        numberLabel.Parent = rButton
        numberLabel.Text = "1"

        local remoteNameLabel = rButton:FindFirstChild("RemoteNameLabel") or RemoteNameLabelTemplate:Clone()
        remoteNameLabel.Parent = rButton
        remoteNameLabel.Text = remote.Name
        if table.find(BlockList, remote) then
            remoteNameLabel.TextColor3 = Color3.fromRGB(225, 177, 44)
        elseif table.find(IgnoreList, remote) then -- Sebenarnya tidak akan sampai sini jika diabaikan, tapi untuk konsistensi
             remoteNameLabel.TextColor3 = Color3.fromRGB(127, 143, 166)
        end

        local remoteIcon = rButton:FindFirstChild("RemoteIcon") or RemoteIconTemplate:Clone()
        remoteIcon.Parent = rButton
        remoteIcon.Image = isEvent and eventImage or functionImage

        -- Simpan data remote
        remoteData[dataKey] = {
            instance = remote,
            argsHistory = {args}, -- Simpan history argumen
            callingScript = callingScript,
            count = 1,
            button = rButton,
            isEvent = isEvent,
            firstSeen = tick()
        }
        
        -- Update posisi nama remote berdasarkan panjang angka
        local numSize = TextService:GetTextSize(numberLabel.Text, numberLabel.TextSize, numberLabel.Font, Vector2.new())
        remoteNameLabel.Position = UDim2.new(0, numSize.X + 10, 0, 0)
        remoteNameLabel.Size = UDim2.new(1, -(numSize.X + 10 + 30), 1, 0) -- -30 untuk ikon

        -- Tambahkan koneksi klik
        local conn = rButton.MouseButton1Click:Connect(function()
            UpdateInfoFrame(remote, dataKey)
        end)
        table.insert(activeConnections, conn)
        
        -- Panggil filter untuk mengatur posisi dan visibilitas
        FilterRemotes(FilterTextBox.Text) 
        if settings.AutoScroll and RemoteScrollFrame.Visible then
             RemoteScrollFrame.CanvasPosition = Vector2.new(0, RemoteScrollFrame.CanvasSize.Y.Offset)
        end

    else -- Remote sudah ada (baik di-stack atau unstack dengan argumen sama)
        local data = remoteData[dataKey]
        data.count = data.count + 1
        if IsValid(data.button) then
            data.button.NumberLabel.Text = tostring(data.count)
            local numSize = TextService:GetTextSize(data.button.NumberLabel.Text, data.button.NumberLabel.TextSize, data.button.NumberLabel.Font, Vector2.new())
            data.button.RemoteNameLabel.Position = UDim2.new(0, numSize.X + 10, 0, 0)
            data.button.RemoteNameLabel.Size = UDim2.new(1, -(numSize.X + 10 + 30), 1, 0)
        end
        
        -- Update argumen terbaru dan script pemanggil jika berbeda
        table.insert(data.argsHistory, args)
        if #data.argsHistory > 20 then table.remove(data.argsHistory, 1) end -- Batasi history argumen
        data.callingScript = callingScript -- Selalu update ke pemanggil terbaru

        -- Jika remote ini sedang dilihat di InfoFrame, update infonya
        if currentRemoteLookingAt == remote and currentRemoteDataKey == dataKey and isInfoFrameOpen then
            UpdateInfoFrame(remote, dataKey)
        end
    end
    setThreadContextFunc(currentId)
end

-- Hooking Functions
local OldEvent_FireServer, OldFunction_InvokeServer, OldNamecall

if Instance.new("RemoteEvent").FireServer then
    OldEvent_FireServer = hookfunction(Instance.new("RemoteEvent").FireServer, function(self, ...)
        if not fireServerHookActive then return OldEvent_FireServer(self, ...) end
        if not checkcaller() and table.find(BlockList, self) then return end -- Blokir jika bukan dari game dan ada di BlockList
        
        local script = getCallingScriptFunc and getCallingScriptFunc() or nil
        addToListInternal(true, self, script, ...)
        return OldEvent_FireServer(self, ...)
    end)
else
    warn("TurtleSpy: Gagal hook RemoteEvent.FireServer (mungkin sudah dihook atau tidak ada).")
end

if Instance.new("RemoteFunction").InvokeServer then
    OldFunction_InvokeServer = hookfunction(Instance.new("RemoteFunction").InvokeServer, function(self, ...)
        if not invokeServerHookActive then return OldFunction_InvokeServer(self, ...) end
        if not checkcaller() and table.find(BlockList, self) then return end -- Blokir
        
        local script = getCallingScriptFunc and getCallingScriptFunc() or nil
        addToListInternal(false, self, script, ...)
        return OldFunction_InvokeServer(self, ...)
    end)
else
    warn("TurtleSpy: Gagal hook RemoteFunction.InvokeServer.")
end

if hookmetamethod then
    OldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
        if not namecallHookActive then return OldNamecall(self, ...) end
        
        local method = getNamecallMethodFunc and getNamecallMethodFunc() or ""
        local args = {...} -- Ambil argumen untuk __namecall

        if method == "FireServer" and self:IsA("RemoteEvent") then
            if not checkcaller() and table.find(BlockList, self) then return end
            local script = getCallingScriptFunc and getCallingScriptFunc() or nil
            addToListInternal(true, self, script, unpack(args)) -- Unpack args untuk FireServer
        elseif method == "InvokeServer" and self:IsA("RemoteFunction") then
            if not checkcaller() and table.find(BlockList, self) then return end
            local script = getCallingScriptFunc and getCallingScriptFunc() or nil
            addToListInternal(false, self, script, unpack(args)) -- Unpack args untuk InvokeServer
        end
        return OldNamecall(self, ...)
    end)
else
    warn("TurtleSpy: hookmetamethod tidak tersedia. Namecall tidak akan terdeteksi.")
end

-- Inisialisasi akhir
FilterRemotes("") -- Tampilkan semua log awal
TurtleSpyGUI.Enabled = true -- Tampilkan GUI saat dimuat
HeaderTextLabel.Text = "TurtleSpy V2 (" .. executorName .. ")"

-- Pembersihan saat script dihancurkan (jika memungkinkan)
if script and script:IsA("Script") then -- Atau LocalScript
    script.Destroying:Connect(function()
        if OldEvent_FireServer and typeof(OldEvent_FireServer) == 'function' then OldEvent_FireServer() end -- Unhook jika hookfunction mengembalikan fungsi unhook
        if OldFunction_InvokeServer and typeof(OldFunction_InvokeServer) == 'function' then OldFunction_InvokeServer() end
        if OldNamecall and typeof(OldNamecall) == 'function' then OldNamecall() end -- Ini mungkin tidak standar untuk unhook metamethod

        for _, conn in ipairs(activeConnections) do
            if conn and conn.Connected then conn:Disconnect() end
        end
        activeConnections = {}
        if IsValid(TurtleSpyGUI) then TurtleSpyGUI:Destroy() end
        -- Simpan pengaturan saat keluar?
        pcall(writefile, settingsFileName, HttpService:JSONEncode(settings))
    end)
end

-- Pesan bahwa skrip telah dimuat
print("TurtleSpy V2 Enhanced by Gemini loaded. Executor: " .. executorName .. ". Keybind: " .. settings.Keybind)
