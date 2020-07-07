local KnitClient = {}

KnitClient.Controllers = {}
KnitClient.Util = script.Parent.Util

local Promise = require(KnitClient.Util.Promise)
local Thread = require(KnitClient.Util.Thread)
local Event = require(KnitClient.Util.Event)
local TableUtil = require(KnitClient.Util.TableUtil)

local services = {}
local servicesFolder = script.Parent:WaitForChild("Services")

local started = false


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


function KnitClient.CreateController(controller)
	assert(type(controller) == "table", "Controller must be a table; got " .. type(controller))
	assert(type(controller.Name) == "string", "Controller.Name must be a string; got " .. type(controller.Name))
	assert(#controller.Name > 0, "Controller.Name must be a non-empty string")
	assert(KnitClient.Controllers[controller.Name] == nil, "Service \"" .. controller.Name .. "\" already exists")
	TableUtil.Extend(controller, {
		_knit_is_controller = true;
	})
	KnitClient.Controllers[controller.Name] = controller
	return controller
end


function KnitClient.GetService(serviceName)
	assert(type(serviceName) == "string", "ServiceName must be a string; got " .. type(serviceName))
	local folder = servicesFolder:FindFirstChild(serviceName)
	assert(folder ~= nil, "Could not find service \"" .. serviceName .. "\"")
	return services[serviceName] or BuildService(serviceName, folder)
end


function KnitClient.Start()
	
	assert(not started, "Knit already started")
	started = true
	if (next(KnitClient.Controllers) == nil) then
		warn("No controllers created for Knit\n\nYou may have run Start before creating controllers\n\n" .. debug.traceback())
	end

	local controllers = KnitClient.Controllers
	
	return Promise.new(function(resolve)

		-- Init:
		local promisesStartControllers = {}
		for _,controller in pairs(controllers) do
			if (type(controller.KnitInit) == "function") then
				table.insert(promisesStartControllers, Promise.new(function(r)
					controller:KnitInit()
					r()
				end))
			end
		end
		Promise.all(promisesStartControllers):await()

		-- Start:
		for _,controller in pairs(controllers) do
			if (type(controller.KnitStart) == "function") then
				Thread.SpawnNow(controller.KnitStart, controller)
			end
		end
		
		resolve()
		
	end)
	
end


return KnitClient