local RunService = game:GetService("RunService")

local success, v = pcall(function()
	return RunService:IsEdit()
end)
local IS_EDIT = success and v

if RunService:IsServer() then
	return require(script.KnitServer)
else
	local KnitServer = script:FindFirstChild("KnitServer")
	if KnitServer and not IS_EDIT then
		KnitServer:Destroy()
	end
	return require(script.KnitClient)
end
