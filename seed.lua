local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

-- Variabel global
local testingActive = false
local exploitLog = {}
local remoteTimer = {} -- Timer lokal per remote
local remoteList = {} -- Daftar RemoteEvents/Functions
local selectedRemote = nil -- Remote yang dipilih
local customArgs = nil -- Argumen kustom dari input
local uiDragging = false -- Status drag UI

-- Fungsi logging
local function logExploit(action, status, details)
	local logEntry = {
		timestamp = os.time(),
		action = action,
		status = status,
		details = details
	}
	table.insert(exploitLog, logEntry)
	local logText = string.format("[%s] %s: %s (%s)", os.date("%X", logEntry.timestamp), action, status, details)
	print(logText)
	return logText
end

-- Deteksi semua RemoteEvents dan RemoteFunctions
local function detectRemotes()
	remoteList = {}
	for _, obj in pairs(ReplicatedStorage:GetDescendants()) do
		if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
			table.insert(remoteList, obj)
			remoteTimer[obj] = { lastCall = 0, cooldown = 0 } -- Timer dan cooldown lokal
			logExploit("Remote Detection", "Success", "Found: " .. obj:GetFullName())
		end
	end
	return #remoteList > 0
end

-- Argumen uji default
local testArgs = {
	nil,
	"instant",
	true,
	-1,
	999999,
	string.rep("x", 1000),
	{ exploit = "malicious", nested = { depth = 100 } },
	{ math.huge, -math.huge, 0/0 },
	"function() end",
}

-- Fungsi untuk menguji remote
local function testRemote(remote, args)
	if not remote or remoteTimer[remote].cooldown > 0 then return false end
	local success, result = pcall(function()
		if remote:IsA("RemoteEvent") then
			remote:FireServer(args)
			return "Fired"
		elseif remote:IsA("RemoteFunction") then
			return remote:InvokeServer(args)
		end
	end)
	remoteTimer[remote].lastCall = tick()
	remoteTimer[remote].cooldown = 0 -- Bypass cooldown klien
	local status = success and "Success" or "Failed"
	local details = remote:GetFullName() .. " with args: " .. tostring(args) .. ", Result: " .. tostring(result)
	logExploit("Test Remote", status, details)
	return success, status, details
end

-- Loop pengujian otomatis
local function runExploitLoop()
	if not testingActive then return end
	local argsToUse = customArgs or testArgs
	for _, remote in ipairs(remoteList) do
		if selectedRemote == nil or remote == selectedRemote then
			for _, arg in ipairs(argsToUse) do
				if not testingActive then return end
				testRemote(remote, arg)
				task.wait(0.01)
			end
		end
	end
end

-- Parsing argumen kustom
local function parseCustomArgs(input)
	local success, result = pcall(function()
		return loadstring("return " .. input)()
	end)
	if success then
		customArgs = { result }
		return true, "Parsed: " .. tostring(result)
	else
		customArgs = nil
		return false, "Invalid input: " .. tostring(result)
	end
end

-- Buat UI dengan Instance.new
local function createUI()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "AdvancedSecurityTestUI"
	screenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	-- Frame utama
	local mainFrame = Instance.new("Frame")
	mainFrame.Size = UDim2.new(0, 450, 0, 350)
	mainFrame.Position = UDim2.new(0.5, -225, 0.5, -175)
	mainFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	mainFrame.BorderSizePixel = 0
	mainFrame.ClipsDescendants = true
	mainFrame.Parent = screenGui
	Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 8)

	-- Title bar (untuk drag)
	local titleBar = Instance.new("Frame")
	titleBar.Size = UDim2.new(1, 0, 0, 30)
	titleBar.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	titleBar.BorderSizePixel = 0
	titleBar.Parent = mainFrame
	Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 8)

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, -30, 1, 0)
	titleLabel.Position = UDim2.new(0, 5, 0, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	titleLabel.Text = "Advanced Security Test"
	titleLabel.Font = Enum.Font.SourceSansBold
	titleLabel.TextSize = 18
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Parent = titleBar

	-- Tombol close
	local closeButton = Instance.new("TextButton")
	closeButton.Size = UDim2.new(0, 30, 0, 30)
	closeButton.Position = UDim2.new(1, -30, 0, 0)
	closeButton.BackgroundTransparency = 1
	closeButton.TextColor3 = Color3.fromRGB(255, 100, 100)
	closeButton.Text = "X"
	closeButton.Font = Enum.Font.SourceSansBold
	closeButton.TextSize = 18
	closeButton.Parent = titleBar

	-- Log box dengan scroll
	local logFrame = Instance.new("Frame")
	logFrame.Size = UDim2.new(1, -10, 0, 150)
	logFrame.Position = UDim2.new(0, 5, 0, 40)
	logFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	logFrame.BorderSizePixel = 0
	logFrame.Parent = mainFrame
	Instance.new("UICorner", logFrame).CornerRadius = UDim.new(0, 4)

	local logBox = Instance.new("TextBox")
	logBox.Size = UDim2.new(1, -10, 1, -10)
	logBox.Position = UDim2.new(0, 5, 0, 5)
	logBox.BackgroundTransparency = 1
	logBox.TextColor3 = Color3.fromRGB(200, 200, 200)
	logBox.TextWrapped = true
	logBox.TextYAlignment = Enum.TextYAlignment.Top
	logBox.Text = "Log: Detecting remotes..."
	logBox.MultiLine = true
	logBox.ClearTextOnFocus = false
	logBox.TextEditable = false
	logBox.Font = Enum.Font.SourceSans
	logBox.TextSize = 14
	logBox.Parent = logFrame

	local logScrolling = Instance.new("ScrollingFrame")
	logScrolling.Size = UDim2.new(1, 0, 1, 0)
	logScrolling.Position = UDim2.new(0, 0, 0, 0)
	logScrolling.BackgroundTransparency = 1
	logScrolling.ScrollBarThickness = 6
	logScrolling.CanvasSize = UDim2.new(0, 0, 0, 0)
	logScrolling.Parent = logFrame
	logBox.Parent = logScrolling

	-- Status timer
	local timerFrame = Instance.new("ScrollingFrame")
	timerFrame.Size = UDim2.new(1, -10, 0, 80)
	timerFrame.Position = UDim2.new(0, 5, 0, 195)
	timerFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
	timerFrame.ScrollBarThickness = 6
	timerFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
	timerFrame.Parent = mainFrame
	Instance.new("UICorner", timerFrame).CornerRadius = UDim.new(0, 4)

	local timerLayout = Instance.new("UIListLayout")
	timerLayout.SortOrder = Enum.SortOrder.LayoutOrder
	timerLayout.Padding = UDim.new(0, 2)
	timerLayout.Parent = timerFrame

	-- Input argumen kustom
	local argsInput = Instance.new("TextBox")
	argsInput.Size = UDim2.new(1, -10, 0, 30)
	argsInput.Position = UDim2.new(0, 5, 0, 280)
	argsInput.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	argsInput.TextColor3 = Color3.fromRGB(255, 255, 255)
	argsInput.PlaceholderText = "Enter custom args (e.g., {test=123})"
	argsInput.Font = Enum.Font.SourceSans
	argsInput.TextSize = 14
	argsInput.Parent = mainFrame
	Instance.new("UICorner", argsInput).CornerRadius = UDim.new(0, 4)

	-- Tombol kontrol
	local startButton = Instance.new("TextButton")
	startButton.Size = UDim2.new(0.33, -5, 0, 30)
	startButton.Position = UDim2.new(0, 5, 1, -35)
	startButton.BackgroundColor3 = Color3.fromRGB(0, 120, 0)
	startButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	startButton.Text = "Start Testing"
	startButton.Font = Enum.Font.SourceSansBold
	startButton.TextSize = 16
	startButton.Parent = mainFrame
	Instance.new("UICorner", startButton).CornerRadius = UDim.new(0, 4)

	local stopButton = Instance.new("TextButton")
	stopButton.Size = UDim2.new(0.33, -5, 0, 30)
	stopButton.Position = UDim2.new(0.33, 0, 1, -35)
	stopButton.BackgroundColor3 = Color3.fromRGB(120, 0, 0)
	stopButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	stopButton.Text = "Stop Testing"
	stopButton.Font = Enum.Font.SourceSansBold
	stopButton.TextSize = 16
	stopButton.Parent = mainFrame
	Instance.new("UICorner", stopButton).CornerRadius = UDim.new(0, 4)

	local singleButton = Instance.new("TextButton")
	singleButton.Size = UDim2.new(0.33, -5, 0, 30)
	singleButton.Position = UDim2.new(0.66, 0, 1, -35)
	singleButton.BackgroundColor3 = Color3.fromRGB(0, 80, 120)
	singleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	singleButton.Text = "Single Test"
	singleButton.Font = Enum.Font.SourceSansBold
	singleButton.TextSize = 16
	singleButton.Parent = mainFrame
	Instance.new("UICorner", singleButton).CornerRadius = UDim.new(0, 4)

	-- Dropdown remote
	local remoteDropdown = Instance.new("TextButton")
	remoteDropdown.Size = UDim2.new(1, -10, 0, 30)
	remoteDropdown.Position = UDim2.new(0, 5, 0, 315)
	remoteDropdown.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
	remoteDropdown.TextColor3 = Color3.fromRGB(255, 255, 255)
	remoteDropdown.Text = "Select Remote: All"
	remoteDropdown.Font = Enum.Font.SourceSans
	remoteDropdown.TextSize = 16
	remoteDropdown.Parent = mainFrame
	Instance.new("UICorner", remoteDropdown).CornerRadius = UDim.new(0, 4)

	local dropdownList = Instance.new("Frame")
	dropdownList.Size = UDim2.new(1, 0, 0, 100)
	dropdownList.Position = UDim2.new(0, 0, 1, 0)
	dropdownList.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	dropdownList.Visible = false
	dropdownList.Parent = remoteDropdown
	Instance.new("UICorner", dropdownList).CornerRadius = UDim.new(0, 4)

	local dropdownScrolling = Instance.new("ScrollingFrame")
	dropdownScrolling.Size = UDim2.new(1, 0, 1, 0)
	dropdownScrolling.BackgroundTransparency = 1
	dropdownScrolling.ScrollBarThickness = 6
	dropdownScrolling.CanvasSize = UDim2.new(0, 0, 0, 0)
	dropdownScrolling.Parent = dropdownList

	-- Animasi tombol
	local function animateButton(button, hover)
		spawn(function()
			local originalColor = button.BackgroundColor3
			local targetColor = hover and Color3.fromRGB(
				math.min(originalColor.R * 255 + 20, 255),
				math.min(originalColor.G * 255 + 20, 255),
				math.min(originalColor.B * 255 + 20, 255)
			) or originalColor
			for t = 0, 1, 0.1 do
				button.BackgroundColor3 = originalColor:Lerp(targetColor, t)
				task.wait(0.02)
			end
		end)
	end

	-- Perbarui log
	local function updateLog(text)
		logBox.Text = logBox.Text .. "\n" .. text
		logScrolling.CanvasSize = UDim2.new(0, 0, 0, logBox.TextBounds.Y)
		logScrolling.CanvasPosition = Vector2.new(0, logBox.TextBounds.Y)
	end

	-- Perbarui timer UI
	local function updateTimerUI()
		for _, child in ipairs(timerFrame:GetChildren()) do
			if child:IsA("TextLabel") then
				child:Destroy()
			end
		end
		local yOffset = 0
		for remote, timer in pairs(remoteTimer) do
			local timerLabel = Instance.new("TextLabel")
			timerLabel.Size = UDim2.new(1, -10, 0, 20)
			timerLabel.Position = UDim2.new(0, 5, 0, yOffset)
			timerLabel.BackgroundTransparency = 1
			timerLabel.TextColor3 = timer.cooldown <= 0 and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(255, 100, 100)
			timerLabel.Text = string.format("%s: %s", remote.Name, timer.cooldown <= 0 and "Ready" or string.format("%.2fs", timer.cooldown))
			timerLabel.Font = Enum.Font.SourceSans
			timerLabel.TextSize = 14
			timerLabel.TextXAlignment = Enum.TextXAlignment.Left
			timerLabel.Parent = timerFrame
			yOffset = yOffset + 22
		end
		timerFrame.CanvasSize = UDim2.new(0, 0, 0, yOffset)
	end

	-- Isi dropdown
	local function populateDropdown()
		for _, child in ipairs(dropdownScrolling:GetChildren()) do
			if child:IsA("TextButton") then
				child:Destroy()
			end
		end
		local yOffset = 0
		local allButton = Instance.new("TextButton")
		allButton.Size = UDim2.new(1, 0, 0, 25)
		allButton.Position = UDim2.new(0, 0, 0, yOffset)
		allButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
		allButton.TextColor3 = Color3.fromRGB(255, 255, 255)
		allButton.Text = "All Remotes"
		allButton.Font = Enum.Font.SourceSans
		allButton.TextSize = 14
		allButton.Parent = dropdownScrolling
		allButton.MouseButton1Click:Connect(function()
			selectedRemote = nil
			remoteDropdown.Text = "Select Remote: All"
			dropdownList.Visible = false
		end)
		allButton.MouseEnter:Connect(function() animateButton(allButton, true) end)
		allButton.MouseLeave:Connect(function() animateButton(allButton, false) end)
		yOffset = yOffset + 25
		for _, remote in ipairs(remoteList) do
			local button = Instance.new("TextButton")
			button.Size = UDim2.new(1, 0, 0, 25)
			button.Position = UDim2.new(0, 0, 0, yOffset)
			button.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
			button.TextColor3 = Color3.fromRGB(255, 255, 255)
			button.Text = remote:GetFullName()
			button.Font = Enum.Font.SourceSans
			button.TextSize = 14
			button.Parent = dropdownScrolling
			button.MouseButton1Click:Connect(function()
				selectedRemote = remote
				remoteDropdown.Text = "Select Remote: " .. remote.Name
				dropdownList.Visible = false
			end)
			button.MouseEnter:Connect(function() animateButton(button, true) end)
			button.MouseLeave:Connect(function() animateButton(button, false) end)
			yOffset = yOffset + 25
		end
		dropdownScrolling.CanvasSize = UDim2.new(0, 0, 0, yOffset)
	end

	-- Event UI
	startButton.MouseButton1Click:Connect(function()
		if not testingActive then
			testingActive = true
			startButton.BackgroundColor3 = Color3.fromRGB(0, 80, 0)
			updateLog("Testing started")
			spawn(runExploitLoop)
		end
	end)
	startButton.MouseEnter:Connect(function() animateButton(startButton, true) end)
	startButton.MouseLeave:Connect(function() animateButton(startButton, false) end)

	stopButton.MouseButton1Click:Connect(function()
		if testingActive then
			testingActive = false
			startButton.BackgroundColor3 = Color3.fromRGB(0, 120, 0)
			updateLog("Testing stopped")
		end
	end)
	stopButton.MouseEnter:Connect(function() animateButton(stopButton, true) end)
	stopButton.MouseLeave:Connect(function() animateButton(stopButton, false) end)

	singleButton.MouseButton1Click:Connect(function()
		if selectedRemote then
			local argsToUse = customArgs or testArgs
			for _, arg in ipairs(argsToUse) do
				local success, status, details = testRemote(selectedRemote, arg)
				if success then
					updateLog(status .. ": " .. details)
				end
			end
		else
			updateLog("Select a remote first")
		end
	end)
	singleButton.MouseEnter:Connect(function() animateButton(singleButton, true) end)
	singleButton.MouseLeave:Connect(function() animateButton(singleButton, false) end)

	closeButton.MouseButton1Click:Connect(function()
		screenGui:Destroy()
		testingActive = false
	end)

	argsInput.FocusLost:Connect(function(enterPressed)
		if enterPressed then
			local success, msg = parseCustomArgs(argsInput.Text)
			updateLog(success and "Custom args set: " .. msg or "Failed to parse args: " .. msg)
		end
	end)

	remoteDropdown.MouseButton1Click:Connect(function()
		dropdownList.Visible = not dropdownList.Visible
	end)

	-- Drag UI
	local dragStartPos, dragStartFramePos
	titleBar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			uiDragging = true
			dragStartPos = input.Position
			dragStartFramePos = mainFrame.Position
		end
	end)

	titleBar.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			uiDragging = false
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if uiDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			local delta = input.Position - dragStartPos
			mainFrame.Position = UDim2.new(
				dragStartFramePos.X.Scale,
				dragStartFramePos.X.Offset + delta.X,
				dragStartFramePos.Y.Scale,
				dragStartFramePos.Y.Offset + delta.Y
			)
		end
	end)

	-- Tutup dropdown saat klik di luar
	UserInputService.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 and dropdownList.Visible then
			local mousePos = UserInputService:GetMouseLocation()
			local dropdownPos = dropdownList.AbsolutePosition
			local dropdownSize = dropdownList.AbsoluteSize
			if mousePos.X < dropdownPos.X or mousePos.X > dropdownPos.X + dropdownSize.X or
				mousePos.Y < dropdownPos.Y or mousePos.Y > dropdownPos.Y + dropdownSize.Y then
				dropdownList.Visible = false
			end
		end
	end)

	-- Update timer setiap frame
	RunService.Heartbeat:Connect(function(delta)
		for _, timer in pairs(remoteTimer) do
			if timer.cooldown > 0 then
				timer.cooldown = timer.cooldown - delta
			end
		end
		updateTimerUI()
	end)

	-- Inisialisasi
	if detectRemotes() then
		updateLog("Detected " .. #remoteList .. " remotes")
		populateDropdown()
	else
		updateLog("No remotes found in ReplicatedStorage")
	end

	return screenGui
end

-- Inisialisasi
createUI()

-- Cetak log akhir
game:BindToClose(function()
	local logJson = HttpService:JSONEncode(exploitLog)
	print("Final Exploit Log:", logJson)
end)
