local Knit = require(game:GetService("ReplicatedStorage").Test.Knit)

local MyController = Knit.CreateController {
	Name = "MyController";
}

function MyController:KnitInit()
	local MyService = Knit.GetService("MyService")
	MyService.TestEvent:Connect(function(msg)
		print("Got event from server:", msg)
	end)
	MyService.TestEvent:Fire("Hello")
	MyService:TestMethod("Hello world from client"):andThen(function(result)
		print("Result from server:", result)
	end)
end

Knit.Start({ServicePromises = true}):andThen(function()
	print("KnitClient started")
end):catch(warn)
