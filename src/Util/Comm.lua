--!strict

-- Comm
-- Stephen Leitnick
-- August 05, 2021

--[[

	CORE FUNCTIONS:

		Comm.Server.BindFunction(parent: Instance, name: string, func: (Instance, ...any) -> ...any, middleware): RemoteFunction
		Comm.Server.WrapMethod(parent: Instance, tbl: {}, name: string, middleware: ServerMiddleware?): RemoteFunction
		Comm.Server.CreateSignal(parent: Instance, name: string): RemoteEvent

		Comm.Client.GetFunction(parent: Instance, name: string, usePromise: boolean, middleware: ClientMiddleware?): (...any) -> ...any
		Comm.Client.GetSignal(parent: Instance, name: string): RemoteEvent


	HELPER CLASSES:

		serverComm = Comm.Server.ForParent(parent: Instance, namespace: string?, janitor: Janitor?): ServerComm
		serverComm:BindFunction(name: string, func: (Instance, ...any) -> ...any, middleware): RemoteFunction
		serverComm:WrapMethod(tbl: {}, name: string, middleware: ServerMiddleware?): RemoteFunction
		serverComm:CreateSignal(name: string): RemoteEvent
		serverComm:Destroy()

		clientComm = Comm.Client.ForParent(parent: Instance, usePromise: boolean, namespace: string?, janitor: Janitor?): ClientComm
		clientComm:GetFunction(name: string, usePromise: boolean, middleware: ClientMiddleware?): (...any) -> ...any
		clientComm:GetSignal(name: string): RemoteEvent
		clientComm:Destroy()

--]]


type FnBind = (Instance, ...any) -> ...any
type Args = {
	n: number,
	[any]: any,
}

type ServerMiddlewareFn = (Instance, Args) -> (boolean, ...any)
type ServerMiddleware = {ServerMiddlewareFn}

type ClientMiddlewareFn = (Args) -> (boolean, ...any)
type ClientMiddleware = {ClientMiddlewareFn}


local Signal = require(script.Parent.Signal)
local Option = require(script.Parent.Option)
local Promise = require(script.Parent.Promise)

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local IS_SERVER = RunService:IsServer()
local DEFAULT_COMM_FOLDER_NAME = "__comm__"
local WAIT_FOR_CHILD_TIMEOUT = 10


local function GetCommSubFolder(parent: Instance, subFolderName: string): Option.Option
	local subFolder: Instance = nil
	if IS_SERVER then
		subFolder = parent:FindFirstChild(subFolderName)
		if not subFolder then
			subFolder = Instance.new("Folder")
			subFolder.Name = subFolderName
			subFolder.Parent = parent
		end
	else
		subFolder = parent:WaitForChild(subFolderName, WAIT_FOR_CHILD_TIMEOUT)
	end
	return Option.Wrap(subFolder)
end


local RemoteSignal = {}
RemoteSignal.__index = RemoteSignal

function RemoteSignal.new(parent: Instance, name: string, inboundMiddleware: ServerMiddleware?, outboundMiddleware: ServerMiddleware?)
	local self = setmetatable({}, RemoteSignal)
	self._re = Instance.new("RemoteEvent")
	self._re.Name = name
	self._re.Parent = parent
	if outboundMiddleware and #outboundMiddleware > 0 then
		self._hasOutbound = true
		self._outbound = outboundMiddleware
	else
		self._hasOutbound = false
	end
	if inboundMiddleware and #inboundMiddleware > 0 then
		self._directConnect = false
		self._signal = Signal.new(nil)
		self._re.OnServerEvent:Connect(function(player, ...)
			local args = table.pack(...)
			for _,middlewareFunc in ipairs(inboundMiddleware) do
				local middlewareResult = table.pack(middlewareFunc(player, args))
				if not middlewareResult[1] then
					return
				end
			end
			self._signal:Fire(player, table.unpack(args, 1, args.n))
		end)
	else
		self._directConnect = true
	end
	return self
end

function RemoteSignal:Connect(fn)
	if self._directConnect then
		return self._re.OnServerEvent:Connect(fn)
	else
		return self._signal:Connect(fn)
	end
end

function RemoteSignal:_processOutboundMiddleware(...: any)
	if not self._hasOutbound then
		return ...
	end
	local args = table.pack(...)
	for _,middlewareFunc in ipairs(self._outbound) do
		local middlewareResult = table.pack(middlewareFunc(args))
		if not middlewareResult[1] then
			return table.unpack(middlewareResult, 2, middlewareResult.n)
		end
	end
	return table.unpack(args, 1, args.n)
end

function RemoteSignal:Fire(player: Player, ...: any)
	self._re:FireClient(player, self:_processOutboundMiddleware(...))
end

function RemoteSignal:FireAll(...: any)
	self._re:FireAllClients(self:_processOutboundMiddleware(...))
end

function RemoteSignal:FireFilter(predicate: (Player, ...any) -> boolean, ...: any)
	for _,player in ipairs(Players:GetPlayers()) do
		if predicate(player, ...) then
			self._re:FireClient(player, self:_processOutboundMiddleware(...))
		end
	end
end

function RemoteSignal:Destroy()
	self._re:Destroy()
	if self._signal then
		self._signal:Destroy()
	end
end


local ClientRemoteSignal = {}
ClientRemoteSignal.__index = ClientRemoteSignal

function ClientRemoteSignal.new(re: RemoteEvent, inboundMiddleware: ClientMiddleware?, outboudMiddleware: ClientMiddleware?)
	local self = setmetatable({}, ClientRemoteSignal)
	self._re = re
	if outboudMiddleware and #outboudMiddleware > 0 then
		self._hasOutbound = true
		self._outbound = outboudMiddleware
	else
		self._hasOutbound = false
	end
	if inboundMiddleware and #inboundMiddleware > 0 then
		self._directConnect = false
		self._signal = Signal.new(nil)
		self._reConn = self._re.OnClientEvent:Connect(function(...)
			local args = table.pack(...)
			for _,middlewareFunc in ipairs(inboundMiddleware) do
				local middlewareResult = table.pack(middlewareFunc(args))
				if not middlewareResult[1] then
					return
				end
			end
			self._signal:Fire(table.unpack(args, 1, args.n))
		end)
	else
		self._directConnect = true
	end
	return self
end

function ClientRemoteSignal:Connect(fn)
	if self._directConnect then
		return self._re.OnClientEvent:Connect(fn)
	else
		return self._signal:Connect(fn)
	end
end

function ClientRemoteSignal:Destroy()
end


local Comm = {Server = {}, Client = {}}


function Comm.Server.BindFunction(parent: Instance, name: string, func: FnBind, middleware: ServerMiddleware?): RemoteFunction
	assert(IS_SERVER, "BindFunction must be called from the server")
	local folder = GetCommSubFolder(parent, "RF"):Expect("Failed to get Comm RF folder")
	local rf = Instance.new("RemoteFunction")
	rf.Name = name
	if middleware and #middleware > 0 then
		local function OnServerInvoke(player, ...)
			local args = table.pack(...)
			for _,middlewareFunc in ipairs(middleware) do
				local middlewareResult = table.pack(middlewareFunc(player, args))
				if not middlewareResult[1] then
					return table.unpack(middlewareResult, 2, middlewareResult.n)
				end
			end
			return func(player, table.unpack(args, 1, args.n))
		end
		rf.OnServerInvoke = OnServerInvoke
	else
		rf.OnServerInvoke = func
	end
	rf.Parent = folder
	return rf
end


function Comm.Server.WrapMethod(parent: Instance, tbl: {}, name: string, middleware: ServerMiddleware?): RemoteFunction
	assert(IS_SERVER, "WrapMethod must be called from the server")
	local fn = tbl[name]
	assert(type(fn) == "function", "Value at index " .. name .. " must be a function; got " .. type(fn))
	return Comm.Server.BindFunction(parent, name, function(...) return fn(tbl, ...) end, middleware)
end


function Comm.Server.CreateSignal(parent: Instance, name: string, inboundMiddleware: ServerMiddleware?, outboundMiddleware: ServerMiddleware?)
	assert(IS_SERVER, "CreateSignal must be called from the server")
	local folder = GetCommSubFolder(parent, "RE"):Expect("Failed to get Comm RE folder")
	local rs = RemoteSignal.new(folder, name, inboundMiddleware, outboundMiddleware)
	return rs
end


function Comm.Client.GetFunction(parent: Instance, name: string, usePromise: boolean, middleware: ClientMiddleware?)
	assert(not IS_SERVER, "GetFunction must be called from the client")
	local folder = GetCommSubFolder(parent, "RF"):Expect("Failed to get Comm RF folder")
	local rf = folder:WaitForChild(name, WAIT_FOR_CHILD_TIMEOUT)
	assert(rf ~= nil, "Failed to find RemoteFunction: " .. name)
	if middleware and #middleware > 0 then
		if usePromise then
			return function(...)
				local args = table.pack(...)
				return Promise.new(function(resolve, reject)
					local success, res = pcall(function()
						return table.pack(rf:InvokeServer(table.unpack(args, 1, args.n)))
					end)
					if success then
						for _,middlewareFunc in ipairs(middleware) do
							local middlewareResult = table.pack(middlewareFunc(res))
							if not middlewareResult[1] then
								return table.unpack(middlewareResult, 2, middlewareResult.n)
							end
						end
						resolve(table.unpack(res, 1, res.n))
					else
						reject(res)
					end
				end)
			end
		else
			return function(...)
				local res = table.pack(rf:InvokeServer(...))
				for _,middlewareFunc in ipairs(middleware) do
					local middlewareResult = table.pack(middlewareFunc(res))
					if not middlewareResult[1] then
						return table.unpack(middlewareResult, 2, middlewareResult.n)
					end
				end
				return table.unpack(res, 1, res.n)
			end
		end
	else
		if usePromise then
			return function(...)
				local args = table.pack(...)
				return Promise.new(function(resolve, reject)
					local success, res = pcall(function()
						return table.pack(rf:InvokeServer(table.unpack(args, 1, args.n)))
					end)
					if success then
						resolve(table.unpack(res, 1, res.n))
					else
						reject(res)
					end
				end)
			end
		else
			return function(...)
				return rf:InvokeServer(...)
			end
		end
	end
end


function Comm.Client.GetSignal(parent: Instance, name: string, inboundMiddleware: ClientMiddleware?, outboundMiddleware: ClientMiddleware?)
	assert(not IS_SERVER, "GetSignal must be called from the client")
	local folder = GetCommSubFolder(parent, "RE"):Expect("Failed to get Comm RE folder")
	local re = folder:WaitForChild(name, WAIT_FOR_CHILD_TIMEOUT)
	assert(re ~= nil, "Failed to find RemoteEvent: " .. name)
	return ClientRemoteSignal.new(re, inboundMiddleware, outboundMiddleware)
end


local ServerComm = {}
ServerComm.__index = ServerComm

function ServerComm.new(parent: Instance, namespace: string?, janitor)
	assert(IS_SERVER, "ServerComm must be constructed from the server")
	assert(typeof(parent) == "Instance", "Parent must be of type Instance")
	local ns = DEFAULT_COMM_FOLDER_NAME
	if namespace then
		ns = namespace
	end
	assert(not parent:FindFirstChild(ns), "Parent already has another ServerComm bound to namespace " .. ns)
	local self = setmetatable({}, ServerComm)
	self._instancesFolder = Instance.new("Folder")
	self._instancesFolder.Name = ns
	self._instancesFolder.Parent = parent
	if janitor then
		janitor:Add(self)
	end
	return self
end

function ServerComm:BindFunction(name: string, func: FnBind, middleware: ServerMiddleware?): RemoteFunction
	return Comm.Server.BindFunction(self._instancesFolder, name, func, middleware)
end

function ServerComm:WrapMethod(tbl: {}, name: string, middleware: ServerMiddleware?): RemoteFunction
	return Comm.Server.WrapMethod(self._instancesFolder, tbl, name, middleware)
end

function ServerComm:CreateSignal(name: string, inboundMiddleware: ServerMiddleware?, outboundMiddleware: ServerMiddleware?)
	return Comm.Server.CreateSignal(self._instancesFolder, name, inboundMiddleware, outboundMiddleware)
end

function ServerComm:Destroy()
	self._instancesFolder:Destroy()
end


local ClientComm = {}
ClientComm.__index = ClientComm

function ClientComm.new(parent: Instance, usePromise: boolean, namespace: string?, janitor)
	assert(not IS_SERVER, "ClientComm must be constructed from the client")
	assert(typeof(parent) == "Instance", "Parent must be of type Instance")
	local ns = DEFAULT_COMM_FOLDER_NAME
	if namespace then
		ns = namespace
	end
	local folder: Instance? = parent:WaitForChild(ns, WAIT_FOR_CHILD_TIMEOUT)
	assert(folder ~= nil, "Could not find namespace for ClientComm in parent: " .. ns)
	local self = setmetatable({}, ClientComm)
	self._instancesFolder = folder
	self._usePromise = usePromise
	if janitor then
		janitor:Add(self)
	end
	return self
end

function ClientComm:GetFunction(name: string, middleware: ClientMiddleware?)
	return Comm.Client.GetFunction(self._instancesFolder, name, self._usePromise, middleware)
end

function ClientComm:GetSignal(name: string, inboundMiddleware: ClientMiddleware?, outboundMiddleware: ClientMiddleware?)
	return Comm.Client.GetSignal(self._instancesFolder, name, inboundMiddleware, outboundMiddleware)
end

function ClientComm:Destroy()
end


Comm.Server.ForParent = ServerComm.new
Comm.Client.ForParent = ClientComm.new


return Comm
