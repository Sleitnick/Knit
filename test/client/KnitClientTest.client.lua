local Knit = require(game:GetService("ReplicatedStorage").Test.Knit)

Knit.Start():andThen(function()
	print("KnitClient started")
end):catch(warn)
