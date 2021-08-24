The [TableUtil](https://github.com/AtollStudios/Knit/blob/main/src/Util/TableUtil.lua) module provides extra functions to deal with tables.

## `Copy`
`TableUtil.Copy(tbl: table): table`

Performs a deep copy of the given table. In other words, all nested tables will also get copied.

Use `Copy` if the entire table must be copied over. Otherwise, use `CopyShallow`.

```lua
local tbl = {"a", "b", "c", {"d", "e", "f"}}
local tblCopy = TableUtil.Copy(tbl)

print(tblCopy) --> {"a", "b", "c", {"d", "e", "f"}}
print(tblCopy[4] == tbl[4]) --> false
```

!!! warning "Cyclical Tables"
	The `Copy` function does _not_ handle cyclical tables. Passing a table with cyclical references to `Copy` will result in a stack-overflow.


`Copy` can be used with arrays and dictionaries.

---------------

## `CopyShallow`
`TableUtil.CopyShallow(tbl: table): table`

Performs a shallow copy of the given table. In other words, all nested tables will not be copied, but only re-referenced. Thus, a nested table in both the original and the copy will be the same.

```lua
local tbl = {"a", "b", "c", {"d", "e", "f"}}
local tblCopy = TableUtil.Copy(tbl)

print(tblCopy) --> {"a", "b", "c", {"d", "e", "f"}}
print(tblCopy[4] == tbl[4]) --> true
```

`CopyShallow` can be used with arrays and dictionaries.

---------------

## `Sync`
`TableUtil.Sync(tbl: table, template: table): table`

Synchronizes the `tbl` table based on `template` table.

- If `tbl` is missing something from `template`, it is added.
- If `tbl` has something that `template` does not, it is removed.
- If `tbl` has a different data type than the item in `template`, overwrite with the `template` value instead.

```lua
local template = {
	kills = 0;
	deaths = 0;
	points = 0;
}

local data = {kills = 10; deaths = "test"; xp = 20}

local syncData = TableUtil.Sync(data, template)
print(syncData) --> {kills = 10, deaths = 0, points = 0}
```

From the above example, `Sync` did the following:
- Kept `kills` the same because it already exists and is of the same data type.
- Overwrote `deaths` to the template value because of the mismatched data type.
- Added `points` because it was missing.
- Removed `xp` because it was not present in the template.

!!! warning "Cyclical Tables"
	Although not shown in the above example, `Sync` will properly handle nested tables; however, it will _not_ handle cyclical tables. Cyclical tables given to `Sync` will throw a stack-overflow error.

`Sync` can be used with arrays and dictionaries.

---------------

## `FastRemove`
`TableUtil.FastRemove(tbl: table, index: number): void`

Quickly removes the index from the table in `O(1)` time. This is done by simply swapping the last value in the table with the given index, and then trimming off the last index. Using `FastRemove` is beneficial where data in large arrays need to be removed quickly and ordering is where the ordering of items in said array are not important.

This function will mutate the given table.

```lua
local tbl = {"Hello", "world", "how", "are", "you"}
TableUtil.FastRemove(tbl, 2) -- Remove index 2 ("world") from the table
print(tbl) --> {"Hello", "you", "how", "are"}
```

!!! warning "Table Order"
	Table order is not preserved when using `FastRemove`. If the ordering of the table must not change, use `table.remove()` instead.

`FastRemove` can only be used with arrays.

---------------

## `FastRemoveFirstValue`
`TableUtil.FastRemoveFirstValue(tbl: table, value: any): (boolean, number | nil)`

Quickly removes the first index in the table that matches `value`. If the value is found, this function will return both `true` and the index at which the value was found. If not found, this function will return `true` and `nil` for the index.

```lua
local tbl = {"Hello", "world", "how", "are", "you"}
local removed, index = TableUtil.FastRemove(tbl, "are")
print(tbl, removed, index) --> {"Hello", "world", "how", "you"}, true, 4
```

`FastRemoveFirstValue` can only be used with arrays.

---------------

## `Map`
`TableUtil.Map(tbl: table, callback: (value: any) -> any): table`

Creates a new table mapped from the original, given the callback predicate. Mapping tables makes it easy to transform large sets of data into a different format.

For instance, if there was a table with a bunch of items representing people's first and last name, `Map` could be used to turn this into a simple combined list of first and last names:
```lua
local people = {
	{FirstName = "John", LastName = "Doe"},
	{FirstName = "Jane", LastName = "Doe"},
	{FirstName = "Jack", LastName = "Smith"},
	{FirstName = "Jill", LastName = "Smith"},
}

local names = TableUtil.Map(people, function(person)
	return person.FirstName .. " " .. person.LastName
end)

print(names) --> {"John Doe", "Jane Doe", "Jack Smith", "Jill Smith"}
```

Bonus: To add a new `FullName` field, the function could be rewritten as such:
```lua
people = TableUtil.Map(people, function(person)
	-- Make a copy of person instead of modifying the original
	person = TableUtil.Copy(person)
	person.FullName = person.FirstName .. " " .. person.LastName
	return person
end)

print(people)
--[[
{
	{FirstName = "John", LastName = "Doe", FullName = "John Doe"},
	{FirstName = "Jane", LastName = "Doe", FullName = "Jane Doe"},
	{FirstName = "Jack", LastName = "Smith", FullName = "Jack Smith"},
	{FirstName = "Jill", LastName = "Smith", FullName = "Jill Smith"},
}
]]
```

`Map` can be used with both arrays and dictionaries.

---------------

## `Filter`
`TableUtil.Filter(tbl: table, callback: (value: any) -> boolean): table`

Creates a new table only containing values that the callback predicate has determined should remain from the original table.

```lua
local scores = {10, 20, 5, 3, 6, 23, 15, 40, 31}
local scoresAboveTwenty = TableUtil.Filter(scores, function(value)
	return value > 20
end)

print(scores) --> {23, 40, 31}
```

`Filter` can be used with both arrays and dictionaries.

---------------

## `Reduce`
`TableUtil.Reduce(tbl: table, callback: (acc: number, val: number) -> number [, init: number]): number`

Reduces the contents of a table to a number.

```lua
local scores = {10, 20, 30}

local totalScore = TableUtil.Reduce(scores, function(accumulator, value)
	return accumulator + value
end)

print(totalScore) --> 60
```

An initial value can also be set as the last argument of `Reduce`:
```lua
local initialValue = 40
local scores = {10, 20, 30}

local totalScore = TableUtil.Reduce(scores, function(accumulator, value)
	return accumulator + value
end, initialValue)

print(totalScore) --> 100
```

`Reduce` can be used with both arrays and dictionaries.

---------------

## `Assign`
`TableUtil.Assign(target: table, ...sources: table): table`

Assigns the values of `sources` to a copy of `target`. This is useful for composing an object.

```lua
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
	return TableUtil.Assign(state, Driver(), Teleporter())
end

local car = CreateCar()
car:Drive()
car:Teleport(Vector3.new(0, 10, 0))
```

`Assign` can be used with both arrays and dictionaries, but is most commonly used on dictionaries.

---------------

## `Extend`
`TableUtil.Extend(tbl: table, extension: table): table`

Extends an array with another. This essentially appends the entirety of the `extension` table at the end of `tbl`.

```lua
local data = {10, 20, 30}
local newData = {40, 50, 60}

local combinedData = TableUtil.Extend(data, newData)

print(combinedData) --> {10, 20, 30, 40, 50, 60}
```

!!! note "Shallow Copy"
	The movement of `extension` to `tbl` is a shallow copy.

`Extend` can only be used with arrays.

---------------

## `Reverse`
`TableUtil.Reverse(tbl: table): table`

Creates a reversed version of the table.

```lua
local data = {1, 2, 3, 4, 5}
local reversed = TableUtil.Reverse(data)

print(reversed) --> {5, 4, 3, 2, 1}
```

`Reverse` can only be used with arrays.

---------------

## `Shuffle`
`TableUtil.Shuffle(tbl: table [, rng: Random]): table`

Creates a shallow copy of the given table and shuffles it using the [Fisher-Yates shuffle](https://en.wikipedia.org/wiki/Fisher%E2%80%93Yates_shuffle) algorithm. If desired, a [Random](https://developer.roblox.com/en-us/api-reference/datatype/Random) object can be passed as a second argument to override the default RNG in TableUtil.

```lua
local music = {"Song1", "Song2", "Song3", "Song4", "Song5"}

local shuffledMusic = TableUtil.Shuffle(music)

print(shuffledMusic) --> e.g. {"Song4", "Song5", "Song2", "Song3", "Song1"}
```

`Shuffle` can only be used with arrays.

---------------

## `Sample`
`TableUtil.Sample(tbl: table, size: number [, rng: Random]): table`

Returns a random sample of the given array. The sample size is determined by the `size` argument.

```lua
local names = {"John", "Mary", "Ron", "Julie", "Sam"}
local sample = TableUtil.Sample(names, 3)

print(sample) --> e.g. {"Julie", "John", "Sam"}
```

`Sample` can only be used with arrays.

---------------

## `Flat`
`TableUtil.Flat(tbl: table [, maxDepth: number = 1]): table`

Flattens out an array that might have multiple nested arrays. The `maxDepth` optional parameter controls how deep the function can go into nested arrays.

```lua
local tbl = {1, 2, {3, 4, {5, 6}}, {7, {8, 9}}}

local flat = TableUtil.Flat(tbl, 2)

print(flat) --> {1, 2, 3, 4, 5, 6, 7, 8, 9}
```

`Flat` can only be used with arrays.

---------------

## `FlatMap`
`TableUtil.FlatMap(tbl: callback: (value: any) -> table): table`

For each value in a table, `FlatMap` will call `Map` on the item and then `Flat` (with a max depth of 1) on whatever was returned from `Map`.

```lua
local tbl = {
	"Flat map",
	"is",
	"really cool to",
	"use"
}

local flatMap = TableUtil.FlatMap(tbl, function(words)
	return words:split(" ")
end)

print(flatMap) --> {"Flat", "map", "is", "really", "cool", "to", "use"}
```

`FlatMap` can only be used with arrays.

---------------

## `Keys`
`TableUtil.Keys(tbl: table): table`

Returns an array of all keys in the table.

```lua
local tbl = {Hello = 0, World = 1}

local keys = TableUtil.Keys(tbl)

print(keys) --> {"Hello", "World"}
```

!!! note "No Ordering"
	Lua dictionaries have no set ordering for keys, so the order of keys in the returned table may be different per call. If ordering is important, use `table.sort()` on the returned array of keys.

`Keys` can be used with both arrays and dictionaries, but only makes sense to use with dictionaries.

---------------

## `Find`
`TableUtil.Find(tbl: table, callback: (value: any) -> boolean): (any, number | nil)`

Finds a value in the given table using the callback predicate. If found, the value and the index are returned. If not found, `nil` is returned.

```lua
local tbl = {
	{Name = "John", Score = 10},
	{Name = "Jane", Score = 20},
	{Name = "Jerry", Score = 30}
}

local person, index = TableUtil.Find(tbl, function(p)
	return p.Name == "Jane"
end)

print(person, index) --> "Jane", 2
```

!!! note "Not the same as `table.find()`"
	This is _not_ the same as `table.find()`, which returns the index of the first matched value. Using `Find` allows for more complex searches, since the condition can be computed more than simply an equality check.

`Find` can be used with both arrays and dictionaries.

---------------

## `Every`
`TableUtil.Every(tbl: table, callback: (value: any) -> boolean): boolean`

Returns `true` if every value in the table returns `true` against the callback predicate.

```lua
local numbers = {7, 20, 30}

local allAboveFive = TableUtil.Every(numbers, function(num)
	return num > 5
end)

local allAboveTen = TableUtil.Every(numbers, function(num)
	return num > 10
end)

print("AllAboveFive", allAboveFive) --> AllAboveFive, true
print("AllAboveTen", allAboveTen) --> AllAboveTen, false
```

`Every` can be used with both arrays and dictionaries.

---------------

## `Some`
`TableUtil.Some(tbl: table, callback: (value: any) -> boolean): boolean`

Returns `true` if at least one value in the table returns `true` against the callback predicate.

```lua
local numbers = {10, 50, 100}

local someAboveSeventy = TableUtil.Some(numbers, function(num)
	return num > 70
end)

local someBelowFive = TableUtil.Every(numbers, function(num)
	return num < 5
end)

print("SomeAboveSeventy", someAboveSeventy) --> SomeAboveSeventy, true
print("SomeBelowFive", someBelowFive) --> SomeBelowFive, false
```

`Some` can be used with both arrays and dictionaries.

---------------

## `Truncate`
`TableUtil.Truncate(tbl: table, length: number): table`

Truncates a table to the specified length.

```lua
local t1 = {10, 20, 30, 40, 50}
local t2 = TableUtil.Truncate(t1, 3)

print(t2) --> {10, 20, 30}
```

---------------

## `Zip`
`TableUtil.Zip(...table): Iterator`

Returns an iterator that can be used to iterate through multiple different arrays or dictionaries. Any overlapping indices between all given tables will be included in the iteration.

```lua
local a = {4, 5, 6}
local b = {9, 8, 7}

for i,values in TableUtil.Zip(a, b) do
	print(i, values)
end
--> 1 {4, 9}
--> 2 {5, 8}
--> 3 {6, 7}
```

```lua
local a = {X = 10, Y = 20, Z = 30}
local b = {X = 40, Y = 50, Z = 60}
local c = {X = 70, Y = 80, Z = 90}

for k,values in TableUtil.Zip(a, b, c) do
	print(k, values)
end
--> X {10, 40, 70}
--> Y {20, 50, 80}
--> Z {30, 60, 90}
```

---------------

## `IsEmpty`
`TableUtil.IsEmpty(tbl: table): boolean`

Returns `true` if the table is empty. The implementation for this is simply checking against the condition: `next(tbl) == nil`.

```lua
local t1 = {}
local t2 = {32}
local t3 = {num = 10}

print("T1 empty", TableUtil.IsEmpty(t1)) --> T1 empty, true
print("T2 empty", TableUtil.IsEmpty(t2)) --> T2 empty, false
print("T3 empty", TableUtil.IsEmpty(t3)) --> T3 empty, false
```

`IsEmpty` can be used with both arrays and dictionaries.

---------------

## `EncodeJSON`
`TableUtil.EncodeJSON(tbl: table): string`

Transforms the given table into a JSON string. An error will be thrown if the table cannot be transformed. Internally, this is just a proxy for [`HttpService:JSONEncode()`](https://developer.roblox.com/en-us/api-reference/function/HttpService/JSONEncode).

```lua
local tbl = {
	xp = 100;
	money = 500;
}

local json = TableUtil.EncodeJSON(tbl)

print(json) --> {"xp": 100, "money": 500}
```

---------------

## `DecodeJSON`
`TableUtil.DecodeJSON(json: string): table`

Transforms the given JSON string into a Lua table. An error will be thrown if the JSON string cannot be transformed. Internally, this is just a proxy for [`HttpService:JSONDecode()`](https://developer.roblox.com/en-us/api-reference/function/HttpService/JSONDecode).

```lua
local json = [[{"xp": 100, "money": 500}]]

local tbl = TableUtil.DecodeJSON(json)

print(tbl) --> {xp = 100, money = 500}
```