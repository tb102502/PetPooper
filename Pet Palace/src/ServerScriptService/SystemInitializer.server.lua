-- Place in ServerScriptService/SystemInitializer.server.lua
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

print("=== System Initializer Starting ===")

local function ValidateStructure()
	local coreFolder = ServerScriptService:FindFirstChild("Core")
	assert(coreFolder, "Core folder not found in ServerScriptService")
	assert(coreFolder:FindFirstChild("GameCore"), "GameCore module not found in Core")
	assert(ReplicatedStorage:FindFirstChild("ItemConfig"), "ItemConfig not found in ReplicatedStorage")
	return true
end

local ServerScriptService = game:GetService("ServerScriptService")

local function LoadGameCore()
	local coreFolder = ServerScriptService:WaitForChild("Core")
	local gameCoreModule = coreFolder:WaitForChild("GameCore")
	local success, result = pcall(function()
		return require(gameCoreModule)
	end)
	if not success then
		error("CRITICAL: Failed to load GameCore module: " .. tostring(result))
	end
	if not result or type(result) ~= "table" then
		error("CRITICAL: GameCore module returned invalid data: " .. type(result))
	end
	if type(result.Initialize) ~= "function" then
		error("CRITICAL: GameCore is missing Initialize function")
	end
	return result
end

local function InitAllSystems()
	local GameCore = LoadGameCore()
	GameCore:Initialize()  -- Server core must always be initialized first!

	
	end

	print("SystemInitializer: All major systems initialized!")


InitAllSystems()

Players.PlayerAdded:Connect(function(player)
	print("SystemInitializer: Player " .. player.Name .. " joined")
end)

game:BindToClose(function()
	print("SystemInitializer: Server shutting down, saving data...")
	if _G.GameCore and _G.GameCore.SavePlayerData then
		for _, player in ipairs(Players:GetPlayers()) do
			pcall(function() _G.GameCore:SavePlayerData(player) end)
		end
	end
	wait(2)
end)
