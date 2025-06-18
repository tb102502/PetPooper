-- Enhanced UFOCropDestructionClient.client.lua
-- Place in: StarterPlayer/StarterPlayerScripts/

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer

-- Wait for UFO event
local ufoAttackEvent = ReplicatedStorage:WaitForChild("UFOAttack", 10)
if not ufoAttackEvent then
	warn("UFOClient: UFOAttack event not found")
	return
end

print("=== ENHANCED UFO CLIENT SYSTEM LOADED ===")

-- Client-side state
local clientState = {
	originalLighting = {
		Brightness = Lighting.Brightness,
		OutdoorAmbient = Lighting.OutdoorAmbient,
		Ambient = Lighting.Ambient,
		ColorShift_Top = Lighting.ColorShift_Top,
		ShadowSoftness = Lighting.ShadowSoftness,
	},
	currentTweens = {},
	ufoSounds = {},
	screenEffects = {},
}

-- ========== SOUND SYSTEM ==========

-- Create UFO sound effects
local function createUFOSounds()
	local sounds = {}

	-- UFO Humming sound
	sounds.hum = Instance.new("Sound")
	sounds.hum.SoundId = "rbxassetid://131961136" -- Sci-fi hum
	sounds.hum.Volume = 0.3
	sounds.hum.Looped = true
	sounds.hum.Parent = SoundService

	-- UFO Approach sound
	sounds.approach = Instance.new("Sound")
	sounds.approach.SoundId = "rbxassetid://9125980459" -- Warning siren
	sounds.approach.Volume = 0.4
	sounds.approach.Parent = SoundService

	-- Beam charging sound
	sounds.charge = Instance.new("Sound")
	sounds.charge.SoundId = "rbxassetid://9125980176" -- Energy charging
	sounds.charge.Volume = 0.5
	sounds.charge.Parent = SoundService

	-- Beam firing sound
	sounds.beam = Instance.new("Sound")
	sounds.beam.SoundId = "rbxassetid://162670113" -- Beam sound
	sounds.beam.Volume = 0.6
	sounds.beam.Parent = SoundService

	-- UFO Retreat sound
	sounds.retreat = Instance.new("Sound")
	sounds.retreat.SoundId = "rbxassetid://12221842" -- Retreat sound
	sounds.retreat.Volume = 0.4
	sounds.retreat.Parent = SoundService

	return sounds
end

-- Initialize sound system
clientState.ufoSounds = createUFOSounds()

-- ========== LIGHTING EFFECTS ==========

-- Store original lighting settings
local function storeOriginalLighting()
	clientState.originalLighting.Brightness = Lighting.Brightness
	clientState.originalLighting.OutdoorAmbient = Lighting.OutdoorAmbient
	clientState.originalLighting.Ambient = Lighting.Ambient
	clientState.originalLighting.ColorShift_Top = Lighting.ColorShift_Top
	clientState.originalLighting.ShadowSoftness = Lighting.ShadowSoftness
end

-- Apply UFO attack lighting
local function applyUFOLighting()
	print("UFOClient: Applying UFO attack lighting...")

	-- Cancel existing lighting tweens
	for _, tween in pairs(clientState.currentTweens) do
		if tween then tween:Cancel() end
	end
	clientState.currentTweens = {}

	-- Create dramatic lighting changes
	local lightingTweens = {
		-- Darken the environment
		TweenService:Create(Lighting, TweenInfo.new(3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Brightness = 0.2,
			OutdoorAmbient = Color3.fromRGB(0, 50, 20), -- Eerie green tint
			Ambient = Color3.fromRGB(20, 60, 20),
			ColorShift_Top = Color3.fromRGB(0, 100, 0), -- Green from above
			ShadowSoftness = 0.1
		})
	}

	-- Play all lighting tweens
	for _, tween in pairs(lightingTweens) do
		tween:Play()
		table.insert(clientState.currentTweens, tween)
	end
end

-- Restore normal lighting
local function restoreLighting()
	print("UFOClient: Restoring normal lighting...")

	-- Cancel existing lighting tweens
	for _, tween in pairs(clientState.currentTweens) do
		if tween then tween:Cancel() end
	end
	clientState.currentTweens = {}

	-- Restore original lighting
	local restoreTween = TweenService:Create(Lighting, 
		TweenInfo.new(4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), 
		clientState.originalLighting
	)

	restoreTween:Play()
	table.insert(clientState.currentTweens, restoreTween)
end

-- ========== SCREEN EFFECTS ==========

-- Create UFO warning screen overlay
local function createWarningOverlay()
	local playerGui = player:WaitForChild("PlayerGui")

	-- Remove existing overlay
	local existingOverlay = playerGui:FindFirstChild("UFOWarningOverlay")
	if existingOverlay then
		existingOverlay:Destroy()
	end

	-- Create new overlay
	local overlay = Instance.new("ScreenGui")
	overlay.Name = "UFOWarningOverlay"
	overlay.Parent = playerGui

	-- Warning frame
	local warningFrame = Instance.new("Frame")
	warningFrame.Name = "WarningFrame"
	warningFrame.Size = UDim2.new(1, 0, 1, 0)
	warningFrame.Position = UDim2.new(0, 0, 0, 0)
	warningFrame.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
	warningFrame.BackgroundTransparency = 0.8
	warningFrame.BorderSizePixel = 0
	warningFrame.Parent = overlay

	-- Warning text
	local warningText = Instance.new("TextLabel")
	warningText.Name = "WarningText"
	warningText.Size = UDim2.new(0.8, 0, 0.2, 0)
	warningText.Position = UDim2.new(0.1, 0, 0.4, 0)
	warningText.BackgroundTransparency = 1
	warningText.Text = "🛸 UFO ATTACK DETECTED 🛸\nSEEK IMMEDIATE SHELTER!"
	warningText.TextColor3 = Color3.fromRGB(255, 255, 255)
	warningText.TextScaled = true
	warningText.Font = Enum.Font.GothamBold
	warningText.TextStrokeTransparency = 0
	warningText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	warningText.Parent = warningFrame

	-- Animate warning flashing
	spawn(function()
		for i = 1, 10 do
			warningFrame.BackgroundTransparency = 0.3
			wait(0.2)
			warningFrame.BackgroundTransparency = 0.9
			wait(0.2)
		end

		-- Fade out warning
		local fadeOut = TweenService:Create(warningFrame,
			TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{BackgroundTransparency = 1}
		)

		local textFadeOut = TweenService:Create(warningText,
			TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{TextTransparency = 1}
		)

		fadeOut:Play()
		textFadeOut:Play()

		fadeOut.Completed:Connect(function()
			overlay:Destroy()
		end)
	end)

	return overlay
end

-- Create scanning effect overlay
local function createScanningOverlay()
	local playerGui = player:WaitForChild("PlayerGui")

	local overlay = Instance.new("ScreenGui")
	overlay.Name = "UFOScanningOverlay"
	overlay.Parent = playerGui

	-- Scanning lines
	for i = 1, 5 do
		local scanLine = Instance.new("Frame")
		scanLine.Name = "ScanLine" .. i
		scanLine.Size = UDim2.new(1, 0, 0, 2)
		scanLine.Position = UDim2.new(0, 0, i * 0.2, 0)
		scanLine.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
		scanLine.BackgroundTransparency = 0.3
		scanLine.BorderSizePixel = 0
		scanLine.Parent = overlay

		-- Animate scanning lines
		local moveTween = TweenService:Create(scanLine,
			TweenInfo.new(2, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, 3),
			{Position = UDim2.new(0, 0, 1.2, 0)}
		)

		local fadeTween = TweenService:Create(scanLine,
			TweenInfo.new(6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{BackgroundTransparency = 1}
		)

		moveTween:Play()
		fadeTween:Play()
	end

	-- Clean up overlay
	Debris:AddItem(overlay, 6)

	return overlay
end

-- Create beam impact screen shake
local function createScreenShake()
	if not player.Character or not player.Character:FindFirstChild("Humanoid") then
		return
	end

	local humanoid = player.Character.Humanoid
	local camera = workspace.CurrentCamera

	if not camera then return end

	-- Screen shake effect
	spawn(function()
		local originalCFrame = camera.CFrame

		for i = 1, 30 do
			local shakeIntensity = 2 * (1 - i/30) -- Decrease over time
			local shakeX = math.random(-shakeIntensity, shakeIntensity)
			local shakeY = math.random(-shakeIntensity, shakeIntensity)
			local shakeZ = math.random(-shakeIntensity, shakeIntensity)

			camera.CFrame = camera.CFrame * CFrame.new(shakeX, shakeY, shakeZ)

			wait(0.05)
		end

		-- Restore camera position gradually
		TweenService:Create(camera, TweenInfo.new(1), {CFrame = originalCFrame}):Play()
	end)
end

-- ========== PARTICLE EFFECTS ==========

-- Create atmospheric particles during UFO presence
local function createAtmosphericEffects()
	if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
		return
	end

	local playerPosition = player.Character.HumanoidRootPart.Position

	-- Create floating particles around player
	spawn(function()
		for i = 1, 20 do
			local particle = Instance.new("Part")
			particle.Name = "AtmosphericParticle"
			particle.Size = Vector3.new(0.2, 0.2, 0.2)
			particle.Material = Enum.Material.Neon
			particle.Color = Color3.fromRGB(0, 255, 100)
			particle.CanCollide = false
			particle.Anchored = true
			particle.Shape = Enum.PartType.Ball
			particle.Parent = workspace

			-- Random position around player
			local randomOffset = Vector3.new(
				math.random(-50, 50),
				math.random(5, 30),
				math.random(-50, 50)
			)
			particle.Position = playerPosition + randomOffset

			-- Animate particle floating
			local floatTween = TweenService:Create(particle,
				TweenInfo.new(math.random(8, 12), Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
				{
					Position = particle.Position + Vector3.new(
						math.random(-20, 20),
						math.random(-10, 10),
						math.random(-20, 20)
					),
					Transparency = 1
				}
			)

			floatTween:Play()
			Debris:AddItem(particle, 12)

			wait(0.3)
		end
	end)
end

-- ========== NOTIFICATION SYSTEM ==========

-- Enhanced notification system
local function showUFONotification(title, message, notificationType)
	local success, _ = pcall(function()
		-- Try CoreGui notification first
		game.StarterGui:SetCore("SendNotification", {
			Title = title,
			Text = message,
			Duration = 8,
			Button1 = "Understood"
		})
	end)

	if not success then
		print("UFOClient: " .. title .. " - " .. message)
	end

	-- Also try GameClient notification if available
	pcall(function()
		if _G.GameClient and _G.GameClient.ShowNotification then
			_G.GameClient:ShowNotification(title, message, notificationType or "info")
		end
	end)
end

-- Check player protection status
local function checkPlayerProtection()
	local hasProtection = false
	local protectionCount = 0

	pcall(function()
		if _G.GameClient and _G.GameClient.GetPlayerData then
			local playerData = _G.GameClient:GetPlayerData()
			if playerData and playerData.roofs then
				for _, roofInfo in pairs(playerData.roofs) do
					if roofInfo.installed then
						hasProtection = true
						protectionCount = protectionCount + 1
					end
				end
			end
		end
	end)

	return hasProtection, protectionCount
end

-- ========== UFO EVENT HANDLERS ==========

-- Handle UFO attack events
ufoAttackEvent.OnClientEvent:Connect(function(action, data1, data2)
	print("UFOClient: Received event:", action, data1, data2)

	-- Store original lighting on first event
	if not clientState.lightingStored then
		storeOriginalLighting()
		clientState.lightingStored = true
	end

	if action == "ATTACK_START" then
		local cropCount = data1 or 0
		print("UFOClient: UFO attack starting with " .. cropCount .. " crops detected")

		-- Play warning sound
		if clientState.ufoSounds.approach then
			clientState.ufoSounds.approach:Play()
		end

		-- Show warning overlay
		createWarningOverlay()

		-- Check protection status
		local hasProtection, protectionCount = checkPlayerProtection()

		local warningMessage = "UFO ATTACK DETECTED!\n" .. cropCount .. " crops in danger!"
		if hasProtection then
			warningMessage = warningMessage .. "\n🏠 " .. protectionCount .. " crops protected by roofs!"
		else
			warningMessage = warningMessage .. "\n⚠️ No roof protection! Your crops are vulnerable!"
		end

		showUFONotification("🛸 UFO ATTACK!", warningMessage, "warning")

	elseif action == "UFO_APPEAR" then
		local ufoPosition = data1
		print("UFOClient: UFO appearing at", tostring(ufoPosition))

		-- Apply dramatic lighting
		applyUFOLighting()

		-- Start UFO humming sound
		if clientState.ufoSounds.hum then
			clientState.ufoSounds.hum:Play()
		end

		-- Create atmospheric effects
		createAtmosphericEffects()

		showUFONotification("👁️ UFO DETECTED", "Unidentified Flying Object has appeared in the area!", "warning")

	elseif action == "UFO_SCAN" then
		print("UFOClient: UFO scanning area")

		-- Create scanning effects
		createScanningOverlay()

		-- Play charging sound
		if clientState.ufoSounds.charge then
			clientState.ufoSounds.charge:Play()
		end

		showUFONotification("🔍 SCANNING", "UFO is scanning the area for targets...", "info")

	elseif action == "UFO_ATTACK" then
		local attackPosition = data1
		print("UFOClient: UFO attacking at", tostring(attackPosition))

		-- Stop humming, start beam sound
		if clientState.ufoSounds.hum then
			clientState.ufoSounds.hum:Stop()
		end
		if clientState.ufoSounds.beam then
			clientState.ufoSounds.beam:Play()
		end

		-- Create screen shake
		createScreenShake()

		-- Make lighting more intense during beam
		pcall(function()
			TweenService:Create(Lighting, TweenInfo.new(1), {
				Brightness = 0.1,
				OutdoorAmbient = Color3.fromRGB(0, 100, 0),
				ColorShift_Top = Color3.fromRGB(0, 200, 0)
			}):Play()
		end)

		showUFONotification("⚡ BEAM FIRING!", "UFO is firing its destruction beam!", "error")

	elseif action == "UFO_RETREAT" then
		print("UFOClient: UFO retreating")

		-- Stop beam sound, play retreat sound
		if clientState.ufoSounds.beam then
			clientState.ufoSounds.beam:Stop()
		end
		if clientState.ufoSounds.retreat then
			clientState.ufoSounds.retreat:Play()
		end

		showUFONotification("🚁 UFO RETREATING", "The UFO is leaving the area...", "info")

	elseif action == "UFO_COMPLETE" then
		print("UFOClient: UFO attack sequence complete")

		-- Stop all UFO sounds
		for _, sound in pairs(clientState.ufoSounds) do
			if sound then
				sound:Stop()
			end
		end

		-- Restore normal lighting
		restoreLighting()

		showUFONotification("✅ ALL CLEAR", "UFO attack sequence complete. Area is now safe.", "success")

	elseif action == "START" then
		-- Legacy support for old UFO system
		local cropCount = data1 or 0
		print("UFOClient: Legacy UFO attack starting")

		applyUFOLighting()
		createWarningOverlay()

		if clientState.ufoSounds.approach then
			clientState.ufoSounds.approach:Play()
		end

	elseif action == "END" then
		-- Legacy support for old UFO system
		local destroyedCount = data1 or 0
		local protectedCount = data2 or 0

		print("UFOClient: Legacy UFO attack ended")

		restoreLighting()

		for _, sound in pairs(clientState.ufoSounds) do
			if sound then sound:Stop() end
		end

		-- Show results
		local resultMessage = ""
		if destroyedCount > 0 and protectedCount > 0 then
			resultMessage = "🔥 " .. destroyedCount .. " crops destroyed\n🏠 " .. protectedCount .. " crops protected!"
		elseif destroyedCount > 0 then
			resultMessage = "🔥 " .. destroyedCount .. " crops destroyed!\n💡 Consider buying roof protection!"
		elseif protectedCount > 0 then
			resultMessage = "🏠 All " .. protectedCount .. " crops protected!\n✨ Your roof investment paid off!"
		else
			resultMessage = "No crops were in the attack zone"
		end

		showUFONotification("🛸 ATTACK COMPLETE", resultMessage, destroyedCount > 0 and "warning" or "success")
	end
end)

-- ========== CLEANUP ==========

-- Clean up when player leaves
game.Players.PlayerRemoving:Connect(function(leavingPlayer)
	if leavingPlayer == player then
		-- Stop all sounds
		for _, sound in pairs(clientState.ufoSounds) do
			if sound then
				sound:Stop()
				sound:Destroy()
			end
		end

		-- Cancel all tweens
		for _, tween in pairs(clientState.currentTweens) do
			if tween then
				tween:Cancel()
			end
		end

		-- Remove screen effects
		local playerGui = player:FindFirstChild("PlayerGui")
		if playerGui then
			local overlay = playerGui:FindFirstChild("UFOWarningOverlay")
			if overlay then overlay:Destroy() end

			local scanOverlay = playerGui:FindFirstChild("UFOScanningOverlay")
			if scanOverlay then scanOverlay:Destroy() end
		end
	end
end)

print("=== UFO CLIENT SYSTEM READY ===")
print("Features:")
print("✅ Dramatic lighting effects during UFO attacks")
print("✅ Warning overlays and scanning effects")
print("✅ Screen shake during beam impact")
print("✅ Atmospheric particle effects")
print("✅ UFO sound effects (humming, charging, beam)")
print("✅ Enhanced notifications with protection status")
print("✅ Full integration with new UFO animation system")
print("✅ Legacy support for existing UFO events")