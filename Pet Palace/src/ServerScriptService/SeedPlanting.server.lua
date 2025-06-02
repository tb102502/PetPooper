local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlantSeedEvent = ReplicatedStorage:WaitForChild("PlantSeed")

PlantSeedEvent.OnServerEvent:Connect(function(player, seedName)
	if not seedName then
		warn("No seed selected")
		return
	end
	-- Proceed with planting logic
	-- Example: Check if player has the seed in inventory, then plant
end)
