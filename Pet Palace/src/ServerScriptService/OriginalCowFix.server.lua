--[[
    OriginalCowFix.server.lua - Handle Template/Original Cow Issues
    Place in: ServerScriptService/OriginalCowFix.server.lua
    
    This script fixes the "cow without owner" warning for template cows
]]

local Players = game:GetService("Players")

print("🐄 OriginalCowFix: Fixing template cow issues...")

-- ========== TEMPLATE COW HANDLING ==========

local function handleTemplateCows()
	print("🔧 OriginalCowFix: Handling template cows...")

	local fixedCount = 0

	for _, obj in pairs(workspace:GetChildren()) do
		-- Check for cows without owners
		if (obj.Name == "cow" or obj.Name:find("cow_")) and not obj:GetAttribute("Owner") then
			print("🔍 Found cow without owner: " .. obj.Name)

			-- Check if this is the original template cow
			if obj.Name == "cow" then
				print("📋 This appears to be the original template cow")

				-- Option 1: Mark it as a template (recommended)
				obj:SetAttribute("IsTemplate", true)
				obj:SetAttribute("OriginalCow", true)
				obj.Name = "OriginalCow" -- Rename to avoid confusion

				print("✅ Marked as template cow: " .. obj.Name)
				fixedCount = fixedCount + 1

			elseif obj.Name:find("cow_") then
				-- This looks like a player cow without proper ownership
				print("🔍 This looks like a player cow without ownership")

				-- Try to determine ownership
				local ownerId = nil
				local ownerName = nil

				-- Extract user ID from cow name (format: cow_userId_number)
				local userIdMatch = obj.Name:match("cow_(%d+)_")
				if userIdMatch then
					ownerId = tonumber(userIdMatch)
					local player = Players:GetPlayerByUserId(ownerId)
					if player then
						ownerName = player.Name
						print("🔍 Determined owner from ID: " .. ownerName)
					end
				end

				-- If no owner found, check proximity to players
				if not ownerName then
					for _, player in pairs(Players:GetPlayers()) do
						if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
							local playerPos = player.Character.HumanoidRootPart.Position
							local cowPos = obj:GetPivot().Position
							local distance = (playerPos - cowPos).Magnitude

							-- If player is very close, assume ownership
							if distance < 25 then
								ownerName = player.Name
								ownerId = player.UserId
								print("🔍 Inferred ownership from proximity: " .. ownerName)
								break
							end
						end
					end
				end

				-- Apply ownership if found
				if ownerName then
					obj:SetAttribute("Owner", ownerName)
					obj:SetAttribute("OwnerId", ownerId)
					obj:SetAttribute("CowId", obj.Name)
					print("✅ Fixed ownership: " .. obj.Name .. " -> " .. ownerName)
					fixedCount = fixedCount + 1
				else
					-- No owner found - this might be an orphaned cow
					print("⚠️ No owner found for: " .. obj.Name)

					-- Option A: Remove orphaned cow
					-- obj:Destroy()
					-- print("🗑️ Removed orphaned cow: " .. obj.Name)

					-- Option B: Mark as orphaned for manual review
					obj:SetAttribute("Orphaned", true)
					obj:SetAttribute("OrphanedTime", os.time())
					print("🏷️ Marked as orphaned: " .. obj.Name)
					fixedCount = fixedCount + 1
				end
			end
		end
	end

	return fixedCount
end

-- ========== CLEAN UP TEMPLATE SYSTEM ==========

local function cleanupTemplateSystem()
	print("🧹 OriginalCowFix: Cleaning up template system...")

	local templateCow = workspace:FindFirstChild("OriginalCow")
	if not templateCow then
		templateCow = workspace:FindFirstChild("cow")
	end

	if templateCow then
		print("📋 Found template cow: " .. templateCow.Name)

		-- Ensure it's properly marked as template
		templateCow:SetAttribute("IsTemplate", true)
		templateCow:SetAttribute("OriginalCow", true)
		templateCow:SetAttribute("DoNotProcess", true) -- Skip in ownership monitoring

		-- Remove any incorrect ownership attributes
		templateCow:SetAttribute("Owner", nil)
		templateCow:SetAttribute("OwnerId", nil)

		-- Rename to avoid confusion
		if templateCow.Name == "cow" then
			templateCow.Name = "OriginalCow"
		end

		print("✅ Template cow properly configured")
		return true
	else
		print("ℹ️ No template cow found")
		return false
	end
end

-- ========== UPDATE OWNERSHIP MONITORING ==========

local function updateOwnershipMonitoring()
	print("🔄 OriginalCowFix: Updating ownership monitoring to ignore templates...")

	-- Modify the CowOwnershipFix monitoring to ignore template cows
	if _G.CowOwnershipFix then
		print("✅ Found CowOwnershipFix - updating its monitoring")
		-- The monitoring will now check for DoNotProcess attribute
	end
end

-- ========== DEBUG COMMANDS ==========

local function setupTemplateCowCommands()
	print("🔧 Setting up template cow commands...")

	Players.PlayerAdded:Connect(function(player)
		player.Chatted:Connect(function(message)
			if player.Name == "TommySalami311" then -- Change to your username
				local command = message:lower()

				if command == "/fixtemplatecow" then
					print("🔧 Fixing template cow issues...")
					local fixed = handleTemplateCows()
					cleanupTemplateSystem()
					print("✅ Fixed " .. fixed .. " cow ownership issues")

				elseif command == "/checktemplate" then
					print("🔍 Checking template cow status...")

					local templateCow = workspace:FindFirstChild("OriginalCow") or workspace:FindFirstChild("cow")
					if templateCow then
						print("📋 Template cow found: " .. templateCow.Name)
						print("  IsTemplate: " .. tostring(templateCow:GetAttribute("IsTemplate")))
						print("  OriginalCow: " .. tostring(templateCow:GetAttribute("OriginalCow")))
						print("  DoNotProcess: " .. tostring(templateCow:GetAttribute("DoNotProcess")))
						print("  Owner: " .. tostring(templateCow:GetAttribute("Owner")))
						print("  Position: " .. tostring(templateCow:GetPivot().Position))
					else
						print("❌ No template cow found")
					end

				elseif command == "/listallcows" then
					print("🐄 Listing ALL cows in workspace...")

					local cowCount = 0
					for _, obj in pairs(workspace:GetChildren()) do
						if obj.Name == "cow" or obj.Name:find("cow_") or obj.Name == "OriginalCow" then
							cowCount = cowCount + 1
							local owner = obj:GetAttribute("Owner")
							local isTemplate = obj:GetAttribute("IsTemplate")
							local isOrphaned = obj:GetAttribute("Orphaned")

							print("  " .. cowCount .. ". " .. obj.Name)
							print("    Owner: " .. tostring(owner))
							print("    IsTemplate: " .. tostring(isTemplate))
							print("    Orphaned: " .. tostring(isOrphaned))
							print("    Position: " .. tostring(obj:GetPivot().Position))
						end
					end

					print("Total cows found: " .. cowCount)

				elseif command == "/cleanorphans" then
					print("🧹 Cleaning up orphaned cows...")

					local removedCount = 0
					for _, obj in pairs(workspace:GetChildren()) do
						if obj:GetAttribute("Orphaned") then
							print("🗑️ Removing orphaned cow: " .. obj.Name)
							obj:Destroy()
							removedCount = removedCount + 1
						end
					end

					print("✅ Removed " .. removedCount .. " orphaned cows")

				elseif command == "/assignorphan" then
					print("👤 Assigning orphaned cows to " .. player.Name .. "...")

					local assignedCount = 0
					for _, obj in pairs(workspace:GetChildren()) do
						if obj:GetAttribute("Orphaned") and not obj:GetAttribute("IsTemplate") then
							obj:SetAttribute("Owner", player.Name)
							obj:SetAttribute("OwnerId", player.UserId)
							obj:SetAttribute("CowId", obj.Name)
							obj:SetAttribute("Orphaned", nil)
							obj:SetAttribute("OrphanedTime", nil)

							print("✅ Assigned orphan to you: " .. obj.Name)
							assignedCount = assignedCount + 1
						end
					end

					print("✅ Assigned " .. assignedCount .. " orphaned cows to " .. player.Name)
				end
			end
		end)
	end)

	print("✅ Template cow commands ready")
end

-- ========== IMPROVED MONITORING PATCH ==========

local function patchOwnershipMonitoring()
	print("🔧 OriginalCowFix: Patching ownership monitoring...")

	-- Create a better monitoring function that ignores templates
	local function improvedOwnershipCheck()
		for _, obj in pairs(workspace:GetChildren()) do
			if (obj.Name == "cow" or obj.Name:find("cow_")) and not obj:GetAttribute("Owner") then
				-- Skip if it's marked as template or should not be processed
				if obj:GetAttribute("IsTemplate") or obj:GetAttribute("DoNotProcess") or obj:GetAttribute("OriginalCow") then
					-- Skip template cows
					continue
				end

				print("⚠️ Found cow without owner: " .. obj.Name .. " (attempting to fix)")

				-- Try to assign to nearest player
				local nearestPlayer = nil
				local nearestDistance = math.huge

				for _, player in pairs(Players:GetPlayers()) do
					if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
						local distance = (player.Character.HumanoidRootPart.Position - obj:GetPivot().Position).Magnitude
						if distance < nearestDistance and distance < 30 then
							nearestDistance = distance
							nearestPlayer = player
						end
					end
				end

				if nearestPlayer then
					obj:SetAttribute("Owner", nearestPlayer.Name)
					obj:SetAttribute("OwnerId", nearestPlayer.UserId)
					obj:SetAttribute("CowId", obj.Name)
					print("✅ Auto-assigned cow " .. obj.Name .. " to " .. nearestPlayer.Name)
				else
					-- No nearby player found - mark as orphaned
					obj:SetAttribute("Orphaned", true)
					obj:SetAttribute("OrphanedTime", os.time())
					print("🏷️ Marked cow as orphaned: " .. obj.Name)
				end
			end
		end
	end

	-- Override the monitoring if it exists
	if _G.CowOwnershipFix then
		_G.CowOwnershipFix.improvedMonitoring = improvedOwnershipCheck
	end

	-- Start improved monitoring
	spawn(function()
		while true do
			wait(60) -- Check every minute
			pcall(improvedOwnershipCheck)
		end
	end)

	print("✅ Improved ownership monitoring started")
end

-- ========== MAIN EXECUTION ==========

local function main()
	-- Fix template cows immediately
	local fixed = handleTemplateCows()
	cleanupTemplateSystem()

	-- Setup improved monitoring
	patchOwnershipMonitoring()

	-- Setup commands
	setupTemplateCowCommands()

	print("✅ OriginalCowFix: Complete!")
	print("Fixed " .. fixed .. " cow ownership issues")
end

-- Execute with delay to let other systems load
wait(3)

local success, error = pcall(main)

if not success then
	warn("❌ OriginalCowFix failed: " .. tostring(error))
else
	print("🎉 OriginalCowFix: Ready!")
	print("")
	print("🐄 TEMPLATE COW COMMANDS:")
	print("  /fixtemplatecow - Fix template cow and ownership issues")
	print("  /checktemplate - Check template cow status")
	print("  /listallcows - List all cows in workspace")
	print("  /cleanorphans - Remove orphaned cows")
	print("  /assignorphan - Assign orphaned cows to yourself")
	print("")
	print("🔧 The ownership monitoring warning should now be resolved!")
end