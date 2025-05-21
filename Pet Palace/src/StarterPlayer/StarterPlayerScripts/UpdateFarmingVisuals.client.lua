-- Place this script in StarterPlayerScripts
-- This script adds price labels and tooltips to your farming buttons
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local shopGui = playerGui:WaitForChild("ShopGui")

-- Load the shop data
local ShopData = require(ReplicatedStorage:WaitForChild("ShopData"))

-- Helper function to find item data by button name
local function findItemByButtonName(buttonName)
	-- Convert button name to item ID format
	local searchName
	if buttonName == "ExtraPlot" then
		searchName = "farm_plot_upgrade"
	elseif buttonName:match("Seed$") then
		-- CarrotSeed -> carrot_seeds
		searchName = buttonName:gsub("Seed$", ""):lower() .. "_seeds"
	else
		searchName = buttonName:lower()
	end

	-- Check in Farming category
	for _, item in ipairs(ShopData.Farming) do
		if string.lower(item.ID) == searchName then
			return item
		end
	end

	-- Check in FarmingTools category
	for _, item in ipairs(ShopData.FarmingTools or {}) do
		if string.lower(item.ID) == searchName then
			return item
		end
	end

	return nil
end

-- Function to create or update tooltip

-- Update visuals whenever the shop is opened
shopGui.MainFrame:GetPropertyChangedSignal("Visible"):Connect(function()
	if shopGui.MainFrame.Visible then
	end
end)