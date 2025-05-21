while true do
	wait(math.random(2,5))
	script.Parent.PointLight.Enabled = true
	script.Parent.ParticleEmitter.Enabled = true
	script.Parent.Velocity = Vector3.new(20,0,40)
	script.Parent.Transparency = 0
	wait(0.5)
	script.Parent.PointLight.Enabled = false
	script.Parent.ParticleEmitter.Enabled = false
	script.Parent.Transparency = 1
end