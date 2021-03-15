There are some utility modules that come prepackaged with Knit. These are used internally, but are also meant to be accessible to developers.

These modules are accessible via `Knit.Util` and must be required, such as `require(Knit.Util.Signal)`.

--------------------

## [Signal](https://github.com/Sleitnick/Knit/blob/main/src/Knit/Util/Signal.lua)

The [Signal](https://github.com/Sleitnick/Knit/blob/main/src/Knit/Util/Signal.lua) module gives basic Roblox Signal functionality. It is easy to instantiate and use a signal object.

```lua
local Signal = require(Knit.Util.Signal)

local signal = Signal.new()

signal:Fire(...)
signal:DisconnectAll()
signal:Destroy()

local connection = signal:Connect(function(...) end)

connection.Connected
connection:Disconnect()
```

The Connection object internal to the Signal module also has a Destroy method associated with it, so it will still play nicely with the Maid module.

--------------------

## [Thread](https://github.com/Sleitnick/Knit/blob/main/src/Knit/Util/Thread.lua)

The [Thread](https://github.com/Sleitnick/Knit/blob/main/src/Knit/Util/Thread.lua) module aims to replace the somewhat-broken built-in thread functions (such as `wait`, `spawn`, and `delay`), which suffer from throttling.

```lua
local Thread = require(Knit.Util.Thread)

Thread.SpawnNow(function() print("Hello") end)
Thread.Spawn(function() print("Hi") end)
Thread.Delay(1, function() print("Hola") end)
Thread.DelayRepeat(1, function() print("Hello again") end)
```

DelayRepeat has an optional Behavior parameter, which can be used to switch the behavior between an initial delay (default) or immediate execution before the first delay. For instance, if you want the function to fire immediately before starting the delay loop, use the Immediate behavior:

```lua
-- Fire the function immediately:
Thread.DelayRepeat(1, function()
	print("Hello")
end, Thread.DelayRepeatBehavior.Immediate)

-- Fire the function after the first 1 second delay (default behavior):
Thread.DelayRepeat(1, function()
	print("Hello")
end, Thread.DelayRepeatBehavior.Delayed)
```

All of these functions can also be given arguments, as a vararg list at the end of the Thread function call. For instance:

```lua
Thread.Spawn(function(someMessage)
	print(someMessage)
end, someMessage)
```

The caveat with the above is dealing with DelayRepeat, where the behavior must first be defined before the vararg list:

```lua
-- Will work:
Thread.DelayRepeat(1, function(message)
	print(message)
end, Thread.DelayRepeatBehavior.Delayed, "Hello world!")

-- Will throw an error as an unknown behavior:
Thread.DelayRepeat(1, function(message)
	print(message)
end, "Hello world!")
```

The Delay and DelayRepeat functions also return an event listener, so they can be cancelled if needed:

```lua
local delayConnection = Thread.Delay(10, function()
	print("I'll never see the light of day")
end)

delayConnection:Disconnect()
```

--------------------

## [Maid](https://github.com/Sleitnick/Knit/blob/main/src/Knit/Util/Maid.lua)

The [Maid](https://github.com/Sleitnick/Knit/blob/main/src/Knit/Util/Maid.lua) module is a powerful tool for tracking and cleaning up your messes (hence the name). The Maid module was created by [James Onnen](https://github.com/Quenty). Read his [tutorial on Maids](https://medium.com/roblox-development/how-to-use-a-maid-class-on-roblox-to-manage-state-651bf74de98b) for a better understanding of how to use it.

```lua
local Maid = require(Knit.Util.Maid)

local maid = Maid.new()

-- Give tasks to be cleaned up at a later time:
maid:GiveTask(somePart)
maid:GiveTask(something.SomeEvent:Connect(function() end))
maid:GiveTask(function() end)

-- Both Destroy and DoCleaning do the same thing:
maid:Destroy()
maid:DoCleaning()
```

Any table with a `Destroy` method can be added to a maid. If you have a bunch of events that you've created for a custom class, using a maid would be good to clean them all up when you're done with the object. Typically a maid will live with the object with which contains the items being tracked.

--------------------

## [Promise](https://github.com/Sleitnick/Knit/blob/main/src/Knit/Util/Promise.lua)

The [Promise](https://github.com/Sleitnick/Knit/blob/main/src/Knit/Util/Promise.lua) module reproduces the behavior of Promises common in web programming, written by [evaera](https://github.com/evaera). Promises are incredibly useful for managing asynchronous flows. Read the [official documentation](https://eryn.io/roblox-lua-promise/lib/) for usage.

```lua
local Promise = require(Knit.Util.Promise)

local function Fetch(url)
	return Promise.new(function(resolve, reject)
		local success, result = pcall(function()
			return game:GetService("HttpService"):GetAsync(url)
		end)
		if (success) then
			resolve(result)
		else
			reject(result)
		end
	end)
end

Fetch("https://www.example.com")
	:Then(function(result)
		print(result)
	end)
	:Catch(function(err)
		warn(err)
	end)
```

--------------------

## [RemoteSignal](https://github.com/Sleitnick/Knit/blob/main/src/Knit/Util/Remote/RemoteSignal.lua)

The [RemoteSignal](https://github.com/Sleitnick/Knit/blob/main/src/Knit/Util/Remote/RemoteSignal.lua) module wraps the RemoteEvent object and is typically used within services. The only time a developer should ever have to instantiate a RemoteSignal is within the `Client` table of a service. For use on the client, see ClientRemoteSignal.

```lua
local remoteSignal = RemoteSignal.new()

remoteSignal:Fire(player, ...)
remoteSignal:FireExcept(player, ...)
remoteSignal:FireAll(...)
remoteSignal:Wait()
remoteSignal:Destroy()

local connection = remoteSignal:Connect(functionHandler(player, ...))
connection:IsConnected()
connection:Disconnect()
```

--------------------

## [ClientRemoteSignal](https://github.com/Sleitnick/Knit/blob/main/src/Knit/Util/Remote/ClientRemoteSignal.lua)

The [ClientRemoteSignal](https://github.com/Sleitnick/Knit/blob/main/src/Knit/Util/Remote/ClientRemoteSignal.lua) module wraps the RemoteEvent object and is typically used within services. Usually, ClientRemoteSignals are created behind-the-scenes and don't need to be instantiated by developers. However, it is available for developers in case custom workflows are being used.

```lua
local remoteSignal = ClientRemoteSignal.new(remoteEventObject)

remoteSignal:Fire(...)
remoteSignal:Wait()
remoteSignal:Destroy()

local connection = remoteSignal:Connect(functionHandler(...))
connection:IsConnected()
connection:Disconnect()
```

--------------------

## [RemoteProperty](https://github.com/Sleitnick/Knit/blob/main/src/Knit/Util/Remote/RemoteProperty.lua)

The [RemoteProperty](https://github.com/Sleitnick/Knit/blob/main/src/Knit/Util/Remote/RemoteProperty.lua) module wraps a ValueBase object to expose properties to the client from the server. The server can read and write to this object, but the client can only read. This is useful when it's overkill to write a combination of a method and event to replicate data to the client.

When a RemoteProperty is created on the server, a value must be passed to the constructor. The type of the value will determine the ValueBase chosen. For instance, if a string is passed, it will instantiate a StringValue internally. The server can then set/get this value.

On the client, a RemoteProperty must be instantiated by giving the ValueBase to the constructor.

```lua
local property = RemoteProperty.new(10)
property:Set(30)
property:Replicate() -- Only for table values
local value = property:Get()
property.Changed:Connect(function(newValue) end)
```

!!! warning "Tables"
	When using a table in a RemoteProperty, you **_must_** call `property:Replicate()` server-side after changing a value in the table in order for the changes to replicate to the client. This is necessary because there is no way to watch for changes on a table (unless you clutter it with a bunch of metatables). Calling `Replicate` will replicate the table to the clients.

--------------------

## [ClientRemoteProperty](https://github.com/Sleitnick/Knit/blob/main/src/Knit/Util/Remote/ClientRemoteProperty.lua)

The [ClientRemoteProperty](https://github.com/Sleitnick/Knit/blob/main/src/Knit/Util/Remote/ClientRemoteProperty.lua) module wraps a ValueBase object to expose properties from the server to the client. The client can only read the value. This class should be used alongside RemoteProperty on the server.

Typically, developers will never need to instantiate ClientRemoteProperties, as they are automatically created for services on the client if the service has a RemoteProperty defined in its Client table. However, the class is exposed to developers in case custom workflows are being used.

```lua
-- Client-side
local property = ClientRemoteProperty.new(valueBaseObject)
local value = property:Get()
property.Changed:Connect(function(newValue) end)
```

--------------------

## [Component](https://github.com/Sleitnick/Knit/blob/main/src/Knit/Util/Component.lua)

The [Component](https://github.com/Sleitnick/Knit/blob/main/src/Knit/Util/Component.lua) class allows developers to bind custom component classes to in-game objects based on tags provided by the [CollectionService](https://developer.roblox.com/en-us/api-reference/class/CollectionService).

For instance, a component might be created called `DanceFloor`, which has the purpose of making a part flash random colors. Here's what our DanceFloor component module might look like:

```lua
local DanceFloor = {}
DanceFloor.__index = DanceFloor

-- How often the color changes:
local UPDATE_INTERVAL = 0.5

function DanceFloor.new()
	local self = setmetatable({}, DanceFloor)
	self._nextUpdate = time() + UPDATE_INTERVAL
	return self
end

function DanceFloor:HeartbeatUpdate(dt)
	if (time() > self._nextUpdate) then
		-- Set the assigned instance to a random color:
		self.Instance.Color = Color3.new(
			math.random(),
			math.random(),
			math.random()
		)
		self._nextUpdate = self._nextUpdate + UPDATE_INTERVAL
	end
end

function DanceFloor:Destroy()
end

return DanceFloor
```

Now the Component module can be used to register the above component:

```lua
local Component = require(Knit.Util.Component)
local DanceFloor = require(somewhere.DanceFloor)

local danceFloor = Component.new("DanceFloor", DanceFloor)
```

Lastly, simply assign parts within the game with the `DanceFloor` tag, and the DanceFloor component will automatically be instantiated for those objects. For editing tags within Studio, check out the [Tag Editor](https://www.roblox.com/library/948084095/Tag-Editor) plugin.

The full API for components is listed within the [Component](https://github.com/Sleitnick/Knit/blob/main/src/Knit/Util/Component.lua) module.

!!! note
	If a component needs to be used on both the server and the client, it is recommended to make two separate component modules for each environment. In the above example, we made a DanceFloor. Ideally, such a module should only run on the client, since it is rapidly changing the color of the part at random. Another DanceFloor component could also be created for the server if desired.

--------------------

## [Streamable](https://github.com/Sleitnick/Knit/blob/main/src/Knit/Util/Streamable.lua)

Streamables allow developers to observe the existence of an instance. This is very useful for watching parts within a model in a game that has StreamingEnabled on. Streamables allow clean setup and teardown of streamed instances. In just about all cases, streamables should be attached to a model somewhere within the workspace and observe a BasePart child within the model.

Streamables can be paired with Components. If a component is attached to a model and the component needs to access the model's children, a streamable can guarantee safe access to those children. When using a streamable within a component, be sure to pass the streamable to the component's maid for automatic cleanup.

Check out Roblox's [Content Streaming](https://developer.roblox.com/en-us/articles/content-streaming) developer documentation for more information on how content is streamed into and out of games during runtime.

```lua
local Streamable = require(Knit.Util.Streamable)

local streamable = Streamable.new(workspace.MyModel, "SomePart") -- Expects "SomePart" to be a direct child of MyModel

streamable:Observe(function(part, maid)
	-- This function is called every time 'SomePart' comes into existence.
	-- The 'maid' is cleaned up when 'SomePart' is removed from existence.
	print(part.Name .. " exists")
	maid:GiveTask(function()
		print(part.Name .. " no longer exists")
	end)
end)

-- Multiple functions can be attached to the streamable:
streamable:Observe(function(part, maid)
	print("Another one!")
end)

-- Streamables should be destroyed when no longer needed:
streamable:Destroy()

-- Streamables are often passed to maids instead of explicitly calling Destroy:
someMaid:GiveTask(streamable)
```

--------------------

## [StreamableUtil](https://github.com/Sleitnick/Knit/blob/main/src/Knit/Util/StreamableUtil.lua)

Extra functionality for Streamables. For instance, `StreamableUtil.Compound` can be used to observe multiple streamables, and thus guarantee access to all instances referenced.

```lua
-- Compound Streamables:
local s1 = Streamable.new(someModel, "SomeChild")
local s2 = Streamable.new(anotherModel, "AnotherChild")

StreamableUtil.Compound({s1, s2}, function(streamables, maid)
	local someChild = streamables[1].Instance
	local anotherChild = streamables[2].Instance
	maid:GiveTask(function()
		-- Cleanup (will be called if ANY streamables are cleaned up)
	end)
end)
```

--------------------

## [Option](https://github.com/Sleitnick/Knit/blob/main/src/Knit/Util/Option.lua)

An Option is a powerful concept taken from [Rust](https://doc.rust-lang.org/std/option/index.html) and other languages. The purpose is to represent an optional value. An option can either be `Some` or `None`. Using Options helps reduce `nil` bugs (which can cause silent bugs that can be hard to track down). Options automatically serialize/deserialize across the server/client boundary when passed through services or controllers.

For full documentation, check out the [LuaOption](https://github.com/Sleitnick/LuaOption) repository.

Using Options is very simple:

```lua
local Option = require(Knit.Util.Option)

-- Returns an Option:
local function DoSomething()
	local rng = Random.new()
	local value = rng:NextNumber()
	if (value > 0.5) then
		return Option.Some(value)
	else
		return Option.None
	end
end

-- Get option value:
local value = DoSomething()

-- Match if the value is 'some' or 'none':
value:Match {
	Some = function(value) print("Got value:", value),
	None = function() print("Got no value") end
}

-- Optionally, use IsSome() and Unwrap():
if (value:IsSome()) then
	print("Got value:", value:Unwrap())
end
```

Because these are automatically serialized/deserialized in services and controllers, they work great in cases where a returned result is uncertain:

```lua
-- SERVICE:
local MyService = Knit.CreateService { Name = "MyService" }
local Option = require(Knit.Util.Option)

function MyService.Client:GetWeapon(player, weaponName)
	local weapon = TryToGetWeaponSomehow(player, weaponName)
	if (weapon) then
		return Option.Some(weapon)
	else
		return Option.None
	end
end

----

-- CONTROLLER:
local MyController = Knit.CreateController { Name = "MyController" }

function MyController:KnitStart()
	local MyService = Knit.GetService("MyService")
	local weaponOption = MyService:GetWeapon("SomeWeapon")
	weaponOption:Match {
		Some = function(weapon) --[[ Do something with weapon ]] end,
		None = function() warn("No weapon found") end
	}
end
```

!!! note
	Attempting to unwrap an option with no value will throw an error. This is intentional. The purpose is to avoid unhandled `nil` cases. Whenever calling `Unwrap()`, be sure that `IsSome()` was first checked. Using the `Match` pattern is the easiest way to handle both Some and None cases.