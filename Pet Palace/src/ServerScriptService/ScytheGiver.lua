--[[
    ScytheGiver.lua - UPDATED to Use Existing Scythe Tool
    Place in: ServerScriptService/ScytheGiver.lua
    
    UPDATES:
    ✅ Uses existing Scythe tool from ServerStorage
    ✅ Immediately equips tool (no backpack delay)
    ✅ Preserves existing tool's LocalScript
    ✅ Enhanced visual feedback
]]

local ScytheGiver = {}

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local TweenService = game:GetService("TweenService")

-- Configuration
local SCYTHE_CONFIG = {
	SCYTHE_NAME = "Scythe",
	COOLDOWN_TIME = 2,
	GLOW_DURATION = 0.5
}

-- State
ScytheGiver.GameCore = nil
ScytheGiver.ScytheGiverModel = nil
ScytheGiver.TouchConnections = {}
ScytheGiver.PlayerCooldowns = {}
ScytheGiver.ScytheTool = nil

-- ========== INITIALIZATION ==========

function ScytheGiver:Initialize(gameCore)
	print("ScytheGiver: Initializing with EXISTING scythe tool...")

	self.GameCore = gameCore

	-- Find the ScytheGiver model
	self:FindScytheGiverModel()

	-- Find the existing scythe tool
	self:FindExistingScytheTool()

	-- Setup touch detection
	self:SetupTouchDetection()

	print("ScytheGiver: ✅ Initialized with existing scythe tool")
	return true
end

-- ========== SCYTHE GIVER MODEL SETUP ==========

function ScytheGiver:FindScytheGiverModel()
	print("ScytheGiver: Looking for ScytheGiver model...")

	self.ScytheGiverModel = workspace:FindFirstChild("ScytheGiver")

	if not self.ScytheGiverModel then
		for _, child in pairs(workspace:GetChildren()) do
			if child:IsA("Model") then
				local found = child:FindFirstChild("ScytheGiver")
				if found then
					self.ScytheGiverModel = found
					break
				end
			end
		end
	end

	if not self.ScytheGiverModel then
		error("ScytheGiver: ScytheGiver model not found in workspace!")
	end

	print("ScytheGiver: Found ScytheGiver model: " .. self.ScytheGiverModel.Name)
	self:EnhanceScytheGiverVisuals()
end

function ScytheGiver:EnhanceScytheGiverVisuals()
	local function addGlow(part)
		if part:IsA("BasePart") then
			local selectionBox = Instance.new("SelectionBox")
			selectionBox.Name = "ScytheGiverGlow"
			selectionBox.Adornee = part
			selectionBox.Color3 = Color3.fromRGB(255, 255, 0)
			selectionBox.Transparency = 0.5
			selectionBox.LineThickness = 0.2
			selectionBox.Parent = part

			local tween = TweenService:Create(selectionBox,
				TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
				{Transparency = 0.2}
			)
			tween:Play()
		end
	end

	for _, child in pairs(self.ScytheGiverModel:GetChildren()) do
		addGlow(child)
	end
end

-- ========== EXISTING SCYTHE TOOL SETUP ==========

function ScytheGiver:FindExistingScytheTool()
	print("ScytheGiver: Looking for existing scythe tool...")

	-- First check ServerStorage
	local serverStorage = ServerStorage
	self.ScytheTool = serverStorage:FindFirstChild(SCYTHE_CONFIG.SCYTHE_NAME)

	if self.ScytheTool and self.ScytheTool:IsA("Tool") then
		print("ScytheGiver: ✅ Found existing scythe tool in ServerStorage: " .. self.ScytheTool.Name)
		self:ValidateScytheTool()
		return
	end

	-- Check ReplicatedStorage as backup
	self.ScytheTool = ReplicatedStorage:FindFirstChild(SCYTHE_CONFIG.SCYTHE_NAME)

	if self.ScytheTool and self.ScytheTool:IsA("Tool") then
		print("ScytheGiver: ✅ Found existing scythe tool in ReplicatedStorage: " .. self.ScytheTool.Name)
		self:ValidateScytheTool()
		return
	end

	-- If not found, provide helpful error
	error("ScytheGiver: Scythe tool not found! Please place your Scythe tool in ServerStorage with the name '" .. SCYTHE_CONFIG.SCYTHE_NAME .. "'")
end

function ScytheGiver:ValidateScytheTool()
	print("ScytheGiver: Validating existing scythe tool...")

	-- Check if tool has a Handle
	local handle = self.ScytheTool:FindFirstChild("Handle")
	if not handle then
		warn("ScytheGiver: ⚠️ Scythe tool missing Handle - this may cause issues")
	else
		print("ScytheGiver: ✅ Handle found")
	end

	-- Check if tool has a LocalScript
	local hasLocalScript = false
	for _, child in pairs(self.ScytheTool:GetChildren()) do
		if child:IsA("LocalScript") then
			hasLocalScript = true
			print("ScytheGiver: ✅ Found LocalScript: " .. child.Name)
			break
		end
	end

	if not hasLocalScript then
		warn("ScytheGiver: ⚠️ No LocalScript found in scythe tool - swing functionality may not work")
		print("ScytheGiver: Consider adding a LocalScript to handle tool activation")
	end

	-- Check tool properties
	print("ScytheGiver: Tool Properties:")
	print("  RequiresHandle: " .. tostring(self.ScytheTool.RequiresHandle))
	print("  CanBeDropped: " .. tostring(self.ScytheTool.CanBeDropped))
	print("  ManualActivationOnly: " .. tostring(self.ScytheTool.ManualActivationOnly))

	print("ScytheGiver: ✅ Scythe tool validation complete")
end

-- ========== TOUCH DETECTION ==========

function ScytheGiver:SetupTouchDetection()
	print("ScytheGiver: Setting up touch detection...")

	for _, child in pairs(self.ScytheGiverModel:GetChildren()) do
		if child:IsA("BasePart") then
			local connection = child.Touched:Connect(function(hit)
				self:HandleTouch(hit)
			end)
			table.insert(self.TouchConnections, connection)
			print("ScytheGiver: Connected touch detection to " .. child.Name)
		end
	end

	print("ScytheGiver: ✅ Touch detection setup complete")
end

function ScytheGiver:HandleTouch(hit)
	local character = hit.Parent
	local humanoid = character:FindFirstChildOfClass("Humanoid")

	if not humanoid then return end

	local player = Players:GetPlayerFromCharacter(character)
	if not player then return end

	-- Check cooldown
	local currentTime = tick()
	local lastGiveTime = self.PlayerCooldowns[player.UserId] or 0

	if (currentTime - lastGiveTime) < SCYTHE_CONFIG.COOLDOWN_TIME then
		return
	end

	self:GiveScytheToPlayer(player)
end

-- ========== SCYTHE GIVING (UPDATED FOR IMMEDIATE EQUIP) ==========

function ScytheGiver:GiveScytheToPlayer(player)
	print("ScytheGiver: Giving existing scythe tool to " .. player.Name)

	-- Check if player already has a scythe
	if self:PlayerHasScythe(player) then
		if self.GameCore and self.GameCore.SendNotification then
			self.GameCore:SendNotification(player, "Already Have Scythe", "You already have a scythe!", "info")
		end
		return
	end

	-- Update cooldown
	self.PlayerCooldowns[player.UserId] = tick()

	-- Validate scythe tool exists
	if not self.ScytheTool then
		warn("ScytheGiver: Scythe tool not available")
		if self.GameCore and self.GameCore.SendNotification then
			self.GameCore:SendNotification(player, "Error", "Scythe tool not found!", "error")
		end
		return
	end

	-- Clone the existing scythe tool
	local scytheClone = self.ScytheTool:Clone()

	-- IMMEDIATELY EQUIP: Put directly in character instead of backpack
	local character = player.Character
	if character then
		scytheClone.Parent = character
		print("ScytheGiver: ✅ Immediately equipped scythe for " .. player.Name)
	else
		-- Fallback to backpack if no character
		scytheClone.Parent = player.Backpack
		print("ScytheGiver: ⚠️ No character found, added to backpack for " .. player.Name)
	end

	-- Create visual effects
	self:CreateGiveEffect(player)

	-- Send notification
	if self.GameCore and self.GameCore.SendNotification then
		self.GameCore:SendNotification(player, "🌾 Scythe Equipped", "Scythe ready! Approach the wheat field to start harvesting.", "success")
	end

	-- Update player stats
	if self.GameCore then
		local playerData = self.GameCore:GetPlayerData(player)
		if playerData then
			playerData.stats = playerData.stats or {}
			playerData.stats.scythesReceived = (playerData.stats.scythesReceived or 0) + 1
			self.GameCore:UpdatePlayerData(player, playerData)
		end
	end

	print("ScytheGiver: ✅ Successfully gave and equipped scythe to " .. player.Name)
end

function ScytheGiver:CreateGiveEffect(player)
	local character = player.Character
	if not character then return end

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return end

	-- Create multiple sparkle effects
	for i = 1, 5 do
		local sparkle = Instance.new("Part")
		sparkle.Name = "ScytheGiveEffect"
		sparkle.Size = Vector3.new(0.5, 0.5, 0.5)
		sparkle.Material = Enum.Material.Neon
		sparkle.BrickColor = BrickColor.new("Bright yellow")
		sparkle.Anchored = true
		sparkle.CanCollide = false
		sparkle.Transparency = 0.3
		sparkle.Shape = Enum.PartType.Ball
		sparkle.Parent = workspace

		-- Random position around player
		local offset = Vector3.new(
			math.random(-3, 3),
			math.random(1, 4),
			math.random(-3, 3)
		)
		sparkle.Position = rootPart.Position + offset

		-- Animate sparkle
		local tween = TweenService:Create(sparkle,
			TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{
				Position = sparkle.Position + Vector3.new(0, 5, 0),
				Transparency = 1,
				Size = Vector3.new(0.1, 0.1, 0.1)
			}
		)
		tween:Play()

		tween.Completed:Connect(function()
			sparkle:Destroy()
		end)
	end

	-- Create main glow effect
	local mainGlow = Instance.new("Part")
	mainGlow.Name = "ScytheMainGlow"
	mainGlow.Size = Vector3.new(4, 4, 4)
	mainGlow.Material = Enum.Material.Neon
	mainGlow.BrickColor = BrickColor.new("Bright yellow")
	mainGlow.Anchored = true
	mainGlow.CanCollide = false
	mainGlow.Transparency = 0.7
	mainGlow.Shape = Enum.PartType.Ball
	mainGlow.Position = rootPart.Position
	mainGlow.Parent = workspace

	local mainTween = TweenService:Create(mainGlow,
		TweenInfo.new(SCYTHE_CONFIG.GLOW_DURATION, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{Transparency = 1, Size = Vector3.new(8, 8, 8)}
	)
	mainTween:Play()

	mainTween.Completed:Connect(function()
		mainGlow:Destroy()
	end)
end

-- ========== UTILITY FUNCTIONS ==========

function ScytheGiver:PlayerHasScythe(player)
	-- Check if player has scythe in backpack
	if player.Backpack:FindFirstChild(SCYTHE_CONFIG.SCYTHE_NAME) then
		return true
	end

	-- Check if player has scythe equipped (in character)
	if player.Character and player.Character:FindFirstChild(SCYTHE_CONFIG.SCYTHE_NAME) then
		return true
	end

	return false
end

function ScytheGiver:PlayerRemoving(player)
	if self.PlayerCooldowns[player.UserId] then
		self.PlayerCooldowns[player.UserId] = nil
	end
end

-- ========== DEBUG FUNCTIONS ==========

function ScytheGiver:DebugStatus()
	print("=== SCYTHE GIVER DEBUG STATUS ===")
	print("ScytheGiver model: " .. (self.ScytheGiverModel and self.ScytheGiverModel.Name or "❌ Not found"))
	print("Scythe tool: " .. (self.ScytheTool and self.ScytheTool.Name or "❌ Not found"))

	if self.ScytheTool then
		print("Scythe tool location: " .. self.ScytheTool.Parent.Name)
		print("Scythe tool class: " .. self.ScytheTool.ClassName)

		-- Check for Handle
		local handle = self.ScytheTool:FindFirstChild("Handle")
		print("Has Handle: " .. (handle and "✅" or "❌"))

		-- Check for LocalScript
		local hasScript = false
		for _, child in pairs(self.ScytheTool:GetChildren()) do
			if child:IsA("LocalScript") then
				hasScript = true
				break
			end
		end
		print("Has LocalScript: " .. (hasScript and "✅" or "❌"))
	end

	print("Touch connections: " .. #self.TouchConnections)
	print("Player cooldowns: " .. self:CountTable(self.PlayerCooldowns))

	print("")
	print("Players with scythes:")
	for _, player in pairs(Players:GetPlayers()) do
		local hasScythe = self:PlayerHasScythe(player)
		local location = ""
		if hasScythe then
			if player.Character and player.Character:FindFirstChild(SCYTHE_CONFIG.SCYTHE_NAME) then
				location = " (equipped)"
			else
				location = " (in backpack)"
			end
		end
		print("  " .. player.Name .. ": " .. (hasScythe and "✅" or "❌") .. location)
	end
	print("==================================")
end

function ScytheGiver:CountTable(t)
	local count = 0
	for _ in pairs(t) do
		count = count + 1
	end
	return count
end

-- ========== CLEANUP ==========

function ScytheGiver:Cleanup()
	for _, connection in pairs(self.TouchConnections) do
		if connection then
			connection:Disconnect()
		end
	end
	self.TouchConnections = {}
	self.PlayerCooldowns = {}
end

Players.PlayerRemoving:Connect(function(player)
	ScytheGiver:PlayerRemoving(player)
end)

_G.ScytheGiver = ScytheGiver

return ScytheGiver