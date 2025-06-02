-- UFOCropDestruction.server.lua
-- Place in ServerScriptService

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

-- RemoteEvent for UFO attack visuals and sound
local ufoAttackEvent = Instance.new("RemoteEvent")
ufoAttackEvent.Name = "UFOAttack"
ufoAttackEvent.Parent = ReplicatedStorage

local CROP_FOLDER_NAME = "Crops" -- Adjust if your crops are stored elsewhere
local UFO_INTERVAL = 600 -- 10 minutes in seconds

-- Utility: Get all crop instances in farm plots
local function getAllCrops()
	local crops = {}
	local farmFolder = workspace:FindFirstChild("FarmPlots") or workspace
	for _, plot in ipairs(farmFolder:GetChildren()) do
		local cropFolder = plot:FindFirstChild(CROP_FOLDER_NAME)
		if cropFolder then
			for _, crop in ipairs(cropFolder:GetChildren()) do
				table.insert(crops, crop)
			end
		end
	end
	return crops
end

-- Destroy crops under the UFO beam
local function destroyCropsInPath(pathRegion)
	local destroyed = 0
	for _, crop in ipairs(getAllCrops()) do
		if pathRegion:Contains(crop.Position) then
			crop:Destroy()
			destroyed = destroyed + 1
		end
	end
	return destroyed
end

-- Main UFO Event Loop
spawn(function()
	while true do
		wait(UFO_INTERVAL)

		-- 1. Sky darkens and tornado siren plays
		ufoAttackEvent:FireAllClients("START") -- Clients handle sky/siren/beam

		-- 2. Wait a few seconds for effect buildup
		wait(3)

		-- 3. Simulate UFO beam moving through plots and destroying crops
		-- You may want to define plot positions/area for accuracy
		local ufoPathRegion = Region3.new(Vector3.new(-400, 0, 75), Vector3.new(60, 10, 200)) -- Adjust as needed
		local destroyedCount = destroyCropsInPath(ufoPathRegion)

		-- 4. Notify clients beam is done
		ufoAttackEvent:FireAllClients("END", destroyedCount)
	end
end)
