-- Component
-- Stephen Leitnick
-- July 25, 2020

--[[

	Component.Auto(folder: Instance)
		-> Create components automatically from descendant modules of this folder
		-> Each module must have a '.Tag' string property
		-> Each module optionally can have '.RenderPriority' number property

	component = Component.FromTag(tag: string)
		-> Retrieves an existing component from the tag name

	Component.ObserveFromTag(tag: string, observer: (component: Component, maid: Maid) -> void): Maid

	component = Component.new(tag: string, class: table [, renderPriority: RenderPriority, requireComponents: {string}])
		-> Creates a new component from the tag name, class module, and optional render priority

	component:GetAll(): ComponentInstance[]
	component:GetFromInstance(instance: Instance): ComponentInstance | nil
	component:GetFromID(id: number): ComponentInstance | nil
	component:Filter(filterFunc: (comp: ComponentInstance) -> boolean): ComponentInstance[]
	component:WaitFor(instanceOrName: Instance | string [, timeout: number = 60]): Promise<ComponentInstance>
	component:Observe(instance: Instance, observer: (component: ComponentInstance, maid: Maid) -> void): Maid
	component:Destroy()

	component.Added(obj: ComponentInstance)
	component.Removed(obj: ComponentInstance)

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

local componentByTagCreated = Signal.new()
local componentByTagDestroyed = Signal.new()


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


function Component.ObserveFromTag(tag, observer)
	local maid = Maid.new()
	local observeMaid = Maid.new()
	maid:GiveTask(observeMaid)
	local function OnCreated(component)
		if (component._tag == tag) then
			observer(component, observeMaid)
		end
	end
	local function OnDestroyed(component)
		if (component._tag == tag) then
			observeMaid:DoCleaning()
		end
	end
	do
		local component = Component.FromTag(tag)
		if (component) then
			Thread.SpawnNow(OnCreated, component)
		end
	end
	maid:GiveTask(componentByTagCreated:Connect(OnCreated))
	maid:GiveTask(componentByTagDestroyed:Connect(OnDestroyed))
	return maid
end


function Component.Auto(folder)
	local function Setup(moduleScript)
		local m = require(moduleScript)
		assert(type(m) == "table", "Expected table for component")
		assert(type(m.Tag) == "string", "Expected .Tag property")
		Component.new(m.Tag, m, m.RenderPriority, m.RequiredComponents)
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


function Component.new(tag, class, renderPriority, requireComponents)

	assert(type(tag) == "string", "Argument #1 (tag) should be a string; got " .. type(tag))
	assert(type(class) == "table", "Argument #2 (class) should be a table; got " .. type(class))
	assert(type(class.new) == "function", "Class must contain a .new constructor function")
	assert(type(class.Destroy) == "function", "Class must contain a :Destroy function")
	assert(componentsByTag[tag] == nil, "Component already bound to this tag")

	local self = setmetatable({}, Component)

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
	self._requireComponents = requireComponents or {}
	self._lifecycle = false
	self._nextId = 0

	self.Added = Signal.new(self._maid)
	self.Removed = Signal.new(self._maid)

	local observeMaid = Maid.new()
	self._maid:GiveTask(observeMaid)

	local function ObserveTag()

		local function HasRequiredComponents(instance)
			for _,reqComp in ipairs(self._requireComponents) do
				local comp = Component.FromTag(reqComp)
				if (comp:GetFromInstance(instance) == nil) then
					return false
				end
			end
			return true
		end

		observeMaid:GiveTask(CollectionService:GetInstanceAddedSignal(tag):Connect(function(instance)
			if (IsDescendantOfWhitelist(instance) and HasRequiredComponents(instance)) then
				self:_instanceAdded(instance)
			end
		end))

		observeMaid:GiveTask(CollectionService:GetInstanceRemovedSignal(tag):Connect(function(instance)
			self:_instanceRemoved(instance)
		end))

		for _,reqComp in ipairs(self._requireComponents) do
			local comp = Component.FromTag(reqComp)
			observeMaid:GiveTask(comp.Added:Connect(function(obj)
				if (CollectionService:HasTag(obj.Instance, tag) and HasRequiredComponents(obj.Instance)) then
					self:_instanceAdded(obj.Instance)
				end
			end))
			observeMaid:GiveTask(comp.Removed:Connect(function(obj)
				if (CollectionService:HasTag(obj.Instance, tag)) then
					self:_instanceRemoved(obj.Instance)
				end
			end))
		end

		observeMaid:GiveTask(function()
			self:_stopLifecycle()
			for instance in pairs(self._instancesToObjects) do
				self:_instanceRemoved(instance)
			end
		end)

		do
			local b = Instance.new("BindableEvent")
			for _,instance in ipairs(CollectionService:GetTagged(tag)) do
				if (IsDescendantOfWhitelist(instance) and HasRequiredComponents(instance)) then
					local c = b.Event:Connect(function()
						self:_instanceAdded(instance)
					end)
					b:Fire()
					c:Disconnect()
				end
			end
			b:Destroy()
		end

	end

	if (#self._requireComponents == 0) then
		ObserveTag()
	else
		-- Only observe tag when all required components are available:
		local tagsReady = {}
		local function Check()
			for _,ready in pairs(tagsReady) do
				if (not ready) then
					return
				end
			end
			ObserveTag()
		end
		local function Cleanup()
			observeMaid:DoCleaning()
		end
		for _,requiredComponent in ipairs(self._requireComponents) do
			tagsReady[requiredComponent] = false
			self._maid:GiveTask(Component.ObserveFromTag(requiredComponent, function(_component, maid)
				tagsReady[requiredComponent] = true
				Check()
				maid:GiveTask(function()
					tagsReady[requiredComponent] = false
					Cleanup()
				end)
			end))
		end
	end

	componentsByTag[tag] = self
	componentByTagCreated:Fire(self)
	self._maid:GiveTask(function()
		componentsByTag[tag] = nil
		componentByTagDestroyed:Fire(self)
	end)

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
	if (not self._instancesToObjects[instance]) then return end
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
			TableUtil.FastRemove(self._objects, i)
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
			return Promise.Resolve(obj)
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


function Component:Observe(instance, observer)
	local maid = Maid.new()
	local observeMaid = Maid.new()
	maid:GiveTask(observeMaid)
	maid:GiveTask(self.Added:Connect(function(obj)
		if (obj.Instance == instance) then
			observer(obj, observeMaid)
		end
	end))
	maid:GiveTask(self.Removed:Connect(function(obj)
		if (obj.Instance == instance) then
			observeMaid:DoCleaning()
		end
	end))
	for _,obj in ipairs(self._objects) do
		if (obj.Instance == instance) then
			Thread.SpawnNow(observer, obj, observeMaid)
			break
		end
	end
	return maid
end


function Component:Destroy()
	self._maid:Destroy()
end


return Component