There are some utility modules that come prepackaged with Knit. These are used internally, but are also meant to be accessible to developers.

These modules are accessible via `Knit.Util` and must be required, such as `require(Knit.Util.Event)`.

## [Event](https://github.com/Sleitnick/Knit/blob/master/src/Knit/Util/Event.lua)

The [Event](https://github.com/Sleitnick/Knit/blob/master/src/Knit/Util/Event.lua) module gives basic Roblox Signal functionality. It is easy to instantiate and use an event object.

```lua
local Event = require(Knit.Util.Event)

local event = Event.new()

event:Fire(...)
event:DisconnectAll()
event:Destroy()

local connection = event:Connect(function(...) end)

connection.Connected
connection:Disconnect()
```

The Connection object internal to the Event module also has a Destroy method associated with it, so it will still play nicely with the Maid module.

## [Thread](https://github.com/Sleitnick/Knit/blob/master/src/Knit/Util/Thread.lua)

The [Thread](https://github.com/Sleitnick/Knit/blob/master/src/Knit/Util/Thread.lua) module aims to replace the somewhat-broken built-in thread functions (such as `wait`, `spawn`, and `delay`), which suffer from throttling.

```lua
local Thread = require(Knit.Util.Thread)

Thread.SpawnNow(function() print("Hello") end)
Thread.Spawn(function() print("Hi") end)
Thread.Delay(1, function() print("Hola") end)
Thread.DelayRepeat(1, function() print("Hello again") end)
```

The Delay and DelayRepeat functions also return an event listener, so they can be cancelled if needed:

```lua
local delayConnection = Thread.Delay(10, function()
	print("I'll never see the light of day")
end)

delayConnection:Disconnect()
```

## [Maid](https://github.com/Sleitnick/Knit/blob/master/src/Knit/Util/Maid.lua)

The [Maid](https://github.com/Sleitnick/Knit/blob/master/src/Knit/Util/Maid.lua) module is a powerful tool for tracking and cleaning up your messes (hence the name). The Maid module was created by [James Onnen](https://github.com/Quenty). Read his [tutorial on Maids](https://medium.com/roblox-development/how-to-use-a-maid-class-on-roblox-to-manage-state-651bf74de98b) for a better understanding of how to use it.

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

## [Promise](https://github.com/Sleitnick/Knit/blob/master/src/Knit/Util/Promise.lua)

The [Promise](https://github.com/Sleitnick/Knit/blob/master/src/Knit/Util/Promise.lua) module reproduces the behavior of Promises common in web programming, written by [evaera](https://github.com/evaera). Promises are incredibly useful for managing asynchronous flows. Read the [official documentation](https://eryn.io/roblox-lua-promise/lib/) for usage.

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
	:andThen(function(result)
		print(result)
	end)
	:catch(function(err)
		warn(err)
	end)
```