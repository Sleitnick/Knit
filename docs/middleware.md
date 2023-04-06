---
sidebar_position: 8
---

# Middleware

Knit's networking layer uses the [Comm](https://sleitnick.github.io/RbxUtil/api/Comm/) module internally, which allows for middleware to be introduced at both the inbound and outbound level. For example, if a service had a client method called `GetMoney(player)`, and the client called that method, your service would then fire that function. If there is any inbound middleware on the server, the inbound middleware would fire _before_ `GetMoney` is fired. And the outbound middleware would fire _after_ GetMoney is fired.

Middleware can be used to both transform inbound/outbound arguments, and also decide to drop requests/responses. This is useful for many use-cases, such as automatically serializing/deserializing complex data types over the network, or sanitizing incoming data.

Middleware can be added on both the server and client, and affects functions and signals. Middleware can either be added at the Knit global level, or per service.

## Usage

Middleware is added when Knit is started: `Knit.Start({Middleware = {Inbound = {...}, Outbound = {...}}})` _or_ on each service. Each "middleware" item in the tables is a function. On the client, this function takes an array table containing all the arguments passed along. On the server, it is nearly the same, except the first argument before the arguments table is the player.

Each function should return a boolean, indicating whether or not to continue to the request/response. If `false`, an optional variadic list of items can be returned, which will be returned back to the caller (essentially a short-circuit, but still returning data).

- Client middleware function signature: `(args: {any}) -> (boolean, ...)`
- Server middleware function signature: `(player: Player, args: {any}) -> (boolean, ...)`

### Examples

#### Logger

Here's an example on the client which logs all inbound data from the server:
```lua
local function Logger(args: { any })
	print(args)
	return true
end

Knit.Start({
	Middleware = { Inbound = { Logger } }
})
```

Here's the same thing, but on the server. As you can see, the only difference is that the `player` argument is added to the middleware function:
```lua
local function Logger(player: Player, args: { any })
	print(player, args)
	return true
end

Knit.Start({
	Middleware = { Inbound = { Logger } }
})
```

#### Manipulation

A more complex example, where any inbound number to the client is multiplied by 2:
```lua
local function DoubleNumbers(args)
	for i, v in args do
		if type(v) == "number" then
			args[i] *= 2
		end
	end
	return true
end

Knit.Start({ Middleware = { Inbound = { DoubleNumbers } } })
```

#### Per-Service Example

Middleware can also be targeted per-service, which will override the global level middleware for the given service.
```lua
-- Server-side:
local MyService = Knit.CreateService {
	Name = "MyService",
	Client = {},
	Middleware = {
		Inbound = { Logger },
		Outbound = {},
	},
}
```

On the client, things look a little different. Middleware is still per-service, not controller, so the definitions of per-service middleware need to go within `Knit.Start()` on the client:
```lua
-- Client-side:
Knit.Start({
	PerServiceMiddleware = {
		-- Mapped by name of the service
		MyService = {
			Inbound = { Logger },
			Outbound = {},
		},
	},
})
```

#### Serialization

Another example, where a simple class is serialized/deserialized on the client before/after remote network communication occurs. A similar setup could be used server-side to complete the loop:
```lua
-----------------------------------------------------
-- Setup a simple class:
local MyClass = {}
MyClass.__index = MyClass
MyClass.ClassName = "MyClass"

function MyClass.new()
	return setmetatable({
		SomeData = "",
	}, MyClass)
end

function MyClass:Serialize()
	return { _CN = self.ClassName, D = self.SomeData }
end

function MyClass.deserialize(data)
	local myClass = MyClass.new()
	myClass.SomeData = data
	return myClass
end
-----------------------------------------------------

-- Setup middleware for class serialization/deserialization on client:

local function InboundClass(args)
	for i, v in args do
		if type(v) == "table" and v._CN == "MyClass" then
			args[i] = MyClass.deserialize(v)
		end
	end
	return true
end

local function OutboundClass(args)
	for i, v in args do
		if type(v) == "table" and v.ClassName == "MyClass" then
			args[i] = v:Serialize()
		end
	end
	return true
end

Knit.Start({
	Middleware = {
		Inbound = { InboundClass },
		Outbound = { OutboundClass },
	},
})
```
