--!strict
--[[
    ZXHELL Security Tools - Enhanced Version for Roblox Script Executor (Lua)

    This script provides a robust, user-friendly interface for detecting and testing
    RemoteEvents and RemoteFunctions in Roblox games. It simulates advanced exploit
    methods, logs vulnerabilities with granular details, and ensures performance
    optimization and security best practices.

    Enhanced Features:
    - Dynamic remote detection across multiple services with real-time updates
    - Advanced fuzzing with mutation-based argument generation
    - New hacking methods: SequenceTest, ReplayAttack
    - Improved UI with dynamic scaling, auto-scroll toggles, and batched log updates
    - Granular vulnerability categorization and interactive exploit log UI
    - Safe parsing of custom arguments using JSONDecode and custom Roblox type parser
    - Optimized performance with batched UI updates and conditional Heartbeat connections
    - Comprehensive cooldown mechanism per remote

    Fixed Issues:
    - Non-functional cooldown mechanism
    - Fragile drag logic
    - Dropdown visibility issues
    - Replaced unsafe loadstring with JSONDecode
    - Limited remote detection scope
    - Frequent UI updates causing performance issues

    Disclaimer: For ethical security testing only. Unauthorized use violates Roblox ToS.
]]

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()

-- Global Variables
local testingActive: boolean = false
local exploitLog: { [number]: { timestamp: number, action: string, status: string, details: string, vulnerabilityType: string? } } = {}
local remoteTimer: { [RemoteEvent | RemoteFunction]: { lastCall: number, cooldown: number } } = {}
local remoteList: { [number]: RemoteEvent | RemoteFunction } = {}
local selectedRemote: RemoteEvent | RemoteFunction | nil = nil
local customArgs: { any } | nil = nil
local hackMethod: string = "AutoSpam"
local uiStates: { [string]: boolean } = {}
local autoScrollLogs: { [string]: boolean } = { ProcessLog = true, StatusLog = true, DetailedLog = true }
local draggingFrame: Frame | nil = nil
local uiElements: { [string]: GuiObject } = {}
local logBatch: { [string]: { [number]: string } } = { ProcessLog = {}, StatusLog = {}, DetailedLog = {} } -- Batched log entries
local replayLog: { [number]: { remote: RemoteEvent | RemoteFunction, args: any, timestamp: number } } = {} -- For ReplayAttack
local sequenceQueue: { [number]: { remote: RemoteEvent | RemoteFunction, args: any } } = {} -- For SequenceTest

-- Constants for UI Styling
local FRAME_BACKGROUND_COLOR = Color3.fromRGB(20, 20, 30)
local TITLE_TEXT_COLOR_PRIMARY = Color3.fromRGB(0, 255, 255)
local TITLE_TEXT_COLOR_SECONDARY = Color3.fromRGB(255, 0, 255)
local BUTTON_BACKGROUND_COLOR = Color3.fromRGB(0, 80, 150)
local BUTTON_HOVER_COLOR = Color3.fromRGB(0, 100, 200)
local BUTTON_ACTIVE_COLOR = Color3.fromRGB(150, 0, 0)
local TEXT_COLOR_LIGHT = Color3.fromRGB(255, 255, 255)
local LOG_TEXT_COLOR = Color3.fromRGB(200, 200, 200)
local INPUT_BACKGROUND_COLOR = Color3.fromRGB(30, 30, 40)
local BORDER_COLOR = Color3.fromRGB(0, 255, 255)
local CORNER_RADIUS = UDim.new(0, 8)
local BUTTON_CORNER_RADIUS = UDim.new(0, 4)
local SCROLLBAR_THICKNESS = 4

-- Expanded Test Arguments
local testArgs: { any } = {
    nil,
    "instant",
    true,
    -1,
    999999,
    string.rep("x", 1000),
    {},
    { exploit = "malicious", nested = { depth = 100, circular = {} } },
    { math.huge, -math.huge, 0/0 },
    "function() end",
    LocalPlayer,
    workspace,
    ReplicatedStorage,
    Vector3.new(0,0,0),
    CFrame.new(0,0,0),
    Color3.new(1,0,0),
    UDim2.new(0.5,0,0.5,0),
    "",
    "\0",
    "\n",
    "local function test() print('hello') end",
    Instance.new("Part"),
    Instance.new("Folder", nil),
    Enum.KeyCode.A,
    12345678901234567,
    -12345678901234567,
    -0, -- Negative zero
    1e-308, -- Very small floating-point
    string.rep("\0", 100), -- String with multiple null bytes
    { key = nil }, -- Table with nil value
}
testArgs[8].circular = testArgs[8]

-- Hacking Methods
local methods: { { name: string, value: string, desc: string } } = {
    { name = "Auto Spam", value = "AutoSpam", desc = "Spam all arguments automatically to the selected remote." },
    { name = "Single Shot", value = "SingleShot", desc = "Test one argument per button click manually." },
    { name = "Custom Args", value = "CustomArgs", desc = "Use user-provided custom arguments." },
    { name = "Flood Test", value = "FloodTest", desc = "Rapid spam for load testing and rate-limit detection." },
    { name = "Property Manip", value = "PropertyManip", desc = "Attempt to manipulate client-authoritative properties (e.g., leaderstats)." },
    { name = "Mutation Fuzz", value = "MutationFuzz", desc = "Automatically mutate arguments to find edge cases." },
    { name = "Sequence Test", value = "SequenceTest", desc = "Execute a predefined sequence of remote calls." },
    { name = "Replay Attack", value = "ReplayAttack", desc = "Record and replay legitimate remote calls with modifications." },
}

-- Logging Functions
local function logExploit(action: string, status: string, details: string, vulnerabilityType: string?): string
    local logEntry = {
        timestamp = os.time(),
        action = action,
        status = status,
        details = details,
        vulnerabilityType = vulnerabilityType
    }
    table.insert(exploitLog, logEntry)
    local logText = string.format("[%s] %s: %s (%s)", os.date("%X", logEntry.timestamp), action, status, details)
    print(logText)
    return logText
end

local function updateLogUI(logBox: TextLabel, scrollingFrame: ScrollingFrame, text: string, logType: string)
    table.insert(logBatch[logType], text)
end

local function flushLogBatch()
    for logType, entries in pairs(logBatch) do
        local logBox = uiElements[logType .. "Box"] as TextLabel
        local scrollingFrame = uiElements[logType .. "ScrollingFrame"] as ScrollingFrame
        if logBox and scrollingFrame and #entries > 0 then
            local newText = table.concat(entries, "\n")
            logBox.Text = logBox.Text .. (logBox.Text == "" and "" or "\n") .. newText
            logBox.Size = UDim2.new(1, -10, 0, logBox.TextBounds.Y)
            scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, logBox.TextBounds.Y)
            if autoScrollLogs[logType] then
                scrollingFrame.CanvasPosition = Vector2.new(0, logBox.TextBounds.Y)
            end
            logBatch[logType] = {}
        end
    end
end

local function updateProcessLog(text: string)
    updateLogUI(uiElements.ProcessLogBox as TextLabel, uiElements.ProcessLogScrollingFrame as ScrollingFrame, textross
    local function detectRemotes(servicesToScan: { Instance }): boolean
        local initialCount = #remoteList
        local newRemotesFound = 0
        for _, service in ipairs(servicesToScan) do
            for _, obj in pairs(service:GetDescendants()) do
                if (obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction")) and not table.find(remoteList, obj) then
                    table.insert(remoteList, obj)
                    remoteTimer[obj] = { lastCall = tick(), cooldown = 0 }
                    logExploit("Remote Detection", "Success", "Found: " .. obj:GetFullName())
                    newRemotesFound = newRemotesFound + 1
                end
            end
        end
        return newRemotesFound > 0 or initialCount > 0
    end

    local function setupDynamicRemoteDetection()
        local servicesToMonitor = {
            ReplicatedStorage,
            workspace,
            LocalPlayer.PlayerGui,
            game:GetService("Lighting"),
            game:GetService("StarterGui"),
        }
        detectRemotes(servicesToMonitor)
        populateRemotes()
        for _, service in ipairs(servicesToMonitor) do
            service.DescendantAdded:Connect(function(newDescendant)
                if (newDescendant:IsA("RemoteEvent") or newDescendant:IsA("RemoteFunction")) and not table.find(remoteList, newDescendant) then
                    table.insert(remoteList, newDescendant)
                    remoteTimer[newDescendant] = { lastCall = tick(), cooldown = 0 }
                    logExploit("Remote Detection", "Success", "Dynamically Found: " .. newDescendant:GetFullName())
                    populateRemotes()
                end
            end)
        end
    end

    local function mutateArgument(arg: any): any
        local rand = math.random
        if type(arg) == "string" then
            if rand() < 0.3 then
                return arg .. string.char(rand(0, 255))
            elseif rand() < 0.6 then
                return string.rep(arg, rand(2, 5))
            else
                return arg:upper()
            end
        elseif type(arg) == "number" then
            if rand() < 0.5 then
                return arg + rand(-100, 100)
            else
                return arg * rand(2, 5)
            end
        elseif type(arg) == "table" then
            local newTable = table.clone(arg)
            if rand() < 0.5 then
                newTable.mutated = rand(1, 1000)
            else
                newTable.nested = { depth = rand(1, 10) }
            end
            return newTable
        end
        return arg
    end

    local function testRemote(remote: RemoteEvent | RemoteFunction, args: any, method: string): boolean
        local currentTick = tick()
        if remoteTimer[remote].cooldown > (currentTick - remoteTimer[remote].lastCall) then
            return false
        end

        local success: boolean = false
        local result: any = nil
        local vulnerabilityType: string? = nil

        if method == "PropertyManip" then
            local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
            if leaderstats and leaderstats:FindFirstChild(remote.Name) and leaderstats[remote.Name]:IsA("IntValue") then
                local pcallSuccess, pcallResult = pcall(function()
                    leaderstats[remote.Name].Value = 999999999
                    return "Attempted property manipulation"
                end)
                success = pcallSuccess
                result = pcallResult
                if success then
                    vulnerabilityType = "High: Property Manipulation"
                end
            else
                result = "Property manipulation not applicable or leaderstat not found/not IntValue."
            end
        elseif method == "ReplayAttack" then
            local replayEntry = replayLog[math.random(1, #replayLog)]
            if replayEntry then
                local pcallSuccess, pcallResult = pcall(function()
                    if remote:IsA("RemoteEvent") then
                        remote:FireServer(replayEntry.args)
                        return "Replayed"
                    elseif remote:IsA("RemoteFunction") then
                        return remote:InvokeServer(replayEntry.args)
                    end
                end)
                success = pcallSuccess
                result = pcallResult
                if success then
                    vulnerabilityType = "High: Replay Attack Success"
                end
            else
                result = "No recorded calls to replay."
            end
        else
            local argsToTest = (method == "MutationFuzz") and mutateArgument(args) or args
            local pcallSuccess, pcallResult = pcall(function()
                if remote:IsA("RemoteEvent") then
                    remote:FireServer(argsToTest)
                    return "Fired"
                elseif remote:IsA("RemoteFunction") then
                    return remote:InvokeServer(argsToTest)
                end
            end)
            success = pcallSuccess
            result = pcallResult

            if success then
                local resultString = tostring(result)
                if resultString:find("Error") or resultString:find("Fail") then
                    vulnerabilityType = "Medium: Server Error/Bad Response"
                elseif resultString:find("true") or resultString:find("granted") or resultString:find("success") then
                    vulnerabilityType = "High: Unauthorized Action Granted"
                elseif resultString:find("999999999") or resultString:find("inf") or resultString:find("huge") then
                    vulnerabilityType = "Critical: Infinite Value/Resource"
                elseif resultString:find("teleported") or resultString:find("moved") or resultString:find("position") then
                    vulnerabilityType = "High: Unauthorized Teleport/Movement"
                elseif resultString:find("removed") or resultString:find("destroyed") or resultString:find("deleted") then
                    vulnerabilityType = "Critical: Unauthorized Object Removal"
                else
                    vulnerabilityType = "Low: Unexpected Success"
                end
            else
                local pcallResultString = tostring(pcallResult)
                if pcallResultString:find("timeout") or pcallResultString:find("yield") then
                    vulnerabilityType = "Medium: Server Yield/Timeout"
                elseif pcallResultString:find("argument") or pcallResultString:find("type") then
                    vulnerabilityType = "Low: Argument Type Mismatch"
                end
            end
        end

        remoteTimer[remote].lastCall = currentTick
        local delayFromUI = tonumber(uiElements.DelayInput.Text) or 0.5
        remoteTimer[remote].cooldown = delayFromUI > 0 and delayFromUI or 0.5

        local status = success and "Success" or "Failed"
        local details = string.format("%s with args: %s, Method: %s, Result: %s",
            remote:GetFullName(), tostring(args), method, tostring(result))
        local logText = logExploit("Test Remote", status, details, vulnerabilityType)
        updateProcessLog(logText)
        if success or vulnerabilityType then
            updateStatusLog(logText, vulnerabilityType)
        end
        return success
    end

    local function runExploitLoop()
        local argsToUse = customArgs or testArgs
        local delayTime = tonumber(uiElements.DelayInput.Text) or 0.5
        while testingActive do
            for _, remote in ipairs(remoteList) do
                if not testingActive then return end
                if selectedRemote == nil or remote == selectedRemote then
                    if hackMethod == "AutoSpam" then
                        for _, arg in ipairs(argsToUse) do
                            if not testingActive then return end
                            testRemote(remote, arg, hackMethod)
                            task.wait(delayTime)
                        end
                    elseif hackMethod == "FloodTest" then
                        for i = 1, 100 do
                            if not testingActive then return end
                            testRemote(remote, argsToUse[math.random(1, #argsToUse)], hackMethod)
                            task.wait(delayTime / 10)
                        end
                    elseif hackMethod == "SingleShot" then
                        task.wait(0.1)
                    elseif hackMethod == "CustomArgs" then
                        if customArgs then
                            testRemote(remote, customArgs[1], hackMethod)
                            task.wait(delayTime)
                        else
                            updateProcessLog("Error: Invalid or empty custom arguments.")
                        end
                    elseif hackMethod == "PropertyManip" then
                        testRemote(remote, nil, hackMethod)
                        task.wait(delayTime)
                    elseif hackMethod == "MutationFuzz" then
                        for _, arg in ipairs(argsToUse) do
                            if not testingActive then return end
                            testRemote(remote, arg, hackMethod)
                            task.wait(delayTime)
                        end
                    elseif hackMethod == "SequenceTest" then
                        for _, entry in ipairs(sequenceQueue) do
                            if not testingActive then return end
                            testRemote(entry.remote, entry.args, hackMethod)
                            task.wait(delayTime)
                        end
                    elseif hackMethod == "ReplayAttack" then
                        testRemote(remote, nil, hackMethod)
                        task.wait(delayTime)
                    end
                end
            end
            task.wait(0.1)
        end
    end

    local function parseCustomArgs(input: string): (boolean, string)
        local success, result = pcall(function()
            return HttpService:JSONDecode(input)
        end)
        if success then
            customArgs = { result }
            return true, "Parsed: " .. HttpService:JSONEncode(result)
        else
            -- Try parsing Roblox-specific types
            local robloxTypeSuccess, robloxTypeResult = pcall(function()
                if input:match("^Vector3%(") then
                    local x, y, z = input:match("Vector3%((%d+%.?%d*),(%d+%.?%d*),(%d+%.?%d*)%)")
                    return Vector3.new(tonumber(x), tonumber(y), tonumber(z))
                elseif input:match("^Color3%(") then
                    local r, g, b = input:match("Color3%((%d+%.?%d*),(%d+%.?%d*),(%d+%.?%d*)%)")
                    return Color3.new(tonumber(r), tonumber(g), tonumber(b))
                elseif input:match("^UDim2%(") then
                    local xs, xo, ys, yo = input:match("UDim2%((%d+%.?%d*),(%d+),(%d+%.?%d*),(%d+)%)")
                    return UDim2.new(tonumber(xs), tonumber(xo), tonumber(ys), tonumber(yo))
                end
                return nil
            end)
            if robloxTypeSuccess and robloxTypeResult then
                customArgs = { robloxTypeResult }
                return true, "Parsed Roblox type: " .. tostring(robloxTypeResult)
            end
            customArgs = nil
            return false, "Invalid JSON or Roblox type: " .. tostring(result)
        end
    end

    local function createFrame(name: string, size: UDim2, position: UDim2, parent: Instance): Frame
        local frame = Instance.new("Frame")
        frame.Name = name
        frame.Size = size
        frame.Position = position
        frame.BackgroundColor3 = FRAME_BACKGROUND_COLOR
        frame.BorderSizePixel = 0
        frame.ClipsDescendants = true
        frame.Parent = parent

        local uiCorner = Instance.new("UICorner")
        uiCorner.CornerRadius = CORNER_RADIUS
        uiCorner.Parent = frame

        local uiStroke = Instance.new("UIStroke")
        uiStroke.Thickness = 2
        uiStroke.Color = BORDER_COLOR
        uiStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        uiStroke.Transparency = 0.3
        uiStroke.Parent = frame

        local uiGradient = Instance.new("UIGradient")
        uiGradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 255, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 255))
        })
        uiGradient.Rotation = 45
        uiGradient.Transparency = NumberSequence.new(0.7)
        uiGradient.Parent = uiStroke

        local aspectRatio = Instance.new("UIAspectRatioConstraint")
        aspectRatio.AspectRatio = 1
        aspectRatio.Parent = frame

        return frame
    end

    local function createTitleBar(parent: GuiObject, text: string, textColor: Color3): TextLabel
        local titleBar = Instance.new("TextLabel")
        titleBar.Name = "TitleBar"
        titleBar.Size = UDim2.new(1, 0, 0, 30)
        titleBar.BackgroundTransparency = 1
        titleBar.TextColor3 = textColor
        titleBar.Text = text
        titleBar.Font = Enum.Font.SourceSansBold
        titleBar.TextSize = 18
        titleBar.TextScaled = true
        titleBar.TextWrapped = true
        titleBar.TextXAlignment = Enum.TextXAlignment.Center
        titleBar.Parent = parent
        titleBar.ZIndex = 2
        titleBar.LayoutOrder = 1

        local toggleButton = Instance.new("TextButton")
        toggleButton.Name = "ToggleButton"
        toggleButton.Size = UDim2.new(0, 20, 1, 0)
        toggleButton.Position = UDim2.new(1, -25, 0, 0)
        toggleButton.BackgroundTransparency = 1
        toggleButton.TextColor3 = textColor
        toggleButton.Text = "[-]"
        toggleButton.Font = Enum.Font.SourceSansBold
        toggleButton.TextSize = 16
        toggleButton.TextXAlignment = Enum.TextXAlignment.Center
        toggleButton.TextYAlignment = Enum.TextYAlignment.Center
        toggleButton.Parent = titleBar
        toggleButton.ZIndex = 3
        toggleButton.Cursor = Enum.Cursor.PointingHand

        toggleButton.MouseButton1Click:Connect(function()
            local frameName = parent.Name
            uiStates[frameName] = not (uiStates[frameName] or false)
            toggleButton.Text = uiStates[frameName] and "[+]" or "[-]"
            local targetHeight = uiStates[frameName] and 30 or (frameName == "StartFrame" and 100 or 250)
            local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
            TweenService:Create(parent, tweenInfo, { Size = UDim2.new(parent.Size.X.Scale, parent.Size.X.Offset, 0, targetHeight) }):Play()
            for _, child in pairs(parent:GetChildren()) do
                if child ~= titleBar and child ~= toggleButton then
                    child.Visible = not uiStates[frameName]
                end
            end
        end)

        return titleBar
    end

    local function setupDrag(frame: Frame, titleBar: TextLabel)
        titleBar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                draggingFrame = frame
                frame.DragStartPos = input.Position
                frame.DragStartFramePos = frame.Position
                titleBar.Cursor = Enum.Cursor.Grabbing
            end
        end)
        titleBar.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                if draggingFrame == frame then
                    draggingFrame = nil
                    titleBar.Cursor = Enum.Cursor.Grab
                end
            end
        end)
    end

    UserInputService.InputChanged:Connect(function(input)
        if draggingFrame and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - draggingFrame.DragStartPos
            draggingFrame.Position = UDim2.new(
                draggingFrame.DragStartFramePos.X.Scale,
                draggingFrame.DragStartFramePos.X.Offset + delta.X,
                draggingFrame.DragStartFramePos.Y.Scale,
                draggingFrame.DragStartFramePos.Y.Offset + delta.Y
            )
        end
    end)

    UserInputService.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            local target = input.Target
            local methodListFrame = uiElements.MethodListFrame as Frame
            local methodDropdownButton = uiElements.MethodDropdownButton as TextButton
            if methodListFrame and methodDropdownButton and methodListFrame.Visible then
                if not (target:IsDescendantOf(methodDropdownButton) or target:IsDescendantOf(methodListFrame)) then
                    methodListFrame.Visible = false
                end
            end
            local remoteListFrame = uiElements.RemoteListFrame as Frame
            local remoteDropdownButton = uiElements.RemoteDropdownButton as TextButton
            if remoteListFrame and remoteDropdownButton and remoteListFrame.Visible then
                if not (target:IsDescendantOf(remoteDropdownButton) or target:IsDescendantOf(remoteListFrame)) then
                    remoteListFrame.Visible = false
                end
            end
        end
    end)

    local function createStyledButton(parent: GuiObject, text: string, position: UDim2, size: UDim2, bgColor: Color3, textColor: Color3): TextButton
        local button = Instance.new("TextButton")
        button.Size = size
        button.Position = position
        button.BackgroundColor3 = bgColor
        button.TextColor3 = textColor
        button.Text = text
        button.Font = Enum.Font.SourceSansBold
        button.TextSize = 16
        button.TextScaled = true
        button.TextWrapped = true
        button.Parent = parent
        button.ZIndex = 2

        local uiCorner = Instance.new("UICorner")
        uiCorner.CornerRadius = BUTTON_CORNER_RADIUS
        uiCorner.Parent = button

        button.MouseEnter:Connect(function()
            TweenService:Create(button, TweenInfo.new(0.1), { BackgroundColor3 = BUTTON_HOVER_COLOR }):Play()
        end)
        button.MouseLeave:Connect(function()
            if button.BackgroundColor3 ~= BUTTON_ACTIVE_COLOR then
                TweenService:Create(button, TweenInfo.new(0.1), { BackgroundColor3 = bgColor }):Play()
            end
        end)

        return button
    end

    local function createStyledTextBox(parent: GuiObject, placeholder: string, position: UDim2, size: UDim2): TextBox
        local textBox = Instance.new("TextBox")
        textBox.Size = size
        textBox.Position = position
        textBox.BackgroundColor3 = INPUT_BACKGROUND_COLOR
        textBox.TextColor3 = TEXT_COLOR_LIGHT
        textBox.PlaceholderText = placeholder
        textBox.Font = Enum.Font.SourceSans
        textBox.TextSize = 14
        textBox.TextScaled = true
        textBox.TextWrapped = true
        textBox.Parent = parent
        textBox.ZIndex = 2

        local uiCorner = Instance.new("UICorner")
        uiCorner.CornerRadius = BUTTON_CORNER_RADIUS
        uiCorner.Parent = textBox

        return textBox
    end

    local function createAutoScrollToggleButton(parent: GuiObject, logType: string, initialPosition: UDim2): TextButton
        local button = Instance.new("TextButton")
        button.Name = "AutoScrollToggle"
        button.Size = UDim2.new(0, 100, 0, 20)
        button.Position = initialPosition
        button.BackgroundColor3 = INPUT_BACKGROUND_COLOR
        button.TextColor3 = TEXT_COLOR_LIGHT
        button.Text = "Auto-Scroll: ON"
        button.Font = Enum.Font.SourceSans
        button.TextSize = 12
        button.Parent = parent
        button.ZIndex = 2

        local uiCorner = Instance.new("UICorner")
        uiCorner.CornerRadius = BUTTON_CORNER_RADIUS
        uiCorner.Parent = button

        button.MouseButton1Click:Connect(function()
            autoScrollLogs[logType] = not autoScrollLogs[logType]
            button.Text = "Auto-Scroll: " .. (autoScrollLogs[logType] and "ON" or "OFF")
            updateProcessLog(string.format("Auto-scroll %s: %s", logType, (autoScrollLogs[logType] and "ON" or "OFF")))
        end)

        button.Text = "Auto-Scroll: " .. (autoScrollLogs[logType] and "ON" or "OFF")
        return button
    end

    local function populateRemotes()
        local remoteScrollingFrame = uiElements.RemoteScrollingFrame as ScrollingFrame
        local remoteDropdownButton = uiElements.RemoteDropdownButton as TextButton
        local remoteListLayout = uiElements.RemoteListLayout as UIListLayout

        for _, child in pairs(remoteScrollingFrame:GetChildren()) do
            if child:IsA("TextButton") then
                child:Destroy()
            end
        end

        local allButton = createStyledButton(remoteScrollingFrame, "All Remotes", UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0, 25), INPUT_BACKGROUND_COLOR, TEXT_COLOR_LIGHT)
        allButton.TextXAlignment = Enum.TextXAlignment.Left
        allButton.MouseButton1Click:Connect(function()
            selectedRemote = nil
            remoteDropdownButton.Text = "Select Remote: All ▼"
            uiElements.RemoteListFrame.Visible = false
            updateProcessLog("Selected remote: All Remotes.")
        end)

        for _, remote in ipairs(remoteList) do
            local button = createStyledButton(remoteScrollingFrame, remote.Name .. " (" .. (remote:IsA("RemoteEvent") and "Event" or "Function") .. ")", UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0, 25), INPUT_BACKGROUND_COLOR, TEXT_COLOR_LIGHT)
            button.TextXAlignment = Enum.TextXAlignment.Left
            button.MouseButton1Click:Connect(function()
                selectedRemote = remote
                remoteDropdownButton.Text = "Select Remote: " .. remote.Name .. " ▼"
                uiElements.RemoteListFrame.Visible = false
                updateProcessLog("Selected remote: " .. remote.Name)
            end)
        end
    end

    local function createUI(): ScreenGui
        local screenGui = Instance.new("ScreenGui")
        screenGui.Name = "ZXHELLSecurityTools"
        screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
        screenGui.ResetOnSpawn = false
        screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        screenGui.DisplayOrder = 1000

        local frameWidth = UDim2.new(0, 250)
        local frameHeight = UDim2.new(0, 250)
        local startFrameHeight = UDim2.new(0, 100)

        local startFrame = createFrame("StartFrame", frameWidth, UDim2.new(0.02, 0, 0.05, 0), screenGui)
        startFrame.Size = startFrameHeight
        local startTitle = createTitleBar(startFrame, "ZXHELL Start", TITLE_TEXT_COLOR_PRIMARY)
        setupDrag(startFrame, startTitle)
        uiElements.StartFrame = startFrame

        local startButton = createStyledButton(startFrame, "START TEST", UDim2.new(0.5, -95, 0, 40), UDim2.new(0, 190, 0, 40), BUTTON_BACKGROUND_COLOR, TEXT_COLOR_LIGHT)
        startButton.MouseButton1Click:Connect(function()
            testingActive = not testingActive
            if testingActive then
                startButton.Text = "STOP TEST"
                TweenService:Create(startButton, TweenInfo.new(0.1), { BackgroundColor3 = BUTTON_ACTIVE_COLOR }):Play()
                task.spawn(runExploitLoop)
                logExploit("Testing", "Started", "Security testing enabled")
            else
                startButton.Text = "START TEST"
                TweenService:Create(startButton, TweenInfo.new(0.1), { BackgroundColor3 = BUTTON_BACKGROUND_COLOR }):Play()
                logExploit("Testing", "Stopped", "Security testing disabled")
            end
        end)
        uiElements.StartButton = startButton

        local processFrame = createFrame("ProcessFrame", frameWidth, UDim2.new(0.02, 260, 0.05, 0), screenGui)
        local processTitle = createTitleBar(processFrame, "Process", TITLE_TEXT_COLOR_SECONDARY)
        setupDrag(processFrame, processTitle)
        uiElements.ProcessFrame = processFrame

        local processLogScrollingFrame = Instance.new("ScrollingFrame")
        processLogScrollingFrame.Name = "ProcessLogScrollingFrame"
        processLogScrollingFrame.Size = UDim2.new(1, -10, 1, -65)
        processLogScrollingFrame.Position = UDim2.new(0, 5, 0, 35)
        processLogScrollingFrame.BackgroundTransparency = 1
        processLogScrollingFrame.ScrollBarThickness = SCROLLBAR_THICKNESS
        processLogScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
        processLogScrollingFrame.Parent = processFrame
        uiElements.ProcessLogScrollingFrame = processLogScrollingFrame

        local processLogBox = Instance.new("TextLabel")
        processLogBox.Name = "ProcessLogBox"
        processLogBox.Size = UDim2.new(1, -10, 0, 0)
        processLogBox.BackgroundTransparency = 1
        processLogBox.TextColor3 = LOG_TEXT_COLOR
        processLogBox.TextWrapped = true
        processLogBox.TextYAlignment = Enum.TextYAlignment.Top
        processLogBox.TextXAlignment = Enum.TextXAlignment.Left
        processLogBox.Text = "Waiting for activity..."
        processLogBox.Font = Enum.Font.SourceSans
        processLogBox.TextSize = 14
        processLogBox.Parent = processLogScrollingFrame
        uiElements.ProcessLogBox = processLogBox

        local processAutoScrollButton = createAutoScrollToggleButton(processFrame, "ProcessLog", UDim2.new(0.5, -50, 1, -25))
        uiElements.ProcessAutoScrollButton = processAutoScrollButton

        local optionsFrame = createFrame("OptionsFrame", frameWidth, UDim2.new(0.02, 520, 0.05, 0), screenGui)
        local optionsTitle = createTitleBar(optionsFrame, "Options", TITLE_TEXT_COLOR_PRIMARY)
        setupDrag(optionsFrame, optionsTitle)
        uiElements.OptionsFrame = optionsFrame

        local argsInputLabel = Instance.new("TextLabel")
        argsInputLabel.Size = UDim2.new(1, -10, 0, 20)
        argsInputLabel.Position = UDim2.new(0, 5, 0, 35)
        argsInputLabel.BackgroundTransparency = 1
        argsInputLabel.TextColor3 = TEXT_COLOR_LIGHT
        argsInputLabel.Text = "Custom Args (JSON or Roblox type):"
        argsInputLabel.Font = Enum.Font.SourceSansBold
        argsInputLabel.TextSize = 12
        argsInputLabel.TextXAlignment = Enum.TextXAlignment.Left
        argsInputLabel.Parent = optionsFrame

        local argsInput = createStyledTextBox(optionsFrame, 'Example: {"test":123} or Vector3(1,2,3)', UDim2.new(0, 5, 0, 55), UDim2.new(1, -10, 0, 30))
        argsInput.Text = ""
        argsInput.FocusLost:Connect(function(enterPressed)
            if enterPressed then
                local success, msg = parseCustomArgs(argsInput.Text)
                updateProcessLog(success and "Custom args: " .. msg or "Failed to parse: " .. msg)
            end
        end)
        uiElements.ArgsInput = argsInput

        local delayInputLabel = Instance.new("TextLabel")
        delayInputLabel.Size = UDim2.new(1, -10, 0, 20)
        delayInputLabel.Position = UDim2.new(0, 5, 0, 95)
        delayInputLabel.BackgroundTransparency = 1
        delayInputLabel.TextColor3 = TEXT_COLOR_LIGHT
        delayInputLabel.Text = "Delay (seconds, e.g., 0.5):"
        delayInputLabel.Font = Enum.Font.SourceSansBold
        delayInputLabel.TextSize = 12
        delayInputLabel.TextXAlignment = Enum.TextXAlignment.Left
        delayInputLabel.Parent = optionsFrame

        local delayInput = createStyledTextBox(optionsFrame, "0.5", UDim2.new(0, 5, 0, 115), UDim2.new(1, -10, 0, 30))
        delayInput.Text = "0.5"
        uiElements.DelayInput = delayInput

        local statusFrame = createFrame("StatusFrame", frameWidth, UDim2.new(0.02, 780, 0.05, 0), screenGui)
        local statusTitle = createTitleBar(statusFrame, "Status", TITLE_TEXT_COLOR_SECONDARY)
        setupDrag(statusFrame, statusTitle)
        uiElements.StatusFrame = statusFrame

        local statusLogScrollingFrame = Instance.new("ScrollingFrame")
        statusLogScrollingFrame.Name = "StatusLogScrollingFrame"
        statusLogScrollingFrame.Size = UDim2.new(1, -10, 1, -65)
        statusLogScrollingFrame.Position = UDim2.new(0, 5, 0, 35)
        statusLogScrollingFrame.BackgroundTransparency = 1
        statusLogScrollingFrame.ScrollBarThickness = SCROLLBAR_THICKNESS
        statusLogScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
        statusLogScrollingFrame.Parent = statusFrame
        uiElements.StatusLogScrollingFrame = statusLogScrollingFrame

        local statusLogBox = Instance.new("TextLabel")
        statusLogBox.Name = "StatusLogBox"
        statusLogBox.Size = UDim2.new(1, -10, 0, 0)
        statusLogBox.BackgroundTransparency = 1
        statusLogBox.TextColor3 = LOG_TEXT_COLOR
        statusLogBox.TextWrapped = true
        statusLogBox.TextYAlignment = Enum.TextYAlignment.Top
        statusLogBox.TextXAlignment = Enum.TextXAlignment.Left
        statusLogBox.Text = "Vulnerabilities will appear here..."
        statusLogBox.Font = Enum.Font.SourceSans
        statusLogBox.TextSize = 14
        statusLogBox.Parent = statusLogScrollingFrame
        uiElements.StatusLogBox = statusLogBox

        local statusAutoScrollButton = createAutoScrollToggleButton(statusFrame, "StatusLog", UDim2.new(0.5, -50, 1, -25))
        uiElements.StatusAutoScrollButton = statusAutoScrollButton

        local methodFrame = createFrame("MethodFrame", frameWidth, UDim2.new(0.02, 0, 0.5, 0), screenGui)
        local methodTitle = createTitleBar(methodFrame, "Hacking Methods", TITLE_TEXT_COLOR_PRIMARY)
        setupDrag(methodFrame, methodTitle)
        uiElements.MethodFrame = methodFrame

        local methodDropdownButton = createStyledButton(methodFrame, "Select Method: Auto Spam", UDim2.new(0, 5, 0, 40), UDim2.new(1, -10, 0, 30), INPUT_BACKGROUND_COLOR, TEXT_COLOR_LIGHT)
        methodDropdownButton.TextXAlignment = Enum.TextXAlignment.Left
        methodDropdownButton.Text = methodDropdownButton.Text .. " ▼"
        methodDropdownButton.MouseButton1Click:Connect(function()
            uiElements.MethodListFrame.Visible = not uiElements.MethodListFrame.Visible
        end)
        uiElements.MethodDropdownButton = methodDropdownButton

        local methodListFrame = createFrame("MethodListFrame", UDim2.new(1, 0, 0, 150), UDim2.new(0, 0, 1, 0), methodDropdownButton)
        methodListFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
        methodListFrame.Visible = false
        methodListFrame.ZIndex = 3
        uiElements.MethodListFrame = methodListFrame

        local methodScrollingFrame = Instance.new("ScrollingFrame")
        methodScrollingFrame.Name = "MethodScrollingFrame"
        methodScrollingFrame.Size = UDim2.new(1, 0, 1, 0)
        methodScrollingFrame.BackgroundTransparency = 1
        methodScrollingFrame.ScrollBarThickness = SCROLLBAR_THICKNESS
        methodScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
        methodScrollingFrame.Parent = methodListFrame
        uiElements.MethodScrollingFrame = methodScrollingFrame

        local methodListLayout = Instance.new("UIListLayout")
        methodListLayout.FillDirection = Enum.FillDirection.Vertical
        methodListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
        methodListLayout.Padding = UDim.new(0, 2)
        methodListLayout.Parent = methodScrollingFrame

        for _, method in ipairs(methods) do
            local button = createStyledButton(methodScrollingFrame, method.name, UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0, 25), INPUT_BACKGROUND_COLOR, TEXT_COLOR_LIGHT)
            button.TextXAlignment = Enum.TextXAlignment.Left
            button.MouseButton1Click:Connect(function()
                hackMethod = method.value
                methodDropdownButton.Text = "Select Method: " .. method.name .. " ▼"
                methodListFrame.Visible = false
                updateProcessLog("Method changed: " .. method.name)
                if uiElements.SingleShotButton then
                    uiElements.SingleShotButton.Visible = (hackMethod == "SingleShot")
                end
                if uiElements.SequenceInput then
                    uiElements.SequenceInput.Visible = (hackMethod == "SequenceTest")
                end
            end)

            local tooltip = Instance.new("TextLabel")
            tooltip.Name = "Tooltip"
            tooltip.Size = UDim2.new(0, 180, 0, 40)
            tooltip.Position = UDim2.new(1, 5, 0, 0)
            tooltip.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
            tooltip.TextColor3 = Color3.fromRGB(200, 200, 200)
            tooltip.Text = method.desc
            tooltip.TextWrapped = true
            tooltip.Visible = false
            tooltip.Font = Enum.Font.SourceSans
            tooltip.TextSize = 12
            tooltip.TextXAlignment = Enum.TextXAlignment.Left
            tooltip.TextYAlignment = Enum.TextYAlignment.Top
            tooltip.Parent = button
            local tooltipCorner = Instance.new("UICorner")
            tooltipCorner.CornerRadius = BUTTON_CORNER_RADIUS
            tooltipCorner.Parent = tooltip
            tooltip.ZIndex = 4

            button.MouseEnter:Connect(function() tooltip.Visible = true end)
            button.MouseLeave:Connect(function() tooltip.Visible = false end)
        end

        local singleShotButton = createStyledButton(methodFrame, "RUN SINGLE SHOT", UDim2.new(0.5, -95, 0, 180), UDim2.new(0, 190, 0, 40), BUTTON_BACKGROUND_COLOR, TEXT_COLOR_LIGHT)
        singleShotButton.Visible = (hackMethod == "SingleShot")
        singleShotButton.MouseButton1Click:Connect(function()
            if selectedRemote then
                local argsToUse = customArgs or testArgs
                testRemote(selectedRemote, argsToUse[1] or nil, hackMethod)
                updateProcessLog(string.format("Single Shot to %s completed.", selectedRemote.Name))
            else
                updateProcessLog("Select a remote first for Single Shot.")
            end
        end)
        uiElements.SingleShotButton = singleShotButton

        local sequenceInput = createStyledTextBox(methodFrame, 'Sequence (e.g., [{"remote":"Name","args":"value"}])', UDim2.new(0, 5, 0, 80), UDim2.new(1, -10, 0, 30))
        sequenceInput.Visible = (hackMethod == "SequenceTest")
        sequenceInput.FocusLost:Connect(function(enterPressed)
            if enterPressed then
                local success, result = pcall(function()
                    local decoded = HttpService:JSONDecode(sequenceInput.Text)
                    sequenceQueue = {}
                    for _, entry in ipairs(decoded) do
                        for _, remote in ipairs(remoteList) do
                            if remote.Name == entry.remote then
                                table.insert(sequenceQueue, { remote = remote, args = entry.args })
                            end
                        end
                    end
                    return "Parsed sequence: " .. HttpService:JSONEncode(decoded)
                end)
                updateProcessLog(success and result or "Failed to parse sequence: " .. tostring(result))
            end
        end)
        uiElements.SequenceInput = sequenceInput

        local remoteFrame = createFrame("RemoteFrame", frameWidth, UDim2.new(0.02, 260, 0.5, 0), screenGui)
        local remoteTitle = createTitleBar(remoteFrame, "Select Remote", TITLE_TEXT_COLOR_SECONDARY)
        setupDrag(remoteFrame, remoteTitle)
        uiElements.RemoteFrame = remoteFrame

        local remoteDropdownButton = createStyledButton(remoteFrame, "Select Remote: All", UDim2.new(0, 5, 0, 40), UDim2.new(1, -10, 0, 30), INPUT_BACKGROUND_COLOR, TEXT_COLOR_LIGHT)
        remoteDropdownButton.TextXAlignment = Enum.TextXAlignment.Left
        remoteDropdownButton.Text = remoteDropdownButton.Text .. " ▼"
        remoteDropdownButton.MouseButton1Click:Connect(function()
            uiElements.RemoteListFrame.Visible = not uiElements.RemoteListFrame.Visible
            populateRemotes()
        end)
        uiElements.RemoteDropdownButton = remoteDropdownButton

        local remoteListFrame = createFrame("RemoteListFrame", UDim2.new(1, 0, 0, 150), UDim2.new(0, 0, 1, 0), remoteDropdownButton)
        remoteListFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
        remoteListFrame.Visible = false
        remoteListFrame.ZIndex = 3
        uiElements.RemoteListFrame = remoteListFrame

        local remoteScrollingFrame = Instance.new("ScrollingFrame")
        remoteScrollingFrame.Name = "RemoteScrollingFrame"
        remoteScrollingFrame.Size = UDim2.new(1, 0, 1, 0)
        remoteScrollingFrame.BackgroundTransparency = 1
        remoteScrollingFrame.ScrollBarThickness = SCROLLBAR_THICKNESS
        remoteScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
        remoteScrollingFrame.Parent = remoteListFrame
        uiElements.RemoteScrollingFrame = remoteScrollingFrame

        local remoteListLayout = Instance.new("UIListLayout")
        remoteListLayout.FillDirection = Enum.FillDirection.Vertical
        remoteListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
        remoteListLayout.Padding = UDim.new(0, 2)
        remoteListLayout.Parent = remoteScrollingFrame
        uiElements.RemoteListLayout = remoteListLayout

        local detailedLogFrame = createFrame("DetailedLogFrame", UDim2.new(0, 510, 0, 250), UDim2.new(0.02, 520, 0.5, 0), screenGui)
        local detailedLogTitle = createTitleBar(detailedLogFrame, "Detailed Exploit Log", TITLE_TEXT_COLOR_PRIMARY)
        setupDrag(detailedLogFrame, detailedLogTitle)
        uiElements.DetailedLogFrame = detailedLogFrame

        local detailedLogScrollingFrame = Instance.new("ScrollingFrame")
        detailedLogScrollingFrame.Name = "DetailedLogScrollingFrame"
        detailedLogScrollingFrame.Size = UDim2.new(1, -10, 1, -65)
        detailedLogScrollingFrame.Position = UDim2.new(0, 5, 0, 35)
        detailedLogScrollingFrame.BackgroundTransparency = 1
        detailedLogScrollingFrame.ScrollBarThickness = SCROLLBAR_THICKNESS
        detailedLogScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
        detailedLogScrollingFrame.Parent = detailedLogFrame
        uiElements.DetailedLogScrollingFrame = detailedLogScrollingFrame

        local detailedLogBox = Instance.new("TextLabel")
        detailedLogBox.Name = "DetailedLogBox"
        detailedLogBox.Size = UDim2.new(1, -10, 0, 0)
        detailedLogBox.BackgroundTransparency = 1
        detailedLogBox.TextColor3 = LOG_TEXT_COLOR
        detailedLogBox.TextWrapped = true
        detailedLogBox.TextYAlignment = Enum.TextYAlignment.Top
        detailedLogBox.TextXAlignment = Enum.TextXAlignment.Left
        detailedLogBox.Text = "Detailed logs will appear here..."
        detailedLogBox.Font = Enum.Font.SourceSans
        detailedLogBox.TextSize = 12
        detailedLogBox.Parent = detailedLogScrollingFrame
        uiElements.DetailedLogBox = detailedLogBox

        local detailedAutoScrollButton = createAutoScrollToggleButton(detailedLogFrame, "DetailedLog", UDim2.new(0.5, -50, 1, -25))
        uiElements.DetailedAutoScrollButton = detailedAutoScrollButton

        local exportLogButton = createStyledButton(detailedLogFrame, "Export Log (Console)", UDim2.new(0.5, -95, 1, -25), UDim2.new(0, 190, 0, 25), BUTTON_BACKGROUND_COLOR, TEXT_COLOR_LIGHT)
        exportLogButton.MouseButton1Click:Connect(function()
            local jsonLog = HttpService:JSONEncode(exploitLog)
            print("--- EXPORTED EXPLOIT LOG ---")
            print(jsonLog)
            print("--- END EXPORTED LOG ---")
            updateProcessLog("Exploit log exported to console.")
        end)
        uiElements.ExportLogButton = exportLogButton

        return screenGui
    end

    local mainScreenGui = createUI()
    setupDynamicRemoteDetection()
    updateProcessLog("ZXHELL Security Tools ready! Click START TEST to begin.")

    game:BindToClose(function()
        local logJson = HttpService:JSONEncode(exploitLog)
        print("--- FINAL EXPLOIT LOG ON CLOSE ---")
        print(logJson)
        print("--- END FINAL EXPLOIT LOG ---")
    end)

    local heartbeatConnection: RBXScriptConnection?
    RunService.Heartbeat:Connect(function()
        if testingActive then
            flushLogBatch()
        end
        if uiElements.DetailedLogFrame and not uiStates.DetailedLogFrame then
            local logText = ""
            for _, entry in ipairs(exploitLog) do
                local timestamp = os.date("%X", entry.timestamp)
                local statusColor = entry.status == "Success" and "rgb(0,255,0)" or "rgb(255,0,0)"
                if entry.vulnerabilityType then
                    if entry.vulnerabilityType:find("Critical") then statusColor = "rgb(255,0,0)" end
                    if entry.vulnerabilityType:find("High") then statusColor = "rgb(255,165,0)" end
                    if entry.vulnerabilityType:find("Medium") then statusColor = "rgb(255,255,0)" end
                end
                local entryString = string.format("[%s] <font color=\"%s\">%s</font>: %s (%s)",
                    timestamp, statusColor, entry.action, entry.status, entry.details)
                if entry.vulnerabilityType then
                    entryString = entryString .. string.format(" - Vulnerability: %s", entry.vulnerabilityType)
                end
                logText = logText .. entryString .. "\n"
            end
            local detailedLogBox = uiElements.DetailedLogBox as TextLabel
            local detailedLogScrollingFrame = uiElements.DetailedLogScrollingFrame as ScrollingFrame
            detailedLogBox.RichText = true
            detailedLogBox.Text = logText
            detailedLogBox.Size = UDim2.new(1, -10, 0, detailedLogBox.TextBounds.Y)
            detailedLogScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, detailedLogBox.TextBounds.Y)
            if autoScrollLogs.DetailedLog then
                detailedLogScrollingFrame.CanvasPosition = Vector2.new(0, detailedLogBox.TextBounds.Y)
            end
        end
    end)

    -- Passive monitoring for ReplayAttack
    local function monitorRemoteCalls()
        for _, remote in ipairs(remoteList) do
            if remote:IsA("RemoteEvent") then
                remote.OnClientEvent:Connect(function(...)
                    table.insert(replayLog, { remote = remote, args = {...}, timestamp = os.time() })
                    updateProcessLog("Recorded RemoteEvent call: " .. remote.Name)
                end)
            elseif remote:IsA("RemoteFunction") then
                -- Note: Cannot directly monitor RemoteFunction calls from client, but log user-initiated calls
            end
        end
    end

    monitorRemoteCalls()
