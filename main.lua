-- TurtleSpy V1.5.3, credits to Intrer#0421
-- Dimodifikasi oleh ZXHELL X ZEDLIST

-- Pengaturan warna baru (dominan merah)
local colorSettings =
{
    ["Main"] = {
        ["HeaderColor"] = Color3.fromRGB(200, 0, 0), -- Merah Tua
        ["HeaderShadingColor"] = Color3.fromRGB(150, 0, 0), -- Merah Lebih Tua untuk Shading
        ["HeaderTextColor"] = Color3.fromRGB(255, 220, 220), -- Putih Kemerahan Muda
        ["MainBackgroundColor"] = Color3.fromRGB(60, 10, 10), -- Merah Sangat Tua Gelap
        ["InfoScrollingFrameBgColor"] = Color3.fromRGB(60, 10, 10), -- Merah Sangat Tua Gelap
        ["ScrollBarImageColor"] = Color3.fromRGB(180, 50, 50) -- Merah untuk Scrollbar
    },
    ["RemoteButtons"] = {
        ["BorderColor"] = Color3.fromRGB(120, 20, 20), -- Merah Tua untuk Border
        ["BackgroundColor"] = Color3.fromRGB(80, 15, 15), -- Merah Gelap untuk Background
        ["TextColor"] = Color3.fromRGB(255, 200, 200), -- Putih Kemerahan
        ["NumberTextColor"] = Color3.fromRGB(255, 180, 180) -- Putih Kemerahan Muda
    },
    ["MainButtons"] = { 
        ["BorderColor"] = Color3.fromRGB(120, 20, 20), -- Merah Tua untuk Border
        ["BackgroundColor"] = Color3.fromRGB(80, 15, 15), -- Merah Gelap untuk Background
        ["TextColor"] = Color3.fromRGB(255, 200, 200) -- Putih Kemerahan
    },
    ['Code'] = {
        ['BackgroundColor'] = Color3.fromRGB(50, 5, 5), -- Merah Sangat Tua untuk Background Kode
        ['TextColor'] = Color3.fromRGB(255, 220, 220), -- Putih Kemerahan Muda
        ['CreditsColor'] = Color3.fromRGB(150, 120, 120) -- Merah Abu-abu untuk Kredit
    },
}

local settings = {
    ["Keybind"] = "P"
}

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
if not isfile("TurtleSpySettings.json") then
    writefile("TurtleSpySettings.json", HttpService:JSONEncode(settings))
else
    local success, decodedSettings = pcall(HttpService.JSONDecode, HttpService, readfile("TurtleSpySettings.json"))
    if success and decodedSettings then
        if decodedSettings["Main"] then -- Memeriksa apakah format lama
            writefile("TurtleSpySettings.json", HttpService:JSONEncode(settings)) -- Menulis ulang dengan format baru jika format lama
        else
            settings = decodedSettings
        end
    else
        -- Jika gagal decode, tulis ulang dengan pengaturan default
        warn("Gagal membaca TurtleSpySettings.json, menggunakan pengaturan default.")
        writefile("TurtleSpySettings.json", HttpService:JSONEncode(settings))
    end
end

-- Kompatibilitas untuk protosmasher: kredit ke sdjsdj (nama pengguna v3rm) untuk konversi ke proto

function isSynapse()
    if PROTOSMASHER_LOADED then
        return false
    else
        return true
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
local function toUnicode(string)
    local codepoints = "utf8.char("
    
    for _i, v in utf8.codes(string) do
        codepoints = codepoints .. v .. ', '
    end
    
    return codepoints:sub(1, -3) .. ')'
end

local function GetFullPathOfAnInstance(instance)
    if not instance then return "nil" end -- Perbaikan bug: Menangani instance nil
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
        local _success, result = pcall(game.GetService, game, instance.ClassName)
        
        if result and result == instance then -- Pastikan GetService mengembalikan instance yang sama
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
    
    if instance.Parent then
        return GetFullPathOfAnInstance(instance.Parent) .. head
    else
        return head -- Jika instance.Parent adalah nil tetapi bukan game (misalnya CoreGui)
    end
end
-- Skrip Utama

-- referensi ke fungsi game (untuk mencegah penggunaan namecall di dalam hook namecall)
local isA = game.IsA
local clone = game.Clone -- Seharusnya Instance.clone jika Instance adalah variabel lokal, atau langsung Instance.new("Part").Clone jika itu yang dimaksud

local TextService = game:GetService("TextService")
local getTextSize = TextService.GetTextSize -- Seharusnya TextService:GetTextSize
if game:GetService("Players").LocalPlayer then
    local mouse = game:GetService("Players").LocalPlayer:GetMouse() -- Dipindahkan ke sini agar lebih aman
    mouse.KeyDown:Connect(function(key)
        if key:lower() == settings["Keybind"]:lower() then
            TurtleSpyGUI.Enabled = not TurtleSpyGUI.Enabled
        end
    end)
else
    warn("LocalPlayer tidak ditemukan saat inisialisasi TurtleSpy.")
end

game:GetService("StarterGui").ResetPlayerGuiOnSpawn = false -- Menggunakan GetService untuk konsistensi


-- hapus instance turtlespy sebelumnya
if game:GetService("CoreGui"):FindFirstChild("TurtleSpyGUI") then
    game:GetService("CoreGui").TurtleSpyGUI:Destroy()
end

--Tabel penting dan offset GUI
local buttonOffset = -25
local scrollSizeOffset = 287 -- Inisialisasi yang benar
local functionImage = "http://www.roblox.com/asset/?id=413369623"
local eventImage = "http://www.roblox.com/asset/?id=413369506"
local remotes = {}
local remoteArgs = {}
local remoteButtons = {}
local remoteScripts = {}
-- local IgnoreList = {} -- Bug: Didefinisikan dua kali, yang ini dihapus
local BlockList = {}
local IgnoreList = {} -- Definisi IgnoreList yang ini dipertahankan
local connections = {}
local unstacked = {}

-- Kode (sebagian besar) dibuat oleh Gui to lua
local TurtleSpyGUI = Instance.new("ScreenGui")
local mainFrame = Instance.new("Frame")
local Header = Instance.new("Frame")
local HeaderShading = Instance.new("Frame")
local HeaderTextLabel = Instance.new("TextLabel")
local RemoteScrollFrame = Instance.new("ScrollingFrame")
local RemoteButton = Instance.new("TextButton")
local Number = Instance.new("TextLabel")
local RemoteName = Instance.new("TextLabel")
local RemoteIcon = Instance.new("ImageLabel")
local InfoFrame = Instance.new("Frame")
local InfoFrameHeader = Instance.new("Frame")
local InfoTitleShading = Instance.new("Frame")
local CodeFrame = Instance.new("ScrollingFrame")
local Code = Instance.new("TextLabel")
local CodeComment = Instance.new("TextLabel")
local InfoHeaderText = Instance.new("TextLabel")
local InfoButtonsScroll = Instance.new("ScrollingFrame")
local CopyCode = Instance.new("TextButton")
local RunCode = Instance.new("TextButton")
local CopyScriptPath = Instance.new("TextButton")
local CopyDecompiled = Instance.new("TextButton")
local IgnoreRemote = Instance.new("TextButton")
local BlockRemote = Instance.new("TextButton")
local WhileLoop = Instance.new("TextButton")
local CopyReturn = Instance.new("TextButton")
local Clear = Instance.new("TextButton")
local FrameDivider = Instance.new("Frame")
local CloseInfoFrame = Instance.new("TextButton")
local OpenInfoFrame = Instance.new("TextButton")
local Minimize = Instance.new("TextButton")
local DoNotStack = Instance.new("TextButton")
local ImageButton = Instance.new("ImageButton")

-- Browser Remote
local BrowserHeader = Instance.new("Frame")
local BrowserHeaderFrame = Instance.new("Frame")
local BrowserHeaderText = Instance.new("TextLabel")
local CloseInfoFrame2 = Instance.new("TextButton")
local RemoteBrowserFrame = Instance.new("ScrollingFrame")
local RemoteButton2 = Instance.new("TextButton")
local RemoteName2 = Instance.new("TextLabel")
local RemoteIcon2 = Instance.new("ImageLabel")

TurtleSpyGUI.Name = "TurtleSpyGUI"
TurtleSpyGUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling -- Untuk konsistensi render

Parent(TurtleSpyGUI)

mainFrame.Name = "mainFrame"
mainFrame.Parent = TurtleSpyGUI
mainFrame.BackgroundColor3 = colorSettings["Main"]["MainBackgroundColor"] -- Warna baru
mainFrame.BorderColor3 = colorSettings["Main"]["BorderColor"] or colorSettings["Main"]["MainBackgroundColor"] -- Fallback jika BorderColor tidak ada
mainFrame.Position = UDim2.new(0.100000001, 0, 0.239999995, 0)
mainFrame.Size = UDim2.new(0, 207, 0, 35)
mainFrame.ZIndex = 8
mainFrame.Active = true
mainFrame.Draggable = true

-- Properti browser remote

BrowserHeader.Name = "BrowserHeader"
BrowserHeader.Parent = TurtleSpyGUI
BrowserHeader.BackgroundColor3 = colorSettings["Main"]["HeaderShadingColor"]
BrowserHeader.BorderColor3 = colorSettings["Main"]["HeaderShadingColor"]
BrowserHeader.Position = UDim2.new(0.712152421, 0, 0.339464903, 0)
BrowserHeader.Size = UDim2.new(0, 207, 0, 33)
BrowserHeader.ZIndex = 20
BrowserHeader.Active = true
BrowserHeader.Draggable = true
BrowserHeader.Visible = false

BrowserHeaderFrame.Name = "BrowserHeaderFrame"
BrowserHeaderFrame.Parent = BrowserHeader
BrowserHeaderFrame.BackgroundColor3 = colorSettings["Main"]["HeaderColor"]
BrowserHeaderFrame.BorderColor3 = colorSettings["Main"]["HeaderColor"]
BrowserHeaderFrame.Position = UDim2.new(0, 0, -0.0202544238, 0)
BrowserHeaderFrame.Size = UDim2.new(0, 207, 0, 26)
BrowserHeaderFrame.ZIndex = 21

BrowserHeaderText.Name = "InfoHeaderText" -- Seharusnya BrowserHeaderText
BrowserHeaderText.Parent = BrowserHeaderFrame
BrowserHeaderText.BackgroundTransparency = 1.000
BrowserHeaderText.Position = UDim2.new(0, 0, -0.00206991332, 0)
BrowserHeaderText.Size = UDim2.new(0, 206, 0, 33)
BrowserHeaderText.ZIndex = 22
BrowserHeaderText.Font = Enum.Font.SourceSans
BrowserHeaderText.Text = "Remote Browser"
BrowserHeaderText.TextColor3 = colorSettings["Main"]["HeaderTextColor"]
BrowserHeaderText.TextSize = 17.000

CloseInfoFrame2.Name = "CloseInfoFrame" -- Seharusnya CloseBrowserFrame atau semacamnya
CloseInfoFrame2.Parent = BrowserHeaderFrame
CloseInfoFrame2.BackgroundColor3 = colorSettings["Main"]["HeaderColor"]
CloseInfoFrame2.BorderColor3 = colorSettings["Main"]["HeaderColor"]
CloseInfoFrame2.Position = UDim2.new(0, 185, 0, 2)
CloseInfoFrame2.Size = UDim2.new(0, 22, 0, 22)
CloseInfoFrame2.ZIndex = 38
CloseInfoFrame2.Font = Enum.Font.SourceSansLight
CloseInfoFrame2.Text = "X"
CloseInfoFrame2.TextColor3 = colorSettings["Main"]["HeaderTextColor"] -- Disesuaikan dengan tema
CloseInfoFrame2.MouseButton1Click:Connect(function()
    BrowserHeader.Visible = not BrowserHeader.Visible
end)

RemoteBrowserFrame.Name = "RemoteBrowserFrame"
RemoteBrowserFrame.Parent = BrowserHeader
RemoteBrowserFrame.Active = true
RemoteBrowserFrame.BackgroundColor3 = colorSettings["Main"]["InfoScrollingFrameBgColor"] -- Warna baru
RemoteBrowserFrame.BorderColor3 = colorSettings["Main"]["InfoScrollingFrameBgColor"] -- Warna baru
RemoteBrowserFrame.Position = UDim2.new(-0.004540205, 0, 1.03504682, 0)
RemoteBrowserFrame.Size = UDim2.new(0, 207, 0, 286)
RemoteBrowserFrame.ZIndex = 19
RemoteBrowserFrame.CanvasSize = UDim2.new(0, 0, 0, 287)
RemoteBrowserFrame.ScrollBarThickness = 8
RemoteBrowserFrame.VerticalScrollBarPosition = Enum.VerticalScrollBarPosition.Left
RemoteBrowserFrame.ScrollBarImageColor3 = colorSettings["Main"]["ScrollBarImageColor"]

RemoteButton2.Name = "RemoteButton" -- Seharusnya BrowserRemoteButton
RemoteButton2.Parent = RemoteBrowserFrame
RemoteButton2.BackgroundColor3 = colorSettings["RemoteButtons"]["BackgroundColor"]
RemoteButton2.BorderColor3 = colorSettings["RemoteButtons"]["BorderColor"]
RemoteButton2.Position = UDim2.new(0, 17, 0, 10)
RemoteButton2.Size = UDim2.new(0, 182, 0, 26)
RemoteButton2.ZIndex = 20
RemoteButton2.Selected = true
RemoteButton2.Font = Enum.Font.SourceSans
RemoteButton2.Text = ""
RemoteButton2.TextSize = 18.000
RemoteButton2.TextStrokeTransparency = 123.000 -- Sepertinya typo, mungkin maksudnya 1.000 atau property lain
RemoteButton2.TextWrapped = true
RemoteButton2.TextXAlignment = Enum.TextXAlignment.Left
RemoteButton2.Visible = false

RemoteName2.Name = "RemoteName2" -- Seharusnya BrowserRemoteName
RemoteName2.Parent = RemoteButton2
RemoteName2.BackgroundTransparency = 1.000
RemoteName2.Position = UDim2.new(0, 5, 0, 0)
RemoteName2.Size = UDim2.new(0, 155, 0, 26)
RemoteName2.ZIndex = 21
RemoteName2.Font = Enum.Font.SourceSans
RemoteName2.Text = "RemoteEventaasdadad"
RemoteName2.TextColor3 = colorSettings["RemoteButtons"]["TextColor"]
RemoteName2.TextSize = 16.000
RemoteName2.TextXAlignment = Enum.TextXAlignment.Left
RemoteName2.TextTruncate = Enum.TextTruncate.AtEnd -- Lebih deskriptif

RemoteIcon2.Name = "RemoteIcon2" -- Seharusnya BrowserRemoteIcon
RemoteIcon2.Parent = RemoteButton2
RemoteIcon2.BackgroundTransparency = 1.000
RemoteIcon2.Position = UDim2.new(0.840260386, 0, 0.0225472748, 0)
RemoteIcon2.Size = UDim2.new(0, 24, 0, 24)
RemoteIcon2.ZIndex = 21
RemoteIcon2.Image = functionImage

local browsedRemotes = {}
local browsedConnections = {}
local browsedButtonOffset = 10
local browserCanvasSize = 286

ImageButton.Parent = Header
ImageButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
ImageButton.BackgroundTransparency = 1.000
ImageButton.Position = UDim2.new(0, 8, 0, 8)
ImageButton.Size = UDim2.new(0, 18, 0, 18)
ImageButton.ZIndex = 9
ImageButton.Image = "rbxassetid://169476802" -- Pastikan ID aset ini valid
ImageButton.ImageColor3 = colorSettings["Main"]["HeaderTextColor"] -- Disesuaikan dengan tema
ImageButton.MouseButton1Click:Connect(function()
    BrowserHeader.Visible = not BrowserHeader.Visible
    -- Membersihkan remote yang sudah ada sebelumnya untuk mencegah duplikasi saat dibuka kembali
    for _, btn in ipairs(RemoteBrowserFrame:GetChildren()) do
        if btn:IsA("TextButton") and btn.Name == "RemoteButton" then -- Hanya hapus tombol remote yang relevan
            btn:Destroy()
        end
    end
    for _, conn in ipairs(browsedConnections) do
        conn:Disconnect()
    end
    browsedConnections = {}
    browsedButtonOffset = 10 -- Reset offset
    browserCanvasSize = 286 -- Reset ukuran canvas
    RemoteBrowserFrame.CanvasSize = UDim2.new(0, 0, 0, browserCanvasSize)


    for i, v in pairs(game:GetDescendants()) do
        if isA(v, "RemoteEvent") or isA(v, "RemoteFunction") then
            local bButton = RemoteButton2:Clone() -- Menggunakan Clone dari template
            bButton.Parent = RemoteBrowserFrame
            bButton.Visible = true
            bButton.Position = UDim2.new(0, 17, 0, browsedButtonOffset)
            local fireFunction = ""
            if isA(v, "RemoteEvent") then
                fireFunction = ":FireServer()"
                bButton.RemoteIcon2.Image = eventImage
            else
                fireFunction = ":InvokeServer()"
                bButton.RemoteIcon2.Image = functionImage -- Memastikan ikon benar
            end
            bButton.RemoteName2.Text = v.Name
            local pathOfInstance = GetFullPathOfAnInstance(v) -- Simpan path agar tidak dipanggil berulang kali
            local connection = bButton.MouseButton1Click:Connect(function()
                local success, err = pcall(setclipboard, pathOfInstance..fireFunction)
                if not success then
                    warn("Gagal menyalin ke clipboard:", err)
                end
            end)
            table.insert(browsedConnections, connection)
            browsedButtonOffset = browsedButtonOffset + 35

            if #browsedConnections > 8 then -- Seharusnya menggunakan #RemoteBrowserFrame:GetChildren() atau counter yang lebih akurat
                browserCanvasSize = browserCanvasSize + 35
                RemoteBrowserFrame.CanvasSize = UDim2.new(0, 0, 0, browserCanvasSize)
            end
        end
    end
end)

Header.Name = "Header"
Header.Parent = mainFrame
Header.BackgroundColor3 = colorSettings["Main"]["HeaderColor"]
Header.BorderColor3 = colorSettings["Main"]["HeaderColor"]
Header.Size = UDim2.new(0, 207, 0, 26)
Header.ZIndex = 9

HeaderShading.Name = "HeaderShading"
HeaderShading.Parent = Header
HeaderShading.BackgroundColor3 = colorSettings["Main"]["HeaderShadingColor"]
HeaderShading.BorderColor3 = colorSettings["Main"]["HeaderShadingColor"]
HeaderShading.Position = UDim2.new(1.46719131e-07, 0, 0.285714358, 0)
HeaderShading.Size = UDim2.new(0, 207, 0, 27)
HeaderShading.ZIndex = 8

HeaderTextLabel.Name = "HeaderTextLabel"
HeaderTextLabel.Parent = HeaderShading
HeaderTextLabel.BackgroundTransparency = 1.000
HeaderTextLabel.Position = UDim2.new(-0.00507604145, 0, -0.202857122, 0)
HeaderTextLabel.Size = UDim2.new(0, 215, 0, 29)
HeaderTextLabel.ZIndex = 10
HeaderTextLabel.Font = Enum.Font.GothamSemibold -- Font yang lebih modern jika tersedia, atau biarkan SourceSans
HeaderTextLabel.Text = "ZXHELL X ZEDLIST" -- Judul baru
HeaderTextLabel.TextColor3 = colorSettings["Main"]["HeaderTextColor"]
HeaderTextLabel.TextSize = 18.000 -- Sedikit lebih besar untuk judul

-- Fungsi untuk efek glitch pada judul
local function applyGlitchEffect(textLabel, originalText)
    local glitchChars = {"@", "#", "$", "%", "&", "*", "!", "?"}
    local isGlitching = false

    local function startGlitch()
        if isGlitching then return end
        isGlitching = true
        task.spawn(function()
            local duration = 0.3 -- Durasi efek glitch dalam detik
            local interval = 0.05 -- Interval perubahan teks
            local startTime = tick()
            
            while tick() - startTime < duration do
                local newText = ""
                for i = 1, #originalText do
                    if math.random() < 0.7 then -- 70% kemungkinan karakter asli
                        newText = newText .. originalText:sub(i,i)
                    else -- 30% kemungkinan karakter glitch
                        newText = newText .. glitchChars[math.random(#glitchChars)]
                    end
                end
                textLabel.Text = newText
                task.wait(interval)
            end
            textLabel.Text = originalText -- Kembalikan ke teks asli
            isGlitching = false
        end)
    end
    -- Panggil efek glitch sesekali atau saat UI pertama kali muncul
    -- Contoh: panggil saat minimize/maximize atau saat pertama kali UI dibuat
    -- Untuk demo, kita bisa panggil saat minimize di-klik
    return startGlitch 
end

local triggerGlitch = applyGlitchEffect(HeaderTextLabel, "ZXHELL X ZEDLIST")
-- Panggil triggerGlitch() saat event tertentu, misalnya saat UI pertama kali muncul atau saat tombol minimize diklik
-- Untuk contoh, kita panggil sekali setelah UI dibuat
task.wait(0.5) -- Tunggu UI dimuat
triggerGlitch()


RemoteScrollFrame.Name = "RemoteScrollFrame"
RemoteScrollFrame.Parent = mainFrame
RemoteScrollFrame.Active = true
RemoteScrollFrame.BackgroundColor3 = colorSettings["Main"]["InfoScrollingFrameBgColor"] -- Warna baru
RemoteScrollFrame.BorderColor3 = colorSettings["Main"]["InfoScrollingFrameBgColor"] -- Warna baru
RemoteScrollFrame.Position = UDim2.new(0, 0, 1.02292562, 0)
RemoteScrollFrame.Size = UDim2.new(0, 207, 0, 286)
RemoteScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 287)
RemoteScrollFrame.ScrollBarThickness = 8
RemoteScrollFrame.VerticalScrollBarPosition = Enum.VerticalScrollBarPosition.Left
RemoteScrollFrame.ScrollBarImageColor3 = colorSettings["Main"]["ScrollBarImageColor"]

RemoteButton.Name = "RemoteButton"
RemoteButton.Parent = RemoteScrollFrame
RemoteButton.BackgroundColor3 = colorSettings["RemoteButtons"]["BackgroundColor"]
RemoteButton.BorderColor3 = colorSettings["RemoteButtons"]["BorderColor"]
RemoteButton.Position = UDim2.new(0, 17, 0, 10)
RemoteButton.Size = UDim2.new(0, 182, 0, 26)
RemoteButton.Selected = true
RemoteButton.Font = Enum.Font.SourceSans
RemoteButton.Text = ""
RemoteButton.TextColor3 = colorSettings["RemoteButtons"]["TextColor"] -- Warna baru
RemoteButton.TextSize = 18.000
RemoteButton.TextStrokeTransparency = 1.000 -- Memperbaiki kemungkinan typo
RemoteButton.TextWrapped = true
RemoteButton.TextXAlignment = Enum.TextXAlignment.Left
RemoteButton.Visible = false

Number.Name = "Number"
Number.Parent = RemoteButton
Number.BackgroundTransparency = 1.000
Number.Position = UDim2.new(0, 5, 0, 0)
Number.Size = UDim2.new(0, 30, 0, 26) -- Ukuran disesuaikan agar tidak terlalu lebar
Number.ZIndex = 2
Number.Font = Enum.Font.SourceSans
Number.Text = "1"
Number.TextColor3 = colorSettings["RemoteButtons"]["NumberTextColor"]
Number.TextSize = 16.000
Number.TextWrapped = true
Number.TextXAlignment = Enum.TextXAlignment.Left

RemoteName.Name = "RemoteName"
RemoteName.Parent = RemoteButton
RemoteName.BackgroundTransparency = 1.000
RemoteName.Position = UDim2.new(0, 20, 0, 0) -- Akan diatur ulang di addToList
RemoteName.Size = UDim2.new(0, 134, 0, 26) -- Akan diatur ulang di addToList
RemoteName.Font = Enum.Font.SourceSans
RemoteName.Text = "RemoteEvent"
RemoteName.TextColor3 = colorSettings["RemoteButtons"]["TextColor"]
RemoteName.TextSize = 16.000
RemoteName.TextXAlignment = Enum.TextXAlignment.Left
RemoteName.TextTruncate = Enum.TextTruncate.AtEnd

RemoteIcon.Name = "RemoteIcon"
RemoteIcon.Parent = RemoteButton
RemoteIcon.BackgroundTransparency = 1.000
RemoteIcon.Position = UDim2.new(0.840260386, 0, 0.0225472748, 0)
RemoteIcon.Size = UDim2.new(0, 24, 0, 24)
RemoteIcon.Image = eventImage -- Default ke event, akan diubah jika function

InfoFrame.Name = "InfoFrame"
InfoFrame.Parent = mainFrame
InfoFrame.BackgroundColor3 = colorSettings["Main"]["MainBackgroundColor"]
InfoFrame.BorderColor3 = colorSettings["Main"]["MainBackgroundColor"]
InfoFrame.Position = UDim2.new(1.005, 0, 0, 0) -- Diposisikan di kanan mainFrame
InfoFrame.Size = UDim2.new(0, 357, 0, 322)
InfoFrame.Visible = false
InfoFrame.ZIndex = 6

InfoFrameHeader.Name = "InfoFrameHeader"
InfoFrameHeader.Parent = InfoFrame
InfoFrameHeader.BackgroundColor3 = colorSettings["Main"]["HeaderColor"]
InfoFrameHeader.BorderColor3 = colorSettings["Main"]["HeaderColor"]
InfoFrameHeader.Size = UDim2.new(0, 357, 0, 26)
InfoFrameHeader.ZIndex = 14

InfoTitleShading.Name = "InfoTitleShading"
InfoTitleShading.Parent = InfoFrame -- Seharusnya InfoFrameHeader
InfoTitleShading.BackgroundColor3 = colorSettings["Main"]["HeaderShadingColor"]
InfoTitleShading.BorderColor3 = colorSettings["Main"]["HeaderShadingColor"]
InfoTitleShading.Position = UDim2.new(0, 0, 0.2, 0) -- Disesuaikan agar di bawah InfoFrameHeader text
InfoTitleShading.Size = UDim2.new(1, 0, 1, 0) -- Mengisi Parent
InfoTitleShading.ZIndex = 13

CodeFrame.Name = "CodeFrame"
CodeFrame.Parent = InfoFrame
CodeFrame.Active = true
CodeFrame.BackgroundColor3 = colorSettings["Code"]["BackgroundColor"]
CodeFrame.BorderColor3 = colorSettings["Code"]["BackgroundColor"]
CodeFrame.Position = UDim2.new(0.0391303748, 0, 0.141156405, 0)
CodeFrame.Size = UDim2.new(0, 329, 0, 63)
CodeFrame.ZIndex = 16
CodeFrame.CanvasSize = UDim2.new(0, 670, 2, 0)
CodeFrame.ScrollBarThickness = 8
CodeFrame.ScrollingDirection = Enum.ScrollingDirection.XY -- Memungkinkan scroll horizontal dan vertikal
CodeFrame.ScrollBarImageColor3 = colorSettings["Main"]["ScrollBarImageColor"]

Code.Name = "Code"
Code.Parent = CodeFrame
Code.BackgroundTransparency = 1.000
Code.Position = UDim2.new(0.00888902973, 0, 0.0394801199, 0)
Code.Size = UDim2.new(0, 100000, 0, 25) -- Lebar besar untuk teks panjang
Code.ZIndex = 18
Code.Font = Enum.Font.SourceSans
Code.Text = "Terima kasih telah menggunakan ZXHELL X ZEDLIST Spy! :D"
Code.TextColor3 = colorSettings["Code"]["TextColor"]
Code.TextSize = 14.000
Code.TextWrapped = false -- Agar bisa scroll horizontal
Code.TextXAlignment = Enum.TextXAlignment.Left
Code.ClearTextOnFocus = false -- Mencegah teks terhapus

CodeComment.Name = "CodeComment"
CodeComment.Parent = CodeFrame
CodeComment.BackgroundTransparency = 1.000
CodeComment.Position = UDim2.new(0.0119285434, 0, -0.001968503, 0) -- Seharusnya di atas Code.Text
CodeComment.Size = UDim2.new(0, 1000, 0, 25)
CodeComment.ZIndex = 18
CodeComment.Font = Enum.Font.SourceSans
CodeComment.Text = "-- Skrip dibuat oleh TurtleSpy, dimodifikasi oleh ZXHELL X ZEDLIST"
CodeComment.TextColor3 = colorSettings["Code"]["CreditsColor"]
CodeComment.TextSize = 14.000
CodeComment.TextXAlignment = Enum.TextXAlignment.Left

InfoHeaderText.Name = "InfoHeaderText"
InfoHeaderText.Parent = InfoFrameHeader -- Dipindahkan ke InfoFrameHeader
InfoHeaderText.BackgroundTransparency = 1.000
InfoHeaderText.Position = UDim2.new(0.0391303934, 0, 0, 0) -- Disesuaikan
InfoHeaderText.Size = UDim2.new(0.9, 0, 1, 0) -- Mengisi header
InfoHeaderText.ZIndex = 18
InfoHeaderText.Font = Enum.Font.SourceSans
InfoHeaderText.Text = "Info: RemoteFunction"
InfoHeaderText.TextColor3 = colorSettings["Main"]["HeaderTextColor"]
InfoHeaderText.TextSize = 17.000

InfoButtonsScroll.Name = "InfoButtonsScroll"
InfoButtonsScroll.Parent = InfoFrame
InfoButtonsScroll.Active = true
InfoButtonsScroll.BackgroundColor3 = colorSettings["Main"]["MainBackgroundColor"]
InfoButtonsScroll.BorderColor3 = colorSettings["Main"]["MainBackgroundColor"]
InfoButtonsScroll.Position = UDim2.new(0.0391303748, 0, 0.355857909, 0)
InfoButtonsScroll.Size = UDim2.new(0, 329, 0, 199)
InfoButtonsScroll.ZIndex = 11
InfoButtonsScroll.CanvasSize = UDim2.new(0, 0, 1, 0) -- Akan disesuaikan
InfoButtonsScroll.ScrollBarThickness = 8
InfoButtonsScroll.VerticalScrollBarPosition = Enum.VerticalScrollBarPosition.Left
InfoButtonsScroll.ScrollBarImageColor3 = colorSettings["Main"]["ScrollBarImageColor"]

-- Helper untuk membuat tombol info
local function createInfoButton(name, text, yOffset)
    local button = Instance.new("TextButton")
    button.Name = name
    button.Parent = InfoButtonsScroll
    button.BackgroundColor3 = colorSettings["MainButtons"]["BackgroundColor"]
    button.BorderColor3 = colorSettings["MainButtons"]["BorderColor"]
    button.Position = UDim2.new(0.0645, 0, 0, yOffset)
    button.Size = UDim2.new(0, 294, 0, 26)
    button.ZIndex = 15
    button.Font = Enum.Font.SourceSans
    button.Text = text
    button.TextColor3 = colorSettings["MainButtons"]["TextColor"]
    button.TextSize = 16.000
    return button
end

CopyCode = createInfoButton("CopyCode", "Salin kode", 10)
RunCode = createInfoButton("RunCode", "Eksekusi", 45)
CopyScriptPath = createInfoButton("CopyScriptPath", "Salin path skrip", 80)
CopyDecompiled = createInfoButton("CopyDecompiled", "Salin skrip dekompilasi", 115)
DoNotStack = createInfoButton("DoNotStack", "Jangan stack remote saat arg baru", 150)
IgnoreRemote = createInfoButton("IgnoreRemote", "Abaikan remote", 185)
BlockRemote = createInfoButton("BlockRemote", "Blokir remote", 220)
Clear = createInfoButton("Clear", "Bersihkan log", 255)
WhileLoop = createInfoButton("WhileLoop", "Buat skrip while loop", 290)
CopyReturn = createInfoButton("CopyReturn", "Eksekusi & salin nilai return", 325)

-- Sesuaikan CanvasSize InfoButtonsScroll berdasarkan tombol terakhir
InfoButtonsScroll.CanvasSize = UDim2.new(0, 0, 0, CopyReturn.Position.Y.Offset + CopyReturn.Size.Y.Offset + 10)


FrameDivider.Name = "FrameDivider"
FrameDivider.Parent = InfoFrame
FrameDivider.BackgroundColor3 = colorSettings["Main"]["HeaderShadingColor"] -- Warna baru
FrameDivider.BorderColor3 = colorSettings["Main"]["HeaderShadingColor"] -- Warna baru
FrameDivider.Position = UDim2.new(0, 0, 0, 0) -- Di sisi kiri InfoFrame
FrameDivider.Size = UDim2.new(0, 4, 1, 0) -- Tinggi penuh
FrameDivider.ZIndex = 7

local InfoFrameOpen = false
CloseInfoFrame.Name = "CloseInfoFrame"
CloseInfoFrame.Parent = InfoFrameHeader -- Dipindahkan ke InfoFrameHeader agar selalu terlihat
CloseInfoFrame.BackgroundColor3 = colorSettings["Main"]["HeaderColor"]
CloseInfoFrame.BorderColor3 = colorSettings["Main"]["HeaderColor"]
CloseInfoFrame.Position = UDim2.new(1, -24, 0, 2) -- Pojok kanan atas
CloseInfoFrame.Size = UDim2.new(0, 22, 0, 22)
CloseInfoFrame.ZIndex = 18
CloseInfoFrame.Font = Enum.Font.SourceSansLight
CloseInfoFrame.Text = "X"
CloseInfoFrame.TextColor3 = colorSettings["Main"]["HeaderTextColor"] -- Warna baru
CloseInfoFrame.TextSize = 20.000
CloseInfoFrame.MouseButton1Click:Connect(function()
    InfoFrame.Visible = false
    InfoFrameOpen = false
    mainFrame.Size = UDim2.new(0, 207, 0, 35)
    OpenInfoFrame.Text = ">" -- Kembalikan teks tombol Open
end)

OpenInfoFrame.Name = "OpenInfoFrame"
OpenInfoFrame.Parent = Header -- Dipindahkan ke Header utama
OpenInfoFrame.BackgroundColor3 = colorSettings["Main"]["HeaderColor"]
OpenInfoFrame.BorderColor3 = colorSettings["Main"]["HeaderColor"]
OpenInfoFrame.Position = UDim2.new(1, -24, 0, 2) -- Pojok kanan atas Header
OpenInfoFrame.Size = UDim2.new(0, 22, 0, 22)
OpenInfoFrame.ZIndex = 18
OpenInfoFrame.Font = Enum.Font.SourceSans
OpenInfoFrame.Text = ">"
OpenInfoFrame.TextColor3 = colorSettings["Main"]["HeaderTextColor"] -- Warna baru
OpenInfoFrame.TextSize = 16.000
OpenInfoFrame.MouseButton1Click:Connect(function()
	if not InfoFrame.Visible then
		mainFrame.Size = UDim2.new(0, 207 + InfoFrame.Size.X.Offset, 0, 35) -- Lebar dinamis
		OpenInfoFrame.Text = "<"
        InfoFrame.Visible = true
	else
		mainFrame.Size = UDim2.new(0, 207, 0, 35)
		OpenInfoFrame.Text = ">"
        InfoFrame.Visible = false
	end
	InfoFrameOpen = not InfoFrameOpen
end)

Minimize.Name = "Minimize"
Minimize.Parent = Header -- Dipindahkan ke Header utama
Minimize.BackgroundColor3 = colorSettings["Main"]["HeaderColor"]
Minimize.BorderColor3 = colorSettings["Main"]["HeaderColor"]
Minimize.Position = UDim2.new(1, -48, 0, 2) -- Di sebelah kiri OpenInfoFrame
Minimize.Size = UDim2.new(0, 22, 0, 22)
Minimize.ZIndex = 18
Minimize.Font = Enum.Font.SourceSans
Minimize.Text = "_"
Minimize.TextColor3 = colorSettings["Main"]["HeaderTextColor"] -- Warna baru
Minimize.TextSize = 16.000
Minimize.MouseButton1Click:Connect(function()
    triggerGlitch() -- Panggil efek glitch saat minimize
	if RemoteScrollFrame.Visible then
		mainFrame.Size = UDim2.new(0, mainFrame.Size.X.Offset, 0, 35) -- Pertahankan lebar saat ini jika InfoFrame terbuka
        RemoteScrollFrame.Visible = false
        -- Jangan sembunyikan InfoFrame otomatis, biarkan user yang kontrol via OpenInfoFrame
	else
        RemoteScrollFrame.Visible = true
		if InfoFrameOpen then
		    mainFrame.Size = UDim2.new(0, 207 + InfoFrame.Size.X.Offset, 0, RemoteScrollFrame.Size.Y.Offset + Header.Size.Y.Offset + 5)
		else
			mainFrame.Size = UDim2.new(0, 207, 0, RemoteScrollFrame.Size.Y.Offset + Header.Size.Y.Offset + 5)
		end
	end
end)

local function FindRemote(remote, args)
    local currentId = (get_thread_context or syn.get_thread_identity)()
    local originalIdentity = currentId
    if syn and syn.set_thread_identity then -- Hanya jika Synapse
        syn.set_thread_identity(7)
    elseif get_thread_context and set_thread_context then -- Untuk exploit lain yang mendukung
        set_thread_context(7)
    end

    local foundIndex
    if table.find(unstacked, remote) then
        for b, v_remote in ipairs(remotes) do -- Menggunakan ipairs untuk array
            if v_remote == remote then
                -- Perbandingan argumen yang lebih aman
                local argsMatch = true
                if #remoteArgs[b] == #args then
                    for i_arg = 1, #args do
                        if remoteArgs[b][i_arg] ~= args[i_arg] then
                            argsMatch = false
                            break
                        end
                    end
                else
                    argsMatch = false
                end

                if argsMatch then
                    foundIndex = b
                    break
                end
            end
        end
    else
        for i, r in ipairs(remotes) do
            if r == remote then
                foundIndex = i
                break
            end
        end
    end

    if syn and syn.set_thread_identity then
        syn.set_thread_identity(originalIdentity)
    elseif get_thread_context and set_thread_context then
        set_thread_context(originalIdentity)
    end
    return foundIndex
end

local function ButtonEffect(textlabel, text, successColor)
    if not textlabel or not textlabel:IsA("TextButton") then return end -- Pemeriksaan keamanan
    
    local orgText = textlabel.Text
    local orgColor = textlabel.TextColor3
    textlabel.Text = text or "Disalin!"
    textlabel.TextColor3 = successColor or Color3.fromRGB(76, 209, 55) -- Hijau default
    
    task.delay(0.8, function()
        if textlabel and textlabel.Parent then -- Pastikan masih ada
            textlabel.Text = orgText
            textlabel.TextColor3 = orgColor
        end
    end)
end

local lookingAt
local lookingAtArgs
local lookingAtButton

CopyCode.MouseButton1Click:Connect(function()
    if not lookingAt then return end
    local codeToCopy = CodeComment.Text.. "\n\n"..Code.Text
    local success, err = pcall(setclipboard, codeToCopy)
    if success then
        ButtonEffect(CopyCode)
    else
        warn("Gagal menyalin kode:", err)
        ButtonEffect(CopyCode, "Gagal Salin!", Color3.fromRGB(230,0,0))
    end
end)

RunCode.MouseButton1Click:Connect(function()
    if lookingAt and lookingAtArgs then -- Pastikan lookingAtArgs juga ada
        local success, err
        if isA(lookingAt, "RemoteFunction") then
            success, err = pcall(function() lookingAt:InvokeServer(table.unpack(lookingAtArgs)) end)
        elseif isA(lookingAt, "RemoteEvent") then
            success, err = pcall(function() lookingAt:FireServer(table.unpack(lookingAtArgs)) end)
        end
        if not success then
            warn("Gagal mengeksekusi remote:", err)
            ButtonEffect(RunCode, "Gagal Eksekusi!", Color3.fromRGB(230,0,0))
        else
             ButtonEffect(RunCode, "Dieksekusi!", Color3.fromRGB(76, 209, 55))
        end
    end
end)

CopyScriptPath.MouseButton1Click:Connect(function()
    local remoteIndex = FindRemote(lookingAt, lookingAtArgs)
    if remoteIndex and remoteScripts[remoteIndex] then
        local scriptPath = GetFullPathOfAnInstance(remoteScripts[remoteIndex])
        local success, err = pcall(setclipboard, scriptPath)
        if success then
            ButtonEffect(CopyScriptPath)
        else
            warn("Gagal menyalin path skrip:", err)
            ButtonEffect(CopyScriptPath, "Gagal Salin!", Color3.fromRGB(230,0,0))
        end
    else
        ButtonEffect(CopyScriptPath, "Path Tidak Ada!", Color3.fromRGB(230,0,0))
    end
end)

local decompiling = false
CopyDecompiled.MouseButton1Click:Connect(function()
    local remoteIndex = FindRemote(lookingAt, lookingAtArgs)
    if not isSynapse() then -- Hanya Synapse yang mendukung decompile (biasanya)
        ButtonEffect(CopyDecompiled, "Decompile tidak didukung!", Color3.fromRGB(232, 65, 24))
        return
    end
    if not decompiling and remoteIndex and remoteScripts[remoteIndex] and lookingAt then
        decompiling = true
        local originalText = CopyDecompiled.Text
        local originalColor = CopyDecompiled.TextColor3

        task.spawn(function()
            local i = 0
            while decompiling do
                i = (i % 3) + 1
                CopyDecompiled.Text = "Mendekompilasi" .. string.rep(".", i)
                task.wait(0.5)
            end
        end)
        
        local success, result = pcall(decompile, remoteScripts[remoteIndex])
        decompiling = false -- Set setelah pcall selesai

        if success and result then
            local copySuccess, copyErr = pcall(setclipboard, result)
            if copySuccess then
                ButtonEffect(CopyDecompiled, "Dekompilasi Disalin!", Color3.fromRGB(76, 209, 55))
            else
                warn("Gagal menyalin dekompilasi:", copyErr)
                ButtonEffect(CopyDecompiled, "Gagal Salin Dekompilasi!", Color3.fromRGB(232, 65, 24))
            end
        else
            warn("Kesalahan dekompilasi:", result) -- result akan berisi pesan error dari decompile
            ButtonEffect(CopyDecompiled, "Gagal Dekompilasi!", Color3.fromRGB(232, 65, 24))
        end
        task.delay(1.6, function()
            if CopyDecompiled and CopyDecompiled.Parent then
                 CopyDecompiled.Text = originalText
                 CopyDecompiled.TextColor3 = originalColor
            end
        end)
    end
end)

BlockRemote.MouseButton1Click:Connect(function()
    if not lookingAt then return end
    local bRemoteIndex = table.find(BlockList, lookingAt)

    if not bRemoteIndex then
        table.insert(BlockList, lookingAt)
        BlockRemote.Text = "Buka blokir remote"
        BlockRemote.TextColor3 = Color3.fromRGB(251, 197, 49) -- Kuning
        if lookingAtButton and lookingAtButton.Parent then
            lookingAtButton.Parent.RemoteName.TextColor3 = Color3.fromRGB(225, 177, 44) -- Kuning lebih gelap
        end
    else
        table.remove(BlockList, bRemoteIndex)
        BlockRemote.Text = "Blokir remote agar tidak menembak"
        BlockRemote.TextColor3 = colorSettings["MainButtons"]["TextColor"]
         if lookingAtButton and lookingAtButton.Parent then
            lookingAtButton.Parent.RemoteName.TextColor3 = colorSettings["RemoteButtons"]["TextColor"]
        end
    end
end)

IgnoreRemote.MouseButton1Click:Connect(function()
    if not lookingAt then return end
    local iRemoteIndex = table.find(IgnoreList, lookingAt)
    if not iRemoteIndex then
        table.insert(IgnoreList, lookingAt)
        IgnoreRemote.Text = "Berhenti mengabaikan remote"
        IgnoreRemote.TextColor3 = Color3.fromRGB(127, 143, 166) -- Abu-abu
        if lookingAtButton and lookingAtButton.Parent then
            lookingAtButton.Parent.RemoteName.TextColor3 = Color3.fromRGB(127, 143, 166)
        end
    else
        table.remove(IgnoreList, iRemoteIndex)
        IgnoreRemote.Text = "Abaikan remote"
        IgnoreRemote.TextColor3 = colorSettings["MainButtons"]["TextColor"]
        if lookingAtButton and lookingAtButton.Parent then
            lookingAtButton.Parent.RemoteName.TextColor3 = colorSettings["RemoteButtons"]["TextColor"]
        end
    end
end)

WhileLoop.MouseButton1Click:Connect(function()
    if not lookingAt then return end
    local codeToCopy = "while task.wait() do\n   "..Code.Text.."\nend"
    local success, err = pcall(setclipboard, codeToCopy)
    if success then
        ButtonEffect(WhileLoop)
    else
        warn("Gagal menyalin while loop:", err)
        ButtonEffect(WhileLoop, "Gagal Salin!", Color3.fromRGB(230,0,0))
    end
end)

Clear.MouseButton1Click:Connect(function()
    for _, v in ipairs(RemoteScrollFrame:GetChildren()) do -- Menggunakan ipairs
        if v:IsA("TextButton") and v.Name == "RemoteButton" then -- Hanya hapus tombol remote yang relevan
            v:Destroy()
        end
    end
    for _, v_conn in ipairs(connections) do
        if typeof(v_conn) == "RBXScriptConnection" then -- Pastikan itu koneksi
             v_conn:Disconnect()
        end
    end
    -- reset semuanya
    buttonOffset = -25
    scrollSizeOffset = 287 -- Reset ke nilai awal
    remotes = {}
    remoteArgs = {}
    remoteButtons = {}
    remoteScripts = {}
    -- IgnoreList = {} -- Tidak perlu di-reset jika ingin persist antar clear, atau reset jika perlu
    -- BlockList = {} -- Sama seperti IgnoreList
    unstacked = {}
    connections = {}
    RemoteScrollFrame.CanvasSize = UDim2.new(0, 0, 0, scrollSizeOffset)

    ButtonEffect(Clear, "Log Dibersihkan!", Color3.fromRGB(76,209,55))
end)

DoNotStack.MouseButton1Click:Connect(function()
    if lookingAt then
        local isUnstackedIndex = table.find(unstacked, lookingAt)
        if isUnstackedIndex then
            table.remove(unstacked, isUnstackedIndex)
            DoNotStack.Text = "Jangan stack remote saat arg baru"
            DoNotStack.TextColor3 = colorSettings["MainButtons"]["TextColor"]
        else
            table.insert(unstacked, lookingAt)
            DoNotStack.Text = "Stack remote"
            DoNotStack.TextColor3 = Color3.fromRGB(251, 197, 49) -- Kuning
        end
    end
end)

local function tableLength(t) -- Pengganti len() yang lebih aman untuk tabel campuran
    local count = 0
    if type(t) == "table" then
        for _ in pairs(t) do
            count = count + 1
        end
    end
    return count
end

local function convertTableToString(argsTable, anies)
    anies = anies or {} -- Untuk mendeteksi rekursi tabel
    if anies[argsTable] then return "{RECURSION}" end
    anies[argsTable] = true

    local str = ""
    local first = true
    for k, v in pairs(argsTable) do
        if not first then str = str .. ", " end
        if type(k) == "string" and k:match("^[%a_][%w_]*$") then -- Identifier valid
            str = str .. k .. " = "
        else
            str = str .. "[" .. convertTableToString({k}, anies) .. "] = " -- Rekursi untuk kunci kompleks
        end

        if v == nil then
            str = str .. "nil"
        elseif typeof(v) == "Instance" then
            str = str .. GetFullPathOfAnInstance(v)
        elseif type(v) == "number" or type(v) == "function" or type(v) == "boolean" then
            str = str .. tostring(v)
        elseif type(v) == "string" then
            str = str .. string.format("%q", v) -- Menggunakan %q untuk string yang aman
        elseif type(v) == "table" then
            str = str .. "{" .. convertTableToString(v, anies) .. "}"
        elseif type(v) == "userdata" then
             str = str .. typeof(v)..": " .. tostring(v) -- Lebih informatif
        else
            str = str .. tostring(v) -- Fallback
        end
        first = false
    end
    anies[argsTable] = nil -- Hapus setelah selesai
    return str
end

CopyReturn.MouseButton1Click:Connect(function()
    local remoteIndex = FindRemote(lookingAt, lookingAtArgs)
    if lookingAt and remoteIndex and isA(lookingAt, "RemoteFunction") then
        local results
        local success, err = pcall(function()
            results = {lookingAt:InvokeServer(table.unpack(remoteArgs[remoteIndex]))}
        end)

        if success then
            local resultString = convertTableToString(results)
            local copySuccess, copyErr = pcall(setclipboard, resultString)
            if copySuccess then
                ButtonEffect(CopyReturn)
            else
                warn("Gagal menyalin return value:", copyErr)
                ButtonEffect(CopyReturn, "Gagal Salin Return!", Color3.fromRGB(230,0,0))
            end
        else
            warn("Gagal invoke remote untuk copy return:", err)
            ButtonEffect(CopyReturn, "Gagal Invoke!", Color3.fromRGB(230,0,0))
        end
    elseif not isA(lookingAt, "RemoteFunction") then
         ButtonEffect(CopyReturn, "Bukan Fungsi!", Color3.fromRGB(230,0,0))
    end
end)

RemoteScrollFrame.ChildAdded:Connect(function(child)
    if not child:IsA("TextButton") or child.Name ~= "RemoteButton" then return end -- Hanya proses tombol yang relevan

    local remote = remotes[#remotes] -- Asumsi remote terakhir yang ditambahkan
    local args = remoteArgs[#remoteArgs] -- Asumsi argumen terakhir
    
    if not remote or not args then return end -- Pemeriksaan keamanan

    local isFunction = isA(remote, "RemoteFunction")
    local fireMethod = isFunction and ":InvokeServer(" or ":FireServer("

    local connection = child.MouseButton1Click:Connect(function()
        if not remote or not remote.Parent then -- Pastikan remote masih valid
            InfoHeaderText.Text = "Info: Remote Tidak Valid"
            Code.Text = "-- Remote sudah tidak ada atau tidak valid."
            lookingAt = nil
            lookingAtArgs = nil
            lookingAtButton = nil
            return
        end

        InfoHeaderText.Text = "Info: " .. remote.Name
        if isFunction then 
            InfoButtonsScroll.CanvasSize = UDim2.new(0, 0, 0, CopyReturn.Position.Y.Offset + CopyReturn.Size.Y.Offset + 10)
            CopyReturn.Visible = true
        else
            InfoButtonsScroll.CanvasSize = UDim2.new(0, 0, 0, WhileLoop.Position.Y.Offset + WhileLoop.Size.Y.Offset + 10)
            CopyReturn.Visible = false
        end

        if not InfoFrame.Visible then
             mainFrame.Size = UDim2.new(0, 207 + InfoFrame.Size.X.Offset, 0, mainFrame.Size.Y.Offset)
             OpenInfoFrame.Text = "<"
             InfoFrame.Visible = true
             InfoFrameOpen = true
        end
        
        local codeText = GetFullPathOfAnInstance(remote) .. fireMethod .. convertTableToString(args) .. ")"
        Code.Text = codeText
        
        local textSizeVec = TextService:GetTextSize(codeText, Code.TextSize, Code.Font, Vector2.new(math.huge, Code.AbsoluteSize.Y))
        CodeFrame.CanvasSize = UDim2.new(0, textSizeVec.X + 20, 0, textSizeVec.Y + 20) -- Tambahkan padding
        
        lookingAt = remote
        lookingAtArgs = args
        lookingAtButton = child.Number

        local isBlocked = table.find(BlockList, remote)
        if isBlocked then
            BlockRemote.Text = "Buka blokir remote"
            BlockRemote.TextColor3 = Color3.fromRGB(251, 197, 49)
        else
            BlockRemote.Text = "Blokir remote agar tidak menembak"
            BlockRemote.TextColor3 = colorSettings["MainButtons"]["TextColor"]
        end

        local isIgnored = table.find(IgnoreList, remote) -- Menggunakan 'remote' bukan 'lookingAt'
        if isIgnored then
            IgnoreRemote.Text = "Berhenti mengabaikan remote"
            IgnoreRemote.TextColor3 = Color3.fromRGB(127, 143, 166)
        else
            IgnoreRemote.Text = "Abaikan remote"
            IgnoreRemote.TextColor3 = colorSettings["MainButtons"]["TextColor"]
        end
        
        local isUnstacked = table.find(unstacked, remote)
        if isUnstacked then
            DoNotStack.Text = "Stack remote"
            DoNotStack.TextColor3 = Color3.fromRGB(251, 197, 49)
        else
            DoNotStack.Text = "Jangan stack remote saat arg baru"
            DoNotStack.TextColor3 = colorSettings["MainButtons"]["TextColor"]
        end
    end)
    table.insert(connections, connection)
end)


function addToList(isEvent, remote, ...)
    local currentId = (get_thread_context or syn.get_thread_identity)()
    local originalIdentity = currentId
     if syn and syn.set_thread_identity then
        syn.set_thread_identity(7)
    elseif get_thread_context and set_thread_context then
        set_thread_context(7)
    end

    if not remote or typeof(remote) ~= "Instance" then  -- Pemeriksaan keamanan
        if syn and syn.set_thread_identity then syn.set_thread_identity(originalIdentity)
        elseif get_thread_context and set_thread_context then set_thread_context(originalIdentity) end
        return
    end

    local name = remote.Name
    local args = {...}
    local remoteIndex = FindRemote(remote, args)

    if not remoteIndex then
        table.insert(remotes, remote)
        remoteIndex = #remotes -- Dapatkan index baru

        local rButtonInstance = RemoteButton:Clone()
        remoteButtons[remoteIndex] = rButtonInstance.Number
        remoteArgs[remoteIndex] = args
        
        local callingScript
        if isSynapse() and getcallingscript then
            callingScript = getcallingscript()
        elseif rawget(_G, "getfenv") then -- Fallback untuk environment lain
            local fenv = getfenv(0)
            if fenv then callingScript = rawget(fenv, "script") end
        end
        remoteScripts[remoteIndex] = callingScript or "Tidak Diketahui"


        rButtonInstance.Parent = RemoteScrollFrame
        rButtonInstance.Visible = true
        rButtonInstance.Number.Text = "1" -- Mulai dari 1

        local numberTextSize = TextService:GetTextSize(rButtonInstance.Number.Text, rButtonInstance.Number.TextSize, rButtonInstance.Number.Font, Vector2.new(math.huge, rButtonInstance.Number.AbsoluteSize.Y))
        rButtonInstance.RemoteName.Position = UDim2.new(0, rButtonInstance.Number.AbsolutePosition.X + numberTextSize.X + 5 - rButtonInstance.AbsolutePosition.X, 0, 0)
        
        if name then
            rButtonInstance.RemoteName.Text = name
        else
            rButtonInstance.RemoteName.Text = isEvent and "RemoteEvent Tanpa Nama" or "RemoteFunction Tanpa Nama"
        end

        if not isEvent then -- Ini adalah RemoteFunction
            rButtonInstance.RemoteIcon.Image = functionImage
        else
            rButtonInstance.RemoteIcon.Image = eventImage
        end
        
        buttonOffset = buttonOffset + 35
        rButtonInstance.Position = UDim2.new(0.0912411734, 0, 0, buttonOffset)
        
        if #remotes * 35 > RemoteScrollFrame.AbsoluteSize.Y then -- Jika total tinggi tombol melebihi ukuran frame
            scrollSizeOffset = scrollSizeOffset + 35
            RemoteScrollFrame.CanvasSize = UDim2.new(0, 0, 0, scrollSizeOffset)
        end
    else
        local existingButtonNumber = remoteButtons[remoteIndex]
        if existingButtonNumber and existingButtonNumber.Parent then
            existingButtonNumber.Text = tostring(tonumber(existingButtonNumber.Text) + 1)
            
            local numberTextSize = TextService:GetTextSize(existingButtonNumber.Text, existingButtonNumber.TextSize, existingButtonNumber.Font, Vector2.new(math.huge, existingButtonNumber.AbsoluteSize.Y))
            local remoteNameLabel = existingButtonNumber.Parent.RemoteName
            remoteNameLabel.Position = UDim2.new(0, existingButtonNumber.AbsolutePosition.X + numberTextSize.X + 5 - existingButtonNumber.Parent.AbsolutePosition.X, 0, 0)
            -- remoteNameLabel.Size = UDim2.new(0, math.max(50, 149 - numberTextSize.X), 0, 26) -- Pastikan ukuran tidak negatif
        end

        remoteArgs[remoteIndex] = args -- Selalu update argumen

        if lookingAt and lookingAt == remote and lookingAtButton == remoteButtons[remoteIndex] and InfoFrame.Visible then
            local fireMethod = isA(remote, "RemoteFunction") and ":InvokeServer(" or ":FireServer("
            local codeText = GetFullPathOfAnInstance(remote) .. fireMethod .. convertTableToString(remoteArgs[remoteIndex]) .. ")"
            Code.Text = codeText
            local textSizeVec = TextService:GetTextSize(codeText, Code.TextSize, Code.Font, Vector2.new(math.huge, Code.AbsoluteSize.Y))
            CodeFrame.CanvasSize = UDim2.new(0, textSizeVec.X + 20, 0, textSizeVec.Y + 20)
        end
    end

    if syn and syn.set_thread_identity then
        syn.set_thread_identity(originalIdentity)
    elseif get_thread_context and set_thread_context then
        set_thread_context(originalIdentity)
    end
end

local OldEvent
local remoteEventProto = Instance.new("RemoteEvent") -- Buat satu prototipe
if remoteEventProto.FireServer then -- Pastikan method ada
    OldEvent = hookfunction(remoteEventProto.FireServer, function(Self, ...)
        if not checkcaller() and table.find(BlockList, Self) then
            return
        elseif table.find(IgnoreList, Self) then
            return OldEvent(Self, ...) -- Panggil yang asli
        end
        addToList(true, Self, ...)
        return OldEvent(Self, ...) -- Selalu panggil yang asli setelah logging
    end)
else
    warn("TurtleSpy: Gagal hook RemoteEvent.FireServer, method tidak ditemukan.")
end

local OldFunction
local remoteFunctionProto = Instance.new("RemoteFunction") -- Buat satu prototipe
if remoteFunctionProto.InvokeServer then -- Pastikan method ada
    OldFunction = hookfunction(remoteFunctionProto.InvokeServer, function(Self, ...)
        if not checkcaller() and table.find(BlockList, Self) then
            return -- Untuk fungsi, return nil atau error jika diblokir
        elseif table.find(IgnoreList, Self) then
            return OldFunction(Self, ...) -- Panggil yang asli
        end
        addToList(false, Self, ...)
        return OldFunction(Self, ...) -- Selalu panggil yang asli setelah logging dan return hasilnya
    end)
else
    warn("TurtleSpy: Gagal hook RemoteFunction.InvokeServer, method tidak ditemukan.")
end


local OldNamecall
OldNamecall = hookmetamethod(game,"__namecall",function(...)
    local args = {...}
    local Self = args[1]
    local currentNamecallMethod = (getnamecallmethod or get_namecall_method)() -- Simpan method saat ini

    if typeof(Self) == "Instance" then -- Hanya proses jika Self adalah Instance
        if currentNamecallMethod == "FireServer" and isA(Self, "RemoteEvent") then
            if not checkcaller() and table.find(BlockList, Self) then
                return -- Jangan panggil OldNamecall jika diblokir
            elseif table.find(IgnoreList, Self) then
                return OldNamecall(...)
            end
            pcall(addToList, true, Self, select(2, ...)) -- Panggil addToList dengan argumen yang benar
        elseif currentNamecallMethod == "InvokeServer" and isA(Self, 'RemoteFunction') then
            if not checkcaller() and table.find(BlockList, Self) then
                return -- Jangan panggil OldNamecall jika diblokir, return nil
            elseif table.find(IgnoreList, Self) then
                 return OldNamecall(...)
            end
            pcall(addToList, false, Self, select(2, ...)) -- Panggil addToList dengan argumen yang benar
        end
    end
    return OldNamecall(...)
end)

-- Inisialisasi efek glitch sekali saat GUI dimuat jika diinginkan
task.wait(1) -- Beri waktu UI untuk render
if HeaderTextLabel and HeaderTextLabel.Parent then
    triggerGlitch()
end
