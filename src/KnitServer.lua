--!strict

--[[

	Knit.CreateService(service): Service
	Knit.AddServices(folder): Service[]
	Knit.AddServicesDeep(folder): Service[]
	Knit.Start(): Promise<void>
	Knit.OnStart(): Promise<void>

--]]


type ServiceDef = {
	Name: string,
	Client: {[any]: any}?,
	[any]: any,
}

type Service = {
	Name: string,
	Client: ServiceClient,
	_knit_is_service: boolean,
	_knit_rf: {},
	_knit_re: {},
	_knit_rp: {},
	_knit_rep_folder: Instance,
	[any]: any,
}

type ServiceClient = {
	Server: Service,
	[any]: any,
}


local KnitServer = {}

KnitServer.Version = script.Parent:WaitForChild("Version").Value
KnitServer.Services = {} :: {[string]: Service}
KnitServer.Util = script.Parent:WaitForChild("Util")


local knitRepServiceFolder = Instance.new("Folder")
knitRepServiceFolder.Name = "Services"

local Promise = require(KnitServer.Util.Promise)
local Signal = require(KnitServer.Util.Signal)
local Loader = require(KnitServer.Util.Loader)
local Ser = require(KnitServer.Util.Ser)
local RemoteSignal = require(KnitServer.Util.Remote.RemoteSignal)
local RemoteProperty = require(KnitServer.Util.Remote.RemoteProperty)
local TableUtil = require(KnitServer.Util.TableUtil)

local started = false
local startedComplete = false
local onStartedComplete = Instance.new("BindableEvent")


local function CreateRepFolder(serviceName: string): Instance
	local folder = Instance.new("Folder")
	folder.Name = serviceName
	return folder
end


local function GetFolderOrCreate(parent: Instance, name: string): Instance
	local f = parent:FindFirstChild(name)
	if not f then
		f = Instance.new("Folder")
		f.Name = name
		f.Parent = parent
	end
	return f
end


local function AddToRepFolder(service: Service, remoteObj: Instance, folderOverride: string?)
	if folderOverride then
		remoteObj.Parent = GetFolderOrCreate(service._knit_rep_folder, folderOverride)
	elseif remoteObj:IsA("RemoteFunction") then
		remoteObj.Parent = GetFolderOrCreate(service._knit_rep_folder, "RF")
	elseif remoteObj:IsA("RemoteEvent") then
		remoteObj.Parent = GetFolderOrCreate(service._knit_rep_folder, "RE")
	elseif remoteObj:IsA("ValueBase") then
		remoteObj.Parent = GetFolderOrCreate(service._knit_rep_folder, "RP")
	else
		error("Invalid rep object: " .. remoteObj.ClassName)
	end
	if not service._knit_rep_folder.Parent then
		service._knit_rep_folder.Parent = knitRepServiceFolder
	end
end


local function DoesServiceExist(serviceName: string): boolean
	local service: Service? = KnitServer.Services[serviceName]
	return service ~= nil
end


function KnitServer.IsService(object: any): boolean
	return type(object) == "table" and object._knit_is_service == true
end


function KnitServer.CreateService(serviceDef: ServiceDef): Service
	assert(type(serviceDef) == "table", "Service must be a table; got " .. type(serviceDef))
	assert(type(serviceDef.Name) == "string", "Service.Name must be a string; got " .. type(serviceDef.Name))
	assert(#serviceDef.Name > 0, "Service.Name must be a non-empty string")
	assert(not DoesServiceExist(serviceDef.Name), "Service \"" .. serviceDef.Name .. "\" already exists")
	local service: Service = TableUtil.Assign(serviceDef, {
		_knit_is_service = true;
		_knit_rf = {};
		_knit_re = {};
		_knit_rp = {};
		_knit_rep_folder = CreateRepFolder(serviceDef.Name);
	})
	if type(service.Client) ~= "table" then
		service.Client = {Server = service}
	else
		if service.Client.Server ~= service then
			service.Client.Server = service
		end
	end
	KnitServer.Services[service.Name] = service
	return service
end


function KnitServer.AddServices(folder: Instance): {any}
	return Loader.LoadChildren(folder)
end


function KnitServer.AddServicesDeep(folder: Instance): {any}
	return Loader.LoadDescendants(folder)
end


function KnitServer.GetService(serviceName: string): Service
	assert(type(serviceName) == "string", "ServiceName must be a string; got " .. type(serviceName))
	return assert(KnitServer.Services[serviceName], "Could not find service \"" .. serviceName .. "\"") :: Service
end


function KnitServer.BindRemoteEvent(service: Service, eventName: string, remoteEvent)
	assert(service._knit_re[eventName] == nil, "RemoteEvent \"" .. eventName .. "\" already exists")
	local re = remoteEvent._remote
	re.Name = eventName
	service._knit_re[eventName] = re
	AddToRepFolder(service, re)
end


function KnitServer.BindRemoteFunction(service: Service, funcName: string, func: (ServiceClient, ...any) -> ...any)
	assert(service._knit_rf[funcName] == nil, "RemoteFunction \"" .. funcName .. "\" already exists")
	local rf = Instance.new("RemoteFunction")
	rf.Name = funcName
	service._knit_rf[funcName] = rf
	AddToRepFolder(service, rf)
	rf.OnServerInvoke = function(...)
		return Ser.SerializeArgsAndUnpack(func(service.Client, Ser.DeserializeArgsAndUnpack(...)))
	end
end


function KnitServer.BindRemoteProperty(service: Service, propName: string, prop)
	assert(service._knit_rp[propName] == nil, "RemoteProperty \"" .. propName .. "\" already exists")
	prop._object.Name = propName
	service._knit_rp[propName] = prop
	AddToRepFolder(service, prop._object, "RP")
end


function KnitServer.Start()

	if started then
		return Promise.Reject("Knit already started")
	end

	started = true

	local services = KnitServer.Services

	return Promise.new(function(resolve)

		-- Bind remotes:
		for _,service in pairs(services) do
			for k,v in pairs(service.Client) do
				if type(v) == "function" then
					KnitServer.BindRemoteFunction(service, k, v)
				elseif RemoteSignal.Is(v) then
					KnitServer.BindRemoteEvent(service, k, v)
				elseif RemoteProperty.Is(v) then
					KnitServer.BindRemoteProperty(service, k, v)
				elseif Signal.Is(v) then
					warn("Found Signal instead of RemoteSignal (Knit.Util.RemoteSignal). Please change to RemoteSignal. [" .. service.Name .. ".Client." .. k .. "]")
				end
			end
		end

		-- Init:
		local promisesInitServices = {}
		for _,service in pairs(services) do
			if type(service.KnitInit) == "function" then
				table.insert(promisesInitServices, Promise.new(function(r)
					service:KnitInit()
					r()
				end))
			end
		end

		resolve(Promise.All(promisesInitServices))

	end):Then(function()

		-- Start:
		for _,service in pairs(services) do
			if type(service.KnitStart) == "function" then
				task.spawn(service.KnitStart, service)
			end
		end

		startedComplete = true
		onStartedComplete:Fire()

		task.defer(function()
			onStartedComplete:Destroy()
		end)

		-- Expose service remotes to everyone:
		knitRepServiceFolder.Parent = script.Parent

	end)

end


function KnitServer.OnStart()
	if startedComplete then
		return Promise.Resolve()
	else
		return Promise.FromEvent(onStartedComplete.Event)
	end
end


return KnitServer
