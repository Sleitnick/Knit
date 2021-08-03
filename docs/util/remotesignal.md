The [RemoteSignal](https://github.com/AtollStudios/Knit/blob/main/src/Util/Remote/RemoteSignal.lua) module wraps the RemoteEvent object and is typically used within services. The only time a developer should ever have to instantiate a RemoteSignal is within the `Client` table of a service. For use on the client, see ClientRemoteSignal.

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

## [ClientRemoteSignal](https://github.com/AtollStudios/Knit/blob/main/src/Util/Remote/ClientRemoteSignal.lua)

The [ClientRemoteSignal](https://github.com/AtollStudios/Knit/blob/main/src/Util/Remote/ClientRemoteSignal.lua) module wraps the RemoteEvent object and is typically used within services. Usually, ClientRemoteSignals are created behind-the-scenes and don't need to be instantiated by developers. However, it is available for developers in case custom workflows are being used.

```lua
local remoteSignal = ClientRemoteSignal.new(remoteEventObject)

remoteSignal:Fire(...)
remoteSignal:Wait()
remoteSignal:Destroy()

local connection = remoteSignal:Connect(functionHandler(...))
connection:IsConnected()
connection:Disconnect()
```