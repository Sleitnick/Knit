-- Signal
-- Stephen Leitnick
-- Based off of Anaminus' Signal class: https://gist.github.com/Anaminus/afd813efc819bad8e560caea28942010

--[[

	signal = Signal.new([maid: Maid])
	signal = Signal.Proxy(rbxSignal: RBXScriptSignal [, maid: Maid])

	Signal.Is(object: any): boolean

	signal:Fire(...)
	signal:Wait()
	signal:WaitPromise()
	signal:Destroy()
	signal:DisconnectAll()

	connection = signal:Connect((...) -> void)

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


function Signal.new(maid)
	local self = setmetatable({
		_bindable = Instance.new("BindableEvent");
		_connections = {};
		_args = {};
		_threads = 0;
		_id = 0;
	}, Signal)
	if (maid) then
		maid:GiveTask(self)
	end
	return self
end


function Signal.Proxy(rbxScriptSignal, maid)
	assert(typeof(rbxScriptSignal) == "RBXScriptSignal", "Argument #1 must be of type RBXScriptSignal")
	local signal = Signal.new(maid)
	signal:_setProxy(rbxScriptSignal)
	return signal
end


function Signal.Is(obj)
	return (type(obj) == "table" and getmetatable(obj) == Signal)
end


function Signal:_setProxy(rbxScriptSignal)
	assert(typeof(rbxScriptSignal) == "RBXScriptSignal", "Argument #1 must be of type RBXScriptSignal")
	self:_clearProxy()
	self._proxyHandle = rbxScriptSignal:Connect(function(...)
		self:Fire(...)
	end)
end


function Signal:_clearProxy()
	if (self._proxyHandle) then
		self._proxyHandle:Disconnect()
		self._proxyHandle = nil
	end
end


function Signal:Fire(...)
	local totalListeners = (#self._connections + self._threads)
	if (totalListeners == 0) then return end
	local id = self._id
	self._id += 1
	self._args[id] = {totalListeners, {n = select("#", ...), ...}}
	self._threads = 0
	self._bindable:Fire(id)
end


function Signal:Wait()
	self._threads += 1
	local id = self._bindable.Event:Wait()
	local args = self._args[id]
	args[1] -= 1
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
		args[1] -= 1
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
	self:_clearProxy()
	self._bindable:Destroy()
end


return Signal
