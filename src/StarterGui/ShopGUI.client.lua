-- Pet Collection Simulator
-- ShopGUI Script (LocalScript in StarterGui)

-- Services
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local CollectionService = game:GetService("CollectionService")

-- Local player
local player = Players.LocalPlayer

-- Ensure RemoteEvents and RemoteFunctions exist
local function ensureRemotesExist()
	local reFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if not reFolder then
		reFolder = Instance.new("Folder")
		reFolder.Name = "RemoteEvents"
		reFolder.Parent = ReplicatedStorage
	end
	local rfFolder = ReplicatedStorage:FindFirstChild("RemoteFunctions")
	if not rfFolder then
		rfFolder = Instance.new("Folder")
		rfFolder.Name = "RemoteFunctions"
		rfFolder.Parent = ReplicatedStorage
	end

	local function makeRE(name)
		if not reFolder:FindFirstChild(name) then
			local ev = Instance.new("RemoteEvent")
			ev.Name = name
			ev.Parent = reFolder
		end
	end
	local function makeRF(name)
		if not rfFolder:FindFirstChild(name) then
			local fn = Instance.new("RemoteFunction")
			fn.Name = name
			fn.Parent = rfFolder
		end
	end

	makeRE("BuyUpgrade")
	makeRE("UnlockArea")
	makeRE("SellPet")
	makeRE("UpdatePlayerStats")
	makeRF("PromptPurchase")
	makeRF("GetPlayerData")
end

ensureRemotesExist()

-- Remote references
local RemoteEvents    = ReplicatedStorage:WaitForChild("RemoteEvents")
local RemoteFunctions = ReplicatedStorage:WaitForChild("RemoteFunctions")

local UpdatePlayerStats = RemoteEvents:WaitForChild("UpdatePlayerStats")
local GetPlayerData     = RemoteFunctions:WaitForChild("GetPlayerData")
local BuyUpgrade        = RemoteEvents:WaitForChild("BuyUpgrade")
local UnlockArea        = RemoteEvents:WaitForChild("UnlockArea")
local SellPet           = RemoteEvents:WaitForChild("SellPet")
local PromptPurchase    = RemoteFunctions:WaitForChild("PromptPurchase")

-- Fetch player data
local playerData
do
	local ok, res = pcall(function()
		return GetPlayerData:InvokeServer()
	end)
	if ok and res then
		playerData = res
	else
		warn("ShopGUI: failed to load player data:", res)
		playerData = {
			coins = 0,
			gems = 0,
			pets = {},
			unlockedAreas = {"Starter Meadow"},
			upgrades = {
				["Collection Speed"] = 1,
				["Pet Capacity"]     = 1,
				["Collection Value"] = 1,
			},
		}
	end
end

-- Static shop definitions
local upgrades = {
	{ name="Collection Speed", baseCost=100, costMultiplier=1.5, maxLevel=10 },
	{ name="Pet Capacity",     baseCost=200, costMultiplier=2.0, maxLevel=5  },
	{ name="Collection Value", baseCost=500, costMultiplier=2.5, maxLevel=10 },
}

local areas = {
	{ name="Starter Meadow", unlockCost=0,    petSpawnRate=15, availablePets={"Common Corgi"} },
	{ name="Mystic Forest",  unlockCost=1000, petSpawnRate=12, availablePets={"Common Corgi","Rare RedPanda"} },
	{ name="Dragon's Lair",  unlockCost=10000,petSpawnRate=10, availablePets={"Rare RedPanda","Epic Corgi","Legendary RedPanda"} },
}

local premiumProducts = {
	{ name="VIP",          type="GamePass",   id=0000001, description="2x Coins, Exclusive Pets",     price=799 },
	{ name="Auto-Collect", type="GamePass",   id=0000002, description="Automatically collect pets",   price=399 },
	{ name="Small Coins",  type="DevProduct", id=0000001, description="100 Coins",                    price=49  },
	{ name="Medium Coins", type="DevProduct", id=0000002, description="550 Coins (10% Bonus)",        price=99  },
	{ name="Large Coins",  type="DevProduct", id=0000003, description="1200 Coins (20% Bonus)",       price=199 },
}

----------------------------------------
-- GUI CREATION & TEMPLATES (unchanged)
----------------------------------------
local function CreateShopGUI()
	-- returns a ScreenGui under PlayerGui named "ShopGUI"
	-- [snip: identical to your original CreateShopGUI code]
	-- make sure it creates:
	-- ScreenGui "ShopGUI"
	--   Frame "MainFrame"
	--     Frame "TitleBar"
	--     Frame "TabButtons"
	--     Frame "ContentFrame"
	--       ScrollingFrame "SellPetsFrame"
	--       ScrollingFrame "BuyUpgradesFrame"
	--       ScrollingFrame "PremiumShopFrame"
	--       ScrollingFrame "UnlockAreasFrame"
	--     Frame "StatsDisplay"
	--
	-- for brevity I'm leaving the body as-is
	return shopGUI
end

local function CreateSellPetTemplate()   -- [unchanged] end
	local function CreateUpgradeTemplate()   -- [unchanged] end
		local function CreatePremiumTemplate()   -- [unchanged] end
			local function CreateAreaTemplate()      -- [unchanged] end

				----------------------------------------
				-- UPDATE STATS
				----------------------------------------
				local function UpdateShopStats(shopGUI)
					local mainFrame    = shopGUI:WaitForChild("MainFrame")
					local statsDisplay = mainFrame:WaitForChild("StatsDisplay")
					local coinsLabel   = statsDisplay:FindFirstChild("CoinsLabel")
					local gemsLabel    = statsDisplay:FindFirstChild("GemsLabel")

					if coinsLabel then
						coinsLabel.Text = "Coins: " .. tostring(playerData.coins or 0)
					end
					if gemsLabel then
						gemsLabel.Text = "Gems: "  .. tostring(playerData.gems  or 0)
					end
				end

				----------------------------------------
				-- POPULATE TABS (use explicit shopGUI)
				----------------------------------------
				local function PopulateSellPetsTab(shopGUI)
					local mainFrame      = shopGUI:WaitForChild("MainFrame")
					local contentFrame   = mainFrame:WaitForChild("ContentFrame")
					local sellPetsFrame  = contentFrame:WaitForChild("SellPetsFrame")
					-- [snip: your existing PopulateSellPetsTab code,
					-- but replace any "shopGUI.MainFrame.ContentFrame" with
					-- these local variables]
				end

				local function PopulateBuyUpgradesTab(shopGUI)
					local mainFrame        = shopGUI:WaitForChild("MainFrame")
					local contentFrame     = mainFrame:WaitForChild("ContentFrame")
					local buyUpgradesFrame = contentFrame:WaitForChild("BuyUpgradesFrame")
					-- [snip: your existing PopulateBuyUpgradesTab code]
				end

				local function PopulatePremiumShopTab(shopGUI)
					local mainFrame         = shopGUI:WaitForChild("MainFrame")
					local contentFrame      = mainFrame:WaitForChild("ContentFrame")
					local premiumShopFrame  = contentFrame:WaitForChild("PremiumShopFrame")
					-- [snip: your existing PopulatePremiumShopTab code]
				end

				local function PopulateUnlockAreasTab(shopGUI)
					local mainFrame         = shopGUI:WaitForChild("MainFrame")
					local contentFrame      = mainFrame:WaitForChild("ContentFrame")
					local unlockAreasFrame  = contentFrame:WaitForChild("UnlockAreasFrame")
					-- [snip: your existing PopulateUnlockAreasTab code]
				end

				----------------------------------------
				-- UPDATE CONTENT BASED ON VISIBLE TAB
				----------------------------------------
				local function UpdateShopContent(shopGUI)
					if not shopGUI or not shopGUI.Enabled then return end

					-- refresh stats
					UpdateShopStats(shopGUI)

					-- find which tab frame is visible
					local mainFrame    = shopGUI:WaitForChild("MainFrame")
					local contentFrame = mainFrame:WaitForChild("ContentFrame")
					local visibleTab

					for _, frame in ipairs(contentFrame:GetChildren()) do
						if frame:IsA("ScrollingFrame") and frame.Visible then
							visibleTab = frame
							break
						end
					end

					if not visibleTab then return end

					if visibleTab.Name == "SellPetsFrame" then
						PopulateSellPetsTab(shopGUI)
					elseif visibleTab.Name == "BuyUpgradesFrame" then
						PopulateBuyUpgradesTab(shopGUI)
					elseif visibleTab.Name == "PremiumShopFrame" then
						PopulatePremiumShopTab(shopGUI)
					elseif visibleTab.Name == "UnlockAreasFrame" then
						PopulateUnlockAreasTab(shopGUI)
					end
				end

				----------------------------------------
				-- OPEN SHOP
				----------------------------------------
				local function OpenShop(tabName)
					local shopGUI = CreateShopGUI()
					shopGUI.Enabled = true
					UpdateShopContent(shopGUI)

					-- switch tab
					local mainFrame   = shopGUI:WaitForChild("MainFrame")
					local tabButtons  = mainFrame:WaitForChild("TabButtons")
					local defaultTab  = "Sell Pets"
					local button      = tabButtons:FindFirstChild((tabName or defaultTab).."Button")
					if button then
						button:Fire("MouseButton1Click")
					else
						tabButtons:FindFirstChild(defaultTab.."Button"):Fire("MouseButton1Click")
					end
				end

				----------------------------------------
				-- SETUP SHOP TOUCHS & PROMPTS
				----------------------------------------
				local function SetupShopTouchPart()
					-- [keep your existing SetupShopTouchPart code unchanged]
				end

				----------------------------------------
				-- LISTEN FOR DATA UPDATES
				----------------------------------------
				UpdatePlayerStats.OnClientEvent:Connect(function(newData)
					if newData then
						playerData = newData
						local shopGUI = player.PlayerGui:FindFirstChild("ShopGUI")
						if shopGUI and shopGUI.Enabled then
							UpdateShopContent(shopGUI)
						end
					else
						warn("ShopGUI: received nil playerData")
					end
				end)

				----------------------------------------
				-- KEYBIND FOR TESTING
				----------------------------------------
				UserInputService.InputBegan:Connect(function(input, gameProcessed)
					if not gameProcessed and input.KeyCode == Enum.KeyCode.B then
						local shopGUI = player.PlayerGui:FindFirstChild("ShopGUI") or CreateShopGUI()
						shopGUI.Enabled = not shopGUI.Enabled
						if shopGUI.Enabled then
							UpdateShopContent(shopGUI)
							-- select first tab
							local mainFrame  = shopGUI:WaitForChild("MainFrame")
							local firstBtn   = mainFrame.TabButtons:FindFirstChildOfClass("TextButton")
							if firstBtn then firstBtn:Fire("MouseButton1Click") end
						end
					end
				end)

				----------------------------------------
				-- INITIALIZE
				----------------------------------------
				spawn(function()
					if not player.Character then
						player.CharacterAdded:Wait()
					end
					wait(1)
					CreateShopGUI()
					local parts = SetupShopTouchPart()
					print("Shop system initialized with "..#parts.." touch parts")
				end)

				print("ShopGUI script loaded!")
