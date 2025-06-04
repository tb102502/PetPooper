--[[
    CowMilkSystem.server.lua
    Place in: ServerScriptService/CowMilkSystem.server.lua
    
    Handles:
    - Cow milk collection visual indicator (red/yellow/green circle)
    - Click detection for milk collection
    - Integration with GameCore for cooldown management
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

print("=== COW MILK SYSTEM STARTING ===")

local CowMilkSystem = {}

-- Find cow model in workspace
local cowModel = workspace:FindFirstChild("cow")
if not cowModel then
	error("CowMilkSystem: Cow model not found in workspace! Make sure there's a model named 'cow' in workspace.")
end

print("CowMilkSystem: Found cow model")

-- Initialize the cow milk collection system
function CowMilkSystem:Initialize()
	print("CowMilkSystem: Initializing cow milk collection system...")

	-- Setup the visual indicator above the cow
	self:SetupMilkIndicator()

	-- Setup click detection for milk collection
	self:SetupClickDetection()

	-- Start the indicator update loop
	self:StartIndicatorUpdates()

	print("CowMilkSystem: Cow milk system fully initialized!")
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
	indicator.Size = Vector3.new(6, 0.5, 6) -- Large circular indicator
	indicator.Shape = Enum.PartType.Cylinder
	indicator.Material = Enum.Material.Neon
	indicator.Color = Color3.fromRGB(255, 0, 0) -- Start red (not ready)
	indicator.CanCollide = false
	indicator.Anchored = true
	indicator.TopSurface = Enum.SurfaceType.Smooth
	indicator.BottomSurface = Enum.SurfaceType.Smooth

	-- Position above cow's head
	local cowHead = cowModel:FindFirstChild("Head") or cowModel:FindFirstChild("HumanoidRootPart")
	if cowHead then
		indicator.CFrame = cowHead.CFrame + Vector3.new(0, 8, 0)
		indicator.Orientation = Vector3.new(0, 0, 90) -- Rotate cylinder to be horizontal
	else
		warn("CowMilkSystem: Could not find cow head or HumanoidRootPart for indicator positioning")
		indicator.CFrame = CFrame.new(0, 10, 0) -- Default position
	end

	indicator.Parent = cowModel

	-- Add a subtle pulsing effect
	local pulseConnection = RunService.Heartbeat:Connect(function()
		if indicator and indicator.Parent then
			local time = tick()
			local pulse = math.sin(time * 2) * 0.2 + 1 -- Pulse between 0.8 and 1.2
			indicator.Size = Vector3.new(6 * pulse, 0.5, 6 * pulse)
		else
			pulseConnection:Disconnect()
		end
	end)

	-- Store reference for updates
	self.milkIndicator = indicator
	self.pulseConnection = pulseConnection

	print("CowMilkSystem: Milk indicator created and positioned")
end

-- Setup click detection for the cow
function CowMilkSystem:SetupClickDetection()
	-- Create a larger clickable area around the cow
	local clickPart = Instance.new("Part")
	clickPart.Name = "CowClickArea"
	clickPart.Size = Vector3.new(8, 8, 8) -- Large clickable area
	clickPart.Transparency = 1 -- Invisible
	clickPart.CanCollide = false
	clickPart.Anchored = true

	-- Position at cow's center
	local cowRoot = cowModel:FindFirstChild("HumanoidRootPart") or cowModel:FindFirstChild("Torso")
	if cowRoot then
		clickPart.CFrame = cowRoot.CFrame
	else
		warn("CowMilkSystem: Could not find cow root part for click detection")
		clickPart.CFrame = CFrame.new(0, 5, 0)
	end

	clickPart.Parent = cowModel

	-- Add ClickDetector
	local clickDetector = Instance.new("ClickDetector")
	clickDetector.MaxActivationDistance = 15 -- Allow clicking from 15 studs away
	clickDetector.CursorIcon = "rbxasset://textures/Cursors/KeyboardMouse/ArrowCursor.png"
	clickDetector.Parent = clickPart

	-- Handle clicks
	clickDetector.MouseClick:Connect(function(player)
		self:HandleCowClick(player)
	end)

	-- Visual feedback on hover
	clickDetector.MouseHoverEnter:Connect(function(player)
		if self.milkIndicator then
			-- Brighten the indicator when hovering
			local currentColor = self.milkIndicator.Color
			self.milkIndicator.Color = Color3.new(
				math.min(currentColor.R + 0.2, 1),
				math.min(currentColor.G + 0.2, 1),
				math.min(currentColor.B + 0.2, 1)
			)
		end
	end)

	clickDetector.MouseHoverLeave:Connect(function(player)
		-- Update indicator color back to normal
		spawn(function()
			wait(0.1) -- Small delay to prevent flickering
			self:UpdateIndicatorColor()
		end)
	end)

	self.clickPart = clickPart
	self.clickDetector = clickDetector

	print("CowMilkSystem: Click detection setup complete")
end

-- Handle cow clicks for milk collection
function CowMilkSystem:HandleCowClick(player)
	print("CowMilkSystem: " .. player.Name .. " clicked the cow")

	-- Forward to GameCore's milk collection handler
	if GameCore and GameCore.HandleMilkCollection then
		GameCore:HandleMilkCollection(player)
	else
		warn("CowMilkSystem: GameCore.HandleMilkCollection not available")

		-- Fallback: Fire the remote event directly
		local gameRemotes = ReplicatedStorage:FindFirstChild("GameRemotes")
		if gameRemotes then
			local collectMilkEvent = gameRemotes:FindFirstChild("CollectMilk")
			if collectMilkEvent then
				-- Simulate server-side handling
				collectMilkEvent:FireServer() -- This won't work from server, but shows the structure
			end
		end
	end

	-- Create visual effect at cow
	self:CreateMilkCollectionEffect()
end

-- Create visual effect when milk is collected
function CowMilkSystem:CreateMilkCollectionEffect()
	if not cowModel then return end

	local cowRoot = cowModel:FindFirstChild("HumanoidRootPart") or cowModel:FindFirstChild("Torso")
	if not cowRoot then return end

	-- Create milk droplet effects
	for i = 1, 8 do
		local droplet = Instance.new("Part")
		droplet.Name = "MilkDroplet"
		droplet.Size = Vector3.new(0.3, 0.3, 0.3)
		droplet.Shape = Enum.PartType.Ball
		droplet.Material = Enum.Material.Neon
		droplet.Color = Color3.fromRGB(255, 255, 255) -- White milk color
		droplet.CanCollide = false
		droplet.Anchored = true
		droplet.Position = cowRoot.Position + Vector3.new(
			math.random(-2, 2),
			math.random(1, 3),
			math.random(-2, 2)
		)
		droplet.Parent = workspace

		-- Animate droplet
		local endPosition = droplet.Position + Vector3.new(
			math.random(-5, 5),
			math.random(8, 15),
			math.random(-5, 5)
		)

		local tween = TweenService:Create(droplet,
			TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
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

		wait(0.5)

		self.milkIndicator.Color = originalColor
	end

	print("CowMilkSystem: Created milk collection effect")
end

-- Start the indicator update loop
function CowMilkSystem:StartIndicatorUpdates()
	spawn(function()
		print("CowMilkSystem: Starting indicator update loop")

		while self.milkIndicator and self.milkIndicator.Parent do
			self:UpdateIndicatorColor()
			wait(1) -- Update every second
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
				-- Get player's milk cooldown (accounting for upgrades)
				local cooldown = 30 -- Default cooldown
				if GameCore.ItemConfig and GameCore.ItemConfig.GetMilkCooldown then
					cooldown = GameCore.ItemConfig.GetMilkCooldown(playerData.upgrades or {})
				end

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

	-- Update indicator color based on status
	if anyPlayerReady then
		-- Green - ready to collect
		self.milkIndicator.Color = Color3.fromRGB(0, 255, 0)
	elseif shortestWait <= 10 then
		-- Yellow - almost ready (10 seconds or less)
		self.milkIndicator.Color = Color3.fromRGB(255, 255, 0)
	else
		-- Red - not ready
		self.milkIndicator.Color = Color3.fromRGB(255, 0, 0)
	end
end

-- Handle player connections
Players.PlayerAdded:Connect(function(player)
	print("CowMilkSystem: Player " .. player.Name .. " joined - they can collect milk when indicator is green")
end)

Players.PlayerRemoving:Connect(function(player)
	print("CowMilkSystem: Player " .. player.Name .. " left")
end)

-- Cleanup function
function CowMilkSystem:Cleanup()
	if self.pulseConnection then
		self.pulseConnection:Disconnect()
	end

	if self.milkIndicator then
		self.milkIndicator:Destroy()
	end

	if self.clickPart then
		self.clickPart:Destroy()
	end

	print("CowMilkSystem: Cleaned up")
end

-- Initialize the system
CowMilkSystem:Initialize()

-- Admin commands for testing
Players.PlayerAdded:Connect(function(player)
	player.Chatted:Connect(function(message)
		-- Replace with your username
		if player.Name == "TommySalami311" then -- Replace with your username
			local args = string.split(message:lower(), " ")
			local command = args[1]

			if command == "/testmilk" then
				-- Force milk collection for testing
				print("Admin: Testing milk collection")
				CowMilkSystem:HandleCowClick(player)

			elseif command == "/resetcow" then
				-- Reset cow cooldowns for all players
				if GameCore and GameCore.Systems and GameCore.Systems.Livestock then
					GameCore.Systems.Livestock.CowCooldowns = {}
					print("Admin: Reset all cow cooldowns")
				end

			elseif command == "/cowstatus" then
				-- Show cow system status
				print("=== COW SYSTEM STATUS ===")
				print("Cow model found:", cowModel ~= nil)
				print("Milk indicator active:", CowMilkSystem.milkIndicator ~= nil)
				print("Click detection active:", CowMilkSystem.clickDetector ~= nil)

				if GameCore and GameCore.Systems and GameCore.Systems.Livestock then
					local cooldownCount = 0
					for userId, lastCollection in pairs(GameCore.Systems.Livestock.CowCooldowns) do
						cooldownCount = cooldownCount + 1
						local player = Players:GetPlayerByUserId(userId)
						local timeLeft = 30 - (os.time() - lastCollection)
						print("  " .. (player and player.Name or "Unknown") .. ": " .. math.max(0, timeLeft) .. "s cooldown")
					end
					print("Total players with cooldowns:", cooldownCount)
				end
				print("========================")

			elseif command == "/fixcow" then
				-- Reinitialize the cow system
				print("Admin: Reinitializing cow system")
				CowMilkSystem:Cleanup()
				wait(1)
				CowMilkSystem:Initialize()
			end
		end
	end)
end)

-- Make globally available
_G.CowMilkSystem = CowMilkSystem

print("=== COW MILK SYSTEM ACTIVE ===")
print("Features:")
print("✅ Visual milk collection indicator (red/yellow/green)")
print("✅ Click detection on cow for milk collection")
print("✅ Visual effects when milk is collected")
print("✅ Integration with GameCore cooldown system")
print("✅ Automatic indicator updates based on player cooldowns")
print("")
print("Admin Commands:")
print("  /testmilk - Test milk collection")
print("  /resetcow - Reset all cow cooldowns")
print("  /cowstatus - Show cow system status")
print("  /fixcow - Reinitialize cow system")

return CowMilkSystem