print("Hello world!")
-- UIIntegration.client.lua
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Wait for systems to load
local function waitForSystems()
	while not _G.UIManager or not _G.CowMilkingModule do
		wait(0.1)
	end
	return _G.UIManager, _G.CowMilkingModule
end

spawn(function()
	local UIManager, CowMilkingModule = waitForSystems()

	-- 1. Route milking notifications through UIManager
	local originalSendNotification = CowMilkingModule.SendNotification
	CowMilkingModule.SendNotification = function(self, player, title, message, notificationType)
		if player == LocalPlayer then
			UIManager:ShowNotification(title, message, notificationType)
		end
	end

	-- 2. Update currency when milking data changes
	game:GetService("ReplicatedStorage"):WaitForChild("GameRemotes")
		:WaitForChild("PlayerDataUpdated").OnClientEvent:Connect(function(playerData)
			UIManager:UpdateCurrencyDisplay(playerData)
		end)

	print("✅ UI systems integrated successfully!")
end)