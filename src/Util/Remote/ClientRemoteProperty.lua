-- ClientRemoteProperty
-- Stephen Leitnick
-- January 07, 2021

--[[

	remoteProperty = ClientRemoteProperty.new(valueObject: Instance)

	remoteProperty:Get(): any
	remoteProperty:Destroy(): void

	remoteProperty.Changed(newValue: any): Connection

--]]


local IS_SERVER = game:GetService("RunService"):IsServer()
local Signal = require(script.Parent.Parent.Signal)

local ClientRemoteProperty = {}
ClientRemoteProperty.__index = ClientRemoteProperty


function ClientRemoteProperty.new(object)

	assert(not IS_SERVER, "ClientRemoteProperty can only be created on the client")

	local self = setmetatable({
		_object = object;
		_value = nil;
	}, ClientRemoteProperty)

	local function SetValue(v)
		self._value = v
	end

	self.Changed = Signal.new()

	SetValue(object.GetValue:InvokeServer())
	self._changed = object.OnClientEvent:Connect(function(newValue)
		SetValue(newValue)
		self.Changed:Fire(newValue)
	end)

	return self

end


function ClientRemoteProperty:Get()
	return self._value
end


function ClientRemoteProperty:Destroy()
	self._change:Disconnect()
	self.Changed:Destroy()
end


return ClientRemoteProperty
