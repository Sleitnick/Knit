-- Component
-- Stephen Leitnick
-- July 25, 2020

--[[

	component = Component.new(tag, class [, renderPriority])

	component:GetAll()
	component:GetFromInstance(instance)
	component:GetFromID(id)
	component:Filter(filterFunc)
	component:Destroy()

	component.Added(obj)
	component.Removed(obj)

	-----------------------------------------------------------------------

	A component class must look something like this:

		-- DEFINE
		local MyComponent = {}
		MyComponent.__index = MyComponent

		-- CONSTRUCTOR
		function MyComponent.new(instance)
			local self = setmetatable({}, MyComponent)
			return self
		end

		-- OPTIONAL LIFECYCLE HOOKS
		function MyComponent:Init() end                     -> Called right after constructor
		function MyComponent:Deinit() end                   -> Called right before deconstructor
		function MyComponent:HeartbeatUpdate(dt) ... end    -> Updates every heartbeat
		function MyComponent:SteppedUpdate(dt) ... end      -> Updates every physics step
		function MyComponent:RenderUpdate(dt) ... end       -> Updates every render step

		-- DESTRUCTOR
		function MyComponent:Destroy()
		end


	A component is then registered like so:
		
		local Component = require(Knit.Util.Component)
		local MyComponent = require(somewhere.MyComponent)
		local tag = "MyComponent"

		local myComponent = Component.new(tag, MyComponent)


	Components can be listened and queried:

		myComponent.Added:Connect(function(instanceOfComponent)
			-- New MyComponent constructed
		end)

		myComponent.Removed:Connect(function(instanceOfComponent)
			-- New MyComponent deconstructed
		end)

--]]


local Knit = require(game:GetService("ReplicatedStorage").Knit)
local Maid = require(Knit.Util.Maid)
local Signal = require(Knit.Util.Signal)
local TableUtil = require(Knit.Util.TableUtil)
local CollectionService = game:GetService("CollectionService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local Component = {}
Component.__index = Component


local function FastRemove(tbl, i)
	local n = #tbl
	tbl[i] = tbl[n]
	tbl[n] = nil
end


function Component.new(tag, class, renderPriority)

	assert(type(tag) == "string", "Argument #1 (tag) should be a string; got " .. type(tag))
	assert(type(class) == "table", "Argument #2 (class) should be a table; got " .. type(class))
	assert(type(class.new) == "function", "Class must contain a .new constructor function")
	assert(type(class.Destroy) == "function", "Class must contain a :Destroy function")

	local self = setmetatable({}, Component)

	self.Added = Signal.new()
	self.Removed = Signal.new()

	self._maid = Maid.new()
	self._lifecycleMaid = Maid.new()
	self._tag = tag
	self._class = class
	self._objects = {}
	self._instancesToObjects = {}
	self._hasHeartbeatUpdate = (type(class.HeartbeatUpdate) == "function")
	self._hasSteppedUpdate = (type(class.SteppedUpdate) == "function")
	self._hasRenderUpdate = (type(class.RenderUpdate) == "function")
	self._hasInit = (type(class.Init) == "function")
	self._hasDeinit = (type(class.Deinit) == "function")
	self._renderPriority = renderPriority or Enum.RenderPriority.Last.Value
	self._lifecycle = false

	self._maid:GiveTask(CollectionService:GetInstanceAddedSignal(tag):Connect(function(instance)
		self:_instanceAdded(instance)
	end))

	self._maid:GiveTask(CollectionService:GetInstanceRemovedSignal(tag):Connect(function(instance)
		self:_instanceRemoved(instance)
	end))

	self._maid:GiveTask(self._lifecycleMaid)

	do
		local b = Instance.new("BindableEvent")
		for _,instance in ipairs(CollectionService:GetTagged(tag)) do
			local c = b.Event:Connect(function()
				self:_instanceAdded(instance)
			end)
			b:Fire()
			c:Disconnect()
		end
		b:Destroy()
	end

	return self

end


function Component:_startHeartbeatUpdate()
	local all = self._objects
	self._heartbeatUpdate = RunService.Heartbeat:Connect(function(dt)
		for _,v in ipairs(all) do
			v:HeartbeatUpdate(dt)
		end
	end)
	self._lifecycleMaid:GiveTask(self._heartbeatUpdate)
end


function Component:_startSteppedUpdate()
	local all = self._objects
	self._steppedUpdate = RunService.Stepped:Connect(function(_, dt)
		for _,v in ipairs(all) do
			v:SteppedUpdate(dt)
		end
	end)
	self._lifecycleMaid:GiveTask(self._steppedUpdate)
end


function Component:_startRenderUpdate()
	local all = self._objects
	self._renderName = (self._tag .. "RenderUpdate")
	RunService:BindToRenderStep(self._renderName, self._renderPriority, function(dt)
		for _,v in ipairs(all) do
			v:RenderUpdate(dt)
		end
	end)
	self._lifecycleMaid:GiveTask(function()
		RunService:UnbindFromRenderStep(self._renderName)
	end)
end


function Component:_startLifecycle()
	self._lifecycle = true
	if (self._hasHeartbeatUpdate) then
		self:_startHeartbeatUpdate()
	end
	if (self._hasSteppedUpdate) then
		self:_startSteppedUpdate()
	end
	if (self._hasRenderUpdate) then
		self:_startRenderUpdate()
	end
end


function Component:_stopLifecycle()
	self._lifecycle = false
	self._lifecycleMaid:DoCleaning()
end


function Component:_instanceAdded(instance)
	if (self._instancesToObjects[instance]) then return end
	if (not self._lifecycle) then
		self:_startLifecycle()
	end
	local id = HttpService:GenerateGUID(false)
	local obj = self._class.new(instance)
	obj._instance = instance
	obj._id = id
	self._instancesToObjects[instance] = obj
	table.insert(self._objects, obj)
	if (self._hasInit) then
		obj:Init()
	end
	self.Added:Fire(obj)
	return obj
end


function Component:_instanceRemoved(instance)
	self._instancesToObjects[instance] = nil
	for i,obj in ipairs(self._objects) do
		if (obj._instance == instance) then
			if (self._hasDeinit) then
				obj:Deinit()
			end
			self.Removed:Fire(obj)
			obj:Destroy()
			FastRemove(self._objects, i)
			break
		end
	end
	if (#self._objects == 0 and self._lifecycle) then
		self:_stopLifecycle()
	end
end


function Component:GetAll()
	return TableUtil.CopyShallow(self._objects)
end


function Component:GetFromInstance(instance)
	return self._instancesToObjects[instance]
end


function Component:GetFromID(id)
	for _,v in ipairs(self._objects) do
		if (v._id == id) then
			return v
		end
	end
	return nil
end


function Component:Filter(filterFunc)
	return TableUtil.Filter(self._objects, filterFunc)
end


function Component:Destroy()
	self._maid:Destroy()
end


return Component