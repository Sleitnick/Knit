-- Signal
-- Stephen Leitnick
-- Based off of Anaminus' Signal class: https://gist.github.com/Anaminus/afd813efc819bad8e560caea28942010

--[[

	signal = Signal.new()

	signal:Fire(...)
	signal:Wait()
	signal:WaitPromise()
	signal:Destroy()
	signal:DisconnectAll()
	
	connection = signal:Connect(functionHandler)

	connection:Disconnect()
	connection:IsConnected()

--]]

local Promise = require(script.Parent.Promise)

local Connection = {}
Connection.__index = Connection

function Connection.new(signal, connection)
	local self = setmetatable({
		_signal = signal;
		_conn = connection;
		Connected = true;
	}, Connection)
	return self
end

function Connection:Disconnect()
	if (self._conn) then
		self._conn:Disconnect()
		self._conn = nil
	end
	if (not self._signal) then return end
	self.Connected = false
	local connections = self._signal._connections
	local connectionIndex = table.find(connections, self)
	if (connectionIndex) then
		local n = #connections
		connections[connectionIndex] = connections[n]
		connections[n] = nil
	end
	self._signal = nil
end

function Connection:IsConnected()
	if (self._conn) then
		return self._conn.Connected
	end
	return false
end

Connection.Destroy = Connection.Disconnect

--------------------------------------------

local Signal = {}
Signal.__index = Signal


function Signal.new()
	local self = setmetatable({
		_bindable = Instance.new("BindableEvent");
		_connections = {};
		_args = {};
		_threads = 0;
		_id = 0;
	}, Signal)
	return self
end


function Signal.Is(obj)
	return (type(obj) == "table" and getmetatable(obj) == Signal)
end


function Signal:Fire(...)
	local id = self._id
	self._id = self._id + 1
	self._args[id] = {#self._connections + self._threads, {n = select("#", ...), ...}}
	self._threads = 0
	self._bindable:Fire(id)
end


function Signal:Wait()
	self._threads = self._threads + 1
	local id = self._bindable.Event:Wait()
	local args = self._args[id]
	args[1] = args[1] - 1
	if (args[1] <= 0) then
		self._args[id] = nil
	end
	return table.unpack(args[2], 1, args[2].n)
end


function Signal:WaitPromise()
	return Promise.new(function(resolve)
		resolve(self:Wait())
	end)
end


function Signal:Connect(handler)
	local connection = Connection.new(self, self._bindable.Event:Connect(function(id)
		local args = self._args[id]
		args[1] = args[1] - 1
		if (args[1] <= 0) then
			self._args[id] = nil
		end
		handler(table.unpack(args[2], 1, args[2].n))
	end))
	table.insert(self._connections, connection)
	return connection
end


function Signal:DisconnectAll()
	for _,c in ipairs(self._connections) do
		if (c._conn) then
			c._conn:Disconnect()
		end
	end
	self._connections = {}
	self._args = {}
end


function Signal:Destroy()
	self:DisconnectAll()
	self._bindable:Destroy()
end


return Signal