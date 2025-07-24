--[[  
    Fixed EffectManager.server.lua
    Place in: ServerScriptService/EffectManager.server.lua
    
    FIXES:
    ✅ Removed problematic code causing nil argument errors
    ✅ Simplified effect management system  
    ✅ Better error handling
    ✅ Cleaner, more maintainable code structure
]]  

local EffectManager = {}

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- Configuration
local EFFECT_CONFIG = {
	MAX_EFFECTS = 50,
	DEFAULT_LIFETIME = 3,
	CLEANUP_INTERVAL = 10
}

-- State
EffectManager.ActiveEffects = {}
EffectManager.EffectCount = 0

-- ========== INITIALIZATION ==========

function EffectManager:Initialize()
	print("EffectManager: Initializing FIXED effect manager...")

	-- Setup periodic cleanup
	self:SetupCleanup()

	print("EffectManager: ✅ FIXED effect manager initialized")
	return true
end

-- ========== EFFECT CREATION ==========

function EffectManager:CreateParticleEffect(position, config)
	-- Validate inputs
	if not position or typeof(position) ~= "Vector3" then
		warn("EffectManager: Invalid position provided")
		return nil
	end

	config = config or {}

	-- Limit number of active effects
	if self.EffectCount >= EFFECT_CONFIG.MAX_EFFECTS then
		self:CleanupOldEffects()
	end

	-- Create effect part
	local effect = Instance.new("Part")
	effect.Name = "ParticleEffect"
	effect.Size = Vector3.new(config.size or 1, config.size or 1, config.size or 1)
	effect.Material = config.material or Enum.Material.Neon
	effect.BrickColor = config.color or BrickColor.new("Bright yellow")
	effect.Anchored = true
	effect.CanCollide = false
	effect.Transparency = config.transparency or 0.3
	effect.Position = position
	effect.Parent = workspace

	-- Add to tracking
	local effectData = {
		part = effect,
		createdTime = tick(),
		lifetime = config.lifetime or EFFECT_CONFIG.DEFAULT_LIFETIME
	}

	table.insert(self.ActiveEffects, effectData)
	self.EffectCount = self.EffectCount + 1

	-- Auto-cleanup after lifetime
	spawn(function()
		wait(effectData.lifetime)
		self:RemoveEffect(effectData)
	end)

	return effect
end

function EffectManager:CreateHarvestEffect(position)
	-- Create multiple particle effects for wheat harvesting
	for i = 1, 3 do
		local offsetPos = position + Vector3.new(
			math.random(-2, 2),
			math.random(0, 2),
			math.random(-2, 2)
		)

		local effect = self:CreateParticleEffect(offsetPos, {
			size = 0.5,
			color = BrickColor.new("Bright yellow"),
			material = Enum.Material.Neon,
			lifetime = 2
		})

		if effect then
			-- Add movement
			local tween = TweenService:Create(effect,
				TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{
					Position = offsetPos + Vector3.new(0, 5, 0),
					Transparency = 1,
					Size = Vector3.new(0.1, 0.1, 0.1)
				}
			)
			tween:Play()
		end
	end
end

-- ========== CLEANUP SYSTEM ==========

function EffectManager:SetupCleanup()
	spawn(function()
		while true do
			wait(EFFECT_CONFIG.CLEANUP_INTERVAL)
			self:CleanupOldEffects()
		end
	end)
end

function EffectManager:CleanupOldEffects()
	local currentTime = tick()
	local cleanedCount = 0

	for i = #self.ActiveEffects, 1, -1 do
		local effectData = self.ActiveEffects[i]

		if not effectData.part or not effectData.part.Parent then
			-- Effect was destroyed externally
			table.remove(self.ActiveEffects, i)
			self.EffectCount = self.EffectCount - 1
			cleanedCount = cleanedCount + 1
		elseif (currentTime - effectData.createdTime) > effectData.lifetime then
			-- Effect has exceeded its lifetime
			self:RemoveEffect(effectData)
			cleanedCount = cleanedCount + 1
		end
	end

	if cleanedCount > 0 then
		print("EffectManager: Cleaned up " .. cleanedCount .. " old effects")
	end
end

function EffectManager:RemoveEffect(effectData)
	if effectData.part and effectData.part.Parent then
		effectData.part:Destroy()
	end

	-- Remove from tracking
	for i, effect in ipairs(self.ActiveEffects) do
		if effect == effectData then
			table.remove(self.ActiveEffects, i)
			self.EffectCount = self.EffectCount - 1
			break
		end
	end
end

-- ========== UTILITY FUNCTIONS ==========

function EffectManager:GetEffectCount()
	return self.EffectCount
end

function EffectManager:ClearAllEffects()
	print("EffectManager: Clearing all effects...")

	for _, effectData in ipairs(self.ActiveEffects) do
		if effectData.part and effectData.part.Parent then
			effectData.part:Destroy()
		end
	end

	self.ActiveEffects = {}
	self.EffectCount = 0

	print("EffectManager: All effects cleared")
end

-- ========== DEBUG FUNCTIONS ==========

function EffectManager:DebugStatus()
	print("=== EFFECT MANAGER DEBUG STATUS ===")
	print("Active effects: " .. self.EffectCount)
	print("Max effects: " .. EFFECT_CONFIG.MAX_EFFECTS)
	print("Effects in tracking table: " .. #self.ActiveEffects)
	print("")

	if #self.ActiveEffects > 0 then
		print("Effect details:")
		for i, effectData in ipairs(self.ActiveEffects) do
			local age = tick() - effectData.createdTime
			local remaining = effectData.lifetime - age
			print("  " .. i .. ": Age=" .. math.floor(age*10)/10 .. "s, Remaining=" .. math.floor(remaining*10)/10 .. "s")
		end
	end
	print("===================================")
end

-- ========== GLOBAL FUNCTIONS ==========

-- Initialize the effect manager
EffectManager:Initialize()

-- Make globally available
_G.EffectManager = EffectManager

-- Global convenience functions
_G.CreateHarvestEffect = function(position)
	return EffectManager:CreateHarvestEffect(position)
end

_G.CreateParticleEffect = function(position, config)
	return EffectManager:CreateParticleEffect(position, config)
end

print("EffectManager: ✅ FIXED version loaded and ready")

return EffectManager