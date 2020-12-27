-- Symbol
-- Stephen Leitnick
-- December 27, 2020


local CLASSNAME = "Symbol"

local Symbol = {}
Symbol.__index = Symbol


function Symbol.new(id, scope)
	assert(id ~= nil, "Symbol ID cannot be nil")
	if (scope ~= nil) then
		assert(Symbol.Is(scope), "Scope must be a Symbol or nil")
	end
	local self = setmetatable({
		ClassName = CLASSNAME;
		_id = id;
		_scope = scope;
	}, Symbol)
	return self
end


function Symbol.Is(obj)
	return (type(obj) == "table" and getmetatable(obj) == Symbol)
end


function Symbol.IsScope(obj, scope)
	return (Symbol.Is(obj) and obj._scope == scope)
end


function Symbol:__tostring()
	return ("Symbol<%s>"):format(self._id)
end


return Symbol