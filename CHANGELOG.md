## 1.4.4
- Add memory categories per service and controller to help track memory usage
- Update dependencies

## 1.4.3

- Update Component dependency
- Update Input dependency
- Update Signal dependency
- Update Timer dependency
- Update Trove dependency

## 1.4.2

- Update dependencies to latest

## 1.4.1

- Update the Comm module to patch a [middleware bug](https://github.com/Sleitnick/RbxUtil/pull/27) only affecting middleware that tries to change number of arguments (i.e. injecting custom arguments will now be fixed)
- Documentation improvements

## 1.4.0

- Add ability to set independent middleware per service, but on the server and the client
- Added tutorial video links
- Add short-circuit evaluation to `GetService` and `GetController` functions for better performance when the service/controller exists
- Change Comm module to use service name as namespace instead of nested `__comm__` folder
- Documentation improvements
- Breaking changes to middleware assignment (now within one `Middleware` table instead of two for inbound/outbound)

## 1.3.0

- Add support for RemoteProperties via Comm library

## 1.2.1

- Add updated dependencies to the `wally_bundle.toml` dependency list

## 1.2.0

- Added options to include middleware

## 1.1.0-rc.2

- Removed `Services` and `Controllers` properties to force use of `GetService` and `GetController` functions
- Add `KnitOptions` argument for KnitClient to toggle whether service methods simply yield or return promises (promises by default)
- Various documentation improvements

## 1.1.0-rc.1

- Migrated all core modules to Wally
- Revamped documentation

## 0.0.22-alpha

- Fix `TableUtil.Sample` algorithm to properly implement a partial Fisher-Yates shuffle
- Fix `TableUtil.Reduce` to handle the `init` parameter properly
- Update Janitor to [v1.13.6](https://github.com/howmanysmall/Janitor/releases/tag/V1.13.6)
- Small documentation adjustments

## 0.0.21-alpha

- Fix issue with having multiple required components
- Adds `Sample` and `Zip` to TableUtil
- Improvements to Timer module

## 0.0.20-alpha

- Fixes bug with Timer class
- Updates Janitor
- Removes unnecessary parentheses
- Adds some more Luau types

## 0.0.19-alpha

- New Signal implementation
- Remove Thread module in favor of new `task.spawn` and `task.defer` functions
- Add Janitor / Remove Maid
- Add Timer module

## 0.0.18-alpha

### Components
- Added optional [`RequiredComponents`](https://sleitnick.github.io/Knit/util/component/#required-components) table for components
- Added [`Observe`](https://sleitnick.github.io/Knit/util/component/#observe) method for components
- Fixed `Added` and `Removed` events not being cleaned up when component class destroyed
- Fixed lifecycle RunService method bindings not being cleaned up properly for future reuse

### Documentation
- Added [more documentation](https://sleitnick.github.io/Knit/util/component) for components

### Stability
- Upgraded CI/CD pipeline to use latest packages

## 0.0.17-alpha

- Hotfix for TableUtil `Sync`, `Assign`, `Extend`, and `Shuffle` functions to do shallow copies instead of deep copies
- Fix release GitHub action to properly use `"Knit"` as the top-level directory name within the zipped file
- Fix documentation to properly use user preference theme (light/dark)

## 0.0.16-alpha

**[BR]** = Breaking Change
- Project directory restructure
- Can now include Knit as a Git submodule and reference the default rojo project to sync in (see below)
- Added unit tests for Knit-specific utility modules
- Added simple integration tests
- TableUtil fixes, additions, and improvements:
   - **[BR]** All functions (except `FastRemove` and `FastRemoveFirstValue`) no longer mutate table
   - Fix `Filter` bug introduced in v0.0.15-alpha
   - Fix behavior of `Extend` to extend arrays and not dictionaries (use `Assign` to extend a dictionary)
   - Add optional RNG override parameter for `Shuffle`
   - Add `Flat`, `FlatMap`, `Keys`, `Find`, `Every`, and `Some` functions
   - Add documentation page for TableUtil
- Simplify `Knit.OnStart()` internally to use `Promise.FromEvent`
- Update Rojo version used by CI/CD pipeline
- Fix broken links in documentation pages

## 0.0.15-alpha

- Memory leak fixed with Streamable when instance was immediately available
- `Knit.GetService(serviceName)` added to server-side Knit
- Minor improvements to TableUtil
- Util documentation split across multiple pages

## 0.0.14-alpha

- Fix Signal leak when firing with no connections
- Change `._instance` to `.Instance` in Component
- Components will use attributes to store unique ID instead of StringValue
- Add `Signal.Proxy` constructor to wrap built-in RBXScriptSignals
- Add `Maid:GivePromise` method
- Allow dictionary tables in `StreamableUtil.Compound` observers list

**Note breaking changes from above:**
- When upgrading, make sure to change `._instance` field accessors to `.Instance` for components
- `ServerID` StringValue for components has been switched to use attributes: `instance:GetAttribute("ComponentServerId")`

## 0.0.13-alpha

- `Component:WaitFor` has been rewritten to utilize built-in promise features better, which also eliminated an existing event connection leak.
- `Streamable` and `StreamableUtil` modules added to easily manage parts that may stream in & out during runtime when using [`StreamingEnabled`](https://developer.roblox.com/en-us/api-reference/property/Workspace/StreamingEnabled).
- Documentation improvements.

## 0.0.12-alpha

- Added new 'Add' functions to automatically load all modules in a folder. This is useful for quickly loading a bunch of service or controller modules:
   - `KnitServer.AddServices(folder: Instance)`
   - `KnitServer.AddServicesDeep(folder: Instance)`
   - `KnitClient.AddControllers(folder: Instance)`
   - `KnitClient.AddControllersDeep(folder: Instance)`
- Split up remotes to server/client versions:
   - `RemoteEvent` -> `RemoteSignal` and `ClientRemoteSignal`
   - `RemoteProperty` -> `RemoteProperty` and `ClientRemoteProperty`
- Knit module isn't required to live in ReplicatedStorage now
- Added `EnumList` class which wraps `Symbol`s to create pseudo-enums
- Added style guide in documentation

## 0.0.11-alpha

- Documentation fixes and additions
- Better table support for `RemoteProperty` class
- Fixes and additions to `Option` class
- Optional behavior argument for `Thread.DelayRepeat`
   - **Note:** If using var-args list for `DelayRepeat`, this is a breaking change. `DelayRepeat`'s third argument must be the behavior (`Thread.DelayRepeatBehavior.Delayed` or `Thread.DelayRepeatBehavior.Immediate`).
- Added `Symbol` class

## 0.0.10-alpha

- Switch default branch from `master` to `main`
- `Component:WaitFor` first arg can now be a name or instance
- `Init` for individual components is called after a heartbeat, which helps allow components to get other components without race conditions when `Component.Auto` is used.

## 0.0.9-alpha

- Fixed issue where remote objects were parented before services completed initialization. This created a possible race condition between services initializing and clients loading Knit.

## 0.0.8-alpha

- Added `Option` class for creating optionals.
- Added serialization/deserialization automatic flow for RemoteEvents and RemoteFunctions.
- Upgraded `Promise` to v3.0.1.

## 0.0.7-alpha

- Added a few tests (very few so far)
- Added PascalCase methods to Promise module
- Components will only trigger for instances that are descendants of Players or Workspace by default
- GitHub workflow to auto-publish the [Knit](https://www.roblox.com/library/5530714855/Knit) module to Roblox.

## 0.0.6-alpha

- Add more functionality to Component module

## 0.0.5-alpha

- Added Component class, which allows developers to bind component classes to in-game instances using the CollectionService tags
- Renamed `Event` to `Signal`

## 0.0.4-alpha

- Ability to use tables within RemoteProperty object
- RemoteProperty now has `property:Replicate()` method server-side that must be called when a table value is changed ([see doc](https://sleitnick.github.io/Knit/util/#remoteproperty))

## 0.0.3-alpha

- Add more documentation
- Inject `Player` field into `KnitClient`

## 0.0.2-alpha

- Add `Knit.OnStart()` to capture when Knit starts
- Add RemoteEvent and RemoteProperty
- Add documentation

## 0.0.1-alpha

- Initial release