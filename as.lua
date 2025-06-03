-- Enhanced Roblox Dex Explorer Script
-- Version: 4.0.0
-- Optimized for external executor with advanced features and bug fixes

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

-- Constants
local VERSION = "4.0.0"
local PERFORMANCE_MODE = true
local DEBUG_MODE = false
local GUI_OBJECTS = {}
local CONNECTIONS = {}

-- Utility Functions
local function safeCall(func, ...)
    local success, result = pcall(func, ...)
    if not success then
        warn("Error:", result)
        if DEBUG_MODE then debug.traceback() end
        return nil
    end
    return result
end

local function optimizeGuiObject(obj)
    if PERFORMANCE_MODE then
        obj.Archivable = false
        obj.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        table.insert(GUI_OBJECTS, obj)
    end
end

local function cleanUpGui(gui)
    if gui and gui:IsA("GuiObject") then
        gui:Destroy()
        GUI_OBJECTS[gui] = nil
    end
end

local function connectEvent(event, callback)
    local conn = event:Connect(callback)
    table.insert(CONNECTIONS, conn)
    return conn
end

local function cleanUpConnections()
    for _, conn in pairs(CONNECTIONS) do
        if conn and conn.Disconnect then conn:Disconnect() end
    end
    CONNECTIONS = {}
end

-- GUI Creation
local function createTextButton(parent, name, text, position, size, callback)
    local button = Instance.new("TextButton")
    button.Name = name
    button.Text = text
    button.Position = position
    button.Size = size
    button.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
    button.Font = Enum.Font.SourceSans
    button.TextSize = 14
    button.Parent = parent
    optimizeGuiObject(button)
    if callback then
        connectEvent(button.MouseButton1Click, callback)
    end
    return button
end

-- Enhanced Property Viewer
local function createPropertyViewer(parent, selection)
    local frame = Instance.new("ScrollingFrame")
    frame.Name = "PropertyViewer"
    frame.Size = UDim2.new(1, 0, 1, -40)
    frame.Position = UDim2.new(0, 0, 0, 40)
    frame.BackgroundTransparency = 0.1
    frame.CanvasSize = UDim2.new(0, 0, 0, 0)
    frame.Parent = parent

    local function updateProperties()
        for _, child in pairs(frame:GetChildren()) do
            child:Destroy()
        end
        if not selection or #selection == 0 then return end
        
        local obj = selection[1]
        local properties = {}
        for _, prop in pairs(obj:GetProperties()) do
            table.insert(properties, prop)
        end
        table.sort(properties)

        local yOffset = 0
        for i, prop in ipairs(properties) do
            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(0.5, 0, 0, 20)
            label.Position = UDim2.new(0, 5, 0, yOffset)
            label.Text = prop
            label.Parent = frame

            local valueBox = Instance.new("TextBox")
            valueBox.Size = UDim2.new(0.5, -10, 0, 20)
            valueBox.Position = UDim2.new(0.5, 5, 0, yOffset)
            valueBox.Text = tostring(safeCall(function() return obj[prop] end) or "N/A")
            valueBox.Parent = frame

            yOffset = yOffset + 25
        end
        frame.CanvasSize = UDim2.new(0, 0, 0, yOffset)
    end

    connectEvent(Players.LocalPlayer:GetPropertyChangedSignal("Selection"), updateProperties)
    updateProperties()
    return frame
end

-- Enhanced Script Editor with Syntax Highlighting
local function createScriptEditor(parent)
    local editor = Instance.new("Frame")
    editor.Name = "ScriptEditor"
    editor.Size = UDim2.new(1, 0, 1, -40)
    editor.Position = UDim2.new(0, 0, 0, 40)
    editor.BackgroundTransparency = 0.1
    editor.Parent = parent

    local codeBox = Instance.new("TextBox")
    codeBox.Name = "CodeBox"
    codeBox.Size = UDim2.new(1, -20, 1, -20)
    codeBox.Position = UDim2.new(0, 10, 0, 10)
    codeBox.MultiLine = true
    codeBox.ClearTextOnFocus = false
    codeBox.TextWrapped = true
    codeBox.Font = Enum.Font.Code
    codeBox.TextSize = 14
    codeBox.Parent = editor

    local keywords = {"local", "function", "if", "then", "else", "end", "for", "while", "do", "return"}
    local function highlightSyntax()
        local text = codeBox.Text
        local highlighted = ""
        for line in text:gmatch("[^\n]+") do
            for _, kw in pairs(keywords) do
                line = line:gsub("(%f[%w]" .. kw .. "%f[^%w])", "<font color='rgb(0,0,255)'>" .. kw .. "</font>")
            end
            highlighted = highlighted .. line .. "\n"
        end
        codeBox.Text = highlighted
    end

    connectEvent(codeBox:GetPropertyChangedSignal("Text"), highlightSyntax)
    return editor
end

-- Main GUI Setup
local function createGui()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "DexExplorer"
    screenGui.ResetOnSpawn = false
    optimizeGuiObject(screenGui)

    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 600, 0, 400)
    mainFrame.Position = UDim2.new(0.5, -300, 0.5, -200)
    mainFrame.BackgroundTransparency = 0.1
    mainFrame.Parent = screenGui

    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, -40, 0, 30)
    title.Position = UDim2.new(0, 20, 0, 10)
    title.Text = "Dex Explorer v" .. VERSION
    title.Font = Enum.Font.SourceSansBold
    title.TextSize = 20
    title.BackgroundTransparency = 1
    title.Parent = mainFrame

    local closeButton = createTextButton(mainFrame, "Close", "X", UDim2.new(1, -30, 0, 10), UDim2.new(0, 20, 0, 20), function()
        cleanUpGui(screenGui)
        cleanUpConnections()
    end)

    local tabFrame = Instance.new("Frame")
    tabFrame.Name = "TabFrame"
    tabFrame.Size = UDim2.new(1, 0, 0, 30)
    tabFrame.Position = UDim2.new(0, 0, 0, 40)
    tabFrame.BackgroundTransparency = 0.2
    tabFrame.Parent = mainFrame

    local propertyTab = createTextButton(tabFrame, "PropertyTab", "Properties", UDim2.new(0, 10, 0, 5), UDim2.new(0, 100, 0, 20))
    local scriptTab = createTextButton(tabFrame, "ScriptTab", "Scripts", UDim2.new(0, 120, 0, 5), UDim2.new(0, 100, 0, 20))

    local contentFrame = Instance.new("Frame")
    contentFrame.Name = "ContentFrame"
    contentFrame.Size = UDim2.new(1, 0, 1, -70)
    contentFrame.Position = UDim2.new(0, 0, 0, 70)
    contentFrame.BackgroundTransparency = 1
    contentFrame.Parent = mainFrame

    local propertyViewer = createPropertyViewer(contentFrame, {game.Workspace})
    local scriptEditor = createScriptEditor(contentFrame)
    scriptEditor.Visible = false

    connectEvent(propertyTab.MouseButton1Click, function()
        propertyViewer.Visible = true
        scriptEditor.Visible = false
    end)

    connectEvent(scriptTab.MouseButton1Click, function()
        propertyViewer.Visible = false
        scriptEditor.Visible = true
        local selection = game:GetService("Selection"):Get()
        if #selection > 0 then
            local obj = selection[1]
            if obj:IsA("Script") or obj:IsA("LocalScript") then
                codeBox.Text = safeCall(function() return decompile(obj) end) or "-- Decompilation failed"
            end
        end
    end)

    screenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
    return screenGui
end

-- Initialization
local gui = createGui()

-- Performance Optimization
RunService.RenderStepped:Connect(function()
    if PERFORMANCE_MODE then
        for _, obj in pairs(GUI_OBJECTS) do
            if obj.Parent == nil then
                GUI_OBJECTS[obj] = nil
            end
        end
    end
end)

-- Selection Handling
connectEvent(game:GetService("Selection").SelectionChanged, function()
    local selection = game:GetService("Selection"):Get()
    if #selection > 0 and gui then
        gui.MainFrame.ContentFrame.PropertyViewer:UpdateProperties()
    end
end)

print("Dex Explorer v" .. VERSION .. " loaded successfully!")
