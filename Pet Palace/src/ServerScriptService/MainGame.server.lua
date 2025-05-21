-- MainGame.lua (ServerScript)
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Reference the module
local MainGameModule = require(script.Parent:WaitForChild("MainGameModule"))

-- Setup Remote Events and Functions if needed
-- [Your remote setup code here]

-- Player joining
Players.PlayerAdded:Connect(function(player)
	-- Get player data from module
	local playerData = MainGameModule.GetPlayerData(player)

	-- Create leaderstats
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	-- Create stats
	local coins = Instance.new("IntValue")
	coins.Name = "Coins"
	coins.Value = playerData.coins
	coins.Parent = leaderstats

	local pets = Instance.new("IntValue")
	pets.Name = "Pets"
	pets.Value = #playerData.pets
	pets.Parent = leaderstats

	-- Update client
	ReplicatedStorage.RemoteEvents.UpdatePlayerStats:FireClient(player, playerData)
end)

-- Player leaving
Players.PlayerRemoving:Connect(function(player)
	MainGameModule.SavePlayerData(player)
end)

print("MainGame script loaded (using MainGameModule)")