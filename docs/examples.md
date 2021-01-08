## Start All Services

A useful pattern is to keep all service modules within a folder. The script that starts Knit can then require all of these at once. Let's say we have a directory structure like such:

- Server
	- KnitRuntime [Script]
	- Services [Folder]
		- MyService [Module]
		- AnotherService [Module]
		- HelloService [Module]

We can write our KnitRuntime script as such:

```lua
local Knit = require(game:GetService("ReplicatedStorage").Knit)

-- Load all services:
for _,v in ipairs(script.Parent.Services:GetDescendants()) do
	if (v:IsA("ModuleScript")) then
		require(v)
	end
end

Knit.Start():Catch(warn)
```

Alternatively, we can use `Knit.AutoServices` to load all of the services without writing a loop:

```lua
local Knit = require(game:GetService("ReplicatedStorage").Knit)

-- Load all services:
Knit.AutoServices(Knit.AutoBehavior.Descendants, script.Parent.Services)

Knit.Start():Catch(warn)
```

!!! tip
	This same design practice can also be done on the client with controllers. Either loop through and collect controllers or use the `Knit.AutoControllers` function.

----------------

## Expose a Collection of Modules

Like `Knit.Util`, we can expose a collection of modules to our codebase. This is very simple. All we need to do is add `Knit.WHATEVER` and point it to a folder of ModuleScripts.

For instance, if we had a folder of modules at `ReplicatedStorage.MyModules`, we can expose this within our main runtime script:

```lua
local Knit = require(game:GetService("ReplicatedStorage").Knit)

-- Expose our MyModules folder:
Knit.MyModules = game:GetService("ReplicatedStorage").MyModules

-- Load services/controllers

Knit.Start()
```

We can then use these modules elsewhere. For instance:

```lua
local SomeModule = require(Knit.MyModules.SomeModule)
```
