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
	TableUtil.Shuffle(tbl: table): table
	TableUtil.Flat(tbl: table [, maxDepth: number = 1]): table
	TableUtil.FlatMap(tbl: callback: (value: any) -> table): table
	TableUtil.Keys(tbl: table): table
	TableUtil.Find(tbl: table, callback: (value: any) -> boolean): (any, number)
	TableUtil.Every(tbl: table, callback: (value: any) -> boolean): boolean
	TableUtil.Some(tbl: table, callback: (value: any) -> boolean): boolean
	TableUtil.IsEmpty(tbl: table): boolean
	TableUtil.EncodeJSON(tbl: table): string
	TableUtil.DecodeJSON(json: string): table

	EXAMPLES:

		Copy:

			Performs a deep copy of the given table. In other words,
			all nested tables will also get copied.

			local tbl = {"a", "b", "c"}
			local tblCopy = TableUtil.Copy(tbl)


		CopyShallow:

			Performs a shallow copy of the given table. In other words,
			all nested tables will not be copied, but only moved by
			reference. Thus, a nested table in both the original and
			the copy will be the same.

			local tbl = {"a", "b", "c"}
			local tblCopy = TableUtil.CopyShallow(tbl)


		Sync:

			Synchronizes a table to a template table. If the table does not have an
			item that exists within the template, it gets added. If the table has
			something that the template does not have, it gets removed.

			local tbl1 = {kills = 0; deaths = 0; points = 0}
			local tbl2 = {points = 0}
			TableUtil.Sync(tbl2, tbl1)  -- In words: "Synchronize table2 to table1"
			print(tbl2.deaths)


		FastRemove:

			Removes an item from an array at a given index. Only use this if you do
			NOT care about the order of your array. This works by simply popping the
			last item in the array and overwriting the given index with the last
			item. This is O(1), compared to table.remove's O(n) speed.

			local tbl = {"hello", "there", "this", "is", "a", "test"}
			TableUtil.FastRemove(tbl, 2)   -- Remove "there" in the array
			print(table.concat(tbl, " "))  -- > hello test is a


		FastRemoveFirstValue:

			Calls FastRemove on the first index that holds the given value.

			local tbl = {"abc", "hello", "hi", "goodbye", "hello", "hey"}
			local removed, atIndex = TableUtil.FastRemoveFirstValue(tbl, "hello")
			if (removed) then
				print("Removed at index " .. atIndex)
				print(table.concat(tbl, " "))  -- > abc hi goodbye hello hey
			else
				print("Did not find value")
			end


		Map:

			This allows you to construct a new table by calling the given function
			on each item in the table.

			local peopleData = {
				{firstName = "Bob"; lastName = "Smith"};
				{firstName = "John"; lastName = "Doe"};
				{firstName = "Jane"; lastName = "Doe"};
			}

			local people = TableUtil.Map(peopleData, function(item)
				return {Name = item.firstName .. " " .. item.lastName}
			end)

			-- 'people' is now an array that looks like: { {Name = "Bob Smith"}; ... }


		Filter:

			This allows you to create a table based on the given table and a filter
			function. If the function returns 'true', the item remains in the new
			table; if the function returns 'false', the item is discluded from the
			new table.

			local people = {
				{Name = "Bob Smith"; Age = 42};
				{Name = "John Doe"; Age = 34};
				{Name = "Jane Doe"; Age = 37};
			}

			local peopleUnderForty = TableUtil.Filter(people, function(item)
				return item.Age < 40
			end)


		Reduce:

			This allows you to reduce an array to a single value. Useful for quickly
			summing up an array.

			local tbl = {40, 32, 9, 5, 44}
			local tblSum = TableUtil.Reduce(tbl, function(accumulator, value)
				return accumulator + value
			end)
			print(tblSum)  -- > 130


		Assign:

			This allows you to assign values from multiple tables into one. The
			Assign function is very similar to JavaScript's Object.Assign() and
			is useful for things such as composition-designed systems.

			local function Driver()
				return {
					Drive = function(self) self.Speed = 10 end;
				}
			end

			local function Teleporter()
				return {
					Teleport = function(self, pos) self.Position = pos end;
				}
			end

			local function CreateCar()
				local state = {
					Speed = 0;
					Position = Vector3.new();
				}
				-- Assign the Driver and Teleporter components to the car:
				return TableUtil.Assign({}, Driver(), Teleporter())
			end

			local car = CreateCar()
			car:Drive()
			car:Teleport(Vector3.new(0, 10, 0))


		Reverse:

			Creates a reversed version of the array. Note: This is a shallow
			copy, so existing references will remain within the new table.

			local tbl = {2, 4, 6, 8}
			local rblReversed = TableUtil.Reverse(tbl)  -- > {8, 6, 4, 2}


		Shuffle:

			Shuffles (i.e. randomizes) an array. This uses the Fisher-Yates algorithm.

			local tbl = {1, 2, 3, 4, 5, 6, 7, 8, 9}
			TableUtil.Shuffle(tbl)
			print(table.concat(tbl, ", "))  -- e.g. > 3, 6, 9, 2, 8, 4, 1, 7, 5


		Flat:

			Flattens out an array that might have multiple nested arrays.

			local tbl = {1, 2, {3, 4, {5, 6}}, {7, {8, 9}}}
			local flat = TableUtil.Flat(tbl, 2)
			--> {1, 2, 3, 4, 5, 6, 7, 8, 9}


		FlatMap:

			For each item in a table, calls Map on the item and then Flat
			on whatever Map returns.

			local tbl = {
				"Flat map",
				"is",
				"really cool to"
				"use"
			}

			local flatMap = TableUtil.FlatMap(tbl, function(words)
				return words:split(" ")
			end)
			--> {"Flat", "map", "is", "really", "cool", "to", "use"}


		Keys:

			Returns an array of all the keys in the table.

			local tbl = {hello = 32, world = 64}
			local keys = TableUtil.Keys(tbl)
			--> {"hello", "world"}


		Find:

			Returns the found item and its index based on the callback.

			local tbl = {
				{Name = "John", Score = 10},
				{Name = "Jane", Score = 20},
				{Name = "Jerry", Score = 30}
			}

			local person, index = TableUtil.Find(tbl, function(p)
				return p.Name == "Jane"
			end)

			print(person, index) --> "Jane", 2


		Every:

			Returns true if every item in the table passes the callback condition.

			local tbl = {10, 20, 30, 40}

			-- Check if every item in the table is greater or equal to 10:
			local every = TableUtil.Every(tbl, function(num)
				return num >= 10
			end)

			if every then ... end


		Some:

			Returns true if at least one item in the table passes the callback condition.

			local tbl = {10, 20, 30, 40}

			-- Check if at least one item in the table is greater or equal to 40:
			local some = TableUtil.Some(tbl, function(num)
				return num >= 40
			end)

			if some then ... end

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

	local tbl = CopyTable(srcTbl)

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
	local tbl = CopyTable(target)
	for _,src in ipairs({...}) do
		for k,v in pairs(src) do
			tbl[k] = v
		end
	end
	return tbl
end


local function Extend(target, extension)
	local tbl = CopyTable(target)
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


local function Shuffle(tbl)
	assert(type(tbl) == "table", "First argument must be a table")
	local shuffled = CopyTable(tbl)
	for i = #tbl, 2, -1 do
		local j = rng:NextInteger(1, i)
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
