## [Streamable](https://github.com/Sleitnick/Knit/blob/main/src/Knit/Util/Streamable.lua)

Streamables allow developers to observe the existence of an instance. This is very useful for watching parts within a model in a game that has StreamingEnabled on. Streamables allow clean setup and teardown of streamed instances. In just about all cases, streamables should be attached to a model somewhere within the workspace and observe a BasePart child within the model.

Streamables can be paired with Components. If a component is attached to a model and the component needs to access the model's children, a streamable can guarantee safe access to those children. When using a streamable within a component, be sure to pass the streamable to the component's maid for automatic cleanup.

Check out Roblox's [Content Streaming](https://developer.roblox.com/en-us/articles/content-streaming) developer documentation for more information on how content is streamed into and out of games during runtime.

```lua
local Streamable = require(Knit.Util.Streamable)

local streamable = Streamable.new(workspace.MyModel, "SomePart") -- Expects "SomePart" to be a direct child of MyModel

streamable:Observe(function(part, maid)
	-- This function is called every time 'SomePart' comes into existence.
	-- The 'maid' is cleaned up when 'SomePart' is removed from existence.
	print(part.Name .. " exists")
	maid:GiveTask(function()
		print(part.Name .. " no longer exists")
	end)
end)

-- Multiple functions can be attached to the streamable:
streamable:Observe(function(part, maid)
	print("Another one!")
end)

-- Streamables should be destroyed when no longer needed:
streamable:Destroy()

-- Streamables are often passed to maids instead of explicitly calling Destroy:
someMaid:GiveTask(streamable)
```

--------------------

## [StreamableUtil](https://github.com/Sleitnick/Knit/blob/main/src/Knit/Util/StreamableUtil.lua)

Extra functionality for Streamables. For instance, `StreamableUtil.Compound` can be used to observe multiple streamables, and thus guarantee access to all instances referenced.

```lua
-- Compound Streamables:
local s1 = Streamable.new(someModel, "SomeChild")
local s2 = Streamable.new(anotherModel, "AnotherChild")

StreamableUtil.Compound({Stream1 = s1, Stream2 = s2}, function(streamables, maid)
	local someChild = streamables.Stream1.Instance
	local anotherChild = streamables.Stream2.Instance
	maid:GiveTask(function()
		-- Cleanup (will be called if ANY streamables are cleaned up)
	end)
end)
```