-- FarmingTabFix.client.lua
-- Place this script in StarterPlayerScripts
-- This script will ensure the FarmingFrame is properly handled

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local shopGui = playerGui:WaitForChild("ShopGui", 10)

-- Wait for shop to initialize
local function waitForShop()
	if not shopGui then
		warn("ShopGui not found!")
		return false
	end

	local mainFrame = shopGui:WaitForChild("MainFrame", 10)
	if not mainFrame then
		warn("MainFrame not found!")
		return false
	end

	local contentFrame = mainFrame:WaitForChild("ContentFrame", 5)
	if not contentFrame then
		warn("ContentFrame not found!")
		return false
	end

	return mainFrame, contentFrame
end

-- Fix the farming tab when it becomes visible
local function setupFarmingTabFix()
	local mainFrame, contentFrame = waitForShop()
	if not mainFrame or not contentFrame then return end

	-- Get the farming frame
	local farmingFrame = contentFrame:FindFirstChild("FarmingFrame")
	if not farmingFrame then
		warn("FarmingFrame not found!")
		return
	end

	-- Connect to the Visible property change
	farmingFrame:GetPropertyChangedSignal("Visible"):Connect(function()
		if farmingFrame.Visible then
			print("FarmingFrame became visible - enforcing visibility rules")

			-- Hide all other frames
			for _, otherFrame in pairs(contentFrame:GetChildren()) do
				if otherFrame:IsA("Frame") or otherFrame:IsA("ScrollingFrame") then
					if otherFrame ~= farmingFrame then
						otherFrame.Visible = false
					end
				end
			end

			-- Extra check to keep only your farming elements visible
			local preserveElements = {
				"CarrotSeed",
				"CornSeed",
				"GoldenSeed", -- Based on your screenshot, this is "GOLDEN FRUIT SEED"
				"StrawberrySeed",
				"ExtraPlot",
				"UIGridLayout"  -- Keep layout if you have one
			}

			-- Make sure only your custom elements are visible
			for _, child in pairs(farmingFrame:GetChildren()) do
				local shouldKeep = false
				for _, name in ipairs(preserveElements) do
					if child.Name == name then
						shouldKeep = true
						break
					end
				end

				-- Keep your custom elements, remove anything else that's not a UI layout
				if not shouldKeep and 
					not child:IsA("UIGridLayout") and 
					not child:IsA("UIListLayout") and
					not (child:IsA("TextLabel") and child.Name == "PriceLabel") and
					not (child:IsA("TextLabel") and child.Name == "LevelLabel") then
					child.Visible = false
				end
			end
		end
	end)

	-- Also connect to MainFrame visibility changes to ensure proper setup
	mainFrame:GetPropertyChangedSignal("Visible"):Connect(function()
		if mainFrame.Visible then
			-- Make sure that competing frames from different tab systems are not conflicting
			spawn(function()
				wait(0.1) -- Give a moment for other scripts to run

				-- If farming frame is supposed to be visible, make sure others are hidden
				if farmingFrame.Visible then
					for _, otherFrame in pairs(contentFrame:GetChildren()) do
						if otherFrame:IsA("Frame") or otherFrame:IsA("ScrollingFrame") then
							if otherFrame ~= farmingFrame then
								otherFrame.Visible = false
							end
						end
					end
				end
			end)
		end
	end)
end

-- Start the fix system
spawn(function()
	wait(1) -- Give time for other scripts to initialize
	setupFarmingTabFix()
	print("Farming Tab Fix initialized")
end)