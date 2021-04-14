The [Maid](https://github.com/Sleitnick/Knit/blob/main/src/Knit/Util/Maid.lua) module is a powerful tool for tracking and cleaning up your messes (hence the name). The Maid module was created by [James Onnen](https://github.com/Quenty). Read his [tutorial on Maids](https://medium.com/roblox-development/how-to-use-a-maid-class-on-roblox-to-manage-state-651bf74de98b) for a better understanding of how to use it.

```lua
local Maid = require(Knit.Util.Maid)

local maid = Maid.new()

-- Give tasks to be cleaned up at a later time:
maid:GiveTask(somePart)
maid:GiveTask(something.SomeEvent:Connect(function() end))
maid:GiveTask(function() end)

-- Give promises, which will have 'Cancel' called if the maid is cleaned up:
maid:GivePromise(somePromise)

-- Both Destroy and DoCleaning do the same thing:
maid:Destroy()
maid:DoCleaning()
```

Any table with a `Destroy` method can be added to a maid. If you have a bunch of events that you've created for a custom class, using a maid would be good to clean them all up when you're done with the object. Typically a maid will live with the object with which contains the items being tracked.
