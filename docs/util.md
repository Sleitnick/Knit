---
sidebar_position: 5
---

# Util

## Knit via Wally
When installing Knit with Wally, developers should pull in utility modules
via Wally as required. Knit's utility modules are significantly slimmed down
in the Wally release.

## Knit via ModuleScript
Knit comes with a few utility modules. If Knit is being used from the packaged
ModuleScript, then the best way to access these modules is via `require(Knit.Util.PACKAGE)`.

The following modules are available:

- [`Knit.Util.Comm`](https://sleitnick.github.io/RbxUtil/api/Comm)
- [`Knit.Util.Component`](https://sleitnick.github.io/RbxUtil/api/Component)
- [`Knit.Util.EnumList`](https://sleitnick.github.io/RbxUtil/api/EnumList)
- [`Knit.Util.Option`](https://sleitnick.github.io/RbxUtil/api/Option)
- [`Knit.Util.Signal`](https://sleitnick.github.io/RbxUtil/api/Signal)
- [`Knit.Util.TableUtil`](https://sleitnick.github.io/RbxUtil/api/TableUtil)
- [`Knit.Util.Timer`](https://sleitnick.github.io/RbxUtil/api/Timer)
- [`Knit.Util.Trove`](https://sleitnick.github.io/RbxUtil/api/Trove)
- [`Knit.Util.Promise`](https://eryn.io/roblox-lua-promise/api/Promise)

Below is an example of the Signal class being used in a service:

```lua
local Signal = require(Knit.Util.Signal)

local MyService = Knit.CreateService {
	Name = "MyService";
	SomeSignal = Signal.new();
}
```
