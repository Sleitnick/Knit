local Knit = require(game:GetService("ReplicatedStorage").Knit)

Knit.Start():andThen(function()
	print("KnitClient started")
end):catch(warn)
