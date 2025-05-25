-- Put this script in ServerScriptService and run it once to set up the UI elements
-- After running, you can delete this script

local Players = game:GetService("Players")

-- Function to add farming tab to a player's GUI
local function addFarmingTabToShop(player)
	local playerGui = player:WaitForChild("PlayerGui")
	local shopGui = playerGui:WaitForChild("ShopGui", 10)
	if not shopGui then 
		warn("ShopGui not found for player: " .. player.Name)
		return 
	end

	local mainFrame = shopGui:WaitForChild("MainFrame")
	local tabsFrame = mainFrame:WaitForChild("TabsFrame")
	local contentFrame = mainFrame:WaitForChild("ContentFrame")

	-- Create Farming Tab Button if it doesn't exist
	if not tabsFrame:FindFirstChild("FarmingTab") then
		local collectingTab = tabsFrame:FindFirstChild("CollectingTab")

		-- Create a new tab button based on the existing tabs
		local farmingTab = collectingTab:Clone()
		farmingTab.Name = "FarmingTab"
		farmingTab.Text = "Farming"
		farmingTab.Position = UDim2.new(0, 0, 0.4, 0) -- Position it after the existing tabs
		farmingTab.Parent = tabsFrame

		-- Adjust other tab positions if needed
		local areasTab = tabsFrame:FindFirstChild("AreasTab")
		if areasTab then
			areasTab.Position = UDim2.new(0, 0, 0.6, 0)
		end

		local premiumTab = tabsFrame:FindFirstChild("PremiumTab")
		if premiumTab then
			premiumTab.Position = UDim2.new(0, 0, 0.8, 0)
		end
	end

	-- Create Farming Content Frame if it doesn't exist
	if not contentFrame:FindFirstChild("FarmingFrame") then
		local collectingFrame = contentFrame:FindFirstChild("CollectingFrame")

		-- Create a new content frame based on existing ones
		local farmingFrame = collectingFrame:Clone()
		farmingFrame.Name = "FarmingFrame"
		farmingFrame.Visible = false

		-- Clear existing items
		for _, child in pairs(farmingFrame:GetChildren()) do
			if child:IsA("Frame") and child.Name:match("^Item%d+$") then
				child:Destroy()
			end
		end

		farmingFrame.Parent = contentFrame
	end

	print("Added Farming tab to ShopGui for player: " .. player.Name)
end

-- Add to all current players
for _, player in pairs(Players:GetPlayers()) do
	addFarmingTabToShop(player)
end

-- Add to new players
Players.PlayerAdded:Connect(addFarmingTabToShop)

print("Farming tab setup script complete")