--[[
    Fixed Cow Click System with Debug
    Replace your CowMilkSystem.lua with this version
    
    FIXES:
    - Added extensive debug logging for click detection
    - Multiple click detection methods
    - Better error handling
    - Verification of GameCore connection
]]

local function WaitForGameCore(scriptName, maxWaitTime)
	maxWaitTime = maxWaitTime or 15
	local startTime = tick()

	print(scriptName .. ": Waiting for GameCore...")

	while not _G.GameCore and (tick() - startTime) < maxWaitTime do
		wait(0.5)
	end

	if not _G.GameCore then
		error(scriptName .. ": GameCore not found after " .. maxWaitTime .. " seconds!")
	end

	print(scriptName .. ": GameCore found successfully!")
	return _G.GameCore
end

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Wait for GameCore
local GameCore = WaitForGameCore("CowMilkSystem")

print("=== ENHANCED COW MILK SYSTEM WITH DEBUG STARTING ===")

local CowMilkSystem = {}

-- Find cow model in workspace
local cowModel = workspace:FindFirstChild("cow")
if not cowModel then
	error("CowMilkSystem: Cow model not found in workspace! Make sure there's a model named 'cow' in workspace.")
end

print("CowMilkSystem: Found cow model at:", cowModel:GetFullName())

-- Debug: List all parts in cow model
print("CowMilkSystem: Cow model parts:")
for _, part in pairs(cowModel:GetChildren()) do
	if part:IsA("BasePart") then
		print("  - " .. part.Name .. " (" .. part.ClassName .. ")")
	end
end

-- Create moo sound
local function CreateCowSounds()
	-- Create moo sound
	local mooSound = Instance.new("Sound")
	mooSound.Name = "MooSound"
	mooSound.SoundId = "rbxasset://sounds/impact_water.mp3" -- Placeholder
	mooSound.Volume = 0.7
	--mooSound.Pitch = 0.8
	mooSound.Parent = cowModel

	print("CowMilkSystem: Created moo sound in", cowModel.Name)
	return mooSound
end

-- Initialize the cow milk collection system
function CowMilkSystem:Initialize()
	print("CowMilkSystem: Initializing enhanced cow milk collection system...")

	-- Setup sounds
	self.mooSound = CreateCowSounds()

	-- Setup the visual indicator above the cow
	self:SetupMilkIndicator()

	-- Setup MULTIPLE click detection methods for maximum reliability
	self:SetupClickDetection()

	-- Start the indicator update loop
	self:StartIndicatorUpdates()

	print("CowMilkSystem: Enhanced cow milk system fully initialized!")
end

-- Setup the visual milk collection indicator
function CowMilkSystem:SetupMilkIndicator()
	-- Remove any existing indicator
	local existingIndicator = cowModel:FindFirstChild("MilkIndicator")
	if existingIndicator then
		existingIndicator:Destroy()
	end

	-- Create the circular indicator above the cow
	local indicator = Instance.new("Part")
	indicator.Name = "MilkIndicator"
	indicator.Size = Vector3.new(6, 0.5, 6)
	indicator.Shape = Enum.PartType.Cylinder
	indicator.Material = Enum.Material.Neon
	indicator.Color = Color3.fromRGB(255, 0, 0)
	indicator.CanCollide = false
	indicator.Anchored = true

	-- Position above cow's head
	local cowHead = cowModel:FindFirstChild("Head") or cowModel:FindFirstChild("HumanoidRootPart")
	if cowHead then
		indicator.CFrame = cowHead.CFrame + Vector3.new(0, 8, 0)
		indicator.Orientation = Vector3.new(0, 0, 90)
		print("CowMilkSystem: Positioned indicator above", cowHead.Name)
	else
		warn("CowMilkSystem: Could not find cow head or HumanoidRootPart")
		indicator.CFrame = CFrame.new(0, 10, 0)
	end

	indicator.Parent = cowModel

	-- Add text label for clarity
	local billboardGui = Instance.new("BillboardGui")
	billboardGui.Size = UDim2.new(0, 100, 0, 50)
	billboardGui.StudsOffset = Vector3.new(0, 3, 0)
	billboardGui.Parent = indicator

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = "🥛 CLICK TO COLLECT MILK"
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.TextStrokeTransparency = 0
	label.TextStrokeColor3 = Color3.new(0, 0, 0)
	label.Parent = billboardGui

	-- Add pulsing effect (fixed)
	local pulseConnection
	pulseConnection = RunService.Heartbeat:Connect(function()
		if indicator and indicator.Parent then
			local time = tick()
			local pulse = math.sin(time * 2) * 0.2 + 1
			indicator.Size = Vector3.new(6 * pulse, 0.5, 6 * pulse)
		else
			if pulseConnection then
				pulseConnection:Disconnect()
				pulseConnection = nil
			end
		end
	end)

	-- Store references
	self.milkIndicator = indicator
	self.milkLabel = label
	self.pulseConnection = pulseConnection

	print("CowMilkSystem: Enhanced milk indicator created with click prompt")
end

-- Setup MULTIPLE click detection methods for maximum reliability
function CowMilkSystem:SetupClickDetection()
	print("CowMilkSystem: Setting up multiple click detection methods...")

	-- METHOD 1: ClickDetector on HumanoidRootPart
	local cowRoot = cowModel:FindFirstChild("HumanoidRootPart")
	if cowRoot then
		self:CreateClickDetector(cowRoot, "HumanoidRootPart")
	end

	-- METHOD 2: ClickDetector on Torso (backup)
	local cowTorso = cowModel:FindFirstChild("Torso")
	if cowTorso then
		self:CreateClickDetector(cowTorso, "Torso")
	end

	-- METHOD 3: ClickDetector on Head
	local cowHead = cowModel:FindFirstChild("Head")
	if cowHead then
		self:CreateClickDetector(cowHead, "Head")
	end

	-- METHOD 4: ClickDetector on the indicator itself
	if self.milkIndicator then
		self:CreateClickDetector(self.milkIndicator, "MilkIndicator")
	end

	-- METHOD 5: Create a large invisible clickable area
	self:CreateLargeClickArea()

	print("CowMilkSystem: Multiple click detection methods setup complete")
end

-- Create click detector on a specific part
function CowMilkSystem:CreateClickDetector(part, partName)
	if not part then return end

	-- Remove existing click detector
	local existingDetector = part:FindFirstChild("ClickDetector")
	if existingDetector then
		existingDetector:Destroy()
	end

	-- Create new ClickDetector
	local clickDetector = Instance.new("ClickDetector")
	clickDetector.MaxActivationDistance = 20
	clickDetector.CursorIcon = "rbxasset://textures/Cursors/KeyboardMouse/ArrowCursor.png"
	clickDetector.Parent = part

	print("CowMilkSystem: Created ClickDetector on", partName)

	-- Handle clicks with detailed logging
	clickDetector.MouseClick:Connect(function(player)
		print("CowMilkSystem: CLICK DETECTED! Player:", player.Name, "clicked", partName)
		self:HandleCowClick(player, partName)
	end)

	-- Visual feedback on hover
	clickDetector.MouseHoverEnter:Connect(function(player)
		print("CowMilkSystem: Player", player.Name, "hovering over", partName)
		if self.milkIndicator then
			local currentColor = self.milkIndicator.Color
			self.milkIndicator.Color = Color3.new(
				math.min(currentColor.R + 0.3, 1),
				math.min(currentColor.G + 0.3, 1),
				math.min(currentColor.B + 0.3, 1)
			)
		end

		if self.milkLabel then
			self.milkLabel.Text = "🥛 CLICK NOW!"
			self.milkLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
		end
	end)

	clickDetector.MouseHoverLeave:Connect(function(player)
		print("CowMilkSystem: Player", player.Name, "stopped hovering over", partName)
		spawn(function()
			wait(0.1)
			self:UpdateIndicatorColor()
		end)

		if self.milkLabel then
			self.milkLabel.Text = "🥛 CLICK TO COLLECT MILK"
			self.milkLabel.TextColor3 = Color3.new(1, 1, 1)
		end
	end)

	return clickDetector
end

-- Create a large invisible clickable area around the cow
function CowMilkSystem:CreateLargeClickArea()
	local clickArea = Instance.new("Part")
	clickArea.Name = "CowLargeClickArea"
	clickArea.Size = Vector3.new(12, 12, 12) -- Large clickable area
	clickArea.Transparency = 1 -- Invisible
	clickArea.CanCollide = false
	clickArea.Anchored = true

	-- Position at cow's center
	local cowRoot = cowModel:FindFirstChild("HumanoidRootPart") or cowModel:FindFirstChild("Torso")
	if cowRoot then
		clickArea.CFrame = cowRoot.CFrame
	else
		clickArea.CFrame = CFrame.new(0, 5, 0)
	end

	clickArea.Parent = cowModel

	-- Add ClickDetector
	local clickDetector = Instance.new("ClickDetector")
	clickDetector.MaxActivationDistance = 25
	clickDetector.Parent = clickArea

	print("CowMilkSystem: Created large invisible click area")

	-- Handle clicks
	clickDetector.MouseClick:Connect(function(player)
		print("CowMilkSystem: LARGE AREA CLICK! Player:", player.Name)
		self:HandleCowClick(player, "LargeClickArea")
	end)

	self.largeClickArea = clickArea
end

-- Handle cow clicks for milk collection (enhanced with debugging)
function CowMilkSystem:HandleCowClick(player, clickSource)
	print("CowMilkSystem: ========== CLICK HANDLER CALLED ==========")
	print("CowMilkSystem: Player:", player.Name)
	print("CowMilkSystem: Click Source:", clickSource or "Unknown")
	print("CowMilkSystem: GameCore available:", _G.GameCore ~= nil)

	-- Verify GameCore is available
	if not GameCore or not GameCore.HandleMilkCollection then
		print("CowMilkSystem: ERROR - GameCore or HandleMilkCollection not available!")
		if GameCore then
			print("CowMilkSystem: GameCore exists but HandleMilkCollection is missing")
		else
			print("CowMilkSystem: GameCore is completely missing")
		end
		return
	end

	print("CowMilkSystem: Calling GameCore:HandleMilkCollection...")

	-- Call GameCore's milk collection handler
	local success, result = pcall(function()
		return GameCore:HandleMilkCollection(player)
	end)

	if success then
		print("CowMilkSystem: GameCore call successful, result:", result)
		if result then
			-- Play moo sound
			print("CowMilkSystem: Playing moo sound...")
			self:PlayMooSound()

			-- Create enhanced visual effect
			print("CowMilkSystem: Creating visual effects...")
			self:CreateMilkCollectionEffect()

			-- Update indicator immediately
			self:UpdateIndicatorColor()
		else
			print("CowMilkSystem: Milk collection failed (cooldown or other reason)")
		end
	else
		print("CowMilkSystem: ERROR calling GameCore:HandleMilkCollection:", result)
	end

	print("CowMilkSystem: ========== CLICK HANDLER COMPLETE ==========")
end

-- Play moo sound with variety
function CowMilkSystem:PlayMooSound()
	if self.mooSound then
		self.mooSound.Pitch = 0.7 + (math.random() * 0.3)

		local success, error = pcall(function()
			self.mooSound:Play()
		end)

		if success then
			print("CowMilkSystem: Cow mooed!")
		else
			warn("CowMilkSystem: Failed to play moo sound:", error)
		end
	else
		print("CowMilkSystem: No moo sound available")
	end
end

-- Create enhanced visual effect when milk is collected
function CowMilkSystem:CreateMilkCollectionEffect()
	if not cowModel then return end

	local cowRoot = cowModel:FindFirstChild("HumanoidRootPart") or cowModel:FindFirstChild("Torso")
	if not cowRoot then return end

	print("CowMilkSystem: Creating milk droplet effects...")

	-- Create milk droplet effects
	for i = 1, 12 do
		local droplet = Instance.new("Part")
		droplet.Name = "MilkDroplet"
		droplet.Size = Vector3.new(0.4, 0.4, 0.4)
		droplet.Shape = Enum.PartType.Ball
		droplet.Material = Enum.Material.Neon
		droplet.Color = Color3.fromRGB(255, 255, 255)
		droplet.CanCollide = false
		droplet.Anchored = true
		droplet.Position = cowRoot.Position + Vector3.new(
			math.random(-3, 3),
			math.random(1, 4),
			math.random(-3, 3)
		)
		droplet.Parent = workspace

		-- Animate droplet
		local endPosition = droplet.Position + Vector3.new(
			math.random(-8, 8),
			math.random(10, 20),
			math.random(-8, 8)
		)

		local tween = TweenService:Create(droplet,
			TweenInfo.new(2.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{
				Position = endPosition,
				Transparency = 1,
				Size = Vector3.new(0.1, 0.1, 0.1)
			}
		)
		tween:Play()
		tween.Completed:Connect(function()
			droplet:Destroy()
		end)
	end

	-- Flash the indicator green briefly
	if self.milkIndicator then
		local originalColor = self.milkIndicator.Color
		self.milkIndicator.Color = Color3.fromRGB(0, 255, 0)

		if self.milkLabel then
			self.milkLabel.Text = "🥛 MILK COLLECTED!"
			self.milkLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
		end

		spawn(function()
			wait(1)
			self.milkIndicator.Color = originalColor
			if self.milkLabel then
				self.milkLabel.Text = "🥛 CLICK TO COLLECT MILK"
				self.milkLabel.TextColor3 = Color3.new(1, 1, 1)
			end
		end)
	end

	print("CowMilkSystem: Created enhanced milk collection effect with moo sound")
end

-- Start the indicator update loop
function CowMilkSystem:StartIndicatorUpdates()
	spawn(function()
		print("CowMilkSystem: Starting indicator update loop")

		while self.milkIndicator and self.milkIndicator.Parent do
			self:UpdateIndicatorColor()
			wait(1)
		end

		print("CowMilkSystem: Indicator update loop ended")
	end)
end

-- Update the indicator color based on milk collection status
function CowMilkSystem:UpdateIndicatorColor()
	if not self.milkIndicator then return end
	if not GameCore or not GameCore.Systems or not GameCore.Systems.Livestock then return end

	local anyPlayerReady = false
	local shortestWait = math.huge
	local currentTime = os.time()

	-- Check all player cooldowns
	for userId, lastCollection in pairs(GameCore.Systems.Livestock.CowCooldowns) do
		local player = Players:GetPlayerByUserId(userId)
		if player then
			local playerData = GameCore:GetPlayerData(player)
			if playerData then
				local ItemConfig = require(ReplicatedStorage:WaitForChild("ItemConfig"))
				local cooldown = ItemConfig.GetMilkCooldown(playerData.upgrades or {})

				local timeSinceCollection = currentTime - lastCollection
				local timeLeft = cooldown - timeSinceCollection

				if timeLeft <= 0 then
					anyPlayerReady = true
					break
				else
					shortestWait = math.min(shortestWait, timeLeft)
				end
			end
		end
	end

	-- If no cooldowns recorded, anyone can collect
	if next(GameCore.Systems.Livestock.CowCooldowns) == nil then
		anyPlayerReady = true
	end

	-- Update indicator color and text based on status
	if anyPlayerReady then
		self.milkIndicator.Color = Color3.fromRGB(0, 255, 0)
		if self.milkLabel then
			self.milkLabel.Text = "🥛 CLICK TO COLLECT MILK"
			self.milkLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
		end
	elseif shortestWait <= 10 then
		self.milkIndicator.Color = Color3.fromRGB(255, 255, 0)
		if self.milkLabel then
			self.milkLabel.Text = "🥛 ALMOST READY (" .. math.ceil(shortestWait) .. "s)"
			self.milkLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
		end
	else
		self.milkIndicator.Color = Color3.fromRGB(255, 0, 0)
		if self.milkLabel then
			self.milkLabel.Text = "🥛 COW RESTING (" .. math.ceil(shortestWait) .. "s)"
			self.milkLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
		end
	end
end

-- Handle player connections
Players.PlayerAdded:Connect(function(player)
	print("CowMilkSystem: Player " .. player.Name .. " joined - they can collect milk by clicking the cow")
end)

-- Admin commands for testing
Players.PlayerAdded:Connect(function(player)
	player.Chatted:Connect(function(message)
		if player.Name == "TommySalami311" then -- Replace with your username
			local args = string.split(message:lower(), " ")
			local command = args[1]

			if command == "/testmoo" then
				print("Admin: Testing moo sound")
				CowMilkSystem:PlayMooSound()

			elseif command == "/testmilk" then
				print("Admin: Testing milk collection")
				CowMilkSystem:HandleCowClick(player, "AdminCommand")

			elseif command == "/cowdebug" then
				print("=== COW SYSTEM DEBUG ===")
				print("Cow model:", cowModel and cowModel.Name or "NOT FOUND")
				print("GameCore available:", _G.GameCore ~= nil)
				print("HandleMilkCollection available:", _G.GameCore and _G.GameCore.HandleMilkCollection ~= nil)
				print("Milk indicator:", CowMilkSystem.milkIndicator and "Active" or "Missing")
				print("Click detectors in cow:")
				for _, part in pairs(cowModel:GetChildren()) do
					local detector = part:FindFirstChild("ClickDetector")
					if detector then
						print("  - " .. part.Name .. " has ClickDetector")
					end
				end
				print("=======================")

			elseif command == "/resetcow" then
				if GameCore and GameCore.Systems and GameCore.Systems.Livestock then
					GameCore.Systems.Livestock.CowCooldowns = {}
					print("Admin: Reset all cow cooldowns")
				end
			end
		end
	end)
end)

-- Cleanup function
function CowMilkSystem:Cleanup()
	if self.pulseConnection then
		self.pulseConnection:Disconnect()
	end

	if self.milkIndicator then
		self.milkIndicator:Destroy()
	end

	if self.largeClickArea then
		self.largeClickArea:Destroy()
	end

	if self.mooSound then
		self.mooSound:Destroy()
	end

	print("CowMilkSystem: Cleaned up")
end

-- Initialize the system
CowMilkSystem:Initialize()

-- Make globally available
_G.CowMilkSystem = CowMilkSystem

print("=== ENHANCED COW MILK SYSTEM WITH DEBUG ACTIVE ===")
print("Features:")
print("✅ Multiple click detection methods for reliability")
print("✅ Extensive debug logging")
print("✅ Large invisible click area backup")
print("✅ Enhanced error handling")
print("")
print("Admin Commands:")
print("  /testmoo - Test moo sound")
print("  /testmilk - Test milk collection")
print("  /cowdebug - Show detailed debug info")
print("  /resetcow - Reset all cow cooldowns")

return CowMilkSystem