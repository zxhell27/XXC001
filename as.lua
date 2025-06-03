-- TurtleSpy V1.5.3, credits to Intrer#0421
-- Ditambah fitur Overpower oleh Partner Coding (AI)

local colorSettings =
{
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
-- read settings for keybind
if not isfile("TurtleSpySettings.json") then
    writefile("TurtleSpySettings.json", HttpService:JSONEncode(settings))
else
    if HttpService:JSONDecode(readfile("TurtleSpySettings.json"))["Main"] then
        writefile("TurtleSpySettings.json", HttpService:JSONEncode(settings))
    else
        settings = HttpService:JSONDecode(readfile("TurtleSpySettings.json"))
    end
end

-- Compatibility for protosmasher: credits to sdjsdj (v3rm username) for converting to proto

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

        if result then
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

-- references to game functions (to prevent using namecall inside of a namecall hook)
local isA = game.IsA
local clone = game.Clone

local TextService = game:GetService("TextService")
local getTextSize = TextService.GetTextSize
game.StarterGui.ResetPlayerGuiOnSpawn = false
local mouse = game.Players.LocalPlayer:GetMouse()

-- delete the previous instances of turtlespy
if game.CoreGui:FindFirstChild("TurtleSpyGUI") then
    game.CoreGui.TurtleSpyGUI:Destroy()
end

--Important tables and GUI offsets
local buttonOffset = -25
local scrollSizeOffset = 287
local functionImage = "http://www.roblox.com/asset/?id=413369623"
local eventImage = "http://www.roblox.com/asset/?id=413369506"
local remotes = {}
local remoteArgs = {}
local remoteButtons = {}
local remoteScripts = {}
local IgnoreList = {}
local BlockList = {}
-- local IgnoreList = {} -- Duplikat, sudah ada di atas
local connections = {}
local unstacked = {}

-- (mostly) generated code by Gui to lua
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

-- Remote browser
local BrowserHeader = Instance.new("Frame")
local BrowserHeaderFrame = Instance.new("Frame")
local BrowserHeaderText = Instance.new("TextLabel")
local CloseInfoFrame2 = Instance.new("TextButton")
local RemoteBrowserFrame = Instance.new("ScrollingFrame")
local RemoteButton2 = Instance.new("TextButton")
local RemoteName2 = Instance.new("TextLabel")
local RemoteIcon2 = Instance.new("ImageLabel")

-- Overpower Features GUI Elements
local OverpowerFeaturesFrame = Instance.new("Frame")
local OverpowerFeaturesHeader = Instance.new("Frame")
-- local OverpowerFeaturesHeaderShading = Instance.new("Frame") -- Tidak digunakan di implementasi baru
local OverpowerFeaturesHeaderText = Instance.new("TextLabel")
local CloseOverpowerFeaturesButton = Instance.new("TextButton")
local OverpowerFeaturesScroll = Instance.new("ScrollingFrame")

local OpenOverpowerButton = Instance.new("ImageButton")

local WalkSpeedLabel = Instance.new("TextLabel")
local WalkSpeedInput = Instance.new("TextBox")
local SetWalkSpeedButton = Instance.new("TextButton")

local JumpPowerLabel = Instance.new("TextLabel")
local JumpPowerInput = Instance.new("TextBox")
local SetJumpPowerButton = Instance.new("TextButton")

local ESPToggleButton = Instance.new("TextButton")
local espActive = false
local espHighlights = {}
local espConnectionRenderStepped

local InfiniteYieldButton = Instance.new("TextButton")

-- Fitur Analisis Remote Overpower
local AdvancedRemoteAnalysisButton = Instance.new("TextButton")
local DecompileAllButton = Instance.new("TextButton")
local SourceTrackerButton = Instance.new("TextButton")
local DecompileOutputFrame = Instance.new("Frame") -- Frame untuk menampilkan hasil decompile
local DecompileOutputHeader = Instance.new("Frame")
local DecompileOutputHeaderText = Instance.new("TextLabel")
local CloseDecompileOutputButton = Instance.new("TextButton")
local DecompileOutputScroll = Instance.new("ScrollingFrame")
local DecompileOutputText = Instance.new("TextLabel")


local currentOverpowerYOffset = 10

TurtleSpyGUI.Name = "TurtleSpyGUI"

Parent(TurtleSpyGUI)

mainFrame.Name = "mainFrame"
mainFrame.Parent = TurtleSpyGUI
mainFrame.BackgroundColor3 = colorSettings["Main"]["MainBackgroundColor"] -- Menggunakan skema warna yang ada
mainFrame.BorderColor3 = colorSettings["Main"]["MainBackgroundColor"] -- Menggunakan skema warna yang ada
mainFrame.Position = UDim2.new(0.100000001, 0, 0.239999995, 0)
mainFrame.Size = UDim2.new(0, 207, 0, 35)
mainFrame.ZIndex = 8
mainFrame.Active = true
mainFrame.Draggable = true

-- Remote browser properties

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

CloseInfoFrame2.Name = "CloseInfoFrame" -- Seharusnya CloseBrowserFrame atau serupa
CloseInfoFrame2.Parent = BrowserHeaderFrame
CloseInfoFrame2.BackgroundColor3 = colorSettings["Main"]["HeaderColor"]
CloseInfoFrame2.BorderColor3 = colorSettings["Main"]["HeaderColor"]
CloseInfoFrame2.Position = UDim2.new(0, 185, 0, 2)
CloseInfoFrame2.Size = UDim2.new(0, 22, 0, 22)
CloseInfoFrame2.ZIndex = 38
CloseInfoFrame2.Font = Enum.Font.SourceSansLight
CloseInfoFrame2.Text = "X"
CloseInfoFrame2.TextColor3 = Color3.fromRGB(0, 0, 0)
CloseInfoFrame2.TextSize = 20.000
CloseInfoFrame2.MouseButton1Click:Connect(function()
    BrowserHeader.Visible = not BrowserHeader.Visible
end)

RemoteBrowserFrame.Name = "RemoteBrowserFrame"
RemoteBrowserFrame.Parent = BrowserHeader
RemoteBrowserFrame.Active = true
RemoteBrowserFrame.BackgroundColor3 = Color3.fromRGB(47, 54, 64)
RemoteBrowserFrame.BorderColor3 = Color3.fromRGB(47, 54, 64)
RemoteBrowserFrame.Position = UDim2.new(-0.004540205, 0, 1.03504682, 0)
RemoteBrowserFrame.Size = UDim2.new(0, 207, 0, 286)
RemoteBrowserFrame.ZIndex = 19
RemoteBrowserFrame.CanvasSize = UDim2.new(0, 0, 0, 287)
RemoteBrowserFrame.ScrollBarThickness = 8
RemoteBrowserFrame.VerticalScrollBarPosition = Enum.VerticalScrollBarPosition.Left
RemoteBrowserFrame.ScrollBarImageColor3 = colorSettings["Main"]["ScrollBarImageColor"]

RemoteButton2.Name = "RemoteButton"
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
RemoteButton2.TextStrokeTransparency = 123.000 -- Tidak ada properti ini
RemoteButton2.TextWrapped = true
RemoteButton2.TextXAlignment = Enum.TextXAlignment.Left
RemoteButton2.Visible = false

RemoteName2.Name = "RemoteName2"
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
RemoteName2.TextTruncate = Enum.TextTruncate.AtEnd -- Mengganti 1 dengan Enum

RemoteIcon2.Name = "RemoteIcon2"
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
ImageButton.Image = "rbxassetid://169476802" -- Icon Browser Remote
ImageButton.ImageColor3 = Color3.fromRGB(53, 53, 53)
ImageButton.MouseButton1Click:Connect(function()
    BrowserHeader.Visible = not BrowserHeader.Visible
    -- Bersihkan daftar lama sebelum mengisi ulang
    for _, child in pairs(RemoteBrowserFrame:GetChildren()) do
        if child.Name == "RemoteButtonTemplate" then -- Nama template yang lebih spesifik
            child:Destroy()
        end
    end
    browsedButtonOffset = 10
    browserCanvasSize = 286
    RemoteBrowserFrame.CanvasSize = UDim2.new(0, 0, 0, browserCanvasSize)
    table.clear(browsedConnections) -- Membersihkan koneksi lama

    for i, v in pairs(game:GetDescendants()) do
        if isA(v, "RemoteEvent") or isA(v, "RemoteFunction") then
            local bButton = clone(RemoteButton2)
            bButton.Name = "RemoteButtonTemplate" -- Beri nama template
            bButton.Parent = RemoteBrowserFrame
            bButton.Visible = true
            bButton.Position = UDim2.new(0, 17, 0, browsedButtonOffset)
            local fireFunction = ""
            if isA(v, "RemoteEvent") then
                fireFunction = ":FireServer()"
                bButton.RemoteIcon2.Image = eventImage
            else
                fireFunction = ":InvokeServer()"
                bButton.RemoteIcon2.Image = functionImage -- Pastikan ini sudah ada
            end
            bButton.RemoteName2.Text = v.Name
            local connection = bButton.MouseButton1Click:Connect(function()
                setclipboard(GetFullPathOfAnInstance(v)..fireFunction)
                ButtonEffect(bButton.RemoteName2, "Path Copied!")
            end)
            table.insert(browsedConnections, connection)
            browsedButtonOffset = browsedButtonOffset + 35

            if #browsedConnections > 7 then -- Sedikit penyesuaian agar scrollbar muncul lebih awal
                browserCanvasSize = browsedButtonOffset + 10 -- Lebih dinamis
                RemoteBrowserFrame.CanvasSize = UDim2.new(0, 0, 0, browserCanvasSize)
            end
        end
    end
end)

-- Tombol Overpower di Header Utama
OpenOverpowerButton.Name = "OpenOverpowerButton"
OpenOverpowerButton.Parent = Header
OpenOverpowerButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
OpenOverpowerButton.BackgroundTransparency = 1.000
OpenOverpowerButton.Position = UDim2.new(0, ImageButton.Position.X.Offset + ImageButton.Size.X.Offset + 5, 0, 8) -- Di sebelah kanan tombol browser
OpenOverpowerButton.Size = UDim2.new(0, 18, 0, 18)
OpenOverpowerButton.ZIndex = 9
OpenOverpowerButton.Image = "rbxassetid://284402950" -- Ganti dengan ID ikon 'power' atau 'settings' yang sesuai
OpenOverpowerButton.ImageColor3 = Color3.fromRGB(53, 53, 53)
OpenOverpowerButton.MouseButton1Click:Connect(function()
    OverpowerFeaturesFrame.Visible = not OverpowerFeaturesFrame.Visible
end)

mouse.KeyDown:Connect(function(key)
    if key:lower() == settings["Keybind"]:lower() then
        TurtleSpyGUI.Enabled = not TurtleSpyGUI.Enabled
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
HeaderTextLabel.Parent = HeaderShading -- Seharusnya Header
HeaderTextLabel.BackgroundTransparency = 1.000
HeaderTextLabel.Position = UDim2.new(-0.00507604145, 0, -0.202857122, 0) -- Sesuaikan jika parentnya Header
HeaderTextLabel.Size = UDim2.new(0, 215, 0, 29)
HeaderTextLabel.ZIndex = 10
HeaderTextLabel.Font = Enum.Font.SourceSans
HeaderTextLabel.Text = "Turtle Spy"
HeaderTextLabel.TextColor3 = colorSettings["Main"]["HeaderTextColor"]
HeaderTextLabel.TextSize = 17.000

RemoteScrollFrame.Name = "RemoteScrollFrame"
RemoteScrollFrame.Parent = mainFrame
RemoteScrollFrame.Active = true
RemoteScrollFrame.BackgroundColor3 = Color3.fromRGB(47, 54, 64)
RemoteScrollFrame.BorderColor3 = Color3.fromRGB(47, 54, 64)
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
RemoteButton.TextColor3 = Color3.fromRGB(220, 221, 225)
RemoteButton.TextSize = 18.000
-- RemoteButton.TextStrokeTransparency = 123.000 -- Tidak ada properti ini
RemoteButton.TextWrapped = true
RemoteButton.TextXAlignment = Enum.TextXAlignment.Left
RemoteButton.Visible = false

Number.Name = "Number"
Number.Parent = RemoteButton
Number.BackgroundTransparency = 1.000
Number.Position = UDim2.new(0, 5, 0, 0)
Number.Size = UDim2.new(0, 300, 0, 26) -- Lebar disesuaikan agar teks angka tidak terpotong
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
RemoteName.Position = UDim2.new(0, 20, 0, 0) -- Akan diupdate oleh addToList
RemoteName.Size = UDim2.new(0, 134, 0, 26) -- Akan diupdate oleh addToList
RemoteName.Font = Enum.Font.SourceSans
RemoteName.Text = "RemoteEvent"
RemoteName.TextColor3 = colorSettings["RemoteButtons"]["TextColor"]
RemoteName.TextSize = 16.000
RemoteName.TextXAlignment = Enum.TextXAlignment.Left
RemoteName.TextTruncate = Enum.TextTruncate.AtEnd -- Mengganti 1 dengan Enum

RemoteIcon.Name = "RemoteIcon"
RemoteIcon.Parent = RemoteButton
RemoteIcon.BackgroundTransparency = 1.000
RemoteIcon.Position = UDim2.new(0.840260386, 0, 0.0225472748, 0)
RemoteIcon.Size = UDim2.new(0, 24, 0, 24)
RemoteIcon.Image = eventImage -- Menggunakan variabel yang sudah ada

InfoFrame.Name = "InfoFrame"
InfoFrame.Parent = mainFrame
InfoFrame.BackgroundColor3 = colorSettings["Main"]["MainBackgroundColor"]
InfoFrame.BorderColor3 = colorSettings["Main"]["MainBackgroundColor"]
InfoFrame.Position = UDim2.new(1, 5, 0, 0) -- Diposisikan di kanan mainFrame
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
InfoTitleShading.Parent = InfoFrameHeader -- Parent ke InfoFrameHeader agar ikut tergeser
InfoTitleShading.BackgroundColor3 = colorSettings["Main"]["HeaderShadingColor"]
InfoTitleShading.BorderColor3 = colorSettings["Main"]["HeaderShadingColor"]
InfoTitleShading.Position = UDim2.new(0, 0, 0, 0) -- Relatif ke InfoFrameHeader
InfoTitleShading.Size = UDim2.new(1, 0, 1, 0) -- Ukuran penuh dari InfoFrameHeader
InfoTitleShading.ZIndex = 13 -- Di bawah InfoHeaderText

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
CodeFrame.ScrollingDirection = Enum.ScrollingDirection.X -- Mengganti 1 dengan Enum
CodeFrame.ScrollBarImageColor3 = colorSettings["Main"]["ScrollBarImageColor"]

Code.Name = "Code"
Code.Parent = CodeFrame
Code.BackgroundTransparency = 1.000
Code.Position = UDim2.new(0.00888902973, 0, 0.0394801199, 0)
Code.Size = UDim2.new(0, 100000, 0, 25) -- Ukuran sangat besar untuk X
Code.ZIndex = 18
Code.Font = Enum.Font.SourceSans
Code.Text = "Thanks for using Turtle Spy! :D"
Code.TextColor3 = colorSettings["Code"]["TextColor"]
Code.TextSize = 14.000
Code.TextWrapped = false -- Agar bisa scroll horizontal
Code.TextXAlignment = Enum.TextXAlignment.Left

CodeComment.Name = "CodeComment"
CodeComment.Parent = CodeFrame
CodeComment.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
CodeComment.BackgroundTransparency = 1.000
CodeComment.Position = UDim2.new(0.0119285434, 0, -0.001968503, 0)
CodeComment.Size = UDim2.new(0, 1000, 0, 25)
CodeComment.ZIndex = 18
CodeComment.Font = Enum.Font.SourceSans
CodeComment.Text = "-- Script generated by TurtleSpy, made by Intrer#0421"
CodeComment.TextColor3 = colorSettings["Code"]["CreditsColor"]
CodeComment.TextSize = 14.000
CodeComment.TextXAlignment = Enum.TextXAlignment.Left

InfoHeaderText.Name = "InfoHeaderText"
InfoHeaderText.Parent = InfoFrameHeader -- Parent ke InfoFrameHeader
InfoHeaderText.BackgroundTransparency = 1.000
InfoHeaderText.Position = UDim2.new(0.0391303934, 0, 0, 0) -- Relatif ke InfoFrameHeader
InfoHeaderText.Size = UDim2.new(1, -50, 1, 0) -- Sisakan ruang untuk tombol close
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
InfoButtonsScroll.CanvasSize = UDim2.new(0, 0, 1, 0)
InfoButtonsScroll.ScrollBarThickness = 8
InfoButtonsScroll.VerticalScrollBarPosition = Enum.VerticalScrollBarPosition.Left
InfoButtonsScroll.ScrollBarImageColor3 = colorSettings["Main"]["ScrollBarImageColor"]

CopyCode.Name = "CopyCode"
CopyCode.Parent = InfoButtonsScroll
CopyCode.BackgroundColor3 = colorSettings["MainButtons"]["BackgroundColor"]
CopyCode.BorderColor3 = colorSettings["MainButtons"]["BorderColor"]
CopyCode.Position = UDim2.new(0.0645, 0, 0, 10)
CopyCode.Size = UDim2.new(0, 294, 0, 26)
CopyCode.ZIndex = 15
CopyCode.Font = Enum.Font.SourceSans
CopyCode.Text = "Copy code"
CopyCode.TextColor3 = Color3.fromRGB(250, 251, 255)
CopyCode.TextSize = 16.000

RunCode.Name = "RunCode"
RunCode.Parent = InfoButtonsScroll
RunCode.BackgroundColor3 = colorSettings["MainButtons"]["BackgroundColor"]
RunCode.BorderColor3 = colorSettings["MainButtons"]["BorderColor"]
RunCode.Position = UDim2.new(0.0645, 0, 0, 45)
RunCode.Size = UDim2.new(0, 294, 0, 26)
RunCode.ZIndex = 15
RunCode.Font = Enum.Font.SourceSans
RunCode.Text = "Execute"
RunCode.TextColor3 = Color3.fromRGB(250, 251, 255)
RunCode.TextSize = 16.000

CopyScriptPath.Name = "CopyScriptPath"
CopyScriptPath.Parent = InfoButtonsScroll
CopyScriptPath.BackgroundColor3 = colorSettings["MainButtons"]["BackgroundColor"]
CopyScriptPath.BorderColor3 = colorSettings["MainButtons"]["BorderColor"]
CopyScriptPath.Position = UDim2.new(0.0645, 0, 0, 80)
CopyScriptPath.Size = UDim2.new(0, 294, 0, 26)
CopyScriptPath.ZIndex = 15
CopyScriptPath.Font = Enum.Font.SourceSans
CopyScriptPath.Text = "Copy script path"
CopyScriptPath.TextColor3 = Color3.fromRGB(250, 251, 255)
CopyScriptPath.TextSize = 16.000

CopyDecompiled.Name = "CopyDecompiled"
CopyDecompiled.Parent = InfoButtonsScroll
CopyDecompiled.BackgroundColor3 = colorSettings["MainButtons"]["BackgroundColor"]
CopyDecompiled.BorderColor3 = colorSettings["MainButtons"]["BorderColor"]
CopyDecompiled.Position = UDim2.new(0.0645, 0, 0, 115)
CopyDecompiled.Size = UDim2.new(0, 294, 0, 26)
CopyDecompiled.ZIndex = 15
CopyDecompiled.Font = Enum.Font.SourceSans
CopyDecompiled.Text = "Copy decompiled script"
CopyDecompiled.TextColor3 = Color3.fromRGB(250, 251, 255)
CopyDecompiled.TextSize = 16.000

IgnoreRemote.Name = "IgnoreRemote"
IgnoreRemote.Parent = InfoButtonsScroll
IgnoreRemote.BackgroundColor3 = colorSettings["MainButtons"]["BackgroundColor"]
IgnoreRemote.BorderColor3 = colorSettings["MainButtons"]["BorderColor"]
IgnoreRemote.Position = UDim2.new(0.0645, 0, 0, 185)
IgnoreRemote.Size = UDim2.new(0, 294, 0, 26)
IgnoreRemote.ZIndex = 15
IgnoreRemote.Font = Enum.Font.SourceSans
IgnoreRemote.Text = "Ignore remote"
IgnoreRemote.TextColor3 = Color3.fromRGB(250, 251, 255)
IgnoreRemote.TextSize = 16.000

BlockRemote.Name = "Block Remote"
BlockRemote.Parent = InfoButtonsScroll
BlockRemote.BackgroundColor3 = colorSettings["MainButtons"]["BackgroundColor"]
BlockRemote.BorderColor3 = colorSettings["MainButtons"]["BorderColor"]
BlockRemote.Position = UDim2.new(0.0645, 0, 0, 220)
BlockRemote.Size = UDim2.new(0, 294, 0, 26)
BlockRemote.ZIndex = 15
BlockRemote.Font = Enum.Font.SourceSans
BlockRemote.Text = "Block remote from firing"
BlockRemote.TextColor3 = Color3.fromRGB(250, 251, 255)
BlockRemote.TextSize = 16.000

WhileLoop.Name = "WhileLoop"
WhileLoop.Parent = InfoButtonsScroll
WhileLoop.BackgroundColor3 = colorSettings["MainButtons"]["BackgroundColor"]
WhileLoop.BorderColor3 = colorSettings["MainButtons"]["BorderColor"]
WhileLoop.Position = UDim2.new(0.0645, 0, 0, 290)
WhileLoop.Size = UDim2.new(0, 294, 0, 26)
WhileLoop.ZIndex = 15
WhileLoop.Font = Enum.Font.SourceSans
WhileLoop.Text = "Generate while loop script"
WhileLoop.TextColor3 = Color3.fromRGB(250, 251, 255)
WhileLoop.TextSize = 16.000

Clear.Name = "Clear"
Clear.Parent = InfoButtonsScroll
Clear.BackgroundColor3 = colorSettings["MainButtons"]["BackgroundColor"]
Clear.BorderColor3 = colorSettings["MainButtons"]["BorderColor"]
Clear.Position = UDim2.new(0.0645, 0, 0, 255)
Clear.Size = UDim2.new(0, 294, 0, 26)
Clear.ZIndex = 15
Clear.Font = Enum.Font.SourceSans
Clear.Text = "Clear logs"
Clear.TextColor3 = Color3.fromRGB(250, 251, 255)
Clear.TextSize = 16.000

CopyReturn.Name = "CopyReturn"
CopyReturn.Parent = InfoButtonsScroll
CopyReturn.BackgroundColor3 = colorSettings["MainButtons"]["BackgroundColor"]
CopyReturn.BorderColor3 = colorSettings["MainButtons"]["BorderColor"]
CopyReturn.Position = UDim2.new(0.0645, 0, 0, 325)
CopyReturn.Size = UDim2.new(0, 294, 0, 26)
CopyReturn.ZIndex = 15
CopyReturn.Font = Enum.Font.SourceSans
CopyReturn.Text = "Execute and copy return value"
CopyReturn.TextColor3 = Color3.fromRGB(250, 251, 255)
CopyReturn.TextSize = 16.000

DoNotStack.Name = "DoNotStack" -- Nama variabel berbeda dari nama properti
DoNotStack.Parent = InfoButtonsScroll
DoNotStack.BackgroundColor3 = colorSettings["MainButtons"]["BackgroundColor"]
DoNotStack.BorderColor3 =  colorSettings["MainButtons"]["BorderColor"]
DoNotStack.Position = UDim2.new(0.0645, 0, 0, 150)
DoNotStack.Size = UDim2.new(0, 294, 0, 26)
DoNotStack.ZIndex = 15
DoNotStack.Font = Enum.Font.SourceSans
DoNotStack.Text = "Unstack remote when fired with new args"
DoNotStack.TextColor3 = Color3.fromRGB(250, 251, 255)
DoNotStack.TextSize = 16.000

FrameDivider.Name = "FrameDivider"
FrameDivider.Parent = mainFrame -- Seharusnya parent ke mainFrame jika memisahkan mainFrame dan InfoFrame
FrameDivider.BackgroundColor3 = Color3.fromRGB(53, 59, 72)
FrameDivider.BorderColor3 = Color3.fromRGB(53, 59, 72)
FrameDivider.Position = UDim2.new(1, 0, 0, 0) -- Di ujung kanan mainFrame
FrameDivider.Size = UDim2.new(0, 4, 1, 0) -- Tinggi penuh dari mainFrame
FrameDivider.ZIndex = 7

local InfoFrameOpen = false
CloseInfoFrame.Name = "CloseInfoFrame"
CloseInfoFrame.Parent = InfoFrameHeader -- Parent ke InfoFrameHeader
CloseInfoFrame.BackgroundColor3 = colorSettings["Main"]["HeaderColor"]
CloseInfoFrame.BorderColor3 = colorSettings["Main"]["HeaderColor"]
CloseInfoFrame.Position = UDim2.new(1, -24, 0, 2) -- Pojok kanan atas InfoFrameHeader
CloseInfoFrame.Size = UDim2.new(0, 22, 0, 22)
CloseInfoFrame.ZIndex = 18
CloseInfoFrame.Font = Enum.Font.SourceSansLight
CloseInfoFrame.Text = "X"
CloseInfoFrame.TextColor3 = Color3.fromRGB(0, 0, 0)
CloseInfoFrame.TextSize = 20.000
CloseInfoFrame.MouseButton1Click:Connect(function()
    InfoFrame.Visible = false
    InfoFrameOpen = false
    mainFrame.Size = UDim2.new(0, 207, 0, 35) -- Kembalikan ukuran mainFrame
    OpenInfoFrame.Text = ">" -- Kembalikan teks tombol OpenInfoFrame
end)

OpenInfoFrame.Name = "OpenInfoFrame"
OpenInfoFrame.Parent = Header -- Parent ke Header utama
OpenInfoFrame.BackgroundColor3 = colorSettings["Main"]["HeaderColor"]
OpenInfoFrame.BorderColor3 = colorSettings["Main"]["HeaderColor"]
OpenInfoFrame.Position = UDim2.new(0, 185, 0, 2)
OpenInfoFrame.Size = UDim2.new(0, 22, 0, 22)
OpenInfoFrame.ZIndex = 18
OpenInfoFrame.Font = Enum.Font.SourceSans
OpenInfoFrame.Text = ">"
OpenInfoFrame.TextColor3 = Color3.fromRGB(0, 0, 0)
OpenInfoFrame.TextSize = 16.000
OpenInfoFrame.MouseButton1Click:Connect(function()
	if not InfoFrame.Visible then
		mainFrame.Size = UDim2.new(0, 207 + InfoFrame.Size.X.Offset + FrameDivider.Size.X.Offset, 0, 35) -- Sesuaikan ukuran
		OpenInfoFrame.Text = "<"
	else
		mainFrame.Size = UDim2.new(0, 207, 0, 35)
		OpenInfoFrame.Text = ">"
	end
	InfoFrame.Visible = not InfoFrame.Visible
	InfoFrameOpen = not InfoFrameOpen
end)

Minimize.Name = "Minimize"
Minimize.Parent = Header -- Parent ke Header utama
Minimize.BackgroundColor3 = colorSettings["Main"]["HeaderColor"]
Minimize.BorderColor3 = colorSettings["Main"]["HeaderColor"]
Minimize.Position = UDim2.new(0, 164, 0, 2)
Minimize.Size = UDim2.new(0, 22, 0, 22)
Minimize.ZIndex = 18
Minimize.Font = Enum.Font.SourceSans
Minimize.Text = "_"
Minimize.TextColor3 = Color3.fromRGB(0, 0, 0)
Minimize.TextSize = 16.000
Minimize.MouseButton1Click:Connect(function()
	if RemoteScrollFrame.Visible then -- Jika sedang terbuka (expanded)
		mainFrame.Size = UDim2.new(0, 207, 0, 35) -- Ukuran header saja
		if InfoFrameOpen then OpenInfoFrame.Text = ">" else OpenInfoFrame.Text = ">" end -- InfoFrame akan tertutup
		InfoFrame.Visible = false
        RemoteScrollFrame.Visible = false
	else -- Jika sedang tertutup (minimized)
		if InfoFrameOpen then
		    mainFrame.Size = UDim2.new(0, 207 + InfoFrame.Size.X.Offset + FrameDivider.Size.X.Offset, 0, 321) -- Tinggi penuh
		    OpenInfoFrame.Text = "<"
			InfoFrame.Visible = true
		else
			mainFrame.Size = UDim2.new(0, 207, 0, 321) -- Tinggi penuh
			OpenInfoFrame.Text = ">"
			InfoFrame.Visible = false
		end
        RemoteScrollFrame.Visible = true
	end
	-- RemoteScrollFrame.Visible = not RemoteScrollFrame.Visible -- Logika ini diganti di atas
    -- Update tinggi mainFrame berdasarkan visibilitas RemoteScrollFrame
    if RemoteScrollFrame.Visible then
        if InfoFrameOpen then
            mainFrame.Size = UDim2.new(0, 207 + InfoFrame.Size.X.Offset + FrameDivider.Size.X.Offset, 0, 321)
        else
            mainFrame.Size = UDim2.new(0, 207, 0, 321)
        end
    else
         mainFrame.Size = UDim2.new(0, 207, 0, 35) -- Hanya header
    end
end)

-- Pengaturan GUI Fitur Overpower
OverpowerFeaturesFrame.Name = "OverpowerFeaturesFrame"
OverpowerFeaturesFrame.Parent = TurtleSpyGUI
OverpowerFeaturesFrame.BackgroundColor3 = colorSettings["Main"]["HeaderShadingColor"]
OverpowerFeaturesFrame.BorderColor3 = colorSettings["Main"]["HeaderShadingColor"]
OverpowerFeaturesFrame.Position = UDim2.new(mainFrame.Position.X.Scale, mainFrame.Position.X.Offset + mainFrame.Size.X.Offset + 10, mainFrame.Position.Y.Scale, mainFrame.Position.Y.Offset) -- Di kanan mainFrame
OverpowerFeaturesFrame.Size = UDim2.new(0, 280, 0, 350) -- Ukuran default, bisa disesuaikan
OverpowerFeaturesFrame.ZIndex = 20
OverpowerFeaturesFrame.Active = true
OverpowerFeaturesFrame.Draggable = true
OverpowerFeaturesFrame.Visible = false

OverpowerFeaturesHeader.Name = "OverpowerFeaturesHeader"
OverpowerFeaturesHeader.Parent = OverpowerFeaturesFrame
OverpowerFeaturesHeader.BackgroundColor3 = colorSettings["Main"]["HeaderColor"]
OverpowerFeaturesHeader.BorderColor3 = colorSettings["Main"]["HeaderColor"]
OverpowerFeaturesHeader.Size = UDim2.new(1, 0, 0, 26)
OverpowerFeaturesHeader.ZIndex = 21

OverpowerFeaturesHeaderText.Name = "OverpowerFeaturesHeaderText"
OverpowerFeaturesHeaderText.Parent = OverpowerFeaturesHeader
OverpowerFeaturesHeaderText.BackgroundTransparency = 1.000
OverpowerFeaturesHeaderText.Size = UDim2.new(1, -25, 1, 0)
OverpowerFeaturesHeaderText.ZIndex = 22
OverpowerFeaturesHeaderText.Font = Enum.Font.SourceSans
OverpowerFeaturesHeaderText.Text = "Overpower Features"
OverpowerFeaturesHeaderText.TextColor3 = colorSettings["Main"]["HeaderTextColor"]
OverpowerFeaturesHeaderText.TextSize = 17.000
OverpowerFeaturesHeaderText.TextXAlignment = Enum.TextXAlignment.Center

CloseOverpowerFeaturesButton.Name = "CloseOverpowerFeaturesButton"
CloseOverpowerFeaturesButton.Parent = OverpowerFeaturesHeader
CloseOverpowerFeaturesButton.BackgroundColor3 = colorSettings["Main"]["HeaderColor"]
CloseOverpowerFeaturesButton.BorderColor3 = colorSettings["Main"]["HeaderColor"]
CloseOverpowerFeaturesButton.Position = UDim2.new(1, -24, 0, 2)
CloseOverpowerFeaturesButton.Size = UDim2.new(0, 22, 0, 22)
CloseOverpowerFeaturesButton.ZIndex = 38
CloseOverpowerFeaturesButton.Font = Enum.Font.SourceSansLight
CloseOverpowerFeaturesButton.Text = "X"
CloseOverpowerFeaturesButton.TextColor3 = Color3.fromRGB(0, 0, 0)
CloseOverpowerFeaturesButton.TextSize = 20.000
CloseOverpowerFeaturesButton.MouseButton1Click:Connect(function()
    OverpowerFeaturesFrame.Visible = false
end)

OverpowerFeaturesScroll.Name = "OverpowerFeaturesScroll"
OverpowerFeaturesScroll.Parent = OverpowerFeaturesFrame
OverpowerFeaturesScroll.Active = true
OverpowerFeaturesScroll.BackgroundColor3 = colorSettings["Main"]["InfoScrollingFrameBgColor"]
OverpowerFeaturesScroll.BorderColor3 = colorSettings["Main"]["InfoScrollingFrameBgColor"]
OverpowerFeaturesScroll.Position = UDim2.new(0, 0, 0, OverpowerFeaturesHeader.Size.Y.Offset + 2)
OverpowerFeaturesScroll.Size = UDim2.new(1, 0, 1, -(OverpowerFeaturesHeader.Size.Y.Offset + 7))
OverpowerFeaturesScroll.ZIndex = 19
OverpowerFeaturesScroll.CanvasSize = UDim2.new(0, 0, 0, 0) -- Akan diatur
OverpowerFeaturesScroll.ScrollBarThickness = 8
OverpowerFeaturesScroll.VerticalScrollBarPosition = Enum.VerticalScrollBarPosition.Left
OverpowerFeaturesScroll.ScrollBarImageColor3 = colorSettings["Main"]["ScrollBarImageColor"]

-- Elemen Kontrol di OverpowerFeaturesScroll
currentOverpowerYOffset = 10 -- Reset untuk layout di dalam scroll frame ini

-- WalkSpeed
WalkSpeedLabel.Name = "WalkSpeedLabel"
WalkSpeedLabel.Parent = OverpowerFeaturesScroll
WalkSpeedLabel.BackgroundTransparency = 1.000
WalkSpeedLabel.Size = UDim2.new(0.9, -10, 0, 20)
WalkSpeedLabel.Position = UDim2.new(0.05, 0, 0, currentOverpowerYOffset)
WalkSpeedLabel.Font = Enum.Font.SourceSans
WalkSpeedLabel.TextColor3 = colorSettings["Code"]["TextColor"]
WalkSpeedLabel.TextSize = 14.000
WalkSpeedLabel.TextXAlignment = Enum.TextXAlignment.Left
WalkSpeedLabel.Text = "WalkSpeed:"
currentOverpowerYOffset = currentOverpowerYOffset + 25

WalkSpeedInput.Name = "WalkSpeedInput"
WalkSpeedInput.Parent = OverpowerFeaturesScroll
WalkSpeedInput.BackgroundColor3 = colorSettings["Code"]["BackgroundColor"]
WalkSpeedInput.BorderColor3 = colorSettings["MainButtons"]["BorderColor"]
WalkSpeedInput.Position = UDim2.new(0.05, 0, 0, currentOverpowerYOffset)
WalkSpeedInput.Size = UDim2.new(0.6, 0, 0, 25)
WalkSpeedInput.Font = Enum.Font.SourceSans
WalkSpeedInput.TextColor3 = colorSettings["Code"]["TextColor"]
WalkSpeedInput.TextSize = 14.000
WalkSpeedInput.Text = tostring(client.Character and client.Character:FindFirstChildOfClass("Humanoid") and client.Character.Humanoid.WalkSpeed or 16)
WalkSpeedInput.PlaceholderText = "Enter speed"

SetWalkSpeedButton.Name = "SetWalkSpeedButton"
SetWalkSpeedButton.Parent = OverpowerFeaturesScroll
SetWalkSpeedButton.BackgroundColor3 = colorSettings["MainButtons"]["BackgroundColor"]
SetWalkSpeedButton.BorderColor3 = colorSettings["MainButtons"]["BorderColor"]
SetWalkSpeedButton.Position = UDim2.new(0.7, 0, 0, currentOverpowerYOffset)
SetWalkSpeedButton.Size = UDim2.new(0.25, 0, 0, 25)
SetWalkSpeedButton.Font = Enum.Font.SourceSans
SetWalkSpeedButton.TextColor3 = colorSettings["MainButtons"]["TextColor"]
SetWalkSpeedButton.TextSize = 14.000
SetWalkSpeedButton.Text = "Set"
SetWalkSpeedButton.MouseButton1Click:Connect(function()
    local speed = tonumber(WalkSpeedInput.Text)
    if speed and client and client.Character and client.Character:FindFirstChildOfClass("Humanoid") then
        client.Character.Humanoid.WalkSpeed = speed
        ButtonEffect(SetWalkSpeedButton, "Set!")
    else
        ButtonEffect(SetWalkSpeedButton, "Error!")
    end
end)
currentOverpowerYOffset = currentOverpowerYOffset + 35

-- JumpPower
JumpPowerLabel.Name = "JumpPowerLabel"
JumpPowerLabel.Parent = OverpowerFeaturesScroll
JumpPowerLabel.BackgroundTransparency = 1.000
JumpPowerLabel.Size = UDim2.new(0.9, -10, 0, 20)
JumpPowerLabel.Position = UDim2.new(0.05, 0, 0, currentOverpowerYOffset)
JumpPowerLabel.Font = Enum.Font.SourceSans
JumpPowerLabel.TextColor3 = colorSettings["Code"]["TextColor"]
JumpPowerLabel.TextSize = 14.000
JumpPowerLabel.TextXAlignment = Enum.TextXAlignment.Left
JumpPowerLabel.Text = "JumpPower:"
currentOverpowerYOffset = currentOverpowerYOffset + 25

JumpPowerInput.Name = "JumpPowerInput"
JumpPowerInput.Parent = OverpowerFeaturesScroll
JumpPowerInput.BackgroundColor3 = colorSettings["Code"]["BackgroundColor"]
JumpPowerInput.BorderColor3 = colorSettings["MainButtons"]["BorderColor"]
JumpPowerInput.Position = UDim2.new(0.05, 0, 0, currentOverpowerYOffset)
JumpPowerInput.Size = UDim2.new(0.6, 0, 0, 25)
JumpPowerInput.Font = Enum.Font.SourceSans
JumpPowerInput.TextColor3 = colorSettings["Code"]["TextColor"]
JumpPowerInput.TextSize = 14.000
JumpPowerInput.Text = tostring(client.Character and client.Character:FindFirstChildOfClass("Humanoid") and client.Character.Humanoid.JumpPower or 50)
JumpPowerInput.PlaceholderText = "Enter power"

SetJumpPowerButton.Name = "SetJumpPowerButton"
SetJumpPowerButton.Parent = OverpowerFeaturesScroll
SetJumpPowerButton.BackgroundColor3 = colorSettings["MainButtons"]["BackgroundColor"]
SetJumpPowerButton.BorderColor3 = colorSettings["MainButtons"]["BorderColor"]
SetJumpPowerButton.Position = UDim2.new(0.7, 0, 0, currentOverpowerYOffset)
SetJumpPowerButton.Size = UDim2.new(0.25, 0, 0, 25)
SetJumpPowerButton.Font = Enum.Font.SourceSans
SetJumpPowerButton.TextColor3 = colorSettings["MainButtons"]["TextColor"]
SetJumpPowerButton.TextSize = 14.000
SetJumpPowerButton.Text = "Set"
SetJumpPowerButton.MouseButton1Click:Connect(function()
    local power = tonumber(JumpPowerInput.Text)
    if power and client and client.Character and client.Character:FindFirstChildOfClass("Humanoid") then
        client.Character.Humanoid.JumpPower = power
        ButtonEffect(SetJumpPowerButton, "Set!")
    else
        ButtonEffect(SetJumpPowerButton, "Error!")
    end
end)
currentOverpowerYOffset = currentOverpowerYOffset + 35

-- ESP Toggle Button
ESPToggleButton.Name = "ESPToggleButton"
ESPToggleButton.Parent = OverpowerFeaturesScroll
ESPToggleButton.BackgroundColor3 = colorSettings["MainButtons"]["BackgroundColor"]
ESPToggleButton.BorderColor3 = colorSettings["MainButtons"]["BorderColor"]
ESPToggleButton.Position = UDim2.new(0.05, 0, 0, currentOverpowerYOffset)
ESPToggleButton.Size = UDim2.new(0.9, 0, 0, 25)
ESPToggleButton.Font = Enum.Font.SourceSans
ESPToggleButton.TextColor3 = colorSettings["MainButtons"]["TextColor"]
ESPToggleButton.TextSize = 14.000
ESPToggleButton.Text = "Toggle Player ESP (Highlight)"

local function updateESP()
    if not espActive then
        for playerObj, highlightInstance in pairs(espHighlights) do
            if highlightInstance and highlightInstance.Parent then
                highlightInstance:Destroy()
            end
        end
        espHighlights = {}
        return
    end

    local currentPlayers = game:GetService("Players"):GetPlayers()
    local activePlayerCharacters = {}

    for _, playerObj in pairs(currentPlayers) do
        if playerObj ~= client and playerObj.Character and playerObj.Character:FindFirstChild("Head") then
            activePlayerCharacters[playerObj] = playerObj.Character
            if not espHighlights[playerObj] or not espHighlights[playerObj].Parent then
                local highlightInstance = Instance.new("Highlight")
                highlightInstance.FillColor = Color3.fromRGB(255, 0, 0) -- Merah
                highlightInstance.OutlineColor = Color3.fromRGB(200, 0, 0)
                highlightInstance.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                highlightInstance.Adornee = playerObj.Character
                highlightInstance.Parent = playerObj.Character
                espHighlights[playerObj] = highlightInstance
            elseif espHighlights[playerObj].Adornee ~= playerObj.Character then
                 espHighlights[playerObj].Adornee = playerObj.Character
            end
        else
            if espHighlights[playerObj] and espHighlights[playerObj].Parent then
                espHighlights[playerObj]:Destroy()
                espHighlights[playerObj] = nil
            end
        end
    end

    for playerObj, highlightInstance in pairs(espHighlights) do
        if not activePlayerCharacters[playerObj] then
            if highlightInstance and highlightInstance.Parent then
                highlightInstance:Destroy()
            end
            espHighlights[playerObj] = nil
        end
    end
end

ESPToggleButton.MouseButton1Click:Connect(function()
    espActive = not espActive
    if espActive then
        ESPToggleButton.Text = "Player ESP: ON"
        ESPToggleButton.TextColor3 = Color3.fromRGB(76, 209, 55) -- Hijau
        if not espConnectionRenderStepped or not espConnectionRenderStepped.Connected then
             espConnectionRenderStepped = game:GetService("RunService").RenderStepped:Connect(updateESP)
        end
        updateESP()
    else
        ESPToggleButton.Text = "Toggle Player ESP (Highlight)"
        ESPToggleButton.TextColor3 = colorSettings["MainButtons"]["TextColor"]
        if espConnectionRenderStepped and espConnectionRenderStepped.Connected then
            espConnectionRenderStepped:Disconnect()
        end
        updateESP()
    end
end)
currentOverpowerYOffset = currentOverpowerYOffset + 35

-- Infinite Yield Button
InfiniteYieldButton.Name = "InfiniteYieldButton"
InfiniteYieldButton.Parent = OverpowerFeaturesScroll
InfiniteYieldButton.BackgroundColor3 = colorSettings["MainButtons"]["BackgroundColor"]
InfiniteYieldButton.BorderColor3 = colorSettings["MainButtons"]["BorderColor"]
InfiniteYieldButton.Position = UDim2.new(0.05, 0, 0, currentOverpowerYOffset)
InfiniteYieldButton.Size = UDim2.new(0.9, 0, 0, 25)
InfiniteYieldButton.Font = Enum.Font.SourceSans
InfiniteYieldButton.TextColor3 = colorSettings["MainButtons"]["TextColor"]
InfiniteYieldButton.TextSize = 14.000
InfiniteYieldButton.Text = "Run Infinite Yield"
InfiniteYieldButton.MouseButton1Click:Connect(function()
    ButtonEffect(InfiniteYieldButton, "Loading...")
    local iyScriptUrl = "https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source" -- Contoh URL IY yang umum
    local success, err = pcall(function()
        local iySource = game:HttpGet(iyScriptUrl, true)
        loadstring(iySource)()
        ButtonEffect(InfiniteYieldButton, "IY Executed!")
    end)
    if not success then
        ButtonEffect(InfiniteYieldButton, "IY Error!")
        warn("TurtleSpy: Error executing Infinite Yield: " .. tostring(err))
    end
end)
currentOverpowerYOffset = currentOverpowerYOffset + 35

-- Tombol Analisis Remote Tingkat Lanjut (Placeholder)
AdvancedRemoteAnalysisButton.Name = "AdvancedRemoteAnalysisButton"
AdvancedRemoteAnalysisButton.Parent = OverpowerFeaturesScroll
AdvancedRemoteAnalysisButton.BackgroundColor3 = colorSettings["MainButtons"]["BackgroundColor"]
AdvancedRemoteAnalysisButton.BorderColor3 = colorSettings["MainButtons"]["BorderColor"]
AdvancedRemoteAnalysisButton.Position = UDim2.new(0.05, 0, 0, currentOverpowerYOffset)
AdvancedRemoteAnalysisButton.Size = UDim2.new(0.9, 0, 0, 25)
AdvancedRemoteAnalysisButton.Font = Enum.Font.SourceSans
AdvancedRemoteAnalysisButton.TextColor3 = colorSettings["MainButtons"]["TextColor"]
AdvancedRemoteAnalysisButton.TextSize = 14.000
AdvancedRemoteAnalysisButton.Text = "Analisis Remote Lanjutan (Segera)"
AdvancedRemoteAnalysisButton.MouseButton1Click:Connect(function()
    ButtonEffect(AdvancedRemoteAnalysisButton, "Segera Hadir!")
    warn("TurtleSpy: Fitur Analisis Remote Lanjutan belum diimplementasikan sepenuhnya.")
end)
currentOverpowerYOffset = currentOverpowerYOffset + 35

-- Frame untuk Output Decompile
DecompileOutputFrame.Name = "DecompileOutputFrame"
DecompileOutputFrame.Parent = TurtleSpyGUI
DecompileOutputFrame.BackgroundColor3 = colorSettings["Main"]["HeaderShadingColor"]
DecompileOutputFrame.BorderColor3 = colorSettings["Main"]["HeaderShadingColor"]
DecompileOutputFrame.Position = UDim2.new(0.5, -200, 0.5, -150) -- Tengah layar
DecompileOutputFrame.Size = UDim2.new(0, 400, 0, 300)
DecompileOutputFrame.ZIndex = 100 -- Di atas segalanya
DecompileOutputFrame.Active = true
DecompileOutputFrame.Draggable = true
DecompileOutputFrame.Visible = false

DecompileOutputHeader.Name = "DecompileOutputHeader"
DecompileOutputHeader.Parent = DecompileOutputFrame
DecompileOutputHeader.BackgroundColor3 = colorSettings["Main"]["HeaderColor"]
DecompileOutputHeader.BorderColor3 = colorSettings["Main"]["HeaderColor"]
DecompileOutputHeader.Size = UDim2.new(1, 0, 0, 26)
DecompileOutputHeader.ZIndex = 101

DecompileOutputHeaderText.Name = "DecompileOutputHeaderText"
DecompileOutputHeaderText.Parent = DecompileOutputHeader
DecompileOutputHeaderText.BackgroundTransparency = 1.000
DecompileOutputHeaderText.Size = UDim2.new(1, -25, 1, 0)
DecompileOutputHeaderText.ZIndex = 102
DecompileOutputHeaderText.Font = Enum.Font.SourceSans
DecompileOutputHeaderText.Text = "Hasil Decompile Skrip"
DecompileOutputHeaderText.TextColor3 = colorSettings["Main"]["HeaderTextColor"]
DecompileOutputHeaderText.TextSize = 17.000
DecompileOutputHeaderText.TextXAlignment = Enum.TextXAlignment.Center

CloseDecompileOutputButton.Name = "CloseDecompileOutputButton"
CloseDecompileOutputButton.Parent = DecompileOutputHeader
CloseDecompileOutputButton.BackgroundColor3 = colorSettings["Main"]["HeaderColor"]
CloseDecompileOutputButton.BorderColor3 = colorSettings["Main"]["HeaderColor"]
CloseDecompileOutputButton.Position = UDim2.new(1, -24, 0, 2)
CloseDecompileOutputButton.Size = UDim2.new(0, 22, 0, 22)
CloseDecompileOutputButton.ZIndex = 103
CloseDecompileOutputButton.Font = Enum.Font.SourceSansLight
CloseDecompileOutputButton.Text = "X"
CloseDecompileOutputButton.TextColor3 = Color3.fromRGB(0, 0, 0)
CloseDecompileOutputButton.TextSize = 20.000
CloseDecompileOutputButton.MouseButton1Click:Connect(function()
    DecompileOutputFrame.Visible = false
end)

DecompileOutputScroll.Name = "DecompileOutputScroll"
DecompileOutputScroll.Parent = DecompileOutputFrame
DecompileOutputScroll.Active = true
DecompileOutputScroll.BackgroundColor3 = colorSettings["Code"]["BackgroundColor"]
DecompileOutputScroll.BorderColor3 = colorSettings["Code"]["BackgroundColor"]
DecompileOutputScroll.Position = UDim2.new(0, 5, 0, DecompileOutputHeader.Size.Y.Offset + 5)
DecompileOutputScroll.Size = UDim2.new(1, -10, 1, -(DecompileOutputHeader.Size.Y.Offset + 10))
DecompileOutputScroll.ZIndex = 100
DecompileOutputScroll.CanvasSize = UDim2.new(2, 0, 5, 0) -- Perluas canvas untuk teks panjang
DecompileOutputScroll.ScrollBarThickness = 8
DecompileOutputScroll.ScrollingDirection = Enum.ScrollingDirection.XY -- Scroll X dan Y
DecompileOutputScroll.ScrollBarImageColor3 = colorSettings["Main"]["ScrollBarImageColor"]

DecompileOutputText.Name = "DecompileOutputText"
DecompileOutputText.Parent = DecompileOutputScroll
DecompileOutputText.BackgroundTransparency = 1.000
DecompileOutputText.Size = UDim2.new(1, 0, 1, 0) -- Ukuran awal, akan disesuaikan dengan konten
DecompileOutputText.Font = Enum.Font.Code -- Font monospace lebih baik untuk kode
DecompileOutputText.TextColor3 = colorSettings["Code"]["TextColor"]
DecompileOutputText.TextSize = 12.000 -- Ukuran lebih kecil untuk banyak teks
DecompileOutputText.TextWrapped = false -- Jangan wrap, biarkan scroll horizontal
DecompileOutputText.TextXAlignment = Enum.TextXAlignment.Left
DecompileOutputText.TextYAlignment = Enum.TextYAlignment.Top
DecompileOutputText.Text = ""


-- Tombol Decompile Semua Skrip Terkait Remote
DecompileAllButton.Name = "DecompileAllButton"
DecompileAllButton.Parent = OverpowerFeaturesScroll
DecompileAllButton.BackgroundColor3 = colorSettings["MainButtons"]["BackgroundColor"]
DecompileAllButton.BorderColor3 = colorSettings["MainButtons"]["BorderColor"]
DecompileAllButton.Position = UDim2.new(0.05, 0, 0, currentOverpowerYOffset)
DecompileAllButton.Size = UDim2.new(0.9, 0, 0, 25)
DecompileAllButton.Font = Enum.Font.SourceSans
DecompileAllButton.TextColor3 = colorSettings["MainButtons"]["TextColor"]
DecompileAllButton.TextSize = 14.000
DecompileAllButton.Text = "Decompile Skrip Remote (Synapse)"

local decompilingAll = false
DecompileAllButton.MouseButton1Click:Connect(function()
    if not isSynapse() or not syn.request then -- Synapse X (atau exploit dengan API serupa) diperlukan
        ButtonEffect(DecompileAllButton, "Hanya Synapse X!")
        warn("TurtleSpy: Fitur decompile massal membutuhkan Synapse X atau exploit dengan `syn.request` dan `decompile()`.")
        return
    end
    if decompilingAll then
        ButtonEffect(DecompileAllButton, "Sedang Proses...")
        return
    end

    decompilingAll = true
    ButtonEffect(DecompileAllButton, "Mendecompile...")
    DecompileOutputText.Text = "Mulai mendecompile...\n\n"
    DecompileOutputFrame.Visible = true

    local uniqueScriptsToDecompile = {}
    for _, scriptInstance in pairs(remoteScripts) do
        if scriptInstance and not table.find(uniqueScriptsToDecompile, scriptInstance) then
            table.insert(uniqueScriptsToDecompile, scriptInstance)
        end
    end

    if #uniqueScriptsToDecompile == 0 then
        ButtonEffect(DecompileAllButton, "Tidak Ada Skrip")
        DecompileOutputText.Text = DecompileOutputText.Text .. "Tidak ada skrip remote yang tercatat untuk didecompile.\n"
        warn("TurtleSpy: Tidak ada skrip remote yang tercatat untuk didecompile.")
        decompilingAll = false
        return
    end

    spawn(function()
        local totalDecompiled = 0
        for i, scriptInstance in ipairs(uniqueScriptsToDecompile) do
            DecompileOutputText.Text = DecompileOutputText.Text .. "Mencoba mendecompile: " .. GetFullPathOfAnInstance(scriptInstance) .. "\n"
            local success, result = pcall(decompile, scriptInstance) -- Fungsi decompile() dari Synapse

            if success and type(result) == "string" then
                DecompileOutputText.Text = DecompileOutputText.Text .. "-- Path: " .. GetFullPathOfAnInstance(scriptInstance) .. "\n"
                DecompileOutputText.Text = DecompileOutputText.Text .. result .. "\n\n--------------------------------------------------\n\n"
                totalDecompiled = totalDecompiled + 1
            else
                DecompileOutputText.Text = DecompileOutputText.Text .. "Gagal mendecompile: " .. GetFullPathOfAnInstance(scriptInstance) .. (result and (": " .. tostring(result)) or "") .. "\n\n"
                warn("TurtleSpy: Gagal mendecompile " .. GetFullPathOfAnInstance(scriptInstance) .. (result and (": " .. tostring(result)) or ""))
            end
            DecompileAllButton.Text = "Mendecompile ("..totalDecompiled.."/"..#uniqueScriptsToDecompile..")"
            wait(0.1) -- Beri jeda kecil
            if not decompilingAll then break end
        end

        DecompileOutputText.Text = DecompileOutputText.Text .. "\nProses decompile selesai. Total " .. totalDecompiled .. " skrip berhasil didecompile.\n"
        ButtonEffect(DecompileAllButton, "Selesai ("..totalDecompiled..")")
        local textSize = TextService:GetTextSize(DecompileOutputText.Text, DecompileOutputText.TextSize, DecompileOutputText.Font, Vector2.new(DecompileOutputScroll.AbsoluteSize.X - 20, math.huge))
        DecompileOutputScroll.CanvasSize = UDim2.new(0, textSize.X + 20 , 0, textSize.Y + 20) -- Lebar X juga disesuaikan
        decompilingAll = false
    end)
end)
currentOverpowerYOffset = currentOverpowerYOffset + 35

-- Tombol Pelacakan Sumber (Placeholder)
SourceTrackerButton.Name = "SourceTrackerButton"
SourceTrackerButton.Parent = OverpowerFeaturesScroll
SourceTrackerButton.BackgroundColor3 = colorSettings["MainButtons"]["BackgroundColor"]
SourceTrackerButton.BorderColor3 = colorSettings["MainButtons"]["BorderColor"]
SourceTrackerButton.Position = UDim2.new(0.05, 0, 0, currentOverpowerYOffset)
SourceTrackerButton.Size = UDim2.new(0.9, 0, 0, 25)
SourceTrackerButton.Font = Enum.Font.SourceSans
SourceTrackerButton.TextColor3 = colorSettings["MainButtons"]["TextColor"]
SourceTrackerButton.TextSize = 14.000
SourceTrackerButton.Text = "Pelacakan Sumber Remote (Segera)"
SourceTrackerButton.MouseButton1Click:Connect(function()
    ButtonEffect(SourceTrackerButton, "Segera Hadir!")
    warn("TurtleSpy: Fitur Pelacakan Sumber Remote belum diimplementasikan sepenuhnya.")
    -- Di sini Anda bisa menambahkan logika untuk:
    -- 1. Mencoba mengidentifikasi dari skrip mana remote pertama kali di-cache atau diakses.
    -- 2. Menganalisis stack panggilan (jika memungkinkan dan didukung exploit).
end)
currentOverpowerYOffset = currentOverpowerYOffset + 35


-- Atur CanvasSize untuk OverpowerFeaturesScroll
OverpowerFeaturesScroll.CanvasSize = UDim2.new(0, 0, 0, currentOverpowerYOffset + 10)


local function FindRemote(remote, args)
    local currentId = (get_thread_context or syn.get_thread_identity)()
    ;(set_thread_context or syn.set_thread_identity)(7)
    local i
    if table.find(unstacked, remote) then
    local numOfRemotes = 0
        for b, v in pairs(remotes) do
            if v == remote then
                numOfRemotes = numOfRemotes + 1
                for i2, v2 in pairs(remoteArgs) do
                    if remoteArgs[b] and args and table.pack(table.unpack(remoteArgs[b])) == table.pack(table.unpack(args)) then -- Perbandingan tabel yang lebih aman
                        i = b
                        break -- Keluar dari loop inner jika sudah ditemukan
                    end
                end
            end
            if i then break end -- Keluar dari loop outer jika sudah ditemukan
        end
    else
        i = table.find(remotes, remote)
    end
    ;(set_thread_context or syn.set_thread_identity)(currentId)
    return i
end

-- creates a simple color and text change effect
local function ButtonEffect(textlabel, text)
    if not textlabel then return end -- Pemeriksaan tambahan
    if not text then
        text = "Copied!"
    end
    local orgText = textlabel.Text
    local orgColor = textlabel.TextColor3
    textlabel.Text = text
    textlabel.TextColor3 = Color3.fromRGB(76, 209, 55)
    wait(0.8)
    textlabel.Text = orgText
    textlabel.TextColor3 = orgColor
end

-- important values for later
local lookingAt
local lookingAtArgs
local lookingAtButton

CopyCode.MouseButton1Click:Connect(function()
    if not lookingAt then return end
    setclipboard(CodeComment.Text.. "\n\n"..Code.Text)
    ButtonEffect(CopyCode)
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
        if success then
            ButtonEffect(RunCode, "Executed!")
        else
            ButtonEffect(RunCode, "Error!")
            warn("TurtleSpy: Error executing remote:", err)
        end
    end
end)
CopyScriptPath.MouseButton1Click:Connect(function()
    local remoteIndex = FindRemote(lookingAt, lookingAtArgs)
    if remoteIndex and remoteScripts[remoteIndex] then
        setclipboard(GetFullPathOfAnInstance(remoteScripts[remoteIndex]))
        ButtonEffect(CopyScriptPath)
    else
        ButtonEffect(CopyScriptPath, "Script N/A")
    end
end)

local decompiling
CopyDecompiled.MouseButton1Click:Connect(function()
    local remoteIndex = FindRemote(lookingAt, lookingAtArgs)
    if not isSynapse() or not syn.request then
        ButtonEffect(CopyDecompiled, "Hanya Synapse X!")
        return
    end
    if not remoteIndex or not remoteScripts[remoteIndex] then
        ButtonEffect(CopyDecompiled, "Script N/A")
        return
    end

    if not decompiling then
        decompiling = true
        local originalText = CopyDecompiled.Text
        spawn(function()
            local dots = ""
            while decompiling do
                dots = dots == "..." and "." or dots .. "."
                CopyDecompiled.Text = "Decompiling" .. dots
                wait(0.5)
            end
        end)

        local success, result = pcall(decompile, remoteScripts[remoteIndex])
        decompiling = false
        if success and type(result) == "string" then
            setclipboard(result)
            ButtonEffect(CopyDecompiled, "Decompiled & Copied!")
        else
            warn("TurtleSpy: Decompilation error for " .. remoteScripts[remoteIndex].Name .. ": " .. tostring(result))
            ButtonEffect(CopyDecompiled, "Decompile Error!")
        end
        wait(1.6)
        CopyDecompiled.Text = originalText
        CopyDecompiled.TextColor3 = Color3.fromRGB(250, 251, 255)
    end
end)

BlockRemote.MouseButton1Click:Connect(function()
    local bRemote = table.find(BlockList, lookingAt)
    if lookingAt and not bRemote then
        table.insert(BlockList, lookingAt)
        BlockRemote.Text = "Unblock remote"
        BlockRemote.TextColor3 = Color3.fromRGB(251, 197, 49)
        if lookingAtButton then lookingAtButton.Parent.RemoteName.TextColor3 = Color3.fromRGB(225, 177, 44) end
    elseif lookingAt and bRemote then
        table.remove(BlockList, bRemote)
        BlockRemote.Text = "Block remote from firing"
        BlockRemote.TextColor3 = Color3.fromRGB(250, 251, 255)
        if lookingAtButton then lookingAtButton.Parent.RemoteName.TextColor3 = colorSettings["RemoteButtons"]["TextColor"] end
    end
end)

IgnoreRemote.MouseButton1Click:Connect(function()
    local iRemote = table.find(IgnoreList, lookingAt)
    if lookingAt and not iRemote then
        table.insert(IgnoreList, lookingAt)
        IgnoreRemote.Text = "Stop ignoring remote"
        IgnoreRemote.TextColor3 = Color3.fromRGB(127, 143, 166)
        if lookingAtButton then lookingAtButton.Parent.RemoteName.TextColor3 = Color3.fromRGB(127, 143, 166) end
    elseif lookingAt and iRemote then
        table.remove(IgnoreList, iRemote)
        IgnoreRemote.Text = "Ignore remote"
        IgnoreRemote.TextColor3 = Color3.fromRGB(250, 251, 255)
        if lookingAtButton then lookingAtButton.Parent.RemoteName.TextColor3 = colorSettings["RemoteButtons"]["TextColor"] end
    end
end)

WhileLoop.MouseButton1Click:Connect(function()
    if not lookingAt then return end
    setclipboard("while task.wait() do\n   "..Code.Text.."\nend") -- Menggunakan task.wait()
    ButtonEffect(WhileLoop)
end)

Clear.MouseButton1Click:Connect(function()
    for i, v in pairs(RemoteScrollFrame:GetChildren()) do
        if v.Name == "RemoteButtonTemplateInstance" then -- Hanya hapus instance tombol remote
            v:Destroy()
        end
    end
    for i, v in pairs(connections) do
        v:Disconnect()
    end
    buttonOffset = 10 -- Reset ke offset awal
    scrollSizeOffset = 287 -- Reset ke ukuran canvas awal
    remotes = {}
    remoteArgs = {}
    remoteButtons = {}
    remoteScripts = {}
    IgnoreList = {}
    BlockList = {}
    unstacked = {}
    connections = {}
    RemoteScrollFrame.CanvasSize = UDim2.new(0, 0, 0, scrollSizeOffset)
    ButtonEffect(Clear, "Cleared!")
end)

DoNotStack.MouseButton1Click:Connect(function()
    if lookingAt then
        local isUnstacked = table.find(unstacked, lookingAt)
        if isUnstacked then
            table.remove(unstacked, isUnstacked)
            DoNotStack.Text = "Unstack remote when fired with new args"
            DoNotStack.TextColor3 = Color3.fromRGB(245, 246, 250)
        else
            table.insert(unstacked, lookingAt)
            DoNotStack.Text = "Stack remote"
            DoNotStack.TextColor3 = Color3.fromRGB(251, 197, 49)
        end
    end
end)

local function len(t)
    local n = 0
    for _ in pairs(t) do
        n = n + 1
    end
    return n
end

local function convertTableToString(argsTable, indentationLevel)
    indentationLevel = indentationLevel or 1
    local indent = string.rep("    ", indentationLevel)
    local nextIndent = string.rep("    ", indentationLevel + 1)
    local entries = {}
    local isArray = true
    local maxNumericKey = 0

    for k, _ in pairs(argsTable) do
        if type(k) ~= "number" or k < 1 or math.floor(k) ~= k then
            isArray = false
        end
        if type(k) == "number" and k > maxNumericKey then
            maxNumericKey = k
        end
    end
    if #argsTable ~= maxNumericKey then isArray = false end


    for k, v in pairs(argsTable) do
        local keyStr
        if type(k) == "string" and k:match("^[%a_][%w_]*$") then
            keyStr = k .. " = "
        else
            keyStr = "[" .. (type(k) == "string" and '"'..k..'"' or tostring(k)) .. "] = "
        end
        if isArray then keyStr = "" end -- Jangan tampilkan key untuk array

        local valueStr
        if v == nil then
            valueStr = "nil"
        elseif typeof(v) == "Instance" then
            valueStr = GetFullPathOfAnInstance(v)
        elseif type(v) == "number" or type(v) == "function" or type(v) == "boolean" then
            valueStr = tostring(v)
        elseif type(v) == "string" then
            valueStr = string.format("%q", v)
        elseif type(v) == "table" then
            valueStr = "{\n" .. convertTableToString(v, indentationLevel + 1) .. "\n" .. indent .. "}"
        elseif type(v) == "userdata" then
             valueStr = typeof(v)..".new("..tostring(v)..") -- Userdata tidak bisa selalu direpresentasikan dengan baik
        else
            valueStr = tostring(v) -- Fallback
        end
        table.insert(entries, (not isArray and indent or nextIndent) .. keyStr .. valueStr)
    end

    if isArray then
        return table.concat(entries, ",\n")
    else
        return "\n" .. table.concat(entries, ",\n")
    end
end


CopyReturn.MouseButton1Click:Connect(function()
    local remoteIndex = FindRemote(lookingAt, lookingAtArgs)
    if lookingAt and remoteIndex and remoteArgs[remoteIndex] then
        if isA(lookingAt, "RemoteFunction") then
            local success, resultPack = pcall(function() return table.pack(remotes[remoteIndex]:InvokeServer(unpack(remoteArgs[remoteIndex]))) end)
            if success then
                local resultString = convertTableToString(resultPack)
                if resultPack.n == 1 then resultString = convertTableToString({resultPack[1]}) end -- Jika hanya satu hasil
                setclipboard(resultString)
                ButtonEffect(CopyReturn)
            else
                ButtonEffect(CopyReturn, "Error!")
                warn("TurtleSpy: Error invoking and copying return:", resultPack)
            end
        else
            ButtonEffect(CopyReturn, "Not a Func!")
        end
    else
         ButtonEffect(CopyReturn, "N/A")
    end
end)

RemoteScrollFrame.ChildAdded:Connect(function(child)
    if child.Name ~= "RemoteButtonTemplateInstance" then return end -- Hanya proses instance tombol

    local remoteIndex = child.LayoutOrder -- Menggunakan LayoutOrder untuk menyimpan indeks sementara
    if not remoteIndex or not remotes[remoteIndex] then return end

    local remote = remotes[remoteIndex]
    local args = remoteArgs[remoteIndex]
    local isRemoteEvent = isA(remote, "RemoteEvent")
    local fireFunction = isRemoteEvent and ":FireServer(" or ":InvokeServer("

    local connection = child.MouseButton1Click:Connect(function()
        InfoHeaderText.Text = "Info: " .. remote.Name
        if isRemoteEvent then
            InfoButtonsScroll.CanvasSize = UDim2.new(0, 0, 1, 0) -- Ukuran default
            CopyReturn.Visible = false -- Sembunyikan tombol copy return untuk RemoteEvent
        else
            InfoButtonsScroll.CanvasSize = UDim2.new(0, 0, 1.15, 0) -- Lebih banyak ruang untuk tombol RF
            CopyReturn.Visible = true -- Tampilkan tombol copy return
        end

        if not InfoFrame.Visible then
            mainFrame.Size = UDim2.new(0, 207 + InfoFrame.Size.X.Offset + FrameDivider.Size.X.Offset, 0, mainFrame.Size.Y.Offset)
            OpenInfoFrame.Text = "<"
        end
        InfoFrame.Visible = true

        Code.Text = GetFullPathOfAnInstance(remote) .. fireFunction .. convertTableToString(args, 0) .. ")"
        local textSize = TextService:GetTextSize(Code.Text, Code.TextSize, Code.Font, Vector2.new(math.huge, Code.AbsoluteSize.Y))
        CodeFrame.CanvasSize = UDim2.new(0, textSize.X + 20, 0, textSize.Y + 10)

        lookingAt = remote
        lookingAtArgs = args
        lookingAtButton = child.Number

        local blocked = table.find(BlockList, remote)
        BlockRemote.Text = blocked and "Unblock remote" or "Block remote from firing"
        BlockRemote.TextColor3 = blocked and Color3.fromRGB(251, 197, 49) or colorSettings["MainButtons"]["TextColor"]

        local ignored = table.find(IgnoreList, remote)
        IgnoreRemote.Text = ignored and "Stop ignoring remote" or "Ignore remote"
        IgnoreRemote.TextColor3 = ignored and Color3.fromRGB(127, 143, 166) or colorSettings["MainButtons"]["TextColor"]

        local isUnstacked = table.find(unstacked, remote)
        DoNotStack.Text = isUnstacked and "Stack remote" or "Unstack remote when fired with new args"
        DoNotStack.TextColor3 = isUnstacked and Color3.fromRGB(251, 197, 49) or colorSettings["MainButtons"]["TextColor"]

        InfoFrameOpen = true
    end)
    table.insert(connections, connection)
end)


function addToList(event, remote, ...)
    local currentId = (get_thread_context or syn.get_thread_identity)()
    ;(set_thread_context or syn.set_thread_identity)(7)
    if not remote or typeof(remote) ~= "Instance" then -- Pemeriksaan tambahan
        ;(set_thread_context or syn.set_thread_identity)(currentId)
        return
    end

    local name = remote.Name
    local args = {...}
    local i = FindRemote(remote, args)

    if not i then
        table.insert(remotes, remote)
        local currentRemoteIndex = #remotes -- Indeks dari remote yang baru ditambahkan

        local rButtonInstance = clone(RemoteButton)
        rButtonInstance.Name = "RemoteButtonTemplateInstance" -- Nama unik untuk instance
        rButtonInstance.LayoutOrder = currentRemoteIndex -- Simpan indeks untuk referensi di ChildAdded

        remoteButtons[currentRemoteIndex] = rButtonInstance.Number
        remoteArgs[currentRemoteIndex] = args
        remoteScripts[currentRemoteIndex] = (isSynapse() and getcallingscript and getcallingscript() or rawget(getfenv(0), "script"))

        rButtonInstance.Parent = RemoteScrollFrame
        rButtonInstance.Visible = true
        if name then rButtonInstance.RemoteName.Text = name end
        if not event then rButtonInstance.RemoteIcon.Image = functionImage else rButtonInstance.RemoteIcon.Image = eventImage end

        buttonOffset = buttonOffset + 35
        rButtonInstance.Position = UDim2.new(0.0912411734, 0, 0, buttonOffset) -- Posisi berdasarkan offset

        -- Update nomor dan posisi nama remote
        rButtonInstance.Number.Text = "1"
        local numberTextsize = TextService:GetTextSize(rButtonInstance.Number.Text, rButtonInstance.Number.TextSize, rButtonInstance.Number.Font, Vector2.new(math.huge, math.huge))
        rButtonInstance.RemoteName.Position = UDim2.new(0, numberTextsize.X + 10, 0, 0)
        rButtonInstance.RemoteName.Size = UDim2.new(0, rButtonInstance.AbsoluteSize.X - (numberTextsize.X + 10) - rButtonInstance.RemoteIcon.AbsoluteSize.X - 10, 1, 0)


        if #remotes > 8 then -- Lebih dari 8 remote, perbesar scroll frame
            scrollSizeOffset = buttonOffset + 45 -- Disesuaikan dengan offset tombol terakhir
            RemoteScrollFrame.CanvasSize = UDim2.new(0, 0, 0, scrollSizeOffset)
        end
    else
        remoteButtons[i].Text = tostring(tonumber(remoteButtons[i].Text) + 1)
        local numberTextsize = TextService:GetTextSize(remoteButtons[i].Text, remoteButtons[i].TextSize, remoteButtons[i].Font, Vector2.new(math.huge, math.huge))
        local parentButton = remoteButtons[i].Parent
        parentButton.RemoteName.Position = UDim2.new(0, numberTextsize.X + 10, 0, 0)
        parentButton.RemoteName.Size = UDim2.new(0, parentButton.AbsoluteSize.X - (numberTextsize.X + 10) - parentButton.RemoteIcon.AbsoluteSize.X - 10, 1, 0)

        remoteArgs[i] = args

        if lookingAt and lookingAt == remote and lookingAtButton == remoteButtons[i] and InfoFrame.Visible then
            local fireFunction = isA(remote, "RemoteEvent") and ":FireServer(" or ":InvokeServer("
            Code.Text = GetFullPathOfAnInstance(remote) .. fireFunction .. convertTableToString(remoteArgs[i],0) .. ")"
            local textSize = TextService:GetTextSize(Code.Text, Code.TextSize, Code.Font, Vector2.new(math.huge, Code.AbsoluteSize.Y))
            CodeFrame.CanvasSize = UDim2.new(0, textSize.X + 20, 0, textSize.Y + 10)
        end
    end
    ;(set_thread_context or syn.set_thread_identity)(currentId)
end


local OldEvent
OldEvent = hookfunction(Instance.new("RemoteEvent").FireServer, function(Self, ...)
    if not checkcaller() and table.find(BlockList, Self) then
        return
    elseif table.find(IgnoreList, Self) then
        return OldEvent(Self, ...)
    end
    addToList(true, Self, ...)
    return OldEvent(Self, ...) -- Panggil fungsi asli setelah logging
end)

local OldFunction
OldFunction = hookfunction(Instance.new("RemoteFunction").InvokeServer, function(Self, ...)
    if not checkcaller() and table.find(BlockList, Self) then
        return nil -- RemoteFunction harus me-return sesuatu, bahkan jika diblokir
    elseif table.find(IgnoreList, Self) then
        return OldFunction(Self, ...)
    end
    addToList(false, Self, ...)
    return OldFunction(Self, ...) -- Panggil fungsi asli setelah logging
end)

local OldNamecall
OldNamecall = hookmetamethod(game,"__namecall",function(...)
    local argsNC = {...}
    local Self = argsNC[1]
    local method = (getnamecallmethod or get_namecall_method)()
    if method == "FireServer" and isA(Self, "RemoteEvent")  then
        if not checkcaller() and table.find(BlockList, Self) then
            return
        elseif table.find(IgnoreList, Self) then
            return OldNamecall(...)
        end
        addToList(true, unpack(argsNC)) -- unpack argsNC
    elseif method == "InvokeServer" and isA(Self, 'RemoteFunction') then
        if not checkcaller() and table.find(BlockList, Self) then
            return nil
        elseif table.find(IgnoreList, Self) then
            return OldNamecall(...)
        end
        addToList(false, unpack(argsNC)) -- unpack argsNC
    end

    return OldNamecall(...)
end)

-- Inisialisasi tinggi mainFrame saat pertama kali dijalankan
if RemoteScrollFrame.Visible then
    if InfoFrameOpen then
        mainFrame.Size = UDim2.new(0, 207 + InfoFrame.Size.X.Offset + FrameDivider.Size.X.Offset, 0, 321)
    else
        mainFrame.Size = UDim2.new(0, 207, 0, 321)
    end
else
    mainFrame.Size = UDim2.new(0, 207, 0, 35) -- Hanya header
end

print("TurtleSpy V1.5.3 (Overpowered by Partner Coding) Loaded!")
