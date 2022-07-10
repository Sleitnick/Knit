if game:GetService("RunService"):IsServer() then
	return require(script.KnitServer)
else
	local _, notInEdit = pcall(function()
		game:GetService("RunService"):IsEdit()
	end)
	
	local KnitServer = script:FindFirstChild("KnitServer")
	if KnitServer and notInEdit then
		KnitServer:Destroy()
	end
	return require(script.KnitClient)
end
