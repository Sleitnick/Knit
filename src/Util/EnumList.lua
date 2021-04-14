-- EnumList
-- Stephen Leitnick
-- January 08, 2021

--[[

	enumList = EnumList.new(name: string, enums: string[])

	enumList:Is(item)


	Example:

		direction = EnumList.new("Direction", {"Up", "Down", "Left", "Right"})
		leftDir = direction.Left
		print("IsDirection", direction:Is(leftDir))

--]]


local Symbol = require(script.Parent.Symbol)

local EnumList = {}


function EnumList.new(name, enums)
	local scope = Symbol.new(name)
	local enumItems = {}
	for _,enumName in ipairs(enums) do
		enumItems[enumName] = Symbol.new(enumName, scope)
	end
	local self = setmetatable({
		_scope = scope;
	}, {
		__index = function(_t, k)
			if (enumItems[k]) then
				return enumItems[k]
			elseif (EnumList[k]) then
				return EnumList[k]
			else
				error("Unknown " .. name .. ": " .. tostring(k), 2)
			end
		end;
		__newindex = function()
			error("Cannot add new " .. name, 2)
		end;
	})
	return self
end


function EnumList:Is(obj)
	return Symbol.IsInScope(obj, self._scope)
end


return EnumList