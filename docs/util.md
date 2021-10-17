---
sidebar_position: 5
---

# Util

## Knit via ModuleScript
Knit comes with a few utility modules. If Knit is being used from the packaged
ModuleScript, then the best way to access these modules is via `Knit.Util.PACKAGE`.

The following modules are available:

- [`Knit.Util.Signal`](https://sleitnick.github.io/RbxUtil/api/Signal)
- [`Knit.Util.Remote`](https://sleitnick.github.io/RbxUtil/api/Remote)
- [`Knit.Util.TableUtil`](https://sleitnick.github.io/RbxUtil/api/TableUtil)
- [`Knit.Util.Comm`](https://sleitnick.github.io/RbxUtil/api/Comm)
- [`Knit.Util.Promise`](https://eryn.io/roblox-lua-promise/api/Promise)

## Knit via Wally
When using Knit via Wally, it's recommended to just pull in the desired utility
modules as needed and use them however you would otherwise.
