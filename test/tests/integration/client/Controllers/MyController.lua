local Knit = require(game:GetService("ReplicatedStorage").Knit)
local Comm = require(Knit.Util.Comm)


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

	local comm = Comm.Client.ForParent(workspace)
	local Add = comm:GetFunction("Add")
	local a = 10
	local b = 20
	local c = Add(a, b)
	print(a .. " + " .. b .. " = " .. c)

end


function MyController:KnitInit()
end


return MyController