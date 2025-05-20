-- ServerScriptService/PetGuiCleaner.lua
local PET_FOLDER = workspace:WaitForChild("Pets")

local function stripBillboards(model)
	for _, gui in ipairs(model:GetDescendants()) do
		if gui:IsA("BillboardGui") then
			gui:Destroy()
		end
	end
end

for _, pet in ipairs(PET_FOLDER:GetChildren()) do
	stripBillboards(pet)
end

PET_FOLDER.DescendantAdded:Connect(function(inst)
	if inst:IsA("BillboardGui") then
		inst:Destroy()
	end
end)
