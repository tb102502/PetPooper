--[[
    PetSystemClient.lua
    Client-side interface for the PetSystem
    Created: 2025-05-24
]]

local PetSystemClient = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

-- Cache for data received from server
PetSystemClient.Cache = {
	LocalPlayerPets = {
		equippedPets = {},
		ownedPets = {}
	},
	PetDefinitions = {}
}

-- Remote event references
PetSystemClient.Remotes = {
	Events = {},
	Functions = {}
}

-- Initialize client-side pet system
function PetSystemClient:Initialize()
	print("PetSystemClient: Starting initialization...")

	-- Wait for the remote folder
	local startTime = tick()
	local remoteFolder

	while tick() - startTime < 10 do
		remoteFolder = ReplicatedStorage:FindFirstChild("PetSystem")
		if remoteFolder then break end
		wait(0.5)
	end

	if not remoteFolder then
		warn("PetSystemClient: Could not find PetSystem folder in ReplicatedStorage")
		return false
	end

	print("PetSystemClient: Found remote folder")

	-- Store remote event and function references
	for _, instance in ipairs(remoteFolder:GetChildren()) do
		if instance:IsA("RemoteEvent") then
			self.Remotes.Events[instance.Name] = instance
			print("PetSystemClient: Found RemoteEvent: " .. instance.Name)
		elseif instance:IsA("RemoteFunction") then
			self.Remotes.Functions[instance.Name] = instance
			print("PetSystemClient: Found RemoteFunction: " .. instance.Name)
		end
	end

	-- Set up client-side event handlers
	self:SetupEventHandlers()

	-- Create bindable events
	self:CreateBindableEvents()

	-- Request initial pet data after a short delay to ensure server is ready
	spawn(function()
		wait(2)
		self:RequestPetData()
	end)

	print("PetSystemClient: Initialized successfully")
	return true
end

-- Create bindable events for UI components to connect to
function PetSystemClient:CreateBindableEvents()
	-- Clean up any existing events
	for _, event in pairs(self._events or {}) do
		if event and typeof(event) == "Instance" then
			pcall(function() event:Destroy() end)
		end
	end

	-- Create new events
	local events = {
		"OnPetsUpdated",
		"OnPetEquipped",
		"OnPetUnequipped",
		"OnPetLevelUp"
	}

	self._events = {}

	for _, eventName in ipairs(events) do
		local event = Instance.new("BindableEvent")
		self._events[eventName] = event
		self[eventName] = event.Event
	end
end

-- Set up client-side event handlers
function PetSystemClient:SetupEventHandlers()
	local events = self.Remotes.Events

	if events.PetsUpdated then
		events.PetsUpdated.OnClientEvent:Connect(function(petData)
			self:HandlePetsUpdated(petData)
		end)
	end

	if events.PetEquipped then
		events.PetEquipped.OnClientEvent:Connect(function(petId, petData)
			self:HandlePetEquipped(petId, petData)
		end)
	end

	if events.PetUnequipped then
		events.PetUnequipped.OnClientEvent:Connect(function(petId)
			self:HandlePetUnequipped(petId)
		end)
	end

	if events.PetLevelUp then
		events.PetLevelUp.OnClientEvent:Connect(function(petId, level, stats)
			self:HandlePetLevelUp(petId, level, stats)
		end)
	end
end

-- Handle pets updated event
function PetSystemClient:HandlePetsUpdated(petData)
	-- Update local cache
	self.Cache.LocalPlayerPets = petData

	-- Fire local event for UI to update
	if self._events and self._events.OnPetsUpdated then
		self._events.OnPetsUpdated:Fire(petData)
	end
end

-- Handle pet equipped event
function PetSystemClient:HandlePetEquipped(petId, petData)
	-- Update local UI or effects
	if self._events and self._events.OnPetEquipped then
		self._events.OnPetEquipped:Fire(petId, petData)
	end
end

-- Handle pet unequipped event
function PetSystemClient:HandlePetUnequipped(petId)
	-- Update local UI or effects
	if self._events and self._events.OnPetUnequipped then
		self._events.OnPetUnequipped:Fire(petId)
	end
end

-- Handle pet level up event
function PetSystemClient:HandlePetLevelUp(petId, level, stats)
	-- Show level up effects
	if self._events and self._events.OnPetLevelUp then
		self._events.OnPetLevelUp:Fire(petId, level, stats)
	end
end

-- Request pet data from server
function PetSystemClient:RequestPetData()
	print("PetSystemClient: Requesting pet data from server...")
	local functions = self.Remotes.Functions

	if functions.GetEquippedPets and functions.GetOwnedPets then
		local success1, equippedPets = pcall(function()
			return functions.GetEquippedPets:InvokeServer()
		end)

		local success2, ownedPets = pcall(function()
			return functions.GetOwnedPets:InvokeServer()
		end)

		if success1 and success2 then
			self.Cache.LocalPlayerPets = {
				equippedPets = equippedPets or {},
				ownedPets = ownedPets or {}
			}

			if self._events and self._events.OnPetsUpdated then
				self._events.OnPetsUpdated:Fire(self.Cache.LocalPlayerPets)
			end

			print("PetSystemClient: Successfully received pet data")
		else
			warn("PetSystemClient: Failed to request pet data from server")
		end
	else
		warn("PetSystemClient: Required RemoteFunctions not found")
	end
end

-- Get pet data for a specific pet
function PetSystemClient:GetPetData(petId)
	local functions = self.Remotes.Functions

	if functions.GetPetData then
		local success, data = pcall(function()
			return functions.GetPetData:InvokeServer(petId)
		end)

		if success then
			return data
		end
	end

	return nil
end

-- Equip a pet
function PetSystemClient:EquipPet(petId)
	local equipPetEvent = self.Remotes.Events.EquipPet

	if equipPetEvent then
		equipPetEvent:FireServer(petId)
		return true
	end

	return false
end

-- Unequip a pet
function PetSystemClient:UnequipPet(petId)
	local unequipPetEvent = self.Remotes.Events.UnequipPet

	if unequipPetEvent then
		unequipPetEvent:FireServer(petId)
		return true
	end

	return false
end

-- Get all equipped pets
function PetSystemClient:GetEquippedPets()
	return self.Cache.LocalPlayerPets.equippedPets or {}
end

-- Get all owned pets
function PetSystemClient:GetOwnedPets()
	return self.Cache.LocalPlayerPets.ownedPets or {}
end

return PetSystemClient