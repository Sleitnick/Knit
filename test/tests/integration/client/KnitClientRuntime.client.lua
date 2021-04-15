local Knit = require(game:GetService("ReplicatedStorage").Knit)

Knit.AddControllers(script.Parent.Controllers)

Knit.Start():Then(function()
	print("Knit started on the client")
end):Catch(warn)