-- Place this script in StarterPlayerScripts
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local shopGui = playerGui:WaitForChild("ShopGui")

-- Get RemoteEvents
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local UpdatePlayerStats = RemoteEvents:WaitForChild("UpdatePlayerStats")

-- Load the shop data
local ShopData = require(ReplicatedStorage:WaitForChild("ShopData"))

-- Find farm plot upgrade data
local plotUpgradeData
for _, item in ipairs(ShopData.Farming) do
	if item.ID == "farm_plot_upgrade" then
		plotUpgradeData = item
		break
	end
end

