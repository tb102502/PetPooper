--[[
    Conflict Detection Script
    Place in StarterPlayerScripts to identify UIManager conflicts
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

-- Wait for UIManager to load
spawn(function()
	wait(5)

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end

		if input.KeyCode == Enum.KeyCode.F10 then
			detectConflicts()
		end
	end)

	print("CONFLICT DETECTOR: Press F10 to check for UIManager conflicts")
end)

function detectConflicts()
	print("=== UIMANAGER CONFLICT DETECTION ===")

	if not _G.UIManager then
		print("❌ UIManager not found in _G")
		return
	end

	local ui = _G.UIManager

	-- Check configurations
	print("1. CHECKING CONFIGURATIONS:")
	if ui.LargeUniformShopConfig then
		print("  ✅ LargeUniformShopConfig found")
		print("    Item size: " .. tostring(ui.LargeUniformShopConfig.ItemFrame.Size))
	else
		print("  ❌ LargeUniformShopConfig missing!")
	end

	if ui.UniformShopConfig then
		print("  ⚠️ OLD UniformShopConfig still exists (SHOULD BE REMOVED)")
	else
		print("  ✅ No old UniformShopConfig found")
	end

	if ui.ItemConfig then
		print("  ⚠️ OLD ItemConfig still exists (SHOULD BE REMOVED)")
	else
		print("  ✅ No old ItemConfig found")
	end

	-- Check for conflicting methods
	print("2. CHECKING FOR CONFLICTING METHODS:")
	local conflictingMethods = {
		"CreateTrulyUniformShopItem",
		"CreateStandardShopItemFrame",
		"GetAdjustedItemConfig",
		"CreateUniformPriceArea",
		"CreateUniformButtonArea",
		"PopulateUniformShopTabContent"
	}

	local foundConflicts = 0
	for _, methodName in ipairs(conflictingMethods) do
		if ui[methodName] then
			print("  ❌ CONFLICT: " .. methodName .. " (should be removed)")
			foundConflicts = foundConflicts + 1
		else
			print("  ✅ No conflict: " .. methodName)
		end
	end

	-- Check for required large methods
	print("3. CHECKING FOR REQUIRED LARGE METHODS:")
	local requiredMethods = {
		"CreateLargeUniformShopItem",
		"CreateLargePriceArea", 
		"CreateLargeButtonArea",
		"CreateLargeBadge",
		"PopulateLargeShopTabContent",
		"PopulateLargeSellTab"
	}

	local missingMethods = 0
	for _, methodName in ipairs(requiredMethods) do
		if ui[methodName] then
			print("  ✅ Found: " .. methodName)
		else
			print("  ❌ MISSING: " .. methodName)
			missingMethods = missingMethods + 1
		end
	end

	-- Check main population method
	print("4. CHECKING MAIN POPULATION METHOD:")
	if ui.PopulateShopTabContent then
		print("  ✅ PopulateShopTabContent exists")
		-- Try to see what it calls
		local success, _ = pcall(function()
			-- This won't actually run but will help us see if methods exist
			if ui.PopulateLargeShopTabContent then
				print("    ✅ Redirects to PopulateLargeShopTabContent")
			else
				print("    ❌ PopulateLargeShopTabContent missing!")
			end
		end)
	else
		print("  ❌ PopulateShopTabContent missing!")
	end

	-- Check for broken method calls
	print("5. CHECKING FOR BROKEN METHOD CALLS:")
	local brokenCalls = {
		"GetAdjustedItemConfig",
		"CreateStandardShopItemFrame"
	}

	for _, methodName in ipairs(brokenCalls) do
		if ui[methodName] then
			print("  ❌ BROKEN: " .. methodName .. " still exists (will cause errors)")
		else
			print("  ✅ Clean: " .. methodName .. " not found")
		end
	end

	-- Summary
	print("=== SUMMARY ===")
	if foundConflicts > 0 then
		print("❌ Found " .. foundConflicts .. " conflicting methods - REMOVE THESE")
	else
		print("✅ No conflicting methods found")
	end

	if missingMethods > 0 then
		print("❌ Missing " .. missingMethods .. " required large methods - ADD THESE")
	else
		print("✅ All required large methods found")
	end

	if foundConflicts == 0 and missingMethods == 0 then
		print("🎉 UIManager appears to be clean! Try opening shop with H key.")
	else
		print("🔧 Apply the fixes from the Clean UIManager Fix artifact")
	end

	print("=======================================")
end

print("Conflict Detection Script loaded - Press F10 to run check")