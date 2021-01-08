-- RemoteSignal
-- Stephen Leitnick

--[[
	
	[Server]
		remoteSignal = RemoteSignal.new()
		remoteSignal:Fire(player, ...)
		remoteSignal:FireAll(...)
		remoteSignal:FireExcept(player, ...)
		remoteSignal:Wait()
		remoteSignal:Destroy()
		connection = remoteSignal:Connect(functionHandler(player, ...))
		connection:Disconnect()
		connection:IsConnected()

	[Client]
		remoteSignal = RemoteSignal.new(remoteEventObject)
		remoteSignal:Fire(...)
		remoteSignal:Wait()
		remoteSignal:Destroy()
		connection = remoteSignal:Connect(functionHandler(...))
		connection:Disconnect()
		connection:IsConnected()

--]]

local IS_SERVER = game:GetService("RunService"):IsServer()

local Players = game:GetService("Players")
local Ser = require(script.Parent.Parent.Ser)

local RemoteSignal = {}
RemoteSignal.__index = RemoteSignal

function RemoteSignal.Is(object)
	return (type(object) == "table" and getmetatable(object) == RemoteSignal)
end

if (IS_SERVER) then

	function RemoteSignal.new()
		warn("Using deprecated RemoteSignal")
		local self = setmetatable({
			_remote = Instance.new("RemoteEvent");
		}, RemoteSignal)
		return self
	end

	function RemoteSignal:Fire(player, ...)
		self._remote:FireClient(player, Ser.SerializeArgsAndUnpack(...))
	end

	function RemoteSignal:FireAll(...)
		self._remote:FireAllClients(Ser.SerializeArgsAndUnpack(...))
	end

	function RemoteSignal:FireExcept(player, ...)
		local args = Ser.SerializeArgs(...)
		for _,plr in ipairs(Players:GetPlayers()) do
			if (plr ~= player) then
				self._remote:FireClient(plr, Ser.UnpackArgs(args))
			end
		end
	end

	function RemoteSignal:Wait()
		return self._remote.OnServerEvent:Wait()
	end

	function RemoteSignal:Connect(handler)
		return self._remote.OnServerEvent:Connect(function(player, ...)
			handler(player, Ser.DeserializeArgsAndUnpack(...))
		end)
	end

	function RemoteSignal:Destroy()
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

	function RemoteSignal.new(remoteEvent)
		warn("Using deprecated RemoteSignal")
		assert(typeof(remoteEvent) == "Instance", "Argument #1 (RemoteEvent) expected Instance; got " .. typeof(remoteEvent))
		assert(remoteEvent:IsA("RemoteEvent"), "Argument #1 (RemoteEvent) expected RemoteEvent; got" .. remoteEvent.ClassName)
		local self = setmetatable({
			_remote = remoteEvent;
			_connections = {};
		}, RemoteSignal)
		return self
	end

	function RemoteSignal:Fire(...)
		self._remote:FireServer(Ser.SerializeArgsAndUnpack(...))
	end

	function RemoteSignal:Wait()
		return Ser.DeserializeArgsAndUnpack(self._remote.OnClientEvent:Wait())
	end

	function RemoteSignal:Connect(handler)
		local connection = Connection.new(self, self._remote.OnClientEvent:Connect(function(...)
			handler(Ser.DeserializeArgsAndUnpack(...))
		end))
		table.insert(self._connections, connection)
		return connection
	end

	function RemoteSignal:Destroy()
		for _,c in ipairs(self._connections) do
			if (c._conn) then
				c._conn:Disconnect()
			end
		end
		self._connections = nil
		self._remote = nil
	end

end

return RemoteSignal