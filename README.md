# Knit

![Knit](logo/logo_256.png)

**[Under Development]**

Simple game framework for the Roblox game engine.

-------------------

Knit gives developers the tools to create services/controllers on the server and client. These services and controllers can talk to each other seamlessly. It is up to the developer to create the runtime.

## Using Knit

To use Knit, both the server and the client will look like this:

```lua
-- Load core module:
local Knit = require(game:GetService("ReplicatedStorage").Knit)

----
-- Load services or controllers here
----

-- Start Knit:
Knit.Start():andThen(function()
	print("Knit running")
end)
```

### Server Service

Services are server-side singletons that perform specific tasks. For instance, a game might have a MoneyService, which handles in-game currency for the players.

Typically, services (and controllers) each exist within their own ModuleScript. The core Script or LocalScript that starts Knit should require these modules to load them in.

Here's a Service in its simplest form:

```lua
local Knit = require(game:GetService("ReplicatedStorage").Knit)

local MoneyService = Knit.CreateService {
	Name = "MoneyService";
}

return MoneyService
```

At the core, services are nothing more than simple tables. Developers can add methods and events. There are a few methods and properties that are specific to Knit, but those will be explained later.

### Client Controller

Controllers are client-side singletons that perform specific tasks. They are very similar to services, except they run on the client. Controllers can perform client tasks _and/or_ communicate with a server-side service.

Here's a Controller in its simplest form:

```lua
local Knit = require(game:GetService("ReplicatedStorage").Knit)

local MoneyController = Knit.CreateController {
	Name = "MoneyController";
}

return MoneyController
```

## API

### `Knit.Services`
[Server-side only]

A table of all currently-created services.

This should not be accessed before starting Knit. Within a service, it is safe to reference other services as soon as its `KnitInit` method fires, but those services should not be utilized until its `KnitStart` method fires.

----------

### `Knit.Controllers`
[Client-side only]

A table of all currently-created controllers.

This should not be accessed before starting Knit. Within a controller, it is safe to reference other controllers as soon as its `KnitInit` method fires, but those controllers should not be utilized until its `KnitStart` method fires.

----------

### `Knit.CreateService(service)`
[Server-side only]

Creates a new service. The `service` argument must be a table with a `Name` key, which defines a unique name for the service. There cannot be more than one service with the same name.

```lua
-- Plain service:
local MyService = Knit.CreateService { Name = "MyService" }

-- With events:
local Event = require(Knit.Util.Event)
local MyService = Knit.CreateService {
	Name = "MyService";
	CustomEvent = Event.new();
	Client = {
		ClientExposedEvent = Event.new();
	}
}
```

----------

### `Knit.CreateController(controller)`
[Client-side only]

Creates a new controller. The `controller` argument must be a table with a `Name` key, which defines a unique name for the controller. There cannot be more than one controller with the same name.

```lua
-- Plain controller:
local MyController = Knit.CreateController { Name = "MyController" }

-- With events:
local Event = require(Knit.Util.Event)
local MyController = Knit.CreateController {
	Name = "MyController";
	CustomEvent = Event.new();
}
```

----------

### `Knit.GetService(serviceName)`
[Client-side only]

Gets a representation of a server-side service that contains the exposed remote functions and events.

```lua
local MyService = Knit.GetService("MyService")
MyService:DoSomething()
MyService.SomeEvent:Fire("Some data")
MyService.AnotherEvent:Connect(function(data) end)
```

----------

### `Knit.Start()`
Starts all the services or controllers (depending if this is called from the server or client). Returns a Promise which will resolve once all services or controllers are set up and running.

```lua
-- Different ways of starting Knit:
Knit.Start()
Knit.Start():await()
Knit.Start():andThen(function() end)
```

## Server-client Functions

A common necessity is for the client to invoke the server to process or get information. Knit makes this easy. Below is an example of a service and controller creating a simple communication process:

```lua
-- Server service
local MathService = Knit.CreateService {
	Name = "MathService";
}

function MathService.Client:AddNumbers(player, n1, n2)
	return n1 + n2
end
```

```lua
-- Client controller
local MathController = Knit.CreateController {
	Name = "MathController";
}

function MathController:KnitStart()
	-- Get the MathService and call the AddNumbers function:
	local MathService = Knit.GetService("MathService")
	local sum = MathService:AddNumbers(10, 20)
	print("10 + 20 = " .. tostring(sum))
end
```

Under the hood, Knit has automatically created a RemoteFunction bound to AddNumbers on the service. The controller then grabs a representation of the service, which wraps the RemoteFunction.

By design, the server cannot invoke client-side functions. Server-to-client function invocation is considered bad practice.

## Server-client Events

If data doesn't need to be returned, then using an event is better than using a function, because it will not yield. Creating events that can communicate both directions (server-to-client and client-to-server) is very easy.

Here's an example of sending data one way from the server to the client:

```lua
-- Server service
local Event = require(Knit.Util.Event)
local MyService = Knit.CreateService {
	Name = "MyService";
	Client = {
		SomeEvent = Event.new();
	}
}

function MyService:KnitStart()
	wait(10)
	self.Client.SomeEvent:FireAll("Hello world")
	-- Server-to-client events have the following fire methods:
	--   FireAll(...) [Fire all clients]
	--   Fire(player, ...) [Fire individual client]
	--   FireExcept(player, ...) [Fire all clients, except for the given client]
end
```

```lua
-- Client controller
local Event = require(Knit.Util.Event)
local MyController = Knit.CreateController {
	Name = "MyController";
}

function MyController:KnitStart()
	-- Connect to remote event:
	local MyService = Knit.GetService("MyService")
	MyService.SomeEvent:Connect(function(msg)
		print("Received message from MyService:", msg)
	end)
end
```

The client can also invoke the server:
```lua
-- Server service
function MyService:KnitStart()
	-- Listen for the client to send data:
	self.Client.SomeEvent:Connect(function(player, msg)
		print("Got message from player " .. player.Name .. ":", msg)
	end)
end
```

```lua
-- Client controller
function MyController:KnitStart()
	-- Fire event on service:
	local MyService = Knit.GetService("MyService")
	MyService.SomeEvent:Fire("Hello server, from the client!")
end
```