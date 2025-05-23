-- Place this script in StarterPlayerScripts
-- This script will handle the farming items in the shop

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local shopGui = playerGui:WaitForChild("ShopGui", 10)

-- Load the farming data
local FarmingSeeds = require(ReplicatedStorage:WaitForChild("FarmingSeeds"))
local ShopData = require(ReplicatedStorage:WaitForChild("ShopData"))

-- Get RemoteEvents
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local BuySeed = RemoteEvents:WaitForChild("BuySeed")
local SendNotification = RemoteEvents:WaitForChild("SendNotification") 

	
-- Connect tab buttons to show farming tab
local function connectTabButtons()
	if not shopGui then return end

	local mainFrame = shopGui:WaitForChild("MainFrame")
	local tabsFrame = mainFrame:WaitForChild("TabsFrame")
	local contentFrame = mainFrame:WaitForChild("ContentFrame")

	local farmingTab = tabsFrame:FindFirstChild("FarmingTab")
	if farmingTab then
		farmingTab.MouseButton1Click:Connect(function()
			-- Hide all content frames
			for _, frame in pairs(contentFrame:GetChildren()) do
				if frame:IsA("Frame") then
					frame.Visible = false
				end
			end

			-- Show farming frame
			local farmingFrame = contentFrame:FindFirstChild("FarmingFrame")
			if farmingFrame then
				farmingFrame.Visible = true
			end

			-- Update tab button colors
			for _, button in pairs(tabsFrame:GetChildren()) do
				if button:IsA("TextButton") then
					if button == farmingTab then
						button.BackgroundColor3 = Color3.fromRGB(80, 120, 80) -- Active, green tint
					else
						button.BackgroundColor3 = Color3.fromRGB(60, 60, 60) -- Inactive
					end
				end
			end

		
		end)
	end
end

-- Wait for shop to initialize then set up
-- Give time for other scripts to initialize

	connectTabButtons()
	print("Farming shop module initialized")
