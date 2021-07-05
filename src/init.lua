local KnitServer = script:FindFirstChild("KnitServer")
if (game:GetService("RunService"):IsServer()) then
	return require(KnitServer)
else
	if KnitServer then
		KnitServer:Destroy()
	end
	return require(script.KnitClient)
end