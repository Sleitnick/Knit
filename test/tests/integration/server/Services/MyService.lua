local Knit = require(game:GetService("ReplicatedStorage").Knit)
local Option = require(Knit.Util.Option)


local MyService = Knit.CreateService {
	Name = "MyService";
	Client = {};
}


function MyService.Client:GetMessage(_player)
	return "Hello from MyService"
end


function MyService.Client:MaybeGetRandomNumber(_player)
	local rng = Random.new()
	local num = rng:NextNumber()
	if (num < 0.5) then
		return Option.Some(num)
	else
		return Option.None
	end
end


function MyService:KnitStart()
	print(self.Name .. " started")
end


function MyService:KnitInit()
	print(self.Name .. " initialized")
end


return MyService