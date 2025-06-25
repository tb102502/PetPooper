--[[
    Quick Test Commands
    Place in: ServerScriptService/QuickTest.server.lua
    
    Simple commands to test that everything is working
]]

local Players = game:GetService("Players")

-- Wait for systems to load
wait(3)

print("🧪 QUICK TEST COMMANDS LOADED")

-- Test command when you type in chat
Players.PlayerAdded:Connect(function(player)
	player.Chatted:Connect(function(message)
		local args = string.split(message:lower(), " ")
		local command = args[1]

		-- Test shop command
		if command == "/testshop" then
			print("🛒 Testing shop for " .. player.Name)

			-- Give test resources first
			if _G.GiveTestResources then
				_G.GiveTestResources(player.Name)
			end

			-- Test emergency shop
			if _G.EmergencyShopTest then
				local items = _G.EmergencyShopTest(player.Name)
				print("✅ Shop test complete - found " .. #items .. " items")
			end

			-- Quick setup command
		elseif command == "/quicksetup" then
			print("⚡ Quick setup for " .. player.Name)

			if _G.GiveTestResources then
				_G.GiveTestResources(player.Name)
				print("✅ Gave test resources")
			end

			if _G.AdminTools and _G.AdminTools.SetupPlayer then
				_G.AdminTools.SetupPlayer(player.Name)
				print("✅ Ran admin setup")
			end

			-- Debug command
		elseif command == "/debug" then
			print("🔍 Debug info for " .. player.Name)

			-- Check ItemConfig
			local ReplicatedStorage = game:GetService("ReplicatedStorage")
			local itemConfig = ReplicatedStorage:FindFirstChild("ItemConfig")
			print("ItemConfig exists: " .. tostring(itemConfig ~= nil))

			-- Check GameRemotes
			local gameRemotes = ReplicatedStorage:FindFirstChild("GameRemotes")
			print("GameRemotes exists: " .. tostring(gameRemotes ~= nil))

			if gameRemotes then
				local getShopItems = gameRemotes:FindFirstChild("GetShopItems")
				print("GetShopItems exists: " .. tostring(getShopItems ~= nil))

				if getShopItems then
					print("GetShopItems type: " .. getShopItems.ClassName)
				end
			end

			-- Check global systems
			print("_G.GameCore exists: " .. tostring(_G.GameCore ~= nil))
			print("_G.ShopSystem exists: " .. tostring(_G.ShopSystem ~= nil))
			print("_G.PlayerData exists: " .. tostring(_G.PlayerData ~= nil))

			-- Force shop test
		elseif command == "/forceshop" then
			print("🔨 Force testing shop...")

			local ReplicatedStorage = game:GetService("ReplicatedStorage")
			local gameRemotes = ReplicatedStorage:FindFirstChild("GameRemotes")

			if gameRemotes then
				local getShopItems = gameRemotes:FindFirstChild("GetShopItems")
				if getShopItems and getShopItems:IsA("RemoteFunction") then
					local success, result = pcall(function()
						return getShopItems:InvokeServer()
					end)

					if success then
						print("✅ GetShopItems returned " .. #result .. " items")

						local categories = {}
						for _, item in ipairs(result) do
							categories[item.category] = (categories[item.category] or 0) + 1
						end

						print("Categories found:")
						for cat, count in pairs(categories) do
							print("  " .. cat .. ": " .. count)
						end
					else
						print("❌ GetShopItems failed: " .. tostring(result))
					end
				end
			end
		end
	end)
end)

-- Auto-test for existing players
for _, player in pairs(Players:GetPlayers()) do
	print("🎮 Auto-testing for existing player: " .. player.Name)

	spawn(function()
		wait(1)

		-- Give resources
		if _G.GiveTestResources then
			_G.GiveTestResources(player.Name)
		end

		-- Test shop
		if _G.EmergencyShopTest then
			_G.EmergencyShopTest(player.Name)
		end
	end)
end

print("💬 Chat Commands Available:")
print("  /testshop - Test the shop system")
print("  /quicksetup - Give resources and setup")
print("  /debug - Show debug information")
print("  /forceshop - Force test GetShopItems")