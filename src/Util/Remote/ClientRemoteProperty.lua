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
		_isTable = object:IsA("RemoteEvent");
	}, ClientRemoteProperty)

	local function SetValue(v)
		self._value = v
	end

	if self._isTable then
		self.Changed = Signal.new()
		self._change = object.OnClientEvent:Connect(function(tbl)
			SetValue(tbl)
			self.Changed:Fire(tbl)
		end)
		SetValue(object.TableRequest:InvokeServer())
	else
		SetValue(object.Value)
		self.Changed = object.Changed
		self._change = object.Changed:Connect(SetValue)
	end

	return self

end


function ClientRemoteProperty:Get()
	return self._value
end


function ClientRemoteProperty:Destroy()
	self._change:Disconnect()
	if self._isTable then
		self.Changed:Destroy()
	end
end


return ClientRemoteProperty
