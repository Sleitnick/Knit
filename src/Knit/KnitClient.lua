local KnitClient = {}

KnitClient.Util = script.Parent.Util

local Promise = require(KnitClient.Util.Promise)
local Thread = require(KnitClient.Util.Thread)
local Event = require(KnitClient.Util.Event)

local services = {}
local servicesFolder = script.Parent:WaitForChild("Services")


local function BuildService(serviceName, folder)
	local service = {}
	if (folder:FindFirstChild("RF")) then
		for _,rf in ipairs(folder.RF:GetChildren()) do
			if (rf:IsA("RemoteFunction")) then
				service[rf.Name] = function(self, ...)
					return rf:InvokeServer(...)
				end
				service[rf.Name .. "Promise"] = function(self, ...)
					local args = table.pack(...)
					return Promise.new(function(resolve)
						resolve(rf:InvokeServer(table.unpack(args, 1, args.n)))
					end)
				end
			end
		end
	end
	if (folder:FindFirstChild("RE")) then
		for _,re in ipairs(folder.RE:GetChildren()) do
			if (re:IsA("RemoteEvent")) then
				local event = Event.new()
				local _fire = event.Fire
				function event:Fire(...)
					re:FireServer(...)
				end
				re.OnClientEvent:Connect(function(...)
					_fire(event, ...)
				end)
				service[re.Name] = event
			end
		end
	end
	services[serviceName] = service
	return service
end


function KnitClient.CreateController(controllerName)
	
end


function KnitClient.GetService(serviceName)
	assert(type(serviceName) == "string", "ServiceName must be a string; got " .. type(serviceName))
	local folder = servicesFolder:FindFirstChild(serviceName)
	assert(folder ~= nil, "Could not find service \"" .. serviceName .. "\"")
	return services[serviceName] or BuildService(serviceName, folder)
end


function KnitClient.Start()
	
	return Promise.new(function(resolve)
		
		resolve()
		
	end)
	
end


return KnitClient