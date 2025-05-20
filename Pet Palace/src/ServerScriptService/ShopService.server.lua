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
-- Function to set up shop parts
local function setupShopParts()
	-- Find all ShopTouchParts in the workspace
	-- Find all ShopTouchParts in the workspace
	local shopParts = workspace:WaitForChild("ShopTouchPart")
	local allDescendants = workspace:GetDescendants()
	local shopParts = {}
	for _, descendant in ipairs(allDescendants) do
		if descendant.Name == "ShopTouchPart" then
			table.insert(shopParts, descendant)
		end
	end

	if #shopParts == 0 then
		warn("No ShopTouchPart found in workspace! Please add at least one.")
		return
	end

	print("Setting up " .. #shopParts .. " shop parts")

	-- ... (rest of your function remains the same)

		-- Configure the part for optimized touch detection
		shopParts.CanCollide = false
		shopParts.Transparency = 0.8
		shopParts.Anchored = true

		-- Set up touch detection
		shopParts.Touched:Connect(function(hit)
			local character = hit.Parent
			local player = Players:GetPlayerFromCharacter(character)

			if not player then return end

			-- Check cooldown for this player
			if playerCooldowns[player.UserId] then return end

			-- Set cooldown
			playerCooldowns[player.UserId] = true

			-- Get shop type from attributes
			local shopType = shopParts:GetAttribute("ShopType") or "General"

			-- Fire client event to open shop
			OpenShopEvent:FireClient(player, shopType)

			-- Reset cooldown after delay
			task.delay(shopConfig.CooldownTime, function()
				playerCooldowns[player.UserId] = nil
			end)
		end)

		-- ProximityPrompt for better UX (optional)
		local prompt = shopParts:FindFirstChild("ShopPrompt") or Instance.new("ProximityPrompt")
		prompt.Name = "ShopPrompt"
		prompt.ActionText = "Open Shop"
		prompt.ObjectText = shopParts:GetAttribute("ShopName") or "Shop"
		prompt.KeyboardKeyCode = Enum.KeyCode.E
		prompt.HoldDuration = 0
		prompt.MaxActivationDistance = shopConfig.ProximityDistance
		prompt.Parent = shopParts

		-- Connect proximity prompt
		prompt.Triggered:Connect(function(player)
			if playerCooldowns[player.UserId] then return end

			playerCooldowns[player.UserId] = true

			local shopType = shopParts:GetAttribute("ShopType") or "General"
			OpenShopEvent:FireClient(player, shopType)

			task.delay(shopConfig.CooldownTime, function()
				playerCooldowns[player.UserId] = nil
			end)
		end)
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