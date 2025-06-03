-- TurtleSpy V1.5.4 (Revisi berdasarkan analisis skrip yang berhasil)
-- Credits to Intrer#0421
-- Perbaikan dan penambahan fitur Overpower oleh Partner Coding (AI)

-- [[ BAGIAN 1: DEKLARASI AWAL DAN PENGATURAN DASAR ]]

local colorSettings = {
    ["Main"] = {
        ["HeaderColor"] = Color3.fromRGB(0, 168, 255),
        ["HeaderShadingColor"] = Color3.fromRGB(0, 151, 230),
        ["HeaderTextColor"] = Color3.fromRGB(47, 54, 64),
        ["MainBackgroundColor"] = Color3.fromRGB(47, 54, 64),
        ["InfoScrollingFrameBgColor"] = Color3.fromRGB(47, 54, 64),
        ["ScrollBarImageColor"] = Color3.fromRGB(127, 143, 166)
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
    ["Keybind"] = "P"
}

local client = game:GetService("Players").LocalPlayer
local HttpService = game:GetService("HttpService")
local TextService = game:GetService("TextService")
local CoreGui = game:GetService("CoreGui")

-- Variabel untuk referensi GUI utama
local TurtleSpyGUI, mainFrame, Header, RemoteScrollFrame, InfoFrame, OpenInfoFrame, Minimize, ImageButton -- Dan lainnya akan dideklarasikan nanti

-- Variabel untuk fitur Overpower
local OverpowerFeaturesFrame, OpenOverpowerButton -- Dan lainnya akan dideklarasikan nanti

-- Variabel penting lainnya dari skrip asli
local buttonOffset = 10 -- Disesuaikan untuk layout yang lebih baik dari awal
local scrollSizeOffset = 287
local functionImage = "http://www.roblox.com/asset/?id=413369623"
local eventImage = "http://www.roblox.com/asset/?id=413369506"
local remotes = {}
local remoteArgs = {}
local remoteButtons = {}
local remoteScripts = {}
local IgnoreList = {}
local BlockList = {}
local connections = {}
local unstacked = {}

-- Variabel untuk status dan kontrol
local InfoFrameOpen = false
local lookingAt, lookingAtArgs, lookingAtButton
local decompiling, decompilingAll

-- [[ BAGIAN 2: FUNGSI UTILITAS DAN KOMPATIBILITAS EKSEKUTOR ]]

-- Fungsi isSynapse() dan PROTOSMASHER_LOADED (asumsi PROTOSMASHER_LOADED adalah global jika relevan)
local IS_PROTOSMASHER = PROTOSMASHER_LOADED or false -- Pastikan tidak nil
local function isSynapse()
    if IS_PROTOSMASHER then return false end
    return syn and syn.protect_gui -- Cara yang lebih baik untuk mendeteksi Synapse
end
local IS_SYNAPSE = isSynapse()

-- Fungsi aman untuk parenting GUI
local function ParentGUISafe(guiElement)
    if not guiElement then print("TurtleSpy Error: Mencoba mem-parent elemen GUI yang nil!") return end
    local parented = false
    local pcall_success, pcall_error = pcall(function()
        if IS_SYNAPSE and syn.protect_gui then
            syn.protect_gui(guiElement)
            guiElement.Parent = CoreGui
            parented = true
        elseif IS_PROTOSMASHER and get_hidden_gui then
            local hiddenGui = get_hidden_gui()
            if hiddenGui then
                guiElement.Parent = hiddenGui
                parented = true
            else
                guiElement.Parent = CoreGui -- Fallback jika get_hidden_gui gagal
                parented = true
            end
        else
            guiElement.Parent = CoreGui
            parented = true
        end
    end)
    if not pcall_success then
        print("TurtleSpy Error saat mem-parent GUI (" .. guiElement.Name .. "): " .. tostring(pcall_error))
    elseif not parented then
         print("TurtleSpy Warning: Gagal mem-parent GUI (" .. guiElement.Name .. ") dengan metode spesifik exploit, menggunakan CoreGui fallback.")
         if not guiElement.Parent then guiElement.Parent = CoreGui end -- Final fallback
    end
end

-- Fungsi untuk File Operations (isfile, readfile, writefile) dengan fallback
local function initializeFileOperations()
    if notisfile then
        if IS_PROTOSMASHER and getgenv().isfile then
            isfile = getgenv().isfile
        elseif IS_SYNAPSE and syn.isfile then
            isfile = syn.isfile
        else
            print("TurtleSpy Info: 'isfile' tidak ditemukan. Menggunakan fallback dasar.")
            isfile = function(path)
                local s, r = pcall(function() return readfile(path) end)
                return s and r ~= nil
            end
        end
    end

    if not readfile then
        if IS_SYNAPSE and syn.readfile then
            readfile = syn.readfile
        else
            print("TurtleSpy Info: 'readfile' tidak ditemukan. Menggunakan fallback dasar.")
            readfile = function(path)
                -- Fallback ini mungkin tidak berfungsi di semua eksekutor.
                -- Untuk keamanan, return nil jika tidak ada implementasi.
                print("TurtleSpy Warning: readfile fallback mungkin tidak berfungsi.")
                return nil
            end
        end
    end

    if not writefile then
        if IS_SYNAPSE and syn.writefile then
            writefile = syn.writefile
        else
            print("TurtleSpy Info: 'writefile' tidak ditemukan. Pengaturan mungkin tidak tersimpan.")
            writefile = function(path, content)
                print("TurtleSpy Warning: writefile tidak diimplementasikan.")
            end
        end
    end

    -- Khusus untuk Protosmasher, jika isfile belum didefinisikan oleh blok di atas
    if IS_PROTOSMASHER and (not getgenv().isfile and not isfile) then
        local suc_nc, _ = pcall(function()
            getgenv().isfile = newcclosure(function(File)
                local Suc_rf, Er_rf = pcall(readfile, File)
                return Suc_rf and Er_rf ~= nil
            end)
        end)
        if suc_nc then print("TurtleSpy Info: 'isfile' untuk Protosmasher didefinisikan via newcclosure.")
        else print("TurtleSpy Warning: Gagal mendefinisikan 'isfile' Protosmasher via newcclosure.") end
    end
end
initializeFileOperations() -- Panggil segera untuk memastikan fungsi tersedia

-- Memuat settings dengan aman
local function loadSettings()
    local settingsLoaded = false
    local pcall_success, result = pcall(function()
        if isfile and readfile and HttpService and HttpService.JSONDecode then
            if isfile("TurtleSpySettings.json") then
                local fileContent = readfile("TurtleSpySettings.json")
                if fileContent then
                    local decoded = HttpService:JSONDecode(fileContent)
                    if type(decoded) == "table" and decoded.Keybind then -- Periksa apakah formatnya benar
                        settings = decoded
                        settingsLoaded = true
                        print("TurtleSpy: Pengaturan dimuat dari TurtleSpySettings.json")
                    else
                        print("TurtleSpy Warning: TurtleSpySettings.json rusak atau format salah. Menggunakan pengaturan default.")
                        if writefile then writefile("TurtleSpySettings.json", HttpService:JSONEncode(settings)) end
                    end
                else
                    print("TurtleSpy Warning: Gagal membaca TurtleSpySettings.json. Menggunakan pengaturan default.")
                    if writefile then writefile("TurtleSpySettings.json", HttpService:JSONEncode(settings)) end
                end
            else
                print("TurtleSpy Info: TurtleSpySettings.json tidak ditemukan. Membuat file baru dengan pengaturan default.")
                if writefile and HttpService and HttpService.JSONEncode then
                    writefile("TurtleSpySettings.json", HttpService:JSONEncode(settings))
                end
            end
        else
            print("TurtleSpy Warning: Fungsi file atau HttpService tidak tersedia sepenuhnya. Tidak dapat memuat/menyimpan pengaturan.")
        end
    end)
    if not pcall_success then
        print("TurtleSpy Error saat memuat pengaturan: " .. tostring(result))
    end
end
loadSettings() -- Panggil setelah file operations diinisialisasi

-- Fungsi utilitas lainnya dari skrip asli
local function toUnicode(str)
    if not utf8 or not utf8.codes then return str end -- Fallback jika utf8 tidak tersedia
    local codepoints = "utf8.char("
    for _, v in utf8.codes(str) do
        codepoints = codepoints .. v .. ', '
    end
    return codepoints:sub(1, -3) .. ')'
end

local function GetFullPathOfAnInstance(instance)
    if not instance then return "nil" end
    local path = {}
    local current = instance
    while current do
        if current == game then table.insert(path, 1, "game"); break end
        if current == workspace then table.insert(path, 1, "workspace"); break end
        if current.Parent == game then -- Cek apakah service
             local success, serviceName = pcall(game.GetService, game, current.ClassName)
             if success and serviceName == current then
                 table.insert(path, 1, 'game:GetService("' .. current.ClassName .. '")')
                 break
             end
        end
        
        local name = current.Name
        if string.match(name, "^[%a_][%w_]*$") then -- Nama variabel valid
            table.insert(path, 1, "." .. name)
        else
            table.insert(path, 1, '["' .. name:gsub('"', '\\"'):gsub('\\', '\\\\') .. '"]')
        end
        if not current.Parent then break end -- Handle jika parent tiba-tiba nil
        current = current.Parent
    end
    return table.concat(path):gsub("^%.", "") -- Hapus titik di awal jika ada
end


local function ButtonEffect(textlabel, text, successColor)
    if not textlabel or not textlabel.Parent then return end
    if not text then text = "Copied!" end
    local orgText = textlabel.Text
    local orgColor = textlabel.TextColor3
    textlabel.Text = text
    textlabel.TextColor3 = successColor or Color3.fromRGB(76, 209, 55) -- Default hijau
    task.wait(0.8)
    if textlabel and textlabel.Parent then -- Cek lagi jika GUI dihancurkan saat wait
        textlabel.Text = orgText
        textlabel.TextColor3 = orgColor
    end
end

local function len(t)
    local n = 0
    if type(t) ~= "table" then return 0 end
    for _ in pairs(t) do n = n + 1 end
    return n
end

local function convertTableToString(argsTable, indentationLevel)
    indentationLevel = indentationLevel or 0
    local indent = string.rep("  ", indentationLevel)
    local nextIndent = string.rep("  ", indentationLevel + 1)
    local entries = {}
    local isArray = true
    local numericKeys = {}

    if type(argsTable) ~= "table" then return tostring(argsTable) end

    for k, _ in pairs(argsTable) do
        if type(k) ~= "number" or k < 1 or math.floor(k) ~= k then
            isArray = false
        else
            table.insert(numericKeys, k)
        end
    end
    table.sort(numericKeys)
    if #numericKeys ~= len(argsTable) then isArray = false end
    if #numericKeys > 0 and numericKeys[#numericKeys] ~= #numericKeys then isArray = false end


    if isArray then
        for i = 1, #argsTable do
            local v = argsTable[i]
            local valueStr
            if v == nil then valueStr = "nil"
            elseif typeof(v) == "Instance" then valueStr = GetFullPathOfAnInstance(v)
            elseif type(v) == "string" then valueStr = string.format("%q", v)
            elseif type(v) == "table" then valueStr = "{\n" .. convertTableToString(v, indentationLevel + 1) .. "\n" .. nextIndent .. "}"
            else valueStr = tostring(v) end
            table.insert(entries, nextIndent .. valueStr)
        end
        return "{\n" .. table.concat(entries, ",\n") .. "\n" .. indent .. "}"
    else -- Dictionary
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
-- Hapus instance lama jika ada
pcall(function() if CoreGui:FindFirstChild("TurtleSpyGUI") then CoreGui.TurtleSpyGUI:Destroy() end end)

TurtleSpyGUI = Instance.new("ScreenGui")
TurtleSpyGUI.Name = "TurtleSpyGUI"
TurtleSpyGUI.ResetOnSpawn = false -- Penting agar tidak hilang saat respawn

mainFrame = Instance.new("Frame")
mainFrame.Name = "mainFrame"
mainFrame.Parent = TurtleSpyGUI -- Parent ke ScreenGui dulu
mainFrame.BackgroundColor3 = colorSettings["Main"]["MainBackgroundColor"]
mainFrame.BorderColor3 = colorSettings["Main"]["MainBackgroundColor"]
mainFrame.Position = UDim2.new(0.1, 0, 0.15, 0) -- Penyesuaian posisi awal
mainFrame.Size = UDim2.new(0, 207, 0, 35) -- Hanya header awal
mainFrame.ZIndex = 800 -- ZIndex tinggi untuk di atas game UI
mainFrame.Active = true
mainFrame.Draggable = true

Header = Instance.new("Frame")
Header.Name = "Header"
Header.Parent = mainFrame
Header.BackgroundColor3 = colorSettings["Main"]["HeaderColor"]
Header.BorderSizePixel = 0
Header.Size = UDim2.new(1, 0, 0, 26)
Header.ZIndex = 801

local HeaderShading = Instance.new("Frame") -- Tidak diekspos global karena hanya bagian dari Header
HeaderShading.Name = "HeaderShading"
HeaderShading.Parent = Header
HeaderShading.BackgroundColor3 = colorSettings["Main"]["HeaderShadingColor"]
HeaderShading.BorderSizePixel = 0
HeaderShading.Position = UDim2.new(0, 0, 1, 0) -- Di bawah Header
HeaderShading.Size = UDim2.new(1, 0, 0, 2) -- Tinggi shading
HeaderShading.ZIndex = 800

local HeaderTextLabel = Instance.new("TextLabel")
HeaderTextLabel.Name = "HeaderTextLabel"
HeaderTextLabel.Parent = Header
HeaderTextLabel.BackgroundTransparency = 1.000
HeaderTextLabel.Position = UDim2.new(0, 30, 0, 0) -- Sisakan ruang untuk ikon browser
HeaderTextLabel.Size = UDim2.new(1, -90, 1, 0) -- Sisakan ruang untuk tombol-tombol header
HeaderTextLabel.ZIndex = 802
HeaderTextLabel.Font = Enum.Font.SourceSans
HeaderTextLabel.Text = "Turtle Spy"
HeaderTextLabel.TextColor3 = colorSettings["Main"]["HeaderTextColor"]
HeaderTextLabel.TextSize = 17.000
HeaderTextLabel.TextXAlignment = Enum.TextXAlignment.Center

RemoteScrollFrame = Instance.new("ScrollingFrame")
RemoteScrollFrame.Name = "RemoteScrollFrame"
RemoteScrollFrame.Parent = mainFrame
RemoteScrollFrame.Active = true
RemoteScrollFrame.BackgroundColor3 = colorSettings["Main"]["InfoScrollingFrameBgColor"]
RemoteScrollFrame.BorderColor3 = colorSettings["Main"]["InfoScrollingFrameBgColor"]
RemoteScrollFrame.Position = UDim2.new(0, 0, 0, Header.Size.Y.Offset) -- Di bawah header
RemoteScrollFrame.Size = UDim2.new(1, 0, 1, -Header.Size.Y.Offset - 5) -- Isi sisa frame utama (dengan sedikit padding bawah)
RemoteScrollFrame.ZIndex = 800
RemoteScrollFrame.CanvasSize = UDim2.new(0, 0, 0, scrollSizeOffset)
RemoteScrollFrame.ScrollBarThickness = 8
RemoteScrollFrame.VerticalScrollBarPosition = Enum.VerticalScrollBarPosition.Left
RemoteScrollFrame.ScrollBarImageColor3 = colorSettings["Main"]["ScrollBarImageColor"]
RemoteScrollFrame.Visible = true -- Awalnya terlihat

-- Template Tombol Remote (akan di-clone)
local RemoteButtonTemplate = Instance.new("TextButton")
RemoteButtonTemplate.Name = "RemoteButtonTemplate"
-- Parent tidak diatur di sini, akan diatur saat cloning
RemoteButtonTemplate.BackgroundColor3 = colorSettings["RemoteButtons"]["BackgroundColor"]
RemoteButtonTemplate.BorderColor3 = colorSettings["RemoteButtons"]["BorderColor"]
RemoteButtonTemplate.Size = UDim2.new(1, -16, 0, 26) -- Relatif ke parent (dikurangi padding scrollbar)
RemoteButtonTemplate.Font = Enum.Font.SourceSans
RemoteButtonTemplate.Text = ""
RemoteButtonTemplate.TextColor3 = colorSettings["RemoteButtons"]["TextColor"]
RemoteButtonTemplate.TextSize = 18.000
RemoteButtonTemplate.TextXAlignment = Enum.TextXAlignment.Left

local NumberLabelTemplate = Instance.new("TextLabel")
NumberLabelTemplate.Name = "Number"
NumberLabelTemplate.Parent = RemoteButtonTemplate
NumberLabelTemplate.BackgroundTransparency = 1.000
NumberLabelTemplate.Position = UDim2.new(0, 5, 0, 0)
NumberLabelTemplate.Size = UDim2.new(0, 30, 1, 0) -- Lebar awal, akan disesuaikan
NumberLabelTemplate.ZIndex = 2
NumberLabelTemplate.Font = Enum.Font.SourceSans
NumberLabelTemplate.Text = "1"
NumberLabelTemplate.TextColor3 = colorSettings["RemoteButtons"]["NumberTextColor"]
NumberLabelTemplate.TextSize = 16.000
NumberLabelTemplate.TextXAlignment = Enum.TextXAlignment.Left

local RemoteNameLabelTemplate = Instance.new("TextLabel")
RemoteNameLabelTemplate.Name = "RemoteName"
RemoteNameLabelTemplate.Parent = RemoteButtonTemplate
RemoteNameLabelTemplate.BackgroundTransparency = 1.000
-- Posisi dan ukuran akan diatur di addToList
RemoteNameLabelTemplate.Font = Enum.Font.SourceSans
RemoteNameLabelTemplate.Text = "RemoteName"
RemoteNameLabelTemplate.TextColor3 = colorSettings["RemoteButtons"]["TextColor"]
RemoteNameLabelTemplate.TextSize = 16.000
RemoteNameLabelTemplate.TextXAlignment = Enum.TextXAlignment.Left
RemoteNameLabelTemplate.TextTruncate = Enum.TextTruncate.AtEnd

local RemoteIconTemplate = Instance.new("ImageLabel")
RemoteIconTemplate.Name = "RemoteIcon"
RemoteIconTemplate.Parent = RemoteButtonTemplate
RemoteIconTemplate.BackgroundTransparency = 1.000
RemoteIconTemplate.Position = UDim2.new(1, -29, 0.5, -12) -- Kanan, tengah vertikal
RemoteIconTemplate.Size = UDim2.new(0, 24, 0, 24)
RemoteIconTemplate.Image = eventImage -- Default

-- Info Frame (Awalnya Tersembunyi)
InfoFrame = Instance.new("Frame")
InfoFrame.Name = "InfoFrame"
InfoFrame.Parent = mainFrame
InfoFrame.BackgroundColor3 = colorSettings["Main"]["MainBackgroundColor"]
InfoFrame.BorderColor3 = colorSettings["Main"]["MainBackgroundColor"]
InfoFrame.Position = UDim2.new(1, 5, 0, 0) -- Kanan mainFrame
InfoFrame.Size = UDim2.new(0, 357, 1, 0) -- Tinggi penuh mainFrame
InfoFrame.Visible = false
InfoFrame.ZIndex = 790 -- Di bawah mainFrame header tapi di atas game

local InfoFrameHeader = Instance.new("Frame")
InfoFrameHeader.Name = "InfoFrameHeader"
InfoFrameHeader.Parent = InfoFrame
InfoFrameHeader.BackgroundColor3 = colorSettings["Main"]["HeaderColor"]
InfoFrameHeader.BorderSizePixel = 0
InfoFrameHeader.Size = UDim2.new(1, 0, 0, 26)
InfoFrameHeader.ZIndex = 792

local InfoHeaderText = Instance.new("TextLabel")
InfoHeaderText.Name = "InfoHeaderText"
InfoHeaderText.Parent = InfoFrameHeader
InfoHeaderText.BackgroundTransparency = 1.000
InfoHeaderText.Size = UDim2.new(1, -25, 1, 0)
InfoHeaderText.ZIndex = 793
InfoHeaderText.Font = Enum.Font.SourceSans
InfoHeaderText.Text = "Info: Remote"
InfoHeaderText.TextColor3 = colorSettings["Main"]["HeaderTextColor"]
InfoHeaderText.TextSize = 17.000
InfoHeaderText.TextXAlignment = Enum.TextXAlignment.Center

local CloseInfoFrameButton = Instance.new("TextButton")
CloseInfoFrameButton.Name = "CloseInfoFrameButton"
CloseInfoFrameButton.Parent = InfoFrameHeader
CloseInfoFrameButton.BackgroundColor3 = colorSettings["Main"]["HeaderColor"]
CloseInfoFrameButton.BorderSizePixel = 0
CloseInfoFrameButton.Position = UDim2.new(1, -24, 0.5, -11)
CloseInfoFrameButton.Size = UDim2.new(0, 22, 0, 22)
CloseInfoFrameButton.ZIndex = 794
CloseInfoFrameButton.Font = Enum.Font.SourceSansLight
CloseInfoFrameButton.Text = "X"
CloseInfoFrameButton.TextColor3 = Color3.fromRGB(0,0,0)
CloseInfoFrameButton.TextSize = 20.000

local CodeFrame = Instance.new("ScrollingFrame")
-- ... (Definisi CodeFrame dan elemen di dalamnya seperti Code, CodeComment)
CodeFrame.Name = "CodeFrame"
CodeFrame.Parent = InfoFrame
CodeFrame.Active = true
CodeFrame.BackgroundColor3 = colorSettings["Code"]["BackgroundColor"]
CodeFrame.Position = UDim2.new(0.039, 0, 0.1, 0) -- Sesuaikan posisi
CodeFrame.Size = UDim2.new(1, -28, 0, 63) -- Relatif ke InfoFrame
CodeFrame.ZIndex = 791
CodeFrame.CanvasSize = UDim2.new(2, 0, 1, 0) -- Izinkan scroll horizontal
CodeFrame.ScrollBarThickness = 6
CodeFrame.ScrollingDirection = Enum.ScrollingDirection.XY
CodeFrame.ScrollBarImageColor3 = colorSettings["Main"]["ScrollBarImageColor"]

local CodeComment = Instance.new("TextLabel")
CodeComment.Name = "CodeComment"
CodeComment.Parent = CodeFrame
CodeComment.BackgroundTransparency = 1.000
CodeComment.Position = UDim2.new(0, 5, 0, 2)
CodeComment.Size = UDim2.new(1, -10, 0, 18)
CodeComment.ZIndex = 792
CodeComment.Font = Enum.Font.Code
CodeComment.Text = "-- Script generated by TurtleSpy"
CodeComment.TextColor3 = colorSettings["Code"]["CreditsColor"]
CodeComment.TextSize = 12.000
CodeComment.TextXAlignment = Enum.TextXAlignment.Left

local Code = Instance.new("TextLabel")
Code.Name = "Code"
Code.Parent = CodeFrame
Code.BackgroundTransparency = 1.000
Code.Position = UDim2.new(0, 5, 0, CodeComment.Position.Y.Offset + CodeComment.Size.Y.Offset)
Code.Size = UDim2.new(10, 0, 1, - (CodeComment.Position.Y.Offset + CodeComment.Size.Y.Offset + 5)) -- Ukuran X besar untuk scroll
Code.ZIndex = 792
Code.Font = Enum.Font.Code
Code.Text = "Select a remote to see its code."
Code.TextColor3 = colorSettings["Code"]["TextColor"]
Code.TextSize = 13.000
Code.TextWrapped = false
Code.TextXAlignment = Enum.TextXAlignment.Left
Code.TextYAlignment = Enum.TextYAlignment.Top


local InfoButtonsScroll = Instance.new("ScrollingFrame")
-- ... (Definisi InfoButtonsScroll dan tombol-tombol di dalamnya seperti CopyCode, RunCode, dll.)
InfoButtonsScroll.Name = "InfoButtonsScroll"
InfoButtonsScroll.Parent = InfoFrame
InfoButtonsScroll.Active = true
InfoButtonsScroll.BackgroundColor3 = colorSettings["Main"]["MainBackgroundColor"]
InfoButtonsScroll.Position = UDim2.new(0.039, 0, CodeFrame.Position.Y.Scale, CodeFrame.Position.Y.Offset + CodeFrame.Size.Y.Offset + 10)
InfoButtonsScroll.Size = UDim2.new(1, -28, 1, -(CodeFrame.Position.Y.Offset + CodeFrame.Size.Y.Offset + 10 + InfoFrameHeader.Size.Y.Offset + 5))
InfoButtonsScroll.ZIndex = 791
InfoButtonsScroll.CanvasSize = UDim2.new(0,0,0,0) -- Akan diatur
InfoButtonsScroll.ScrollBarThickness = 6
InfoButtonsScroll.ScrollBarImageColor3 = colorSettings["Main"]["ScrollBarImageColor"]

-- Tombol-tombol di Header
ImageButton = Instance.new("ImageButton") -- Browser Remote
ImageButton.Name = "BrowserButton"
ImageButton.Parent = Header
ImageButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
ImageButton.BackgroundTransparency = 1.000
ImageButton.Position = UDim2.new(0, 5, 0.5, -9)
ImageButton.Size = UDim2.new(0, 18, 0, 18)
ImageButton.ZIndex = 803
ImageButton.Image = "rbxassetid://169476802"
ImageButton.ImageColor3 = colorSettings["Main"]["HeaderTextColor"]

OpenOverpowerButton = Instance.new("ImageButton")
OpenOverpowerButton.Name = "OpenOverpowerButton"
OpenOverpowerButton.Parent = Header
OpenOverpowerButton.BackgroundTransparency = 1.000
OpenOverpowerButton.Position = UDim2.new(0, ImageButton.Position.X.Offset + ImageButton.Size.X.Offset + 5, 0.5, -9)
OpenOverpowerButton.Size = UDim2.new(0, 18, 0, 18)
OpenOverpowerButton.ZIndex = 803
OpenOverpowerButton.Image = "rbxassetid://284402950" -- Ikon Overpower (ganti jika perlu)
OpenOverpowerButton.ImageColor3 = colorSettings["Main"]["HeaderTextColor"]

Minimize = Instance.new("TextButton")
Minimize.Name = "MinimizeButton"
Minimize.Parent = Header
Minimize.BackgroundColor3 = colorSettings["Main"]["HeaderColor"]
Minimize.BorderSizePixel = 0
Minimize.Position = UDim2.new(1, -49, 0.5, -11) -- Kanan, sebelum OpenInfoFrame
Minimize.Size = UDim2.new(0, 22, 0, 22)
Minimize.ZIndex = 803
Minimize.Font = Enum.Font.SourceSansBold
Minimize.Text = "_"
Minimize.TextColor3 = colorSettings["Main"]["HeaderTextColor"]
Minimize.TextSize = 16.000

OpenInfoFrame = Instance.new("TextButton")
OpenInfoFrame.Name = "OpenInfoFrameButton"
OpenInfoFrame.Parent = Header
OpenInfoFrame.BackgroundColor3 = colorSettings["Main"]["HeaderColor"]
OpenInfoFrame.BorderSizePixel = 0
OpenInfoFrame.Position = UDim2.new(1, -25, 0.5, -11) -- Paling kanan
OpenInfoFrame.Size = UDim2.new(0, 22, 0, 22)
OpenInfoFrame.ZIndex = 803
OpenInfoFrame.Font = Enum.Font.SourceSansBold
OpenInfoFrame.Text = ">"
OpenInfoFrame.TextColor3 = colorSettings["Main"]["HeaderTextColor"]
OpenInfoFrame.TextSize = 16.000

-- Parent GUI Utama ke CoreGui setelah semua elemen dasar didefinisikan
ParentGUISafe(TurtleSpyGUI)
task.wait(0.1) -- Beri waktu sedikit untuk parenting

-- Atur tinggi awal mainFrame
mainFrame.Size = UDim2.new(0, 207, 0, 321) -- Tinggi penuh awal

-- [[ BAGIAN 4: FUNGSI LOGIKA INTI (addToList, hooks, event handlers) ]]

local function createInfoButton(name, text, yOffset, parentScroll)
    local button = Instance.new("TextButton")
    button.Name = name
    button.Parent = parentScroll
    button.BackgroundColor3 = colorSettings["MainButtons"]["BackgroundColor"]
    button.BorderColor3 = colorSettings["MainButtons"]["BorderColor"]
    button.Position = UDim2.new(0.05, 0, 0, yOffset)
    button.Size = UDim2.new(0.9, 0, 0, 26)
    button.ZIndex = 15
    button.Font = Enum.Font.SourceSans
    button.Text = text
    button.TextColor3 = colorSettings["MainButtons"]["TextColor"]
    button.TextSize = 15.000
    return button
end

-- Membuat Tombol-tombol di InfoButtonsScroll
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
CopyReturnValueButton.Visible = false -- Awalnya tidak terlihat, hanya untuk RemoteFunction
InfoButtonsScroll.CanvasSize = UDim2.new(0,0,0, infoButtonYOffset + 10)


-- Fungsi addToList (Disederhanakan dan diperbaiki)
local currentRemoteButtonYOffset = 10
function addToList(isRemoteEvent, remoteInstance, ...)
    if not remoteInstance or typeof(remoteInstance) ~= "Instance" then return end
    local currentId = pcall(get_thread_context) and get_thread_context() or (IS_SYNAPSE and syn.get_thread_identity and syn.get_thread_identity()) or 7
    if pcall(set_thread_context, currentId) or (IS_SYNAPSE and syn.set_thread_identity) then
        pcall(set_thread_context, 7) or (IS_SYNAPSE and syn.set_thread_identity and syn.set_thread_identity(7))
    end

    local remoteName = remoteInstance.Name
    local args = table.pack(...)

    local existingIndex
    for i = 1, #remotes do
        if remotes[i] == remoteInstance then
            if table.find(unstacked, remoteInstance) then -- Jika unstacked, cek argumen
                local sameArgs = true
                if #remoteArgs[i] == args.n then
                    for k = 1, args.n do
                        if remoteArgs[i][k] ~= args[k] then sameArgs = false; break end
                    end
                else
                    sameArgs = false
                end
                if sameArgs then existingIndex = i; break end
            else -- Jika stacked, hanya cek instance remote
                existingIndex = i; break
            end
        end
    end

    if not existingIndex then
        table.insert(remotes, remoteInstance)
        table.insert(remoteArgs, args)
        local callingScript = (IS_SYNAPSE and getcallingscript and getcallingscript()) or (rawget and rawget(getfenv(0), "script"))
        table.insert(remoteScripts, callingScript)

        local newButton = RemoteButtonTemplate:Clone()
        newButton.Name = "RemoteEntry_" .. #remotes
        newButton.LayoutOrder = #remotes -- Untuk referensi
        newButton.Parent = RemoteScrollFrame
        newButton.Position = UDim2.new(0.05, 0, 0, currentRemoteButtonYOffset)

        newButton.RemoteIcon.Image = isRemoteEvent and eventImage or functionImage
        newButton.RemoteName.Text = remoteName

        local numberLabel = newButton.Number
        numberLabel.Text = "1"
        table.insert(remoteButtons, numberLabel) -- Simpan referensi ke label angka

        -- Atur posisi dan ukuran nama remote berdasarkan teks angka
        local numSize = TextService:GetTextSize(numberLabel.Text, numberLabel.TextSize, numberLabel.Font, Vector2.new(math.huge, numberLabel.AbsoluteSize.Y))
        numberLabel.Size = UDim2.new(0, numSize.X + 5, 1, 0)
        newButton.RemoteName.Position = UDim2.new(0, numberLabel.AbsoluteSize.X + 5, 0, 0)
        newButton.RemoteName.Size = UDim2.new(1, -(numberLabel.AbsoluteSize.X + 5 + newButton.RemoteIcon.AbsoluteSize.X + 10), 1, 0)

        currentRemoteButtonYOffset = currentRemoteButtonYOffset + newButton.AbsoluteSize.Y + 5
        if currentRemoteButtonYOffset > RemoteScrollFrame.CanvasSize.Y.Offset then
            RemoteScrollFrame.CanvasSize = UDim2.new(0,0,0, currentRemoteButtonYOffset + 10)
        end

        -- Event handler untuk tombol baru
        newButton.MouseButton1Click:Connect(function()
            lookingAt = remoteInstance
            lookingAtArgs = args
            lookingAtButton = numberLabel -- Referensi ke label angka untuk update hitungan

            InfoHeaderText.Text = "Info: " .. remoteName
            CodeComment.Text = "-- Called from: " .. (callingScript and GetFullPathOfAnInstance(callingScript) or "Unknown Script")
            Code.Text = GetFullPathOfAnInstance(remoteInstance) .. (isRemoteEvent and ":FireServer(" or ":InvokeServer(") .. convertTableToString(args,0) .. ")"
            
            local codeTextSize = TextService:GetTextSize(Code.Text, Code.TextSize, Code.Font, Vector2.new(math.huge, math.huge))
            local commentTextSize = TextService:GetTextSize(CodeComment.Text, CodeComment.TextSize, CodeComment.Font, Vector2.new(math.huge, math.huge))
            Code.Size = UDim2.new(0, math.max(codeTextSize.X, commentTextSize.X) + 20, 0, codeTextSize.Y + 5)
            CodeFrame.CanvasSize = UDim2.new(0, math.max(codeTextSize.X, commentTextSize.X) + 30, 0, Code.Position.Y.Offset + Code.Size.Y.Offset + 10)


            CopyReturnValueButton.Visible = not isRemoteEvent
            local baseCanvasY = 290
            if not isRemoteEvent then baseCanvasY = baseCanvasY + 35 end
            InfoButtonsScroll.CanvasSize = UDim2.new(0,0,0, baseCanvasY)


            local isBlocked = table.find(BlockList, remoteInstance)
            BlockRemoteButton.Text = isBlocked and "Unblock Remote" or "Block Remote"
            BlockRemoteButton.TextColor3 = isBlocked and Color3.fromRGB(251,197,49) or colorSettings["MainButtons"]["TextColor"]

            local isIgnored = table.find(IgnoreList, remoteInstance)
            IgnoreRemoteButton.Text = isIgnored and "Unignore Remote" or "Ignore Remote"
            IgnoreRemoteButton.TextColor3 = isIgnored and Color3.fromRGB(127,143,166) or colorSettings["MainButtons"]["TextColor"]

            local isUnstacked = table.find(unstacked, remoteInstance)
            DoNotStackButton.Text = isUnstacked and "Stack Remote" or "Unstack Remote"
            DoNotStackButton.TextColor3 = isUnstacked and Color3.fromRGB(251,197,49) or colorSettings["MainButtons"]["TextColor"]

            if not InfoFrame.Visible then
                InfoFrame.Visible = true
                InfoFrameOpen = true
                mainFrame.Size = UDim2.new(0, mainFrame.Size.X.Offset + InfoFrame.Size.X.Offset + 5, 0, mainFrame.Size.Y.Offset)
                OpenInfoFrame.Text = "<"
            end
        end)
        table.insert(connections, newButton.MouseButton1Click) -- Simpan koneksi untuk di-disconnect nanti

    else -- Remote sudah ada
        remoteButtons[existingIndex].Text = tostring(tonumber(remoteButtons[existingIndex].Text) + 1)
        remoteArgs[existingIndex] = args -- Update argumen terakhir

        local numSize = TextService:GetTextSize(remoteButtons[existingIndex].Text, remoteButtons[existingIndex].TextSize, remoteButtons[existingIndex].Font, Vector2.new(math.huge, remoteButtons[existingIndex].AbsoluteSize.Y))
        remoteButtons[existingIndex].Size = UDim2.new(0, numSize.X + 5, 1, 0)
        local parentButton = remoteButtons[existingIndex].Parent
        parentButton.RemoteName.Position = UDim2.new(0, remoteButtons[existingIndex].AbsoluteSize.X + 5, 0, 0)
        parentButton.RemoteName.Size = UDim2.new(1, -(remoteButtons[existingIndex].AbsoluteSize.X + 5 + parentButton.RemoteIcon.AbsoluteSize.X + 10), 1, 0)


        if lookingAt == remoteInstance and lookingAtButton == remoteButtons[existingIndex] and InfoFrame.Visible then
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

-- Event Handlers untuk Tombol Info
CopyCodeButton.MouseButton1Click:Connect(function()
    if lookingAt and Code.Text ~= "" and setclipboard then
        setclipboard(CodeComment.Text .. "\n" .. Code.Text)
        ButtonEffect(CopyCodeButton)
    else
        ButtonEffect(CopyCodeButton, "Nothing to copy!", Color3.fromRGB(230,0,0))
    end
end)

RunCodeButton.MouseButton1Click:Connect(function()
    if lookingAt and lookingAtArgs then
        local remote = lookingAt
        local argsUnpacked = table.unpack(lookingAtArgs, 1, lookingAtArgs.n)
        local success, err = pcall(function()
            if remote:IsA("RemoteEvent") then
                remote:FireServer(argsUnpacked)
            elseif remote:IsA("RemoteFunction") then
                remote:InvokeServer(argsUnpacked)
            end
        end)
        if success then
            ButtonEffect(RunCodeButton, "Executed!")
        else
            ButtonEffect(RunCodeButton, "Error!", Color3.fromRGB(230,0,0))
            warn("TurtleSpy: RunCode Error:", err)
        end
    else
        ButtonEffect(RunCodeButton, "No remote selected!", Color3.fromRGB(230,0,0))
    end
end)

CopyScriptPathButton.MouseButton1Click:Connect(function()
    if lookingAt then
        local index
        for i=1, #remotes do if remotes[i] == lookingAt then index = i; break; end end
        if index and remoteScripts[index] and setclipboard then
            setclipboard(GetFullPathOfAnInstance(remoteScripts[index]))
            ButtonEffect(CopyScriptPathButton)
        else
            ButtonEffect(CopyScriptPathButton, "Script N/A", Color3.fromRGB(230,0,0))
        end
    end
end)

CopyDecompiledButton.MouseButton1Click:Connect(function()
    if not IS_SYNAPSE or not decompile or not syn.request then -- Cek decompile dan syn.request
        ButtonEffect(CopyDecompiledButton, "Synapse Only!", Color3.fromRGB(230,0,0))
        return
    end
    if lookingAt and not decompiling then
        local index
        for i=1, #remotes do if remotes[i] == lookingAt then index = i; break; end end
        if not index or not remoteScripts[index] then
            ButtonEffect(CopyDecompiledButton, "Script N/A", Color3.fromRGB(230,0,0))
            return
        end

        decompiling = true
        local originalText = CopyDecompiledButton.Text
        task.spawn(function() -- Gunakan task.spawn
            local dots = ""
            while decompiling do
                dots = dots == "..." and "." or dots .. "."
                CopyDecompiledButton.Text = "Decompiling" .. dots
                task.wait(0.4)
            end
            CopyDecompiledButton.Text = originalText -- Kembalikan teks jika sudah selesai/error
        end)

        local success, result = pcall(decompile, remoteScripts[index])
        decompiling = false
        if success and type(result) == "string" then
            if setclipboard then setclipboard(result) end
            ButtonEffect(CopyDecompiledButton, "Decompiled & Copied!")
        else
            ButtonEffect(CopyDecompiledButton, "Decompile Error!", Color3.fromRGB(230,0,0))
            warn("TurtleSpy: Decompile Error:", result)
        end
    end
end)

DoNotStackButton.MouseButton1Click:Connect(function()
    if lookingAt then
        local idx = table.find(unstacked, lookingAt)
        if idx then
            table.remove(unstacked, idx)
            DoNotStackButton.Text = "Unstack Remote"
            DoNotStackButton.TextColor3 = colorSettings["MainButtons"]["TextColor"]
        else
            table.insert(unstacked, lookingAt)
            DoNotStackButton.Text = "Stack Remote"
            DoNotStackButton.TextColor3 = Color3.fromRGB(251,197,49)
        end
    end
end)

IgnoreRemoteButton.MouseButton1Click:Connect(function()
    if lookingAt then
        local idx = table.find(IgnoreList, lookingAt)
        if idx then
            table.remove(IgnoreList, idx)
            IgnoreRemoteButton.Text = "Ignore Remote"
            IgnoreRemoteButton.TextColor3 = colorSettings["MainButtons"]["TextColor"]
            if lookingAtButton and lookingAtButton.Parent then lookingAtButton.Parent.RemoteName.TextColor3 = colorSettings["RemoteButtons"]["TextColor"] end
        else
            table.insert(IgnoreList, lookingAt)
            IgnoreRemoteButton.Text = "Unignore Remote"
            IgnoreRemoteButton.TextColor3 = Color3.fromRGB(127,143,166)
            if lookingAtButton and lookingAtButton.Parent then lookingAtButton.Parent.RemoteName.TextColor3 = Color3.fromRGB(127,143,166) end
        end
    end
end)

BlockRemoteButton.MouseButton1Click:Connect(function()
     if lookingAt then
        local idx = table.find(BlockList, lookingAt)
        if idx then
            table.remove(BlockList, idx)
            BlockRemoteButton.Text = "Block Remote"
            BlockRemoteButton.TextColor3 = colorSettings["MainButtons"]["TextColor"]
            if lookingAtButton and lookingAtButton.Parent then lookingAtButton.Parent.RemoteName.TextColor3 = colorSettings["RemoteButtons"]["TextColor"] end
        else
            table.insert(BlockList, lookingAt)
            BlockRemoteButton.Text = "Unblock Remote"
            BlockRemoteButton.TextColor3 = Color3.fromRGB(251,197,49)
            if lookingAtButton and lookingAtButton.Parent then lookingAtButton.Parent.RemoteName.TextColor3 = Color3.fromRGB(230,0,0) end
        end
    end
end)

ClearLogsButton.MouseButton1Click:Connect(function()
    for _, child in ipairs(RemoteScrollFrame:GetChildren()) do
        if child.Name:match("^RemoteEntry_") then child:Destroy() end
    end
    for _, conn in ipairs(connections) do if conn and conn.Connected then conn:Disconnect() end end
    
    remotes = {}
    remoteArgs = {}
    remoteButtons = {}
    remoteScripts = {}
    IgnoreList = {}
    BlockList = {}
    unstacked = {}
    connections = {}
    
    currentRemoteButtonYOffset = 10
    RemoteScrollFrame.CanvasSize = UDim2.new(0,0,0,20) -- Reset canvas size
    lookingAt, lookingAtArgs, lookingAtButton = nil, nil, nil
    InfoFrame.Visible = false
    InfoFrameOpen = false
    mainFrame.Size = UDim2.new(0, 207, 0, mainFrame.Size.Y.Offset) -- Kembalikan ukuran x jika info frame tertutup
    OpenInfoFrame.Text = ">"
    ButtonEffect(ClearLogsButton, "Logs Cleared!")
end)

GenerateWhileLoopButton.MouseButton1Click:Connect(function()
    if lookingAt and Code.Text ~= "" and setclipboard then
        setclipboard("while task.wait() do\n    " .. Code.Text .. "\nend")
        ButtonEffect(GenerateWhileLoopButton)
    else
        ButtonEffect(GenerateWhileLoopButton, "No code to loop!", Color3.fromRGB(230,0,0))
    end
end)

CopyReturnValueButton.MouseButton1Click:Connect(function()
    if lookingAt and lookingAt:IsA("RemoteFunction") and lookingAtArgs then
        local remote = lookingAt
        local argsUnpacked = table.unpack(lookingAtArgs, 1, lookingAtArgs.n)
        local status, result = pcall(function() return remote:InvokeServer(argsUnpacked) end)
        if status then
            if setclipboard then setclipboard(convertTableToString(table.pack(result))) end
            ButtonEffect(CopyReturnValueButton, "Return Copied!")
        else
            ButtonEffect(CopyReturnValueButton, "Invoke Error!", Color3.fromRGB(230,0,0))
            warn("TurtleSpy: Invoke Error for CopyReturn:", result)
        end
    else
        ButtonEffect(CopyReturnValueButton, "Not a Function or No Args!", Color3.fromRGB(230,0,0))
    end
end)


-- Event Handlers untuk Tombol Header
OpenInfoFrame.MouseButton1Click:Connect(function()
    InfoFrameOpen = not InfoFrameOpen
    InfoFrame.Visible = InfoFrameOpen
    if InfoFrameOpen then
        mainFrame.Size = UDim2.new(0, mainFrame.Size.X.Offset + InfoFrame.Size.X.Offset + 5, 0, mainFrame.Size.Y.Offset)
        OpenInfoFrame.Text = "<"
    else
        mainFrame.Size = UDim2.new(0, mainFrame.Size.X.Offset - InfoFrame.Size.X.Offset - 5, 0, mainFrame.Size.Y.Offset)
        OpenInfoFrame.Text = ">"
    end
end)
CloseInfoFrameButton.MouseButton1Click:Connect(function() -- Tombol X di InfoFrameHeader
    if InfoFrameOpen then OpenInfoFrame:MouseButton1Click() end -- Panggil logika toggle
end)

Minimize.MouseButton1Click:Connect(function()
    local isCurrentlyVisible = RemoteScrollFrame.Visible
    RemoteScrollFrame.Visible = not isCurrentlyVisible
    
    if RemoteScrollFrame.Visible then -- Membuka
        mainFrame.Size = UDim2.new(0, mainFrame.Size.X.Offset, 0, 321) -- Ukuran penuh
        Minimize.Text = "_"
        if InfoFrameOpen then -- Jika info frame seharusnya terbuka, pastikan ukuran x benar
             mainFrame.Size = UDim2.new(0, 207 + InfoFrame.Size.X.Offset + 5, 0, 321)
             InfoFrame.Visible = true
             OpenInfoFrame.Text = "<"
        else
            mainFrame.Size = UDim2.new(0, 207, 0, 321)
            InfoFrame.Visible = false
            OpenInfoFrame.Text = ">"
        end
    else -- Menutup
        mainFrame.Size = UDim2.new(0, mainFrame.Size.X.Offset, 0, Header.Size.Y.Offset) -- Hanya header
        Minimize.Text = "□"
        InfoFrame.Visible = false -- Info frame juga tertutup saat minimize
    end
end)

-- Logika untuk Keybind
if mouse and mouse.KeyDown then
    mouse.KeyDown:Connect(function(key)
        if key:lower() == settings.Keybind:lower() then
            TurtleSpyGUI.Enabled = not TurtleSpyGUI.Enabled
        end
    end)
else
    print("TurtleSpy Warning: Mouse atau Mouse.KeyDown tidak tersedia. Keybind mungkin tidak berfungsi.")
end

-- Hooking Functions (PENTING: Ini bagian yang paling sensitif terhadap environment exploit)
local OldEventFireServer, OldFunctionInvokeServer, OldNamecall

local function unhookFunctions()
    if OldEventFireServer and OldEventFireServer.UnHook then OldEventFireServer:UnHook() end
    if OldFunctionInvokeServer and OldFunctionInvokeServer.UnHook then OldFunctionInvokeServer:UnHook() end
    if OldNamecall and OldNamecall.UnHook then OldNamecall:UnHook() end
    print("TurtleSpy: Hooks dinonaktifkan.")
end

local function hookFunctions()
    local success = true
    local errorMessages = {}

    -- Hook RemoteEvent.FireServer
    local _, err1 = pcall(function()
        local eventExample = Instance.new("RemoteEvent")
        OldEventFireServer = hookfunction(eventExample.FireServer, function(self, ...)
            if not checkcaller() and table.find(BlockList, self) then return end
            if table.find(IgnoreList, self) then return OldEventFireServer(self, ...) end
            addToList(true, self, ...)
            return OldEventFireServer(self, ...)
        end)
        eventExample:Destroy() -- Hancurkan instance contoh
    end)
    if err1 then success = false; table.insert(errorMessages, "Hook FireServer gagal: " .. tostring(err1)) end

    -- Hook RemoteFunction.InvokeServer
    local _, err2 = pcall(function()
        local funcExample = Instance.new("RemoteFunction")
        OldFunctionInvokeServer = hookfunction(funcExample.InvokeServer, function(self, ...)
            if not checkcaller() and table.find(BlockList, self) then return nil end -- RF harus return
            if table.find(IgnoreList, self) then return OldFunctionInvokeServer(self, ...) end
            addToList(false, self, ...)
            return OldFunctionInvokeServer(self, ...)
        end)
        funcExample:Destroy()
    end)
    if err2 then success = false; table.insert(errorMessages, "Hook InvokeServer gagal: " .. tostring(err2)) end

    -- Hook Metamethod __namecall
    local _, err3 = pcall(function()
        OldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
            local method = getnamecallmethod and getnamecallmethod() or (IS_SYNAPSE and get_namecall_method and get_namecall_method())
            if not method then return OldNamecall(self, ...) end -- Jika tidak bisa dapat method, panggil yang asli

            if method == "FireServer" and self:IsA("RemoteEvent") then
                if not checkcaller() and table.find(BlockList, self) then return end
                if table.find(IgnoreList, self) then return OldNamecall(self, ...) end
                addToList(true, self, ...)
            elseif method == "InvokeServer" and self:IsA("RemoteFunction") then
                if not checkcaller() and table.find(BlockList, self) then return nil end
                if table.find(IgnoreList, self) then return OldNamecall(self, ...) end
                addToList(false, self, ...)
            end
            return OldNamecall(self, ...)
        end)
    end)
    if err3 then success = false; table.insert(errorMessages, "Hook __namecall gagal: " .. tostring(err3)) end

    if success then
        print("TurtleSpy: Semua fungsi berhasil di-hook.")
    else
        warn("TurtleSpy: Beberapa hook gagal. Detail:\n" .. table.concat(errorMessages, "\n"))
    end
    return success
end

-- Hanya panggil hookFunctions jika fungsi hook tersedia
if hookfunction and hookmetamethod and (getnamecallmethod or (IS_SYNAPSE and get_namecall_method)) then
    hookFunctions()
else
    print("TurtleSpy Warning: Fungsi hook penting (hookfunction/hookmetamethod/getnamecallmethod) tidak tersedia. Skrip mungkin tidak berfungsi penuh.")
end


-- [[ BAGIAN 5: INISIALISASI FITUR OVERPOWER (GUI dan Logika) ]]
-- (Ini akan menjadi tempat untuk menambahkan OverpowerFeaturesFrame, BrowserFrame, dan logikanya)
-- Untuk saat ini, kita biarkan kosong agar GUI utama stabil dulu.
-- Jika GUI utama sudah stabil, kita bisa tambahkan ini secara bertahap.


-- [[ BAGIAN 6: PEMBERSIHAN SAAT SKRIP BERHENTI ATAU GAME DITUTUP ]]
game:BindToClose(function()
    print("TurtleSpy: Game ditutup. Membersihkan...")
    unhookFunctions()
    if TurtleSpyGUI and TurtleSpyGUI.Parent then
        TurtleSpyGUI:Destroy()
    end
    print("TurtleSpy: Pembersihan selesai.")
end)

print("TurtleSpy V1.5.4 (Revised) Loaded. Tekan '" .. settings.Keybind .. "' untuk toggle GUI.")
if not TurtleSpyGUI.Parent then -- Cek ulang parenting jika gagal di awal
    warn("TurtleSpy: GUI tidak ter-parent dengan benar di awal, mencoba lagi...")
    ParentGUISafe(TurtleSpyGUI)
    if TurtleSpyGUI.Parent then
        print("TurtleSpy: GUI berhasil di-parent pada percobaan kedua.")
    else
        warn("TurtleSpy: Gagal mem-parent GUI bahkan setelah percobaan kedua. Periksa error di atas.")
    end
end
