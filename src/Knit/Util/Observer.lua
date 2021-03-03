-- Observer
-- Stephen Leitnick
-- March 03, 2021

--[[

	observer = Observer.new(parent: Instance, childName: string)
	
	observer:Observe(handler: (child: Instance, maid: Maid) -> void)
	observer:Destroy()

--]]


local Knit = require(game:GetService("ReplicatedStorage").Knit)
local Maid = require(Knit.Util.Maid)
local Signal = require(Knit.Util.Signal)
local Thread = require(Knit.Util.Thread)


local Observer = {}
Observer.__index = Observer


function Observer.new(parent, childName)
	local self = setmetatable({}, Observer)
	self._maid = Maid.new()
	self._shown = Signal.new(self._maid)
	self._shownMaid = Maid.new()
	self._maid:GiveTask(self._shownMaid)
	self.Instance = parent:FindFirstChild(childName)
	self._maid:GiveTask(parent.ChildAdded:Connect(function(child)
		if (child.Name == childName and not self.Instance) then
			self.Instance = child
			self._shown:Fire(child, self._shownMaid)
			self._shownMaid:GiveTask(child:GetPropertyChangedSignal("Parent"):Connect(function()
				if (not child.Parent) then
					self._shownMaid:DoCleaning()
				end
			end))
			self._shownMaid:GiveTask(function()
				self.Instance = nil
			end)
		end
	end))
	return self
end


function Observer:Observe(handler)
	self._shown:Connect(handler)
	if (self.Instance) then
		Thread.SpawnNow(handler, self.Instance, self._shownMaid)
	end
end


function Observer:Destroy()
	self._maid:Destroy()
end


return Observer