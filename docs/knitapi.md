---
sidebar_position: 7
---

# Knit API

## Knit

### `Knit.Services: [Service]`
[Server-side only]

A table that contains all created [services](#service).

```lua
local allServices = Knit.Services
for name,service in pairs(allServices) do
	print(name)
end
```

:::note
Within other services, this table should only be accessed during or after the `KnitInit` stage. While it is safe to reference other services at the `KnitInit` stage, it is _not_ safe to use them. Wait until the `KnitStart` stage to start using them (e.g. calling methods and events).
:::

### `Knit.Controllers: Controller[]`
[Client-side only]

A table that contains all created [controllers](#controller).

```lua
local allControllers = Knit.Controllers
for name,controller in pairs(allControllers) do
	print(name)
end
```

:::note
Within other controllers, this table should only be accessed during or after the `KnitInit` stage. While it is safe to reference other controllers at the `KnitInit` stage, it is _not_ safe to use them. Wait until the `KnitStart` stage to start using them (e.g. calling methods and events).
:::

### `Knit.Util: Folder`
A folder containing utility modules used by Knit, but also accessible for developers to use. They can be required like any other module:

```lua
local Signal = require(Knit.Util.Signal)
```

### `Knit.Start()` -> `Promise`

Start Knit. This returns a promise which resolves once all services or controllers are fully initialized and started. The usage of this is the same on the server and the client.

```lua
local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

----
-- Create services or controllers here
----

-- Start Knit:
Knit.Start():andThen(function()
	print("Knit is running")
end):catch(function(err)
	warn(err)
end)
```

Alternative ways to start Knit:

```lua
-- Use 'Await' to wait for Knit to start and capture any errors:
local success, err = Knit.Start():await()
if (not success) then
	warn(err)
end
```
```lua
-- Feed the 'warn' built-in function directly to the Catch of the returned promise:
Knit.Start():catch(warn)
```
```lua
-- Same as above, but also yield until Knit has started.
-- Just note that the 'Catch' will eat up the error, so Await will return successfully even if an error occurs.
Knit.Start():catch(warn):await()
```

It is important that errors are handled when starting Catch, as any errors within the Init lifecycle will go undetected otherwise.

### `Knit.OnStart()` -> `Promise`

Wait for Knit to start. This is useful if there are other scripts that need to access Knit services or controllers. If Knit is already started, it resolves the promise immediately.

```lua
-- Wait for Knit to be started:
Knit.OnStart():await()
```

### `Knit.CreateService(service: ServiceDefinition)` -> `Service`
[Server-side only]

Creates a new [service](#service). Returns the service. Please see the [Services](services.md) documentation for more info.

The provided `service` table must contain a unique `Name` property. It can optionally contain a `Client` table as well. If the `Client` table isn't provided, Knit will automatically create one for the service.

```lua
local MyService = Knit.CreateService { Name = "MyService", Client = {} }
```

### `Knit.AddServices(folder: Instance)`
[Server-side only]

Automatically creates new [services](#service) from ModuleScripts found directly within `folder`.

```lua
Knit.AddServices(serverStorage.MyServices)
```

### `Knit.AddServicesDeep(folder: Instance)`
[Server-side only]

Works the same as `Knit.AddServices`, but scans all descendants of `folder`. This is useful if services are organized into sub-folders.

However, this should be used sparingly, since it will try to load _any_ ModuleScript descendant as a service. If your services might have non-service modules nested in the descendant hierarchy, use a series of `Knit.AddServices` instead.

```lua
Knit.AddServicesDeep(serverStorage.MyServices)
```

### `Knit.CreateController(controller: ControllerDefinition)` -> `Controller`
[Client-side only]

Creates a new [controller](#controller). Returns the controller. Please see the [Controllers](controllers.md) documentation for more info.

The provided `controller` table must contain a unique `Name` property.

```lua
local MyController = Knit.CreateController { Name = "MyController" }
```

### `Knit.AddControllers(folder: Instance)`
[Client-side only]

Automatically creates new [controllers](#controller) from ModuleScripts found directly within `folder`.

```lua
Knit.AddControllers(replicatedStorage.MyControllers)
```

### `Knit.AddControllersDeep(folder: Instance)`
[Client-side only]

Works the same as `Knit.AddControllers`, but scans all descendants of `folder`. This is useful if controllers are organized into sub-folders.

However, this should be used sparingly, since it will try to load _any_ ModuleScript descendant as a controller. If your controllers might have non-controller modules nested in the descendant hierarchy, use a series of `Knit.AddControllers` instead.

```lua
Knit.AddControllersDeep(replicatedStorage.MyControllers)
```

### `Knit.GetService(serviceName: string)` -> `ServiceMirror`

Returns a [ServiceMirror](#servicemirror) table object representing the service. Service methods and events that have been exposed to the client can be used from this returned object.

```lua
local SomeService = Knit.GetService("SomeService")
SomeService:DoSomething()
```

Every method will also have a "Promisefied" version. Just append "Promise" to the name of the event:

```lua
local SomeService = Knit.GetService("SomeService")
SomeService:DoSomethingPromise():andThen(function() ... end)
```

### `Knit.GetController(controllerName: string)` -> Controller
[Client-side only]

Returns a [controller](#controller) with the given controller name. This is just an alias for `Knit.Controllers[controllerName]` and only exists for developers who want to have the same pattern used with `Knit.GetService`.

--------------

## Service

A service is a singleton object that serves a specific purpose on the server.

### `Service.Name: string`

The name of the service.

### `Service.Client: ServiceClient`

A [ServiceClient](#serviceclient) table that contains client-exposed methods and events.

### `Service:KnitInit()` -> `void`

An optional method that is called during the KnitInit lifecycle stage (see [Execution Model](executionmodel.md) for more info).

### `Service:KnitStart()` -> `void`

An optional method that is called during the KnitStart lifecycle stage (see [Execution Model](executionmodel.md) for more info).

### `Service.CUSTOM_FIELD: any`
### `Service:CUSTOM_METHOD(...)` -> `any`
### `Service.CUSTOM_EVENT:Fire(...)` -> `void`

--------------

## ServiceClient

Refers to the the Client table within a [service](#service).

### `ServiceClient.Server: Service`

A reference back to the top-level [service](#service).

### `ServiceClient:CUSTOM_METHOD(player: Player, ...)` -> `any`
### `ServiceClient.CUSTOM_EVENT:Fire(player: Player, ...)` -> `void`
### `ServiceClient.CUSTOM_EVENT:FireAll(...)` -> `void`
### `ServiceClient.CUSTOM_EVENT:FireExcept(player: Player, ...)` -> `void`

--------------

## Controller

A controller is a singleton object that serves a specific purpose on the client.

### `Controller.Name: string`

The name of the controller.

### `Controller:KnitInit()` -> `void`

An optional method that is called during the KnitInit lifecycle stage (see [Execution Model](executionmodel.md) for more info).

### `Controller:KnitStart()` -> `void`

An optional method that is called during the KnitStart lifecycle stage (see [Execution Model](executionmodel.md) for more info).

### `Controller.CUSTOM_FIELD: any`
### `Controller:CUSTOM_METHOD(...)` -> `any`
### `Controller.CUSTOM_EVENT:Fire(...)` -> `void`

--------------

## ServiceMirror

A table that mirrors the methods and events that were exposed on the server via the [Client](#serviceclient) table.

### `ServiceMirror:CUSTOM_METHOD(...)` -> `any`
### `ServiceMirror:CUSTOM_METHODPromise(...)` -> `Promise`
### `ServiceMirror.CUSTOM_EVENT:Fire(...)` -> `void`
### `ServiceMirror.CUSTOM_EVENT:Connect(function(...) end)` -> `void`
