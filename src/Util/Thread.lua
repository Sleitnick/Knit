-- Thread
-- Stephen Leitnick
-- January 5, 2020

--[[

	Thread.DelayRepeatBehavior { Delayed, Immediate }

	Thread.Delay(waitTime: number, func: (...any): void [, ...any]): Connection
	Thread.DelayRepeat(waitTime: number, func: (...any): void [, behavior: DelayRepeatBehavior, ...any]): Connection

	Delay(waitTime: number, func: (...any): void [, ...args])

		>	The given function is called after the elapsed
			waitTime has been reached.

		>	Returns the connection to the Heartbeat event,
			so the delay can be cancelled by disconnecting
			the returned connection.

	DelayRepeat(intervalTime: number, func: (...any): void [, behavior: DelayRepeatBehavior, ...args])

		>	The same as Thread.Delay, except it repeats
			indefinitely.

		>	Returns the Heartbeat connection, thus the
			repeated delay can be stopped by disconnecting
			the returned connection.

		>	Properly bound to the time interval, thus will
			not experience drift.

		>	If DelayRepeatBehavior is Delayed (default behavior),
			then the function will first fire after an initial
			delay. If set to Immediate, the function will fire
			immediately before the first delay.


	Examples:

		Thread.Delay(1, function()
			print("Hello from Delay")
		end)

		local delayConnection = Thread.Delay(5, function()
			print("Hello?")
		end)
		delayConnection:Disconnect()

		local repeatConnection = Thread.DelayRepeat(1, function()
			print("Hello again", time())
		end, Thread.DelayRepeatBehavior.Delayed)
		task.wait(5)
		repeatConnection:Disconnect()

--]]


local EnumList = require(script.Parent.EnumList)

local Thread = {}

local heartbeat = game:GetService("RunService").Heartbeat

Thread.DelayRepeatBehavior = EnumList.new("DelayRepeatBehavior", {
	"Delayed";
	"Immediate";
})


function Thread.Delay(waitTime, func, ...)
	local args = table.pack(...)
	local executeTime = (time() + waitTime)
	local hb
	hb = heartbeat:Connect(function()
		if (time() >= executeTime) then
			hb:Disconnect()
			func(table.unpack(args, 1, args.n))
		end
	end)
	return hb
end


function Thread.DelayRepeat(intervalTime, func, behavior, ...)
	local args = table.pack(...)
	if (behavior == nil) then
		behavior = Thread.DelayRepeatBehavior.Delayed
	end
	assert(Thread.DelayRepeatBehavior:Is(behavior), "Invalid behavior")
	local immediate = (behavior == Thread.DelayRepeatBehavior.Immediate)
	local nextExecuteTime = (time() + (immediate and 0 or intervalTime))
	local hb
	hb = heartbeat:Connect(function()
		if (time() >= nextExecuteTime) then
			nextExecuteTime = (time() + intervalTime)
			func(table.unpack(args, 1, args.n))
		end
	end)
	return hb
end


return Thread
