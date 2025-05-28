local Lib = workspace.Multiplayer.GetMapVals:Invoke() --Has: Map, Script, Button, btnFuncs
Lib.Button:connect(function(p, bNo) if Lib.btnFuncs[bNo] then Lib.btnFuncs[bNo](bNo, p) end end)

Lib.btnFuncs[1] = function()
	---Move Door (fixed lol)
	Lib.Script.moveWater(Lib.Map._Door5, Vector3.new(10, 0, 0), 1.5, true)
	Lib.Script.moveWater(Lib.Map._Door6, Vector3.new(-10, 0, 0), 1.5, true)
end

Lib.btnFuncs[2] = function()
	---Move Door (fixed lol again)
	Lib.Script.moveWater(Lib.Map._Door7, Vector3.new(10, 0, 0), 1.5, true)
	Lib.Script.moveWater(Lib.Map._Door8, Vector3.new(-10, 0, 0), 1.5, true)
end

Lib.btnFuncs[3] = function()
	---Move Door (fixeeedd)
	Lib.Script.moveWater(Lib.Map._Door9, Vector3.new(5, 0, 0), 5, true)
	Lib.Script.moveWater(Lib.Map._Door10, Vector3.new(-5, 0, 0), 5, true)
end

Lib.btnFuncs[4] = function()
	---Move Water
	wait(2)
	Lib.Script.moveWater(Lib.Map.Intro._Fence, Vector3.new(0, 0, 68), 5, true)
end

Lib.btnFuncs[5] = function()
	---Move Rock
	Lib.Script.moveWater(Lib.Map._RockMove, Vector3.new(0, 20, 0), 2, true)
end

Lib.btnFuncs[6] = function()
	---Delete Rocks
	Lib.Map._Disappear.Rock1.CanCollide = false
	Lib.Map._Disappear.Rock2.CanCollide = false
	Lib.Map._Disappear.Rock3.CanCollide = false
	Lib.Map._Disappear.Rock4.CanCollide = false
	Lib.Map._Disappear.Rock5.CanCollide = false
	Lib.Map._Disappear.Rock6.CanCollide = false
	Lib.Map._Disappear.Rock1.Anchored = false
	Lib.Map._Disappear.Rock2.Anchored = false
	Lib.Map._Disappear.Rock3.Anchored = false
	Lib.Map._Disappear.Rock4.Anchored = false
	Lib.Map._Disappear.Rock5.Anchored = false
	Lib.Map._Disappear.Rock6.Anchored = false
	wait(2.5)
	Lib.Script.moveWater(Lib.Map._Door11, Vector3.new(0, -12, 0), 0.75, true)
end

wait(3)
Lib.Script.moveWater(Lib.Map._Door1, Vector3.new(-10, 0, 0), 1.5, true)
Lib.Script.moveWater(Lib.Map._Door2, Vector3.new(10, 0, 0), 1.5, true)
wait(13.5)--38.5 before (i deleted this cuz all is connected in the same room.)
Lib.Script.moveWater(Lib.Map.Intro._Water1, Vector3.new(0, 56.5, 0), 19, true)
Lib.Script.moveWater(Lib.Map.Intro._Water2, Vector3.new(0, 54.5, 0), 5.2, true)
Lib.Script.moveWater(Lib.Map.Intro._Water0, Vector3.new(0, 56.5, 0), 19, true)
Lib.Script.moveWater(Lib.Map.Intro._Water3, Vector3.new(0, 38.65, 0), 4.85, true)
Lib.Script.moveWater(Lib.Map.Intro._Barrier1, Vector3.new(0, 56.5, 0), 19, true)
Lib.Script.moveWater(Lib.Map.Intro._Barrier2, Vector3.new(0, 56.5, 0), 19, true)
Lib.Script.moveWater(Lib.Map.Intro._Barrier3, Vector3.new(0, 54.5, 0), 5.2, true)
Lib.Script.moveWater(Lib.Map.Intro._Barrier4, Vector3.new(0, 38.65, 0), 4.85, true)
wait(16.5)-- 20.15 before
Lib.Script.moveWater(Lib.Map.Intro._Water4, Vector3.new(0, 56.5, 0), 17.45, true)
Lib.Script.moveWater(Lib.Map.Intro._Barrier5, Vector3.new(0, 56.5, 0), 17.45, true)
wait(14.5)--38.5 before
Lib.Script.moveWater(Lib.Map.Intro._Water5, Vector3.new(0, 60, 0), 19, true)
wait(13.5)--16.5 before
Lib.Script.moveWater(Lib.Map.Intro._Water5, Vector3.new(0, 20, 0), 5, true)
wait(5.145)
Lib.Script.moveWater(Lib.Map.Intro._Water7, Vector3.new(0, 54.5, 0), 19, true)
Lib.Script.moveWater(Lib.Map.Intro._Barrier6, Vector3.new(0, 54.5, 0), 19, true)
wait(0.1)--14.5 before
Lib.Script.moveWater(Lib.Map.Intro._Water8, Vector3.new(0, 31.5, 0), 10.5, true)
Lib.Script.moveWater(Lib.Map.Intro._Barrier7, Vector3.new(0, 31.5, 0), 10.5, true)
wait(4.5)
Lib.Script.moveWater(Lib.Map._Door12, Vector3.new(0, -13.5, 0), 1.5, true)
wait(6.15)
Lib.Script.moveWater(Lib.Map.Intro._Water9, Vector3.new(0, 46.5, 0), 16.5, true)
Lib.Script.moveWater(Lib.Map._Door12, Vector3.new(0, 13.5, 0), 1.5, true)
wait(2.5)
Lib.Script.moveWater(Lib.Map.Intro._Water10, Vector3.new(0, 65, 0), 18.15, true)