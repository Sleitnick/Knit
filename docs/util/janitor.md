The [Janitor](https://github.com/AtollStudios/Knit/blob/main/src/Util/Janitor.lua) class manages the cleanup of instances, connections, promises, or anything else. A typical pattern is to use a Janitor within other classes. Instances and connections created by said classes can be added to janitors and then automatically cleaned up when destructed.

```lua
local Janitor = require(Knit.Util.Janitor)

local janitor = Janitor.new()

-- Instances added to janitors will be destroyed when the janitor is cleaned up:
janitor:Add(Instance.new("Folder"))

-- Janitors can also track RBXScriptConnections:
janitor:Add(workspace.Changed:Connect(function() end))

-- Janitors can also be given functions, which will be fired on cleanup:
janitor:Add(function() print("Cleanup") end)

-- Janitors can be given promises, which will be cancelled if cleaned up:
janitor:AddPromise(Promise.new(function(resolve, reject) ... end))

-- Janitors can be linked to an instance. The janitor will clean up once the instance is destroyed:
janitor:LinkToInstance(workspace.SomeModel)

-- Clean up all items added:
janitor:Cleanup()

-- Clean up and destroy the janitor:
janitor:Destroy()
```

Check out the [API Reference](https://github.com/howmanysmall/Janitor#janitor-api) for more info.
