--[[
    WheatHarvestingGUI.client.lua - Client-side Wheat Harvesting GUI
    Place in: StarterPlayer/StarterPlayerScripts/WheatHarvestingGUI.client.lua
    
    FEATURES:
    ✅ Proximity prompt GUI like cow milking
    ✅ Harvesting progress display
    ✅ Instructions and feedback
    ✅ Integration with existing framework
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
		currentSection = 0,
		swingProgress = 0,
		maxSwings = 10,
		availableWheat = 0
	}
}

-- UI Elements
WheatHarvestingGUI.UIElements = {
	ProximityGUI = nil,
	HarvestingGUI = nil
}

-- ========== INITIALIZATION ==========

function WheatHarvestingGUI:Initialize()
	print("WheatHarvestingGUI: Initializing wheat harvesting GUI...")

	-- Setup remote events
	self:SetupRemoteEvents()

	-- Setup input handling
	self:SetupInputHandling()

	print("WheatHarvestingGUI: ✅ Wheat harvesting GUI initialized")
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
		"SwingScythe",
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
	print("WheatHarvestingGUI: Creating proximity GUI")

	-- Create main GUI
	local proximityGUI = Instance.new("ScreenGui")
	proximityGUI.Name = "WheatProximityGUI"
	proximityGUI.ResetOnSpawn = false
	proximityGUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	proximityGUI.Parent = PlayerGui

	-- Main frame
	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainFrame"
	mainFrame.Size = UDim2.new(0, 400, 0, 200)
	mainFrame.Position = UDim2.new(0.5, -200, 0.7, -100)
	mainFrame.BackgroundColor3 = Color3.fromRGB(40, 60, 40)
	mainFrame.BorderSizePixel = 0
	mainFrame.Parent = proximityGUI

	-- Corner radius
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.05, 0)
	corner.Parent = mainFrame

	-- Title
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, 0, 40)
	title.Position = UDim2.new(0, 0, 0, 10)
	title.BackgroundTransparency = 1
	title.Text = "🌾 WHEAT FIELD"
	title.TextColor3 = Color3.new(1, 1, 1)
	title.TextScaled = true
	title.Font = Enum.Font.GothamBold
	title.Parent = mainFrame

	-- Status text
	local statusText = Instance.new("TextLabel")
	statusText.Name = "StatusText"
	statusText.Size = UDim2.new(1, -20, 0, 30)
	statusText.Position = UDim2.new(0, 10, 0, 60)
	statusText.BackgroundTransparency = 1
	statusText.TextColor3 = Color3.new(1, 1, 1)
	statusText.TextScaled = true
	statusText.Font = Enum.Font.Gotham
	statusText.Parent = mainFrame

	-- Instructions
	local instructions = Instance.new("TextLabel")
	instructions.Name = "Instructions"
	instructions.Size = UDim2.new(1, -20, 0, 60)
	instructions.Position = UDim2.new(0, 10, 0, 100)
	instructions.BackgroundTransparency = 1
	instructions.TextColor3 = Color3.fromRGB(200, 200, 200)
	instructions.TextScaled = true
	instructions.Font = Enum.Font.Gotham
	instructions.TextWrapped = true
	instructions.Parent = mainFrame

	-- Set content based on player state
	if not hasScythe then
		statusText.Text = "⚠️ No Scythe Found"
		statusText.TextColor3 = Color3.fromRGB(255, 200, 100)
		instructions.Text = "You need a scythe to harvest wheat! Find the Scythe Giver to get one."
	elseif availableWheat <= 0 then
		statusText.Text = "🌾 No Wheat Available"
		statusText.TextColor3 = Color3.fromRGB(255, 200, 100)
		instructions.Text = "All wheat has been harvested! Wait for it to respawn."
	else
		statusText.Text = "🌾 " .. availableWheat .. " wheat available"
		statusText.TextColor3 = Color3.fromRGB(100, 255, 100)
		instructions.Text = "Click 'Start Harvesting' to begin! You'll need to swing your scythe 10 times per wheat."

		-- Add start button
		local startButton = Instance.new("TextButton")
		startButton.Name = "StartButton"
		startButton.Size = UDim2.new(0, 150, 0, 30)
		startButton.Position = UDim2.new(0.5, -75, 1, -40)
		startButton.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
		startButton.BorderSizePixel = 0
		startButton.Text = "Start Harvesting"
		startButton.TextColor3 = Color3.new(1, 1, 1)
		startButton.TextScaled = true
		startButton.Font = Enum.Font.GothamBold
		startButton.Parent = mainFrame

		local buttonCorner = Instance.new("UICorner")
		buttonCorner.CornerRadius = UDim.new(0.1, 0)
		buttonCorner.Parent = startButton

		startButton.MouseButton1Click:Connect(function()
			self:StartHarvesting()
		end)

		-- Button hover effect
		startButton.MouseEnter:Connect(function()
			local tween = TweenService:Create(startButton,
				TweenInfo.new(0.2, Enum.EasingStyle.Quad),
				{BackgroundColor3 = Color3.fromRGB(120, 220, 120)}
			)
			tween:Play()
		end)

		startButton.MouseLeave:Connect(function()
			local tween = TweenService:Create(startButton,
				TweenInfo.new(0.2, Enum.EasingStyle.Quad),
				{BackgroundColor3 = Color3.fromRGB(100, 200, 100)}
			)
			tween:Play()
		end)
	end

	-- Store reference
	self.UIElements.ProximityGUI = proximityGUI

	-- Animate in
	mainFrame.Size = UDim2.new(0, 0, 0, 0)
	local animTween = TweenService:Create(mainFrame,
		TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{Size = UDim2.new(0, 400, 0, 200)}
	)
	animTween:Play()

	print("WheatHarvestingGUI: ✅ Proximity GUI created")
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
	print("WheatHarvestingGUI: Showing harvesting GUI")

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
	print("WheatHarvestingGUI: Creating harvesting GUI")

	-- Create main GUI
	local harvestingGUI = Instance.new("ScreenGui")
	harvestingGUI.Name = "WheatHarvestingGUI"
	harvestingGUI.ResetOnSpawn = false
	harvestingGUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	harvestingGUI.Parent = PlayerGui

	-- Main frame
	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainFrame"
	mainFrame.Size = UDim2.new(0, 500, 0, 250)
	mainFrame.Position = UDim2.new(0.5, -250, 0.7, -125)
	mainFrame.BackgroundColor3 = Color3.fromRGB(40, 60, 40)
	mainFrame.BorderSizePixel = 0
	mainFrame.Parent = harvestingGUI

	-- Corner radius
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.05, 0)
	corner.Parent = mainFrame

	-- Title
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, 0, 40)
	title.Position = UDim2.new(0, 0, 0, 10)
	title.BackgroundTransparency = 1
	title.Text = "🌾 HARVESTING WHEAT"
	title.TextColor3 = Color3.new(1, 1, 1)
	title.TextScaled = true
	title.Font = Enum.Font.GothamBold
	title.Parent = mainFrame

	-- Section info
	local sectionInfo = Instance.new("TextLabel")
	sectionInfo.Name = "SectionInfo"
	sectionInfo.Size = UDim2.new(1, -20, 0, 30)
	sectionInfo.Position = UDim2.new(0, 10, 0, 60)
	sectionInfo.BackgroundTransparency = 1
	sectionInfo.Text = "Section 1 of 6"
	sectionInfo.TextColor3 = Color3.fromRGB(200, 200, 200)
	sectionInfo.TextScaled = true
	sectionInfo.Font = Enum.Font.Gotham
	sectionInfo.Parent = mainFrame

	-- Progress bar background
	local progressBG = Instance.new("Frame")
	progressBG.Name = "ProgressBG"
	progressBG.Size = UDim2.new(1, -40, 0, 20)
	progressBG.Position = UDim2.new(0, 20, 0, 100)
	progressBG.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	progressBG.BorderSizePixel = 0
	progressBG.Parent = mainFrame

	local progressBGCorner = Instance.new("UICorner")
	progressBGCorner.CornerRadius = UDim.new(0.5, 0)
	progressBGCorner.Parent = progressBG

	-- Progress bar
	local progressBar = Instance.new("Frame")
	progressBar.Name = "ProgressBar"
	progressBar.Size = UDim2.new(0, 0, 1, 0)
	progressBar.Position = UDim2.new(0, 0, 0, 0)
	progressBar.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
	progressBar.BorderSizePixel = 0
	progressBar.Parent = progressBG

	local progressBarCorner = Instance.new("UICorner")
	progressBarCorner.CornerRadius = UDim.new(0.5, 0)
	progressBarCorner.Parent = progressBar

	-- Progress text
	local progressText = Instance.new("TextLabel")
	progressText.Name = "ProgressText"
	progressText.Size = UDim2.new(1, -20, 0, 25)
	progressText.Position = UDim2.new(0, 10, 0, 130)
	progressText.BackgroundTransparency = 1
	progressText.Text = "0 / 10 swings"
	progressText.TextColor3 = Color3.new(1, 1, 1)
	progressText.TextScaled = true
	progressText.Font = Enum.Font.GothamBold
	progressText.Parent = mainFrame

	-- Instructions
	local instructions = Instance.new("TextLabel")
	instructions.Name = "Instructions"
	instructions.Size = UDim2.new(1, -20, 0, 40)
	instructions.Position = UDim2.new(0, 10, 0, 165)
	instructions.BackgroundTransparency = 1
	instructions.Text = "Click to swing your scythe! You need 10 swings to harvest this section."
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
	stopButton.BackgroundColor3 = Color3.fromRGB(200, 100, 100)
	stopButton.BorderSizePixel = 0
	stopButton.Text = "Stop"
	stopButton.TextColor3 = Color3.new(1, 1, 1)
	stopButton.TextScaled = true
	stopButton.Font = Enum.Font.GothamBold
	stopButton.Parent = mainFrame

	local stopButtonCorner = Instance.new("UICorner")
	stopButtonCorner.CornerRadius = UDim.new(0.1, 0)
	stopButtonCorner.Parent = stopButton

	stopButton.MouseButton1Click:Connect(function()
		self:StopHarvesting()
	end)

	-- Store reference
	self.UIElements.HarvestingGUI = harvestingGUI

	-- Initial update
	self:UpdateHarvestingDisplay()

	-- Animate in
	mainFrame.Size = UDim2.new(0, 0, 0, 0)
	local animTween = TweenService:Create(mainFrame,
		TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{Size = UDim2.new(0, 500, 0, 250)}
	)
	animTween:Play()

	print("WheatHarvestingGUI: ✅ Harvesting GUI created")
end

function WheatHarvestingGUI:UpdateHarvestingDisplay()
	if not self.UIElements.HarvestingGUI then return end

	local data = self.State.harvestingData
	local mainFrame = self.UIElements.HarvestingGUI:FindFirstChild("MainFrame")
	if not mainFrame then return end

	-- Update section info
	local sectionInfo = mainFrame:FindFirstChild("SectionInfo")
	if sectionInfo then
		sectionInfo.Text = "Section " .. data.currentSection .. " of 6"
	end

	-- Update progress bar
	local progressBar = mainFrame:FindFirstChild("ProgressBG"):FindFirstChild("ProgressBar")
	if progressBar then
		local progress = data.swingProgress / data.maxSwings
		local tween = TweenService:Create(progressBar,
			TweenInfo.new(0.3, Enum.EasingStyle.Quad),
			{Size = UDim2.new(progress, 0, 1, 0)}
		)
		tween:Play()
	end

	-- Update progress text
	local progressText = mainFrame:FindFirstChild("ProgressText")
	if progressText then
		progressText.Text = data.swingProgress .. " / " .. data.maxSwings .. " swings"
	end

	-- Update instructions based on progress
	local instructions = mainFrame:FindFirstChild("Instructions")
	if instructions then
		if data.swingProgress >= data.maxSwings then
			instructions.Text = "Section completed! Moving to next section..."
			instructions.TextColor3 = Color3.fromRGB(100, 255, 100)
		else
			instructions.Text = "Click to swing your scythe! " .. (data.maxSwings - data.swingProgress) .. " swings remaining."
			instructions.TextColor3 = Color3.fromRGB(200, 200, 200)
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
		self.UIElements.HarvestingGUI:Destroy()
		self.UIElements.HarvestingGUI = nil
	end

	-- Reset state
	self.State.guiType = "none"
	self.State.isVisible = false
	self.State.currentGUI = nil
end

-- ========== INPUT HANDLING ==========

function WheatHarvestingGUI:SetupInputHandling()
	print("WheatHarvestingGUI: Setting up input handling...")

	-- Handle clicks during harvesting
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end

		-- Check if we're in harvesting mode
		if self.State.guiType == "harvesting" and self.State.isVisible then
			local isClick = (input.UserInputType == Enum.UserInputType.MouseButton1) or
				(input.UserInputType == Enum.UserInputType.Touch) or
				(input.KeyCode == Enum.KeyCode.Space)

			if isClick then
				-- Check if player has scythe equipped
				local character = LocalPlayer.Character
				if character and character:FindFirstChild("Scythe") then
					-- Let the scythe tool handle the swing
					local scythe = character:FindFirstChild("Scythe")
					if scythe then
						-- The scythe tool will handle the swing and send to server
						print("WheatHarvestingGUI: Scythe swing handled by tool")
					end
				end
			end
		end
	end)

	print("WheatHarvestingGUI: ✅ Input handling setup")
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
	if self.UIElements.HarvestingGUI then
		self.UIElements.HarvestingGUI:Destroy()
		self.UIElements.HarvestingGUI = nil
	end

	-- Reset state
	self.State.guiType = "none"
	self.State.isVisible = false
	self.State.currentGUI = nil
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
	print("  Section: " .. self.State.harvestingData.currentSection)
	print("  Progress: " .. self.State.harvestingData.swingProgress .. "/" .. self.State.harvestingData.maxSwings)
	print("  Available Wheat: " .. self.State.harvestingData.availableWheat)
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

	-- Clear state
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

-- Note: LocalScripts automatically cleanup when player leaves, so no manual cleanup needed

-- Global reference
_G.WheatHarvestingGUI = WheatHarvestingGUI

return WheatHarvestingGUI