if game:GetService("RunService"):IsServer() then
	return require(script.KnitServer)
else
  local KnitServer = script:FindFirstChild("KnitServer")
	if KnitServer then
		KnitServer:Destroy()
	end
	return require(script.KnitClient)
end
