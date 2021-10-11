# Knit Style Guide

For those who want to contribute to Knit, here are some guidelines in regards to code style.

---------------------------

## Readability

Readability is king. Code within Knit should not be impressive; it should be readable. Having readable code is important for debugging and future maintainability.

This also means that code shouldn't be prematurely optimized with fancy Lua tricks unless absolutely necessary. In almost all cases, such optimizations only make the code unreadable and add no real value.

---------------------------

## Single Purpose Files

Every source file within Knit should have a single purpose. This might be a single class, table, function, etc. For instance, a source file should _not_ contain a bunch of public classes. Split these into separate files.

---------------------------

## File Structure

File names should match the name of the module.

All source files should follow a similar format to this template:

```lua
-- Header (author, date, etc.)

-- Documentation

-- Module requires (e.g. Module = require(somewhere.Module))

-- Service refs (e.g. RunService = game:GetService("RunService"))

-- Constants (e.g. MY_CONSTANT = 10)

-- Variables (although, global vars are looked down upon)

-- Module definition (e.g. MyModule = {})

-- Module code

-- Return module
```

In other Roblox programming ecosystems, it is usually standard for service refs to come _before_ module requires. The reason for the switch here is that imports are always first in just about every other ecosystem, and thus Knit tries to follow the more global standard.

Example of `MyModule.lua`:

```lua
-- MyModule
-- John Doe
-- January 10, 2021

--[[

	MyModule.DoSomething(value: number)
	MyModule.DoAnotherThing()

	MyModule.DidSomething(value: number)

--]]


local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)
local Signal = require(Knit.Util.Signal)

local HttpService = game:GetService("HttpService")

local MESSAGE = "Hello"

local MyModule = {}

MyModule.DidSomething = Signal.new()


function MyModule.DoSomething(value)
	-- Do something
	MyModule.DidSomething:Fire(value)
end


function MyModule.DoAnotherThing()
	-- Do something else
end


return MyModule
```

### Spacing

Between each section above, there should be a blank line of separation. Two blank lines should exist around methods and functions.

---------------------------

## Variables

Variables should be descriptive and should be written in `camelCase`.

```lua
local amountLeft = 10
```

### Constants

Variables that should act as constants (non-changing variables) should be written in `UPPER_SNAKE_CASE`.

```lua
local MAX_INTERVAL = 20
local DEFAULT_TEXT = "Hello"
```

### Services and Requires
Services retrieved using `game:GetService` or modules retrieved using `require` should be written in `PascalCase`.

```lua
local Signal = require(Knit.Util.Signal)
local RunService = game:GetService("RunService")
```

---------------------------

## Functions

Function names should be written in `PascalCase` and declared with `local` if possible. Functions should be short and easy to understand.

When possible, prefer functional programming techniques, so that side effects are avoided. In other words, functions should only manipulate the variables within the function or passed as arguments, and the function should _not_ change any variables outside of the function's scope.

```lua
local function HelloWorld(message)
	local newMessage = "The message was: " .. message
	return newMessage
end
```

---------------------------

## Classes

Classes should be defined with the following boilerplate code:
```lua
local MyClass = {}
MyClass.__index = MyClass

function MyClass.new()
	local self = setmetatable({}, MyClass)
	return self
end

function MyClass:Destroy()
end
```

It is important that classes have a `Destroy` method so that they can be passed to Janitors for cleanup.

### Method & Field Names

Public method and field names should be written in `PascalCase`. Private method and field names should be written in `_underscoreCamelCase`.

Fields should be declared within the `new` constructor. For readability, it is preferred to add the fields _after_ the `setmetatable` line. Please note that it is technically faster to declare fields within the table declaration, but readability is key.

Only the class itself should ever access private methods or fields. If other code is accessing these methods or fields, it is probably due to bad design. Switch those methods/fields to be public or redesign how those items are being accessed.

```lua
function MyClass.new()
	local self = setmetatable({}, MyClass)
	self.MyPublicField = "Hello world"
	self._myPrivateField = "Goodbye earth"
	return self
end

function MyClass:SomeMethod()
	local combined = (self.MyPublicField .. " " .. self._myPrivateField)
	return combined
end

function MyClass:_somePrivateMethod()
	return self.MyPublicField:rep(10)
end
```

#### Public or Private

When deciding if a method or field should be public or private, ask these questions: Does the method/field need to be accessed by code outside of this class? If yes, the method/field should be public. If no, keep it private.

Simply underscoring the name of a method/field gives no actual security to those methods/fields. It is only a convention. It helps authors know if they _should_ be accessing the methods/fields. An assumption can be made that accessing or manipulating private methods/fields is bad and can result in unexpected behavior, and is thus better avoided.

### Method or Function
It is important to decide whether a piece of code should exist as a method or as a function. This can be figured out quite simply: Is is required that external code can invoke this function, and does it need any information about the object itself? If the answer is "no" to both of these questions, then it should exist as a standalone function.

Standalone functions in class modules should be defined above the class definition.

---------------------------

## Documentation

At the top of each source file, simple documentation should be given to show how to use the module. This should show method signatures, fields, and events. If needed, short examples of usage can be shown too.

While Lua is a dynamic language, it is helpful to include types for arguments and return values. For instance: `Symbol.Is(obj: any): boolean`, which shows that `obj` can be any type, and a `boolean` is the expected return type.

The typical layout is as follows:

```lua
--[[

	-- CONSTRUCTOR DEFINITIONS --

	-- FIELD DEFINITIONS --

	-- METHOD DEFINITIONS --

	-- EVENT DEFINITIONS --

	-- EXAMPLES IF NEEDED --

--]]
```

Example:

```lua
--[[

	myClass = MyClass.new()

	myClass.MyPublicField: string

	myClass:SomeMethod(): string

--]]
```

## Other Material

Outside of styling defined in this guide, follow the [Roblox Lua Style Guide](https://roblox.github.io/lua-style-guide/).
