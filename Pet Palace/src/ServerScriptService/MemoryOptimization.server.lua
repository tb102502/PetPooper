--[[
    MemoryOptimization.server.lua - MEMORY USAGE REDUCTION
    Place in: ServerScriptService/MemoryOptimization.server.lua
    
    FIXES:
    1. ✅ Aggressive memory cleanup
    2. ✅ Limit pet spawning to reduce memory
    3. ✅ Remove unused areas and objects
    4. ✅ Force garbage collection
    5. ✅ Monitor and report memory usage
]]

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

-- Memory optimization settings
local MEMORY_OPTIMIZATION = {
	MAX_PETS_TOTAL = 12,           -- Maximum pets in entire game
	MAX_PETS_PER_AREA = 8,         -- Maximum pets per area
	CLEANUP_INTERVAL = 30,         -- Cleanup every 30 seconds
	FORCE_GC_THRESHOLD = 800,      -- Force garbage collection at 800MB
	MAX_MEMORY_WARNING = 1200,     -- Warn at 1200MB
	PET_LIFETIME = 300,            -- Pet lifetime in seconds (5 minutes)
	AGGRESSIVE_CLEANUP = true      -- Enable aggressive cleanup
}

print("=== MEMORY OPTIMIZATION SYSTEM STARTING ===")

-- Wait for GameCore to be available
local function WaitForGameCore()
	local maxWait = 30
	local waitTime = 0

	while not _G.GameCore and waitTime < maxWait do
		wait(1)
		waitTime = waitTime + 1
	end

	if not _G.GameCore then
		warn("MemoryOptimization: GameCore not found after " .. maxWait .. " seconds")
		return nil
	end

	return _G.GameCore
end

local GameCore = WaitForGameCore()
if not GameCore then
	error("MemoryOptimization: Cannot run without GameCore")
end

-- Memory monitoring
local function GetMemoryUsage()
	local stats = game:GetService("Stats")
	return stats:GetTotalMemoryUsageMb()
end

-- Clean up workspace objects
local function CleanupWorkspace()
	local cleaned = 0

	-- Remove old debris
	for _, obj in pairs(workspace:GetChildren()) do
		if obj.Name:find("CollectionSparkle") or 
			obj.Name:find("GlowEffect") or 
			obj.Name:find("ProximityGlow") or
			obj.Name:find("MagnetEffect") or
			obj.Name:find("DEBUG_PET") then
			obj:Destroy()
			cleaned = cleaned + 1
		end
	end

	-- Clean up any orphaned sounds
	for _, obj in pairs(workspace:GetDescendants()) do
		if obj:IsA("Sound") and not obj.Parent.Parent then
			obj:Destroy()
			cleaned = cleaned + 1
		end
	end

	if cleaned > 0 then
		print("MemoryOptimization: Cleaned " .. cleaned .. " workspace objects")
	end

	return cleaned
end

-- Clean up pets aggressively
local function AggressivelyCleanupPets()
	local totalPets = 0
	local removedPets = 0
	local oldestPets = {}

	-- Count and collect old pets
	local areasFolder = workspace:FindFirstChild("Areas")
	if areasFolder then
		for _, area in pairs(areasFolder:GetChildren()) do
			local petsFolder = area:FindFirstChild("Pets")
			if petsFolder then
				for _, pet in pairs(petsFolder:GetChildren()) do
					totalPets = totalPets + 1

					local spawnTime = pet:GetAttribute("SpawnTime") or os.time()
					local age = os.time() - spawnTime

					-- Mark pets for removal if too old or if we have too many
					if age > MEMORY_OPTIMIZATION.PET_LIFETIME or totalPets > MEMORY_OPTIMIZATION.MAX_PETS_TOTAL then
						table.insert(oldestPets, {pet = pet, age = age})
					end
				end
			end
		end
	end

	-- Sort by age (oldest first)
	table.sort(oldestPets, function(a, b) return a.age > b.age end)

	-- Remove excess pets
	local petsToRemove = math.max(0, totalPets - MEMORY_OPTIMIZATION.MAX_PETS_TOTAL)
	petsToRemove = math.max(petsToRemove, #oldestPets)

	for i = 1, math.min(petsToRemove, #oldestPets) do
		local petInfo = oldestPets[i]
		if petInfo.pet and petInfo.pet.Parent then
			-- Clean up behavior connection
			local behaviorId = petInfo.pet:GetAttribute("BehaviorId")
			if behaviorId and GameCore.Systems.Pets.BehaviorConnections[behaviorId] then
				local connection = GameCore.Systems.Pets.BehaviorConnections[behaviorId]
				if connection then
					connection:Disconnect()
				end
				GameCore.Systems.Pets.BehaviorConnections[behaviorId] = nil
			end

			petInfo.pet:Destroy()
			removedPets = removedPets + 1
		end
	end

	if removedPets > 0 then
		print("MemoryOptimization: Removed " .. removedPets .. " old pets (Total: " .. (totalPets - removedPets) .. ")")
	end

	return removedPets
end

-- Clean up broken connections
local function CleanupConnections()
	local cleaned = 0

	if GameCore.Systems and GameCore.Systems.Pets and GameCore.Systems.Pets.BehaviorConnections then
		for behaviorId, connection in pairs(GameCore.Systems.Pets.BehaviorConnections) do
			if not connection or not connection.Connected then
				GameCore.Systems.Pets.BehaviorConnections[behaviorId] = nil
				cleaned = cleaned + 1
			end
		end
	end

	if cleaned > 0 then
		print("MemoryOptimization: Cleaned " .. cleaned .. " broken connections")
	end

	return cleaned
end

-- Clean up player GUIs
local function CleanupPlayerGUIs()
	local cleaned = 0

	for _, player in pairs(Players:GetPlayers()) do
		local playerGui = player:FindFirstChild("PlayerGui")
		if playerGui then
			-- Remove old notifications
			for _, gui in pairs(playerGui:GetChildren()) do
				if gui.Name:find("Notification") or 
					gui.Name:find("ErrorGui") or
					gui.Name:find("TempGui") then
					gui:Destroy()
					cleaned = cleaned + 1
				end
			end
		end
	end

	if cleaned > 0 then
		print("MemoryOptimization: Cleaned " .. cleaned .. " old GUI elements")
	end

	return cleaned
end

-- Remove unused areas (keep only Starter Meadow)
local function RemoveUnusedAreas()
	local areasFolder = workspace:FindFirstChild("Areas")
	if not areasFolder then return 0 end

	local removed = 0
	local allowedAreas = {"Starter Meadow"}

	for _, area in pairs(areasFolder:GetChildren()) do
		local isAllowed = false
		for _, allowedName in pairs(allowedAreas) do
			if area.Name == allowedName then
				isAllowed = true
				break
			end
		end

		if not isAllowed then
			-- Clean up any pets in this area first
			local petsFolder = area:FindFirstChild("Pets")
			if petsFolder then
				for _, pet in pairs(petsFolder:GetChildren()) do
					local behaviorId = pet:GetAttribute("BehaviorId")
					if behaviorId and GameCore.Systems.Pets.BehaviorConnections[behaviorId] then
						local connection = GameCore.Systems.Pets.BehaviorConnections[behaviorId]
						if connection then
							connection:Disconnect()
						end
						GameCore.Systems.Pets.BehaviorConnections[behaviorId] = nil
					end
				end
			end

			area:Destroy()
			removed = removed + 1
			print("MemoryOptimization: Removed unused area: " .. area.Name)
		end
	end

	-- Clean up GameCore spawn areas too
	if GameCore.Systems and GameCore.Systems.Pets and GameCore.Systems.Pets.SpawnAreas then
		for areaName, areaData in pairs(GameCore.Systems.Pets.SpawnAreas) do
			local isAllowed = false
			for _, allowedName in pairs(allowedAreas) do
				if areaName == allowedName then
					isAllowed = true
					break
				end
			end

			if not isAllowed then
				GameCore.Systems.Pets.SpawnAreas[areaName] = nil
				print("MemoryOptimization: Removed spawn area from GameCore: " .. areaName)
			end
		end
	end

	return removed
end

-- Force garbage collection
local function ForceGarbageCollection()
	gcinfo("collect")
	wait(0.1)
	gcinfo("collect")
	print("MemoryOptimization: Forced garbage collection")
end

-- Comprehensive cleanup function
local function PerformComprehensiveCleanup()
	local startMemory = GetMemoryUsage()
	print("MemoryOptimization: Starting cleanup - Memory: " .. math.floor(startMemory) .. "MB")

	local totalCleaned = 0

	-- 1. Clean workspace objects
	totalCleaned = totalCleaned + CleanupWorkspace()

	-- 2. Clean up pets aggressively
	totalCleaned = totalCleaned + AggressivelyCleanupPets()

	-- 3. Clean up broken connections
	totalCleaned = totalCleaned + CleanupConnections()

	-- 4. Clean up player GUIs
	totalCleaned = totalCleaned + CleanupPlayerGUIs()

	-- 5. Force garbage collection
	ForceGarbageCollection()

	local endMemory = GetMemoryUsage()
	local memorySaved = startMemory - endMemory

	print("MemoryOptimization: Cleanup complete - Cleaned " .. totalCleaned .. " objects")
	print("MemoryOptimization: Memory: " .. math.floor(startMemory) .. "MB -> " .. math.floor(endMemory) .. "MB (Saved: " .. math.floor(memorySaved) .. "MB)")

	return totalCleaned, memorySaved
end

-- Monitor memory usage and trigger cleanup
local function MonitorMemoryUsage()
	local currentMemory = GetMemoryUsage()

	-- Trigger cleanup based on memory usage
	if currentMemory > MEMORY_OPTIMIZATION.FORCE_GC_THRESHOLD then
		if currentMemory > MEMORY_OPTIMIZATION.MAX_MEMORY_WARNING then
			warn("MemoryOptimization: HIGH MEMORY USAGE: " .. math.floor(currentMemory) .. "MB - Performing aggressive cleanup!")
			PerformComprehensiveCleanup()
		else
			print("MemoryOptimization: Memory usage: " .. math.floor(currentMemory) .. "MB - Triggering cleanup")
			CleanupWorkspace()
			AggressivelyCleanupPets()
			ForceGarbageCollection()
		end
	end
end

-- Limit pet spawning
local function LimitPetSpawning()
	if not GameCore.Systems or not GameCore.Systems.Pets or not GameCore.Systems.Pets.SpawnAreas then
		return
	end

	-- Count total pets
	local totalPets = 0
	local areasFolder = workspace:FindFirstChild("Areas")
	if areasFolder then
		for _, area in pairs(areasFolder:GetChildren()) do
			local petsFolder = area:FindFirstChild("Pets")
			if petsFolder then
				totalPets = totalPets + #petsFolder:GetChildren()
			end
		end
	end

	-- Limit spawning if too many pets
	if totalPets >= MEMORY_OPTIMIZATION.MAX_PETS_TOTAL then
		-- Temporarily disable spawning by modifying spawn areas
		for areaName, areaData in pairs(GameCore.Systems.Pets.SpawnAreas) do
			if areaData.config then
				areaData.config.maxPets = math.min(areaData.config.maxPets, MEMORY_OPTIMIZATION.MAX_PETS_PER_AREA)
			end
		end
	end
end

-- Initial cleanup
print("MemoryOptimization: Performing initial cleanup...")
RemoveUnusedAreas()
PerformComprehensiveCleanup()

-- Set up regular monitoring
spawn(function()
	while true do
		wait(MEMORY_OPTIMIZATION.CLEANUP_INTERVAL)

		-- Monitor memory and clean up if needed
		MonitorMemoryUsage()

		-- Limit pet spawning
		LimitPetSpawning()

		-- Regular maintenance cleanup
		if MEMORY_OPTIMIZATION.AGGRESSIVE_CLEANUP then
			CleanupWorkspace()
			CleanupConnections()
		end
	end
end)

-- Set up performance monitoring
spawn(function()
	while true do
		wait(60) -- Every minute

		local memory = GetMemoryUsage()
		local playerCount = #Players:GetPlayers()

		-- Count active pets
		local totalPets = 0
		local areasFolder = workspace:FindFirstChild("Areas")
		if areasFolder then
			for _, area in pairs(areasFolder:GetChildren()) do
				local petsFolder = area:FindFirstChild("Pets")
				if petsFolder then
					totalPets = totalPets + #petsFolder:GetChildren()
				end
			end
		end

		-- Count active connections
		local totalConnections = 0
		if GameCore.Systems and GameCore.Systems.Pets and GameCore.Systems.Pets.BehaviorConnections then
			for _ in pairs(GameCore.Systems.Pets.BehaviorConnections) do
				totalConnections = totalConnections + 1
			end
		end

		print("MemoryOptimization: Performance Report - Memory: " .. math.floor(memory) .. "MB, Players: " .. playerCount .. ", Pets: " .. totalPets .. ", Connections: " .. totalConnections)

		-- Emergency cleanup if memory is critically high
		if memory > 1500 then
			warn("MemoryOptimization: CRITICAL MEMORY USAGE: " .. math.floor(memory) .. "MB - Emergency cleanup!")

			-- Emergency: Remove ALL pets except the newest ones
			local petsRemoved = 0
			if areasFolder then
				for _, area in pairs(areasFolder:GetChildren()) do
					local petsFolder = area:FindFirstChild("Pets")
					if petsFolder then
						local pets = petsFolder:GetChildren()
						-- Keep only the 3 newest pets per area
						for i = 4, #pets do
							if pets[i] then
								local behaviorId = pets[i]:GetAttribute("BehaviorId")
								if behaviorId and GameCore.Systems.Pets.BehaviorConnections[behaviorId] then
									local connection = GameCore.Systems.Pets.BehaviorConnections[behaviorId]
									if connection then
										connection:Disconnect()
									end
									GameCore.Systems.Pets.BehaviorConnections[behaviorId] = nil
								end
								pets[i]:Destroy()
								petsRemoved = petsRemoved + 1
							end
						end
					end
				end
			end

			ForceGarbageCollection()

			local newMemory = GetMemoryUsage()
			warn("MemoryOptimization: Emergency cleanup complete - Removed " .. petsRemoved .. " pets, Memory: " .. math.floor(memory) .. "MB -> " .. math.floor(newMemory) .. "MB")
		end
	end
end)

-- Handle player connections for memory management
Players.PlayerAdded:Connect(function(player)
	print("MemoryOptimization: Player joined - Current memory: " .. math.floor(GetMemoryUsage()) .. "MB")

	-- Clean up when player joins to make room
	if GetMemoryUsage() > 600 then
		CleanupWorkspace()
		AggressivelyCleanupPets()
	end
end)

Players.PlayerRemoving:Connect(function(player)
	-- Clean up player-specific objects
	spawn(function()
		wait(5) -- Wait a bit for other systems to clean up

		local cleaned = 0

		-- Clean up any objects with the player's name
		for _, obj in pairs(workspace:GetDescendants()) do
			if obj.Name:find(player.Name) and obj.Parent then
				obj:Destroy()
				cleaned = cleaned + 1
			end
		end

		-- Clean up farming areas
		local farmingAreas = workspace:FindFirstChild("FarmingAreas")
		if farmingAreas then
			local playerFarm = farmingAreas:FindFirstChild(player.Name)
			if playerFarm then
				playerFarm:Destroy()
				cleaned = cleaned + 1
			end
		end

		if cleaned > 0 then
			print("MemoryOptimization: Cleaned " .. cleaned .. " objects for leaving player: " .. player.Name)
		end

		ForceGarbageCollection()
		print("MemoryOptimization: Player left - Current memory: " .. math.floor(GetMemoryUsage()) .. "MB")
	end)
end)

-- Admin commands for manual memory management
Players.PlayerAdded:Connect(function(player)
	player.Chatted:Connect(function(message)
		-- Replace with your username for admin commands
		if player.Name == "TommySalami311" then
			local args = string.split(message:lower(), " ")
			local command = args[1]

			if command == "/memory" then
				local memory = GetMemoryUsage()
				print("Current memory usage: " .. math.floor(memory) .. "MB")

			elseif command == "/cleanup" then
				local cleaned, saved = PerformComprehensiveCleanup()
				print("Manual cleanup complete - Cleaned " .. cleaned .. " objects, Saved " .. math.floor(saved) .. "MB")

			elseif command == "/forcegc" then
				ForceGarbageCollection()
				print("Forced garbage collection")

			elseif command == "/memstats" then
				local memory = GetMemoryUsage()
				local playerCount = #Players:GetPlayers()

				local totalPets = 0
				local areasFolder = workspace:FindFirstChild("Areas")
				if areasFolder then
					for _, area in pairs(areasFolder:GetChildren()) do
						local petsFolder = area:FindFirstChild("Pets")
						if petsFolder then
							totalPets = totalPets + #petsFolder:GetChildren()
						end
					end
				end

				local totalConnections = 0
				if GameCore.Systems and GameCore.Systems.Pets and GameCore.Systems.Pets.BehaviorConnections then
					for _ in pairs(GameCore.Systems.Pets.BehaviorConnections) do
						totalConnections = totalConnections + 1
					end
				end

				print("=== MEMORY STATISTICS ===")
				print("Memory Usage: " .. math.floor(memory) .. "MB")
				print("Players: " .. playerCount)
				print("Total Pets: " .. totalPets)
				print("Active Connections: " .. totalConnections)
				print("Max Pets Allowed: " .. MEMORY_OPTIMIZATION.MAX_PETS_TOTAL)
				print("========================")

			elseif command == "/clearpets" then
				local removed = AggressivelyCleanupPets()
				print("Removed " .. removed .. " pets")
			end
		end
	end)
end)

print("MemoryOptimization: System active")
print("Commands: /memory, /cleanup, /forcegc, /memstats, /clearpets")
print("Max pets: " .. MEMORY_OPTIMIZATION.MAX_PETS_TOTAL)
print("Cleanup interval: " .. MEMORY_OPTIMIZATION.CLEANUP_INTERVAL .. " seconds")
print("Force GC threshold: " .. MEMORY_OPTIMIZATION.FORCE_GC_THRESHOLD .. "MB")
print("=======================================")

return MEMORY_OPTIMIZATION