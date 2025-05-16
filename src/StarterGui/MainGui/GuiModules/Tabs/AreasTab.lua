-- AreasTab.lua (ModuleScript)
-- Place in StarterGui/MainGui/GuiModules/Tabs/

local AreasTab = {}

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local UnlockArea = RemoteEvents:WaitForChild("UnlockArea")

-- Initialize variables
local player = Players.LocalPlayer
local playerData = nil
local areasFrame = nil

-- Area definitions
local areaDefinitions = {
	{
		name = "Starter Meadow",
		unlockCost = 0,
		petSpawnRate = 15,
		info = "The beginning area with basic pets.",
		pets = {"Common Corgi"}
	},
	{
		name = "Mystic Forest",
		unlockCost = 1000,
		petSpawnRate = 12,
		info = "A magical forest with rare pets.",
		pets = {"Common Corgi", "Rare RedPanda"}
	},
	{
		name = "Dragon's Lair",
		unlockCost = 10000,
		petSpawnRate = 10,
		info = "Home to legendary pets.",
		pets = {"Rare RedPanda", "Epic Corgi", "Legendary RedPanda"}
	}
}

-- Initialize the tab
function AreasTab.Init(frame, data)
	areasFrame = frame
	playerData = data

	-- Create the tab content if it doesn't exist
	if not areasFrame:FindFirstChild("AreaTemplate") then
		AreasTab.CreateTemplate()
	end

	return AreasTab
end

-- Create the area item template
function AreasTab.CreateTemplate()
	local areaTemplate = Instance.new("Frame")
	areaTemplate.Name = "AreaTemplate"
	areaTemplate.Size = UDim2.new(0, 300, 0, 120)
	areaTemplate.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
	areaTemplate.BorderColor3 = Color3.fromRGB(200, 200, 200)
	areaTemplate.BorderSizePixel = 2
	areaTemplate.Visible = false
	areaTemplate.Parent = areasFrame

	-- Add rounded corners
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = areaTemplate

	-- Create area name label
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLabel"
	nameLabel.Size = UDim2.new(1, -10, 0, 30)
	nameLabel.Position = UDim2.new(0, 5, 0, 5)
	nameLabel.Text = "Area Name"
	nameLabel.TextSize = 18
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextColor3 = Color3.fromRGB(50, 50, 50)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Parent = areaTemplate

	-- Create info label
	local infoLabel = Instance.new("TextLabel")
	infoLabel.Name = "InfoLabel"
	infoLabel.Size = UDim2.new(1, -10, 0, 40)
	infoLabel.Position = UDim2.new(0, 5, 0, 35)
	infoLabel.Text = "Area info goes here"
	infoLabel.TextSize = 14
	infoLabel.Font = Enum.Font.Gotham
	infoLabel.TextColor3 = Color3.fromRGB(100, 100, 100)
	infoLabel.TextXAlignment = Enum.TextXAlignment.Left
	infoLabel.TextWrapped = true
	infoLabel.BackgroundTransparency = 1
	infoLabel.Parent = areaTemplate

	-- Create unlock/teleport button
	local actionButton = Instance.new("TextButton")
	actionButton.Name = "ActionButton"
	actionButton.Size = UDim2.new(0.8, 0, 0, 35)
	actionButton.Position = UDim2.new(0.5, 0, 0, 75)
	actionButton.AnchorPoint = Vector2.new(0.5, 0)
	actionButton.Text = "Unlock: 1000 Coins"
	actionButton.TextSize = 16
	actionButton.Font = Enum.Font.GothamBold
	actionButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	actionButton.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
	actionButton.BorderSizePixel = 0
	actionButton.Parent = areaTemplate

	-- Add rounded corners to button
	local buttonCorner = Instance.new("UICorner")
	buttonCorner.CornerRadius = UDim.new(0, 6)
	buttonCorner.Parent = actionButton
end

-- Update the tab content with current data
function AreasTab.Update(data)
	playerData = data or playerData

	if not areasFrame then return end
	print("Updating areas display")

	-- Clear existing area displays
	for _, child in pairs(areasFrame:GetChildren()) do
		if child:IsA("Frame") and child.Name ~= "AreaTemplate" then
			child:Destroy()
		end
	end

	local areaTemplate = areasFrame:FindFirstChild("AreaTemplate")
	if not areaTemplate then
		AreasTab.CreateTemplate()
		areaTemplate = areasFrame:FindFirstChild("AreaTemplate")
	end

	-- Create area display for each area
	for i, area in ipairs(areaDefinitions) do
		local areaFrame = areaTemplate:Clone()
		areaFrame.Name = area.name
		areaFrame.Visible = true

		-- Update texts
		areaFrame.NameLabel.Text = area.name

		-- Convert pets table to string
		local petsString = ""
		for j, pet in ipairs(area.pets) do
			petsString = petsString .. pet
			if j < #area.pets then
				petsString = petsString .. ", "
			end
		end

		areaFrame.InfoLabel.Text = area.info .. "\nPets: " .. petsString

		-- Check if area is unlocked
		local isUnlocked = false
		if playerData and playerData.unlockedAreas then
			for _, unlockedArea in ipairs(playerData.unlockedAreas) do
				if unlockedArea == area.name then
					isUnlocked = true
					break
				end
			end
		end

		-- Set button text and color based on unlock status
		local actionButton = areaFrame.ActionButton
		if isUnlocked then
			actionButton.Text = "Teleport"
			actionButton.BackgroundColor3 = Color3.fromRGB(0, 100, 200)  -- Blue for teleport
		else
			if area.unlockCost == 0 then
				actionButton.Text = "Go to Area"
				actionButton.BackgroundColor3 = Color3.fromRGB(0, 100, 200)  -- Blue for free area
			else
				actionButton.Text = "Unlock: " .. area.unlockCost .. " Coins"

				-- Check if player can afford it
				if playerData and playerData.coins >= area.unlockCost then
					actionButton.BackgroundColor3 = Color3.fromRGB(0, 150, 0)  -- Green if affordable
				else
					actionButton.BackgroundColor3 = Color3.fromRGB(150, 0, 0)  -- Red if not affordable
				end
			end
		end

		-- Position the frame
		areaFrame.Position = UDim2.new(0, 10, 0, (i-1) * 130 + 10)

		-- Connect button
		actionButton.MouseButton1Click:Connect(function()
			if isUnlocked then
				-- Teleport logic
				print("Teleporting to " .. area.name)

				-- Find area in workspace
				local areaModel = workspace:FindFirstChild("Areas"):FindFirstChild(area.name)
				if areaModel then
					-- Find spawn location
					local spawnLocation = areaModel:FindFirstChild("SpawnLocation")

					if spawnLocation and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
						-- Teleport character
						player.Character.HumanoidRootPart.CFrame = spawnLocation.CFrame + Vector3.new(0, 5, 0)
					else
						print("Could not find spawn location or character")
					end
				else
					print("Could not find area model in workspace")
				end
			else
				-- Unlock logic
				if area.unlockCost == 0 or (playerData and playerData.coins >= area.unlockCost) then
					-- Fire UnlockArea event to server
					if UnlockArea then
						UnlockArea:FireServer(area.name)
					end
				else
					-- Show "not enough coins" message
					local message = actionButton:FindFirstChild("Message")
					if not message then
						message = Instance.new("TextLabel")
						message.Name = "Message"
						message.Size = UDim2.new(1, 0, 0, 20)
						message.Position = UDim2.new(0, 0, 1, 5)
						message.Text = "Not enough coins!"
						message.TextSize = 12
						message.Font = Enum.Font.GothamBold
						message.TextColor3 = Color3.fromRGB(255, 50, 50)
						message.BackgroundTransparency = 1
						message.Parent = actionButton

						-- Remove message after 2 seconds
						spawn(function()
							wait(2)
							if message and message.Parent then
								message:Destroy()
							end
						end)
					end
				end
			end
		end)

		areaFrame.Parent = areasFrame
	end
end

return AreasTab