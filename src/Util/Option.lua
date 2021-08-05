-- Option
-- Stephen Leitnick
-- August 28, 2020

--[[

	MatchTable {
		Some: (value: any) -> any
		None: () -> any
	}

	CONSTRUCTORS:

		Option.Some(anyNonNilValue): Option<any>
		Option.Wrap(anyValue): Option<any>


	STATIC FIELDS:

		Option.None: Option<None>


	STATIC METHODS:

		Option.Is(obj): boolean


	METHODS:

		opt:Match(): (matches: MatchTable) -> any
		opt:IsSome(): boolean
		opt:IsNone(): boolean
		opt:Unwrap(): any
		opt:Expect(errMsg: string): any
		opt:ExpectNone(errMsg: string): void
		opt:UnwrapOr(default: any): any
		opt:UnwrapOrElse(default: () -> any): any
		opt:And(opt2: Option<any>): Option<any>
		opt:AndThen(predicate: (unwrapped: any) -> Option<any>): Option<any>
		opt:Or(opt2: Option<any>): Option<any>
		opt:OrElse(orElseFunc: () -> Option<any>): Option<any>
		opt:XOr(opt2: Option<any>): Option<any>
		opt:Contains(value: any): boolean

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


type SerializedOption = {
	ClassName: string,
	Value: any,
}

type Matches = {
	Some: (Option) -> any,
	None: () -> any,
}


local CLASSNAME = "Option"

local Option = {}
Option.__index = Option


function Option._new(value: any): Option
	local self = setmetatable({
		ClassName = CLASSNAME;
		_v = value;
		_s = (value ~= nil);
	}, Option)
	return self
end


function Option.Some(value: any): Option
	assert(value ~= nil, "Option.Some() value cannot be nil")
	return Option._new(value)
end


function Option.Wrap(value: any): Option
	if value == nil then
		return Option.None
	else
		return Option.Some(value)
	end
end


function Option.Is(obj: any): boolean
	return type(obj) == "table" and getmetatable(obj) == Option
end


function Option.Assert(obj: any)
	assert(Option.Is(obj), "Result was not of type Option")
end


function Option.Deserialize(data: SerializedOption): Option
	assert(type(data) == "table" and data.ClassName == CLASSNAME, "Invalid data for deserializing Option")
	return data.Value == nil and Option.None or Option.Some(data.Value)
end


function Option:Serialize(): SerializedOption
	return {
		ClassName = self.ClassName;
		Value = self._v;
	}
end


function Option:Match(matches: Matches): any
	local onSome = matches.Some
	local onNone = matches.None
	assert(type(onSome) == "function", "Missing 'Some' match")
	assert(type(onNone) == "function", "Missing 'None' match")
	if self:IsSome() then
		return onSome(self:Unwrap())
	else
		return onNone()
	end
end


function Option:IsSome(): boolean
	return self._s
end


function Option:IsNone(): boolean
	return (not self._s)
end


function Option:Expect(msg: string): any
	assert(self:IsSome(), msg)
	return self._v
end


function Option:ExpectNone(msg: string)
	assert(self:IsNone(), msg)
end


function Option:Unwrap(): any
	return self:Expect("Cannot unwrap option of None type")
end


function Option:UnwrapOr(default: any): any
	if self:IsSome() then
		return self:Unwrap()
	else
		return default
	end
end


function Option:UnwrapOrElse(defaultFunc: () -> any): any
	if self:IsSome() then
		return self:Unwrap()
	else
		return defaultFunc()
	end
end


function Option:And(optB: Option): Option
	if self:IsSome() then
		return optB
	else
		return Option.None
	end
end


function Option:AndThen(andThenFunc: (any) -> Option): Option
	if self:IsSome() then
		local result = andThenFunc(self:Unwrap())
		Option.Assert(result)
		return result
	else
		return Option.None
	end
end


function Option:Or(optB: Option): Option
	if self:IsSome() then
		return self
	else
		return optB
	end
end


function Option:OrElse(orElseFunc: () -> Option): Option
	if self:IsSome() then
		return self
	else
		local result = orElseFunc()
		Option.Assert(result)
		return result
	end
end


function Option:XOr(optB: Option): Option
	local someOptA = self:IsSome()
	local someOptB = optB:IsSome()
	if someOptA == someOptB then
		return Option.None
	elseif someOptA then
		return self
	else
		return optB
	end
end


function Option:Filter(predicate: (any) -> any): Option
	if self:IsNone() or not predicate(self._v) then
		return Option.None
	else
		return self
	end
end


function Option:Contains(value: any): boolean
	return self:IsSome() and self._v == value
end


function Option:__tostring(): string
	if self:IsSome() then
		return ("Option<" .. typeof(self._v) .. ">")
	else
		return "Option<None>"
	end
end


function Option:__eq(opt: Option): boolean
	if Option.Is(opt) then
		if self:IsSome() and opt:IsSome() then
			return (self:Unwrap() == opt:Unwrap())
		elseif self:IsNone() and opt:IsNone() then
			return true
		end
	end
	return false
end


Option.None = Option._new()


export type Option = typeof(Option.Some(true))


return Option
