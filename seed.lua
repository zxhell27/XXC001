local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local Parent_upvr = script.Parent.Parent -- Asumsi script berada di lokasi yang sama dengan script asli
local peachTimer = 0 -- Variabel lokal untuk simulasi timer pemanenan

-- Modifikasi logika harvestButton
Parent_upvr.BaseFrame.peachgarden.harvestButton.MouseButton1Up:Connect(function()
	--[[ Upvalues[1]:
		[1]: RemoteEvents (readonly)
		[2]: peachTimer (read and write)
	]]
	if peachTimer <= 0 then
		RemoteEvents.HarvestPeach:FireServer() -- Panggil RemoteEvent untuk memanen
		peachTimer = 0 -- Setel ulang timer ke 0 untuk pemanenan instan
	end
end)

-- Loop otomatis untuk memanen tanpa cooldown
local function autoHarvestPeach()
	while true do
		if peachTimer <= 0 then
			RemoteEvents.HarvestPeach:FireServer() -- Panggil RemoteEvent
			peachTimer = 0 -- Pastikan timer selalu 0
		end
		task.wait(0.01) -- Delay minimal untuk mencegah lag
	end
end

-- Jalankan loop otomatis
autoHarvestPeach()
