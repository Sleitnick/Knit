## Services Defined

Services are singleton objects that serve a specific purpose on the server. For instance, a game might have a PointsService, which manages in-game points for the players.

A game might have many services. They will serve as the backbone of a game.

For the sake of example, we will slowly develop PointsService to show how a service is constructed. For full API documentation, visit the [Knit API](knitapi.md#service) page.

## Creating Services

In its simplest form, a service can be created like so:

```lua
local PointsService = Knit.CreateService { Name = "PointsService", Client = {} }

return PointsService
```

!!! note "Client table otional"
	The `Client` table is optional for the constructor. However, it will be added by Knit if left out. For the sake of code clarity, it is recommended to keep it in the constructor as shown above.

The `Name` field is required. This name is how code outside of your service will find it. This name must be unique from all other services. It is best practice to name your variable the same as the service name (e.g. `local PointsService` matches `Name = "PointsService"`).

The last line (`return PointsService`) assumes this code is written in a ModuleScript, which is best practice for containing services.

## Adding methods

Services are just simple tables at the end of the day. As such, it is very easy to add methods to services.

```lua
function PointsService:AddPoints(player, amount)
	-- TODO: add points
end

function PointsService:GetPoints(player)
	return 0
end
```

## Adding properties

Again, services are just tables. So we can simply add in properties as we want. In our above method, we are returning `0` for `GetPoints()` because we have nowhere to store/retreive points. Likewise, our `AddPoints()` method can't do anything. Let's change that. Let's create a property that holds a table of points per player:

```lua
PointsService.PointsPerPlayer = {}
```

## Using methods and properties

Now we can change our `AddPoints()` and `GetPoints()` methods to use this field.

```lua
PointsService.PointsPerPlayer = {}

function PointsService:AddPoints(player, amount)
	local points = self:GetPoints(player) -- Current amount of points
	points = points + amount              -- Add points
	self.PointsPerPlayer[player] = points -- Store points
end

function PointsService:GetPoints(player)
	local points = self.PointsPerPlayer[player]
	return points or 0 -- Return 0 if no points found for player
end
```

## Using events

What if we want to fire an event when the amount of points changes? This is easy. We can assign an event named `PointsChanged` as a property of our service, and have our `AddPoints()` method fire the event:

```lua
-- Load the Signal module and create PointsChanged signal:
local Signal = require(Knit.Util.Signal)
PointsService.PointsChanged = Signal.new()

-- Modify AddPoints:
function PointsService:AddPoints(player, amount)
	local points = self:GetPoints(player)
	points = points + amount
	self.PointsPerPlayer[player] = points
	-- Fire event signal, as long as we actually changed the points:
	if (amount ~= 0) then
		self.PointsChanged:Fire(player, points)
	end
end
```

Another service could then listen for the changes on that event:

```lua
function SomeOtherService:KnitStart()
	local PointsService = Knit.Services.PointsService
	PointsService.PointsChanged:Connect(function(player, points)
		print("Points changed for " .. player.Name .. ":", points)
	end)
end
```

## KnitInit and KnitStart

In that last code snippet, there's an odd `KnitStart()` method. This is part of the Knit lifecycle (read more under [execution model](executionmodel.md)). These methods are optional, but very useful for orchestrating communication between other services.

When a service is first created, it is not guaranteed that other services are also created and ready to be used. The `KnitInit` and `KnitStart` methods come to save the day! After all services are created and the `Knit.Start()` method is fired, the `KnitInit` methods of all services will be fired.

From the `KnitInit` method, we can guarantee that all other services have been created. However, we still cannot guarantee that those services are ready to be consumed. Therefore, we can _reference_ them within the `Init` step, but we should never _use_ them (e.g. use the methods or events attached to those other services).

After all `KnitInit` methods have finished, all `KnitStart` methods are then fired. At this point, we can guarantee that all `KnitInits` are done, and thus can freely access other services.

In order to maintain this pattern, be sure to set up you service in the `Init` method (or earlier; just in the ModuleScript itself). By the time `KnitStart` methods are being fired, your services should be available for use.

## Cleaning Up Unused Memory

Alright, back to our PointsService! We have a problem... We have created a [memory leak](https://en.wikipedia.org/wiki/Memory_leak)! When we add points for a player, we add the player to the table. What happens when the player leaves? Nothing! And that's a problem. That player's data is forever held onto within that `PointsPerPlayer` table. To fix this, we need to clear out that data when the player leaves. We can use the `KnitInit` method to hook up to the `Players.PlayerRemoving` event and remove the data:

```lua
function PointsService:KnitInit()
	game:GetService("Players").PlayerRemoving:Connect(function(player)
		-- Clear out the data for hte player when the player leaves:
		self.PointsPerPlayer[player] = nil
	end)
end
```

While memory management is not unique to Knit, it is still an important aspect to consider when making your game. Even a garbage-collected language like Lua can have memory leaks introduced by the developer.

## Client Communication

Alright, so we can store and add points on the server for a player. But who cares? Players have no visibility to these points at the moment. We need to open a line of communication between our service and the clients (AKA players). This functionality is so fundamental to Knit, that it's where the name came from: The need to _knit_ together communication.

This is where we are going to use that `Client` table defined at the beginning.

### Methods

Let's say that we want to create a method that lets players fetch how many points they have, and when their points change. First, let's make a method to fetch points:

```lua
function PointsService.Client:GetPoints(player)
	-- We can just call our other method from here:
	return self.Server:GetPoints(player)
end
```

This creates a client-exposed method called `GetPoints`. Within it, we reach back to our top-level service using `self.Server` and then invoke our other `GetPoints` method that we wrote before. In this example, we've basically just created a proxy for another method; however, this will not always be the case. There will be many times where a client method will exist alone without an equivalent server-side-only method.

Under the hood, Knit will create a RemoteFunction and bind this method to it.

On the client, we could then invoke the service as such:

```lua
-- From a LocalScript
local Knit = require(game:GetService("ReplicatedStorage").Knit)

local PointsService = Knit.GetService("PointsService")
local points = PointsService:GetPoints()

print("Points for myself:", points)
```

### Events (Server-to-Client)

We should also create an event that we can fire for the clients when their points change. We can use the RemoteEvent module (`Knit.Util.Remote.RemoteEvent`), and just put one within the `Client` table:

```lua
PointsService.Client.PointsChanged = RemoteEvent.new()
```

Under the hood, Knit is creating a RemoteEvent linked to this event. This is a two-way event (like a tranceiver), so we can both send and receive data on both the server and the client.

We can then modify our `AddPoints` method again to fire this event too:

```lua
function PointsService:AddPoints(player, amount)
	local points = self:GetPoints(player)
	points = points + amount
	self.PointsPerPlayer[player] = points
	if (amount ~= 0) then
		self.PointsChanged:Fire(player, points)
		-- Fire the client event:
		self.Client.PointsChanged:Fire(player, points)
	end
end
```

And from the client, we can listen for the event:

```lua
-- From a LocalScript
local Knit = require(game:GetService("ReplicatedStorage").Knit)

local PointsService = Knit.GetService("PointsService")

PointsService.PointsChanged:Connect(function(points)
	print("Points for myself now:", points)
end)
```

!!! note
	Be sure to use `RemoteEvent` (_not_ `Event`) for client-exposed events.

### Events (Client-to-Server)

Events can also be fired from the client. This is useful when the client needs to give the server information, but doesn't care about any response from the server. For instance, maybe the client wants to tell the PointsService that it wants some points. This is an odd use-case, but let's just role with it.

We will create another client-exposed event called `GiveMePoints` which will randomly give the player points. Again, this is nonesense in the context of an actual game, but useful for example.

Let's create the event on the PointsService:
```lua
PointsService.Client.GiveMePoints = RemoteEvent.new()
```

Now, let's listen for the client to call this event. We can hook this up in our `KnitInit` method:

```lua
function PointsService:KnitInit()

	local rng = Random.new()
	-- Listen for the client to fire this event, then give random points:
	self.Client.GiveMePoints:Connect(function(player)
		local points = rng:NextInteger(0, 10)
		self:AddPoints(player, points)
		print("Gave " .. player.Name .. " " .. points .. " points")
	end)

	-- ...other code for cleaning up player data here
end
```

From the client, we can fire the event like so:

```lua
-- From a LocalScript
local Knit = require(game:GetService("ReplicatedStorage").Knit)

local PointsService = Knit.GetService("PointsService")

-- Fire the event:
PointsService.GiveMePoints:Fire()
```

### Properties

Knit provides a `RemoteProperty` module to easily expose valuse to the client. These values are read-only on the client.

For our example, let's say that we want to show the most points in the game. First, let's create the `RemoteProperty` object:

```lua
local RemoteProperty = require(Knit.Util.Remote.RemoteProperty)

PointsService.MostPoints = RemoteProperty.new(0)
```

Now, let's change this object whenever we add points:

```lua
function PointsService:AddPoints(player, amount)
	-- Other code from before...

	-- Set MostPoints value:
	if (points > self.Client.MostPoints:Get()) then
		self.Client.MostPoints:Set(points)
	end
end
```

On the server, the `RemoteProperty` object has `Set` and `Get` methods, and also has a `Changed` event. On the client, it only has the `Get` method and `Changed` event (no `Set` method on the client; read-only).

Let's grab this value on the client:

```lua
-- From a LocalScript
local Knit = require(game:GetService("ReplicatedStorage").Knit)

local PointsService = Knit.GetService("PointsService")

-- Grab value:
local mostPoints = PointsService.MostPoints:Get()

-- Keep it updated:
PointsService.MostPoints.Changed:Connect(function(newMostPoints)
	mostPoints = newMostPoints
end)
```

-----------------------------------------------------

## Full Example

### PointsService

At the end of this tutorial, we should have a PointsService that looks something like this:

```lua
local Knit = require(game:GetService("ReplicatedStorage").Knit)
local Signal = require(Knit.Util.Signal)
local RemoteEvent = require(Knit.Util.Remote.RemoteEvent)
local RemoteProperty = require(Knit.Util.Remote.RemoteProperty)

local PointsService = Knit.CreateService { Name = "PointsService", Client = {} }

-- Server-exposed events/fields:
PointsService.PointsPerPlayer = {}
PointsService.PointsChanged = Signal.new()

-- Client exposed events:
PointsService.Client.PointsChanged = RemoteEvent.new()
PointsService.Client.GiveMePoints = RemoteEvent.new()

-- Client exposed properties:
PointsService.Client.MostPoints = RemoteProperty.new(0)

-- Client exposed GetPoints method:
function PointsService.Client:GetPoints(player)
	return self.Server:GetPoints(player)
end

-- Add Points:
function PointsService:AddPoints(player, amount)
	local points = self:GetPoints(player)
	points = points + amount
	self.PointsPerPlayer[player] = points
	if (amount ~= 0) then
		self.PointsChanged:Fire(player, points)
		self.Client.PointsChanged:Fire(player, points)
	end
	if (points > self.Client.MostPoints:Get()) then
		self.Client.MostPoints:Set(points)
	end
end

-- Get Points:
function PointsService:GetPoints(player)
	local points = self.PointsPerPlayer[player]
	return points or 0
end

-- Initialize
function PointsService:KnitInit()

	local rng = Random.new()
	
	-- Give player random amount of points:
	self.Client.GiveMePoints:Connect(function(player)
		local points = rng:NextInteger(0, 10)
		self:AddPoints(player, points)
		print("Gave " .. player.Name .. " " .. points .. " points")
	end)

	-- Clean up data when player leaves:
	game:GetService("Players").PlayerRemoving:Connect(function(player)
		self.PointsPerPlayer[player] = nil
	end)

end

return PointsService
```

Alternatively, we could have put all non-methods within the `CreateService` constructor:

```lua
local PointsService = Knit.CreateService {
	Name = "PointsService";
	PointsPerPlayer = {};
	PointsChanged = Event.new();
	Client = {
		PointsChanged = Event.new();
		GiveMePoints = Event.new();
	};
}

-- The rest of code here
```

### Client Consumer

Example of client-side LocalScript consuming the PointsService:

```lua
-- From a LocalScript
local Knit = require(game:GetService("ReplicatedStorage").Knit)

local PointsService = Knit.GetService("PointsService")

local function PointsChanged(points)
	print("My points:", points)
end

-- Get points and listen for changes:
local initialPoints = PointsService:GetPoints()
PointsChanged(initialPoints)
PointsService.PointsChanged:Connect(PointsChanged)

-- Ask server to give points randomly:
PointsService.GiveMePoints:Fire()

-- Grab MostPoints value:
local mostPoints = PointsService.MostPoints:Get()

-- Keep MostPoints value updated:
PointsService.MostPoints.Changed:Connect(function(newMostPoints)
	mostPoints = newMostPoints
end)

-- Advanced example, using promises to get points:
PointsService:GetPointsPromise():Then(function(points)
	print("Got points:", points)
end)
```