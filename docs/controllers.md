## Controllers Defined

Controllers are singleton objects that serve a specific purpose on the client. For instance, a game might have a CameraController, which manages a custom in-game camera for the player.

A controller is essentially the client-side equivalent of a service on the server.

A game might have many controllers. They serve as a core structure of the client within Knit.

For the sake of example, we will develop a CameraController. For full API documentation, visit the [Knit API](knitapi.md#controller) page.

## Creating Controllers

In its simplest form, a controller can be created like so:

```lua
local CameraController = Knit.CreateController { Name = "CameraController" }

return CameraController
```

The `Name` field is required. The name is how code outside of your controller will find it. This name must be unique from all other controllers. It is best practice to name your variable the same as the controller (e.g. `local CameraController` matches `Name = "CameraController"`).

The last line (`return CameraController`) assumes this code is written in a ModuleScript, which is best practice for containing controllers.

## Adding methods

Controllers are just simple tables at the end of the day. As such, it is very easy to add methods to controllers.

```lua
function CameraController:LockTo(part)
	-- TODO: Lock camera
end

function CameraController:Unlock()
	-- TODO: Unlock
end
```

## Adding properties

Again, controllers are just tables. We can simply add in properties as we want. Let's add a property to describe how far away our camera should be from the part we lock onto, and another to describe if the camera is currently locked:

```lua
CameraController.Distance = 20
CameraController.Locked = false
```

## Adding Basic Behavior

Let's add some basic behavior to our controller. When the camera is locked, we should set the CurrentCamera's CameraType to Scriptable, and set the CFrame to the part. When unlocked, we should set the CameraType back to Custom. We will also utilize the `Locked` property so other code can check if we are currently locked to a part.

```lua
function CameraController:LockTo(part)
	local cam = workspace.CurrentCamera
	self.Locked = true
	cam.CameraType = Enum.CameraType.Scriptable
	cam.CFrame = part.CFrame * CFrame.new(0, 0, self.Distance)
end

function CameraController:Unlock()
	local cam = workspace.CurrentCamera
	self.Locked = false
	cam.CameraType = Enum.CameraType.Custom
end
```

## More Behavior

Right now, when we lock onto a part, we simply set the camera's CFrame once. But what if the part moves? We need to constantly set the camera's CFrame to properly lock onto the part. We can bind to RenderStep to do this.

```lua
CameraController.RenderName = "CustomCamRender"
CameraController.Priority = Enum.RenderPriority.Camera.Value

function CameraController:LockTo(part)
	if (self.Locked) then return end -- Stop if already locked
	local cam = workspace.CurrentCamera
	local runService = game:GetService("RunService")
	self.Locked = true
	cam.CameraType = Enum.CameraType.Scriptable
	-- Bind to RenderStep:
	runService:BindToRenderStep(self.RenderName, self.Priority, function()
		cam.CFrame = part.CFrame * CFrame.new(0, 0, self.Distance)
	end)
end

function CameraController:Unlock()
	if (not self.Locked) then return end -- Stop if already unlocked
	local cam = workspace.CurrentCamera
	local runService = game:GetService("RunService")
	self.Locked = false
	cam.CameraType = Enum.CameraType.Custom
	-- Unbind:
	runService:UnbindFromRenderStep(self.RenderName)
end
```

## Events

What if we want to create an event that gets fired when the camera is locked and unlocked? We can easily do this! Just create a new signal object as a property of the controller, and fire it in our `LockTo` and `Unlock` methods. Let's created a `LockedChanged` signal. It will pass `true` when locked and `false` when unlocked.

```lua
local Signal = require(Knit.Util.Signal)

CameraController.LockedChanged = Signal.new()

function CameraController:LockTo(part)
	-- Other code...
	self.LockedChanged:Fire(true)
end

function CameraController:Unlock()
	-- Other code...
	self.LockedChanged:Fire(false)
end
```

Other code could then listen in for that event:

```lua
-- Somewhere else on the client
local CameraController = Knit.Controllers.CameraController

CameraController.LockedChanged:Connect(function(isLocked)
	print(isLocked and "Camera is now locked" or "Camera was unlocked")
end)
```

## Server Communication

Knit allows client code to access certain server-side service methods and events that have been explicitly exposed.

See the [Services: Client Communication](services.md#client-communication) section for more info.

An example of accessing a service on the server might look like such:

```lua
function CameraController:KnitStart()
	local SomeService = Knit.GetService("SomeService")
	SomeService:DoSomething()
	SomeService.SomeEvent:Connect(function(...) end)
	SomeService.AnotherEvent:Fire("Some data")
end
```

## KnitInit and KnitStart

The `KnitInit` and `KnitStart` methods are optional lifecycle methods that can be added to any controller. For more info, check out the [service version](services.md#knitinit-and-knitstart) of this section (which has the same behavior) and the [execution model](executionmodel.md).

These methods can be added just like any other method:

```lua
function CameraController:KnitStart()
	print("CameraController KnitStart called")
end

function CameraController:KnitInit()
	print("CameraController KnitInit called")
end
```
