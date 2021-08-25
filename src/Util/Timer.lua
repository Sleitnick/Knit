-- Timer
-- Stephen Leitnick
-- July 28, 2021

--[[

	timer = Timer.new(interval: number [, janitor: Janitor])
	connection = Timer.Simple(interval: number, callback: () -> void [, updateSignal: Signal = Heartbeat, timeFunc: () -> number = time])

	timer.Tick: Signal
	timer.Interval: number
	timer.UpdateSignal: Signal
	timer.TimeFunction: () -> number
	timer.AllowDrift: boolean

	timer:Start()
	timer:StartNow()
	timer:Stop()
	timer:Destroy()

	------------------------------------

	local timer = Timer.new(2)
	timer.Tick:Connect(function()
		print("Tock")
	end)
	timer:Start()

	Timer.Simple(2, function()
		print("Tock")
	end)

--]]


type CallbackFunc = () -> nil
type TimeFunc = () -> number

local Signal = require(script.Parent.Signal)

local RunService = game:GetService("RunService")


local Timer = {}
Timer.__index = Timer


function Timer.new(interval: number, janitor)
	assert(type(interval) == "number", "Argument #1 to Timer.new must be a number; got " .. type(interval))
	assert(interval >= 0, "Argument #1 to Timer.new must be greater or equal to 0; got " .. tostring(interval))
	local self = setmetatable({}, Timer)
	self._runHandle = nil
	self.Interval = interval
	self.UpdateSignal = RunService.Heartbeat
	self.TimeFunction = time
	self.AllowDrift = true
	self.Tick = Signal.new()
	if janitor then
		janitor:Add(self)
	end
	return self
end


function Timer.Simple(interval: number, callback: CallbackFunc, startNow: boolean?, updateSignal: RBXScriptSignal?, timeFunc: TimeFunc?)
	local update = updateSignal or RunService.Heartbeat
	local t = timeFunc or time
	local nextTick = t() + interval
	if startNow then
		task.defer(callback)
	end
	return update:Connect(function()
		local now = t()
		if now >= nextTick then
			nextTick = now + interval
			task.defer(callback)
		end
	end)
end


function Timer.Is(obj: any): boolean
	return type(obj) == "table" and getmetatable(obj) == Timer
end


function Timer:_startTimer()
	local t = self.TimeFunction
	local nextTick = t() + self.Interval
	self._runHandle = self.UpdateSignal:Connect(function()
		local now = t()
		if now >= nextTick then
			nextTick = now + self.Interval
			self.Tick:Fire()
		end
	end)
end


function Timer:_startTimerNoDrift()
	assert(self.Interval > 0, "Interval must be greater than 0 when AllowDrift is set to false")
	local t = self.TimeFunction
	local n = 1
	local start = t()
	local nextTick = start + self.Interval
	self._runHandle = self.UpdateSignal:Connect(function()
		local now = t()
		while now >= nextTick do
			n += 1
			nextTick = start + (self.Interval * n)
			self.Tick:Fire()
		end
	end)
end


function Timer:Start()
	if self._runHandle then return end
	if self.AllowDrift then
		self:_startTimer()
	else
		self:_startTimerNoDrift()
	end
end


function Timer:StartNow()
	if self._runHandle then return end
	self.Tick:Fire()
	self:Start()
end


function Timer:Stop()
	if not self._runHandle then return end
	self._runHandle:Disconnect()
	self._runHandle = nil
end


function Timer:Destroy()
	self.Tick:Destroy()
	self:Stop()
end


return Timer
