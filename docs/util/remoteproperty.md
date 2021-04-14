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