-- FrameVisibilityFixer.client.lua
-- Simple script to ensure only one tab is visible at a time
-- Version: 1.0.0
-- Date: 2025-05-23

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local shopGui = playerGui:WaitForChild("ShopGui")

-- Track if we've initialized
local initialized = false

-- Function to hide all content frames except the active one
local function hideAllFramesExcept(contentFrame, activeFrame)
	for _, frame in pairs(contentFrame:GetChildren()) do
		if frame:IsA("Frame") or frame:IsA("ScrollingFrame") then
			-- Ensure the frame is properly visible/invisible
			frame.Visible = (frame == activeFrame)
		end
	end
end

-- Function to set up tab button visibility control
local function setupTabVisibility()
	local mainFrame = shopGui:WaitForChild("MainFrame", 10)
	if not mainFrame then
		warn("MainFrame not found")
		return
	end

	local contentFrame = mainFrame:WaitForChild("ContentFrame", 5)
	if not contentFrame then
		warn("ContentFrame not found")
		return
	end

	local tabsFrame = mainFrame:WaitForChild("TabsFrame", 5)
	if not tabsFrame then
		warn("TabsFrame not found")
		return
	end

	-- Fix for ConnectTabButtons error - Create SellingFrame if it doesn't exist
	if not contentFrame:FindFirstChild("SellingFrame") then
		local sellingFrame = Instance.new("Frame")
		sellingFrame.Name = "SellingFrame"
		sellingFrame.Size = UDim2.new(1, 0, 1, 0)
		sellingFrame.BackgroundTransparency = 1
		sellingFrame.Visible = false
		sellingFrame.Parent = contentFrame
		print("Created missing SellingFrame")
	end

	-- Add our own click handlers to all tab buttons
	for _, button in pairs(tabsFrame:GetChildren()) do
		if button:IsA("TextButton") and button.Name:match("Tab$") then
			-- Extract the corresponding frame name
			local tabName = button.Name:gsub("Tab$", "")
			local contentName = tabName .. "Frame"

			-- Add our visibility manager
			button.MouseButton1Click:Connect(function()
				-- Small delay to let original handler run
				task.spawn(function()
					task.wait(0.03)

					-- Find the target frame
					local targetFrame = contentFrame:FindFirstChild(contentName)
					if targetFrame then
						-- Hide all and show only this one
						hideAllFramesExcept(contentFrame, targetFrame)
					end

					-- Special case for SellTab/SellingFrame/SellFrame
					if button.Name == "SellTab" then
						local sellFrame = contentFrame:FindFirstChild("SellFrame")
						if sellFrame then
							hideAllFramesExcept(contentFrame, sellFrame)
						end
					end
				end)
			end)
		end
	end

	-- Also run a continuous monitor to catch any cases where multiple frames become visible
	spawn(function()
		while wait(0.2) do
			-- Count visible frames
			local visibleFrames = {}

			for _, frame in pairs(contentFrame:GetChildren()) do
				if (frame:IsA("Frame") or frame:IsA("ScrollingFrame")) and frame.Visible then
					table.insert(visibleFrames, frame)
				end
			end

			-- If more than one is visible, keep only the last one visible
			if #visibleFrames > 1 then
				hideAllFramesExcept(contentFrame, visibleFrames[#visibleFrames])
			end
		end
	end)

	print("Tab visibility manager initialized")
end

-- Initialize after a short delay
spawn(function()
	wait(1)  -- Wait for other scripts to initialize
	if not initialized then
		setupTabVisibility()
		initialized = true
	end
end)

print("FrameVisibilityFixer loaded - " .. os.date("%Y-%m-%d %H:%M:%S"))