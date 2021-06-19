-- Table Util
-- Stephen Leitnick
-- September 13, 2017

--[[

	TableUtil.Copy(tbl: table): table
	TableUtil.CopyShallow(tbl: table): table
	TableUtil.Sync(tbl: table, template: table): void
	TableUtil.FastRemove(tbl: table, index: number): void
	TableUtil.FastRemoveFirstValue(tbl: table, value: any): (boolean, number)
	TableUtil.Map(tbl: table, callback: (value: any) -> any): table
	TableUtil.Filter(tbl: table, callback: (value: any) -> boolean): table
	TableUtil.Reduce(tbl: table, callback: (accum: number, value: number) -> number [, initialValue: number]): number
	TableUtil.Assign(target: table, ...sources: table): table
	TableUtil.Extend(tbl: table, extension: table): table
	TableUtil.Reverse(tbl: table): table
	TableUtil.Shuffle(tbl: table [, rng: Random]): table
	TableUtil.Flat(tbl: table [, maxDepth: number = 1]): table
	TableUtil.FlatMap(tbl: callback: (value: any) -> table): table
	TableUtil.Keys(tbl: table): table
	TableUtil.Find(tbl: table, callback: (value: any) -> boolean): (any, number)
	TableUtil.Every(tbl: table, callback: (value: any) -> boolean): boolean
	TableUtil.Some(tbl: table, callback: (value: any) -> boolean): boolean
	TableUtil.IsEmpty(tbl: table): boolean
	TableUtil.EncodeJSON(tbl: table): string
	TableUtil.DecodeJSON(json: string): table

--]]


local TableUtil = {}

local HttpService = game:GetService("HttpService")
local rng = Random.new()


local function CopyTable(t)
	assert(type(t) == "table", "First argument must be a table")
	local function Copy(tbl)
		local tCopy = table.create(#tbl)
		for k,v in pairs(tbl) do
			if (type(v) == "table") then
				tCopy[k] = Copy(v)
			else
				tCopy[k] = v
			end
		end
		return tCopy
	end
	return Copy(t)
end


local function CopyTableShallow(t)
	local tCopy = table.create(#t)
	if (#t > 0) then
		table.move(t, 1, #t, 1, tCopy)
	else
		for k,v in pairs(t) do tCopy[k] = v end
	end
	return tCopy
end


local function Sync(srcTbl, templateTbl)

	assert(type(srcTbl) == "table", "First argument must be a table")
	assert(type(templateTbl) == "table", "Second argument must be a table")

	local tbl = CopyTableShallow(srcTbl)

	-- If 'tbl' has something 'templateTbl' doesn't, then remove it from 'tbl'
	-- If 'tbl' has something of a different type than 'templateTbl', copy from 'templateTbl'
	-- If 'templateTbl' has something 'tbl' doesn't, then add it to 'tbl'
	for k,v in pairs(tbl) do

		local vTemplate = templateTbl[k]

		-- Remove keys not within template:
		if (vTemplate == nil) then
			tbl[k] = nil

		-- Synchronize data types:
		elseif (type(v) ~= type(vTemplate)) then
			if (type(vTemplate) == "table") then
				tbl[k] = CopyTable(vTemplate)
			else
				tbl[k] = vTemplate
			end

		-- Synchronize sub-tables:
		elseif (type(v) == "table") then
			tbl[k] = Sync(v, vTemplate)
		end

	end

	-- Add any missing keys:
	for k,vTemplate in pairs(templateTbl) do

		local v = tbl[k]

		if (v == nil) then
			if (type(vTemplate) == "table") then
				tbl[k] = CopyTable(vTemplate)
			else
				tbl[k] = vTemplate
			end
		end

	end

	return tbl

end


local function FastRemove(t, i)
	local n = #t
	t[i] = t[n]
	t[n] = nil
end


local function FastRemoveFirstValue(t, v)
	local index = table.find(t, v)
	if (index) then
		FastRemove(t, index)
		return true, index
	end
	return false, nil
end


local function Map(t, f)
	assert(type(t) == "table", "First argument must be a table")
	assert(type(f) == "function", "Second argument must be a function")
	local newT = table.create(#t)
	for k,v in pairs(t) do
		newT[k] = f(v, k, t)
	end
	return newT
end


local function Filter(t, f)
	assert(type(t) == "table", "First argument must be a table")
	assert(type(f) == "function", "Second argument must be a function")
	local newT = table.create(#t)
	if (#t > 0) then
		local n = 0
		for i,v in ipairs(t) do
			if (f(v, i, t)) then
				n += 1
				newT[n] = v
			end
		end
	else
		for k,v in pairs(t) do
			if (f(v, k, t)) then
				newT[k] = v
			end
		end
	end
	return newT
end


local function Reduce(t, f, init)
	assert(type(t) == "table", "First argument must be a table")
	assert(type(f) == "function", "Second argument must be a function")
	assert(init == nil or type(init) == "number", "Third argument must be a number or nil")
	local result = (init or 0)
	for k,v in pairs(t) do
		result = f(result, v, k, t)
	end
	return result
end


local function Assign(target, ...)
	local tbl = CopyTableShallow(target)
	for _,src in ipairs({...}) do
		for k,v in pairs(src) do
			tbl[k] = v
		end
	end
	return tbl
end


local function Extend(target, extension)
	local tbl = CopyTableShallow(target)
	for _,v in ipairs(extension) do
		table.insert(tbl, v)
	end
	return tbl
end


local function Reverse(tbl)
	local n = #tbl
	local tblRev = table.create(n)
	for i = 1,n do
		tblRev[i] = tbl[n - i + 1]
	end
	return tblRev
end


local function Shuffle(tbl, rngOverride)
	assert(type(tbl) == "table", "First argument must be a table")
	local shuffled = CopyTableShallow(tbl)
	local random = (rngOverride or rng)
	for i = #tbl, 2, -1 do
		local j = random:NextInteger(1, i)
		shuffled[i], shuffled[j] = shuffled[j], shuffled[i]
	end
	return shuffled
end


local function Flat(tbl, depth)
	depth = (depth or 1)
	local flatTbl = table.create(#tbl)
	local function Scan(t, d)
		for _,v in ipairs(t) do
			if (type(v) == "table" and d < depth) then
				Scan(v, d + 1)
			else
				table.insert(flatTbl, v)
			end
		end
	end
	Scan(tbl, 0)
	return flatTbl
end


local function FlatMap(tbl, callback)
	return Flat(Map(tbl, callback))
end


local function Keys(tbl)
	local keys = table.create(#tbl)
	for k in pairs(tbl) do
		table.insert(keys, k)
	end
	return keys
end


local function Find(tbl, callback)
	for k,v in pairs(tbl) do
		if (callback(v, k, tbl)) then
			return v, k
		end
	end
	return nil, nil
end


local function Every(tbl, callback)
	for k,v in pairs(tbl) do
		if (not callback(v, k, tbl)) then
			return false
		end
	end
	return true
end


local function Some(tbl, callback)
	for k,v in pairs(tbl) do
		if (callback(v, k, tbl)) then
			return true
		end
	end
	return false
end


local function IsEmpty(tbl)
	return (next(tbl) == nil)
end

local function Truncate(tbl, len)
	return table.move(tbl, 1, #tbl - len, 1, table.create(#tbl - len))
end

local function EncodeJSON(tbl)
	return HttpService:JSONEncode(tbl)
end


local function DecodeJSON(str)
	return HttpService:JSONDecode(str)
end


TableUtil.Copy = CopyTable
TableUtil.CopyShallow = CopyTableShallow
TableUtil.Sync = Sync
TableUtil.FastRemove = FastRemove
TableUtil.FastRemoveFirstValue = FastRemoveFirstValue
TableUtil.Map = Map
TableUtil.Filter = Filter
TableUtil.Reduce = Reduce
TableUtil.Assign = Assign
TableUtil.Extend = Extend
TableUtil.Reverse = Reverse
TableUtil.Shuffle = Shuffle
TableUtil.Flat = Flat
TableUtil.FlatMap = FlatMap
TableUtil.Keys = Keys
TableUtil.Find = Find
TableUtil.Every = Every
TableUtil.Some = Some
TableUtil.IsEmpty = IsEmpty
TableUtil.EncodeJSON = EncodeJSON
TableUtil.DecodeJSON = DecodeJSON


return TableUtil
