--!strict

-- Ser
-- Stephen Leitnick
-- August 28, 2020

--[[

	Ser is a serialization/deserialization utility module that is used
	by Knit to automatically serialize/deserialize values passing
	through remote functions and remote events.


	Ser.Classes = {
		[ClassName] = {
			Serialize = (value) -> serializedValue
			Deserialize = (value) => deserializedValue
		}
	}

	Ser.SerializeArgs(...)            -> table
	Ser.SerializeArgsAndUnpack(...)   -> Tuple
	Ser.DeserializeArgs(...)          -> table
	Ser.DeserializeArgsAndUnpack(...) -> Tuple
	Ser.Serialize(value: any)         -> any
	Ser.Deserialize(value: any)       -> any
	Ser.UnpackArgs(args: table)       -> Tuple

--]]


type Args = {
	n: number,
	[any]: any,
}


local Option = require(script.Parent.Option)

local Ser = {}

Ser.Classes = {
	Option = {
		Serialize = function(opt) return opt:Serialize() end;
		Deserialize = Option.Deserialize;
	};
}


function Ser.SerializeArgs(...: any): Args
	local args = table.pack(...)
	for i,arg in ipairs(args) do
		if type(arg) == "table" then
			local ser = Ser.Classes[arg.ClassName]
			if ser then
				args[i] = ser.Serialize(arg)
			end
		end
	end
	return args
end


function Ser.SerializeArgsAndUnpack(...: any): ...any
	local args = Ser.SerializeArgs(...)
	return table.unpack(args, 1, args.n)
end


function Ser.DeserializeArgs(...: any): Args
	local args = table.pack(...)
	for i,arg in ipairs(args) do
		if type(arg) == "table" then
			local ser = Ser.Classes[arg.ClassName]
			if ser then
				args[i] = ser.Deserialize(arg)
			end
		end
	end
	return args
end


function Ser.DeserializeArgsAndUnpack(...: any): ...any
	local args = Ser.DeserializeArgs(...)
	return table.unpack(args, 1, args.n)
end


function Ser.Serialize(value: any): any
	if type(value) == "table" then
		local ser = Ser.Classes[value.ClassName]
		if ser then
			value = ser.Serialize(value)
		end
	end
	return value
end


function Ser.Deserialize(value: any): any
	if type(value) == "table" then
		local ser = Ser.Classes[value.ClassName]
		if ser then
			value = ser.Deserialize(value)
		end
	end
	return value
end


function Ser.UnpackArgs(args: Args): ...any
	return table.unpack(args, 1, args.n)
end


return Ser
