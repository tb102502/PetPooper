-- Place this script in StarterPlayerScripts
-- This script will remove any script-created buttons from the farming tab
-- but preserve your manually-created items

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Wait for the ShopGui to load
local function cleanupFarmingTab()
	local shopGui = playerGui:WaitForChild("ShopGui", 10)
	if not shopGui then
		warn("ShopGui not found!")
		return
	end

	local mainFrame = shopGui:WaitForChild("MainFrame")
	if not mainFrame then
		warn("MainFrame not found in ShopGui")
		return
	end

	local contentFrame = mainFrame:WaitForChild("ContentFrame")
	if not contentFrame then
		warn("ContentFrame not found in MainFrame")
		return
	end

	local farmingFrame = contentFrame:WaitForChild("FarmingFrame")
	if not farmingFrame then
		warn("FarmingFrame not found in ContentFrame")
		return
	end

	-- List of your original buttons to keep (based on the image you shared)
	local buttonsToKeep = {
		"CarrotSeed",
		"CornSeed", 
		"GoldenSeed", 
		"StrawberrySeed", 
		"ExtraPlot"
	}

	-- Function to check if we should keep a button
	local function shouldKeepButton(button)
		for _, name in ipairs(buttonsToKeep) do
			if button.Name == name then
				return true
			end
		end
		return false
	end

	-- Find and remove script-created buttons
	local removed = 0
	for _, child in pairs(farmingFrame:GetChildren()) do
		if (child:IsA("TextButton") or child:IsA("ImageButton") or child:IsA("Frame")) then
			-- If it's not in our list of buttons to keep, remove it
			if not shouldKeepButton(child) then
				-- Check if it looks like a script-created button
				if child.Name:match("^SeedItem_") or 
					child.Name:match("^ToolItem_") or 
					child.Name:match("^UpgradeItem_") or
					child.Name:match("^Item%d+$") or
					child.Name:match("^Button%d+$") or
					child.Name == "ScrollFrame" then
					child:Destroy()
					removed = removed + 1
				end
			else
				-- For the buttons we're keeping, let's remove any script-added labels or frames
				-- that might have been attached to them
				for _, subChild in pairs(child:GetChildren()) do
					if subChild.Name == "PriceLabel" or 
						subChild.Name == "Tooltip" then
						subChild:Destroy()
					end
				end
			end
		end
	end

	print("Removed " .. removed .. " script-created items from the farming tab")

	-- Optional: Fix layout of remaining buttons
	local gridLayout = farmingFrame:FindFirstChild("UIGridLayout")
	if gridLayout then
		-- Ensure the layout is set up correctly
		gridLayout.CellSize = UDim2.new(0, 100, 0, 100)
		gridLayout.CellPadding = UDim2.new(0, 10, 0, 10)
		gridLayout.SortOrder = Enum.SortOrder.Name
	end
end

-- Run the cleanup when the script loads
cleanupFarmingTab()

-- Also run cleanup whenever the shop is opened
spawn(function()
	wait(1) -- Wait for other scripts to initialize

	local shopGui = playerGui:WaitForChild("ShopGui", 10)
	if shopGui and shopGui:FindFirstChild("MainFrame") then
		shopGui.MainFrame:GetPropertyChangedSignal("Visible"):Connect(function()
			if shopGui.MainFrame.Visible then
				-- Wait a moment to let any other scripts add buttons first
				wait(0.1)
				cleanupFarmingTab()
			end
		end)
	end
end)

print("Farming tab cleanup script loaded")