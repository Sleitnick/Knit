-- Streamable
-- Stephen Leitnick
-- March 03, 2021

--[[

	streamable = Streamable.new(parent: Instance, childName: string)
	
	streamable:Observe(handler: (child: Instance, maid: Maid) -> void): Connection
	streamable:Destroy()

--]]


local Maid = require(script.Parent.Maid)
local Signal = require(script.Parent.Signal)
local Thread = require(script.Parent.Thread)


local Streamable = {}
Streamable.__index = Streamable


function Streamable.new(parent, childName)
	local self = setmetatable({}, Streamable)
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


function Streamable:Observe(handler)
	if (self.Instance) then
		Thread.SpawnNow(handler, self.Instance, self._shownMaid)
	end
	return self._shown:Connect(handler)
end


function Streamable:Destroy()
	self._maid:Destroy()
end


return Streamable