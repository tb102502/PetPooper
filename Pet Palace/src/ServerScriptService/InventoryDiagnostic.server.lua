--[[
    INVENTORY DIAGNOSTIC SCRIPT
    Place this as a separate ServerScript in ServerScriptService
    
    This will help diagnose the exact inventory synchronization issue
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

print("🔍 === INVENTORY DIAGNOSTIC SCRIPT STARTING ===")

-- Wait for game systems to load
local function WaitForGameSystems()
	local maxWait = 30
	local startTime = tick()

	while not _G.GameCore and (tick() - startTime) < maxWait do
		wait(0.5)
	end

	if _G.GameCore then
		print("🔍 GameCore found!")
		return true
	else
		warn("🔍 GameCore not found after " .. maxWait .. " seconds")
		return false
	end
end

WaitForGameSystems()

-- Diagnostic functions
local function DiagnosePlayerInventory(player)
	if not _G.GameCore then
		print("🔍 Cannot diagnose - GameCore not available")
		return
	end

	local playerData = _G.GameCore:GetPlayerData(player)
	if not playerData then
		print("🔍 No player data found for " .. player.Name)
		return
	end

	print("🔍 === COMPLETE INVENTORY DIAGNOSIS FOR " .. player.Name .. " ===")

	-- Check farming structure
	print("🌾 FARMING DATA:")
	if playerData.farming then
		print("  ✅ farming exists")
		print("  plots: " .. tostring(playerData.farming.plots or "nil"))

		if playerData.farming.inventory then
			print("  ✅ farming.inventory exists")
			local seedCount = 0
			print("  Seeds in farming inventory:")
			for itemId, quantity in pairs(playerData.farming.inventory) do
				if itemId:find("_seeds") then
					print("    " .. itemId .. ": " .. quantity)
					seedCount = seedCount + quantity
				end
			end
			print("  Total seeds in farming: " .. seedCount)
		else
			print("  ❌ farming.inventory is nil")
		end
	else
		print("  ❌ farming is nil")
	end

	-- Check general inventory
	print("📦 GENERAL INVENTORY:")
	if playerData.inventory then
		print("  ✅ inventory exists")
		local seedCount = 0
		print("  Seeds in general inventory:")
		for itemId, quantity in pairs(playerData.inventory) do
			if itemId:find("_seeds") then
				print("    " .. itemId .. ": " .. quantity)
				seedCount = seedCount + quantity
			end
		end
		print("  Total seeds in general: " .. seedCount)
	else
		print("  ❌ inventory is nil")
	end

	-- Check purchase history
	print("🛒 PURCHASE HISTORY:")
	if playerData.purchaseHistory then
		print("  ✅ purchaseHistory exists")
		print("  Seed purchases:")
		for itemId, purchased in pairs(playerData.purchaseHistory) do
			if itemId:find("_seeds") then
				print("    " .. itemId .. ": " .. tostring(purchased))
			end
		end
	else
		print("  ❌ purchaseHistory is nil")
	end

	-- Check currency
	print("💰 CURRENCY:")
	print("  coins: " .. tostring(playerData.coins or "nil"))
	print("  farmTokens: " .. tostring(playerData.farmTokens or "nil"))

	print("🔍 ===============================================")
end

-- Monitor purchase events
local function SetupPurchaseMonitoring()
	local gameRemotes = ReplicatedStorage:FindFirstChild("GameRemotes")
	if not gameRemotes then
		warn("🔍 GameRemotes not found - cannot monitor purchases")
		return
	end

	local purchaseEvent = gameRemotes:FindFirstChild("PurchaseItem")
	if purchaseEvent then
		purchaseEvent.OnServerEvent:Connect(function(player, itemId, quantity)
			print("🔍 === PURCHASE DETECTED ===")
			print("Player: " .. player.Name)
			print("Item: " .. itemId)
			print("Quantity: " .. tostring(quantity))

			-- Check inventory before purchase
			print("🔍 BEFORE PURCHASE:")
			DiagnosePlayerInventory(player)

			-- Check inventory after purchase (with delay)
			spawn(function()
				wait(2) -- Wait for purchase to process
				print("🔍 AFTER PURCHASE:")
				DiagnosePlayerInventory(player)
			end)
		end)
		print("🔍 Purchase monitoring active!")
	end

	local plantSeedEvent = gameRemotes:FindFirstChild("PlantSeed")
	if plantSeedEvent then
		plantSeedEvent.OnServerEvent:Connect(function(player, plotModel, seedId)
			print("🔍 === PLANT SEED ATTEMPT ===")
			print("Player: " .. player.Name)
			print("Seed: " .. tostring(seedId))

			print("🔍 INVENTORY AT PLANTING TIME:")
			DiagnosePlayerInventory(player)
		end)
		print("🔍 Plant seed monitoring active!")
	end
end

-- Admin command for manual diagnosis
Players.PlayerAdded:Connect(function(player)
	player.Chatted:Connect(function(message)
		-- Replace with your username
		if player.Name == "TommySalami311" then
			local args = string.split(message:lower(), " ")
			local command = args[1]

			if command == "/fulldiagnose" then
				local targetName = args[2] or player.Name
				local targetPlayer = Players:FindFirstChild(targetName)

				if targetPlayer then
					DiagnosePlayerInventory(targetPlayer)
				else
					print("🔍 Player not found: " .. targetName)
				end

			elseif command == "/comparedata" then
				-- Compare data between GameCore and ShopSystem (if available)
				if _G.GameCore and _G.ShopSystem then
					local gameCoreData = _G.GameCore:GetPlayerData(player)
					print("🔍 === DATA COMPARISON ===")
					print("GameCore has player data: " .. tostring(gameCoreData ~= nil))

					if gameCoreData then
						print("GameCore farming inventory:")
						if gameCoreData.farming and gameCoreData.farming.inventory then
							for itemId, qty in pairs(gameCoreData.farming.inventory) do
								if itemId:find("_seeds") then
									print("  " .. itemId .. ": " .. qty)
								end
							end
						else
							print("  No farming inventory in GameCore data")
						end
					end
				else
					print("🔍 GameCore or ShopSystem not available globally")
				end

			elseif command == "/forcesync" then
				-- Force sync inventory data
				if _G.GameCore then
					local playerData = _G.GameCore:GetPlayerData(player)
					if playerData then
						-- Ensure farming structure exists
						if not playerData.farming then
							playerData.farming = {plots = 1, inventory = {}}
							print("🔍 Created farming structure")
						end
						if not playerData.farming.inventory then
							playerData.farming.inventory = {}
							print("🔍 Created farming inventory")
						end

						-- Force save and update
						_G.GameCore:SavePlayerData(player, true)

						if _G.GameCore.RemoteEvents and _G.GameCore.RemoteEvents.PlayerDataUpdated then
							_G.GameCore.RemoteEvents.PlayerDataUpdated:FireClient(player, playerData)
							print("🔍 Sent player data update to client")
						end

						print("🔍 Force sync complete")
					end
				end
			end
		end
	end)
end)

-- Start monitoring
spawn(function()
	wait(5) -- Wait for systems to fully load
	SetupPurchaseMonitoring()
	print("🔍 Inventory diagnostic system ready!")
	print("🔍 Admin commands:")
	print("  /fulldiagnose [player] - Complete inventory diagnosis")
	print("  /comparedata - Compare GameCore and ShopSystem data")
	print("  /forcesync - Force sync player data")
end)

return true