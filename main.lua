local RemoteScrollFrame, InfoFrame, InfoButtonsScroll, HeaderTextLabel, lookingAt
local BlockList, IgnoreList, blockedArgs = {}, {}, {}
local colorSettings = {
	["MainBackground"] = {["BackgroundColor"] = Color3.fromRGB(47, 53, 66), ["BorderColor"] = Color3.fromRGB(47, 53, 66)},
	["MainButtons"] = {["BackgroundColor"] = Color3.fromRGB(53, 59, 72), ["BorderColor"] = Color3.fromRGB(53, 59, 72)},
	["MainButtonsText"] = {["TextColor"] = Color3.fromRGB(250, 251, 255)},
	["InfoFrame"] = {["BackgroundColor"] = Color3.fromRGB(47, 53, 66), ["BorderColor"] = Color3.fromRGB(47, 53, 66)},
	["ScrollFrame"] = {["BackgroundColor"] = Color3.fromRGB(47, 53, 66), ["BorderColor"] = Color3.fromRGB(47, 53, 66)}
}

local function isA(instance, class)
	return instance:IsA(class)
end

local OldEvent
OldEvent = hookfunction(Instance.new("RemoteEvent").FireServer, function(Self, ...)
	if not checkcaller() then
		local args = {...}
		if blockedArgs[Self] then
			for _, index in pairs(blockedArgs[Self]) do
				if index <= #args then args[index] = nil end
			end
		end
		if table.find(BlockList, Self) then return end
		if table.find(IgnoreList, Self) then return OldEvent(Self, unpack(args)) end
		addToList(true, Self, unpack(args))
	end
	return OldEvent(Self, ...)
end)

local OldFunction
OldFunction = hookfunction(Instance.new("RemoteFunction").InvokeServer, function(Self, ...)
	if not checkcaller() then
		local args = {...}
		if blockedArgs[Self] then
			for _, index in pairs(blockedArgs[Self]) do
				if index <= #args then args[index] = nil end
			end
		end
		if table.find(BlockList, Self) then return end
		if table.find(IgnoreList, Self) then return OldFunction(Self, unpack(args)) end
		addToList(false, Self, unpack(args))
	end
	return OldFunction(Self, ...)
end)

local OldNamecall
OldNamecall = hookmetamethod(game, "__namecall", function(Self, ...)
	local method = getnamecallmethod()
	if (method == "FireServer" and isA(Self, "RemoteEvent")) or
	   (method == "InvokeServer" and isA(Self, "RemoteFunction")) or
	   (method == "Send" and isA(Self, "UnreliableRemoteEvent")) then
		if not checkcaller() then
			if table.find(BlockList, Self) then return end
			local args = {...}
			if blockedArgs[Self] then
				for _, index in pairs(blockedArgs[Self]) do
					if index <= #args then args[index] = nil end
				end
			end
			if table.find(IgnoreList, Self) then return OldNamecall(Self, unpack(args)) end
			addToList(
				isA(Self, "RemoteEvent") and true or
				isA(Self, "RemoteFunction") and false or
				"unreliable",
				Self, unpack(args)
			)
			return OldNamecall(Self, unpack(args))
		end
	end
	return OldNamecall(Self, ...)
end)

local function glitchText(textLabel)
	local originalPosition = textLabel.Position
	local originalColor = textLabel.TextColor3
	local glitchDuration = 0.5
	local glitchInterval = 0.05
	local numGlitches = glitchDuration / glitchInterval

	for i = 1, numGlitches do
		local offsetX = math.random(-3, 3)
		local offsetY = math.random(-3, 3)
		local colorOffset = math.random(-20, 20)
		textLabel.Position = originalPosition + UDim2.new(0, offsetX, 0, offsetY)
		textLabel.TextColor3 = Color3.fromRGB(
			math.clamp(originalColor.R * 255 + colorOffset, 0, 255),
			math.clamp(originalColor.G * 255 + colorOffset, 0, 255),
			math.clamp(originalColor.B * 255 + colorOffset, 0, 255)
		)
		wait(glitchInterval)
	end
	textLabel.Position = originalPosition
	textLabel.TextColor3 = originalColor
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Parent = game:GetService("CoreGui")
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local MainFrame = Instance.new("Frame")
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = colorSettings["MainBackground"]["BackgroundColor"]
MainFrame.BorderColor3 = colorSettings["MainBackground"]["BorderColor"]
MainFrame.Position = UDim2.new(0.314148, 0, 0.255319, 0)
MainFrame.Size = UDim2.new(0, 519, 0, 349)

local HeaderFrame = Instance.new("Frame")
HeaderFrame.Parent = MainFrame
HeaderFrame.BackgroundColor3 = Color3.fromRGB(53, 59, 72)
HeaderFrame.BorderColor3 = Color3.fromRGB(53, 59, 72)
HeaderFrame.Size = UDim2.new(0, 519, 0, 50)

HeaderTextLabel = Instance.new("TextLabel")
HeaderTextLabel.Parent = HeaderFrame
HeaderTextLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
HeaderTextLabel.BackgroundTransparency = 1.000
HeaderTextLabel.Position = UDim2.new(0.0289017, 0, 0, 0)
HeaderTextLabel.Size = UDim2.new(0, 489, 0, 50)
HeaderTextLabel.Font = Enum.Font.SourceSans
HeaderTextLabel.Text = "ZXHELL X SPY"
HeaderTextLabel.TextColor3 = Color3.fromRGB(250, 251, 255)
HeaderTextLabel.TextSize = 20.000

spawn(function()
	while true do
		wait(math.random(2, 5))
		glitchText(HeaderTextLabel)
	end
end)

RemoteScrollFrame = Instance.new("ScrollingFrame")
RemoteScrollFrame.Parent = MainFrame
RemoteScrollFrame.Active = true
RemoteScrollFrame.BackgroundColor3 = colorSettings["ScrollFrame"]["BackgroundColor"]
RemoteScrollFrame.BorderColor3 = colorSettings["ScrollFrame"]["BorderColor"]
RemoteScrollFrame.Position = UDim2.new(0.0289017, 0, 0.164286, 0)
RemoteScrollFrame.Size = UDim2.new(0, 199, 0, 287)
RemoteScrollFrame.ScrollBarThickness = 5

InfoFrame = Instance.new("Frame")
InfoFrame.Parent = MainFrame
InfoFrame.BackgroundColor3 = colorSettings["InfoFrame"]["BackgroundColor"]
InfoFrame.BorderColor3 = colorSettings["InfoFrame"]["BorderColor"]
InfoFrame.Position = UDim2.new(0.455684, 0, 0.164286, 0)
InfoFrame.Size = UDim2.new(0, 268, 0, 287)

InfoButtonsScroll = Instance.new("ScrollingFrame")
InfoButtonsScroll.Parent = InfoFrame
InfoButtonsScroll.Active = true
InfoButtonsScroll.BackgroundColor3 = Color3.fromRGB(47, 53, 66)
InfoButtonsScroll.BorderColor3 = Color3.fromRGB(47, 53, 66)
InfoButtonsScroll.Position = UDim2.new(0.0746269, 0, 0.174216, 0)
InfoButtonsScroll.Size = UDim2.new(0, 228, 0, 199)
InfoButtonsScroll.ScrollBarThickness = 5

local InfoTitleTextLabel = Instance.new("TextLabel")
InfoTitleTextLabel.Parent = InfoFrame
InfoTitleTextLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
InfoTitleTextLabel.BackgroundTransparency = 1.000
InfoTitleTextLabel.Position = UDim2.new(0.0708955, 0, 0, 0)
InfoTitleTextLabel.Size = UDim2.new(0, 228, 0, 50)
InfoTitleTextLabel.Font = Enum.Font.SourceSans
InfoTitleTextLabel.Text = "Info"
InfoTitleTextLabel.TextColor3 = Color3.fromRGB(250, 251, 255)
InfoTitleTextLabel.TextSize = 20.000

local function addToList(event, remote, ...)
	local args = {...}
	local RemoteFrame = Instance.new("Frame")
	RemoteFrame.Name = remote.Name
	RemoteFrame.Parent = RemoteScrollFrame
	RemoteFrame.BackgroundColor3 = Color3.fromRGB(53, 59, 72)
	RemoteFrame.BorderColor3 = Color3.fromRGB(53, 59, 72)
	RemoteFrame.Position = UDim2.new(0.0301508, 0, 0, 0 + (#RemoteScrollFrame:GetChildren() - 1) * 35)
	RemoteFrame.Size = UDim2.new(0, 177, 0, 26)

	local RemoteTextButton = Instance.new("TextButton")
	RemoteTextButton.Parent = RemoteFrame
	RemoteTextButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	RemoteTextButton.BackgroundTransparency = 1.000
	RemoteTextButton.Size = UDim2.new(0, 177, 0, 26)
	RemoteTextButton.Font = Enum.Font.SourceSans
	RemoteTextButton.Text = remote.Name
	RemoteTextButton.TextColor3 = Color3.fromRGB(250, 251, 255)
	RemoteTextButton.TextSize = 16.000

	RemoteScrollFrame.CanvasSize = UDim2.new(0, 0, 0, RemoteScrollFrame.CanvasSize.Y.Offset + 35)

	RemoteTextButton.MouseButton1Click:Connect(function()
		for _, v in pairs(InfoButtonsScroll:GetChildren()) do
			if v:IsA("GuiButton") then v:Destroy() end
		end
		lookingAt = remote

		local CopyCodeButton = Instance.new("TextButton")
		CopyCodeButton.Parent = InfoButtonsScroll
		CopyCodeButton.BackgroundColor3 = colorSettings["MainButtons"]["BackgroundColor"]
		CopyCodeButton.BorderColor3 = colorSettings["MainButtons"]["BorderColor"]
		CopyCodeButton.Position = UDim2.new(0.0645, 0, 0, 10)
		CopyCodeButton.Size = UDim2.new(0, 294, 0, 26)
		CopyCodeButton.ZIndex = 15
		CopyCodeButton.Font = Enum.Font.SourceSans
		CopyCodeButton.Text = "Copy Script to Clipboard"
		CopyCodeButton.TextColor3 = Color3.fromRGB(250, 251, 255)
		CopyCodeButton.TextSize = 16.000

		local ExecuteButton = Instance.new("TextButton")
		ExecuteButton.Parent = InfoButtonsScroll
		ExecuteButton.BackgroundColor3 = colorSettings["MainButtons"]["BackgroundColor"]
		ExecuteButton.BorderColor3 = colorSettings["MainButtons"]["BorderColor"]
		ExecuteButton.Position = UDim2.new(0.0645, 0, 0, 45)
		ExecuteButton.Size = UDim2.new(0, 294, 0, 26)
		ExecuteButton.ZIndex = 15
		ExecuteButton.Font = Enum.Font.SourceSans
		ExecuteButton.Text = "Execute Script"
		ExecuteButton.TextColor3 = Color3.fromRGB(250, 251, 255)
		ExecuteButton.TextSize = 16.000

		local BlockButton = Instance.new("TextButton")
		BlockButton.Parent = InfoButtonsScroll
		BlockButton.BackgroundColor3 = colorSettings["MainButtons"]["BackgroundColor"]
		BlockButton.BorderColor3 = colorSettings["MainButtons"]["BorderColor"]
		BlockButton.Position = UDim2.new(0.0645, 0, 0, 80)
		BlockButton.Size = UDim2.new(0, 294, 0, 26)
		BlockButton.ZIndex = 15
		BlockButton.Font = Enum.Font.SourceSans
		BlockButton.Text = "Block Remote from firing"
		BlockButton.TextColor3 = Color3.fromRGB(250, 251, 255)
		BlockButton.TextSize = 16.000

		local IgnoreButton = Instance.new("TextButton")
		IgnoreButton.Parent = InfoButtonsScroll
		IgnoreButton.BackgroundColor3 = colorSettings["MainButtons"]["BackgroundColor"]
		IgnoreButton.BorderColor3 = colorSettings["MainButtons"]["BorderColor"]
		IgnoreButton.Position = UDim2.new(0.0645, 0, 0, 115)
		IgnoreButton.Size = UDim2.new(0, 294, 0, 26)
		IgnoreButton.ZIndex = 15
		IgnoreButton.Font = Enum.Font.SourceSans
		IgnoreButton.Text = "Ignore Remote (No Logs)"
		IgnoreButton.TextColor3 = Color3.fromRGB(250, 251, 255)
		IgnoreButton.TextSize = 16.000

		local UnblockButton = Instance.new("TextButton")
		UnblockButton.Parent = InfoButtonsScroll
		UnblockButton.BackgroundColor3 = colorSettings["MainButtons"]["BackgroundColor"]
		UnblockButton.BorderColor3 = colorSettings["MainButtons"]["BorderColor"]
		UnblockButton.Position = UDim2.new(0.0645, 0, 0, 150)
		UnblockButton.Size = UDim2.new(0, 294, 0, 26)
		UnblockButton.ZIndex = 15
		UnblockButton.Font = Enum.Font.SourceSans
		UnblockButton.Text = "Unblock Remote"
		UnblockButton.TextColor3 = Color3.fromRGB(250, 251, 255)
		UnblockButton.TextSize = 16.000

		local UnignoreButton = Instance.new("TextButton")
		UnignoreButton.Parent = InfoButtonsScroll
		UnignoreButton.BackgroundColor3 = colorSettings["MainButtons"]["BackgroundColor"]
		UnignoreButton.BorderColor3 = colorSettings["MainButtons"]["BorderColor"]
		UnignoreButton.Position = UDim2.new(0.0645, 0, 0, 185)
		UnignoreButton.Size = UDim2.new(0, 294, 0, 26)
		UnignoreButton.ZIndex = 15
		UnignoreButton.Font = Enum.Font.SourceSans
		UnignoreButton.Text = "Unignore Remote"
		UnignoreButton.TextColor3 = Color3.fromRGB(250, 251, 255)
		UnignoreButton.TextSize = 16.000

		local CopyPathButton = Instance.new("TextButton")
		CopyPathButton.Parent = InfoButtonsScroll
		CopyPathButton.BackgroundColor3 = colorSettings["MainButtons"]["BackgroundColor"]
		CopyPathButton.BorderColor3 = colorSettings["MainButtons"]["BorderColor"]
		CopyPathButton.Position = UDim2.new(0.0645, 0, 0, 220)
		CopyPathButton.Size = UDim2.new(0, 294, 0, 26)
		CopyPathButton.ZIndex = 15
		CopyPathButton.Font = Enum.Font.SourceSans
		CopyPathButton.Text = "Copy Path to Remote"
		CopyPathButton.TextColor3 = Color3.fromRGB(250, 251, 255)
		CopyPathButton.TextSize = 16.000

		local CopyArgsButton = Instance.new("TextButton")
		CopyArgsButton.Parent = InfoButtonsScroll
		CopyArgsButton.BackgroundColor3 = colorSettings["MainButtons"]["BackgroundColor"]
		CopyArgsButton.BorderColor3 = colorSettings["MainButtons"]["BorderColor"]
		CopyArgsButton.Position = UDim2.new(0.0645, 0, 0, 255)
		CopyArgsButton.Size = UDim2.new(0, 294, 0, 26)
		CopyArgsButton.ZIndex = 15
		CopyArgsButton.Font = Enum.Font.SourceSans
		CopyArgsButton.Text = "Copy Arguments to Clipboard"
		CopyArgsButton.TextColor3 = Color3.fromRGB(250, 251, 255)
		CopyArgsButton.TextSize = 16.000

		local CopyReturnButton = Instance.new("TextButton")
		if not event then
			CopyReturnButton.Parent = InfoButtonsScroll
			CopyReturnButton.BackgroundColor3 = colorSettings["MainButtons"]["BackgroundColor"]
			CopyReturnButton.BorderColor3 = colorSettings["MainButtons"]["BorderColor"]
			CopyReturnButton.Position = UDim2.new(0.0645, 0, 0, 325)
			CopyReturnButton.Size = UDim2.new(0, 294, 0, 26)
			CopyReturnButton.ZIndex = 15
			CopyReturnButton.Font = Enum.Font.SourceSans
			CopyReturnButton.Text = "Copy Return Value to Clipboard"
			CopyReturnButton.TextColor3 = Color3.fromRGB(250, 251, 255)
			CopyReturnButton.TextSize = 16.000
		end

		local BlockArgButton = Instance.new("TextButton")
		BlockArgButton.Name = "BlockArgButton"
		BlockArgButton.Parent = InfoButtonsScroll
		BlockArgButton.BackgroundColor3 = colorSettings["MainButtons"]["BackgroundColor"]
		BlockArgButton.BorderColor3 = colorSettings["MainButtons"]["BorderColor"]
		BlockArgButton.Position = UDim2.new(0.0645, 0, 0, 360)
		BlockArgButton.Size = UDim2.new(0, 294, 0, 26)
		BlockArgButton.ZIndex = 15
		BlockArgButton.Font = Enum.Font.SourceSans
		BlockArgButton.Text = "Block Argument"
		BlockArgButton.TextColor3 = Color3.fromRGB(250, 251, 255)
		BlockArgButton.TextSize = 16.000

		local InputFrame = Instance.new("Frame")
		InputFrame.Name = "InputFrame"
		InputFrame.Parent = InfoFrame
		InputFrame.BackgroundColor3 = Color3.fromRGB(53, 59, 72)
		InputFrame.BorderColor3 = Color3.fromRGB(53, 59, 72)
		InputFrame.Position = UDim2.new(0.1, 0, 0.2, 0)
		InputFrame.Size = UDim2.new(0, 200, 0, 100)
		InputFrame.Visible = false
		InputFrame.ZIndex = 20

		local InputTextBox = Instance.new("TextBox")
		InputTextBox.Name = "InputTextBox"
		InputTextBox.Parent = InputFrame
		InputTextBox.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		InputTextBox.Position = UDim2.new(0.1, 0, 0.1, 0)
		InputTextBox.Size = UDim2.new(0, 180, 0, 30)
		InputTextBox.Font = Enum.Font.SourceSans
		InputTextBox.Text = "Enter argument index"
		InputTextBox.TextColor3 = Color3.fromRGB(0, 0, 0)
		InputTextBox.TextSize = 14.000

		local ConfirmButton = Instance.new("TextButton")
		ConfirmButton.Name = "ConfirmButton"
		ConfirmButton.Parent = InputFrame
		ConfirmButton.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
		ConfirmButton.Position = UDim2.new(0.1, 0, 0.5, 0)
		ConfirmButton.Size = UDim2.new(0, 180, 0, 30)
		ConfirmButton.Font = Enum.Font.SourceSans
		ConfirmButton.Text = "Confirm"
		ConfirmButton.TextColor3 = Color3.fromRGB(0, 0, 0)
		ConfirmButton.TextSize = 16.000

		CopyCodeButton.MouseButton1Click:Connect(function()
			local code = (event and "game." or "local returnVal = game.") .. remote:GetFullName() .. (event and ":FireServer(" or ":InvokeServer(")
			for i, v in pairs(args) do code = code .. tostring(v) .. (i == #args and ")" or ", ") end
			if not event then code = code .. "\n\nprint(returnVal)" end
			setclipboard(code)
		end)

		ExecuteButton.MouseButton1Click:Connect(function()
			if event then remote:FireServer(unpack(args)) else remote:InvokeServer(unpack(args)) end
		end)

		BlockButton.MouseButton1Click:Connect(function()
			if not table.find(BlockList, remote) then table.insert(BlockList, remote) end
		end)

		IgnoreButton.MouseButton1Click:Connect(function()
			if not table.find(IgnoreList, remote) then table.insert(IgnoreList, remote) end
		end)

		UnblockButton.MouseButton1Click:Connect(function()
			for i, v in pairs(BlockList) do if v == remote then table.remove(BlockList, i) end end
		end)

		UnignoreButton.MouseButton1Click:Connect(function()
			for i, v in pairs(IgnoreList) do if v == remote then table.remove(IgnoreList, i) end end
		end)

		CopyPathButton.MouseButton1Click:Connect(function()
			setclipboard("game." .. remote:GetFullName())
		end)

		CopyArgsButton.MouseButton1Click:Connect(function()
			local argString = ""
			for i, v in pairs(args) do argString = argString .. tostring(v) .. (i == #args and "" or ", ") end
			setclipboard(argString)
		end)

		if not event then
			CopyReturnButton.MouseButton1Click:Connect(function()
				local returnVal = remote:InvokeServer(unpack(args))
				setclipboard(tostring(returnVal))
			end)
		end

		BlockArgButton.MouseButton1Click:Connect(function()
			if lookingAt then InputFrame.Visible = true end
		end)

		ConfirmButton.MouseButton1Click:Connect(function()
			local index = tonumber(InputTextBox.Text)
			if index and lookingAt then
				if not blockedArgs[lookingAt] then blockedArgs[lookingAt] = {} end
				table.insert(blockedArgs[lookingAt], index)
				InputFrame.Visible = false
			end
		end)

		if event then 
			InfoButtonsScroll.CanvasSize = UDim2.new(0, 0, 0, 400)
		else
			InfoButtonsScroll.CanvasSize = UDim2.new(0, 0, 0, 450)
		end
	end)
end

local ClearLogsButton = Instance.new("TextButton")
ClearLogsButton.Parent = MainFrame
ClearLogsButton.BackgroundColor3 = colorSettings["MainButtons"]["BackgroundColor"]
ClearLogsButton.BorderColor3 = colorSettings["MainButtons"]["BorderColor"]
ClearLogsButton.Position = UDim2.new(0.0289017, 0, 0.911174, 0)
ClearLogsButton.Size = UDim2.new(0, 199, 0, 26)
ClearLogsButton.Font = Enum.Font.SourceSans
ClearLogsButton.Text = "Clear Logs"
ClearLogsButton.TextColor3 = Color3.fromRGB(250, 251, 255)
ClearLogsButton.TextSize = 16.000

ClearLogsButton.MouseButton1Click:Connect(function()
	for _, v in pairs(RemoteScrollFrame:GetChildren()) do if v:IsA("Frame") then v:Destroy() end end
	RemoteScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
end)
