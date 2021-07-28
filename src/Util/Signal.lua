-- Signal
-- Stephen Leitnick
-- July 28, 2021


--[[

	signal = Signal.new([maid: Maid])
	signal = Signal.Wrap(rbxSignal: RBXScriptSignal [, maid: Maid])

	Signal.Is(obj: any): boolean

	signal:Connect(fn: (...any) -> void): Connection
	signal:Fire(...): void
	signal:FireNow(...): void
	signal:Wait(): ...any
	signal:Await(): Promise<...any>
	signal:DisconnectAll(): void
	signal:Destroy(): void

	connection.Connected: boolean
	connection:Disconnect(): void

	--------------------------------------------------

	Connect(fn)
	> Connects the given function to the signal. Any
	  time the signal is fired, the function will be
	  called. The arguments passed to the fired signal
	  will be passed along to the connected function.

	Fire(...)
	> Fires all connections using task.defer. Because
	  of the deferred guarantee, this is the fastest
	  option & should be used in most cases.

	FireNow(...)
	> Fires all connections using task.spawn. Because
	  there could be inner conflicts with connections
	  being disconnected during the middle of this
	  process, extra work has to be done to assure
	  this process works properly. Due to the extra
	  work, this will be somewhat slower than Fire().

	Wait()
	> Yields the caller's thread until the next time
	  the signal is fired. The arguments passed to
	  the fired signal will be returned from the
	  Wait() method. For asynchronous programming, it
	  is better to use Await() below, which returns
	  a Promise version of Wait().

	Await()
	> Returns a Promise that resolves the first time
	  the signal is fired. This signal is cancellable.
	  The arguments passed from the fired signal are
	  passed to the resolve handler.

	DisconnectAll()
	> Disconnects all connections to the signal.

	Destroy()
	> Destroys the signal. Internally, this disconnects
	  all connections and clears out the wrapped proxy
	  connection if present.

--]]


local Promise = require(script.Parent.Promise)


local Connection = {}
Connection.__index = Connection


function Connection:Disconnect()
	if (not self.Connected) then return end
	self.Connected = false
	if (self._signal._handlerHead == self) then
		self._signal._handlerHead = self._next
	else
		local prev = self._signal._handlerHead
		while (prev and prev._next ~= self) do
			prev = prev._next
		end
		if (prev) then
			prev._next = self._next
		end
	end
end


local Signal = {}
Signal.__index = Signal


function Signal.new(maid)
	local self = setmetatable({}, Signal)
	self._handlerHead = nil
	if (maid) then
		maid:GiveTask(self)
	end
	return self
end


function Signal.Wrap(rbxScriptSignal, maid)
	assert(typeof(rbxScriptSignal) == "RBXScriptSignal", "Argument #1 must be of type RBXScriptSignal")
	local signal = Signal.new(maid)
	signal._proxyHandle = rbxScriptSignal:Connect(function(...)
		signal:Fire(...)
	end)
	return signal
end


function Signal.Is(obj)
	return (type(obj) == "table" and getmetatable(obj) == Signal)
end


function Signal:Connect(fn)
	local connection = setmetatable({
		Connected = true;
		_fn = fn;
		_next = self._handlerHead;
		_signal = self;
	}, Connection)
	self._handlerHead = connection
	return connection
end


function Signal:Fire(...)
	local connection = self._handlerHead
	while (connection) do
		task.defer(connection._fn, ...)
		connection = connection._next
	end
end


function Signal:FireNow(...)
	for _,connection in ipairs(self:_getConnections()) do
		if (connection.Connected) then
			task.spawn(connection._fn, ...)
		end
	end
end


function Signal:_getConnections()
	local connection = self._handlerHead
	local connections = {}
	while (connection) do
		table.insert(connections, connection)
		connection = connection._next
	end
	return connections
end


function Signal:Wait()
	local args = nil
	local done = false
	local connection
	connection = self:Connect(function(...)
		if (done) then return end
		connection:Disconnect()
		args = table.pack(...)
		done = true
	end)
	while (not done) do
		task.wait()
	end
	return table.unpack(args, 1, args.n)
end


function Signal:Await()
	return Promise.new(function(resolve, _reject, onCancel)
		local args = nil
		local done = false
		local connection
		connection = self:Connect(function(...)
			if (done) then return end
			connection:Disconnect()
			args = table.pack(...)
			done = true
		end)
		onCancel(function()
			if (connection.Connected) then
				connection:Disconnect()
				done = true
			end
		end)
		while (not done) do
			task.wait()
		end
		if (args) then
			resolve(table.unpack(args, 1, args.n))
		end
	end)
end


function Signal:DisconnectAll()
	while (self._handlerHead) do
		self._handlerHead:Disconnect()
	end
end


function Signal:Destroy()
	self:DisconnectAll()
	if (self._proxyHandle) then
		self._proxyHandle:Disconnect()
	end
end


return Signal
