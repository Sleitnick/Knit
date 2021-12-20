local Knit = require(game:GetService("ReplicatedStorage").Test.Knit)

local MyService = Knit.CreateService {
	Name = "MyService";
	Client = {
		TestEvent = Knit.CreateSignal();
		TestProperty = Knit.CreateProperty("Hello");
	};
}

function MyService:KnitInit()
	self.Client.TestEvent:Connect(function(player, msg)
		print("Got message from client event:", player, msg)
		self.Client.TestEvent:Fire(player, msg:lower())
	end)
end

function MyService.Client:TestMethod(player, msg)
	print("TestMethod from client:", player, msg)
	return msg:upper()
end

Knit.Start():andThen(function()
	print("KnitServer started")
end):catch(warn)
