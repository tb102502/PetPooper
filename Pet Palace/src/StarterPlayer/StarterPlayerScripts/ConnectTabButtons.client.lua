-- Place this script in StarterPlayerScripts
-- This script ensures all tab buttons in the ShopGui are properly connected

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Function to connect tab buttons
local function connectAllTabButtons()
	local shopGui = playerGui:WaitForChild("ShopGui", 10)
	if not shopGui then
		warn("ShopGui not found!")
		return
	end

	local mainFrame = shopGui:WaitForChild("MainFrame")
	local tabsFrame = mainFrame:WaitForChild("TabsFrame")
	local contentFrame = mainFrame:WaitForChild("ContentFrame")

	-- Find all tab buttons in the TabsFrame
	for _, button in pairs(tabsFrame:GetChildren()) do
		if button:IsA("TextButton") and button.Name:match("Tab$") then
			local tabName = button.Name:gsub("Tab$", "")
			local contentName = tabName .. "Frame"

			-- Connect button click
			button.MouseButton1Click:Connect(function()
				-- Hide all content frames
				for _, frame in pairs(contentFrame:GetChildren()) do
					if frame:IsA("Frame") then
						frame.Visible = false
					end
				end

				-- Show the corresponding content frame
				local tabContent = contentFrame:FindFirstChild(contentName)
				if tabContent then
					tabContent.Visible = true
				else
					warn("Content frame not found: " .. contentName)
				end

				-- Update tab button colors
				for _, btn in pairs(tabsFrame:GetChildren()) do
					if btn:IsA("TextButton") then
						if btn == button then
							btn.BackgroundColor3 = Color3.fromRGB(80, 120, 180) -- Active
						else
							btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60) -- Inactive
						end
					end
				end
			end)

			print("Connected tab button: " .. button.Name)
		end
	end
end

-- Wait for the GUI to load, then connect buttons
spawn(function()
	wait(5) -- Give time for other scripts to initialize the GUI
	connectAllTabButtons()
end)