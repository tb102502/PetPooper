while true do
	wait(math.random(2, 8))
	script.Parent.Material = Enum.Material.Neon
	script.Parent.PointLight.Enabled = true
	wait(math.random(2, 8))
	script.Parent.Material = Enum.Material.Glass
	script.Parent.PointLight.Enabled = false
end