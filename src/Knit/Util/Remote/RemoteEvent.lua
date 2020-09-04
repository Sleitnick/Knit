-- RemoteEvent
-- Stephen Leitnick

--[[
	
	[Server]
		event = RemoteEvent.new()
		event:Fire(player, ...)
		event:FireAll(...)
		event:FireExcept(player, ...)
		event:Wait()
		event:Destroy()
		connection = event:Connect(functionHandler(player, ...))
		connection:Disconnect()
		connection:IsConnected()

	[Client]
		event = RemoteEvent.new(remoteEventObject)
		event:Fire(...)
		event:Wait()
		event:Destroy()
		connection = event:Connect(functionHandler(...))
		connection:Disconnect()
		connection:IsConnected()

--]]

local IS_SERVER = game:GetService("RunService"):IsServer()

local Players = game:GetService("Players")
local Ser = require(script.Parent.Parent.Ser)

local RemoteEvent = {}
RemoteEvent.__index = RemoteEvent

function RemoteEvent.Is(object)
	return (type(object) == "table" and getmetatable(object) == RemoteEvent)
end

if (IS_SERVER) then

	function RemoteEvent.new()
		local self = setmetatable({
			_remote = Instance.new("RemoteEvent");
		}, RemoteEvent)
		return self
	end

	function RemoteEvent:Fire(player, ...)
		self._remote:FireClient(player, Ser.SerializeArgsAndUnpack(...))
	end

	function RemoteEvent:FireAll(...)
		self._remote:FireAllClients(Ser.SerializeArgsAndUnpack(...))
	end

	function RemoteEvent:FireExcept(player, ...)
		local args = Ser.SerializeArgs(...)
		for _,plr in ipairs(Players:GetPlayers()) do
			if (plr ~= player) then
				self._remote:FireClient(plr, Ser.UnpackArgs(args))
			end
		end
	end

	function RemoteEvent:Wait()
		return self._remote.OnServerEvent:Wait()
	end

	function RemoteEvent:Connect(handler)
		return self._remote.OnServerEvent:Connect(function(player, ...)
			handler(player, Ser.DeserializeArgsAndUnpack(...))
		end)
	end

	function RemoteEvent:Destroy()
		self._remote:Destroy()
		self._remote = nil
	end

else

	local Connection = {}
	Connection.__index = Connection

	function Connection.new(event, connection)
		local self = setmetatable({
			_conn = connection;
			_event = event;
			Connected = true;
		}, Connection)
		return self
	end

	function Connection:IsConnected()
		if (self._conn) then
			return self._conn.Connected
		end
		return false
	end

	function Connection:Disconnect()
		if (self._conn) then
			self._conn:Disconnect()
			self._conn = nil
		end
		if (not self._event) then return end
		self.Connected = false
		local connections = self._event._connections
		for i,c in ipairs(connections) do
			if (c == self) then
				connections[i] = connections[#connections]
				connections[#connections] = nil
				break
			end
		end
		self._event = nil
	end

	Connection.Destroy = Connection.Disconnect

	function RemoteEvent.new(remoteEvent)
		assert(typeof(remoteEvent) == "Instance", "Argument #1 (RemoteEvent) expected Instance; got " .. typeof(remoteEvent))
		assert(remoteEvent:IsA("RemoteEvent"), "Argument #1 (RemoteEvent) expected RemoteEvent; got" .. remoteEvent.ClassName)
		local self = setmetatable({
			_remote = remoteEvent;
			_connections = {};
		}, RemoteEvent)
		return self
	end

	function RemoteEvent:Fire(...)
		self._remote:FireServer(Ser.SerializeArgsAndUnpack(...))
	end

	function RemoteEvent:Wait()
		return Ser.DeserializeArgsAndUnpack(self._remote.OnClientEvent:Wait())
	end

	function RemoteEvent:Connect(handler)
		local connection = Connection.new(self, self._remote.OnClientEvent:Connect(function(...)
			handler(Ser.DeserializeArgsAndUnpack(...))
		end))
		table.insert(self._connections, connection)
		return connection
	end

	function RemoteEvent:Destroy()
		for _,c in ipairs(self._connections) do
			if (c._conn) then
				c._conn:Disconnect()
			end
		end
		self._connections = nil
		self._remote = nil
	end

end

return RemoteEvent