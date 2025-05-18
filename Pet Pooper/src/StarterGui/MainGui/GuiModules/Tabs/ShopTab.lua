-- ShopTab.lua (ModuleScript)
-- Place in StarterGui/MainGui/GuiModules/Tabs/ShopTab.lua

local ShopTab = {}

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

-- References
local player = Players.LocalPlayer
local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")

-- Tab frame reference
local shopFrame = nil

-- Initialize the tab
function ShopTab.Initialize(frame, playerData)
	print("Initializing Shop Tab...")

	-- Store references
	shopFrame = frame

	-- Create or get info panel
	local infoPanel = shopFrame:FindFirstChild("InfoPanel")
	if not infoPanel then
		infoPanel = Instance.new("Frame")
		infoPanel.Name = "InfoPanel"
		infoPanel.Size = UDim2.new(1, -20, 0, 120)
		infoPanel.Position = UDim2.new(0, 10, 0, 10)
		infoPanel.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
		infoPanel.BorderColor3 = Color3.fromRGB(200, 200, 200)
		infoPanel.BorderSizePixel = 2
		infoPanel.Parent = shopFrame

		-- Add rounded corners
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 8)
		corner.Parent = infoPanel

		-- Create title label
		local titleLabel = Instance.new("TextLabel")
		titleLabel.Name = "TitleLabel"
		titleLabel.Size = UDim2.new(1, -10, 0, 30)
		titleLabel.Position = UDim2.new(0, 5, 0, 5)
		titleLabel.Text = "Pet Shop"
		titleLabel.TextSize = 24
		titleLabel.Font = Enum.Font.GothamBold
		titleLabel.TextColor3 = Color3.fromRGB(50, 50, 50)
		titleLabel.BackgroundTransparency = 1
		titleLabel.Parent = infoPanel

		-- Create description label
		local descLabel = Instance.new("TextLabel")
		descLabel.Name = "DescLabel"
		descLabel.Size = UDim2.new(1, -10, 0, 40)
		descLabel.Position = UDim2.new(0, 5, 0, 40)
		descLabel.Text = "Sell your pets for coins! Rarer pets are worth more coins."
		descLabel.TextSize = 16
		descLabel.Font = Enum.Font.Gotham
		descLabel.TextColor3 = Color3.fromRGB(100, 100, 100)
		descLabel.TextWrapped = true
		descLabel.BackgroundTransparency = 1
		descLabel.Parent = infoPanel

		-- Create select instructions
		local selectLabel = Instance.new("TextLabel")
		selectLabel.Name = "SelectLabel"
		selectLabel.Size = UDim2.new(1, -10, 0, 30)
		selectLabel.Position = UDim2.new(0, 5, 0, 80)
		selectLabel.Text = "Select pets below to sell them."
		selectLabel.TextSize = 14
		selectLabel.Font = Enum.Font.GothamBold
		selectLabel.TextColor3 = Color3.fromRGB(0, 100, 0)
		selectLabel.BackgroundTransparency = 1
		selectLabel.Parent = infoPanel

		-- Create sell all button
		local sellAllButton = Instance.new("TextButton")
		sellAllButton.Name = "SellAllButton"
		sellAllButton.Size = UDim2.new(0, 150, 0, 40)
		sellAllButton.Position = UDim2.new(1, -160, 0, 70)
		sellAllButton.Text = "Sell All Pets"
		sellAllButton.TextSize = 16
		sellAllButton.Font = Enum.Font.GothamBold
		sellAllButton.TextColor3 = Color3.fromRGB(255, 255, 255)
		sellAllButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
		sellAllButton.BorderSizePixel = 0
		sellAllButton.Parent = infoPanel

		-- Add rounded corners
		local buttonCorner = Instance.new("UICorner")
		buttonCorner.CornerRadius = UDim.new(0, 6)
		buttonCorner.Parent = sellAllButton

		-- Connect sell all button
		sellAllButton.MouseButton1Click:Connect(function()
			ShopTab.ConfirmSellAllPets()
		end)
	end

	-- Create or get pet list frame
	local petListFrame = shopFrame:FindFirstChild("PetListFrame")
	if not petListFrame then
		petListFrame = Instance.new("ScrollingFrame")
		petListFrame.Name = "PetListFrame"
		petListFrame.Size = UDim2.new(1, -20, 1, -140)
		petListFrame.Position = UDim2.new(0, 10, 0, 140)
		petListFrame.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
		petListFrame.BorderColor3 = Color3.fromRGB(200, 200, 200)
		petListFrame.BorderSizePixel = 2
		petListFrame.ScrollBarThickness = 6
		petListFrame.ScrollingDirection = Enum.ScrollingDirection.Y
		petListFrame.CanvasSize = UDim2.new(0, 0, 0, 0)  -- Will be adjusted based on content
		petListFrame.Parent = shopFrame
	end

	print("Shop Tab initialization complete!")

	-- Initial update
	ShopTab.Update(playerData)
end

-- Confirm selling all pets with dialog
function ShopTab.ConfirmSellAllPets()
	local parent = player:WaitForChild("PlayerGui"):WaitForChild("MainGui")

	-- Create confirmation dialog
	local confirmFrame = Instance.new("Frame")
	confirmFrame.Name = "ConfirmFrame"
	confirmFrame.Size = UDim2.new(0, 300, 0, 150)
	confirmFrame.Position = UDim2.new(0.5, -150, 0.5, -75)
	confirmFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	confirmFrame.BorderSizePixel = 0
	confirmFrame.ZIndex = 10

	-- Add rounded corners
	local confirmCorner = Instance.new("UICorner")
	confirmCorner.CornerRadius = UDim.new(0, 8)
	confirmCorner.Parent = confirmFrame

	-- Add title
	local confirmTitle = Instance.new("TextLabel")
	confirmTitle.Name = "ConfirmTitle"
	confirmTitle.Size = UDim2.new(1, -20, 0, 40)
	confirmTitle.Position = UDim2.new(0, 10, 0, 10)
	confirmTitle.Text = "Confirm Sell All Pets"
	confirmTitle.TextSize = 20
	confirmTitle.Font = Enum.Font.GothamBold
	confirmTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
	confirmTitle.BackgroundTransparency = 1
	confirmTitle.ZIndex = 11
	confirmTitle.Parent = confirmFrame

	-- Add message
	local confirmMessage = Instance.new("TextLabel")
	confirmMessage.Name = "ConfirmMessage"
	confirmMessage.Size = UDim2.new(1, -20, 0, 40)
	confirmMessage.Position = UDim2.new(0, 10, 0, 50)
	confirmMessage.Text = "Are you sure you want to sell ALL your pets? This cannot be undone!"
	confirmMessage.TextSize = 14
	confirmMessage.Font = Enum.Font.Gotham
	confirmMessage.TextColor3 = Color3.fromRGB(255, 255, 255)
	confirmMessage.TextWrapped = true
	confirmMessage.BackgroundTransparency = 1
	confirmMessage.ZIndex = 11
	confirmMessage.Parent = confirmFrame

	-- Add confirm button
	local confirmButton = Instance.new("TextButton")
	confirmButton.Name = "ConfirmButton"
	confirmButton.Size = UDim2.new(0.4, 0, 0, 40)
	confirmButton.Position = UDim2.new(0.1, 0, 0, 100)
	confirmButton.Text = "Sell All"
	confirmButton.TextSize = 16
	confirmButton.Font = Enum.Font.GothamBold
	confirmButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	confirmButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
	confirmButton.BorderSizePixel = 0
	confirmButton.ZIndex = 11

	-- Add rounded corners to button
	local confirmButtonCorner = Instance.new("UICorner")
	confirmButtonCorner.CornerRadius = UDim.new(0, 6)
	confirmButtonCorner.Parent = confirmButton

	-- Connect confirm button
	confirmButton.MouseButton1Click:Connect(function()
		-- Fire SellAllPets event to server
		local SellAllPets = remoteEvents:FindFirstChild("SellAllPets")
		if SellAllPets then
			SellAllPets:FireServer()
		end

		-- Remove confirm dialog
		confirmFrame:Destroy()
	end)

	confirmButton.Parent = confirmFrame

	-- Add cancel button
	local cancelButton = Instance.new("TextButton")
	cancelButton.Name = "CancelButton"
	cancelButton.Size = UDim2.new(0.4, 0, 0, 40)
	cancelButton.Position = UDim2.new(0.5, 0, 0, 100)
	cancelButton.Text = "Cancel"
	cancelButton.TextSize = 16
	cancelButton.Font = Enum.Font.GothamBold
	cancelButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	cancelButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
	cancelButton.BorderSizePixel = 0
	cancelButton.ZIndex = 11

	-- Add rounded corners to button
	local cancelButtonCorner = Instance.new("UICorner")
	cancelButtonCorner.CornerRadius = UDim.new(0, 6)
	cancelButtonCorner.Parent = cancelButton

	-- Connect cancel button
	cancelButton.MouseButton1Click:Connect(function()
		-- Remove confirm dialog
		confirmFrame:Destroy()
	end)

	cancelButton.Parent = confirmFrame

	-- Add to parent
	confirmFrame.Parent = parent
end

-- Update shop display
function ShopTab.Update(playerData)
	if not shopFrame then return end
	print("Updating shop display")

	-- Get pet list frame
	local petListFrame = shopFrame:FindFirstChild("PetListFrame")
	if not petListFrame then return end

	-- Clear existing pet displays
	for _, child in pairs(petListFrame:GetChildren()) do
		if child:IsA("Frame") or child:IsA("TextLabel") then
			child:Destroy()
		end
	end

	-- Get player's pets
	if not playerData or not playerData.pets or #playerData.pets == 0 then
		local emptyLabel = Instance.new("TextLabel")
		emptyLabel.Size = UDim2.new(1, -20, 0, 40)
		emptyLabel.Position = UDim2.new(0, 10, 0, 10)
		emptyLabel.Text = "No pets to sell. Collect some pets first!"
		emptyLabel.TextSize = 16
		emptyLabel.Font = Enum.Font.GothamBold
		emptyLabel.TextColor3 = Color3.fromRGB(100, 100, 100)
		emptyLabel.BackgroundTransparency = 1
		emptyLabel.Parent = petListFrame
		return
	end

	-- Create pet item template
	local petItemTemplate = Instance.new("Frame")
	petItemTemplate.Name = "PetItemTemplate"
	petItemTemplate.Size = UDim2.new(1, -20, 0, 80)
	petItemTemplate.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	petItemTemplate.BorderColor3 = Color3.fromRGB(200, 200, 200)
	petItemTemplate.BorderSizePixel = 1

	-- Add rounded corners
	local itemCorner = Instance.new("UICorner")
	itemCorner.CornerRadius = UDim.new(0, 6)
	itemCorner.Parent = petItemTemplate

	-- Create pet name label
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLabel"
	nameLabel.Size = UDim2.new(0.6, -10, 0, 30)
	nameLabel.Position = UDim2.new(0, 10, 0, 5)
	nameLabel.Text = "Pet Name"
	nameLabel.TextSize = 18
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextColor3 = Color3.fromRGB(50, 50, 50)
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.BackgroundTransparency = 1
	nameLabel.Parent = petItemTemplate

	-- Create rarity label
	local rarityLabel = Instance.new("TextLabel")
	rarityLabel.Name = "RarityLabel"
	rarityLabel.Size = UDim2.new(0.6, -10, 0, 20)
	rarityLabel.Position = UDim2.new(0, 10, 0, 35)
	rarityLabel.Text = "Rarity"
	rarityLabel.TextSize = 14
	rarityLabel.Font = Enum.Font.Gotham
	rarityLabel.TextColor3 = Color3.fromRGB(100, 100, 100)
	rarityLabel.TextXAlignment = Enum.TextXAlignment.Left
	rarityLabel.BackgroundTransparency = 1
	rarityLabel.Parent = petItemTemplate

	-- Create value label
	local valueLabel = Instance.new("TextLabel")
	valueLabel.Name = "ValueLabel"
	valueLabel.Size = UDim2.new(0.4, -10, 0, 30)
	valueLabel.Position = UDim2.new(0, 10, 0, 55)
	valueLabel.Text = "Value: 10 Coins"
	valueLabel.TextSize = 14
	valueLabel.Font = Enum.Font.GothamBold
	valueLabel.TextColor3 = Color3.fromRGB(0, 100, 0)
	valueLabel.TextXAlignment = Enum.TextXAlignment.Left
	valueLabel.BackgroundTransparency = 1
	valueLabel.Parent = petItemTemplate

	-- Create sell button
	local sellButton = Instance.new("TextButton")
	sellButton.Name = "SellButton"
	sellButton.Size = UDim2.new(0.3, 0, 0, 30)
	sellButton.Position = UDim2.new(0.68, 0, 0, 25)
	sellButton.Text = "Sell"
	sellButton.TextSize = 16
	sellButton.Font = Enum.Font.GothamBold
	sellButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	sellButton.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
	sellButton.BorderSizePixel = 0
	sellButton.Parent = petItemTemplate

	-- Add rounded corners to button
	local buttonCorner = Instance.new("UICorner")
	buttonCorner.CornerRadius = UDim.new(0, 6)
	buttonCorner.Parent = sellButton

	-- Group pets by type for easier display
	local petGroups = {}

	for _, pet in ipairs(playerData.pets) do
		local key = pet.name .. "_" .. pet.rarity

		if not petGroups[key] then
			petGroups[key] = {
				name = pet.name,
				rarity = pet.rarity,
				ids = {pet.id},
				count = 1,
				modelName = pet.modelName
			}
		else
			table.insert(petGroups[key].ids, pet.id)
			petGroups[key].count = petGroups[key].count + 1
		end
	end

	-- Convert to array for sorting
	local groupedPets = {}
	for _, group in pairs(petGroups) do
		table.insert(groupedPets, group)
	end

	-- Sort by rarity
	table.sort(groupedPets, function(a, b)
		local rarityOrder = {
			["Legendary"] = 1,
			["Epic"] = 2,
			["Rare"] = 3,
			["Common"] = 4
		}

		return (rarityOrder[a.rarity] or 99) < (rarityOrder[b.rarity] or 99)
	end)

	-- Display pet groups
	for i, petGroup in ipairs(groupedPets) do
		local petItem = petItemTemplate:Clone()
		petItem.Position = UDim2.new(0, 10, 0, (i-1) * 90 + 10)

		-- Update texts
		petItem.NameLabel.Text = petGroup.name .. " x" .. petGroup.count
		petItem.RarityLabel.Text = petGroup.rarity

		-- Set rarity text color
		if petGroup.rarity == "Common" then
			petItem.RarityLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
		elseif petGroup.rarity == "Rare" then
			petItem.RarityLabel.TextColor3 = Color3.fromRGB(30, 144, 255)
		elseif petGroup.rarity == "Epic" then
			petItem.RarityLabel.TextColor3 = Color3.fromRGB(138, 43, 226)
		elseif petGroup.rarity == "Legendary" then
			petItem.RarityLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
		end

		-- Calculate value
		local baseValue = 1
		if petGroup.rarity == "Common" then
			baseValue = 1
		elseif petGroup.rarity == "Rare" then
			baseValue = 5
		elseif petGroup.rarity == "Epic" then
			baseValue = 20
		elseif petGroup.rarity == "Legendary" then
			baseValue = 100
		end

		local totalValue = baseValue * petGroup.count
		petItem.ValueLabel.Text = "Value: " .. totalValue .. " Coins"

		-- Connect sell button
		petItem.SellButton.MouseButton1Click:Connect(function()
			-- Fire SellPetGroup event to server
			local SellPetGroup = remoteEvents:FindFirstChild("SellPetGroup")
			if SellPetGroup then
				SellPetGroup:FireServer(petGroup.name, petGroup.rarity)
			end
		end)

		petItem.Parent = petListFrame
	end

	-- Update canvas size based on content
	petListFrame.CanvasSize = UDim2.new(0, 0, 0, math.max(#groupedPets * 90 + 20, petListFrame.AbsoluteSize.Y))
end

return ShopTab