-- Timer
-- Stephen Leitnick
-- July 28, 2021

--[[

	timer = Timer.new(interval: number [, janitor: Janitor])

	timer.Tick: Signal

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

--]]


local Signal = require(script.Parent.Signal)

local RunService = game:GetService("RunService")


local Timer = {}
Timer.__index = Timer


function Timer.new(interval: number, janitor)
	assert(type(interval) == "number", "Argument #1 to Timer.new must be a number; got " .. type(interval))
	assert(interval > 0, "Argument #1 to Timer.new must be greater than 0; got " .. tostring(interval))
	local self = setmetatable({}, Timer)
	self._runHandle = nil
	self.Interval = interval
	self.Tick = Signal.new()
	if janitor then
		janitor:Add(self)
	end
	return self
end


function Timer.Is(obj: any): boolean
	return type(obj) == "table" and getmetatable(obj) == Timer
end


function Timer:Start()
	if self._runHandle then return end
	local n = 1
	local start = time()
	local nextTick = start + self.Interval
	self._runHandle = RunService.Heartbeat:Connect(function()
		local now = time()
		while now >= nextTick do
			n += 1
			nextTick = start + (self.Interval * n)
			self.Tick:Fire()
		end
	end)
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
