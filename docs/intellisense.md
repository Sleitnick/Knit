---
sidebar_position: 9
---

# Intellisense

Knit was created before intellisense was introduced to Roblox. Unfortunately, due to the nature of how Knit is written, Knit does not benefit much from Roblox's intellisense. While the performance and stability of Knit are top-notch, the lack of intellisense can cause unnecessary strain on developers.

There are a couple ways to help resolve this issue:
1. Create your own bootstrapper to load in Knit services and controllers.
2. Create your own Knit-like framework using plain ModuleScripts.

:::note Service/Controller
In this article, any references to "Service" or "GetService" can also be implied to also include "Controller" or "GetController". It's simply less wordy to avoid referencing both.
:::

## Custom Bootstrapper

The verb "bootstrapping" in programming parlance is often used to describe a process that starts everything up (coming from the old phrase, "pull yourself up by your bootstraps"). In the context of Knit, this is usually handled internally when calling functions like `Knit.CreateService()` and `Knit.Start()`. This is ideal for a framework, as the users of the framework do not need to know the messy details of the startup procedure.

The consequence of Knit taking control of the bootstrapping process is that all loaded services end up in a generic table (think of a bucket of assorted items). Due to the dynamic nature of this process, there is no way for Luau's type system to understand the _type_ of a service simply based on the string name (e.g. `Knit.GetService("HelloService")`; Luau can't statically understand that this is pointing to a specific service table).

Thus, the question at hand is: **How do we get Luau to understand the _type_ of our service?**

### ModuleScripts Save the Day
An important factor about Knit services is that they are just Lua tables with some extra items stuffed inside. This is why services are usually designed like any other module, with the exception that `Knit.CreateService` is called. Then, the resultant service is returned at the end of the ModuleScript.

Because services are relatively statically defined, Roblox/Luau _can_ understand its "type" if accessed directly. In other words, if the ModuleScript that the service lives inside is directly `require`'d, then intellisense would magically become available.

Thus, the fix is to simply require the services directly from their corresponding ModuleScripts, side-stepping Knit's `GetService` calls entirely.

```lua
-- Old way:
local MyService = Knit.GetService("MyService")

-- New way:
local MyService = require(somewhere.MyService)
```

### Shifting the Problem
The problem, however, is that the call to `CreateService` messes it all up. Our day is ruined. Because `CreateService` is called _within_ the ModuleScript, this messes up the "type" of the service. Thankfully, this is easy to fix. We simply need to remove our call to `CreateService` and instead call it within our custom bootstrap loader. We'll get to that in the next section.

```lua
-- Old way:
local SomeService = Knit.CreateService {
	Name = "SomeService",
}
return SomeService

-- New way; only getting rid of the Knit.CreateService call:
local SomeService = {
	Name = "SomeService",
}
return SomeService
```

Now, when our service is required, Luau will properly infer the type of the service, which will provide proper intellisense. However, we are no longer calling `CreateService`, which means our service is never registered within Knit, thus `KnitStart` and `KnitInit` never run. Oops. Let's fix this by writing our own service module loader.

### Module Loader

Since we are no longer calling `CreateService` from the ModuleScript itself, our call to `AddServices` will no longer work as expected. Thus, we need to write our own version of `AddServices` that also calls `CreateService` on behalf of the module.

```lua
local function AddServicesCustom(parent: Instance)
	-- For deep scan, switch GetChildren() to GetDescendants()
	for _, v in parent:GetChildren() do
		-- Only match on instances that are ModuleScripts and names that end with "Service":
		if v:IsA("ModuleScript") and v.Name:match("Service$") then
			local service = require(v) -- Load the service module
			Knit.CreateService(service) -- Add the service into Knit
		end
	end
end

--Knit.AddServices(parent) (NO LONGER WILL WORK AS EXPECTED)
AddServicesCustom(parent)

Knit.Start()
```

:::tip Loader Module
The [Loader](https://sleitnick.github.io/RbxUtil/api/Loader/) module can be used if you do not want to write your own loader function.

```lua
local services = Loader.LoadChildren(parent, Loader.MatchesName("Service$"))
for _, service in services do
	Knit.CreateService(service)
end

Knit.Start()
```
:::

### Cyclical Dependencies
When requiring modules directly, it is possible to run into cyclical dependency errors. In short, Roblox will not allow `Module A` to require `Module B`, which also then requires `Module A`. If `A` requires `B`, and `B` requires `A`, we have a cyclical dependency. This can happen in longer chains too (e.g. `A`->`B`->`C`->`A`).

A side-effect of Knit's traditional startup procedure is that cyclical dependencies work fine. They work because modules are first loaded into memory before they grab any references to each other. Knit essentially acts as a bridge. However, **this is an unintentional side-effect of Knit**. Cyclical dependencies are a sign of poor architectural design.

Knit does not seek to allow cyclical dependencies. Knit will not make any effort to allow them to exist. Their allowance is a byproduct of Knit's design. If you are running into cyclical dependency problems after switching to directly requiring services (i.e. using `require` instead of `Knit.GetService`), this is _not_ an issue of Knit, but rather a code structure issue on your end.

### Why Not the Default
A fair question to ask is: Why is this not the preferred setup for Knit?
1. Knit's various assertions are being side-stepped to allow intellisense to work.
1. A lot of extra custom code has to be written.
1. If you are willing to go to this length, then perhaps a custom-built framework would work better.

### Client-accessed Services
Services accessed from the client must still go through `Knit.GetService`, thus cannot benefit from this structural change. A secondary module could be used as the client-facing service module, but that would be a lot more work to maintain and handle. 

## Create-a-Knit

Creating your own framework like Knit is quite easy. In this short section, we will set up a simple module loader that works similar to Knit's startup procedure. However, it will lack networking capabilities. There are plenty of third-party networking libraries that can be used. Choosing which networking library to use is out of scope for this section.

### Using the RbxUtil Loader Module
To help speed up this whole process, the [Loader](https://sleitnick.github.io/RbxUtil/api/Loader) module will be utilized. This will help us quickly load our modules and kick off any sort of startup method per module.

In keeping with the Service/Controller naming scheme, we will use the same names for our custom framework.

### Loading Services

To load in our modules, we can call `Loader.LoadChildren` or `Loader.LoadDescendants`. This will go through and `require` all found ModuleScripts, returning them in a named dictionary table, where each key represents the name of the ModuleScript, and each value is the loaded value from the ModuleScript.

```lua
local modules = Loader.LoadDescendants(ServerScriptService)
```

However, this isn't very useful, as we probably have a lot of non-service ModuleScripts in our codebase. The `Loader` module lets us filter which modules to use by passing in a predicate function. A helper `MatchesName` function generator can also be used to simply filter based on the name, which is what we will do. Let's load all ModuleScripts that end with the word "Service":

```lua
local services = Loader.LoadDescendants(ServerScriptService, Loader.MatchesName("Service$"))
```

Great, so now we have a key/value table of loaded services! To mirror a bit of Knit, let's call the `OnStart` method of each service.

### Starting Services

It's often useful to have a startup method that gets automatically called once all of our modules are loaded. This could be done by looping through each module and calling a method if it's found:

```lua
for _, service in services do
	if typeof(service.OnStart) == "function" then
		task.spawn(function()
			service:OnStart()
		end)
	end
end
```

That's a bit much. Thankfully, the `Loader` module also includes a `SpawnAll` function. This special function also calls `debug.setmemorycategory` so that we can properly profile the memory being used per OnStart service call:

```lua
Loader.SpawnAll(services, "OnStart")
```

### Final Loader Script

Let's merge all of the above code in one spot:
```lua
-- ServerScriptService.ServerStartup
local services = Loader.LoadDescendants(ServerScriptService, Loader.MatchesName("Service$"))
Loader.SpawnAll(services, "OnStart")
```

Our client-side code would look nearly identical. Just swap out the names. In this example, our controllers live in ReplicatedStorage:
```lua
-- StarterPlayer.StarterPlayerScripts.ClientStartup
local controllers = Loader.LoadDescendants(ReplicatedStorage, Loader.MatchesName("Controller$"))
Loader.SpawnAll(controllers, "OnStart")
```

### Example Services

Due to this incredibly simple setup, our services are also very simple in structure; they're just tables within ModuleScripts. Nothing fancy. To use one service from another, simply require its ModuleScript. As such, intellisense comes natively baked in.

```lua
-- ServerScriptService.MathService
local MathService = {}

function MathService:Add(a: number, b: number): number
	return a + b
end

return MathService
```

```lua
-- ServerScriptService.CalcService

-- Simply require another service to use it:
local MathService = require(somewhere.MathService)

local CalcService = {}

function CalcService:OnStart()
	local n1 = 10
	local n2 = 20
	local sum = MathService:Add(n1, n2)
	print(`Sum of {n1} and {n2} is {sum}`)
end

return CalcService
```
