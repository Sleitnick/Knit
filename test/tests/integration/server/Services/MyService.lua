local Knit = require(game:GetService("ReplicatedStorage").Knit)
local Option = require(Knit.Util.Option)
local Timer = require(Knit.Util.Timer)
local TableUtil = require(Knit.Util.TableUtil)


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

	local conn = Timer.Simple(1, function()
		print("TICK_SIMPLE", time())
	end)

	local timerNoDrift = Timer.new(1)
	timerNoDrift.AllowDrift = false
	timerNoDrift.Tick:Connect(function()
		print("TICK_SYNC", time())
	end)
	timerNoDrift:Start()

	task.delay(5, function()
		timer:Destroy()
		timerNoDrift:Destroy()
		conn:Disconnect()
	end)

	local a = {10, 20, 30, 40, 50}
	local b = {5, 4, 3, 2, 1}
	for i,v in TableUtil.Zip(a, b) do
		print(i, v)
	end

end


function MyService:KnitInit()
	print(self.Name .. " initialized")
end


return MyService