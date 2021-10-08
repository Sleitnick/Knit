local Knit = require(game:GetService("ReplicatedStorage").Knit)

Knit.Start():andThen(function()
	print("KnitServer started")
end):catch(warn)
