-- ServerScriptService/ShopTouchHandler.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")
local openShopEvent     = ReplicatedStorage
	:WaitForChild("RemoteEvents")
	:WaitForChild("OpenShop")

local farmModel         = workspace
	:WaitForChild("Areas")
	:WaitForChild("Starter Meadow")
	:WaitForChild("Farm")

local shopTouchPart     = farmModel:WaitForChild("ShopTouchPart")
assert(shopTouchPart:IsA("BasePart"), "ShopTouchPart must be a BasePart")

shopTouchPart.Touched:Connect(function(hit)
	local player = Players:GetPlayerFromCharacter(hit.Parent)
	if player then
		openShopEvent:FireClient(player)
	end
end)

local lastTouch = {}
shopTouchPart.Touched:Connect(function(hit)
	local p = Players:GetPlayerFromCharacter(hit.Parent)
	if not p then return end
	if lastTouch[p] and tick() - lastTouch[p] < 1 then return end
	lastTouch[p] = tick()
	openShopEvent:FireClient(p)
end)
