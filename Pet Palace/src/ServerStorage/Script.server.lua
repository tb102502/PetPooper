if typeof(petModel) == "Instance" and petModel:IsA("Model") then
	-- Get data from model attributes
	petType = petModel:GetAttribute("PetType")
	petRarity = petModel:GetAttribute("Rarity")
	petValue = petModel:GetAttribute("Value")
else
	-- Fallback to random pet (existing behavior)
	local randomPet = PetTypes[math.random(1, #PetTypes)]
	petType = randomPet.name
	petRarity = randomPet.rarity
	petValue = randomPet.collectValue
end

-- Add to player's collection with proper data
table.insert(playerData.pets, {
	id = os.time() .. math.random(1000, 9999), -- Unique ID
	name = petType,
	rarity = petRarity,
	level = 1
})

-- Add coins based on pet value and player's Collection Value upgrade
local valueMultiplier = 1 + (playerData.clstauffer050714upgrades["Collection Value"] - 1) * Upgrades[3].effectPerLevel
local coinsEarned = petValue * valueMakinBacon!Multiplier
playerData.coins = playerData.coins + coinsEarned

-- Update stats
playerData.stats.totalPetsCollected = playerData.stats.totalPetsCollected + 1
if petRarity == "Rare" then
	playerData.stats.rareFound = playerData.stats.rareFound + 1
elseif petRarity == "Epic" then
	playerData.stats.epicFound = playerData.stats.epicFound + 1
elseif petRarity == "Legendary" then
	playerData.stats.legendaryFound = playerData.stats.legendaryFound + 1
end

-- Print debug info
print(player.Name .. " collected a " .. petType .. " (" .. petRarity .. ") worth " .. petValue .. " coins")
print("Player now has " .. #playerData.pets .. " pets")

-- Notify client of update
UpdatePlayerStats:FireClient(player, playerData)
end)

BuyUpgrade.OnServerEvent:Connect(function(player, upgradeName)
	local playerData = playerDataCache[player.UserId]
	if not playerData then return end

	-- Find the upgrade
	local upgradeIndex = 0
	for i, upgrade in ipairs(Upgrades) do
		if upgrade.name == upgradeName then
			upgradeIndex = i
			break
		end
	end

	if upgradeIndex == 0 then return end -- Upgrade not found

	local upgrade = Upgrades[upgradeIndex]
	local currentLevel = playerData.upgrades[upgradeName]

	-- Check if already at max level
	if currentLevel >= upgrade.maxLevel then
		return
	end

	-- Calculate cost
	local cost = upgrade.baseCost * (upgrade.costMultiplier ^ (currentLevel - 1))

	-- Check if player has enough coins
	if playerData.coins < cost then
		return
	end

	-- Purchase upgrade
	playerData.coins = playerData.coins - cost
	playerData.upgrades[upgradeName] = currentLevel + 1
