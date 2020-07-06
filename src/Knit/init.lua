local IS_SERVER = game:GetService("RunService"):IsServer()

if (IS_SERVER) then
	return require(script.KnitServer)
else
	script.KnitServer:Destroy()
	return require(script.KnitClient)
end