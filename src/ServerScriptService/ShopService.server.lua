-- ShopService.server.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Create RemoteEvent for shop communication
local ShopEvents = ReplicatedStorage:FindFirstChild("ShopEvents") or Instance.new("Folder")
ShopEvents.Name = "ShopEvents"
ShopEvents.Parent = ReplicatedStorage

local OpenShopEvent = ShopEvents:FindFirstChild("OpenShopEvent") or Instance.new("RemoteEvent")
OpenShopEvent.Name = "OpenShopEvent" 
OpenShopEvent.Parent = ShopEvents

-- Configuration for shops
local shopConfig = {
	CooldownTime = 1, -- Seconds between activations
	ProximityDistance = 8 -- Distance in studs for proximity detection
}

-- Cache for managing player cooldowns
local playerCooldowns = {}

-- Function to set up shop parts
local function setupShopParts()
	-- Find all ShopTouchParts in the workspace
	local shopParts = workspace:GetDescendantsByName("ShopTouchPart")

	if #shopParts == 0 then
		warn("No ShopTouchPart found in workspace! Please add at least one.")
		return
	end

	print("Setting up " .. #shopParts .. " shop parts")

	for _, shopPart in ipairs(shopParts) do
		if not shopPart:IsA("BasePart") then 
			continue 
		end

		-- Configure the part for optimized touch detection
		shopPart.CanCollide = false
		shopPart.Transparency = 0.8
		shopPart.Anchored = true

		-- Create visual indicator for the shop
		local attachment = shopPart:FindFirstChild("ShopAttachment") or Instance.new("Attachment")
		attachment.Name = "ShopAttachment"
		attachment.Parent = shopPart

		local particle = attachment:FindFirstChild("ShopParticle") or Instance.new("ParticleEmitter")
		particle.Name = "ShopParticle"
		particle.Color = ColorSequence.new(Color3.fromRGB(255, 220, 50))
		particle.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.5),
			NumberSequenceKeypoint.new(0.5, 1),
			NumberSequenceKeypoint.new(1, 0.5)
		})
		particle.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.8),
			NumberSequenceKeypoint.new(0.5, 0.5),
			NumberSequenceKeypoint.new(1, 0.8)
		})
		particle.Lifetime = NumberRange.new(1, 2)
		particle.Rate = 5
		particle.SpreadAngle = Vector2.new(180, 180)
		particle.Speed = NumberRange.new(0.5, 1)
		particle.Parent = attachment

		-- Set up touch detection
		shopPart.Touched:Connect(function(hit)
			local character = hit.Parent
			local player = Players:GetPlayerFromCharacter(character)

			if not player then return end

			-- Check cooldown for this player
			if playerCooldowns[player.UserId] then return end

			-- Set cooldown
			playerCooldowns[player.UserId] = true

			-- Get shop type from attributes
			local shopType = shopPart:GetAttribute("ShopType") or "General"

			-- Fire client event to open shop
			OpenShopEvent:FireClient(player, shopType)

			-- Reset cooldown after delay
			task.delay(shopConfig.CooldownTime, function()
				playerCooldowns[player.UserId] = nil
			end)
		end)

		-- ProximityPrompt for better UX (optional)
		local prompt = shopPart:FindFirstChild("ShopPrompt") or Instance.new("ProximityPrompt")
		prompt.Name = "ShopPrompt"
		prompt.ActionText = "Open Shop"
		prompt.ObjectText = shopPart:GetAttribute("ShopName") or "Shop"
		prompt.KeyboardKeyCode = Enum.KeyCode.E
		prompt.HoldDuration = 0
		prompt.MaxActivationDistance = shopConfig.ProximityDistance
		prompt.Parent = shopPart

		-- Connect proximity prompt
		prompt.Triggered:Connect(function(player)
			if playerCooldowns[player.UserId] then return end

			playerCooldowns[player.UserId] = true

			local shopType = shopPart:GetAttribute("ShopType") or "General"
			OpenShopEvent:FireClient(player, shopType)

			task.delay(shopConfig.CooldownTime, function()
				playerCooldowns[player.UserId] = nil
			end)
		end)
	end
end

-- Run setup when the script starts
setupShopParts()

-- Also set up new ShopTouchParts if added later
workspace.DescendantAdded:Connect(function(descendant)
	if descendant.Name == "ShopTouchPart" and descendant:IsA("BasePart") then
		task.wait() -- Wait a frame for any attributes to be set
		setupShopParts()
	end
end)

-- Clean up cooldowns when player leaves
Players.PlayerRemoving:Connect(function(player)
	playerCooldowns[player.UserId] = nil
end)