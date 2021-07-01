![Release](https://github.com/Sleitnick/Knit/workflows/Release/badge.svg)
![Lint](https://github.com/Sleitnick/Knit/workflows/Lint/badge.svg)
![Deploy Docs](https://github.com/Sleitnick/Knit/workflows/Deploy%20Docs/badge.svg)

# Knit

<img align="right" src="logo/rounded/knit_logo_rounded_256.png" width="128px" style="margin-left: 20px;">

Knit is a lightweight framework for Roblox that simplifies communication between core parts of your game and seamlessly bridges the gap between the server and the client.

Read the [documentation](https://sleitnick.github.io/Knit/) for more info.

Check out the [Knit video tutorials](https://www.youtube.com/playlist?list=PLk3R4TM3pnqusf59x2tZ8f-5vE2c3L5S9) for hands-on examples.

-------------------

## Alpha
Knit is still in alpha, but will soon be elevated to beta. See the [Beta Roadmap](https://github.com/Sleitnick/Knit/projects/1) for more info. Please be aware that breaking changes may still be introduced.

-------------------

## Example

Here is a simple and fully-working example where a PointsService is created server-side and lets the client access points from the service. No RemoteFunctions or RemoteEvents have to be made; those are handled internally by Knit.

**Server:**
```lua
local Knit = require(game:GetService("ReplicatedStorage").Knit)

-- Create a PointsService:
local PointsService = Knit.CreateService {
	Name = "PointsService";
	Client = {};
}

-- Expose an endpoint that the client can invoke:
function PointsService.Client:GetPoints(player)
	return 10
end

Knit.Start()
```

**Client:**
```lua
local Knit = require(game:GetService("ReplicatedStorage").Knit)

local MyController = Knit.CreateController {
	Name = "MyController";
}

function MyController:KnitStart()
	-- Fetch points from the server-side PointsService:
	local PointsService = Knit.GetService("PointsService")
	local points = PointsService:GetPoints()
	print("Points", points)
end

Knit.Start()
```
