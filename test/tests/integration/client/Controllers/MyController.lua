local Knit = require(game:GetService("ReplicatedStorage").Knit)


local MyController = Knit.CreateController { Name = "MyController" }


function MyController:KnitStart()
	local MyService = Knit.GetService("MyService")
	local msg = MyService:GetMessage()
	print("Message from MyService: " .. msg)
	for _ = 1,10 do
		MyService:MaybeGetRandomNumber():Match {
			Some = function(num)
				print("Got random number: " .. num)
			end;
			None = function()
				print("Did not get a random number")
			end;
		}
	end
end


function MyController:KnitInit()
end


return MyController