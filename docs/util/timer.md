The [Timer](https://github.com/Sleitnick/Knit/blob/main/src/Util/Timer.lua) class allows for firing tasks at given intervals. An example could be a periodic check to see if a car is flipped upside down.

```lua
local Timer = require(Knit.Util.Timer)

local timer = Timer.new(1)

timer.Tick:Connect(function()
	print("Tock")
end)

timer:Start()
```


## Constructor

```lua
timer = Timer.new(interval: number [, maid: Maid])
```

## Fields

```lua
-- Seconds between ticks:
timer.Interval: number

-- Signal fired at each interval:
timer.Tick: Signal
```

## Methods

```lua
-- Start the timer:
timer:Start()

-- Same as Start, but fires the 'Tick' signal immediately:
timer:StartNow()

-- Stop the timer:
timer:Stop()

-- Clean up:
timer:Destroy()
```
