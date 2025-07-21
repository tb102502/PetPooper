game.Players.PlayerAdded:Connect(function(player)

	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local Trimmings = Instance.new("NumberValue")
	Trimmings.Name = "Trimmings"
	Trimmings.Parent = leaderstats

end)
--
local dataStore = game:GetService("DataStoreService"):GetDataStore("StatsDataStore")
game.Players.PlayerAdded:Connect(function(plr)
	wait()
	local plrid = "id_"..plr.UserId
	local save1 = plr.leaderstats.Trimmings


	local GetSaved = dataStore:GetAsync(plrid)
	if GetSaved then
		save1.Value = GetSaved[1]

	else
		local NumberForSaving = {save1.Value}
		dataStore:GetAsync(plrid,NumberForSaving)
	end
end)
game.Players.PlayerRemoving:Connect(function(plr)
	dataStore:SetAsync("id_"..plr.UserId,{plr.leaderstats.Trimmings.Value})
end)