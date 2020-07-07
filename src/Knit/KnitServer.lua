local KnitServer = {}

KnitServer.Services = {}
KnitServer.Util = script.Parent.Util


local knitRepServiceFolder = Instance.new("Folder")
knitRepServiceFolder.Name = "Services"
knitRepServiceFolder.Parent = script.Parent

local Promise = require(KnitServer.Util.Promise)
local Thread = require(KnitServer.Util.Thread)
local Event = require(KnitServer.Util.Event)
local TableUtil = require(KnitServer.Util.TableUtil)

local started = false


local function CreateRepFolder(serviceName)
	local folder = Instance.new("Folder")
	folder.Name = serviceName
	local rf = Instance.new("Folder")
	rf.Name = "RF"
	rf.Parent = folder
	local re = Instance.new("Folder")
	re.Name = "RE"
	re.Parent = folder
	return folder
end


local function AddToRepFolder(service, remoteObj)
	if (remoteObj:IsA("RemoteFunction")) then
		remoteObj.Parent = service._knit_rep_folder.RF
	else
		remoteObj.Parent = service._knit_rep_folder.RE
	end
	if (not service._knit_rep_folder.Parent) then
		service._knit_rep_folder.Parent = knitRepServiceFolder
	end
end


function KnitServer.IsService(object)
	return type(object) == "table" and object._knit_is_service == true
end


function KnitServer.CreateService(service)
	assert(type(service) == "table", "Service must be a table; got " .. type(service))
	assert(type(service.Name) == "string", "Service.Name must be a string; got " .. type(service.Name))
	assert(#service.Name > 0, "Service.Name must be a non-empty string")
	assert(KnitServer.Services[service.Name] == nil, "Service \"" .. service.Name .. "\" already exists")
	TableUtil.Extend(service, {
		_knit_is_service = true;
		_knit_rf = {};
		_knit_re = {};
		_knit_rep_folder = CreateRepFolder(service.Name);
	})
	if (type(service.Client) ~= "table") then
		service.Client = {Server = service}
	else
		if (service.Client.Server ~= service) then
			service.Client.Server = service
		end
	end
	KnitServer.Services[service.Name] = service
	return service
end


function KnitServer.BindRemoteEvent(service, eventName, event)
	assert(KnitServer.IsService(service), "Expected Service")
	assert(type(eventName) == "string", "Expected string for EventName; got " .. type(eventName))
	assert(service._knit_re[eventName] == nil, "RemoteEvent \"" .. eventName .. "\" already exists")
	local re = Instance.new("RemoteEvent")
	re.Name = eventName
	service._knit_re[eventName] = re
	AddToRepFolder(service, re)
	local _fire = event.Fire
	function event:Fire(...)
		re:FireClient(...)
	end
	function event:FireAll(...)
		re:FireAllClients(...)
	end
	function event:FireExcept(plr, ...)
		for _,p in ipairs(game:GetService("Players"):GetPlayers()) do
			if (p ~= plr) then
				re:FireClient(p, ...)
			end
		end
	end
	re.OnServerEvent:Connect(function(...)
		_fire(event, ...)
	end)
end


function KnitServer.BindRemoteFunction(service, funcName, func)
	assert(KnitServer.IsService(service), "Expected Service")
	assert(type(func) == "function", "Expected function for Func; got " .. type(func))
	assert(funcName ~= nil, "Failed to find function within service; make sure the function passed belongs to the given service")
	assert(service._knit_rf[funcName] == nil, "RemoteFunction \"" .. funcName .. "\" already exists")
	local rf = Instance.new("RemoteFunction")
	rf.Name = funcName
	service._knit_rf[funcName] = rf
	AddToRepFolder(service, rf)
	function rf.OnServerInvoke(...)
		return func(service, ...)
	end
end


function KnitServer.Start()
	
	assert(not started, "Knit already started")
	started = true
	if (next(KnitServer.Services) == nil) then
		warn("No services created for Knit\n\nYou may have run Start before creating services\n\n" .. debug.traceback())
	end
	
	local services = KnitServer.Services
	
	return Promise.new(function(resolve)
		
		-- Bind remotes:
		for _,service in pairs(services) do
			for k,v in pairs(service.Client) do
				if (type(v) == "function") then
					KnitServer.BindRemoteFunction(service, k, v)
				elseif (Event.Is(v)) then
					KnitServer.BindRemoteEvent(service, k, v)
				end
			end
		end
		
		-- Init:
		local promisesStartServices = {}
		for _,service in pairs(services) do
			if (type(service.KnitInit) == "function") then
				table.insert(promisesStartServices, Promise.new(function(r)
					service:KnitInit()
					r()
				end))
			end
		end
		Promise.all(promisesStartServices):await()
		
		-- Start:
		for _,service in pairs(services) do
			if (type(service.KnitStart) == "function") then
				Thread.SpawnNow(service.KnitStart, service)
			end
		end
		
		resolve()
		
	end)
	
end


return KnitServer