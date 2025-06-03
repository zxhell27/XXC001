-- ZXHELL27 Spy V1.6.1, credits to Intrer#0421, modified by ZXHELL27
-- Disesuaikan agar lebih mirip dengan fungsionalitas dan UI source.lua

local colorSettings =
{
    ["Main"] = {
        ["HeaderColor"] = Color3.fromRGB(30, 30, 30),
        ["HeaderShadingColor"] = Color3.fromRGB(25, 25, 25), -- Kurang relevan sekarang
        ["HeaderTextColor"] = Color3.fromRGB(0, 190, 255),
        ["MainBackgroundColor"] = Color3.fromRGB(45, 45, 45),
        ["InfoScrollingFrameBgColor"] = Color3.fromRGB(40, 40, 40),
        ["ScrollBarImageColor"] = Color3.fromRGB(100, 100, 100),
        ["GridLineColor"] = Color3.fromRGB(60, 60, 60)
    },
    ["RemoteButtons"] = {
        ["BorderColor"] = Color3.fromRGB(80, 80, 80),
        ["BackgroundColor"] = Color3.fromRGB(55, 55, 55),
        ["TextColor"] = Color3.fromRGB(230, 230, 230),
        ["NumberTextColor"] = Color3.fromRGB(0, 190, 255)
    },
    ["MainButtons"] = { 
        ["BorderColor"] = Color3.fromRGB(80, 80, 80),
        ["BackgroundColor"] = Color3.fromRGB(65, 65, 65),
        ["TextColor"] = Color3.fromRGB(230, 230, 230),
        ["HoverBackgroundColor"] = Color3.fromRGB(75, 75, 75)
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

local function addStroke(element, color, thickness)
    -- Fallback jika UIStroke tidak tersedia atau untuk eksekutor lama
    element.BorderSizePixel = thickness or 1
    element.BorderColor3 = color or colorSettings.Main.GridLineColor
    --[[
    -- Jika ingin mencoba UIStroke dan eksekutor mendukung:
    if not pcall(function() return Instance.new("UIStroke") end) then
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
    --]]
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
if not isfile("ZXHELL27SpySettings.json") then
    writefile("ZXHELL27SpySettings.json", HttpService:JSONEncode(settings))
else
    local success, decodedSettings = pcall(function() return HttpService:JSONDecode(readfile("ZXHELL27SpySettings.json")) end)
    if success and decodedSettings then
        if decodedSettings["Main"] then 
            writefile("ZXHELL27SpySettings.json", HttpService:JSONEncode(settings))
        else
            settings = decodedSettings
        end
    else
        writefile("ZXHELL27SpySettings.json", HttpService:JSONEncode(settings))
    end
end

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
local function toUnicode(str) 
    local codepoints = "utf8.char("
    for _, v in utf8.codes(str) do
        codepoints = codepoints .. v .. ', '
    end
    return codepoints:sub(1, -3) .. ')'
end

local function GetFullPathOfAnInstance(instance)
    if not instance then return "nil" end 
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
        local success, serviceInstance = pcall(function() return game:GetService(instance.ClassName) end)
        
        if success and serviceInstance == instance then 
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
    
    if instance.Parent == nil then return head end -- Tambahan guard
    return GetFullPathOfAnInstance(instance.Parent) .. head
end

local isA = game.IsA
local clone = Instance.new -- Menggunakan Instance.new langsung untuk UI

local TextService = game:GetService("TextService")
local getTextSize = TextService.GetTextSize 
game.StarterGui.ResetPlayerGuiOnSpawn = false
local mouse = game.Players.LocalPlayer:GetMouse()

if game.CoreGui:FindFirstChild("ZXHELL27SpyGUI") then 
    game.CoreGui.ZXHELL27SpyGUI:Destroy()
end

-- Variabel dari source.lua
local buttonOffset = -25
local scrollSizeOffset = 287 -- Nilai awal dari source.lua
local functionImage = "http://www.roblox.com/asset/?id=413369623"
local eventImage = "http://www.roblox.com/asset/?id=413369506"

local remotes = {}
local remoteArgs = {}
local remoteButtons = {} -- Akan menyimpan referensi ke label Nomor dari tombol remote
local remoteScripts = {}
local IgnoreList = {}
local BlockList = {}
local connections = {}
local unstacked = {}

-- UI Elements (mirip source.lua)
local TurtleSpyGUI = clone("ScreenGui")
local mainFrame = clone("Frame")
local Header = clone("Frame")
local HeaderShading = clone("Frame") -- Dipertahankan dari source.lua
local HeaderTextLabel = clone("TextLabel")
local RemoteScrollFrame = clone("ScrollingFrame")

-- Template Tombol Remote (dibuat sekali, lalu di-clone)
local RemoteButton_Template = clone("TextButton")
local Number_Template = clone("TextLabel")
local RemoteName_Template = clone("TextLabel")
local RemoteIcon_Template = clone("ImageLabel")

RemoteButton_Template.Name = "RemoteButton"
RemoteButton_Template.BackgroundColor3 = colorSettings.RemoteButtons.BackgroundColor
RemoteButton_Template.BorderColor3 = colorSettings.RemoteButtons.BorderColor
RemoteButton_Template.Size = UDim2.new(0, 182, 0, 26)
RemoteButton_Template.Font = Enum.Font.SourceSans
RemoteButton_Template.Text = ""
RemoteButton_Template.TextColor3 = colorSettings.RemoteButtons.TextColor
RemoteButton_Template.TextSize = 18.000
RemoteButton_Template.TextXAlignment = Enum.TextXAlignment.Left
addStroke(RemoteButton_Template, colorSettings.RemoteButtons.BorderColor, 1)

Number_Template.Name = "Number"
Number_Template.Parent = RemoteButton_Template
Number_Template.BackgroundTransparency = 1.000
Number_Template.Position = UDim2.new(0, 5, 0, 0)
Number_Template.Size = UDim2.new(0, 30, 0, 26) -- Ukuran awal, akan disesuaikan
Number_Template.ZIndex = 2
Number_Template.Font = Enum.Font.SourceSans
Number_Template.Text = "1"
Number_Template.TextColor3 = colorSettings.RemoteButtons.NumberTextColor
Number_Template.TextSize = 16.000
Number_Template.TextXAlignment = Enum.TextXAlignment.Left

RemoteName_Template.Name = "RemoteName"
RemoteName_Template.Parent = RemoteButton_Template
RemoteName_Template.BackgroundTransparency = 1.000
RemoteName_Template.Position = UDim2.new(0, 20, 0, 0) -- Ukuran awal, akan disesuaikan
RemoteName_Template.Size = UDim2.new(0, 134, 0, 26)
RemoteName_Template.Font = Enum.Font.SourceSans
RemoteName_Template.Text = "RemoteEvent"
RemoteName_Template.TextColor3 = colorSettings.RemoteButtons.TextColor
RemoteName_Template.TextSize = 16.000
RemoteName_Template.TextXAlignment = Enum.TextXAlignment.Left
RemoteName_Template.TextTruncate = Enum.TextTruncate.AtEnd -- Di source.lua adalah 1, ini ekuivalennya

RemoteIcon_Template.Name = "RemoteIcon"
RemoteIcon_Template.Parent = RemoteButton_Template
RemoteIcon_Template.BackgroundTransparency = 1.000
RemoteIcon_Template.Position = UDim2.new(0.840260386, 0, 0.0225472748, 0)
RemoteIcon_Template.Size = UDim2.new(0, 24, 0, 24)
RemoteIcon_Template.Image = eventImage -- Default

-- Sisa UI Elements (InfoFrame, dll.)
local InfoFrame = clone("Frame")
local InfoFrameHeader = clone("Frame")
local InfoTitleShading = clone("Frame") -- Dipertahankan
local CodeFrame = clone("ScrollingFrame")
local Code = clone("TextLabel") -- Nama dari source.lua
local CodeComment = clone("TextLabel") -- Nama dari source.lua
local InfoHeaderText = clone("TextLabel")
local InfoButtonsScroll = clone("ScrollingFrame")

-- Tombol-tombol di InfoButtonsScroll (dibuat seperti di source.lua)
local CopyCode = clone("TextButton")
local RunCode = clone("TextButton")
local CopyScriptPath = clone("TextButton")
local CopyDecompiled = clone("TextButton")
local IgnoreRemote = clone("TextButton")
local BlockRemote = clone("TextButton")
local WhileLoop = clone("TextButton")
local Clear = clone("TextButton")
local CopyReturn = clone("TextButton")
local DoNotStack = clone("TextButton")

local FrameDivider = clone("Frame")
local CloseInfoFrame = clone("TextButton")
local OpenInfoFrame = clone("TextButton")
local Minimize = clone("TextButton")
local ImageButton = clone("ImageButton") -- Tombol browser remote

-- Remote browser UI (disederhanakan, mirip source.lua)
local BrowserHeader = clone("Frame")
local BrowserHeaderFrame = clone("Frame") -- Dipertahankan
local BrowserHeaderText = clone("TextLabel")
local CloseInfoFrame2 = clone("TextButton") -- Tombol close browser
local RemoteBrowserFrame = clone("ScrollingFrame")
-- Template untuk browser, dibuat sekali
local RemoteButton2_Template = clone("TextButton")
local RemoteName2_Template = clone("TextLabel")
local RemoteIcon2_Template = clone("ImageLabel")

RemoteButton2_Template.Name = "RemoteButton" -- Nama dari source.lua
RemoteButton2_Template.BackgroundColor3 = colorSettings.RemoteButtons.BackgroundColor
RemoteButton2_Template.BorderColor3 = colorSettings.RemoteButtons.BorderColor
RemoteButton2_Template.Size = UDim2.new(0, 182, 0, 26)
RemoteButton2_Template.Font = Enum.Font.SourceSans
RemoteButton2_Template.Text = ""
addStroke(RemoteButton2_Template, colorSettings.RemoteButtons.BorderColor, 1)

RemoteName2_Template.Name = "RemoteName2"
RemoteName2_Template.Parent = RemoteButton2_Template
RemoteName2_Template.BackgroundTransparency = 1.000
RemoteName2_Template.Position = UDim2.new(0, 5, 0, 0)
RemoteName2_Template.Size = UDim2.new(0, 155, 0, 26)
RemoteName2_Template.Font = Enum.Font.SourceSans
RemoteName2_Template.Text = "RemoteEventName"
RemoteName2_Template.TextColor3 = colorSettings.RemoteButtons.TextColor
RemoteName2_Template.TextSize = 16.000
RemoteName2_Template.TextXAlignment = Enum.TextXAlignment.Left
RemoteName2_Template.TextTruncate = Enum.TextTruncate.AtEnd

RemoteIcon2_Template.Name = "RemoteIcon2"
RemoteIcon2_Template.Parent = RemoteButton2_Template
RemoteIcon2_Template.BackgroundTransparency = 1.000
RemoteIcon2_Template.Position = UDim2.new(0.840260386, 0, 0.0225472748, 0)
RemoteIcon2_Template.Size = UDim2.new(0, 24, 0, 24)
RemoteIcon2_Template.Image = functionImage


TurtleSpyGUI.Name = "ZXHELL27SpyGUI"
Parent(TurtleSpyGUI)

mainFrame.Name = "mainFrame"
mainFrame.Parent = TurtleSpyGUI
mainFrame.BackgroundColor3 = colorSettings.Main.MainBackgroundColor -- Menggunakan skema warna baru
mainFrame.BorderColor3 = colorSettings.Main.GridLineColor
mainFrame.Position = UDim2.new(0.100000001, 0, 0.239999995, 0)
mainFrame.Size = UDim2.new(0, 207, 0, 35)
mainFrame.ZIndex = 8
mainFrame.Active = true
mainFrame.Draggable = true
addStroke(mainFrame, colorSettings.Main.GridLineColor, 1)


-- Properti Header dari source.lua
Header.Name = "Header"
Header.Parent = mainFrame
Header.BackgroundColor3 = colorSettings.Main.HeaderColor
Header.BorderColor3 = colorSettings.Main.HeaderColor -- Tidak ada stroke di source.lua untuk ini
Header.Size = UDim2.new(0, 207, 0, 26)
Header.ZIndex = 9

HeaderShading.Name = "HeaderShading"
HeaderShading.Parent = Header
HeaderShading.BackgroundColor3 = colorSettings.Main.HeaderShadingColor -- Warna shading dari source (disesuaikan)
HeaderShading.BorderColor3 = colorSettings.Main.HeaderShadingColor
HeaderShading.Position = UDim2.new(1.46719131e-07, 0, 0.285714358, 0)
HeaderShading.Size = UDim2.new(0, 207, 0, 27)
HeaderShading.ZIndex = 8

HeaderTextLabel.Name = "HeaderTextLabel"
HeaderTextLabel.Parent = HeaderShading -- Di source.lua, parentnya HeaderShading
HeaderTextLabel.BackgroundTransparency = 1.000
HeaderTextLabel.Position = UDim2.new(-0.00507604145, 0, -0.202857122, 0)
HeaderTextLabel.Size = UDim2.new(0, 215, 0, 29)
HeaderTextLabel.ZIndex = 10
HeaderTextLabel.Font = Enum.Font.SourceSans
HeaderTextLabel.Text = "ZXHELL27 Spy" -- Nama diubah
HeaderTextLabel.TextColor3 = colorSettings.Main.HeaderTextColor
HeaderTextLabel.TextSize = 17.000

-- Properti RemoteScrollFrame dari source.lua
RemoteScrollFrame.Name = "RemoteScrollFrame"
RemoteScrollFrame.Parent = mainFrame
RemoteScrollFrame.Active = true
RemoteScrollFrame.BackgroundColor3 = colorSettings.Main.InfoScrollingFrameBgColor
RemoteScrollFrame.BorderColor3 = colorSettings.Main.InfoScrollingFrameBgColor
RemoteScrollFrame.Position = UDim2.new(0, 0, 1.02292562, 0)
RemoteScrollFrame.Size = UDim2.new(0, 207, 0, 286)
RemoteScrollFrame.CanvasSize = UDim2.new(0, 0, 0, scrollSizeOffset) -- Menggunakan variabel
RemoteScrollFrame.ScrollBarThickness = 8
RemoteScrollFrame.VerticalScrollBarPosition = Enum.VerticalScrollBarPosition.Left
RemoteScrollFrame.ScrollBarImageColor3 = colorSettings.Main.ScrollBarImageColor
addStroke(RemoteScrollFrame, colorSettings.Main.GridLineColor, 1)


-- Properti InfoFrame dari source.lua
InfoFrame.Name = "InfoFrame"
InfoFrame.Parent = mainFrame
InfoFrame.BackgroundColor3 = colorSettings.Main.MainBackgroundColor
InfoFrame.BorderColor3 = colorSettings.Main.MainBackgroundColor
InfoFrame.Position = UDim2.new(1.00966184, 0, -5.58035717e-05, 0) -- Disesuaikan agar pas di kanan
InfoFrame.Size = UDim2.new(0, 357, 0, 322)
InfoFrame.Visible = false
InfoFrame.ZIndex = 6
addStroke(InfoFrame, colorSettings.Main.GridLineColor, 1)

InfoFrameHeader.Name = "InfoFrameHeader"
InfoFrameHeader.Parent = InfoFrame
InfoFrameHeader.BackgroundColor3 = colorSettings.Main.HeaderColor
InfoFrameHeader.BorderColor3 = colorSettings.Main.HeaderColor
InfoFrameHeader.Size = UDim2.new(0, 357, 0, 26)
InfoFrameHeader.ZIndex = 14

InfoTitleShading.Name = "InfoTitleShading"
InfoTitleShading.Parent = InfoFrameHeader -- Di source.lua, parentnya InfoFrame, tapi lebih logis di Header
InfoTitleShading.BackgroundColor3 = colorSettings.Main.HeaderShadingColor
InfoTitleShading.BorderColor3 = colorSettings.Main.HeaderShadingColor
InfoTitleShading.Position = UDim2.new(0,0,0.28,0) -- Disesuaikan agar di bawah teks header
InfoTitleShading.Size = UDim2.new(1, 0, 1, 0) -- Menutupi sisa header
InfoTitleShading.ZIndex = 13


InfoHeaderText.Name = "InfoHeaderText"
InfoHeaderText.Parent = InfoFrameHeader -- Di atas shading
InfoHeaderText.BackgroundTransparency = 1.000
InfoHeaderText.Position = UDim2.new(0.0391303934, 0, 0, 0)
InfoHeaderText.Size = UDim2.new(0.85, 0, 1, 0) -- Agar tidak tertutup tombol close
InfoHeaderText.ZIndex = 18
InfoHeaderText.Font = Enum.Font.SourceSans
InfoHeaderText.Text = "Info: RemoteFunction"
InfoHeaderText.TextColor3 = colorSettings.Main.HeaderTextColor
InfoHeaderText.TextSize = 17.000


CodeFrame.Name = "CodeFrame"
CodeFrame.Parent = InfoFrame
CodeFrame.Active = true
CodeFrame.BackgroundColor3 = colorSettings.Code.BackgroundColor
CodeFrame.BorderColor3 = colorSettings.Code.BackgroundColor
CodeFrame.Position = UDim2.new(0.0391303748, 0, 0.141156405, 0)
CodeFrame.Size = UDim2.new(0, 329, 0, 63)
CodeFrame.ZIndex = 16
CodeFrame.CanvasSize = UDim2.new(0, 670, 2, 0) -- Ukuran dari source
CodeFrame.ScrollBarThickness = 8
CodeFrame.ScrollingDirection = Enum.ScrollingDirection.XY -- source.lua menggunakan 1 (Horizontal)
CodeFrame.ScrollBarImageColor3 = colorSettings.Main.ScrollBarImageColor
addStroke(CodeFrame, colorSettings.Main.GridLineColor,1)

CodeComment.Name = "CodeComment"
CodeComment.Parent = CodeFrame
CodeComment.BackgroundTransparency = 1.000
CodeComment.Position = UDim2.new(0.0119285434, 0, 0.05, 0) -- Disesuaikan sedikit padding
CodeComment.Size = UDim2.new(0, 1000, 0, 25) -- Lebar besar untuk scroll
CodeComment.ZIndex = 18
CodeComment.Font = Enum.Font.SourceSansItalic
CodeComment.Text = "-- Script generated by ZXHELL27 Spy"
CodeComment.TextColor3 = colorSettings.Code.CreditsColor
CodeComment.TextSize = 14.000
CodeComment.TextXAlignment = Enum.TextXAlignment.Left

Code.Name = "Code"
Code.Parent = CodeFrame
Code.BackgroundTransparency = 1.000
Code.Position = UDim2.new(0.00888902973, 0, 0, 30) -- Di bawah comment
Code.Size = UDim2.new(0, 100000, 0, 25) -- Lebar sangat besar
Code.ZIndex = 18
Code.Font = Enum.Font.Code -- Font Code
Code.Text = "Thanks for using ZXHELL27 Spy! :D"
Code.TextColor3 = colorSettings.Code.TextColor
Code.TextSize = 14.000
Code.TextWrapped = false -- Agar bisa scroll horizontal
Code.TextXAlignment = Enum.TextXAlignment.Left
Code.TextYAlignment = Enum.TextYAlignment.Top


InfoButtonsScroll.Name = "InfoButtonsScroll"
InfoButtonsScroll.Parent = InfoFrame
InfoButtonsScroll.Active = true
InfoButtonsScroll.BackgroundColor3 = colorSettings.Main.InfoScrollingFrameBgColor
InfoButtonsScroll.BorderColor3 = colorSettings.Main.InfoScrollingFrameBgColor
InfoButtonsScroll.Position = UDim2.new(0.0391303748, 0, 0.355857909, 0)
InfoButtonsScroll.Size = UDim2.new(0, 329, 0, 199)
InfoButtonsScroll.ZIndex = 11
InfoButtonsScroll.CanvasSize = UDim2.new(0, 0, 1, 0) -- Disesuaikan dengan jumlah tombol
InfoButtonsScroll.ScrollBarThickness = 8
InfoButtonsScroll.VerticalScrollBarPosition = Enum.VerticalScrollBarPosition.Left
InfoButtonsScroll.ScrollBarImageColor3 = colorSettings.Main.ScrollBarImageColor
addStroke(InfoButtonsScroll, colorSettings.Main.GridLineColor, 1)

-- Helper untuk membuat tombol di InfoButtonsScroll
local function createInfoButton(name, text, yOffset)
    local button = clone("TextButton")
    button.Name = name
    button.Parent = InfoButtonsScroll
    button.BackgroundColor3 = colorSettings.MainButtons.BackgroundColor
    button.BorderColor3 = colorSettings.MainButtons.BorderColor
    button.Position = UDim2.new(0.0645, 0, 0, yOffset)
    button.Size = UDim2.new(0, 294, 0, 26)
    button.ZIndex = 15
    button.Font = Enum.Font.SourceSans
    button.Text = text
    button.TextColor3 = colorSettings.MainButtons.TextColor
    button.TextSize = 16.000
    addStroke(button, colorSettings.MainButtons.BorderColor, 1)
    
    button.MouseEnter:Connect(function() button.BackgroundColor3 = colorSettings.MainButtons.HoverBackgroundColor end)
    button.MouseLeave:Connect(function() button.BackgroundColor3 = colorSettings.MainButtons.BackgroundColor end)
    return button
end

CopyCode = createInfoButton("CopyCode", "Copy code", 10)
RunCode = createInfoButton("RunCode", "Execute", 45)
CopyScriptPath = createInfoButton("CopyScriptPath", "Copy script path", 80)
CopyDecompiled = createInfoButton("CopyDecompiled", "Copy decompiled script", 115)
DoNotStack = createInfoButton("DoNotStack", "Unstack remote (New Args)", 150) -- Teks disesuaikan
IgnoreRemote = createInfoButton("IgnoreRemote", "Ignore remote", 185)
BlockRemote = createInfoButton("BlockRemote", "Block remote from firing", 220)
Clear = createInfoButton("Clear", "Clear logs", 255)
WhileLoop = createInfoButton("WhileLoop", "Generate while loop script", 290)
CopyReturn = createInfoButton("CopyReturn", "Execute and copy return value", 325)
CopyReturn.Visible = false -- Sembunyikan awalnya, hanya untuk RemoteFunction

-- Update CanvasSize InfoButtonsScroll
local totalButtonHeight = 325 + 26 + 10 -- Posisi Y tombol terakhir + tinggi + padding
InfoButtonsScroll.CanvasSize = UDim2.new(0,0,0, totalButtonHeight)


FrameDivider.Name = "FrameDivider"
FrameDivider.Parent = InfoFrame
FrameDivider.BackgroundColor3 = colorSettings.Main.GridLineColor -- Warna dari source (disesuaikan)
FrameDivider.BorderColor3 = colorSettings.Main.GridLineColor
FrameDivider.Position = UDim2.new(0, 0, 0, 0) -- Di paling kiri InfoFrame
FrameDivider.Size = UDim2.new(0, 4, 1, 0) -- Tinggi penuh
FrameDivider.ZIndex = 7


local InfoFrameOpen = false
CloseInfoFrame.Name = "CloseInfoFrame"
CloseInfoFrame.Parent = InfoFrameHeader -- Di header InfoFrame
CloseInfoFrame.BackgroundColor3 = colorSettings.Main.HeaderColor
CloseInfoFrame.BorderColor3 = colorSettings.Main.HeaderColor
CloseInfoFrame.Position = UDim2.new(0.92, 0, 0.1, 0) -- Disesuaikan agar di kanan
CloseInfoFrame.Size = UDim2.new(0, 22, 0, 22)
CloseInfoFrame.ZIndex = 18
CloseInfoFrame.Font = Enum.Font.SourceSansLight
CloseInfoFrame.Text = "X"
CloseInfoFrame.TextColor3 = colorSettings.Main.HeaderTextColor
CloseInfoFrame.TextSize = 20.000
CloseInfoFrame.MouseButton1Click:Connect(function()
    InfoFrame.Visible = false
    InfoFrameOpen = false
    mainFrame.Size = UDim2.new(0, 207, 0, mainFrame.Size.Y.Offset) -- Kembalikan ukuran mainFrame
    OpenInfoFrame.Text = ">"
end)

OpenInfoFrame.Name = "OpenInfoFrame"
OpenInfoFrame.Parent = Header -- Di header utama
OpenInfoFrame.BackgroundColor3 = colorSettings.Main.HeaderColor
OpenInfoFrame.BorderColor3 = colorSettings.Main.HeaderColor
OpenInfoFrame.Position = UDim2.new(0, 185, 0, 2)
OpenInfoFrame.Size = UDim2.new(0, 22, 0, 22)
OpenInfoFrame.ZIndex = 18
OpenInfoFrame.Font = Enum.Font.SourceSansBold -- Font lebih tebal
OpenInfoFrame.Text = ">"
OpenInfoFrame.TextColor3 = colorSettings.Main.HeaderTextColor
OpenInfoFrame.TextSize = 16.000
OpenInfoFrame.MouseButton1Click:Connect(function()
	if not InfoFrame.Visible then
		mainFrame.Size = UDim2.new(0, 207 + InfoFrame.Size.X.Offset + 4, 0, mainFrame.Size.Y.Offset) -- Lebar ditambah InfoFrame
		OpenInfoFrame.Text = "<"
	else
		mainFrame.Size = UDim2.new(0, 207, 0, mainFrame.Size.Y.Offset)
		OpenInfoFrame.Text = ">"
	end
	InfoFrame.Visible = not InfoFrame.Visible
	InfoFrameOpen = InfoFrame.Visible
end)

Minimize.Name = "Minimize"
Minimize.Parent = Header -- Di header utama
Minimize.BackgroundColor3 = colorSettings.Main.HeaderColor
Minimize.BorderColor3 = colorSettings.Main.HeaderColor
Minimize.Position = UDim2.new(0, 160, 0, 2) -- Sedikit ke kiri dari OpenInfoFrame
Minimize.Size = UDim2.new(0, 22, 0, 22)
Minimize.ZIndex = 18
Minimize.Font = Enum.Font.SourceSansBold
Minimize.Text = "_"
Minimize.TextColor3 = colorSettings.Main.HeaderTextColor
Minimize.TextSize = 16.000
Minimize.MouseButton1Click:Connect(function()
	local currentMainFrameHeight = mainFrame.AbsoluteSize.Y
    local headerHeightOnly = Header.AbsoluteSize.Y

	if RemoteScrollFrame.Visible then -- Jika terbuka, minimalkan
		mainFrame.Size = UDim2.new(0, mainFrame.Size.X.Offset, 0, headerHeightOnly)
		RemoteScrollFrame.Visible = false
		if InfoFrameOpen then InfoFrame.Visible = false end 
        OpenInfoFrame.Text = ">" 
	else -- Jika terminimalisir, buka ke tinggi sebelumnya atau default
        local targetHeight = (currentMainFrameHeight <= headerHeightOnly + 5) and (headerHeightOnly + RemoteScrollFrame.Size.Y.Offset + 5) or currentMainFrameHeight
		mainFrame.Size = UDim2.new(0, mainFrame.Size.X.Offset, 0, targetHeight)
		RemoteScrollFrame.Visible = true
		if InfoFrameOpen then 
            InfoFrame.Visible = true 
            OpenInfoFrame.Text = "<"
        end
	end
end)

-- Remote Browser (Mirip source.lua)
BrowserHeader.Name = "BrowserHeader"
BrowserHeader.Parent = TurtleSpyGUI
BrowserHeader.BackgroundColor3 = colorSettings.Main.HeaderShadingColor -- Sesuai source.lua
BrowserHeader.BorderColor3 = colorSettings.Main.HeaderShadingColor
BrowserHeader.Position = UDim2.new(0.712152421, 0, 0.339464903, 0)
BrowserHeader.Size = UDim2.new(0, 207, 0, 33)
BrowserHeader.ZIndex = 20
BrowserHeader.Active = true
BrowserHeader.Draggable = true
BrowserHeader.Visible = false
addStroke(BrowserHeader, colorSettings.Main.GridLineColor, 1)


BrowserHeaderFrame.Name = "BrowserHeaderFrame"
BrowserHeaderFrame.Parent = BrowserHeader
BrowserHeaderFrame.BackgroundColor3 = colorSettings.Main.HeaderColor
BrowserHeaderFrame.BorderColor3 = colorSettings.Main.HeaderColor
BrowserHeaderFrame.Position = UDim2.new(0, 0, -0.0202544238, 0)
BrowserHeaderFrame.Size = UDim2.new(0, 207, 0, 26)
BrowserHeaderFrame.ZIndex = 21

BrowserHeaderText.Name = "BrowserHeaderText" -- Dulu InfoHeaderText
BrowserHeaderText.Parent = BrowserHeaderFrame
BrowserHeaderText.BackgroundTransparency = 1.000
BrowserHeaderText.Position = UDim2.new(0, 0, -0.00206991332, 0)
BrowserHeaderText.Size = UDim2.new(0, 206, 0, 33)
BrowserHeaderText.ZIndex = 22
BrowserHeaderText.Font = Enum.Font.SourceSans
BrowserHeaderText.Text = "Remote Browser"
BrowserHeaderText.TextColor3 = colorSettings.Main.HeaderTextColor
BrowserHeaderText.TextSize = 17.000

CloseInfoFrame2.Name = "CloseInfoFrame2" -- Nama dari source.lua
CloseInfoFrame2.Parent = BrowserHeaderFrame
CloseInfoFrame2.BackgroundColor3 = colorSettings.Main.HeaderColor
CloseInfoFrame2.BorderColor3 = colorSettings.Main.HeaderColor
CloseInfoFrame2.Position = UDim2.new(0, 185, 0, 2)
CloseInfoFrame2.Size = UDim2.new(0, 22, 0, 22)
CloseInfoFrame2.ZIndex = 38
CloseInfoFrame2.Font = Enum.Font.SourceSansLight
CloseInfoFrame2.Text = "X"
CloseInfoFrame2.TextColor3 = colorSettings.Main.HeaderTextColor -- Disesuaikan
CloseInfoFrame2.TextSize = 20.000
CloseInfoFrame2.MouseButton1Click:Connect(function()
    BrowserHeader.Visible = not BrowserHeader.Visible
end)

RemoteBrowserFrame.Name = "RemoteBrowserFrame"
RemoteBrowserFrame.Parent = BrowserHeader
RemoteBrowserFrame.Active = true
RemoteBrowserFrame.BackgroundColor3 = colorSettings.Main.InfoScrollingFrameBgColor
RemoteBrowserFrame.BorderColor3 = colorSettings.Main.InfoScrollingFrameBgColor
RemoteBrowserFrame.Position = UDim2.new(-0.004540205, 0, 1.03504682, 0)
RemoteBrowserFrame.Size = UDim2.new(0, 207, 0, 286)
RemoteBrowserFrame.ZIndex = 19
RemoteBrowserFrame.CanvasSize = UDim2.new(0, 0, 0, 287) -- Nilai awal
RemoteBrowserFrame.ScrollBarThickness = 8
RemoteBrowserFrame.VerticalScrollBarPosition = Enum.VerticalScrollBarPosition.Left
RemoteBrowserFrame.ScrollBarImageColor3 = colorSettings.Main.ScrollBarImageColor
addStroke(RemoteBrowserFrame, colorSettings.Main.GridLineColor, 1)

local browsedRemotes = {} -- Tabel dari source.lua
local browsedConnections = {} -- Tabel dari source.lua
local browsedButtonOffset = 10 -- Variabel dari source.lua
local browserCanvasSize = 286 -- Variabel dari source.lua

ImageButton.Name = "ImageButton" -- Tombol untuk membuka browser
ImageButton.Parent = Header
ImageButton.BackgroundTransparency = 1.000
ImageButton.Position = UDim2.new(0.05, 0, 0.15, 0) -- Disesuaikan posisinya
ImageButton.Size = UDim2.new(0, 20, 0, 20)
ImageButton.ZIndex = 9
ImageButton.Image = "rbxassetid://169476802"
ImageButton.ImageColor3 = colorSettings.Main.HeaderTextColor
ImageButton.MouseButton1Click:Connect(function()
    BrowserHeader.Visible = not BrowserHeader.Visible
    if BrowserHeader.Visible then
        -- Bersihkan list lama
        for _, btn in pairs(browsedRemotes) do btn:Destroy() end
        for _, conn in pairs(browsedConnections) do conn:Disconnect() end
        browsedRemotes = {}
        browsedConnections = {}
        browsedButtonOffset = 10
        browserCanvasSize = 286
        RemoteBrowserFrame.CanvasSize = UDim2.new(0,0,0,browserCanvasSize)

        for i, v in pairs(game:GetDescendants()) do
            if isA(v, "RemoteEvent") or isA(v, "RemoteFunction") then
                local bButton = RemoteButton2_Template:Clone()
                bButton.Parent = RemoteBrowserFrame
                bButton.Visible = true
                bButton.Position = UDim2.new(0, 17, 0, browsedButtonOffset)
                
                bButton.RemoteName2.Text = v.Name
                local fireFunctionText = ""
                if isA(v, "RemoteEvent") then
                    fireFunctionText = ":FireServer()"
                    bButton.RemoteIcon2.Image = eventImage
                else
                    fireFunctionText = ":InvokeServer()"
                    bButton.RemoteIcon2.Image = functionImage
                end

                local connection = bButton.MouseButton1Click:Connect(function()
                    setclipboard(GetFullPathOfAnInstance(v) .. fireFunctionText)
                     -- Efek visual singkat
                    local originalColor = bButton.BackgroundColor3
                    bButton.BackgroundColor3 = colorSettings.MainButtons.HoverBackgroundColor
                    task.wait(0.2)
                    bButton.BackgroundColor3 = originalColor
                end)
                table.insert(browsedRemotes, bButton)
                table.insert(browsedConnections, connection)
                browsedButtonOffset = browsedButtonOffset + 35

                if #browsedConnections > 7 then -- Source.lua menggunakan 8, tapi karena offset awal 10, ini jadi 7
                    browserCanvasSize = browserCanvasSize + 35
                    RemoteBrowserFrame.CanvasSize = UDim2.new(0, 0, 0, browserCanvasSize)
                end
            end
        end
    end
end)


mouse.KeyDown:Connect(function(key)
    if key:lower() == settings["Keybind"]:lower() then
        TurtleSpyGUI.Enabled = not TurtleSpyGUI.Enabled
    end
end)

-- Fungsi FindRemote dari source.lua
local function FindRemote(remote, args)
    local currentId = (get_thread_context or syn.get_thread_identity)()
    ;(set_thread_context or syn.set_thread_identity)(7)
    local i
    if table.find(unstacked, remote) then
        local numOfRemotes = 0
        for b, v_remote in pairs(remotes) do -- Ubah v menjadi v_remote
            if v_remote == remote then
                numOfRemotes = numOfRemotes + 1
                -- Perbandingan argumen yang lebih aman
                local currentArgs = remoteArgs[b]
                local match = true
                if #currentArgs ~= #args then
                    match = false
                else
                    for i2 = 1, #args do
                        if currentArgs[i2] ~= args[i2] then
                            match = false
                            break
                        end
                    end
                end
                if match then
                    i = b
                    break -- Ditemukan, keluar dari loop
                end
            end
        end
    else
        i = table.find(remotes, remote)
    end
    ;(set_thread_context or syn.set_thread_identity)(currentId)
    return i
end


local function ButtonFeedback(button, text, success) -- Tambahkan parameter success
    local originalText = button.Text
    local originalColor = button.TextColor3
    button.Text = text or "Copied!"
    button.TextColor3 = success and Color3.fromRGB(76, 209, 55) or Color3.fromRGB(232, 65, 24) -- Hijau atau Merah
    task.delay(0.8, function() 
        if button and button.Parent then 
            button.Text = originalText
            button.TextColor3 = originalColor
        end
    end)
end

local lookingAt = nil -- Menyimpan instance remote yang dilihat
local lookingAtArgs = nil -- Menyimpan argumen dari remote yang dilihat
local lookingAtButton = nil -- Menyimpan referensi ke Number label dari tombol yang dilihat

CopyCode.MouseButton1Click:Connect(function()
    if not lookingAt then return end
    setclipboard(CodeComment.Text.. "\n\n"..Code.Text)
    ButtonFeedback(CopyCode, "Copied!", true)
end)

RunCode.MouseButton1Click:Connect(function()
    if lookingAt then
        local success, err = pcall(function()
            if isA(lookingAt, "RemoteFunction") then
                lookingAt:InvokeServer(unpack(lookingAtArgs))
            elseif isA(lookingAt, "RemoteEvent") then
                lookingAt:FireServer(unpack(lookingAtArgs))
            end
        end)
        ButtonFeedback(RunCode, success and "Executed!" or "Error!", success)
        if not success then warn("ZXHELL27 Spy - Execute Error:", err) end
    end
end)

CopyScriptPath.MouseButton1Click:Connect(function()
    local remoteIndex = FindRemote(lookingAt, lookingAtArgs) -- Menggunakan remoteIndex
    if remoteIndex and lookingAt and remoteScripts[remoteIndex] then
        setclipboard(GetFullPathOfAnInstance(remoteScripts[remoteIndex]))
        ButtonFeedback(CopyScriptPath, "Path Copied!", true)
    else
        ButtonFeedback(CopyScriptPath, "No Script!", false)
    end
end)

local decompiling = false
CopyDecompiled.MouseButton1Click:Connect(function()
    local remoteIndex = FindRemote(lookingAt, lookingAtArgs)
    if not remoteIndex or not lookingAt or not remoteScripts[remoteIndex] then
        ButtonFeedback(CopyDecompiled, "No Script!", false)
        return
    end

    if not isSynapse() then
        ButtonFeedback(CopyDecompiled, "No Decompiler!", false)
        return
    end

    if not decompiling then
        decompiling = true
        local originalText = CopyDecompiled.Text
        local animationThread = task.spawn(function()
            while decompiling do
                if not CopyDecompiled or not CopyDecompiled.Parent then break end
                CopyDecompiled.Text = "Decompiling."
                task.wait(0.5)
                if not decompiling then break end
                CopyDecompiled.Text = "Decompiling.."
                task.wait(0.5)
                if not decompiling then break end
                CopyDecompiled.Text = "Decompiling..."
                task.wait(0.5)
            end
        end)

        local success, result = pcall(decompile, remoteScripts[remoteIndex])
        decompiling = false
        if animationThread then task.cancel(animationThread) end

        if CopyDecompiled and CopyDecompiled.Parent then
            if success then
                setclipboard(result)
                ButtonFeedback(CopyDecompiled, "Decompiled!", true)
            else
                warn("ZXHELL27 Spy - Decompilation Error:", result)
                ButtonFeedback(CopyDecompiled, "Error!", false)
            end
            task.delay(1.6, function()
                if CopyDecompiled and CopyDecompiled.Parent then
                    CopyDecompiled.Text = originalText
                    CopyDecompiled.TextColor3 = colorSettings.MainButtons.TextColor
                end
            end)
        end
    end
end)

BlockRemote.MouseButton1Click:Connect(function()
    if not lookingAt then return end
    local bRemoteIndexInList = table.find(BlockList, lookingAt)

    if not bRemoteIndexInList then
        table.insert(BlockList, lookingAt)
        BlockRemote.Text = "Unblock Remote"
        BlockRemote.TextColor3 = Color3.fromRGB(251, 197, 49)
        if lookingAtButton and lookingAtButton.Parent then lookingAtButton.Parent.RemoteName.TextColor3 = Color3.fromRGB(225, 177, 44) end
    else
        table.remove(BlockList, bRemoteIndexInList)
        BlockRemote.Text = "Block remote from firing"
        BlockRemote.TextColor3 = colorSettings.MainButtons.TextColor
        if lookingAtButton and lookingAtButton.Parent then lookingAtButton.Parent.RemoteName.TextColor3 = colorSettings.RemoteButtons.TextColor end
    end
end)

IgnoreRemote.MouseButton1Click:Connect(function()
    if not lookingAt then return end
    local iRemoteIndexInList = table.find(IgnoreList, lookingAt)
    if not iRemoteIndexInList then
        table.insert(IgnoreList, lookingAt)
        IgnoreRemote.Text = "Stop Ignoring"
        IgnoreRemote.TextColor3 = Color3.fromRGB(127, 143, 166)
        if lookingAtButton and lookingAtButton.Parent then lookingAtButton.Parent.RemoteName.TextColor3 = Color3.fromRGB(127, 143, 166) end
    else
        table.remove(IgnoreList, iRemoteIndexInList)
        IgnoreRemote.Text = "Ignore remote"
        IgnoreRemote.TextColor3 = colorSettings.MainButtons.TextColor
        if lookingAtButton and lookingAtButton.Parent then lookingAtButton.Parent.RemoteName.TextColor3 = colorSettings.RemoteButtons.TextColor end
    end
end)

WhileLoop.MouseButton1Click:Connect(function()
    if not lookingAt then return end
    setclipboard("while task.wait() do\n   "..Code.Text.."\nend")
    ButtonFeedback(WhileLoop, "Loop Copied!", true)
end)

Clear.MouseButton1Click:Connect(function()
    for _, child in pairs(RemoteScrollFrame:GetChildren()) do
        if child:IsA("TextButton") and child.Name == "RemoteButton" then -- Hanya hapus tombol remote yang di-clone
            local remoteIndex = nil
            for i, btnLabel in pairs(remoteButtons) do
                if btnLabel.Parent == child then
                    remoteIndex = i
                    break
                end
            end
            if remoteIndex and connections[remoteIndex] then
                 connections[remoteIndex]:Disconnect()
                 table.remove(connections, remoteIndex) -- Hapus koneksi yang sesuai
            end
            child:Destroy()
        end
    end
    
    buttonOffset = -25
    scrollSizeOffset = 287 -- Reset ke nilai awal
    remotes = {}
    remoteArgs = {}
    remoteButtons = {}
    remoteScripts = {}
    IgnoreList = {}
    BlockList = {}
    -- connections = {} -- Dikelola per tombol sekarang
    unstacked = {}
    RemoteScrollFrame.CanvasSize = UDim2.new(0, 0, 0, scrollSizeOffset)
    lookingAt = nil
    lookingAtArgs = nil
    lookingAtButton = nil
    
    Code.Text = "Logs Cleared!"
    CodeComment.Text = "-- ZXHELL27 Spy"
    ButtonFeedback(Clear, "Cleared!", true)
end)

DoNotStack.MouseButton1Click:Connect(function()
    if lookingAt then
        local isUnstacked = table.find(unstacked, lookingAt)
        if isUnstacked then
            table.remove(unstacked, isUnstacked)
            DoNotStack.Text = "Unstack remote (New Args)"
            DoNotStack.TextColor3 = colorSettings.MainButtons.TextColor
        else
            table.insert(unstacked, lookingAt)
            DoNotStack.Text = "Stack Remote"
            DoNotStack.TextColor3 = Color3.fromRGB(251, 197, 49)
        end
    end
end)

local function len(t)
    local n = 0
    for _ in pairs(t) do n = n + 1 end
    return n
end

local function convertTableToString(argsTable, indentLevel)
    indentLevel = indentLevel or 0
    local indent = string.rep("  ", indentLevel)
    local nextIndent = string.rep("  ", indentLevel + 1)
    local str = ""
    
    local isArray = true
    local maxNumericIndex = 0
    for k, _ in pairs(argsTable) do
        if type(k) ~= "number" or k < 1 or k > #argsTable then -- Perbaikan: k > #argsTable
            isArray = false
        end
        if type(k) == "number" and k > maxNumericIndex then
            maxNumericIndex = k
        end
    end
    if maxNumericIndex ~= #argsTable then isArray = false end -- Perbaikan: #argsTable


    local entries = {}
    if isArray then
        for i = 1, #argsTable do
            local v = argsTable[i]
            local valStr
            if v == nil then valStr = "nil"
            elseif typeof(v) == "Instance" then valStr = GetFullPathOfAnInstance(v)
            elseif type(v) == "number" or type(v) == "function" or type(v) == "boolean" then valStr = tostring(v)
            elseif type(v) == "userdata" then valStr = typeof(v)..": " .. tostring(v) 
            elseif type(v) == "string" then valStr = string.format("%q", v) 
            elseif type(v) == "table" then valStr = "{\n" .. convertTableToString(v, indentLevel + 1) .. nextIndent .. "}"
            else valStr = tostring(v) end
            table.insert(entries, nextIndent .. valStr)
        end
    else 
        for k, v in pairs(argsTable) do
            local keyStr
            if type(k) == "string" and k:match("^[%a_][%w_]*$") then keyStr = k 
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

CopyReturn.MouseButton1Click:Connect(function()
    local remoteIndex = FindRemote(lookingAt, lookingAtArgs)
    if lookingAt and remoteIndex and isA(lookingAt, "RemoteFunction") then
        local success, result = pcall(function() return table.pack(remotes[remoteIndex]:InvokeServer(unpack(remoteArgs[remoteIndex]))) end)
        
        if success then
            if result.n == 0 then setclipboard("nil -- (no return value)")
            elseif result.n == 1 then setclipboard(convertTableToString({result[1]}))
            else
                local returnTable = {}
                for i=1, result.n do table.insert(returnTable, result[i]) end
                setclipboard(convertTableToString(returnTable))
            end
            ButtonFeedback(CopyReturn, "Return Copied!", true)
        else
            warn("ZXHELL27 Spy - Invoke Error:", result)
            setclipboard("-- ERROR INVOKING --\n" .. tostring(result))
            ButtonFeedback(CopyReturn, "Invoke Error!", false)
        end
    else
        ButtonFeedback(CopyReturn, "Not a Function!", false)
    end
end)

-- Koneksi ChildAdded dari source.lua
RemoteScrollFrame.ChildAdded:Connect(function(child)
    if child.Name == "RemoteButton" and child:IsA("TextButton") then -- Pastikan itu tombol remote yang benar
        -- Dapatkan data yang relevan untuk tombol ini.
        -- Karena tombol di-clone, kita perlu cara untuk mengaitkannya kembali ke data di tabel `remotes`
        -- Ini adalah bagian yang rumit karena `addToList` menambahkan ke tabel `remotes` *sebelum* ChildAdded dipicu.
        -- Kita akan mengasumsikan ChildAdded dipicu secara berurutan untuk remote terakhir yang ditambahkan.

        local remoteIndex = #remotes -- Asumsikan ini adalah remote terakhir yang ditambahkan
        if not remotes[remoteIndex] then return end -- Guard jika ada race condition

        local remote = remotes[remoteIndex]
        local args = remoteArgs[remoteIndex]
        local isEvent = isA(remote, "RemoteEvent")
        
        local fireFunction = isEvent and ":FireServer(" or ":InvokeServer("

        local connection = child.MouseButton1Click:Connect(function()
            lookingAt = remote
            lookingAtArgs = args
            lookingAtButton = child.Number -- Sesuai source.lua, ini adalah label Nomor

            InfoHeaderText.Text = "Info: "..(remote.Name or "Unnamed Remote")
            CopyReturn.Visible = not isEvent
            
            local currentCanvasY = InfoButtonsScroll.CanvasSize.Y.Offset
            local copyReturnButtonHeight = 26 + 8 -- Tinggi tombol + padding jika ada
            if not isEvent then -- RemoteFunction
                if not CopyReturn.Visible then -- Jika belum terlihat, tambahkan tingginya
                     -- InfoButtonsScroll.CanvasSize = UDim2.new(0,0,0, currentCanvasY + copyReturnButtonHeight)
                end
            else -- RemoteEvent
                if CopyReturn.Visible then -- Jika terlihat, kurangi tingginya
                    -- InfoButtonsScroll.CanvasSize = UDim2.new(0,0,0, currentCanvasY - copyReturnButtonHeight)
                end
            end


            if not InfoFrame.Visible then
                OpenInfoFrame:MouseButton1Click()
            end
            
            Code.Text = GetFullPathOfAnInstance(remote)..fireFunction..convertTableToString(args,0)..")"
            local textSize = TextService:GetTextSize(Code.Text, Code.TextSize, Code.Font, Vector2.new(math.huge, math.huge))
            CodeFrame.CanvasSize = UDim2.new(0, math.max(670, textSize.X + 20), 2, 0) -- Lebar minimal 670
            Code.Size = UDim2.new(0, math.max(100000, textSize.X + 10), 0, textSize.Y + 10) -- Sesuaikan ukuran TextLabel juga

            BlockRemote.Text = table.find(BlockList, remote) and "Unblock Remote" or "Block remote from firing"
            BlockRemote.TextColor3 = table.find(BlockList, remote) and Color3.fromRGB(251,197,49) or colorSettings.MainButtons.TextColor
            
            IgnoreRemote.Text = table.find(IgnoreList, remote) and "Stop Ignoring" or "Ignore remote"
            IgnoreRemote.TextColor3 = table.find(IgnoreList, remote) and Color3.fromRGB(127,143,166) or colorSettings.MainButtons.TextColor

            DoNotStack.Text = table.find(unstacked, remote) and "Stack Remote" or "Unstack remote (New Args)"
            DoNotStack.TextColor3 = table.find(unstacked, remote) and Color3.fromRGB(251,197,49) or colorSettings.MainButtons.TextColor
            
            InfoFrameOpen = true
        end)
        connections[remoteIndex] = connection -- Simpan koneksi berdasarkan indeks remote
    end
end)


function addToList(isEvent, remote, ...)
    local successCall, errCall = pcall(function()
        local currentId = (get_thread_context or syn.get_thread_identity)()
        ;(set_thread_context or syn.set_thread_identity)(7)
        
        if not remote or not remote.Parent then 
            ;(set_thread_context or syn.set_thread_identity)(currentId)
            return
        end

        local name = remote.Name
        local args = {...}
        local existingRemoteIndex = FindRemote(remote, args)

        if not existingRemoteIndex then
            table.insert(remotes, remote)
            local newRemoteIndex = #remotes

            remoteArgs[newRemoteIndex] = args
            remoteScripts[newRemoteIndex] = (isSynapse() and getcallingscript() or rawget(getfenv(0), "script"))

            local rButton = RemoteButton_Template:Clone()
            rButton.Name = "RemoteButton" -- Pastikan nama tetap untuk ChildAdded
            rButton.Parent = RemoteScrollFrame
            rButton.Visible = true
            
            -- Simpan referensi ke label Nomor untuk remote ini
            remoteButtons[newRemoteIndex] = rButton.Number 
            
            rButton.Number.Text = "1"
            rButton.RemoteName.Text = name or "Unnamed Remote"
            if not isEvent then
                rButton.RemoteIcon.Image = functionImage
            else
                rButton.RemoteIcon.Image = eventImage
            end
            
            buttonOffset = buttonOffset + 35
            rButton.Position = UDim2.new(0.0821256041, 0, 0, buttonOffset) -- Posisi dari source (0,17 relatif ke parent)
            
            -- Update posisi RemoteName berdasarkan ukuran Number
            local numSize = getTextSize(TextService, rButton.Number.Text, rButton.Number.TextSize, rButton.Number.Font, Vector2.new(math.huge, math.huge))
            rButton.RemoteName.Position = UDim2.new(0, numSize.X + 10, 0, 0)
            rButton.RemoteName.Size = UDim2.new(0, 149 - numSize.X, 0, 26) -- Lebar sisa

            if #remotes > 8 then -- Logika dari source.lua
                scrollSizeOffset = scrollSizeOffset + 35
                RemoteScrollFrame.CanvasSize = UDim2.new(0, 0, 0, scrollSizeOffset)
            end
        else 
            local countLabel = remoteButtons[existingRemoteIndex]
            if countLabel and countLabel.Parent then
                countLabel.Text = tostring(tonumber(countLabel.Text) + 1)
                
                local numSize = getTextSize(TextService, countLabel.Text, countLabel.TextSize, countLabel.Font, Vector2.new(math.huge, math.huge))
                countLabel.Parent.RemoteName.Position = UDim2.new(0, numSize.X + 10, 0, 0)
                countLabel.Parent.RemoteName.Size = UDim2.new(0, 149 - numSize.X, 0, 26)
            end

            remoteArgs[existingRemoteIndex] = args 
            remoteScripts[existingRemoteIndex] = (isSynapse() and getcallingscript() or rawget(getfenv(0), "script"))

            if lookingAt == remote and lookingAtButton == remoteButtons[existingRemoteIndex] and InfoFrame.Visible then
                local fireFunc = isA(remote, "RemoteEvent") and ":FireServer(" or ":InvokeServer("
                Code.Text = GetFullPathOfAnInstance(remote)..fireFunc..convertTableToString(args,0)..")"
                local textSize = getTextSize(TextService, Code.Text, Code.TextSize, Code.Font, Vector2.new(math.huge, math.huge))
                CodeFrame.CanvasSize = UDim2.new(0, math.max(670, textSize.X + 20), 2, 0)
                Code.Size = UDim2.new(0, math.max(100000, textSize.X + 10), 0, textSize.Y + 10)
                lookingAtArgs = args -- Update argumen yang dilihat juga
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
    
    local originalReturn = table.pack(OldEvent(Self, ...)) -- Panggil fungsi asli
    addToList(true, Self, ...) -- Log setelahnya
    return table.unpack(originalReturn, 1, originalReturn.n)
end)

local OldFunction
OldFunction = hookfunction(Instance.new("RemoteFunction").InvokeServer, function(Self, ...)
    if not checkcaller() and table.find(BlockList, Self) then return end 
    if table.find(IgnoreList, Self) then return OldFunction(Self, ...) end
    
    local results = table.pack(OldFunction(Self, ...)) 
    addToList(false, Self, ...) 
    return table.unpack(results, 1, results.n) 
end)

local OldNamecall
OldNamecall = hookmetamethod(game,"__namecall",function(...)
    local argsHook = {...} -- Ganti nama agar tidak konflik dengan 'args' di addToList
    local Self = argsHook[1]
    local method = (getnamecallmethod or get_namecall_method)() -- Perbaikan krusial
    
    local shouldLog = false
    local isEventCall = false -- Ganti nama agar tidak konflik

    if method == "FireServer" and isA(Self, "RemoteEvent")  then
        if not checkcaller() and table.find(BlockList, Self) then return end
        if table.find(IgnoreList, Self) then return OldNamecall(...) end
        isEventCall = true
        shouldLog = true
    elseif method == "InvokeServer" and isA(Self, 'RemoteFunction') then
        if not checkcaller() and table.find(BlockList, Self) then return end
        if table.find(IgnoreList, Self) then return OldNamecall(...) end
        isEventCall = false
        shouldLog = true
    end

    if shouldLog then
        local remoteArgsUnpacked = {}
        for i = 2, #argsHook do
            table.insert(remoteArgsUnpacked, argsHook[i])
        end
        
        addToList(isEventCall, Self, unpack(remoteArgsUnpacked))
    end

    return OldNamecall(...)
end)

-- Inisialisasi tinggi mainFrame setelah semua elemen UI didefinisikan
task.wait(0.1) 
if mainFrame and mainFrame.Parent and Header and Header.Parent and RemoteScrollFrame and RemoteScrollFrame.Parent then
    local headerHeight = Header.AbsoluteSize.Y
    local scrollHeight = RemoteScrollFrame.AbsoluteSize.Y > 0 and RemoteScrollFrame.AbsoluteSize.Y or 286 -- Fallback jika AbsoluteSize belum siap
    local initialMainFrameHeight = headerHeight + scrollHeight + 10 
    mainFrame.Size = UDim2.new(mainFrame.Size.X.Scale, mainFrame.Size.X.Offset, 0, initialMainFrameHeight)
    
    if InfoFrame and InfoFrame.Parent then
        InfoFrame.Size = UDim2.new(InfoFrame.Size.X.Scale, InfoFrame.Size.X.Offset, 0, initialMainFrameHeight) 
    end
else
    warn("ZXHELL27 Spy: Gagal menginisialisasi tinggi mainFrame, beberapa elemen UI mungkin hilang.")
end
