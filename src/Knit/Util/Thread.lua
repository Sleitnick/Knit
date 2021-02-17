-- Thread
-- Stephen Leitnick
-- January 5, 2020

--[[

	Thread.DelayRepeatBehavior { Delayed, Immediate }

	Thread.SpawnNow(func: (...any) -> void, [...any])
	Thread.Spawn(func: (...any) -> void, [...any])
	Thread.Delay(waitTime: number, func: (...any) -> void [, ...any])
	Thread.DelayRepeat(waitTime: number, func: (...any) -> void [, behavior: DelayRepeatBehavior, ...any])

	SpawnNow(func: (...any) -> void [, ...args])

		>	Uses a BindableEvent to spawn a new thread
			immediately. More performance-intensive than
			using Thread.Spawn, but will guarantee a
			thread is started immediately.

		>	Use this only if the thread must be executed
			right away, otherwise use Thread.Spawn for
			the sake of performance.

	Spawn(func: (...any) -> void [, ...args])

		>	Uses RunService's PostSimulation to spawn a new
			thread on the next post-simulation event and then
			call the given function.

		>	Better performance than Thread.SpawnNow, but
			will have a short delay of 1 frame before
			calling the function.

	Delay(waitTime: number, func: (...any) -> void [, ...args])

		>	The same as Thread.Spawn, but waits to call
			the function until the in-game time as elapsed
			by 'waitTime' amount.

		>	Returns the connection to the PostSimulation event,
			so the delay can be cancelled by disconnecting
			the returned connection.

	DelayRepeat(intervalTime: number, func: (...any) -> void [, behavior: DelayRepeatBehavior, ...args])

		>	The same as Thread.Delay, except it repeats
			indefinitely.
		
		>	Returns the PostSimulation connection, thus the
			repeated delay can be stopped by disconnecting
			the returned connection.

		>	Properly bound to the time interval, thus will
			not experience drift.

		>	If DelayRepeatBehavior is Delayed (default behavior),
			then the function will first fire after an initial
			delay. If set to Immediate, the function will fire
			immediately before the first delay.

	
	Examples:

		Thread.Spawn(function()
			print("Hello from Spawn")
		end)

		Thread.Delay(1, function()
			print("Hello from Delay")
		end)

		Thread.SpawnNow(function()
			print("Hello from SpawnNow")
		end)

		local delayConnection = Thread.Delay(5, function()
			print("Hello?")
		end)
		delayConnection:Disconnect()

		local repeatConnection = Thread.DelayRepeat(1, function()
			print("Hello again", time())
		end, Thread.DelayRepeatBehavior.Delayed)
		wait(5)
		repeatConnection:Disconnect()


	Why:
		
		The built-in 'spawn' and 'delay' functions have the
		potential to be throttled unknowingly. This can cause
		all sorts of problems. Developers need to be certain
		when their code is going to run. This small library
		helps give the same functionality as 'spawn' and 'delay'
		but with the expected behavior.

	Why not coroutines:
		
		Coroutines are powerful, but can be extremely difficult
		to debug due to the ways that coroutines obscure the
		stack trace.

	Credit:
	
		evaera & buildthomas: https://devforum.roblox.com/t/coroutines-v-s-spawn-which-one-should-i-use/368966
		Quenty: FastSpawn (AKA SpawnNow) method using BindableEvent

--]]


local EnumList = require(script.Parent.EnumList)

local Thread = {}

local postSimulation = game:GetService("RunService").PostSimulation

Thread.DelayRepeatBehavior = EnumList.new("DelayRepeatBehavior", {
	"Delayed";
	"Immediate";
})


function Thread.SpawnNow(func, ...)
	--[[
		This method was originally written by Quenty and is slightly
		modified for this module. The original source can be found in
		the link below, as well as the MIT license:
			https://github.com/Quenty/NevermoreEngine/blob/version2/Modules/Shared/Utility/fastSpawn.lua
			https://github.com/Quenty/NevermoreEngine/blob/version2/LICENSE.md
	--]]
	local args = table.pack(...)
	local bindable = Instance.new("BindableEvent")
	bindable.Event:Connect(function() func(table.unpack(args, 1, args.n)) end)
	bindable:Fire()
	bindable:Destroy()
end


function Thread.Spawn(func, ...)
	local args = table.pack(...)
	local postSimulationHandle
	postSimulationHandle = postSimulation:Connect(function()
		postSimulationHandle:Disconnect()
		func(table.unpack(args, 1, args.n))
	end)
end


function Thread.Delay(waitTime, func, ...)
	local args = table.pack(...)
	local executeTime = (time() + waitTime)
	local postSimulationHandle
	postSimulationHandle = postSimulation:Connect(function()
		if (time() >= executeTime) then
			postSimulationHandle:Disconnect()
			func(table.unpack(args, 1, args.n))
		end
	end)
	return postSimulationHandle
end


function Thread.DelayRepeat(intervalTime, func, behavior, ...)
	local args = table.pack(...)
	if (behavior == nil) then
		behavior = Thread.DelayRepeatBehavior.Delayed
	end
	assert(Thread.DelayRepeatBehavior:Is(behavior), "Invalid behavior")
	local immediate = (behavior == Thread.DelayRepeatBehavior.Immediate)
	local nextExecuteTime = (time() + (immediate and 0 or intervalTime))
	local postSimulationHandle
	postSimulationHandle = postSimulation:Connect(function()
		if (time() >= nextExecuteTime) then
			nextExecuteTime = (time() + intervalTime)
			func(table.unpack(args, 1, args.n))
		end
	end)
	return postSimulationHandle
end


return Thread