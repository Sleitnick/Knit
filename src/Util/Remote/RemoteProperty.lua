-- RemoteProperty
-- Stephen Leitnick
-- January 07, 2021

--[[

	remoteProperty = RemoteProperty.new(value: any [, overrideClass: string])

	remoteProperty:Get(): any
	remoteProperty:Set(value: any): void
	remoteProperty:Replicate(): void   [Only for table values]
	remoteProperty:GetForPlayer(player: Player): any
	remoteProperty:SetForPlayer(player: Player, value: any)
	remoteProperty:ReplicateForPlayer(player: Player, value: any)
	remoteProperty:Destroy(): void

	remoteProperty.Changed(newValue: any [, player: Player]): Connection


	remoteProperty = RemoteProperty.new(defaultValue: any)

	remoteProperty:SetDefault(value: any): void
	remoteProperty:SetAll(value: any): void
	remoteProperty:SetForPlayer(player: Player, value: any): void
	remoteProperty:GetDefault(): any
	remoteProperty:GetForPlayer(player: Player): any
	remoteProperty:GetForPlayerOrDefault(player: Player): any
	remoteProperty:ReplicateForPlayer(player: Player): any
	remoteProperty:ReplicateAll(): any
	remoteProperty:Destroy()

--]]


local Signal = require(script.Parent.Parent.Signal)

local IS_SERVER = game:GetService("RunService"):IsServer()

-- local typeClassMap = {
-- 	boolean = "BoolValue";
-- 	string = "StringValue";
-- 	table = "RemoteEvent";
-- 	CFrame = "CFrameValue";
-- 	Color3 = "Color3Value";
-- 	BrickColor = "BrickColorValue";
-- 	number = "NumberValue";
-- 	Instance = "ObjectValue";
-- 	Ray = "RayValue";
-- 	Vector3 = "Vector3Value";
-- 	["nil"] = "ObjectValue";
-- }


local RemoteProperty = {}
RemoteProperty.__index = RemoteProperty


function RemoteProperty.Is(object)
	return (type(object) == "table" and getmetatable(object) == RemoteProperty)
end


--[[


function RemoteProperty.new(value, overrideClass)

	assert(IS_SERVER, "RemoteProperty can only be created on the server")

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
	}, RemoteProperty)

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


function RemoteProperty:Replicate(player)
	if (self._isTable) then
		self:Set(self._value, player)
	end
end


function RemoteProperty:Set(value, player)
	if (self._isTable) then
		self._object:FireAllClients(value)
		self.Changed:Fire(value)
	else
		self._object.Value = value
	end
	self._value = value
end


function RemoteProperty:Get()
	return self._value
end


function RemoteProperty:Destroy()
	self._object:Destroy()
end


]]


function RemoteProperty.new(defaultValue)

	assert(IS_SERVER, "RemoteProperty can only be created on the server")

	local self = setmetatable({}, RemoteProperty)

	self._remote = Instance.new("RemoteEvent")
	self._func = Instance.new("RemoteFunction")
	self._func.Name = "GetValue"
	self._func.Parent = self._remote

	self._defaultValue = defaultValue
	self._valuePerPlayer = {}

	self._func.OnServerInvoke = function(player)
		return self:GetForPlayerOrDefault(player)
	end

	self._playerLeave = game:GetService("Players").PlayerRemoving:Connect(function(player)
		self._valuePerPlayer[player] = nil
	end)

	self.DefaultChanged = Signal.new()
	self.PlayerChanged = Signal.new()

	return self

end


function RemoteProperty:SetDefault(value)
	if (value ~= self._defaultValue) then
		self._defaultValue = value
		self.DefaultChanged:Fire(value)
	end
end


function RemoteProperty:SetAll(value)
	self:SetDefault(value)
	for player in pairs(self._valuePerPlayer) do
		self:Set(player, value)
	end
end


function RemoteProperty:SetForPlayer(player, value)
	assert(typeof(player) == "Instance" and player:IsA("Player"), "Argument #1 for RemoteProperty:SetForPlayer must be a Player")
	local oldValue = self._valuePerPlayer[player]
	if (value ~= oldValue) then
		self._valuePerPlayer[player] = value
		self.PlayerChanged:Fire(player, value)
		self:ReplicateForPlayer(player)
	end
end


function RemoteProperty:GetDefault()
	return self._defaultValue
end


function RemoteProperty:GetForPlayer(player)
	assert(typeof(player) == "Instance" and player:IsA("Player"), "Argument #1 for RemoteProperty:GetForPlayer must be a Player")
	return self._valuePerPlayer[player]
end


function RemoteProperty:GetForPlayerOrDefault(player)
	assert(typeof(player) == "Instance" and player:IsA("Player"), "Argument #1 for RemoteProperty:GetForPlayerOrDefault must be a Player")
	local value = self:GetForPlayer(player)
	if (value == nil) then
		value = self._defaultValue
	end
	return value
end


function RemoteProperty:ReplicateForPlayer(player)
	assert(typeof(player) == "Instance" and player:IsA("Player"), "Argument #1 for RemoteProperty:ReplicateForPlayer must be a Player")
	self._remote:FireClient(player, self:GetForPlayerOrDefault(player))
end


function RemoteProperty:ReplicateAll()
	for player in pairs(self._valuePerPlayer) do
		self:ReplicateForPlayer(player)
	end
end


function RemoteProperty:Destroy()
	self._remote:Destroy()
	self._playerLeave:Disconnect()
	self.DefaultChanged:Destroy()
	self.PlayerChanged:Destroy()
end


return RemoteProperty
