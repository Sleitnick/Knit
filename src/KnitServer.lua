--[[

	Knit.CreateService(service): Service
	Knit.AddServices(folder): Service[]
	Knit.AddServicesDeep(folder): Service[]
	Knit.Start(): Promise<void>
	Knit.OnStart(): Promise<void>

--]]


--[=[
	@interface ServiceDef
	.Name string
	.Client table?
	.[any] any
	@within KnitServer
	Used to define a service when creating it in `CreateService`.
]=]
type ServiceDef = {
	Name: string,
	Client: {[any]: any}?,
	[any]: any,
}

--[=[
	@interface Service
	.Name string
	.Client ServiceClient
	.KnitComm Comm
	.[any] any
	@within KnitServer
]=]
type Service = {
	Name: string,
	Client: ServiceClient,
	KnitComm: any,
	_knit_is_service: boolean,
	[any]: any,
}

--[=[
	@interface ServiceClient
	.Server Service
	.[any] any
	@within KnitServer
]=]
type ServiceClient = {
	Server: Service,
	[any]: any,
}


--[=[
	@class KnitServer
	@server
]=]
local KnitServer = {}

--[=[
	@prop Services {[string]: Service}
	@within KnitServer
]=]
KnitServer.Services = {} :: {[string]: Service}

--[=[
	@prop Util Folder
	@within KnitServer
]=]
KnitServer.Util = script.Parent.Parent


local knitRepServiceFolder = Instance.new("Folder")
knitRepServiceFolder.Name = "Services"

local Promise = require(KnitServer.Util.Promise)
local Loader = require(KnitServer.Util.Loader)
local TableUtil = require(KnitServer.Util.TableUtil)
local Comm = require(KnitServer.Util.Comm)
local ServerComm = Comm.ServerComm

local started = false
local startedComplete = false
local onStartedComplete = Instance.new("BindableEvent")


local function CreateRepFolder(serviceName: string): Instance
	local folder = Instance.new("Folder")
	folder.Name = serviceName
	return folder
end


local function DoesServiceExist(serviceName: string): boolean
	local service: Service? = KnitServer.Services[serviceName]
	return service ~= nil
end


--[=[
	@param serviceDefinition ServiceDef
	@return Service
	Constructs a new service.
]=]
function KnitServer.CreateService(serviceDef: ServiceDef): Service
	assert(type(serviceDef) == "table", "Service must be a table; got " .. type(serviceDef))
	assert(type(serviceDef.Name) == "string", "Service.Name must be a string; got " .. type(serviceDef.Name))
	assert(#serviceDef.Name > 0, "Service.Name must be a non-empty string")
	assert(not DoesServiceExist(serviceDef.Name), "Service \"" .. serviceDef.Name .. "\" already exists")
	local service: Service = TableUtil.Assign(serviceDef, {
		_knit_is_service = true;
		KnitComm = ServerComm.new(CreateRepFolder(serviceDef.Name));
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


--[=[
	@param parent Instance
	@return {any}
	Requires all the modules that are children of the given parent. This is an easy
	way to quickly load all services that might be in a folder.
	```lua
	Knit.AddServices(somewhere.Services)
	```
]=]
function KnitServer.AddServices(parent: Instance): {any}
	return Loader.LoadChildren(parent)
end


--[=[
	@param parent Instance
	@return {any}
	Requires all the modules that are descendants of the given parent.
]=]
function KnitServer.AddServicesDeep(parent: Instance): {any}
	return Loader.LoadDescendants(parent)
end


--[=[
	@param serviceName string
	@return Service?
	Gets the service by name, or `nil` if it is not found.
]=]
function KnitServer.GetService(serviceName: string): Service
	assert(type(serviceName) == "string", "ServiceName must be a string; got " .. type(serviceName))
	return assert(KnitServer.Services[serviceName], "Could not find service \"" .. serviceName .. "\"") :: Service
end


--[=[
	@return Promise
	Starts Knit. Should only be called once.

	:::caution
	Be sure that all services have been created _before_ calling `Start`. Services cannot be added later.
	:::

	```lua
	Knit.Start():andThen(function()
		print("Knit started!")
	end):catch(warn)
	```
]=]
function KnitServer.Start()

	if started then
		return Promise.reject("Knit already started")
	end

	started = true

	local services = KnitServer.Services

	return Promise.new(function(resolve)

		-- Bind remotes:
		for _,service in pairs(services) do
			for k,v in pairs(service.Client) do
				if type(v) == "function" then
					service.KnitComm:BindFunction(k, v)
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

		resolve(Promise.all(promisesInitServices))

	end):andThen(function()

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


--[=[
	@return Promise
	Returns a promise that is resolved once Knit has started. This is useful
	for any code that needs to tie into Knit services but is not the script
	that called `Start`.
	```lua
	Knit.OnStart():andThen(function()
		local MyService = Knit.Services.MyService
		MyService:DoSomething()
	end):catch(warn)
	```
]=]
function KnitServer.OnStart()
	if startedComplete then
		return Promise.resolve()
	else
		return Promise.fromEvent(onStartedComplete.Event)
	end
end


return KnitServer
