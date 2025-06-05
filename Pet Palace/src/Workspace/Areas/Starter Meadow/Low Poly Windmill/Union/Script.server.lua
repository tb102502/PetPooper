--this script makes the WindMill thingy spin.

spinning = script.Parent

while true do
spinning.CFrame = spinning.CFrame * CFrame.fromEulerAnglesXYZ(0, math.rad(0),0.005)--0.005 is recommended (Higher makes it faster),(Lower is slower)
wait(0.00)
end
