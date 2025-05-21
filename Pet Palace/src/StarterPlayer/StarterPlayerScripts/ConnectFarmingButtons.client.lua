-- Place this script in StarterPlayerScripts
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Safety check for shop GUI
local shopGui
local function getShopGui()
	if shopGui then return shopGui end

	shopGui = playerGui:FindFirstChild("ShopGui")
	if not shopGui then
		warn("ShopGui not found in PlayerGui! Will retry later.")
		return nil
	end
	return shopGui
end

-- Safely get shop data
local ShopData
pcall(function()
	ShopData = require(ReplicatedStorage:WaitForChild("ShopData"))
end)

if not ShopData then
	warn("Failed to load ShopData module!")
	ShopData = {
		Farming = {},
		FarmingTools = {}
	}
end

-- Safely get RemoteEvents
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local BuySeed

-- Safety function to get the BuySeed remote
local function getBuySeedRemote()
	if BuySeed then return BuySeed end

	BuySeed = RemoteEvents:FindFirstChild("BuySeed")
	if not BuySeed then
		warn("BuySeed remote not found! Will retry later.")
		return nil
	end
	return BuySeed
end

-- Helper function to find item data by name with error checking
local function findItemByName(itemName)
	if not itemName then return nil end
	if not ShopData then return nil end

	-- Remove "Seed" suffix if present
	local searchName = itemName:gsub("Seed$", "_seeds")
	searchName = string.lower(searchName)

	-- Special case for ExtraPlot
	if itemName == "ExtraPlot" then
		searchName = "farm_plot_upgrade"
	end

	-- Check Farming category
	if ShopData.Farming then
		for _, item in ipairs(ShopData.Farming) do
			if item and item.ID and string.lower(item.ID) == searchName then
				return item
			end
		end
	end

	-- Check FarmingTools category if it exists
	if ShopData.FarmingTools then
		for _, item in ipairs(ShopData.FarmingTools) do
			if item and item.ID and string.lower(item.ID) == searchName then
				return item
			end
		end
	end

	return nil
end

-- Function to connect buttons in the FarmingFrame with error handling
local function connectFarmingButtons()
	local shop = getShopGui()
	if not shop then 
		warn("ShopGui not available for connecting buttons")
		return false
	end

	local mainFrame = shop:FindFirstChild("MainFrame")
	if not mainFrame then
		warn("MainFrame not found in ShopGui")
		return false
	end

	local contentFrame = mainFrame:FindFirstChild("ContentFrame")
	if not contentFrame then
		warn("ContentFrame not found in MainFrame")
		return false
	end

	local farmingFrame = contentFrame:FindFirstChild("FarmingFrame")
	if not farmingFrame then
		warn("FarmingFrame not found in ContentFrame")
		return false
	end

	-- Find all buttons in the farming frame
	local connectedButtons = 0
	for _, button in pairs(farmingFrame:GetChildren()) do
		if button:IsA("TextButton") or button:IsA("ImageButton") then
			-- Find item data based on button name
			
					pcall(function()
					end)
					button.MouseButton1Click:Connect(function()
			end)
		end
	end
end
-- Retry mechanism for connecting buttons
local function setupWithRetry()
	local success = connectFarmingButtons()

	if not success then
		print("Will retry connecting farming buttons in 2 seconds...")
		wait(2)
		success = connectFarmingButtons()

		if not success then
			print("Will retry connecting farming buttons one last time in 5 seconds...")
			wait(5)
			connectFarmingButtons()
		end
	end
end

-- Wait for shop to initialize then connect buttons
spawn(function()
	wait(1) -- Give time for UI to fully load
	setupWithRetry()
end)

-- Re-connect buttons whenever the shop is shown
spawn(function()
	while wait(1) do
		local shop = getShopGui()
		if shop and shop:FindFirstChild("MainFrame") then
			local mainFrame = shop.MainFrame

			-- Check if visibility changes
			mainFrame:GetPropertyChangedSignal("Visible"):Connect(function()
				if mainFrame.Visible then
					print("Shop opened - reconnecting farming buttons")
					connectFarmingButtons()
				end
			end)

			break -- Exit the loop once we've connected the signal
		end
	end
end)

print("Farming buttons connection script loaded")