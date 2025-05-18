-- ShopHandler.server.lua
-- Place this in ServerScriptService

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local ServerStorage = game:GetService("ServerStorage")

-- Get or create the MainGameModule
local MainGameModule
local success, result = pcall(function()
	return require(script.Parent:WaitForChild("MainGameModule"))
end)

if success then
	MainGameModule = result
else
	warn("Failed to require MainGameModule: " .. tostring(result))
	-- Create a minimal version for testing
	MainGameModule = {
		GetPlayerData = function(player)
			warn("Using fallback GetPlayerData")
			return {
				coins = 0,
				pets = {},
				upgrades = {
					["Collection Speed"] = 1,
					["Pet Capacity"] = 1,
					["Collection Value"] = 1
				},
				unlockedAreas = {"Starter Meadow"}
			}
		end,

		SavePlayerData = function(player)
			warn("Using fallback SavePlayerData")
		end,

		BuyUpgrade = function(player, upgradeName)
			warn("Using fallback BuyUpgrade: " .. upgradeName)
			return false
		end,

		UnlockArea = function(player, areaName)
			warn("Using fallback UnlockArea: " .. areaName)
			return false
		end
	}
end

-- Make sure RemoteEvents folder exists
local RemoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
if not RemoteEvents then
	RemoteEvents = Instance.new("Folder")
	RemoteEvents.Name = "RemoteEvents"
	RemoteEvents.Parent = ReplicatedStorage
end

-- Make sure RemoteFunctions folder exists
local RemoteFunctions = ReplicatedStorage:FindFirstChild("RemoteFunctions")
if not RemoteFunctions then
	RemoteFunctions = Instance.new("Folder")
	RemoteFunctions.Name = "RemoteFunctions"
	RemoteFunctions.Parent = ReplicatedStorage
end

-- Create or get the remote events for shop functions
local function ensureRemoteExists(name, isFunction)
	local folder = isFunction and RemoteFunctions or RemoteEvents
	if not folder:FindFirstChild(name) then
		local remote = isFunction and Instance.new("RemoteFunction") or Instance.new("RemoteEvent")
		remote.Name = name
		remote.Parent = folder
		return remote
	end
	return folder:FindFirstChild(name)
end

-- Create required remotes
local SellPets = ensureRemoteExists("SellPets", false)
local BuyUpgrade = ensureRemoteExists("BuyUpgrade", false)
local UnlockArea = ensureRemoteExists("UnlockArea", false)
local UpdatePlayerStats = ensureRemoteExists("UpdatePlayerStats", false)
local OpenShop = ensureRemoteExists("OpenShop", false)
local PromptPurchase = ensureRemoteExists("PromptPurchase", true)

-- Function to get pet value based on rarity
local function getPetValue(pet)
	if pet.rarity == "Common" then
		return 1
	elseif pet.rarity == "Rare" then
		return 5
	elseif pet.rarity == "Epic" then
		return 20
	elseif pet.rarity == "Legendary" then
		return 100
	else
		return 1 -- Default
	end
end

-- Handler for selling pets
SellPets.OnServerEvent:Connect(function(player, petIndices)
	if not player or not petIndices or type(petIndices) ~= "table" then return end

	-- Get player data
	local playerData = MainGameModule.GetPlayerData(player)
	if not playerData then
		warn("Player data not found for " .. player.Name)
		return
	end

	-- Calculate total value
	local totalValue = 0
	local petsToRemove = {}

	-- Sort indices in descending order to avoid index shifting issues
	table.sort(petIndices, function(a, b) return a > b end)

	-- Track pets to be removed
	for _, index in ipairs(petIndices) do
		if playerData.pets[index] then
			local pet = playerData.pets[index]
			local value = getPetValue(pet)
			totalValue = totalValue + value
			table.insert(petsToRemove, index)
		end
	end

	-- Remove pets (in reverse order to avoid index shifting)
	for _, index in ipairs(petsToRemove) do
		table.remove(playerData.pets, index)
	end

	-- Add coins
	playerData.coins = playerData.coins + totalValue

	-- Save data
	MainGameModule.SavePlayerData(player)

	-- Update client
	UpdatePlayerStats:FireClient(player, playerData)

	print(player.Name .. " sold " .. #petsToRemove .. " pets for " .. totalValue .. " coins")
end)

-- Handler for buying upgrades
BuyUpgrade.OnServerEvent:Connect(function(player, upgradeName)
	-- Call the existing MainGameModule function
	local success = MainGameModule.BuyUpgrade(player, upgradeName)

	if success then
		print(player.Name .. " purchased upgrade: " .. upgradeName)

		-- Get updated data
		local playerData = MainGameModule.GetPlayerData(player)

		-- Update client
		UpdatePlayerStats:FireClient(player, playerData)
	else
		print(player.Name .. " failed to purchase upgrade: " .. upgradeName)
	end
end)

-- Handler for unlocking areas
UnlockArea.OnServerEvent:Connect(function(player, areaName)
	-- Call the existing MainGameModule function
	local success = MainGameModule.UnlockArea(player, areaName)

	if success then
		print(player.Name .. " unlocked area: " .. areaName)

		-- Get updated data
		local playerData = MainGameModule.GetPlayerData(player)

		-- Update client
		UpdatePlayerStats:FireClient(player, playerData)
	else
		print(player.Name .. " failed to unlock area: " .. areaName)
	end
end)

-- Handler for prompting purchases
PromptPurchase.OnServerInvoke = function(player, itemType, itemName)
	if itemType == "GamePass" then
		-- Get game pass ID
		local passId = 0
		if itemName == "VIP Pass" then
			passId = 0000001
		elseif itemName == "Auto-Collect" then
			passId = 0000002
		end

		if passId > 0 then
			MarketplaceService:PromptGamePassPurchase(player, passId)
			return true
		end
	elseif itemType == "DevProduct" then
		-- Get developer product ID
		local productId = 0
		if itemName == "100 Coins" then
			productId = 0000001
		elseif itemName == "500 Coins" then
			productId = 0000002
		elseif itemName == "1000 Coins" then
			productId = 0000003
		end

		if productId > 0 then
			MarketplaceService:PromptProductPurchase(player, productId)
			return true
		end
	end

	return false
end

-- Create a custom ShopTouchPart if it doesn't exist
local function createShopTouchPart()
	local shopPart = workspace:FindFirstChild("ShopTouchPart")
	if not shopPart then
		shopPart = Instance.new("Part")
		shopPart.Name = "ShopTouchPart"
		shopPart.Size = Vector3.new(5, 5, 5)
		shopPart.Position = Vector3.new(0, 5, 0) -- Center of the world, 5 studs up
		shopPart.Anchored = true
		shopPart.CanCollide = true
		shopPart.BrickColor = BrickColor.new("Really blue")
		shopPart.Material = Enum.Material.Neon
		shopPart.Transparency = 0.3

		-- Add a BillboardGui with shop text
		local billboardGui = Instance.new("BillboardGui")
		billboardGui.Size = UDim2.new(0, 150, 0, 50)
		billboardGui.StudsOffset = Vector3.new(0, 3, 0)
		billboardGui.Adornee = shopPart
		billboardGui.AlwaysOnTop = true

		local shopLabel = Instance.new("TextLabel")
		shopLabel.Size = UDim2.new(1, 0, 1, 0)
		shopLabel.BackgroundTransparency = 0.5
		shopLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		shopLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		shopLabel.TextSize = 24
		shopLabel.Font = Enum.Font.GothamBold
		shopLabel.Text = "SHOP"
		shopLabel.Parent = billboardGui

		billboardGui.Parent = shopPart
		shopPart.Parent = workspace

		print("Created default ShopTouchPart")
	end

	return shopPart
end

-- Look for a ShopTouchPart or create one if it doesn't exist
local shopPart = createShopTouchPart()

-- Connect the touched event for the shop part
local touchConnections = {}

local function setupShopTouchPart(part)
	-- Remove any existing connection
	if touchConnections[part] then
		touchConnections[part]:Disconnect()
		touchConnections[part] = nil
	end

	-- Add new connection
	touchConnections[part] = part.Touched:Connect(function(hit)
		local character = hit.Parent
		if character and character:FindFirstChild("Humanoid") then
			local player = Players:GetPlayerFromCharacter(character)
			if player then
				-- Prevent spamming
				if not part:GetAttribute("LastTouched") or tick() - part:GetAttribute("LastTouched") > 2 then
					part:SetAttribute("LastTouched", tick())

					print("Player " .. player.Name .. " touched shop part")
					OpenShop:FireClient(player)
				end
			end
		end
	end)

	print("Set up touch connection for ShopTouchPart")
end

-- Set up the touch connection for the shop part
setupShopTouchPart(shopPart)

-- Handle when a different ShopTouchPart is added
workspace.ChildAdded:Connect(function(child)
	if child.Name == "ShopTouchPart" then
		setupShopTouchPart(child)
	end
end)

print("Shop handler script loaded!")