The [Thread](https://github.com/Sleitnick/Knit/blob/main/src/Util/Thread.lua) module aims to replace the somewhat-broken built-in thread functions (such as `wait`, `spawn`, and `delay`), which suffer from throttling.

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