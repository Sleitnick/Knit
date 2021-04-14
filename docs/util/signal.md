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

It is possible to wrap an existing RBXScriptSignal (e.g. `BasePart.Touched`) using `Signal.Proxy`, which is useful when creating abstractions that utilize existing built-in signals:

```lua
local touchTap = Signal.Proxy(UserInputService.TouchTap)
```