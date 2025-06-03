-- TurtleSpy V1.5.3 (Enhanced by Gemini, Arceus X Compatibility Fix V2)
-- Credits to Intrer#0421 for the original script
print("TurtleSpy V2 Loading...")

local colorSettings =
{
    ["Main"] = {
        ["HeaderColor"] = Color3.fromRGB(0, 168, 255),
        ["HeaderShadingColor"] = Color3.fromRGB(0, 151, 230),
        ["HeaderTextColor"] = Color3.fromRGB(47, 54, 64),
        ["MainBackgroundColor"] = Color3.fromRGB(47, 54, 64),
        ["InfoScrollingFrameBgColor"] = Color3.fromRGB(47, 54, 64),
        ["ScrollBarImageColor"] = Color3.fromRGB(127, 143, 166),
        ["InputBackgroundColor"] = Color3.fromRGB(53, 59, 72),
        ["InputBorderColor"] = Color3.fromRGB(113, 128, 147),
        ["InputTextColor"] = Color3.fromRGB(220, 221, 225)
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
    ["AutoScroll"] = true,
    ["MaxDisplayedRemotes"] = 200
}

-- Layanan Roblox
local HttpService = game:GetService("HttpService")
local TextService = game:GetService("TextService")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

-- Variabel Global
local client = Players.LocalPlayer
local mouse = nil
if client then mouse = client:GetMouse() end

local executorName = "Unknown"
local getThreadContextFunc = function() return 7 end -- Default aman
local setThreadContextFunc = function() end -- Default aman
local getCallingScriptFunc = function() return getfenv(0).script end -- Fallback umum
local decompileFunc = function() return "-- Decompilation not reliably available" end
local getNamecallMethodFunc = function() return "" end

-- Deteksi Executor Sederhana & Penyesuaian Fungsi
if syn and syn.protect_gui then
    executorName = "Synapse X"
    getThreadContextFunc = syn.get_thread_identity
    setThreadContextFunc = syn.set_thread_identity
    if getcallingscript then getCallingScriptFunc = getcallingscript end
    if decompile then decompileFunc = decompile end
    if getnamecallmethod then getNamecallMethodFunc = getnamecallmethod end
    print("TurtleSpy: Synapse X detected.")
elseif PROTOSMASHER_LOADED then
    executorName = "ProtoSmasher"
    if get_thread_context then getThreadContextFunc = get_thread_context end
    if set_thread_context then setThreadContextFunc = set_thread_context end
    -- getCallingScriptFunc sudah diatur ke fallback umum
    -- decompileFunc sudah diatur ke fallback umum
    if get_namecall_method then getNamecallMethodFunc = get_namecall_method end
    print("TurtleSpy: ProtoSmasher detected.")
elseif typeof(Arceus) == "table" or typeof(getgenv().Arceus) == "table" then
    executorName = "Arceus X"
    -- Fungsi lain menggunakan fallback default yang seharusnya lebih aman untuk Arceus X
    print("TurtleSpy: Arceus X detected (or similar). Using general fallbacks.")
else
    print("TurtleSpy: Executor tidak dikenal. Menggunakan fallback umum.")
end

-- Fungsi File I/O (gunakan global jika ada, jika tidak, fallback ke io)
local function safeIsFile(path)
    local success, result = pcall(isfile, path)
    if success then return result end
    local f_success, f_result = pcall(io.open, path, "r")
    if f_success and f_result then f_result:close(); return true end
    return false
end

local function safeReadFile(path)
    local success, result = pcall(readfile, path)
    if success then return result end
    local f_success, f_handle = pcall(io.open, path, "r")
    if f_success and f_handle then
        local content_success, content = pcall(f_handle.read, f_handle, "*a")
        pcall(f_handle.close, f_handle)
        if content_success then return content end
    end
    warn("TurtleSpy: safeReadFile failed for path: ", path)
    return nil
end

local function safeWriteFile(path, content)
    local success, result = pcall(writefile, path, content)
    if success then return result end
    local f_success, f_handle = pcall(io.open, path, "w")
    if f_success and f_handle then
        local write_success, write_err = pcall(f_handle.write, f_handle, content)
        pcall(f_handle.close, f_handle)
        if write_success then return true end
        warn("TurtleSpy: safeWriteFile (io) error: ", write_err)
    else
        warn("TurtleSpy: safeWriteFile (io) open error: ", f_handle)
    end
    return false
end

-- Muat atau buat file pengaturan
local settingsFileName = "TurtleSpySettings_v2.json"
if not safeIsFile(settingsFileName) then
    local success, err = pcall(safeWriteFile, settingsFileName, HttpService:JSONEncode(settings))
    if not success then warn("TurtleSpy: Gagal menyimpan pengaturan awal:", err) end
else
    local success, currentSettingsJson = pcall(safeReadFile, settingsFileName)
    if success and currentSettingsJson then
        local decodedSuccess, decodedSettings = pcall(HttpService.JSONDecode, HttpService, currentSettingsJson)
        if decodedSuccess then
            for k, v in pairs(settings) do
                if decodedSettings[k] == nil then
                    decodedSettings[k] = v
                end
            end
            settings = decodedSettings
            local resaveSuccess, resaveErr = pcall(safeWriteFile, settingsFileName, HttpService:JSONEncode(settings))
            if not resaveSuccess then warn("TurtleSpy: Gagal menyimpan ulang pengaturan:", resaveErr) end
        else
            warn("TurtleSpy: Gagal mendekode pengaturan, menggunakan default:", decodedSettings)
            pcall(safeWriteFile, settingsFileName .. ".backup", currentSettingsJson)
            pcall(safeWriteFile, settingsFileName, HttpService:JSONEncode(settings))
        end
    else
        warn("TurtleSpy: Gagal membaca file pengaturan, menggunakan default:", currentSettingsJson)
        pcall(safeWriteFile, settingsFileName, HttpService:JSONEncode(settings))
    end
end
print("TurtleSpy: Pengaturan dimuat.")

-- Fungsi Utilitas
local function toUnicode(str)
    if not str then return "utf8.char()" end
    local codepoints = "utf8.char("
    local success, codes = pcall(utf8.codes, str)
    if not success or not codes then return "utf8.char()" end
    for _i, v in ipairs(codes) do codepoints = codepoints .. v .. ', ' end
    return codepoints:sub(1, -3) .. ')'
end

local function GetFullPathOfAnInstance(instance)
    if not instance then return "nil" end
    if not instance.Parent then
        if instance == game then return "game" end
        if instance == workspace then return "workspace" end
        if instance == CoreGui then return "game:GetService('CoreGui')" end
        if instance == Players then return "game:GetService('Players')" end
        if client and instance == client then return "game:GetService('Players').LocalPlayer" end
        return (instance.Name or "UnknownInstance") .. " --[[ PARENTED TO NIL OR DESTROYED ]]"
    end
    local path = {}
    local current = instance
    while current ~= game and current.Parent do
        local name = current.Name
        if string.match(name, "^[%w_]+$") and not tonumber(name:sub(1,1)) then
            table.insert(path, 1, "." .. name)
        else
            table.insert(path, 1, '["' .. name:gsub('"', '\\"'):gsub('\\', '\\\\') .. '"]')
        end
        if current.Parent == game then
            local isService = false
            local sucGetService, serviceInstance = pcall(game.GetService, game, current.ClassName)
            if sucGetService and serviceInstance == current then
                table.remove(path, 1)
                table.insert(path, 1, ':GetService("' .. current.ClassName .. '")')
                isService = true
            end
            if not isService and #path > 0 and path[1]:sub(1,1) == "." then path[1] = path[1]:sub(2) end
            table.insert(path, 1, "game")
            break 
        end
        current = current.Parent
        if not current then break end
    end
    local resultPath = table.concat(path, "")
    resultPath = resultPath:gsub("^game%.%.", "game.") -- Perbaikan untuk duplikasi titik
    return resultPath
end
print("TurtleSpy: Fungsi utilitas siap.")

-- Hapus instance TurtleSpyGUI sebelumnya
pcall(function()
    local oldGui = CoreGui:FindFirstChild("TurtleSpyGUI_V2")
    if oldGui then oldGui:Destroy(); print("TurtleSpy: GUI lama dihapus.") end
end)

-- Variabel dan Tabel Penting GUI
local buttonOffset = -25
local scrollSizeOffset = 287 
local functionImage = "http://www.roblox.com/asset/?id=413369623"
local eventImage = "http://www.roblox.com/asset/?id=413369506"
local remoteData = {} 
local IgnoreList = {} 
local BlockList = {} 
local unstackedRemotes = {} 
local activeConnections = {} 

-- GUI Elements 
local TurtleSpyGUI = Instance.new("ScreenGui")
local mainFrame = Instance.new("Frame")
local Header = Instance.new("Frame")
local HeaderShading = Instance.new("Frame")
local HeaderTextLabel = Instance.new("TextLabel")
local RemoteScrollFrame = Instance.new("ScrollingFrame")
local RemoteButtonTemplate = Instance.new("TextButton") 
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
local ArgumentEditorFrame = Instance.new("Frame") 
local ArgumentEditorLabel = Instance.new("TextLabel")
local ArgumentEditorTextBox = Instance.new("TextBox") 
local ApplyArgumentsButton = Instance.new("TextButton") 
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
local CopyFullPathButton = Instance.new("TextButton") 
local OpenInfoFrameButton = Instance.new("TextButton")
local MinimizeButton = Instance.new("TextButton")
local FilterTextBox = Instance.new("TextBox") 
local SaveSessionButton = Instance.new("TextButton")
local LoadSessionButton = Instance.new("TextButton")
local UnstackAllButton = Instance.new("TextButton") 
local HookSettingsFrame = Instance.new("Frame")
local ToggleFireServerHookButton = Instance.new("TextButton")
local ToggleInvokeServerHookButton = Instance.new("TextButton")
local ToggleNamecallHookButton = Instance.new("TextButton")
local BrowserHeader = Instance.new("Frame")
local BrowserHeaderFrame = Instance.new("Frame")
local BrowserHeaderText = Instance.new("TextLabel")
local CloseBrowserButton = Instance.new("TextButton")
local RemoteBrowserFrame = Instance.new("ScrollingFrame")
local RemoteButtonBrowserTemplate = Instance.new("TextButton")
local RemoteNameBrowserTemplate = Instance.new("TextLabel")
local RemoteIconBrowserTemplate = Instance.new("ImageLabel")
local OpenBrowserButton = Instance.new("ImageButton") 
print("TurtleSpy: Variabel GUI dideklarasikan.")

-- Fungsi Parent GUI yang Ditingkatkan
local function ParentGUI(guiInstance)
    if syn and syn.protect_gui then
        pcall(syn.protect_gui, guiInstance) -- Bungkus dengan pcall untuk keamanan
    end
    -- Selalu parent ke CoreGui sebagai fallback atau default
    guiInstance.Parent = CoreGui
    print("TurtleSpy: GUI diparenting ke CoreGui.")
end

-- Inisialisasi GUI Utama
TurtleSpyGUI.Name = "TurtleSpyGUI_V2"
TurtleSpyGUI.ResetOnSpawn = false -- PENTING: Sesuai referensi user untuk Arceus X
TurtleSpyGUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling 
ParentGUI(TurtleSpyGUI) -- Panggil setelah properti dasar ScreenGui diatur

-- Fungsi untuk membuat UI 
local function CreateUI()
    pcall(function() -- Bungkus seluruh pembuatan UI dalam pcall
        mainFrame.Name = "mainFrame"
        mainFrame.Parent = TurtleSpyGUI
        mainFrame.BackgroundColor3 = colorSettings["Main"]["MainBackgroundColor"]
        mainFrame.BorderColor3 = colorSettings["Main"]["HeaderShadingColor"] 
        mainFrame.BorderSizePixel = 1
        mainFrame.Position = UDim2.new(0.1, 0, 0.15, 0) 
        mainFrame.Size = UDim2.new(0, 220, 0, 35) 
        mainFrame.ZIndex = 1000
        mainFrame.Active = true
        mainFrame.Draggable = true

        Header.Name = "Header"
        Header.Parent = mainFrame
        Header.BackgroundColor3 = colorSettings["Main"]["HeaderColor"]
        Header.BorderSizePixel = 0
        Header.Size = UDim2.new(1, 0, 0, 26)
        Header.ZIndex = 1001

        HeaderShading.Name = "HeaderShading" 
        HeaderShading.Parent = Header
        HeaderShading.BackgroundColor3 = colorSettings["Main"]["HeaderShadingColor"]
        HeaderShading.BorderSizePixel = 0
        HeaderShading.Position = UDim2.new(0, 0, 1, -1) 
        HeaderShading.Size = UDim2.new(1, 0, 0, 1)
        HeaderShading.ZIndex = 1000 

        HeaderTextLabel.Name = "HeaderTextLabel"
        HeaderTextLabel.Parent = Header
        HeaderTextLabel.BackgroundTransparency = 1.000
        HeaderTextLabel.Size = UDim2.new(1, -80, 1, 0) 
        HeaderTextLabel.Position = UDim2.new(0, 5, 0, 0)
        HeaderTextLabel.ZIndex = 1002
        HeaderTextLabel.Font = Enum.Font.SourceSansSemibold
        HeaderTextLabel.Text = "TurtleSpy V2"
        HeaderTextLabel.TextColor3 = colorSettings["Main"]["HeaderTextColor"]
        HeaderTextLabel.TextSize = 16.000
        HeaderTextLabel.TextXAlignment = Enum.TextXAlignment.Left

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
        OpenBrowserButton.Image = "rbxassetid://169476802" 
        OpenBrowserButton.ImageColor3 = colorSettings["Main"]["HeaderTextColor"]
        OpenBrowserButton.ScaleType = Enum.ScaleType.Fit

        FilterTextBox.Name = "FilterTextBox"
        FilterTextBox.Parent = mainFrame
        FilterTextBox.BackgroundColor3 = colorSettings["Main"]["InputBackgroundColor"]
        FilterTextBox.BorderColor3 = colorSettings["Main"]["InputBorderColor"]
        FilterTextBox.Position = UDim2.new(0.05, 0, 1, 5) 
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
        RemoteScrollFrame.Position = UDim2.new(0, 0, 1, 35) 
        RemoteScrollFrame.Size = UDim2.new(1, 0, 0, 286) 
        RemoteScrollFrame.CanvasSize = UDim2.new(0, 0, 0, scrollSizeOffset)
        RemoteScrollFrame.ScrollBarThickness = 8
        RemoteScrollFrame.VerticalScrollBarPosition = Enum.VerticalScrollBarPosition.Left
        RemoteScrollFrame.ScrollBarImageColor3 = colorSettings["Main"]["ScrollBarImageColor"]
        RemoteScrollFrame.ZIndex = 1000

        RemoteButtonTemplate.Name = "RemoteButtonTemplate"
        RemoteButtonTemplate.BackgroundColor3 = colorSettings["RemoteButtons"]["BackgroundColor"]
        RemoteButtonTemplate.BorderColor3 = colorSettings["RemoteButtons"]["BorderColor"]
        RemoteButtonTemplate.Size = UDim2.new(1, -10, 0, 28) 
        RemoteButtonTemplate.Font = Enum.Font.SourceSans
        RemoteButtonTemplate.Text = ""
        RemoteButtonTemplate.TextColor3 = colorSettings["RemoteButtons"]["TextColor"]
        RemoteButtonTemplate.TextSize = 1.000 
        RemoteButtonTemplate.TextWrapped = true
        RemoteButtonTemplate.TextXAlignment = Enum.TextXAlignment.Left
        RemoteButtonTemplate.ZIndex = 1001

        NumberLabelTemplate.Name = "NumberLabel"
        NumberLabelTemplate.Parent = RemoteButtonTemplate
        NumberLabelTemplate.BackgroundTransparency = 1.000
        NumberLabelTemplate.Position = UDim2.new(0, 5, 0, 0)
        NumberLabelTemplate.Size = UDim2.new(0, 30, 1, 0) 
        NumberLabelTemplate.ZIndex = 1002
        NumberLabelTemplate.Font = Enum.Font.SourceSans
        NumberLabelTemplate.Text = "1"
        NumberLabelTemplate.TextColor3 = colorSettings["RemoteButtons"]["NumberTextColor"]
        NumberLabelTemplate.TextSize = 15.000
        NumberLabelTemplate.TextXAlignment = Enum.TextXAlignment.Left

        RemoteNameLabelTemplate.Name = "RemoteNameLabel"
        RemoteNameLabelTemplate.Parent = RemoteButtonTemplate
        RemoteNameLabelTemplate.BackgroundTransparency = 1.000
        RemoteNameLabelTemplate.Position = UDim2.new(0, 30, 0, 0) 
        RemoteNameLabelTemplate.Size = UDim2.new(1, -60, 1, 0) 
        RemoteNameLabelTemplate.Font = Enum.Font.SourceSansSemibold
        RemoteNameLabelTemplate.Text = "RemoteEventName"
        RemoteNameLabelTemplate.TextColor3 = colorSettings["RemoteButtons"]["TextColor"]
        RemoteNameLabelTemplate.TextSize = 15.000
        RemoteNameLabelTemplate.TextXAlignment = Enum.TextXAlignment.Left
        RemoteNameLabelTemplate.TextTruncate = Enum.TextTruncate.AtEnd

        RemoteIconTemplate.Name = "RemoteIcon"
        RemoteIconTemplate.Parent = RemoteButtonTemplate
        RemoteIconTemplate.BackgroundTransparency = 1.000
        RemoteIconTemplate.Position = UDim2.new(1, -28, 0.5, -12) 
        RemoteIconTemplate.Size = UDim2.new(0, 24, 0, 24)
        RemoteIconTemplate.ZIndex = 1002
        RemoteIconTemplate.Image = eventImage 

        InfoFrame.Name = "InfoFrame"
        InfoFrame.Parent = mainFrame
        InfoFrame.BackgroundColor3 = colorSettings["Main"]["InfoScrollingFrameBgColor"]
        InfoFrame.BorderColor3 = colorSettings["Main"]["HeaderShadingColor"]
        InfoFrame.BorderSizePixel = 1
        InfoFrame.Position = UDim2.new(1, 5, 0, 0) 
        InfoFrame.Size = UDim2.new(0, 380, 1, 0) 
        InfoFrame.Visible = false
        InfoFrame.ZIndex = 999 
        InfoFrame.ClipsDescendants = true

        InfoFrameHeader.Name = "InfoFrameHeader"
        InfoFrameHeader.Parent = InfoFrame
        InfoFrameHeader.BackgroundColor3 = colorSettings["Main"]["HeaderColor"]
        InfoFrameHeader.BorderSizePixel = 0
        InfoFrameHeader.Size = UDim2.new(1, 0, 0, 26)
        InfoFrameHeader.ZIndex = 1011

        InfoTitleShading.Name = "InfoTitleShading" 
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
        CodeFrame.CanvasSize = UDim2.new(2, 0, 1, 0) 
        CodeFrame.ScrollBarThickness = 6
        CodeFrame.ScrollingDirection = Enum.ScrollingDirection.X
        CodeFrame.ScrollBarImageColor3 = colorSettings["Main"]["ScrollBarImageColor"]

        CodeCommentTextLabel.Name = "CodeCommentTextLabel"
        CodeCommentTextLabel.Parent = CodeFrame
        CodeCommentTextLabel.BackgroundTransparency = 1.000
        CodeCommentTextLabel.Position = UDim2.new(0, 5, 0, 2)
        CodeCommentTextLabel.Size = UDim2.new(0, 10000, 0, 18) 
        CodeCommentTextLabel.ZIndex = 1011
        CodeCommentTextLabel.Font = Enum.Font.Code 
        CodeCommentTextLabel.Text = "-- Script generated by TurtleSpy V2, enhanced by Gemini. Original by Intrer#0421"
        CodeCommentTextLabel.TextColor3 = colorSettings["Code"]["CreditsColor"]
        CodeCommentTextLabel.TextSize = 13.000
        CodeCommentTextLabel.TextXAlignment = Enum.TextXAlignment.Left

        CodeTextLabel.Name = "CodeTextLabel"
        CodeTextLabel.Parent = CodeFrame
        CodeTextLabel.BackgroundTransparency = 1.000
        CodeTextLabel.Position = UDim2.new(0, 5, 0, 20)
        CodeTextLabel.Size = UDim2.new(0, 10000, 0, 40) 
        CodeTextLabel.ZIndex = 1011
        CodeTextLabel.Font = Enum.Font.Code
        CodeTextLabel.Text = "game:GetService('ReplicatedStorage').RemoteEvent:FireServer(...)"
        CodeTextLabel.TextColor3 = colorSettings["Code"]["TextColor"]
        CodeTextLabel.TextSize = 14.000
        CodeTextLabel.TextWrapped = false 
        CodeTextLabel.TextXAlignment = Enum.TextXAlignment.Left
        CodeTextLabel.ClipsDescendants = false

        ArgumentEditorFrame.Name = "ArgumentEditorFrame"
        ArgumentEditorFrame.Parent = InfoFrame
        ArgumentEditorFrame.BackgroundColor3 = colorSettings["Code"]["BackgroundColor"]
        ArgumentEditorFrame.BorderColor3 = colorSettings["Main"]["HeaderShadingColor"]
        ArgumentEditorFrame.BorderSizePixel = 1
        ArgumentEditorFrame.Position = UDim2.new(0.025, 0, 0, 100) 
        ArgumentEditorFrame.Size = UDim2.new(0.95, 0, 0, 100) 
        ArgumentEditorFrame.ZIndex = 1010
        ArgumentEditorFrame.Visible = true 

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
        ArgumentEditorTextBox.Size = UDim2.new(0.95, 0, 1, -50) 
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
        ApplyArgumentsButton.Position = UDim2.new(0.5, -50, 1, -28) 
        ApplyArgumentsButton.Size = UDim2.new(0, 100, 0, 22)
        ApplyArgumentsButton.ZIndex = 1012
        ApplyArgumentsButton.Font = Enum.Font.SourceSans
        ApplyArgumentsButton.Text = "Terapkan & Jalankan"
        ApplyArgumentsButton.TextColor3 = colorSettings["MainButtons"]["TextColor"]
        ApplyArgumentsButton.TextSize = 13.000

        InfoButtonsScroll.Name = "InfoButtonsScroll"
        InfoButtonsScroll.Parent = InfoFrame
        InfoButtonsScroll.Active = true
        InfoButtonsScroll.BackgroundColor3 = colorSettings["Main"]["InfoScrollingFrameBgColor"]
        InfoButtonsScroll.BorderSizePixel = 0
        InfoButtonsScroll.Position = UDim2.new(0.025, 0, 0, 205) 
        InfoButtonsScroll.Size = UDim2.new(0.95, 0, 1, -210) 
        InfoButtonsScroll.ZIndex = 1009
        InfoButtonsScroll.CanvasSize = UDim2.new(0, 0, 2, 0) 
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
        RunCodeButton = createInfoButton("RunCodeButton", "Jalankan Kode Asli", buttonYOffset) 
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
        CopyReturnValueButton.Visible = false 
        
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

        globalButtonY = globalButtonY + 25 + 10 

        HookSettingsFrame.Name = "HookSettingsFrame"
        HookSettingsFrame.Parent = mainFrame
        HookSettingsFrame.BackgroundTransparency = 1.0
        HookSettingsFrame.Position = UDim2.new(0.05, 0, 1, RemoteScrollFrame.Size.Y.Offset + FilterTextBox.Size.Y.Offset + globalButtonY + 40)
        HookSettingsFrame.Size = UDim2.new(0.9, 0, 0, 30)
        HookSettingsFrame.ZIndex = 1001
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
            button.Size = UDim2.new(0.31, 0, 1, 0) 
            button.Font = Enum.Font.SourceSans
            button.Text = text .. (initialActive and " (Aktif)" or " (Nonaktif)")
            button.TextColor3 = colorSettings["MainButtons"]["TextColor"]
            button.TextSize = 11.000
            button.ZIndex = 1002
            button._isActive = initialActive 
            return button
        end

        ToggleFireServerHookButton = createHookToggleButton("ToggleFireServerHook", "FireServer", true)
        ToggleInvokeServerHookButton = createHookToggleButton("ToggleInvokeServerHook", "InvokeServer", true)
        ToggleNamecallHookButton = createHookToggleButton("ToggleNamecallHook", "Namecall", true)
        
        local totalBottomUIHeight = FilterTextBox.Size.Y.Offset + 5 + RemoteScrollFrame.Size.Y.Offset + 5 + ClearLogsButton.Size.Y.Offset + 5 + SaveSessionButton.Size.Y.Offset + 5 + HookSettingsFrame.Size.Y.Offset + 10
        mainFrame.Size = UDim2.new(0, 220, 0, 35 + totalBottomUIHeight) 
        RemoteScrollFrame.Size = UDim2.new(1,0,0, mainFrame.Size.Y.Offset - (35 + FilterTextBox.Size.Y.Offset + 5 + ClearLogsButton.Size.Y.Offset + 5 + SaveSessionButton.Size.Y.Offset + 5 + HookSettingsFrame.Size.Y.Offset + 10))

        BrowserHeader.Name = "BrowserHeader"
        BrowserHeader.Parent = TurtleSpyGUI
        BrowserHeader.BackgroundColor3 = colorSettings["Main"]["HeaderShadingColor"]
        BrowserHeader.BorderColor3 = colorSettings["Main"]["HeaderShadingColor"]
        BrowserHeader.Position = UDim2.new(0.5, -103, 0.1, 0) 
        BrowserHeader.Size = UDim2.new(0, 207, 0, 33)
        BrowserHeader.ZIndex = 1999
        BrowserHeader.Active = true
        BrowserHeader.Draggable = true
        BrowserHeader.Visible = false 

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
        print("TurtleSpy: CreateUI() selesai.")
    end)
end
CreateUI() 

-- Variabel Status GUI
local isInfoFrameOpen = false
local isMainFrameMinimized = false
local currentRemoteLookingAt = nil 
local currentRemoteDataKey = nil 

-- Fungsi Utilitas GUI
local function IsValid(instance) 
    return instance and pcall(function() return instance.Parent end) -- Cara lebih aman untuk cek Parent
end

local function ButtonEffect(button, text, success)
    if not button or not IsValid(button) then return end
    local originalText = button.Text
    local originalColor = button.TextColor3
    local originalBgColor = button.BackgroundColor3

    button.Text = text or "Berhasil!"
    if success == true then
        button.TextColor3 = Color3.fromRGB(255, 255, 255)
        button.BackgroundColor3 = Color3.fromRGB(76, 209, 55) 
    elseif success == false then
        button.TextColor3 = Color3.fromRGB(255, 255, 255)
        button.BackgroundColor3 = Color3.fromRGB(232, 65, 24) 
    else 
        button.TextColor3 = Color3.fromRGB(76, 209, 55) 
    end
    
    task.delay(1.2, function() -- Menggunakan task.delay
        if button and IsValid(button) then
            button.Text = originalText
            button.TextColor3 = originalColor
            button.BackgroundColor3 = originalBgColor
        end
    end)
end

local function UpdateInfoFrame(remoteInstance, dataKey)
    if not remoteInstance or not IsValid(remoteInstance) or not remoteData[dataKey] then
        if InfoFrame and IsValid(InfoFrame) then InfoFrame.Visible = false end
        isInfoFrameOpen = false
        if OpenInfoFrameButton and IsValid(OpenInfoFrameButton) then OpenInfoFrameButton.Text = ">" end
        currentRemoteLookingAt = nil
        currentRemoteDataKey = nil
        return
    end

    currentRemoteLookingAt = remoteInstance
    currentRemoteDataKey = dataKey
    local data = remoteData[dataKey]

    if InfoHeaderText and IsValid(InfoHeaderText) then InfoHeaderText.Text = "Info: " .. remoteInstance.Name end
    local isFunc = remoteInstance:IsA("RemoteFunction")
    if CopyReturnValueButton and IsValid(CopyReturnValueButton) then CopyReturnValueButton.Visible = isFunc end
    
    local fireMethod = isFunc and ":InvokeServer(" or ":FireServer("
    local currentArgs = data.argsHistory[#data.argsHistory] 
    
    local success, codeStr = pcall(convertTableToString, currentArgs, true)
    if not success then codeStr = "{ --[[ Error converting args: " .. tostring(codeStr) .. " ]] }" end

    if CodeTextLabel and IsValid(CodeTextLabel) then CodeTextLabel.Text = GetFullPathOfAnInstance(remoteInstance) .. fireMethod .. codeStr .. ")" end
    
    local successArgsEdit, argsEditStr = pcall(convertTableToString, currentArgs, true, 2) 
    if not successArgsEdit then argsEditStr = "{ --[[ Error converting args: " .. tostring(argsEditStr) .. " ]] }" end
    if ArgumentEditorTextBox and IsValid(ArgumentEditorTextBox) then ArgumentEditorTextBox.Text = argsEditStr end

    if CodeTextLabel and IsValid(CodeTextLabel) and TextService and IsValid(TextService) and CodeFrame and IsValid(CodeFrame) then
        local textSizeSuccess, textSize = pcall(TextService.GetTextSize, TextService, CodeTextLabel.Text, CodeTextLabel.TextSize, CodeTextLabel.Font, Vector2.new(math.huge, CodeTextLabel.AbsoluteSize.Y))
        if textSizeSuccess and textSize then
            CodeTextLabel.Size = UDim2.new(0, textSize.X + 20, 0, CodeTextLabel.Size.Y.Offset) 
            CodeFrame.CanvasSize = UDim2.new(0, textSize.X + 30, 0, CodeFrame.CanvasSize.Y.Scale > 0 and CodeFrame.CanvasSize.Y.Scale or 1) 
        end
    end

    if IgnoreRemoteButton and IsValid(IgnoreRemoteButton) then
        IgnoreRemoteButton.Text = table.find(IgnoreList, remoteInstance) and "Berhenti Mengabaikan" or "Abaikan Remote Ini"
        IgnoreRemoteButton.TextColor3 = table.find(IgnoreList, remoteInstance) and Color3.fromRGB(251, 197, 49) or colorSettings["MainButtons"]["TextColor"]
    end
    if BlockRemoteButton and IsValid(BlockRemoteButton) then
        BlockRemoteButton.Text = table.find(BlockList, remoteInstance) and "Buka Blokir Remote" or "Blokir Remote Ini"
        BlockRemoteButton.TextColor3 = table.find(BlockList, remoteInstance) and Color3.fromRGB(251, 197, 49) or colorSettings["MainButtons"]["TextColor"]
    end
    if UnstackRemoteButton and IsValid(UnstackRemoteButton) then
        UnstackRemoteButton.Text = table.find(unstackedRemotes, remoteInstance) and "Stack Remote Ini" or "Unstack Remote (Argumen Baru)"
        UnstackRemoteButton.TextColor3 = table.find(unstackedRemotes, remoteInstance) and Color3.fromRGB(251, 197, 49) or colorSettings["MainButtons"]["TextColor"]
    end

    if not isInfoFrameOpen and InfoFrame and IsValid(InfoFrame) and mainFrame and IsValid(mainFrame) and OpenInfoFrameButton and IsValid(OpenInfoFrameButton) then
        InfoFrame.Visible = true
        isInfoFrameOpen = true
        OpenInfoFrameButton.Text = "<"
        mainFrame.Size = UDim2.new(0, mainFrame.Size.X.Offset + InfoFrame.Size.X.Offset + 5, 0, mainFrame.Size.Y.Offset)
        InfoFrame.ZIndex = 1000 
    end
end

function convertTableToString(tbl, prettyPrint, indentLevel, visited)
    local typeTbl = type(tbl)
    if typeTbl ~= "table" then
        if typeTbl == "string" then
            return '"' .. tbl:gsub("\\", "\\\\"):gsub('"', '\\"'):gsub("\n", "\\n"):gsub("\r", "\\r") .. '"'
        elseif typeTbl == "Instance" then
            return IsValid(tbl) and GetFullPathOfAnInstance(tbl) or "nil --[[ Instance dihancurkan ]]"
        elseif typeTbl == "EnumItem" then
            return "Enum." .. tbl.EnumType.Name .. "." .. tbl.Name
        elseif typeTbl == "nil" then
            return "nil"
        else
            return tostring(tbl)
        end
    end
    visited = visited or {}
    if visited[tbl] then return "{ --[[ Referensi siklik detectée ]] }" end
    visited[tbl] = true
    indentLevel = indentLevel or 0
    local str = "{"
    local first = true
    local indentStr = prettyPrint and string.rep("  ", indentLevel + 1) or ""
    local newLine = prettyPrint and "\n" or ""
    local space = prettyPrint and " " or ""
    local isArray = true
    local count = 0
    for _ in pairs(tbl) do count = count + 1 end
    if count > 0 then 
        for i = 1, count do if tbl[i] == nil then isArray = false; break end end
        if count ~= #tbl then isArray = false end 
    else isArray = (#tbl == 0) end
    if isArray then
        for i = 1, #tbl do
            if not first then str = str .. "," .. space end
            str = str .. newLine .. indentStr .. convertTableToString(tbl[i], prettyPrint, indentLevel + 1, visited)
            first = false
        end
    else 
        for k, v in pairs(tbl) do
            if not first then str = str .. "," .. space end
            local keyStr
            if type(k) == "string" and k:match("^[%a_][%w_]*$") then keyStr = k
            else keyStr = "[" .. convertTableToString(k, false, 0, {}) .. "]" end
            str = str .. newLine .. indentStr .. keyStr .. space .. "=" .. space .. convertTableToString(v, prettyPrint, indentLevel + 1, visited)
            first = false
        end
    end
    visited[tbl] = nil 
    str = str .. newLine .. (prettyPrint and count > 0 and string.rep("  ", indentLevel) or "") .. "}"
    return str
end

local function parseArgumentsString(argsString)
    local success, func = pcall(loadstring, "return " .. argsString)
    if not success or not func then
        warn("TurtleSpy: Gagal mem-parse string argumen:", func) 
        return nil, "Error parsing: " .. (func or "unknown error")
    end
    local env = getfenv(0) 
    if not env.Enum then env.Enum = Enum end
    if not env.game then env.game = game end 
    if not env.workspace then env.workspace = workspace end
    local setEnvSuccess, _ = pcall(setfenv, func, env) 
    if not setEnvSuccess then warn("TurtleSpy: Gagal mengatur environment untuk parser argumen.") end
    local execSuccess, result = pcall(func)
    if not execSuccess then
        warn("TurtleSpy: Gagal mengeksekusi string argumen yang diparsing:", result)
        return nil, "Error executing: " .. (result or "unknown error")
    end
    if type(result) ~= "table" then 
        if result == nil and argsString:match("^%s*nil%s*$") then return {}, nil end 
        if result == nil and argsString:match("^%s*%{%s*%}%s*$") then return {}, nil end 
        if type(result) ~= "nil" then return {result}, nil end
        return nil, "Hasil parsing bukan tabel yang valid."
    end
    return result, nil
end

MinimizeButton.MouseButton1Click:Connect(function()
    isMainFrameMinimized = not isMainFrameMinimized
    if isMainFrameMinimized then
        if IsValid(RemoteScrollFrame) then RemoteScrollFrame.Visible = false end
        if IsValid(FilterTextBox) then FilterTextBox.Visible = false end
        if IsValid(ClearLogsButton) then ClearLogsButton.Visible = false end
        if IsValid(UnstackAllButton) then UnstackAllButton.Visible = false end
        if IsValid(SaveSessionButton) then SaveSessionButton.Visible = false end
        if IsValid(LoadSessionButton) then LoadSessionButton.Visible = false end
        if IsValid(HookSettingsFrame) then HookSettingsFrame.Visible = false end
        if IsValid(Header) and IsValid(mainFrame) then
            local headerHeight = Header.AbsoluteSize.Y
            mainFrame.Size = UDim2.new(0, mainFrame.Size.X.Offset, 0, headerHeight)
        end
        if IsValid(MinimizeButton) then MinimizeButton.Text = "O" end
        if isInfoFrameOpen and IsValid(InfoFrame) then InfoFrame.Visible = false end
    else
        if IsValid(RemoteScrollFrame) then RemoteScrollFrame.Visible = true end
        if IsValid(FilterTextBox) then FilterTextBox.Visible = true end
        if IsValid(ClearLogsButton) then ClearLogsButton.Visible = true end
        if IsValid(UnstackAllButton) then UnstackAllButton.Visible = true end
        if IsValid(SaveSessionButton) then SaveSessionButton.Visible = true end
        if IsValid(LoadSessionButton) then LoadSessionButton.Visible = true end
        if IsValid(HookSettingsFrame) then HookSettingsFrame.Visible = true end
        if IsValid(Header) and IsValid(FilterTextBox) and IsValid(RemoteScrollFrame) and IsValid(ClearLogsButton) and IsValid(SaveSessionButton) and IsValid(HookSettingsFrame) and IsValid(mainFrame) then
            local totalBottomUIHeight = FilterTextBox.Size.Y.Offset + 5 + RemoteScrollFrame.Size.Y.Offset + 5 + ClearLogsButton.Size.Y.Offset + 5 + SaveSessionButton.Size.Y.Offset + 5 + HookSettingsFrame.Size.Y.Offset + 10
            local fullHeight = Header.AbsoluteSize.Y + totalBottomUIHeight
            mainFrame.Size = UDim2.new(0, mainFrame.Size.X.Offset, 0, fullHeight)
            RemoteScrollFrame.Size = UDim2.new(1,0,0, mainFrame.Size.Y.Offset - (Header.AbsoluteSize.Y + FilterTextBox.Size.Y.Offset + 5 + ClearLogsButton.Size.Y.Offset + 5 + SaveSessionButton.Size.Y.Offset + 5 + HookSettingsFrame.Size.Y.Offset + 10))
        end
        if IsValid(MinimizeButton) then MinimizeButton.Text = "_" end
        if isInfoFrameOpen and IsValid(InfoFrame) then InfoFrame.Visible = true end
    end
end)

OpenInfoFrameButton.MouseButton1Click:Connect(function()
    if isMainFrameMinimized then return end 
    isInfoFrameOpen = not isInfoFrameOpen
    if IsValid(InfoFrame) then InfoFrame.Visible = isInfoFrameOpen end
    if isInfoFrameOpen then
        if IsValid(OpenInfoFrameButton) then OpenInfoFrameButton.Text = "<" end
        if IsValid(mainFrame) and IsValid(InfoFrame) then
             mainFrame.Size = UDim2.new(0, mainFrame.Size.X.Offset + InfoFrame.Size.X.Offset + 5, 0, mainFrame.Size.Y.Offset)
             InfoFrame.ZIndex = 1000 
        end
        if not currentRemoteLookingAt and IsValid(InfoHeaderText) and IsValid(CodeTextLabel) and IsValid(ArgumentEditorTextBox) then
            InfoHeaderText.Text = "Info: Tidak ada remote dipilih"
            CodeTextLabel.Text = "-- Pilih remote dari daftar untuk melihat detail --"
            ArgumentEditorTextBox.Text = "{}"
        end
    else
        if IsValid(OpenInfoFrameButton) then OpenInfoFrameButton.Text = ">" end
        if IsValid(mainFrame) and IsValid(InfoFrame) then
            mainFrame.Size = UDim2.new(0, mainFrame.Size.X.Offset - InfoFrame.Size.X.Offset - 5, 0, mainFrame.Size.Y.Offset)
            InfoFrame.ZIndex = 999
        end
    end
end)

CloseInfoFrameButton.MouseButton1Click:Connect(function()
    if isInfoFrameOpen then
        isInfoFrameOpen = false
        if IsValid(InfoFrame) then InfoFrame.Visible = false end
        if IsValid(OpenInfoFrameButton) then OpenInfoFrameButton.Text = ">" end
        if IsValid(mainFrame) and IsValid(InfoFrame) then
            mainFrame.Size = UDim2.new(0, mainFrame.Size.X.Offset - InfoFrame.Size.X.Offset - 5, 0, mainFrame.Size.Y.Offset)
            InfoFrame.ZIndex = 999
        end
        currentRemoteLookingAt = nil
        currentRemoteDataKey = nil
    end
end)

CopyCodeButton.MouseButton1Click:Connect(function()
    if currentRemoteLookingAt and IsValid(CodeTextLabel) and CodeTextLabel.Text ~= "" and IsValid(CodeCommentTextLabel) then
        local success, err = pcall(setclipboard, CodeCommentTextLabel.Text .. "\n\n" .. CodeTextLabel.Text)
        ButtonEffect(CopyCodeButton, success and "Kode Disalin!" or "Gagal Menyalin", success)
    else
        ButtonEffect(CopyCodeButton, "Tidak Ada Kode", false)
    end
end)

local function ExecuteRemote(remote, argsToExecute)
    if not remote or not IsValid(remote) then
        warn("TurtleSpy: Remote tidak valid untuk dieksekusi.")
        return nil, "Remote tidak valid"
    end
    local result = {}
    local successCall = false
    local callError = "Unknown error"
    local args = argsToExecute or {} 
    if remote:IsA("RemoteFunction") then
        successCall, result = pcall(remote.InvokeServer, remote, unpack(args))
        if not successCall then callError = tostring(result) end 
    elseif remote:IsA("RemoteEvent") then
        successCall, result = pcall(remote.FireServer, remote, unpack(args))
        if not successCall then callError = tostring(result) end
    else return nil, "Tipe remote tidak didukung" end
    if successCall then return result, nil else return nil, callError end
end

RunCodeButton.MouseButton1Click:Connect(function()
    if currentRemoteLookingAt and currentRemoteDataKey and remoteData[currentRemoteDataKey] then
        local data = remoteData[currentRemoteDataKey]
        local originalArgs = data.argsHistory[#data.argsHistory] 
        local _, err = ExecuteRemote(currentRemoteLookingAt, originalArgs)
        if err then ButtonEffect(RunCodeButton, "Gagal Eksekusi!", false); warn("TurtleSpy: Gagal menjalankan kode asli:", err)
        else ButtonEffect(RunCodeButton, "Kode Asli Dijalankan!", true) end
    else ButtonEffect(RunCodeButton, "Pilih Remote Dulu", false) end
end)

ApplyArgumentsButton.MouseButton1Click:Connect(function()
    if currentRemoteLookingAt and IsValid(ArgumentEditorTextBox) then
        local argsStr = ArgumentEditorTextBox.Text
        local parsedArgs, parseErr = parseArgumentsString(argsStr)
        if parseErr then ButtonEffect(ApplyArgumentsButton, "Error Argumen!", false); warn("TurtleSpy: Gagal mem-parse argumen yang diedit:", parseErr); return end
        local _, execErr = ExecuteRemote(currentRemoteLookingAt, parsedArgs) 
        if execErr then ButtonEffect(ApplyArgumentsButton, "Gagal Eksekusi!", false); warn("TurtleSpy: Gagal menjalankan dengan argumen yang diedit:", execErr)
        else ButtonEffect(ApplyArgumentsButton, "Dijalankan dg Arg Editan!", true) end
    else ButtonEffect(ApplyArgumentsButton, "Pilih Remote Dulu", false) end
end)

CopyScriptPathButton.MouseButton1Click:Connect(function()
    if currentRemoteLookingAt and currentRemoteDataKey and remoteData[currentRemoteDataKey] then
        local data = remoteData[currentRemoteDataKey]
        if data.callingScript and IsValid(data.callingScript) then
            local path = GetFullPathOfAnInstance(data.callingScript)
            local success, err = pcall(setclipboard, path)
            ButtonEffect(CopyScriptPathButton, success and "Path Script Disalin!" or "Gagal Menyalin", success)
        else ButtonEffect(CopyScriptPathButton, "Script Tidak Ditemukan", false) end
    else ButtonEffect(CopyScriptPathButton, "Pilih Remote Dulu", false) end
end)

CopyDecompiledButton.MouseButton1Click:Connect(function()
    if not decompileFunc then ButtonEffect(CopyDecompiledButton, "Decompile Tdk Tersedia", false); return end
    if currentRemoteLookingAt and currentRemoteDataKey and remoteData[currentRemoteDataKey] then
        local data = remoteData[currentRemoteDataKey]
        if data.callingScript and IsValid(data.callingScript) then
            if IsValid(CopyDecompiledButton) then CopyDecompiledButton.Text = "Mendekompilasi..." end
            local success, result = pcall(decompileFunc, data.callingScript)
            if success then
                local cbSuccess, _ = pcall(setclipboard, result)
                ButtonEffect(CopyDecompiledButton, cbSuccess and "Dekompilasi Disalin!" or "Gagal Menyalin Hasil", cbSuccess)
            else ButtonEffect(CopyDecompiledButton, "Gagal Dekompilasi", false); warn("TurtleSpy: Decompilation error:", result) end
            task.delay(1.5, function() if IsValid(CopyDecompiledButton) then CopyDecompiledButton.Text = "Salin Script Decompiled" end end)
        else ButtonEffect(CopyDecompiledButton, "Script Tidak Ditemukan", false) end
    else ButtonEffect(CopyDecompiledButton, "Pilih Remote Dulu", false) end
end)

CopyFullPathButton.MouseButton1Click:Connect(function()
    if currentRemoteLookingAt and IsValid(currentRemoteLookingAt) then
        local path = GetFullPathOfAnInstance(currentRemoteLookingAt)
        local success, err = pcall(setclipboard, path)
        ButtonEffect(CopyFullPathButton, success and "Path Instance Disalin!" or "Gagal Menyalin", success)
    else ButtonEffect(CopyFullPathButton, "Pilih Remote Dulu", false) end
end)

IgnoreRemoteButton.MouseButton1Click:Connect(function()
    if currentRemoteLookingAt then
        local index = table.find(IgnoreList, currentRemoteLookingAt)
        if index then
            table.remove(IgnoreList, index)
            if IsValid(IgnoreRemoteButton) then IgnoreRemoteButton.Text = "Abaikan Remote Ini"; IgnoreRemoteButton.TextColor3 = colorSettings["MainButtons"]["TextColor"] end
            ButtonEffect(IgnoreRemoteButton, "Berhenti Mengabaikan", true)
            if remoteData[currentRemoteDataKey] and IsValid(remoteData[currentRemoteDataKey].button) and IsValid(remoteData[currentRemoteDataKey].button.RemoteNameLabel) then
                 remoteData[currentRemoteDataKey].button.RemoteNameLabel.TextColor3 = colorSettings["RemoteButtons"]["TextColor"] end
        else
            table.insert(IgnoreList, currentRemoteLookingAt)
            if IsValid(IgnoreRemoteButton) then IgnoreRemoteButton.Text = "Berhenti Mengabaikan"; IgnoreRemoteButton.TextColor3 = Color3.fromRGB(251, 197, 49) end
            ButtonEffect(IgnoreRemoteButton, "Remote Diabaikan", true)
            if remoteData[currentRemoteDataKey] and IsValid(remoteData[currentRemoteDataKey].button) and IsValid(remoteData[currentRemoteDataKey].button.RemoteNameLabel) then
                 remoteData[currentRemoteDataKey].button.RemoteNameLabel.TextColor3 = Color3.fromRGB(127, 143, 166) end
        end
    else ButtonEffect(IgnoreRemoteButton, "Pilih Remote Dulu", false) end
end)

BlockRemoteButton.MouseButton1Click:Connect(function()
    if currentRemoteLookingAt then
        local index = table.find(BlockList, currentRemoteLookingAt)
        if index then
            table.remove(BlockList, index)
            if IsValid(BlockRemoteButton) then BlockRemoteButton.Text = "Blokir Remote Ini"; BlockRemoteButton.TextColor3 = colorSettings["MainButtons"]["TextColor"] end
            ButtonEffect(BlockRemoteButton, "Blokir Dilepas", true)
            if remoteData[currentRemoteDataKey] and IsValid(remoteData[currentRemoteDataKey].button) and IsValid(remoteData[currentRemoteDataKey].button.RemoteNameLabel) then
                 remoteData[currentRemoteDataKey].button.RemoteNameLabel.TextColor3 = colorSettings["RemoteButtons"]["TextColor"] end
        else
            table.insert(BlockList, currentRemoteLookingAt)
            if IsValid(BlockRemoteButton) then BlockRemoteButton.Text = "Buka Blokir Remote"; BlockRemoteButton.TextColor3 = Color3.fromRGB(251, 197, 49) end
            ButtonEffect(BlockRemoteButton, "Remote Diblokir", true)
            if remoteData[currentRemoteDataKey] and IsValid(remoteData[currentRemoteDataKey].button) and IsValid(remoteData[currentRemoteDataKey].button.RemoteNameLabel) then
                 remoteData[currentRemoteDataKey].button.RemoteNameLabel.TextColor3 = Color3.fromRGB(225, 177, 44) end
        end
    else ButtonEffect(BlockRemoteButton, "Pilih Remote Dulu", false) end
end)

UnstackRemoteButton.MouseButton1Click:Connect(function()
    if currentRemoteLookingAt then
        local index = table.find(unstackedRemotes, currentRemoteLookingAt)
        if index then
            table.remove(unstackedRemotes, index)
            if IsValid(UnstackRemoteButton) then UnstackRemoteButton.Text = "Unstack Remote (Argumen Baru)"; UnstackRemoteButton.TextColor3 = colorSettings["MainButtons"]["TextColor"] end
            ButtonEffect(UnstackRemoteButton, "Remote Akan Di-stack", true)
        else
            table.insert(unstackedRemotes, currentRemoteLookingAt)
            if IsValid(UnstackRemoteButton) then UnstackRemoteButton.Text = "Stack Remote Ini"; UnstackRemoteButton.TextColor3 = Color3.fromRGB(251, 197, 49) end
            ButtonEffect(UnstackRemoteButton, "Remote Akan Di-unstack", true)
        end
    else ButtonEffect(UnstackRemoteButton, "Pilih Remote Dulu", false) end
end)

WhileLoopButton.MouseButton1Click:Connect(function()
    if currentRemoteLookingAt and IsValid(CodeTextLabel) and CodeTextLabel.Text ~= "" then
        local loopScript = string.format("while task.wait() do\n    %s\nend", CodeTextLabel.Text)
        local success, err = pcall(setclipboard, loopScript)
        ButtonEffect(WhileLoopButton, success and "Skrip Loop Disalin!" or "Gagal Menyalin", success)
    else ButtonEffect(WhileLoopButton, "Tidak Ada Kode", false) end
end)

CopyReturnValueButton.MouseButton1Click:Connect(function()
    if currentRemoteLookingAt and currentRemoteLookingAt:IsA("RemoteFunction") and currentRemoteDataKey and remoteData[currentRemoteDataKey] then
        local data = remoteData[currentRemoteDataKey]
        local originalArgs = data.argsHistory[#data.argsHistory]
        local result, execErr = ExecuteRemote(currentRemoteLookingAt, originalArgs)
        if execErr then ButtonEffect(CopyReturnValueButton, "Gagal Eksekusi!", false); warn("TurtleSpy: Gagal mengeksekusi RemoteFunction untuk menyalin return:", execErr); return end
        local success, returnStr = pcall(convertTableToString, result, true)
        if not success then returnStr = "--[[ Error converting return value: " .. tostring(returnStr) .. " ]]--" end
        local cbSuccess, _ = pcall(setclipboard, returnStr)
        ButtonEffect(CopyReturnValueButton, cbSuccess and "Return Disalin!" or "Gagal Menyalin Return", cbSuccess)
    elseif not (currentRemoteLookingAt and currentRemoteLookingAt:IsA("RemoteFunction")) then ButtonEffect(CopyReturnValueButton, "Ini Bukan Fungsi", false)
    else ButtonEffect(CopyReturnValueButton, "Pilih Remote Dulu", false) end
end)

ClearLogsButton.MouseButton1Click:Connect(function()
    if IsValid(RemoteScrollFrame) then
        for _, child in ipairs(RemoteScrollFrame:GetChildren()) do
            if child:IsA("TextButton") and child.Name ~= "RemoteButtonTemplate" then child:Destroy() end
        end
    end
    for _, conn in ipairs(activeConnections) do if conn and conn.Connected then conn:Disconnect() end end
    activeConnections = {}
    remoteData = {}
    buttonOffset = 5 
    if IsValid(RemoteScrollFrame) then RemoteScrollFrame.CanvasSize = UDim2.new(0, 0, 0, scrollSizeOffset) end
    currentRemoteLookingAt = nil
    currentRemoteDataKey = nil
    if isInfoFrameOpen and IsValid(CloseInfoFrameButton) then CloseInfoFrameButton:MouseButton1Click() end
    ButtonEffect(ClearLogsButton, "Log Dibersihkan!", true)
end)

UnstackAllButton.MouseButton1Click:Connect(function()
    local currentUnstackedCount = #unstackedRemotes
    local allKnownRemotes = {}
    for _, dataItem in pairs(remoteData) do 
        if dataItem.instance and IsValid(dataItem.instance) then table.insert(allKnownRemotes, dataItem.instance) end
    end
    if currentUnstackedCount > 0 and currentUnstackedCount == #allKnownRemotes then 
        unstackedRemotes = {}
        if IsValid(UnstackAllButton) then UnstackAllButton.Text = "Unstack Semua" end
        ButtonEffect(UnstackAllButton, "Semua Di-stack Ulang", true)
    else 
        unstackedRemotes = {} 
        for _, remoteInst in ipairs(allKnownRemotes) do
            if not table.find(unstackedRemotes, remoteInst) then table.insert(unstackedRemotes, remoteInst) end
        end
        if IsValid(UnstackAllButton) then UnstackAllButton.Text = "Stack Semua" end
        ButtonEffect(UnstackAllButton, "Semua Di-unstack", true)
    end
    if currentRemoteLookingAt and isInfoFrameOpen and IsValid(UnstackRemoteButton) then
        UnstackRemoteButton.Text = table.find(unstackedRemotes, currentRemoteLookingAt) and "Stack Remote Ini" or "Unstack Remote (Argumen Baru)"
        UnstackRemoteButton.TextColor3 = table.find(unstackedRemotes, currentRemoteLookingAt) and Color3.fromRGB(251, 197, 49) or colorSettings["MainButtons"]["TextColor"]
    end
end)

SaveSessionButton.MouseButton1Click:Connect(function()
    local sessionData = { remotes = {}, ignoreList = {}, blockList = {}, unstackedRemotes = {} }
    for _, dataItem in pairs(remoteData) do
        if dataItem.instance and IsValid(dataItem.instance) then
            local remoteInfo = {
                path = GetFullPathOfAnInstance(dataItem.instance), name = dataItem.instance.Name, className = dataItem.instance.ClassName,
                argsHistory = {}, count = dataItem.count,
            }
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
        local writeSuccess, err = pcall(safeWriteFile, "TurtleSpySession.json", encodedData)
        ButtonEffect(SaveSessionButton, writeSuccess and "Sesi Disimpan!" or "Gagal Menyimpan", writeSuccess)
        if not writeSuccess then warn("TurtleSpy: Gagal menulis file sesi:", err) end
    else ButtonEffect(SaveSessionButton, "Gagal Encode Sesi", false); warn("TurtleSpy: Gagal JSONEncode sesi:", encodedData) end
end)

LoadSessionButton.MouseButton1Click:Connect(function()
    local success, jsonData = pcall(safeReadFile, "TurtleSpySession.json")
    if not success or not jsonData then ButtonEffect(LoadSessionButton, "File Sesi Tidak Ada", false); warn("TurtleSpy: Gagal membaca file sesi:", jsonData); return end
    local decodeSuccess, sessionData = pcall(HttpService.JSONDecode, HttpService, jsonData)
    if not decodeSuccess then ButtonEffect(LoadSessionButton, "Gagal Decode Sesi", false); warn("TurtleSpy: Gagal JSONDecode sesi:", sessionData); return end
    if IsValid(ClearLogsButton) then ClearLogsButton:MouseButton1Click() end
    local function findInstanceByPath(pathString)
        if type(pathString) ~= "string" then return nil end; local parts = {}
        for part in pathString:gmatch("([^%.%[%]:]+)") do table.insert(parts, part:gsub('^%s*"?(.-)"?%s*$', "%1")) end
        local currentInstance = game
        for i, partName in ipairs(parts) do
            if currentInstance == nil then return nil end
            if i == 1 and partName:lower() == "game" then goto continue_loop end
            local foundChild = nil
            local sfc, fc = pcall(currentInstance.FindFirstChild, currentInstance, partName, true)
            if sfc and fc then foundChild = fc
            else
                sfc, fc = pcall(currentInstance.FindFirstChild, currentInstance, partName)
                if sfc and fc then foundChild = fc
                else
                    local sgs, serv = pcall(currentInstance.GetService, currentInstance, partName)
                    if sgs and serv then foundChild = serv end
                end
            end
            if foundChild then currentInstance = foundChild else return nil end
            ::continue_loop::
        end
        return currentInstance
    end
    for _, remoteInfo in ipairs(sessionData.remotes or {}) do
        local instance = findInstanceByPath(remoteInfo.path)
        if instance and IsValid(instance) and instance:IsA(remoteInfo.className) then
            local args = {}; if remoteInfo.lastArgsString then local parsed, _ = parseArgumentsString(remoteInfo.lastArgsString); args = parsed or {} end
            local dummyScript = Instance.new("LocalScript"); dummyScript.Name = "LoadedFromSession"
            addToListInternal(instance:IsA("RemoteEvent"), instance, dummyScript, unpack(args))
            dummyScript:Destroy()
            local dataKey = GetKeyForRemote(instance, args, table.find(unstackedRemotes, instance) ~= nil)
            if remoteData[dataKey] and remoteInfo.count and remoteInfo.count > 1 then
                remoteData[dataKey].count = remoteInfo.count
                if IsValid(remoteData[dataKey].button) and IsValid(remoteData[dataKey].button.NumberLabel) then
                    remoteData[dataKey].button.NumberLabel.Text = tostring(remoteInfo.count)
                    if TextService and IsValid(TextService) then
                        local tsSuccess, numSize = pcall(TextService.GetTextSize, TextService, remoteData[dataKey].button.NumberLabel.Text, remoteData[dataKey].button.NumberLabel.TextSize, remoteData[dataKey].button.NumberLabel.Font, Vector2.new())
                        if tsSuccess and numSize and IsValid(remoteData[dataKey].button.RemoteNameLabel) then
                             remoteData[dataKey].button.RemoteNameLabel.Position = UDim2.new(0, numSize.X + 10, 0, 0)
                        end
                    end
                end
            end
        else warn("TurtleSpy: Gagal menemukan instance saat memuat sesi:", remoteInfo.path) end
    end
    IgnoreList = {}; for _, path in ipairs(sessionData.ignoreList or {}) do local inst = findInstanceByPath(path) if inst and IsValid(inst) then table.insert(IgnoreList, inst) end end
    BlockList = {}; for _, path in ipairs(sessionData.blockList or {}) do local inst = findInstanceByPath(path) if inst and IsValid(inst) then table.insert(BlockList, inst) end end
    unstackedRemotes = {}; for _, path in ipairs(sessionData.unstackedRemotes or {}) do local inst = findInstanceByPath(path) if inst and IsValid(inst) then table.insert(unstackedRemotes, inst) end end
    ButtonEffect(LoadSessionButton, "Sesi Dimuat!", true)
    if IsValid(FilterTextBox) then FilterTextBox.Text = "" end 
    FilterRemotes("") 
end)

local fireServerHookActive = true
local invokeServerHookActive = true
local namecallHookActive = true

local function updateHookButton(button, textPrefix, isActive)
    if not IsValid(button) then return end
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

local function FilterRemotes(filterText)
    if not IsValid(RemoteScrollFrame) then return end
    filterText = filterText:lower()
    local newButtonOffset = 5 
    local visibleCount = 0
    for _, dataItem in pairs(remoteData) do
        if dataItem.button and IsValid(dataItem.button) then
            local remoteName = dataItem.instance and dataItem.instance.Name:lower() or ""
            if filterText == "" or remoteName:find(filterText, 1, true) then
                dataItem.button.Visible = true
                dataItem.button.Position = UDim2.new(0.05, 0, 0, newButtonOffset)
                newButtonOffset = newButtonOffset + dataItem.button.AbsoluteSize.Y + 5
                visibleCount = visibleCount + 1
            else dataItem.button.Visible = false end
        end
    end
    RemoteScrollFrame.CanvasSize = UDim2.new(0, 0, 0, math.max(scrollSizeOffset, newButtonOffset))
end

if IsValid(FilterTextBox) then
    FilterTextBox.FocusLost:Connect(function(enterPressed) if enterPressed then FilterRemotes(FilterTextBox.Text) end end)
    FilterTextBox:GetPropertyChangedSignal("Text"):Connect(function() FilterRemotes(FilterTextBox.Text) end)
end

if UserInputService and mouse then -- Pastikan mouse ada
    UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
        if gameProcessedEvent then return end 
        if input.KeyCode == Enum.KeyCode[settings["Keybind"]:upper()] then
            if IsValid(TurtleSpyGUI) then TurtleSpyGUI.Enabled = not TurtleSpyGUI.Enabled end
        end
    end)
end

local browsedRemotesCache = {} 
local browsedConnections = {}
local browserButtonOffsetY = 10
local browserCanvasCurrentSizeY = 286

if IsValid(OpenBrowserButton) then
    OpenBrowserButton.MouseButton1Click:Connect(function()
        if not IsValid(BrowserHeader) or not IsValid(RemoteBrowserFrame) then return end
        BrowserHeader.Visible = not BrowserHeader.Visible
        if BrowserHeader.Visible then
            for _, child in ipairs(RemoteBrowserFrame:GetChildren()) do
                if child:IsA("TextButton") and child.Name ~= "RemoteButtonBrowserTemplate" then child:Destroy() end
            end
            for _, conn in ipairs(browsedConnections) do if conn.Connected then conn:Disconnect() end end
            browsedConnections = {}; browsedRemotesCache = {}; browserButtonOffsetY = 10; browserCanvasCurrentSizeY = 286
            RemoteBrowserFrame.CanvasSize = UDim2.new(0,0,0, browserCanvasCurrentSizeY)
            for _, v in ipairs(game:GetDescendants()) do
                if (v:IsA("RemoteEvent") or v:IsA("RemoteFunction")) and not table.find(browsedRemotesCache, v) then
                    table.insert(browsedRemotesCache, v)
                    local bButton = RemoteButtonBrowserTemplate:Clone(); bButton.Parent = RemoteBrowserFrame; bButton.Visible = true
                    bButton.Position = UDim2.new(0.05, 0, 0, browserButtonOffsetY)
                    local nameLabel = bButton:FindFirstChild("RemoteNameBrowserLabel") or RemoteNameBrowserTemplate:Clone()
                    nameLabel.Parent = bButton; nameLabel.Text = v.Name
                    local iconLabel = bButton:FindFirstChild("RemoteIconBrowser") or RemoteIconBrowserTemplate:Clone()
                    iconLabel.Parent = bButton; iconLabel.Image = v:IsA("RemoteEvent") and eventImage or functionImage
                    local fireMethod = v:IsA("RemoteEvent") and ":FireServer()" or ":InvokeServer()"
                    local conn = bButton.MouseButton1Click:Connect(function()
                        local successCopy, errCopy = pcall(setclipboard, GetFullPathOfAnInstance(v) .. fireMethod)
                        ButtonEffect(bButton, successCopy and "Path Disalin!" or "Gagal", successCopy)
                    end)
                    table.insert(browsedConnections, conn)
                    browserButtonOffsetY = browserButtonOffsetY + bButton.AbsoluteSize.Y + 5
                    if browserButtonOffsetY > browserCanvasCurrentSizeY - 30 then 
                        browserCanvasCurrentSizeY = browserCanvasCurrentSizeY + bButton.AbsoluteSize.Y + 5
                        RemoteBrowserFrame.CanvasSize = UDim2.new(0, 0, 0, browserCanvasCurrentSizeY)
                    end
                end
            end
        end
    end)
end

if IsValid(CloseBrowserButton) then
    CloseBrowserButton.MouseButton1Click:Connect(function() if IsValid(BrowserHeader) then BrowserHeader.Visible = false end end)
end

local function GetKeyForRemote(remote, args, isUnstacked)
    local key = GetFullPathOfAnInstance(remote) 
    if not isUnstacked then
        local success, argStr = pcall(HttpService.JSONEncode, HttpService, args)
        if success then key = key .. "|" .. argStr 
        else local simpleArgStr = ""; for _, argVal in ipairs(args) do simpleArgStr = simpleArgStr .. tostring(argVal) end; key = key .. "|SIMPLE|" .. simpleArgStr end
    end
    return key
end

local function addToListInternal(isEvent, remote, callingScript, ...)
    if not remote or not IsValid(remote) then return end
    if table.find(IgnoreList, remote) then return end 
    local currentId = getThreadContextFunc()
    setThreadContextFunc(7) 
    local args = {...}
    local isUnstackedCurrent = table.find(unstackedRemotes, remote) ~= nil
    local dataKey = GetKeyForRemote(remote, args, isUnstackedCurrent)
    if not remoteData[dataKey] then
        if IsValid(RemoteScrollFrame) and #RemoteScrollFrame:GetChildren() > settings.MaxDisplayedRemotes then
            local oldestKey, oldestTimestamp = nil, math.huge
            for k, dataItem in pairs(remoteData) do if dataItem.firstSeen < oldestTimestamp then oldestTimestamp = dataItem.firstSeen; oldestKey = k end end
            if oldestKey and remoteData[oldestKey] and IsValid(remoteData[oldestKey].button) then remoteData[oldestKey].button:Destroy(); remoteData[oldestKey] = nil end
        end
        local rButton = RemoteButtonTemplate:Clone(); rButton.Name = remote.Name .. "_Button"; rButton.Parent = RemoteScrollFrame; rButton.Visible = true 
        local numberLabel = rButton:FindFirstChild("NumberLabel") or NumberLabelTemplate:Clone(); numberLabel.Parent = rButton; numberLabel.Text = "1"
        local remoteNameLabel = rButton:FindFirstChild("RemoteNameLabel") or RemoteNameLabelTemplate:Clone(); remoteNameLabel.Parent = rButton; remoteNameLabel.Text = remote.Name
        if table.find(BlockList, remote) then remoteNameLabel.TextColor3 = Color3.fromRGB(225, 177, 44)
        elseif table.find(IgnoreList, remote) then remoteNameLabel.TextColor3 = Color3.fromRGB(127, 143, 166) end
        local remoteIcon = rButton:FindFirstChild("RemoteIcon") or RemoteIconTemplate:Clone(); remoteIcon.Parent = rButton; remoteIcon.Image = isEvent and eventImage or functionImage
        remoteData[dataKey] = { instance = remote, argsHistory = {args}, callingScript = callingScript, count = 1, button = rButton, isEvent = isEvent, firstSeen = tick() }
        if TextService and IsValid(TextService) then
            local tsSuccess, numSize = pcall(TextService.GetTextSize, TextService, numberLabel.Text, numberLabel.TextSize, numberLabel.Font, Vector2.new())
            if tsSuccess and numSize then remoteNameLabel.Position = UDim2.new(0, numSize.X + 10, 0, 0); remoteNameLabel.Size = UDim2.new(1, -(numSize.X + 10 + 30), 1, 0) end
        end
        local conn = rButton.MouseButton1Click:Connect(function() UpdateInfoFrame(remote, dataKey) end)
        table.insert(activeConnections, conn)
        FilterRemotes(IsValid(FilterTextBox) and FilterTextBox.Text or "") 
        if settings.AutoScroll and IsValid(RemoteScrollFrame) and RemoteScrollFrame.Visible then RemoteScrollFrame.CanvasPosition = Vector2.new(0, RemoteScrollFrame.CanvasSize.Y.Offset) end
    else 
        local data = remoteData[dataKey]; data.count = data.count + 1
        if IsValid(data.button) and IsValid(data.button.NumberLabel) then
            data.button.NumberLabel.Text = tostring(data.count)
            if TextService and IsValid(TextService) and IsValid(data.button.RemoteNameLabel) then
                local tsSuccess, numSize = pcall(TextService.GetTextSize, TextService, data.button.NumberLabel.Text, data.button.NumberLabel.TextSize, data.button.NumberLabel.Font, Vector2.new())
                if tsSuccess and numSize then data.button.RemoteNameLabel.Position = UDim2.new(0, numSize.X + 10, 0, 0); data.button.RemoteNameLabel.Size = UDim2.new(1, -(numSize.X + 10 + 30), 1, 0) end
            end
        end
        table.insert(data.argsHistory, args); if #data.argsHistory > 20 then table.remove(data.argsHistory, 1) end 
        data.callingScript = callingScript 
        if currentRemoteLookingAt == remote and currentRemoteDataKey == dataKey and isInfoFrameOpen then UpdateInfoFrame(remote, dataKey) end
    end
    setThreadContextFunc(currentId)
end

local OldEvent_FireServer, OldFunction_InvokeServer, OldNamecall
local hookSuccess = true

if typeof(hookfunction) ~= "function" then
    warn("TurtleSpy: CRITICAL - hookfunction is not available. Remote detection will not work.")
    hookSuccess = false
else
    local remoteEventProto = Instance.new("RemoteEvent")
    if remoteEventProto and remoteEventProto.FireServer then
        local suc, res = pcall(function()
            OldEvent_FireServer = hookfunction(remoteEventProto.FireServer, function(self, ...)
                if not fireServerHookActive then return OldEvent_FireServer(self, ...) end
                local isBlocked = false; local s, r = pcall(table.find, BlockList, self); if s then isBlocked = r end
                if not checkcaller() and isBlocked then return end 
                local script = getCallingScriptFunc and getCallingScriptFunc() or nil
                addToListInternal(true, self, script, ...)
                return OldEvent_FireServer(self, ...)
            end)
        end)
        if not suc then warn("TurtleSpy: Gagal hook RemoteEvent.FireServer:", res); hookSuccess = false else print("TurtleSpy: RemoteEvent.FireServer hooked.") end
    else warn("TurtleSpy: Tidak dapat membuat RemoteEvent prototype atau FireServer tidak ada."); hookSuccess = false end
    if remoteEventProto then remoteEventProto:Destroy() end

    local remoteFunctionProto = Instance.new("RemoteFunction")
    if remoteFunctionProto and remoteFunctionProto.InvokeServer then
        local suc, res = pcall(function()
            OldFunction_InvokeServer = hookfunction(remoteFunctionProto.InvokeServer, function(self, ...)
                if not invokeServerHookActive then return OldFunction_InvokeServer(self, ...) end
                local isBlocked = false; local s, r = pcall(table.find, BlockList, self); if s then isBlocked = r end
                if not checkcaller() and isBlocked then return end 
                local script = getCallingScriptFunc and getCallingScriptFunc() or nil
                addToListInternal(false, self, script, ...)
                return OldFunction_InvokeServer(self, ...)
            end)
        end)
        if not suc then warn("TurtleSpy: Gagal hook RemoteFunction.InvokeServer:", res); hookSuccess = false else print("TurtleSpy: RemoteFunction.InvokeServer hooked.") end
    else warn("TurtleSpy: Tidak dapat membuat RemoteFunction prototype atau InvokeServer tidak ada."); hookSuccess = false end
    if remoteFunctionProto then remoteFunctionProto:Destroy() end
end

if typeof(hookmetamethod) ~= "function" then
    warn("TurtleSpy: CRITICAL - hookmetamethod is not available. Namecall detection will not work.")
    hookSuccess = false
else
    local suc, res = pcall(function()
        OldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
            if not namecallHookActive then return OldNamecall(self, ...) end
            local method = getNamecallMethodFunc and getNamecallMethodFunc() or ""
            local args = {...} 
            if method == "FireServer" and self:IsA("RemoteEvent") then
                local isBlocked = false; local s, r = pcall(table.find, BlockList, self); if s then isBlocked = r end
                if not checkcaller() and isBlocked then return end
                local script = getCallingScriptFunc and getCallingScriptFunc() or nil
                addToListInternal(true, self, script, unpack(args)) 
            elseif method == "InvokeServer" and self:IsA("RemoteFunction") then
                local isBlocked = false; local s, r = pcall(table.find, BlockList, self); if s then isBlocked = r end
                if not checkcaller() and isBlocked then return end
                local script = getCallingScriptFunc and getCallingScriptFunc() or nil
                addToListInternal(false, self, script, unpack(args)) 
            end
            return OldNamecall(self, ...)
        end)
    end)
    if not suc then warn("TurtleSpy: Gagal hook __namecall:", res); hookSuccess = false else print("TurtleSpy: __namecall hooked.") end
end

if not hookSuccess then
    warn("TurtleSpy: SATU ATAU LEBIH HOOK GAGAL DIPASANG. Fungsi inti mungkin tidak bekerja.")
end

FilterRemotes("") 
if IsValid(TurtleSpyGUI) then TurtleSpyGUI.Enabled = true end
if IsValid(HeaderTextLabel) then HeaderTextLabel.Text = "TurtleSpy V2 (" .. executorName .. ")" end
print("TurtleSpy: Inisialisasi UI akhir selesai.")

if script and script.Destroying then 
    script.Destroying:Connect(function()
        print("TurtleSpy: Script dihancurkan, membersihkan...")
        if OldEvent_FireServer and typeof(OldEvent_FireServer) == 'function' then 
            local suc, err = pcall(OldEvent_FireServer)
            if not suc then warn("Error unhooking FireServer:", err) end
        end 
        if OldFunction_InvokeServer and typeof(OldFunction_InvokeServer) == 'function' then 
            local suc, err = pcall(OldFunction_InvokeServer)
            if not suc then warn("Error unhooking InvokeServer:", err) end
        end
        if OldNamecall and typeof(OldNamecall) == 'function' then 
            local suc, err = pcall(OldNamecall)
            if not suc then warn("Error unhooking Namecall:", err) end
        end
        for _, conn in ipairs(activeConnections) do if conn and conn.Connected then conn:Disconnect() end end
        activeConnections = {}
        if IsValid(TurtleSpyGUI) then TurtleSpyGUI:Destroy() end
        pcall(safeWriteFile, settingsFileName, HttpService:JSONEncode(settings))
        print("TurtleSpy: Pembersihan selesai.")
    end)
end

print("TurtleSpy V2 Enhanced (Arceus X Fix V2) loaded. Executor: " .. executorName .. ". Keybind: " .. settings.Keybind)
if executorName == "Arceus X" and (typeof(readfile) ~= "function" or typeof(writefile) ~= "function" or typeof(isfile) ~= "function") then
    warn("TurtleSpy (Arceus X): Global file functions (readfile/writefile/isfile) not detected. File operations might be unreliable. Saving/loading sessions may not work correctly.")
end

if not hookSuccess then
    if IsValid(HeaderTextLabel) then
        HeaderTextLabel.Text = HeaderTextLabel.Text .. " (HOOK FAIL)"
        HeaderTextLabel.TextColor3 = Color3.fromRGB(255,0,0)
    end
    if IsValid(StatusLabel) then -- Anggap StatusLabel ada jika HeaderTextLabel ada
        StatusLabel.Text = "KESALAHAN HOOK KRITIS! Periksa konsol (F9)."
        StatusLabel.TextColor3 = Color3.fromRGB(255,100,100)
    end
end
