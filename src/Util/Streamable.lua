--!strict

-- Streamable
-- Stephen Leitnick
-- March 03, 2021

--[[

	streamable = Streamable.new(parent: Instance, childName: string)

	streamable:Observe(handler: (child: Instance, janitor: Janitor) -> void): Connection
	streamable:Destroy()

--]]

type StreamableWithInstance = {
	Instance: Instance?,
	[any]: any,
}

local Janitor = require(script.Parent.Janitor)
local Signal = require(script.Parent.Signal)


local Streamable = {}
Streamable.__index = Streamable


function Streamable.new(parent: Instance, childName: string)

	local self: StreamableWithInstance = {}
	setmetatable(self, Streamable)

	self._janitor = Janitor.new()
	self._shown = Signal.new(self._janitor)
	self._shownJanitor = Janitor.new()
	self._janitor:Add(self._shownJanitor)

	self.Instance = parent:FindFirstChild(childName)

	local function OnInstanceSet()
		local instance = self.Instance
		if typeof(instance) == "Instance" then
			self._shown:Fire(instance, self._shownJanitor)
			self._shownJanitor:Add(instance:GetPropertyChangedSignal("Parent"):Connect(function()
				if not instance.Parent then
					self._shownJanitor:Cleanup()
				end
			end))
			self._shownJanitor:Add(function()
				if self.Instance == instance then
					self.Instance = nil
				end
			end)
		end
	end

	local function OnChildAdded(child: Instance)
		if child.Name == childName and not self.Instance then
			self.Instance = child
			OnInstanceSet()
		end
	end

	self._janitor:Add(parent.ChildAdded:Connect(OnChildAdded))
	if self.Instance then
		OnInstanceSet()
	end

	return self

end


function Streamable:Observe(handler)
	if self.Instance then
		task.spawn(handler, self.Instance, self._shownJanitor)
	end
	return self._shown:Connect(handler)
end


function Streamable:Destroy()
	self._janitor:Destroy()
end


export type Streamable = typeof(Streamable.new(workspace, "X"))


return Streamable
