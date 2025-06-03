-- TurtleSpy V1.5.5 (Revisi Final berdasarkan analisis skrip yang berhasil)
-- Credits to Intrer#0421
-- Perbaikan dan penambahan fitur Overpower oleh Partner Coding (AI)

-- [[ BAGIAN 1: DEKLARASI AWAL DAN PENGATURAN DASAR ]]
local success_init, error_init = pcall(function() -- Melindungi seluruh inisialisasi awal

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "TurtleSpyScreenGui" -- Nama unik
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global -- Menggunakan ZIndex global
    ScreenGui.ResetOnSpawn = false -- Penting!

    local colorSettings = {
        ["Main"] = {
            ["HeaderColor"] = Color3.fromRGB(0, 168, 255),
            ["HeaderShadingColor"] = Color3.fromRGB(0, 151, 230),
            ["HeaderTextColor"] = Color3.fromRGB(255, 255, 255), -- Teks header lebih terang
            ["MainBackgroundColor"] = Color3.fromRGB(30, 35, 45), -- Gelap modern
            ["InfoScrollingFrameBgColor"] = Color3.fromRGB(35, 40, 50),
            ["ScrollBarImageColor"] = Color3.fromRGB(100, 120, 140)
        },
        ["RemoteButtons"] = {
            ["BorderColor"] = Color3.fromRGB(80, 90, 110),
            ["BackgroundColor"] = Color3.fromRGB(45, 50, 65),
            ["TextColor"] = Color3.fromRGB(210, 220, 230),
            ["NumberTextColor"] = Color3.fromRGB(180, 190, 200)
        },
        ["MainButtons"] = {
            ["BorderColor"] = Color3.fromRGB(80, 90, 110),
            ["BackgroundColor"] = Color3.fromRGB(50, 100, 180), -- Warna tombol lebih menonjol
            ["TextColor"] = Color3.fromRGB(230, 240, 255)
        },
        ['Code'] = {
            ['BackgroundColor'] = Color3.fromRGB(25, 30, 40),
            ['TextColor'] = Color3.fromRGB(200, 210, 220),
            ['CreditsColor'] = Color3.fromRGB(120, 120, 120)
        },
    }

    local settings = {
        ["Keybind"] = Enum.KeyCode.P -- Menggunakan Enum.KeyCode
    }

    -- Servis Roblox
    local Players = game:GetService("Players")
    local HttpService = game:GetService("HttpService")
    local TextService = game:GetService("TextService")
    local CoreGui = game:GetService("CoreGui")
    local RunService = game:GetService("RunService") -- Untuk RenderStepped jika diperlukan nanti

    local client = Players.LocalPlayer
    local mouse = client:GetMouse()

    -- Variabel untuk referensi GUI utama
    local mainFrame, Header, RemoteScrollFrame, InfoFrame, OpenInfoFrame, MinimizeButton, BrowserButton
    local OverpowerFeaturesFrame, OpenOverpowerButton, DecompileOutputFrame -- Untuk fitur Overpower

    -- Variabel penting lainnya dari skrip asli
    local currentRemoteButtonYOffset = 10
    local remoteListCanvasYOffset = 287 -- Ketinggian awal canvas scroll remote
    local functionImage = "rbxassetid://413369623" -- Menggunakan rbxassetid
    local eventImage = "rbxassetid://413369506"  -- Menggunakan rbxassetid
    local remotes = {}
    local remoteArgs = {}
    local remoteButtons = {} -- Akan menyimpan referensi ke label Angka
    local remoteScripts = {}
    local IgnoreList = {}
    local BlockList = {}
    local activeConnections = {} -- Mengganti nama 'connections'
    local unstackedRemotes = {}  -- Mengganti nama 'unstacked'

    local InfoFrameOpen = false
    local lookingAtRemote, lookingAtRemoteArgs, lookingAtRemoteButtonLabel
    local isDecompilingSingle, isDecompilingAll

    -- [[ BAGIAN 2: FUNGSI UTILITAS DAN KOMPATIBILITAS EKSEKUTOR ]]
    local IS_PROTOSMASHER = PROTOSMASHER_LOADED or false
    local IS_SYNAPSE = syn and syn.protect_gui -- Deteksi Synapse yang lebih andal

    local function ParentGUISafe(guiElement, desiredParent)
        if not guiElement then print("TurtleSpy Error: Mencoba mem-parent elemen GUI yang nil!") return false end
        local targetParent = desiredParent or CoreGui
        local success, err = pcall(function()
            if IS_SYNAPSE and syn.protect_gui and targetParent == CoreGui then
                syn.protect_gui(guiElement)
            end
            guiElement.Parent = targetParent
        end)
        if not success then
            print("TurtleSpy Error saat mem-parent GUI (" .. guiElement.Name .. ") ke (" .. targetParent.Name .. "): " .. tostring(err))
            if not guiElement.Parent and targetParent == CoreGui then -- Coba lagi tanpa proteksi jika gagal
                 local s2,e2 = pcall(function() guiElement.Parent = CoreGui end)
                 if not s2 then print("TurtleSpy Error: Gagal fallback parenting ke CoreGui:", e2) return false end
            elseif not guiElement.Parent then return false
            end
        end
        return true
    end

    -- Fungsi untuk File Operations
    local _isfile, _readfile, _writefile -- Variabel lokal untuk menyimpan fungsi asli/fallback
    local function initializeFileOperations()
        local function getGlobalOrSyn(name)
            if _G[name] then return _G[name] end
            if IS_SYNAPSE and syn[name] then return syn[name] end
            return nil
        end

        _isfile = getGlobalOrSyn("isfile")
        if not _isfile then
            print("TurtleSpy Info: 'isfile' tidak ditemukan. Menggunakan fallback.")
            _isfile = function(path)
                local s, r = pcall(function() return _readfile(path) end) -- Tergantung _readfile
                return s and r ~= nil
            end
        end

        _readfile = getGlobalOrSyn("readfile")
        if not _readfile then
            print("TurtleSpy Info: 'readfile' tidak ditemukan. Pengaturan tidak akan dimuat.")
            _readfile = function(path) return nil end
        end

        _writefile = getGlobalOrSyn("writefile")
        if not _writefile then
            print("TurtleSpy Info: 'writefile' tidak ditemukan. Pengaturan tidak akan disimpan.")
            _writefile = function(path, content) end
        end

        if IS_PROTOSMASHER and not getgenv().isfile and (_isfile == nil or tostring(_isfile):find("fallback")) then
             pcall(function()
                getgenv().isfile = newcclosure(function(File)
                    local Suc_rf, Er_rf = pcall(_readfile, File)
                    return Suc_rf and Er_rf ~= nil
                end)
                _isfile = getgenv().isfile -- Gunakan versi Protosmasher jika berhasil dibuat
                print("TurtleSpy Info: 'isfile' Protosmasher dikonfigurasi.")
            end)
        end
    end

    local function loadSettings()
        local success, result = pcall(function()
            if not HttpService or not HttpService.JSONDecode then
                print("TurtleSpy Error: HttpService atau JSONDecode tidak tersedia.")
                return
            end
            if _isfile("TurtleSpySettings.json") then
                local fileContent = _readfile("TurtleSpySettings.json")
                if fileContent then
                    local decodedSettings = HttpService:JSONDecode(fileContent)
                    if type(decodedSettings) == "table" and decodedSettings.Keybind then
                        settings.Keybind = Enum.KeyCode[decodedSettings.Keybind] or Enum.KeyCode.P -- Ambil KeyCode dari string
                        print("TurtleSpy: Pengaturan dimuat.")
                    else
                        _writefile("TurtleSpySettings.json", HttpService:JSONEncode({Keybind = settings.Keybind.Name}))
                    end
                else
                    _writefile("TurtleSpySettings.json", HttpService:JSONEncode({Keybind = settings.Keybind.Name}))
                end
            else
                _writefile("TurtleSpySettings.json", HttpService:JSONEncode({Keybind = settings.Keybind.Name}))
            end
        end)
        if not success then print("TurtleSpy Error saat memuat pengaturan:", result) end
    end

    local function GetFullPathOfAnInstance(instance)
        -- (Implementasi GetFullPathOfAnInstance yang lebih aman dan lengkap dari revisi sebelumnya)
        if not instance then return "nil" end
        local path = {}
        local current = instance
        while current do
            if current == game then table.insert(path, 1, "game"); break end
            if current == workspace then table.insert(path, 1, "workspace"); break end
            if current.Parent == game then
                 local success_gs, serviceName = pcall(game.GetService, game, current.ClassName)
                 if success_gs and serviceName == current then
                     table.insert(path, 1, 'game:GetService("' .. current.ClassName .. '")')
                     break
                 end
            end
            local name = current.Name
            if string.match(name, "^[%a_][%w_]*$") then
                table.insert(path, 1, "." .. name)
            else
                table.insert(path, 1, '["' .. name:gsub('"', '\\"'):gsub('\\', '\\\\') .. '"]')
            end
            if not current.Parent or current.Parent == current then break end -- Hentikan jika parent nil atau loop
            current = current.Parent
        end
        return table.concat(path):gsub("^%.", "")
    end

    local function ButtonEffect(textlabel, text, successColor)
        -- (Implementasi ButtonEffect dari revisi sebelumnya)
        if not textlabel or not textlabel.Parent then return end
        if not text then text = "Copied!" end
        local orgText = textlabel.Text; local orgColor = textlabel.TextColor3
        textlabel.Text = text; textlabel.TextColor3 = successColor or Color3.fromRGB(76, 209, 55)
        task.delay(0.8, function()
            if textlabel and textlabel.Parent then
                textlabel.Text = orgText; textlabel.TextColor3 = orgColor
            end
        end)
    end

    local function convertTableToString(argsTable, indentationLevel)
        -- (Implementasi convertTableToString yang ditingkatkan dari revisi sebelumnya)
        indentationLevel = indentationLevel or 0
        local indent = string.rep("  ", indentationLevel)
        local nextIndent = string.rep("  ", indentationLevel + 1)
        local entries = {}
        local isArray = true; local numericKeys = {}

        if type(argsTable) ~= "table" then return tostring(argsTable) end
        if next(argsTable) == nil then return "{}" end -- Tabel kosong

        for k, _ in pairs(argsTable) do
            if type(k) ~= "number" or k < 1 or math.floor(k) ~= k then isArray = false else table.insert(numericKeys, k) end
        end
        if isArray then table.sort(numericKeys); if #numericKeys > 0 and numericKeys[#numericKeys] ~= #numericKeys then isArray = false end end
        if #numericKeys ~= 다음에 나오는 pairs(argsTable)의 반복 횟수 then isArray = false end


        if isArray then
            for i = 1, #argsTable do
                local v = argsTable[i]; local valueStr
                if v == nil then valueStr = "nil"
                elseif typeof(v) == "Instance" then valueStr = GetFullPathOfAnInstance(v)
                elseif type(v) == "string" then valueStr = string.format("%q", v)
                elseif type(v) == "table" then valueStr = "{\n" .. convertTableToString(v, indentationLevel + 1) .. "\n" .. nextIndent .. "}"
                else valueStr = tostring(v) end
                table.insert(entries, nextIndent .. valueStr)
            end
            return "{\n" .. table.concat(entries, ",\n") .. "\n" .. indent .. "}"
        else
            for k, v in pairs(argsTable) do
                local keyStr
                if type(k) == "string" and k:match("^[%a_][%w_]*$") then keyStr = k
                else keyStr = "[" .. (type(k) == "string" and string.format("%q",k) or tostring(k)) .. "]" end
                local valueStr
                if v == nil then valueStr = "nil"
                elseif typeof(v) == "Instance" then valueStr = GetFullPathOfAnInstance(v)
                elseif type(v) == "string" then valueStr = string.format("%q", v)
                elseif type(v) == "table" then valueStr = "{\n" .. convertTableToString(v, indentationLevel + 1) .. "\n" .. nextIndent .. "}"
                else valueStr = tostring(v) end
                table.insert(entries, nextIndent .. keyStr .. " = " .. valueStr)
            end
            return "{\n" .. table.concat(entries, ",\n") .. "\n" .. indent .. "}"
        end
    end


    -- [[ BAGIAN 3: INISIALISASI DAN PEMBUATAN GUI UTAMA ]]
    pcall(function() if CoreGui:FindFirstChild(ScreenGui.Name) then CoreGui:FindFirstChild(ScreenGui.Name):Destroy() end end)

    mainFrame = Instance.new("Frame")
    mainFrame.Name = "TurtleSpyMainFrame"
    mainFrame.BackgroundColor3 = colorSettings["Main"]["MainBackgroundColor"]
    mainFrame.BorderColor3 = colorSettings["Main"]["HeaderColor"] -- Border dengan warna header
    mainFrame.BorderSizePixel = 1
    mainFrame.Position = UDim2.new(0.05, 0, 0.1, 0)
    mainFrame.Size = UDim2.new(0, 220, 0, 350) -- Ukuran awal yang wajar
    mainFrame.ZIndex = 1000 -- ZIndex tinggi
    mainFrame.Active = true
    mainFrame.Draggable = true
    ParentGUISafe(mainFrame, ScreenGui) -- Parent ke ScreenGui

    Header = Instance.new("Frame")
    Header.Name = "Header"
    Header.Parent = mainFrame
    Header.BackgroundColor3 = colorSettings["Main"]["HeaderColor"]
    Header.BorderSizePixel = 0
    Header.Size = UDim2.new(1, 0, 0, 30) -- Header lebih tinggi sedikit
    Header.ZIndex = 1001

    local HeaderTextLabel = Instance.new("TextLabel")
    HeaderTextLabel.Name = "HeaderTextLabel"
    HeaderTextLabel.Parent = Header
    HeaderTextLabel.BackgroundTransparency = 1.000
    HeaderTextLabel.Position = UDim2.new(0, 30, 0, 0)
    HeaderTextLabel.Size = UDim2.new(1, -95, 1, 0)
    HeaderTextLabel.ZIndex = 1002
    HeaderTextLabel.Font = Enum.Font.GothamSemibold -- Font lebih modern
    HeaderTextLabel.Text = "TurtleSpy"
    HeaderTextLabel.TextColor3 = colorSettings["Main"]["HeaderTextColor"]
    HeaderTextLabel.TextSize = 18.000
    HeaderTextLabel.TextXAlignment = Enum.TextXAlignment.Center

    RemoteScrollFrame = Instance.new("ScrollingFrame")
    RemoteScrollFrame.Name = "RemoteScrollFrame"
    RemoteScrollFrame.Parent = mainFrame
    RemoteScrollFrame.BackgroundColor3 = colorSettings["Main"]["InfoScrollingFrameBgColor"]
    RemoteScrollFrame.BorderColor3 = colorSettings["Main"]["HeaderColor"]
    RemoteScrollFrame.BorderSizePixel = 1
    RemoteScrollFrame.Position = UDim2.new(0, 5, 0, Header.Size.Y.Offset + 5)
    RemoteScrollFrame.Size = UDim2.new(1, -10, 1, -(Header.Size.Y.Offset + 10))
    RemoteScrollFrame.ZIndex = 1000
    RemoteScrollFrame.CanvasSize = UDim2.new(0, 0, 0, remoteListCanvasYOffset)
    RemoteScrollFrame.ScrollBarThickness = 7
    RemoteScrollFrame.VerticalScrollBarPosition = Enum.VerticalScrollBarPosition.Right -- Scrollbar di kanan
    RemoteScrollFrame.ScrollBarImageColor3 = colorSettings["Main"]["ScrollBarImageColor"]
    RemoteScrollFrame.Visible = true

    local RemoteButtonTemplate = Instance.new("TextButton")
    -- (Konfigurasi RemoteButtonTemplate, NumberLabelTemplate, RemoteNameLabelTemplate, RemoteIconTemplate seperti revisi sebelumnya)
    RemoteButtonTemplate.Name = "RemoteButtonTemplate"
    RemoteButtonTemplate.BackgroundColor3 = colorSettings["RemoteButtons"]["BackgroundColor"]
    RemoteButtonTemplate.BorderColor3 = colorSettings["RemoteButtons"]["BorderColor"]
    RemoteButtonTemplate.Size = UDim2.new(1, -8, 0, 28)
    RemoteButtonTemplate.Font = Enum.Font.Gotham
    RemoteButtonTemplate.Text = ""; RemoteButtonTemplate.TextColor3 = colorSettings["RemoteButtons"]["TextColor"]
    RemoteButtonTemplate.TextSize = 16.000; RemoteButtonTemplate.TextXAlignment = Enum.TextXAlignment.Left

    local NumberLabelTemplate = Instance.new("TextLabel")
    NumberLabelTemplate.Name = "Number"; NumberLabelTemplate.Parent = RemoteButtonTemplate
    NumberLabelTemplate.BackgroundTransparency = 1.000; NumberLabelTemplate.Position = UDim2.new(0, 5, 0, 0)
    NumberLabelTemplate.Size = UDim2.new(0, 30, 1, 0); NumberLabelTemplate.ZIndex = 2
    NumberLabelTemplate.Font = Enum.Font.Gotham; NumberLabelTemplate.Text = "1"
    NumberLabelTemplate.TextColor3 = colorSettings["RemoteButtons"]["NumberTextColor"]; NumberLabelTemplate.TextSize = 15.000
    NumberLabelTemplate.TextXAlignment = Enum.TextXAlignment.Left

    local RemoteNameLabelTemplate = Instance.new("TextLabel")
    RemoteNameLabelTemplate.Name = "RemoteName"; RemoteNameLabelTemplate.Parent = RemoteButtonTemplate
    RemoteNameLabelTemplate.BackgroundTransparency = 1.000; RemoteNameLabelTemplate.Font = Enum.Font.Gotham
    RemoteNameLabelTemplate.Text = "RemoteName"; RemoteNameLabelTemplate.TextColor3 = colorSettings["RemoteButtons"]["TextColor"]
    RemoteNameLabelTemplate.TextSize = 15.000; RemoteNameLabelTemplate.TextXAlignment = Enum.TextXAlignment.Left
    RemoteNameLabelTemplate.TextTruncate = Enum.TextTruncate.AtEnd

    local RemoteIconTemplate = Instance.new("ImageLabel")
    RemoteIconTemplate.Name = "RemoteIcon"; RemoteIconTemplate.Parent = RemoteButtonTemplate
    RemoteIconTemplate.BackgroundTransparency = 1.000; RemoteIconTemplate.Position = UDim2.new(1, -29, 0.5, -12)
    RemoteIconTemplate.Size = UDim2.new(0, 24, 0, 24); RemoteIconTemplate.Image = eventImage

    InfoFrame = Instance.new("Frame")
    -- (Konfigurasi InfoFrame, InfoFrameHeader, InfoHeaderText, CloseInfoFrameButton seperti revisi sebelumnya)
    InfoFrame.Name = "InfoFrame"; InfoFrame.Parent = mainFrame
    InfoFrame.BackgroundColor3 = colorSettings["Main"]["MainBackgroundColor"]
    InfoFrame.BorderColor3 = colorSettings["Main"]["HeaderColor"]; InfoFrame.BorderSizePixel = 1
    InfoFrame.Position = UDim2.new(1, 5, 0, 0); InfoFrame.Size = UDim2.new(0, 360, 1, 0)
    InfoFrame.Visible = false; InfoFrame.ZIndex = 990

    local InfoFrameHeader = Instance.new("Frame")
    InfoFrameHeader.Name = "InfoFrameHeader"; InfoFrameHeader.Parent = InfoFrame
    InfoFrameHeader.BackgroundColor3 = colorSettings["Main"]["HeaderColor"]
    InfoFrameHeader.BorderSizePixel = 0; InfoFrameHeader.Size = UDim2.new(1, 0, 0, 30)
    InfoFrameHeader.ZIndex = 992

    local InfoHeaderText = Instance.new("TextLabel")
    InfoHeaderText.Name = "InfoHeaderText"; InfoHeaderText.Parent = InfoFrameHeader
    InfoHeaderText.BackgroundTransparency = 1.000; InfoHeaderText.Size = UDim2.new(1, -30, 1, 0)
    InfoHeaderText.ZIndex = 993; InfoHeaderText.Font = Enum.Font.GothamSemibold
    InfoHeaderText.Text = "Remote Info"; InfoHeaderText.TextColor3 = colorSettings["Main"]["HeaderTextColor"]
    InfoHeaderText.TextSize = 17.000; InfoHeaderText.TextXAlignment = Enum.TextXAlignment.Center

    local CloseInfoFrameButton = Instance.new("TextButton")
    CloseInfoFrameButton.Name = "CloseInfoFrameButton"; CloseInfoFrameButton.Parent = InfoFrameHeader
    CloseInfoFrameButton.BackgroundColor3 = colorSettings["Main"]["HeaderColor"]; CloseInfoFrameButton.BorderSizePixel = 0
    CloseInfoFrameButton.Position = UDim2.new(1, -28, 0.5, -11); CloseInfoFrameButton.Size = UDim2.new(0, 22, 0, 22)
    CloseInfoFrameButton.ZIndex = 994; CloseInfoFrameButton.Font = Enum.Font.GothamBold
    CloseInfoFrameButton.Text = "X"; CloseInfoFrameButton.TextColor3 = colorSettings["Main"]["HeaderTextColor"]
    CloseInfoFrameButton.TextSize = 16.000

    local CodeFrame = Instance.new("ScrollingFrame")
    -- (Konfigurasi CodeFrame, CodeComment, Code seperti revisi sebelumnya)
    CodeFrame.Name = "CodeFrame"; CodeFrame.Parent = InfoFrame
    CodeFrame.BackgroundColor3 = colorSettings["Code"]["BackgroundColor"]
    CodeFrame.BorderColor3 = colorSettings["Main"]["HeaderColor"]; CodeFrame.BorderSizePixel = 1
    CodeFrame.Position = UDim2.new(0.03, 0, 0, InfoFrameHeader.Size.Y.Offset + 10)
    CodeFrame.Size = UDim2.new(0.94, 0, 0, 80); CodeFrame.ZIndex = 991
    CodeFrame.CanvasSize = UDim2.new(2, 0, 1, 0); CodeFrame.ScrollBarThickness = 6
    CodeFrame.ScrollingDirection = Enum.ScrollingDirection.XY
    CodeFrame.ScrollBarImageColor3 = colorSettings["Main"]["ScrollBarImageColor"]

    local CodeComment = Instance.new("TextLabel")
    CodeComment.Name = "CodeComment"; CodeComment.Parent = CodeFrame
    CodeComment.BackgroundTransparency = 1.000; CodeComment.Position = UDim2.new(0, 5, 0, 2)
    CodeComment.Size = UDim2.new(1, -10, 0, 18); CodeComment.ZIndex = 992
    CodeComment.Font = Enum.Font.Code; CodeComment.Text = "-- Script generated by TurtleSpy"
    CodeComment.TextColor3 = colorSettings["Code"]["CreditsColor"]; CodeComment.TextSize = 12.000
    CodeComment.TextXAlignment = Enum.TextXAlignment.Left

    local Code = Instance.new("TextLabel")
    Code.Name = "Code"; Code.Parent = CodeFrame
    Code.BackgroundTransparency = 1.000
    Code.Position = UDim2.new(0, 5, 0, CodeComment.Position.Y.Offset + CodeComment.Size.Y.Offset)
    Code.Size = UDim2.new(10, 0, 1, -(CodeComment.Position.Y.Offset + CodeComment.Size.Y.Offset + 5))
    Code.ZIndex = 992; Code.Font = Enum.Font.Code
    Code.Text = "Select a remote."; Code.TextColor3 = colorSettings["Code"]["TextColor"]
    Code.TextSize = 13.000; Code.TextWrapped = false
    Code.TextXAlignment = Enum.TextXAlignment.Left; Code.TextYAlignment = Enum.TextYAlignment.Top

    local InfoButtonsScroll = Instance.new("ScrollingFrame")
    -- (Konfigurasi InfoButtonsScroll seperti revisi sebelumnya)
    InfoButtonsScroll.Name = "InfoButtonsScroll"; InfoButtonsScroll.Parent = InfoFrame
    InfoButtonsScroll.BackgroundColor3 = colorSettings["Main"]["InfoScrollingFrameBgColor"]
    InfoButtonsScroll.BorderColor3 = colorSettings["Main"]["HeaderColor"]; InfoButtonsScroll.BorderSizePixel = 1
    InfoButtonsScroll.Position = UDim2.new(0.03, 0, 0, CodeFrame.Position.Y.Offset + CodeFrame.Size.Y.Offset + 10)
    InfoButtonsScroll.Size = UDim2.new(0.94, 0, 1, -(CodeFrame.Position.Y.Offset + CodeFrame.Size.Y.Offset + InfoFrameHeader.Size.Y.Offset + 25))
    InfoButtonsScroll.ZIndex = 991; InfoButtonsScroll.CanvasSize = UDim2.new(0,0,0,0)
    InfoButtonsScroll.ScrollBarThickness = 6
    InfoButtonsScroll.ScrollBarImageColor3 = colorSettings["Main"]["ScrollBarImageColor"]

    BrowserButton = Instance.new("ImageButton")
    -- (Konfigurasi BrowserButton seperti revisi sebelumnya, menggunakan ImageButton)
    BrowserButton.Name = "BrowserButton"; BrowserButton.Parent = Header
    BrowserButton.BackgroundTransparency = 1.000; BrowserButton.Position = UDim2.new(0, 5, 0.5, -9)
    BrowserButton.Size = UDim2.new(0, 18, 0, 18); BrowserButton.ZIndex = 1003
    BrowserButton.Image = "rbxassetid://169476802"; BrowserButton.ImageColor3 = colorSettings["Main"]["HeaderTextColor"]

    OpenOverpowerButton = Instance.new("ImageButton")
    -- (Konfigurasi OpenOverpowerButton seperti revisi sebelumnya)
    OpenOverpowerButton.Name = "OpenOverpowerButton"; OpenOverpowerButton.Parent = Header
    OpenOverpowerButton.BackgroundTransparency = 1.000
    OpenOverpowerButton.Position = UDim2.new(0, BrowserButton.Position.X.Offset + BrowserButton.Size.X.Offset + 5, 0.5, -9)
    OpenOverpowerButton.Size = UDim2.new(0, 18, 0, 18); OpenOverpowerButton.ZIndex = 1003
    OpenOverpowerButton.Image = "rbxassetid://284402950"; OpenOverpowerButton.ImageColor3 = colorSettings["Main"]["HeaderTextColor"]


    MinimizeButton = Instance.new("TextButton")
    -- (Konfigurasi MinimizeButton seperti revisi sebelumnya)
    MinimizeButton.Name = "MinimizeButton"; MinimizeButton.Parent = Header
    MinimizeButton.BackgroundColor3 = colorSettings["Main"]["HeaderColor"]; MinimizeButton.BorderSizePixel = 0
    MinimizeButton.Position = UDim2.new(1, -55, 0.5, -11) -- Sedikit ke kiri
    MinimizeButton.Size = UDim2.new(0, 22, 0, 22); MinimizeButton.ZIndex = 1003
    MinimizeButton.Font = Enum.Font.GothamBold; MinimizeButton.Text = "_"
    MinimizeButton.TextColor3 = colorSettings["Main"]["HeaderTextColor"]; MinimizeButton.TextSize = 16.000

    OpenInfoFrame = Instance.new("TextButton")
    -- (Konfigurasi OpenInfoFrame seperti revisi sebelumnya)
    OpenInfoFrame.Name = "OpenInfoFrameButton"; OpenInfoFrame.Parent = Header
    OpenInfoFrame.BackgroundColor3 = colorSettings["Main"]["HeaderColor"]; OpenInfoFrame.BorderSizePixel = 0
    OpenInfoFrame.Position = UDim2.new(1, -28, 0.5, -11)
    OpenInfoFrame.Size = UDim2.new(0, 22, 0, 22); OpenInfoFrame.ZIndex = 1003
    OpenInfoFrame.Font = Enum.Font.GothamBold; OpenInfoFrame.Text = ">"
    OpenInfoFrame.TextColor3 = colorSettings["Main"]["HeaderTextColor"]; OpenInfoFrame.TextSize = 16.000

    -- [[ BAGIAN 4: FUNGSI LOGIKA INTI (addToList, event handlers, hooks) ]]
    local function createInfoButton(name, text, yPos, parentScroll)
        -- (Implementasi createInfoButton dari revisi sebelumnya)
        local button = Instance.new("TextButton")
        button.Name = name; button.Parent = parentScroll
        button.BackgroundColor3 = colorSettings["MainButtons"]["BackgroundColor"]
        button.BorderColor3 = colorSettings["MainButtons"]["BorderColor"]; button.BorderSizePixel = 1
        button.Position = UDim2.new(0.05, 0, 0, yPos); button.Size = UDim2.new(0.9, 0, 0, 28)
        button.ZIndex = 15; button.Font = Enum.Font.Gotham
        button.Text = text; button.TextColor3 = colorSettings["MainButtons"]["TextColor"]
        button.TextSize = 14.000
        return button
    end

    local infoButtonYOffset = 10
    local CopyCodeButton = createInfoButton("CopyCode", "Copy Code", infoButtonYOffset, InfoButtonsScroll); infoButtonYOffset = infoButtonYOffset + 35
    local RunCodeButton = createInfoButton("RunCode", "Execute", infoButtonYOffset, InfoButtonsScroll); infoButtonYOffset = infoButtonYOffset + 35
    local CopyScriptPathButton = createInfoButton("CopyScriptPath", "Copy Script Path", infoButtonYOffset, InfoButtonsScroll); infoButtonYOffset = infoButtonYOffset + 35
    local CopyDecompiledButton = createInfoButton("CopyDecompiled", "Copy Decompiled (Synapse)", infoButtonYOffset, InfoButtonsScroll); infoButtonYOffset = infoButtonYOffset + 35
    local DoNotStackButton = createInfoButton("DoNotStack", "Unstack Remote", infoButtonYOffset, InfoButtonsScroll); infoButtonYOffset = infoButtonYOffset + 35
    local IgnoreRemoteButton = createInfoButton("IgnoreRemote", "Ignore Remote", infoButtonYOffset, InfoButtonsScroll); infoButtonYOffset = infoButtonYOffset + 35
    local BlockRemoteButton = createInfoButton("BlockRemote", "Block Remote", infoButtonYOffset, InfoButtonsScroll); infoButtonYOffset = infoButtonYOffset + 35
    local ClearLogsButton = createInfoButton("ClearLogs", "Clear Logs", infoButtonYOffset, InfoButtonsScroll); infoButtonYOffset = infoButtonYOffset + 35
    local GenerateWhileLoopButton = createInfoButton("GenerateWhileLoop", "Generate While Loop", infoButtonYOffset, InfoButtonsScroll); infoButtonYOffset = infoButtonYOffset + 35
    local CopyReturnValueButton = createInfoButton("CopyReturnValue", "Execute & Copy Return", infoButtonYOffset, InfoButtonsScroll)
    CopyReturnValueButton.Visible = false
    InfoButtonsScroll.CanvasSize = UDim2.new(0,0,0, infoButtonYOffset + 10)

    function addToList(isRemoteEvent, remoteInstance, ...)
        -- (Implementasi addToList yang disempurnakan dari revisi sebelumnya)
        if not remoteInstance or typeof(remoteInstance) ~= "Instance" then return end
        local currentId = pcall(get_thread_context) and get_thread_context() or (IS_SYNAPSE and syn.get_thread_identity and syn.get_thread_identity()) or 7
        if pcall(set_thread_context, currentId) or (IS_SYNAPSE and syn.set_thread_identity) then
             pcall(set_thread_context, 7) or (IS_SYNAPSE and syn.set_thread_identity and syn.set_thread_identity(7))
        end

        local remoteName = remoteInstance.Name; local args = table.pack(...)
        local existingIndex
        for i = 1, #remotes do
            if remotes[i] == remoteInstance then
                if table.find(unstackedRemotes, remoteInstance) then
                    local sameArgs = true
                    if #remoteArgs[i] == args.n then
                        for k = 1, args.n do if remoteArgs[i][k] ~= args[k] then sameArgs = false; break end end
                    else sameArgs = false end
                    if sameArgs then existingIndex = i; break end
                else existingIndex = i; break end
            end
        end

        if not existingIndex then
            table.insert(remotes, remoteInstance); table.insert(remoteArgs, args)
            local callingScript = (IS_SYNAPSE and getcallingscript and getcallingscript()) or (rawget and rawget(getfenv(0), "script"))
            table.insert(remoteScripts, callingScript)

            local newButton = RemoteButtonTemplate:Clone()
            newButton.Name = "RemoteEntry_" .. #remotes; newButton.LayoutOrder = #remotes
            newButton.Parent = RemoteScrollFrame
            newButton.Position = UDim2.new(0.025, 0, 0, currentRemoteButtonYOffset) -- Posisi dengan padding

            newButton.RemoteIcon.Image = isRemoteEvent and eventImage or functionImage
            newButton.RemoteName.Text = remoteName
            local numberLabel = newButton.Number; numberLabel.Text = "1"
            table.insert(remoteButtons, numberLabel)

            local numSize = TextService:GetTextSize(numberLabel.Text, numberLabel.TextSize, numberLabel.Font, Vector2.new(math.huge, numberLabel.AbsoluteSize.Y))
            numberLabel.Size = UDim2.new(0, numSize.X + 5, 1, 0)
            newButton.RemoteName.Position = UDim2.new(0, numberLabel.AbsoluteSize.X + 5, 0, 0)
            newButton.RemoteName.Size = UDim2.new(1, -(numberLabel.AbsoluteSize.X + 5 + newButton.RemoteIcon.AbsoluteSize.X + 10), 1, 0)

            currentRemoteButtonYOffset = currentRemoteButtonYOffset + newButton.AbsoluteSize.Y + 4 -- Spasi antar tombol
            if currentRemoteButtonYOffset > RemoteScrollFrame.CanvasSize.Y.Offset then
                RemoteScrollFrame.CanvasSize = UDim2.new(0,0,0, currentRemoteButtonYOffset + 10)
            end

            local clickConnection = newButton.MouseButton1Click:Connect(function()
                lookingAtRemote = remoteInstance; lookingAtRemoteArgs = args; lookingAtRemoteButtonLabel = numberLabel
                InfoHeaderText.Text = "Info: " .. remoteName
                CodeComment.Text = "-- Path: " .. GetFullPathOfAnInstance(remoteInstance) .. "\n-- Caller: " .. (callingScript and GetFullPathOfAnInstance(callingScript) or "Unknown")
                Code.Text = GetFullPathOfAnInstance(remoteInstance) .. (isRemoteEvent and ":FireServer(" or ":InvokeServer(") .. convertTableToString(args,0) .. ")"
                local codeTextSize = TextService:GetTextSize(Code.Text, Code.TextSize, Code.Font, Vector2.new(math.huge, math.huge))
                local commentTextSize = TextService:GetTextSize(CodeComment.Text, CodeComment.TextSize, CodeComment.Font, Vector2.new(math.huge, math.huge))
                local requiredWidth = math.max(codeTextSize.X, commentTextSize.X) + 30
                local requiredHeight = CodeComment.AbsoluteSize.Y + codeTextSize.Y + 20
                Code.Size = UDim2.new(0, requiredWidth -10, 0, codeTextSize.Y + 5) -- Atur ukuran Code
                CodeFrame.CanvasSize = UDim2.new(0, requiredWidth, 0, requiredHeight)

                CopyReturnValueButton.Visible = not isRemoteEvent
                local baseCanvasY = 330; if not isRemoteEvent then baseCanvasY = baseCanvasY + 35 end
                InfoButtonsScroll.CanvasSize = UDim2.new(0,0,0, baseCanvasY)

                local isBlocked = table.find(BlockList, remoteInstance)
                BlockRemoteButton.Text = isBlocked and "Unblock" or "Block"; BlockRemoteButton.TextColor3 = isBlocked and Color3.fromRGB(251,197,49) or colorSettings["MainButtons"]["TextColor"]
                local isIgnored = table.find(IgnoreList, remoteInstance)
                IgnoreRemoteButton.Text = isIgnored and "Unignore" or "Ignore"; IgnoreRemoteButton.TextColor3 = isIgnored and Color3.fromRGB(127,143,166) or colorSettings["MainButtons"]["TextColor"]
                local isUnstacked = table.find(unstackedRemotes, remoteInstance)
                DoNotStackButton.Text = isUnstacked and "Stack" or "Unstack"; DoNotStackButton.TextColor3 = isUnstacked and Color3.fromRGB(251,197,49) or colorSettings["MainButtons"]["TextColor"]

                if not InfoFrame.Visible then
                    InfoFrame.Visible = true; InfoFrameOpen = true
                    mainFrame.Size = UDim2.new(0, mainFrame.Size.X.Offset + InfoFrame.Size.X.Offset + 5, 0, mainFrame.Size.Y.Offset)
                    OpenInfoFrame.Text = "<"
                end
            end)
            table.insert(activeConnections, clickConnection)
        else
            remoteButtons[existingIndex].Text = tostring(tonumber(remoteButtons[existingIndex].Text) + 1)
            remoteArgs[existingIndex] = args
            local numSize = TextService:GetTextSize(remoteButtons[existingIndex].Text, remoteButtons[existingIndex].TextSize, remoteButtons[existingIndex].Font, Vector2.new(math.huge, remoteButtons[existingIndex].AbsoluteSize.Y))
            remoteButtons[existingIndex].Size = UDim2.new(0, numSize.X + 5, 1, 0)
            local parentButton = remoteButtons[existingIndex].Parent
            parentButton.RemoteName.Position = UDim2.new(0, remoteButtons[existingIndex].AbsoluteSize.X + 5, 0, 0)
            parentButton.RemoteName.Size = UDim2.new(1, -(remoteButtons[existingIndex].AbsoluteSize.X + 5 + parentButton.RemoteIcon.AbsoluteSize.X + 10), 1, 0)

            if lookingAtRemote == remoteInstance and lookingAtRemoteButtonLabel == remoteButtons[existingIndex] and InfoFrame.Visible then
                Code.Text = GetFullPathOfAnInstance(remoteInstance) .. (isRemoteEvent and ":FireServer(" or ":InvokeServer(") .. convertTableToString(args,0) .. ")"
                local codeTextSize = TextService:GetTextSize(Code.Text, Code.TextSize, Code.Font, Vector2.new(math.huge, math.huge))
                Code.Size = UDim2.new(0, codeTextSize.X + 20, 0, codeTextSize.Y + 5)
                CodeFrame.CanvasSize = UDim2.new(0, Code.Size.X.Offset + 10, 0, Code.Position.Y.Offset + Code.Size.Y.Offset + 10)
            end
        end
        if pcall(set_thread_context, currentId) or (IS_SYNAPSE and syn.set_thread_identity) then
             pcall(set_thread_context, currentId) or (IS_SYNAPSE and syn.set_thread_identity and syn.set_thread_identity(currentId))
        end
    end

    -- Event Handlers Tombol Info (dipersingkat)
    CopyCodeButton.MouseButton1Click:Connect(function() if lookingAtRemote and Code.Text ~= "" and setclipboard then setclipboard(CodeComment.Text .. "\n" .. Code.Text); ButtonEffect(CopyCodeButton) else ButtonEffect(CopyCodeButton, "Error!",Color3.fromRGB(230,0,0)) end end)
    RunCodeButton.MouseButton1Click:Connect(function() if lookingAtRemote and lookingAtRemoteArgs then local r,a=lookingAtRemote,lookingAtRemoteArgs;local s,e=pcall(function() if r:IsA("RemoteEvent")then r:FireServer(table.unpack(a,1,a.n)) else r:InvokeServer(table.unpack(a,1,a.n)) end end); if s then ButtonEffect(RunCodeButton,"Executed!")else ButtonEffect(RunCodeButton,"Error!",Color3.fromRGB(230,0,0));warn("TS RunErr:",e)end else ButtonEffect(RunCodeButton,"No Sel!",Color3.fromRGB(230,0,0))end end)
    CopyScriptPathButton.MouseButton1Click:Connect(function() if lookingAtRemote then local i;for k,v in pairs(remotes)do if v==lookingAtRemote then i=k;break end end; if i and remoteScripts[i]and setclipboard then setclipboard(GetFullPathOfAnInstance(remoteScripts[i]));ButtonEffect(CopyScriptPathButton)else ButtonEffect(CopyScriptPathButton,"N/A",Color3.fromRGB(230,0,0))end end end)
    CopyDecompiledButton.MouseButton1Click:Connect(function() if not(IS_SYNAPSE and decompile and syn.request)then ButtonEffect(CopyDecompiledButton,"Synapse!",Color3.fromRGB(230,0,0))return end;if lookingAtRemote and not isDecompilingSingle then local i;for k,v in pairs(remotes)do if v==lookingAtRemote then i=k;break end end;if not(i and remoteScripts[i])then ButtonEffect(CopyDecompiledButton,"N/A",Color3.fromRGB(230,0,0))return end;isDecompilingSingle=true;local oT=CopyDecompiledButton.Text;task.spawn(function()local d="";while isDecompilingSingle do d=d=="..."and"."or d..".";CopyDecompiledButton.Text="Decompiling"..d;task.wait(0.4)end;CopyDecompiledButton.Text=oT end);local s,r=pcall(decompile,remoteScripts[i]);isDecompilingSingle=false;if s and type(r)=="string"then if setclipboard then setclipboard(r)end;ButtonEffect(CopyDecompiledButton,"Copied!")else ButtonEffect(CopyDecompiledButton,"Error!",Color3.fromRGB(230,0,0));warn("TS DecompErr:",r)end end end)
    DoNotStackButton.MouseButton1Click:Connect(function() if lookingAtRemote then local i=table.find(unstackedRemotes,lookingAtRemote);if i then table.remove(unstackedRemotes,i);DoNotStackButton.Text="Unstack";DoNotStackButton.TextColor3=colorSettings["MainButtons"]["TextColor"]else table.insert(unstackedRemotes,lookingAtRemote);DoNotStackButton.Text="Stack";DoNotStackButton.TextColor3=Color3.fromRGB(251,197,49)end end end)
    IgnoreRemoteButton.MouseButton1Click:Connect(function() if lookingAtRemote then local i=table.find(IgnoreList,lookingAtRemote);local nC=colorSettings["RemoteButtons"]["TextColor"];if i then table.remove(IgnoreList,i);IgnoreRemoteButton.Text="Ignore";IgnoreRemoteButton.TextColor3=colorSettings["MainButtons"]["TextColor"]else table.insert(IgnoreList,lookingAtRemote);IgnoreRemoteButton.Text="Unignore";IgnoreRemoteButton.TextColor3=Color3.fromRGB(127,143,166);nC=Color3.fromRGB(127,143,166)end;if lookingAtRemoteButtonLabel and lookingAtRemoteButtonLabel.Parent then lookingAtRemoteButtonLabel.Parent.RemoteName.TextColor3=nC end end end)
    BlockRemoteButton.MouseButton1Click:Connect(function() if lookingAtRemote then local i=table.find(BlockList,lookingAtRemote);local nC=colorSettings["RemoteButtons"]["TextColor"];if i then table.remove(BlockList,i);BlockRemoteButton.Text="Block";BlockRemoteButton.TextColor3=colorSettings["MainButtons"]["TextColor"]else table.insert(BlockList,lookingAtRemote);BlockRemoteButton.Text="Unblock";BlockRemoteButton.TextColor3=Color3.fromRGB(251,197,49);nC=Color3.fromRGB(230,0,0)end;if lookingAtRemoteButtonLabel and lookingAtRemoteButtonLabel.Parent then lookingAtRemoteButtonLabel.Parent.RemoteName.TextColor3=nC end end end)
    ClearLogsButton.MouseButton1Click:Connect(function() for _,c in ipairs(RemoteScrollFrame:GetChildren())do if c.Name:match("^RemoteEntry_")then c:Destroy()end end;for _,c in ipairs(activeConnections)do if c and c.Connected then c:Disconnect()end end;remotes={};remoteArgs={};remoteButtons={};remoteScripts={};IgnoreList={};BlockList={};unstackedRemotes={};activeConnections={};currentRemoteButtonYOffset=10;RemoteScrollFrame.CanvasSize=UDim2.new(0,0,0,20);lookingAtRemote,lookingAtRemoteArgs,lookingAtRemoteButtonLabel=nil,nil,nil;InfoFrame.Visible=false;InfoFrameOpen=false;mainFrame.Size=UDim2.new(0,220,0,mainFrame.Size.Y.Offset);OpenInfoFrame.Text=">";ButtonEffect(ClearLogsButton,"Cleared!")end)
    GenerateWhileLoopButton.MouseButton1Click:Connect(function() if lookingAtRemote and Code.Text~=""and setclipboard then setclipboard("while task.wait() do\n    "..Code.Text.."\nend");ButtonEffect(GenerateWhileLoopButton)else ButtonEffect(GenerateWhileLoopButton,"No Code!",Color3.fromRGB(230,0,0))end end)
    CopyReturnValueButton.MouseButton1Click:Connect(function() if lookingAtRemote and lookingAtRemote:IsA("RemoteFunction")and lookingAtRemoteArgs then local r,a=lookingAtRemote,lookingAtRemoteArgs;local s,res=pcall(function()return r:InvokeServer(table.unpack(a,1,a.n))end);if s then if setclipboard then setclipboard(convertTableToString(table.pack(res)))end;ButtonEffect(CopyReturnValueButton,"Return Copied!")else ButtonEffect(CopyReturnValueButton,"Invoke Error!",Color3.fromRGB(230,0,0));warn("TS InvokeErr:",res)end else ButtonEffect(CopyReturnValueButton,"Not Func!",Color3.fromRGB(230,0,0))end end)

    -- Event Handlers Tombol Header
    OpenInfoFrame.MouseButton1Click:Connect(function() InfoFrameOpen=not InfoFrameOpen;InfoFrame.Visible=InfoFrameOpen;if InfoFrameOpen then mainFrame.Size=UDim2.new(0,mainFrame.Size.X.Offset+InfoFrame.Size.X.Offset+5,0,mainFrame.Size.Y.Offset);OpenInfoFrame.Text="<"else mainFrame.Size=UDim2.new(0,mainFrame.Size.X.Offset-InfoFrame.Size.X.Offset-5,0,mainFrame.Size.Y.Offset);OpenInfoFrame.Text=">"end end)
    CloseInfoFrameButton.MouseButton1Click:Connect(function() if InfoFrameOpen then OpenInfoFrame.MouseButton1Click:Invoke() end end)
    MinimizeButton.MouseButton1Click:Connect(function() local v=RemoteScrollFrame.Visible;RemoteScrollFrame.Visible=not v;if RemoteScrollFrame.Visible then mainFrame.Size=UDim2.new(0,mainFrame.Size.X.Offset,0,350);MinimizeButton.Text="_";if InfoFrameOpen then InfoFrame.Visible=true;OpenInfoFrame.Text="<";mainFrame.Size=UDim2.new(0,220+InfoFrame.Size.X.Offset+5,0,350)else InfoFrame.Visible=false;OpenInfoFrame.Text=">";mainFrame.Size=UDim2.new(0,220,0,350)end else mainFrame.Size=UDim2.new(0,mainFrame.Size.X.Offset,0,Header.Size.Y.Offset);MinimizeButton.Text="□";InfoFrame.Visible=false end end)

    if mouse and mouse.KeyDown then
        table.insert(activeConnections, mouse.KeyDown:Connect(function(key)
            if key == settings.Keybind then ScreenGui.Enabled = not ScreenGui.Enabled end
        end))
    else print("TurtleSpy Warning: Mouse tidak tersedia untuk keybind.") end

    -- Hooking Functions
    local OldEventFireServer, OldFunctionInvokeServer, OldNamecallHook
    local function unhookFunctions()
        if OldEventFireServer and OldEventFireServer.UnHook then OldEventFireServer:UnHook() end
        if OldFunctionInvokeServer and OldFunctionInvokeServer.UnHook then OldFunctionInvokeServer:UnHook() end
        if OldNamecallHook and OldNamecallHook.UnHook then OldNamecallHook:UnHook() end
    end
    local function hookFunctions()
        if not (hookfunction and hookmetamethod and (getnamecallmethod or (IS_SYNAPSE and get_namecall_method))) then
            print("TurtleSpy Error: Fungsi hook tidak tersedia!"); return false
        end
        local success = true; local errors = {}
        pcall(function() local e=Instance.new("RemoteEvent");OldEventFireServer=hookfunction(e.FireServer,function(s,...)if not checkcaller()and table.find(BlockList,s)then return end;if table.find(IgnoreList,s)then return OldEventFireServer(s,...)end;addToList(true,s,...);return OldEventFireServer(s,...)end);e:Destroy()end)
        pcall(function() local f=Instance.new("RemoteFunction");OldFunctionInvokeServer=hookfunction(f.InvokeServer,function(s,...)if not checkcaller()and table.find(BlockList,s)then return end;if table.find(IgnoreList,s)then return OldFunctionInvokeServer(s,...)end;addToList(false,s,...);return OldFunctionInvokeServer(s,...)end);f:Destroy()end)
        pcall(function() OldNamecallHook=hookmetamethod(game,"__namecall",function(s,...)local m=(getnamecallmethod and getnamecallmethod())or(IS_SYNAPSE and get_namecall_method and get_namecall_method());if not m then return OldNamecallHook(s,...)end;if m=="FireServer"and s:IsA("RemoteEvent")then if not checkcaller()and table.find(BlockList,s)then return end;if table.find(IgnoreList,s)then return OldNamecallHook(s,...)end;addToList(true,s,...)elseif m=="InvokeServer"and s:IsA("RemoteFunction")then if not checkcaller()and table.find(BlockList,s)then return end;if table.find(IgnoreList,s)then return OldNamecallHook(s,...)end;addToList(false,s,...)end;return OldNamecallHook(s,...)end)end)
        if #errors > 0 then print("TurtleSpy Hook Errors:\n" .. table.concat(errors, "\n")); success = false end
        return success
    end
    hookFunctions() -- Panggil hook

    -- [[ BAGIAN 5: FITUR OVERPOWER (Akan ditambahkan di sini nanti) ]]
    -- DecompileOutputFrame, OverpowerFeaturesFrame, BrowserFrame, dll.

    -- [[ BAGIAN 6: PEMBERSIHAN ]]
    game:BindToClose(function()
        print("TurtleSpy: Membersihkan...")
        unhookFunctions()
        for _, conn in ipairs(activeConnections) do if conn and conn.Connected then conn:Disconnect() end end
        if ScreenGui and ScreenGui.Parent then ScreenGui:Destroy() end
    end)

    -- Inisialisasi Akhir
    initializeFileOperations() -- Panggil lagi untuk memastikan jika ada yang didefinisikan lambat
    loadSettings()
    ParentGUISafe(ScreenGui, CoreGui) -- Pastikan ScreenGui utama ter-parent

    print("TurtleSpy V1.5.5 (Revised) Loaded. Tekan '" .. settings.Keybind.Name .. "' untuk toggle.")
    if not ScreenGui.Parent then
        warn("TurtleSpy: ScreenGui GAGAL di-parent ke CoreGui!")
    end

end) -- Akhir dari pcall inisialisasi utama

if not success_init then
    warn("------------------------------------------------------")
    warn("TURTLESPY GAGAL DIMUAT! Error pada inisialisasi awal:")
    warn(error_init)
    warn("------------------------------------------------------")
    -- Coba buat UI error sederhana jika CoreGui masih bisa diakses
    pcall(function()
        local errScr = Instance.new("ScreenGui")
        errScr.Name = "TurtleSpy_INIT_ERROR"
        local errFrm = Instance.new("Frame", errScr)
        errFrm.Size = UDim2.new(0,300,0,100); errFrm.Position = UDim2.new(0.5,-150,0.5,-50)
        errFrm.BackgroundColor3 = Color3.new(0.8,0.2,0.2)
        local errLbl = Instance.new("TextLabel", errFrm)
        errLbl.Size = UDim2.new(1, -10, 1, -10); errLbl.Position = UDim2.new(0,5,0,5)
        errLbl.Text = "TurtleSpy Gagal Dimuat! Error:\n" .. tostring(error_init)
        errLbl.TextColor3 = Color3.new(1,1,1); errLbl.TextWrapped = true
        errLbl.BackgroundTransparency = 1
        if get_hidden_gui then errScr.Parent = get_hidden_gui() else errScr.Parent = game:GetService("CoreGui") end
    end)
end
