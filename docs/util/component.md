The [Component](https://github.com/AtollStudios/Knit/blob/main/src/Util/Component.lua) class allows developers to bind custom component classes to in-game objects based on tags provided by the [CollectionService](https://developer.roblox.com/en-us/api-reference/class/CollectionService).

The best practice is to keep all components as descendants of a folder and then call `Component.Auto(folder)` to load all the components automatically. This process is looks for component modules in all descendants of the given folder.

## Dance Floor Example

For instance, a component might be created called `DanceFloor`, which has the purpose of making a part flash random colors. Here's what our DanceFloor component module might look like:

```lua
local DanceFloor = {}
DanceFloor.__index = DanceFloor

-- The CollectionService tag to bind:
DanceFloor.Tag = "DanceFloor"

-- [Optional] The RenderPriority to be used when using the RenderUpdate lifecycle method:
DanceFloor.RenderPriority = Enum.RenderPriority.Camera.Value

-- [Optional] The other components that must exist on a given instance before this one can exist:
DanceFloor.RequiredComponents = {}

-- How often the color changes:
local UPDATE_INTERVAL = 0.5

function DanceFloor.new()
	local self = setmetatable({}, DanceFloor)
	self._nextUpdate = time() + UPDATE_INTERVAL
	return self
end

function DanceFloor:HeartbeatUpdate(dt)
	if (time() > self._nextUpdate) then
		-- Set the assigned instance to a random color:
		self.Instance.Color = Color3.new(
			math.random(),
			math.random(),
			math.random()
		)
		self._nextUpdate = self._nextUpdate + UPDATE_INTERVAL
	end
end

function DanceFloor:Destroy()
end

return DanceFloor
```

Within your runtime script, load in all components using `Component.Auto`:

```lua
local Knit = require(game:GetService("ReplicatedStorage").Knit)
local Component = require(Knit.Util.Component)

Knit.Start():Await()

-- Load all components in some folder:
Component.Auto(script.Parent.Components)
```

Simply assign parts within the game with the `DanceFloor` tag, and the DanceFloor component will automatically be instantiated for those objects. For editing tags within Studio, check out the [Tag Editor](https://www.roblox.com/library/948084095/Tag-Editor) plugin.

Components can live in either the server or the client. It is _not_ recommended to use the exact same component module for both the server and the client. Instead, it is best to create separate components for the server and client. For instance, there could be a `DanceFloor` component on the server and a `ClientDanceFloor` component on the client.

Because this component is flashing colors quickly, it is probably best to run this component on the client, rather than the server.

---------------------------

## Component Instance

A component _instance_ is the instantiated object from your component class. In other words, this is the object being created when your component's `.new()` constructor is called.

```lua
function MyComponent.new(robloxInstance)
	-- This is the component instance:
	local self = setmetatable({}, MyComponent)
	return self
end
```

### Roblox Instance

Component instances are bound to a Roblox instance. This is injected into the component instance _after_ the constructor is completed (it is identical to the `robloxInstance` argument passed to the constructor). This can be accessed as the `.Instance` field on the component instance. For example, here is the Roblox instance being referenced within the initializer:

```lua
function MyComponent:Init()
	print("I am bound to: " .. self.Instance:GetFullName())
end
```

---------------------------

## Lifecycle Methods

Components have special "lifecycle methods" which will automatically fire during the lifecycle of the component. The available methods are `Init`, `Deinit`, `Destroy`, `HeartbeatUpdate`, `SteppedUpdated`, and `RenderUpdate`. The only required of these is `Destroy`; the rest are optional.

### Init & Deinit

`Init` fires a tick/frame after the constructor has fired. `Deinit` fires right before the component's `Destroy` method is called. Both `Init` and `Deinit` are optional.

### Destroy

`Destroy` is fired internally when the component becomes unbound from the instance. A component is destroyed when one of the following conditions occurs:

1. The bound instance is destroyed
1. The bound instance no longer has the component tag anymore
1. The bound instance no longer has the required components attached anymore (see section on [Required Components](#required-components))

It is recommended to use janitors in components and to only have the janitor cleanup within the `Destroy` method. Any other cleanup logic should just be added to the janitor:

```lua
function MyComponent.new(instance)
	local self = setmetatable({}, MyComponent)
	self._janitor = Janitor.new()
	return self
end

function MyComponent:Destroy()
	self._janitor:Destroy()
end
```

### HeartbeatUpdate & SteppedUpdate

These optional methods are fired when `RunService.Heartbeat` and `RunService.Stepped` are fired. The delta time argument from the event is passed as an argument to the methods.

```lua
function MyComponent:HeartbeatUpdate(dt)
	print("Update!", dt)
end
function MyComponent:SteppedUpdate(dt)
	print("Update!", dt)
end
```

### RenderUpdate

The `RenderUpdate` optional method uses `RunService:BindToRenderStep` internally, using your component's RenderPriority field as the priority for binding. Just like `HeartbeatUpdate` and `SteppedUpdate`, the delta time is passed along to the method.

```lua
MyComponent.RenderPriority = Enum.RenderPriority.Camera.Value

function MyComponent:RenderUpdate(dt)
	print("Render update", dt)
end
```

---------------------------

## Required Components

Being able to extend instances by binding multiple components is very useful. However, if these components need to communicate, it is required to use the `RequiredComponents` optional table to indicate which components are necessary for instantiation.

For example, let's say we have a `Vehicle` component and a `Truck` component. The `Truck` component _must_ have the `Vehicle` component in order to operate. The `Truck` component also needs to invoke methods on the `Vehicle` component. We can make this guarantee using the `RequiredComponents` table on the `Truck`:

```lua
local Truck = {}
Truck.__index = Truck
Truck.Tag = "Truck"

-- Set the 'Vehicle' as a required component:
Truck.RequiredComponents = {"Vehicle"}
```

With that done, the `Truck` component will _only_ bind to an instance with the "Truck" tag if the instance already has a `Vehicle` component bound to it. If the `Vehicle` component becomes unbound for any reason, the `Truck` component will also be unbound and destroyed.

Because of this guarantee, we can reference the `Vehicle` component within the `Truck` constructor safely:

```lua
local Knit = require(game:GetService("ReplicatedStorage").Knit)
local Component = require(Knit.Util.Component)

...

Truck.RequiredComponents = {"Vehicle"}

function Truck.new(instance)
	local self = setmetatable({}, Truck)

	-- Get the Vehicle component on this instance:
	self.Vehicle = Component.FromTag("Vehicle"):GetFromInstance(instance)

	return self
end
```

## Component API

### Static Methods

```
Component.Auto(folder: Instance): void
Component.FromTag(tag: string): ComponentInstance | nil
Component.ObserveFromTag(tag: string, observer: (component: Component, janitor: Janitor) -> void): Janitor
```

#### `Auto`

Automatically create components from the component module descendants of the given instance.

```lua
Component.Auto(someFolder)
```

#### `FromTag`

Get a component from the tag name, which assumes the component class has already been loaded. This will return `nil` if not found.

```lua
local MyComponent = Component.FromTag("MyComponent")
```

#### `ObserveFromTag`

Observe a component with the given tag name. Unless component classes will be destroyed and reconstructed often, this method is most likely not going to be needed in your code.

```lua
Component.ObserveFromTag("MyComponent", function(MyComponent, janitor)
	-- Use MyComponent
end)
```

### Constructor

```
Component.new(tag: string, class: table [, renderPriority: RenderPriority, requiredComponents: table])
```

```lua
local MyComponentClass = require(somewhere.MyComponent)
local MyComponent = Component.new(
	MyComponentClass.Tag,
	MyComponentClass,
	MyComponentClass.RenderPriority,
	MyComponentClass.RequiredComponents
)
```

!!! note
	While the constructor can be called directly, it is recommended to use `Component.Auto` instead.

### Methods

```
component:GetAll(): ComponentInstance[]
component:GetFromInstance(instance: Instance): ComponentInstance | nil
component:Filter(filterFunc: (comp: ComponentInstance) -> boolean): ComponentInstance[]
component:WaitFor(instance: Instance [, timeout: number = 60]): Promise<ComponentInstance>
component:Observe(instance: Instance, observer: (component: ComponentInstance, janitor: Janitor) -> void): Janitor
component:Destroy()
```

#### `GetAll`
Gets all component instances for the given component class.

```lua
local MyComponent = Component.FromTag("MyComponent")
for _,component in ipairs(MyComponent:GetAll()) do
	print(component.Instance:GetFullName())
end
```

#### `GetFromInstance`
Gets a component instance from the given Roblox instance. If no component is found, `nil` is returned.

```lua
local MyComponent = Component.FromTag("MyComponent")
local component = MyComponent:GetFromInstance(workspace.SomePart)
```

#### `Filter`
Returns a filtered list from all components for a given component class. This is equivalent to calling `GetAll` and running it through `TableUtil.Filter`.

```lua
local MyComponent = Component.FromTag("MyComponent")
local componentsStartWithC = MyComponent:Filter(function(component)
	return component.Instance.Name:sub(1, 1):lower() == "c"
end)
```

#### `WaitFor`
Waits for a component to be bound to a given instance. Returns a promise that is resolved when the component is bound, or rejected when either the timeout is reached or the instance is removed.

```lua
local MyComponent = Component.FromTag("MyComponent")
MyComponent:WaitFor(workspace.SomePart):Then(function(component)
	print("Got component")
end):Catch(warn)
```

#### `Observe`
Observes when a component is bound to a given instance. Returns a janitor that can be destroyed.

```lua
local MyComponent = Component.FromTag("MyComponent")
local observeJanitor = MyComponent:Observe(workspace.SomePart, function(component, janitor)
	-- Do something
	janitor:Add(function()
		-- Cleanup
	end)
end)
```

!!! warning
	This does _not_ clean itself up if the instance is destroyed. This should be handled explicitly in your code.

#### `Destroy`
If the component is not needed anymore, `Destroy` can be called to clean it up. Typically, components are never destroyed.

```lua
local MyComponent = Component.FromTag("MyComponent")
MyComponent:Destroy()
```

### Events

```
component.Added(obj: ComponentInstance)
component.Removed(obj: ComponentInstance)
```

## Boilerplate Examples

Here is the most basic component with the recommended Janitor pattern:
```lua
local Knit = require(game:GetService("ReplicatedStorage").Knit)
local Janitor = require(Knit.Util.Janitor)

local MyComponent = {}
MyComponent.__index = MyComponent

MyComponent.Tag = "MyComponent"

function MyComponent.new(instance)
	local self = setmetatable({}, MyComponent)
	self._janitor = Janitor.new()
	return self
end

function MyComponent:Destroy()
	self._janitor:Destroy()
end

return MyComponent
```

Here is a more robust example with lifecycles and required components:
```lua
local Knit = require(game:GetService("ReplicatedStorage").Knit)
local Janitor = require(Knit.Util.Janitor)

local MyComponent = {}
MyComponent.__index = MyComponent

MyComponent.Tag = "MyComponent"
MyComponent.RenderPriority = Enum.RenderPriority.Camera.Value
MyComponent.RequiredComponents = {"AnotherComponent", "YetAnotherComponent"}

function MyComponent.new(instance)
	local self = setmetatable({}, MyComponent)
	self._janitor = Janitor.new()
	return self
end

function MyComponent:Init()
	print("Initialized. Bound to: ", self.Instance:GetFullName())
end

function MyComponent:Deinit()
	print("About to clean up")
end

function MyComponent:HeartbeatUpdate(dt)
	print("Heartbeat", dt)
end

function MyComponent:SteppedUpdate(dt)
	print("Stepped", dt)
end

function MyComponent:RenderUpdate(dt)
	print("Render", dt)
end

function MyComponent:Destroy()
	self._janitor:Destroy()
end

return MyComponent
```