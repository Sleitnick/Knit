An [Option](https://github.com/Sleitnick/Knit/blob/main/src/Util/Option.lua) is a powerful concept taken from [Rust](https://doc.rust-lang.org/std/option/index.html) and other languages. The purpose is to represent an optional value. An option can either be `Some` or `None`. Using Options helps reduce `nil` bugs (which can cause silent bugs that can be hard to track down). Options automatically serialize/deserialize across the server/client boundary when passed through services or controllers.

For full documentation, check out the [LuaOption](https://github.com/Sleitnick/LuaOption) repository.

Using Options is very simple:

```lua
local Option = require(Knit.Util.Option)

-- Returns an Option:
local function DoSomething()
	local rng = Random.new()
	local value = rng:NextNumber()
	if (value > 0.5) then
		return Option.Some(value)
	else
		return Option.None
	end
end

-- Get option value:
local value = DoSomething()

-- Match if the value is 'some' or 'none':
value:Match {
	Some = function(value) print("Got value:", value),
	None = function() print("Got no value") end
}

-- Optionally, use IsSome() and Unwrap():
if (value:IsSome()) then
	print("Got value:", value:Unwrap())
end
```

Because these are automatically serialized/deserialized in services and controllers, they work great in cases where a returned result is uncertain:

```lua
-- SERVICE:
local MyService = Knit.CreateService { Name = "MyService" }
local Option = require(Knit.Util.Option)

function MyService.Client:GetWeapon(player, weaponName)
	local weapon = TryToGetWeaponSomehow(player, weaponName)
	if (weapon) then
		return Option.Some(weapon)
	else
		return Option.None
	end
end

----

-- CONTROLLER:
local MyController = Knit.CreateController { Name = "MyController" }

function MyController:KnitStart()
	local MyService = Knit.GetService("MyService")
	local weaponOption = MyService:GetWeapon("SomeWeapon")
	weaponOption:Match {
		Some = function(weapon) --[[ Do something with weapon ]] end,
		None = function() warn("No weapon found") end
	}
end
```

!!! note
	Attempting to unwrap an option with no value will throw an error. This is intentional. The purpose is to avoid unhandled `nil` cases. Whenever calling `Unwrap()`, be sure that `IsSome()` was first checked. Using the `Match` pattern is the easiest way to handle both Some and None cases.