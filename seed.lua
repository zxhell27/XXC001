local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")

-- Variabel global
local testingActive = false
local exploitLog = {}
local remoteTimer = {} -- Timer lokal untuk bypass cooldown per remote
local remoteList = {} -- Daftar RemoteEvents/Functions
local selectedRemote = nil -- Remote yang dipilih dari UI

-- Fungsi logging
local function logExploit(action, status, details)
	local logEntry = {
		timestamp = os.time(),
		action = action,
		status = status,
		details = details
	}
	table.insert(exploitLog, logEntry)
	return string.format("[%s] %s: %s (%s)", os.date("%X", logEntry.timestamp), action, status, details)
end

-- Deteksi semua RemoteEvents dan RemoteFunctions
local function detectRemotes()
	remoteList = {}
	for _, obj in pairs(ReplicatedStorage:GetDescendants()) do
		if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
			table.insert(remoteList, obj)
			remoteTimer[obj] = 0 -- Inisialisasi timer lokal untuk bypass cooldown
			logExploit("Remote Detection", "Success", "Found: " .. obj:GetFullName())
		end
	end
	return #remoteList > 0
end

-- Argumen uji untuk pengujian kerentanan
local testArgs = {
	nil,
	"instant",
	true,
	-1,
	999999,
	string.rep("x", 1000),
	{ exploit = "malicious", nested = { depth = 100 } },
	{ math.huge, -math.huge, 0/0 }, -- Nilai numerik tidak valid
	"function() end", -- String menyerupai kode
}

-- Fungsi untuk menguji remote
local function testRemote(remote, args)
	if not remote then return end
	if remoteTimer[remote] <= 0 then
		local success, result = pcall(function()
			if remote:IsA("RemoteEvent") then
				remote:FireServer(args)
				return "Fired"
			elseif remote:IsA("RemoteFunction") then
				return remote:InvokeServer(args)
			end
		end)
		if success then
			remoteTimer[remote] = 0 -- Reset timer untuk bypass cooldown
			logExploit("Test Remote", "Success", remote:GetFullName() .. " with args: " .. tostring(args) .. ", Result: " .. tostring(result))
		else
			logExploit("Test Remote", "Failed", remote:GetFullName() .. " with args: " .. tostring(args) .. ", Error: " .. tostring(result))
		end
	end
end

-- Loop pengujian agresif
local function runExploitLoop()
	if not testingActive then return end
	for _, remote in ipairs(remoteList) do
		if selectedRemote == nil or remote == selectedRemote then
			for _, arg in ipairs(testArgs) do
				testRemote(remote, arg)
				if not testingActive then return end
				task.wait(0.01)
			end
		end
	end
end

-- Buat UI dengan Instance.new
local function createUI()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "SecurityTestUI"
	screenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	screenGui.ResetOnSpawn = false

	local mainFrame = Instance.new("Frame")
	mainFrame.Size = UDim2.new(0, 400, 0, 300)
	mainFrame.Position = UDim2.new(0.5, -200, 0.5, -150)
	mainFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	mainFrame.BorderSizePixel = 0
	mainFrame.Parent = screenGui

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, 0, 0, 30)
	titleLabel.Position = UDim2.new(0, 0, 0, 0)
	titleLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	titleLabel.Text = "Security Test Exploit UI"
	titleLabel.Font = Enum.Font.SourceSansBold
	titleLabel.TextSize = 18
	titleLabel.Parent = mainFrame

	local logBox = Instance.new("TextBox")
	logBox.Size = UDim2.new(1, -10, 0, 150)
	logBox.Position = UDim2.new(0, 5, 0, 35)
	logBox.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	logBox.TextColor3 = Color3.fromRGB(200, 200, 200)
	logBox.TextWrapped = true
	logBox.TextYAlignment = Enum.TextYAlignment.Top
	logBox.Text = "Log: Detecting remotes..."
	logBox.MultiLine = true
	logBox.ClearTextOnFocus = false
	logBox.TextEditable = false
	logBox.Font = Enum.Font.SourceSans
	logBox.TextSize = 14
	logBox.Parent = mainFrame

	local startButton = Instance.new("TextButton")
	startButton.Size = UDim2.new(0.45, -5, 0, 30)
	startButton.Position = UDim2.new(0, 5, 1, -65)
	startButton.BackgroundColor3 = Color3.fromRGB(0, 120, 0)
	startButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	startButton.Text = "Start Testing"
	startButton.Font = Enum.Font.SourceSans
	startButton.TextSize = 16
	startButton.Parent = mainFrame

	local stopButton = Instance.new("TextButton")
	stopButton.Size = UDim2.new(0.45, -5, 0, 30)
	stopButton.Position = UDim2.new(0.55, 0, 1, -65)
	stopButton.BackgroundColor3 = Color3.fromRGB(120, 0, 0)
	stopButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	stopButton.Text = "Stop Testing"
	stopButton.Font = Enum.Font.SourceSans
	stopButton.TextSize = 16
	stopButton.Parent = mainFrame

	local remoteDropdown = Instance.new("TextButton")
	remoteDropdown.Size = UDim2.new(1, -10, 0, 30)
	remoteDropdown.Position = UDim2.new(0, 5, 1, -30)
	remoteDropdown.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
	remoteDropdown.TextColor3 = Color3.fromRGB(255, 255, 255)
	remoteDropdown.Text = "Select Remote: All"
	remoteDropdown.Font = Enum.Font.SourceSans
	remoteDropdown.TextSize = 16
	remoteDropdown.Parent = mainFrame

	local dropdownList = Instance.new("Frame")
	dropdownList.Size = UDim2.new(1, -10, 0, 100)
	dropdownList.Position = UDim2.new(0, 0, 1, 0)
	dropdownList.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	dropdownList.Visible = false
	dropdownList.Parent = remoteDropdown

	local scrollingFrame = Instance.new("ScrollingFrame")
	scrollingFrame.Size = UDim2.new(1, 0, 1, 0)
	scrollingFrame.BackgroundTransparency = 1
	scrollingFrame.ScrollBarThickness = 6
	scrollingFrame.Parent = dropdownList

	-- Fungsi untuk memperbarui log
	local function updateLog(text)
		logBox.Text = logBox.Text .. "\n" .. text
		logBox.CursorPosition = #logBox.Text + 1
	end

	-- Isi dropdown dengan remote
	local function populateDropdown()
		for i, child in ipairs(scrollingFrame:GetChildren()) do
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
		allButton.Parent = scrollingFrame
		allButton.MouseButton1Click:Connect(function()
			selectedRemote = nil
			remoteDropdown.Text = "Select Remote: All"
			dropdownList.Visible = false
		end)
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
			button.Parent = scrollingFrame
			button.MouseButton1Click:Connect(function()
				selectedRemote = remote
				remoteDropdown.Text = "Select Remote: " .. remote.Name
				dropdownList.Visible = false
			end)
			yOffset = yOffset + 25
		end
		scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, yOffset)
	end

	-- Event UI
	startButton.MouseButton1Click:Connect(function()
		if not testingActive then
			testingActive = true
			startButton.BackgroundColor3 = Color3.fromRGB(0, 80, 0)
			logExploit("Testing", "Started", "Exploit testing activated")
			updateLog("Testing started")
			spawn(runExploitLoop)
		end
	end)

	stopButton.MouseButton1Click:Connect(function()
		if testingActive then
			testingActive = false
			startButton.BackgroundColor3 = Color3.fromRGB(0, 120, 0)
			logExploit("Testing", "Stopped", "Exploit testing deactivated")
			updateLog("Testing stopped")
		end
	end)

	remoteDropdown.MouseButton1Click:Connect(function()
		dropdownList.Visible = not dropdownList.Visible
	end)

	-- Deteksi remote dan isi dropdown
	if detectRemotes() then
		updateLog("Detected " .. #remoteList .. " remotes")
		populateDropdown()
	else
		updateLog("No remotes found in ReplicatedStorage")
	end

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

	return screenGui
end

-- Inisialisasi
createUI()

-- Cetak log akhir saat game ditutup
game:BindToClose(function()
	local logJson = HttpService:JSONEncode(exploitLog)
	print("Final Exploit Log:", logJson)
end)
