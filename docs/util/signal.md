The [Signal](https://github.com/Sleitnick/Knit/blob/main/src/Util/Signal.lua) module gives basic Roblox Signal functionality. Signals are key to event-driven programming in Roblox.

```lua
local Signal = require(Knit.Util.Signal)
```

## Constructors

### `new()`
Creates a new signal.
```lua
local signal = Signal.new()
```

### `new(janitor)`
Create a new signal that will be cleaned up with the given janitor.
```lua
local signal = Signal.new(janitor)
```

## Methods

### `Fire(...)`
Fire the signal with any number of arguments. Internally, this uses `task.defer`.
```lua
signal:Fire(...)
```

### `FireNow()`
Fires the signal with any number of arguments. Internally, this uses `task.spawn`. Using `Fire()` is preferred over `FireNow()` due to the performance benefits of using `task.defer` instead of `task.spawn`. Only use `FireNow()` when it is absolutely necessary.
```lua
signal:FireNow(...)
```

### `Wait()`
Yields the current thread until the signal fires & returns all arguments fired.
```lua
local arg1, arg2, arg3 = signal:Wait()
```

### `Await()`
Returns a promise that is resolved once the signal is fired. This promise is also cancellable.
```lua
signal:Await():Then(function(arg1, arg2, arg3)
	...
end)
```

### `Connect()`
Connects a function to the signal and returns a connection object.
```lua
local connection = signal:Connect(function(arg1, arg2, arg3)
	...
end)

-- Connections can be disconnected
connection:Disconnect()

-- Check if a connection is still connected
if connection.Connected then ... end
```

### `DisconnectAll()`
```lua
-- Disconnects all connections to the signal
signal:DisconnectAll()
```

### `Destroy()`
```lua
-- Destroys the signal
signal:Destroy()
```