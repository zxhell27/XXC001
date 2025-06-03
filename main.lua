-- ZXHELL27 Spy V1.6.0, credits to Intrer#0421, modified by ZXHELL27
-- Peningkatan UI, fungsionalitas, dan efek "gridge" ditambahkan.

local colorSettings =
{
    ["Main"] = {
        ["HeaderColor"] = Color3.fromRGB(30, 30, 30), -- Lebih gelap
        ["HeaderShadingColor"] = Color3.fromRGB(25, 25, 25), -- Lebih gelap
        ["HeaderTextColor"] = Color3.fromRGB(0, 190, 255), -- Biru cerah untuk kontras
        ["MainBackgroundColor"] = Color3.fromRGB(45, 45, 45),
        ["InfoScrollingFrameBgColor"] = Color3.fromRGB(40, 40, 40),
        ["ScrollBarImageColor"] = Color3.fromRGB(100, 100, 100),
        ["GridLineColor"] = Color3.fromRGB(60, 60, 60) -- Untuk efek "gridge"
    },
    ["RemoteButtons"] = {
        ["BorderColor"] = Color3.fromRGB(80, 80, 80),
        ["BackgroundColor"] = Color3.fromRGB(55, 55, 55),
        ["BackgroundColorAlternate"] = Color3.fromRGB(50, 50, 50), -- Untuk efek baris bergaris
        ["TextColor"] = Color3.fromRGB(230, 230, 230),
        ["NumberTextColor"] = Color3.fromRGB(0, 190, 255) -- Biru cerah
    },
    ["MainButtons"] = { 
        ["BorderColor"] = Color3.fromRGB(80, 80, 80),
        ["BackgroundColor"] = Color3.fromRGB(65, 65, 65),
        ["TextColor"] = Color3.fromRGB(230, 230, 230),
        ["HoverBackgroundColor"] = Color3.fromRGB(75, 75, 75) -- Warna saat mouse di atas tombol
    },
    ['Code'] = {
        ['BackgroundColor'] = Color3.fromRGB(30, 30, 30),
        ['TextColor'] = Color3.fromRGB(220, 221, 225),
        ['CreditsColor'] = Color3.fromRGB(120, 120, 120)
    },
}

local settings = {
    ["Keybind"] = "P"
}

-- Fungsi utilitas untuk menambahkan UIStroke untuk efek "gridge"
local function addStroke(element, color, thickness)
    if not game:GetService("CoreGui"):FindFirstChild("UIStroke") then -- Periksa apakah UIStroke didukung/ada
        -- Fallback jika UIStroke tidak tersedia atau untuk eksekutor lama
        element.BorderSizePixel = thickness or 1
        element.BorderColor3 = color or colorSettings.Main.GridLineColor
        return
    end
    local stroke = Instance.new("UIStroke")
    stroke.Color = color or colorSettings.Main.GridLineColor
    stroke.Thickness = thickness or 1
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = element
    return stroke
end


if PROTOSMASHER_LOADED then
    getgenv().isfile = newcclosure(function(File)
        local Suc, Er = pcall(readfile, File)
        if not Suc then
            return false
        end
        return true
    end)
end

local HttpService = game:GetService("HttpService")
-- baca pengaturan untuk keybind
if not isfile("ZXHELL27SpySettings.json") then -- Nama file pengaturan diubah
    writefile("ZXHELL27SpySettings.json", HttpService:JSONEncode(settings))
else
    local success, decodedSettings = pcall(function() return HttpService:JSONDecode(readfile("ZXHELL27SpySettings.json")) end)
    if success and decodedSettings then
        if decodedSettings["Main"] then -- Logika lama untuk pengaturan yang salah
            writefile("ZXHELL27SpySettings.json", HttpService:JSONEncode(settings))
        else
            settings = decodedSettings
        end
    else
        -- Gagal membaca atau mendekode, tulis ulang dengan default
        writefile("ZXHELL27SpySettings.json", HttpService:JSONEncode(settings))
    end
end

-- Kompatibilitas untuk protosmasher: credits to sdjsdj (v3rm username) untuk konversi ke proto
function isSynapse()
    if PROTOSMASHER_LOADED then
        return false
    else
        return true -- Asumsikan Synapse jika bukan Protosmasher, bisa disesuaikan
    end
end

function Parent(GUI)
    if syn and syn.protect_gui then
        syn.protect_gui(GUI)
        GUI.Parent = game:GetService("CoreGui")
    elseif PROTOSMASHER_LOADED then
        GUI.Parent = get_hidden_gui()
    else
        GUI.Parent = game:GetService("CoreGui")
    end
end

local client = game.Players.LocalPlayer
local function toUnicode(str) -- Menggunakan 'str' sebagai nama parameter yang lebih umum
    local codepoints = "utf8.char("
    for _, v in utf8.codes(str) do
        codepoints = codepoints .. v .. ', '
    end
    return codepoints:sub(1, -3) .. ')'
end

local function GetFullPathOfAnInstance(instance)
    if not instance then return "nil" end -- Penanganan instance nil
    local name = instance.Name
    local head = (#name > 0 and '.' .. name) or "['']"
    
    if not instance.Parent and instance ~= game then
        return head .. " --[[ PARENTED TO NIL OR DESTROYED ]]"
    end
    
    if instance == game then
        return "game"
    elseif instance == workspace then
        return "workspace"
    else
        local success, serviceName = pcall(function() return game:GetService(instance.ClassName) end)
        
        if success and serviceName == instance then -- Periksa apakah instance adalah service itu sendiri
            head = ':GetService("' .. instance.ClassName .. '")'
        elseif instance == client then
            head = '.LocalPlayer' 
        else
            local nonAlphaNum = name:gsub('[%w_]', '')
            local noPunct = nonAlphaNum:gsub('[%s%p]', '')
            
            if tonumber(name:sub(1, 1)) or (#nonAlphaNum ~= 0 and #noPunct == 0) then
                head = '["' .. name:gsub('"', '\\"'):gsub('\\', '\\\\') .. '"]'
            elseif #nonAlphaNum ~= 0 and #noPunct > 0 then
                head = '[' .. toUnicode(name) .. ']'
            end
        end
    end
    
    return GetFullPathOfAnInstance(instance.Parent) .. head
end
-- Main Script

-- referensi ke fungsi game (untuk mencegah penggunaan namecall di dalam hook namecall)
local isA = game.IsA
local clone = game.Clone -- Menggunakan Instance.new("Frame") lebih disukai daripada game.Clone untuk UI

local TextService = game:GetService("TextService")
local getTextSize = TextService.GetTextSize -- Cache fungsi
game.StarterGui.ResetPlayerGuiOnSpawn = false
local mouse = game.Players.LocalPlayer:GetMouse()

-- hapus instance turtlespy sebelumnya
if game.CoreGui:FindFirstChild("ZXHELL27SpyGUI") then -- Nama GUI diubah
    game.CoreGui.ZXHELL27SpyGUI:Destroy()
end

-- Tabel penting dan offset GUI
local buttonOffsetY = 10 -- Offset Y awal untuk tombol di RemoteScrollFrame
local remoteButtonHeight = 30 -- Tinggi tombol remote + padding
local scrollSizeOffsetY = 0 -- Offset ukuran scroll awal
local functionImage = "http://www.roblox.com/asset/?id=413369623"
local eventImage = "http://www.roblox.com/asset/?id=413369506"
local remotes = {}
local remoteArgs = {}
local remoteData = {} -- Tabel baru untuk menyimpan data terkait remote (button, args, script, count)
local IgnoreList = {}
local BlockList = {}
local connections = {}
local unstacked = {}

-- (sebagian besar) kode yang dihasilkan oleh Gui to lua
local TurtleSpyGUI = Instance.new("ScreenGui") -- Akan dinamai ZXHELL27SpyGUI
local mainFrame = Instance.new("Frame")
local Header = Instance.new("Frame")
-- HeaderShading tidak diperlukan jika menggunakan UIStroke atau desain datar
local HeaderTextLabel = Instance.new("TextLabel")
local RemoteScrollFrame = Instance.new("ScrollingFrame")
local RemoteButtonTemplate = Instance.new("TextButton") -- Template untuk tombol remote
local NumberLabelTemplate = Instance.new("TextLabel") -- Template untuk label nomor
local RemoteNameLabelTemplate = Instance.new("TextLabel") -- Template untuk nama remote
local RemoteIconTemplate = Instance.new("ImageLabel") -- Template untuk ikon remote

local InfoFrame = Instance.new("Frame")
local InfoFrameHeader = Instance.new("Frame")
-- InfoTitleShading tidak diperlukan
local CodeFrame = Instance.new("ScrollingFrame")
local CodeTextLabel = Instance.new("TextLabel") -- Mengganti nama Code menjadi CodeTextLabel
local CodeCommentTextLabel = Instance.new("TextLabel") -- Mengganti nama CodeComment
local InfoHeaderTextLabel = Instance.new("TextLabel") -- Mengganti nama InfoHeaderText
local InfoButtonsScroll = Instance.new("ScrollingFrame")
local CopyCodeButton = Instance.new("TextButton") -- Mengganti nama
local RunCodeButton = Instance.new("TextButton") -- Mengganti nama
local CopyScriptPathButton = Instance.new("TextButton") -- Mengganti nama
local CopyDecompiledButton = Instance.new("TextButton") -- Mengganti nama
local IgnoreRemoteButton = Instance.new("TextButton") -- Mengganti nama
local BlockRemoteButton = Instance.new("TextButton") -- Mengganti nama
local WhileLoopButton = Instance.new("TextButton") -- Mengganti nama
local CopyReturnButton = Instance.new("TextButton") -- Mengganti nama
local ClearLogsButton = Instance.new("TextButton") -- Mengganti nama Clear
local FrameDivider = Instance.new("Frame")
local CloseInfoFrameButton = Instance.new("TextButton") -- Mengganti nama
local OpenInfoFrameButton = Instance.new("TextButton") -- Mengganti nama
local MinimizeButton = Instance.new("TextButton") -- Mengganti nama
local DoNotStackButton = Instance.new("TextButton") -- Mengganti nama DoNotStack
local RemoteBrowserButton = Instance.new("ImageButton") -- Mengganti nama ImageButton

-- Remote browser
local BrowserHeader = Instance.new("Frame")
-- BrowserHeaderFrame tidak diperlukan
local BrowserHeaderText = Instance.new("TextLabel")
local CloseBrowserButton = Instance.new("TextButton") -- Mengganti nama CloseInfoFrame2
local RemoteBrowserFrame = Instance.new("ScrollingFrame")
local RemoteButtonBrowserTemplate = Instance.new("TextButton") -- Template, mengganti RemoteButton2
local RemoteNameBrowserLabelTemplate = Instance.new("TextLabel") -- Template, mengganti RemoteName2
local RemoteIconBrowserTemplate = Instance.new("ImageLabel") -- Template, mengganti RemoteIcon2

TurtleSpyGUI.Name = "ZXHELL27SpyGUI" -- Nama GUI diubah
Parent(TurtleSpyGUI)

-- Fungsi untuk membuat tombol dengan gaya yang konsisten
local function createStyledButton(parent, text, position, size)
    local button = Instance.new("TextButton")
    button.Parent = parent
    button.Text = text
    button.Position = position
    button.Size = size
    button.BackgroundColor3 = colorSettings.MainButtons.BackgroundColor
    button.BorderColor3 = colorSettings.MainButtons.BorderColor -- Digunakan jika UIStroke tidak ada
    button.TextColor3 = colorSettings.MainButtons.TextColor
    button.Font = Enum.Font.SourceSansBold
    button.TextSize = 15.000
    button.AutoButtonColor = false -- Untuk mengontrol warna hover secara manual jika diinginkan

    addStroke(button, colorSettings.MainButtons.BorderColor, 1)

    button.MouseEnter:Connect(function()
        button.BackgroundColor3 = colorSettings.MainButtons.HoverBackgroundColor
    end)
    button.MouseLeave:Connect(function()
        button.BackgroundColor3 = colorSettings.MainButtons.BackgroundColor
    end)
    return button
end

mainFrame.Name = "mainFrame"
mainFrame.Parent = TurtleSpyGUI
mainFrame.BackgroundColor3 = colorSettings.Main.MainBackgroundColor
mainFrame.Position = UDim2.new(0.1, 0, 0.15, 0) -- Posisi disesuaikan
mainFrame.Size = UDim2.new(0, 220, 0, 35) -- Ukuran disesuaikan
mainFrame.ZIndex = 8
mainFrame.Active = true
mainFrame.Draggable = true
addStroke(mainFrame, colorSettings.Main.GridLineColor)

-- Remote browser properties
BrowserHeader.Name = "BrowserHeader"
BrowserHeader.Parent = TurtleSpyGUI
BrowserHeader.BackgroundColor3 = colorSettings.Main.HeaderColor
BrowserHeader.Position = UDim2.new(0.712152421, 0, 0.2, 0) -- Posisi disesuaikan
BrowserHeader.Size = UDim2.new(0, 220, 0, 30) -- Ukuran disesuaikan
BrowserHeader.ZIndex = 20
BrowserHeader.Active = true
BrowserHeader.Draggable = true
BrowserHeader.Visible = false
addStroke(BrowserHeader, colorSettings.Main.GridLineColor)

BrowserHeaderText.Name = "BrowserHeaderText" -- Nama diubah
BrowserHeaderText.Parent = BrowserHeader
BrowserHeaderText.BackgroundTransparency = 1.000
BrowserHeaderText.Position = UDim2.new(0.05, 0, 0, 0)
BrowserHeaderText.Size = UDim2.new(0.8, 0, 1, 0)
BrowserHeaderText.ZIndex = 22
BrowserHeaderText.Font = Enum.Font.SourceSansBold
BrowserHeaderText.Text = "Remote Browser"
BrowserHeaderText.TextColor3 = colorSettings.Main.HeaderTextColor
BrowserHeaderText.TextSize = 16.000
BrowserHeaderText.TextXAlignment = Enum.TextXAlignment.Left

CloseBrowserButton.Name = "CloseBrowserButton" -- Nama diubah
CloseBrowserButton.Parent = BrowserHeader
CloseBrowserButton.BackgroundColor3 = colorSettings.Main.HeaderColor
CloseBrowserButton.Position = UDim2.new(0.85, 0, 0.1, 0)
CloseBrowserButton.Size = UDim2.new(0.1, 0, 0.8, 0)
CloseBrowserButton.ZIndex = 38
CloseBrowserButton.Font = Enum.Font.SourceSansLight
CloseBrowserButton.Text = "X"
CloseBrowserButton.TextColor3 = colorSettings.Main.HeaderTextColor
CloseBrowserButton.TextSize = 20.000
CloseBrowserButton.MouseButton1Click:Connect(function()
    BrowserHeader.Visible = not BrowserHeader.Visible
end)

RemoteBrowserFrame.Name = "RemoteBrowserFrame"
RemoteBrowserFrame.Parent = BrowserHeader
RemoteBrowserFrame.Active = true
RemoteBrowserFrame.BackgroundColor3 = colorSettings.Main.InfoScrollingFrameBgColor
RemoteBrowserFrame.Position = UDim2.new(0, 0, 1, 5) -- Sedikit padding dari header
RemoteBrowserFrame.Size = UDim2.new(1, 0, 0, 280) -- Ukuran disesuaikan
RemoteBrowserFrame.ZIndex = 19
RemoteBrowserFrame.CanvasSize = UDim2.new(0, 0, 0, 0) -- Akan diatur secara dinamis
RemoteBrowserFrame.ScrollBarThickness = 8
RemoteBrowserFrame.VerticalScrollBarPosition = Enum.VerticalScrollBarPosition.Left
RemoteBrowserFrame.ScrollBarImageColor3 = colorSettings.Main.ScrollBarImageColor
addStroke(RemoteBrowserFrame, colorSettings.Main.GridLineColor)

-- Template untuk Tombol Remote di Browser (tidak terlihat secara default)
RemoteButtonBrowserTemplate.Name = "RemoteButtonBrowserTemplate"
RemoteButtonBrowserTemplate.Parent = RemoteBrowserFrame -- Hanya untuk organisasi, akan di-clone
RemoteButtonBrowserTemplate.BackgroundColor3 = colorSettings.RemoteButtons.BackgroundColor
RemoteButtonBrowserTemplate.Size = UDim2.new(0.9, 0, 0, 28) -- Ukuran disesuaikan
RemoteButtonBrowserTemplate.ZIndex = 20
RemoteButtonBrowserTemplate.Font = Enum.Font.SourceSans
RemoteButtonBrowserTemplate.Text = ""
RemoteButtonBrowserTemplate.TextXAlignment = Enum.TextXAlignment.Left
RemoteButtonBrowserTemplate.Visible = false
addStroke(RemoteButtonBrowserTemplate, colorSettings.RemoteButtons.BorderColor)

RemoteNameBrowserLabelTemplate.Name = "RemoteNameBrowserLabel"
RemoteNameBrowserLabelTemplate.Parent = RemoteButtonBrowserTemplate
RemoteNameBrowserLabelTemplate.BackgroundTransparency = 1.000
RemoteNameBrowserLabelTemplate.Position = UDim2.new(0.05, 0, 0, 0)
RemoteNameBrowserLabelTemplate.Size = UDim2.new(0.75, 0, 1, 0)
RemoteNameBrowserLabelTemplate.ZIndex = 21
RemoteNameBrowserLabelTemplate.Font = Enum.Font.SourceSans
RemoteNameBrowserLabelTemplate.Text = "RemoteName"
RemoteNameBrowserLabelTemplate.TextColor3 = colorSettings.RemoteButtons.TextColor
RemoteNameBrowserLabelTemplate.TextSize = 15.000
RemoteNameBrowserLabelTemplate.TextXAlignment = Enum.TextXAlignment.Left
RemoteNameBrowserLabelTemplate.TextTruncate = Enum.TextTruncate.AtEnd

RemoteIconBrowserTemplate.Name = "RemoteIconBrowser"
RemoteIconBrowserTemplate.Parent = RemoteButtonBrowserTemplate
RemoteIconBrowserTemplate.BackgroundTransparency = 1.000
RemoteIconBrowserTemplate.Position = UDim2.new(0.85, 0, 0.1, 0)
RemoteIconBrowserTemplate.Size = UDim2.new(0.1, 0, 0.8, 0)
RemoteIconBrowserTemplate.ZIndex = 21
RemoteIconBrowserTemplate.Image = functionImage
RemoteIconBrowserTemplate.ScaleType = Enum.ScaleType.Fit

local browsedRemotesData = {} -- Untuk menyimpan data remote yang di-browse
local browsedConnections = {}
local remoteBrowserListLayout = Instance.new("UIListLayout")
remoteBrowserListLayout.Parent = RemoteBrowserFrame
remoteBrowserListLayout.Padding = UDim.new(0, 5)
remoteBrowserListLayout.SortOrder = Enum.SortOrder.LayoutOrder
remoteBrowserListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center


RemoteBrowserButton.Name = "RemoteBrowserButton" -- Nama diubah
RemoteBrowserButton.Parent = Header
RemoteBrowserButton.BackgroundTransparency = 1.000
RemoteBrowserButton.Position = UDim2.new(0.05, 0, 0.15, 0)
RemoteBrowserButton.Size = UDim2.new(0, 20, 0, 20) -- Ukuran ikon
RemoteBrowserButton.ZIndex = 9
RemoteBrowserButton.Image = "rbxassetid://169476802" -- Ikon folder/browse
RemoteBrowserButton.ImageColor3 = colorSettings.Main.HeaderTextColor
RemoteBrowserButton.MouseButton1Click:Connect(function()
    BrowserHeader.Visible = not BrowserHeader.Visible
    if BrowserHeader.Visible then
        -- Bersihkan list lama sebelum mengisi ulang
        for _, data in pairs(browsedRemotesData) do
            if data.button and data.button.Parent then data.button:Destroy() end
            if data.connection then data.connection:Disconnect() end
        end
        browsedRemotesData = {}
        
        local currentButtonY = 0
        RemoteBrowserFrame.CanvasSize = UDim2.new(0,0,0,0) -- Reset canvas size

        local foundRemotes = {}
        for _, v in pairs(game:GetDescendants()) do
            if isA(v, "RemoteEvent") or isA(v, "RemoteFunction") then
                table.insert(foundRemotes, v)
            end
        end
        
        -- Urutkan berdasarkan nama untuk konsistensi
        table.sort(foundRemotes, function(a,b) return a.Name < b.Name end)

        for _, remoteInstance in ipairs(foundRemotes) do
            local bButton = RemoteButtonBrowserTemplate:Clone()
            bButton.Parent = RemoteBrowserFrame
            bButton.Visible = true
            bButton.LayoutOrder = #browsedRemotesData + 1
            
            bButton.RemoteNameBrowserLabel.Text = remoteInstance.Name
            local fireFunctionText = ""
            if isA(remoteInstance, "RemoteEvent") then
                fireFunctionText = ":FireServer()"
                bButton.RemoteIconBrowser.Image = eventImage
            else
                fireFunctionText = ":InvokeServer()"
                bButton.RemoteIconBrowser.Image = functionImage
            end

            local connection = bButton.MouseButton1Click:Connect(function()
                setclipboard(GetFullPathOfAnInstance(remoteInstance) .. fireFunctionText)
                -- Efek visual singkat
                local originalColor = bButton.BackgroundColor3
                bButton.BackgroundColor3 = colorSettings.MainButtons.HoverBackgroundColor
                wait(0.2)
                bButton.BackgroundColor3 = originalColor
            end)
            
            table.insert(browsedRemotesData, {button = bButton, connection = connection, remote = remoteInstance})
        end
        -- Update CanvasSize setelah semua tombol ditambahkan
        RemoteBrowserFrame.CanvasSize = UDim2.new(0, 0, 0, #browsedRemotesData * (RemoteButtonBrowserTemplate.Size.Y.Offset + remoteBrowserListLayout.Padding.Offset) )
    end
end)

mouse.KeyDown:Connect(function(key)
    if key:lower() == settings["Keybind"]:lower() then
        TurtleSpyGUI.Enabled = not TurtleSpyGUI.Enabled
    end
end)

Header.Name = "Header"
Header.Parent = mainFrame
Header.BackgroundColor3 = colorSettings.Main.HeaderColor
Header.Size = UDim2.new(1, 0, 0, 30) -- Ukuran disesuaikan
Header.ZIndex = 9
addStroke(Header, colorSettings.Main.GridLineColor, 0) -- Tidak perlu stroke di sini jika menyatu dengan mainframe

HeaderTextLabel.Name = "HeaderTextLabel"
HeaderTextLabel.Parent = Header
HeaderTextLabel.BackgroundTransparency = 1.000
HeaderTextLabel.Position = UDim2.new(0.2, 0, 0, 0) -- Posisi disesuaikan setelah ikon
HeaderTextLabel.Size = UDim2.new(0.5, 0, 1, 0) -- Ukuran disesuaikan
HeaderTextLabel.ZIndex = 10
HeaderTextLabel.Font = Enum.Font.SourceSansBold
HeaderTextLabel.Text = "ZXHELL27 Spy" -- Nama diubah
HeaderTextLabel.TextColor3 = colorSettings.Main.HeaderTextColor
HeaderTextLabel.TextSize = 17.000
HeaderTextLabel.TextXAlignment = Enum.TextXAlignment.Left


RemoteScrollFrame.Name = "RemoteScrollFrame"
RemoteScrollFrame.Parent = mainFrame
RemoteScrollFrame.Active = true
RemoteScrollFrame.BackgroundColor3 = colorSettings.Main.InfoScrollingFrameBgColor
RemoteScrollFrame.Position = UDim2.new(0, 0, 1, 5) -- Sedikit padding dari header
RemoteScrollFrame.Size = UDim2.new(1, 0, 0, 280) -- Ukuran disesuaikan
RemoteScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0) -- Akan diatur secara dinamis
RemoteScrollFrame.ScrollBarThickness = 8
RemoteScrollFrame.VerticalScrollBarPosition = Enum.VerticalScrollBarPosition.Left
RemoteScrollFrame.ScrollBarImageColor3 = colorSettings.Main.ScrollBarImageColor
addStroke(RemoteScrollFrame, colorSettings.Main.GridLineColor)

local remoteScrollListLayout = Instance.new("UIListLayout")
remoteScrollListLayout.Parent = RemoteScrollFrame
remoteScrollListLayout.Padding = UDim.new(0, 3)
remoteScrollListLayout.SortOrder = Enum.SortOrder.LayoutOrder
remoteScrollListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center


-- Template untuk tombol remote (tidak terlihat secara default)
RemoteButtonTemplate.Name = "RemoteButtonTemplate"
RemoteButtonTemplate.Parent = RemoteScrollFrame -- Hanya untuk organisasi
RemoteButtonTemplate.BackgroundColor3 = colorSettings.RemoteButtons.BackgroundColor
RemoteButtonTemplate.Size = UDim2.new(0.9, 0, 0, remoteButtonHeight - remoteScrollListLayout.Padding.Offset * 2)
RemoteButtonTemplate.Font = Enum.Font.SourceSans
RemoteButtonTemplate.Text = ""
RemoteButtonTemplate.Visible = false
addStroke(RemoteButtonTemplate, colorSettings.RemoteButtons.BorderColor)

NumberLabelTemplate.Name = "NumberLabel"
NumberLabelTemplate.Parent = RemoteButtonTemplate
NumberLabelTemplate.BackgroundTransparency = 1.000
NumberLabelTemplate.Position = UDim2.new(0.03, 0, 0, 0)
NumberLabelTemplate.Size = UDim2.new(0.15, 0, 1, 0)
NumberLabelTemplate.ZIndex = 2
NumberLabelTemplate.Font = Enum.Font.SourceSansBold
NumberLabelTemplate.Text = "1"
NumberLabelTemplate.TextColor3 = colorSettings.RemoteButtons.NumberTextColor
NumberLabelTemplate.TextSize = 15.000
NumberLabelTemplate.TextXAlignment = Enum.TextXAlignment.Left

RemoteNameLabelTemplate.Name = "RemoteNameLabel"
RemoteNameLabelTemplate.Parent = RemoteButtonTemplate
RemoteNameLabelTemplate.BackgroundTransparency = 1.000
RemoteNameLabelTemplate.Position = UDim2.new(0.2, 0, 0, 0)
RemoteNameLabelTemplate.Size = UDim2.new(0.6, 0, 1, 0)
RemoteNameLabelTemplate.Font = Enum.Font.SourceSans
RemoteNameLabelTemplate.Text = "RemoteEvent"
RemoteNameLabelTemplate.TextColor3 = colorSettings.RemoteButtons.TextColor
RemoteNameLabelTemplate.TextSize = 15.000
RemoteNameLabelTemplate.TextXAlignment = Enum.TextXAlignment.Left
RemoteNameLabelTemplate.TextTruncate = Enum.TextTruncate.AtEnd

RemoteIconTemplate.Name = "RemoteIcon"
RemoteIconTemplate.Parent = RemoteButtonTemplate
RemoteIconTemplate.BackgroundTransparency = 1.000
RemoteIconTemplate.Position = UDim2.new(0.85, 0, 0.1, 0)
RemoteIconTemplate.Size = UDim2.new(0.1, 0, 0.8, 0)
RemoteIconTemplate.Image = eventImage -- Default ke event
RemoteIconTemplate.ScaleType = Enum.ScaleType.Fit


InfoFrame.Name = "InfoFrame"
InfoFrame.Parent = mainFrame
InfoFrame.BackgroundColor3 = colorSettings.Main.MainBackgroundColor
InfoFrame.Position = UDim2.new(1, 5, 0, 0) -- Diposisikan di sebelah kanan mainFrame
InfoFrame.Size = UDim2.new(0, 370, 1, 0) -- Ukuran disesuaikan, tinggi sama dengan mainFrame + scroll
InfoFrame.Visible = false
InfoFrame.ZIndex = 6
addStroke(InfoFrame, colorSettings.Main.GridLineColor)

InfoFrameHeader.Name = "InfoFrameHeader"
InfoFrameHeader.Parent = InfoFrame
InfoFrameHeader.BackgroundColor3 = colorSettings.Main.HeaderColor
InfoFrameHeader.Size = UDim2.new(1, 0, 0, 30)
InfoFrameHeader.ZIndex = 14
-- addStroke(InfoFrameHeader, colorSettings.Main.GridLineColor, 0) -- Tidak perlu jika menyatu

InfoHeaderTextLabel.Name = "InfoHeaderTextLabel" -- Nama diubah
InfoHeaderTextLabel.Parent = InfoFrameHeader -- Parent diubah ke InfoFrameHeader
InfoHeaderTextLabel.BackgroundTransparency = 1.000
InfoHeaderTextLabel.Position = UDim2.new(0.05, 0, 0, 0)
InfoHeaderTextLabel.Size = UDim2.new(0.8, 0, 1, 0)
InfoHeaderTextLabel.ZIndex = 18
InfoHeaderTextLabel.Font = Enum.Font.SourceSansBold
InfoHeaderTextLabel.Text = "Info: RemoteFunction"
InfoHeaderTextLabel.TextColor3 = colorSettings.Main.HeaderTextColor
InfoHeaderTextLabel.TextSize = 16.000
InfoHeaderTextLabel.TextXAlignment = Enum.TextXAlignment.Left


CodeFrame.Name = "CodeFrame"
CodeFrame.Parent = InfoFrame
CodeFrame.Active = true
CodeFrame.BackgroundColor3 = colorSettings.Code.BackgroundColor
CodeFrame.Position = UDim2.new(0.05, 0, 0.1, 0) -- Posisi disesuaikan
CodeFrame.Size = UDim2.new(0.9, 0, 0, 80) -- Ukuran disesuaikan
CodeFrame.ZIndex = 16
CodeFrame.CanvasSize = UDim2.new(0, 0, 2, 0) -- X akan diatur, Y bisa lebih besar
CodeFrame.ScrollBarThickness = 8
CodeFrame.HorizontalScrollBarInset = Enum.ScrollBarInset.Always
CodeFrame.VerticalScrollBarInset = Enum.ScrollBarInset.Always
CodeFrame.ScrollingDirection = Enum.ScrollingDirection.XY -- Izinkan scroll horizontal dan vertikal
CodeFrame.ScrollBarImageColor3 = colorSettings.Main.ScrollBarImageColor
addStroke(CodeFrame, colorSettings.Main.GridLineColor)

CodeCommentTextLabel.Name = "CodeCommentTextLabel" -- Nama diubah
CodeCommentTextLabel.Parent = CodeFrame
CodeCommentTextLabel.BackgroundTransparency = 1.000
CodeCommentTextLabel.Position = UDim2.new(0, 5, 0, 5)
CodeCommentTextLabel.Size = UDim2.new(1, -10, 0, 20) -- Ukuran dinamis untuk teks
CodeCommentTextLabel.ZIndex = 18
CodeCommentTextLabel.Font = Enum.Font.SourceSansItalic
CodeCommentTextLabel.Text = "-- Script generated by ZXHELL27 Spy" -- Nama diubah
CodeCommentTextLabel.TextColor3 = colorSettings.Code.CreditsColor
CodeCommentTextLabel.TextSize = 13.000
CodeCommentTextLabel.TextXAlignment = Enum.TextXAlignment.Left
CodeCommentTextLabel.TextWrapped = true -- Izinkan wrap jika terlalu panjang

CodeTextLabel.Name = "CodeTextLabel" -- Nama diubah
CodeTextLabel.Parent = CodeFrame
CodeTextLabel.BackgroundTransparency = 1.000
CodeTextLabel.Position = UDim2.new(0, 5, 0, 25) -- Di bawah komentar
CodeTextLabel.Size = UDim2.new(1, -10, 1, -30) -- Ukuran dinamis untuk teks
CodeTextLabel.ZIndex = 18
CodeTextLabel.Font = Enum.Font.Code -- Font yang lebih cocok untuk kode
CodeTextLabel.Text = "Thanks for using ZXHELL27 Spy! :D" -- Nama diubah
CodeTextLabel.TextColor3 = colorSettings.Code.TextColor
CodeTextLabel.TextSize = 14.000
CodeTextLabel.TextXAlignment = Enum.TextXAlignment.Left
CodeTextLabel.TextYAlignment = Enum.TextYAlignment.Top -- Mulai dari atas
CodeTextLabel.TextWrapped = false -- Kode biasanya tidak di-wrap, biarkan scroll horizontal


InfoButtonsScroll.Name = "InfoButtonsScroll"
InfoButtonsScroll.Parent = InfoFrame
InfoButtonsScroll.Active = true
InfoButtonsScroll.BackgroundColor3 = colorSettings.Main.InfoScrollingFrameBgColor
InfoButtonsScroll.Position = UDim2.new(0.05, 0, CodeFrame.Position.Y.Scale + CodeFrame.Size.Y.Scale + 0.05, 0) -- Di bawah CodeFrame
InfoButtonsScroll.Size = UDim2.new(0.9, 0, 1, -(InfoButtonsScroll.Position.Y.Scale * InfoFrame.AbsoluteSize.Y) - 15) -- Sisa ruang
InfoButtonsScroll.ZIndex = 11
InfoButtonsScroll.CanvasSize = UDim2.new(0, 0, 0, 0) -- Akan diatur oleh UIListLayout
InfoButtonsScroll.ScrollBarThickness = 8
InfoButtonsScroll.VerticalScrollBarPosition = Enum.VerticalScrollBarPosition.Left
InfoButtonsScroll.ScrollBarImageColor3 = colorSettings.Main.ScrollBarImageColor
addStroke(InfoButtonsScroll, colorSettings.Main.GridLineColor)

local infoButtonsListLayout = Instance.new("UIListLayout")
infoButtonsListLayout.Parent = InfoButtonsScroll
infoButtonsListLayout.Padding = UDim.new(0, 8)
infoButtonsListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
infoButtonsListLayout.SortOrder = Enum.SortOrder.LayoutOrder

local buttonWidth = UDim.new(0.95, 0)
local buttonHeight = 30

CopyCodeButton = createStyledButton(InfoButtonsScroll, "Copy Code", UDim2.new(), UDim2.new(buttonWidth.Scale,0,0,buttonHeight))
CopyCodeButton.Name = "CopyCodeButton"
CopyCodeButton.LayoutOrder = 1

RunCodeButton = createStyledButton(InfoButtonsScroll, "Execute", UDim2.new(), UDim2.new(buttonWidth.Scale,0,0,buttonHeight))
RunCodeButton.Name = "RunCodeButton"
RunCodeButton.LayoutOrder = 2

CopyScriptPathButton = createStyledButton(InfoButtonsScroll, "Copy Script Path", UDim2.new(), UDim2.new(buttonWidth.Scale,0,0,buttonHeight))
CopyScriptPathButton.Name = "CopyScriptPathButton"
CopyScriptPathButton.LayoutOrder = 3

CopyDecompiledButton = createStyledButton(InfoButtonsScroll, "Copy Decompiled Script", UDim2.new(), UDim2.new(buttonWidth.Scale,0,0,buttonHeight))
CopyDecompiledButton.Name = "CopyDecompiledButton"
CopyDecompiledButton.LayoutOrder = 4

DoNotStackButton = createStyledButton(InfoButtonsScroll, "Unstack Remote (New Args)", UDim2.new(), UDim2.new(buttonWidth.Scale,0,0,buttonHeight))
DoNotStackButton.Name = "DoNotStackButton"
DoNotStackButton.LayoutOrder = 5

IgnoreRemoteButton = createStyledButton(InfoButtonsScroll, "Ignore Remote", UDim2.new(), UDim2.new(buttonWidth.Scale,0,0,buttonHeight))
IgnoreRemoteButton.Name = "IgnoreRemoteButton"
IgnoreRemoteButton.LayoutOrder = 6

BlockRemoteButton = createStyledButton(InfoButtonsScroll, "Block Remote Firing", UDim2.new(), UDim2.new(buttonWidth.Scale,0,0,buttonHeight))
BlockRemoteButton.Name = "BlockRemoteButton"
BlockRemoteButton.LayoutOrder = 7

ClearLogsButton = createStyledButton(InfoButtonsScroll, "Clear Logs", UDim2.new(), UDim2.new(buttonWidth.Scale,0,0,buttonHeight))
ClearLogsButton.Name = "ClearLogsButton"
ClearLogsButton.LayoutOrder = 8

WhileLoopButton = createStyledButton(InfoButtonsScroll, "Generate While Loop", UDim2.new(), UDim2.new(buttonWidth.Scale,0,0,buttonHeight))
WhileLoopButton.Name = "WhileLoopButton"
WhileLoopButton.LayoutOrder = 9

CopyReturnButton = createStyledButton(InfoButtonsScroll, "Execute & Copy Return", UDim2.new(), UDim2.new(buttonWidth.Scale,0,0,buttonHeight))
CopyReturnButton.Name = "CopyReturnButton"
CopyReturnButton.LayoutOrder = 10
CopyReturnButton.Visible = false -- Hanya untuk RemoteFunction


FrameDivider.Name = "FrameDivider" -- Tidak terlalu diperlukan dengan UIStroke, tapi bisa dipertahankan
FrameDivider.Parent = InfoFrame
FrameDivider.BackgroundColor3 = colorSettings.Main.GridLineColor
FrameDivider.Position = UDim2.new(-0.01, 0, 0, 0) -- Di sebelah kiri InfoFrame
FrameDivider.Size = UDim2.new(0, 2, 1, 0)
FrameDivider.ZIndex = 7


local InfoFrameOpen = false
CloseInfoFrameButton.Name = "CloseInfoFrameButton" -- Nama diubah
CloseInfoFrameButton.Parent = InfoFrameHeader -- Parent diubah ke InfoFrameHeader
CloseInfoFrameButton.BackgroundColor3 = colorSettings.Main.HeaderColor
CloseInfoFrameButton.Position = UDim2.new(0.9, 0, 0.1, 0)
CloseInfoFrameButton.Size = UDim2.new(0.08, 0, 0.8, 0)
CloseInfoFrameButton.ZIndex = 18
CloseInfoFrameButton.Font = Enum.Font.SourceSansLight
CloseInfoFrameButton.Text = "X"
CloseInfoFrameButton.TextColor3 = colorSettings.Main.HeaderTextColor
CloseInfoFrameButton.TextSize = 20.000
CloseInfoFrameButton.MouseButton1Click:Connect(function()
    InfoFrame.Visible = false
    InfoFrameOpen = false
    mainFrame.Size = UDim2.new(0, 220, 0, mainFrame.Size.Y.Offset) -- Kembali ke ukuran awal
    OpenInfoFrameButton.Text = ">"
end)

OpenInfoFrameButton.Name = "OpenInfoFrameButton" -- Nama diubah
OpenInfoFrameButton.Parent = Header -- Parent diubah ke Header utama
OpenInfoFrameButton.BackgroundColor3 = colorSettings.Main.HeaderColor
OpenInfoFrameButton.Position = UDim2.new(0.85, 0, 0.15, 0)
OpenInfoFrameButton.Size = UDim2.new(0.1, 0, 0.7, 0)
OpenInfoFrameButton.ZIndex = 18
OpenInfoFrameButton.Font = Enum.Font.SourceSansBold
OpenInfoFrameButton.Text = ">"
OpenInfoFrameButton.TextColor3 = colorSettings.Main.HeaderTextColor
OpenInfoFrameButton.TextSize = 18.000
OpenInfoFrameButton.MouseButton1Click:Connect(function()
	if not InfoFrame.Visible then
		mainFrame.Size = UDim2.new(0, 220 + InfoFrame.Size.X.Offset + 10, 0, mainFrame.Size.Y.Offset) -- Lebar diperluas
		OpenInfoFrameButton.Text = "<"
	else
		mainFrame.Size = UDim2.new(0, 220, 0, mainFrame.Size.Y.Offset) -- Kembali ke ukuran awal
		OpenInfoFrameButton.Text = ">"
	end
	InfoFrame.Visible = not InfoFrame.Visible
	InfoFrameOpen = not InfoFrame.Visible -- Seharusnya InfoFrameOpen = InfoFrame.Visible
end)

MinimizeButton.Name = "MinimizeButton" -- Nama diubah
MinimizeButton.Parent = Header -- Parent diubah ke Header utama
MinimizeButton.BackgroundColor3 = colorSettings.Main.HeaderColor
MinimizeButton.Position = UDim2.new(0.7, 0, 0.15, 0)
MinimizeButton.Size = UDim2.new(0.1, 0, 0.7, 0)
MinimizeButton.ZIndex = 18
MinimizeButton.Font = Enum.Font.SourceSansBold
MinimizeButton.Text = "_"
MinimizeButton.TextColor3 = colorSettings.Main.HeaderTextColor
MinimizeButton.TextSize = 18.000
MinimizeButton.MouseButton1Click:Connect(function()
	local mainFrameHeight = Header.AbsoluteSize.Y + RemoteScrollFrame.AbsoluteSize.Y + 10 -- Perkiraan tinggi
	if RemoteScrollFrame.Visible then -- Jika terbuka, minimalkan
		mainFrame.Size = UDim2.new(0, mainFrame.Size.X.Offset, 0, Header.Size.Y.Offset)
		RemoteScrollFrame.Visible = false
		if InfoFrameOpen then InfoFrame.Visible = false end -- Sembunyikan info frame juga
        OpenInfoFrameButton.Text = ">" -- Reset tombol open info
	else -- Jika terminimalisir, buka
		mainFrame.Size = UDim2.new(0, mainFrame.Size.X.Offset, 0, mainFrameHeight)
		RemoteScrollFrame.Visible = true
		if InfoFrameOpen then 
            InfoFrame.Visible = true 
            OpenInfoFrameButton.Text = "<"
        end
	end
end)

-- Fungsi untuk menemukan data remote berdasarkan instance remote dan argumen (jika unstacked)
local function FindRemoteData(remote, args)
    local currentId = (get_thread_context or syn.get_thread_identity)()
    ;(set_thread_context or syn.set_thread_identity)(7)
    
    local foundData = nil
    for i, data in ipairs(remoteData) do
        if data.remote == remote then
            if table.find(unstacked, remote) then
                -- Jika unstacked, cocokkan juga argumennya
                local match = true
                if #data.args ~= #args then
                    match = false
                else
                    for k = 1, #args do
                        if data.args[k] ~= args[k] then -- Perbandingan sederhana, mungkin perlu deep compare
                            match = false
                            break
                        end
                    end
                end
                if match then
                    foundData = data
                    break
                end
            else
                -- Jika stacked, hanya cocokkan remote instance
                foundData = data
                break
            end
        end
    end
    
    ;(set_thread_context or syn.set_thread_identity)(currentId)
    return foundData
end


-- efek tombol yang disederhanakan
local function ButtonFeedback(button, text)
    local originalText = button.Text
    local originalColor = button.TextColor3
    button.Text = text or "Copied!"
    button.TextColor3 = Color3.fromRGB(76, 209, 55) -- Hijau untuk sukses
    task.delay(0.8, function() -- Menggunakan task.delay
        if button and button.Parent then -- Pastikan tombol masih ada
            button.Text = originalText
            button.TextColor3 = originalColor
        end
    end)
end

local lookingAtData = nil -- Akan menyimpan data remote yang sedang dilihat

CopyCodeButton.MouseButton1Click:Connect(function()
    if not lookingAtData then return end
    setclipboard(CodeCommentTextLabel.Text.. "\n\n"..CodeTextLabel.Text)
    ButtonFeedback(CopyCodeButton)
end)

RunCodeButton.MouseButton1Click:Connect(function()
    if lookingAtData then
        local remote = lookingAtData.remote
        local args = lookingAtData.args
        local success, err = pcall(function()
            if isA(remote, "RemoteFunction") then
                remote:InvokeServer(unpack(args))
            elseif isA(remote, "RemoteEvent") then
                remote:FireServer(unpack(args))
            end
        end)
        if not success then
            warn("ZXHELL27 Spy - Error executing remote:", err)
            ButtonFeedback(RunCodeButton, "Error!")
        else
            ButtonFeedback(RunCodeButton, "Executed!")
        end
    end
end)

CopyScriptPathButton.MouseButton1Click:Connect(function()
    if lookingAtData and lookingAtData.script then
        setclipboard(GetFullPathOfAnInstance(lookingAtData.script))
        ButtonFeedback(CopyScriptPathButton)
    else
         ButtonFeedback(CopyScriptPathButton, "No Script!")
    end
end)

local decompiling = false
CopyDecompiledButton.MouseButton1Click:Connect(function()
    if not lookingAtData or not lookingAtData.script then 
        ButtonFeedback(CopyDecompiledButton, "No Script!")
        return 
    end

    if not isSynapse() then
        ButtonFeedback(CopyDecompiledButton, "No Decompiler!")
        CopyDecompiledButton.TextColor3 = Color3.fromRGB(232, 65, 24) -- Merah untuk error
        task.delay(1.6, function()
            if CopyDecompiledButton and CopyDecompiledButton.Parent then
                 CopyDecompiledButton.Text = "Copy Decompiled Script"
                 CopyDecompiledButton.TextColor3 = colorSettings.MainButtons.TextColor
            end
        end)
        return
    end

    if not decompiling then
        decompiling = true
        local originalText = CopyDecompiledButton.Text
        
        local animationThread = task.spawn(function()
            while decompiling do
                if not CopyDecompiledButton or not CopyDecompiledButton.Parent then break end
                CopyDecompiledButton.Text = "Decompiling."
                task.wait(0.5)
                if not decompiling then break end
                CopyDecompiledButton.Text = "Decompiling.."
                task.wait(0.5)
                if not decompiling then break end
                CopyDecompiledButton.Text = "Decompiling..."
                task.wait(0.5)
            end
        end)

        local success, result = pcall(decompile, lookingAtData.script)
        decompiling = false
        task.cancel(animationThread) -- Hentikan animasi

        if CopyDecompiledButton and CopyDecompiledButton.Parent then
            if success then
                setclipboard(result)
                ButtonFeedback(CopyDecompiledButton, "Decompiled!")
            else
                warn("ZXHELL27 Spy - Decompilation Error:", result)
                ButtonFeedback(CopyDecompiledButton, "Error!")
                CopyDecompiledButton.TextColor3 = Color3.fromRGB(232, 65, 24)
            end
            task.delay(1.6, function()
                if CopyDecompiledButton and CopyDecompiledButton.Parent then
                    CopyDecompiledButton.Text = originalText
                    CopyDecompiledButton.TextColor3 = colorSettings.MainButtons.TextColor
                end
            end)
        end
    end
end)

BlockRemoteButton.MouseButton1Click:Connect(function()
    if not lookingAtData then return end
    local remote = lookingAtData.remote
    local bRemoteIndex = table.find(BlockList, remote)

    if not bRemoteIndex then
        table.insert(BlockList, remote)
        BlockRemoteButton.Text = "Unblock Remote"
        BlockRemoteButton.TextColor3 = Color3.fromRGB(251, 197, 49) -- Kuning untuk status aktif
        if lookingAtData.button then lookingAtData.button.RemoteNameLabel.TextColor3 = Color3.fromRGB(225, 177, 44) end
    else
        table.remove(BlockList, bRemoteIndex)
        BlockRemoteButton.Text = "Block Remote Firing"
        BlockRemoteButton.TextColor3 = colorSettings.MainButtons.TextColor
        if lookingAtData.button then lookingAtData.button.RemoteNameLabel.TextColor3 = colorSettings.RemoteButtons.TextColor end
    end
end)

IgnoreRemoteButton.MouseButton1Click:Connect(function()
    if not lookingAtData then return end
    local remote = lookingAtData.remote
    local iRemoteIndex = table.find(IgnoreList, remote)

    if not iRemoteIndex then
        table.insert(IgnoreList, remote)
        IgnoreRemoteButton.Text = "Stop Ignoring"
        IgnoreRemoteButton.TextColor3 = Color3.fromRGB(127, 143, 166) -- Abu-abu untuk status aktif
        if lookingAtData.button then lookingAtData.button.RemoteNameLabel.TextColor3 = Color3.fromRGB(127, 143, 166) end
    else
        table.remove(IgnoreList, iRemoteIndex)
        IgnoreRemoteButton.Text = "Ignore Remote"
        IgnoreRemoteButton.TextColor3 = colorSettings.MainButtons.TextColor
        if lookingAtData.button then lookingAtData.button.RemoteNameLabel.TextColor3 = colorSettings.RemoteButtons.TextColor end
    end
end)

WhileLoopButton.MouseButton1Click:Connect(function()
    if not lookingAtData then return end
    setclipboard("while task.wait() do\n   "..CodeTextLabel.Text.."\nend") -- Menggunakan task.wait()
    ButtonFeedback(WhileLoopButton)
end)

ClearLogsButton.MouseButton1Click:Connect(function()
    for i = #remoteData, 1, -1 do -- Iterasi mundur untuk menghapus dengan aman
        local data = remoteData[i]
        if data.button and data.button.Parent then data.button:Destroy() end
        if data.connection then data.connection:Disconnect() end
        table.remove(remoteData, i)
    end
    
    -- Reset tabel dan variabel terkait
    remotes = {} -- Dipertahankan untuk kompatibilitas dengan FindRemote lama, tapi remoteData lebih utama
    remoteArgs = {} -- Sama seperti di atas
    IgnoreList = {}
    BlockList = {}
    unstacked = {}
    connections = {} -- Ini harusnya dikelola per tombol, bukan global lagi
    
    buttonOffsetY = 10 -- Reset offset Y
    scrollSizeOffsetY = 0
    RemoteScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    lookingAtData = nil
    
    -- Reset UI InfoFrame jika terbuka
    CodeTextLabel.Text = "Logs Cleared!"
    CodeCommentTextLabel.Text = "-- ZXHELL27 Spy"
    CodeFrame.CanvasSize = UDim2.new(0,0,2,0)
    InfoHeaderTextLabel.Text = "Info"

    ButtonFeedback(ClearLogsButton, "Cleared!")
end)

DoNotStackButton.MouseButton1Click:Connect(function()
    if lookingAtData then
        local remote = lookingAtData.remote
        local isUnstacked = table.find(unstacked, remote)
        if isUnstacked then
            table.remove(unstacked, isUnstacked)
            DoNotStackButton.Text = "Unstack Remote (New Args)"
            DoNotStackButton.TextColor3 = colorSettings.MainButtons.TextColor
        else
            table.insert(unstacked, remote)
            DoNotStackButton.Text = "Stack Remote"
            DoNotStackButton.TextColor3 = Color3.fromRGB(251, 197, 49) -- Kuning
        end
    end
end)

local function len(t)
    local n = 0
    for _ in pairs(t) do n = n + 1 end
    return n
end

-- Konversi tabel ke string dengan indentasi
local function convertTableToString(argsTable, indentLevel)
    indentLevel = indentLevel or 0
    local indent = string.rep("  ", indentLevel)
    local nextIndent = string.rep("  ", indentLevel + 1)
    local str = ""
    
    local isArray = true
    local maxNumericIndex = 0
    for k, _ in pairs(argsTable) do
        if type(k) ~= "number" or k < 1 or k > len(argsTable) then
            isArray = false
        end
        if type(k) == "number" and k > maxNumericIndex then
            maxNumericIndex = k
        end
    end
    if maxNumericIndex ~= len(argsTable) then isArray = false end


    local entries = {}
    if isArray then
        for i = 1, #argsTable do
            local v = argsTable[i]
            local valStr
            if v == nil then valStr = "nil"
            elseif typeof(v) == "Instance" then valStr = GetFullPathOfAnInstance(v)
            elseif type(v) == "number" or type(v) == "function" or type(v) == "boolean" then valStr = tostring(v)
            elseif type(v) == "userdata" then valStr = typeof(v)..": " .. tostring(v) -- Lebih deskriptif
            elseif type(v) == "string" then valStr = string.format("%q", v) -- Menggunakan %q untuk string
            elseif type(v) == "table" then valStr = "{\n" .. convertTableToString(v, indentLevel + 1) .. nextIndent .. "}"
            else valStr = tostring(v) end
            table.insert(entries, nextIndent .. valStr)
        end
    else -- Dictionary-like table
        for k, v in pairs(argsTable) do
            local keyStr
            if type(k) == "string" and k:match("^[%a_][%w_]*$") then keyStr = k -- Kunci identifier sederhana
            else keyStr = "[" .. (type(k)=="string" and string.format("%q", k) or tostring(k)) .. "]"
            end

            local valStr
            if v == nil then valStr = "nil"
            elseif typeof(v) == "Instance" then valStr = GetFullPathOfAnInstance(v)
            elseif type(v) == "number" or type(v) == "function" or type(v) == "boolean" then valStr = tostring(v)
            elseif type(v) == "userdata" then valStr = typeof(v)..": " .. tostring(v)
            elseif type(v) == "string" then valStr = string.format("%q", v)
            elseif type(v) == "table" then valStr = "{\n" .. convertTableToString(v, indentLevel + 1) .. nextIndent .. "}"
            else valStr = tostring(v) end
            table.insert(entries, nextIndent .. keyStr .. " = " .. valStr)
        end
    end
    
    return table.concat(entries, ",\n") .. (len(entries) > 0 and "\n" or "")
end


CopyReturnButton.MouseButton1Click:Connect(function()
    if lookingAtData and isA(lookingAtData.remote, "RemoteFunction") then
        local remote = lookingAtData.remote
        local args = lookingAtData.args
        local success, result = pcall(function() return table.pack(remote:InvokeServer(unpack(args))) end)
        
        if success then
            if result.n == 0 then
                setclipboard("nil -- (no return value)")
            elseif result.n == 1 then
                 setclipboard(convertTableToString({result[1]})) -- Bungkus dalam tabel untuk konsistensi format
            else
                local returnTable = {}
                for i=1, result.n do table.insert(returnTable, result[i]) end
                setclipboard(convertTableToString(returnTable))
            end
            ButtonFeedback(CopyReturnButton, "Return Copied!")
        else
            warn("ZXHELL27 Spy - Error invoking for return:", result)
            setclipboard("-- ERROR INVOKING REMOTE FUNCTION --\n" .. tostring(result))
            ButtonFeedback(CopyReturnButton, "Invoke Error!")
        end
    else
        ButtonFeedback(CopyReturnButton, "Not a Function!")
    end
end)

-- Fungsi utama: tambahkan remote ke daftar
function addToList(isEvent, remote, ...)
    local successCall, errCall = pcall(function() -- Bungkus seluruh fungsi dalam pcall
        local currentId = (get_thread_context or syn.get_thread_identity)()
        ;(set_thread_context or syn.set_thread_identity)(7)
        
        if not remote or not remote.Parent then -- Pemeriksaan tambahan untuk remote yang valid
            ;(set_thread_context or syn.set_thread_identity)(currentId)
            return
        end

        local name = remote.Name
        local args = {...}
        local existingData = FindRemoteData(remote, args)

        if not existingData then
            local newData = {
                remote = remote,
                args = args,
                script = (isSynapse() and getcallingscript() or rawget(getfenv(0), "script")),
                count = 1,
                isEvent = isEvent,
                button = nil, -- Akan diisi oleh tombol yang di-clone
                connection = nil -- Akan diisi oleh koneksi event tombol
            }
            table.insert(remoteData, 1, newData) -- Tambahkan ke awal agar yang terbaru di atas
            
            -- Urutkan ulang remoteData jika diperlukan (misalnya, berdasarkan nama atau waktu)
            -- Saat ini, hanya menambahkan ke atas.

            local rButton = RemoteButtonTemplate:Clone()
            rButton.Parent = RemoteScrollFrame
            rButton.Visible = true
            rButton.LayoutOrder = #remoteData -- Untuk UIListLayout
            
            -- Efek baris bergaris
            if #remoteData % 2 == 0 then
                rButton.BackgroundColor3 = colorSettings.RemoteButtons.BackgroundColorAlternate
            else
                rButton.BackgroundColor3 = colorSettings.RemoteButtons.BackgroundColor
            end

            newData.button = rButton -- Simpan referensi tombol

            rButton.NumberLabel.Text = tostring(newData.count)
            rButton.RemoteNameLabel.Text = name or "Unnamed Remote"
            if not isEvent then
                rButton.RemoteIcon.Image = functionImage
            else
                rButton.RemoteIcon.Image = eventImage
            end
            
            -- Update posisi label nama berdasarkan panjang teks nomor
            local numSize = TextService:GetTextSize(rButton.NumberLabel.Text, rButton.NumberLabel.TextSize, rButton.NumberLabel.Font, Vector2.new(math.huge, math.huge))
            rButton.RemoteNameLabel.Position = UDim2.new(0.05 + numSize.X / rButton.AbsoluteSize.X, 5, 0, 0)
            rButton.RemoteNameLabel.Size = UDim2.new(0.75 - (numSize.X / rButton.AbsoluteSize.X) - 0.05, -5, 1, 0)

            -- Koneksi event untuk tombol ini
            newData.connection = rButton.MouseButton1Click:Connect(function()
                lookingAtData = newData
                
                InfoHeaderTextLabel.Text = "Info: " .. (newData.remote.Name or "Unnamed")
                CopyReturnButton.Visible = not newData.isEvent -- Tampilkan hanya untuk RemoteFunction
                
                -- Update tinggi InfoButtonsScroll berdasarkan visibilitas CopyReturnButton
                local baseButtonCount = 9 -- Jumlah tombol dasar yang selalu terlihat
                local totalButtonHeight = (baseButtonCount + (CopyReturnButton.Visible and 1 or 0)) * (buttonHeight + infoButtonsListLayout.Padding.Offset)
                InfoButtonsScroll.CanvasSize = UDim2.new(0,0,0,totalButtonHeight)

                if not InfoFrame.Visible then -- Jika info frame tertutup, buka
                    OpenInfoFrameButton:MouseButton1Click() -- Simulasikan klik
                end
                
                local fireFunc = newData.isEvent and ":FireServer(" or ":InvokeServer("
                CodeTextLabel.Text = GetFullPathOfAnInstance(newData.remote) .. fireFunc .. "\n" .. convertTableToString(newData.args, 1) .. ")"
                
                -- Update ukuran CodeFrame berdasarkan konten
                local commentSize = TextService:GetTextSize(CodeCommentTextLabel.Text, CodeCommentTextLabel.TextSize, CodeCommentTextLabel.Font, Vector2.new(CodeFrame.AbsoluteSize.X - 20, math.huge))
                local codeSize = TextService:GetTextSize(CodeTextLabel.Text, CodeTextLabel.TextSize, CodeTextLabel.Font, Vector2.new(math.huge, math.huge)) -- Lebar tidak terbatas untuk scroll horizontal
                
                CodeFrame.CanvasSize = UDim2.new(0, math.max(300, codeSize.X + 20), 0, commentSize.Y + codeSize.Y + 30)
                CodeTextLabel.Size = UDim2.new(0, codeSize.X + 10, 0, codeSize.Y + 10) -- Sesuaikan ukuran TextLabel juga
                
                -- Update status tombol di InfoFrame
                BlockRemoteButton.Text = table.find(BlockList, newData.remote) and "Unblock Remote" or "Block Remote Firing"
                BlockRemoteButton.TextColor3 = table.find(BlockList, newData.remote) and Color3.fromRGB(251,197,49) or colorSettings.MainButtons.TextColor
                
                IgnoreRemoteButton.Text = table.find(IgnoreList, newData.remote) and "Stop Ignoring" or "Ignore Remote"
                IgnoreRemoteButton.TextColor3 = table.find(IgnoreList, newData.remote) and Color3.fromRGB(127,143,166) or colorSettings.MainButtons.TextColor

                DoNotStackButton.Text = table.find(unstacked, newData.remote) and "Stack Remote" or "Unstack Remote (New Args)"
                DoNotStackButton.TextColor3 = table.find(unstacked, newData.remote) and Color3.fromRGB(251,197,49) or colorSettings.MainButtons.TextColor
            end)
            
            -- Update CanvasSize dari RemoteScrollFrame
            if #remoteData * (remoteButtonHeight + remoteScrollListLayout.Padding.Offset) > RemoteScrollFrame.AbsoluteSize.Y then
                 RemoteScrollFrame.CanvasSize = UDim2.new(0,0,0, #remoteData * (remoteButtonHeight + remoteScrollListLayout.Padding.Offset))
            else
                 RemoteScrollFrame.CanvasSize = UDim2.new(0,0,0, RemoteScrollFrame.AbsoluteSize.Y) -- Minimal sebesar frame itu sendiri
            end

        else -- Remote sudah ada
            existingData.count = existingData.count + 1
            existingData.args = args -- Update argumen terbaru
            existingData.script = (isSynapse() and getcallingscript() or rawget(getfenv(0), "script")) -- Update script pemanggil terbaru

            if existingData.button and existingData.button.Parent then
                existingData.button.NumberLabel.Text = tostring(existingData.count)
                
                local numSize = TextService:GetTextSize(existingData.button.NumberLabel.Text, existingData.button.NumberLabel.TextSize, existingData.button.NumberLabel.Font, Vector2.new(math.huge, math.huge))
                existingData.button.RemoteNameLabel.Position = UDim2.new(0.05 + numSize.X / existingData.button.AbsoluteSize.X, 5, 0, 0)
                existingData.button.RemoteNameLabel.Size = UDim2.new(0.75 - (numSize.X / existingData.button.AbsoluteSize.X) - 0.05, -5, 1, 0)


                -- Jika remote yang sedang dilihat adalah yang ini, update info panel
                if lookingAtData == existingData and InfoFrame.Visible then
                    local fireFunc = existingData.isEvent and ":FireServer(" or ":InvokeServer("
                    CodeTextLabel.Text = GetFullPathOfAnInstance(existingData.remote) .. fireFunc .. "\n" .. convertTableToString(existingData.args,1) .. ")"
                    local codeSize = TextService:GetTextSize(CodeTextLabel.Text, CodeTextLabel.TextSize, CodeTextLabel.Font, Vector2.new(math.huge, math.huge))
                    local commentSize = TextService:GetTextSize(CodeCommentTextLabel.Text, CodeCommentTextLabel.TextSize, CodeCommentTextLabel.Font, Vector2.new(CodeFrame.AbsoluteSize.X - 20, math.huge))
                    CodeFrame.CanvasSize = UDim2.new(0, math.max(300, codeSize.X + 20), 0, commentSize.Y + codeSize.Y + 30)
                    CodeTextLabel.Size = UDim2.new(0, codeSize.X + 10, 0, codeSize.Y + 10)
                end
            end
        end
        ;(set_thread_context or syn.set_thread_identity)(currentId)
    end)
    if not successCall then
        warn("ZXHELL27 Spy - Error in addToList:", errCall)
    end
end

local OldEvent
OldEvent = hookfunction(Instance.new("RemoteEvent").FireServer, function(Self, ...)
    if not checkcaller() and table.find(BlockList, Self) then return end
    if table.find(IgnoreList, Self) then return OldEvent(Self, ...) end
    
    addToList(true, Self, ...)
    return OldEvent(Self, ...) -- Panggil fungsi asli setelah logging
end)

local OldFunction
OldFunction = hookfunction(Instance.new("RemoteFunction").InvokeServer, function(Self, ...)
    if not checkcaller() and table.find(BlockList, Self) then return end -- Untuk RemoteFunction, return nil atau error jika diblokir
    if table.find(IgnoreList, Self) then return OldFunction(Self, ...) end
    
    local results = table.pack(OldFunction(Self, ...)) -- Panggil fungsi asli terlebih dahulu
    addToList(false, Self, ...) -- Log setelahnya
    return table.unpack(results, 1, results.n) -- Kembalikan hasil asli
end)

local OldNamecall
OldNamecall = hookmetamethod(game,"__namecall",function(...)
    local args = {...}
    local Self = args[1]
    local method = 내부메서드호출() -- Menggunakan alias jika ada, atau (getnamecallmethod or get_namecall_method)()
    
    local shouldLog = false
    local isEvent = false

    if method == "FireServer" and isA(Self, "RemoteEvent")  then
        if not checkcaller() and table.find(BlockList, Self) then return end
        if table.find(IgnoreList, Self) then return OldNamecall(...) end
        isEvent = true
        shouldLog = true
    elseif method == "InvokeServer" and isA(Self, 'RemoteFunction') then
        if not checkcaller() and table.find(BlockList, Self) then return end
        if table.find(IgnoreList, Self) then return OldNamecall(...) end
        isEvent = false
        shouldLog = true
    end

    if shouldLog then
        -- Untuk namecall, argumen dimulai dari indeks ke-2 di 'args'
        local remoteArgsUnpacked = {}
        for i = 2, #args do
            table.insert(remoteArgsUnpacked, args[i])
        end
        
        if isEvent then
             addToList(true, Self, unpack(remoteArgsUnpacked))
        else
            -- Untuk InvokeServer melalui namecall, kita tidak bisa mendapatkan return value di sini tanpa memanggilnya dua kali.
            -- Jadi, kita hanya akan log panggilannya. Return value handling lebih baik di hookfunction langsung.
            addToList(false, Self, unpack(remoteArgsUnpacked))
        end
    end

    return OldNamecall(...)
end)

-- Inisialisasi tinggi mainFrame
task.wait(0.1) -- Tunggu UI dimuat sedikit
local initialMainFrameHeight = Header.AbsoluteSize.Y + RemoteScrollFrame.AbsoluteSize.Y + 20 -- Padding bawah
mainFrame.Size = UDim2.new(mainFrame.Size.X.Scale, mainFrame.Size.X.Offset, 0, initialMainFrameHeight)
InfoFrame.Size = UDim2.new(InfoFrame.Size.X.Scale, InfoFrame.Size.X.Offset, 0, initialMainFrameHeight) -- Samakan tinggi InfoFrame
