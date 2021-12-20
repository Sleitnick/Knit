--[=[
	@interface ControllerDef
	.Name string
	.[any] any
	@within KnitClient
]=]
type ControllerDef = {
	Name: string,
	[any]: any,
}

--[=[
	@interface Controller
	.Name string
	.[any] any
	@within KnitClient
]=]
type Controller = {
	Name: string,
	[any]: any,
}

--[=[
	@interface Service
	.[any] any
	@within KnitClient
]=]
type Service = {
	[any]: any,
}

--[=[
	@type ClientMiddlewareFn (args: {any}) -> (shouldContinue: boolean, ...: any)
	@within KnitClient

	For more info, see [ClientComm](https://sleitnick.github.io/RbxUtil/api/ClientComm/) documentation.
]=]

--[=[
	@interface KnitOptions
	.ServicePromises boolean?
	.InboundMiddleware ClientMiddlewareFn?
	.OutboundMiddleware ClientMiddlewareFn?
	@within KnitClient

	- `ServicePromises` defaults to `true` and indicates if service methods use promises.
	- `InboundMiddleware` and `OutboundMiddleware` default to `nil`.
]=]
type KnitOptions = {
	ServicePromises: boolean,
	InboundMiddleware: {(...any) -> (boolean, ...any)}?,
	OutboundMiddleware: {(...any) -> (boolean, ...any)}?,
}

local defaultOptions: KnitOptions = {
	ServicePromises = true;
	InboundMiddleware = nil;
	OutboundMiddleware = nil;
}

local selectedOptions = nil


--[=[
	@class KnitClient
	@client
]=]
local KnitClient = {}

--[=[
	@prop Player Player
	@within KnitClient
	@readonly
	Reference to the LocalPlayer.
]=]
KnitClient.Player = game:GetService("Players").LocalPlayer

--[=[
	@prop Util Folder
	@within KnitClient
	@readonly
	References the Util folder. Should only be accessed when using Knit as
	a standalone module. If using Knit from Wally, modules should just be
	pulled in via Wally instead of relying on Knit's Util folder, as this
	folder only contains what is necessary for Knit to run in Wally mode.
]=]
KnitClient.Util = script.Parent.Parent

local Promise = require(KnitClient.Util.Promise)
local Comm = require(KnitClient.Util.Comm)
local ClientComm = Comm.ClientComm

local controllers: {[string]: Controller} = {}
local services: {[string]: Service} = {}
local servicesFolder = nil

local started = false
local startedComplete = false
local onStartedComplete = Instance.new("BindableEvent")


local function BuildService(serviceName: string, folder: Instance): Service
	local service = ClientComm.new(folder, selectedOptions.ServicePromises):BuildObject(selectedOptions.InboundMiddleware, selectedOptions.OutboundMiddleware)
	services[serviceName] = service
	return service
end


local function DoesControllerExist(controllerName: string): boolean
	local controller: Controller? = controllers[controllerName]
	return controller ~= nil
end


local function GetServicesFolder()
	if not servicesFolder then
		servicesFolder = script.Parent:WaitForChild("Services")
	end
	return servicesFolder
end


--[=[
	@param controllerDefinition ControllerDef
	@return Controller
	Creates a new controller.
]=]
function KnitClient.CreateController(controllerDef: ControllerDef): Controller
	assert(type(controllerDef) == "table", "Controller must be a table; got " .. type(controllerDef))
	assert(type(controllerDef.Name) == "string", "Controller.Name must be a string; got " .. type(controllerDef.Name))
	assert(#controllerDef.Name > 0, "Controller.Name must be a non-empty string")
	assert(not DoesControllerExist(controllerDef.Name), "Controller \"" .. controllerDef.Name .. "\" already exists")
	local controller = controllerDef :: Controller
	controllers[controller.Name] = controller
	return controller
end


--[=[
	@param parent Instance
	@return controllers: {Controller}
	Requires all the modules that are children of the given parent. This is an easy
	way to quickly load all controllers that might be in a folder.
	```lua
	Knit.AddControllers(somewhere.Controllers)
	```
]=]
function KnitClient.AddControllers(parent: Instance): {Controller}
	local addedControllers = {}
	for _,v in ipairs(parent:GetChildren()) do
		if not v:IsA("ModuleScript") then continue end
		table.insert(addedControllers, require(v))
	end
	return addedControllers
end


--[=[
	@param parent Instance
	@return controllers: {Controller}
	Requires all the modules that are descendants of the given parent.
]=]
function KnitClient.AddControllersDeep(parent: Instance): {any}
	local addedControllers = {}
	for _,v in ipairs(parent:GetDescendants()) do
		if not v:IsA("ModuleScript") then continue end
		table.insert(addedControllers, require(v))
	end
	return addedControllers
end


--[=[
	@param serviceName string
	@return Service?
	Returns a Service object which is a reflection of the remote objects
	within the Client table of the given service. Returns `nil` if the
	service is not found.

	If a service's Client table contains RemoteSignals and/or RemoteProperties,
	these values are reflected as
	[ClientRemoteSignals](https://sleitnick.github.io/RbxUtil/api/ClientRemoteSignal) and
	[ClientRemoteProperties](https://sleitnick.github.io/RbxUtil/api/ClientRemoteProperty).

	```lua
	-- Server-side service creation:
	local MyService = Knit.CreateService {
		Name = "MyService";
		Client = {
			MySignal = Knit.CreateSignal();
			MyProperty = Knit.CreateProperty("Hello");
		};
	}
	function MyService:AddOne(player, number)
		return number + 1
	end

	-------------------------------------------------

	-- Client-side service reflection:
	local MyService = Knit.GetService("MyService")

	-- Call a method:
	local num = MyService:AddOne(5) --> 6

	-- Fire a signal to the server:
	MyService.MySignal:Fire("Hello")

	-- Listen for signals from the server:
	MyService.MySignal:Connect(function(message)
		print(message)
	end)

	-- Observe the initial value and changes to properties:
	MyService.MyProperty:Observe(function(value)
		print(value)
	end)
	```

	:::caution
	Services are only exposed to the client if the service has remote-based
	content in the Client table. If not, the service will not be visible
	to the client. `KnitClient.GetService` will only work on services that
	expose remote-based content on their Client tables.
	:::
]=]
function KnitClient.GetService(serviceName: string): Service
	assert(started, "Cannot call GetService until Knit has been started")
	assert(type(serviceName) == "string", "ServiceName must be a string; got " .. type(serviceName))
	local folder: Instance? = GetServicesFolder():FindFirstChild(serviceName)
	assert(folder ~= nil, "Could not find service \"" .. serviceName .. "\". Check the service name and that the service has client-facing methods/RemoteSignals/RemoteProperties.")
	return services[serviceName] or BuildService(serviceName, folder :: Instance)
end


--[=[
	@param controllerName string
	@return Controller?
	Gets the controller by name. Throws an error if the controller
	is not found.
]=]
function KnitClient.GetController(controllerName: string): Controller
	assert(started, "Cannot call GetController until Knit has been started")
	assert(type(controllerName) == "string", "ControllerName must be a string; got " .. type(controllerName))
	local controller = controllers[controllerName]
	assert(controller ~= nil, " Could not find controller \"" .. controllerName .. "\". Check to verify a controller with this name exists.")
	return controller
end


--[=[
	@param options KnitOptions?
	@return Promise
	Starts Knit. Should only be called once per client.
	```lua
	Knit.Start():andThen(function()
		print("Knit started!")
	end):catch(warn)
	```

	By default, service methods exposed to the client will return promises.
	To change this behavior, set the `ServicePromises` option to `false`:
	```lua
	Knit.Start({ServicePromises = false}):andThen(function()
		print("Knit started!")
	end):catch(warn)
	```
]=]
function KnitClient.Start(options: KnitOptions?)

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

	return Promise.new(function(resolve)

		-- Init:
		local promisesStartControllers = {}
		for _,controller in pairs(controllers) do
			if type(controller.KnitInit) == "function" then
				table.insert(promisesStartControllers, Promise.new(function(r)
					controller:KnitInit()
					r()
				end))
			end
		end

		resolve(Promise.all(promisesStartControllers))

	end):andThen(function()

		-- Start:
		for _,controller in pairs(controllers) do
			if type(controller.KnitStart) == "function" then
				task.spawn(controller.KnitStart, controller)
			end
		end

		startedComplete = true
		onStartedComplete:Fire()

		task.defer(function()
			onStartedComplete:Destroy()
		end)

	end)

end


--[=[
	@return Promise
	Returns a promise that is resolved once Knit has started. This is useful
	for any code that needs to tie into Knit controllers but is not the script
	that called `Start`.
	```lua
	Knit.OnStart():andThen(function()
		local MyController = Knit.GetController("MyController")
		MyController:DoSomething()
	end):catch(warn)
	```
]=]
function KnitClient.OnStart()
	if startedComplete then
		return Promise.resolve()
	else
		return Promise.fromEvent(onStartedComplete.Event)
	end
end


return KnitClient
