
local cooldown = script.Parent.cooldown.Value
local plr = ""
script.Parent.Equipped:connect(function()
	plr = script.Parent.Parent
	script.Parent.GripPos = Vector3.new(.4, 0, .3)
end)

script.Parent.Activated:connect(function()
		if cooldown == true then
			cooldown  = false	
			script.Parent.Parent.Animate.toolnone.ToolNoneAnim.AnimationId = "rbxassetid://1331956048"
			script.Parent.GripPos = Vector3.new(1.5, -0.7, -0.7)
			script.Parent.Eat:Play()
			wait(1)
			plr.Animate.toolnone.ToolNoneAnim.AnimationId = "http://www.roblox.com/asset/?id=182393478"
			if script.Parent.Parent.ClassName == "Model" then
				local sparkle = Instance.new("Sparkles")
				sparkle.Parent = script.Parent.Parent.Torso
				script.Parent.Parent.Humanoid.WalkSpeed = script.Parent.Parent.Humanoid.WalkSpeed + 16
				script.Parent.Parent.Humanoid.JumpPower = script.Parent.Parent.Humanoid.JumpPower + 5
				local dScript = script.DestroyScript:Clone()
				dScript.Parent = sparkle
				script.Parent.GripPos = Vector3.new(.4, 0, .3)
				wait(5)
				if script.Parent.Parent.ClassName == "Model" then
					script.Parent.Parent.Humanoid.WalkSpeed = script.Parent.Parent.Humanoid.WalkSpeed - 16
					script.Parent.Parent.Humanoid.JumpPower = script.Parent.Parent.Humanoid.JumpPower - 5
				else
					local character = script.Parent.Parent.Parent.Character.Humanoid
					character.WalkSpeed = character.WalkSpeed - 16
					character.JumpPower = character.JumpPower - 5
				end
				cooldown = true
				sparkle.Enabled = false
		end
	end
end)

