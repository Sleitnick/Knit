local Knit = require(game:GetService("ReplicatedStorage").Knit)

Knit.AddServices(script.Parent.Services)

Knit.Start():Then(function()
	print("Knit started on the server")
end):Catch(warn)