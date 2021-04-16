local Knit = require(game:GetService("ReplicatedStorage").Knit)

Knit.AddServices(script.Parent.Services)

Knit.OnStart():Then(function()
	print("OnStart before")
end):Catch(warn)

Knit.Start():Then(function()

	print("Knit started on the server")

	Knit.OnStart():Then(function()
		print("OnStart after")
	end):Catch(warn)

end):Catch(warn)