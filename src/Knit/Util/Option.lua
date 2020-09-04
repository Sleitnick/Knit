-- Option
-- Stephen Leitnick
-- August 28, 2020

--[[

	MatchTable {
		Some: (value: any) -> void
		None: () -> void
	}

	Option.Some(anyValue): Option<any>

	Option.None: Option<None>

	Option.Is(obj): boolean

	opt:Match(): (matches: MatchTable) -> void
	opt:IsSome(): boolean
	opt:IsNone(): boolean
	opt:Unwrap(): any

	--------------------------------------------------------------------

	Options are useful for handling nil-value cases. Any time that an
	operation might return nil, it is useful to instead return an
	Option, which will indicate that the value might be nil, and should
	be explicitly checked before using the value. This will help
	prevent common bugs caused by nil values that can fail silently.


	Example:

	local result1 = Option.Some(32)
	local result2 = Option.Some(nil)
	local result3 = Option.Some("Hi")
	local result4 = Option.Some(nil)
	local result5 = Option.None

	-- Use 'Match' to match if the value is Some or None:
	result1:Match {
		Some = function(value) print(value) end;
		None = function() print("No value") end;
	}

	-- Raw check:
	if result2:IsSome() then
		local value = result2:Unwrap() -- Explicitly call Unwrap
		print("Value of result2:", value)
	end

	if result3:IsNone() then
		print("No result for result3")
	end

	-- Bad, will throw error bc result4 is none:
	local value = result4:Unwrap()

--]]


local CLASSNAME = "Option"

local Option = {}
Option.__index = Option


function Option._new(value)
	local self = setmetatable({
		ClassName = CLASSNAME;
		_v = value;
		_s = (value ~= nil);
	}, Option)
	return self
end


function Option.Some(value)
	assert(value ~= nil, "Option.Some() value cannot be nil")
	return Option._new(value)
end


function Option.Is(obj)
	return (type(obj) == "table" and getmetatable(obj) == Option)
end


function Option.Deserialize(data) -- type data = {ClassName: string, Value: any}
	assert(type(data) == "table" and data.ClassName == CLASSNAME, "Invalid data for deserializing Option")
	return (data.Value == nil and Option.None or Option.Some(data.Value))
end


function Option:Serialize()
	return {
		ClassName = self.ClassName;
		Value = self._v;
	}
end


function Option:Match(matches)
	local onSome = matches.Some
	local onNone = matches.None
	assert(type(onSome) == "function", "Missing 'Some' match")
	assert(type(onNone) == "function", "Missing 'None' match")
	if (self:IsSome()) then
		onSome(self:Unwrap())
	else
		onNone()
	end
end


function Option:IsSome()
	return self._s
end


function Option:IsNone()
	return (not self._s)
end


function Option:Expect(msg)
	assert(self:IsSome(), msg)
	return self._v
end


function Option:ExpectNone(msg)
	assert(self:IsNone(), msg)
end


function Option:Unwrap()
	return self:Expect("Cannot unwrap option of None type")
end


function Option:UnwrapOr(default)
	if (self:IsSome()) then
		return self:Unwrap()
	else
		return default
	end
end


function Option:UnwrapOrElse(defaultFunc)
	if (self:IsSome()) then
		return self:Unwrap()
	else
		return defaultFunc()
	end
end


function Option:And(optB)
	if (self:IsSome()) then
		return optB
	else
		return Option.None
	end
end


function Option:AndThen(andThenFunc)
	if (self:IsSome()) then
		return andThenFunc()
	else
		return Option.None
	end
end


function Option:Or(optB)
	if (self:IsSome()) then
		return self:Unwrap()
	else
		return optB
	end
end


function Option:OrElse(orElseFunc)
	if (self:IsSome()) then
		return self:Unwrap()
	else
		return orElseFunc()
	end
end


function Option:XOr(optB)
	local someOptA = self:IsSome()
	local someOptB = optB:IsSome()
	if (someOptA == someOptB) then
		return Option.None
	elseif (someOptA) then
		return self:Unwrap()
	else
		return optB:Unwrap()
	end
end


function Option:Contains(value)
	return (self:IsSome() and self:Unwrap() == value)
end


function Option:__tostring()
	if (self:IsSome()) then
		return ("Option<" .. typeof(self._v) .. ">")
	else
		return "Option<None>"
	end
end


function Option:__eq(opt)
	if (Option.Is(opt)) then
		if (self:IsSome() and opt:IsSome()) then
			return (self:Unwrap() == opt:Unwrap())
		elseif (self:IsNone() and opt:IsNone()) then
			return true
		end
	end
	return false
end


Option.None = Option._new()


return Option
