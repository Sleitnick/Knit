The [Signal](https://github.com/Sleitnick/Knit/blob/main/src/Util/Signal.lua) module gives basic Roblox Signal functionality. Signals are key to event-driven programming in Roblox.

```lua
local Signal = require(Knit.Util.Signal)
```

## Constructors

### `new([janitor: Janitor])`
Creates a new signal. If a Janitor is passed ot the constructor, the signal will be added to the janitor for future cleanup.
```lua
-- Create a signal:
local signal = Signal.new()

-- Create a signal with a janitor:
local signal = Signal.new(janitor)

	-- The above is equivalent to:
	local signal = Signal.new()
	janitor:Add(signal)
```

### `Wrap(signal: RBXScriptSignal [, janitor: Janitor])`
Wraps an existing RBXScriptSignal. This is useful when simply proxying a built-in signal that should have all connections disconnected at some point.
```lua
local signal = Signal.Wrap()
```

## Static Functions

### `Is(obj: any)`
Returns `true` if the given `obj` is a Signal.
```lua
local signal = Signal.new()

print(Signal.Is(signal)) --> true
print(Signal.Is("abc")) --> false
```

## Methods

### `Fire(...)`
Fire the signal with any number of arguments. Internally, this uses `task.spawn` and optimizes to reuse the same coroutine when possible.
```lua
signal:Fire(...)
```

### `FireDeferred(...)`
Fires the signal with any number of arguments. Internally, this uses `task.defer`. This does not reuse coroutines, but does take advantage of the built-in deferral scheduling.
```lua
signal:FireDeferred(...)
```

### `Wait()`
Yields the current thread until the signal fires & returns all arguments fired.
```lua
local arg1, arg2, arg3 = signal:Wait()
```

### `Promise([predicate: (...) -> boolean])`
Returns a promise that is resolved once the signal is fired. This promise is also cancellable. A predicate function can optionally be passed to signal which event should resolve the promise.
```lua
-- Resolve promise the first time the signal is fired:
signal:Promise():Then(function(arg1, arg2, arg3)
	print(arg1, arg2, arg3) --> 10, 15, 20
end)
signal:Fire(10, 15, 20)

-- Using predicate to signal when promise should resolve:
local function IsPositive(num)
	return num >= 0
end
signal:Promise(IsPositive):Then(function(positiveNum)
	print(positiveNum) --> 15
end)
signal:Fire(-20)
signal:Fire(-5)
signal:Fire(15)
```

### `Connect(fn: (...) -> void)`
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
