## [Component](https://github.com/Sleitnick/Knit/blob/main/src/Knit/Util/Component.lua)

The [Component](https://github.com/Sleitnick/Knit/blob/main/src/Knit/Util/Component.lua) class allows developers to bind custom component classes to in-game objects based on tags provided by the [CollectionService](https://developer.roblox.com/en-us/api-reference/class/CollectionService).

For instance, a component might be created called `DanceFloor`, which has the purpose of making a part flash random colors. Here's what our DanceFloor component module might look like:

```lua
local DanceFloor = {}
DanceFloor.__index = DanceFloor

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

Now the Component module can be used to register the above component:

```lua
local Component = require(Knit.Util.Component)
local DanceFloor = require(somewhere.DanceFloor)

local danceFloor = Component.new("DanceFloor", DanceFloor)
```

Lastly, simply assign parts within the game with the `DanceFloor` tag, and the DanceFloor component will automatically be instantiated for those objects. For editing tags within Studio, check out the [Tag Editor](https://www.roblox.com/library/948084095/Tag-Editor) plugin.

The full API for components is listed within the [Component](https://github.com/Sleitnick/Knit/blob/main/src/Knit/Util/Component.lua) module.

!!! note
	If a component needs to be used on both the server and the client, it is recommended to make two separate component modules for each environment. In the above example, we made a DanceFloor. Ideally, such a module should only run on the client, since it is rapidly changing the color of the part at random. Another DanceFloor component could also be created for the server if desired.