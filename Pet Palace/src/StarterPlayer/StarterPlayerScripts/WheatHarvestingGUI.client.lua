--[[
    WheatHarvestingGUI.client.lua - Fixed Client-side Wheat Harvesting GUI
    Place in: StarterPlayer/StarterPlayerScripts/WheatHarvestingGUI.client.lua
    
    FIXES:
    ✅ Simplified UI for individual grain harvesting
    ✅ Better integration with scythe tool
    ✅ Real-time wheat count updates
    ✅ Improved user feedback
]]

local WheatHarvestingGUI = {}

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

-- Local player
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- State
WheatHarvestingGUI.State = {
	guiType = "none", -- "proximity", "harvesting", "none"
	isVisible = false,
	currentGUI = nil,
	remoteEvents = {},
	harvestingData = {
		harvesting = false,
		availableWheat = 0,
		message = ""
	}
}

-- UI Elements
WheatHarvestingGUI.UIElements = {
	ProximityGUI = nil,
	HarvestingGUI = nil
}

-- ========== INITIALIZATION ==========

function WheatHarvestingGUI:Initialize()
	print("WheatHarvestingGUI: Initializing FIXED wheat harvesting GUI...")

	-- Setup remote events
	self:SetupRemoteEvents()

	-- Setup input handling
	self:SetupInputHandling()

	print("WheatHarvestingGUI: ✅ FIXED wheat harvesting GUI initialized")
	return true
end

-- ========== REMOTE EVENTS SETUP ==========

function WheatHarvestingGUI:SetupRemoteEvents()
	print("WheatHarvestingGUI: Setting up remote events...")

	local gameRemotes = ReplicatedStorage:WaitForChild("GameRemotes", 30)
	if not gameRemotes then
		error("WheatHarvestingGUI: GameRemotes not found")
	end

	-- Required remote events
	local requiredEvents = {
		"ShowWheatPrompt",
		"HideWheatPrompt", 
		"StartWheatHarvesting",
		"StopWheatHarvesting",
		"WheatHarvestUpdate"
	}

	-- Connect to remote events
	for _, eventName in ipairs(requiredEvents) do
		local event = gameRemotes:WaitForChild(eventName, 10)
		if event then
			self.State.remoteEvents[eventName] = event
			print("WheatHarvestingGUI: Connected to " .. eventName)
		else
			warn("WheatHarvestingGUI: Failed to find " .. eventName)
		end
	end

	-- Connect event handlers
	self:ConnectEventHandlers()
end

function WheatHarvestingGUI:ConnectEventHandlers()
	print("WheatHarvestingGUI: Connecting event handlers...")

	-- Show wheat prompt
	if self.State.remoteEvents.ShowWheatPrompt then
		self.State.remoteEvents.ShowWheatPrompt.OnClientEvent:Connect(function(hasScythe, availableWheat)
			self:ShowProximityPrompt(hasScythe, availableWheat)
		end)
	end

	-- Hide wheat prompt
	if self.State.remoteEvents.HideWheatPrompt then
		self.State.remoteEvents.HideWheatPrompt.OnClientEvent:Connect(function()
			self:HideAllGUIs()
		end)
	end

	-- Wheat harvest update
	if self.State.remoteEvents.WheatHarvestUpdate then
		self.State.remoteEvents.WheatHarvestUpdate.OnClientEvent:Connect(function(harvestingData)
			self:UpdateHarvestingGUI(harvestingData)
		end)
	end

	print("WheatHarvestingGUI: ✅ Event handlers connected")
end

-- ========== PROXIMITY PROMPT GUI ==========

function WheatHarvestingGUI:ShowProximityPrompt(hasScythe, availableWheat)
	print("WheatHarvestingGUI: Showing proximity prompt")

	-- Hide existing GUIs
	self:HideAllGUIs()

	-- Create proximity GUI
	self:CreateProximityGUI(hasScythe, availableWheat)

	-- Update state
	self.State.guiType = "proximity"
	self.State.isVisible = true
	self.State.currentGUI = self.UIElements.ProximityGUI
end

function WheatHarvestingGUI:CreateProximityGUI(hasScythe, availableWheat)
	print("WheatHarvestingGUI: Creating FIXED proximity GUI")

	-- Create main GUI
	local proximityGUI = Instance.new("ScreenGui")
	proximityGUI.Name = "WheatProximityGUI"
	proximityGUI.ResetOnSpawn = false
	proximityGUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	proximityGUI.Parent = PlayerGui

	-- Main frame
	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainFrame"
	mainFrame.Size = UDim2.new(0, 420, 0, 180)
	mainFrame.Position = UDim2.new(0.5, -210, 0.75, -90)
	mainFrame.BackgroundColor3 = Color3.fromRGB(45, 65, 45)
	mainFrame.BorderSizePixel = 0
	mainFrame.Parent = proximityGUI

	-- Corner radius
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.04, 0)
	corner.Parent = mainFrame

	-- Add subtle border glow
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(100, 150, 100)
	stroke.Thickness = 2
	stroke.Transparency = 0.5
	stroke.Parent = mainFrame

	-- Title
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, 0, 35)
	title.Position = UDim2.new(0, 0, 0, 10)
	title.BackgroundTransparency = 1
	title.Text = "🌾 WHEAT FIELD"
	title.TextColor3 = Color3.fromRGB(255, 255, 120)
	title.TextScaled = true
	title.Font = Enum.Font.GothamBold
	title.Parent = mainFrame

	-- Wheat count
	local wheatCount = Instance.new("TextLabel")
	wheatCount.Name = "WheatCount"
	wheatCount.Size = UDim2.new(1, -20, 0, 25)
	wheatCount.Position = UDim2.new(0, 10, 0, 50)
	wheatCount.BackgroundTransparency = 1
	wheatCount.Text = availableWheat .. " wheat grains available"
	wheatCount.TextColor3 = Color3.fromRGB(200, 255, 200)
	wheatCount.TextScaled = true
	wheatCount.Font = Enum.Font.Gotham
	wheatCount.Parent = mainFrame

	-- Status and instructions
	local instructions = Instance.new("TextLabel")
	instructions.Name = "Instructions"
	instructions.Size = UDim2.new(1, -20, 0, 50)
	instructions.Position = UDim2.new(0, 10, 0, 85)
	instructions.BackgroundTransparency = 1
	instructions.TextColor3 = Color3.fromRGB(200, 200, 200)
	instructions.TextScaled = true
	instructions.Font = Enum.Font.Gotham
	instructions.TextWrapped = true
	instructions.Parent = mainFrame

	-- Set content based on player state
	if not hasScythe then
		wheatCount.TextColor3 = Color3.fromRGB(255, 200, 100)
		instructions.Text = "⚠️ You need a scythe to harvest wheat!\nFind the Scythe Giver to get one."
		instructions.TextColor3 = Color3.fromRGB(255, 200, 100)
	elseif availableWheat <= 0 then
		wheatCount.Text = "No wheat available"
		wheatCount.TextColor3 = Color3.fromRGB(255, 200, 100)
		instructions.Text = "🌾 All wheat has been harvested!\nWait for it to respawn in a few minutes."
		instructions.TextColor3 = Color3.fromRGB(255, 200, 100)
	else
		instructions.Text = "Click 'Start Harvesting' to begin!\nEach scythe swing will harvest one grain of wheat."

		-- Add start button
		local startButton = Instance.new("TextButton")
		startButton.Name = "StartButton"
		startButton.Size = UDim2.new(0, 160, 0, 30)
		startButton.Position = UDim2.new(0.5, -80, 1, -40)
		startButton.BackgroundColor3 = Color3.fromRGB(80, 140, 80)
		startButton.BorderSizePixel = 0
		startButton.Text = "🌾 Start Harvesting"
		startButton.TextColor3 = Color3.new(1, 1, 1)
		startButton.TextScaled = true
		startButton.Font = Enum.Font.GothamBold
		startButton.Parent = mainFrame

		local buttonCorner = Instance.new("UICorner")
		buttonCorner.CornerRadius = UDim.new(0.15, 0)
		buttonCorner.Parent = startButton

		startButton.MouseButton1Click:Connect(function()
			self:StartHarvesting()
		end)

		-- Button hover effects
		startButton.MouseEnter:Connect(function()
			local tween = TweenService:Create(startButton,
				TweenInfo.new(0.2, Enum.EasingStyle.Quad),
				{
					BackgroundColor3 = Color3.fromRGB(100, 160, 100),
					Size = UDim2.new(0, 170, 0, 32)
				}
			)
			tween:Play()
		end)

		startButton.MouseLeave:Connect(function()
			local tween = TweenService:Create(startButton,
				TweenInfo.new(0.2, Enum.EasingStyle.Quad),
				{
					BackgroundColor3 = Color3.fromRGB(80, 140, 80),
					Size = UDim2.new(0, 160, 0, 30)
				}
			)
			tween:Play()
		end)
	end

	-- Store reference
	self.UIElements.ProximityGUI = proximityGUI

	-- Animate in
	mainFrame.Position = UDim2.new(0.5, -210, 1, 0)
	local animTween = TweenService:Create(mainFrame,
		TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{Position = UDim2.new(0.5, -210, 0.75, -90)}
	)
	animTween:Play()

	print("WheatHarvestingGUI: ✅ FIXED proximity GUI created")
end

-- ========== HARVESTING GUI ==========

function WheatHarvestingGUI:StartHarvesting()
	print("WheatHarvestingGUI: Starting harvesting session")

	-- Send start request to server
	if self.State.remoteEvents.StartWheatHarvesting then
		self.State.remoteEvents.StartWheatHarvesting:FireServer()
	end
end

function WheatHarvestingGUI:UpdateHarvestingGUI(harvestingData)
	print("WheatHarvestingGUI: Updating harvesting GUI")

	-- Update state
	self.State.harvestingData = harvestingData

	if harvestingData.harvesting then
		self:ShowHarvestingGUI()
	else
		self:HideHarvestingGUI()
	end
end

function WheatHarvestingGUI:ShowHarvestingGUI()
	print("WheatHarvestingGUI: Showing FIXED harvesting GUI")

	-- Hide proximity GUI
	if self.UIElements.ProximityGUI then
		self.UIElements.ProximityGUI:Destroy()
		self.UIElements.ProximityGUI = nil
	end

	-- Create or update harvesting GUI
	if not self.UIElements.HarvestingGUI then
		self:CreateHarvestingGUI()
	else
		self:UpdateHarvestingDisplay()
	end

	-- Update state
	self.State.guiType = "harvesting"
	self.State.isVisible = true
	self.State.currentGUI = self.UIElements.HarvestingGUI
end

function WheatHarvestingGUI:CreateHarvestingGUI()
	print("WheatHarvestingGUI: Creating FIXED harvesting GUI")

	-- Create main GUI
	local harvestingGUI = Instance.new("ScreenGui")
	harvestingGUI.Name = "WheatHarvestingGUI"
	harvestingGUI.ResetOnSpawn = false
	harvestingGUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	harvestingGUI.Parent = PlayerGui

	-- Main frame
	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainFrame"
	mainFrame.Size = UDim2.new(0, 450, 0, 160)
	mainFrame.Position = UDim2.new(0.5, -225, 0.8, -80)
	mainFrame.BackgroundColor3 = Color3.fromRGB(45, 65, 45)
	mainFrame.BorderSizePixel = 0
	mainFrame.Parent = harvestingGUI

	-- Corner radius
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.04, 0)
	corner.Parent = mainFrame

	-- Add border glow
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(100, 150, 100)
	stroke.Thickness = 2
	stroke.Transparency = 0.3
	stroke.Parent = mainFrame

	-- Title
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, 0, 35)
	title.Position = UDim2.new(0, 0, 0, 5)
	title.BackgroundTransparency = 1
	title.Text = "🌾 HARVESTING WHEAT"
	title.TextColor3 = Color3.fromRGB(255, 255, 120)
	title.TextScaled = true
	title.Font = Enum.Font.GothamBold
	title.Parent = mainFrame

	-- Wheat count display
	local wheatCount = Instance.new("TextLabel")
	wheatCount.Name = "WheatCount"
	wheatCount.Size = UDim2.new(1, -20, 0, 30)
	wheatCount.Position = UDim2.new(0, 10, 0, 40)
	wheatCount.BackgroundTransparency = 1
	wheatCount.Text = "0 wheat remaining"
	wheatCount.TextColor3 = Color3.fromRGB(200, 255, 200)
	wheatCount.TextScaled = true
	wheatCount.Font = Enum.Font.GothamBold
	wheatCount.Parent = mainFrame

	-- Instructions
	local instructions = Instance.new("TextLabel")
	instructions.Name = "Instructions"
	instructions.Size = UDim2.new(1, -20, 0, 35)
	instructions.Position = UDim2.new(0, 10, 0, 75)
	instructions.BackgroundTransparency = 1
	instructions.Text = "Click to swing your scythe and harvest wheat!"
	instructions.TextColor3 = Color3.fromRGB(200, 200, 200)
	instructions.TextScaled = true
	instructions.Font = Enum.Font.Gotham
	instructions.TextWrapped = true
	instructions.Parent = mainFrame

	-- Stop button
	local stopButton = Instance.new("TextButton")
	stopButton.Name = "StopButton"
	stopButton.Size = UDim2.new(0, 100, 0, 25)
	stopButton.Position = UDim2.new(0.5, -50, 1, -35)
	stopButton.BackgroundColor3 = Color3.fromRGB(180, 80, 80)
	stopButton.BorderSizePixel = 0
	stopButton.Text = "Stop"
	stopButton.TextColor3 = Color3.new(1, 1, 1)
	stopButton.TextScaled = true
	stopButton.Font = Enum.Font.GothamBold
	stopButton.Parent = mainFrame

	local stopButtonCorner = Instance.new("UICorner")
	stopButtonCorner.CornerRadius = UDim.new(0.15, 0)
	stopButtonCorner.Parent = stopButton

	stopButton.MouseButton1Click:Connect(function()
		self:StopHarvesting()
	end)

	-- Store reference
	self.UIElements.HarvestingGUI = harvestingGUI

	-- Initial update
	self:UpdateHarvestingDisplay()

	-- Animate in
	mainFrame.Position = UDim2.new(0.5, -225, 1, 0)
	local animTween = TweenService:Create(mainFrame,
		TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{Position = UDim2.new(0.5, -225, 0.8, -80)}
	)
	animTween:Play()

	print("WheatHarvestingGUI: ✅ FIXED harvesting GUI created")
end

function WheatHarvestingGUI:UpdateHarvestingDisplay()
	if not self.UIElements.HarvestingGUI then return end

	local data = self.State.harvestingData
	local mainFrame = self.UIElements.HarvestingGUI:FindFirstChild("MainFrame")
	if not mainFrame then return end

	-- Update wheat count
	local wheatCount = mainFrame:FindFirstChild("WheatCount")
	if wheatCount then
		wheatCount.Text = data.availableWheat .. " wheat grains remaining"

		-- Change color based on amount
		if data.availableWheat <= 0 then
			wheatCount.TextColor3 = Color3.fromRGB(255, 200, 100)
		elseif data.availableWheat < 10 then
			wheatCount.TextColor3 = Color3.fromRGB(255, 255, 150)
		else
			wheatCount.TextColor3 = Color3.fromRGB(200, 255, 200)
		end
	end

	-- Update instructions
	local instructions = mainFrame:FindFirstChild("Instructions")
	if instructions then
		if data.message and data.message ~= "" then
			instructions.Text = data.message
		else
			instructions.Text = "Click to swing your scythe and harvest wheat!"
		end
	end
end

function WheatHarvestingGUI:StopHarvesting()
	print("WheatHarvestingGUI: Stopping harvesting session")

	-- Send stop request to server
	if self.State.remoteEvents.StopWheatHarvesting then
		self.State.remoteEvents.StopWheatHarvesting:FireServer()
	end
end

function WheatHarvestingGUI:HideHarvestingGUI()
	print("WheatHarvestingGUI: Hiding harvesting GUI")

	if self.UIElements.HarvestingGUI then
		local mainFrame = self.UIElements.HarvestingGUI:FindFirstChild("MainFrame")
		if mainFrame then
			-- Animate out
			local animTween = TweenService:Create(mainFrame,
				TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
				{Position = UDim2.new(0.5, -225, 1, 0)}
			)
			animTween:Play()

			animTween.Completed:Connect(function()
				self.UIElements.HarvestingGUI:Destroy()
				self.UIElements.HarvestingGUI = nil
			end)
		else
			self.UIElements.HarvestingGUI:Destroy()
			self.UIElements.HarvestingGUI = nil
		end
	end

	-- Reset state
	self.State.guiType = "none"
	self.State.isVisible = false
	self.State.currentGUI = nil
end

-- ========== INPUT HANDLING ==========

function WheatHarvestingGUI:SetupInputHandling()
	print("WheatHarvestingGUI: Setting up FIXED input handling...")

	-- The scythe tool will handle the actual swinging and server communication
	-- This GUI just provides visual feedback

	print("WheatHarvestingGUI: ✅ FIXED input handling setup")
end

-- ========== UTILITY FUNCTIONS ==========

function WheatHarvestingGUI:HideAllGUIs()
	print("WheatHarvestingGUI: Hiding all GUIs")

	-- Hide proximity GUI
	if self.UIElements.ProximityGUI then
		self.UIElements.ProximityGUI:Destroy()
		self.UIElements.ProximityGUI = nil
	end

	-- Hide harvesting GUI
	self:HideHarvestingGUI()
end

-- ========== DEBUG FUNCTIONS ==========

function WheatHarvestingGUI:DebugStatus()
	print("=== WHEAT HARVESTING GUI DEBUG STATUS ===")
	print("GUI Type: " .. self.State.guiType)
	print("Is Visible: " .. tostring(self.State.isVisible))
	print("Current GUI: " .. (self.State.currentGUI and self.State.currentGUI.Name or "None"))
	print("Remote Events: " .. self:CountTable(self.State.remoteEvents))
	print("")
	print("Harvesting Data:")
	print("  Harvesting: " .. tostring(self.State.harvestingData.harvesting))
	print("  Available Wheat: " .. self.State.harvestingData.availableWheat)
	print("  Message: " .. (self.State.harvestingData.message or "None"))
	print("==========================================")
end

function WheatHarvestingGUI:CountTable(t)
	local count = 0
	for _ in pairs(t) do
		count = count + 1
	end
	return count
end

-- ========== CLEANUP ==========

function WheatHarvestingGUI:Cleanup()
	print("WheatHarvestingGUI: Performing cleanup...")

	self:HideAllGUIs()
	self.State.guiType = "none"
	self.State.isVisible = false
	self.State.currentGUI = nil
	self.State.remoteEvents = {}

	print("WheatHarvestingGUI: Cleanup complete")
end

-- ========== AUTO-INITIALIZATION ==========

-- Initialize when script loads
spawn(function()
	wait(3) -- Wait for ReplicatedStorage to populate
	WheatHarvestingGUI:Initialize()
end)

-- Global reference
_G.WheatHarvestingGUI = WheatHarvestingGUI

return WheatHarvestingGUI