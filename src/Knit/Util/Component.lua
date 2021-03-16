-- Component
-- Stephen Leitnick
-- July 25, 2020

--[[

	Component.Auto(folder)
		-> Create components automatically from descendant modules of this folder
		-> Each module must have a '.Tag' string property
		-> Each module optionally can have '.RenderPriority' number property

	component = Component.FromTag(tag)
		-> Retrieves an existing component from the tag name

	component = Component.new(tag, class [, renderPriority])
		-> Creates a new component from the tag name, class module, and optional render priority

	component:GetAll()
	component:GetFromInstance(instance)
	component:GetFromID(id)
	component:Filter(filterFunc)
	component:WaitFor(instanceOrName)
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

		-- FIELDS AFTER CONSTRUCTOR COMPLETES
		MyComponent.Instance: Instance

		-- OPTIONAL LIFECYCLE HOOKS
		function MyComponent:Init() end                          -> Called right after constructor
		function MyComponent:Deinit() end                        -> Called right before deconstructor
		function MyComponent:PreAnimationUpdate(dt) ... end      -> Called before the animation step in the runtime pipeline
		function MyComponent:PreRenderUpdate(dt) ... end         -> Called before the render step in the runtime pipeline
		function MyComponent:PreSimulationUpdate(dt) ... end     -> Called before physics calculations in the runtime pipeline
		function MyComponent:PostSimulationUpdate(dt) ... end    -> Called after physics calculations in the runtime pipeline
		function MyComponent:RenderUpdate(dt)                    -> Bound to RenderStep with the given RenderPriority from the component constructor

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


local Maid = require(script.Parent.Maid)
local Signal = require(script.Parent.Signal)
local Promise = require(script.Parent.Promise)
local Thread = require(script.Parent.Thread)
local TableUtil = require(script.Parent.TableUtil)
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local IS_SERVER = RunService:IsServer()
local DEFAULT_WAIT_FOR_TIMEOUT = 60
local ATTRIBUTE_ID_NAME = "ComponentServerId"

-- Components will only work on instances parented under these descendants:
local DESCENDANT_WHITELIST = {workspace, Players}

local Component = {}
Component.__index = Component

local componentsByTag = {}


local function FastRemove(tbl, i)
	local n = #tbl
	tbl[i] = tbl[n]
	tbl[n] = nil
end


local function IsDescendantOfWhitelist(instance)
	for _,v in ipairs(DESCENDANT_WHITELIST) do
		if (instance:IsDescendantOf(v)) then
			return true
		end
	end
	return false
end


function Component.FromTag(tag)
	return componentsByTag[tag]
end


function Component.Auto(folder)
	local function Setup(moduleScript)
		local m = require(moduleScript)
		assert(type(m) == "table", "Expected table for component")
		assert(type(m.Tag) == "string", "Expected .Tag property")
		Component.new(m.Tag, m, m.RenderPriority)
	end
	for _,v in ipairs(folder:GetDescendants()) do
		if (v:IsA("ModuleScript")) then
			Setup(v)
		end
	end
	folder.DescendantAdded:Connect(function(v)
		if (v:IsA("ModuleScript")) then
			Setup(v)
		end
	end)
end


function Component.new(tag, class, renderPriority)

	assert(type(tag) == "string", "Argument #1 (tag) should be a string; got " .. type(tag))
	assert(type(class) == "table", "Argument #2 (class) should be a table; got " .. type(class))
	assert(type(class.new) == "function", "Class must contain a .new constructor function")
	assert(type(class.Destroy) == "function", "Class must contain a :Destroy function")
	assert(componentsByTag[tag] == nil, "Component already bound to this tag")

	local self = setmetatable({}, Component)

	self.Added = Signal.new()
	self.Removed = Signal.new()

	self._maid = Maid.new()
	self._lifecycleMaid = Maid.new()
	self._tag = tag
	self._class = class
	self._objects = {}
	self._instancesToObjects = {}
	self._hasPreAnimation = (type(class.PreAnimationUpdate) == "function")
	self._hasPreRender = (type(class.PreRenderUpdate) == "function")
	self._hasPreSimulation = (type(class.PreSimulationUpdate) == "function")
	self._hasPostSimulation = (type(class.PostSimulationUpdate) == "function")
	self._hasRender = (type(class.RenderUpdate) == "function")
	self._hasInit = (type(class.Init) == "function")
	self._hasDeinit = (type(class.Deinit) == "function")
	self._renderPriority = renderPriority or Enum.RenderPriority.Last.Value
	self._lifecycle = false
	self._nextId = 0

	self._maid:GiveTask(CollectionService:GetInstanceAddedSignal(tag):Connect(function(instance)
		if (IsDescendantOfWhitelist(instance)) then
			self:_instanceAdded(instance)
		end
	end))

	self._maid:GiveTask(CollectionService:GetInstanceRemovedSignal(tag):Connect(function(instance)
		self:_instanceRemoved(instance)
	end))

	self._maid:GiveTask(self._lifecycleMaid)

	do
		local b = Instance.new("BindableEvent")
		for _,instance in ipairs(CollectionService:GetTagged(tag)) do
			if (IsDescendantOfWhitelist(instance)) then
				local c = b.Event:Connect(function()
					self:_instanceAdded(instance)
				end)
				b:Fire()
				c:Disconnect()
			end
		end
		b:Destroy()
	end

	componentsByTag[tag] = self
	self._maid:GiveTask(function()
		componentsByTag[tag] = nil
	end)

	return self

end


function Component:_startPreAnimationUpdate()
	local all = self._objects
	self._lifecycleMaid:GiveTask(RunService.PreAnimation:Connect(function(dt)
		for _,v in ipairs(all) do
			v:PreAnimationUpdate(dt)
		end
	end))
end


function Component:_startPreRenderUpdate()
	local all = self._objects
	self._lifecycleMaid:GiveTask(RunService.PreRender:Connect(function(dt)
		for _,v in ipairs(all) do
			v:PreRenderUpdate(dt)
		end
	end))
end


function Component:_startPreSimulationUpdate()
	local all = self._objects
	self._lifecycleMaid:GiveTask(RunService.PreSimulation:Connect(function(dt)
		for _,v in ipairs(all) do
			v:PreSimulationUpdate(dt)
		end
	end))
end


function Component:_startPostSimulationUpdate()
	local all = self._objects
	self._lifecycleMaid:GiveTask(RunService.PostSimulation:Connect(function(dt)
		for _,v in ipairs(all) do
			v:PostSimulationUpdate(dt)
		end
	end))
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
	if (self._hasPreAnimation) then
		self:_startPreAnimationUpdate()
	end
	if (self._hasPreRender) then
		self:_startPreRenderUpdate()
	end
	if (self._hasPreSimulation) then
		self:_startPreSimulationUpdate()
	end
	if (self._hasPostSimulation) then
		self:_startPostSimulationUpdate()
	end
	if (self._hasRender) then
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
	self._nextId = (self._nextId + 1)
	local id = (self._tag .. tostring(self._nextId))
	if (IS_SERVER) then
		instance:SetAttribute(ATTRIBUTE_ID_NAME, id)
	end
	local obj = self._class.new(instance)
	obj.Instance = instance
	obj._id = id
	self._instancesToObjects[instance] = obj
	table.insert(self._objects, obj)
	if (self._hasInit) then
		Thread.Spawn(function()
			if (self._instancesToObjects[instance] ~= obj) then return end
			obj:Init()
		end)
	end
	self.Added:Fire(obj)
	return obj
end


function Component:_instanceRemoved(instance)
	self._instancesToObjects[instance] = nil
	for i,obj in ipairs(self._objects) do
		if (obj.Instance == instance) then
			if (self._hasDeinit) then
				obj:Deinit()
			end
			if (IS_SERVER and instance.Parent and instance:GetAttribute(ATTRIBUTE_ID_NAME) ~= nil) then
				instance:SetAttribute(ATTRIBUTE_ID_NAME, nil)
			end
			self.Removed:Fire(obj)
			obj:Destroy()
			obj._destroyed = true
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


function Component:WaitFor(instance, timeout)
	local isName = (type(instance) == "string")
	local function IsInstanceValid(obj)
		return ((isName and obj.Instance.Name == instance) or ((not isName) and obj.Instance == instance))
	end
	for _,obj in ipairs(self._objects) do
		if (IsInstanceValid(obj)) then
			return Promise.resolve(obj)
		end
	end
	local lastObj = nil
	return Promise.FromEvent(self.Added, function(obj)
		lastObj = obj
		return IsInstanceValid(obj)
	end):Then(function()
		return lastObj
	end):Timeout(timeout or DEFAULT_WAIT_FOR_TIMEOUT)
end


function Component:Destroy()
	self._maid:Destroy()
end


return Component