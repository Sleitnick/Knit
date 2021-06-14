local RunService = game:GetService("RunService")

return  RunService:IsServer() and require(script.KnitServer) or  require(script.KnitClient)


-- script.KnitServer:Destroy() // Redundant, the client can NEVER see any server scripts, (even if they exist in a container that the client can access them)
-- since the server never replicates the bytecode of a server script to the client
