---
sidebar_position: 3
---

# Services

## Services Defined

Services are singleton provider objects that serve a specific purpose on the server. For instance, a game might have a PointsService, which manages in-game points for the players.

A game might have many services. They will serve as the backbone of a game.

For the sake of example, we will slowly develop PointsService to show how a service is constructed.

## Creating Services

In its simplest form, a service can be created like so:

```lua
local PointsService = Knit.CreateService { Name = "PointsService", Client = {} }

return PointsService
```

:::note Client table optional
The `Client` table is optional for the constructor. However, it will be added by Knit if left out. For the sake of code clarity, it is recommended to keep it in the constructor as shown above.
:::

:::caution No client table forces server-only mode
If the `Client` table is omitted, the service will be interpreted as server-side only. This means that the client will _not_ be able to access this service using `Knit.GetService` on the client.
:::caution

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

Again, services are just tables. So we can simply add in properties as we want. In our above method, we are returning `0` for `GetPoints()` because we have nowhere to store/retrieve points. Likewise, our `AddPoints()` method can't do anything. Let's change that. Let's create a property that holds a table of points per player:

```lua
PointsService.PointsPerPlayer = {}
```

## Using methods and properties

Now we can change our `AddPoints()` and `GetPoints()` methods to use this field.

```lua
PointsService.PointsPerPlayer = {}

function PointsService:AddPoints(player, amount)
	local points = self:GetPoints(player) -- Current amount of points
	points += amount                      -- Add points
	self.PointsPerPlayer[player] = points -- Store points
end

function PointsService:GetPoints(player)
	local points = self.PointsPerPlayer[player]
	return if points ~= nil then points else 0 -- Return 0 if no points found for player
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
	points += amount
	self.PointsPerPlayer[player] = points
	-- Fire event signal, as long as we actually changed the points:
	if amount ~= 0 then
		self.PointsChanged:Fire(player, points)
	end
end
```

Another service could then listen for the changes on that event:

```lua
function SomeOtherService:KnitStart()
	local PointsService = Knit.GetService("PointsService")
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

In order to maintain this pattern, be sure to set up your service in the `Init` method (or earlier; just in the ModuleScript itself). By the time `KnitStart` methods are being fired, your services should be available for use.

## Cleaning Up Unused Memory

Alright, back to our PointsService! We have a problem... We have created a [memory leak](https://en.wikipedia.org/wiki/Memory_leak)! When we add points for a player, we add the player to the table. What happens when the player leaves? Nothing! And that's a problem. That player's data is forever held onto within that `PointsPerPlayer` table. To fix this, we need to clear out that data when the player leaves. We can use the `KnitInit` method to hook up to the `Players.PlayerRemoving` event and remove the data:

```lua
function PointsService:KnitInit()
	game:GetService("Players").PlayerRemoving:Connect(function(player)
		-- Clear out the data for the player when the player leaves:
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
local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

local PointsService = Knit.GetService("PointsService")
PointsService:GetPoints():andThen(function(points)
	print("Points for myself:", points)
end)
```

### Events (Server-to-Client)

We can use remote signals to fire events from the server to the clients. Continuing with the previous PointsService example, let's create a signal that fires when a client's points change. We can use `Knit.CreateSignal()` to indicate we want a signal created for the service.

```lua
local PointsService = Knit.CreateService {
	Name = "PointsService",
	Client = {
		PointsChanged = Knit.CreateSignal(), -- Create the signal
	},
}
```

:::tip Remote Signal
See the [RemoteSignal](https://sleitnick.github.io/RbxUtil/api/RemoteSignal) documentation for more info on how to use the RemoteSignal object.
:::

Under the hood, Knit is using the `Comm` module, which is creating a RemoteEvent object linked to this event. This is a two-way signal (like a transceiver), so we can both send and receive data on both the server and the client.

We can then modify our `AddPoints` method again to fire this signal too:

```lua
function PointsService:AddPoints(player, amount)
	local points = self:GetPoints(player)
	points += amount
	self.PointsPerPlayer[player] = points
	if amount ~= 0 then
		self.PointsChanged:Fire(player, points)
		-- Fire the client signal:
		self.Client.PointsChanged:Fire(player, points)
	end
end
```

And from the client, we can listen for an event on the signal:

```lua
-- From a LocalScript
local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

local PointsService = Knit.GetService("PointsService")

PointsService.PointsChanged:Connect(function(points)
	print("Points for myself now:", points)
end)
```

### Events (Client-to-Server)

Signal events can also be fired from the client. This is useful when the client needs to give the server information, but doesn't care about any response from the server. For instance, maybe the client wants to tell the PointsService that it wants some points. This is an odd use-case, but let's just roll with it.

We will create another client-exposed signal called `GiveMePoints` which will randomly give the player points. Again, this is nonsense in the context of an actual game, but useful for example.

Let's create the signal on the PointsService:
```lua
local PointsService = Knit.CreateService {
	Name = "PointsService",
	Client = {
		PointsChanged = Knit.CreateSignal(),
		GiveMePoints = Knit.CreateSignal(), -- Create the new signal
	},
}
```

Now, let's listen for the client to fire this signal. We can hook this up in our `KnitInit` method:

```lua
function PointsService:KnitInit()

	local rng = Random.new()
	-- Listen for the client to fire this signal, then give random points:
	self.Client.GiveMePoints:Connect(function(player)
		local points = rng:NextInteger(0, 10)
		self:AddPoints(player, points)
		print("Gave " .. player.Name .. " " .. points .. " points")
	end)

	-- ...other code for cleaning up player data here
end
```

From the client, we can fire the signal like so:

```lua
-- From a LocalScript
local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

local PointsService = Knit.GetService("PointsService")

-- Fire the signal:
PointsService.GiveMePoints:Fire()
```

:::tip Client Remote Signal
See the [ClientRemoteSignal](https://sleitnick.github.io/RbxUtil/api/ClientRemoteSignal) documentation for more info on how to use the ClientRemoteSignal object.
:::

### Unreliable Events

Knit also supports [UnreliableRemoteEvents](https://create.roblox.com/docs/reference/engine/classes/UnreliableRemoteEvent), which is a special version of RemoteEvent. UnreliableRemoteEvents are, as the name suggests, unreliable. When an event is fired on an UnreliableRemoteEvent, the order and delivery of the event is not guaranteed. The listener of the event may receive the events out of order, or possibly not at all.

Having unreliable events is useful in scenarios where the data being sent is not crucial to game state. For example, setting the tilt rotation of each avatar's head: if some packets are dropped, this won't affect actual gameplay. The benefit is that unreliable events take up less network bandwidth.

To create an unreliable event, use `Knit.CreateUnreliableSignal()` within the client table of a service:

```lua
local MyService = Knit.CreateService {
	Name = "MyService",
	Client = {
		PlayEffect = Knit.CreateUnreliableSignal(),
	},
}
```

Using the unreliable signal is the same as normal ones (see the two sections above on events).

### Properties

It is often useful to replicate data to all or individual players. Instead of creating methods and signals to communicate this data, RemoteProperties
can be used.

For example, let's refactor the `AddPoints` method to set a RemoteProperty of the number of points the player has. The client will then be able to
easily read this property:

```lua
-- Create the RemoteProperty:
PointsService.Client.Points = Knit.CreateProperty(0)

function PointsService:AddPoints(player, amount)
	local points = self:GetPoints(player)
	points += amount
	self.PointsPerPlayer[player] = points
	self.Client.Points:SetFor(player, points)
end
```

On the client, we can now easily read the `Points` property:

```lua
-- LocalScript
local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

local PointsService = Knit.GetService("PointsService")

-- The 'Observe' method will fire for the current value and any time the value changes:
PointsService.Points:Observe(function(points)
	print("Current number of points:", points)
end)
```

Using `Observe` is the easiest way to track the value of a RemoteProperty on the client.

:::tip Remote Property
See the [RemoteProperty](https://sleitnick.github.io/RbxUtil/api/RemoteProperty) and
[ClientRemoteProperty](https://sleitnick.github.io/RbxUtil/api/ClientRemoteProperty)
documentation for more info on how to use the RemoteProperty and ClientRemoteProperty objects.
:::

-----------------------------------------------------

## Full Example

### PointsService

At the end of this tutorial, we should have a PointsService that looks something like this:

```lua
local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)
local Signal = require(Knit.Util.Signal)

local PointsService = Knit.CreateService {
	Name = "PointsService",
	-- Define some properties:
	PointsPerPlayer = {},
	PointsChanged = Signal.new(),
	Client = {
		-- Expose signals to the client:
		PointsChanged = Knit.CreateSignal(),
		GiveMePoints = Knit.CreateSignal(),
		Points = Knit.CreateProperty(0),
	},
}

-- Client exposed GetPoints method:
function PointsService.Client:GetPoints(player)
	return self.Server:GetPoints(player)
end

-- Add Points:
function PointsService:AddPoints(player, amount)
	local points = self:GetPoints(player)
	points += amount
	self.PointsPerPlayer[player] = points
	if amount ~= 0 then
		self.PointsChanged:Fire(player, points)
		self.Client.PointsChanged:Fire(player, points)
	end
	self.Client.Points:SetFor(player, points)
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

### Client Consumer

Example of client-side LocalScript consuming the PointsService:

```lua
-- From a LocalScript
local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)
Knit.Start():catch(warn):await()

local PointsService = Knit.GetService("PointsService")

local function PointsChanged(points)
	print("My points:", points)
end

-- Get points and listen for changes:
PointsService:GetPoints():andThen(PointsChanged)
PointsService.PointsChanged:Connect(PointsChanged)

-- Ask server to give points randomly:
PointsService.GiveMePoints:Fire()
```
