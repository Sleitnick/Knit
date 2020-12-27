## Order of Operations

The execution model of Knit defines the flow of operations and lifecycle of the framework.

1. Require the Knit module
1. Create services or controllers
1. Call `Knit.Start()`, which immediately returns a Promise
	1. All `KnitInit` methods are invoked at the same time, and waits for all to finish
	1. All `KnitStart` methods are invoked at the same time
1. After all `KnitStart` methods are called, the promise returned by `Knit.Start()` resolves

On the server, you should have one Script in ServerScriptService. On the client, you should have one LocalScript in PlayerStarterScripts. Each of these scripts should have a similar layout:

```lua
local Knit = require(game:GetService("ReplicatedStorage").Knit)

-- Load services or controllers here

Knit.Start():Catch(warn)
```

Once services or controllers are created, they persist forever (until the server shuts down or the player leaves).

!!! warning
	Services and controllers **_cannot_** be created after `Knit.Start()` has been called.

## Catching KnitInit Errors
Due to the way Promises work, errors that occur within `KnitInit` methods of services or controllers will be caught as a rejected promise. These can be handled by either grabbing the status after using `Await` or using the `Catch()` method:

```lua
local success, err = Knit.Start():Await()
if (not success) then
	-- Handle error
	error(tostring(err))
end
```

```lua
Knit.Start():Catch(function(err)
	-- Handle error
	warn(tostring(err))
end)
```

## Best Practices
- Only one Script on the server should manage loading services and starting the Knit
- Only one LocalScript on the client should manage loading controllers and starting Knit
- Split up services and controllers into their own modules
- Services should be kept in either ServerStorage or ServerScriptService to avoid being exposed to the client
- Code within `KnitInit` and within the root scope of the ModuleScript should try to finish ASAP, and should avoid yielding if possible
- Events and methods should never be added to a service's Client table after `Knit.Start()` has been called
- As shown above in the [Catching knitInit Errors](#catching-knitinit-errors) section, handling a failure case of `Start` is the cleanest way to catch errors on startup.
