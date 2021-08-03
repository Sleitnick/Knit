[StreamableUtil](https://github.com/AtollStudios/Knit/blob/main/src/Util/StreamableUtil.lua) offers extra functionality for Streamables. For instance, `StreamableUtil.Compound` can be used to observe multiple streamables, and thus guarantee access to all instances referenced.

```lua
-- Compound Streamables:
local s1 = Streamable.new(someModel, "SomeChild")
local s2 = Streamable.new(anotherModel, "AnotherChild")

StreamableUtil.Compound({Stream1 = s1, Stream2 = s2}, function(streamables, janitor)
	local someChild = streamables.Stream1.Instance
	local anotherChild = streamables.Stream2.Instance
	janitor:Add(function()
		-- Cleanup (will be called if ANY streamables are cleaned up)
	end)
end)
```