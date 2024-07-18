[![Release](https://github.com/Sleitnick/Knit/actions/workflows/release.yaml/badge.svg)](https://github.com/Sleitnick/Knit/actions/workflows/release.yaml)
[![CI](https://github.com/Sleitnick/Knit/actions/workflows/ci.yaml/badge.svg)](https://github.com/Sleitnick/Knit/actions/workflows/ci.yaml)
[![Docs](https://github.com/Sleitnick/Knit/actions/workflows/docs.yaml/badge.svg)](https://github.com/Sleitnick/Knit/actions/workflows/docs.yaml)

## :warning: No Longer Maintained :warning:

Knit has been archived and will no longer receive updates.

Please [read here](/ARCHIVAL.md) for more information.

# Knit

Knit is a lightweight framework for Roblox that simplifies communication between core parts of your game and seamlessly bridges the gap between the server and the client.

Read the [documentation](https://sleitnick.github.io/Knit/) for more info.

## Install

Installing Knit is very simple. Just drop the module into ReplicatedStorage. Knit can also be used within a Rojo project.

**Roblox Studio workflow:**

1. Get [Knit](https://www.roblox.com/library/5530714855/Knit) from the Roblox library.
1. Place Knit directly within ReplicatedStorage.

**Wally & Rojo workflow:**

1. Add Knit as a Wally dependency (e.g. `Knit = "sleitnick/knit@^1"`)
1. Use Rojo to point the Wally packages to ReplicatedStorage.

## Basic Usage

The core usage of Knit is the same from the server and the client. The general pattern is to create a single script on the server and a single script on the client. These scripts will load Knit, create services/controllers, and then start Knit.

The most basic usage would look as such:

```lua
local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

Knit.Start():catch(warn)
-- Knit.Start() returns a Promise, so we are catching any errors and feeding it to the built-in 'warn' function
-- You could also chain 'await()' to the end to yield until the whole sequence is completed:
--    Knit.Start():catch(warn):await()
```

That would be the necessary code on both the server and the client. However, nothing interesting is going to happen. Let's dive into some more examples.

### A Simple Service

A service is simply a structure that _serves_ some specific purpose. For instance, a game might have a MoneyService, which manages in-game currency for players. Let's look at a simple example:

```lua
local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

-- Create the service:
local MoneyService = Knit.CreateService {
	Name = "MoneyService",
}

-- Add some methods to the service:

function MoneyService:GetMoney(player)
	-- Do some sort of data fetch
	local money = someDataStore:GetAsync("money")
	return money
end

function MoneyService:GiveMoney(player, amount)
	-- Do some sort of data fetch
	local money = self:GetMoney(player)
	money += amount
	someDataStore:SetAsync("money", money)
end

Knit.Start():catch(warn)
```

Now we have a little MoneyService that can get and give money to a player. However, only the server can use this at the moment. What if we want clients to fetch how much money they have? To do this, we have to create some client-side code to consume our service. We _could_ create a controller, but it's not necessary for this example.

First, we need to expose a method to the client. We can do this by writing methods on the service's Client table:

```lua
-- Money service on the server
...
function MoneyService.Client:GetMoney(player)
	-- We already wrote this method, so we can just call the other one.
	-- 'self.Server' will reference back to the root MoneyService.
	return self.Server:GetMoney(player)
end
...
```

We can write client-side code to fetch money from the service:

```lua
-- Client-side code
local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)
Knit.Start():catch(warn):await()

local MoneyService = Knit.GetService("MoneyService")

MoneyService:GetMoney():andThen(function(money)
	print(money)
end)
```

Under the hood, Knit is creating a RemoteFunction bound to the service's GetMoney method. Knit keeps RemoteFunctions and RemoteEvents out of the way so that developers can focus on writing code and not building networking infrastructure.
