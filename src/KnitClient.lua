--!strict

--[[

	Knit.CreateController(controller): Controller
	Knit.AddControllers(folder): Controller[]
	Knit.AddControllersDeep(folder): Controller[]
	Knit.GetService(serviceName): Service
	Knit.GetController(controllerName): Controller
	Knit.Start(): Promise<void>
	Knit.OnStart(): Promise<void>

--]]


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
	@class KnitClient
	@client
]=]
local KnitClient = {}

--[=[
	@prop Player Player
	@within KnitClient
	Reference to the LocalPlayer
]=]
KnitClient.Player = game:GetService("Players").LocalPlayer

--[=[
	@prop Controllers {[string]: Controller}
	@within KnitClient
]=]
KnitClient.Controllers = {} :: {[string]: Controller}

--[=[
	@prop Util Folder
	@within KnitClient
]=]
KnitClient.Util = script.Parent.Parent

local Promise = require(KnitClient.Util.Promise)
local Loader = require(KnitClient.Util.Loader)
local Ser = require(KnitClient.Util.Ser)
local ClientRemoteSignal = require(KnitClient.Util.Remote).ClientRemoteSignal
local ClientRemoteProperty = require(KnitClient.Util.Remote).ClientRemoteProperty
local TableUtil = require(KnitClient.Util.TableUtil)

local services: {[string]: Service} = {}
local servicesFolder = script.Parent:WaitForChild("Services")

local started = false
local startedComplete = false
local onStartedComplete = Instance.new("BindableEvent")


local function BuildService(serviceName: string, folder: Instance): Service
	local service = {}
	local rfFolder = folder:FindFirstChild("RF")
	local reFolder = folder:FindFirstChild("RE")
	local rpFolder = folder:FindFirstChild("RP")
	if rfFolder then
		for _,rf in ipairs(rfFolder:GetChildren()) do
			if rf:IsA("RemoteFunction") then
				local function StandardRemote(_self, ...)
					return Ser.DeserializeArgsAndUnpack(rf:InvokeServer(Ser.SerializeArgsAndUnpack(...)))
				end
				local function PromiseRemote(_self, ...)
					local args = Ser.SerializeArgs(...)
					return Promise.new(function(resolve)
						resolve(Ser.DeserializeArgsAndUnpack(rf:InvokeServer(table.unpack(args, 1, args.n))))
					end)
				end
				service[rf.Name] = StandardRemote
				service[rf.Name .. "Promise"] = PromiseRemote
			end
		end
	end
	if reFolder then
		for _,re in ipairs(reFolder:GetChildren()) do
			if re:IsA("RemoteEvent") then
				service[re.Name] = ClientRemoteSignal.new(re)
			end
		end
	end
	if rpFolder then
		for _,rp in ipairs(rpFolder:GetChildren()) do
			if rp:IsA("ValueBase") or rp:IsA("RemoteEvent") then
				service[rp.Name] = ClientRemoteProperty.new(rp)
			end
		end
	end
	services[serviceName] = service
	return service
end


local function DoesControllerExist(controllerName: string): boolean
	local controller: Controller? = KnitClient.Controllers[controllerName]
	return controller ~= nil
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
	local controller: Controller = TableUtil.Assign(controllerDef, {
		_knit_is_controller = true;
	})
	KnitClient.Controllers[controller.Name] = controller
	return controller
end


--[=[
	@param parent Instance
	@return {any}
	Requires all the modules that are children of the given parent. This is an easy
	way to quickly load all controllers that might be in a folder.
	```lua
	Knit.AddControllers(somewhere.Controllers)
	```
]=]
function KnitClient.AddControllers(parent: Instance): {any}
	return Loader.LoadChildren(parent)
end


--[=[
	@param parent Instance
	@return {any}
	Requires all the modules that are descendants of the given parent.
]=]
function KnitClient.AddControllersDeep(parent: Instance): {any}
	return Loader.LoadDescendants(parent)
end


--[=[
	@param serviceName string
	@return Service?
	Returns a Service object which is a reflection of the remote objects
	within the Client table of the given service. Returns `nil` if the
	service is not found.

	:::caution
	Services are only exposed to the client if the service has remote-based
	content in the Client table. If not, the service will not be visible
	to the client. `KnitClient.GetService` will only work on services that
	expose remote-based content on their Client tables.
	:::
]=]
function KnitClient.GetService(serviceName: string): Service
	assert(type(serviceName) == "string", "ServiceName must be a string; got " .. type(serviceName))
	local folder: Instance? = servicesFolder:FindFirstChild(serviceName)
	assert(folder ~= nil, "Could not find service \"" .. serviceName .. "\"")
	return services[serviceName] or BuildService(serviceName, folder :: Instance)
end


--[=[
	@param controllerName string
	@return Controller?
	Gets the controller by name. Returns `nil` if not found. This is just
	an alias for `KnitControllers.Controllers[controllerName]`.
]=]
function KnitClient.GetController(controllerName: string): Controller?
	return KnitClient.Controllers[controllerName]
end


--[=[
	Starts Knit.
	```lua
	Knit.Start():andThen(function()
		print("Knit started!")
	end):catch(warn)
	```
]=]
function KnitClient.Start()

	if started then
		return Promise.reject("Knit already started")
	end

	started = true

	local controllers = KnitClient.Controllers

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
		local MyController = Knit.Controllers.MyController
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
