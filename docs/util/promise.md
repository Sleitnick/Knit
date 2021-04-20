The [Promise](https://github.com/Sleitnick/Knit/blob/main/src/Util/Promise.lua) module reproduces the behavior of Promises common in web programming, written by [evaera](https://github.com/evaera). Promises are incredibly useful for managing asynchronous flows. Read the [official documentation](https://eryn.io/roblox-lua-promise/lib/) for usage.

```lua
local Promise = require(Knit.Util.Promise)

local function Fetch(url)
	return Promise.new(function(resolve, reject)
		local success, result = pcall(function()
			return game:GetService("HttpService"):GetAsync(url)
		end)
		if (success) then
			resolve(result)
		else
			reject(result)
		end
	end)
end

Fetch("https://www.example.com")
	:Then(function(result)
		print(result)
	end)
	:Catch(function(err)
		warn(err)
	end)
```
