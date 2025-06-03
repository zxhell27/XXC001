local ReplicatedStorage = game:GetService("ReplicatedStorage")
local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local peachTimer = remoteEvents.ReincarnationEvents:WaitForChild("PeachTimer")
peachTimer:FireServer()
