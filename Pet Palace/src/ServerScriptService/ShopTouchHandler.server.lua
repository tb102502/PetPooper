-- ShopTouchHandler.lua (Fixed for Server Handler)
-- Place in ServerScriptService

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Import our shop handler functions from MinimalShopHandler
-- We'll trigger the same logic that the OpenShop RemoteEvent uses

-- Wait for required services
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local OpenShopClient = RemoteEvents:WaitForChild("OpenShopClient")
local UpdateShopData = RemoteEvents:WaitForChild("UpdateShopData")

-- Import PlayerDataService
local ServerStorage = game:GetService("ServerStorage")
local PlayerDataService = require(ServerStorage:WaitForChild("Modules"):WaitForChild("PlayerDataService"))

-- Get the shop touch part
local farmModel = workspace
	:WaitForChild("Areas")
	:WaitForChild("Starter Meadow")
	:WaitForChild("Farm")

local shopTouchPart = farmModel:WaitForChild("ShopTouchPart")
assert(shopTouchPart:IsA("BasePart"), "ShopTouchPart must be a BasePart")

-- Track last touch times
local lastTouch = {}

-- Function to send shop data (copied from MinimalShopHandler)
local function sendShopData(player)
	local data = PlayerDataService.GetPlayerData(player)
	if not data then return end

	local SHOP_CONFIG = {
		upgrades = {
			walkSpeed = {name = "Swift Steps", baseCost = 100, maxLevel = 10},
			stamina = {name = "Extra Stamina", baseCost = 150, maxLevel = 5},
			collectRange = {name = "Extended Reach", baseCost = 200, maxLevel = 8},
			collectSpeed = {name = "Quick Collection", baseCost = 250, maxLevel = 6}
		},
		areas = {
			{name = "Mystic Forest", cost = 1000, currency = "coins"},
			{name = "Dragon's Lair", cost = 10000, currency = "coins"},
			{name = "Crystal Cave", cost = 500, currency = "gems"}
		}
	}

	local shopData = {
		Collecting = {},
		Areas = {},
		Premium = {}
	}

	-- Add upgrade data
	for upgradeId, config in pairs(SHOP_CONFIG.upgrades) do
		local currentLevel = data.upgrades[upgradeId] or 1
		local cost = math.floor(config.baseCost * (1.5 ^ (currentLevel - 1)))

		table.insert(shopData.Collecting, {
			id = upgradeId,
			currentLevel = currentLevel,
			maxLevel = config.maxLevel,
			cost = cost,
			maxed = currentLevel >= config.maxLevel
		})
	end

	-- Add area data
	for i, areaConfig in ipairs(SHOP_CONFIG.areas) do
		local isUnlocked = false
		for _, unlockedArea in ipairs(data.unlockedAreas) do
			if unlockedArea == areaConfig.name then
				isUnlocked = true
				break
			end
		end

		table.insert(shopData.Areas, {
			id = areaConfig.name,
			unlocked = isUnlocked,
			cost = areaConfig.cost,
			currency = areaConfig.currency
		})
	end

	UpdateShopData:FireClient(player, shopData)
end

-- Handle touch/click
local function handleShopInteraction(player)
	if not player then return end

	-- Cooldown check
	if lastTouch[player] and tick() - lastTouch[player] < 1 then 
		return 
	end

	lastTouch[player] = tick()

	-- Send shop data and open shop
	sendShopData(player)
	OpenShopClient:FireClient(player, "Collecting")

	print(player.Name .. " opened shop via touch part")
end

-- Connect touch event
shopTouchPart.Touched:Connect(function(hit)
	local player = Players:GetPlayerFromCharacter(hit.Parent)
	handleShopInteraction(player)
end)

-- Add click detector as backup
local clickDetector = shopTouchPart:FindFirstChild("ClickDetector")
if not clickDetector then
	clickDetector = Instance.new("ClickDetector")
	clickDetector.MaxActivationDistance = 10
	clickDetector.Parent = shopTouchPart
end

clickDetector.MouseClick:Connect(function(player)
	handleShopInteraction(player)
end)

-- Clean up on player leave
Players.PlayerRemoving:Connect(function(player)
	lastTouch[player] = nil
end)

-- Make the touch part more visible
shopTouchPart.BrickColor = BrickColor.new("Bright green")
shopTouchPart.Material = Enum.Material.ForceField
shopTouchPart.Transparency = 0.5

-- Add a sign or GUI above it
local billboard = Instance.new("BillboardGui")
billboard.Size = UDim2.new(0, 100, 0, 50)
billboard.StudsOffset = Vector3.new(0, 5, 0)
billboard.Parent = shopTouchPart

local label = Instance.new("TextLabel")
label.Size = UDim2.new(1, 0, 1, 0)
label.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
label.BackgroundTransparency = 0.3
label.Text = "🛒 SHOP"
label.TextColor3 = Color3.fromRGB(255, 255, 255)
label.TextSize = 18
label.Font = Enum.Font.GothamBold
label.Parent = billboard

-- Add rounded corners
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = label

print("Shop touch handler loaded and configured!")