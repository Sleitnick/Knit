if game:GetService("RunService"):IsServer() then
	return require(script.KnitServer)
else
	script.KnitServer:Destroy()
	return require(script.KnitClient)
end
