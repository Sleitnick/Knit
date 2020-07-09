-- RemoteProperty
-- Stephen Leitnick

--[[

	[Server]

		property = RemoteProperty.new(value [, overrideClass])

		property:Get()
		property:Set(value)
		property:Destroy()

		property.Changed(newValue)


	[Client]

		property = RemoteProperty.new(valueObject)

		property:Get()
		property:Destroy()

		property.Changed(newValue)

--]]

local IS_SERVER = game:GetService("RunService"):IsServer()

local typeClassMap = {
	bool = "BoolValue";
	string = "StringValue";
	CFrame = "CFrameValue";
	Color3 = "Color3Value";
	BrickColor = "BrickColorValue";
	number = "NumberValue";
	Instance = "ObjectValue";
	Ray = "RayValue";
	Vector3 = "Vector3Value";
	["nil"] = "ObjectValue";
}

local RemoteProperty = {}
RemoteProperty.__index = RemoteProperty

function RemoteProperty.Is(object)
	return (type(object) == "table" and getmetatable(object) == RemoteProperty)
end

if (IS_SERVER) then

	function RemoteProperty.new(value, overrideClass)

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
			_object = Instance.new(class);
		}, RemoteProperty)

		self.Changed = self._object.Changed
		self._object.Value = value

		return self

	end

	function RemoteProperty:Set(value)
		self._object.Value = value
		self._value = value
	end

	function RemoteProperty:Get()
		return self._value
	end

	function RemoteProperty:Destroy()
		self._object:Destroy()
	end

else

	function RemoteProperty.new(object)
		local self = setmetatable({
			_object = object;
			_value = object.Value;
		}, RemoteProperty)
		self._change = object.Changed:Connect(function(v)
			self._value = v
		end)
		self.Changed = object.Changed
		return self
	end

	function RemoteProperty:Get()
		return self._value
	end

	function RemoteProperty:Destroy()
		self._change:Disconnect()
		self._set:Destroy()
	end

end

return RemoteProperty