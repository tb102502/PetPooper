-- Place this script inside your ShopTouchPart in Workspace
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Create or get the remote event for opening the shop
local RemoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
if not RemoteEvents then
	RemoteEvents = Instance.new("Folder")
	RemoteEvents.Name = "RemoteEvents"
	RemoteEvents.Parent = ReplicatedStorage
end

local OpenShopEvent = RemoteEvents:FindFirstChild("OpenShop")
if not OpenShopEvent then
	OpenShopEvent = Instance.new("RemoteEvent")
	OpenShopEvent.Name = "OpenShop"
	OpenShopEvent.Parent = RemoteEvents
	print("Created OpenShop RemoteEvent")
end

-- Function to handle when a player touches the part
local function onTouched(hit)
	local character = hit.Parent
	if character and character:FindFirstChild("Humanoid") then
		local player = Players:GetPlayerFromCharacter(character)
		if player then
			print("Player " .. player.Name .. " touched shop part")
			OpenShopEvent:FireClient(player)
		end
	end
end

-- Connect the touched event
script.Parent.Touched:Connect(onTouched)

print("ShopTouchPart script loaded!")