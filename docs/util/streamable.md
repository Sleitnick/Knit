[Streamables](https://github.com/AtollStudios/Knit/blob/main/src/Util/Streamable.lua) allow developers to observe the existence of an instance. This is very useful for watching parts within a model in a game that has StreamingEnabled on. Streamables allow clean setup and teardown of streamed instances. In just about all cases, streamables should be attached to a model somewhere within the workspace and observe a BasePart child within the model.

Streamables can be paired with Components. If a component is attached to a model and the component needs to access the model's children, a streamable can guarantee safe access to those children. When using a streamable within a component, be sure to pass the streamable to the component's janitor for automatic cleanup.

Check out Roblox's [Content Streaming](https://developer.roblox.com/en-us/articles/content-streaming) documentation for more information on how content is streamed into and out of games during runtime.

```lua
local Streamable = require(Knit.Util.Streamable)

local streamable = Streamable.new(workspace.MyModel, "SomePart") -- Expects "SomePart" to be a direct child of MyModel

streamable:Observe(function(part, janitor)
	-- This function is called every time 'SomePart' comes into existence.
	-- The 'janitor' is cleaned up when 'SomePart' is removed from existence.
	print(part.Name .. " exists")
	janitor:Add(function()
		print(part.Name .. " no longer exists")
	end)
end)

-- Multiple functions can be attached to the streamable:
streamable:Observe(function(part, janitor)
	print("Another one!")
end)

-- Streamables should be destroyed when no longer needed:
streamable:Destroy()

-- Streamables are often passed to janitors instead of explicitly calling Destroy:
someJanitor:Add(streamable)
```