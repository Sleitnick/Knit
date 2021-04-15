local Knit = require(game:GetService("ReplicatedStorage").Knit)

Knit.Start():Then(function()
	print("Knit started on the server")
end):Catch(warn)