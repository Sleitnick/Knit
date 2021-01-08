-- ServerRemoteProperty
-- Stephen Leitnick
-- January 07, 2021

--[[

	remoteProperty = RemoteProperty.new(value: any [, overrideClass: string])

	remoteProperty:Get(): any
	remoteProperty:Set(value: any): void
	remoteProperty:Replicate(): void   [Only for table values]
	remoteProperty:Destroy(): void

	remoteProperty.Changed(newValue: any): Connection

--]]


local Signal = require(script.Parent.Parent.Signal)

local IS_SERVER = game:GetService("RunService"):IsServer()

local typeClassMap = {
	boolean = "BoolValue";
	string = "StringValue";
	table = "RemoteEvent";
	CFrame = "CFrameValue";
	Color3 = "Color3Value";
	BrickColor = "BrickColorValue";
	number = "NumberValue";
	Instance = "ObjectValue";
	Ray = "RayValue";
	Vector3 = "Vector3Value";
	["nil"] = "ObjectValue";
}


local ServerRemoteProperty = {}
ServerRemoteProperty.__index = ServerRemoteProperty


function ServerRemoteProperty.Is(object)
	return (type(object) == "table" and getmetatable(object) == ServerRemoteProperty)
end


function ServerRemoteProperty.new(value, overrideClass)

	assert(IS_SERVER, "ServerRemoteProperty can only be created on the server")

	if (overrideClass ~= nil) then
		assert(type(overrideClass) == "string", "OverrideClass must be a string; got " .. type(overrideClass))
		assert(overrideClass:match("Value$"), "OverrideClass must be of super type ValueBase (e.g. IntValue); got " .. overrideClass)
	end

	local t = typeof(value)
	local class = overrideClass or typeClassMap[t]
	assert(class, "RemoteProperty does not support type \"" .. t .. "\"")

	local self = setmetatable({
		_value = value;
		_type = t;
		_isTable = (t == "table");
		_object = Instance.new(class);
	}, ServerRemoteProperty)

	if (self._isTable) then
		local req = Instance.new("RemoteFunction")
		req.Name = "TableRequest"
		req.Parent = self._object
		function req.OnServerInvoke(_player)
			return self._value
		end
		self.Changed = Signal.new()
	else
		self.Changed = self._object.Changed
	end

	self:Set(value)

	return self

end


function ServerRemoteProperty:Replicate()
	if (self._isTable) then
		self:Set(self._value)
	end
end


function ServerRemoteProperty:Set(value)
	if (self._isTable) then
		self._object:FireAllClients(value)
		self.Changed:Fire(value)
	else
		self._object.Value = value
	end
	self._value = value
end


function ServerRemoteProperty:Get()
	return self._value
end


function ServerRemoteProperty:Destroy()
	self._object:Destroy()
end


return ServerRemoteProperty
