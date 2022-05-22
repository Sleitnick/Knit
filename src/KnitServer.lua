--[=[
	@interface Middleware
	.Inbound ServerMiddleware?
	.Outbound ServerMiddleware?
	@within KnitServer
]=]
type Middleware = {
	Inbound: ServerMiddleware?,
	Outbound: ServerMiddleware?,
}

--[=[
	@type ServerMiddlewareFn (player: Player, args: {any}) -> (shouldContinue: boolean, ...: any)
	@within KnitServer

	For more info, see [ServerComm](https://sleitnick.github.io/RbxUtil/api/ServerComm/) documentation.
]=]
type ServerMiddlewareFn = (player: Player, args: {any}) -> (boolean, ...any)

--[=[
	@type ServerMiddleware {ServerMiddlewareFn}
	@within KnitServer
	An array of server middleware functions.
]=]
type ServerMiddleware = {ServerMiddlewareFn}

--[=[
	@interface ServiceDef
	.Name string
	.Client table?
	.Middleware Middleware?
	.[any] any
	@within KnitServer
	Used to define a service when creating it in `CreateService`.

	The middleware tables provided will be used instead of the Knit-level
	middleware (if any). This allows fine-tuning each service's middleware.
	These can also be left out or `nil` to not include middleware.
]=]
type ServiceDef = {
	Name: string,
	Client: {[any]: any}?,
	Middleware: Middleware?,
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
	[any]: any,
}

-- internal
type ServiceTable = {
	Name: string
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
	@interface KnitOptions
	.Middleware Middleware?
	@within KnitServer

	- Middleware will apply to all services _except_ ones that define
	their own middleware.
]=]
type KnitOptions = {
	Middleware: Middleware?,
}

local defaultOptions: KnitOptions = {
	Middleware = nil,
}

local selectedOptions = nil

--[=[
	@class KnitServer
	@server
	Knit server-side lets developers create services and expose methods and signals
	to the clients.

	```lua
	local Knit = require(somewhere.Knit)

	-- Load service modules within some folder:
	Knit.AddServices(somewhere.Services)

	-- Start Knit:
	Knit.Start():andThen(function()
		print("Knit started")
	end):catch(warn)
	```
]=]
local KnitServer = {}

--[=[
	@prop Util Folder
	@within KnitServer
	@readonly
	References the Util folder. Should only be accessed when using Knit as
	a standalone module. If using Knit from Wally, modules should just be
	pulled in via Wally instead of relying on Knit's Util folder, as this
	folder only contains what is necessary for Knit to run in Wally mode.
]=]
KnitServer.Util = script.Parent.Parent

local SIGNAL_MARKER = newproxy(true)
getmetatable(SIGNAL_MARKER).__tostring = function()
	return "SIGNAL_MARKER"
end

local PROPERTY_MARKER = newproxy(true)
getmetatable(PROPERTY_MARKER).__tostring = function()
	return "PROPERTY_MARKER"
end

local knitRepServiceFolder = Instance.new("Folder")
knitRepServiceFolder.Name = "Services"

local Promise = require(KnitServer.Util.Promise)
local Comm = require(KnitServer.Util.Comm)
local ServerComm = Comm.ServerComm

local services: {[string]: Service} = {}
local serviceTables: {[string]: ServiceTable} = {}
local started = false
local startedComplete = false
local onStartedComplete = Instance.new("BindableEvent")


local function DoesServiceExist(serviceName: string): boolean
	local service: Service? = services[serviceName]
	return service ~= nil
end


--[=[
	Constructs a new service.

	:::caution
	Services must be created _before_ calling `Knit.Start()`.
	:::
	```lua
	-- Create a service
	local MyService = Knit.CreateService {
		Name = "MyService",
		Client = {},
	}

	-- Expose a ToAllCaps remote function to the clients
	function MyService.Client:ToAllCaps(player, msg)
		return msg:upper()
	end

	-- Knit will call KnitStart after all services have been initialized
	function MyService:KnitStart()
		print("MyService started")
	end

	-- Knit will call KnitInit when Knit is first started
	function MyService:KnitInit()
		print("MyService initialize")
	end
	```
]=]

local function GetServiceTable(name: string): ServiceTable
	local serviceTable: ServiceTable = serviceTables[name]
	if serviceTable then
		return serviceTable
	end
	
	serviceTable = {
		Name = name;
	}
	
	serviceTables[name] = serviceTable
	
	return serviceTable
end

local function GetServiceFromDef(serviceDef: ServiceDef): Service
	local service = GetServiceTable(serviceDef.Name)
	for k, v in pairs(serviceDef) do
		service[k] = v
	end
	
	service.KnitComm = ServerComm.new(knitRepServiceFolder, serviceDef.Name)
	if type(service.Client) ~= "table" then
		service.Client = {Server = service}
	else
		if service.Client.Server ~= service then
			service.Client.Server = service
		end
	end
	services[service.Name] = service
	
	return service
end

function KnitServer.CreateService(serviceDef: ServiceDef): Service
	assert(type(serviceDef) == "table", "Service must be a table; got " .. type(serviceDef))
	assert(type(serviceDef.Name) == "string", "Service.Name must be a string; got " .. type(serviceDef.Name))
	assert(#serviceDef.Name > 0, "Service.Name must be a non-empty string")
	assert(not DoesServiceExist(serviceDef.Name), "Service \"" .. serviceDef.Name .. "\" already exists")
	
	return GetServiceFromDef(serviceDef)
end


--[=[
	Requires all the modules that are children of the given parent. This is an easy
	way to quickly load all services that might be in a folder.
	```lua
	Knit.AddServices(somewhere.Services)
	```
]=]
function KnitServer.AddServices(parent: Instance): {Service}
	local addedServices = {}
	for _,v in ipairs(parent:GetChildren()) do
		if not v:IsA("ModuleScript") then continue end
		table.insert(addedServices, require(v))
	end
	return addedServices
end


--[=[
	Requires all the modules that are descendants of the given parent.
]=]
function KnitServer.AddServicesDeep(parent: Instance): {Service}
	local addedServices = {}
	for _,v in ipairs(parent:GetDescendants()) do
		if not v:IsA("ModuleScript") then continue end
		table.insert(addedServices, require(v))
	end
	return addedServices
end


--[=[
	Gets the service by name. Throws an error if the service is not found.
]=]
function KnitServer.GetService(serviceName: string): Service
	--assert(started, "Cannot call GetService until Knit has been started")
	assert(type(serviceName) == "string", "ServiceName must be a string; got " .. type(serviceName))
	return GetServiceTable(serviceName) :: Service
end


--[=[
	@return SIGNAL_MARKER
	Returns a marker that will transform the current key into
	a RemoteSignal once the service is created. Should only
	be called within the Client table of a service.

	See [RemoteSignal](https://sleitnick.github.io/RbxUtil/api/RemoteSignal)
	documentation for more info.
	```lua
	local MyService = Knit.CreateService {
		Name = "MyService",
		Client = {
			-- Create the signal marker, which will turn into a
			-- RemoteSignal when Knit.Start() is called:
			MySignal = Knit.CreateSignal(),
		},
	}

	function MyService:KnitInit()
		-- Connect to the signal:
		self.Client.MySignal:Connect(function(player, ...) end)
	end
	```
]=]
function KnitServer.CreateSignal()
	return SIGNAL_MARKER
end


--[=[
	@return PROPERTY_MARKER
	Returns a marker that will transform the current key into
	a RemoteProperty once the service is created. Should only
	be called within the Client table of a service. An initial
	value can be passed along as well.

	RemoteProperties are great for replicating data to all of
	the clients. Different data can also be set per client.

	See [RemoteProperty](https://sleitnick.github.io/RbxUtil/api/RemoteProperty)
	documentation for more info.

	```lua
	local MyService = Knit.CreateService {
		Name = "MyService",
		Client = {
			-- Create the property marker, which will turn into a
			-- RemoteProperty when Knit.Start() is called:
			MyProperty = Knit.CreateProperty("HelloWorld"),
		},
	}

	function MyService:KnitInit()
		-- Change the value of the property:
		self.Client.MyProperty:Set("HelloWorldAgain")
	end
	```
]=]
function KnitServer.CreateProperty(initialValue: any)
	return {PROPERTY_MARKER, initialValue}
end


--[=[
	@return Promise
	Starts Knit. Should only be called once.

	Optionally, `KnitOptions` can be passed in order to set
	Knit's custom configurations.

	:::caution
	Be sure that all services have been created _before_
	calling `Start`. Services cannot be added later.
	:::

	```lua
	Knit.Start():andThen(function()
		print("Knit started!")
	end):catch(warn)
	```
	
	Example of Knit started with options:
	```lua
	Knit.Start({
		Middleware = {
			Inbound = {
				function(player, args)
					print("Player is giving following args to server:", args)
					return true
				end
			},
		},
	}):andThen(function()
		print("Knit started!")
	end):catch(warn)
	```
]=]
function KnitServer.Start(options: KnitOptions?)

	if started then
		return Promise.reject("Knit already started")
	end

	started = true

	if options == nil then
		selectedOptions = defaultOptions
	else
		assert(typeof(options) == "table", "KnitOptions should be a table or nil; got " .. typeof(options))
		selectedOptions = options
		for k,v in pairs(defaultOptions) do
			if selectedOptions[k] == nil then
				selectedOptions[k] = v
			end
		end
	end
	
	for serviceName in pairs(serviceTables) do
		assert(services[serviceName] ~= nil, "Service "..serviceName.." is not defined")
	end

	return Promise.new(function(resolve)

		local knitMiddleware = selectedOptions.Middleware or {}

		-- Bind remotes:
		for _,service in pairs(services) do
			local middleware = service.Middleware or {}
			local inbound = middleware.Inbound or knitMiddleware.Inbound
			local outbound = middleware.Outbound or knitMiddleware.Outbound
			service.Middleware = nil
			for k,v in pairs(service.Client) do
				if type(v) == "function" then
					service.KnitComm:WrapMethod(service.Client, k, inbound, outbound)
				elseif v == SIGNAL_MARKER then
					service.Client[k] = service.KnitComm:CreateSignal(k, inbound, outbound)
				elseif type(v) == "table" and v[1] == PROPERTY_MARKER then
					service.Client[k] = service.KnitComm:CreateProperty(k, v[2], inbound, outbound)
				end
			end
		end

		-- Init:
		local promisesInitServices = {}
		for _,service in pairs(services) do
			if type(service.KnitInit) == "function" then
				table.insert(promisesInitServices, Promise.new(function(r)
					debug.setmemorycategory(service.Name)
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
				task.spawn(function()
					debug.setmemorycategory(service.Name)
					service:KnitStart()
				end)
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
