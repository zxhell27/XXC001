local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents", 10)
local peachTimer = 0 -- Variabel lokal untuk simulasi timer pemanenan

-- Fungsi untuk memanen peach
local function harvestPeach()
	if peachTimer <= 0 then
		if RemoteEvents then
			RemoteEvents.HarvestPeach:FireServer() -- Panggil RemoteEvent untuk memanen
			peachTimer = 0 -- Setel ulang timer ke 0 untuk pemanenan instan
		else
			warn("RemoteEvents.HarvestPeach tidak ditemukan")
		end
	end
end

-- Loop otomatis untuk memanen tanpa cooldown
local function autoHarvestPeach()
	while true do
		harvestPeach()
		task.wait(0.01) -- Delay minimal untuk mencegah lag
	end
end

-- Jalankan loop otomatis
autoHarvestPeach()
