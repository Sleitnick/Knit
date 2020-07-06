-- Event
-- Stephen Leitnick
-- Based off of Anaminus' Signal class: https://gist.github.com/Anaminus/afd813efc819bad8e560caea28942010

local Promise = require(script.Parent.Promise)

local Connection = {}
Connection.__index = Connection

function Connection.new(event, connection)
	local self = setmetatable({
		_event = event;
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

function Connection:IsConnected()
	if (self._conn) then
		return self._conn.Connected
	end
	return false
end

Connection.Destroy = Connection.Disconnect

--------------------------------------------

local Event = {}
Event.__index = Event


function Event.new()
	local self = setmetatable({
		_bindable = Instance.new("BindableEvent");
		_connections = {};
		_args = {};
		_threads = 0;
		_id = 0;
	}, Event)
	return self
end


function Event.Is(obj)
	return (type(obj) == "table" and getmetatable(obj) == Event)
end


function Event:Fire(...)
	local id = self._id
	self._id = self._id + 1
	self._args[id] = {#self._connections + self._threads, {n = select("#", ...), ...}}
	self._threads = 0
	self._bindable:Fire(id)
end


function Event:Wait()
	self._threads = self._threads + 1
	local id = self._bindable.Event:Wait()
	local args = self._args[id]
	args[1] = args[1] - 1
	if (args[1] <= 0) then
		self._args[id] = nil
	end
	return table.unpack(args[2], 1, args[2].n)
end


function Event:WaitPromise()
	return Promise.new(function(resolve)
		resolve(self:Wait())
	end)
end


function Event:Connect(handler)
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


function Event:DisconnectAll()
	self._bindable:Destroy()
	self._bindable = Instance.new("BindableEvent")
	self._args = {}
end


function Event:Destroy()
	self._bindable:Destroy()
end


return Event