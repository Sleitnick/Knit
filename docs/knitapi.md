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

!!! note
	Within other services, this table should only be accessed during or after the `KnitInit` stage. While it is safe to reference other services at the `KnitInit` stage, it is _not_ safe to use them. Wait until the `KnitStart` stage to start using them (e.g. calling methods and events).

### `Knit.Controllers: [Controller]`
[Client-side only]

A table that contains all created [controllers](#controller).

```lua
local allControllers = Knit.Controllers
for name,controller in pairs(allControllers) do
	print(name)
end
```

!!! note
	Within other controllers, this table should only be accessed during or after the `KnitInit` stage. While it is safe to reference other controllers at the `KnitInit` stage, it is _not_ safe to use them. Wait until the `KnitStart` stage to start using them (e.g. calling methods and events).


### `Knit.Util: Folder`
A folder containing utility modules used by Knit, but also accessible for developers to use.

This folder contains the following modules:

- Maid
- Event
- Promise
- Thread

They can be required like any other module:

```lua
local Signal = require(Knit.Util.Signal)
```

### `Knit.Start()` -> `Promise`

Start Knit. This returns a promise which resolves once all services or controllers are fully initialized and started. The usage of this is the same on the server and the client.

```lua
local Knit = require(game:GetService("ReplicatedStorage").Knit)

----
-- Create services or controllers here
----

-- Start Knit:
Knit.Start():andThen(function()
	print("Knit is running")
end)
```

### `Knit.OnStart()` -> `Promise`

Wait for Knit to start. This is useful if there are other scripts that need to access Knit services or controllers. If Knit is already started, it resolves the promise immediately.

```lua
-- Wait for Knit to be started:
Knit.OnStart():await()
```

### `Knit.CreateService(service: Table)` -> `Service`
[Server-side only]

Creates a new [service](#service). Returns the service. Please see the [Services](services.md) documentation for more info.

The provided `service` table must contain a unique `Name` property. It can optionally contain a `Client` table as well. If the `Client` table isn't provided, Knit will automatically create one for the service.

```lua
local MyService = Knit.CreateService { Name = "MyService", Client = {} }
```

### `Knit.CreateController(controller: Table)` -> `Controller`
[Client-side only]

Creates a new [controller](#controller). Returns the controller. Please see the [Controllers](controllers.md) documentation for more info.

The provided `controller` table must contain a unique `Name` property.

```lua
local MyController = Knit.CreateController { Name = "MyController" }
```

### `Knit.GetService(serviceName: String)` -> `ServiceMirror`
[Client-side only]

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

--------------

## Service

A service is a singleton object that serves a specific purpose on the server.

### `Service.Name: String`

The name of the service.

### `Service.Client: ServiceClient`

A [ServiceClient](#serviceclient) table that contains client-exposed methods and events.

### `Service:KnitInit()` -> `Void`

An optional method that is called during the KnitInit lifecycle stage (see [Execution Model](executionmodel.md) for more info).

### `Service:KnitStart()` -> `Void`

An optional method that is called during the KnitStart lifecycle stage (see [Execution Model](executionmodel.md) for more info).

### `Service.CUSTOM_FIELD: Any`
### `Service:CUSTOM_METHOD(...)` -> `Any`
### `Service.CUSTOM_EVENT:Fire(...)` -> `Void`

--------------

## ServiceClient

Refers to the the Client table within a [service](#service).

### `ServiceClient.Server: Service`

A reference back to the top-level [service](#service).

### `ServiceClient:CUSTOM_METHOD(player, ...)` -> `Any`
### `ServiceClient.CUSTOM_EVENT:Fire(player, ...)` -> `Void`
### `ServiceClient.CUSTOM_EVENT:FireAll(...)` -> `Void`
### `ServiceClient.CUSTOM_EVENT:FireExcept(player, ...)` -> `Void`

--------------

## Controller

A controller is a singleton object that serves a specific purpose on the client.

### `Controller.Name: String`

The name of the controller.

### `Controller:KnitInit()` -> `Void`

An optional method that is called during the KnitInit lifecycle stage (see [Execution Model](executionmodel.md) for more info).

### `Controller:KnitStart()` -> `Void`

An optional method that is called during the KnitStart lifecycle stage (see [Execution Model](executionmodel.md) for more info).

### `Controller.CUSTOM_FIELD: Any`
### `Controller:CUSTOM_METHOD(...)` -> `Any`
### `Controller.CUSTOM_EVENT:Fire(...)` -> `Void`

--------------

## ServiceMirror

A table that mirrors the methods and events that were exposed on the server via the [Client](#serviceclient) table.

### `ServiceMirror:CUSTOM_METHOD(...)` -> `Any`
### `ServiceMirror:CUSTOM_METHODPromise(...)` -> `Promise`
### `ServiceMirror.CUSTOM_EVENT:Fire(...)` -> `Void`
### `ServiceMirror.CUSTOM_EVENT:Connect(function(...) end)` -> `Void`