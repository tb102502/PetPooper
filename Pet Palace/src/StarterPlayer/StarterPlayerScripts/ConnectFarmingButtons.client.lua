-- Place this script in StarterPlayerScripts
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local shopGui = playerGui:WaitForChild("ShopGui", 10)

-- Load the shop data
local ShopData = require(ReplicatedStorage:WaitForChild("ShopData"))

-- Get RemoteEvents
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local BuySeed = RemoteEvents:WaitForChild("BuySeed")

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
	if ShopData.FarmingTools then
		for _, item in ipairs(ShopData.FarmingTools) do
			if string.lower(item.ID) == searchName then
				return item
			end
		end
	end

	return nil
end

-- Function to connect buttons in the FarmingFrame
local function connectFarmingButtons()
	if not shopGui then 
		warn("ShopGui not found!")
		return 
	end

	local mainFrame = shopGui:WaitForChild("MainFrame")
	local contentFrame = mainFrame:WaitForChild("ContentFrame")
	local farmingFrame = contentFrame:WaitForChild("FarmingFrame")

	-- Find all buttons in the farming frame
	for _, button in pairs(farmingFrame:GetChildren()) do
		if button:IsA("TextButton") or button:IsA("ImageButton") then
			-- Find item data based on button name
			local itemData = findItemByButtonName(button.Name)

			if itemData then
				-- Connect button to purchase
				button.MouseButton1Click:Connect(function()
					print("Purchasing: " .. button.Name .. " (ID: " .. itemData.ID .. ")")
					BuySeed:FireServer(itemData.ID)
				end)

				print("Connected purchase button: " .. button.Name)
			else
				warn("Could not find shop data for item: " .. button.Name)
			end
		end
	end
end

-- Wait for shop to initialize then connect buttons
spawn(function()
	wait(1) -- Give time for UI to fully load
	connectFarmingButtons()
	print("Connected farming shop buttons")
end)

-- Re-connect buttons whenever the shop is shown
spawn(function()
	while wait(1) do
		local mainFrame = shopGui and shopGui:FindFirstChild("MainFrame")
		if mainFrame then
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