local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents", 10)
local peachTimer = 0 -- Variabel lokal untuk simulasi timer kemunculan peach

-- Akses UI heavenlypeaches
local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui", 10)
local screenGui = playerGui and playerGui:WaitForChild("ScreenGui", 10)
local baseFrame = screenGui and screenGui:WaitForChild("BaseFrame", 10)
local playerFrame = baseFrame and baseFrame:WaitForChild("player", 10)
local heavenlyPeaches = playerFrame and playerFrame:WaitForChild("heavenlypeaches", 10)

-- Fungsi untuk memanen peach
local function harvestPeach()
	if peachTimer <= 0 then
		if RemoteEvents and RemoteEvents.HarvestPeach then
			RemoteEvents.HarvestPeach:FireServer() -- Panggil RemoteEvent untuk memanen
			peachTimer = 0 -- Pastikan timer tetap 0 untuk kemunculan instan
		else
			warn("RemoteEvents.HarvestPeach tidak ditemukan")
		end
	end
end

-- Hubungkan ke heavenlypeaches jika itu tombol
if heavenlyPeaches and (heavenlyPeaches:IsA("TextButton") or heavenlyPeaches:IsA("ImageButton")) then
	heavenlyPeaches.MouseButton1Up:Connect(harvestPeach)
	heavenlyPeaches.Visible = true -- Pastikan tombol terlihat (simulasi peach muncul)
else
	warn("heavenlyPeaches bukan tombol atau tidak ditemukan")
	if heavenlyPeaches then
		heavenlyPeaches.Visible = true -- Jika indikator, buat terlihat
	end
end

-- Coba panggil PeachTimer berulang untuk mempercepat kemunculan di server
if RemoteEvents and RemoteEvents.ReincarnationEvents then
	local peachTimerRemote = RemoteEvents.ReincarnationEvents:WaitForChild("PeachTimer", 10)
	if peachTimerRemote then
		spawn(function()
			while true do
				peachTimerRemote:FireServer() -- Panggil berulang untuk coba hapus cooldown server
				task.wait(1) -- Delay 1 detik untuk menghindari spam berlebihan
			end
		end)
	end
end

-- Loop otomatis untuk memanen peach secepat mungkin
local function autoHarvestPeach()
	while true do
		harvestPeach()
		task.wait(0.01) -- Delay minimal untuk mencegah lag
	end
end

-- Jalankan loop otomatis
autoHarvestPeach()
