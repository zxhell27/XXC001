local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

-- Variabel global
local testingActive = false
local exploitLog = {}
local remoteTimer = {} -- Timer per remote
local remoteList = {} -- Daftar RemoteEvents/Functions
local selectedRemote = nil -- Remote terpilih
local customArgs = nil -- Argumen kustom
local hackMethod = "AutoSpam" -- Metode peretasan
local uiStates = {} -- Status minimize/maximize
local draggingFrame = nil -- Frame yang di-drag

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

-- Deteksi RemoteEvents/RemoteFunctions
local function detectRemotes()
	remoteList = {}
	for _, obj in pairs(ReplicatedStorage:GetDescendants()) do
		if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
			table.insert(remoteList, obj)
			remoteTimer[obj] = { lastCall = 0, cooldown = 0 }
			logExploit("Remote Detection", "Success", "Found: " .. obj:GetFullName())
		end
	end
	return #remoteList > 0
end

-- Argumen uji
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

-- Fungsi pengujian remote
local function testRemote(remote, args, method)
	if not remote or remoteTimer[remote].cooldown > 0 then return false end
	local success, result
	if method == "PropertyManip" then
		success, result = pcall(function()
			Players.LocalPlayer.leaderstats[remote.Name] = 999999
			return "Attempted property manipulation"
		end)
	else
		success, result = pcall(function()
			if remote:IsA("RemoteEvent") then
				remote:FireServer(args)
				return "Fired"
			else
				return remote:InvokeServer(args)
			end
		end)
	end
	remoteTimer[remote].lastCall = tick()
	remoteTimer[remote].cooldown = 0
	local status = success and "Success" or "Failed"
	local details = remote:GetFullName() .. " with args: " .. tostring(args) .. ", Method: " .. method .. ", Result: " .. tostring(result)
	logExploit("Test Remote", status, details)
	return success, status, details
end

-- Loop pengujian
local function runExploitLoop()
	if not testingActive then return end
	local argsToUse = customArgs or testArgs
	for _, remote in ipairs(remoteList) do
		if selectedRemote == nil or remote == selectedRemote then
			if hackMethod == "AutoSpam" then
				for _, arg in ipairs(argsToUse) do
					if not testingActive then return end
					testRemote(remote, arg, hackMethod)
					task.wait(0.01)
				end
			elseif hackMethod == "FloodTest" then
				for i = 1, 100 do
					if not testingActive then return end
					testRemote(remote, argsToUse[math.random(1, #argsToUse)], hackMethod)
					task.wait(0.001)
				end
			else
				testRemote(remote, argsToUse[1], hackMethod)
				task.wait(0.1)
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

-- Buat UI
local function createUI()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "ZXHELLSecurityTools"
	screenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.DisplayOrder = 1000

	-- Skala untuk mobile
	local scaleFactor = math.min(1, math.min(workspace.CurrentCamera.ViewportSize.X / 800, workspace.CurrentCamera.ViewportSize.Y / 600))
	local function createFrame(name, size, position)
		local frame = Instance.new("Frame")
		frame.Name = name
		frame.Size = UDim2.new(size.X.Scale * scaleFactor, size.X.Offset * scaleFactor, size.Y.Scale * scaleFactor, size.Y.Offset * scaleFactor)
		frame.Position = UDim2.new(position.X.Scale, position.X.Offset * scaleFactor, position.Y.Scale, position.Y.Offset * scaleFactor)
		frame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
		frame.BorderSizePixel = 0
		frame.ClipsDescendants = true
		Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)
		local glow = Instance.new("UIGradient")
		glow.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 255, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 255))
		})
		glow.Rotation = 45
		glow.Transparency = NumberSequence.new(0.7)
		local border = Instance.new("UIStroke")
		border.Thickness = 2
		border.Color = Color3.fromRGB(0, 255, 255)
		border.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		border.Transparency = 0.3
		border.Parent = frame
		glow.Parent = border
		frame.Parent = screenGui
		return frame
	end

	-- Animasi tombol
	local function animateButton(button, hover)
		spawn(function()
			local originalColor = button.BackgroundColor3
			local targetColor = hover and Color3.fromRGB(0, 100, 200) or Color3.fromRGB(0, 80, 150)
			for t = 0, 1, 0.1 do
				button.BackgroundColor3 = originalColor:Lerp(targetColor, t)
				task.wait(0.02)
			end
		end)
	end

	-- Fungsi minimize/maximize
	local function toggleFrame(frame, titleBar)
		local isMinimized = uiStates[frame] or false
		frame.Size = isMinimized and UDim2.new(0, 200 * scaleFactor, 0, 250 * scaleFactor) or UDim2.new(0, 200 * scaleFactor, 0, 30 * scaleFactor)
		for _, child in ipairs(frame:GetChildren()) do
			if child ~= titleBar then
				child.Visible = isMinimized
			end
		end
		uiStates[frame] = not isMinimized
	end

	-- Fungsi drag
	local function setupDrag(frame, titleBar)
		local dragStartPos, dragStartFramePos
		titleBar.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				draggingFrame = frame
				dragStartPos = input.Position
				dragStartFramePos = frame.Position
			end
		end)
		titleBar.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				draggingFrame = nil
			end
		end)
	end

	-- Frame Start
	local startFrame = createFrame("StartFrame", UDim2.new(0, 200, 0, 100), UDim2.new(0.05, 10, 0.05, 10))
	local startTitle = Instance.new("TextLabel")
	startTitle.Size = UDim2.new(1, -30, 0, 30)
	startTitle.BackgroundTransparency = 1
	startTitle.TextColor3 = Color3.fromRGB(0, 255, 255)
	startTitle.Text = "ZXHELL Start"
	startTitle.Font = Enum.Font.SourceSansBold
	startTitle.TextSize = 18 * scaleFactor
	startTitle.Parent = startFrame
	setupDrag(startFrame, startTitle)
	startTitle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			toggleFrame(startFrame, startTitle)
		end
	end)

	local startButton = Instance.new("TextButton")
	startButton.Size = UDim2.new(1, -10, 0, 40)
	startButton.Position = UDim2.new(0, 5, 0, 40)
	startButton.BackgroundColor3 = Color3.fromRGB(0, 80, 150)
	startButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	startButton.Text = "START TEST"
	startButton.Font = Enum.Font.SourceSansBold
	startButton.TextSize = 16 * scaleFactor
	startButton.Parent = startFrame
	Instance.new("UICorner", startButton).CornerRadius = UDim.new(0, 4)
	startButton.MouseButton1Click:Connect(function()
		testingActive = not testingActive
		startButton.Text = testingActive and "STOP TEST" or "START TEST"
		startButton.BackgroundColor3 = testingActive and Color3.fromRGB(150, 0, 0) or Color3.fromRGB(0, 80, 150)
		logExploit("Testing", testingActive and "Started" or "Stopped", "Security test " .. (testingActive and "activated" or "deactivated"))
		if testingActive then
			spawn(runExploitLoop)
		end
	end)
	startButton.MouseEnter:Connect(function() animateButton(startButton, true) end)
	startButton.MouseLeave:Connect(function() animateButton(startButton, false) end)

	-- Frame Proses
	local processFrame = createFrame("ProcessFrame", UDim2.new(0, 200, 0, 250), UDim2.new(0.3, 10, 0.05, 10))
	local processTitle = Instance.new("TextLabel")
	processTitle.Size = UDim2.new(1, -30, 0, 30)
	processTitle.BackgroundTransparency = 1
	processTitle.TextColor3 = Color3.fromRGB(255, 0, 255)
	processTitle.Text = "Proses"
	processTitle.Font = Enum.Font.SourceSansBold
	processTitle.TextSize = 18 * scaleFactor
	processTitle.Parent = processFrame
	setupDrag(processFrame, processTitle)
	processTitle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			toggleFrame(processFrame, processTitle)
		end
	end)

	local processLog = Instance.new("ScrollingFrame")
	processLog.Size = UDim2.new(1, -10, 1, -40)
	processLog.Position = UDim2.new(0, 5, 0, 35)
	processLog.BackgroundTransparency = 1
	processLog.ScrollBarThickness = 4
	processLog.CanvasSize = UDim2.new(0, 0, 0, 0)
	processLog.Parent = processFrame
	local processLogBox = Instance.new("TextLabel")
	processLogBox.Size = UDim2.new(1, -10, 0, 0)
	processLogBox.BackgroundTransparency = 1
	processLogBox.TextColor3 = Color3.fromRGB(200, 200, 200)
	processLogBox.TextWrapped = true
	processLogBox.TextYAlignment = Enum.TextYAlignment.Top
	processLogBox.Text = "Menunggu aktivitas..."
	processLogBox.Font = Enum.Font.SourceSans
	processLogBox.TextSize = 14 * scaleFactor
	processLogBox.Parent = processLog
	local function updateProcessLog(text)
		processLogBox.Text = processLogBox.Text .. "\n" .. text
		processLogBox.Size = UDim2.new(1, -10, 0, processLogBox.TextBounds.Y)
		processLog.CanvasSize = UDim2.new(0, 0, 0, processLogBox.TextBounds.Y)
		processLog.CanvasPosition = Vector2.new(0, processLogBox.TextBounds.Y)
	end

	-- Frame Opsi
	local optionsFrame = createFrame("OptionsFrame", UDim2.new(0, 200, 0, 250), UDim2.new(0.55, 10, 0.05, 10))
	local optionsTitle = Instance.new("TextLabel")
	optionsTitle.Size = UDim2.new(1, -30, 0, 30)
	optionsTitle.BackgroundTransparency = 1
	optionsTitle.TextColor3 = Color3.fromRGB(0, 255, 255)
	optionsTitle.Text = "Opsi"
	optionsTitle.Font = Enum.Font.SourceSansBold
	optionsTitle.TextSize = 18 * scaleFactor
	optionsTitle.Parent = optionsFrame
	setupDrag(optionsFrame, optionsTitle)
	optionsTitle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			toggleFrame(optionsFrame, optionsTitle)
		end
	end)

	local argsInput = Instance.new("TextBox")
	argsInput.Size = UDim2.new(1, -10, 0, 30)
	argsInput.Position = UDim2.new(0, 5, 0, 40)
	argsInput.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	argsInput.TextColor3 = Color3.fromRGB(255, 255, 255)
	argsInput.PlaceholderText = "Argumen kustom (misal: {test=123})"
	argsInput.Font = Enum.Font.SourceSans
	argsInput.TextSize = 14 * scaleFactor
	argsInput.Parent = optionsFrame
	Instance.new("UICorner", argsInput).CornerRadius = UDim.new(0, 4)
	argsInput.FocusLost:Connect(function(enterPressed)
		if enterPressed then
			local success, msg = parseCustomArgs(argsInput.Text)
			updateProcessLog(success and "Argumen kustom: " .. msg or "Gagal parse: " .. msg)
		end
	end)

	local delayInput = Instance.new("TextBox")
	delayInput.Size = UDim2.new(1, -10, 0, 30)
	delayInput.Position = UDim2.new(0, 5, 0, 80)
	delayInput.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	delayInput.TextColor3 = Color3.fromRGB(255, 255, 255)
	delayInput.PlaceholderText = "Delay (detik, misal: 0.01)"
	delayInput.Text = "0.01"
	delayInput.Font = Enum.Font.SourceSans
	delayInput.TextSize = 14 * scaleFactor
	delayInput.Parent = optionsFrame
	Instance.new("UICorner", delayInput).CornerRadius = UDim.new(0, 4)

	-- Frame Status
	local statusFrame = createFrame("StatusFrame", UDim2.new(0, 200, 0, 250), UDim2.new(0.8, 10, 0.05, 10))
	local statusTitle = Instance.new("TextLabel")
	statusTitle.Size = UDim2.new(1, -30, 0, 30)
	statusTitle.BackgroundTransparency = 1
	statusTitle.TextColor3 = Color3.fromRGB(255, 0, 255)
	statusTitle.Text = "Status"
	statusTitle.Font = Enum.Font.SourceSansBold
	statusTitle.TextSize = 18 * scaleFactor
	statusTitle.Parent = statusFrame
	setupDrag(statusFrame, statusTitle)
	statusTitle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			toggleFrame(statusFrame, statusTitle)
		end
	end)

	local statusLog = Instance.new("ScrollingFrame")
	statusLog.Size = UDim2.new(1, -10, 1, -40)
	statusLog.Position = UDim2.new(0, 5, 0, 35)
	statusLog.BackgroundTransparency = 1
	statusLog.ScrollBarThickness = 4
	statusLog.CanvasSize = UDim2.new(0, 0, 0, 0)
	statusLog.Parent = statusFrame
	local statusLogBox = Instance.new("TextLabel")
	statusLogBox.Size = UDim2.new(1, -10, 0, 0)
	statusLogBox.BackgroundTransparency = 1
	statusLogBox.TextColor3 = Color3.fromRGB(200, 200, 200)
	statusLogBox.TextWrapped = true
	statusLogBox.TextYAlignment = Enum.TextYAlignment.Top
	statusLogBox.Text = "Kerentanan akan ditampilkan di sini..."
	statusLogBox.Font = Enum.Font.SourceSans
	statusLogBox.TextSize = 14 * scaleFactor
	statusLogBox.Parent = statusLog
	local function updateStatusLog(text)
		if text:find("Success") then
			local remoteName = text:match("Test Remote: Success%((.-) with args") or "Unknown"
			local arg = text:match("args: (.-), Method") or "Unknown"
			local vulnText = string.format("Kerentanan: %s rentan terhadap argumen %s", remoteName, arg)
			statusLogBox.Text = statusLogBox.Text .. "\n" .. vulnText
			statusLogBox.Size = UDim2.new(1, -10, 0, statusLogBox.TextBounds.Y)
			statusLog.CanvasSize = UDim2.new(0, 0, 0, statusLogBox.TextBounds.Y)
			statusLog.CanvasPosition = Vector2.new(0, statusLogBox.TextBounds.Y)
		end
	end

	-- Frame Metode
	local methodFrame = createFrame("MethodFrame", UDim2.new(0, 200, 0, 250), UDim2.new(0.05, 10, 0.4, 10))
	local methodTitle = Instance.new("TextLabel")
	methodTitle.Size = UDim2.new(1, -30, 0, 30)
	methodTitle.BackgroundTransparency = 1
	methodTitle.TextColor3 = Color3.fromRGB(0, 255, 255)
	methodTitle.Text = "Metode Peretasan"
	methodTitle.Font = Enum.Font.SourceSansBold
	methodTitle.TextSize = 18 * scaleFactor
	methodTitle.Parent = methodFrame
	setupDrag(methodFrame, methodTitle)
	methodTitle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			toggleFrame(methodFrame, methodTitle)
		end
	end)

	local methodDropdown = Instance.new("TextButton")
	methodDropdown.Size = UDim2.new(1, -10, 0, 30)
	methodDropdown.Position = UDim2.new(0, 5, 0, 40)
	methodDropdown.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	methodDropdown.TextColor3 = Color3.fromRGB(255, 255, 255)
	methodDropdown.Text = "Pilih Metode: Auto Spam"
	methodDropdown.Font = Enum.Font.SourceSans
	methodDropdown.TextSize = 14 * scaleFactor
	methodDropdown.Parent = methodFrame
	Instance.new("UICorner", methodDropdown).CornerRadius = UDim.new(0, 4)

	local methodList = Instance.new("Frame")
	methodList.Size = UDim2.new(1, 0, 0, 100)
	methodList.Position = UDim2.new(0, 0, 1, 0)
	methodList.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
	methodList.Visible = false
	methodList.Parent = methodDropdown
	Instance.new("UICorner", methodList).CornerRadius = UDim.new(0, 4)

	local methodScrolling = Instance.new("ScrollingFrame")
	methodScrolling.Size = UDim2.new(1, 0, 1, 0)
	methodScrolling.BackgroundTransparency = 1
	methodScrolling.ScrollBarThickness = 4
	methodScrolling.CanvasSize = UDim2.new(0, 0, 0, 0)
	methodScrolling.Parent = methodList

	local methods = {
		{ name = "Auto Spam", desc = "Spam semua argumen secara otomatis" },
		{ name = "Single Shot", desc = "Uji satu argumen per klik" },
		{ name = "Custom Args", desc = "Gunakan argumen kustom" },
		{ name = "Flood Test", desc = "Spam cepat untuk uji beban" },
		{ name = "Property Manip", desc = "Coba ubah properti pemain" },
	}
	local yOffset = 0
	for _, method in ipairs(methods) do
		local button = Instance.new("TextButton")
		button.Size = UDim2.new(1, 0, 0, 25)
		button.Position = UDim2.new(0, 0, 0, yOffset)
		button.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
		button.TextColor3 = Color3.fromRGB(255, 255, 255)
		button.Text = method.name
		button.Font = Enum.Font.SourceSans
		button.TextSize = 14 * scaleFactor
		button.Parent = methodScrolling
		button.MouseButton1Click:Connect(function()
			hackMethod = method.name:gsub(" ", "")
			methodDropdown.Text = "Pilih Metode: " .. method.name
			methodList.Visible = false
			updateProcessLog("Metode diubah: " .. method.name)
		end)
		button.MouseEnter:Connect(function() animateButton(button, true) end)
		button.MouseLeave:Connect(function() animateButton(button, false) end)
		local tooltip = Instance.new("TextLabel")
		tooltip.Size = UDim2.new(0, 150, 0, 40)
		tooltip.Position = UDim2.new(1, 5, 0, 0)
		tooltip.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
		tooltip.TextColor3 = Color3.fromRGB(200, 200, 200)
		tooltip.Text = method.desc
		tooltip.TextWrapped = true
		tooltip.Visible = false
		tooltip.Parent = button
		Instance.new("UICorner", tooltip).CornerRadius = UDim.new(0, 4)
		button.MouseEnter:Connect(function() tooltip.Visible = true end)
		button.MouseLeave:Connect(function() tooltip.Visible = false end)
		yOffset = yOffset + 25
	end
	methodScrolling.CanvasSize = UDim2.new(0, 0, 0, yOffset)
	methodDropdown.MouseButton1Click:Connect(function()
		methodList.Visible = not methodList.Visible
	end)

	-- Remote Dropdown
	local remoteFrame = createFrame("RemoteFrame", UDim2.new(0, 200, 0, 250), UDim2.new(0.3, 10, 0.4, 10))
	local remoteTitle = Instance.new("TextLabel")
	remoteTitle.Size = UDim2.new(1, -30, 0, 30)
	remoteTitle.BackgroundTransparency = 1
	remoteTitle.TextColor3 = Color3.fromRGB(255, 0, 255)
	remoteTitle.Text = "Pilih Remote"
	remoteTitle.Font = Enum.Font.SourceSansBold
	remoteTitle.TextSize = 18 * scaleFactor
	remoteTitle.Parent = remoteFrame
	setupDrag(remoteFrame, remoteTitle)
	remoteTitle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			toggleFrame(remoteFrame, remoteTitle)
		end
	end)

	local remoteDropdown = Instance.new("TextButton")
	remoteDropdown.Size = UDim2.new(1, -10, 0, 30)
	remoteDropdown.Position = UDim2.new(0, 5, 0, 40)
	remoteDropdown.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	remoteDropdown.TextColor3 = Color3.fromRGB(255, 255, 255)
	remoteDropdown.Text = "Pilih Remote: Semua"
	remoteDropdown.Font = Enum.Font.SourceSans
	remoteDropdown.TextSize = 14 * scaleFactor
	remoteDropdown.Parent = remoteFrame
	Instance.new("UICorner", remoteDropdown).CornerRadius = UDim.new(0, 4)

	local remoteListFrame = Instance.new("Frame")
	remoteListFrame.Size = UDim2.new(1, 0, 0, 100)
	remoteListFrame.Position = UDim2.new(0, 0, 1, 0)
	remoteListFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
	remoteListFrame.Visible = false
	remoteListFrame.Parent = remoteDropdown
	Instance.new("UICorner", remoteListFrame).CornerRadius = UDim.new(0, 4)

	local remoteScrolling = Instance.new("ScrollingFrame")
	remoteScrolling.Size = UDim2.new(1, 0, 1, 0)
	remoteScrolling.BackgroundTransparency = 1
	remoteScrolling.ScrollBarThickness = 4
	remoteScrolling.CanvasSize = UDim2.new(0, 0, 0, 0)
	remoteScrolling.Parent = remoteListFrame

	local function populateRemotes()
		for _, child in ipairs(remoteScrolling:GetChildren()) do
			if child:IsA("TextButton") then
				child:Destroy()
			end
		end
		local yOffset = 0
		local allButton = Instance.new("TextButton")
		allButton.Size = UDim2.new(1, 0, 0, 25)
		allButton.Position = UDim2.new(0, 0, 0, yOffset)
		allButton.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
		allButton.TextColor3 = Color3.fromRGB(255, 255, 255)
		allButton.Text = "Semua Remote"
		allButton.Font = Enum.Font.SourceSans
		allButton.TextSize = 14 * scaleFactor
		allButton.Parent = remoteScrolling
		allButton.MouseButton1Click:Connect(function()
			selectedRemote = nil
			remoteDropdown.Text = "Pilih Remote: Semua"
			remoteListFrame.Visible = false
		end)
		allButton.MouseEnter:Connect(function() animateButton(allButton, true) end)
		allButton.MouseLeave:Connect(function() animateButton(allButton, false) end)
		yOffset = yOffset + 25
		for _, remote in ipairs(remoteList) do
			local button = Instance.new("TextButton")
			button.Size = UDim2.new(1, 0, 0, 25)
			button.Position = UDim2.new(0, 0, 0, yOffset)
			button.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
			button.TextColor3 = Color3.fromRGB(255, 255, 255)
			button.Text = remote.Name
			button.Font = Enum.Font.SourceSans
			button.TextSize = 14 * scaleFactor
			button.Parent = remoteScrolling
			button.MouseButton1Click:Connect(function()
				selectedRemote = remote
				remoteDropdown.Text = "Pilih Remote: " .. remote.Name
				remoteListFrame.Visible = false
			end)
			button.MouseEnter:Connect(function() animateButton(button, true) end)
			button.MouseLeave:Connect(function() animateButton(button, false) end)
			yOffset = yOffset + 25
		end
		remoteScrolling.CanvasSize = UDim2.new(0, 0, 0, yOffset)
	end

	-- Update timer
	local function updateTimerUI()
		for _, timer in pairs(remoteTimer) do
			if timer.cooldown > 0 then
				timer.cooldown = timer.cooldown - RunService.Heartbeat:Wait()
			end
		end
	end

	-- Update log dan status
	local function updateLogs(text)
		updateProcessLog(text)
		updateStatusLog(text)
	end

	-- Drag handler
	UserInputService.InputChanged:Connect(function(input)
		if draggingFrame and input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			local delta = input.Position - draggingFrame.dragStartPos
			draggingFrame.Position = UDim2.new(
				draggingFrame.dragStartFramePos.X.Scale,
				draggingFrame.dragStartFramePos.X.Offset + delta.X,
				draggingFrame.dragStartFramePos.Y.Scale,
				draggingFrame.dragStartFramePos.Y.Offset + delta.Y
			)
		end
	end)

	-- Tutup dropdown
	UserInputService.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			if methodList.Visible and not methodDropdown:IsAncestorOf(input.Target) then
				methodList.Visible = false
			end
			if remoteListFrame.Visible and not remoteDropdown:IsAncestorOf(input.Target) then
				remoteListFrame.Visible = false
			end
		end
	end)

	-- Inisialisasi
	if detectRemotes() then
		updateLogs("Terdeteksi " .. #remoteList .. " remote")
		populateRemotes()
	else
		updateLogs("Tidak ada remote ditemukan")
	end

	-- Timer update
	RunService.Heartbeat:Connect(updateTimerUI)

	-- Log awal
	updateLogs("ZXHELL Security Tools siap! Klik START TEST untuk mulai.")
	return screenGui
end

-- Inisialisasi
createUI()

-- Log akhir
game:BindToClose(function()
	local logJson = HttpService:JSONEncode(exploitLog)
	print("Final Exploit Log:", logJson)
end)
