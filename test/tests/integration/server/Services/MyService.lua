local Knit = require(game:GetService("ReplicatedStorage").Knit)
local Option = require(Knit.Util.Option)
local Timer = require(Knit.Util.Timer)


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
	if num < 0.5 then
		return Option.Some(num)
	else
		return Option.None
	end
end


function MyService:KnitStart()
	print(self.Name .. " started")
	local timer = Timer.new(1)
	timer.Tick:Connect(function()
		print("TICK", time())
	end)
	timer:Start()
	task.delay(5, function()
		timer:Destroy()
	end)
end


function MyService:KnitInit()
	print(self.Name .. " initialized")
end


return MyService