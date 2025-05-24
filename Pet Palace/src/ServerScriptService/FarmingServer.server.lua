-- FarmingServer.server.lua
-- Place in ServerScriptService
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Ensure Modules folder exists
if not ReplicatedStorage:FindFirstChild("Modules") then
	local modulesFolder = Instance.new("Folder")
	modulesFolder.Name = "Modules"
	modulesFolder.Parent = ReplicatedStorage
	print("Created Modules folder in ReplicatedStorage")
end

-- Ensure FarmingModule exists
local FarmingModule
local moduleScript = ReplicatedStorage.Modules:FindFirstChild("FarmingModule")
if not moduleScript then
	moduleScript = Instance.new("ModuleScript")
	moduleScript.Name = "FarmingModule"
	moduleScript.Parent = ReplicatedStorage.Modules
	print("Created FarmingModule in ReplicatedStorage.Modules")

	-- Load it from the file you pasted separately
	-- For now, we'll use a minimal implementation
	moduleScript.Source = [[
    local FarmingModule = {}
    
    -- Implementations would go here
    -- This is just a stub for now - paste the actual code
    
    FarmingModule.MAX_FARM_PLOTS = 10
    FarmingModule.PLOT_SIZE = Vector3.new(4, 0.5, 4)
    FarmingModule.PLOT_SPACING = 1
    
    -- Basic stubs for required functions
    function FarmingModule.SetupFarmingArea(player)
        print("Setting up farming area for", player.Name)
        return {}
    end
    
    function FarmingModule.GetPlayerFarmingData(player)
        return {
            unlockedPlots = 3,
            inventory = {
                carrot_seeds = 5,
                corn_seeds = 3
            },
            farmingLevel = 1,
            farmingExp = 0
        }
    end
    
    function FarmingModule.SavePlayerFarmingData(player, data)
        print("Saved farming data for player:", player.Name)
    end
    
    return FarmingModule
    ]]
end
FarmingModule = require(moduleScript)

-- Ensure RemoteEvents folder exists
if not ReplicatedStorage:FindFirstChild("RemoteEvents") then
	local remoteEvents = Instance.new("Folder")
	remoteEvents.Name = "RemoteEvents"
	remoteEvents.Parent = ReplicatedStorage
	print("Created RemoteEvents folder in ReplicatedStorage")
end

local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")

-- Create remote events if they don't exist
local function ensureRemoteEventExists(name)
	if not RemoteEvents:FindFirstChild(name) then
		local event = Instance.new("RemoteEvent")
		event.Name = name
		event.Parent = RemoteEvents
		print("Created missing RemoteEvent: " .. name)
	end
	return RemoteEvents:FindFirstChild(name)
end

-- Create necessary remote events
local BuySeed = ensureRemoteEventExists("BuySeed")
local PlantSeed = ensureRemoteEventExists("PlantSeed")
local HarvestPlant = ensureRemoteEventExists("HarvestPlant")
local FeedPet = ensureRemoteEventExists("FeedPet")
local GetFarmingData = ensureRemoteEventExists("GetFarmingData")
local SendNotification = ensureRemoteEventExists("SendNotification")

-- Handle player joining
Players.PlayerAdded:Connect(function(player)
	-- Create farming area for the player
	FarmingModule.SetupFarmingArea(player)

	-- Send initial farming data to client
	local playerData = FarmingModule.GetPlayerFarmingData(player)
	GetFarmingData:FireClient(player, playerData)
end)

-- Handle buying seeds
BuySeed.OnServerEvent:Connect(function(player, seedID, quantity)
	-- Implementation would connect to your shop system
	-- For demo, just assume purchase successful
	local playerData = FarmingModule.GetPlayerFarmingData(player)
	playerData.inventory[seedID] = (playerData.inventory[seedID] or 0) + (quantity or 1)
	FarmingModule.SavePlayerFarmingData(player, playerData)

	-- Send updated data to client
	GetFarmingData:FireClient(player, playerData)

	-- Send notification
	SendNotification:FireClient(
		player,
		"Seeds Purchased!",
		"You bought " .. (quantity or 1) .. " seeds.",
		"buy" -- Icon name
	)
end)

-- Handle planting seeds
PlantSeed.OnServerEvent:Connect(function(player, plotID, seedID)
	-- Find the plot
	local farmingAreas = workspace:FindFirstChild("FarmingAreas")
	if not farmingAreas then return end

	local playerFarmArea = farmingAreas:FindFirstChild(player.Name)
	if not playerFarmArea then return end

	local plot = playerFarmArea:FindFirstChild("FarmPlot_" .. plotID)
	if not plot then return end

	-- Plant the seed
	local success, message = FarmingModule.PlantSeed(player, plot, seedID)

	-- Update client
	local playerData = FarmingModule.GetPlayerFarmingData(player)
	GetFarmingData:FireClient(player, playerData)

	-- Send notification
	SendNotification:FireClient(
		player,
		success and "Seed Planted!" or "Planting Failed",
		message,
		success and "plant" or "error" -- Icon name
	)
end)

-- Handle harvesting plants
HarvestPlant.OnServerEvent:Connect(function(player, plotID)
	-- Find the plot
	local farmingAreas = workspace:FindFirstChild("FarmingAreas")
	if not farmingAreas then return end

	local playerFarmArea = farmingAreas:FindFirstChild(player.Name)
	if not playerFarmArea then return end

	local plot = playerFarmArea:FindFirstChild("FarmPlot_" .. plotID)
	if not plot then return end

	-- Harvest the plant
	local success, message = FarmingModule.HarvestPlant(player, plot)

	-- Update client
	local playerData = FarmingModule.GetPlayerFarmingData(player)
	GetFarmingData:FireClient(player, playerData)

	-- Send notification
	SendNotification:FireClient(
		player,
		success and "Harvest Success!" or "Harvest Failed",
		message,
		success and "harvest" or "error" -- Icon name
	)
end)

-- Handle feeding pets
FeedPet.OnServerEvent:Connect(function(player, petId, cropID)
	-- Feed the pet
	local success, message = FarmingModule.FeedPet(player, petId, cropID)

	-- Update client
	local playerData = FarmingModule.GetPlayerFarmingData(player)
	GetFarmingData:FireClient(player, playerData)

	-- Send notification
	SendNotification:FireClient(
		player,
		success and "Pet Fed!" or "Feeding Failed",
		message,
		success and "feed" or "error" -- Icon name
	)
end)

-- Update plant growth periodically
spawn(function()
	while wait(1) do -- Check every 1 second
		local currentTime = os.time()
		local farmingAreas = workspace:FindFirstChild("FarmingAreas")
		if not farmingAreas then continue end

		-- Update all planted plots for all players
		for _, playerArea in pairs(farmingAreas:GetChildren()) do
			for _, plot in pairs(playerArea:GetChildren()) do
				if plot:IsA("Model") and plot:GetAttribute("IsPlanted") then
					FarmingModule.UpdatePlantGrowth(plot, currentTime)
				end
			end
		end
	end
end)

print("Farming Server System Initialized!")