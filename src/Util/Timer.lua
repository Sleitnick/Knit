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


local Knit = require(game:GetService("ReplicatedStorage").Knit)
local Signal = require(Knit.Util.Signal)

local RunService = game:GetService("RunService")


local Timer = {}
Timer.__index = Timer


function Timer.new(interval: number, janitor)
	assert(type(interval) == "number", "Argument #1 to Timer.new must be a number; got " .. type(interval))
	assert(interval > 0, "Argument #1 to Timer.new must be greater than 0; got " .. tostring(interval))
	local self = setmetatable({}, Timer)
	self._runHandle = nil
	self.Interval = interval
	self.Index = 0
	self.Second = Signal.new()
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
	local realIndex = 0
	self.Index = 0
	self.Second:Fire(self.Index, realIndex)
	self._runHandle = RunService.Heartbeat:Connect(function()
		local now = time()		

		if now >= start + realIndex then
			self.Index = (self.Index + 1) % self.Interval
			realIndex += 1
			self.Second:Fire(self.Index, realIndex)
		end

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
	self.Second:Destroy()
	self:Stop()
end


return Timer
