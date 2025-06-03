--!strict
--[[
    ZXHELL Security Tools - Enhanced Version for Roblox Script Executor (Lua)

    This script provides a user interface (UI) for detecting and testing RemoteEvents
    and RemoteFunctions within a Roblox game. It aims to simulate various exploit
    methods and log potential vulnerabilities.

    Key Features:
    - Dynamic UI creation using Instance.new()
    - Draggable UI frames
    - Minimize/Maximize functionality for UI frames
    - Real-time logging of processes and potential vulnerabilities
    - Customizable test arguments and delay
    - Multiple hacking methods (Auto Spam, Single Shot, Flood Test, Property Manipulation)
    - Dynamic detection and selection of RemoteEvents/Functions
    - Responsive UI scaling (basic)

    Original issues addressed:
    - Options not appearing / functions not working: Entirely re-implemented UI and logic flow.
    - UI not responding: Ensured non-blocking operations and proper event handling.
    - UI design: Re-imagined with modern aesthetics suitable for Roblox UI.
    - "Stop Test" not working: Fixed the logic to correctly halt the testing loop.

    Disclaimer: This tool is for educational and ethical security testing purposes only.
    Unauthorized use to exploit games without permission is against Roblox Terms of Service.
]]

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait() -- Ensure LocalPlayer is available

-- Global Variables for Application State
local testingActive: boolean = false -- Controls if the security testing loop is running
local exploitLog: { [number]: { timestamp: number, action: string, status: string, details: string } } = {} -- Stores detailed logs of exploit attempts
local remoteTimer: { [RemoteEvent | RemoteFunction]: { lastCall: number, cooldown: number } } = {} -- Cooldown tracking for each remote
local remoteList: { [number]: RemoteEvent | RemoteFunction } = {} -- List of detected RemoteEvents/Functions
local selectedRemote: RemoteEvent | RemoteFunction | nil = nil -- The remote currently selected for specific testing
local customArgs: { any } | nil = nil -- Custom arguments provided by the user for testing
local hackMethod: string = "AutoSpam" -- The current method of attack (e.g., "AutoSpam", "FloodTest")
local uiStates: { [string]: boolean } = {} -- Stores the minimized/maximized state for each UI frame (true if minimized)

-- UI Dragging Variables
local draggingFrame: Frame | nil = nil -- The UI frame currently being dragged
local dragStartPos: Vector2 = Vector2.new(0, 0) -- Mouse/touch position when dragging started
local dragStartFramePos: UDim2 = UDim2.new(0, 0, 0, 0) -- Frame position when dragging started

-- UI Element References (will be populated during UI creation)
local uiElements: { [string]: GuiObject } = {} -- Centralized table to hold references to key UI elements

-- Constants for UI Styling (RGB values for Color3.fromRGB)
local FRAME_BACKGROUND_COLOR = Color3.fromRGB(20, 20, 30)
local TITLE_TEXT_COLOR_PRIMARY = Color3.fromRGB(0, 255, 255) -- Cyan
local TITLE_TEXT_COLOR_SECONDARY = Color3.fromRGB(255, 0, 255) -- Magenta
local BUTTON_BACKGROUND_COLOR = Color3.fromRGB(0, 80, 150)
local BUTTON_HOVER_COLOR = Color3.fromRGB(0, 100, 200)
local BUTTON_ACTIVE_COLOR = Color3.fromRGB(150, 0, 0) -- Red for stop button
local TEXT_COLOR_LIGHT = Color3.fromRGB(255, 255, 255)
local LOG_TEXT_COLOR = Color3.fromRGB(200, 200, 200)
local INPUT_BACKGROUND_COLOR = Color3.fromRGB(30, 30, 40)
local BORDER_COLOR = Color3.fromRGB(0, 255, 255)
local CORNER_RADIUS = UDim.new(0, 8) -- 8 pixels for rounded corners
local BUTTON_CORNER_RADIUS = UDim.new(0, 4) -- 4 pixels for button corners
local SCROLLBAR_THICKNESS = 4 -- Pixels for scrollbar thickness

-- Test Arguments for Remote Calls
-- These are generic arguments that might reveal vulnerabilities if a remote isn't properly validated.
local testArgs: { any } = {
    nil, -- Test with no argument
    "instant", -- Common string argument
    true, -- Boolean argument
    -1, -- Negative number
    999999, -- Large number
    string.rep("x", 1000), -- Long string (potential buffer overflow/DoS)
    { exploit = "malicious", nested = { depth = 100 } }, -- Nested table (complex data structure)
    { math.huge, -math.huge, 0/0 }, -- Edge case numbers (Infinity, NaN)
    "function() end", -- String representing a function (if interpreted as code)
    LocalPlayer, -- Pass the LocalPlayer object itself
    workspace, -- Pass a service
    ReplicatedStorage, -- Pass ReplicatedStorage
    Vector3.new(0,0,0), -- Vector3
    CFrame.new(0,0,0), -- CFrame
}

-- Hacking Methods Available
-- Each method has a name, a value (for internal logic), and a description.
local methods: { { name: string, value: string, desc: string } } = {
    { name = "Auto Spam", value = "AutoSpam", desc = "Spam semua argumen secara otomatis ke remote yang dipilih." },
    { name = "Single Shot", value = "SingleShot", desc = "Uji satu argumen per klik tombol secara manual." },
    { name = "Custom Args", value = "CustomArgs", desc = "Gunakan argumen kustom yang dimasukkan pengguna." },
    { name = "Flood Test", value = "FloodTest", desc = "Spam cepat untuk uji beban dan deteksi batasan rate-limit." },
    { name = "Property Manip", value = "PropertyManip", desc = "Coba ubah properti pemain (misalnya, leaderstats) jika remote mengizinkan." },
}

-- Logging Functions
-- These functions update the UI logs and the internal exploit log.

--- Logs an exploit attempt and updates the exploit log state.
-- @param action string - The action performed (e.g., "Remote Detection", "Test Remote").
-- @param status string - The status of the action (e.g., "Success", "Failed").
-- @param details string - Detailed information about the action.
-- @return string - The formatted log text.
local function logExploit(action: string, status: string, details: string): string
    local logEntry = {
        timestamp = os.time(), -- Current timestamp in seconds since epoch
        action = action,
        status = status,
        details = details
    }
    table.insert(exploitLog, logEntry) -- Add to the internal log history
    local logText = string.format("[%s] %s: %s (%s)", os.date("%X", logEntry.timestamp), action, status, details)
    print(logText) -- Also print to Roblox output for debugging
    return logText
end

--- Updates the process log UI TextLabel.
-- @param text string - The text to add to the process log.
local function updateProcessLog(text: string)
    local processLogBox = uiElements.ProcessLogBox as TextLabel
    local processLogScrollingFrame = uiElements.ProcessLogScrollingFrame as ScrollingFrame

    if processLogBox and processLogScrollingFrame then
        processLogBox.Text = processLogBox.Text .. "\n" .. text -- Append new text
        -- Adjust TextLabel size to fit content
        processLogBox.Size = UDim2.new(1, -10, 0, processLogBox.TextBounds.Y)
        -- Adjust ScrollingFrame CanvasSize to match TextLabel height
        processLogScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, processLogBox.TextBounds.Y)
        -- Scroll to the bottom
        processLogScrollingFrame.CanvasPosition = Vector2.new(0, processLogBox.TextBounds.Y)
    end
end

--- Updates the status log UI TextLabel, specifically looking for vulnerabilities.
-- @param text string - The text to add to the status log.
local function updateStatusLog(text: string)
    local statusLogBox = uiElements.StatusLogBox as TextLabel
    local statusLogScrollingFrame = uiElements.StatusLogScrollingFrame as ScrollingFrame

    if statusLogBox and statusLogScrollingFrame then
        if text:find("Success") then -- Only log successful exploit attempts as vulnerabilities
            local remoteName = text:match("Test Remote: Success%((.-) with args:") or "Unknown"
            local arg = text:match("args: (.-), Method:") or "Unknown"
            local vulnText = string.format("Kerentanan: %s rentan terhadap argumen %s", remoteName, arg)
            statusLogBox.Text = statusLogBox.Text .. "\n" .. vulnText
            statusLogBox.Size = UDim2.new(1, -10, 0, statusLogBox.TextBounds.Y)
            statusLogScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, statusLogBox.TextBounds.Y)
            statusLogScrollingFrame.CanvasPosition = Vector2.new(0, statusLogBox.TextBounds.Y)
        end
    end
end

-- Core Logic Functions

--- Detects RemoteEvents and RemoteFunctions in ReplicatedStorage.
-- Populates the `remoteList` global variable.
-- @return boolean - True if any remotes were found, false otherwise.
local function detectRemotes(): boolean
    remoteList = {} -- Clear previous list
    for _, obj in pairs(ReplicatedStorage:GetDescendants()) do
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            table.insert(remoteList, obj)
            remoteTimer[obj] = { lastCall = tick(), cooldown = 0 } -- Initialize cooldown for each remote
            logExploit("Remote Detection", "Success", "Found: " .. obj:GetFullName())
        end
    end
    return #remoteList > 0
end

--- Simulates testing a remote with given arguments and method.
-- In a real scenario, this would involve firing/invoking the remote.
-- @param remote RemoteEvent | RemoteFunction - The remote object to test.
-- @param args any - The arguments to pass to the remote.
-- @param method string - The hacking method being used.
-- @return boolean - True if the test was "successful", false otherwise.
local function testRemote(remote: RemoteEvent | RemoteFunction, args: any, method: string): boolean
    -- Implement a basic cooldown to prevent excessive spam in simulation
    if remoteTimer[remote].cooldown > 0 then
        return false -- Still on cooldown
    end

    local success: boolean = false
    local result: any = nil

    if method == "PropertyManip" then
        -- Simulate property manipulation attempt
        -- In a real game, this would attempt to modify player properties like leaderstats
        local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
        if leaderstats and leaderstats:FindFirstChild(remote.Name) then
            local pcallSuccess, pcallResult = pcall(function()
                -- Simulate changing a leaderstat value
                leaderstats[remote.Name].Value = 999999
                return "Attempted property manipulation"
            end)
            success = pcallSuccess
            result = pcallResult
        else
            result = "Property manipulation not applicable or leaderstat not found."
        end
    else
        -- Simulate firing/invoking the remote
        local pcallSuccess, pcallResult = pcall(function()
            if remote:IsA("RemoteEvent") then
                remote:FireServer(args) -- Fire the event
                return "Fired"
            elseif remote:IsA("RemoteFunction") then
                return remote:InvokeServer(args) -- Invoke the function and get a return
            end
        end)
        success = pcallSuccess
        result = pcallResult
    end

    -- Update cooldown for the remote
    remoteTimer[remote].lastCall = tick()
    remoteTimer[remote].cooldown = 0.1 -- Small cooldown to prevent immediate re-test

    local status = success and "Success" or "Failed"
    local details = string.format("%s with args: %s, Method: %s, Result: %s",
        remote:GetFullName(), tostring(args), method, tostring(result))
    local logText = logExploit("Test Remote", status, details)
    updateProcessLog(logText)
    updateStatusLog(logText) -- Pass the full log text for status update
    return success
end

--- The main exploit testing loop. Runs while `testingActive` is true.
local function runExploitLoop()
    while testingActive do
        local argsToUse = customArgs or testArgs -- Use custom args if available, otherwise default
        for _, remote in ipairs(remoteList) do
            if not testingActive then return end -- Stop if testing is deactivated mid-loop
            if selectedRemote == nil or remote == selectedRemote then -- Test all remotes or only the selected one
                if hackMethod == "AutoSpam" then
                    for _, arg in ipairs(argsToUse) do
                        if not testingActive then return end
                        testRemote(remote, arg, hackMethod)
                        task.wait(uiElements.DelayInput.Text ~= "" and tonumber(uiElements.DelayInput.Text) or 0.01) -- Use delay from UI
                    end
                elseif hackMethod == "FloodTest" then
                    for i = 1, 100 do -- Flood 100 times per remote
                        if not testingActive then return end
                        testRemote(remote, argsToUse[math.random(1, #argsToUse)], hackMethod)
                        task.wait(0.001) -- Very small delay for flood
                    end
                elseif hackMethod == "SingleShot" then
                    -- SingleShot is triggered manually, so this loop won't run for it
                    -- The loop will effectively pause until testingActive is false or method changes
                    task.wait(0.1) -- Prevent tight loop if SingleShot is selected and loop is running
                elseif hackMethod == "CustomArgs" then
                    if customArgs then
                        testRemote(remote, customArgs[1], hackMethod) -- Use the first custom arg
                        task.wait(uiElements.DelayInput.Text ~= "" and tonumber(uiElements.DelayInput.Text) or 0.01)
                    else
                        updateProcessLog("Error: Argumen kustom tidak valid atau kosong.")
                    end
                elseif hackMethod == "PropertyManip" then
                    testRemote(remote, nil, hackMethod) -- Args might not be relevant for property manipulation
                    task.wait(uiElements.DelayInput.Text ~= "" and tonumber(uiElements.DelayInput.Text) or 0.01)
                end
            end
        end
        task.wait(0.1) -- Small delay between full iterations over the remote list
    end
end

--- Parses custom arguments from a string input.
-- Uses `loadstring` for more flexible Lua expression parsing.
-- @param input string - The string input from the user.
-- @return boolean - True if parsing was successful, false otherwise.
-- @return string - A message indicating success or failure.
local function parseCustomArgs(input: string): (boolean, string)
    local success, result = pcall(function()
        -- Use loadstring to execute the input as Lua code and return its value
        -- This is powerful but also dangerous if input is not controlled.
        -- In a real exploit, this is how arbitrary code execution might be attempted.
        local chunk = loadstring("return " .. input)
        if chunk then
            return { chunk() } -- Wrap in a table to match testArgs structure
        else
            error("Invalid Lua expression.")
        end
    end)

    if success then
        customArgs = result
        return true, "Berhasil diurai: " .. tostring(result[1])
    else
        customArgs = nil
        return false, "Gagal mengurai: " .. tostring(result) .. ". Pastikan format Lua valid (misal: {test=123} atau \"string\")."
    end
end

-- UI Creation and Management Functions

--- Creates a generic UI frame with common styling.
-- @param name string - The name of the frame.
-- @param size UDim2 - The initial size of the frame.
-- @param position UDim2 - The initial position of the frame.
-- @param parent Instance - The parent of the frame.
-- @return Frame - The created frame.
local function createFrame(name: string, size: UDim2, position: UDim2, parent: Instance): Frame
    local frame = Instance.new("Frame")
    frame.Name = name
    frame.Size = size
    frame.Position = position
    frame.BackgroundColor3 = FRAME_BACKGROUND_COLOR
    frame.BorderSizePixel = 0
    frame.ClipsDescendants = true
    frame.Parent = parent

    -- Add UICorner for rounded corners
    local uiCorner = Instance.new("UICorner")
    uiCorner.CornerRadius = CORNER_RADIUS
    uiCorner.Parent = frame

    -- Add UIStroke for border glow effect
    local uiStroke = Instance.new("UIStroke")
    uiStroke.Thickness = 2
    uiStroke.Color = BORDER_COLOR
    uiStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    uiStroke.Transparency = 0.3
    uiStroke.Parent = frame

    -- Optional UIGradient for a subtle glow within the border
    local uiGradient = Instance.new("UIGradient")
    uiGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 255, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 255))
    })
    uiGradient.Rotation = 45
    uiGradient.Transparency = NumberSequence.new(0.7)
    uiGradient.Parent = uiStroke -- Apply gradient to the stroke

    return frame
end

--- Creates a TextLabel for a frame title.
-- @param parent GuiObject - The parent of the title bar.
-- @param text string - The text content of the title.
-- @param textColor Color3 - The color of the title text.
-- @return TextLabel - The created title label.
local function createTitleBar(parent: GuiObject, text: string, textColor: Color3): TextLabel
    local titleBar = Instance.new("TextLabel")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 30) -- Full width, 30px height
    titleBar.BackgroundTransparency = 1
    titleBar.TextColor3 = textColor
    titleBar.Text = text
    titleBar.Font = Enum.Font.SourceSansBold
    titleBar.TextSize = 18
    titleBar.TextScaled = true -- Scale text to fit
    titleBar.TextWrapped = true
    titleBar.TextXAlignment = Enum.TextXAlignment.Center
    titleBar.Parent = parent
    titleBar.ZIndex = 2 -- Ensure title is above content

    -- Add a small minimize/maximize button or indicator
    local toggleButton = Instance.new("TextLabel")
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

    -- Event listener for toggle button
    toggleButton.MouseButton1Click:Connect(function()
        local frameName = parent.Name
        uiStates[frameName] = not (uiStates[frameName] or false) -- Toggle state
        local isMinimized = uiStates[frameName]
        toggleButton.Text = isMinimized and "[+]" or "[-]"

        -- Animate frame size change
        local targetSize = isMinimized and UDim2.new(parent.Size.X.Scale, parent.Size.X.Offset, 0, 30) or UDim2.new(parent.Size.X.Scale, parent.Size.X.Offset, 0, 250) -- Default full height
        if frameName == "StartFrame" then
            targetSize = isMinimized and UDim2.new(parent.Size.X.Scale, parent.Size.X.Offset, 0, 30) or UDim2.new(parent.Size.X.Scale, parent.Size.X.Offset, 0, 100)
        end

        local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        game:GetService("TweenService"):Create(parent, tweenInfo, { Size = targetSize }):Play()

        -- Toggle visibility of children (excluding title bar itself)
        for _, child in pairs(parent:GetChildren()) do
            if child ~= titleBar and child ~= toggleButton then
                child.Visible = not isMinimized
            end
        end
    end)

    return titleBar
end

--- Sets up drag functionality for a UI frame.
-- @param frame Frame - The frame to make draggable.
-- @param titleBar TextLabel - The title bar that acts as the drag handle.
local function setupDrag(frame: Frame, titleBar: TextLabel)
    titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            draggingFrame = frame
            dragStartPos = input.Position
            dragStartFramePos = frame.Position
            titleBar.Cursor = Enum.Cursor.Grabbing -- Change cursor while dragging
        end
    end)

    titleBar.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            draggingFrame = nil
            titleBar.Cursor = Enum.Cursor.Grab -- Reset cursor
        end
    end)
end

-- Global InputChanged handler for dragging
UserInputService.InputChanged:Connect(function(input)
    if draggingFrame and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStartPos
        draggingFrame.Position = UDim2.new(
            dragStartFramePos.X.Scale,
            dragStartFramePos.X.Offset + delta.X,
            dragStartFramePos.Y.Scale,
            dragStartFramePos.Y.Offset + delta.Y
        )
    end
end)

-- Global InputBegan handler to close dropdowns when clicking outside
UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        local target = input.Target

        -- Check Method Dropdown
        local methodListFrame = uiElements.MethodListFrame as Frame
        local methodDropdownButton = uiElements.MethodDropdownButton as TextButton
        if methodListFrame and methodDropdownButton and methodListFrame.Visible and not target:IsDescendantOf(methodDropdownButton) then
            methodListFrame.Visible = false
        end

        -- Check Remote Dropdown
        local remoteListFrame = uiElements.RemoteListFrame as Frame
        local remoteDropdownButton = uiElements.RemoteDropdownButton as TextButton
        if remoteListFrame and remoteDropdownButton and remoteListFrame.Visible and not target:IsDescendantOf(remoteDropdownButton) then
            remoteListFrame.Visible = false
        end
    end
end)

--- Creates a styled TextButton.
-- @param parent GuiObject - The parent of the button.
-- @param text string - The text content of the button.
-- @param position UDim2 - The position of the button.
-- @param size UDim2 - The size of the button.
-- @param bgColor Color3 - The background color of the button.
-- @param textColor Color3 - The text color of the button.
-- @return TextButton - The created button.
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

    -- Button hover animation
    button.MouseEnter:Connect(function()
        button:TweenBackgroundColor3(BUTTON_HOVER_COLOR, Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.1, true)
    end)
    button.MouseLeave:Connect(function()
        if button.BackgroundColor3 ~= BUTTON_ACTIVE_COLOR then -- Don't change if it's the active (STOP) color
            button:TweenBackgroundColor3(bgColor, Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.1, true)
        end
    end)

    return button
end

--- Creates a styled TextBox.
-- @param parent GuiObject - The parent of the textbox.
-- @param placeholder string - The placeholder text.
-- @param position UDim2 - The position of the textbox.
-- @param size UDim2 - The size of the textbox.
-- @return TextBox - The created textbox.
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

--- Populates the remote selection dropdown with detected remotes.
local function populateRemotes()
    local remoteScrollingFrame = uiElements.RemoteScrollingFrame as ScrollingFrame
    local remoteDropdownButton = uiElements.RemoteDropdownButton as TextButton

    -- Clear existing buttons
    for _, child in pairs(remoteScrollingFrame:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end

    local yOffset = 0
    -- Add "All Remotes" option
    local allButton = createStyledButton(remoteScrollingFrame, "Semua Remote", UDim2.new(0, 0, 0, yOffset), UDim2.new(1, 0, 0, 25), INPUT_BACKGROUND_COLOR, TEXT_COLOR_LIGHT)
    allButton.MouseButton1Click:Connect(function()
        selectedRemote = nil
        remoteDropdownButton.Text = "Pilih Remote: Semua"
        uiElements.RemoteListFrame.Visible = false
        updateProcessLog("Remote yang dipilih: Semua Remote.")
    end)
    yOffset = yOffset + 25

    -- Add buttons for each detected remote
    for _, remote in ipairs(remoteList) do
        local button = createStyledButton(remoteScrollingFrame, remote.Name, UDim2.new(0, 0, 0, yOffset), UDim2.new(1, 0, 0, 25), INPUT_BACKGROUND_COLOR, TEXT_COLOR_LIGHT)
        button.MouseButton1Click:Connect(function()
            selectedRemote = remote
            remoteDropdownButton.Text = "Pilih Remote: " .. remote.Name
            uiElements.RemoteListFrame.Visible = false
            updateProcessLog("Remote yang dipilih: " .. remote.Name)
        end)
        yOffset = yOffset + 25
    end

    -- Adjust CanvasSize to fit all buttons
    remoteScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, yOffset)
end

--- The main function to create the entire UI.
-- @return ScreenGui - The created ScreenGui instance.
local function createUI(): ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "ZXHELLSecurityTools"
    screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.DisplayOrder = 1000 -- Ensure it's on top of most UIs

    -- Define initial positions and sizes for frames
    -- Using scale for basic responsiveness
    local frameWidth = UDim2.new(0, 250)
    local frameHeight = UDim2.new(0, 250)
    local startFrameHeight = UDim2.new(0, 100) -- Smaller for start frame

    -- Frame: Start
    local startFrame = createFrame("StartFrame", frameWidth, UDim2.new(0.02, 0, 0.05, 0), screenGui)
    startFrame.Size = startFrameHeight -- Override default height for start frame
    local startTitle = createTitleBar(startFrame, "ZXHELL Start", TITLE_TEXT_COLOR_PRIMARY)
    setupDrag(startFrame, startTitle)
    uiElements.StartFrame = startFrame

    local startButton = createStyledButton(startFrame, "START TEST", UDim2.new(0.5, -95, 0, 40), UDim2.new(0, 190, 0, 40), BUTTON_BACKGROUND_COLOR, TEXT_COLOR_LIGHT)
    startButton.MouseButton1Click:Connect(function()
        testingActive = not testingActive
        if testingActive then
            startButton.Text = "STOP TEST"
            startButton.BackgroundColor3 = BUTTON_ACTIVE_COLOR
            task.spawn(runExploitLoop) -- Start the loop in a new thread
            logExploit("Testing", "Started", "Security test activated")
        else
            startButton.Text = "START TEST"
            startButton.BackgroundColor3 = BUTTON_BACKGROUND_COLOR
            logExploit("Testing", "Stopped", "Security test deactivated")
        end
    end)
    uiElements.StartButton = startButton

    -- Frame: Proses (Process Log)
    local processFrame = createFrame("ProcessFrame", frameWidth, UDim2.new(0.02, 260, 0.05, 0), screenGui)
    local processTitle = createTitleBar(processFrame, "Proses", TITLE_TEXT_COLOR_SECONDARY)
    setupDrag(processFrame, processTitle)
    uiElements.ProcessFrame = processFrame

    local processLogScrollingFrame = Instance.new("ScrollingFrame")
    processLogScrollingFrame.Name = "ProcessLogScrollingFrame"
    processLogScrollingFrame.Size = UDim2.new(1, -10, 1, -40)
    processLogScrollingFrame.Position = UDim2.new(0, 5, 0, 35)
    processLogScrollingFrame.BackgroundTransparency = 1
    processLogScrollingFrame.ScrollBarThickness = SCROLLBAR_THICKNESS
    processLogScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0) -- Will be adjusted dynamically
    processLogScrollingFrame.Parent = processFrame
    uiElements.ProcessLogScrollingFrame = processLogScrollingFrame

    local processLogBox = Instance.new("TextLabel")
    processLogBox.Name = "ProcessLogBox"
    processLogBox.Size = UDim2.new(1, -10, 0, 0) -- Height will be adjusted dynamically
    processLogBox.BackgroundTransparency = 1
    processLogBox.TextColor3 = LOG_TEXT_COLOR
    processLogBox.TextWrapped = true
    processLogBox.TextYAlignment = Enum.TextYAlignment.Top
    processLogBox.TextXAlignment = Enum.TextXAlignment.Left
    processLogBox.Text = "Menunggu aktivitas..."
    processLogBox.Font = Enum.Font.SourceSans
    processLogBox.TextSize = 14
    processLogBox.Parent = processLogScrollingFrame
    uiElements.ProcessLogBox = processLogBox

    -- Frame: Opsi (Options)
    local optionsFrame = createFrame("OptionsFrame", frameWidth, UDim2.new(0.02, 520, 0.05, 0), screenGui)
    local optionsTitle = createTitleBar(optionsFrame, "Opsi", TITLE_TEXT_COLOR_PRIMARY)
    setupDrag(optionsFrame, optionsTitle)
    uiElements.OptionsFrame = optionsFrame

    local argsInputLabel = Instance.new("TextLabel")
    argsInputLabel.Size = UDim2.new(1, -10, 0, 20)
    argsInputLabel.Position = UDim2.new(0, 5, 0, 35)
    argsInputLabel.BackgroundTransparency = 1
    argsInputLabel.TextColor3 = TEXT_COLOR_LIGHT
    argsInputLabel.Text = "Argumen Kustom (Lua Table/String):"
    argsInputLabel.Font = Enum.Font.SourceSansBold
    argsInputLabel.TextSize = 12
    argsInputLabel.TextXAlignment = Enum.TextXAlignment.Left
    argsInputLabel.Parent = optionsFrame

    local argsInput = createStyledTextBox(optionsFrame, "Contoh: {test=123} atau \"string\"", UDim2.new(0, 5, 0, 55), UDim2.new(1, -10, 0, 30))
    argsInput.Text = "" -- Ensure it starts empty
    argsInput.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            local success, msg = parseCustomArgs(argsInput.Text)
            updateProcessLog(success and "Argumen kustom: " .. msg or "Gagal parse: " .. msg)
        end
    end)
    uiElements.ArgsInput = argsInput

    local delayInputLabel = Instance.new("TextLabel")
    delayInputLabel.Size = UDim2.new(1, -10, 0, 20)
    delayInputLabel.Position = UDim2.new(0, 5, 0, 95)
    delayInputLabel.BackgroundTransparency = 1
    delayInputLabel.TextColor3 = TEXT_COLOR_LIGHT
    delayInputLabel.Text = "Delay (detik, misal: 0.01):"
    delayInputLabel.Font = Enum.Font.SourceSansBold
    delayInputLabel.TextSize = 12
    delayInputLabel.TextXAlignment = Enum.TextXAlignment.Left
    delayInputLabel.Parent = optionsFrame

    local delayInput = createStyledTextBox(optionsFrame, "0.01", UDim2.new(0, 5, 0, 115), UDim2.new(1, -10, 0, 30))
    delayInput.Text = "0.01" -- Default value
    uiElements.DelayInput = delayInput

    -- Frame: Status (Vulnerability Log)
    local statusFrame = createFrame("StatusFrame", frameWidth, UDim2.new(0.02, 780, 0.05, 0), screenGui)
    local statusTitle = createTitleBar(statusFrame, "Status", TITLE_TEXT_COLOR_SECONDARY)
    setupDrag(statusFrame, statusTitle)
    uiElements.StatusFrame = statusFrame

    local statusLogScrollingFrame = Instance.new("ScrollingFrame")
    statusLogScrollingFrame.Name = "StatusLogScrollingFrame"
    statusLogScrollingFrame.Size = UDim2.new(1, -10, 1, -40)
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
    statusLogBox.Text = "Kerentanan akan ditampilkan di sini..."
    statusLogBox.Font = Enum.Font.SourceSans
    statusLogBox.TextSize = 14
    statusLogBox.Parent = statusLogScrollingFrame
    uiElements.StatusLogBox = statusLogBox

    -- Frame: Metode Peretasan (Hacking Methods)
    local methodFrame = createFrame("MethodFrame", frameWidth, UDim2.new(0.02, 0, 0.5, 0), screenGui)
    local methodTitle = createTitleBar(methodFrame, "Metode Peretasan", TITLE_TEXT_COLOR_PRIMARY)
    setupDrag(methodFrame, methodTitle)
    uiElements.MethodFrame = methodFrame

    local methodDropdownButton = createStyledButton(methodFrame, "Pilih Metode: Auto Spam", UDim2.new(0, 5, 0, 40), UDim2.new(1, -10, 0, 30), INPUT_BACKGROUND_COLOR, TEXT_COLOR_LIGHT)
    methodDropdownButton.TextXAlignment = Enum.TextXAlignment.Left
    methodDropdownButton.Text = methodDropdownButton.Text .. " ▼" -- Add dropdown arrow
    methodDropdownButton.MouseButton1Click:Connect(function()
        uiElements.MethodListFrame.Visible = not uiElements.MethodListFrame.Visible
    end)
    uiElements.MethodDropdownButton = methodDropdownButton

    local methodListFrame = createFrame("MethodListFrame", UDim2.new(1, 0, 0, 150), UDim2.new(0, 0, 1, 0), methodDropdownButton)
    methodListFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    methodListFrame.Visible = false
    methodListFrame.ZIndex = 3 -- Ensure dropdown is above other content
    uiElements.MethodListFrame = methodListFrame

    local methodScrollingFrame = Instance.new("ScrollingFrame")
    methodScrollingFrame.Name = "MethodScrollingFrame"
    methodScrollingFrame.Size = UDim2.new(1, 0, 1, 0)
    methodScrollingFrame.BackgroundTransparency = 1
    methodScrollingFrame.ScrollBarThickness = SCROLLBAR_THICKNESS
    methodScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    methodScrollingFrame.Parent = methodListFrame
    uiElements.MethodScrollingFrame = methodScrollingFrame

    local yOffsetMethods = 0
    for _, method in ipairs(methods) do
        local button = createStyledButton(methodScrollingFrame, method.name, UDim2.new(0, 0, 0, yOffsetMethods), UDim2.new(1, 0, 0, 25), INPUT_BACKGROUND_COLOR, TEXT_COLOR_LIGHT)
        button.TextXAlignment = Enum.TextXAlignment.Left
        button.MouseButton1Click:Connect(function()
            hackMethod = method.value
            methodDropdownButton.Text = "Pilih Metode: " .. method.name .. " ▼"
            methodListFrame.Visible = false
            updateProcessLog("Metode diubah: " .. method.name)
        end)

        -- Tooltip for method description
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
        tooltip.ZIndex = 4 -- Ensure tooltip is on top

        button.MouseEnter:Connect(function() tooltip.Visible = true end)
        button.MouseLeave:Connect(function() tooltip.Visible = false end)

        yOffsetMethods = yOffsetMethods + 25
    end
    methodScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, yOffsetMethods)

    -- Single Shot Button (only visible if hackMethod is SingleShot)
    local singleShotButton = createStyledButton(methodFrame, "JALANKAN SINGLE SHOT", UDim2.new(0.5, -95, 0, 180), UDim2.new(0, 190, 0, 40), BUTTON_BACKGROUND_COLOR, TEXT_COLOR_LIGHT)
    singleShotButton.Visible = (hackMethod == "SingleShot") -- Initial visibility
    singleShotButton.MouseButton1Click:Connect(function()
        if selectedRemote then
            local argsToUse = customArgs or testArgs
            testRemote(selectedRemote, argsToUse[1], hackMethod) -- Test with the first arg
            updateProcessLog(string.format("Single Shot ke %s selesai.", selectedRemote.Name))
        else
            updateProcessLog("Pilih remote terlebih dahulu untuk Single Shot.")
        end
    end)
    uiElements.SingleShotButton = singleShotButton

    -- Update visibility of SingleShotButton when hackMethod changes
    local function updateSingleShotButtonVisibility()
        singleShotButton.Visible = (hackMethod == "SingleShot")
    end
    -- This will be called after UI creation in the main script flow

    -- Frame: Pilih Remote (Select Remote)
    local remoteFrame = createFrame("RemoteFrame", frameWidth, UDim2.new(0.02, 260, 0.5, 0), screenGui)
    local remoteTitle = createTitleBar(remoteFrame, "Pilih Remote", TITLE_TEXT_COLOR_SECONDARY)
    setupDrag(remoteFrame, remoteTitle)
    uiElements.RemoteFrame = remoteFrame

    local remoteDropdownButton = createStyledButton(remoteFrame, "Pilih Remote: Semua", UDim2.new(0, 5, 0, 40), UDim2.new(1, -10, 0, 30), INPUT_BACKGROUND_COLOR, TEXT_COLOR_LIGHT)
    remoteDropdownButton.TextXAlignment = Enum.TextXAlignment.Left
    remoteDropdownButton.Text = remoteDropdownButton.Text .. " ▼" -- Add dropdown arrow
    remoteDropdownButton.MouseButton1Click:Connect(function()
        uiElements.RemoteListFrame.Visible = not uiElements.RemoteListFrame.Visible
        populateRemotes() -- Repopulate in case new remotes were detected
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

    -- Initial population of remotes (will be called after UI creation)

    return screenGui
end

-- Initialization Sequence

-- Create the UI
local mainScreenGui = createUI()

-- Initial remote detection and UI population
if detectRemotes() then
    updateProcessLog("Terdeteksi " .. #remoteList .. " remote.")
    populateRemotes()
else
    updateProcessLog("Tidak ada remote ditemukan.")
end

-- Initial log message
updateProcessLog("ZXHELL Security Tools siap! Klik START TEST untuk mulai.")

-- Update SingleShotButton visibility based on initial hackMethod
if uiElements.SingleShotButton then
    uiElements.SingleShotButton.Visible = (hackMethod == "SingleShot")
end

-- Bind to game close for final log output (useful for debugging in Studio)
game:BindToClose(function()
    local logJson = HttpService:JSONEncode(exploitLog)
    print("Final Exploit Log:", logJson)
end)

-- Keep the script running (important for executor scripts)
-- In a real game, this would be managed by external events or services.
-- For a security tool, it typically runs as long as the game session is active.
-- No explicit loop needed here as event listeners and task.spawn handle continuous operations.

-- Listen for changes in hackMethod to update SingleShotButton visibility
-- This is a simple observer pattern. In a larger system, you might use a dedicated state manager.
local function observeHackMethod()
    if uiElements.SingleShotButton then
        uiElements.SingleShotButton.Visible = (hackMethod == "SingleShot")
    end
end
-- This is a simple way to observe the global variable.
-- In a more complex system, you might use a custom event dispatcher.
RunService.Heartbeat:Connect(observeHackMethod) -- Continuously check (lightweight for a single variable)

