---
sidebar_position: 7
---

# Examples

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
local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

-- Load all services:
for _,v in ipairs(script.Parent.Services:GetDescendants()) do
	if (v:IsA("ModuleScript")) then
		require(v)
	end
end

Knit.Start():catch(warn)
```

Alternatively, we can use `Knit.AddServices` or `Knit.AddServicesDeep` to load all of the services without writing a loop. It scans and loads all ModuleScripts found and passes them to `Knit.CreateService`:

```lua
local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

-- Load all services within 'Services':
Knit.AddServices(script.Parent.Services)

-- Load all services (the Deep version scans all descendants of the passed instance):
Knit.AddServicesDeep(script.Parent.OtherServices)

Knit.Start():catch(warn)
```

:::tip
This same design practice can also be done on the client with controllers. Either loop through and collect controllers or use the `Knit.AddControllers` or `Knit.AddControllersDeep` function.
:::

----------------

## Expose a Collection of Modules

Like `Knit.Util`, we can expose a collection of modules to our codebase. This is very simple. All we need to do is add `Knit.WHATEVER` and point it to a folder of ModuleScripts.

For instance, if we had a folder of modules at `ReplicatedStorage.MyModules`, we can expose this within our main runtime script:

```lua
local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

-- Expose our MyModules folder:
Knit.MyModules = game:GetService("ReplicatedStorage").MyModules

-- Load services/controllers

Knit.Start()
```

We can then use these modules elsewhere. For instance:

```lua
local SomeModule = require(Knit.MyModules.SomeModule)
```
