local RunService = game:GetService("RunService")

local IS_EDIT = pcall(function()
	RunService:IsEdit()
end)

if RunService:IsServer() then
	return require(script.KnitServer)
else
	local KnitServer = script:FindFirstChild("KnitServer")
	if KnitServer and not IS_EDIT then
		KnitServer:Destroy()
	end
	return require(script.KnitClient)
end
