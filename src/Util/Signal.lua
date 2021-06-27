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


local SignalSnapshot = {}
SignalSnapshot.__index = SignalSnapshot

function SignalSnapshot.new(signal)
	local self = setmetatable({
		_connections = signal._connections;
		_waiting = signal._waiting;
		_bindable = signal._bindable;
	}, SignalSnapshot)
	for _,c in ipairs(self._connections) do
		c._snapshot = self
	end
	for _,w in ipairs(self._waiting) do
		w._snapshot = self
	end
	return self
end

function SignalSnapshot:Destroy()
	self._bindable:Destroy()
	for _,c in ipairs(self._connections) do
		c.Connected = false
	end
end

--------------------------------------------

local Waiting = {}
Waiting.__index = Waiting

function Waiting.new(signal)
	local self = setmetatable({
		_args = signal._args;
		_bindable = signal._bindable;
	}, Waiting)
	return self
end

function Waiting:Wait()
	local id = self._bindable.Event:Wait()
	local args = self._args[id]
	args[1] -= 1
	if (args[1] <= 0) then
		self._args[id] = nil
	end
	return table.unpack(args[2], 1, args[2].n)
end

--------------------------------------------

local Connection = {}
Connection.__index = Connection

function Connection.new(signal, event, handler)
	local self = setmetatable({
		_signal = signal;
		_args = signal._args;
		Connected = true;
	}, Connection)
	self._conn = event:Connect(function(id)
		handler(self, id)
	end)
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
		_waiting = {};
		_args = {};
		_threads = 0;
		_id = 0;
		_snapshots = {};
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
	local waiting = Waiting.new(self)
	table.insert(self._waiting, waiting)
	return waiting:Wait()
end


function Signal:WaitPromise()
	return Promise.new(function(resolve)
		resolve(self:Wait())
	end)
end


function Signal:Connect(handler)
	local connection = Connection.new(self, self._bindable.Event, function(connSelf, id)
		local args = connSelf._args[id]
		args[1] -= 1
		if (args[1] <= 0) then
			connSelf._args[id] = nil
			if (next(connSelf._args) == nil and connSelf._snapshot) then
				connSelf._snapshot:Destroy()
			end
		end
		handler(table.unpack(args[2], 1, args[2].n))
	end)
	table.insert(self._connections, connection)
	return connection
end


function Signal:_disconnectAll()
	for _,c in ipairs(self._connections) do
		if (c._conn) then
			c._conn:Disconnect()
		end
		c.Connected = false
	end
	table.clear(self._connections)
	table.clear(self._waiting)
	table.clear(self._args)
end


function Signal:_queueForDisconnect()
	local snapshot = SignalSnapshot.new(self)
	table.insert(self._snapshots, snapshot)
	self._bindable = Instance.new("BindableEvent")
	self._connections = {}
	self._waiting = {}
	self._args = {}
	self._threads = 0
	self._id = 0
end


function Signal:DisconnectAll()
	if (self._destroyed) then return end
	if (next(self._args)) then
		self:_queueForDisconnect()
	else
		self:_disconnectAll()
	end
end


function Signal:Destroy()
	self:DisconnectAll()
	self:_clearProxy()
	self._bindable:Destroy()
	self._destroyed = true
end


return Signal
